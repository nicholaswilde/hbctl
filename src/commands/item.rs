use std::collections::{HashMap, HashSet};
use std::io::{self, IsTerminal, Write};
use std::path::{Path, PathBuf};

use serde::Serialize;
use serde_json::{json, Map, Value};

use crate::cli::{
    ImportFormat, ItemArgs, ItemCommands, ItemCreateArgs, ItemDedupArgs, ItemDeleteArgs,
    ItemDuplicateArgs, ItemGetArgs, ItemImportArgs, ItemListArgs, ItemMoveArgs, ItemPathArgs,
    ItemTreeArgs, ItemUpdateArgs, ItemUpsertArgs, MatchKey, MatchMode, OnMatchAction,
};
use crate::client::models::{
    entity_warranty_expiring_within, format_breadcrumb, normalize_json_aliases, parse_bool_loose,
    today_utc_days, upsert_custom_fields, CreateEntityRequest, CustomField, Entity, EntityPatch,
    FieldValueType,
};
use crate::client::resolve::Resolver;
use crate::client::{DryRunRequest, HomeboxClient, ListEntitiesQuery};
use crate::commands::attachment::{
    attach_targets_to_item, build_target_dry_run, parse_local_attachment_spec,
    parse_url_attachment_spec, validate_attachment_targets, AttachmentTarget,
};
use crate::commands::{
    read_file_or_stdin, read_item_ids, render_entities, render_entity, render_entity_with_path,
};
use crate::config::{AppConfig, OutputFormat};
use crate::dedup;
use crate::error::{HbctlError, Result};
use crate::image_opt::ImageOptOptions;
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

pub fn handle(
    args: &ItemArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    match &args.command {
        ItemCommands::List(a) => handle_list(a, config, ctx, out),
        ItemCommands::Get(a) => handle_get(a, config, ctx, out),
        ItemCommands::Create(a) => handle_create(a, dry_run, config, ctx, out, err),
        ItemCommands::Update(a) => handle_update(a, dry_run, config, ctx, out, err),
        ItemCommands::Upsert(a) => handle_upsert(a, dry_run, config, ctx, out, err),
        ItemCommands::Delete(a) => handle_delete(a, dry_run, config, ctx, out, err),
        ItemCommands::Import(a) => handle_import(a, dry_run, config, ctx, out, err),
        ItemCommands::Dedup(a) => handle_dedup(a, dry_run, config, ctx, out, err),
        ItemCommands::Move(a) => handle_move(a, dry_run, config, ctx, out, err),
        ItemCommands::Duplicate(a) => handle_duplicate(a, dry_run, config, ctx, out),
        ItemCommands::Path(a) => handle_path(a, config, ctx, out),
        ItemCommands::Tree(a) => handle_tree(a, config, ctx, out),
    }
}

fn handle_list(
    args: &ItemListArgs,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);

    let mut query = ListEntitiesQuery {
        page_size: args.page_size,
        include_archived: args.include_archived || args.archived_only,
        ..Default::default()
    };

    if let Some(ref tag) = args.tag {
        query.tag_ids.push(resolver.resolve_tag_id(tag, false)?);
    }
    if let Some(ref et) = args.entity_type {
        query.entity_type_id = Some(resolver.resolve_entity_type_id(et)?);
    }
    let parent_filter = match args.parent {
        Some(ref p) => Some(resolver.resolve_parent_id(p)?),
        None => None,
    };

    let fetch_all = args.all
        || parent_filter.is_some()
        || args.archived_only
        || args.warranty_expiring.is_some();
    let mut entities = client.list_entities(&query, fetch_all)?;

    if let Some(ref target_parent) = parent_filter {
        entities.retain(|e| match target_parent {
            Some(pid) => e.parent_id.as_deref() == Some(pid.as_str()),
            None => e
                .parent_id
                .as_deref()
                .map(|s| s.trim().is_empty())
                .unwrap_or(true),
        });
    }

    if args.archived_only {
        entities.retain(|e| e.archived.unwrap_or(false));
    }

    if args.has_field.is_some() || args.warranty_expiring.is_some() {
        entities = client.hydrate_entity_fields(entities)?;
    }

    if let Some(ref key) = args.has_field {
        entities.retain(|e| e.find_field(key).is_some() || e.field_value(key).is_some());
    }

    if let Some(days) = args.warranty_expiring {
        let today = today_utc_days();
        entities.retain(|e| entity_warranty_expiring_within(e, days, today));
    }

    render_entities(&entities, ctx, out)
}

fn handle_get(
    args: &ItemGetArgs,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let client = HomeboxClient::from_config(config)?;
    let entity = client.get_entity(&args.id)?;
    if args.with_path {
        let path = client.get_entity_path(&args.id)?;
        return render_entity_with_path(&entity, &path, ctx, out);
    }
    render_entity(&entity, ctx, out)
}

struct BulkSelector<'a> {
    ids: &'a [String],
    items_from: Option<&'a Path>,
    tag: Option<&'a str>,
    parent: Option<&'a str>,
    entity_type: Option<&'a str>,
}

impl BulkSelector<'_> {
    fn has_remote_filters(&self) -> bool {
        self.tag.is_some() || self.parent.is_some() || self.entity_type.is_some()
    }

    fn has_any_selector(&self) -> bool {
        !self.ids.is_empty() || self.items_from.is_some() || self.has_remote_filters()
    }
}

struct ResolvedTargets {
    ids: Vec<String>,
    is_bulk: bool,
}

fn push_unique_id(seen: &mut HashSet<String>, out: &mut Vec<String>, raw: &str) {
    let trimmed = raw.trim();
    if !trimmed.is_empty() && seen.insert(trimmed.to_string()) {
        out.push(trimmed.to_string());
    }
}

fn resolve_bulk_targets(
    selector: &BulkSelector<'_>,
    client_opt: Option<&HomeboxClient>,
    config: &AppConfig,
) -> Result<ResolvedTargets> {
    if !selector.has_any_selector() {
        return Err(HbctlError::InvalidInput(
            "specify one or more item <ID>s, --items-from <FILE|->, or filter selectors"
                .to_string(),
        ));
    }

    let mut seen = HashSet::new();
    let mut ids = Vec::new();
    for raw_id in selector.ids {
        push_unique_id(&mut seen, &mut ids, raw_id);
    }

    if let Some(path) = selector.items_from {
        for id in read_item_ids(path)? {
            push_unique_id(&mut seen, &mut ids, &id);
        }
    }

    if selector.has_remote_filters() {
        let owned_client;
        let client = match client_opt {
            Some(c) => c,
            None => {
                owned_client = HomeboxClient::from_config(config)?;
                &owned_client
            }
        };
        let mut resolver = Resolver::new(client);
        let mut query = ListEntitiesQuery::default();
        if let Some(tag) = selector.tag {
            query.tag_ids.push(resolver.resolve_tag_id(tag, false)?);
        }
        if let Some(et) = selector.entity_type {
            query.entity_type_id = Some(resolver.resolve_entity_type_id(et)?);
        }
        let parent_filter = match selector.parent {
            Some(p) => Some(resolver.resolve_parent_id(p)?),
            None => None,
        };

        let mut entities = client.list_entities(&query, true)?;
        if let Some(ref target_parent) = parent_filter {
            entities.retain(|e| match target_parent {
                Some(pid) => e.parent_id.as_deref() == Some(pid.as_str()),
                None => e
                    .parent_id
                    .as_deref()
                    .map(|s| s.trim().is_empty())
                    .unwrap_or(true),
            });
        }
        for entity in &entities {
            push_unique_id(&mut seen, &mut ids, &entity.id);
        }
    }

    if ids.is_empty() && selector.items_from.is_none() && !selector.has_remote_filters() {
        return Err(HbctlError::InvalidInput(
            "specify at least one non-empty item <ID>".to_string(),
        ));
    }

    let is_bulk = selector.items_from.is_some() || selector.has_remote_filters() || ids.len() != 1;
    Ok(ResolvedTargets { ids, is_bulk })
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct BulkItemError {
    id: String,
    error: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct BulkUpdateSummary {
    updated: usize,
    failed: usize,
    ids: Vec<String>,
    items: Vec<Entity>,
    errors: Vec<BulkItemError>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct BulkMoveSummary {
    moved: usize,
    failed: usize,
    ids: Vec<String>,
    items: Vec<Entity>,
    errors: Vec<BulkItemError>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct BulkDeleteSummary {
    deleted: usize,
    failed: usize,
    ids: Vec<String>,
    errors: Vec<BulkItemError>,
}

fn render_bulk_status_table(
    succeeded_ids: &[String],
    ok_status: &str,
    errors: &[BulkItemError],
    format: OutputFormat,
    out: &mut dyn Write,
) -> Result<()> {
    let mut rows: Vec<Vec<String>> = succeeded_ids
        .iter()
        .map(|id| vec![id.clone(), ok_status.to_string(), String::new()])
        .collect();
    for e in errors {
        rows.push(vec![e.id.clone(), "failed".to_string(), e.error.clone()]);
    }
    write_table_or_plain(
        &["ID".to_string(), "STATUS".to_string(), "DETAIL".to_string()],
        &rows,
        format,
        out,
    )
}

fn check_bulk_partial_failure(
    action: &str,
    succeeded: usize,
    errors: &[BulkItemError],
) -> Result<()> {
    if !errors.is_empty() {
        return Err(HbctlError::BulkPartialFailure {
            action: action.to_string(),
            succeeded,
            failed: errors.len(),
        });
    }
    Ok(())
}

#[derive(Default)]
struct ParsedItemInput {
    name: Option<String>,
    description: Option<String>,
    quantity: Option<i64>,
    entity_type: Option<String>,
    parent: Option<String>,
    tags: Vec<String>,
    purchase_price: Option<f64>,
    purchase_date: Option<String>,
    purchase_from: Option<String>,
    archived: Option<bool>,
    insured: Option<bool>,
    lifetime_warranty: Option<bool>,
    warranty_expires: Option<String>,
    warranty_details: Option<String>,
    sold_time: Option<String>,
    sold_to: Option<String>,
    sold_price: Option<f64>,
    sold_notes: Option<String>,
    fields: Vec<CustomField>,
    attachments: Vec<AttachmentTarget>,
}

struct MetaOverrides<'a> {
    archived: Option<bool>,
    insured: Option<bool>,
    lifetime_warranty: Option<bool>,
    warranty_expires: Option<&'a str>,
    warranty_details: Option<&'a str>,
    sold_time: Option<&'a str>,
    sold_to: Option<&'a str>,
    sold_price: Option<f64>,
    sold_notes: Option<&'a str>,
}

impl ParsedItemInput {
    fn apply_meta(&mut self, meta: MetaOverrides<'_>) {
        if let Some(v) = meta.archived {
            self.archived = Some(v);
        }
        if let Some(v) = meta.insured {
            self.insured = Some(v);
        }
        if let Some(v) = meta.lifetime_warranty {
            self.lifetime_warranty = Some(v);
        }
        if let Some(v) = meta.warranty_expires {
            self.warranty_expires = Some(v.to_string());
        }
        if let Some(v) = meta.warranty_details {
            self.warranty_details = Some(v.to_string());
        }
        if let Some(v) = meta.sold_time {
            self.sold_time = Some(v.to_string());
        }
        if let Some(v) = meta.sold_to {
            self.sold_to = Some(v.to_string());
        }
        if let Some(v) = meta.sold_price {
            self.sold_price = Some(v);
        }
        if let Some(v) = meta.sold_notes {
            self.sold_notes = Some(v.to_string());
        }
    }

    fn insert_dry_run_meta(&self, obj: &mut Map<String, Value>) {
        if let Some(v) = self.archived {
            obj.insert("archived".to_string(), Value::Bool(v));
        }
        if let Some(v) = self.insured {
            obj.insert("insured".to_string(), Value::Bool(v));
        }
        if let Some(v) = self.lifetime_warranty {
            obj.insert("lifetimeWarranty".to_string(), Value::Bool(v));
        }
        if let Some(ref v) = self.warranty_expires {
            obj.insert("warrantyExpires".to_string(), Value::String(v.clone()));
        }
        if let Some(ref v) = self.warranty_details {
            obj.insert("warrantyDetails".to_string(), Value::String(v.clone()));
        }
        if let Some(ref v) = self.sold_time {
            obj.insert("soldTime".to_string(), Value::String(v.clone()));
        }
        if let Some(ref v) = self.sold_to {
            obj.insert("soldTo".to_string(), Value::String(v.clone()));
        }
        if let Some(v) = self.sold_price {
            obj.insert("soldPrice".to_string(), json!(v));
        }
        if let Some(ref v) = self.sold_notes {
            obj.insert("soldNotes".to_string(), Value::String(v.clone()));
        }
    }
}

fn merge_unique_targets(target: &mut Vec<AttachmentTarget>, extra: &[AttachmentTarget]) {
    for item in extra {
        if !target.contains(item) {
            target.push(item.clone());
        }
    }
}

fn parse_attach_targets(
    local_specs: &[String],
    url_specs: &[String],
) -> Result<Vec<AttachmentTarget>> {
    let mut targets = Vec::with_capacity(local_specs.len() + url_specs.len());
    for raw in local_specs {
        targets.push(parse_local_attachment_spec(raw)?);
    }
    for raw in url_specs {
        targets.push(parse_url_attachment_spec(raw)?);
    }
    Ok(targets)
}

fn attachment_dry_run_previews(
    base_url: &str,
    item_id: &str,
    targets: &[AttachmentTarget],
) -> Vec<DryRunRequest> {
    targets
        .iter()
        .map(|t| build_target_dry_run(base_url, item_id, t))
        .collect()
}

fn parse_dry_run_parent(raw: &str) -> Option<String> {
    let trimmed = raw.trim();
    if trimmed.is_empty() || trimmed.eq_ignore_ascii_case("none") {
        None
    } else {
        Some(trimmed.to_string())
    }
}

fn parse_from_json_value(mut val: Value) -> Result<ParsedItemInput> {
    let mut input = ParsedItemInput::default();
    let normalized_fields = normalize_json_aliases(&mut val);
    input.fields = normalized_fields;

    let obj = val
        .as_object()
        .ok_or_else(|| HbctlError::InvalidInput("item JSON must be an object".to_string()))?;

    input.name = json_str(obj, &["name"]);
    input.description = json_str(obj, &["description"]);
    input.quantity = obj.get("quantity").and_then(Value::as_i64);
    input.entity_type = json_str(obj, &["entityTypeId", "entity_type_id", "type"]);
    if input.entity_type.is_none() {
        if let Some(et_obj) = obj.get("entityType").and_then(Value::as_object) {
            input.entity_type = et_obj
                .get("id")
                .or_else(|| et_obj.get("name"))
                .and_then(Value::as_str)
                .map(ToOwned::to_owned);
        }
    }
    input.parent = json_str(obj, &["parentId", "parent_id", "parent"]);
    if input.parent.is_none() {
        for key in ["parentId", "parent_id", "parent"] {
            if matches!(obj.get(key), Some(Value::Null)) {
                input.parent = Some("none".to_string());
                break;
            }
        }
    }
    input.purchase_price = obj
        .get("purchasePrice")
        .or_else(|| obj.get("purchase_price"))
        .and_then(Value::as_f64);
    input.purchase_date = json_str(obj, &["purchaseDate", "purchase_date"]);
    input.purchase_from = json_str(obj, &["purchaseFrom", "purchase_from"]);
    input.archived = json_bool(obj, &["archived"]);
    input.insured = json_bool(obj, &["insured"]);
    input.lifetime_warranty = json_bool(obj, &["lifetimeWarranty", "lifetime_warranty"]);
    input.warranty_expires = json_str(obj, &["warrantyExpires", "warranty_expires"]);
    input.warranty_details = json_str(obj, &["warrantyDetails", "warranty_details"]);
    input.sold_time = json_str(obj, &["soldTime", "sold_time", "soldDate", "sold_date"]);
    input.sold_to = json_str(obj, &["soldTo", "sold_to"]);
    input.sold_price = obj
        .get("soldPrice")
        .or_else(|| obj.get("sold_price"))
        .and_then(Value::as_f64);
    input.sold_notes = json_str(obj, &["soldNotes", "sold_notes"]);

    if let Some(Value::Array(arr)) = obj.get("tagIds").or_else(|| obj.get("tag_ids")) {
        for v in arr {
            if let Some(s) = v.as_str() {
                if !s.trim().is_empty() {
                    input.tags.push(s.trim().to_string());
                }
            }
        }
    }
    if let Some(Value::Array(arr)) = obj.get("tags") {
        for v in arr {
            if let Some(s) = v.as_str() {
                if !s.trim().is_empty() {
                    input.tags.push(s.trim().to_string());
                }
            } else if let Some(t_obj) = v.as_object() {
                if let Some(s) = t_obj
                    .get("id")
                    .or_else(|| t_obj.get("name"))
                    .and_then(Value::as_str)
                {
                    if !s.trim().is_empty() {
                        input.tags.push(s.trim().to_string());
                    }
                }
            }
        }
    }
    match obj.get("attachments") {
        Some(Value::String(s)) => {
            let t = s.trim();
            if !t.is_empty() {
                input.attachments.push(parse_local_attachment_spec(t)?);
            }
        }
        Some(Value::Array(arr)) => {
            for v in arr {
                if let Some(s) = v.as_str() {
                    let t = s.trim();
                    if !t.is_empty() {
                        input.attachments.push(parse_local_attachment_spec(t)?);
                    }
                } else if let Some(a_obj) = v.as_object() {
                    if let Some(s) = a_obj
                        .get("path")
                        .or_else(|| a_obj.get("file"))
                        .and_then(Value::as_str)
                    {
                        let t = s.trim();
                        if !t.is_empty() {
                            let remote_name = a_obj
                                .get("name")
                                .and_then(Value::as_str)
                                .map(str::trim)
                                .filter(|n| !n.is_empty())
                                .map(ToOwned::to_owned);
                            if remote_name.is_some() {
                                input.attachments.push(AttachmentTarget::Local {
                                    path: PathBuf::from(t),
                                    remote_name,
                                });
                            } else {
                                input.attachments.push(parse_local_attachment_spec(t)?);
                            }
                        }
                    }
                }
            }
        }
        _ => {}
    }

    Ok(input)
}

fn json_str(obj: &serde_json::Map<String, Value>, keys: &[&str]) -> Option<String> {
    for key in keys {
        if let Some(s) = obj.get(*key).and_then(Value::as_str) {
            return Some(s.to_string());
        }
    }
    None
}

fn json_bool(obj: &serde_json::Map<String, Value>, keys: &[&str]) -> Option<bool> {
    for key in keys {
        if let Some(val) = obj.get(*key) {
            if let Some(b) = val.as_bool() {
                return Some(b);
            }
            if let Some(s) = val.as_str() {
                if let Some(b) = parse_bool_loose(s.trim()) {
                    return Some(b);
                }
            }
        }
    }
    None
}

fn append_alias_and_cli_fields(
    target: &mut Vec<CustomField>,
    manufacturer: Option<&str>,
    model: Option<&str>,
    serial: Option<&str>,
    notes: Option<&str>,
    cli_fields: &[String],
    field_type: FieldValueType,
) -> Result<()> {
    if let Some(m) = manufacturer {
        let cf = CustomField::new_typed("Manufacturer", FieldValueType::Text, m)?;
        upsert_custom_fields(target, &[cf]);
    }
    if let Some(m) = model {
        let cf = CustomField::new_typed("Model Number", FieldValueType::Text, m)?;
        upsert_custom_fields(target, &[cf]);
    }
    if let Some(s) = serial {
        let cf = CustomField::new_typed("Serial Number", FieldValueType::Text, s)?;
        upsert_custom_fields(target, &[cf]);
    }
    if let Some(n) = notes {
        let cf = CustomField::new_typed("Notes", FieldValueType::Text, n)?;
        upsert_custom_fields(target, &[cf]);
    }
    for spec in cli_fields {
        let cf = CustomField::parse_key_value(spec, field_type)?;
        upsert_custom_fields(target, &[cf]);
    }
    Ok(())
}

fn handle_create(
    args: &ItemCreateArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    let mut parsed = if let Some(ref src) = args.from_json {
        let raw_text = read_file_or_stdin(src)?;
        let val: Value = serde_json::from_str(&raw_text)?;
        parse_from_json_value(val)?
    } else {
        ParsedItemInput::default()
    };

    if let Some(ref n) = args.name {
        parsed.name = Some(n.clone());
    }
    if let Some(ref d) = args.description {
        parsed.description = Some(d.clone());
    }
    if let Some(ref et) = args.entity_type {
        parsed.entity_type = Some(et.clone());
    }
    if let Some(ref p) = args.parent {
        parsed.parent = Some(p.clone());
    }
    if let Some(q) = args.quantity {
        parsed.quantity = Some(q);
    }
    if let Some(p) = args.purchase_price {
        parsed.purchase_price = Some(p);
    }
    if let Some(ref d) = args.purchase_date {
        parsed.purchase_date = Some(d.clone());
    }
    if let Some(ref f) = args.purchase_from {
        parsed.purchase_from = Some(f.clone());
    }
    parsed.apply_meta(MetaOverrides {
        archived: args.archived,
        insured: args.insured,
        lifetime_warranty: args.lifetime_warranty,
        warranty_expires: args.warranty_expires.as_deref(),
        warranty_details: args.warranty_details.as_deref(),
        sold_time: args.sold_time.as_deref(),
        sold_to: args.sold_to.as_deref(),
        sold_price: args.sold_price,
        sold_notes: args.sold_notes.as_deref(),
    });
    for tag in &args.tags {
        if !parsed.tags.contains(tag) {
            parsed.tags.push(tag.clone());
        }
    }

    append_alias_and_cli_fields(
        &mut parsed.fields,
        args.manufacturer.as_deref(),
        args.model.as_deref(),
        args.serial.as_deref(),
        args.notes.as_deref(),
        &args.fields,
        args.field_type,
    )?;
    let att_opts = ImageOptOptions::from_config(config, args.optimize, args.force);
    let cli_targets = parse_attach_targets(&args.attach, &args.attach_url)?;
    merge_unique_targets(&mut parsed.attachments, &cli_targets);
    if !args.attach_best_effort {
        validate_attachment_targets(&parsed.attachments, att_opts, err)?;
    }

    let name = parsed
        .name
        .clone()
        .filter(|s| !s.trim().is_empty())
        .ok_or_else(|| {
            HbctlError::InvalidInput(
                "item name is required (pass --name or provide in --from-json)".into(),
            )
        })?;

    if dry_run {
        let base_url = config.require_base_url()?;
        let req_payload = CreateEntityRequest {
            name,
            description: parsed.description.clone(),
            quantity: parsed.quantity,
            entity_type_id: parsed.entity_type.clone(),
            parent_id: parsed.parent.as_deref().and_then(parse_dry_run_parent),
            tag_ids: parsed.tags.clone(),
            purchase_price: parsed.purchase_price,
            purchase_date: parsed.purchase_date.clone(),
            purchase_from: parsed.purchase_from.clone(),
            archived: parsed.archived,
            insured: parsed.insured,
            lifetime_warranty: parsed.lifetime_warranty,
            warranty_expires: parsed.warranty_expires.clone(),
            warranty_details: parsed.warranty_details.clone(),
            sold_time: parsed.sold_time.clone(),
            sold_to: parsed.sold_to.clone(),
            sold_price: parsed.sold_price,
            sold_notes: parsed.sold_notes.clone(),
            fields: parsed.fields.clone(),
        };
        let mut previews = vec![HomeboxClient::build_dry_run(
            base_url,
            "POST",
            "entities",
            Some(serde_json::to_value(&req_payload)?),
        )];
        if req_payload.needs_followup_put() {
            let mut put_body = Map::new();
            if !parsed.fields.is_empty() {
                put_body.insert("fields".to_string(), serde_json::to_value(&parsed.fields)?);
            }
            parsed.insert_dry_run_meta(&mut put_body);
            previews.push(HomeboxClient::build_dry_run(
                base_url,
                "PUT",
                "entities/<created-id>",
                Some(Value::Object(put_body)),
            ));
        }
        previews.extend(attachment_dry_run_previews(
            base_url,
            "<created-id>",
            &parsed.attachments,
        ));
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);

    let tag_ids = resolver.resolve_tag_ids(&parsed.tags, true)?;
    let entity_type_id = match parsed.entity_type {
        Some(ref et) => Some(resolver.resolve_entity_type_id(et)?),
        None => None,
    };
    let parent_id = match parsed.parent {
        Some(ref p) => resolver.resolve_parent_id(p)?,
        None => None,
    };

    let req = CreateEntityRequest {
        name,
        description: parsed.description,
        quantity: parsed.quantity,
        entity_type_id,
        parent_id,
        tag_ids,
        purchase_price: parsed.purchase_price,
        purchase_date: parsed.purchase_date,
        purchase_from: parsed.purchase_from,
        archived: parsed.archived,
        insured: parsed.insured,
        lifetime_warranty: parsed.lifetime_warranty,
        warranty_expires: parsed.warranty_expires,
        warranty_details: parsed.warranty_details,
        sold_time: parsed.sold_time,
        sold_to: parsed.sold_to,
        sold_price: parsed.sold_price,
        sold_notes: parsed.sold_notes,
        fields: parsed.fields,
    };

    let mut created = client.create_entity(&req)?;
    let attachment_errors = if !parsed.attachments.is_empty() {
        let (uploaded, errors) = attach_targets_to_item(
            &client,
            &created.id,
            &created.attachments,
            &parsed.attachments,
            att_opts,
            args.attach_best_effort,
            err,
        )?;
        created.attachments.extend(uploaded);
        errors
    } else {
        Vec::new()
    };

    if !attachment_errors.is_empty() && !ctx.quiet && ctx.format == OutputFormat::Json {
        let mut val = serde_json::to_value(&created)?;
        if let Some(obj) = val.as_object_mut() {
            obj.insert(
                "attachmentErrors".to_string(),
                serde_json::to_value(&attachment_errors)?,
            );
        }
        return write_compact_json(&val, ctx.select.as_deref(), out);
    }

    render_entity(&created, ctx, out)
}

fn handle_update(
    args: &ItemUpdateArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    if args.from_json.as_deref() == Some("-") && args.items_from.as_deref() == Some(Path::new("-"))
    {
        return Err(HbctlError::InvalidInput(
            "cannot read both --from-json and --items-from from stdin ('-')".to_string(),
        ));
    }

    let selector = BulkSelector {
        ids: &args.ids,
        items_from: args.items_from.as_deref(),
        tag: args.filter_tag.as_deref(),
        parent: args.filter_parent.as_deref(),
        entity_type: args.filter_type.as_deref(),
    };

    let mut parsed = if let Some(ref src) = args.from_json {
        let raw_text = read_file_or_stdin(src)?;
        let val: Value = serde_json::from_str(&raw_text)?;
        parse_from_json_value(val)?
    } else {
        ParsedItemInput::default()
    };

    if let Some(ref n) = args.name {
        parsed.name = Some(n.clone());
    }
    if let Some(ref d) = args.description {
        parsed.description = Some(d.clone());
    }
    if let Some(ref et) = args.entity_type {
        parsed.entity_type = Some(et.clone());
    }
    if let Some(ref p) = args.parent {
        parsed.parent = Some(p.clone());
    }
    if let Some(q) = args.quantity {
        parsed.quantity = Some(q);
    }
    if let Some(p) = args.purchase_price {
        parsed.purchase_price = Some(p);
    }
    if let Some(ref d) = args.purchase_date {
        parsed.purchase_date = Some(d.clone());
    }
    if let Some(ref f) = args.purchase_from {
        parsed.purchase_from = Some(f.clone());
    }
    parsed.apply_meta(MetaOverrides {
        archived: args.archived,
        insured: args.insured,
        lifetime_warranty: args.lifetime_warranty,
        warranty_expires: args.warranty_expires.as_deref(),
        warranty_details: args.warranty_details.as_deref(),
        sold_time: args.sold_time.as_deref(),
        sold_to: args.sold_to.as_deref(),
        sold_price: args.sold_price,
        sold_notes: args.sold_notes.as_deref(),
    });
    for tag in &args.tags {
        if !parsed.tags.contains(tag) {
            parsed.tags.push(tag.clone());
        }
    }

    append_alias_and_cli_fields(
        &mut parsed.fields,
        args.manufacturer.as_deref(),
        args.model.as_deref(),
        args.serial.as_deref(),
        args.notes.as_deref(),
        &args.fields,
        args.field_type,
    )?;

    if dry_run {
        let resolved = resolve_bulk_targets(&selector, None, config)?;
        let base_url = config.require_base_url()?;
        let patch = EntityPatch {
            name: parsed.name,
            description: parsed.description,
            quantity: parsed.quantity,
            entity_type_id: parsed.entity_type,
            parent_id: parsed.parent.as_deref().map(parse_dry_run_parent),
            tag_ids: if parsed.tags.is_empty() {
                None
            } else {
                Some(parsed.tags)
            },
            purchase_price: parsed.purchase_price,
            purchase_date: parsed.purchase_date,
            purchase_from: parsed.purchase_from,
            archived: parsed.archived,
            insured: parsed.insured,
            lifetime_warranty: parsed.lifetime_warranty,
            warranty_expires: parsed.warranty_expires,
            warranty_details: parsed.warranty_details,
            sold_time: parsed.sold_time,
            sold_to: parsed.sold_to,
            sold_price: parsed.sold_price,
            sold_notes: parsed.sold_notes,
            add_tag_ids: args.add_tags.clone(),
            remove_tag_ids: args.remove_tags.clone(),
            fields: parsed.fields,
            fill_missing: args.fill_missing,
            ..Default::default()
        };
        let patch_val = serde_json::to_value(&patch)?;
        let previews: Vec<DryRunRequest> = resolved
            .ids
            .iter()
            .map(|id| {
                HomeboxClient::build_dry_run(
                    base_url,
                    "PUT",
                    &format!("entities/{id}"),
                    Some(patch_val.clone()),
                )
            })
            .collect();
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let resolved = resolve_bulk_targets(&selector, Some(&client), config)?;

    if resolved.ids.is_empty() {
        if ctx.quiet {
            return write_quiet_ids(&[], out);
        }
        if ctx.format == OutputFormat::Json {
            return write_compact_json(
                &BulkUpdateSummary {
                    updated: 0,
                    failed: 0,
                    ids: Vec::new(),
                    items: Vec::new(),
                    errors: Vec::new(),
                },
                ctx.select.as_deref(),
                out,
            );
        }
        writeln!(out, "No matching items to update.")?;
        return Ok(());
    }

    let mut resolver = Resolver::new(&client);

    let tag_ids = if parsed.tags.is_empty() {
        None
    } else {
        Some(resolver.resolve_tag_ids(&parsed.tags, true)?)
    };
    let add_tag_ids = if args.add_tags.is_empty() {
        Vec::new()
    } else {
        resolver.resolve_tag_ids(&args.add_tags, true)?
    };
    let remove_tag_ids = if args.remove_tags.is_empty() {
        Vec::new()
    } else {
        resolver.resolve_tag_ids(&args.remove_tags, false)?
    };
    let entity_type_id = match parsed.entity_type {
        Some(ref et) => Some(resolver.resolve_entity_type_id(et)?),
        None => None,
    };
    let parent_id = match parsed.parent {
        Some(ref p) => Some(resolver.resolve_parent_id(p)?),
        None => None,
    };

    let patch = EntityPatch {
        name: parsed.name,
        description: parsed.description,
        quantity: parsed.quantity,
        entity_type_id,
        parent_id,
        tag_ids,
        purchase_price: parsed.purchase_price,
        purchase_date: parsed.purchase_date,
        purchase_from: parsed.purchase_from,
        archived: parsed.archived,
        insured: parsed.insured,
        lifetime_warranty: parsed.lifetime_warranty,
        warranty_expires: parsed.warranty_expires,
        warranty_details: parsed.warranty_details,
        sold_time: parsed.sold_time,
        sold_to: parsed.sold_to,
        sold_price: parsed.sold_price,
        sold_notes: parsed.sold_notes,
        add_tag_ids,
        remove_tag_ids,
        fields: parsed.fields,
        fill_missing: args.fill_missing,
        ..Default::default()
    };

    if !resolved.is_bulk {
        let updated = client.update_entity(&resolved.ids[0], &patch)?;
        return render_entity(&updated, ctx, out);
    }

    let mut updated_items = Vec::new();
    let mut succeeded_ids = Vec::new();
    let mut errors = Vec::new();
    for id in &resolved.ids {
        match client.update_entity(id, &patch) {
            Ok(ent) => {
                succeeded_ids.push(ent.id.clone());
                updated_items.push(ent);
            }
            Err(e) => {
                writeln!(err, "error updating item '{id}': {e}")?;
                errors.push(BulkItemError {
                    id: id.clone(),
                    error: e.to_string(),
                });
            }
        }
    }

    if ctx.quiet {
        write_quiet_ids(&succeeded_ids, out)?;
    } else if ctx.format == OutputFormat::Json {
        let summary = BulkUpdateSummary {
            updated: updated_items.len(),
            failed: errors.len(),
            ids: succeeded_ids.clone(),
            items: updated_items,
            errors: errors.clone(),
        };
        write_compact_json(&summary, ctx.select.as_deref(), out)?;
    } else if errors.is_empty() {
        render_entities(&updated_items, ctx, out)?;
    } else {
        render_bulk_status_table(&succeeded_ids, "updated", &errors, ctx.format, out)?;
    }

    check_bulk_partial_failure("update", succeeded_ids.len(), &errors)
}

fn effective_match_keys(keys: &[MatchKey]) -> Vec<MatchKey> {
    if keys.is_empty() {
        vec![MatchKey::Name]
    } else {
        keys.to_vec()
    }
}

fn match_keys_need_hydration(keys: &[MatchKey]) -> bool {
    keys.iter().any(|k| !matches!(k, MatchKey::Name))
}

fn normalize_match_str(s: &str) -> Option<String> {
    let trimmed = s.trim();
    if trimmed.is_empty() {
        None
    } else {
        Some(trimmed.to_ascii_lowercase())
    }
}

fn input_custom_field_value(fields: &[CustomField], names: &[&str]) -> Option<String> {
    for candidate_name in names {
        if let Some(cf) = fields
            .iter()
            .find(|f| f.name.trim().eq_ignore_ascii_case(candidate_name))
        {
            if let Some(val) = normalize_match_str(&cf.display_value()) {
                return Some(val);
            }
        }
    }
    None
}

fn entity_custom_field_or_fallback(
    entity: &Entity,
    names: &[&str],
    fallback: Option<&str>,
) -> Option<String> {
    for candidate_name in names {
        if let Some(cf) = entity.find_field(candidate_name) {
            if let Some(val) = normalize_match_str(&cf.display_value()) {
                return Some(val);
            }
        }
    }
    fallback.and_then(normalize_match_str)
}

fn input_match_value(input: &ParsedItemInput, key: &MatchKey) -> Option<String> {
    match key {
        MatchKey::Name => input.name.as_deref().and_then(normalize_match_str),
        MatchKey::Model => input_custom_field_value(
            &input.fields,
            &["Model Number", "Model", "modelNumber", "model_number"],
        ),
        MatchKey::Serial => input_custom_field_value(
            &input.fields,
            &["Serial Number", "Serial", "serialNumber", "serial_number"],
        ),
        MatchKey::Field(k) => input_custom_field_value(&input.fields, &[k.as_str()]),
    }
}

fn entity_match_value(entity: &Entity, key: &MatchKey) -> Option<String> {
    match key {
        MatchKey::Name => normalize_match_str(&entity.name),
        MatchKey::Model => entity_custom_field_or_fallback(
            entity,
            &["Model Number", "Model", "modelNumber", "model_number"],
            entity.model_number.as_deref(),
        ),
        MatchKey::Serial => entity_custom_field_or_fallback(
            entity,
            &["Serial Number", "Serial", "serialNumber", "serial_number"],
            entity.serial_number.as_deref(),
        ),
        MatchKey::Field(k) => entity.field_value(k).and_then(|v| normalize_match_str(&v)),
    }
}

pub const DEFAULT_FUZZY_MATCH_THRESHOLD: f64 = 0.8;

fn find_matching_entity_index(
    candidates: &[Entity],
    input: &ParsedItemInput,
    match_keys: &[MatchKey],
    mode: MatchMode,
) -> Option<usize> {
    for key in match_keys {
        let Some(needle) = input_match_value(input, key) else {
            continue;
        };
        // Exact normalized match always takes precedence over partial/fuzzy hits.
        if let Some(idx) = candidates
            .iter()
            .position(|e| entity_match_value(e, key).as_deref() == Some(needle.as_str()))
        {
            return Some(idx);
        }
        match mode {
            MatchMode::Exact => {}
            MatchMode::Contains => {
                if let Some(idx) = candidates.iter().position(|e| {
                    entity_match_value(e, key)
                        .as_deref()
                        .is_some_and(|h| h.contains(needle.as_str()))
                }) {
                    return Some(idx);
                }
            }
            MatchMode::Fuzzy => {
                let needle_tokens = dedup::normalize_tokens(&needle);
                if needle_tokens.is_empty() {
                    continue;
                }
                let mut best: Option<(usize, f64)> = None;
                for (idx, entity) in candidates.iter().enumerate() {
                    let Some(haystack) = entity_match_value(entity, key) else {
                        continue;
                    };
                    let cand_tokens = dedup::normalize_tokens(&haystack);
                    if cand_tokens.is_empty() {
                        continue;
                    }
                    let sim = dedup::jaccard_similarity(&needle_tokens, &cand_tokens);
                    if sim >= DEFAULT_FUZZY_MATCH_THRESHOLD
                        && best.is_none_or(|(_, best_sim)| sim > best_sim)
                    {
                        best = Some((idx, sim));
                    }
                }
                if let Some((idx, _)) = best {
                    return Some(idx);
                }
            }
        }
    }
    None
}

fn handle_upsert(
    args: &ItemUpsertArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    let mut parsed = if let Some(ref src) = args.from_json {
        let raw_text = read_file_or_stdin(src)?;
        let val: Value = serde_json::from_str(&raw_text)?;
        parse_from_json_value(val)?
    } else {
        ParsedItemInput::default()
    };

    if let Some(ref n) = args.name {
        parsed.name = Some(n.clone());
    }
    if let Some(ref d) = args.description {
        parsed.description = Some(d.clone());
    }
    if let Some(ref et) = args.entity_type {
        parsed.entity_type = Some(et.clone());
    }
    if let Some(ref p) = args.parent {
        parsed.parent = Some(p.clone());
    }
    if let Some(q) = args.quantity {
        parsed.quantity = Some(q);
    }
    if let Some(p) = args.purchase_price {
        parsed.purchase_price = Some(p);
    }
    if let Some(ref d) = args.purchase_date {
        parsed.purchase_date = Some(d.clone());
    }
    if let Some(ref f) = args.purchase_from {
        parsed.purchase_from = Some(f.clone());
    }
    parsed.apply_meta(MetaOverrides {
        archived: args.archived,
        insured: args.insured,
        lifetime_warranty: args.lifetime_warranty,
        warranty_expires: args.warranty_expires.as_deref(),
        warranty_details: args.warranty_details.as_deref(),
        sold_time: args.sold_time.as_deref(),
        sold_to: args.sold_to.as_deref(),
        sold_price: args.sold_price,
        sold_notes: args.sold_notes.as_deref(),
    });
    for tag in &args.tags {
        if !parsed.tags.contains(tag) {
            parsed.tags.push(tag.clone());
        }
    }

    append_alias_and_cli_fields(
        &mut parsed.fields,
        args.manufacturer.as_deref(),
        args.model.as_deref(),
        args.serial.as_deref(),
        args.notes.as_deref(),
        &args.fields,
        args.field_type,
    )?;

    let match_keys = effective_match_keys(&args.match_by);
    let att_opts = ImageOptOptions::from_config(config, args.optimize, args.force);
    let cli_targets = parse_attach_targets(&args.attach, &args.attach_url)?;
    merge_unique_targets(&mut parsed.attachments, &cli_targets);
    if !args.attach_best_effort {
        validate_attachment_targets(&parsed.attachments, att_opts, err)?;
    }
    let has_name = parsed
        .name
        .as_deref()
        .map(|s| !s.trim().is_empty())
        .unwrap_or(false);
    let has_match_value = match_keys
        .iter()
        .any(|k| input_match_value(&parsed, k).is_some());
    if !has_name && !has_match_value {
        return Err(HbctlError::InvalidInput(
            "item name is required (pass --name or provide in --from-json)".into(),
        ));
    }

    if dry_run {
        let base_url = config.require_base_url()?;
        let dry_action = match args.on_match {
            OnMatchAction::Update => "upsert",
            OnMatchAction::Skip => "skip",
            OnMatchAction::AttachOnly => "attach-only",
        };
        let mut body = json!({
            "action": dry_action,
            "name": parsed.name,
            "description": parsed.description,
            "quantity": parsed.quantity,
            "tags": parsed.tags,
            "fields": parsed.fields,
        });
        if args.on_match != OnMatchAction::Update {
            if let Some(obj) = body.as_object_mut() {
                obj.insert(
                    "onMatch".to_string(),
                    Value::String(args.on_match.to_string()),
                );
            }
        }
        if args.match_mode != MatchMode::Exact {
            if let Some(obj) = body.as_object_mut() {
                obj.insert(
                    "matchMode".to_string(),
                    Value::String(args.match_mode.to_string()),
                );
            }
        }
        if args.fill_missing {
            if let Some(obj) = body.as_object_mut() {
                obj.insert("fillMissing".to_string(), Value::Bool(true));
            }
        }
        if !args.match_by.is_empty() {
            if let Some(obj) = body.as_object_mut() {
                let keys: Vec<String> = args.match_by.iter().map(ToString::to_string).collect();
                obj.insert("matchBy".to_string(), json!(keys));
            }
        }
        if let Some(ref p) = parsed.parent {
            if let Some(obj) = body.as_object_mut() {
                let val = match parse_dry_run_parent(p) {
                    Some(pid) => Value::String(pid),
                    None => Value::Null,
                };
                obj.insert("parentId".to_string(), val);
            }
        }
        if let Some(obj) = body.as_object_mut() {
            parsed.insert_dry_run_meta(obj);
        }
        let mut previews = vec![HomeboxClient::build_dry_run(
            base_url,
            "POST",
            "entities",
            Some(body),
        )];
        if args.on_match != OnMatchAction::Skip {
            previews.extend(attachment_dry_run_previews(
                base_url,
                "<item-id>",
                &parsed.attachments,
            ));
        }
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);

    let candidates = if match_keys_need_hydration(&match_keys) {
        let list = client.list_entities(&ListEntitiesQuery::default(), true)?;
        client.hydrate_entity_fields(list)?
    } else if args.match_mode != MatchMode::Exact {
        client.list_entities(&ListEntitiesQuery::default(), true)?
    } else {
        let query = ListEntitiesQuery {
            query: parsed.name.clone(),
            ..Default::default()
        };
        client.list_entities(&query, true)?
    };

    let matched_idx =
        find_matching_entity_index(&candidates, &parsed, &match_keys, args.match_mode);

    let (mut result, action, should_attach) = if let Some(idx) = matched_idx {
        let found = &candidates[idx];
        match args.on_match {
            OnMatchAction::Skip => (found.clone(), "skipped", false),
            OnMatchAction::AttachOnly => {
                if parsed.attachments.is_empty() {
                    (found.clone(), "attached", false)
                } else {
                    let fresh = client.get_entity(&found.id)?;
                    (fresh, "attached", true)
                }
            }
            OnMatchAction::Update => {
                let tag_ids = resolver.resolve_tag_ids(&parsed.tags, true)?;
                let entity_type_id = match parsed.entity_type {
                    Some(ref et) => Some(resolver.resolve_entity_type_id(et)?),
                    None => None,
                };
                let parent_patch = match parsed.parent {
                    Some(ref p) => Some(resolver.resolve_parent_id(p)?),
                    None => None,
                };
                let patch = EntityPatch {
                    name: None,
                    description: parsed.description,
                    quantity: parsed.quantity,
                    entity_type_id,
                    parent_id: parent_patch,
                    tag_ids: if tag_ids.is_empty() {
                        None
                    } else {
                        Some(tag_ids)
                    },
                    purchase_price: parsed.purchase_price,
                    purchase_date: parsed.purchase_date,
                    purchase_from: parsed.purchase_from,
                    archived: parsed.archived,
                    insured: parsed.insured,
                    lifetime_warranty: parsed.lifetime_warranty,
                    warranty_expires: parsed.warranty_expires,
                    warranty_details: parsed.warranty_details,
                    sold_time: parsed.sold_time,
                    sold_to: parsed.sold_to,
                    sold_price: parsed.sold_price,
                    sold_notes: parsed.sold_notes,
                    fields: parsed.fields,
                    fill_missing: args.fill_missing,
                    ..Default::default()
                };
                (client.update_entity(&found.id, &patch)?, "updated", true)
            }
        }
    } else {
        let tag_ids = resolver.resolve_tag_ids(&parsed.tags, true)?;
        let entity_type_id = match parsed.entity_type {
            Some(ref et) => Some(resolver.resolve_entity_type_id(et)?),
            None => None,
        };
        let parent_patch = match parsed.parent {
            Some(ref p) => Some(resolver.resolve_parent_id(p)?),
            None => None,
        };
        let name = parsed
                .name
                .filter(|s| !s.trim().is_empty())
                .ok_or_else(|| {
                    HbctlError::InvalidInput(
                        "item name is required to create a new item (pass --name or provide in --from-json)"
                            .into(),
                    )
                })?;
        let req = CreateEntityRequest {
            name,
            description: parsed.description,
            quantity: parsed.quantity,
            entity_type_id,
            parent_id: parent_patch.flatten(),
            tag_ids,
            purchase_price: parsed.purchase_price,
            purchase_date: parsed.purchase_date,
            purchase_from: parsed.purchase_from,
            archived: parsed.archived,
            insured: parsed.insured,
            lifetime_warranty: parsed.lifetime_warranty,
            warranty_expires: parsed.warranty_expires,
            warranty_details: parsed.warranty_details,
            sold_time: parsed.sold_time,
            sold_to: parsed.sold_to,
            sold_price: parsed.sold_price,
            sold_notes: parsed.sold_notes,
            fields: parsed.fields,
        };
        (client.create_entity(&req)?, "created", true)
    };

    let attachment_errors = if should_attach && !parsed.attachments.is_empty() {
        let (uploaded, errors) = attach_targets_to_item(
            &client,
            &result.id,
            &result.attachments,
            &parsed.attachments,
            att_opts,
            args.attach_best_effort,
            err,
        )?;
        result.attachments.extend(uploaded);
        errors
    } else {
        Vec::new()
    };

    writeln!(err, "{action} item '{}' ({})", result.name, result.id)?;

    if !ctx.quiet && ctx.format == OutputFormat::Json {
        let mut val = serde_json::to_value(&result)?;
        if let Some(obj) = val.as_object_mut() {
            obj.insert("action".to_string(), Value::String(action.to_string()));
            if !attachment_errors.is_empty() {
                obj.insert(
                    "attachmentErrors".to_string(),
                    serde_json::to_value(&attachment_errors)?,
                );
            }
        }
        return write_compact_json(&val, ctx.select.as_deref(), out);
    }

    render_entity(&result, ctx, out)
}

fn handle_delete(
    args: &ItemDeleteArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    let selector = BulkSelector {
        ids: &args.ids,
        items_from: args.items_from.as_deref(),
        tag: args.tag.as_deref(),
        parent: args.parent.as_deref(),
        entity_type: args.entity_type.as_deref(),
    };

    if dry_run {
        let resolved = resolve_bulk_targets(&selector, None, config)?;
        let base_url = config.require_base_url()?;
        let previews: Vec<DryRunRequest> = resolved
            .ids
            .iter()
            .map(|id| {
                HomeboxClient::build_dry_run(base_url, "DELETE", &format!("entities/{id}"), None)
            })
            .collect();
        return write_dry_run(&previews, ctx, out);
    }

    let (resolved, client_opt) = if selector.has_remote_filters() {
        let client = HomeboxClient::from_config(config)?;
        let resolved = resolve_bulk_targets(&selector, Some(&client), config)?;
        (resolved, Some(client))
    } else {
        let resolved = resolve_bulk_targets(&selector, None, config)?;
        (resolved, None)
    };

    if resolved.ids.is_empty() {
        if ctx.quiet {
            return write_quiet_ids(&[], out);
        }
        if ctx.format == OutputFormat::Json {
            return write_compact_json(
                &BulkDeleteSummary {
                    deleted: 0,
                    failed: 0,
                    ids: Vec::new(),
                    errors: Vec::new(),
                },
                ctx.select.as_deref(),
                out,
            );
        }
        writeln!(out, "No matching items to delete.")?;
        return Ok(());
    }

    if !resolved.is_bulk {
        let target_id = &resolved.ids[0];
        if !args.skip_confirm() && io::stdin().is_terminal() {
            write!(err, "Delete item '{target_id}'? [y/N]: ")?;
            err.flush()?;
            let mut answer = String::new();
            io::stdin().read_line(&mut answer)?;
            if !matches!(answer.trim().to_ascii_lowercase().as_str(), "y" | "yes") {
                writeln!(err, "Aborted.")?;
                return Ok(());
            }
        }
    } else if !args.skip_confirm() {
        let stdin_consumed = args.items_from.as_deref() == Some(Path::new("-"));
        if io::stdin().is_terminal() && !stdin_consumed {
            let preview: Vec<&str> = resolved.ids.iter().take(5).map(String::as_str).collect();
            let suffix = if resolved.ids.len() > 5 {
                format!(", ... (+{} more)", resolved.ids.len() - 5)
            } else {
                String::new()
            };
            write!(
                err,
                "Delete {} item(s) ({}{suffix})? [y/N]: ",
                resolved.ids.len(),
                preview.join(", ")
            )?;
            err.flush()?;
            let mut answer = String::new();
            io::stdin().read_line(&mut answer)?;
            if !matches!(answer.trim().to_ascii_lowercase().as_str(), "y" | "yes") {
                writeln!(err, "Aborted.")?;
                return Ok(());
            }
        } else {
            return Err(HbctlError::InvalidInput(format!(
                "refusing to delete {} item(s) non-interactively without --yes (or --force); pass --dry-run to preview",
                resolved.ids.len()
            )));
        }
    }

    let client = match client_opt {
        Some(c) => c,
        None => HomeboxClient::from_config(config)?,
    };

    if !resolved.is_bulk {
        let target_id = &resolved.ids[0];
        client.delete_entity(target_id)?;

        if ctx.quiet {
            return write_quiet_ids(std::slice::from_ref(target_id), out);
        }
        if ctx.format == OutputFormat::Json {
            return write_compact_json(
                &json!({ "id": target_id, "deleted": true }),
                ctx.select.as_deref(),
                out,
            );
        }
        writeln!(out, "Deleted item {target_id}")?;
        return Ok(());
    }

    let mut deleted_ids = Vec::new();
    let mut errors = Vec::new();
    for id in &resolved.ids {
        match client.delete_entity(id) {
            Ok(()) => {
                deleted_ids.push(id.clone());
            }
            Err(e) => {
                writeln!(err, "error deleting item '{id}': {e}")?;
                errors.push(BulkItemError {
                    id: id.clone(),
                    error: e.to_string(),
                });
            }
        }
    }

    if ctx.quiet {
        write_quiet_ids(&deleted_ids, out)?;
    } else if ctx.format == OutputFormat::Json {
        let summary = BulkDeleteSummary {
            deleted: deleted_ids.len(),
            failed: errors.len(),
            ids: deleted_ids.clone(),
            errors: errors.clone(),
        };
        write_compact_json(&summary, ctx.select.as_deref(), out)?;
    } else {
        render_bulk_status_table(&deleted_ids, "deleted", &errors, ctx.format, out)?;
    }

    check_bulk_partial_failure("delete", deleted_ids.len(), &errors)
}

#[derive(Debug, Serialize)]
struct ImportSummary {
    created: usize,
    updated: usize,
    skipped: usize,
    ids: Vec<String>,
}

fn parse_import_records(
    file: &str,
    format_opt: Option<ImportFormat>,
) -> Result<Vec<ParsedItemInput>> {
    let format = format_opt.unwrap_or_else(|| {
        if file.to_ascii_lowercase().ends_with(".csv") {
            ImportFormat::Csv
        } else {
            ImportFormat::Json
        }
    });

    let raw = read_file_or_stdin(file)?;
    match format {
        ImportFormat::Json => parse_json_import(&raw),
        ImportFormat::Csv => parse_csv_import(&raw),
    }
}

fn parse_json_import(raw: &str) -> Result<Vec<ParsedItemInput>> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Ok(Vec::new());
    }

    let val: Value = serde_json::from_str(trimmed)?;
    let arr = match val {
        Value::Array(items) => items,
        Value::Object(mut obj) => {
            if let Some(Value::Array(items)) = obj.remove("items") {
                items
            } else {
                vec![Value::Object(obj)]
            }
        }
        _ => {
            return Err(HbctlError::InvalidInput(
                "JSON import must be an array, object, or {\"items\": [...]}".to_string(),
            ))
        }
    };

    arr.into_iter().map(parse_from_json_value).collect()
}

fn parse_csv_import(raw: &str) -> Result<Vec<ParsedItemInput>> {
    let mut rdr = csv::Reader::from_reader(raw.as_bytes());
    let headers: Vec<String> = rdr
        .headers()?
        .iter()
        .map(|h| h.trim().to_string())
        .collect();

    let mut records = Vec::new();
    for result in rdr.records() {
        let row = result?;
        let mut item = ParsedItemInput::default();
        for (idx, header) in headers.iter().enumerate() {
            let val = row.get(idx).unwrap_or("").trim();
            if val.is_empty() {
                continue;
            }
            let normalized = header.to_ascii_lowercase();
            let key = normalized.strip_prefix("hb.").unwrap_or(&normalized);
            match key {
                "name" => item.name = Some(val.to_string()),
                "description" => item.description = Some(val.to_string()),
                "quantity" => {
                    item.quantity = Some(val.parse::<i64>().map_err(|_| {
                        HbctlError::InvalidInput(format!("invalid CSV quantity '{val}'"))
                    })?);
                }
                "type" | "entitytype" | "entity_type" | "entitytypeid" => {
                    item.entity_type = Some(val.to_string());
                }
                "parent" | "parentid" | "parent_id" => {
                    item.parent = Some(val.to_string());
                }
                "attachments" | "attachment" => {
                    for p in val.split([',', ';']) {
                        let p = p.trim();
                        if !p.is_empty() {
                            item.attachments.push(parse_local_attachment_spec(p)?);
                        }
                    }
                }
                "tags" | "tag" | "labels" => {
                    for t in val.split([',', ';']) {
                        let t = t.trim();
                        if !t.is_empty() {
                            item.tags.push(t.to_string());
                        }
                    }
                }
                "purchaseprice" | "purchase_price" => {
                    item.purchase_price = Some(val.parse::<f64>().map_err(|_| {
                        HbctlError::InvalidInput(format!("invalid CSV purchasePrice '{val}'"))
                    })?);
                }
                "purchasedate" | "purchase_date" | "purchasetime" | "purchase_time" => {
                    item.purchase_date = Some(val.to_string())
                }
                "purchasefrom" | "purchase_from" => item.purchase_from = Some(val.to_string()),
                "archived" => {
                    item.archived = Some(parse_bool_loose(val).ok_or_else(|| {
                        HbctlError::InvalidInput(format!("invalid CSV archived '{val}'"))
                    })?);
                }
                "insured" => {
                    item.insured = Some(parse_bool_loose(val).ok_or_else(|| {
                        HbctlError::InvalidInput(format!("invalid CSV insured '{val}'"))
                    })?);
                }
                "lifetimewarranty" | "lifetime_warranty" => {
                    item.lifetime_warranty = Some(parse_bool_loose(val).ok_or_else(|| {
                        HbctlError::InvalidInput(format!("invalid CSV lifetimeWarranty '{val}'"))
                    })?);
                }
                "warrantyexpires" | "warranty_expires" => {
                    item.warranty_expires = Some(val.to_string())
                }
                "warrantydetails" | "warranty_details" => {
                    item.warranty_details = Some(val.to_string())
                }
                "soldtime" | "sold_time" | "solddate" | "sold_date" => {
                    item.sold_time = Some(val.to_string())
                }
                "soldto" | "sold_to" => item.sold_to = Some(val.to_string()),
                "soldprice" | "sold_price" => {
                    item.sold_price = Some(val.parse::<f64>().map_err(|_| {
                        HbctlError::InvalidInput(format!("invalid CSV soldPrice '{val}'"))
                    })?);
                }
                "soldnotes" | "sold_notes" => item.sold_notes = Some(val.to_string()),
                "manufacturer" => {
                    let cf = CustomField::new_typed("Manufacturer", FieldValueType::Text, val)?;
                    upsert_custom_fields(&mut item.fields, &[cf]);
                }
                "model" | "modelnumber" | "model_number" | "model number" => {
                    let cf = CustomField::new_typed("Model Number", FieldValueType::Text, val)?;
                    upsert_custom_fields(&mut item.fields, &[cf]);
                }
                "serial" | "serialnumber" | "serial_number" | "serial number" => {
                    let cf = CustomField::new_typed("Serial Number", FieldValueType::Text, val)?;
                    upsert_custom_fields(&mut item.fields, &[cf]);
                }
                "notes" => {
                    let cf = CustomField::new_typed("Notes", FieldValueType::Text, val)?;
                    upsert_custom_fields(&mut item.fields, &[cf]);
                }
                _ => {
                    let cf = CustomField::new_typed(header, FieldValueType::Text, val)?;
                    upsert_custom_fields(&mut item.fields, &[cf]);
                }
            }
        }
        records.push(item);
    }
    Ok(records)
}

fn handle_import(
    args: &ItemImportArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    let records = parse_import_records(&args.file, args.format)?;
    let match_keys = effective_match_keys(&args.match_by);

    let att_opts = ImageOptOptions::from_config(config, args.optimize, args.force);
    let cli_attachments = parse_attach_targets(&args.attach, &[])?;
    let mut all_attachments: Vec<AttachmentTarget> = Vec::new();
    for rec in &records {
        merge_unique_targets(&mut all_attachments, &rec.attachments);
    }
    merge_unique_targets(&mut all_attachments, &cli_attachments);
    validate_attachment_targets(&all_attachments, att_opts, err)?;

    if dry_run {
        let base_url = config.require_base_url()?;
        let mut previews = Vec::new();
        for rec in &records {
            let mut body = json!({
                "name": rec.name,
                "description": rec.description,
                "quantity": rec.quantity,
                "tags": rec.tags,
                "fields": rec.fields,
            });
            if args.fill_missing {
                if let Some(obj) = body.as_object_mut() {
                    obj.insert("fillMissing".to_string(), Value::Bool(true));
                }
            }
            if !args.match_by.is_empty() {
                if let Some(obj) = body.as_object_mut() {
                    let keys: Vec<String> = args.match_by.iter().map(ToString::to_string).collect();
                    obj.insert("matchBy".to_string(), json!(keys));
                }
            }
            if args.match_mode != MatchMode::Exact {
                if let Some(obj) = body.as_object_mut() {
                    obj.insert(
                        "matchMode".to_string(),
                        Value::String(args.match_mode.to_string()),
                    );
                }
            }
            if let Some(p) = rec.parent.as_ref().or(args.parent.as_ref()) {
                if let Some(obj) = body.as_object_mut() {
                    let val = match parse_dry_run_parent(p) {
                        Some(pid) => Value::String(pid),
                        None => Value::Null,
                    };
                    obj.insert("parentId".to_string(), val);
                }
            }
            if let Some(obj) = body.as_object_mut() {
                rec.insert_dry_run_meta(obj);
            }
            previews.push(HomeboxClient::build_dry_run(
                base_url,
                "POST",
                "entities",
                Some(body),
            ));
            let mut rec_attachments = rec.attachments.clone();
            merge_unique_targets(&mut rec_attachments, &cli_attachments);
            previews.extend(attachment_dry_run_previews(
                base_url,
                "<item-id>",
                &rec_attachments,
            ));
        }
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);

    let mut existing_entities: Vec<Entity> = if args.skip_existing || args.update_existing {
        let listed = client.list_entities(&ListEntitiesQuery::default(), true)?;
        if match_keys_need_hydration(&match_keys) {
            client.hydrate_entity_fields(listed)?
        } else {
            listed
        }
    } else {
        Vec::new()
    };

    let mut summary = ImportSummary {
        created: 0,
        updated: 0,
        skipped: 0,
        ids: Vec::new(),
    };

    for rec in records {
        let mut rec_attachments = rec.attachments.clone();
        merge_unique_targets(&mut rec_attachments, &cli_attachments);

        if args.skip_existing || args.update_existing {
            if let Some(idx) =
                find_matching_entity_index(&existing_entities, &rec, &match_keys, args.match_mode)
            {
                if args.skip_existing {
                    let existing = &existing_entities[idx];
                    writeln!(
                        err,
                        "skipping existing item '{}' ({})",
                        existing.name, existing.id
                    )?;
                    summary.skipped += 1;
                    continue;
                }
                if args.update_existing {
                    let tag_ids = resolver.resolve_tag_ids(&rec.tags, true)?;
                    let entity_type_id = match rec.entity_type {
                        Some(ref et) => Some(resolver.resolve_entity_type_id(et)?),
                        None => None,
                    };
                    let effective_parent = rec.parent.clone().or_else(|| args.parent.clone());
                    let parent_id = match effective_parent {
                        Some(ref p) => Some(resolver.resolve_parent_id(p)?),
                        None => None,
                    };
                    let patch = EntityPatch {
                        name: None,
                        description: rec.description,
                        quantity: rec.quantity,
                        entity_type_id,
                        parent_id,
                        tag_ids: if tag_ids.is_empty() {
                            None
                        } else {
                            Some(tag_ids)
                        },
                        purchase_price: rec.purchase_price,
                        purchase_date: rec.purchase_date,
                        purchase_from: rec.purchase_from,
                        archived: rec.archived,
                        insured: rec.insured,
                        lifetime_warranty: rec.lifetime_warranty,
                        warranty_expires: rec.warranty_expires,
                        warranty_details: rec.warranty_details,
                        sold_time: rec.sold_time,
                        sold_to: rec.sold_to,
                        sold_price: rec.sold_price,
                        sold_notes: rec.sold_notes,
                        fields: rec.fields,
                        fill_missing: args.fill_missing,
                        ..Default::default()
                    };
                    let mut updated = client.update_entity(&existing_entities[idx].id, &patch)?;
                    if !rec_attachments.is_empty() {
                        let (uploaded, _) = attach_targets_to_item(
                            &client,
                            &updated.id,
                            &updated.attachments,
                            &rec_attachments,
                            att_opts,
                            false,
                            err,
                        )?;
                        updated.attachments.extend(uploaded);
                    }
                    existing_entities[idx] = updated.clone();
                    summary.updated += 1;
                    summary.ids.push(updated.id);
                    continue;
                }
            }
        }

        let Some(name) = rec.name.filter(|s| !s.trim().is_empty()) else {
            writeln!(err, "warning: skipping import row without name")?;
            summary.skipped += 1;
            continue;
        };

        let tag_ids = resolver.resolve_tag_ids(&rec.tags, true)?;
        let entity_type_id = match rec.entity_type {
            Some(ref et) => Some(resolver.resolve_entity_type_id(et)?),
            None => None,
        };
        let effective_parent = rec.parent.clone().or_else(|| args.parent.clone());
        let parent_id = match effective_parent {
            Some(ref p) => resolver.resolve_parent_id(p)?,
            None => None,
        };

        let req = CreateEntityRequest {
            name,
            description: rec.description,
            quantity: rec.quantity,
            entity_type_id,
            parent_id,
            tag_ids,
            purchase_price: rec.purchase_price,
            purchase_date: rec.purchase_date,
            purchase_from: rec.purchase_from,
            archived: rec.archived,
            insured: rec.insured,
            lifetime_warranty: rec.lifetime_warranty,
            warranty_expires: rec.warranty_expires,
            warranty_details: rec.warranty_details,
            sold_time: rec.sold_time,
            sold_to: rec.sold_to,
            sold_price: rec.sold_price,
            sold_notes: rec.sold_notes,
            fields: rec.fields,
        };
        let mut created = client.create_entity(&req)?;
        if !rec_attachments.is_empty() {
            let (uploaded, _) = attach_targets_to_item(
                &client,
                &created.id,
                &created.attachments,
                &rec_attachments,
                att_opts,
                false,
                err,
            )?;
            created.attachments.extend(uploaded);
        }
        if args.skip_existing || args.update_existing {
            existing_entities.push(created.clone());
        }
        summary.created += 1;
        summary.ids.push(created.id);
    }

    if ctx.quiet {
        return write_quiet_ids(&summary.ids, out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&summary, ctx.select.as_deref(), out);
    }

    write_table_or_plain(
        &[
            "CREATED".to_string(),
            "UPDATED".to_string(),
            "SKIPPED".to_string(),
        ],
        &[vec![
            summary.created.to_string(),
            summary.updated.to_string(),
            summary.skipped.to_string(),
        ]],
        ctx.format,
        out,
    )
}

fn handle_dedup(
    args: &ItemDedupArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    let client = HomeboxClient::from_config(config)?;
    let entities = client.list_entities(&ListEntitiesQuery::default(), true)?;
    let clusters = dedup::find_duplicates(&entities, args.threshold);

    let should_delete = args.delete || args.merge;

    if dry_run && should_delete {
        let base_url = client.base_url();
        let mut previews: Vec<DryRunRequest> = Vec::new();
        for cluster in &clusters {
            if args.merge {
                previews.push(HomeboxClient::build_dry_run(
                    base_url,
                    "PUT",
                    &format!("entities/{}", cluster.keeper.id),
                    Some(json!({ "quantity": cluster.merged_quantity })),
                ));
            }
            for dup in &cluster.duplicates {
                previews.push(HomeboxClient::build_dry_run(
                    base_url,
                    "DELETE",
                    &format!("entities/{}", dup.id),
                    None,
                ));
            }
        }
        return write_dry_run(&previews, ctx, out);
    }

    let mut affected_ids = Vec::new();
    if should_delete && !dry_run {
        for cluster in &clusters {
            if args.merge {
                let patch = EntityPatch {
                    quantity: Some(cluster.merged_quantity),
                    ..Default::default()
                };
                client.update_entity(&cluster.keeper.id, &patch)?;
                writeln!(
                    err,
                    "merged quantity {} onto keeper '{}' ({})",
                    cluster.merged_quantity, cluster.keeper.name, cluster.keeper.id
                )?;
            }
            for dup in &cluster.duplicates {
                client.delete_entity(&dup.id)?;
                affected_ids.push(dup.id.clone());
                writeln!(err, "deleted duplicate '{}' ({})", dup.name, dup.id)?;
            }
        }
    } else {
        for cluster in &clusters {
            affected_ids.push(cluster.keeper.id.clone());
        }
    }

    if ctx.quiet {
        return write_quiet_ids(&affected_ids, out);
    }

    if ctx.format == OutputFormat::Json {
        return write_compact_json(&clusters, ctx.select.as_deref(), out);
    }

    if clusters.is_empty() {
        writeln!(out, "No duplicate items found.")?;
        return Ok(());
    }

    let headers = vec![
        "KIND".to_string(),
        "SIM".to_string(),
        "KEEPER".to_string(),
        "DUPLICATES".to_string(),
        "MERGED_QTY".to_string(),
    ];
    let rows: Vec<Vec<String>> = clusters
        .iter()
        .map(|c| {
            let dups = c
                .duplicates
                .iter()
                .map(|d| format!("{} ({})", d.name, d.id))
                .collect::<Vec<_>>()
                .join(", ");
            vec![
                c.match_kind.to_string(),
                format!("{:.2}", c.similarity),
                format!("{} ({})", c.keeper.name, c.keeper.id),
                dups,
                c.merged_quantity.to_string(),
            ]
        })
        .collect();

    write_table_or_plain(&headers, &rows, ctx.format, out)
}

fn log_move_result(
    err: &mut dyn Write,
    updated: &Entity,
    target_parent: Option<&str>,
) -> Result<()> {
    match target_parent {
        Some(pid) => writeln!(
            err,
            "moved item '{}' ({}) under {pid}",
            updated.name, updated.id
        )?,
        None => writeln!(err, "unparented item '{}' ({})", updated.name, updated.id)?,
    }
    Ok(())
}

fn handle_move(
    args: &ItemMoveArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    let (explicit_ids, dest_parent) = args.split_targets_and_destination()?;
    let selector = BulkSelector {
        ids: &explicit_ids,
        items_from: args.items_from.as_deref(),
        tag: args.tag.as_deref(),
        parent: args.parent.as_deref(),
        entity_type: args.entity_type.as_deref(),
    };

    if dry_run {
        let resolved = resolve_bulk_targets(&selector, None, config)?;
        let base_url = config.require_base_url()?;
        let patch = EntityPatch {
            parent_id: Some(parse_dry_run_parent(&dest_parent)),
            ..Default::default()
        };
        let patch_val = serde_json::to_value(&patch)?;
        let previews: Vec<DryRunRequest> = resolved
            .ids
            .iter()
            .map(|id| {
                HomeboxClient::build_dry_run(
                    base_url,
                    "PUT",
                    &format!("entities/{id}"),
                    Some(patch_val.clone()),
                )
            })
            .collect();
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let resolved = resolve_bulk_targets(&selector, Some(&client), config)?;

    if resolved.ids.is_empty() {
        if ctx.quiet {
            return write_quiet_ids(&[], out);
        }
        if ctx.format == OutputFormat::Json {
            return write_compact_json(
                &BulkMoveSummary {
                    moved: 0,
                    failed: 0,
                    ids: Vec::new(),
                    items: Vec::new(),
                    errors: Vec::new(),
                },
                ctx.select.as_deref(),
                out,
            );
        }
        writeln!(out, "No matching items to move.")?;
        return Ok(());
    }

    let mut resolver = Resolver::new(&client);
    let target_parent = resolver.resolve_parent_id(&dest_parent)?;

    if !resolved.is_bulk {
        let target_id = &resolved.ids[0];
        if target_parent.as_deref() == Some(target_id.as_str()) {
            return Err(HbctlError::InvalidInput(format!(
                "cannot move item '{target_id}' under itself"
            )));
        }

        let patch = EntityPatch {
            parent_id: Some(target_parent.clone()),
            ..Default::default()
        };
        let updated = client.update_entity(target_id, &patch)?;
        log_move_result(err, &updated, target_parent.as_deref())?;
        return render_entity(&updated, ctx, out);
    }

    let patch = EntityPatch {
        parent_id: Some(target_parent.clone()),
        ..Default::default()
    };
    let mut moved_items = Vec::new();
    let mut succeeded_ids = Vec::new();
    let mut errors = Vec::new();

    for id in &resolved.ids {
        if target_parent.as_deref() == Some(id.as_str()) {
            let msg = format!("cannot move item '{id}' under itself");
            writeln!(err, "error moving item '{id}': {msg}")?;
            errors.push(BulkItemError {
                id: id.clone(),
                error: msg,
            });
            continue;
        }
        match client.update_entity(id, &patch) {
            Ok(updated) => {
                log_move_result(err, &updated, target_parent.as_deref())?;
                succeeded_ids.push(updated.id.clone());
                moved_items.push(updated);
            }
            Err(e) => {
                writeln!(err, "error moving item '{id}': {e}")?;
                errors.push(BulkItemError {
                    id: id.clone(),
                    error: e.to_string(),
                });
            }
        }
    }

    if ctx.quiet {
        write_quiet_ids(&succeeded_ids, out)?;
    } else if ctx.format == OutputFormat::Json {
        let summary = BulkMoveSummary {
            moved: moved_items.len(),
            failed: errors.len(),
            ids: succeeded_ids.clone(),
            items: moved_items,
            errors: errors.clone(),
        };
        write_compact_json(&summary, ctx.select.as_deref(), out)?;
    } else if errors.is_empty() {
        render_entities(&moved_items, ctx, out)?;
    } else {
        render_bulk_status_table(&succeeded_ids, "moved", &errors, ctx.format, out)?;
    }

    check_bulk_partial_failure("move", succeeded_ids.len(), &errors)
}

fn handle_duplicate(
    args: &ItemDuplicateArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if args.count == 0 {
        return Err(HbctlError::InvalidInput(
            "--count must be at least 1".to_string(),
        ));
    }

    if dry_run {
        let base_url = config.require_base_url()?;
        let previews: Vec<DryRunRequest> = (0..args.count)
            .map(|_| {
                HomeboxClient::build_dry_run(
                    base_url,
                    "POST",
                    &format!("entities/{}/duplicate", args.id),
                    Some(json!({})),
                )
            })
            .collect();
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let mut created = Vec::with_capacity(args.count);
    for _ in 0..args.count {
        created.push(client.duplicate_entity(&args.id)?);
    }

    if created.len() == 1 {
        render_entity(&created[0], ctx, out)
    } else {
        render_entities(&created, ctx, out)
    }
}

fn handle_path(
    args: &ItemPathArgs,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let client = HomeboxClient::from_config(config)?;
    let entries = client.get_entity_path(&args.id)?;
    let breadcrumb = format_breadcrumb(&entries);

    if ctx.quiet {
        let ids: Vec<String> = entries.iter().map(|e| e.id.clone()).collect();
        return write_quiet_ids(&ids, out);
    }

    if ctx.format == OutputFormat::Json {
        return write_compact_json(
            &json!({
                "id": args.id,
                "breadcrumb": breadcrumb,
                "path": entries,
            }),
            ctx.select.as_deref(),
            out,
        );
    }

    if let Some(ref select) = ctx.select {
        return write_selected_table(&entries, select, ctx.format, out);
    }

    if ctx.format == OutputFormat::Plain {
        writeln!(out, "{breadcrumb}")?;
        return Ok(());
    }

    if entries.is_empty() {
        writeln!(out, "No path entries found.")?;
        return Ok(());
    }

    let headers = vec![
        "DEPTH".to_string(),
        "ID".to_string(),
        "NAME".to_string(),
        "TYPE".to_string(),
    ];
    let rows: Vec<Vec<String>> = entries
        .iter()
        .enumerate()
        .map(|(idx, e)| {
            vec![
                idx.to_string(),
                e.id.clone(),
                e.name.clone(),
                e.entry_type.clone().unwrap_or_default(),
            ]
        })
        .collect();

    write_table_or_plain(&headers, &rows, ctx.format, out)
}

#[derive(Debug, Clone, Serialize, PartialEq, Eq)]
#[serde(rename_all = "camelCase")]
struct TreeNode {
    id: String,
    name: String,
    quantity: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    parent_id: Option<String>,
    children: Vec<TreeNode>,
}

fn build_item_tree(
    entities: &[Entity],
    root: Option<&str>,
    max_depth: Option<usize>,
) -> Result<Vec<TreeNode>> {
    let mut by_id: HashMap<&str, &Entity> = HashMap::new();
    for e in entities {
        if !e.id.trim().is_empty() {
            by_id.insert(e.id.as_str(), e);
        }
    }

    let mut children_by_parent: HashMap<&str, Vec<&Entity>> = HashMap::new();
    for e in entities {
        if let Some(ref pid) = e.parent_id {
            let pid_trimmed = pid.trim();
            if !pid_trimmed.is_empty() && by_id.contains_key(pid_trimmed) {
                children_by_parent.entry(pid_trimmed).or_default().push(e);
            }
        }
    }
    for kids in children_by_parent.values_mut() {
        kids.sort_by(|a, b| {
            a.name
                .to_ascii_lowercase()
                .cmp(&b.name.to_ascii_lowercase())
                .then_with(|| a.id.cmp(&b.id))
        });
    }

    let mut visited = HashSet::new();

    if let Some(root_query) = root {
        let needle = root_query.trim();
        if needle.is_empty() {
            return Err(HbctlError::InvalidInput("root cannot be empty".to_string()));
        }
        let root_entity = entities
            .iter()
            .find(|e| e.id == needle)
            .or_else(|| {
                entities
                    .iter()
                    .find(|e| e.name.trim().eq_ignore_ascii_case(needle))
            })
            .ok_or_else(|| HbctlError::NotFound {
                kind: "item".to_string(),
                query: needle.to_string(),
            })?;
        return Ok(vec![build_tree_node(
            root_entity,
            &children_by_parent,
            0,
            max_depth,
            &mut visited,
        )]);
    }

    let mut root_entities: Vec<&Entity> = entities
        .iter()
        .filter(|e| match e.parent_id.as_deref() {
            None => true,
            Some(pid) => {
                let t = pid.trim();
                t.is_empty() || !by_id.contains_key(t)
            }
        })
        .collect();
    root_entities.sort_by(|a, b| {
        a.name
            .to_ascii_lowercase()
            .cmp(&b.name.to_ascii_lowercase())
            .then_with(|| a.id.cmp(&b.id))
    });

    if root_entities.is_empty() && !entities.is_empty() {
        let mut all: Vec<&Entity> = entities.iter().collect();
        all.sort_by(|a, b| {
            a.name
                .to_ascii_lowercase()
                .cmp(&b.name.to_ascii_lowercase())
                .then_with(|| a.id.cmp(&b.id))
        });
        let mut nodes = Vec::new();
        for e in all {
            if !visited.contains(e.id.as_str()) {
                nodes.push(build_tree_node(
                    e,
                    &children_by_parent,
                    0,
                    max_depth,
                    &mut visited,
                ));
            }
        }
        return Ok(nodes);
    }

    Ok(root_entities
        .into_iter()
        .map(|e| build_tree_node(e, &children_by_parent, 0, max_depth, &mut visited))
        .collect())
}

fn build_tree_node(
    entity: &Entity,
    children_by_parent: &HashMap<&str, Vec<&Entity>>,
    depth: usize,
    max_depth: Option<usize>,
    visited: &mut HashSet<String>,
) -> TreeNode {
    visited.insert(entity.id.clone());

    let mut children = Vec::new();
    let can_descend = match max_depth {
        Some(limit) => depth < limit,
        None => true,
    };
    if can_descend {
        if let Some(kids) = children_by_parent.get(entity.id.as_str()) {
            for kid in kids {
                if !visited.contains(kid.id.as_str()) {
                    children.push(build_tree_node(
                        kid,
                        children_by_parent,
                        depth + 1,
                        max_depth,
                        visited,
                    ));
                }
            }
        }
    }

    TreeNode {
        id: entity.id.clone(),
        name: entity.name.clone(),
        quantity: entity.quantity,
        parent_id: entity.parent_id.clone().filter(|p| !p.trim().is_empty()),
        children,
    }
}

fn collect_tree_ids(nodes: &[TreeNode], out: &mut Vec<String>) {
    for node in nodes {
        if !node.id.is_empty() {
            out.push(node.id.clone());
        }
        collect_tree_ids(&node.children, out);
    }
}

fn collect_tree_rows(nodes: &[TreeNode], depth: usize, out: &mut Vec<Vec<String>>) {
    for node in nodes {
        out.push(vec![
            node.id.clone(),
            node.parent_id.clone().unwrap_or_default(),
            depth.to_string(),
            node.name.clone(),
            node.quantity.to_string(),
        ]);
        collect_tree_rows(&node.children, depth + 1, out);
    }
}

fn render_tree_lines(nodes: &[TreeNode]) -> Vec<String> {
    fn walk_children(children: &[TreeNode], prefix: &str, lines: &mut Vec<String>) {
        for (idx, child) in children.iter().enumerate() {
            let is_last = idx + 1 == children.len();
            let connector = if is_last { "└── " } else { "├── " };
            lines.push(format!(
                "{prefix}{connector}{} ({}) [qty: {}]",
                child.name, child.id, child.quantity
            ));
            let child_prefix = format!("{prefix}{}", if is_last { "    " } else { "│   " });
            walk_children(&child.children, &child_prefix, lines);
        }
    }

    let mut lines = Vec::new();
    for root in nodes {
        lines.push(format!(
            "{} ({}) [qty: {}]",
            root.name, root.id, root.quantity
        ));
        walk_children(&root.children, "", &mut lines);
    }
    lines
}

fn handle_tree(
    args: &ItemTreeArgs,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let client = HomeboxClient::from_config(config)?;
    let entities = client.list_entities(&ListEntitiesQuery::default(), true)?;
    let roots = build_item_tree(&entities, args.root.as_deref(), args.max_depth)?;

    if ctx.quiet {
        let mut ids = Vec::new();
        collect_tree_ids(&roots, &mut ids);
        return write_quiet_ids(&ids, out);
    }

    if ctx.format == OutputFormat::Json {
        return write_compact_json(&roots, ctx.select.as_deref(), out);
    }

    if ctx.format == OutputFormat::Plain {
        let mut rows = Vec::new();
        collect_tree_rows(&roots, 0, &mut rows);
        return write_table_or_plain(
            &[
                "ID".to_string(),
                "PARENT_ID".to_string(),
                "DEPTH".to_string(),
                "NAME".to_string(),
                "QTY".to_string(),
            ],
            &rows,
            ctx.format,
            out,
        );
    }

    if roots.is_empty() {
        writeln!(out, "No items found.")?;
        return Ok(());
    }

    for line in render_tree_lines(&roots) {
        writeln!(out, "{line}")?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_entity(id: &str, name: &str, fields: Vec<CustomField>) -> Entity {
        Entity {
            id: id.into(),
            name: name.into(),
            quantity: 1,
            fields: Some(fields),
            ..Default::default()
        }
    }

    #[test]
    fn test_find_matching_entity_index_priority_and_fallback() {
        let candidates = vec![
            sample_entity(
                "ent-name-only",
                "Multimeter",
                vec![
                    CustomField::new_typed("Model Number", FieldValueType::Text, "OLD-M").unwrap(),
                    CustomField::new_typed("Serial Number", FieldValueType::Text, "SN-OTHER")
                        .unwrap(),
                ],
            ),
            sample_entity(
                "ent-model",
                "Other Meter",
                vec![
                    CustomField::new_typed("Model Number", FieldValueType::Text, "87V").unwrap(),
                    CustomField::new_typed("SKU", FieldValueType::Text, "SKU-87V").unwrap(),
                ],
            ),
            sample_entity(
                "ent-serial",
                "Bench Meter",
                vec![
                    CustomField::new_typed("Model Number", FieldValueType::Text, "87V").unwrap(),
                    CustomField::new_typed("Serial Number", FieldValueType::Text, "SN-999")
                        .unwrap(),
                ],
            ),
        ];

        // Priority: serial beats earlier name/model matches
        let input_serial = ParsedItemInput {
            name: Some("Multimeter".into()),
            fields: vec![
                CustomField::new_typed("Model Number", FieldValueType::Text, "87V").unwrap(),
                CustomField::new_typed("Serial Number", FieldValueType::Text, " sn-999 ").unwrap(),
            ],
            ..Default::default()
        };
        let keys = vec![MatchKey::Serial, MatchKey::Model, MatchKey::Name];
        assert_eq!(
            find_matching_entity_index(&candidates, &input_serial, &keys, MatchMode::Exact),
            Some(2)
        );

        // Fallback to model when serial does not match
        let input_model = ParsedItemInput {
            name: Some("Multimeter".into()),
            fields: vec![
                CustomField::new_typed("Model Number", FieldValueType::Text, "87v").unwrap(),
                CustomField::new_typed("Serial Number", FieldValueType::Text, "SN-MISSING")
                    .unwrap(),
            ],
            ..Default::default()
        };
        assert_eq!(
            find_matching_entity_index(&candidates, &input_model, &keys, MatchMode::Exact),
            Some(1)
        );

        // Fallback to name when neither serial nor model matches
        let input_name = ParsedItemInput {
            name: Some(" multimeter ".into()),
            fields: vec![
                CustomField::new_typed("Model Number", FieldValueType::Text, "99X").unwrap(),
            ],
            ..Default::default()
        };
        assert_eq!(
            find_matching_entity_index(&candidates, &input_name, &keys, MatchMode::Exact),
            Some(0)
        );

        // Custom field match ignores blank values
        let input_blank_sku = ParsedItemInput {
            fields: vec![CustomField::new_typed("SKU", FieldValueType::Text, "  ").unwrap()],
            ..Default::default()
        };
        assert_eq!(
            find_matching_entity_index(
                &candidates,
                &input_blank_sku,
                &[MatchKey::Field("SKU".into())],
                MatchMode::Exact
            ),
            None
        );

        let input_sku = ParsedItemInput {
            fields: vec![CustomField::new_typed("SKU", FieldValueType::Text, "sku-87v").unwrap()],
            ..Default::default()
        };
        assert_eq!(
            find_matching_entity_index(
                &candidates,
                &input_sku,
                &[MatchKey::Field("SKU".into())],
                MatchMode::Exact
            ),
            Some(1)
        );
    }

    #[test]
    fn test_find_matching_entity_index_contains_and_fuzzy() {
        let candidates = vec![
            sample_entity(
                "ent-lock-full",
                "Schlage Encode Plus Deadbolt",
                vec![
                    CustomField::new_typed("Model Number", FieldValueType::Text, "BE499WB CAM 716")
                        .unwrap(),
                    CustomField::new_typed(
                        "Notes",
                        FieldValueType::Text,
                        "Purchased on Amazon (ASIN: B08XYZ1234) front door",
                    )
                    .unwrap(),
                ],
            ),
            sample_entity(
                "ent-lock-exact",
                "Schlage Lock",
                vec![
                    CustomField::new_typed("Model Number", FieldValueType::Text, "BE499WB")
                        .unwrap(),
                ],
            ),
            sample_entity("ent-bme", "BME280 Breakout Board", vec![]),
            sample_entity("ent-other", "BME280 Pressure Temperature Humidity", vec![]),
        ];

        // Exact mode does NOT match substring
        let partial_model = ParsedItemInput {
            fields: vec![
                CustomField::new_typed("Model Number", FieldValueType::Text, "cam 716").unwrap(),
            ],
            ..Default::default()
        };
        assert_eq!(
            find_matching_entity_index(
                &candidates,
                &partial_model,
                &[MatchKey::Model],
                MatchMode::Exact
            ),
            None
        );
        // Contains mode matches case-insensitive substring
        assert_eq!(
            find_matching_entity_index(
                &candidates,
                &partial_model,
                &[MatchKey::Model],
                MatchMode::Contains
            ),
            Some(0)
        );

        // Exact hit wins over earlier substring hit in Contains mode
        let exact_model = ParsedItemInput {
            fields: vec![
                CustomField::new_typed("Model Number", FieldValueType::Text, "be499wb").unwrap(),
            ],
            ..Default::default()
        };
        assert_eq!(
            find_matching_entity_index(
                &candidates,
                &exact_model,
                &[MatchKey::Model],
                MatchMode::Contains
            ),
            Some(1)
        );

        // Contains mode matches ASIN inside custom field Notes
        let asin_notes = ParsedItemInput {
            fields: vec![
                CustomField::new_typed("Notes", FieldValueType::Text, "b08xyz1234").unwrap(),
            ],
            ..Default::default()
        };
        assert_eq!(
            find_matching_entity_index(
                &candidates,
                &asin_notes,
                &[MatchKey::Field("Notes".into())],
                MatchMode::Contains
            ),
            Some(0)
        );

        // Fuzzy mode matches via dedup::normalize_tokens + Jaccard similarity (>= 0.8)
        let fuzzy_bme = ParsedItemInput {
            name: Some("BME280 Sensor Module v2.1".into()),
            ..Default::default()
        };
        assert_eq!(
            find_matching_entity_index(
                &candidates,
                &fuzzy_bme,
                &[MatchKey::Name],
                MatchMode::Fuzzy
            ),
            Some(2)
        );

        // Below threshold returns None
        let unrelated = ParsedItemInput {
            name: Some("Fluke 87V Multimeter".into()),
            ..Default::default()
        };
        assert_eq!(
            find_matching_entity_index(
                &candidates,
                &unrelated,
                &[MatchKey::Name],
                MatchMode::Fuzzy
            ),
            None
        );

        // Stop-word-only input produces empty token set -> no false match
        let stop_words_only = ParsedItemInput {
            name: Some("Sensor Module Board".into()),
            ..Default::default()
        };
        assert_eq!(
            find_matching_entity_index(
                &candidates,
                &stop_words_only,
                &[MatchKey::Name],
                MatchMode::Fuzzy
            ),
            None
        );
    }

    #[test]
    fn test_build_item_tree_and_render_hierarchy() {
        let entity = |id: &str, name: &str, qty: i64, parent_id: Option<&str>| Entity {
            id: id.into(),
            name: name.into(),
            quantity: qty,
            parent_id: parent_id.map(ToOwned::to_owned),
            ..Default::default()
        };

        let entities = vec![
            entity("e-garage", "Garage", 1, None),
            entity("e-shelf", "Shelf A", 1, Some("e-garage")),
            entity("e-bin", "Bin B", 1, Some("e-garage")),
            entity("e-dmm", "Multimeter", 2, Some("e-shelf")),
            entity("e-orphan", "Orphan Tool", 1, Some("missing-parent")),
        ];

        let tree = build_item_tree(&entities, None, None).unwrap();
        assert_eq!(tree.len(), 2);
        assert_eq!(tree[0].name, "Garage");
        assert_eq!(tree[0].children.len(), 2);
        assert_eq!(tree[0].children[0].name, "Bin B");
        assert_eq!(tree[0].children[1].name, "Shelf A");
        assert_eq!(tree[0].children[1].children[0].name, "Multimeter");
        assert_eq!(tree[1].name, "Orphan Tool");

        let lines = render_tree_lines(&tree);
        assert_eq!(
            lines,
            vec![
                "Garage (e-garage) [qty: 1]".to_string(),
                "├── Bin B (e-bin) [qty: 1]".to_string(),
                "└── Shelf A (e-shelf) [qty: 1]".to_string(),
                "    └── Multimeter (e-dmm) [qty: 2]".to_string(),
                "Orphan Tool (e-orphan) [qty: 1]".to_string(),
            ]
        );

        // Root filter + max_depth
        let sub = build_item_tree(&entities, Some("Garage"), Some(1)).unwrap();
        assert_eq!(sub.len(), 1);
        assert_eq!(sub[0].children.len(), 2);
        assert!(sub[0].children[1].children.is_empty());

        assert!(build_item_tree(&entities, Some("NoSuchRoot"), None).is_err());

        // Cycle safety
        let cyclic = vec![
            entity("c1", "Node 1", 1, Some("c2")),
            entity("c2", "Node 2", 1, Some("c1")),
        ];
        let cyclic_tree = build_item_tree(&cyclic, None, None).unwrap();
        assert_eq!(cyclic_tree.len(), 1);
        assert_eq!(cyclic_tree[0].children.len(), 1);
        assert!(cyclic_tree[0].children[0].children.is_empty());
    }
}

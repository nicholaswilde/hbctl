use std::collections::{HashMap, HashSet};
use std::io::{self, IsTerminal, Write};
use std::path::PathBuf;

use serde::Serialize;
use serde_json::{json, Value};

use crate::cli::{
    ImportFormat, ItemArgs, ItemCommands, ItemCreateArgs, ItemDedupArgs, ItemDeleteArgs,
    ItemGetArgs, ItemImportArgs, ItemListArgs, ItemMoveArgs, ItemTreeArgs, ItemUpdateArgs,
    ItemUpsertArgs, MatchKey, MatchMode, OnMatchAction,
};
use crate::client::models::{
    normalize_json_aliases, upsert_custom_fields, CreateEntityRequest, CustomField, Entity,
    EntityPatch, FieldValueType,
};
use crate::client::resolve::Resolver;
use crate::client::{DryRunRequest, HomeboxClient, ListEntitiesQuery};
use crate::commands::attachment::{
    attach_targets_to_item, build_target_dry_run, parse_local_attachment_spec,
    parse_url_attachment_spec, validate_attachment_targets, AttachmentTarget,
};
use crate::commands::{read_file_or_stdin, render_entities, render_entity};
use crate::config::{AppConfig, OutputFormat};
use crate::dedup;
use crate::error::{HbctlError, Result};
use crate::image_opt::ImageOptOptions;
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_table_or_plain, OutputContext,
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
        ItemCommands::Update(a) => handle_update(a, dry_run, config, ctx, out),
        ItemCommands::Upsert(a) => handle_upsert(a, dry_run, config, ctx, out, err),
        ItemCommands::Delete(a) => handle_delete(a, dry_run, config, ctx, out, err),
        ItemCommands::Import(a) => handle_import(a, dry_run, config, ctx, out, err),
        ItemCommands::Dedup(a) => handle_dedup(a, dry_run, config, ctx, out, err),
        ItemCommands::Move(a) => handle_move(a, dry_run, config, ctx, out, err),
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

    let fetch_all = args.all || parent_filter.is_some();
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

    if let Some(ref key) = args.has_field {
        entities = client.hydrate_entity_fields(entities)?;
        entities.retain(|e| e.find_field(key).is_some() || e.field_value(key).is_some());
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
    render_entity(&entity, ctx, out)
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
    fields: Vec<CustomField>,
    attachments: Vec<AttachmentTarget>,
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
            description: parsed.description,
            quantity: parsed.quantity,
            entity_type_id: parsed.entity_type,
            parent_id: parsed.parent.as_deref().and_then(parse_dry_run_parent),
            tag_ids: parsed.tags,
            purchase_price: parsed.purchase_price,
            purchase_date: parsed.purchase_date,
            purchase_from: parsed.purchase_from,
            fields: parsed.fields.clone(),
        };
        let mut previews = vec![HomeboxClient::build_dry_run(
            base_url,
            "POST",
            "entities",
            Some(serde_json::to_value(&req_payload)?),
        )];
        if !parsed.fields.is_empty() {
            previews.push(HomeboxClient::build_dry_run(
                base_url,
                "PUT",
                "entities/<created-id>",
                Some(json!({ "fields": parsed.fields })),
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
            add_tag_ids: args.add_tags.clone(),
            remove_tag_ids: args.remove_tags.clone(),
            fields: parsed.fields,
            fill_missing: args.fill_missing,
            ..Default::default()
        };
        let preview = HomeboxClient::build_dry_run(
            base_url,
            "PUT",
            &format!("entities/{}", args.id),
            Some(serde_json::to_value(&patch)?),
        );
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
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
        add_tag_ids,
        remove_tag_ids,
        fields: parsed.fields,
        fill_missing: args.fill_missing,
        ..Default::default()
    };

    let updated = client.update_entity(&args.id, &patch)?;
    render_entity(&updated, ctx, out)
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
    if dry_run {
        let base_url = config.require_base_url()?;
        let preview = HomeboxClient::build_dry_run(
            base_url,
            "DELETE",
            &format!("entities/{}", args.id),
            None,
        );
        return write_dry_run(&[preview], ctx, out);
    }

    if !args.force && io::stdin().is_terminal() {
        write!(err, "Delete item '{}'? [y/N]: ", args.id)?;
        err.flush()?;
        let mut answer = String::new();
        io::stdin().read_line(&mut answer)?;
        if !matches!(answer.trim().to_ascii_lowercase().as_str(), "y" | "yes") {
            writeln!(err, "Aborted.")?;
            return Ok(());
        }
    }

    let client = HomeboxClient::from_config(config)?;
    client.delete_entity(&args.id)?;

    if ctx.quiet {
        return write_quiet_ids(std::slice::from_ref(&args.id), out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(
            &json!({ "id": args.id, "deleted": true }),
            ctx.select.as_deref(),
            out,
        );
    }
    writeln!(out, "Deleted item {}", args.id)?;
    Ok(())
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
            match header.to_ascii_lowercase().as_str() {
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
                "tags" | "tag" => {
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
                "purchasedate" | "purchase_date" => item.purchase_date = Some(val.to_string()),
                "purchasefrom" | "purchase_from" => item.purchase_from = Some(val.to_string()),
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

fn handle_move(
    args: &ItemMoveArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let patch = EntityPatch {
            parent_id: Some(parse_dry_run_parent(&args.parent)),
            ..Default::default()
        };
        let preview = HomeboxClient::build_dry_run(
            base_url,
            "PUT",
            &format!("entities/{}", args.id),
            Some(serde_json::to_value(&patch)?),
        );
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);
    let target_parent = resolver.resolve_parent_id(&args.parent)?;

    if target_parent.as_deref() == Some(args.id.as_str()) {
        return Err(HbctlError::InvalidInput(format!(
            "cannot move item '{}' under itself",
            args.id
        )));
    }

    let patch = EntityPatch {
        parent_id: Some(target_parent.clone()),
        ..Default::default()
    };
    let updated = client.update_entity(&args.id, &patch)?;

    match target_parent {
        Some(ref pid) => writeln!(
            err,
            "moved item '{}' ({}) under {pid}",
            updated.name, updated.id
        )?,
        None => writeln!(err, "unparented item '{}' ({})", updated.name, updated.id)?,
    }

    render_entity(&updated, ctx, out)
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

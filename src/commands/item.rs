use std::collections::HashMap;
use std::io::{self, IsTerminal, Write};

use serde::Serialize;
use serde_json::{json, Value};

use crate::cli::{
    ImportFormat, ItemArgs, ItemCommands, ItemCreateArgs, ItemDedupArgs, ItemDeleteArgs,
    ItemGetArgs, ItemImportArgs, ItemListArgs, ItemUpdateArgs, ItemUpsertArgs,
};
use crate::client::models::{
    normalize_json_aliases, upsert_custom_fields, CreateEntityRequest, CustomField, Entity,
    EntityPatch, FieldValueType,
};
use crate::client::resolve::Resolver;
use crate::client::{DryRunRequest, HomeboxClient, ListEntitiesQuery};
use crate::commands::{read_file_or_stdin, render_entities, render_entity};
use crate::config::{AppConfig, OutputFormat};
use crate::dedup;
use crate::error::{HbctlError, Result};
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
        ItemCommands::Create(a) => handle_create(a, dry_run, config, ctx, out),
        ItemCommands::Update(a) => handle_update(a, dry_run, config, ctx, out),
        ItemCommands::Upsert(a) => handle_upsert(a, dry_run, config, ctx, out),
        ItemCommands::Delete(a) => handle_delete(a, dry_run, config, ctx, out, err),
        ItemCommands::Import(a) => handle_import(a, dry_run, config, ctx, out, err),
        ItemCommands::Dedup(a) => handle_dedup(a, dry_run, config, ctx, out, err),
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

    let mut entities = client.list_entities(&query, args.all)?;

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
    tags: Vec<String>,
    purchase_price: Option<f64>,
    purchase_date: Option<String>,
    purchase_from: Option<String>,
    fields: Vec<CustomField>,
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
        args.notes.as_deref(),
        &args.fields,
        args.field_type,
    )?;

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
            parent_id: None,
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
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);

    let tag_ids = resolver.resolve_tag_ids(&parsed.tags, true)?;
    let entity_type_id = match parsed.entity_type {
        Some(ref et) => Some(resolver.resolve_entity_type_id(et)?),
        None => None,
    };

    let req = CreateEntityRequest {
        name,
        description: parsed.description,
        quantity: parsed.quantity,
        entity_type_id,
        parent_id: None,
        tag_ids,
        purchase_price: parsed.purchase_price,
        purchase_date: parsed.purchase_date,
        purchase_from: parsed.purchase_from,
        fields: parsed.fields,
    };

    let created = client.create_entity(&req)?;
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
            tag_ids: if parsed.tags.is_empty() {
                None
            } else {
                Some(parsed.tags)
            },
            purchase_price: parsed.purchase_price,
            purchase_date: parsed.purchase_date,
            purchase_from: parsed.purchase_from,
            fields: parsed.fields,
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
    let entity_type_id = match parsed.entity_type {
        Some(ref et) => Some(resolver.resolve_entity_type_id(et)?),
        None => None,
    };

    let patch = EntityPatch {
        name: parsed.name,
        description: parsed.description,
        quantity: parsed.quantity,
        entity_type_id,
        tag_ids,
        purchase_price: parsed.purchase_price,
        purchase_date: parsed.purchase_date,
        purchase_from: parsed.purchase_from,
        fields: parsed.fields,
    };

    let updated = client.update_entity(&args.id, &patch)?;
    render_entity(&updated, ctx, out)
}

fn handle_upsert(
    args: &ItemUpsertArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let mut fields = Vec::new();
    append_alias_and_cli_fields(
        &mut fields,
        args.manufacturer.as_deref(),
        args.model.as_deref(),
        args.notes.as_deref(),
        &args.fields,
        args.field_type,
    )?;

    if dry_run {
        let base_url = config.require_base_url()?;
        let body = json!({
            "action": "upsert",
            "name": args.name,
            "description": args.description,
            "quantity": args.quantity,
            "tags": args.tags,
            "fields": fields,
        });
        let preview = HomeboxClient::build_dry_run(base_url, "POST", "entities", Some(body));
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);

    let tag_ids = resolver.resolve_tag_ids(&args.tags, true)?;
    let entity_type_id = match args.entity_type {
        Some(ref et) => Some(resolver.resolve_entity_type_id(et)?),
        None => None,
    };

    // Look up existing entity by trimmed case-insensitive name
    let query = ListEntitiesQuery {
        query: Some(args.name.clone()),
        ..Default::default()
    };
    let candidates = client.list_entities(&query, true)?;
    let existing = candidates
        .into_iter()
        .find(|e| e.name.trim().eq_ignore_ascii_case(args.name.trim()));

    let result = if let Some(found) = existing {
        let patch = EntityPatch {
            name: None,
            description: args.description.clone(),
            quantity: args.quantity,
            entity_type_id,
            tag_ids: if tag_ids.is_empty() {
                None
            } else {
                Some(tag_ids)
            },
            purchase_price: args.purchase_price,
            purchase_date: args.purchase_date.clone(),
            purchase_from: args.purchase_from.clone(),
            fields,
        };
        client.update_entity(&found.id, &patch)?
    } else {
        let req = CreateEntityRequest {
            name: args.name.clone(),
            description: args.description.clone(),
            quantity: args.quantity,
            entity_type_id,
            parent_id: None,
            tag_ids,
            purchase_price: args.purchase_price,
            purchase_date: args.purchase_date.clone(),
            purchase_from: args.purchase_from.clone(),
            fields,
        };
        client.create_entity(&req)?
    };

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

    if dry_run {
        let base_url = config.require_base_url()?;
        let mut previews = Vec::new();
        for rec in &records {
            let body = json!({
                "name": rec.name,
                "description": rec.description,
                "quantity": rec.quantity,
                "tags": rec.tags,
                "fields": rec.fields,
            });
            previews.push(HomeboxClient::build_dry_run(
                base_url,
                "POST",
                "entities",
                Some(body),
            ));
        }
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);

    let mut existing_by_name: HashMap<String, Entity> = HashMap::new();
    if args.skip_existing || args.update_existing {
        let existing = client.list_entities(&ListEntitiesQuery::default(), true)?;
        for e in existing {
            existing_by_name.insert(e.name.trim().to_ascii_lowercase(), e);
        }
    }

    let mut summary = ImportSummary {
        created: 0,
        updated: 0,
        skipped: 0,
        ids: Vec::new(),
    };

    for rec in records {
        let Some(name) = rec.name.filter(|s| !s.trim().is_empty()) else {
            writeln!(err, "warning: skipping import row without name")?;
            summary.skipped += 1;
            continue;
        };
        let key = name.trim().to_ascii_lowercase();

        let tag_ids = resolver.resolve_tag_ids(&rec.tags, true)?;
        let entity_type_id = match rec.entity_type {
            Some(ref et) => Some(resolver.resolve_entity_type_id(et)?),
            None => None,
        };

        if let Some(existing) = existing_by_name.get(&key) {
            if args.skip_existing {
                writeln!(err, "skipping existing item '{name}' ({})", existing.id)?;
                summary.skipped += 1;
                continue;
            }
            if args.update_existing {
                let patch = EntityPatch {
                    name: None,
                    description: rec.description,
                    quantity: rec.quantity,
                    entity_type_id,
                    tag_ids: if tag_ids.is_empty() {
                        None
                    } else {
                        Some(tag_ids)
                    },
                    purchase_price: rec.purchase_price,
                    purchase_date: rec.purchase_date,
                    purchase_from: rec.purchase_from,
                    fields: rec.fields,
                };
                let updated = client.update_entity(&existing.id, &patch)?;
                summary.updated += 1;
                summary.ids.push(updated.id);
                continue;
            }
        }

        let req = CreateEntityRequest {
            name: name.clone(),
            description: rec.description,
            quantity: rec.quantity,
            entity_type_id,
            parent_id: None,
            tag_ids,
            purchase_price: rec.purchase_price,
            purchase_date: rec.purchase_date,
            purchase_from: rec.purchase_from,
            fields: rec.fields,
        };
        let created = client.create_entity(&req)?;
        if args.skip_existing || args.update_existing {
            existing_by_name.insert(key, created.clone());
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

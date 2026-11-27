use std::io::{self, IsTerminal, Write};

use serde_json::{json, Map, Value};

use crate::cli::{TemplateArgs, TemplateCommands};
use crate::client::models::{
    upsert_custom_fields, ApplyTemplateRequest, CustomField, EntityTemplate, FieldValueType,
    UpsertTemplateRequest,
};
use crate::client::resolve::Resolver;
use crate::client::HomeboxClient;
use crate::commands::render_entity;
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

pub fn handle(
    args: &TemplateArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    match &args.command {
        TemplateCommands::List => handle_list(dry_run, config, ctx, out),
        TemplateCommands::Get { id } => handle_get(id, dry_run, config, ctx, out),
        TemplateCommands::Create(create_args) => {
            handle_create(create_args, dry_run, config, ctx, out)
        }
        TemplateCommands::Update(update_args) => {
            handle_update(update_args, dry_run, config, ctx, out)
        }
        TemplateCommands::Delete { id, yes, force } => {
            handle_delete(id, *yes || *force, dry_run, config, ctx, out, err)
        }
        TemplateCommands::Apply(apply_args) => handle_apply(apply_args, dry_run, config, ctx, out),
    }
}

fn parse_template_fields(specs: &[String], kind: FieldValueType) -> Result<Vec<CustomField>> {
    let mut fields = Vec::new();
    for spec in specs {
        let cf = CustomField::parse_key_value(spec, kind)?;
        upsert_custom_fields(&mut fields, &[cf]);
    }
    Ok(fields)
}

fn render_template(tpl: &EntityTemplate, ctx: &OutputContext, out: &mut dyn Write) -> Result<()> {
    if ctx.quiet {
        return write_quiet_ids(std::slice::from_ref(&tpl.id), out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(tpl, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(std::slice::from_ref(tpl), select, ctx.format, out);
    }

    let mut rows = vec![
        vec!["id".to_string(), tpl.id.clone()],
        vec!["name".to_string(), tpl.name.clone()],
    ];
    if !tpl.description.is_empty() {
        rows.push(vec!["description".to_string(), tpl.description.clone()]);
    }
    if !tpl.notes.is_empty() {
        rows.push(vec!["notes".to_string(), tpl.notes.clone()]);
    }
    if !tpl.default_name.is_empty() {
        rows.push(vec!["defaultName".to_string(), tpl.default_name.clone()]);
    }
    if !tpl.default_description.is_empty() {
        rows.push(vec![
            "defaultDescription".to_string(),
            tpl.default_description.clone(),
        ]);
    }
    if tpl.default_quantity != 0.0 {
        rows.push(vec![
            "defaultQuantity".to_string(),
            tpl.default_quantity.to_string(),
        ]);
    }
    if !tpl.default_manufacturer.is_empty() {
        rows.push(vec![
            "defaultManufacturer".to_string(),
            tpl.default_manufacturer.clone(),
        ]);
    }
    if !tpl.default_model_number.is_empty() {
        rows.push(vec![
            "defaultModelNumber".to_string(),
            tpl.default_model_number.clone(),
        ]);
    }
    rows.push(vec![
        "defaultInsured".to_string(),
        tpl.default_insured.to_string(),
    ]);
    rows.push(vec![
        "defaultLifetimeWarranty".to_string(),
        tpl.default_lifetime_warranty.to_string(),
    ]);
    if !tpl.default_warranty_details.is_empty() {
        rows.push(vec![
            "defaultWarrantyDetails".to_string(),
            tpl.default_warranty_details.clone(),
        ]);
    }
    if let Some(ref loc) = tpl.default_location {
        let label = if loc.name.is_empty() {
            loc.id.clone()
        } else {
            format!("{} ({})", loc.name, loc.id)
        };
        rows.push(vec!["defaultLocation".to_string(), label]);
    }
    if !tpl.default_tags.is_empty() {
        let tags_csv = tpl
            .default_tags
            .iter()
            .map(|t| {
                if t.name.is_empty() {
                    t.id.as_str()
                } else {
                    t.name.as_str()
                }
            })
            .collect::<Vec<_>>()
            .join(", ");
        rows.push(vec!["defaultTags".to_string(), tags_csv]);
    }
    rows.push(vec![
        "includeWarrantyFields".to_string(),
        tpl.include_warranty_fields.to_string(),
    ]);
    rows.push(vec![
        "includePurchaseFields".to_string(),
        tpl.include_purchase_fields.to_string(),
    ]);
    rows.push(vec![
        "includeSoldFields".to_string(),
        tpl.include_sold_fields.to_string(),
    ]);
    for field in &tpl.fields {
        rows.push(vec![format!("field:{}", field.name), field.display_value()]);
    }

    write_table_or_plain(
        &["PROPERTY".to_string(), "VALUE".to_string()],
        &rows,
        ctx.format,
        out,
    )
}

fn handle_list(
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let preview = HomeboxClient::build_dry_run(base_url, "GET", "templates", None);
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let templates = client.list_templates()?;

    if ctx.quiet {
        let ids: Vec<String> = templates.iter().map(|t| t.id.clone()).collect();
        return write_quiet_ids(&ids, out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&templates, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&templates, select, ctx.format, out);
    }

    let headers = vec![
        "ID".to_string(),
        "NAME".to_string(),
        "DESCRIPTION".to_string(),
        "UPDATED".to_string(),
    ];
    let rows: Vec<Vec<String>> = templates
        .iter()
        .map(|t| {
            vec![
                t.id.clone(),
                t.name.clone(),
                t.description.clone(),
                t.updated_at.clone(),
            ]
        })
        .collect();
    write_table_or_plain(&headers, &rows, ctx.format, out)
}

fn handle_get(
    id: &str,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let preview =
            HomeboxClient::build_dry_run(base_url, "GET", &format!("templates/{id}"), None);
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let tpl = client.get_template(id)?;
    render_template(&tpl, ctx, out)
}

fn handle_create(
    args: &crate::cli::TemplateCreateArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if args.name.trim().is_empty() {
        return Err(HbctlError::InvalidInput(
            "template --name cannot be empty".to_string(),
        ));
    }
    let fields = parse_template_fields(&args.fields, args.field_type)?;

    let build_request = |default_location_id: Option<String>,
                         default_tag_ids: Option<Vec<String>>| {
        UpsertTemplateRequest {
            id: None,
            name: args.name.clone(),
            description: args.description.clone().unwrap_or_default(),
            notes: args.notes.clone().unwrap_or_default(),
            default_name: args.default_name.clone(),
            default_description: args.default_description.clone(),
            default_quantity: args.default_quantity,
            default_insured: args.default_insured.unwrap_or(false),
            default_manufacturer: args.default_manufacturer.clone(),
            default_model_number: args.default_model.clone(),
            default_lifetime_warranty: args.default_lifetime_warranty.unwrap_or(false),
            default_warranty_details: args.default_warranty_details.clone(),
            default_location_id,
            default_tag_ids,
            include_warranty_fields: args.include_warranty_fields.unwrap_or(false),
            include_purchase_fields: args.include_purchase_fields.unwrap_or(false),
            include_sold_fields: args.include_sold_fields.unwrap_or(false),
            fields: fields.clone(),
        }
    };

    if dry_run {
        let base_url = config.require_base_url()?;
        let dry_tags = (!args.default_tags.is_empty()).then(|| args.default_tags.clone());
        let req = build_request(args.default_location.clone(), dry_tags);
        let preview = HomeboxClient::build_dry_run(
            base_url,
            "POST",
            "templates",
            Some(serde_json::to_value(&req)?),
        );
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);
    let default_location_id = match args.default_location {
        Some(ref loc) => resolver.resolve_parent_id(loc)?,
        None => None,
    };
    let default_tag_ids = if args.default_tags.is_empty() {
        None
    } else {
        Some(resolver.resolve_tag_ids(&args.default_tags, true)?)
    };

    let req = build_request(default_location_id, default_tag_ids);
    let created = client.create_template(&req)?;
    render_template(&created, ctx, out)
}

fn handle_update(
    args: &crate::cli::TemplateUpdateArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let has_change = args.name.is_some()
        || args.description.is_some()
        || args.notes.is_some()
        || args.default_name.is_some()
        || args.default_description.is_some()
        || args.default_quantity.is_some()
        || args.default_manufacturer.is_some()
        || args.default_model.is_some()
        || args.default_insured.is_some()
        || args.default_lifetime_warranty.is_some()
        || args.default_warranty_details.is_some()
        || args.default_location.is_some()
        || !args.default_tags.is_empty()
        || args.include_warranty_fields.is_some()
        || args.include_purchase_fields.is_some()
        || args.include_sold_fields.is_some()
        || !args.fields.is_empty();

    if !has_change {
        return Err(HbctlError::InvalidInput(
            "template update requires at least one field flag".to_string(),
        ));
    }

    if let Some(ref name) = args.name {
        if name.trim().is_empty() {
            return Err(HbctlError::InvalidInput(
                "template --name cannot be empty".to_string(),
            ));
        }
    }

    let parsed_fields = parse_template_fields(&args.fields, args.field_type)?;

    if dry_run {
        let base_url = config.require_base_url()?;
        let mut body = Map::new();
        if let Some(ref v) = args.name {
            body.insert("name".to_string(), json!(v));
        }
        if let Some(ref v) = args.description {
            body.insert("description".to_string(), json!(v));
        }
        if let Some(ref v) = args.notes {
            body.insert("notes".to_string(), json!(v));
        }
        if let Some(ref v) = args.default_name {
            body.insert("defaultName".to_string(), json!(v));
        }
        if let Some(ref v) = args.default_description {
            body.insert("defaultDescription".to_string(), json!(v));
        }
        if let Some(v) = args.default_quantity {
            body.insert("defaultQuantity".to_string(), json!(v));
        }
        if let Some(ref v) = args.default_manufacturer {
            body.insert("defaultManufacturer".to_string(), json!(v));
        }
        if let Some(ref v) = args.default_model {
            body.insert("defaultModelNumber".to_string(), json!(v));
        }
        if let Some(v) = args.default_insured {
            body.insert("defaultInsured".to_string(), json!(v));
        }
        if let Some(v) = args.default_lifetime_warranty {
            body.insert("defaultLifetimeWarranty".to_string(), json!(v));
        }
        if let Some(ref v) = args.default_warranty_details {
            body.insert("defaultWarrantyDetails".to_string(), json!(v));
        }
        if let Some(ref v) = args.default_location {
            body.insert("defaultLocationId".to_string(), json!(v));
        }
        if !args.default_tags.is_empty() {
            body.insert("defaultTagIds".to_string(), json!(args.default_tags));
        }
        if let Some(v) = args.include_warranty_fields {
            body.insert("includeWarrantyFields".to_string(), json!(v));
        }
        if let Some(v) = args.include_purchase_fields {
            body.insert("includePurchaseFields".to_string(), json!(v));
        }
        if let Some(v) = args.include_sold_fields {
            body.insert("includeSoldFields".to_string(), json!(v));
        }
        if !parsed_fields.is_empty() {
            body.insert("fields".to_string(), serde_json::to_value(&parsed_fields)?);
        }
        let preview = HomeboxClient::build_dry_run(
            base_url,
            "PUT",
            &format!("templates/{}", args.id),
            Some(Value::Object(body)),
        );
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let existing = client.get_template(&args.id)?;
    let mut req = existing.to_update_request();
    req.id = Some(args.id.clone());

    if let Some(ref v) = args.name {
        req.name = v.clone();
    }
    if let Some(ref v) = args.description {
        req.description = v.clone();
    }
    if let Some(ref v) = args.notes {
        req.notes = v.clone();
    }
    if let Some(ref v) = args.default_name {
        req.default_name = Some(v.clone());
    }
    if let Some(ref v) = args.default_description {
        req.default_description = Some(v.clone());
    }
    if let Some(v) = args.default_quantity {
        req.default_quantity = Some(v);
    }
    if let Some(ref v) = args.default_manufacturer {
        req.default_manufacturer = Some(v.clone());
    }
    if let Some(ref v) = args.default_model {
        req.default_model_number = Some(v.clone());
    }
    if let Some(v) = args.default_insured {
        req.default_insured = v;
    }
    if let Some(v) = args.default_lifetime_warranty {
        req.default_lifetime_warranty = v;
    }
    if let Some(ref v) = args.default_warranty_details {
        req.default_warranty_details = Some(v.clone());
    }
    if let Some(v) = args.include_warranty_fields {
        req.include_warranty_fields = v;
    }
    if let Some(v) = args.include_purchase_fields {
        req.include_purchase_fields = v;
    }
    if let Some(v) = args.include_sold_fields {
        req.include_sold_fields = v;
    }
    if !parsed_fields.is_empty() {
        upsert_custom_fields(&mut req.fields, &parsed_fields);
    }

    let mut resolver = Resolver::new(&client);
    if let Some(ref loc) = args.default_location {
        req.default_location_id = resolver.resolve_parent_id(loc)?;
    }
    if !args.default_tags.is_empty() {
        req.default_tag_ids = Some(resolver.resolve_tag_ids(&args.default_tags, true)?);
    }

    let updated = client.update_template(&args.id, &req)?;
    render_template(&updated, ctx, out)
}

fn handle_delete(
    id: &str,
    skip_confirm: bool,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let preview =
            HomeboxClient::build_dry_run(base_url, "DELETE", &format!("templates/{id}"), None);
        return write_dry_run(&[preview], ctx, out);
    }

    if !skip_confirm && io::stdin().is_terminal() {
        write!(err, "Delete template '{id}'? [y/N]: ")?;
        err.flush()?;
        let mut answer = String::new();
        io::stdin().read_line(&mut answer)?;
        if !matches!(answer.trim().to_ascii_lowercase().as_str(), "y" | "yes") {
            writeln!(err, "Aborted.")?;
            return Ok(());
        }
    }

    let client = HomeboxClient::from_config(config)?;
    client.delete_template(id)?;

    if ctx.quiet {
        return write_quiet_ids(std::slice::from_ref(&id.to_string()), out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(
            &json!({ "id": id, "deleted": true }),
            ctx.select.as_deref(),
            out,
        );
    }
    writeln!(out, "Deleted template {id}")?;
    Ok(())
}

fn handle_apply(
    args: &crate::cli::TemplateApplyArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let req = ApplyTemplateRequest {
            name: args
                .name
                .clone()
                .unwrap_or_else(|| "<from-template>".to_string()),
            description: args.description.clone().unwrap_or_default(),
            parent_id: args.parent.clone(),
            location_id: args.location.clone(),
            entity_type_id: args.entity_type.clone(),
            tag_ids: args.tags.clone(),
            quantity: args.quantity,
        };
        let preview = HomeboxClient::build_dry_run(
            base_url,
            "POST",
            &format!("templates/{}/create-item", args.id),
            Some(serde_json::to_value(&req)?),
        );
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let needs_template = args.name.is_none()
        || args.description.is_none()
        || (args.parent.is_none() && args.location.is_none())
        || args.tags.is_empty();
    let tpl = if needs_template {
        Some(client.get_template(&args.id)?)
    } else {
        None
    };

    let name = args
        .name
        .clone()
        .or_else(|| {
            tpl.as_ref()
                .map(|t| t.default_name.clone())
                .filter(|s| !s.trim().is_empty())
        })
        .ok_or_else(|| {
            HbctlError::InvalidInput(
                "item name is required (pass --name or set defaultName on template)".to_string(),
            )
        })?;

    let description = args
        .description
        .clone()
        .or_else(|| tpl.as_ref().map(|t| t.default_description.clone()))
        .unwrap_or_default();

    let mut resolver = Resolver::new(&client);
    let parent_id = match args.parent {
        Some(ref p) => resolver.resolve_parent_id(p)?,
        None => None,
    };
    let location_id = match args.location {
        Some(ref loc) => resolver.resolve_parent_id(loc)?,
        None if args.parent.is_none() => tpl
            .as_ref()
            .and_then(|t| t.default_location.as_ref())
            .map(|l| l.id.clone())
            .filter(|s| !s.trim().is_empty()),
        None => None,
    };
    let entity_type_id = match args.entity_type {
        Some(ref et) => Some(resolver.resolve_entity_type_id(et)?),
        None => None,
    };
    let tag_ids = if !args.tags.is_empty() {
        resolver.resolve_tag_ids(&args.tags, true)?
    } else {
        tpl.as_ref()
            .map(|t| {
                t.default_tags
                    .iter()
                    .map(|tag| tag.id.clone())
                    .filter(|s| !s.trim().is_empty())
                    .collect()
            })
            .unwrap_or_default()
    };

    let req = ApplyTemplateRequest {
        name,
        description,
        parent_id,
        location_id,
        entity_type_id,
        tag_ids,
        quantity: args.quantity,
    };

    let created = client.apply_template(&args.id, &req)?;
    render_entity(&created, ctx, out)
}

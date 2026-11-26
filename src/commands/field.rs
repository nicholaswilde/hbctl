use std::io::Write;

use serde_json::json;

use crate::cli::{FieldArgs, FieldCommands};
use crate::client::models::{merge_entity_patch, CustomField, EntityPatch};
use crate::client::HomeboxClient;
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

pub fn handle(
    args: &FieldArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    _err: &mut dyn Write,
) -> Result<()> {
    match &args.command {
        FieldCommands::List { item_id } => {
            let client = HomeboxClient::from_config(config)?;
            let entity = client.get_entity(item_id)?;
            let fields = entity.fields_slice();

            if ctx.quiet {
                let names: Vec<String> = fields.iter().map(|f| f.name.clone()).collect();
                return write_quiet_ids(&names, out);
            }
            if ctx.format == OutputFormat::Json {
                return write_compact_json(&fields, ctx.select.as_deref(), out);
            }
            if let Some(ref select) = ctx.select {
                return write_selected_table(fields, select, ctx.format, out);
            }

            let headers = vec!["NAME".to_string(), "TYPE".to_string(), "VALUE".to_string()];
            let rows: Vec<Vec<String>> = fields
                .iter()
                .map(|f| vec![f.name.clone(), f.field_type.clone(), f.display_value()])
                .collect();
            write_table_or_plain(&headers, &rows, ctx.format, out)
        }

        FieldCommands::Get { item_id, key } => {
            let client = HomeboxClient::from_config(config)?;
            let entity = client.get_entity(item_id)?;

            if let Some(field) = entity.find_field(key) {
                if ctx.quiet || ctx.format == OutputFormat::Plain {
                    writeln!(out, "{}", field.display_value())?;
                    return Ok(());
                }
                if ctx.format == OutputFormat::Json {
                    return write_compact_json(field, ctx.select.as_deref(), out);
                }
                return write_table_or_plain(
                    &["NAME".to_string(), "TYPE".to_string(), "VALUE".to_string()],
                    &[vec![
                        field.name.clone(),
                        field.field_type.clone(),
                        field.display_value(),
                    ]],
                    ctx.format,
                    out,
                );
            }

            if let Some(fallback) = entity.field_value(key) {
                if ctx.quiet || ctx.format == OutputFormat::Plain {
                    writeln!(out, "{fallback}")?;
                    return Ok(());
                }
                if ctx.format == OutputFormat::Json {
                    return write_compact_json(
                        &json!({ "name": key, "type": "text", "value": fallback }),
                        ctx.select.as_deref(),
                        out,
                    );
                }
                return write_table_or_plain(
                    &["NAME".to_string(), "TYPE".to_string(), "VALUE".to_string()],
                    &[vec![key.clone(), "text".to_string(), fallback]],
                    ctx.format,
                    out,
                );
            }

            Err(HbctlError::NotFound {
                kind: "field".to_string(),
                query: key.clone(),
            })
        }

        FieldCommands::Set {
            item_id,
            key,
            value,
            field_type,
        } => {
            let cf = CustomField::new_typed(key, *field_type, value)?;

            if dry_run {
                let base_url = config.require_base_url()?;
                let preview = HomeboxClient::build_dry_run(
                    base_url,
                    "PUT",
                    &format!("entities/{item_id}"),
                    Some(json!({ "fields": [cf] })),
                );
                return write_dry_run(&[preview], ctx, out);
            }

            let client = HomeboxClient::from_config(config)?;
            let patch = EntityPatch {
                fields: vec![cf.clone()],
                ..Default::default()
            };
            let updated = client.update_entity(item_id, &patch)?;

            if ctx.quiet {
                return write_quiet_ids(std::slice::from_ref(&updated.id), out);
            }
            if ctx.format == OutputFormat::Json {
                let stored = updated.find_field(key).unwrap_or(&cf);
                return write_compact_json(stored, ctx.select.as_deref(), out);
            }

            write_table_or_plain(
                &[
                    "ITEM_ID".to_string(),
                    "NAME".to_string(),
                    "TYPE".to_string(),
                    "VALUE".to_string(),
                ],
                &[vec![
                    updated.id,
                    cf.name.clone(),
                    cf.field_type.clone(),
                    cf.display_value(),
                ]],
                ctx.format,
                out,
            )
        }

        FieldCommands::Delete { item_id, key } => {
            if dry_run {
                let base_url = config.require_base_url()?;
                let preview = HomeboxClient::build_dry_run(
                    base_url,
                    "PUT",
                    &format!("entities/{item_id}"),
                    Some(json!({ "removeFields": [key] })),
                );
                return write_dry_run(&[preview], ctx, out);
            }

            let client = HomeboxClient::from_config(config)?;
            let existing = client.get_entity(item_id)?;
            if existing.find_field(key).is_none() {
                return Err(HbctlError::NotFound {
                    kind: "field".to_string(),
                    query: key.clone(),
                });
            }

            let patch = EntityPatch {
                remove_fields: vec![key.clone()],
                ..Default::default()
            };
            let merged = merge_entity_patch(&existing, &patch);
            let updated = client.put_entity(item_id, &merged)?;

            if ctx.quiet {
                return write_quiet_ids(std::slice::from_ref(&updated.id), out);
            }
            if ctx.format == OutputFormat::Json {
                return write_compact_json(
                    &json!({ "itemId": updated.id, "field": key, "deleted": true }),
                    ctx.select.as_deref(),
                    out,
                );
            }
            writeln!(out, "Deleted field '{}' from item {}", key, updated.id)?;
            Ok(())
        }
    }
}

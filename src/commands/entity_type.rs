use std::io::{self, IsTerminal, Write};

use owo_colors::OwoColorize;
use serde_json::json;

use crate::cli::{EntityTypeArgs, EntityTypeCommands};
use crate::client::models::CreateEntityTypeRequest;
use crate::client::HomeboxClient;
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

fn format_is_location(is_location: bool, use_color: bool) -> String {
    if is_location {
        if use_color {
            "yes [location]".green().bold().to_string()
        } else {
            "yes [location]".to_string()
        }
    } else {
        "no".to_string()
    }
}

pub fn handle(
    args: &EntityTypeArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    match args.command {
        None | Some(EntityTypeCommands::List) => {
            let client = HomeboxClient::from_config(config)?;
            let types = client.list_entity_types()?;

            if ctx.quiet {
                let ids: Vec<String> = types.iter().map(|t| t.id.clone()).collect();
                return write_quiet_ids(&ids, out);
            }
            if ctx.format == OutputFormat::Json {
                return write_compact_json(&types, ctx.select.as_deref(), out);
            }
            if let Some(ref select) = ctx.select {
                return write_selected_table(&types, select, ctx.format, out);
            }

            let use_color = ctx.format == OutputFormat::Table && io::stdout().is_terminal();

            let headers = vec![
                "ID".to_string(),
                "NAME".to_string(),
                "IS_LOCATION".to_string(),
                "DESCRIPTION".to_string(),
            ];
            let rows: Vec<Vec<String>> = types
                .iter()
                .map(|et| {
                    vec![
                        et.id.clone(),
                        et.name.clone(),
                        format_is_location(et.is_location, use_color),
                        et.description.clone(),
                    ]
                })
                .collect();

            write_table_or_plain(&headers, &rows, ctx.format, out)
        }

        Some(EntityTypeCommands::Create {
            ref name,
            ref description,
            is_location,
        }) => {
            let trimmed_name = name.trim();
            if trimmed_name.is_empty() {
                return Err(HbctlError::InvalidInput(
                    "entity type name cannot be empty".to_string(),
                ));
            }
            let req = CreateEntityTypeRequest {
                name: trimmed_name.to_string(),
                description: description.clone(),
                is_location,
            };

            if dry_run {
                let base_url = config.require_base_url()?;
                let preview = HomeboxClient::build_dry_run(
                    base_url,
                    "POST",
                    "entity-types",
                    Some(serde_json::to_value(&req)?),
                );
                return write_dry_run(&[preview], ctx, out);
            }

            let client = HomeboxClient::from_config(config)?;
            let created = client.create_entity_type(&req)?;

            if ctx.quiet {
                return write_quiet_ids(std::slice::from_ref(&created.id), out);
            }
            if ctx.format == OutputFormat::Json {
                return write_compact_json(&created, ctx.select.as_deref(), out);
            }
            if let Some(ref select) = ctx.select {
                return write_selected_table(&[created], select, ctx.format, out);
            }

            let use_color = ctx.format == OutputFormat::Table && io::stdout().is_terminal();
            write_table_or_plain(
                &[
                    "ID".to_string(),
                    "NAME".to_string(),
                    "IS_LOCATION".to_string(),
                    "DESCRIPTION".to_string(),
                ],
                &[vec![
                    created.id,
                    created.name,
                    format_is_location(created.is_location, use_color),
                    created.description,
                ]],
                ctx.format,
                out,
            )
        }

        Some(EntityTypeCommands::Delete { ref id, force }) => {
            if dry_run {
                let base_url = config.require_base_url()?;
                let preview = HomeboxClient::build_dry_run(
                    base_url,
                    "DELETE",
                    &format!("entity-types/{id}"),
                    None,
                );
                return write_dry_run(&[preview], ctx, out);
            }

            if !force && io::stdin().is_terminal() {
                write!(err, "Delete entity type '{id}'? [y/N]: ")?;
                err.flush()?;
                let mut answer = String::new();
                io::stdin().read_line(&mut answer)?;
                if !matches!(answer.trim().to_ascii_lowercase().as_str(), "y" | "yes") {
                    writeln!(err, "Aborted.")?;
                    return Ok(());
                }
            }

            let client = HomeboxClient::from_config(config)?;
            client.delete_entity_type(id)?;

            if ctx.quiet {
                return write_quiet_ids(std::slice::from_ref(id), out);
            }
            if ctx.format == OutputFormat::Json {
                return write_compact_json(
                    &json!({ "id": id, "deleted": true }),
                    ctx.select.as_deref(),
                    out,
                );
            }
            writeln!(out, "Deleted entity type {id}")?;
            Ok(())
        }
    }
}

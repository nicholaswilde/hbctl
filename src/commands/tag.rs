use std::io::{self, IsTerminal, Write};

use serde_json::{json, Map, Value};

use crate::cli::{TagArgs, TagCommands};
use crate::client::HomeboxClient;
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

pub fn handle(
    args: &TagArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    match &args.command {
        TagCommands::List => {
            let client = HomeboxClient::from_config(config)?;
            let tags = client.list_tags()?;

            if ctx.quiet {
                let ids: Vec<String> = tags.iter().map(|t| t.id.clone()).collect();
                return write_quiet_ids(&ids, out);
            }
            if ctx.format == OutputFormat::Json {
                return write_compact_json(&tags, ctx.select.as_deref(), out);
            }
            if let Some(ref select) = ctx.select {
                return write_selected_table(&tags, select, ctx.format, out);
            }

            let headers = vec![
                "ID".to_string(),
                "NAME".to_string(),
                "DESCRIPTION".to_string(),
            ];
            let rows: Vec<Vec<String>> = tags
                .iter()
                .map(|t| vec![t.id.clone(), t.name.clone(), t.description.clone()])
                .collect();
            write_table_or_plain(&headers, &rows, ctx.format, out)
        }

        TagCommands::Create { name } => {
            if dry_run {
                let base_url = config.require_base_url()?;
                let preview = HomeboxClient::build_dry_run(
                    base_url,
                    "POST",
                    "tags",
                    Some(json!({ "name": name })),
                );
                return write_dry_run(&[preview], ctx, out);
            }

            let client = HomeboxClient::from_config(config)?;
            let created = client.create_tag(name)?;

            if ctx.quiet {
                return write_quiet_ids(std::slice::from_ref(&created.id), out);
            }
            if ctx.format == OutputFormat::Json {
                return write_compact_json(&created, ctx.select.as_deref(), out);
            }

            write_table_or_plain(
                &["ID".to_string(), "NAME".to_string()],
                &[vec![created.id, created.name]],
                ctx.format,
                out,
            )
        }

        TagCommands::Update {
            id,
            name,
            description,
            color,
        } => {
            if name.is_none() && description.is_none() && color.is_none() {
                return Err(HbctlError::InvalidInput(
                    "provide at least one of --name, --description, or --color".to_string(),
                ));
            }

            if dry_run {
                let base_url = config.require_base_url()?;
                let mut body = Map::new();
                if let Some(ref n) = name {
                    body.insert("name".to_string(), Value::String(n.clone()));
                }
                if let Some(ref d) = description {
                    body.insert("description".to_string(), Value::String(d.clone()));
                }
                if let Some(ref c) = color {
                    body.insert("color".to_string(), Value::String(c.clone()));
                }
                let preview = HomeboxClient::build_dry_run(
                    base_url,
                    "PUT",
                    &format!("tags/{id}"),
                    Some(Value::Object(body)),
                );
                return write_dry_run(&[preview], ctx, out);
            }

            let client = HomeboxClient::from_config(config)?;
            let mut existing = client.get_tag(id)?;
            if existing.id.is_empty() {
                existing.id = id.clone();
            }
            if let Some(ref n) = name {
                existing.name = n.clone();
            }
            if let Some(ref d) = description {
                existing.description = d.clone();
            }
            if let Some(ref c) = color {
                existing.color = Some(c.clone());
            }

            let updated = client.update_tag(id, &existing)?;

            if ctx.quiet {
                return write_quiet_ids(std::slice::from_ref(&updated.id), out);
            }
            if ctx.format == OutputFormat::Json {
                return write_compact_json(&updated, ctx.select.as_deref(), out);
            }

            write_table_or_plain(
                &[
                    "ID".to_string(),
                    "NAME".to_string(),
                    "DESCRIPTION".to_string(),
                ],
                &[vec![updated.id, updated.name, updated.description]],
                ctx.format,
                out,
            )
        }

        TagCommands::Delete { id, force } => {
            if dry_run {
                let base_url = config.require_base_url()?;
                let preview =
                    HomeboxClient::build_dry_run(base_url, "DELETE", &format!("tags/{id}"), None);
                return write_dry_run(&[preview], ctx, out);
            }

            if !*force && io::stdin().is_terminal() {
                write!(err, "Delete tag '{id}'? [y/N]: ")?;
                err.flush()?;
                let mut answer = String::new();
                io::stdin().read_line(&mut answer)?;
                if !matches!(answer.trim().to_ascii_lowercase().as_str(), "y" | "yes") {
                    writeln!(err, "Aborted.")?;
                    return Ok(());
                }
            }

            let client = HomeboxClient::from_config(config)?;
            client.delete_tag(id)?;

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
            writeln!(out, "Deleted tag {id}")?;
            Ok(())
        }
    }
}

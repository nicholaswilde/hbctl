use std::io::Write;

use serde_json::json;

use crate::cli::{TagArgs, TagCommands};
use crate::client::HomeboxClient;
use crate::config::{AppConfig, OutputFormat};
use crate::error::Result;
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
    _err: &mut dyn Write,
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
    }
}

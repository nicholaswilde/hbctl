use std::io::{self, IsTerminal, Write};

use owo_colors::OwoColorize;

use crate::cli::EntityTypeArgs;
use crate::client::HomeboxClient;
use crate::config::{AppConfig, OutputFormat};
use crate::error::Result;
use crate::output::{
    write_compact_json, write_quiet_ids, write_selected_table, write_table_or_plain, OutputContext,
};

pub fn handle(
    _args: &EntityTypeArgs,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    _err: &mut dyn Write,
) -> Result<()> {
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
            let loc_label = if et.is_location {
                if use_color {
                    "yes [location]".green().bold().to_string()
                } else {
                    "yes [location]".to_string()
                }
            } else {
                "no".to_string()
            };
            vec![
                et.id.clone(),
                et.name.clone(),
                loc_label,
                et.description.clone(),
            ]
        })
        .collect();

    write_table_or_plain(&headers, &rows, ctx.format, out)
}

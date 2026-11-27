use std::io::Write;

use serde::Serialize;
use serde_json::json;

use crate::cli::{ActionsArgs, ActionsCommands};
use crate::client::HomeboxClient;
use crate::config::{AppConfig, OutputFormat};
use crate::error::Result;
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct ActionSummary {
    action: String,
    completed: u64,
}

pub fn handle(
    args: &ActionsArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let slug = match args.command {
        ActionsCommands::EnsureAssetIds => "ensure-asset-ids",
        ActionsCommands::CreateMissingThumbnails => "create-missing-thumbnails",
    };

    if dry_run {
        let base_url = config.require_base_url()?;
        let preview = HomeboxClient::build_dry_run(
            base_url,
            "POST",
            &format!("actions/{slug}"),
            Some(json!({})),
        );
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let res = client.run_action(slug)?;

    if ctx.quiet {
        return write_quiet_ids(&[res.completed.to_string()], out);
    }

    let summary = ActionSummary {
        action: slug.to_string(),
        completed: res.completed,
    };

    if ctx.format == OutputFormat::Json {
        return write_compact_json(&summary, ctx.select.as_deref(), out);
    }

    if let Some(ref select) = ctx.select {
        return write_selected_table(&[summary], select, ctx.format, out);
    }

    write_table_or_plain(
        &["ACTION".to_string(), "COMPLETED".to_string()],
        &[vec![summary.action, summary.completed.to_string()]],
        ctx.format,
        out,
    )
}

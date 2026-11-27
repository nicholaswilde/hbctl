use std::io::Write;

use serde::Serialize;

use crate::client::models::ServerStatus;
use crate::client::HomeboxClient;
use crate::config::{normalize_base_url, AppConfig, OutputFormat};
use crate::error::Result;
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct StatusReport {
    url: String,
    reachable: bool,
    #[serde(flatten)]
    status: ServerStatus,
}

pub fn handle(
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let base_url = config.require_base_url()?;

    if dry_run {
        let preview = HomeboxClient::build_dry_run(base_url, "GET", "status", None);
        return write_dry_run(&[preview], ctx, out);
    }

    let normalized = normalize_base_url(base_url)?;
    let status = HomeboxClient::get_status(base_url, config.timeout_secs)?;
    let report = StatusReport {
        url: normalized,
        reachable: true,
        status,
    };

    if ctx.quiet {
        let val = report
            .status
            .effective_version()
            .unwrap_or("ok")
            .to_string();
        return write_quiet_ids(&[val], out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&report, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&[report], select, ctx.format, out);
    }

    let mut rows = vec![
        vec!["url".to_string(), report.url],
        vec!["reachable".to_string(), "yes".to_string()],
        vec![
            "version".to_string(),
            report
                .status
                .effective_version()
                .unwrap_or("(unknown)")
                .to_string(),
        ],
    ];
    if let Some(health) = report.status.health {
        rows.push(vec![
            "health".to_string(),
            if health { "ok" } else { "unhealthy" }.to_string(),
        ]);
    }
    if let Some(commit) = report.status.effective_commit() {
        rows.push(vec!["commit".to_string(), commit.to_string()]);
    }
    if let Some(build_time) = report.status.effective_build_time() {
        rows.push(vec!["buildTime".to_string(), build_time.to_string()]);
    }
    if let Some(title) = report
        .status
        .title
        .as_deref()
        .filter(|s| !s.trim().is_empty())
    {
        rows.push(vec!["title".to_string(), title.to_string()]);
    }
    if let Some(message) = report
        .status
        .message
        .as_deref()
        .filter(|s| !s.trim().is_empty())
    {
        rows.push(vec!["message".to_string(), message.to_string()]);
    }

    write_table_or_plain(
        &["FIELD".to_string(), "VALUE".to_string()],
        &rows,
        ctx.format,
        out,
    )
}

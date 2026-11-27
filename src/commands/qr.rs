use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use serde::Serialize;

use crate::cli::QrArgs;
use crate::client::resolve::{is_asset_id_like, normalize_asset_id};
use crate::client::HomeboxClient;
use crate::config::{normalize_base_url, AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct QrDownloadSummary {
    data: String,
    path: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    content_type: Option<String>,
    bytes: usize,
}

/// Strip `/api/v1` from a normalized API base URL to obtain the Homebox web UI root.
pub fn web_base_url(api_base_url: &str) -> String {
    let trimmed = api_base_url.trim_end_matches('/');
    trimmed
        .strip_suffix("/api/v1")
        .unwrap_or(trimmed)
        .to_string()
}

/// Build the QR `data` payload from `<id>`, encoding `/a/{asset}` for asset IDs,
/// `/item/{uuid}` for entity IDs, or passing full URLs / `--raw` inputs verbatim.
pub fn build_qr_data(
    api_base_url: &str,
    id: &str,
    force_asset_id: bool,
    raw: bool,
) -> Result<String> {
    let trimmed = id.trim();
    if trimmed.is_empty() {
        return Err(HbctlError::InvalidInput(
            "QR code input cannot be empty".to_string(),
        ));
    }

    if raw || trimmed.starts_with("http://") || trimmed.starts_with("https://") {
        return Ok(trimmed.to_string());
    }

    let web = web_base_url(api_base_url);
    if force_asset_id || is_asset_id_like(trimmed) {
        let clean = normalize_asset_id(trimmed);
        if clean.is_empty() {
            return Err(HbctlError::InvalidInput(
                "asset ID cannot be empty".to_string(),
            ));
        }
        Ok(format!("{web}/a/{clean}"))
    } else {
        Ok(format!("{web}/item/{trimmed}"))
    }
}

fn sanitize_filename_token(raw: &str) -> String {
    let sanitized: String = raw
        .chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || c == '-' || c == '_' {
                c
            } else {
                '_'
            }
        })
        .collect();
    let trimmed = sanitized.trim_matches('_');
    if trimmed.is_empty() {
        "code".to_string()
    } else {
        trimmed.chars().take(48).collect()
    }
}

fn extension_for_qr_mime(mime: Option<&str>) -> &'static str {
    match mime.map(str::trim).unwrap_or("") {
        "image/png" => "png",
        "image/svg+xml" => "svg",
        _ => "jpg",
    }
}

pub fn handle(
    args: &QrArgs,
    dry_run: bool,
    force_asset_id: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let normalized = normalize_base_url(base_url)?;
        let data = build_qr_data(&normalized, &args.id, force_asset_id, args.raw)?;
        let preview = HomeboxClient::build_api_dry_run(
            base_url,
            "GET",
            "qrcode",
            &[("data".to_string(), data)],
            None,
        )?;
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let data = build_qr_data(client.base_url(), &args.id, force_asset_id, args.raw)?;
    let downloaded = client.get_binary_endpoint("qrcode", &[("data", data.clone())])?;

    if args.out.as_deref() == Some(Path::new("-")) {
        out.write_all(&downloaded.bytes)?;
        out.flush()?;
        return Ok(());
    }

    let dest = args.out.clone().unwrap_or_else(|| {
        let ext = extension_for_qr_mime(downloaded.content_type.as_deref());
        PathBuf::from(format!("qr-{}.{ext}", sanitize_filename_token(&args.id)))
    });

    if dest.exists() && !args.overwrite {
        return Err(HbctlError::InvalidInput(format!(
            "output file '{}' already exists (pass --overwrite to replace)",
            dest.display()
        )));
    }

    if let Some(parent) = dest.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent)?;
        }
    }
    fs::write(&dest, &downloaded.bytes)?;

    if ctx.quiet {
        return write_quiet_ids(&[dest.display().to_string()], out);
    }

    let summary = QrDownloadSummary {
        data,
        path: dest.display().to_string(),
        content_type: downloaded.content_type,
        bytes: downloaded.bytes.len(),
    };

    if ctx.format == OutputFormat::Json {
        return write_compact_json(&summary, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&[summary], select, ctx.format, out);
    }

    write_table_or_plain(
        &["DATA".to_string(), "PATH".to_string(), "BYTES".to_string()],
        &[vec![summary.data, summary.path, summary.bytes.to_string()]],
        ctx.format,
        out,
    )
}

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use serde::Serialize;

use crate::cli::{LabelArgs, LabelTargetKind};
use crate::client::resolve::{is_asset_id_like, normalize_asset_id};
use crate::client::HomeboxClient;
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct LabelPrintSummary {
    id: String,
    kind: String,
    printed: bool,
    message: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct LabelDownloadSummary {
    id: String,
    kind: String,
    path: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    content_type: Option<String>,
    bytes: usize,
}

pub fn resolve_label_endpoint(
    id: &str,
    kind: LabelTargetKind,
    force_asset_id: bool,
) -> Result<(&'static str, String, String)> {
    let trimmed = id.trim();
    if trimmed.is_empty() {
        return Err(HbctlError::InvalidInput(
            "label target ID cannot be empty".to_string(),
        ));
    }

    match kind {
        LabelTargetKind::Asset => {
            let clean = normalize_asset_id(trimmed);
            if clean.is_empty() {
                return Err(HbctlError::InvalidInput(
                    "asset ID cannot be empty".to_string(),
                ));
            }
            Ok(("asset", clean.clone(), format!("labelmaker/asset/{clean}")))
        }
        LabelTargetKind::Location => Ok((
            "location",
            trimmed.to_string(),
            format!("labelmaker/location/{trimmed}"),
        )),
        LabelTargetKind::Item => Ok((
            "item",
            trimmed.to_string(),
            format!("labelmaker/item/{trimmed}"),
        )),
        LabelTargetKind::Auto => {
            if force_asset_id || is_asset_id_like(trimmed) {
                let clean = normalize_asset_id(trimmed);
                if clean.is_empty() {
                    return Err(HbctlError::InvalidInput(
                        "asset ID cannot be empty".to_string(),
                    ));
                }
                Ok(("asset", clean.clone(), format!("labelmaker/asset/{clean}")))
            } else {
                Ok((
                    "item",
                    trimmed.to_string(),
                    format!("labelmaker/item/{trimmed}"),
                ))
            }
        }
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
        "label".to_string()
    } else {
        trimmed.to_string()
    }
}

fn extension_for_label_mime(mime: Option<&str>) -> &'static str {
    match mime.map(str::trim).unwrap_or("") {
        "image/jpeg" | "image/jpg" => "jpg",
        "application/pdf" => "pdf",
        "image/svg+xml" => "svg",
        _ => "png",
    }
}

pub fn handle(
    args: &LabelArgs,
    dry_run: bool,
    force_asset_id: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let (kind_str, clean_id, path) = resolve_label_endpoint(&args.id, args.kind, force_asset_id)?;

    if dry_run {
        let base_url = config.require_base_url()?;
        let query = if args.print {
            vec![("print".to_string(), "true".to_string())]
        } else {
            Vec::new()
        };
        let preview = HomeboxClient::build_api_dry_run(base_url, "GET", &path, &query, None)?;
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;

    if args.print {
        let downloaded = client.get_binary_endpoint(&path, &[("print", "true".to_string())])?;
        let raw_msg = String::from_utf8_lossy(&downloaded.bytes)
            .trim()
            .to_string();
        let message = if raw_msg.is_empty() {
            "Printed!".to_string()
        } else {
            raw_msg
        };

        if ctx.quiet {
            return write_quiet_ids(&[clean_id], out);
        }

        let summary = LabelPrintSummary {
            id: clean_id,
            kind: kind_str.to_string(),
            printed: true,
            message,
        };

        if ctx.format == OutputFormat::Json {
            return write_compact_json(&summary, ctx.select.as_deref(), out);
        }
        if let Some(ref select) = ctx.select {
            return write_selected_table(&[summary], select, ctx.format, out);
        }

        return write_table_or_plain(
            &[
                "ID".to_string(),
                "KIND".to_string(),
                "STATUS".to_string(),
                "MESSAGE".to_string(),
            ],
            &[vec![
                summary.id,
                summary.kind,
                "printed".to_string(),
                summary.message,
            ]],
            ctx.format,
            out,
        );
    }

    let downloaded = client.get_binary_endpoint(&path, &[])?;

    if args.out.as_deref() == Some(Path::new("-")) {
        out.write_all(&downloaded.bytes)?;
        out.flush()?;
        return Ok(());
    }

    let dest = args.out.clone().unwrap_or_else(|| {
        let ext = extension_for_label_mime(downloaded.content_type.as_deref());
        PathBuf::from(format!(
            "label-{}.{ext}",
            sanitize_filename_token(&clean_id)
        ))
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

    let summary = LabelDownloadSummary {
        id: clean_id,
        kind: kind_str.to_string(),
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
        &[
            "ID".to_string(),
            "KIND".to_string(),
            "PATH".to_string(),
            "BYTES".to_string(),
        ],
        &[vec![
            summary.id,
            summary.kind,
            summary.path,
            summary.bytes.to_string(),
        ]],
        ctx.format,
        out,
    )
}

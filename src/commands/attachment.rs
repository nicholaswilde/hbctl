use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use serde::Serialize;
use serde_json::json;

use crate::cli::{
    AttachmentArgs, AttachmentCommands, AttachmentDeleteArgs, AttachmentDownloadArgs,
    AttachmentListArgs, AttachmentUploadArgs,
};
use crate::client::models::Attachment;
use crate::client::{DryRunRequest, HomeboxClient};
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

/// Maximum image size allowed without `--force` (500 KB).
pub const MAX_IMAGE_SIZE_BYTES: u64 = 500 * 1024;

pub fn handle(
    args: &AttachmentArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    match &args.command {
        AttachmentCommands::Upload(a) => handle_upload(a, dry_run, config, ctx, out, err),
        AttachmentCommands::List(a) => handle_list(a, config, ctx, out),
        AttachmentCommands::Download(a) => handle_download(a, dry_run, config, ctx, out, err),
        AttachmentCommands::Delete(a) => handle_delete(a, dry_run, config, ctx, out),
    }
}

#[derive(Debug, Serialize)]
struct UploadResult {
    file: String,
    status: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    id: Option<String>,
}

fn handle_upload(
    args: &AttachmentUploadArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    // Validate files and enforce the >500KB image guard before touching the server
    for path in &args.files {
        let meta = fs::metadata(path).map_err(|e| {
            HbctlError::InvalidInput(format!("cannot read file '{}': {e}", path.display()))
        })?;
        let mime = mime_guess::from_path(path).first_or_octet_stream();
        if mime.type_() == "image" && meta.len() > MAX_IMAGE_SIZE_BYTES {
            if args.force {
                writeln!(
                    err,
                    "warning: uploading oversized image '{}' ({} bytes > {} bytes) due to --force",
                    path.display(),
                    meta.len(),
                    MAX_IMAGE_SIZE_BYTES
                )?;
            } else {
                return Err(HbctlError::ImageTooLarge {
                    path: path.display().to_string(),
                    size_bytes: meta.len(),
                    max_bytes: MAX_IMAGE_SIZE_BYTES,
                });
            }
        }
    }

    if dry_run {
        let base_url = config.require_base_url()?;
        let mut previews: Vec<DryRunRequest> = Vec::new();
        for path in &args.files {
            let basename = path
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("attachment");
            let mime = mime_guess::from_path(path).first_or_octet_stream();
            previews.push(HomeboxClient::build_dry_run(
                base_url,
                "POST",
                &format!("entities/{}/attachments", args.item_id),
                Some(json!({
                    "name": basename,
                    "mimeType": mime.essence_str(),
                    "file": path.display().to_string(),
                })),
            ));
        }
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let existing_entity = client.get_entity(&args.item_id)?;
    let existing_attachments = existing_entity.attachments;

    let mut results = Vec::new();
    let mut uploaded_ids = Vec::new();

    for path in &args.files {
        let basename = path
            .file_name()
            .and_then(|n| n.to_str())
            .ok_or_else(|| {
                HbctlError::InvalidInput(format!("invalid file path '{}'", path.display()))
            })?
            .to_string();

        let existing = existing_attachments
            .iter()
            .find(|a| a.matches_filename(&basename));

        if let Some(prev) = existing {
            if args.overwrite {
                client.delete_attachment(&args.item_id, &prev.id)?;
            } else {
                // Default idempotent behavior (--skip-existing)
                writeln!(
                    err,
                    "skipping existing attachment '{}' (id: {})",
                    basename, prev.id
                )?;
                results.push(UploadResult {
                    file: basename,
                    status: "skipped".to_string(),
                    id: Some(prev.id.clone()),
                });
                continue;
            }
        }

        let uploaded = client.upload_attachment(&args.item_id, path)?;
        uploaded_ids.push(uploaded.id.clone());
        results.push(UploadResult {
            file: basename,
            status: "uploaded".to_string(),
            id: Some(uploaded.id),
        });
    }

    if ctx.quiet {
        return write_quiet_ids(&uploaded_ids, out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&results, ctx.select.as_deref(), out);
    }

    let headers = vec!["FILE".to_string(), "STATUS".to_string(), "ID".to_string()];
    let rows: Vec<Vec<String>> = results
        .iter()
        .map(|r| {
            vec![
                r.file.clone(),
                r.status.clone(),
                r.id.clone().unwrap_or_default(),
            ]
        })
        .collect();
    write_table_or_plain(&headers, &rows, ctx.format, out)
}

fn handle_list(
    args: &AttachmentListArgs,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let client = HomeboxClient::from_config(config)?;
    let entity = client.get_entity(&args.item_id)?;
    let attachments = entity.attachments;

    if ctx.quiet {
        let ids: Vec<String> = attachments.iter().map(|a| a.id.clone()).collect();
        return write_quiet_ids(&ids, out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&attachments, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&attachments, select, ctx.format, out);
    }

    let headers = vec![
        "ID".to_string(),
        "NAME".to_string(),
        "MIME".to_string(),
        "TYPE".to_string(),
    ];
    let rows: Vec<Vec<String>> = attachments
        .iter()
        .map(|a| {
            vec![
                a.id.clone(),
                a.effective_name().unwrap_or("").to_string(),
                a.mime_type.clone().unwrap_or_default(),
                a.attachment_type.clone().unwrap_or_default(),
            ]
        })
        .collect();
    write_table_or_plain(&headers, &rows, ctx.format, out)
}

#[derive(Debug, Serialize)]
struct DownloadResult {
    id: String,
    path: String,
    status: String,
    bytes: u64,
}

fn handle_download(
    args: &AttachmentDownloadArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    if args.attachment_id.is_none() && !args.all {
        return Err(HbctlError::InvalidInput(
            "specify an <ATTACHMENT_ID> or pass --all".to_string(),
        ));
    }

    let client = HomeboxClient::from_config(config)?;
    let entity = client.get_entity(&args.item_id)?;

    let targets: Vec<&Attachment> = if let Some(ref att_id) = args.attachment_id {
        let found = entity
            .attachments
            .iter()
            .find(|a| a.id == *att_id)
            .ok_or_else(|| HbctlError::NotFound {
                kind: "attachment".to_string(),
                query: att_id.clone(),
            })?;
        vec![found]
    } else {
        entity
            .attachments
            .iter()
            .filter(|a| matches_download_filters(a, args.mime.as_deref(), args.ext.as_deref()))
            .collect()
    };

    let multi_mode = args.all || targets.len() > 1;

    if dry_run {
        let base_url = client.base_url();
        let previews: Vec<DryRunRequest> = targets
            .iter()
            .map(|att| {
                let dest =
                    resolve_download_path(&entity.name, att, args.out.as_deref(), multi_mode);
                HomeboxClient::build_dry_run(
                    base_url,
                    "GET",
                    &format!("entities/{}/attachments/{}", args.item_id, att.id),
                    Some(json!({ "out": dest.display().to_string() })),
                )
            })
            .collect();
        return write_dry_run(&previews, ctx, out);
    }

    let mut results = Vec::new();
    let mut downloaded_ids = Vec::new();

    for att in targets {
        let dest = resolve_download_path(&entity.name, att, args.out.as_deref(), multi_mode);
        if dest.exists() && !args.overwrite {
            writeln!(
                err,
                "skipping existing file '{}' (pass --overwrite to replace)",
                dest.display()
            )?;
            results.push(DownloadResult {
                id: att.id.clone(),
                path: dest.display().to_string(),
                status: "skipped".to_string(),
                bytes: 0,
            });
            continue;
        }

        let bytes = client.download_attachment(&args.item_id, &att.id, &dest)?;
        downloaded_ids.push(att.id.clone());
        results.push(DownloadResult {
            id: att.id.clone(),
            path: dest.display().to_string(),
            status: "downloaded".to_string(),
            bytes,
        });
    }

    if ctx.quiet {
        return write_quiet_ids(&downloaded_ids, out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&results, ctx.select.as_deref(), out);
    }

    let headers = vec![
        "ID".to_string(),
        "PATH".to_string(),
        "STATUS".to_string(),
        "BYTES".to_string(),
    ];
    let rows: Vec<Vec<String>> = results
        .iter()
        .map(|r| {
            vec![
                r.id.clone(),
                r.path.clone(),
                r.status.clone(),
                r.bytes.to_string(),
            ]
        })
        .collect();
    write_table_or_plain(&headers, &rows, ctx.format, out)
}

fn handle_delete(
    args: &AttachmentDeleteArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let preview = HomeboxClient::build_dry_run(
            base_url,
            "DELETE",
            &format!(
                "entities/{}/attachments/{}",
                args.item_id, args.attachment_id
            ),
            None,
        );
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    client.delete_attachment(&args.item_id, &args.attachment_id)?;

    if ctx.quiet {
        return write_quiet_ids(std::slice::from_ref(&args.attachment_id), out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(
            &json!({ "itemId": args.item_id, "id": args.attachment_id, "deleted": true }),
            ctx.select.as_deref(),
            out,
        );
    }
    writeln!(
        out,
        "Deleted attachment {} from item {}",
        args.attachment_id, args.item_id
    )?;
    Ok(())
}

fn matches_download_filters(
    att: &Attachment,
    mime_filter: Option<&str>,
    ext_filter: Option<&str>,
) -> bool {
    if let Some(m) = mime_filter {
        let needle = m.trim().to_ascii_lowercase();
        let actual = att
            .mime_type
            .as_deref()
            .map(|s| s.trim().to_ascii_lowercase())
            .or_else(|| {
                att.effective_name().and_then(|n| {
                    mime_guess::from_path(n)
                        .first()
                        .map(|g| g.essence_str().to_string())
                })
            })
            .unwrap_or_default();
        if actual != needle && !actual.starts_with(&needle) {
            return false;
        }
    }

    if let Some(ext) = ext_filter {
        let target_ext = ext.trim().trim_start_matches('.').to_ascii_lowercase();
        let name_matches = att
            .effective_name()
            .and_then(|n| Path::new(n).extension().and_then(|e| e.to_str()))
            .map(|e| e.eq_ignore_ascii_case(&target_ext))
            .unwrap_or(false);
        let mime_matches = att
            .mime_type
            .as_deref()
            .and_then(mime_guess::get_mime_extensions_str)
            .map(|exts| exts.iter().any(|e| e.eq_ignore_ascii_case(&target_ext)))
            .unwrap_or(false);
        if !name_matches && !mime_matches {
            return false;
        }
    }

    true
}

/// Derive a safe download path. Falls back to `<slugified_entity>_<attachment_id>` when
/// both `title` and `name` are absent.
pub fn resolve_download_path(
    entity_name: &str,
    att: &Attachment,
    out_opt: Option<&Path>,
    multi_mode: bool,
) -> PathBuf {
    let filename = derive_attachment_filename(entity_name, att);

    match out_opt {
        None => PathBuf::from(filename),
        Some(out_path) => {
            if multi_mode || out_path.is_dir() {
                out_path.join(filename)
            } else {
                out_path.to_path_buf()
            }
        }
    }
}

pub fn derive_attachment_filename(entity_name: &str, att: &Attachment) -> String {
    if let Some(raw) = att.effective_name() {
        let sanitized = Path::new(raw)
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or(raw)
            .replace(['/', '\\'], "_");
        if !sanitized.is_empty() {
            return sanitized;
        }
    }

    let slug = slugify(entity_name);
    let base = if slug.is_empty() {
        att.id.clone()
    } else {
        format!("{slug}_{}", att.id)
    };

    if let Some(ext) = att
        .mime_type
        .as_deref()
        .and_then(mime_guess::get_mime_extensions_str)
        .and_then(|exts| exts.first())
    {
        format!("{base}.{ext}")
    } else {
        base
    }
}

pub fn slugify(input: &str) -> String {
    let mut out = String::new();
    let mut prev_sep = true;
    for ch in input.chars() {
        if ch.is_ascii_alphanumeric() {
            out.push(ch.to_ascii_lowercase());
            prev_sep = false;
        } else if !prev_sep {
            out.push('_');
            prev_sep = true;
        }
    }
    out.trim_matches('_').to_string()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_derive_attachment_filename_fallback_slug() {
        let att = Attachment {
            id: "att-42".into(),
            title: None,
            name: None,
            mime_type: Some("application/pdf".into()),
            ..Default::default()
        };
        let fname = derive_attachment_filename("ESP32 DevKit v2!", &att);
        assert_eq!(fname, "esp32_devkit_v2_att-42.pdf");
    }

    #[test]
    fn test_matches_download_filters_mime_and_ext() {
        let pdf = Attachment {
            id: "a1".into(),
            title: Some("datasheet.pdf".into()),
            mime_type: Some("application/pdf".into()),
            ..Default::default()
        };
        assert!(matches_download_filters(
            &pdf,
            Some("application/pdf"),
            Some("pdf")
        ));
        assert!(matches_download_filters(&pdf, None, Some(".PDF")));
        assert!(!matches_download_filters(&pdf, Some("image/png"), None));
    }
}

use std::collections::HashMap;
use std::fs;
use std::io::{self, Read, Write};
use std::path::{Path, PathBuf};

use serde::Serialize;
use serde_json::json;

use crate::cli::{
    AttachmentArgs, AttachmentCommands, AttachmentDeleteArgs, AttachmentDownloadArgs,
    AttachmentListArgs, AttachmentUploadArgs,
};
use crate::client::models::{Attachment, Entity};
use crate::client::resolve::Resolver;
use crate::client::{DryRunRequest, HomeboxClient, ListEntitiesQuery};
#[cfg(test)]
use crate::commands::parse_item_ids;
use crate::commands::read_item_ids;
use crate::config::{AppConfig, OutputFormat, DEFAULT_MAX_IMAGE_KB};
use crate::error::{HbctlError, Result};
use crate::image_opt::{optimize_attachment_bytes, ImageOptOptions, PreparedImageBytes};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

/// Maximum image size allowed without `--force` (500 KB).
pub const MAX_IMAGE_SIZE_BYTES: u64 = DEFAULT_MAX_IMAGE_KB * 1024;

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

/// Normalized attachment input from `--attach` or `--attach-url`.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AttachmentTarget {
    Local {
        path: PathBuf,
        remote_name: Option<String>,
    },
    Url {
        url: String,
        remote_name: Option<String>,
    },
}

impl AttachmentTarget {
    pub fn source_label(&self) -> String {
        match self {
            Self::Local { path, .. } => path.display().to_string(),
            Self::Url { url, .. } => url.clone(),
        }
    }

    pub fn explicit_name(&self) -> Option<&str> {
        match self {
            Self::Local { remote_name, .. } | Self::Url { remote_name, .. } => {
                remote_name.as_deref()
            }
        }
    }

    pub fn effective_preview_name(&self) -> String {
        match self {
            Self::Local { path, remote_name } => remote_name.clone().unwrap_or_else(|| {
                path.file_name()
                    .and_then(|n| n.to_str())
                    .unwrap_or("attachment")
                    .to_string()
            }),
            Self::Url { url, remote_name } => remote_name
                .clone()
                .unwrap_or_else(|| derive_url_filename(url, None, None)),
        }
    }
}

/// Non-fatal per-attachment failure recorded when `--attach-best-effort` is enabled.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct AttachmentError {
    pub source: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
    pub error: String,
}

enum UploadSource {
    File(PathBuf),
    Stdin(Option<Vec<u8>>),
    Url {
        url: String,
        explicit_name: Option<String>,
    },
}

struct PreparedUpload {
    remote_name: String,
    source_label: String,
    source: UploadSource,
}

/// Enforce the >500KB image upload size guard unless `--force` is set.
pub fn check_image_size_guard(
    display_path: &str,
    remote_name: &str,
    size_bytes: u64,
    force: bool,
    err: &mut dyn Write,
) -> Result<()> {
    check_image_size_guard_with_opts(
        display_path,
        remote_name,
        size_bytes,
        ImageOptOptions {
            optimize: false,
            force,
            max_bytes: MAX_IMAGE_SIZE_BYTES,
            max_dimension: crate::config::DEFAULT_MAX_IMAGE_DIMENSION,
        },
        err,
    )
}

/// Enforce the configured image size guard unless `--force` or `--optimize` (`auto_optimize`) is enabled.
pub fn check_image_size_guard_with_opts(
    display_path: &str,
    remote_name: &str,
    size_bytes: u64,
    opts: ImageOptOptions,
    err: &mut dyn Write,
) -> Result<()> {
    let mime = mime_guess::from_path(remote_name).first_or_octet_stream();
    if mime.type_() == "image" && size_bytes > opts.max_bytes {
        if opts.force {
            writeln!(
                err,
                "warning: uploading oversized image '{}' ({} bytes > {} bytes) due to --force",
                display_path, size_bytes, opts.max_bytes
            )?;
        } else if !opts.optimize {
            return Err(HbctlError::ImageTooLarge {
                path: display_path.to_string(),
                size_bytes,
                max_bytes: opts.max_bytes,
            });
        }
    }
    Ok(())
}

fn prepare_upload_bytes(
    display_path: &str,
    remote_name: &str,
    bytes: Vec<u8>,
    opts: ImageOptOptions,
    err: &mut dyn Write,
) -> Result<PreparedImageBytes> {
    let prepared = optimize_attachment_bytes(display_path, remote_name, bytes, opts)?;
    if prepared.optimized {
        let dims = match (prepared.original_dimensions, prepared.final_dimensions) {
            (Some((ow, oh)), Some((fw, fh))) => format!(" ({ow}x{oh} -> {fw}x{fh})"),
            _ => String::new(),
        };
        let rename = if prepared.remote_name != remote_name {
            format!(" as '{}'", prepared.remote_name)
        } else {
            String::new()
        };
        writeln!(
            err,
            "optimized image '{}'{} from {} to {} bytes{}",
            display_path,
            rename,
            prepared.original_bytes,
            prepared.bytes.len(),
            dims
        )?;
    }
    Ok(prepared)
}

/// Parse a `--attach <FILE>[=<REMOTE_NAME>]` specification.
pub fn parse_local_attachment_spec(raw: &str) -> Result<AttachmentTarget> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Err(HbctlError::InvalidInput(
            "attachment path cannot be empty".to_string(),
        ));
    }
    if Path::new(trimmed).exists() {
        return Ok(AttachmentTarget::Local {
            path: PathBuf::from(trimmed),
            remote_name: None,
        });
    }
    if let Some((left, right)) = trimmed.rsplit_once('=') {
        if right.contains(['/', '\\']) && !Path::new(left).exists() {
            return Ok(AttachmentTarget::Local {
                path: PathBuf::from(trimmed),
                remote_name: None,
            });
        }
        if left.trim().is_empty() {
            return Err(HbctlError::InvalidInput(format!(
                "invalid attachment spec '{trimmed}': missing file path before '='"
            )));
        }
        let remote_name = validate_custom_name(right)?;
        return Ok(AttachmentTarget::Local {
            path: PathBuf::from(left),
            remote_name: Some(remote_name),
        });
    }
    Ok(AttachmentTarget::Local {
        path: PathBuf::from(trimmed),
        remote_name: None,
    })
}

/// Parse a `--attach-url <URL>[=<REMOTE_NAME>]` specification safely around query parameters.
pub fn parse_url_attachment_spec(raw: &str) -> Result<AttachmentTarget> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Err(HbctlError::InvalidInput(
            "attachment URL cannot be empty".to_string(),
        ));
    }

    let (url_part, name_part) = split_url_and_optional_name(trimmed);
    let parsed = url::Url::parse(url_part).map_err(|e| {
        HbctlError::InvalidInput(format!("invalid attachment URL '{url_part}': {e}"))
    })?;
    if !matches!(parsed.scheme(), "http" | "https") || parsed.host_str().is_none() {
        return Err(HbctlError::InvalidInput(format!(
            "invalid attachment URL '{url_part}': expected http(s) URL with host"
        )));
    }

    let remote_name = match name_part {
        Some(name_raw) => Some(validate_custom_name(name_raw)?),
        None => None,
    };

    Ok(AttachmentTarget::Url {
        url: url_part.to_string(),
        remote_name,
    })
}

fn split_url_and_optional_name(raw: &str) -> (&str, Option<&str>) {
    let before_frag = raw.split('#').next().unwrap_or(raw);
    if !before_frag.contains('?') {
        if let Some((left, right)) = raw.rsplit_once('=') {
            return (left, Some(right));
        }
        return (raw, None);
    }

    let query_start = before_frag.find('?').expect("checked contains('?')");
    let query_and_rest = &raw[query_start + 1..];
    let last_segment = query_and_rest.rsplit('&').next().unwrap_or(query_and_rest);
    if last_segment.matches('=').count() >= 2 {
        if let Some((left, right)) = raw.rsplit_once('=') {
            return (left, Some(right));
        }
    }
    (raw, None)
}

fn percent_decode(input: &str) -> String {
    let bytes = input.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            if let Ok(hex) = std::str::from_utf8(&bytes[i + 1..i + 3]) {
                if let Ok(val) = u8::from_str_radix(hex, 16) {
                    out.push(val);
                    i += 3;
                    continue;
                }
            }
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

fn extension_for_mime(mime: &str) -> Option<&'static str> {
    let clean = mime.split(';').next().unwrap_or(mime).trim();
    if clean.eq_ignore_ascii_case("image/jpeg") || clean.eq_ignore_ascii_case("image/jpg") {
        Some("jpg")
    } else if clean.eq_ignore_ascii_case("image/png") {
        Some("png")
    } else if clean.eq_ignore_ascii_case("image/webp") {
        Some("webp")
    } else if clean.eq_ignore_ascii_case("image/gif") {
        Some("gif")
    } else if clean.eq_ignore_ascii_case("application/pdf") {
        Some("pdf")
    } else if clean.eq_ignore_ascii_case("text/plain") {
        Some("txt")
    } else {
        mime_guess::get_mime_extensions_str(clean).and_then(|exts| exts.first().copied())
    }
}

fn sanitize_filename_candidate(raw: &str) -> Option<String> {
    let decoded = percent_decode(raw.trim().trim_matches(['"', '\'']));
    let leaf = Path::new(&decoded)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or(&decoded)
        .replace(['/', '\\'], "_")
        .trim()
        .to_string();
    if leaf.is_empty() || leaf == "." || leaf == ".." {
        None
    } else {
        Some(leaf)
    }
}

fn parse_content_disposition_filename(header: &str) -> Option<String> {
    let mut fallback = None;
    for part in header.split(';') {
        let trimmed = part.trim();
        if let Some((key, val)) = trimmed.split_once('=') {
            let key_lower = key.trim().to_ascii_lowercase();
            if key_lower == "filename*" {
                let raw_val = val.trim().trim_matches('"');
                let encoded = match raw_val.splitn(3, '\'').nth(2) {
                    Some(rest) => rest,
                    None => raw_val,
                };
                if let Some(clean) = sanitize_filename_candidate(encoded) {
                    return Some(clean);
                }
            } else if key_lower == "filename" {
                fallback = sanitize_filename_candidate(val);
            }
        }
    }
    fallback
}

/// Derive a clean filename for a remote URL using `Content-Disposition`, URL path, and `Content-Type`.
pub fn derive_url_filename(
    url_str: &str,
    content_disposition: Option<&str>,
    content_type: Option<&str>,
) -> String {
    if let Some(cd) = content_disposition {
        if let Some(name) = parse_content_disposition_filename(cd) {
            return name;
        }
    }

    if let Ok(parsed) = url::Url::parse(url_str) {
        if let Some(segment) = parsed
            .path_segments()
            .and_then(|mut segs| segs.rfind(|s| !s.trim().is_empty()))
        {
            if let Some(mut name) = sanitize_filename_candidate(segment) {
                let has_ext = Path::new(&name)
                    .extension()
                    .and_then(|e| e.to_str())
                    .is_some_and(|e| !e.is_empty());
                if !has_ext {
                    if let Some(ext) = content_type.and_then(extension_for_mime) {
                        name = format!("{name}.{ext}");
                    }
                }
                return name;
            }
        }
    }

    if let Some(ext) = content_type.and_then(extension_for_mime) {
        format!("attachment.{ext}")
    } else {
        "attachment.bin".to_string()
    }
}

/// Validate attachment targets before mutating items (local file readability and image size guard).
pub fn validate_attachment_targets(
    targets: &[AttachmentTarget],
    opts: ImageOptOptions,
    err: &mut dyn Write,
) -> Result<()> {
    for target in targets {
        if let AttachmentTarget::Local { path, remote_name } = target {
            let meta = fs::metadata(path).map_err(|e| {
                HbctlError::InvalidInput(format!("cannot read file '{}': {e}", path.display()))
            })?;
            let basename = path
                .file_name()
                .and_then(|n| n.to_str())
                .filter(|s| !s.trim().is_empty())
                .ok_or_else(|| {
                    HbctlError::InvalidInput(format!("invalid file path '{}'", path.display()))
                })?;
            let effective_name = remote_name.as_deref().unwrap_or(basename);
            check_image_size_guard_with_opts(
                &path.display().to_string(),
                effective_name,
                meta.len(),
                opts,
                err,
            )?;
        }
    }
    Ok(())
}

/// Build a redacted dry-run preview for uploading an `AttachmentTarget` to `item_id`.
pub fn build_target_dry_run(
    base_url: &str,
    item_id: &str,
    target: &AttachmentTarget,
) -> DryRunRequest {
    build_attachment_dry_run(
        base_url,
        item_id,
        &target.effective_preview_name(),
        &target.source_label(),
    )
}

/// Build a redacted dry-run preview for uploading an attachment to `item_id`.
pub fn build_attachment_dry_run(
    base_url: &str,
    item_id: &str,
    remote_name: &str,
    source_label: &str,
) -> DryRunRequest {
    let mime = mime_guess::from_path(remote_name).first_or_octet_stream();
    HomeboxClient::build_dry_run(
        base_url,
        "POST",
        &format!("entities/{item_id}/attachments"),
        Some(json!({
            "name": remote_name,
            "mimeType": mime.essence_str(),
            "file": source_label,
        })),
    )
}

fn attach_single_target(
    client: &HomeboxClient,
    item_id: &str,
    known: &mut Vec<Attachment>,
    target: &AttachmentTarget,
    opts: ImageOptOptions,
    err: &mut dyn Write,
) -> Result<Option<Attachment>> {
    let (display_source, effective_name, raw_bytes) = match target {
        AttachmentTarget::Local { path, remote_name } => {
            let meta = fs::metadata(path).map_err(|e| {
                HbctlError::InvalidInput(format!("cannot read file '{}': {e}", path.display()))
            })?;
            let basename = path
                .file_name()
                .and_then(|n| n.to_str())
                .filter(|s| !s.trim().is_empty())
                .ok_or_else(|| {
                    HbctlError::InvalidInput(format!("invalid file path '{}'", path.display()))
                })?
                .to_string();
            let effective = remote_name.clone().unwrap_or(basename);
            if let Some(prev) = known.iter().find(|a| a.matches_filename(&effective)) {
                writeln!(
                    err,
                    "skipping existing attachment '{}' (id: {})",
                    effective, prev.id
                )?;
                return Ok(None);
            }
            let display = path.display().to_string();
            check_image_size_guard_with_opts(&display, &effective, meta.len(), opts, err)?;
            let bytes = fs::read(path)?;
            (display, effective, bytes)
        }
        AttachmentTarget::Url { url, remote_name } => {
            if let Some(ref explicit) = remote_name {
                if let Some(prev) = known.iter().find(|a| a.matches_filename(explicit)) {
                    writeln!(
                        err,
                        "skipping existing attachment '{}' (id: {})",
                        explicit, prev.id
                    )?;
                    return Ok(None);
                }
            }
            let fetched = client.fetch_remote_url(url)?;
            let effective = remote_name.clone().unwrap_or_else(|| {
                derive_url_filename(
                    &fetched.final_url,
                    fetched.content_disposition.as_deref(),
                    fetched.content_type.as_deref(),
                )
            });
            if let Some(prev) = known.iter().find(|a| a.matches_filename(&effective)) {
                writeln!(
                    err,
                    "skipping existing attachment '{}' (id: {})",
                    effective, prev.id
                )?;
                return Ok(None);
            }
            check_image_size_guard_with_opts(
                url,
                &effective,
                fetched.bytes.len() as u64,
                opts,
                err,
            )?;
            (url.clone(), effective, fetched.bytes)
        }
    };

    let prepared = prepare_upload_bytes(&display_source, &effective_name, raw_bytes, opts, err)?;
    if prepared.remote_name != effective_name {
        if let Some(prev) = known
            .iter()
            .find(|a| a.matches_filename(&prepared.remote_name))
        {
            writeln!(
                err,
                "skipping existing attachment '{}' (id: {})",
                prepared.remote_name, prev.id
            )?;
            return Ok(None);
        }
    }

    let uploaded =
        client.upload_attachment_bytes(item_id, &prepared.remote_name, prepared.bytes)?;
    known.push(uploaded.clone());
    Ok(Some(uploaded))
}

/// Attach local files or remote URLs to an item idempotently, optionally capturing per-attachment failures when `best_effort` is true.
pub fn attach_targets_to_item(
    client: &HomeboxClient,
    item_id: &str,
    existing_attachments: &[Attachment],
    targets: &[AttachmentTarget],
    opts: ImageOptOptions,
    best_effort: bool,
    err: &mut dyn Write,
) -> Result<(Vec<Attachment>, Vec<AttachmentError>)> {
    let mut known: Vec<Attachment> = existing_attachments.to_vec();
    let mut uploaded_all = Vec::new();
    let mut errors = Vec::new();

    for target in targets {
        match attach_single_target(client, item_id, &mut known, target, opts, err) {
            Ok(Some(uploaded)) => uploaded_all.push(uploaded),
            Ok(None) => {}
            Err(e) if best_effort => {
                let source = target.source_label();
                let msg = e.to_string();
                writeln!(err, "warning: failed to attach '{source}': {msg}")?;
                errors.push(AttachmentError {
                    source,
                    name: target.explicit_name().map(ToOwned::to_owned),
                    error: msg,
                });
            }
            Err(e) => return Err(e),
        }
    }

    Ok((uploaded_all, errors))
}

fn validate_custom_name(raw: &str) -> Result<String> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Err(HbctlError::InvalidInput(
            "--name cannot be empty".to_string(),
        ));
    }
    if trimmed.contains(['/', '\\']) {
        return Err(HbctlError::InvalidInput(
            "--name must be a filename without path separators".to_string(),
        ));
    }
    Ok(trimmed.to_string())
}

fn handle_upload(
    args: &AttachmentUploadArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    let parsed_urls: Vec<(String, Option<String>)> = args
        .attach_url
        .iter()
        .map(|raw| match parse_url_attachment_spec(raw)? {
            AttachmentTarget::Url { url, remote_name } => Ok((url, remote_name)),
            AttachmentTarget::Local { .. } => unreachable!("parse_url_attachment_spec returns Url"),
        })
        .collect::<Result<Vec<_>>>()?;

    let total_sources = args.files.len() + parsed_urls.len();
    if total_sources == 0 {
        return Err(HbctlError::InvalidInput(
            "specify at least one file or --attach-url".to_string(),
        ));
    }

    let custom_name = match args.name {
        Some(ref raw) => {
            if total_sources > 1 {
                return Err(HbctlError::InvalidInput(
                    "--name can only be used when uploading a single file, URL, or stdin"
                        .to_string(),
                ));
            }
            Some(validate_custom_name(raw)?)
        }
        None => None,
    };

    let has_stdin = args.files.iter().any(|p| p.as_os_str() == "-");
    if has_stdin && total_sources > 1 {
        return Err(HbctlError::InvalidInput(
            "'-' (stdin) cannot be combined with multiple file or URL arguments".to_string(),
        ));
    }

    let opts = ImageOptOptions::from_config(config, args.optimize, args.force);
    let mut prepared: Vec<PreparedUpload> = Vec::with_capacity(total_sources);
    for path in &args.files {
        if path.as_os_str() == "-" {
            let remote_name = custom_name.clone().ok_or_else(|| {
                HbctlError::InvalidInput(
                    "--name <FILENAME> is required when uploading from stdin ('-')".to_string(),
                )
            })?;
            let bytes = if dry_run {
                None
            } else {
                let mut buf = Vec::new();
                io::stdin().read_to_end(&mut buf)?;
                check_image_size_guard_with_opts("-", &remote_name, buf.len() as u64, opts, err)?;
                Some(buf)
            };
            prepared.push(PreparedUpload {
                remote_name,
                source_label: "-".to_string(),
                source: UploadSource::Stdin(bytes),
            });
        } else {
            let meta = fs::metadata(path).map_err(|e| {
                HbctlError::InvalidInput(format!("cannot read file '{}': {e}", path.display()))
            })?;
            let basename = path
                .file_name()
                .and_then(|n| n.to_str())
                .ok_or_else(|| {
                    HbctlError::InvalidInput(format!("invalid file path '{}'", path.display()))
                })?
                .to_string();
            let remote_name = custom_name.clone().unwrap_or(basename);
            check_image_size_guard_with_opts(
                &path.display().to_string(),
                &remote_name,
                meta.len(),
                opts,
                err,
            )?;
            prepared.push(PreparedUpload {
                remote_name,
                source_label: path.display().to_string(),
                source: UploadSource::File(path.clone()),
            });
        }
    }

    for (url, url_name) in parsed_urls {
        let explicit_name = custom_name.clone().or(url_name);
        let preview_name = explicit_name
            .clone()
            .unwrap_or_else(|| derive_url_filename(&url, None, None));
        prepared.push(PreparedUpload {
            remote_name: preview_name,
            source_label: url.clone(),
            source: UploadSource::Url { url, explicit_name },
        });
    }

    if dry_run {
        let base_url = config.require_base_url()?;
        let previews: Vec<DryRunRequest> = prepared
            .iter()
            .map(|item| {
                build_attachment_dry_run(
                    base_url,
                    &args.item_id,
                    &item.remote_name,
                    &item.source_label,
                )
            })
            .collect();
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let existing_entity = client.get_entity(&args.item_id)?;
    let mut existing_attachments = existing_entity.attachments;

    let mut results = Vec::new();
    let mut uploaded_ids = Vec::new();

    for item in prepared {
        let (orig_remote_name, raw_bytes) = match item.source {
            UploadSource::File(ref path) => {
                if let Some(prev) = existing_attachments
                    .iter()
                    .find(|a| a.matches_filename(&item.remote_name))
                {
                    if !args.overwrite {
                        writeln!(
                            err,
                            "skipping existing attachment '{}' (id: {})",
                            item.remote_name, prev.id
                        )?;
                        results.push(UploadResult {
                            file: item.remote_name,
                            status: "skipped".to_string(),
                            id: Some(prev.id.clone()),
                        });
                        continue;
                    }
                }
                (item.remote_name.clone(), fs::read(path)?)
            }
            UploadSource::Stdin(Some(bytes)) => {
                if let Some(prev) = existing_attachments
                    .iter()
                    .find(|a| a.matches_filename(&item.remote_name))
                {
                    if !args.overwrite {
                        writeln!(
                            err,
                            "skipping existing attachment '{}' (id: {})",
                            item.remote_name, prev.id
                        )?;
                        results.push(UploadResult {
                            file: item.remote_name,
                            status: "skipped".to_string(),
                            id: Some(prev.id.clone()),
                        });
                        continue;
                    }
                }
                (item.remote_name.clone(), bytes)
            }
            UploadSource::Stdin(None) => unreachable!("live stdin upload always buffers bytes"),
            UploadSource::Url { url, explicit_name } => {
                if let Some(ref name) = explicit_name {
                    if let Some(prev) = existing_attachments
                        .iter()
                        .find(|a| a.matches_filename(name))
                    {
                        if !args.overwrite {
                            writeln!(
                                err,
                                "skipping existing attachment '{}' (id: {})",
                                name, prev.id
                            )?;
                            results.push(UploadResult {
                                file: name.clone(),
                                status: "skipped".to_string(),
                                id: Some(prev.id.clone()),
                            });
                            continue;
                        }
                    }
                }
                let fetched = client.fetch_remote_url(&url)?;
                let resolved_name = explicit_name.unwrap_or_else(|| {
                    derive_url_filename(
                        &fetched.final_url,
                        fetched.content_disposition.as_deref(),
                        fetched.content_type.as_deref(),
                    )
                });
                if let Some(prev) = existing_attachments
                    .iter()
                    .find(|a| a.matches_filename(&resolved_name))
                {
                    if !args.overwrite {
                        writeln!(
                            err,
                            "skipping existing attachment '{}' (id: {})",
                            resolved_name, prev.id
                        )?;
                        results.push(UploadResult {
                            file: resolved_name,
                            status: "skipped".to_string(),
                            id: Some(prev.id.clone()),
                        });
                        continue;
                    }
                }
                check_image_size_guard_with_opts(
                    &url,
                    &resolved_name,
                    fetched.bytes.len() as u64,
                    opts,
                    err,
                )?;
                (resolved_name, fetched.bytes)
            }
        };

        let orig_existing_id = existing_attachments
            .iter()
            .find(|a| a.matches_filename(&orig_remote_name))
            .map(|a| a.id.clone());

        let prepared_img =
            prepare_upload_bytes(&item.source_label, &orig_remote_name, raw_bytes, opts, err)?;

        let final_existing_id = existing_attachments
            .iter()
            .find(|a| a.matches_filename(&prepared_img.remote_name))
            .map(|a| a.id.clone());

        if let Some(ref prev_id) = final_existing_id {
            if !args.overwrite {
                writeln!(
                    err,
                    "skipping existing attachment '{}' (id: {})",
                    prepared_img.remote_name, prev_id
                )?;
                results.push(UploadResult {
                    file: prepared_img.remote_name,
                    status: "skipped".to_string(),
                    id: Some(prev_id.clone()),
                });
                continue;
            }
            client.delete_attachment(&args.item_id, prev_id)?;
            existing_attachments.retain(|a| a.id != *prev_id);
        } else if let Some(ref prev_id) = orig_existing_id {
            if args.overwrite {
                client.delete_attachment(&args.item_id, prev_id)?;
                existing_attachments.retain(|a| a.id != *prev_id);
            }
        }

        let uploaded = client.upload_attachment_bytes(
            &args.item_id,
            &prepared_img.remote_name,
            prepared_img.bytes,
        )?;
        existing_attachments.push(uploaded.clone());
        uploaded_ids.push(uploaded.id.clone());
        results.push(UploadResult {
            file: prepared_img.remote_name,
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
#[serde(rename_all = "camelCase")]
struct DownloadResult {
    entity_id: String,
    entity_name: String,
    id: String,
    path: String,
    status: String,
    bytes: u64,
}

fn collision_key(path: &Path) -> String {
    path.to_string_lossy().to_ascii_lowercase()
}

fn prepend_filename_prefix(path: &Path, prefix: &str) -> PathBuf {
    let fname = path
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or("attachment");
    let prefixed = format!("{prefix}{fname}");
    match path.parent() {
        Some(parent) if !parent.as_os_str().is_empty() => parent.join(prefixed),
        _ => PathBuf::from(prefixed),
    }
}

fn count_path_collisions(paths: &[PathBuf]) -> HashMap<String, usize> {
    let mut counts = HashMap::with_capacity(paths.len());
    for path in paths {
        *counts.entry(collision_key(path)).or_insert(0) += 1;
    }
    counts
}

fn disambiguate_download_paths(
    targets: &[(&Entity, &Attachment)],
    out_opt: Option<&Path>,
    multi_mode: bool,
) -> Vec<PathBuf> {
    let initial: Vec<PathBuf> = targets
        .iter()
        .map(|(entity, att)| resolve_download_path(&entity.name, att, out_opt, multi_mode))
        .collect();

    let counts1 = count_path_collisions(&initial);
    let mut paths: Vec<PathBuf> = targets
        .iter()
        .enumerate()
        .map(|(idx, (entity, _))| {
            let base = &initial[idx];
            if counts1.get(&collision_key(base)).copied().unwrap_or(0) <= 1 {
                return base.clone();
            }
            let slug = slugify(&entity.name);
            let prefix = if slug.is_empty() {
                format!("{}_", entity.id)
            } else {
                format!("{slug}_")
            };
            prepend_filename_prefix(base, &prefix)
        })
        .collect();

    let counts2 = count_path_collisions(&paths);
    for (idx, (entity, _)) in targets.iter().enumerate() {
        if counts2
            .get(&collision_key(&paths[idx]))
            .copied()
            .unwrap_or(0)
            > 1
        {
            let slug = slugify(&entity.name);
            let prefix = if slug.is_empty() {
                format!("{}_", entity.id)
            } else {
                format!("{slug}_{}_", entity.id)
            };
            paths[idx] = prepend_filename_prefix(&initial[idx], &prefix);
        }
    }

    let counts3 = count_path_collisions(&paths);
    for (idx, (entity, att)) in targets.iter().enumerate() {
        if counts3
            .get(&collision_key(&paths[idx]))
            .copied()
            .unwrap_or(0)
            > 1
        {
            let prefix = format!("{}_{}_", entity.id, att.id);
            paths[idx] = prepend_filename_prefix(&initial[idx], &prefix);
        }
    }

    paths
}

fn handle_download(
    args: &AttachmentDownloadArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    let bulk_mode = args.all_items || args.tag.is_some() || args.items_from.is_some();

    if !bulk_mode && args.item_id.is_none() {
        return Err(HbctlError::InvalidInput(
            "specify an <ITEM_ID> or one of --all-items, --tag, or --items-from".to_string(),
        ));
    }
    if !bulk_mode && args.attachment_id.is_none() && !args.all {
        return Err(HbctlError::InvalidInput(
            "specify an <ATTACHMENT_ID> or pass --all".to_string(),
        ));
    }

    let client = HomeboxClient::from_config(config)?;
    let entities: Vec<Entity> = if let Some(ref item_id) = args.item_id {
        vec![client.get_entity(item_id)?]
    } else if args.all_items {
        let summary = client.list_entities(&ListEntitiesQuery::default(), true)?;
        client.hydrate_entity_attachments(summary)?
    } else if let Some(ref tag) = args.tag {
        let mut resolver = Resolver::new(&client);
        let tag_id = resolver.resolve_tag_id(tag, false)?;
        let query = ListEntitiesQuery {
            tag_ids: vec![tag_id],
            ..Default::default()
        };
        let summary = client.list_entities(&query, true)?;
        client.hydrate_entity_attachments(summary)?
    } else if let Some(ref items_path) = args.items_from {
        let ids = read_item_ids(items_path)?;
        client.get_entities_by_ids(&ids)?
    } else {
        unreachable!("validated single-item or bulk selector above");
    };

    let targets: Vec<(&Entity, &Attachment)> = if !bulk_mode {
        let entity = &entities[0];
        if let Some(ref att_id) = args.attachment_id {
            let found = entity
                .attachments
                .iter()
                .find(|a| a.id == *att_id)
                .ok_or_else(|| HbctlError::NotFound {
                    kind: "attachment".to_string(),
                    query: att_id.clone(),
                })?;
            vec![(entity, found)]
        } else {
            entity
                .attachments
                .iter()
                .filter(|a| matches_download_filters(a, args.mime.as_deref(), args.ext.as_deref()))
                .map(|a| (entity, a))
                .collect()
        }
    } else {
        entities
            .iter()
            .flat_map(|entity| {
                entity
                    .attachments
                    .iter()
                    .filter(|a| {
                        matches_download_filters(a, args.mime.as_deref(), args.ext.as_deref())
                    })
                    .map(move |a| (entity, a))
            })
            .collect()
    };

    let multi_mode = bulk_mode || args.all || targets.len() > 1;
    let dest_paths = disambiguate_download_paths(&targets, args.out.as_deref(), multi_mode);

    if dry_run {
        let base_url = client.base_url();
        let previews: Vec<DryRunRequest> = targets
            .iter()
            .zip(dest_paths.iter())
            .map(|((entity, att), dest)| {
                HomeboxClient::build_dry_run(
                    base_url,
                    "GET",
                    &format!("entities/{}/attachments/{}", entity.id, att.id),
                    Some(json!({
                        "entityId": entity.id,
                        "entityName": entity.name,
                        "out": dest.display().to_string(),
                    })),
                )
            })
            .collect();
        return write_dry_run(&previews, ctx, out);
    }

    let mut results = Vec::new();
    let mut downloaded_ids = Vec::new();

    for ((entity, att), dest) in targets.into_iter().zip(dest_paths) {
        if dest.exists() && !args.overwrite {
            writeln!(
                err,
                "skipping existing file '{}' (pass --overwrite to replace)",
                dest.display()
            )?;
            results.push(DownloadResult {
                entity_id: entity.id.clone(),
                entity_name: entity.name.clone(),
                id: att.id.clone(),
                path: dest.display().to_string(),
                status: "skipped".to_string(),
                bytes: 0,
            });
            continue;
        }

        let bytes = client.download_attachment(&entity.id, &att.id, &dest)?;
        downloaded_ids.push(att.id.clone());
        results.push(DownloadResult {
            entity_id: entity.id.clone(),
            entity_name: entity.name.clone(),
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
    if let Some(ref select) = ctx.select {
        return write_selected_table(&results, select, ctx.format, out);
    }

    if bulk_mode {
        let headers = vec![
            "ENTITY_ID".to_string(),
            "ENTITY".to_string(),
            "ID".to_string(),
            "PATH".to_string(),
            "STATUS".to_string(),
            "BYTES".to_string(),
        ];
        let rows: Vec<Vec<String>> = results
            .iter()
            .map(|r| {
                vec![
                    r.entity_id.clone(),
                    r.entity_name.clone(),
                    r.id.clone(),
                    r.path.clone(),
                    r.status.clone(),
                    r.bytes.to_string(),
                ]
            })
            .collect();
        write_table_or_plain(&headers, &rows, ctx.format, out)
    } else {
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

    #[test]
    fn test_check_image_size_guard_and_dry_run_preview() {
        let mut err = Vec::new();
        // Under limit succeeds without --force
        check_image_size_guard("small.png", "small.png", 1024, false, &mut err).unwrap();

        // Over limit fails without --force
        let too_big = check_image_size_guard(
            "big.png",
            "big.png",
            MAX_IMAGE_SIZE_BYTES + 1,
            false,
            &mut err,
        );
        assert!(matches!(too_big, Err(HbctlError::ImageTooLarge { .. })));

        // Over limit succeeds with warning when --force is set
        check_image_size_guard(
            "big.png",
            "big.png",
            MAX_IMAGE_SIZE_BYTES + 1,
            true,
            &mut err,
        )
        .unwrap();
        let warn = String::from_utf8(err).unwrap();
        assert!(warn.contains("due to --force"));

        let preview =
            build_attachment_dry_run("http://127.0.0.1:7745/api/v1", "ent-1", "doc.pdf", "-");
        assert_eq!(preview.method, "POST");
        assert_eq!(
            preview.url,
            "http://127.0.0.1:7745/api/v1/entities/ent-1/attachments"
        );
        let body = preview.body.unwrap();
        assert_eq!(body["name"], "doc.pdf");
        assert_eq!(body["mimeType"], "application/pdf");
        assert_eq!(body["file"], "-");
    }

    #[test]
    fn test_parse_item_ids_dedup_trim_and_comments() {
        let parsed = parse_item_ids(
            "\n  # appliance manuals\n  ent-1 \n\nent-2\n# comment\nent-1\n  ent-3  \n",
        );
        assert_eq!(parsed, vec!["ent-1", "ent-2", "ent-3"]);
    }

    #[test]
    fn test_disambiguate_download_paths_preserves_unique_and_resolves_collisions() {
        let e1 = Entity {
            id: "ent-1".into(),
            name: "Washer".into(),
            ..Default::default()
        };
        let e2 = Entity {
            id: "ent-2".into(),
            name: "Dryer".into(),
            ..Default::default()
        };
        let e3 = Entity {
            id: "ent-3".into(),
            name: "Dryer".into(),
            ..Default::default()
        };

        let a1 = Attachment {
            id: "att-1".into(),
            title: Some("manual.pdf".into()),
            mime_type: Some("application/pdf".into()),
            ..Default::default()
        };
        let a2 = Attachment {
            id: "att-2".into(),
            title: Some("manual.pdf".into()),
            mime_type: Some("application/pdf".into()),
            ..Default::default()
        };
        let a3 = Attachment {
            id: "att-3".into(),
            title: Some("manual.pdf".into()),
            mime_type: Some("application/pdf".into()),
            ..Default::default()
        };
        let unique = Attachment {
            id: "att-4".into(),
            title: Some("wiring.png".into()),
            mime_type: Some("image/png".into()),
            ..Default::default()
        };

        let out_dir = Path::new("/tmp/downloads");
        let targets = vec![(&e1, &a1), (&e2, &a2), (&e3, &a3), (&e1, &unique)];
        let resolved = disambiguate_download_paths(&targets, Some(out_dir), true);

        assert_eq!(resolved[0], out_dir.join("washer_manual.pdf"));
        // e2 and e3 share slug "dryer", so disambiguate falls back to slug + entity_id
        assert_eq!(resolved[1], out_dir.join("dryer_ent-2_manual.pdf"));
        assert_eq!(resolved[2], out_dir.join("dryer_ent-3_manual.pdf"));
        // Non-colliding filename keeps its original name
        assert_eq!(resolved[3], out_dir.join("wiring.png"));
    }

    #[test]
    fn test_parse_local_attachment_spec_variants() {
        // Basic path without rename
        assert_eq!(
            parse_local_attachment_spec("/tmp/manual.pdf").unwrap(),
            AttachmentTarget::Local {
                path: PathBuf::from("/tmp/manual.pdf"),
                remote_name: None,
            }
        );

        // Path with remote rename
        assert_eq!(
            parse_local_attachment_spec("/tmp/foo_compressed.pdf=LG_Manual.pdf").unwrap(),
            AttachmentTarget::Local {
                path: PathBuf::from("/tmp/foo_compressed.pdf"),
                remote_name: Some("LG_Manual.pdf".to_string()),
            }
        );

        // Existing literal file containing '=' is preserved untouched
        let dir = tempfile::tempdir().unwrap();
        let eq_file = dir.path().join("a=b.pdf");
        std::fs::write(&eq_file, b"%PDF-1.4").unwrap();
        assert_eq!(
            parse_local_attachment_spec(eq_file.to_str().unwrap()).unwrap(),
            AttachmentTarget::Local {
                path: eq_file,
                remote_name: None,
            }
        );

        // '=' in parent dir when right side has path separators is preserved
        assert_eq!(
            parse_local_attachment_spec("/dir=1/manual.pdf").unwrap(),
            AttachmentTarget::Local {
                path: PathBuf::from("/dir=1/manual.pdf"),
                remote_name: None,
            }
        );

        // Empty or invalid remote name fails
        assert!(parse_local_attachment_spec("/tmp/a.pdf=").is_err());
        assert!(parse_local_attachment_spec("=a.pdf").is_err());
        assert!(parse_local_attachment_spec("  ").is_err());
    }

    #[test]
    fn test_parse_url_attachment_spec_and_query_params() {
        assert_eq!(
            parse_url_attachment_spec("https://example.com/images/photo.jpg").unwrap(),
            AttachmentTarget::Url {
                url: "https://example.com/images/photo.jpg".to_string(),
                remote_name: None,
            }
        );

        assert_eq!(
            parse_url_attachment_spec("https://example.com/dl?id=123&fmt=jpg").unwrap(),
            AttachmentTarget::Url {
                url: "https://example.com/dl?id=123&fmt=jpg".to_string(),
                remote_name: None,
            }
        );

        assert_eq!(
            parse_url_attachment_spec("https://example.com/dl?id=123&fmt=jpg=Product.jpg").unwrap(),
            AttachmentTarget::Url {
                url: "https://example.com/dl?id=123&fmt=jpg".to_string(),
                remote_name: Some("Product.jpg".to_string()),
            }
        );

        assert_eq!(
            parse_url_attachment_spec("https://example.com/manual.pdf=LG_Manual.pdf").unwrap(),
            AttachmentTarget::Url {
                url: "https://example.com/manual.pdf".to_string(),
                remote_name: Some("LG_Manual.pdf".to_string()),
            }
        );

        assert!(parse_url_attachment_spec("ftp://example.com/file.pdf").is_err());
        assert!(parse_url_attachment_spec("https://example.com/a.pdf=bad/name.pdf").is_err());
    }

    #[test]
    fn test_derive_url_filename_priority() {
        // 1. Content-Disposition filename* takes priority over filename and URL path
        assert_eq!(
            derive_url_filename(
                "https://cdn.example.com/blob/1234",
                Some("attachment; filename=\"fallback.pdf\"; filename*=UTF-8''User%20Manual.pdf"),
                Some("application/pdf"),
            ),
            "User Manual.pdf"
        );

        // 2. Quoted Content-Disposition filename
        assert_eq!(
            derive_url_filename(
                "https://cdn.example.com/blob/1234",
                Some("inline; filename=\"datasheet.pdf\""),
                Some("application/pdf"),
            ),
            "datasheet.pdf"
        );

        // 3. URL path segment with extension
        assert_eq!(
            derive_url_filename(
                "https://cdn.example.com/assets/Product%20Photo.webp?v=2",
                None,
                Some("image/webp"),
            ),
            "Product Photo.webp"
        );

        // 4. Extensionless URL segment gains extension from Content-Type
        assert_eq!(
            derive_url_filename("https://cdn.example.com/image/42", None, Some("image/jpeg"),),
            "42.jpg"
        );

        // 5. Root URL falls back to attachment.<ext> or attachment.bin
        assert_eq!(
            derive_url_filename("https://cdn.example.com/", None, Some("application/pdf")),
            "attachment.pdf"
        );
        assert_eq!(
            derive_url_filename("https://cdn.example.com/", None, None),
            "attachment.bin"
        );
    }

    #[test]
    fn test_extension_for_mime_variants() {
        assert_eq!(extension_for_mime("image/jpeg"), Some("jpg"));
        assert_eq!(extension_for_mime("image/png"), Some("png"));
        assert_eq!(extension_for_mime("image/webp"), Some("webp"));
        assert_eq!(extension_for_mime("image/gif"), Some("gif"));
        assert_eq!(extension_for_mime("application/pdf"), Some("pdf"));
        assert_eq!(extension_for_mime("text/plain; charset=utf-8"), Some("txt"));
        assert!(extension_for_mime("application/json").is_some());
    }
}

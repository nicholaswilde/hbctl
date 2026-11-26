use std::collections::{HashMap, HashSet};
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

enum UploadSource {
    File(PathBuf),
    Stdin(Option<Vec<u8>>),
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
    let mime = mime_guess::from_path(remote_name).first_or_octet_stream();
    if mime.type_() == "image" && size_bytes > MAX_IMAGE_SIZE_BYTES {
        if force {
            writeln!(
                err,
                "warning: uploading oversized image '{}' ({} bytes > {} bytes) due to --force",
                display_path, size_bytes, MAX_IMAGE_SIZE_BYTES
            )?;
        } else {
            return Err(HbctlError::ImageTooLarge {
                path: display_path.to_string(),
                size_bytes,
                max_bytes: MAX_IMAGE_SIZE_BYTES,
            });
        }
    }
    Ok(())
}

/// Validate local attachment paths and enforce the >500KB image size guard before mutating items.
pub fn validate_local_attachment_paths(
    paths: &[PathBuf],
    force: bool,
    err: &mut dyn Write,
) -> Result<()> {
    for path in paths {
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
        check_image_size_guard(
            &path.display().to_string(),
            basename,
            meta.len(),
            force,
            err,
        )?;
    }
    Ok(())
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

/// Attach local files to an item idempotently, skipping attachments that already exist by name.
pub fn attach_files_to_item(
    client: &HomeboxClient,
    item_id: &str,
    existing_attachments: &[Attachment],
    files: &[PathBuf],
    err: &mut dyn Write,
) -> Result<Vec<Attachment>> {
    let mut known: Vec<Attachment> = existing_attachments.to_vec();
    let mut uploaded_all = Vec::new();

    for path in files {
        let basename = path
            .file_name()
            .and_then(|n| n.to_str())
            .ok_or_else(|| {
                HbctlError::InvalidInput(format!("invalid file path '{}'", path.display()))
            })?
            .to_string();

        if let Some(prev) = known.iter().find(|a| a.matches_filename(&basename)) {
            writeln!(
                err,
                "skipping existing attachment '{}' (id: {})",
                basename, prev.id
            )?;
            continue;
        }

        let uploaded = client.upload_attachment(item_id, path)?;
        known.push(uploaded.clone());
        uploaded_all.push(uploaded);
    }

    Ok(uploaded_all)
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
    let custom_name = match args.name {
        Some(ref raw) => {
            if args.files.len() > 1 {
                return Err(HbctlError::InvalidInput(
                    "--name can only be used when uploading a single file or stdin".to_string(),
                ));
            }
            Some(validate_custom_name(raw)?)
        }
        None => None,
    };

    let has_stdin = args.files.iter().any(|p| p.as_os_str() == "-");
    if has_stdin && args.files.len() > 1 {
        return Err(HbctlError::InvalidInput(
            "'-' (stdin) cannot be combined with multiple file arguments".to_string(),
        ));
    }

    let mut prepared: Vec<PreparedUpload> = Vec::with_capacity(args.files.len());
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
                check_image_size_guard("-", &remote_name, buf.len() as u64, args.force, err)?;
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
            check_image_size_guard(
                &path.display().to_string(),
                &remote_name,
                meta.len(),
                args.force,
                err,
            )?;
            prepared.push(PreparedUpload {
                remote_name,
                source_label: path.display().to_string(),
                source: UploadSource::File(path.clone()),
            });
        }
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
    let existing_attachments = existing_entity.attachments;

    let mut results = Vec::new();
    let mut uploaded_ids = Vec::new();

    for item in prepared {
        let existing = existing_attachments
            .iter()
            .find(|a| a.matches_filename(&item.remote_name));

        if let Some(prev) = existing {
            if args.overwrite {
                client.delete_attachment(&args.item_id, &prev.id)?;
            } else {
                // Default idempotent behavior (--skip-existing)
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

        let uploaded = match item.source {
            UploadSource::File(ref path) => {
                client.upload_attachment_as(&args.item_id, path, Some(&item.remote_name))?
            }
            UploadSource::Stdin(Some(bytes)) => {
                client.upload_attachment_bytes(&args.item_id, &item.remote_name, bytes)?
            }
            UploadSource::Stdin(None) => unreachable!("live stdin upload always buffers bytes"),
        };
        uploaded_ids.push(uploaded.id.clone());
        results.push(UploadResult {
            file: item.remote_name,
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

fn parse_item_ids(input: &str) -> Vec<String> {
    let mut seen = HashSet::new();
    let mut ids = Vec::new();
    for raw in input.lines() {
        let trimmed = raw.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') {
            continue;
        }
        if seen.insert(trimmed.to_string()) {
            ids.push(trimmed.to_string());
        }
    }
    ids
}

fn read_item_ids(path: &Path) -> Result<Vec<String>> {
    let raw = if path.as_os_str() == "-" {
        let mut buf = String::new();
        io::stdin().read_to_string(&mut buf)?;
        buf
    } else {
        fs::read_to_string(path).map_err(|e| {
            HbctlError::InvalidInput(format!(
                "cannot read item IDs file '{}': {e}",
                path.display()
            ))
        })?
    };
    Ok(parse_item_ids(&raw))
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
}

use std::collections::HashMap;
use std::fmt;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use flate2::write::GzEncoder;
use flate2::Compression;
use serde::Serialize;

use crate::cli::BackupArgs;
use crate::client::models::{Attachment, Entity};
use crate::client::{HomeboxClient, ListEntitiesQuery};
use crate::commands::attachment::derive_attachment_filename;
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_quiet_ids, write_selected_table, write_table_or_plain, OutputContext,
};

static TEMP_COUNTER: AtomicU64 = AtomicU64::new(0);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum BackupFormat {
    Directory,
    Archive,
}

impl fmt::Display for BackupFormat {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            BackupFormat::Directory => f.write_str("directory"),
            BackupFormat::Archive => f.write_str("archive"),
        }
    }
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct BackupCounts {
    entities: usize,
    attachments: usize,
    attachments_downloaded: usize,
    attachments_skipped: usize,
    tags: usize,
    entity_types: usize,
    maintenance: usize,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct BackupFiles {
    entities: &'static str,
    tags: &'static str,
    entity_types: &'static str,
    maintenance: &'static str,
    attachments_dir: &'static str,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct BackupAttachmentRecord {
    entity_id: String,
    entity_name: String,
    attachment_id: String,
    filename: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    path: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    mime_type: Option<String>,
    #[serde(rename = "type", skip_serializing_if = "Option::is_none")]
    attachment_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    primary: Option<bool>,
    bytes: u64,
    status: String,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct BackupManifest {
    schema_version: u32,
    tool: &'static str,
    tool_version: String,
    created_at: String,
    source_url: String,
    include_archived: bool,
    include_attachments: bool,
    counts: BackupCounts,
    files: BackupFiles,
    attachments: Vec<BackupAttachmentRecord>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(rename_all = "camelCase")]
struct BackupSummary {
    dry_run: bool,
    out: String,
    format: BackupFormat,
    include_archived: bool,
    include_attachments: bool,
    entities: usize,
    attachments: usize,
    attachments_downloaded: usize,
    attachments_skipped: usize,
    attachment_bytes: u64,
    tags: usize,
    entity_types: usize,
    maintenance: usize,
    #[serde(skip_serializing_if = "Option::is_none")]
    archive_bytes: Option<u64>,
}

struct StagingDir {
    path: PathBuf,
}

impl StagingDir {
    fn new() -> Result<Self> {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap_or_default()
            .as_nanos();
        let seq = TEMP_COUNTER.fetch_add(1, Ordering::Relaxed);
        let dir = std::env::temp_dir().join(format!(
            "hbctl-backup-stage-{}-{nanos}-{seq}",
            std::process::id()
        ));
        fs::create_dir_all(&dir)?;
        Ok(Self { path: dir })
    }

    fn path(&self) -> &Path {
        &self.path
    }
}

impl Drop for StagingDir {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.path);
    }
}

struct TempFileGuard {
    path: PathBuf,
    armed: bool,
}

impl TempFileGuard {
    fn new(path: PathBuf) -> Self {
        Self { path, armed: true }
    }

    fn disarm(&mut self) {
        self.armed = false;
    }
}

impl Drop for TempFileGuard {
    fn drop(&mut self) {
        if self.armed {
            let _ = fs::remove_file(&self.path);
        }
    }
}

pub fn handle(
    args: &BackupArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    _err: &mut dyn Write,
) -> Result<()> {
    if args.out.as_os_str().is_empty() {
        return Err(HbctlError::InvalidInput(
            "--out path cannot be empty".to_string(),
        ));
    }

    let format = detect_backup_format(&args.out);
    if !dry_run {
        validate_destination(&args.out, format, args.overwrite)?;
    }

    let client = HomeboxClient::from_config(config)?;
    let include_archived = !args.exclude_archived;
    let include_attachments = !args.no_attachments;

    let query = ListEntitiesQuery {
        include_archived,
        ..Default::default()
    };
    let mut entities = client.list_entities(&query, true)?;

    // Hydrate every entity via GET /entities/{id} so backup captures full fields,
    // attachments, warranty, insurance, and sold metadata even when list summaries omit them.
    let hydrate_work: Vec<(usize, String)> = entities
        .iter()
        .enumerate()
        .filter(|(_, e)| !e.id.is_empty())
        .map(|(idx, e)| (idx, e.id.clone()))
        .collect();
    if !hydrate_work.is_empty() {
        let ids: Vec<String> = hydrate_work.iter().map(|(_, id)| id.clone()).collect();
        let hydrated = client.get_entities_by_ids(&ids)?;
        for ((idx, _), full) in hydrate_work.into_iter().zip(hydrated) {
            entities[idx] = full;
        }
    }

    let mut tags = client.list_tags()?;
    let mut entity_types = client.list_entity_types()?;
    let mut maintenance = client.list_maintenance(None, "both")?;

    entities.sort_by(|a, b| a.id.cmp(&b.id));
    tags.sort_by(|a, b| a.id.cmp(&b.id));
    entity_types.sort_by(|a, b| a.id.cmp(&b.id));
    maintenance.sort_by(|a, b| a.id.cmp(&b.id));

    if dry_run {
        let mut total_attachments = 0usize;
        let mut skipped_attachments = 0usize;
        for entity in &entities {
            for att in &entity.attachments {
                total_attachments += 1;
                if !include_attachments
                    || att.id.trim().is_empty()
                    || is_external_link_attachment(att)
                {
                    skipped_attachments += 1;
                }
            }
        }
        let summary = BackupSummary {
            dry_run: true,
            out: args.out.display().to_string(),
            format,
            include_archived,
            include_attachments,
            entities: entities.len(),
            attachments: total_attachments,
            attachments_downloaded: 0,
            attachments_skipped: skipped_attachments,
            attachment_bytes: 0,
            tags: tags.len(),
            entity_types: entity_types.len(),
            maintenance: maintenance.len(),
            archive_bytes: None,
        };
        return render_summary(&summary, ctx, out);
    }

    let staging = (format == BackupFormat::Archive)
        .then(StagingDir::new)
        .transpose()?;
    let root = staging
        .as_ref()
        .map(|s| s.path())
        .unwrap_or(args.out.as_path());
    fs::create_dir_all(root)?;

    write_json_pretty(&root.join("entities.json"), &entities)?;
    write_json_pretty(&root.join("tags.json"), &tags)?;
    write_json_pretty(&root.join("entity_types.json"), &entity_types)?;
    write_json_pretty(&root.join("maintenance.json"), &maintenance)?;

    let mut attachment_records = Vec::new();
    let mut downloaded_rel_paths = Vec::new();
    let mut attachments_downloaded = 0usize;
    let mut attachments_skipped = 0usize;
    let mut attachment_bytes = 0u64;

    for entity in &entities {
        let safe_entity_id = sanitize_path_segment(&entity.id);
        for (att, filename) in plan_entity_attachments(entity) {
            let status_skip = if !include_attachments {
                Some("skipped_no_attachments")
            } else if att.id.trim().is_empty() {
                Some("skipped_missing_id")
            } else if is_external_link_attachment(att) {
                Some("skipped_external_link")
            } else {
                None
            };

            if let Some(reason) = status_skip {
                attachments_skipped += 1;
                attachment_records.push(BackupAttachmentRecord {
                    entity_id: entity.id.clone(),
                    entity_name: entity.name.clone(),
                    attachment_id: att.id.clone(),
                    filename,
                    path: None,
                    mime_type: att.mime_type.clone(),
                    attachment_type: att.attachment_type.clone(),
                    primary: att.primary,
                    bytes: 0,
                    status: reason.to_string(),
                });
                continue;
            }

            let rel_path = format!("attachments/{safe_entity_id}/{filename}");
            let disk_path = root
                .join("attachments")
                .join(&safe_entity_id)
                .join(&filename);
            let bytes = client.download_attachment(&entity.id, &att.id, &disk_path)?;
            attachments_downloaded += 1;
            attachment_bytes += bytes;
            downloaded_rel_paths.push(rel_path.clone());
            attachment_records.push(BackupAttachmentRecord {
                entity_id: entity.id.clone(),
                entity_name: entity.name.clone(),
                attachment_id: att.id.clone(),
                filename,
                path: Some(rel_path),
                mime_type: att.mime_type.clone(),
                attachment_type: att.attachment_type.clone(),
                primary: att.primary,
                bytes,
                status: "downloaded".to_string(),
            });
        }
    }

    let total_attachments = attachment_records.len();
    let manifest = BackupManifest {
        schema_version: 1,
        tool: "hbctl",
        tool_version: env!("PROJECT_VERSION").to_string(),
        created_at: format_utc_rfc3339(SystemTime::now()),
        source_url: sanitize_source_url(client.base_url()),
        include_archived,
        include_attachments,
        counts: BackupCounts {
            entities: entities.len(),
            attachments: total_attachments,
            attachments_downloaded,
            attachments_skipped,
            tags: tags.len(),
            entity_types: entity_types.len(),
            maintenance: maintenance.len(),
        },
        files: BackupFiles {
            entities: "entities.json",
            tags: "tags.json",
            entity_types: "entity_types.json",
            maintenance: "maintenance.json",
            attachments_dir: "attachments",
        },
        attachments: attachment_records,
    };
    write_json_pretty(&root.join("manifest.json"), &manifest)?;

    let archive_bytes = if format == BackupFormat::Archive {
        let mut rel_paths = vec![
            "manifest.json".to_string(),
            "entities.json".to_string(),
            "tags.json".to_string(),
            "entity_types.json".to_string(),
            "maintenance.json".to_string(),
        ];
        rel_paths.extend(downloaded_rel_paths);
        Some(pack_directory_to_tar_gz(root, &rel_paths, &args.out)?)
    } else {
        None
    };

    let summary = BackupSummary {
        dry_run: false,
        out: args.out.display().to_string(),
        format,
        include_archived,
        include_attachments,
        entities: entities.len(),
        attachments: total_attachments,
        attachments_downloaded,
        attachments_skipped,
        attachment_bytes,
        tags: tags.len(),
        entity_types: entity_types.len(),
        maintenance: maintenance.len(),
        archive_bytes,
    };
    render_summary(&summary, ctx, out)
}

fn detect_backup_format(path: &Path) -> BackupFormat {
    let lower = path
        .file_name()
        .and_then(|n| n.to_str())
        .map(str::to_ascii_lowercase)
        .unwrap_or_default();
    if lower.ends_with(".tar.gz") || lower.ends_with(".tgz") {
        BackupFormat::Archive
    } else {
        BackupFormat::Directory
    }
}

fn format_utc_rfc3339(time: SystemTime) -> String {
    let secs = time
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_secs();
    let days = (secs / 86_400) as i64;
    let rem = secs % 86_400;
    let hour = rem / 3_600;
    let min = (rem % 3_600) / 60;
    let sec = rem % 60;

    // Howard Hinnant civil-from-days conversion (proleptic Gregorian calendar).
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = (z - era * 146_097) as u64;
    let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365;
    let y = (yoe as i64) + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let day = doy - (153 * mp + 2) / 5 + 1;
    let month = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = y + i64::from(month <= 2);

    format!("{year:04}-{month:02}-{day:02}T{hour:02}:{min:02}:{sec:02}Z")
}

fn sanitize_source_url(raw: &str) -> String {
    if let Ok(mut parsed) = url::Url::parse(raw) {
        let _ = parsed.set_username("");
        let _ = parsed.set_password(None);
        return parsed.as_str().trim_end_matches('/').to_string();
    }
    raw.trim_end_matches('/').to_string()
}

fn sanitize_path_segment(raw: &str) -> String {
    let mut out = String::with_capacity(raw.len());
    for ch in raw.chars() {
        if matches!(ch, '/' | '\\' | '\0') || ch.is_control() {
            out.push('_');
        } else {
            out.push(ch);
        }
    }
    while out.contains("..") {
        out = out.replace("..", "_");
    }
    let trimmed = out.trim().trim_matches(|c| c == '.' || c == '_');
    if trimmed.is_empty() {
        "unknown".to_string()
    } else {
        trimmed.to_string()
    }
}

fn is_external_link_attachment(att: &Attachment) -> bool {
    att.attachment_type
        .as_deref()
        .is_some_and(|t| t.trim().eq_ignore_ascii_case("link"))
        || att
            .extra
            .get("sourceType")
            .and_then(|v| v.as_str())
            .is_some_and(|s| s.trim().eq_ignore_ascii_case("link"))
        || att
            .mime_type
            .as_deref()
            .is_some_and(|m| m.trim().eq_ignore_ascii_case("text/uri-list"))
}

fn plan_entity_attachments(entity: &Entity) -> Vec<(&Attachment, String)> {
    let bases: Vec<String> = entity
        .attachments
        .iter()
        .map(|att| sanitize_path_segment(&derive_attachment_filename(&entity.name, att)))
        .collect();

    let mut counts1: HashMap<String, usize> = HashMap::new();
    for name in &bases {
        *counts1.entry(name.to_ascii_lowercase()).or_insert(0) += 1;
    }

    let mut pass1: Vec<String> = entity
        .attachments
        .iter()
        .zip(bases.iter())
        .map(|(att, base)| {
            if counts1
                .get(&base.to_ascii_lowercase())
                .copied()
                .unwrap_or(0)
                > 1
            {
                let safe_id = sanitize_path_segment(&att.id);
                format!("{safe_id}_{base}")
            } else {
                base.clone()
            }
        })
        .collect();

    let mut counts2: HashMap<String, usize> = HashMap::new();
    for name in &pass1 {
        *counts2.entry(name.to_ascii_lowercase()).or_insert(0) += 1;
    }

    for (idx, (att, base)) in entity.attachments.iter().zip(bases.iter()).enumerate() {
        if counts2
            .get(&pass1[idx].to_ascii_lowercase())
            .copied()
            .unwrap_or(0)
            > 1
        {
            let safe_id = sanitize_path_segment(&att.id);
            pass1[idx] = format!("{safe_id}_{idx}_{base}");
        }
    }

    entity.attachments.iter().zip(pass1).collect()
}

fn validate_destination(out_path: &Path, format: BackupFormat, overwrite: bool) -> Result<()> {
    if out_path.as_os_str().is_empty() {
        return Err(HbctlError::InvalidInput(
            "--out path cannot be empty".to_string(),
        ));
    }

    match format {
        BackupFormat::Archive => {
            if out_path.is_dir() {
                return Err(HbctlError::InvalidInput(format!(
                    "backup archive path '{}' points to an existing directory",
                    out_path.display()
                )));
            }
            if out_path.exists() && !overwrite {
                return Err(HbctlError::InvalidInput(format!(
                    "backup archive '{}' already exists (pass --overwrite to replace)",
                    out_path.display()
                )));
            }
        }
        BackupFormat::Directory => {
            if out_path.is_file() {
                return Err(HbctlError::InvalidInput(format!(
                    "backup directory '{}' points to an existing file",
                    out_path.display()
                )));
            }
            if out_path.is_dir() && fs::read_dir(out_path)?.next().is_some() && !overwrite {
                return Err(HbctlError::InvalidInput(format!(
                    "backup directory '{}' is not empty (pass --overwrite to write anyway)",
                    out_path.display()
                )));
            }
        }
    }
    Ok(())
}

fn write_json_pretty<T: Serialize>(path: &Path, value: &T) -> Result<()> {
    let mut json = serde_json::to_string_pretty(value)?;
    json.push('\n');
    fs::write(path, json)?;
    Ok(())
}

fn pack_directory_to_tar_gz(
    staging_dir: &Path,
    rel_paths: &[String],
    archive_path: &Path,
) -> Result<u64> {
    let parent_dir = match archive_path.parent() {
        Some(p) if !p.as_os_str().is_empty() => {
            fs::create_dir_all(p)?;
            p
        }
        _ => Path::new("."),
    };

    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos();
    let seq = TEMP_COUNTER.fetch_add(1, Ordering::Relaxed);
    let tmp_path = parent_dir.join(format!(
        ".hbctl-backup-{}-{nanos}-{seq}.tar.gz.tmp",
        std::process::id()
    ));

    let mut guard = TempFileGuard::new(tmp_path.clone());
    {
        let file = File::create(&tmp_path)?;
        let encoder = GzEncoder::new(file, Compression::default());
        let mut builder = tar::Builder::new(encoder);
        for rel in rel_paths {
            builder.append_path_with_name(staging_dir.join(rel), rel)?;
        }
        builder.finish()?;
        let gz = builder.into_inner()?;
        let mut file = gz.finish()?;
        file.flush()?;
    }

    if cfg!(windows) && archive_path.exists() {
        fs::remove_file(archive_path)?;
    }
    fs::rename(&tmp_path, archive_path)?;
    guard.disarm();

    Ok(fs::metadata(archive_path)?.len())
}

fn render_summary(summary: &BackupSummary, ctx: &OutputContext, out: &mut dyn Write) -> Result<()> {
    if ctx.quiet {
        return write_quiet_ids(std::slice::from_ref(&summary.out), out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(summary, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(std::slice::from_ref(summary), select, ctx.format, out);
    }

    let headers = vec!["METRIC".to_string(), "VALUE".to_string()];
    let mut rows = vec![
        vec![
            "mode".to_string(),
            if summary.dry_run { "dry-run" } else { "backup" }.to_string(),
        ],
        vec!["out".to_string(), summary.out.clone()],
        vec!["format".to_string(), summary.format.to_string()],
        vec!["entities".to_string(), summary.entities.to_string()],
        vec!["attachments".to_string(), summary.attachments.to_string()],
        vec![
            "attachments_downloaded".to_string(),
            summary.attachments_downloaded.to_string(),
        ],
        vec![
            "attachments_skipped".to_string(),
            summary.attachments_skipped.to_string(),
        ],
        vec![
            "attachment_bytes".to_string(),
            summary.attachment_bytes.to_string(),
        ],
        vec!["tags".to_string(), summary.tags.to_string()],
        vec!["entity_types".to_string(), summary.entity_types.to_string()],
        vec!["maintenance".to_string(), summary.maintenance.to_string()],
    ];
    if let Some(archive_bytes) = summary.archive_bytes {
        rows.push(vec!["archive_bytes".to_string(), archive_bytes.to_string()]);
    }
    write_table_or_plain(&headers, &rows, ctx.format, out)
}

#[cfg(test)]
mod tests {
    use std::io::Read;
    use std::time::Duration;

    use flate2::read::GzDecoder;
    use serde_json::Value;
    use tempfile::tempdir;

    use super::*;

    #[test]
    fn test_detect_backup_format_variants() {
        assert_eq!(
            detect_backup_format(Path::new("/tmp/inventory.tar.gz")),
            BackupFormat::Archive
        );
        assert_eq!(
            detect_backup_format(Path::new("BACKUP.TAR.GZ")),
            BackupFormat::Archive
        );
        assert_eq!(
            detect_backup_format(Path::new("backup.tgz")),
            BackupFormat::Archive
        );
        assert_eq!(
            detect_backup_format(Path::new("./backup-dir")),
            BackupFormat::Directory
        );
        assert_eq!(
            detect_backup_format(Path::new("backup.json")),
            BackupFormat::Directory
        );
    }

    #[test]
    fn test_format_utc_rfc3339_known_timestamps() {
        assert_eq!(format_utc_rfc3339(UNIX_EPOCH), "1970-01-01T00:00:00Z");
        assert_eq!(
            format_utc_rfc3339(UNIX_EPOCH + Duration::from_secs(1_445_412_470)),
            "2015-10-21T07:27:50Z"
        );
        assert_eq!(
            format_utc_rfc3339(UNIX_EPOCH + Duration::from_secs(1_709_251_199)),
            "2024-02-29T23:59:59Z"
        );
    }

    #[test]
    fn test_sanitize_source_url_strips_userinfo() {
        assert_eq!(
            sanitize_source_url("https://alice:secret@hb.example.com:7745/api/v1/"),
            "https://hb.example.com:7745/api/v1"
        );
        assert_eq!(
            sanitize_source_url("http://127.0.0.1:7745/api/v1"),
            "http://127.0.0.1:7745/api/v1"
        );
    }

    #[test]
    fn test_sanitize_path_segment_and_attachment_collision_disambiguation() {
        assert_eq!(sanitize_path_segment("../etc/passwd"), "etc_passwd");
        assert_eq!(sanitize_path_segment(".."), "unknown");
        assert_eq!(sanitize_path_segment("photo.jpg"), "photo.jpg");

        let entity = Entity {
            id: "ent-1".to_string(),
            name: "Router".to_string(),
            attachments: vec![
                Attachment {
                    id: "att-1".to_string(),
                    title: Some("photo.jpg".to_string()),
                    ..Default::default()
                },
                Attachment {
                    id: "att-2".to_string(),
                    name: Some("photo.jpg".to_string()),
                    ..Default::default()
                },
                Attachment {
                    id: "att-3".to_string(),
                    title: Some("manual.pdf".to_string()),
                    ..Default::default()
                },
            ],
            ..Default::default()
        };

        let planned = plan_entity_attachments(&entity);
        let names: Vec<&str> = planned.iter().map(|(_, n)| n.as_str()).collect();
        assert_eq!(
            names,
            vec!["att-1_photo.jpg", "att-2_photo.jpg", "manual.pdf"]
        );
    }

    #[test]
    fn test_is_external_link_attachment() {
        let by_type = Attachment {
            attachment_type: Some("link".to_string()),
            ..Default::default()
        };
        assert!(is_external_link_attachment(&by_type));

        let mut by_extra = Attachment::default();
        by_extra
            .extra
            .insert("sourceType".to_string(), Value::String("link".to_string()));
        assert!(is_external_link_attachment(&by_extra));

        let by_mime = Attachment {
            mime_type: Some("text/uri-list".to_string()),
            ..Default::default()
        };
        assert!(is_external_link_attachment(&by_mime));

        let regular = Attachment {
            attachment_type: Some("attachment".to_string()),
            mime_type: Some("image/png".to_string()),
            ..Default::default()
        };
        assert!(!is_external_link_attachment(&regular));
    }

    #[test]
    fn test_validate_destination_rules() {
        let dir = tempdir().unwrap();

        let empty_dir = dir.path().join("empty");
        fs::create_dir_all(&empty_dir).unwrap();
        assert!(validate_destination(&empty_dir, BackupFormat::Directory, false).is_ok());

        let non_empty = dir.path().join("non-empty");
        fs::create_dir_all(&non_empty).unwrap();
        fs::write(non_empty.join("existing.txt"), b"hi").unwrap();
        assert!(validate_destination(&non_empty, BackupFormat::Directory, false).is_err());
        assert!(validate_destination(&non_empty, BackupFormat::Directory, true).is_ok());

        let existing_archive = dir.path().join("inv.tar.gz");
        fs::write(&existing_archive, b"archive").unwrap();
        assert!(validate_destination(&existing_archive, BackupFormat::Archive, false).is_err());
        assert!(validate_destination(&existing_archive, BackupFormat::Archive, true).is_ok());

        assert!(validate_destination(&existing_archive, BackupFormat::Directory, true).is_err());
        assert!(validate_destination(&empty_dir, BackupFormat::Archive, true).is_err());
    }

    #[test]
    fn test_pack_directory_to_tar_gz_roundtrip() {
        let dir = tempdir().unwrap();
        let stage = dir.path().join("stage");
        fs::create_dir_all(stage.join("attachments/ent-1")).unwrap();
        fs::write(stage.join("manifest.json"), b"{\"schemaVersion\":1}\n").unwrap();
        fs::write(
            stage.join("attachments/ent-1/photo.jpg"),
            b"\xff\xd8\xff\xe0test",
        )
        .unwrap();

        let archive_path = dir.path().join("out/backup.tar.gz");
        let rel_paths = vec![
            "manifest.json".to_string(),
            "attachments/ent-1/photo.jpg".to_string(),
        ];
        let written = pack_directory_to_tar_gz(&stage, &rel_paths, &archive_path).unwrap();
        assert!(written > 0);
        assert!(archive_path.is_file());

        let gz = GzDecoder::new(File::open(&archive_path).unwrap());
        let mut archive = tar::Archive::new(gz);
        let mut extracted: HashMap<String, Vec<u8>> = HashMap::new();
        for entry in archive.entries().unwrap() {
            let mut entry = entry.unwrap();
            let path = entry.path().unwrap().to_string_lossy().into_owned();
            let mut bytes = Vec::new();
            entry.read_to_end(&mut bytes).unwrap();
            extracted.insert(path, bytes);
        }

        assert_eq!(
            extracted.get("manifest.json").map(Vec::as_slice),
            Some(&b"{\"schemaVersion\":1}\n"[..])
        );
        assert_eq!(
            extracted
                .get("attachments/ent-1/photo.jpg")
                .map(Vec::as_slice),
            Some(&b"\xff\xd8\xff\xe0test"[..])
        );
    }
}

use std::io::{self, IsTerminal, Write};

use serde_json::json;

use crate::cli::{
    MaintenanceArgs, MaintenanceCommands, MaintenanceCreateArgs, MaintenanceUpdateArgs,
};
use crate::client::models::{CreateMaintenanceRequest, MaintenanceEntry, UpdateMaintenanceRequest};
use crate::client::HomeboxClient;
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

pub fn handle(
    args: &MaintenanceArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    match &args.command {
        MaintenanceCommands::List { entity, status } => {
            if dry_run {
                let base_url = config.require_base_url()?;
                let status_str = status.as_str();
                let (path, query) = match entity.as_deref() {
                    Some(id) => {
                        let q = if status_str != "both" {
                            vec![("status".to_string(), status_str.to_string())]
                        } else {
                            Vec::new()
                        };
                        (format!("entities/{id}/maintenance"), q)
                    }
                    None => (
                        "maintenance".to_string(),
                        vec![("status".to_string(), status_str.to_string())],
                    ),
                };
                let preview =
                    HomeboxClient::build_api_dry_run(base_url, "GET", &path, &query, None)?;
                return write_dry_run(&[preview], ctx, out);
            }

            let client = HomeboxClient::from_config(config)?;
            let entries = client.list_maintenance(entity.as_deref(), status.as_str())?;
            render_entries(&entries, ctx, out)
        }

        MaintenanceCommands::Create(create_args) => {
            let req = build_create_request(create_args)?;
            if dry_run {
                let base_url = config.require_base_url()?;
                let body = serde_json::to_value(&req)?;
                let preview = HomeboxClient::build_api_dry_run(
                    base_url,
                    "POST",
                    &format!("entities/{}/maintenance", create_args.entity),
                    &[],
                    Some(body),
                )?;
                return write_dry_run(&[preview], ctx, out);
            }

            let client = HomeboxClient::from_config(config)?;
            let created = client.create_maintenance(&create_args.entity, &req)?;
            render_entry(&created, ctx, out)
        }

        MaintenanceCommands::Update(update_args) => {
            let req = build_update_request(update_args)?;
            if dry_run {
                let base_url = config.require_base_url()?;
                let body = serde_json::to_value(&req)?;
                let preview = HomeboxClient::build_api_dry_run(
                    base_url,
                    "PUT",
                    &format!("maintenance/{}", update_args.entry_id),
                    &[],
                    Some(body),
                )?;
                return write_dry_run(&[preview], ctx, out);
            }

            let client = HomeboxClient::from_config(config)?;
            let updated = client.update_maintenance(&update_args.entry_id, &req)?;
            render_entry(&updated, ctx, out)
        }

        MaintenanceCommands::Delete { entry_id, force } => {
            if dry_run {
                let base_url = config.require_base_url()?;
                let preview = HomeboxClient::build_api_dry_run(
                    base_url,
                    "DELETE",
                    &format!("maintenance/{entry_id}"),
                    &[],
                    None,
                )?;
                return write_dry_run(&[preview], ctx, out);
            }

            if !*force && io::stdin().is_terminal() {
                write!(err, "Delete maintenance entry '{entry_id}'? [y/N]: ")?;
                err.flush()?;
                let mut answer = String::new();
                io::stdin().read_line(&mut answer)?;
                if !matches!(answer.trim().to_ascii_lowercase().as_str(), "y" | "yes") {
                    writeln!(err, "Aborted.")?;
                    return Ok(());
                }
            }

            let client = HomeboxClient::from_config(config)?;
            client.delete_maintenance(entry_id)?;

            if ctx.quiet {
                return write_quiet_ids(std::slice::from_ref(entry_id), out);
            }
            if ctx.format == OutputFormat::Json {
                return write_compact_json(
                    &json!({ "id": entry_id, "deleted": true }),
                    ctx.select.as_deref(),
                    out,
                );
            }
            writeln!(out, "Deleted maintenance entry {entry_id}")?;
            Ok(())
        }
    }
}

fn build_create_request(args: &MaintenanceCreateArgs) -> Result<CreateMaintenanceRequest> {
    let name = args.name.trim();
    if name.is_empty() {
        return Err(HbctlError::InvalidInput(
            "maintenance --name cannot be empty".to_string(),
        ));
    }
    let completed_date = args
        .completed_date
        .as_deref()
        .map(normalize_maintenance_date)
        .transpose()?;
    let scheduled_date = args
        .scheduled_date
        .as_deref()
        .map(normalize_maintenance_date)
        .transpose()?;
    let cost = args
        .cost
        .as_deref()
        .map(normalize_maintenance_cost)
        .transpose()?;
    let description = args.description.as_deref().map(|s| s.trim().to_string());

    Ok(CreateMaintenanceRequest {
        name: name.to_string(),
        description,
        scheduled_date,
        completed_date,
        cost,
    })
}

fn build_update_request(args: &MaintenanceUpdateArgs) -> Result<UpdateMaintenanceRequest> {
    if args.name.is_none()
        && args.completed_date.is_none()
        && args.scheduled_date.is_none()
        && args.cost.is_none()
        && args.description.is_none()
    {
        return Err(HbctlError::InvalidInput(
            "provide at least one of --name, --completed-date, --scheduled-date, --cost, or --description".to_string(),
        ));
    }

    let name = match args.name.as_deref() {
        Some(raw) => {
            let trimmed = raw.trim();
            if trimmed.is_empty() {
                return Err(HbctlError::InvalidInput(
                    "maintenance --name cannot be empty".to_string(),
                ));
            }
            Some(trimmed.to_string())
        }
        None => None,
    };
    let completed_date = args
        .completed_date
        .as_deref()
        .map(normalize_maintenance_date)
        .transpose()?;
    let scheduled_date = args
        .scheduled_date
        .as_deref()
        .map(normalize_maintenance_date)
        .transpose()?;
    let cost = args
        .cost
        .as_deref()
        .map(normalize_maintenance_cost)
        .transpose()?;
    let description = args.description.as_deref().map(|s| s.trim().to_string());

    Ok(UpdateMaintenanceRequest {
        name,
        description,
        scheduled_date,
        completed_date,
        cost,
    })
}

/// Normalize `YYYY-MM-DD` (or `YYYY-MM` -> `YYYY-MM-01`) and validate calendar bounds.
pub fn normalize_maintenance_date(raw: &str) -> Result<String> {
    let trimmed = raw.trim();
    let candidate = if trimmed.len() == 7 && trimmed.as_bytes()[4] == b'-' {
        format!("{trimmed}-01")
    } else {
        trimmed.to_string()
    };

    let bytes = candidate.as_bytes();
    if bytes.len() != 10
        || bytes[4] != b'-'
        || bytes[7] != b'-'
        || !bytes[0..4].iter().all(u8::is_ascii_digit)
        || !bytes[5..7].iter().all(u8::is_ascii_digit)
        || !bytes[8..10].iter().all(u8::is_ascii_digit)
    {
        return Err(HbctlError::InvalidInput(format!(
            "invalid date '{raw}': expected YYYY-MM-DD or YYYY-MM"
        )));
    }

    let year: u32 = candidate[0..4]
        .parse()
        .map_err(|_| HbctlError::InvalidInput(format!("invalid date '{raw}'")))?;
    let month: u32 = candidate[5..7]
        .parse()
        .map_err(|_| HbctlError::InvalidInput(format!("invalid date '{raw}'")))?;
    let day: u32 = candidate[8..10]
        .parse()
        .map_err(|_| HbctlError::InvalidInput(format!("invalid date '{raw}'")))?;

    if !(1..=12).contains(&month) {
        return Err(HbctlError::InvalidInput(format!(
            "invalid date '{raw}': month must be 01..=12"
        )));
    }

    let leap = (year.is_multiple_of(4) && !year.is_multiple_of(100)) || year.is_multiple_of(400);
    let max_day = match month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 => {
            if leap {
                29
            } else {
                28
            }
        }
        _ => unreachable!(),
    };
    if !(1..=max_day).contains(&day) {
        return Err(HbctlError::InvalidInput(format!(
            "invalid date '{raw}': day out of range for {year:04}-{month:02}"
        )));
    }

    Ok(candidate)
}

/// Normalize a cost string like `"$29.99"` or `"1,200.50"` into a clean non-negative numeric string.
pub fn normalize_maintenance_cost(raw: &str) -> Result<String> {
    let cleaned = raw.trim().trim_start_matches('$').replace(',', "");
    let cleaned = cleaned.trim();
    if cleaned.is_empty() {
        return Err(HbctlError::InvalidInput(format!(
            "invalid cost '{raw}': expected a non-negative number"
        )));
    }
    let val: f64 = cleaned.parse().map_err(|_| {
        HbctlError::InvalidInput(format!(
            "invalid cost '{raw}': expected a non-negative number"
        ))
    })?;
    if !val.is_finite() || val < 0.0 {
        return Err(HbctlError::InvalidInput(format!(
            "invalid cost '{raw}': expected a non-negative number"
        )));
    }
    Ok(cleaned.to_string())
}

fn entry_status_and_date(entry: &MaintenanceEntry) -> (&'static str, &str) {
    if let Some(ref completed) = entry.completed_date {
        if !completed.trim().is_empty() {
            return ("completed", completed.as_str());
        }
    }
    if let Some(ref scheduled) = entry.scheduled_date {
        if !scheduled.trim().is_empty() {
            return ("scheduled", scheduled.as_str());
        }
    }
    ("-", "-")
}

fn render_entries(
    entries: &[MaintenanceEntry],
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if ctx.quiet {
        let ids: Vec<String> = entries.iter().map(|e| e.id.clone()).collect();
        return write_quiet_ids(&ids, out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&entries, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(entries, select, ctx.format, out);
    }

    let headers = vec![
        "ID".to_string(),
        "ITEM".to_string(),
        "NAME".to_string(),
        "STATUS".to_string(),
        "DATE".to_string(),
        "COST".to_string(),
    ];
    let rows: Vec<Vec<String>> = entries
        .iter()
        .map(|entry| {
            let (status, date) = entry_status_and_date(entry);
            let item = entry
                .item_name
                .as_deref()
                .filter(|s| !s.trim().is_empty())
                .or(entry.item_id.as_deref().filter(|s| !s.trim().is_empty()))
                .unwrap_or("-");
            let cost = if entry.cost.trim().is_empty() {
                "0"
            } else {
                entry.cost.as_str()
            };
            vec![
                entry.id.clone(),
                item.to_string(),
                entry.name.clone(),
                status.to_string(),
                date.to_string(),
                cost.to_string(),
            ]
        })
        .collect();

    write_table_or_plain(&headers, &rows, ctx.format, out)
}

fn render_entry(entry: &MaintenanceEntry, ctx: &OutputContext, out: &mut dyn Write) -> Result<()> {
    if ctx.quiet {
        return write_quiet_ids(std::slice::from_ref(&entry.id), out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(entry, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(std::slice::from_ref(entry), select, ctx.format, out);
    }

    let mut rows = vec![
        vec!["id".to_string(), entry.id.clone()],
        vec!["name".to_string(), entry.name.clone()],
    ];
    if let Some(ref item_name) = entry.item_name {
        if !item_name.trim().is_empty() {
            rows.push(vec!["itemName".to_string(), item_name.clone()]);
        }
    }
    if let Some(ref item_id) = entry.item_id {
        if !item_id.trim().is_empty() {
            rows.push(vec!["itemID".to_string(), item_id.clone()]);
        }
    }
    if let Some(ref completed) = entry.completed_date {
        if !completed.trim().is_empty() {
            rows.push(vec!["completedDate".to_string(), completed.clone()]);
        }
    }
    if let Some(ref scheduled) = entry.scheduled_date {
        if !scheduled.trim().is_empty() {
            rows.push(vec!["scheduledDate".to_string(), scheduled.clone()]);
        }
    }
    if !entry.cost.trim().is_empty() {
        rows.push(vec!["cost".to_string(), entry.cost.clone()]);
    }
    if !entry.description.trim().is_empty() {
        rows.push(vec!["description".to_string(), entry.description.clone()]);
    }

    write_table_or_plain(
        &["FIELD".to_string(), "VALUE".to_string()],
        &rows,
        ctx.format,
        out,
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_normalize_maintenance_date() {
        assert_eq!(
            normalize_maintenance_date("2026-11-27").unwrap(),
            "2026-11-27"
        );
        assert_eq!(
            normalize_maintenance_date(" 2026-11 ").unwrap(),
            "2026-11-01"
        );
        assert_eq!(
            normalize_maintenance_date("2024-02-29").unwrap(),
            "2024-02-29"
        );
        assert!(normalize_maintenance_date("2026-02-29").is_err());
        assert!(normalize_maintenance_date("2026-02-30").is_err());
        assert!(normalize_maintenance_date("2026-13-01").is_err());
        assert!(normalize_maintenance_date("not-a-date").is_err());
    }

    #[test]
    fn test_normalize_maintenance_cost() {
        assert_eq!(normalize_maintenance_cost("29.99").unwrap(), "29.99");
        assert_eq!(normalize_maintenance_cost(" $29.99 ").unwrap(), "29.99");
        assert_eq!(normalize_maintenance_cost("$1,200.50").unwrap(), "1200.50");
        assert_eq!(normalize_maintenance_cost("0").unwrap(), "0");
        assert!(normalize_maintenance_cost("-5").is_err());
        assert!(normalize_maintenance_cost("abc").is_err());
        assert!(normalize_maintenance_cost("   ").is_err());
    }
}

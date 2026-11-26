use std::io::Write;

use comfy_table::presets::UTF8_FULL_CONDENSED;
use comfy_table::{Cell, ContentArrangement, Table};
use serde::Serialize;
use serde_json::{Map, Value};

use crate::client::DryRunRequest;
use crate::config::OutputFormat;
use crate::error::Result;

/// Options controlling structured output rendering to `stdout`.
#[derive(Debug, Clone)]
pub struct OutputContext {
    pub format: OutputFormat,
    pub select: Option<Vec<String>>,
    pub quiet: bool,
}

impl OutputContext {
    pub fn new(format: OutputFormat, select: Option<Vec<String>>, quiet: bool) -> Self {
        let cleaned_select = select.and_then(|fields| {
            let v: Vec<String> = fields
                .into_iter()
                .flat_map(|s| {
                    s.split(',')
                        .map(|p| p.trim().to_string())
                        .collect::<Vec<_>>()
                })
                .filter(|s| !s.is_empty())
                .collect();
            if v.is_empty() {
                None
            } else {
                Some(v)
            }
        });
        Self {
            format,
            select: cleaned_select,
            quiet,
        }
    }
}

/// Project a `serde_json::Value` to only the requested keys (supports both top-level keys
/// and custom field names stored inside an entity's `fields` array).
pub fn project_json_value(value: &Value, select: &[String]) -> Value {
    match value {
        Value::Array(items) => Value::Array(
            items
                .iter()
                .map(|item| project_json_object(item, select))
                .collect(),
        ),
        Value::Object(_) => project_json_object(value, select),
        other => other.clone(),
    }
}

fn project_json_object(value: &Value, select: &[String]) -> Value {
    let Some(obj) = value.as_object() else {
        return value.clone();
    };

    let mut out = Map::new();
    for key in select {
        if let Some((orig_k, v)) = lookup_json_field(obj, key) {
            out.insert(orig_k, v);
        }
    }
    Value::Object(out)
}

fn lookup_json_field(obj: &Map<String, Value>, key: &str) -> Option<(String, Value)> {
    // 1. Exact key match
    if let Some(v) = obj.get(key) {
        return Some((key.to_string(), v.clone()));
    }
    // 2. Case-insensitive key match
    if let Some((k, v)) = obj.iter().find(|(k, _)| k.eq_ignore_ascii_case(key)) {
        return Some((k.clone(), v.clone()));
    }
    // 3. Fallback to entity custom `fields` array by name
    if let Some(Value::Array(fields)) = obj.get("fields") {
        for field in fields {
            if let Some(name) = field.get("name").and_then(Value::as_str) {
                if name.trim().eq_ignore_ascii_case(key.trim()) {
                    let display = extract_field_json_display(field);
                    return Some((key.to_string(), display));
                }
            }
        }
    }
    None
}

fn extract_field_json_display(field: &Value) -> Value {
    let ftype = field.get("type").and_then(Value::as_str).unwrap_or("text");
    if ftype.eq_ignore_ascii_case("number") {
        if let Some(n) = field.get("numberValue").filter(|v| !v.is_null()) {
            return n.clone();
        }
    }
    if ftype.eq_ignore_ascii_case("boolean") {
        if let Some(b) = field.get("booleanValue").filter(|v| !v.is_null()) {
            return b.clone();
        }
    }
    if let Some(v) = field.get("value").filter(|v| !v.is_null()) {
        return v.clone();
    }
    if let Some(t) = field.get("textValue").filter(|v| !v.is_null()) {
        return t.clone();
    }
    Value::Null
}

/// Emit compact JSON (with optional `--select` projection) to `out`.
pub fn write_compact_json<T: Serialize>(
    value: &T,
    select: Option<&[String]>,
    out: &mut dyn Write,
) -> Result<()> {
    let raw = serde_json::to_value(value)?;
    let final_val = match select {
        Some(keys) if !keys.is_empty() => project_json_value(&raw, keys),
        _ => raw,
    };
    let line = serde_json::to_string(&final_val)?;
    writeln!(out, "{line}")?;
    Ok(())
}

/// Render a table (`comfy-table`) or tab-separated `plain` output from headers & rows.
/// When `--select` is active, filters columns to match the requested keys (case-insensitive)
/// or extracts projected fields directly from serialized JSON objects.
pub fn write_table_or_plain(
    headers: &[String],
    rows: &[Vec<String>],
    format: OutputFormat,
    out: &mut dyn Write,
) -> Result<()> {
    match format {
        OutputFormat::Table => {
            let mut table = Table::new();
            table
                .load_preset(UTF8_FULL_CONDENSED)
                .set_content_arrangement(ContentArrangement::Dynamic)
                .set_header(headers.iter().map(Cell::new));
            for row in rows {
                table.add_row(row.iter().map(Cell::new));
            }
            writeln!(out, "{table}")?;
            Ok(())
        }
        OutputFormat::Plain => {
            for row in rows {
                writeln!(out, "{}", row.join("\t"))?;
            }
            Ok(())
        }
        OutputFormat::Json => {
            let objects: Vec<Value> = rows
                .iter()
                .map(|row| {
                    let mut map = Map::new();
                    for (idx, header) in headers.iter().enumerate() {
                        let cell = row.get(idx).cloned().unwrap_or_default();
                        map.insert(header.clone(), Value::String(cell));
                    }
                    Value::Object(map)
                })
                .collect();
            writeln!(out, "{}", serde_json::to_string(&objects)?)?;
            Ok(())
        }
    }
}

/// Render a projected table/plain view directly from serializable records when `--select` is passed.
pub fn write_selected_table<T: Serialize>(
    records: &[T],
    select: &[String],
    format: OutputFormat,
    out: &mut dyn Write,
) -> Result<()> {
    let raw = serde_json::to_value(records)?;
    let projected = project_json_value(&raw, select);
    let Value::Array(arr) = projected else {
        return Ok(());
    };

    let headers: Vec<String> = select.to_vec();
    let rows: Vec<Vec<String>> = arr
        .iter()
        .map(|val| {
            headers
                .iter()
                .map(|col| {
                    val.as_object()
                        .and_then(|m| {
                            m.get(col).or_else(|| {
                                m.iter()
                                    .find(|(k, _)| k.eq_ignore_ascii_case(col))
                                    .map(|(_, v)| v)
                            })
                        })
                        .map(json_cell_string)
                        .unwrap_or_default()
                })
                .collect()
        })
        .collect();

    write_table_or_plain(&headers, &rows, format, out)
}

fn json_cell_string(val: &Value) -> String {
    match val {
        Value::Null => String::new(),
        Value::String(s) => s.clone(),
        Value::Number(n) => n.to_string(),
        Value::Bool(b) => b.to_string(),
        other => serde_json::to_string(other).unwrap_or_default(),
    }
}

/// Render CSV rows to `out`.
pub fn write_csv(headers: &[String], rows: &[Vec<String>], out: &mut dyn Write) -> Result<()> {
    let mut wtr = csv::Writer::from_writer(out);
    wtr.write_record(headers)?;
    for row in rows {
        wtr.write_record(row)?;
    }
    wtr.flush()?;
    Ok(())
}

/// Render a GitHub Flavored Markdown table to `out`.
pub fn write_markdown_table(
    headers: &[String],
    rows: &[Vec<String>],
    out: &mut dyn Write,
) -> Result<()> {
    let escape = |s: &str| s.replace('|', "\\|").replace(['\r', '\n'], " ");

    let header_line: Vec<String> = headers.iter().map(|h| escape(h)).collect();
    writeln!(out, "| {} |", header_line.join(" | "))?;

    let sep: Vec<&str> = headers.iter().map(|_| "---").collect();
    writeln!(out, "| {} |", sep.join(" | "))?;

    for row in rows {
        let cells: Vec<String> = (0..headers.len())
            .map(|i| escape(row.get(i).map(String::as_str).unwrap_or("")))
            .collect();
        writeln!(out, "| {} |", cells.join(" | "))?;
    }
    Ok(())
}

/// Render redacted `--dry-run` request previews to `stdout`.
pub fn write_dry_run(
    requests: &[DryRunRequest],
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&requests, ctx.select.as_deref(), out);
    }

    for req in requests {
        writeln!(out, "[dry-run] {} {}", req.method, req.url)?;
        for (k, v) in &req.headers {
            writeln!(out, "  {k}: {v}")?;
        }
        if let Some(ref body) = req.body {
            writeln!(out, "  body: {}", serde_json::to_string(body)?)?;
        }
    }
    Ok(())
}

/// Render quiet IDs (one per line) to `stdout`.
pub fn write_quiet_ids(ids: &[String], out: &mut dyn Write) -> Result<()> {
    for id in ids {
        if !id.is_empty() {
            writeln!(out, "{id}")?;
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_project_json_value_top_level_and_custom_field() {
        let entity = json!({
            "id": "ent-1",
            "name": "ESP32",
            "description": "MCU",
            "quantity": 3,
            "fields": [
                {"name": "Voltage", "type": "number", "numberValue": 3.3, "value": "3.3"}
            ]
        });
        let projected = project_json_value(&entity, &["id".into(), "name".into(), "fields".into()]);
        assert_eq!(projected.as_object().unwrap().len(), 3);
        assert_eq!(projected["id"], "ent-1");
        assert_eq!(projected["name"], "ESP32");
        assert!(projected.get("description").is_none());

        // Also supports selecting custom field by name
        let projected_custom = project_json_value(&entity, &["id".into(), "Voltage".into()]);
        assert_eq!(projected_custom["id"], "ent-1");
        assert_eq!(projected_custom["Voltage"], 3.3);
    }

    #[test]
    fn test_write_compact_json_is_single_line() {
        let mut buf = Vec::new();
        let data = vec![json!({"id": "1", "name": "A", "extra": true})];
        write_compact_json(&data, Some(&["id".into(), "name".into()]), &mut buf).unwrap();
        let s = String::from_utf8(buf).unwrap();
        assert_eq!(s, "[{\"id\":\"1\",\"name\":\"A\"}]\n");
    }

    #[test]
    fn test_write_markdown_table() {
        let mut buf = Vec::new();
        write_markdown_table(
            &["Name".into(), "Manufacturer".into()],
            &[vec!["ESP32".into(), "Espressif | Dev".into()]],
            &mut buf,
        )
        .unwrap();
        let s = String::from_utf8(buf).unwrap();
        assert!(s.contains("| Name | Manufacturer |"));
        assert!(s.contains("| --- | --- |"));
        assert!(s.contains("| ESP32 | Espressif \\| Dev |"));
    }
}

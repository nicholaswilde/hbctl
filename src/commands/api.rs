use std::io::Write;

use serde_json::Value;

use crate::cli::ApiArgs;
use crate::client::{ApiResponseBody, HomeboxClient};
use crate::commands::read_file_or_stdin;
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, OutputContext,
};

pub fn handle(
    args: &ApiArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    HomeboxClient::parse_http_method(&args.method)?;
    let query = parse_query_pairs(&args.query)?;
    let body = parse_body(args)?;

    if dry_run {
        let base_url = config.require_base_url()?;
        let preview =
            HomeboxClient::build_api_dry_run(base_url, &args.method, &args.path, &query, body)?;
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let resp = client.raw_request(&args.method, &args.path, &query, body.as_ref())?;

    match resp.body {
        ApiResponseBody::Empty => Ok(()),
        ApiResponseBody::Text(text) => {
            if ctx.format == OutputFormat::Json {
                return write_compact_json(&Value::String(text), None, out);
            }
            write!(out, "{text}")?;
            if !text.ends_with('\n') {
                writeln!(out)?;
            }
            Ok(())
        }
        ApiResponseBody::Json(value) => render_json_response(&value, ctx, out),
    }
}

fn render_json_response(value: &Value, ctx: &OutputContext, out: &mut dyn Write) -> Result<()> {
    if ctx.quiet {
        let ids = extract_quiet_ids(value);
        return write_quiet_ids(&ids, out);
    }

    if ctx.format == OutputFormat::Json {
        return write_compact_json(value, ctx.select.as_deref(), out);
    }

    if let Some(ref select) = ctx.select {
        return match value {
            Value::Array(items) => write_selected_table(items, select, ctx.format, out),
            other => write_selected_table(std::slice::from_ref(other), select, ctx.format, out),
        };
    }

    write_compact_json(value, None, out)
}

fn parse_query_pairs(raw: &[String]) -> Result<Vec<(String, String)>> {
    let mut pairs = Vec::with_capacity(raw.len());
    for entry in raw {
        let Some((k, v)) = entry.split_once('=') else {
            return Err(HbctlError::InvalidInput(format!(
                "invalid --query '{entry}' (expected KEY=VALUE)"
            )));
        };
        let key = k.trim();
        if key.is_empty() {
            return Err(HbctlError::InvalidInput(format!(
                "invalid --query '{entry}' (empty key)"
            )));
        }
        pairs.push((key.to_string(), v.to_string()));
    }
    Ok(pairs)
}

fn parse_body(args: &ApiArgs) -> Result<Option<Value>> {
    if let Some(ref raw) = args.data {
        let val: Value = serde_json::from_str(raw)
            .map_err(|e| HbctlError::InvalidInput(format!("invalid JSON in --data: {e}")))?;
        return Ok(Some(val));
    }
    if let Some(ref src) = args.from_json {
        let raw = read_file_or_stdin(src)?;
        let val: Value = serde_json::from_str(&raw)
            .map_err(|e| HbctlError::InvalidInput(format!("invalid JSON from '{src}': {e}")))?;
        return Ok(Some(val));
    }
    Ok(None)
}

fn extract_quiet_ids(value: &Value) -> Vec<String> {
    match value {
        Value::Object(map) => {
            if let Some(id) = id_from_value(value) {
                return vec![id];
            }
            if let Some(Value::Array(items)) = map.get("items") {
                return items.iter().filter_map(id_from_value).collect();
            }
            Vec::new()
        }
        Value::Array(items) => items.iter().filter_map(id_from_value).collect(),
        _ => Vec::new(),
    }
}

fn id_from_value(value: &Value) -> Option<String> {
    let id = value.as_object()?.get("id")?;
    match id {
        Value::String(s) if !s.trim().is_empty() => Some(s.clone()),
        Value::Number(n) => Some(n.to_string()),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_parse_query_pairs() {
        let parsed = parse_query_pairs(&[
            "status=both".to_string(),
            "expr=a=b".to_string(),
            "empty=".to_string(),
        ])
        .unwrap();
        assert_eq!(
            parsed,
            vec![
                ("status".to_string(), "both".to_string()),
                ("expr".to_string(), "a=b".to_string()),
                ("empty".to_string(), String::new()),
            ]
        );

        assert!(parse_query_pairs(&["missing_eq".to_string()]).is_err());
        assert!(parse_query_pairs(&["=val".to_string()]).is_err());
    }

    #[test]
    fn test_extract_quiet_ids() {
        assert_eq!(
            extract_quiet_ids(&json!({ "id": "item-1", "name": "Drill" })),
            vec!["item-1"]
        );
        assert_eq!(
            extract_quiet_ids(&json!([{ "id": "a" }, { "id": 42 }, { "name": "no-id" }])),
            vec!["a", "42"]
        );
        assert_eq!(
            extract_quiet_ids(&json!({ "items": [{ "id": "x1" }, { "id": "x2" }], "total": 2 })),
            vec!["x1", "x2"]
        );
    }
}

use std::io::Write;

use serde_json::{Map, Value};

use crate::cli::{ExportArgs, ExportFormat, ExportSort};
use crate::client::resolve::Resolver;
use crate::client::{HomeboxClient, ListEntitiesQuery};
use crate::config::AppConfig;
use crate::error::Result;
use crate::output::{
    write_compact_json, write_csv, write_markdown_table, write_quiet_ids, OutputContext,
};

pub fn handle(
    args: &ExportArgs,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    _err: &mut dyn Write,
) -> Result<()> {
    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);

    let mut query = ListEntitiesQuery::default();
    if let Some(ref tag) = args.tag {
        query.tag_ids.push(resolver.resolve_tag_id(tag, false)?);
    }

    let mut entities = client.list_entities(&query, true)?;

    // Hydrate details when custom fields are requested or filtered on
    if args.has_field.is_some() || !args.fields.is_empty() {
        entities = client.hydrate_entity_fields(entities)?;
    }

    if let Some(ref required_field) = args.has_field {
        entities.retain(|e| {
            e.find_field(required_field).is_some() || e.field_value(required_field).is_some()
        });
    }

    match args.sort {
        ExportSort::Name => entities.sort_by(|a, b| {
            a.name
                .to_ascii_lowercase()
                .cmp(&b.name.to_ascii_lowercase())
                .then_with(|| a.id.cmp(&b.id))
        }),
        ExportSort::Id => entities.sort_by(|a, b| a.id.cmp(&b.id)),
    }

    if ctx.quiet {
        let ids: Vec<String> = entities.iter().map(|e| e.id.clone()).collect();
        return write_quiet_ids(&ids, out);
    }

    let mut headers = vec![
        "id".to_string(),
        "name".to_string(),
        "quantity".to_string(),
        "tags".to_string(),
    ];
    for field in &args.fields {
        headers.push(field.clone());
    }

    let rows: Vec<Vec<String>> = entities
        .iter()
        .map(|e| {
            let tags = e
                .tags
                .iter()
                .map(|t| t.name.as_str())
                .collect::<Vec<_>>()
                .join(", ");
            let mut row = vec![e.id.clone(), e.name.clone(), e.quantity.to_string(), tags];
            for col in &args.fields {
                row.push(e.field_value(col).unwrap_or_default());
            }
            row
        })
        .collect();

    match args.format {
        ExportFormat::Json => {
            if args.fields.is_empty() {
                write_compact_json(&entities, ctx.select.as_deref(), out)
            } else {
                let records: Vec<Value> = entities
                    .iter()
                    .map(|e| {
                        let mut map = Map::new();
                        map.insert("id".to_string(), Value::String(e.id.clone()));
                        map.insert("name".to_string(), Value::String(e.name.clone()));
                        map.insert("quantity".to_string(), Value::from(e.quantity));
                        let tag_names: Vec<Value> = e
                            .tags
                            .iter()
                            .map(|t| Value::String(t.name.clone()))
                            .collect();
                        map.insert("tags".to_string(), Value::Array(tag_names));
                        for col in &args.fields {
                            let val = e.field_value(col).unwrap_or_default();
                            map.insert(col.clone(), Value::String(val));
                        }
                        Value::Object(map)
                    })
                    .collect();
                write_compact_json(&records, ctx.select.as_deref(), out)
            }
        }
        ExportFormat::Csv => write_csv(&headers, &rows, out),
        ExportFormat::Markdown => write_markdown_table(&headers, &rows, out),
    }
}

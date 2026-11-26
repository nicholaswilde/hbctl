use std::io::Write;

use serde_json::{Map, Value};

use crate::cli::{ExportArgs, ExportFormat, ExportSort};
use crate::client::models::Entity;
use crate::client::resolve::Resolver;
use crate::client::{HomeboxClient, ListEntitiesQuery};
use crate::config::AppConfig;
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_csv_with_options, write_markdown_table_with_options, write_quiet_ids,
    OutputContext, TableExportOptions,
};

#[derive(Debug, Clone, PartialEq, Eq)]
struct ExportColumn {
    key: String,
    header: String,
}

fn parse_column_spec(spec: &str) -> Result<ExportColumn> {
    if let Some((raw_key, raw_alias)) = spec.split_once('=') {
        let key = raw_key.trim();
        let alias = raw_alias.trim();
        if key.is_empty() || alias.is_empty() {
            return Err(HbctlError::InvalidInput(format!(
                "invalid --columns spec '{spec}': key and alias must be non-empty"
            )));
        }
        Ok(ExportColumn {
            key: key.to_string(),
            header: alias.to_string(),
        })
    } else {
        let key = spec.trim();
        if key.is_empty() {
            return Err(HbctlError::InvalidInput(format!(
                "invalid --columns spec '{spec}': column key cannot be empty"
            )));
        }
        Ok(ExportColumn {
            key: key.to_string(),
            header: key.to_string(),
        })
    }
}

fn resolve_export_columns(
    args: &ExportArgs,
    select: Option<&[String]>,
) -> Result<Vec<ExportColumn>> {
    if !args.columns.is_empty() {
        return args.columns.iter().map(|s| parse_column_spec(s)).collect();
    }
    if let Some(sel) = select {
        if !sel.is_empty() {
            return sel.iter().map(|s| parse_column_spec(s)).collect();
        }
    }
    let mut cols = vec![
        ExportColumn {
            key: "id".to_string(),
            header: "id".to_string(),
        },
        ExportColumn {
            key: "name".to_string(),
            header: "name".to_string(),
        },
        ExportColumn {
            key: "quantity".to_string(),
            header: "quantity".to_string(),
        },
        ExportColumn {
            key: "tags".to_string(),
            header: "tags".to_string(),
        },
    ];
    for field in &args.fields {
        cols.push(ExportColumn {
            key: field.clone(),
            header: field.clone(),
        });
    }
    Ok(cols)
}

fn is_summary_builtin_column(key: &str) -> bool {
    matches!(
        key.trim().to_ascii_lowercase().as_str(),
        "id" | "name"
            | "description"
            | "quantity"
            | "qty"
            | "tags"
            | "assetid"
            | "asset_id"
            | "entitytypeid"
            | "entity_type_id"
            | "entitytype"
            | "entity_type"
            | "type"
            | "parentid"
            | "parent_id"
            | "purchaseprice"
            | "purchase_price"
            | "purchasedate"
            | "purchase_date"
            | "purchasefrom"
            | "purchase_from"
            | "createdat"
            | "created_at"
            | "updatedat"
            | "updated_at"
            | "attachments"
    )
}

fn extract_column_value(entity: &Entity, key: &str) -> Option<String> {
    let trimmed = key.trim();
    match trimmed.to_ascii_lowercase().as_str() {
        "id" => Some(entity.id.clone()).filter(|s| !s.trim().is_empty()),
        "name" => Some(entity.name.clone()).filter(|s| !s.trim().is_empty()),
        "description" => Some(entity.description.clone()).filter(|s| !s.trim().is_empty()),
        "quantity" | "qty" => Some(entity.quantity.to_string()),
        "tags" => {
            let joined = entity
                .tags
                .iter()
                .map(|t| t.name.as_str())
                .collect::<Vec<_>>()
                .join(", ");
            if joined.trim().is_empty() {
                None
            } else {
                Some(joined)
            }
        }
        "assetid" | "asset_id" => entity
            .asset_id
            .as_deref()
            .filter(|s| !s.trim().is_empty())
            .map(ToOwned::to_owned),
        "entitytypeid" | "entity_type_id" => entity
            .effective_entity_type_id()
            .filter(|s| !s.trim().is_empty())
            .map(ToOwned::to_owned),
        "entitytype" | "entity_type" | "type" => entity
            .entity_type
            .as_ref()
            .map(|et| et.name.as_str())
            .filter(|s| !s.trim().is_empty())
            .or_else(|| {
                entity
                    .effective_entity_type_id()
                    .filter(|s| !s.trim().is_empty())
            })
            .map(ToOwned::to_owned),
        "parentid" | "parent_id" => entity
            .parent_id
            .as_deref()
            .filter(|s| !s.trim().is_empty())
            .map(ToOwned::to_owned),
        "purchaseprice" | "purchase_price" => entity.purchase_price.map(|p| format!("{p:.2}")),
        "purchasedate" | "purchase_date" => entity
            .purchase_date
            .as_deref()
            .filter(|s| !s.trim().is_empty())
            .map(ToOwned::to_owned),
        "purchasefrom" | "purchase_from" => entity
            .purchase_from
            .as_deref()
            .filter(|s| !s.trim().is_empty())
            .map(ToOwned::to_owned),
        "createdat" | "created_at" => entity
            .created_at
            .as_deref()
            .filter(|s| !s.trim().is_empty())
            .map(ToOwned::to_owned),
        "updatedat" | "updated_at" => entity
            .updated_at
            .as_deref()
            .filter(|s| !s.trim().is_empty())
            .map(ToOwned::to_owned),
        "attachments" => Some(entity.attachments.len().to_string()),
        _ => entity.field_value(trimmed).filter(|v| !v.trim().is_empty()),
    }
}

pub fn handle(
    args: &ExportArgs,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    _err: &mut dyn Write,
) -> Result<()> {
    let columns = resolve_export_columns(args, ctx.select.as_deref())?;

    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);

    let mut query = ListEntitiesQuery::default();
    if let Some(ref tag) = args.tag {
        query.tag_ids.push(resolver.resolve_tag_id(tag, false)?);
    }

    let mut entities = client.list_entities(&query, true)?;

    // Hydrate details when custom fields are requested or filtered on
    let needs_hydration = args.has_field.is_some()
        || !args.fields.is_empty()
        || columns.iter().any(|c| !is_summary_builtin_column(&c.key));
    if needs_hydration {
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

    let headers: Vec<String> = columns.iter().map(|c| c.header.clone()).collect();
    let rows: Vec<Vec<String>> = entities
        .iter()
        .map(|e| {
            columns
                .iter()
                .map(|col| extract_column_value(e, &col.key).unwrap_or_default())
                .collect()
        })
        .collect();
    let export_opts = TableExportOptions {
        align: args.align,
        empty: &args.empty,
    };

    match args.format {
        ExportFormat::Json => {
            if !args.columns.is_empty() {
                let records: Vec<Value> = entities
                    .iter()
                    .map(|e| {
                        let mut map = Map::new();
                        for col in &columns {
                            let val = extract_column_value(e, &col.key)
                                .unwrap_or_else(|| args.empty.clone());
                            map.insert(col.header.clone(), Value::String(val));
                        }
                        Value::Object(map)
                    })
                    .collect();
                write_compact_json(&records, None, out)
            } else if args.fields.is_empty() {
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
        ExportFormat::Csv => write_csv_with_options(&headers, &rows, &export_opts, out),
        ExportFormat::Markdown => {
            write_markdown_table_with_options(&headers, &rows, &export_opts, out)
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::client::models::{CustomField, FieldValueType, Tag};

    fn make_args() -> ExportArgs {
        ExportArgs {
            tag: None,
            has_field: None,
            fields: Vec::new(),
            sort: ExportSort::Name,
            format: ExportFormat::Markdown,
            columns: Vec::new(),
            align: crate::output::MarkdownAlign::Default,
            empty: String::new(),
        }
    }

    #[test]
    fn test_export_column_parsing_precedence_and_extraction() {
        assert_eq!(
            parse_column_spec("name=Container / Item").unwrap(),
            ExportColumn {
                key: "name".into(),
                header: "Container / Item".into(),
            }
        );
        assert_eq!(
            parse_column_spec(" Tare Weight (g) ").unwrap(),
            ExportColumn {
                key: "Tare Weight (g)".into(),
                header: "Tare Weight (g)".into(),
            }
        );
        assert!(parse_column_spec("").is_err());
        assert!(parse_column_spec("=Alias").is_err());
        assert!(parse_column_spec("name=").is_err());

        // --columns takes precedence over --select and default + --field
        let mut args = make_args();
        args.fields = vec!["Voltage".into()];
        args.columns = vec!["name=Container / Item".into(), "Tare Weight (g)".into()];
        let sel = vec!["id".to_string(), "Manufacturer".to_string()];
        let cols = resolve_export_columns(&args, Some(&sel)).unwrap();
        assert_eq!(
            cols,
            vec![
                ExportColumn {
                    key: "name".into(),
                    header: "Container / Item".into()
                },
                ExportColumn {
                    key: "Tare Weight (g)".into(),
                    header: "Tare Weight (g)".into()
                },
            ]
        );

        // --select takes precedence over default + --field
        args.columns.clear();
        let cols_sel = resolve_export_columns(&args, Some(&sel)).unwrap();
        assert_eq!(
            cols_sel,
            vec![
                ExportColumn {
                    key: "id".into(),
                    header: "id".into()
                },
                ExportColumn {
                    key: "Manufacturer".into(),
                    header: "Manufacturer".into()
                },
            ]
        );

        // Default fallback preserves id,name,quantity,tags + --field
        let cols_def = resolve_export_columns(&args, None).unwrap();
        assert_eq!(cols_def.len(), 5);
        assert_eq!(cols_def[0].key, "id");
        assert_eq!(cols_def[4].key, "Voltage");

        assert!(is_summary_builtin_column("name"));
        assert!(is_summary_builtin_column("purchasePrice"));
        assert!(!is_summary_builtin_column("Manufacturer"));
        assert!(!is_summary_builtin_column("Tare Weight (g)"));

        let ent = Entity {
            id: "ent-1".into(),
            name: "Jar A".into(),
            quantity: 2,
            tags: vec![Tag {
                id: "t1".into(),
                name: "pantry".into(),
                ..Default::default()
            }],
            purchase_price: Some(4.5),
            fields: Some(vec![
                CustomField::new_typed("Tare Weight (g)", FieldValueType::Number, "145").unwrap(),
                CustomField::new_typed("Notes", FieldValueType::Text, "   ").unwrap(),
            ]),
            ..Default::default()
        };
        assert_eq!(extract_column_value(&ent, "name").as_deref(), Some("Jar A"));
        assert_eq!(
            extract_column_value(&ent, "purchasePrice").as_deref(),
            Some("4.50")
        );
        assert_eq!(
            extract_column_value(&ent, "Tare Weight (g)").as_deref(),
            Some("145")
        );
        assert_eq!(extract_column_value(&ent, "Notes"), None);
        assert_eq!(extract_column_value(&ent, "Missing"), None);
    }
}

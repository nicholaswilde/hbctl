use std::io::Write;

use crate::cli::SearchArgs;
use crate::client::models::Entity;
use crate::client::resolve::Resolver;
use crate::client::{HomeboxClient, ListEntitiesQuery};
use crate::commands::render_entities;
use crate::config::AppConfig;
use crate::error::{HbctlError, Result};
use crate::output::OutputContext;

#[derive(Debug, PartialEq, Eq)]
struct FieldFilter {
    key: String,
    value: Option<String>,
}

fn parse_field_filter(spec: &str) -> Result<FieldFilter> {
    if let Some((raw_key, raw_val)) = spec.split_once('=') {
        let key = raw_key.trim();
        if key.is_empty() {
            return Err(HbctlError::InvalidInput(format!(
                "invalid --field '{spec}': key cannot be empty"
            )));
        }
        Ok(FieldFilter {
            key: key.to_string(),
            value: Some(raw_val.trim().to_ascii_lowercase()),
        })
    } else {
        let key = spec.trim();
        if key.is_empty() {
            return Err(HbctlError::InvalidInput(format!(
                "invalid --field '{spec}': key cannot be empty"
            )));
        }
        Ok(FieldFilter {
            key: key.to_string(),
            value: None,
        })
    }
}

pub fn handle(
    args: &SearchArgs,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    _err: &mut dyn Write,
) -> Result<()> {
    let field_filters = args
        .fields
        .iter()
        .map(|s| parse_field_filter(s))
        .collect::<Result<Vec<_>>>()?;

    let client = HomeboxClient::from_config(config)?;
    let mut resolver = Resolver::new(&client);

    let mut query = ListEntitiesQuery {
        query: args.query.clone(),
        ..Default::default()
    };
    if let Some(ref tag) = args.tag {
        query.tag_ids.push(resolver.resolve_tag_id(tag, false)?);
    }

    let mut entities = client.list_entities(&query, true)?;

    let needs_structured = args.model.is_some()
        || args.serial.is_some()
        || args.manufacturer.is_some()
        || !field_filters.is_empty();

    if needs_structured {
        entities = client.hydrate_entity_fields(entities)?;
        entities.retain(|e| {
            matches_opt(
                e,
                args.model.as_deref(),
                &["Model Number", "model", "modelNumber"],
            ) && matches_opt(
                e,
                args.serial.as_deref(),
                &["Serial Number", "serial", "serialNumber"],
            ) && matches_opt(
                e,
                args.manufacturer.as_deref(),
                &["Manufacturer", "manufacturer"],
            ) && field_filters.iter().all(|f| matches_field_filter(e, f))
        });
    }

    render_entities(&entities, ctx, out)
}

fn matches_field_filter(entity: &Entity, filter: &FieldFilter) -> bool {
    let Some(val) = entity.field_value(&filter.key) else {
        return false;
    };
    match &filter.value {
        None => !val.trim().is_empty(),
        Some(needle_lower) => val.to_ascii_lowercase().contains(needle_lower),
    }
}

fn matches_opt(entity: &Entity, needle: Option<&str>, keys: &[&str]) -> bool {
    let Some(needle) = needle else {
        return true;
    };
    let needle_lower = needle.trim().to_ascii_lowercase();
    keys.iter().any(|k| {
        entity
            .field_value(k)
            .map(|val| val.to_ascii_lowercase().contains(&needle_lower))
            .unwrap_or(false)
    })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::client::models::{CustomField, FieldValueType};

    fn sample_entity(id: &str, fields: Vec<CustomField>) -> Entity {
        Entity {
            id: id.into(),
            name: format!("Item {id}"),
            quantity: 1,
            fields: Some(fields),
            ..Default::default()
        }
    }

    #[test]
    fn test_parse_field_filter_and_matching() {
        assert_eq!(
            parse_field_filter(" ASIN ").unwrap(),
            FieldFilter {
                key: "ASIN".into(),
                value: None
            }
        );
        assert_eq!(
            parse_field_filter("Order Number = 112-ABC ").unwrap(),
            FieldFilter {
                key: "Order Number".into(),
                value: Some("112-abc".into())
            }
        );
        assert_eq!(
            parse_field_filter("Formula=a=b").unwrap(),
            FieldFilter {
                key: "Formula".into(),
                value: Some("a=b".into())
            }
        );
        assert!(parse_field_filter("").is_err());
        assert!(parse_field_filter("   ").is_err());
        assert!(parse_field_filter("=val").is_err());

        let populated = sample_entity(
            "e1",
            vec![
                CustomField::new_typed("Manufacturer", FieldValueType::Text, "Fluke").unwrap(),
                CustomField::new_typed("ASIN", FieldValueType::Text, "B00012345").unwrap(),
                CustomField::new_typed("Tare Weight (g)", FieldValueType::Number, "25.5").unwrap(),
                CustomField::new_typed("Calibrated", FieldValueType::Boolean, "true").unwrap(),
                CustomField::new_typed("Formula", FieldValueType::Text, "a=b+c").unwrap(),
            ],
        );
        let blank_asin = sample_entity(
            "e2",
            vec![
                CustomField::new_typed("Manufacturer", FieldValueType::Text, "Fluke").unwrap(),
                CustomField::new_typed("ASIN", FieldValueType::Text, "   ").unwrap(),
            ],
        );

        let exists_asin = parse_field_filter("asin").unwrap();
        assert!(matches_field_filter(&populated, &exists_asin));
        assert!(!matches_field_filter(&blank_asin, &exists_asin));

        let exists_tare = parse_field_filter("Tare Weight (g)").unwrap();
        let exists_cal = parse_field_filter("Calibrated").unwrap();
        assert!(matches_field_filter(&populated, &exists_tare));
        assert!(matches_field_filter(&populated, &exists_cal));

        let substr_asin = parse_field_filter("ASIN=000123").unwrap();
        assert!(matches_field_filter(&populated, &substr_asin));
        assert!(!matches_field_filter(&blank_asin, &substr_asin));

        let substr_formula = parse_field_filter("Formula=A=B").unwrap();
        assert!(matches_field_filter(&populated, &substr_formula));

        let filters = [
            exists_asin,
            parse_field_filter("Tare Weight (g)=25").unwrap(),
        ];
        assert!(
            matches_opt(&populated, Some("fluke"), &["Manufacturer"])
                && filters.iter().all(|f| matches_field_filter(&populated, f))
        );
        assert!(
            !(matches_opt(&blank_asin, Some("fluke"), &["Manufacturer"])
                && filters.iter().all(|f| matches_field_filter(&blank_asin, f)))
        );
    }
}

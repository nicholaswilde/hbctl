use std::io::Write;

use crate::cli::SearchArgs;
use crate::client::models::{entity_warranty_expiring_within, today_utc_days, Entity};
use crate::client::resolve::Resolver;
use crate::client::{HomeboxClient, ListEntitiesQuery};
use crate::commands::{render_entities, render_entities_with_paths};
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

    let query_text = args
        .query
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty());

    let needs_structured = args.model.is_some()
        || args.serial.is_some()
        || args.manufacturer.is_some()
        || !field_filters.is_empty();

    let mut query = ListEntitiesQuery {
        query: if args.any && needs_structured {
            None
        } else {
            args.query.clone()
        },
        include_archived: args.include_archived || args.archived_only,
        ..Default::default()
    };
    if let Some(ref tag) = args.tag {
        query.tag_ids.push(resolver.resolve_tag_id(tag, false)?);
    }
    if let Some(ref et) = args.entity_type {
        query.entity_type_id = Some(resolver.resolve_entity_type_id(et)?);
    }
    let parent_filter = match args.parent {
        Some(ref p) => Some(resolver.resolve_parent_id(p)?),
        None => None,
    };

    let mut entities = client.list_entities(&query, true)?;

    if let Some(ref target_parent) = parent_filter {
        entities.retain(|e| match target_parent {
            Some(pid) => e.parent_id.as_deref() == Some(pid.as_str()),
            None => e
                .parent_id
                .as_deref()
                .map(|s| s.trim().is_empty())
                .unwrap_or(true),
        });
    }

    if args.archived_only {
        entities.retain(|e| e.archived.unwrap_or(false));
    }

    if needs_structured || args.warranty_expiring.is_some() {
        entities = client.hydrate_entity_fields(entities)?;
    }

    if let Some(days) = args.warranty_expiring {
        let today = today_utc_days();
        entities.retain(|e| entity_warranty_expiring_within(e, days, today));
    }

    if needs_structured {
        let or_query = if args.any { query_text } else { None };
        entities.retain(|e| {
            entity_matches_filters(
                e,
                or_query,
                args.model.as_deref(),
                args.serial.as_deref(),
                args.manufacturer.as_deref(),
                &field_filters,
                args.any,
            )
        });
    }

    if let Some(limit) = args.limit {
        entities.truncate(limit);
    }

    if args.with_path {
        let ids: Vec<String> = entities.iter().map(|e| e.id.clone()).collect();
        let paths = client.get_entity_paths_by_ids(&ids)?;
        return render_entities_with_paths(&entities, &paths, ctx, out);
    }

    render_entities(&entities, ctx, out)
}

fn matches_query_text(entity: &Entity, needle: &str) -> bool {
    let needle_lower = needle.trim().to_ascii_lowercase();
    if needle_lower.is_empty() {
        return true;
    }
    if entity.name.to_ascii_lowercase().contains(&needle_lower) {
        return true;
    }
    for opt in [
        Some(entity.description.as_str()),
        entity.model_number.as_deref(),
        entity.serial_number.as_deref(),
        entity.manufacturer.as_deref(),
        entity.notes.as_deref(),
    ]
    .into_iter()
    .flatten()
    {
        if opt.to_ascii_lowercase().contains(&needle_lower) {
            return true;
        }
    }
    entity.fields_slice().iter().any(|f| {
        f.display_value()
            .to_ascii_lowercase()
            .contains(&needle_lower)
    })
}

fn entity_matches_filters(
    entity: &Entity,
    query_text: Option<&str>,
    model: Option<&str>,
    serial: Option<&str>,
    manufacturer: Option<&str>,
    field_filters: &[FieldFilter],
    any_mode: bool,
) -> bool {
    if !any_mode {
        return matches_opt(entity, model, &["Model Number", "model", "modelNumber"])
            && matches_opt(entity, serial, &["Serial Number", "serial", "serialNumber"])
            && matches_opt(entity, manufacturer, &["Manufacturer", "manufacturer"])
            && field_filters
                .iter()
                .all(|f| matches_field_filter(entity, f));
    }

    let mut has_condition = false;
    let mut matched = false;

    if let Some(q) = query_text.map(str::trim).filter(|s| !s.is_empty()) {
        has_condition = true;
        matched |= matches_query_text(entity, q);
    }
    if model.is_some() {
        has_condition = true;
        matched |= matches_opt(entity, model, &["Model Number", "model", "modelNumber"]);
    }
    if serial.is_some() {
        has_condition = true;
        matched |= matches_opt(entity, serial, &["Serial Number", "serial", "serialNumber"]);
    }
    if manufacturer.is_some() {
        has_condition = true;
        matched |= matches_opt(entity, manufacturer, &["Manufacturer", "manufacturer"]);
    }
    for filter in field_filters {
        has_condition = true;
        matched |= matches_field_filter(entity, filter);
    }

    !has_condition || matched
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

    #[test]
    fn test_entity_matches_filters_any_vs_and() {
        let by_model = Entity {
            id: "m1".into(),
            name: "Smart Lock".into(),
            quantity: 1,
            fields: Some(vec![CustomField::new_typed(
                "Model Number",
                FieldValueType::Text,
                "ABC-100",
            )
            .unwrap()]),
            ..Default::default()
        };
        let by_notes = sample_entity(
            "n1",
            vec![CustomField::new_typed("Notes", FieldValueType::Text, "ASIN B001").unwrap()],
        );
        let by_name = sample_entity("q1", vec![]);
        let mut by_name = by_name;
        by_name.name = "Fluke 87V".into();

        let notes_filter = vec![parse_field_filter("Notes=B001").unwrap()];

        // Default AND mode requires both model and Notes=B001
        assert!(!entity_matches_filters(
            &by_model,
            None,
            Some("ABC"),
            None,
            None,
            &notes_filter,
            false
        ));
        assert!(!entity_matches_filters(
            &by_notes,
            None,
            Some("ABC"),
            None,
            None,
            &notes_filter,
            false
        ));

        // --any mode matches either model OR Notes=B001
        assert!(entity_matches_filters(
            &by_model,
            None,
            Some("ABC"),
            None,
            None,
            &notes_filter,
            true
        ));
        assert!(entity_matches_filters(
            &by_notes,
            None,
            Some("ABC"),
            None,
            None,
            &notes_filter,
            true
        ));
        assert!(!entity_matches_filters(
            &by_name,
            None,
            Some("ABC"),
            None,
            None,
            &notes_filter,
            true
        ));

        // --any with positional query + structured filter matches either
        assert!(entity_matches_filters(
            &by_name,
            Some("Fluke"),
            None,
            None,
            None,
            &notes_filter,
            true
        ));
        assert!(entity_matches_filters(
            &by_notes,
            Some("Fluke"),
            None,
            None,
            None,
            &notes_filter,
            true
        ));

        // Multiple --field filters under --any match if any one matches
        let multi_fields = vec![
            parse_field_filter("ASIN=MISSING").unwrap(),
            parse_field_filter("Notes=B001").unwrap(),
        ];
        assert!(entity_matches_filters(
            &by_notes,
            None,
            None,
            None,
            None,
            &multi_fields,
            true
        ));
        assert!(!entity_matches_filters(
            &by_notes,
            None,
            None,
            None,
            None,
            &multi_fields,
            false
        ));
    }
}

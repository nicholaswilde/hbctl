use std::io::Write;

use crate::cli::SearchArgs;
use crate::client::models::Entity;
use crate::client::resolve::Resolver;
use crate::client::{HomeboxClient, ListEntitiesQuery};
use crate::commands::render_entities;
use crate::config::AppConfig;
use crate::error::Result;
use crate::output::OutputContext;

pub fn handle(
    args: &SearchArgs,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    _err: &mut dyn Write,
) -> Result<()> {
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

    let needs_structured =
        args.model.is_some() || args.serial.is_some() || args.manufacturer.is_some();

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
            )
        });
    }

    render_entities(&entities, ctx, out)
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

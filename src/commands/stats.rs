use std::collections::BTreeMap;
use std::io::Write;

use serde::Serialize;

use crate::cli::{StatsArgs, StatsCommands};
use crate::client::models::{
    entity_warranty_expiring_within, parse_ymd_days, today_utc_days, OrganizerStatistic,
};
use crate::client::{HomeboxClient, ListEntitiesQuery};
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct StatsOverview {
    total_items: u64,
    total_item_price: f64,
    total_locations: u64,
    total_tags: u64,
    total_users: u64,
    total_with_warranty: u64,
    #[serde(skip_serializing_if = "Option::is_none")]
    upcoming_maintenance: Option<u64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    warranty_expiring_days: Option<u32>,
    #[serde(skip_serializing_if = "Option::is_none")]
    warranty_expiring: Option<u64>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct EntityTypeStat {
    id: String,
    name: String,
    is_location: bool,
    count: u64,
    total_price: f64,
}

pub fn handle(
    args: &StatsArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let sub = args.command.as_ref().unwrap_or(&StatsCommands::Overview);
    match sub {
        StatsCommands::Overview => handle_overview(args.warranty_days, dry_run, config, ctx, out),
        StatsCommands::Tags => handle_organizer_stats("tags", dry_run, config, ctx, out),
        StatsCommands::Locations => handle_organizer_stats("locations", dry_run, config, ctx, out),
        StatsCommands::EntityTypes => handle_entity_types(dry_run, config, ctx, out),
        StatsCommands::PurchasePrice { start, end } => {
            handle_purchase_price(start.as_deref(), end.as_deref(), dry_run, config, ctx, out)
        }
    }
}

fn handle_overview(
    warranty_days: Option<u32>,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let mut previews = vec![
            HomeboxClient::build_dry_run(base_url, "GET", "groups/statistics", None),
            HomeboxClient::build_dry_run(base_url, "GET", "maintenance?status=scheduled", None),
        ];
        if warranty_days.is_some() {
            previews.push(HomeboxClient::build_dry_run(
                base_url, "GET", "entities", None,
            ));
        }
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let stats = client.get_group_statistics()?;
    let upcoming_maintenance = match client.list_maintenance(None, "scheduled") {
        Ok(list) => Some(list.len() as u64),
        Err(HbctlError::Http {
            status: 404 | 405 | 501,
            ..
        }) => None,
        Err(e) => return Err(e),
    };

    let warranty_expiring = if let Some(days) = warranty_days {
        let entities = client.list_entities(&ListEntitiesQuery::default(), true)?;
        let entities = client.hydrate_entity_fields(entities)?;
        let today = today_utc_days();
        Some(
            entities
                .iter()
                .filter(|e| entity_warranty_expiring_within(e, days, today))
                .count() as u64,
        )
    } else {
        None
    };

    let overview = StatsOverview {
        total_items: stats.total_items,
        total_item_price: stats.total_item_price,
        total_locations: stats.total_locations,
        total_tags: stats.total_tags,
        total_users: stats.total_users,
        total_with_warranty: stats.total_with_warranty,
        upcoming_maintenance,
        warranty_expiring_days: warranty_days,
        warranty_expiring,
    };

    if ctx.quiet {
        return write_quiet_ids(&[overview.total_items.to_string()], out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&overview, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&[overview], select, ctx.format, out);
    }

    let mut rows = vec![
        vec!["totalItems".to_string(), overview.total_items.to_string()],
        vec![
            "totalItemPrice".to_string(),
            format!("{:.2}", overview.total_item_price),
        ],
        vec![
            "totalLocations".to_string(),
            overview.total_locations.to_string(),
        ],
        vec!["totalTags".to_string(), overview.total_tags.to_string()],
        vec!["totalUsers".to_string(), overview.total_users.to_string()],
        vec![
            "totalWithWarranty".to_string(),
            overview.total_with_warranty.to_string(),
        ],
    ];
    if let Some(upcoming) = overview.upcoming_maintenance {
        rows.push(vec![
            "upcomingMaintenance".to_string(),
            upcoming.to_string(),
        ]);
    }
    if let (Some(days), Some(count)) = (overview.warranty_expiring_days, overview.warranty_expiring)
    {
        rows.push(vec![
            format!("warrantyExpiring ({days}d)"),
            count.to_string(),
        ]);
    }

    write_table_or_plain(
        &["METRIC".to_string(), "VALUE".to_string()],
        &rows,
        ctx.format,
        out,
    )
}

fn handle_organizer_stats(
    slug: &str,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let preview = HomeboxClient::build_dry_run(
            base_url,
            "GET",
            &format!("groups/statistics/{slug}"),
            None,
        );
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let mut items: Vec<OrganizerStatistic> = match slug {
        "tags" => client.get_tag_statistics()?,
        "locations" => client.get_location_statistics()?,
        _ => unreachable!("unsupported organizer stats slug: {slug}"),
    };
    items.sort_by(|a, b| {
        b.total.total_cmp(&a.total).then_with(|| {
            a.name
                .to_ascii_lowercase()
                .cmp(&b.name.to_ascii_lowercase())
        })
    });

    if ctx.quiet {
        let ids: Vec<String> = items.iter().map(|i| i.id.clone()).collect();
        return write_quiet_ids(&ids, out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&items, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&items, select, ctx.format, out);
    }

    let rows: Vec<Vec<String>> = items
        .iter()
        .map(|s| vec![s.id.clone(), s.name.clone(), format!("{:.2}", s.total)])
        .collect();

    write_table_or_plain(
        &["ID".to_string(), "NAME".to_string(), "TOTAL".to_string()],
        &rows,
        ctx.format,
        out,
    )
}

fn handle_entity_types(
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let previews = vec![
            HomeboxClient::build_dry_run(base_url, "GET", "entity-types", None),
            HomeboxClient::build_dry_run(base_url, "GET", "entities", None),
        ];
        return write_dry_run(&previews, ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let entity_types = client.list_entity_types()?;
    let entities = client.list_entities(&ListEntitiesQuery::default(), true)?;

    let mut map: BTreeMap<String, EntityTypeStat> = BTreeMap::new();
    for et in entity_types {
        map.insert(
            et.id.clone(),
            EntityTypeStat {
                id: et.id,
                name: et.name,
                is_location: et.is_location,
                count: 0,
                total_price: 0.0,
            },
        );
    }

    for entity in &entities {
        let type_id = entity.effective_entity_type_id().map(ToOwned::to_owned);
        let key = type_id.clone().unwrap_or_else(|| "__untyped__".to_string());
        let entry = map.entry(key).or_insert_with(|| {
            let fallback_name = entity
                .entity_type
                .as_ref()
                .map(|et| et.name.trim())
                .filter(|s| !s.is_empty())
                .unwrap_or("(untyped)")
                .to_string();
            let is_loc = entity
                .entity_type
                .as_ref()
                .map(|et| et.is_location)
                .unwrap_or(false);
            EntityTypeStat {
                id: type_id.unwrap_or_default(),
                name: fallback_name,
                is_location: is_loc,
                count: 0,
                total_price: 0.0,
            }
        });
        entry.count += 1;
        entry.total_price += entity.purchase_price.unwrap_or(0.0);
    }

    let mut stats: Vec<EntityTypeStat> = map.into_values().collect();
    stats.sort_by(|a, b| {
        b.count.cmp(&a.count).then_with(|| {
            a.name
                .to_ascii_lowercase()
                .cmp(&b.name.to_ascii_lowercase())
        })
    });

    if ctx.quiet {
        let ids: Vec<String> = stats.iter().map(|s| s.id.clone()).collect();
        return write_quiet_ids(&ids, out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&stats, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&stats, select, ctx.format, out);
    }

    let rows: Vec<Vec<String>> = stats
        .iter()
        .map(|s| {
            vec![
                s.id.clone(),
                s.name.clone(),
                if s.is_location { "yes" } else { "no" }.to_string(),
                s.count.to_string(),
                format!("{:.2}", s.total_price),
            ]
        })
        .collect();

    write_table_or_plain(
        &[
            "ID".to_string(),
            "NAME".to_string(),
            "LOCATION".to_string(),
            "COUNT".to_string(),
            "TOTAL_PRICE".to_string(),
        ],
        &rows,
        ctx.format,
        out,
    )
}

fn validate_ymd_date(raw: Option<&str>) -> Result<Option<String>> {
    let Some(s) = raw.map(str::trim).filter(|s| !s.is_empty()) else {
        return Ok(None);
    };
    if s.len() == 10 && parse_ymd_days(s).is_some() {
        Ok(Some(s.to_string()))
    } else {
        Err(HbctlError::InvalidInput(format!(
            "invalid date '{s}': expected YYYY-MM-DD"
        )))
    }
}

fn short_date(raw: &str) -> &str {
    if raw.len() >= 10 {
        &raw[..10]
    } else {
        raw
    }
}

fn handle_purchase_price(
    start_raw: Option<&str>,
    end_raw: Option<&str>,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let start = validate_ymd_date(start_raw)?;
    let end = validate_ymd_date(end_raw)?;

    if dry_run {
        let base_url = config.require_base_url()?;
        let mut query = Vec::new();
        if let Some(ref s) = start {
            query.push(format!("start={s}"));
        }
        if let Some(ref e) = end {
            query.push(format!("end={e}"));
        }
        let path = if query.is_empty() {
            "groups/statistics/purchase-price".to_string()
        } else {
            format!("groups/statistics/purchase-price?{}", query.join("&"))
        };
        let preview = HomeboxClient::build_dry_run(base_url, "GET", &path, None);
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let pp = client.get_purchase_price_statistics(start.as_deref(), end.as_deref())?;

    if ctx.quiet {
        return write_quiet_ids(&[format!("{:.2}", pp.value_at_end)], out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&pp, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&[pp], select, ctx.format, out);
    }

    let mut rows = vec![vec![
        short_date(&pp.start).to_string(),
        "(start)".to_string(),
        format!("{:.2}", pp.value_at_start),
    ]];
    for entry in &pp.entries {
        rows.push(vec![
            short_date(&entry.date).to_string(),
            entry.name.clone(),
            format!("{:.2}", entry.value),
        ]);
    }
    rows.push(vec![
        short_date(&pp.end).to_string(),
        "(end)".to_string(),
        format!("{:.2}", pp.value_at_end),
    ]);

    write_table_or_plain(
        &["DATE".to_string(), "NAME".to_string(), "VALUE".to_string()],
        &rows,
        ctx.format,
        out,
    )
}

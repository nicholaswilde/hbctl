pub mod attachment;
pub mod auth;
pub mod entity_type;
pub mod export;
pub mod field;
pub mod item;
pub mod search;
pub mod tag;

use std::fs;
use std::io::{self, Read, Write};

use crate::cli::{Cli, Commands};
use crate::client::models::Entity;
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_quiet_ids, write_selected_table, write_table_or_plain, OutputContext,
};

pub fn dispatch(
    cli: &Cli,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    match &cli.command {
        Commands::Auth(args) => auth::handle(
            args,
            cli.dry_run,
            cli.config.as_ref(),
            config,
            ctx,
            out,
            err,
        ),
        Commands::Item(args) => item::handle(args, cli.dry_run, config, ctx, out, err),
        Commands::Attachment(args) => attachment::handle(args, cli.dry_run, config, ctx, out, err),
        Commands::Search(args) => search::handle(args, config, ctx, out, err),
        Commands::Field(args) => field::handle(args, cli.dry_run, config, ctx, out, err),
        Commands::Tag(args) => tag::handle(args, cli.dry_run, config, ctx, out, err),
        Commands::EntityTypes(args) => entity_type::handle(args, config, ctx, out, err),
        Commands::Export(args) => export::handle(args, config, ctx, out, err),
        Commands::Completions { .. } | Commands::Man | Commands::Update { .. } => Ok(()),
    }
}

/// Read UTF-8 text from a file path or `-` (stdin).
pub fn read_file_or_stdin(path: &str) -> Result<String> {
    if path == "-" {
        let mut buf = String::new();
        io::stdin().read_to_string(&mut buf)?;
        Ok(buf)
    } else {
        fs::read_to_string(path).map_err(|e| {
            HbctlError::InvalidInput(format!("failed to read input file '{path}': {e}"))
        })
    }
}

/// Render a list of entities to `stdout` honoring `--quiet`, `--json`, `--select`, and `--output`.
pub fn render_entities(
    entities: &[Entity],
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if ctx.quiet {
        let ids: Vec<String> = entities.iter().map(|e| e.id.clone()).collect();
        return write_quiet_ids(&ids, out);
    }

    if ctx.format == OutputFormat::Json {
        return write_compact_json(&entities, ctx.select.as_deref(), out);
    }

    if let Some(ref select) = ctx.select {
        return write_selected_table(entities, select, ctx.format, out);
    }

    let headers = vec![
        "ID".to_string(),
        "NAME".to_string(),
        "QTY".to_string(),
        "TAGS".to_string(),
        "DESCRIPTION".to_string(),
    ];
    let rows: Vec<Vec<String>> = entities
        .iter()
        .map(|e| {
            let tags = e
                .tags
                .iter()
                .map(|t| t.name.as_str())
                .collect::<Vec<_>>()
                .join(", ");
            vec![
                e.id.clone(),
                e.name.clone(),
                e.quantity.to_string(),
                tags,
                e.description.clone(),
            ]
        })
        .collect();

    write_table_or_plain(&headers, &rows, ctx.format, out)
}

/// Render a single entity to `stdout` honoring `--quiet`, `--json`, `--select`, and `--output`.
pub fn render_entity(entity: &Entity, ctx: &OutputContext, out: &mut dyn Write) -> Result<()> {
    if ctx.quiet {
        return write_quiet_ids(std::slice::from_ref(&entity.id), out);
    }

    if ctx.format == OutputFormat::Json {
        return write_compact_json(entity, ctx.select.as_deref(), out);
    }

    if let Some(ref select) = ctx.select {
        return write_selected_table(std::slice::from_ref(entity), select, ctx.format, out);
    }

    let mut rows = vec![
        vec!["id".to_string(), entity.id.clone()],
        vec!["name".to_string(), entity.name.clone()],
        vec!["quantity".to_string(), entity.quantity.to_string()],
    ];

    if !entity.description.is_empty() {
        rows.push(vec!["description".to_string(), entity.description.clone()]);
    }
    if !entity.tags.is_empty() {
        let names = entity
            .tags
            .iter()
            .map(|t| t.name.as_str())
            .collect::<Vec<_>>()
            .join(", ");
        rows.push(vec!["tags".to_string(), names]);
    }
    if let Some(price) = entity.purchase_price {
        rows.push(vec!["purchasePrice".to_string(), format!("{price:.2}")]);
    }
    if let Some(ref date) = entity.purchase_date {
        rows.push(vec!["purchaseDate".to_string(), date.clone()]);
    }
    if let Some(ref from) = entity.purchase_from {
        rows.push(vec!["purchaseFrom".to_string(), from.clone()]);
    }
    for field in entity.fields_slice() {
        rows.push(vec![format!("field:{}", field.name), field.display_value()]);
    }
    if !entity.attachments.is_empty() {
        rows.push(vec![
            "attachments".to_string(),
            entity.attachments.len().to_string(),
        ]);
    }

    write_table_or_plain(
        &["PROPERTY".to_string(), "VALUE".to_string()],
        &rows,
        ctx.format,
        out,
    )
}

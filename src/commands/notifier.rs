use std::io::{self, IsTerminal, Write};

use serde_json::{json, Map, Value};

use crate::cli::{NotifierArgs, NotifierCommands};
use crate::client::models::{CreateNotifierRequest, Notifier, UpdateNotifierRequest};
use crate::client::HomeboxClient;
use crate::config::{redact_notifier_url, AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

pub fn handle(
    args: &NotifierArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    match &args.command {
        NotifierCommands::List { reveal } => handle_list(*reveal, dry_run, config, ctx, out),
        NotifierCommands::Create(create_args) => {
            handle_create(create_args, dry_run, config, ctx, out)
        }
        NotifierCommands::Update(update_args) => {
            handle_update(update_args, dry_run, config, ctx, out)
        }
        NotifierCommands::Delete { id, yes, force } => {
            handle_delete(id, *yes || *force, dry_run, config, ctx, out, err)
        }
        NotifierCommands::Test { target } => handle_test(target, dry_run, config, ctx, out),
    }
}

fn render_notifier(notifier: &Notifier, ctx: &OutputContext, out: &mut dyn Write) -> Result<()> {
    let redacted = notifier.redacted();
    if ctx.quiet {
        return write_quiet_ids(std::slice::from_ref(&redacted.id), out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&redacted, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(std::slice::from_ref(&redacted), select, ctx.format, out);
    }

    write_table_or_plain(
        &[
            "ID".to_string(),
            "NAME".to_string(),
            "ACTIVE".to_string(),
            "URL".to_string(),
        ],
        &[vec![
            redacted.id,
            redacted.name,
            redacted.is_active.to_string(),
            redacted.url,
        ]],
        ctx.format,
        out,
    )
}

fn handle_list(
    reveal: bool,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let preview = HomeboxClient::build_dry_run(base_url, "GET", "notifiers", None);
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let notifiers = client.list_notifiers()?;
    let display: Vec<Notifier> = if reveal {
        notifiers
    } else {
        notifiers.iter().map(Notifier::redacted).collect()
    };

    if ctx.quiet {
        let ids: Vec<String> = display.iter().map(|n| n.id.clone()).collect();
        return write_quiet_ids(&ids, out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&display, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&display, select, ctx.format, out);
    }

    let headers = vec![
        "ID".to_string(),
        "NAME".to_string(),
        "ACTIVE".to_string(),
        "URL".to_string(),
    ];
    let rows: Vec<Vec<String>> = display
        .iter()
        .map(|n| {
            vec![
                n.id.clone(),
                n.name.clone(),
                n.is_active.to_string(),
                n.url.clone(),
            ]
        })
        .collect();
    write_table_or_plain(&headers, &rows, ctx.format, out)
}

fn handle_create(
    args: &crate::cli::NotifierCreateArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let name = args.name.trim();
    if name.is_empty() {
        return Err(HbctlError::InvalidInput(
            "notifier --name cannot be empty".to_string(),
        ));
    }
    let url = args.notifier_url.trim();
    if url.is_empty() {
        return Err(HbctlError::InvalidInput(
            "notifier --notifier-url cannot be empty".to_string(),
        ));
    }
    let is_active = args.active.unwrap_or(true);

    if dry_run {
        let base_url = config.require_base_url()?;
        let preview = HomeboxClient::build_dry_run(
            base_url,
            "POST",
            "notifiers",
            Some(json!({
                "name": name,
                "url": redact_notifier_url(url),
                "isActive": is_active,
            })),
        );
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let created = client.create_notifier(&CreateNotifierRequest {
        name: name.to_string(),
        url: url.to_string(),
        is_active,
    })?;
    render_notifier(&created, ctx, out)
}

fn handle_update(
    args: &crate::cli::NotifierUpdateArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if args.name.is_none() && args.notifier_url.is_none() && args.active.is_none() {
        return Err(HbctlError::InvalidInput(
            "provide at least one of --name, --notifier-url, or --active".to_string(),
        ));
    }
    if let Some(ref name) = args.name {
        if name.trim().is_empty() {
            return Err(HbctlError::InvalidInput(
                "notifier --name cannot be empty".to_string(),
            ));
        }
    }
    if let Some(ref url) = args.notifier_url {
        if url.trim().is_empty() {
            return Err(HbctlError::InvalidInput(
                "notifier --notifier-url cannot be empty".to_string(),
            ));
        }
    }

    if dry_run {
        let base_url = config.require_base_url()?;
        let mut body = Map::new();
        if let Some(ref n) = args.name {
            body.insert("name".to_string(), json!(n.trim()));
        }
        if let Some(ref u) = args.notifier_url {
            body.insert("url".to_string(), json!(redact_notifier_url(u.trim())));
        }
        if let Some(a) = args.active {
            body.insert("isActive".to_string(), json!(a));
        }
        let preview = HomeboxClient::build_dry_run(
            base_url,
            "PUT",
            &format!("notifiers/{}", args.id),
            Some(Value::Object(body)),
        );
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let existing =
        if args.name.is_none() || args.active.is_none() {
            let list = client.list_notifiers()?;
            Some(list.into_iter().find(|n| n.id == args.id).ok_or_else(|| {
                HbctlError::NotFound {
                    kind: "notifier".to_string(),
                    query: args.id.clone(),
                }
            })?)
        } else {
            None
        };

    let name = args
        .name
        .as_deref()
        .map(str::trim)
        .map(ToOwned::to_owned)
        .or_else(|| existing.as_ref().map(|e| e.name.clone()))
        .unwrap_or_default();
    let is_active = args
        .active
        .or_else(|| existing.as_ref().map(|e| e.is_active))
        .unwrap_or(true);
    let url = args
        .notifier_url
        .as_deref()
        .map(str::trim)
        .map(ToOwned::to_owned);

    let updated = client.update_notifier(
        &args.id,
        &UpdateNotifierRequest {
            name,
            is_active,
            url,
        },
    )?;
    render_notifier(&updated, ctx, out)
}

fn handle_delete(
    id: &str,
    skip_confirm: bool,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    if dry_run {
        let base_url = config.require_base_url()?;
        let preview =
            HomeboxClient::build_dry_run(base_url, "DELETE", &format!("notifiers/{id}"), None);
        return write_dry_run(&[preview], ctx, out);
    }

    if !skip_confirm && io::stdin().is_terminal() {
        write!(err, "Delete notifier '{id}'? [y/N]: ")?;
        err.flush()?;
        let mut answer = String::new();
        io::stdin().read_line(&mut answer)?;
        if !matches!(answer.trim().to_ascii_lowercase().as_str(), "y" | "yes") {
            writeln!(err, "Aborted.")?;
            return Ok(());
        }
    }

    let client = HomeboxClient::from_config(config)?;
    client.delete_notifier(id)?;

    if ctx.quiet {
        return write_quiet_ids(std::slice::from_ref(&id.to_string()), out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(
            &json!({ "id": id, "deleted": true }),
            ctx.select.as_deref(),
            out,
        );
    }
    writeln!(out, "Deleted notifier {id}")?;
    Ok(())
}

fn handle_test(
    raw_target: &str,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let target = raw_target.trim();
    if target.is_empty() {
        return Err(HbctlError::InvalidInput(
            "notifier test target cannot be empty".to_string(),
        ));
    }

    let is_url = target.contains("://");

    if dry_run {
        let base_url = config.require_base_url()?;
        let body = if is_url {
            json!({ "url": redact_notifier_url(target) })
        } else {
            json!({ "notifierId": target, "url": "<resolved-from-notifier>" })
        };
        let preview = HomeboxClient::build_dry_run(base_url, "POST", "notifiers/test", Some(body));
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let (resolved_id, url) = if is_url {
        (None, target.to_string())
    } else {
        let notifiers = client.list_notifiers()?;
        let found = notifiers
            .iter()
            .find(|n| n.id == target)
            .or_else(|| {
                notifiers
                    .iter()
                    .find(|n| n.name.eq_ignore_ascii_case(target))
            })
            .ok_or_else(|| HbctlError::NotFound {
                kind: "notifier".to_string(),
                query: target.to_string(),
            })?;
        (Some(found.id.clone()), found.url.clone())
    };

    client.test_notifier(&url)?;

    let redacted_url = redact_notifier_url(&url);
    if ctx.quiet {
        let val = resolved_id.as_deref().unwrap_or(&redacted_url);
        return write_quiet_ids(std::slice::from_ref(&val.to_string()), out);
    }
    if ctx.format == OutputFormat::Json {
        let mut payload = json!({
            "ok": true,
            "url": redacted_url,
        });
        if let Some(ref id) = resolved_id {
            payload["id"] = json!(id);
        }
        return write_compact_json(&payload, ctx.select.as_deref(), out);
    }

    if let Some(id) = resolved_id {
        write_table_or_plain(
            &["STATUS".to_string(), "ID".to_string(), "URL".to_string()],
            &[vec!["ok".to_string(), id, redacted_url]],
            ctx.format,
            out,
        )
    } else {
        write_table_or_plain(
            &["STATUS".to_string(), "URL".to_string()],
            &[vec!["ok".to_string(), redacted_url]],
            ctx.format,
            out,
        )
    }
}

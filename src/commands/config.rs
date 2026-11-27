use std::io::Write;
use std::path::PathBuf;

use serde::Serialize;

use crate::cli::{ConfigArgs, ConfigCommands};
use crate::config::{
    default_user_config_path, discover_profiles, normalize_profile_name, redact_auth_header,
    redact_url_credentials, resolve_config_target_path, set_default_profile,
    validate_profile_in_file, AppConfig, OutputFormat,
};
use crate::error::Result;
use crate::output::{
    write_compact_json, write_quiet_ids, write_selected_table, write_table_or_plain, OutputContext,
};

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct ConfigShowOutput {
    #[serde(skip_serializing_if = "Option::is_none")]
    profile: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    url: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    url_source: Option<String>,
    authenticated: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    authorization: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    api_key_source: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    token_type: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    expires_at: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    credential_backend: Option<String>,
    output: OutputFormat,
    timeout_secs: u64,
    download_timeout_secs: u64,
    auto_optimize: bool,
    max_image_kb: u64,
    max_image_dimension: u32,
    #[serde(skip_serializing_if = "Option::is_none")]
    explicit_config_path: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    user_config_path: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    local_config_path: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct ConfigUseOutput {
    profile: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    previous_default: Option<String>,
    config_path: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
struct ConfigUseDryRun {
    dry_run: bool,
    profile: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    previous_default: Option<String>,
    config_path: String,
}

pub fn handle(
    args: &ConfigArgs,
    dry_run: bool,
    config_path: Option<&PathBuf>,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    match &args.command {
        ConfigCommands::Show => handle_show(config_path, config, ctx, out),
        ConfigCommands::Profiles => handle_profiles(config_path, config, ctx, out),
        ConfigCommands::Use { profile } => handle_use(profile, dry_run, config_path, ctx, out),
    }
}

fn handle_show(
    config_path: Option<&PathBuf>,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let cwd = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let user_config_path = if config_path.is_none() {
        default_user_config_path()
            .filter(|p| p.is_file())
            .map(|p| p.display().to_string())
    } else {
        None
    };
    let local_config_path = if config_path.is_none() {
        let local = cwd.join(".hbctl.toml");
        local.is_file().then(|| local.display().to_string())
    } else {
        None
    };

    let show_out = ConfigShowOutput {
        profile: config.profile.clone(),
        url: config.base_url.as_deref().map(redact_url_credentials),
        url_source: config.url_source.map(|s| s.as_str().to_string()),
        authenticated: config.api_key.is_some(),
        authorization: config
            .api_key
            .as_deref()
            .map(|k| redact_auth_header(k).to_string()),
        api_key_source: config.api_key_source.map(|s| s.as_str().to_string()),
        token_type: config.token_type.clone(),
        expires_at: config.expires_at.clone(),
        credential_backend: config.credential_backend.clone(),
        output: config.output,
        timeout_secs: config.timeout_secs,
        download_timeout_secs: config.download_timeout_secs,
        auto_optimize: config.auto_optimize,
        max_image_kb: config.max_image_kb,
        max_image_dimension: config.max_image_dimension,
        explicit_config_path: config_path.map(|p| p.display().to_string()),
        user_config_path,
        local_config_path,
    };

    if ctx.quiet {
        if let Some(ref val) = show_out.profile {
            return write_quiet_ids(std::slice::from_ref(val), out);
        }
        if let Some(ref val) = show_out.url {
            return write_quiet_ids(std::slice::from_ref(val), out);
        }
        return Ok(());
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&show_out, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&[show_out], select, ctx.format, out);
    }

    let mut rows = vec![
        vec![
            "profile".to_string(),
            show_out.profile.unwrap_or_else(|| "(none)".to_string()),
        ],
        vec![
            "url".to_string(),
            show_out.url.unwrap_or_else(|| "(unset)".to_string()),
        ],
    ];
    if let Some(src) = show_out.url_source {
        rows.push(vec!["urlSource".to_string(), src]);
    }
    rows.push(vec![
        "authenticated".to_string(),
        show_out.authenticated.to_string(),
    ]);
    if let Some(auth) = show_out.authorization {
        rows.push(vec!["authorization".to_string(), auth]);
    }
    if let Some(src) = show_out.api_key_source {
        rows.push(vec!["apiKeySource".to_string(), src]);
    }
    if let Some(tt) = show_out.token_type {
        rows.push(vec!["tokenType".to_string(), tt]);
    }
    if let Some(exp) = show_out.expires_at {
        rows.push(vec!["expiresAt".to_string(), exp]);
    }
    if let Some(backend) = show_out.credential_backend {
        rows.push(vec!["credentialBackend".to_string(), backend]);
    }
    rows.extend([
        vec!["output".to_string(), show_out.output.as_str().to_string()],
        vec!["timeoutSecs".to_string(), show_out.timeout_secs.to_string()],
        vec![
            "downloadTimeoutSecs".to_string(),
            show_out.download_timeout_secs.to_string(),
        ],
        vec![
            "autoOptimize".to_string(),
            show_out.auto_optimize.to_string(),
        ],
        vec!["maxImageKb".to_string(), show_out.max_image_kb.to_string()],
        vec![
            "maxImageDimension".to_string(),
            show_out.max_image_dimension.to_string(),
        ],
    ]);
    if let Some(p) = show_out.explicit_config_path {
        rows.push(vec!["explicitConfigPath".to_string(), p]);
    }
    if let Some(p) = show_out.user_config_path {
        rows.push(vec!["userConfigPath".to_string(), p]);
    }
    if let Some(p) = show_out.local_config_path {
        rows.push(vec!["localConfigPath".to_string(), p]);
    }

    write_table_or_plain(
        &["SETTING".to_string(), "VALUE".to_string()],
        &rows,
        ctx.format,
        out,
    )
}

fn handle_profiles(
    config_path: Option<&PathBuf>,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let cwd = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let user_cfg = default_user_config_path();
    let profiles = discover_profiles(
        config_path.map(PathBuf::as_path),
        &cwd,
        user_cfg.as_deref(),
        config.profile.as_deref(),
    )?;

    if ctx.quiet {
        let names: Vec<String> = profiles.iter().map(|p| p.name.clone()).collect();
        return write_quiet_ids(&names, out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&profiles, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&profiles, select, ctx.format, out);
    }

    let rows: Vec<Vec<String>> = profiles
        .iter()
        .map(|p| {
            vec![
                p.name.clone(),
                if p.active { "yes" } else { "no" }.to_string(),
                if p.default { "yes" } else { "no" }.to_string(),
                p.url.clone().unwrap_or_default(),
                p.source.clone(),
            ]
        })
        .collect();

    write_table_or_plain(
        &[
            "NAME".to_string(),
            "ACTIVE".to_string(),
            "DEFAULT".to_string(),
            "URL".to_string(),
            "SOURCE".to_string(),
        ],
        &rows,
        ctx.format,
        out,
    )
}

fn handle_use(
    profile: &str,
    dry_run: bool,
    config_path: Option<&PathBuf>,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let target_path = resolve_config_target_path(config_path)?;

    if dry_run {
        let (cfg_file, normalized) = validate_profile_in_file(&target_path, profile)?;
        let preview = ConfigUseDryRun {
            dry_run: true,
            profile: normalized,
            previous_default: cfg_file.default_profile,
            config_path: target_path.display().to_string(),
        };
        if ctx.format == OutputFormat::Json {
            return write_compact_json(&preview, ctx.select.as_deref(), out);
        }
        writeln!(
            out,
            "[dry-run] set default_profile = \"{}\" in {}",
            preview.profile, preview.config_path
        )?;
        return Ok(());
    }

    let previous_default = set_default_profile(&target_path, profile)?;
    let normalized =
        normalize_profile_name(Some(profile))?.unwrap_or_else(|| profile.trim().to_string());
    let res = ConfigUseOutput {
        profile: normalized,
        previous_default,
        config_path: target_path.display().to_string(),
    };

    if ctx.quiet {
        return write_quiet_ids(std::slice::from_ref(&res.profile), out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(&res, ctx.select.as_deref(), out);
    }
    if let Some(ref select) = ctx.select {
        return write_selected_table(&[res], select, ctx.format, out);
    }

    let rows = vec![
        vec!["profile".to_string(), res.profile],
        vec![
            "previousDefault".to_string(),
            res.previous_default.unwrap_or_else(|| "(none)".to_string()),
        ],
        vec!["configPath".to_string(), res.config_path],
    ];

    write_table_or_plain(
        &["PROPERTY".to_string(), "VALUE".to_string()],
        &rows,
        ctx.format,
        out,
    )
}

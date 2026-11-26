use std::io::{self, BufRead, IsTerminal, Read, Write};
use std::path::PathBuf;

use serde::Serialize;
use serde_json::json;

use crate::auth_store::{AutoSecretStore, SecretStore, TokenType};
use crate::cli::{AuthArgs, AuthCommands, AuthLoginArgs, AuthLogoutArgs, AuthRefreshArgs};
use crate::client::HomeboxClient;
use crate::config::{
    default_user_config_path, normalize_base_url, redact_auth_header, AppConfig, ConfigFile,
    OutputFormat,
};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_table_or_plain, OutputContext,
};

pub fn handle(
    args: &AuthArgs,
    dry_run: bool,
    config_path: Option<&PathBuf>,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    match &args.command {
        AuthCommands::Login(a) => handle_login(a, dry_run, config_path, config, ctx, out, err),
        AuthCommands::Status => handle_status(config, ctx, out),
        AuthCommands::Logout(a) => handle_logout(a, dry_run, config_path, config, ctx, out),
        AuthCommands::Refresh(a) => handle_refresh(a, dry_run, config_path, config, ctx, out, err),
    }
}

#[derive(Debug, Serialize)]
struct AuthStatusOutput {
    authenticated: bool,
    url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    user: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    email: Option<String>,
    source: String,
    token_type: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    expires_at: Option<String>,
    authorization: String,
}

fn resolve_config_target_path(explicit: Option<&PathBuf>) -> Result<PathBuf> {
    if let Some(p) = explicit {
        return Ok(p.clone());
    }
    default_user_config_path().ok_or_else(|| {
        HbctlError::Config("unable to determine ~/.config/hbctl/config.toml path".into())
    })
}

fn read_stdin_trimmed() -> Result<String> {
    let mut buf = String::new();
    io::stdin().read_to_string(&mut buf)?;
    Ok(buf.trim().to_string())
}

fn prompt_line(prompt: &str, err: &mut dyn Write) -> Result<String> {
    write!(err, "{prompt}")?;
    err.flush()?;
    let mut line = String::new();
    io::stdin().lock().read_line(&mut line)?;
    Ok(line.trim().to_string())
}

fn handle_login(
    args: &AuthLoginArgs,
    dry_run: bool,
    config_path: Option<&PathBuf>,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    let base_url = match config.base_url.as_deref() {
        Some(url) => url.to_string(),
        None if io::stdin().is_terminal() => {
            let raw = prompt_line("Homebox URL (e.g. http://192.168.1.50:7745): ", err)?;
            normalize_base_url(&raw)?
        }
        None => return Err(HbctlError::MissingUrl),
    };

    let (token, token_type, expires_at, user_name, user_email) = if args.with_token {
        let raw_token = read_stdin_trimmed()?;
        if raw_token.is_empty() {
            return Err(HbctlError::InvalidInput(
                "no token provided on stdin for --with-token".to_string(),
            ));
        }

        if dry_run {
            let preview = HomeboxClient::build_dry_run(&base_url, "GET", "users/self", None);
            return write_dry_run(&[preview], ctx, out);
        }

        let client = HomeboxClient::new(
            &base_url,
            &raw_token,
            config.timeout_secs,
            config.download_timeout_secs,
        )?;
        let profile = client.get_current_user()?;
        let ttype = TokenType::infer(&raw_token);
        (
            raw_token,
            ttype,
            None,
            non_empty_opt(&profile.name),
            non_empty_opt(&profile.email),
        )
    } else if args.username.is_some() || args.password_stdin {
        let username = match args.username.as_deref() {
            Some(u) if !u.trim().is_empty() => u.trim().to_string(),
            _ if io::stdin().is_terminal() => prompt_line("Homebox email/username: ", err)?,
            _ => {
                return Err(HbctlError::InvalidInput(
                    "--username is required with --password-stdin".to_string(),
                ));
            }
        };

        let password = if args.password_stdin {
            let mut buf = String::new();
            io::stdin().read_to_string(&mut buf)?;
            buf.trim_end_matches(['\r', '\n']).to_string()
        } else {
            rpassword::prompt_password("Password: ")?
        };
        if password.is_empty() {
            return Err(HbctlError::InvalidInput("password cannot be empty".into()));
        }

        if dry_run {
            let preview = HomeboxClient::build_dry_run(
                &base_url,
                "POST",
                "users/login",
                Some(json!({
                    "username": username,
                    "password": "***",
                    "stayLoggedIn": true,
                })),
            );
            return write_dry_run(&[preview], ctx, out);
        }

        let login_resp =
            HomeboxClient::login(&base_url, &username, &password, config.timeout_secs)?;
        let client = HomeboxClient::new(
            &base_url,
            &login_resp.token,
            config.timeout_secs,
            config.download_timeout_secs,
        )?;
        let (name, email) = match client.get_current_user() {
            Ok(p) => (
                non_empty_opt(&p.name),
                non_empty_opt(&p.email).or(Some(username)),
            ),
            Err(_) => (None, Some(username)),
        };
        (
            login_resp.token,
            TokenType::Jwt,
            login_resp.expires_at,
            name,
            email,
        )
    } else if io::stdin().is_terminal() {
        let choice = prompt_line(
            "Authentication method ([1] API key, [2] Email & password) [1]: ",
            err,
        )?;
        if choice == "2" {
            let username = prompt_line("Homebox email/username: ", err)?;
            let password = rpassword::prompt_password("Password: ")?;
            if dry_run {
                let preview = HomeboxClient::build_dry_run(
                    &base_url,
                    "POST",
                    "users/login",
                    Some(json!({
                        "username": username,
                        "password": "***",
                        "stayLoggedIn": true,
                    })),
                );
                return write_dry_run(&[preview], ctx, out);
            }
            let login_resp =
                HomeboxClient::login(&base_url, &username, &password, config.timeout_secs)?;
            (
                login_resp.token,
                TokenType::Jwt,
                login_resp.expires_at,
                None,
                Some(username),
            )
        } else {
            let raw_token = rpassword::prompt_password("Homebox API key (hb_...): ")?;
            if raw_token.trim().is_empty() {
                return Err(HbctlError::InvalidInput("API key cannot be empty".into()));
            }
            if dry_run {
                let preview = HomeboxClient::build_dry_run(&base_url, "GET", "users/self", None);
                return write_dry_run(&[preview], ctx, out);
            }
            let client = HomeboxClient::new(
                &base_url,
                raw_token.trim(),
                config.timeout_secs,
                config.download_timeout_secs,
            )?;
            let profile = client.get_current_user()?;
            let ttype = TokenType::infer(&raw_token);
            (
                raw_token.trim().to_string(),
                ttype,
                None,
                non_empty_opt(&profile.name),
                non_empty_opt(&profile.email),
            )
        }
    } else {
        return Err(HbctlError::InvalidInput(
            "non-interactive login requires --with-token or --username <EMAIL> --password-stdin"
                .to_string(),
        ));
    };

    // Persist secret to OS keyring (falling back to 0600 file store)
    let store = AutoSecretStore::from_defaults(args.insecure_storage)?;
    let backend = store.set_token_with_notice(&base_url, &token, err)?;

    // Save non-secret metadata to config.toml without duplicating plaintext api_key
    let cfg_path = resolve_config_target_path(config_path)?;
    let mut cfg_file = if cfg_path.is_file() {
        ConfigFile::load_from_path(&cfg_path)?
    } else {
        ConfigFile::default()
    };
    cfg_file.url = Some(base_url.clone());
    cfg_file.api_key = None;
    cfg_file.token_type = Some(token_type.as_str().to_string());
    cfg_file.expires_at = expires_at.clone();
    cfg_file.credential_backend = Some(backend.as_str().to_string());
    cfg_file.save_to_path(&cfg_path)?;

    let status_out = AuthStatusOutput {
        authenticated: true,
        url: base_url.clone(),
        user: user_name,
        email: user_email,
        source: backend.as_str().to_string(),
        token_type: token_type.as_str().to_string(),
        expires_at,
        authorization: redact_auth_header(&token).to_string(),
    };

    render_auth_status(&status_out, ctx, out)
}

fn handle_status(config: &AppConfig, ctx: &OutputContext, out: &mut dyn Write) -> Result<()> {
    let base_url = config.require_base_url()?;
    let api_key = config.require_api_key()?;
    let client = HomeboxClient::from_config(config)?;
    let profile = client.get_current_user()?;

    let token_type = config
        .token_type
        .clone()
        .unwrap_or_else(|| TokenType::infer(api_key).as_str().to_string());
    let source = config
        .api_key_source
        .map(|s| s.as_str().to_string())
        .unwrap_or_else(|| "unknown".to_string());

    let status_out = AuthStatusOutput {
        authenticated: true,
        url: base_url.to_string(),
        user: non_empty_opt(&profile.name),
        email: non_empty_opt(&profile.email),
        source,
        token_type,
        expires_at: config.expires_at.clone(),
        authorization: redact_auth_header(api_key).to_string(),
    };

    render_auth_status(&status_out, ctx, out)
}

fn handle_logout(
    args: &AuthLogoutArgs,
    dry_run: bool,
    config_path: Option<&PathBuf>,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let base_url = config.require_base_url()?;

    if dry_run {
        let payload = json!({
            "action": "logout",
            "url": base_url,
            "authorization": redact_auth_header(""),
        });
        if ctx.format == OutputFormat::Json {
            return write_compact_json(&payload, ctx.select.as_deref(), out);
        }
        writeln!(out, "[dry-run] logout {base_url}")?;
        return Ok(());
    }

    let store = AutoSecretStore::from_defaults(args.insecure_storage)?;
    let removed_secret = store.delete_token(base_url)?;

    let cfg_path = resolve_config_target_path(config_path)?;
    if cfg_path.is_file() {
        let mut cfg_file = ConfigFile::load_from_path(&cfg_path)?;
        let matches_url = cfg_file
            .url
            .as_deref()
            .and_then(|u| normalize_base_url(u).ok())
            .map(|u| u == base_url)
            .unwrap_or(true);
        if matches_url {
            cfg_file.api_key = None;
            cfg_file.token_type = None;
            cfg_file.expires_at = None;
            cfg_file.credential_backend = None;
            cfg_file.save_to_path(&cfg_path)?;
        }
    }

    if ctx.quiet {
        return write_quiet_ids(&[base_url.to_string()], out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(
            &json!({
                "logged_out": true,
                "url": base_url,
                "removed_secret": removed_secret,
            }),
            ctx.select.as_deref(),
            out,
        );
    }

    writeln!(out, "Logged out of {base_url}")?;
    Ok(())
}

fn handle_refresh(
    args: &AuthRefreshArgs,
    dry_run: bool,
    config_path: Option<&PathBuf>,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
    err: &mut dyn Write,
) -> Result<()> {
    let base_url = config.require_base_url()?;
    let _ = config.require_api_key()?;

    if dry_run {
        let preview = HomeboxClient::build_dry_run(base_url, "GET", "users/refresh", None);
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let refreshed = client.refresh_token()?;

    let store = AutoSecretStore::from_defaults(args.insecure_storage)?;
    let backend = store.set_token_with_notice(base_url, &refreshed.token, err)?;

    let cfg_path = resolve_config_target_path(config_path)?;
    let mut cfg_file = if cfg_path.is_file() {
        ConfigFile::load_from_path(&cfg_path)?
    } else {
        ConfigFile::default()
    };
    cfg_file.url = Some(base_url.to_string());
    cfg_file.api_key = None;
    cfg_file.token_type = Some(TokenType::Jwt.as_str().to_string());
    cfg_file.expires_at = refreshed.expires_at.clone();
    cfg_file.credential_backend = Some(backend.as_str().to_string());
    cfg_file.save_to_path(&cfg_path)?;

    let status_out = AuthStatusOutput {
        authenticated: true,
        url: base_url.to_string(),
        user: None,
        email: None,
        source: backend.as_str().to_string(),
        token_type: TokenType::Jwt.as_str().to_string(),
        expires_at: refreshed.expires_at,
        authorization: redact_auth_header(&refreshed.token).to_string(),
    };

    render_auth_status(&status_out, ctx, out)
}

fn render_auth_status(
    status: &AuthStatusOutput,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    if ctx.quiet {
        return write_quiet_ids(std::slice::from_ref(&status.url), out);
    }
    if ctx.format == OutputFormat::Json {
        return write_compact_json(status, ctx.select.as_deref(), out);
    }

    let mut rows = vec![
        vec!["url".to_string(), status.url.clone()],
        vec![
            "authenticated".to_string(),
            status.authenticated.to_string(),
        ],
        vec!["source".to_string(), status.source.clone()],
        vec!["token_type".to_string(), status.token_type.clone()],
        vec!["authorization".to_string(), status.authorization.clone()],
    ];
    if let Some(ref user) = status.user {
        rows.push(vec!["user".to_string(), user.clone()]);
    }
    if let Some(ref email) = status.email {
        rows.push(vec!["email".to_string(), email.clone()]);
    }
    if let Some(ref exp) = status.expires_at {
        rows.push(vec!["expires_at".to_string(), exp.clone()]);
    }

    write_table_or_plain(
        &["PROPERTY".to_string(), "VALUE".to_string()],
        &rows,
        ctx.format,
        out,
    )
}

fn non_empty_opt(s: &str) -> Option<String> {
    let t = s.trim();
    if t.is_empty() {
        None
    } else {
        Some(t.to_string())
    }
}

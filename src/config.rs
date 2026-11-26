use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

use clap::ValueEnum;
use directories::BaseDirs;
use serde::{Deserialize, Serialize};
use url::Url;

use crate::auth_store::{AutoSecretStore, CredentialBackend, SecretStore};
use crate::error::{HbxError, Result};

pub const DEFAULT_TIMEOUT_SECS: u64 = 30;
pub const DEFAULT_DOWNLOAD_TIMEOUT_SECS: u64 = 120;
pub const DEFAULT_HOMEBOX_PORT: u16 = 7745;

/// Output rendering mode for CLI commands.
#[derive(ValueEnum, Clone, Copy, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum OutputFormat {
    #[default]
    Table,
    Json,
    Plain,
}

impl std::str::FromStr for OutputFormat {
    type Err = HbxError;

    fn from_str(s: &str) -> Result<Self> {
        match s.trim().to_ascii_lowercase().as_str() {
            "table" => Ok(Self::Table),
            "json" => Ok(Self::Json),
            "plain" => Ok(Self::Plain),
            other => Err(HbxError::Config(format!(
                "invalid output format '{other}' (expected table, json, or plain)"
            ))),
        }
    }
}

/// Origin of a resolved credential or URL value.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum CredentialSource {
    CliFlag,
    Env,
    LocalConfig,
    UserConfig,
    Keyring,
    CredentialsFile,
}

impl CredentialSource {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::CliFlag => "cli_flag",
            Self::Env => "env",
            Self::LocalConfig => "local_config",
            Self::UserConfig => "user_config",
            Self::Keyring => "keyring",
            Self::CredentialsFile => "credentials_file",
        }
    }
}

impl std::fmt::Display for CredentialSource {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}

/// On-disk TOML configuration representation (`.hbx.toml` or `~/.config/hbx/config.toml`).
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct ConfigFile {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub api_key: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub output: Option<OutputFormat>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub timeout_secs: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub download_timeout_secs: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub token_type: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub expires_at: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub credential_backend: Option<String>,
}

impl ConfigFile {
    pub fn load_from_path(path: &Path) -> Result<Self> {
        let content = fs::read_to_string(path).map_err(|e| {
            HbxError::Config(format!("failed to read config '{}': {e}", path.display()))
        })?;
        toml::from_str(&content).map_err(|e| {
            HbxError::Config(format!("failed to parse TOML '{}': {e}", path.display()))
        })
    }

    pub fn save_to_path(&self, path: &Path) -> Result<()> {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }
        let text = toml::to_string_pretty(self)
            .map_err(|e| HbxError::Config(format!("failed to serialize TOML: {e}")))?;
        fs::write(path, text)?;
        Ok(())
    }
}

/// CLI-level configuration overrides.
#[derive(Debug, Clone, Default)]
pub struct CliConfigOverrides {
    pub url: Option<String>,
    pub api_key: Option<String>,
    pub output: Option<OutputFormat>,
    pub json: bool,
    pub config_path: Option<PathBuf>,
}

/// Fully resolved runtime configuration after layering:
/// CLI flags > env / `.env` > `.hbx.toml` > `~/.config/hbx/config.toml` & stored auth > defaults.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppConfig {
    pub base_url: Option<String>,
    pub api_key: Option<String>,
    pub url_source: Option<CredentialSource>,
    pub api_key_source: Option<CredentialSource>,
    pub token_type: Option<String>,
    pub expires_at: Option<String>,
    pub credential_backend: Option<String>,
    pub output: OutputFormat,
    pub timeout_secs: u64,
    pub download_timeout_secs: u64,
}

impl AppConfig {
    /// Load configuration using the current process environment, `.env`, cwd `.hbx.toml`,
    /// `~/.config/hbx/config.toml`, and OS keyring / `0600` credentials file fallback.
    pub fn load(overrides: &CliConfigOverrides) -> Result<Self> {
        // Auto-load local .env without overriding already-set environment variables.
        let _ = dotenvy::dotenv();

        let env_vars: HashMap<String, String> = std::env::vars().collect();
        let cwd = std::env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
        let user_cfg = default_user_config_path();
        let store = AutoSecretStore::from_defaults(false).ok();

        Self::resolve_with_store(
            overrides,
            &env_vars,
            &cwd,
            user_cfg.as_deref(),
            store.as_ref().map(|s| s as &dyn SecretStore),
        )
    }

    /// Deterministic resolver without external keyring/file store (for pure unit tests).
    pub fn resolve(
        overrides: &CliConfigOverrides,
        env_vars: &HashMap<String, String>,
        cwd: &Path,
        user_config_path: Option<&Path>,
    ) -> Result<Self> {
        Self::resolve_with_store(overrides, env_vars, cwd, user_config_path, None)
    }

    /// Deterministic resolver for full layered configuration precedence including `SecretStore`.
    pub fn resolve_with_store(
        overrides: &CliConfigOverrides,
        env_vars: &HashMap<String, String>,
        cwd: &Path,
        user_config_path: Option<&Path>,
        secret_store: Option<&dyn SecretStore>,
    ) -> Result<Self> {
        let mut merged = ConfigFile::default();
        let mut url_source = None;
        let mut api_key_source = None;

        if let Some(explicit_path) = &overrides.config_path {
            let explicit = ConfigFile::load_from_path(explicit_path)?;
            apply_config_layer(
                &mut merged,
                explicit,
                CredentialSource::LocalConfig,
                &mut url_source,
                &mut api_key_source,
            );
        } else {
            // Tier 4: User global ~/.config/hbx/config.toml
            if let Some(user_path) = user_config_path {
                if user_path.is_file() {
                    let user_cfg = ConfigFile::load_from_path(user_path)?;
                    apply_config_layer(
                        &mut merged,
                        user_cfg,
                        CredentialSource::UserConfig,
                        &mut url_source,
                        &mut api_key_source,
                    );
                }
            }

            // Tier 3: Project-local .hbx.toml
            let local_path = cwd.join(".hbx.toml");
            if local_path.is_file() {
                let local_cfg = ConfigFile::load_from_path(&local_path)?;
                apply_config_layer(
                    &mut merged,
                    local_cfg,
                    CredentialSource::LocalConfig,
                    &mut url_source,
                    &mut api_key_source,
                );
            }
        }

        // Tier 2: Environment variables (and .env already loaded into env)
        if let Some(env_url) = env_non_empty(env_vars, "HBX_URL")
            .or_else(|| env_non_empty(env_vars, "HOMEBOX_URL"))
            .or_else(|| env_non_empty(env_vars, "HOMEBOX_IP").map(|ip| expand_homebox_ip(&ip)))
        {
            merged.url = Some(env_url);
            url_source = Some(CredentialSource::Env);
        }

        if let Some(env_key) = env_non_empty(env_vars, "HBX_API_KEY")
            .or_else(|| env_non_empty(env_vars, "HOMEBOX_API_KEY"))
        {
            merged.api_key = Some(env_key);
            api_key_source = Some(CredentialSource::Env);
        }

        if let Some(env_output) = env_non_empty(env_vars, "HBX_OUTPUT") {
            merged.output = Some(env_output.parse()?);
        }

        // Tier 1: CLI flags
        if let Some(url) = non_empty(overrides.url.as_deref()) {
            merged.url = Some(url.to_string());
            url_source = Some(CredentialSource::CliFlag);
        }
        if let Some(key) = non_empty(overrides.api_key.as_deref()) {
            merged.api_key = Some(key.to_string());
            api_key_source = Some(CredentialSource::CliFlag);
        }
        if let Some(out) = overrides.output {
            merged.output = Some(out);
        }
        if overrides.json {
            merged.output = Some(OutputFormat::Json);
        }

        let base_url = match merged.url {
            Some(raw) => Some(normalize_base_url(&raw)?),
            None => None,
        };

        // Fallback to stored `hbx auth` credentials (OS keyring or 0600 file store)
        // when no higher-precedence API key (CLI / env / .hbx.toml / config.toml) is set.
        if merged.api_key.is_none() {
            if let (Some(url), Some(store)) = (base_url.as_deref(), secret_store) {
                if let Ok(Some((token, backend))) = store.get_token(url) {
                    merged.api_key = Some(token);
                    api_key_source = Some(match backend {
                        CredentialBackend::Keyring => CredentialSource::Keyring,
                        CredentialBackend::File => CredentialSource::CredentialsFile,
                    });
                }
            }
        }

        Ok(Self {
            base_url,
            api_key: merged.api_key,
            url_source,
            api_key_source,
            token_type: merged.token_type,
            expires_at: merged.expires_at,
            credential_backend: merged.credential_backend,
            output: merged.output.unwrap_or(OutputFormat::Table),
            timeout_secs: merged.timeout_secs.unwrap_or(DEFAULT_TIMEOUT_SECS),
            download_timeout_secs: merged
                .download_timeout_secs
                .unwrap_or(DEFAULT_DOWNLOAD_TIMEOUT_SECS),
        })
    }

    pub fn require_base_url(&self) -> Result<&str> {
        self.base_url.as_deref().ok_or(HbxError::MissingUrl)
    }

    pub fn require_api_key(&self) -> Result<&str> {
        self.api_key.as_deref().ok_or(HbxError::MissingApiKey)
    }
}

fn apply_config_layer(
    target: &mut ConfigFile,
    layer: ConfigFile,
    source: CredentialSource,
    url_source: &mut Option<CredentialSource>,
    api_key_source: &mut Option<CredentialSource>,
) {
    if layer.url.is_some() {
        target.url = layer.url;
        *url_source = Some(source);
    }
    if layer.api_key.is_some() {
        target.api_key = layer.api_key;
        *api_key_source = Some(source);
    }
    if layer.output.is_some() {
        target.output = layer.output;
    }
    if layer.timeout_secs.is_some() {
        target.timeout_secs = layer.timeout_secs;
    }
    if layer.download_timeout_secs.is_some() {
        target.download_timeout_secs = layer.download_timeout_secs;
    }
    if layer.token_type.is_some() {
        target.token_type = layer.token_type;
    }
    if layer.expires_at.is_some() {
        target.expires_at = layer.expires_at;
    }
    if layer.credential_backend.is_some() {
        target.credential_backend = layer.credential_backend;
    }
}

fn non_empty(val: Option<&str>) -> Option<&str> {
    val.map(str::trim).filter(|s| !s.is_empty())
}

fn env_non_empty(env_vars: &HashMap<String, String>, key: &str) -> Option<String> {
    env_vars
        .get(key)
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(ToOwned::to_owned)
}

/// Default path for user-global config: `~/.config/hbx/config.toml` (or XDG equivalent).
pub fn default_user_config_path() -> Option<PathBuf> {
    if let Ok(xdg) = std::env::var("XDG_CONFIG_HOME") {
        let trimmed = xdg.trim();
        if !trimmed.is_empty() {
            return Some(PathBuf::from(trimmed).join("hbx").join("config.toml"));
        }
    }
    BaseDirs::new().map(|dirs| {
        dirs.home_dir()
            .join(".config")
            .join("hbx")
            .join("config.toml")
    })
}

/// Expand `HOMEBOX_IP` (e.g. `192.168.1.50`) into `http://192.168.1.50:7745`.
pub fn expand_homebox_ip(ip: &str) -> String {
    let trimmed = ip.trim().trim_end_matches('/');
    if trimmed.starts_with("http://") || trimmed.starts_with("https://") {
        trimmed.to_string()
    } else if trimmed.contains(':') && !trimmed.starts_with('[') {
        format!("http://{trimmed}")
    } else {
        format!("http://{trimmed}:{DEFAULT_HOMEBOX_PORT}")
    }
}

/// Normalize a Homebox base URL so both `http://host:7745` and `http://host:7745/api/v1/`
/// resolve cleanly to `http://host:7745/api/v1`.
pub fn normalize_base_url(raw: &str) -> Result<String> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Err(HbxError::MissingUrl);
    }

    let with_scheme = if trimmed.starts_with("http://") || trimmed.starts_with("https://") {
        trimmed.to_string()
    } else {
        format!("http://{trimmed}")
    };

    let parsed = Url::parse(&with_scheme).map_err(|e| HbxError::InvalidUrl {
        url: trimmed.to_string(),
        reason: e.to_string(),
    })?;

    if parsed.host_str().is_none() {
        return Err(HbxError::InvalidUrl {
            url: trimmed.to_string(),
            reason: "missing host".to_string(),
        });
    }

    let without_trailing = parsed.as_str().trim_end_matches('/');
    if without_trailing.ends_with("/api/v1") {
        Ok(without_trailing.to_string())
    } else {
        Ok(format!("{without_trailing}/api/v1"))
    }
}

/// Normalize an API key or Bearer token for the HTTP `Authorization` header.
/// Prepends `Bearer ` to static `hb_` keys and avoids double-prefixing tokens
/// that already begin with `Bearer `.
pub fn normalize_auth_header(raw: &str) -> String {
    let trimmed = raw.trim();
    if trimmed.len() >= 7 && trimmed[..7].eq_ignore_ascii_case("bearer ") {
        let token = trimmed[7..].trim();
        format!("Bearer {token}")
    } else {
        format!("Bearer {trimmed}")
    }
}

/// Always mask `Authorization` headers for logs, errors, and `--dry-run`.
pub fn redact_auth_header(_raw: &str) -> &'static str {
    "Bearer ***"
}

/// Redact any accidental occurrence of the raw API key inside arbitrary diagnostic strings.
pub fn redact_secret(text: &str, api_key: &str) -> String {
    let trimmed = api_key.trim();
    if trimmed.is_empty() {
        return text.to_string();
    }
    let bare = if trimmed.len() >= 7 && trimmed[..7].eq_ignore_ascii_case("bearer ") {
        trimmed[7..].trim()
    } else {
        trimmed
    };
    let mut out = text.replace(&format!("Bearer {bare}"), "Bearer ***");
    if !bare.is_empty() {
        out = out.replace(bare, "***");
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::auth_store::FileSecretStore;
    use tempfile::tempdir;

    #[test]
    fn test_normalize_base_url_variants() {
        assert_eq!(
            normalize_base_url("http://192.168.1.50:7745").unwrap(),
            "http://192.168.1.50:7745/api/v1"
        );
        assert_eq!(
            normalize_base_url("http://192.168.1.50:7745/").unwrap(),
            "http://192.168.1.50:7745/api/v1"
        );
        assert_eq!(
            normalize_base_url("http://192.168.1.50:7745/api/v1").unwrap(),
            "http://192.168.1.50:7745/api/v1"
        );
        assert_eq!(
            normalize_base_url("http://192.168.1.50:7745/api/v1/").unwrap(),
            "http://192.168.1.50:7745/api/v1"
        );
        assert_eq!(
            normalize_base_url("https://homebox.example.com/sub").unwrap(),
            "https://homebox.example.com/sub/api/v1"
        );
    }

    #[test]
    fn test_expand_homebox_ip() {
        assert_eq!(
            expand_homebox_ip("192.168.1.50"),
            "http://192.168.1.50:7745"
        );
        assert_eq!(expand_homebox_ip("10.0.0.5:8080"), "http://10.0.0.5:8080");
        assert_eq!(expand_homebox_ip("https://box.lan"), "https://box.lan");
    }

    #[test]
    fn test_normalize_auth_and_redaction() {
        assert_eq!(normalize_auth_header("hb_secret123"), "Bearer hb_secret123");
        assert_eq!(
            normalize_auth_header("Bearer eyJhbGciOiJIUzI1NiJ9"),
            "Bearer eyJhbGciOiJIUzI1NiJ9"
        );
        assert_eq!(normalize_auth_header("bearer  hb_abc "), "Bearer hb_abc");
        assert_eq!(redact_auth_header("Bearer hb_secret123"), "Bearer ***");
        assert_eq!(
            redact_secret(
                "failed with Authorization: Bearer hb_secret123",
                "hb_secret123"
            ),
            "failed with Authorization: Bearer ***"
        );
        assert_eq!(
            redact_secret("token eyJxyz leaked", "Bearer eyJxyz"),
            "token *** leaked"
        );
    }

    #[test]
    fn test_layered_config_precedence() {
        let dir = tempdir().unwrap();
        let user_cfg = dir.path().join("user_config.toml");
        fs::write(
            &user_cfg,
            r#"
url = "http://user.local:7745"
api_key = "hb_user"
output = "plain"
timeout_secs = 45
download_timeout_secs = 240
"#,
        )
        .unwrap();

        let local_dir = dir.path().join("project");
        fs::create_dir_all(&local_dir).unwrap();
        fs::write(
            local_dir.join(".hbx.toml"),
            r#"
url = "http://local.local:7745"
api_key = "hb_local"
"#,
        )
        .unwrap();

        // 1. User config alone when no local config exists
        let empty_dir = dir.path().join("empty");
        fs::create_dir_all(&empty_dir).unwrap();
        let cfg = AppConfig::resolve(
            &CliConfigOverrides::default(),
            &HashMap::new(),
            &empty_dir,
            Some(&user_cfg),
        )
        .unwrap();
        assert_eq!(
            cfg.base_url.as_deref(),
            Some("http://user.local:7745/api/v1")
        );
        assert_eq!(cfg.api_key.as_deref(), Some("hb_user"));
        assert_eq!(cfg.api_key_source, Some(CredentialSource::UserConfig));
        assert_eq!(cfg.output, OutputFormat::Plain);
        assert_eq!(cfg.timeout_secs, 45);
        assert_eq!(cfg.download_timeout_secs, 240);

        // 2. Project-local .hbx.toml overrides user config
        let cfg = AppConfig::resolve(
            &CliConfigOverrides::default(),
            &HashMap::new(),
            &local_dir,
            Some(&user_cfg),
        )
        .unwrap();
        assert_eq!(
            cfg.base_url.as_deref(),
            Some("http://local.local:7745/api/v1")
        );
        assert_eq!(cfg.api_key.as_deref(), Some("hb_local"));
        assert_eq!(cfg.api_key_source, Some(CredentialSource::LocalConfig));
        assert_eq!(cfg.output, OutputFormat::Plain);

        // 3. Env HOMEBOX_IP < HOMEBOX_URL < HBX_URL
        let mut env = HashMap::new();
        env.insert("HOMEBOX_IP".into(), "192.168.1.99".into());
        env.insert("HOMEBOX_API_KEY".into(), "hb_env_homebox".into());
        let cfg = AppConfig::resolve(
            &CliConfigOverrides::default(),
            &env,
            &local_dir,
            Some(&user_cfg),
        )
        .unwrap();
        assert_eq!(
            cfg.base_url.as_deref(),
            Some("http://192.168.1.99:7745/api/v1")
        );
        assert_eq!(cfg.api_key.as_deref(), Some("hb_env_homebox"));
        assert_eq!(cfg.api_key_source, Some(CredentialSource::Env));

        env.insert("HOMEBOX_URL".into(), "http://env-homebox:7745".into());
        let cfg = AppConfig::resolve(
            &CliConfigOverrides::default(),
            &env,
            &local_dir,
            Some(&user_cfg),
        )
        .unwrap();
        assert_eq!(
            cfg.base_url.as_deref(),
            Some("http://env-homebox:7745/api/v1")
        );

        env.insert("HBX_URL".into(), "http://env-hbx:7745/api/v1/".into());
        env.insert("HBX_API_KEY".into(), "hb_env_hbx".into());
        let cfg = AppConfig::resolve(
            &CliConfigOverrides::default(),
            &env,
            &local_dir,
            Some(&user_cfg),
        )
        .unwrap();
        assert_eq!(cfg.base_url.as_deref(), Some("http://env-hbx:7745/api/v1"));
        assert_eq!(cfg.api_key.as_deref(), Some("hb_env_hbx"));

        // 4. CLI flags override everything
        let overrides = CliConfigOverrides {
            url: Some("http://cli.local:7745".into()),
            api_key: Some("hb_cli".into()),
            output: Some(OutputFormat::Table),
            json: true,
            config_path: None,
        };
        let cfg = AppConfig::resolve(&overrides, &env, &local_dir, Some(&user_cfg)).unwrap();
        assert_eq!(
            cfg.base_url.as_deref(),
            Some("http://cli.local:7745/api/v1")
        );
        assert_eq!(cfg.api_key.as_deref(), Some("hb_cli"));
        assert_eq!(cfg.api_key_source, Some(CredentialSource::CliFlag));
        assert_eq!(cfg.output, OutputFormat::Json);
    }

    #[test]
    fn test_secret_store_fallback_and_precedence() {
        let dir = tempdir().unwrap();
        let user_cfg = dir.path().join("config.toml");
        ConfigFile {
            url: Some("http://stored.local:7745/api/v1".into()),
            token_type: Some("api_key".into()),
            credential_backend: Some("file".into()),
            ..Default::default()
        }
        .save_to_path(&user_cfg)
        .unwrap();

        let creds = FileSecretStore::new(dir.path().join("credentials.json"));
        creds
            .set_token("http://stored.local:7745/api/v1", "hb_from_store")
            .unwrap();

        let empty_dir = dir.path().join("empty");
        fs::create_dir_all(&empty_dir).unwrap();

        // Loads token from SecretStore when config.toml has only metadata
        let cfg = AppConfig::resolve_with_store(
            &CliConfigOverrides::default(),
            &HashMap::new(),
            &empty_dir,
            Some(&user_cfg),
            Some(&creds),
        )
        .unwrap();
        assert_eq!(cfg.api_key.as_deref(), Some("hb_from_store"));
        assert_eq!(cfg.api_key_source, Some(CredentialSource::CredentialsFile));
        assert_eq!(cfg.token_type.as_deref(), Some("api_key"));

        // Env overrides SecretStore
        let mut env = HashMap::new();
        env.insert("HOMEBOX_API_KEY".into(), "hb_env_wins".into());
        let cfg = AppConfig::resolve_with_store(
            &CliConfigOverrides::default(),
            &env,
            &empty_dir,
            Some(&user_cfg),
            Some(&creds),
        )
        .unwrap();
        assert_eq!(cfg.api_key.as_deref(), Some("hb_env_wins"));
        assert_eq!(cfg.api_key_source, Some(CredentialSource::Env));
    }
}

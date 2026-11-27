use std::collections::{BTreeMap, HashMap};
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};

use clap::ValueEnum;
use directories::BaseDirs;
use serde::{Deserialize, Serialize};
use url::Url;

use crate::auth_store::{credential_account_key, AutoSecretStore, CredentialBackend, SecretStore};
use crate::error::{HbctlError, Result};

pub const DEFAULT_TIMEOUT_SECS: u64 = 30;
pub const DEFAULT_DOWNLOAD_TIMEOUT_SECS: u64 = 120;
pub const DEFAULT_HOMEBOX_PORT: u16 = 7745;
pub const DEFAULT_AUTO_OPTIMIZE: bool = false;
pub const DEFAULT_MAX_IMAGE_KB: u64 = 500;
pub const DEFAULT_MAX_IMAGE_DIMENSION: u32 = 1920;

/// Output rendering mode for CLI commands.
#[derive(ValueEnum, Clone, Copy, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum OutputFormat {
    #[default]
    Table,
    Json,
    Plain,
    Csv,
    #[value(alias = "md")]
    #[serde(alias = "md")]
    Markdown,
}

impl OutputFormat {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Table => "table",
            Self::Json => "json",
            Self::Plain => "plain",
            Self::Csv => "csv",
            Self::Markdown => "markdown",
        }
    }
}

impl std::str::FromStr for OutputFormat {
    type Err = HbctlError;

    fn from_str(s: &str) -> Result<Self> {
        match s.trim().to_ascii_lowercase().as_str() {
            "table" => Ok(Self::Table),
            "json" => Ok(Self::Json),
            "plain" => Ok(Self::Plain),
            "csv" => Ok(Self::Csv),
            "markdown" | "md" => Ok(Self::Markdown),
            other => Err(HbctlError::Config(format!(
                "invalid output format '{other}' (expected table, json, plain, csv, or markdown)"
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

/// Per-instance configuration section (`[profiles.<name>]`) inside `config.toml`.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct ProfileConfig {
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
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub auto_optimize: Option<bool>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub max_image_kb: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub max_image_dimension: Option<u32>,
}

/// On-disk TOML configuration representation (`.hbctl.toml` or `~/.config/hbctl/config.toml`).
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct ConfigFile {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub default_profile: Option<String>,
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
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub auto_optimize: Option<bool>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub max_image_kb: Option<u64>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub max_image_dimension: Option<u32>,
    #[serde(default, skip_serializing_if = "BTreeMap::is_empty")]
    pub profiles: BTreeMap<String, ProfileConfig>,
}

impl ConfigFile {
    pub fn load_from_path(path: &Path) -> Result<Self> {
        let content = fs::read_to_string(path).map_err(|e| {
            HbctlError::Config(format!("failed to read config '{}': {e}", path.display()))
        })?;
        toml::from_str(&content).map_err(|e| {
            HbctlError::Config(format!("failed to parse TOML '{}': {e}", path.display()))
        })
    }

    pub fn save_to_path(&self, path: &Path) -> Result<()> {
        let text = toml::to_string_pretty(self)
            .map_err(|e| HbctlError::Config(format!("failed to serialize TOML: {e}")))?;

        let parent = path
            .parent()
            .filter(|p| !p.as_os_str().is_empty())
            .unwrap_or_else(|| Path::new("."));
        fs::create_dir_all(parent)?;

        let file_name = path
            .file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("config.toml");
        let tmp_path = parent.join(format!(".{file_name}.tmp.{}", std::process::id()));

        let write_result: Result<()> = (|| {
            let mut file = OpenOptions::new()
                .write(true)
                .create(true)
                .truncate(true)
                .open(&tmp_path)?;
            #[cfg(unix)]
            if let Ok(meta) = fs::metadata(path) {
                let _ = fs::set_permissions(&tmp_path, meta.permissions());
            }
            file.write_all(text.as_bytes())?;
            file.sync_all()?;
            Ok(())
        })();

        if let Err(err) = write_result {
            let _ = fs::remove_file(&tmp_path);
            return Err(err);
        }

        if let Err(err) = fs::rename(&tmp_path, path) {
            #[cfg(windows)]
            {
                if path.exists()
                    && fs::remove_file(path).is_ok()
                    && fs::rename(&tmp_path, path).is_ok()
                {
                    return Ok(());
                }
            }
            let _ = fs::remove_file(&tmp_path);
            return Err(err.into());
        }

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
    pub profile: Option<String>,
}

/// Validate and normalize an optional profile name (`None` when absent/blank).
pub fn normalize_profile_name(raw: Option<&str>) -> Result<Option<String>> {
    let Some(trimmed) = non_empty(raw) else {
        return Ok(None);
    };
    if !trimmed
        .chars()
        .all(|c| c.is_ascii_alphanumeric() || matches!(c, '-' | '_' | '.'))
    {
        return Err(HbctlError::Config(format!(
            "invalid profile name '{trimmed}': use letters, digits, '-', '_', or '.'"
        )));
    }
    Ok(Some(trimmed.to_string()))
}

/// Fully resolved runtime configuration after layering:
/// CLI flags > env / `.env` > `.hbctl.toml` > `~/.config/hbctl/config.toml` & stored auth > defaults.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AppConfig {
    pub profile: Option<String>,
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
    pub auto_optimize: bool,
    pub max_image_kb: u64,
    pub max_image_dimension: u32,
}

impl AppConfig {
    /// Load configuration using the current process environment, `.env`, cwd `.hbctl.toml`,
    /// `~/.config/hbctl/config.toml`, and OS keyring / `0600` credentials file fallback.
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
        let loaded_files =
            load_config_layers(overrides.config_path.as_deref(), cwd, user_config_path)?;

        let explicit_profile = normalize_profile_name(overrides.profile.as_deref())?.or(
            normalize_profile_name(env_non_empty(env_vars, "HBCTL_PROFILE").as_deref())?,
        );

        let mut cfg_default_profile: Option<String> = None;
        for (file, _) in loaded_files.iter().rev() {
            if let Some(prof) = normalize_profile_name(file.default_profile.as_deref())? {
                cfg_default_profile = Some(prof);
                break;
            }
        }

        let active_profile = if explicit_profile.is_some() {
            explicit_profile.clone()
        } else if cfg_default_profile.is_some() {
            cfg_default_profile
        } else if loaded_files
            .iter()
            .any(|(f, _)| f.profiles.contains_key("default"))
        {
            Some("default".to_string())
        } else {
            None
        };

        let mut merged = ConfigFile::default();
        let mut url_source = None;
        let mut api_key_source = None;

        for (file, source) in loaded_files {
            apply_config_file(
                &mut merged,
                file,
                source,
                active_profile.as_deref(),
                explicit_profile.is_some(),
                &mut url_source,
                &mut api_key_source,
            );
        }

        // Tier 2: Environment variables (and .env already loaded into env)
        if let Some(env_url) = env_non_empty(env_vars, "HBCTL_URL")
            .or_else(|| env_non_empty(env_vars, "HOMEBOX_URL"))
            .or_else(|| env_non_empty(env_vars, "HOMEBOX_IP").map(|ip| expand_homebox_ip(&ip)))
        {
            merged.url = Some(env_url);
            url_source = Some(CredentialSource::Env);
        }

        if let Some(env_key) = env_non_empty(env_vars, "HBCTL_API_KEY")
            .or_else(|| env_non_empty(env_vars, "HOMEBOX_API_KEY"))
        {
            merged.api_key = Some(env_key);
            api_key_source = Some(CredentialSource::Env);
        }

        if let Some(env_output) = env_non_empty(env_vars, "HBCTL_OUTPUT") {
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

        // Fallback to stored `hbctl auth` credentials (OS keyring or 0600 file store)
        // when no higher-precedence API key (CLI / env / .hbctl.toml / config.toml) is set.
        if merged.api_key.is_none() {
            if let (Some(url), Some(store)) = (base_url.as_deref(), secret_store) {
                let primary_account = credential_account_key(active_profile.as_deref(), url);
                let found = match store.get_token(&primary_account) {
                    Ok(Some(hit)) => Some(hit),
                    _ if active_profile.as_deref() == Some("default") => {
                        store.get_token(url).ok().flatten()
                    }
                    _ => None,
                };
                if let Some((token, backend)) = found {
                    merged.api_key = Some(token);
                    api_key_source = Some(match backend {
                        CredentialBackend::Keyring => CredentialSource::Keyring,
                        CredentialBackend::File => CredentialSource::CredentialsFile,
                    });
                }
            }
        }

        let max_image_kb = merged.max_image_kb.unwrap_or(DEFAULT_MAX_IMAGE_KB);
        if max_image_kb == 0 {
            return Err(HbctlError::Config(
                "max_image_kb must be greater than 0".to_string(),
            ));
        }
        let max_image_dimension = merged
            .max_image_dimension
            .unwrap_or(DEFAULT_MAX_IMAGE_DIMENSION);
        if max_image_dimension == 0 {
            return Err(HbctlError::Config(
                "max_image_dimension must be greater than 0".to_string(),
            ));
        }

        Ok(Self {
            profile: active_profile,
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
            auto_optimize: merged.auto_optimize.unwrap_or(DEFAULT_AUTO_OPTIMIZE),
            max_image_kb,
            max_image_dimension,
        })
    }

    pub fn max_image_bytes(&self) -> u64 {
        self.max_image_kb.saturating_mul(1024)
    }

    pub fn require_base_url(&self) -> Result<&str> {
        self.base_url.as_deref().ok_or(HbctlError::MissingUrl)
    }

    pub fn require_api_key(&self) -> Result<&str> {
        self.api_key.as_deref().ok_or(HbctlError::MissingApiKey)
    }
}

fn apply_shared_defaults(target: &mut ConfigFile, layer: &ConfigFile) {
    if layer.output.is_some() {
        target.output = layer.output;
    }
    if layer.timeout_secs.is_some() {
        target.timeout_secs = layer.timeout_secs;
    }
    if layer.download_timeout_secs.is_some() {
        target.download_timeout_secs = layer.download_timeout_secs;
    }
    if layer.auto_optimize.is_some() {
        target.auto_optimize = layer.auto_optimize;
    }
    if layer.max_image_kb.is_some() {
        target.max_image_kb = layer.max_image_kb;
    }
    if layer.max_image_dimension.is_some() {
        target.max_image_dimension = layer.max_image_dimension;
    }
}

fn apply_config_file(
    target: &mut ConfigFile,
    mut file: ConfigFile,
    source: CredentialSource,
    active_profile: Option<&str>,
    has_explicit_profile: bool,
    url_source: &mut Option<CredentialSource>,
    api_key_source: &mut Option<CredentialSource>,
) {
    apply_shared_defaults(target, &file);

    let profile_layer = match active_profile {
        Some(prof_name) => {
            if let Some(p_cfg) = file.profiles.remove(prof_name) {
                Some(p_cfg)
            } else if prof_name == "default"
                || (!has_explicit_profile && source == CredentialSource::LocalConfig)
            {
                Some(ProfileConfig {
                    url: file.url,
                    api_key: file.api_key,
                    output: None,
                    timeout_secs: None,
                    download_timeout_secs: None,
                    token_type: file.token_type,
                    expires_at: file.expires_at,
                    credential_backend: file.credential_backend,
                    auto_optimize: None,
                    max_image_kb: None,
                    max_image_dimension: None,
                })
            } else {
                None
            }
        }
        None => Some(ProfileConfig {
            url: file.url,
            api_key: file.api_key,
            output: None,
            timeout_secs: None,
            download_timeout_secs: None,
            token_type: file.token_type,
            expires_at: file.expires_at,
            credential_backend: file.credential_backend,
            auto_optimize: None,
            max_image_kb: None,
            max_image_dimension: None,
        }),
    };

    if let Some(layer) = profile_layer {
        apply_profile_layer(target, layer, source, url_source, api_key_source);
    }
}

fn apply_profile_layer(
    target: &mut ConfigFile,
    layer: ProfileConfig,
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
    if layer.auto_optimize.is_some() {
        target.auto_optimize = layer.auto_optimize;
    }
    if layer.max_image_kb.is_some() {
        target.max_image_kb = layer.max_image_kb;
    }
    if layer.max_image_dimension.is_some() {
        target.max_image_dimension = layer.max_image_dimension;
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

fn load_config_layers(
    explicit_config: Option<&Path>,
    cwd: &Path,
    user_config_path: Option<&Path>,
) -> Result<Vec<(ConfigFile, CredentialSource)>> {
    if let Some(explicit_path) = explicit_config {
        return Ok(vec![(
            ConfigFile::load_from_path(explicit_path)?,
            CredentialSource::LocalConfig,
        )]);
    }

    let mut files = Vec::new();
    // Tier 4: User global ~/.config/hbctl/config.toml
    if let Some(user_path) = user_config_path {
        if user_path.is_file() {
            files.push((
                ConfigFile::load_from_path(user_path)?,
                CredentialSource::UserConfig,
            ));
        }
    }
    // Tier 3: Project-local .hbctl.toml
    let local_path = cwd.join(".hbctl.toml");
    if local_path.is_file() {
        files.push((
            ConfigFile::load_from_path(&local_path)?,
            CredentialSource::LocalConfig,
        ));
    }
    Ok(files)
}

/// Summary of a discovered `[profiles.<name>]` entry (secrets excluded).
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ProfileSummary {
    pub name: String,
    pub active: bool,
    pub default: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,
    pub source: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub output: Option<OutputFormat>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub timeout_secs: Option<u64>,
}

/// Discover configured `[profiles.*]` across user and local config layers (never exposing secrets).
pub fn discover_profiles(
    explicit_config: Option<&Path>,
    cwd: &Path,
    user_config_path: Option<&Path>,
    active_profile: Option<&str>,
) -> Result<Vec<ProfileSummary>> {
    let layers = load_config_layers(explicit_config, cwd, user_config_path)?;

    let mut cfg_default_profile: Option<String> = None;
    for (file, _) in layers.iter().rev() {
        if let Some(prof) = normalize_profile_name(file.default_profile.as_deref())? {
            cfg_default_profile = Some(prof);
            break;
        }
    }
    let effective_default = cfg_default_profile.or_else(|| {
        layers
            .iter()
            .any(|(f, _)| f.profiles.contains_key("default"))
            .then(|| "default".to_string())
    });

    let mut profiles: BTreeMap<String, ProfileSummary> = BTreeMap::new();
    for (file, source) in layers {
        for (name, p_cfg) in file.profiles {
            let url = non_empty(p_cfg.url.as_deref())
                .map(|raw| normalize_base_url(raw).unwrap_or_else(|_| raw.to_string()))
                .map(|u| redact_url_credentials(&u));
            profiles.insert(
                name.clone(),
                ProfileSummary {
                    active: active_profile == Some(name.as_str()),
                    default: effective_default.as_deref() == Some(name.as_str()),
                    name,
                    url,
                    source: source.as_str().to_string(),
                    output: p_cfg.output,
                    timeout_secs: p_cfg.timeout_secs,
                },
            );
        }
    }

    Ok(profiles.into_values().collect())
}

/// Validate that `profile` exists in `path` and return the loaded `ConfigFile` and normalized name.
pub fn validate_profile_in_file(path: &Path, profile: &str) -> Result<(ConfigFile, String)> {
    let name = normalize_profile_name(Some(profile))?
        .ok_or_else(|| HbctlError::Config("profile name cannot be empty".into()))?;
    if !path.is_file() {
        return Err(HbctlError::Config(format!(
            "config file '{}' does not exist; no profiles configured",
            path.display()
        )));
    }
    let cfg_file = ConfigFile::load_from_path(path)?;
    if !cfg_file.profiles.contains_key(&name) {
        let available = if cfg_file.profiles.is_empty() {
            "none".to_string()
        } else {
            cfg_file
                .profiles
                .keys()
                .cloned()
                .collect::<Vec<_>>()
                .join(", ")
        };
        return Err(HbctlError::Config(format!(
            "profile '{name}' not found in '{}' (available: {available})",
            path.display()
        )));
    }
    Ok((cfg_file, name))
}

/// Persist `default_profile = <profile>` inside `path`, returning the previous default if any.
pub fn set_default_profile(path: &Path, profile: &str) -> Result<Option<String>> {
    let (mut cfg_file, name) = validate_profile_in_file(path, profile)?;
    let previous = cfg_file.default_profile.clone();
    cfg_file.default_profile = Some(name);
    cfg_file.save_to_path(path)?;
    Ok(previous)
}

/// Default path for user-global config: `~/.config/hbctl/config.toml` (or XDG equivalent).
pub fn default_user_config_path() -> Option<PathBuf> {
    if let Ok(xdg) = std::env::var("XDG_CONFIG_HOME") {
        let trimmed = xdg.trim();
        if !trimmed.is_empty() {
            return Some(PathBuf::from(trimmed).join("hbctl").join("config.toml"));
        }
    }
    BaseDirs::new().map(|dirs| {
        dirs.home_dir()
            .join(".config")
            .join("hbctl")
            .join("config.toml")
    })
}

/// Resolve the target configuration file path (`--config` if given, else `~/.config/hbctl/config.toml`).
pub fn resolve_config_target_path(explicit: Option<&PathBuf>) -> Result<PathBuf> {
    if let Some(p) = explicit {
        return Ok(p.clone());
    }
    default_user_config_path().ok_or_else(|| {
        HbctlError::Config("unable to determine ~/.config/hbctl/config.toml path".into())
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
        return Err(HbctlError::MissingUrl);
    }

    let with_scheme = if trimmed.starts_with("http://") || trimmed.starts_with("https://") {
        trimmed.to_string()
    } else {
        format!("http://{trimmed}")
    };

    let parsed = Url::parse(&with_scheme).map_err(|e| HbctlError::InvalidUrl {
        url: trimmed.to_string(),
        reason: e.to_string(),
    })?;

    if parsed.host_str().is_none() {
        return Err(HbctlError::InvalidUrl {
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

/// Mask any embedded userinfo password inside a URL as `***`.
pub fn redact_url_credentials(raw: &str) -> String {
    let Ok(mut parsed) = Url::parse(raw) else {
        return raw.to_string();
    };
    if parsed.password().is_some() {
        let _ = parsed.set_password(Some("***"));
        return parsed.to_string();
    }
    if !parsed.username().is_empty() {
        return parsed.to_string();
    }
    raw.to_string()
}

/// Mask credentials, tokens, and secret path/query components in Shoutrrr and webhook notifier URLs.
pub fn redact_notifier_url(raw: &str) -> String {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return String::new();
    }

    let Ok(mut parsed) = Url::parse(trimmed) else {
        if let Some(scheme_pos) = trimmed.find("://") {
            let after_scheme = &trimmed[scheme_pos + 3..];
            let authority_end = after_scheme
                .find(['/', '?', '#'])
                .unwrap_or(after_scheme.len());
            let authority = &after_scheme[..authority_end];
            if let Some(at_pos) = authority.rfind('@') {
                return format!(
                    "{}://***@{}",
                    &trimmed[..scheme_pos],
                    &after_scheme[at_pos + 1..]
                );
            }
        }
        return "***".to_string();
    };

    if parsed.password().is_some() {
        let _ = parsed.set_password(Some("***"));
    } else if !parsed.username().is_empty() {
        let _ = parsed.set_username("***");
    }

    if let Some(raw_query) = parsed.query().map(str::to_string) {
        let parts: Vec<String> = raw_query
            .split('&')
            .filter(|s| !s.is_empty())
            .map(|part| {
                let key = part.split_once('=').map(|(k, _)| k).unwrap_or(part);
                let lower = key.to_ascii_lowercase();
                let is_sensitive = [
                    "token", "secret", "key", "password", "pass", "auth", "webhook", "apikey",
                ]
                .iter()
                .any(|needle| lower.contains(needle));
                if is_sensitive {
                    format!("{key}=***")
                } else {
                    part.to_string()
                }
            })
            .collect();
        if parts.is_empty() {
            parsed.set_query(None);
        } else {
            parsed.set_query(Some(&parts.join("&")));
        }
    }

    let scheme_lower = parsed.scheme().to_ascii_lowercase();
    let path = parsed.path().to_string();
    if matches!(scheme_lower.as_str(), "slack" | "gotify") {
        if !path.is_empty() && path != "/" {
            parsed.set_path("/***");
        }
    } else {
        let segments: Vec<&str> = path.split('/').filter(|s| !s.is_empty()).collect();
        if let Some(idx) = segments
            .iter()
            .position(|s| matches!(s.to_ascii_lowercase().as_str(), "webhooks" | "services"))
        {
            if segments.len() > idx + 2 {
                let mut kept: Vec<&str> = segments[..=idx + 1].to_vec();
                kept.push("***");
                let new_path = format!("/{}", kept.join("/"));
                parsed.set_path(&new_path);
            }
        }
    }

    parsed.to_string()
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
            local_dir.join(".hbctl.toml"),
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

        // 2. Project-local .hbctl.toml overrides user config
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

        // 3. Env HOMEBOX_IP < HOMEBOX_URL < HBCTL_URL
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

        env.insert("HBCTL_URL".into(), "http://env-hbctl:7745/api/v1/".into());
        env.insert("HBCTL_API_KEY".into(), "hb_env_hbctl".into());
        let cfg = AppConfig::resolve(
            &CliConfigOverrides::default(),
            &env,
            &local_dir,
            Some(&user_cfg),
        )
        .unwrap();
        assert_eq!(
            cfg.base_url.as_deref(),
            Some("http://env-hbctl:7745/api/v1")
        );
        assert_eq!(cfg.api_key.as_deref(), Some("hb_env_hbctl"));

        // 4. CLI flags override everything
        let overrides = CliConfigOverrides {
            url: Some("http://cli.local:7745".into()),
            api_key: Some("hb_cli".into()),
            output: Some(OutputFormat::Table),
            json: true,
            config_path: None,
            profile: None,
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

    #[test]
    fn test_profiles_precedence_default_fallback_and_secret_scoping() {
        let dir = tempdir().unwrap();
        let empty_dir = dir.path().join("empty");
        fs::create_dir_all(&empty_dir).unwrap();

        let user_cfg = dir.path().join("config.toml");
        fs::write(
            &user_cfg,
            r#"
default_profile = "homelab"
url = "http://legacy.local:7745"
api_key = "hb_legacy"
output = "plain"
timeout_secs = 55

[profiles.homelab]
url = "http://homelab.local:7745"
token_type = "api_key"

[profiles.staging]
url = "http://staging.local:7745"
timeout_secs = 15
"#,
        )
        .unwrap();

        let creds = FileSecretStore::new(dir.path().join("credentials.json"));
        creds
            .set_token(
                &credential_account_key(Some("homelab"), "http://homelab.local:7745/api/v1"),
                "hb_homelab_store",
            )
            .unwrap();
        creds
            .set_token(
                &credential_account_key(Some("staging"), "http://staging.local:7745/api/v1"),
                "hb_staging_store",
            )
            .unwrap();

        // 1. default_profile selects homelab and inherits shared top-level defaults
        let cfg = AppConfig::resolve_with_store(
            &CliConfigOverrides::default(),
            &HashMap::new(),
            &empty_dir,
            Some(&user_cfg),
            Some(&creds),
        )
        .unwrap();
        assert_eq!(cfg.profile.as_deref(), Some("homelab"));
        assert_eq!(
            cfg.base_url.as_deref(),
            Some("http://homelab.local:7745/api/v1")
        );
        assert_eq!(cfg.api_key.as_deref(), Some("hb_homelab_store"));
        assert_eq!(cfg.output, OutputFormat::Plain);
        assert_eq!(cfg.timeout_secs, 55);

        // 2. HBCTL_PROFILE overrides default_profile
        let mut env = HashMap::new();
        env.insert("HBCTL_PROFILE".into(), "staging".into());
        let cfg = AppConfig::resolve_with_store(
            &CliConfigOverrides::default(),
            &env,
            &empty_dir,
            Some(&user_cfg),
            Some(&creds),
        )
        .unwrap();
        assert_eq!(cfg.profile.as_deref(), Some("staging"));
        assert_eq!(
            cfg.base_url.as_deref(),
            Some("http://staging.local:7745/api/v1")
        );
        assert_eq!(cfg.api_key.as_deref(), Some("hb_staging_store"));
        assert_eq!(cfg.timeout_secs, 15);

        // 3. CLI --profile overrides HBCTL_PROFILE and does not leak top-level url/api_key into unknown profile
        let overrides = CliConfigOverrides {
            profile: Some("sandbox".into()),
            ..Default::default()
        };
        let cfg = AppConfig::resolve_with_store(
            &overrides,
            &env,
            &empty_dir,
            Some(&user_cfg),
            Some(&creds),
        )
        .unwrap();
        assert_eq!(cfg.profile.as_deref(), Some("sandbox"));
        assert_eq!(cfg.base_url, None);
        assert_eq!(cfg.api_key, None);
        assert_eq!(cfg.output, OutputFormat::Plain);

        // 4. Implicit [profiles.default] and legacy fallback for `default`
        let default_cfg_path = dir.path().join("default_only.toml");
        fs::write(
            &default_cfg_path,
            r#"
[profiles.default]
url = "http://legacy.local:7745"
"#,
        )
        .unwrap();
        creds
            .set_token("http://legacy.local:7745/api/v1", "hb_legacy_creds")
            .unwrap();
        let cfg = AppConfig::resolve_with_store(
            &CliConfigOverrides::default(),
            &HashMap::new(),
            &empty_dir,
            Some(&default_cfg_path),
            Some(&creds),
        )
        .unwrap();
        assert_eq!(cfg.profile.as_deref(), Some("default"));
        assert_eq!(cfg.api_key.as_deref(), Some("hb_legacy_creds"));

        // 5. Invalid profile name fails cleanly
        let bad = CliConfigOverrides {
            profile: Some("bad/name".into()),
            ..Default::default()
        };
        assert!(AppConfig::resolve_with_store(
            &bad,
            &HashMap::new(),
            &empty_dir,
            Some(&user_cfg),
            Some(&creds),
        )
        .is_err());
    }

    #[test]
    fn test_image_optimization_config_defaults_layering_and_validation() {
        let dir = tempdir().unwrap();
        let empty_dir = dir.path().join("empty");
        fs::create_dir_all(&empty_dir).unwrap();

        // 1. Defaults when unset
        let cfg = AppConfig::resolve(
            &CliConfigOverrides::default(),
            &HashMap::new(),
            &empty_dir,
            None,
        )
        .unwrap();
        assert!(!cfg.auto_optimize);
        assert_eq!(cfg.max_image_kb, 500);
        assert_eq!(cfg.max_image_bytes(), 500 * 1024);
        assert_eq!(cfg.max_image_dimension, 1920);

        // 2. Top-level user config + local config + profile layering
        let user_cfg = dir.path().join("user.toml");
        fs::write(
            &user_cfg,
            r#"
auto_optimize = true
max_image_kb = 400
max_image_dimension = 1600

[profiles.tight]
url = "http://tight.local:7745"
max_image_kb = 250
"#,
        )
        .unwrap();

        let project_dir = dir.path().join("project");
        fs::create_dir_all(&project_dir).unwrap();
        fs::write(
            project_dir.join(".hbctl.toml"),
            r#"
max_image_dimension = 1280
"#,
        )
        .unwrap();

        let cfg_local = AppConfig::resolve(
            &CliConfigOverrides::default(),
            &HashMap::new(),
            &project_dir,
            Some(&user_cfg),
        )
        .unwrap();
        assert!(cfg_local.auto_optimize);
        assert_eq!(cfg_local.max_image_kb, 400);
        assert_eq!(cfg_local.max_image_dimension, 1280);

        let cfg_profile = AppConfig::resolve(
            &CliConfigOverrides {
                profile: Some("tight".into()),
                ..Default::default()
            },
            &HashMap::new(),
            &empty_dir,
            Some(&user_cfg),
        )
        .unwrap();
        assert!(cfg_profile.auto_optimize);
        assert_eq!(cfg_profile.max_image_kb, 250);
        assert_eq!(cfg_profile.max_image_bytes(), 250 * 1024);
        assert_eq!(cfg_profile.max_image_dimension, 1600);

        // 3. Reject zero values for max_image_kb and max_image_dimension
        let zero_kb = dir.path().join("zero_kb.toml");
        fs::write(&zero_kb, "max_image_kb = 0\n").unwrap();
        assert!(AppConfig::resolve(
            &CliConfigOverrides::default(),
            &HashMap::new(),
            &empty_dir,
            Some(&zero_kb),
        )
        .is_err());

        let zero_dim = dir.path().join("zero_dim.toml");
        fs::write(&zero_dim, "max_image_dimension = 0\n").unwrap();
        assert!(AppConfig::resolve(
            &CliConfigOverrides::default(),
            &HashMap::new(),
            &empty_dir,
            Some(&zero_dim),
        )
        .is_err());
    }

    #[test]
    fn test_output_format_credential_source_and_url_errors() {
        assert_eq!(
            "TABLE".parse::<OutputFormat>().unwrap(),
            OutputFormat::Table
        );
        assert_eq!(
            " json ".parse::<OutputFormat>().unwrap(),
            OutputFormat::Json
        );
        assert_eq!(
            "Plain".parse::<OutputFormat>().unwrap(),
            OutputFormat::Plain
        );
        assert_eq!("csv".parse::<OutputFormat>().unwrap(), OutputFormat::Csv);
        assert_eq!(
            "markdown".parse::<OutputFormat>().unwrap(),
            OutputFormat::Markdown
        );
        assert_eq!(
            "MD".parse::<OutputFormat>().unwrap(),
            OutputFormat::Markdown
        );
        assert_eq!(OutputFormat::Csv.as_str(), "csv");
        assert_eq!(OutputFormat::Markdown.as_str(), "markdown");
        assert!("xml".parse::<OutputFormat>().is_err());

        for (src, label) in [
            (CredentialSource::CliFlag, "cli_flag"),
            (CredentialSource::Env, "env"),
            (CredentialSource::LocalConfig, "local_config"),
            (CredentialSource::UserConfig, "user_config"),
            (CredentialSource::Keyring, "keyring"),
            (CredentialSource::CredentialsFile, "credentials_file"),
        ] {
            assert_eq!(src.as_str(), label);
            assert_eq!(src.to_string(), label);
        }

        let dir = tempdir().unwrap();
        assert!(ConfigFile::load_from_path(&dir.path().join("missing.toml")).is_err());
        let bad_toml = dir.path().join("bad.toml");
        fs::write(&bad_toml, "not = [valid").unwrap();
        assert!(ConfigFile::load_from_path(&bad_toml).is_err());

        assert!(matches!(
            normalize_base_url("   "),
            Err(HbctlError::MissingUrl)
        ));
        assert!(matches!(
            normalize_base_url("http://"),
            Err(HbctlError::InvalidUrl { .. })
        ));
    }

    #[test]
    fn test_redact_url_credentials_and_profile_discovery_and_switching() {
        assert_eq!(
            redact_url_credentials("http://alice:topsecret@staging.local:7745/api/v1"),
            "http://alice:***@staging.local:7745/api/v1"
        );
        assert_eq!(
            redact_url_credentials("http://192.168.1.50:7745/api/v1"),
            "http://192.168.1.50:7745/api/v1"
        );
        assert_eq!(redact_url_credentials("not a url"), "not a url");

        let dir = tempdir().unwrap();
        let empty_dir = dir.path().join("empty");
        fs::create_dir_all(&empty_dir).unwrap();

        let user_cfg = dir.path().join("config.toml");
        fs::write(
            &user_cfg,
            r#"
default_profile = "homelab"
timeout_secs = 40

[profiles.homelab]
url = "http://homelab.local:7745"
api_key = "hb_super_secret"
output = "plain"

[profiles.staging]
url = "http://alice:topsecret@staging.local:7745"
timeout_secs = 15
"#,
        )
        .unwrap();

        let local_dir = dir.path().join("project");
        fs::create_dir_all(&local_dir).unwrap();
        fs::write(
            local_dir.join(".hbctl.toml"),
            r#"
[profiles.staging]
url = "http://bob:localpass@staging-override.local:7745"

[profiles.localdev]
url = "http://127.0.0.1:7745"
"#,
        )
        .unwrap();

        // Discovery across user + local (local overrides user for `staging`, passwords redacted)
        let profiles =
            discover_profiles(None, &local_dir, Some(&user_cfg), Some("staging")).unwrap();
        assert_eq!(profiles.len(), 3);

        assert_eq!(profiles[0].name, "homelab");
        assert!(!profiles[0].active);
        assert!(profiles[0].default);
        assert_eq!(profiles[0].source, "user_config");
        assert_eq!(profiles[0].output, Some(OutputFormat::Plain));

        assert_eq!(profiles[1].name, "localdev");
        assert_eq!(profiles[1].source, "local_config");

        assert_eq!(profiles[2].name, "staging");
        assert!(profiles[2].active);
        assert!(!profiles[2].default);
        assert_eq!(profiles[2].source, "local_config");
        assert_eq!(
            profiles[2].url.as_deref(),
            Some("http://bob:***@staging-override.local:7745/api/v1")
        );

        // Explicit config ignores user/local layers
        let explicit_profiles =
            discover_profiles(Some(&user_cfg), &local_dir, Some(&user_cfg), None).unwrap();
        assert_eq!(explicit_profiles.len(), 2);
        assert_eq!(
            explicit_profiles[1].url.as_deref(),
            Some("http://alice:***@staging.local:7745/api/v1")
        );

        // Empty directory with no config files -> empty profile list
        assert!(discover_profiles(None, &empty_dir, None, None)
            .unwrap()
            .is_empty());

        // Switching default profile preserves existing profiles/fields
        let prev = set_default_profile(&user_cfg, "staging").unwrap();
        assert_eq!(prev.as_deref(), Some("homelab"));
        let reloaded = ConfigFile::load_from_path(&user_cfg).unwrap();
        assert_eq!(reloaded.default_profile.as_deref(), Some("staging"));
        assert_eq!(reloaded.timeout_secs, Some(40));
        assert!(reloaded.profiles.contains_key("homelab"));
        assert_eq!(
            reloaded.profiles["homelab"].api_key.as_deref(),
            Some("hb_super_secret")
        );

        // Error cases for set_default_profile
        assert!(set_default_profile(&dir.path().join("missing.toml"), "staging").is_err());
        let missing_prof = set_default_profile(&user_cfg, "nope").unwrap_err();
        assert!(missing_prof
            .to_string()
            .contains("available: homelab, staging"));
        assert!(set_default_profile(&user_cfg, "bad/name").is_err());
        assert!(set_default_profile(&user_cfg, "   ").is_err());
    }

    #[test]
    fn test_redact_notifier_url_variants() {
        assert_eq!(redact_notifier_url(""), "");
        assert_eq!(
            redact_notifier_url("smtp://user:s3cr3t@mail.example.com:587"),
            "smtp://user:***@mail.example.com:587"
        );
        assert_eq!(
            redact_notifier_url("ntfy://alice:my_pass@ntfy.sh/alerts"),
            "ntfy://alice:***@ntfy.sh/alerts"
        );
        assert_eq!(
            redact_notifier_url("discord://tok123abc@123456789"),
            "discord://***@123456789"
        );
        assert_eq!(
            redact_notifier_url("telegram://bot123:XYZ@telegram?chats=123"),
            "telegram://bot123:***@telegram?chats=123"
        );
        assert_eq!(
            redact_notifier_url("telegram://bot_token@telegram?chats=123"),
            "telegram://***@telegram?chats=123"
        );
        assert_eq!(
            redact_notifier_url("generic+https://example.com/hook?token=secret_val&channel=ops"),
            "generic+https://example.com/hook?token=***&channel=ops"
        );
        assert_eq!(
            redact_notifier_url("https://discord.com/api/webhooks/12345/secret_tok"),
            "https://discord.com/api/webhooks/12345/***"
        );
        assert_eq!(
            redact_notifier_url("https://hooks.slack.com/services/T00/B00/XXX"),
            "https://hooks.slack.com/services/T00/***"
        );
        assert_eq!(
            redact_notifier_url("slack://T00/B00/XXX"),
            "slack://T00/***"
        );
        assert_eq!(
            redact_notifier_url("gotify://gotify.local/AbCdEf123"),
            "gotify://gotify.local/***"
        );
        assert_eq!(redact_notifier_url("not-a-valid-url-secret"), "***");
        assert_eq!(
            redact_notifier_url("not a valid url://secret_tok@host/path"),
            "not a valid url://***@host/path"
        );
        assert_eq!(
            redact_notifier_url("custom://tok_abc@host with spaces/path"),
            "custom://***@host with spaces/path"
        );
    }
}

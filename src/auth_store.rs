use std::collections::BTreeMap;
use std::fs::{self, OpenOptions};
use std::io::Write;
use std::path::{Path, PathBuf};

#[cfg(unix)]
use std::os::unix::fs::{OpenOptionsExt, PermissionsExt};

use directories::BaseDirs;
use serde::{Deserialize, Serialize};

use crate::error::{HbctlError, Result};

/// Storage backend where an `hbctl auth` secret token is persisted.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum CredentialBackend {
    Keyring,
    File,
}

impl CredentialBackend {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Keyring => "keyring",
            Self::File => "file",
        }
    }
}

impl std::fmt::Display for CredentialBackend {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}

/// Kind of Homebox authentication credential.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum TokenType {
    ApiKey,
    Jwt,
}

impl TokenType {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::ApiKey => "api_key",
            Self::Jwt => "jwt",
        }
    }

    /// Infer token kind from raw token string (`hb_*` -> `ApiKey`, otherwise `Jwt`).
    pub fn infer(raw: &str) -> Self {
        let trimmed = raw.trim();
        let bare = if trimmed.len() >= 7 && trimmed[..7].eq_ignore_ascii_case("bearer ") {
            trimmed[7..].trim()
        } else {
            trimmed
        };
        if bare.starts_with("hb_") {
            Self::ApiKey
        } else {
            Self::Jwt
        }
    }
}

impl std::fmt::Display for TokenType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str(self.as_str())
    }
}

/// Secret token persistence abstraction (keyring or `0600` local file).
pub trait SecretStore {
    fn set_token(&self, account: &str, token: &str) -> Result<CredentialBackend>;
    fn get_token(&self, account: &str) -> Result<Option<(String, CredentialBackend)>>;
    fn delete_token(&self, account: &str) -> Result<bool>;
}

/// Build the credential store account key for an optional profile and normalized base URL.
/// Legacy single-instance mode (`profile: None`) uses `base_url` directly; named profiles use
/// `profile:<name>:<base_url>` so entries stay isolated in both OS keyring and `0600` file store.
pub fn credential_account_key(profile: Option<&str>, base_url: &str) -> String {
    match profile.map(str::trim).filter(|s| !s.is_empty()) {
        Some(name) => format!("profile:{name}:{base_url}"),
        None => base_url.to_string(),
    }
}

/// Default local fallback credentials path (`~/.config/hbctl/credentials.json` or XDG equivalent).
pub fn default_credentials_file_path() -> Option<PathBuf> {
    if let Ok(xdg) = std::env::var("XDG_CONFIG_HOME") {
        let trimmed = xdg.trim();
        if !trimmed.is_empty() {
            return Some(
                PathBuf::from(trimmed)
                    .join("hbctl")
                    .join("credentials.json"),
            );
        }
    }
    BaseDirs::new().map(|dirs| {
        dirs.home_dir()
            .join(".config")
            .join("hbctl")
            .join("credentials.json")
    })
}

/// Returns true when keyring access should be bypassed via env (`HBCTL_INSECURE_STORAGE=1|true`).
pub fn env_forces_file_storage() -> bool {
    std::env::var("HBCTL_INSECURE_STORAGE")
        .map(|v| matches!(v.trim().to_ascii_lowercase().as_str(), "1" | "true" | "yes"))
        .unwrap_or(false)
}

/// `0600`-permissioned JSON file secret store for headless/SSH/container environments.
#[derive(Debug, Clone)]
pub struct FileSecretStore {
    path: PathBuf,
}

impl FileSecretStore {
    pub fn new(path: PathBuf) -> Self {
        Self { path }
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    fn load_map(&self) -> Result<BTreeMap<String, String>> {
        if !self.path.is_file() {
            return Ok(BTreeMap::new());
        }
        let content = fs::read_to_string(&self.path)?;
        let map: BTreeMap<String, String> = serde_json::from_str(&content).unwrap_or_default();
        Ok(map)
    }

    fn save_map(&self, data: &BTreeMap<String, String>) -> Result<()> {
        if let Some(parent) = self.path.parent() {
            fs::create_dir_all(parent)?;
            #[cfg(unix)]
            {
                let _ = fs::set_permissions(parent, fs::Permissions::from_mode(0o700));
            }
        }
        let json = serde_json::to_string_pretty(data)?;
        let mut options = OpenOptions::new();
        options.write(true).create(true).truncate(true);
        #[cfg(unix)]
        options.mode(0o600);

        let mut file = options.open(&self.path)?;
        file.write_all(json.as_bytes())?;
        #[cfg(unix)]
        {
            let _ = fs::set_permissions(&self.path, fs::Permissions::from_mode(0o600));
        }
        Ok(())
    }
}

impl SecretStore for FileSecretStore {
    fn set_token(&self, account: &str, token: &str) -> Result<CredentialBackend> {
        let mut map = self.load_map()?;
        map.insert(account.to_string(), token.to_string());
        self.save_map(&map)?;
        Ok(CredentialBackend::File)
    }

    fn get_token(&self, account: &str) -> Result<Option<(String, CredentialBackend)>> {
        let map = self.load_map()?;
        Ok(map
            .get(account)
            .cloned()
            .filter(|s| !s.trim().is_empty())
            .map(|t| (t, CredentialBackend::File)))
    }

    fn delete_token(&self, account: &str) -> Result<bool> {
        if !self.path.is_file() {
            return Ok(false);
        }
        let mut map = self.load_map()?;
        let removed = map.remove(account).is_some();
        if removed {
            self.save_map(&map)?;
        }
        Ok(removed)
    }
}

/// OS system keyring store (`Secret Service`, macOS Keychain, Windows Credential Manager).
#[derive(Debug, Clone)]
pub struct KeyringSecretStore {
    service: String,
}

impl KeyringSecretStore {
    pub const DEFAULT_SERVICE: &'static str = "hbctl";

    pub fn new(service: impl Into<String>) -> Self {
        Self {
            service: service.into(),
        }
    }
}

impl Default for KeyringSecretStore {
    fn default() -> Self {
        Self::new(Self::DEFAULT_SERVICE)
    }
}

impl SecretStore for KeyringSecretStore {
    fn set_token(&self, account: &str, token: &str) -> Result<CredentialBackend> {
        let entry = keyring::Entry::new(&self.service, account)
            .map_err(|e| HbctlError::Config(format!("keyring init failed: {e}")))?;
        entry
            .set_password(token)
            .map_err(|e| HbctlError::Config(format!("keyring save failed: {e}")))?;
        Ok(CredentialBackend::Keyring)
    }

    fn get_token(&self, account: &str) -> Result<Option<(String, CredentialBackend)>> {
        let entry = keyring::Entry::new(&self.service, account)
            .map_err(|e| HbctlError::Config(format!("keyring init failed: {e}")))?;
        match entry.get_password() {
            Ok(secret) if !secret.trim().is_empty() => {
                Ok(Some((secret, CredentialBackend::Keyring)))
            }
            Ok(_) | Err(keyring::Error::NoEntry) => Ok(None),
            Err(e) => Err(HbctlError::Config(format!("keyring read failed: {e}"))),
        }
    }

    fn delete_token(&self, account: &str) -> Result<bool> {
        let entry = keyring::Entry::new(&self.service, account)
            .map_err(|e| HbctlError::Config(format!("keyring init failed: {e}")))?;
        match entry.delete_credential() {
            Ok(()) => Ok(true),
            Err(keyring::Error::NoEntry) => Ok(false),
            Err(e) => Err(HbctlError::Config(format!("keyring delete failed: {e}"))),
        }
    }
}

/// Hybrid credential store: attempts OS keyring first and automatically falls back
/// to a `0600` local file when headless/unavailable or when `insecure_storage` is true.
#[derive(Debug, Clone)]
pub struct AutoSecretStore {
    keyring: KeyringSecretStore,
    file: FileSecretStore,
    insecure_storage: bool,
}

impl AutoSecretStore {
    pub fn new(keyring: KeyringSecretStore, file: FileSecretStore, insecure_storage: bool) -> Self {
        Self {
            keyring,
            file,
            insecure_storage,
        }
    }

    pub fn from_defaults(insecure_storage: bool) -> Result<Self> {
        let path = default_credentials_file_path().ok_or_else(|| {
            HbctlError::Config("unable to determine user config directory for credentials".into())
        })?;
        Ok(Self::new(
            KeyringSecretStore::default(),
            FileSecretStore::new(path),
            insecure_storage || env_forces_file_storage(),
        ))
    }

    pub fn file_path(&self) -> &Path {
        self.file.path()
    }

    /// Save token, writing a diagnostic notice to `err` if falling back from keyring to file.
    pub fn set_token_with_notice(
        &self,
        account: &str,
        token: &str,
        err: &mut dyn Write,
    ) -> Result<CredentialBackend> {
        if self.insecure_storage {
            return self.file.set_token(account, token);
        }
        match self.keyring.set_token(account, token) {
            Ok(backend) => Ok(backend),
            Err(e) => {
                let _ = writeln!(
                    err,
                    "notice: OS keyring unavailable ({e}); falling back to 0600 file store at {}",
                    self.file.path().display()
                );
                self.file.set_token(account, token)
            }
        }
    }
}

impl SecretStore for AutoSecretStore {
    fn set_token(&self, account: &str, token: &str) -> Result<CredentialBackend> {
        if self.insecure_storage {
            return self.file.set_token(account, token);
        }
        match self.keyring.set_token(account, token) {
            Ok(backend) => Ok(backend),
            Err(_) => self.file.set_token(account, token),
        }
    }

    fn get_token(&self, account: &str) -> Result<Option<(String, CredentialBackend)>> {
        if !self.insecure_storage {
            if let Ok(Some(found)) = self.keyring.get_token(account) {
                return Ok(Some(found));
            }
        }
        self.file.get_token(account)
    }

    fn delete_token(&self, account: &str) -> Result<bool> {
        let mut deleted = false;
        if !self.insecure_storage {
            if let Ok(true) = self.keyring.delete_token(account) {
                deleted = true;
            }
        }
        if self.file.delete_token(account)? {
            deleted = true;
        }
        Ok(deleted)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;

    #[test]
    fn test_token_type_infer() {
        assert_eq!(TokenType::infer("hb_abc123"), TokenType::ApiKey);
        assert_eq!(TokenType::infer("Bearer hb_abc123"), TokenType::ApiKey);
        assert_eq!(
            TokenType::infer("Bearer eyJhbGciOiJIUzI1NiJ9.payload.sig"),
            TokenType::Jwt
        );
        assert_eq!(TokenType::infer("eyJabc"), TokenType::Jwt);
    }

    #[test]
    fn test_file_secret_store_lifecycle_and_permissions() {
        let dir = tempdir().unwrap();
        let path = dir.path().join("hbctl").join("credentials.json");
        let store = FileSecretStore::new(path.clone());

        assert_eq!(store.get_token("http://box:7745/api/v1").unwrap(), None);

        let backend = store
            .set_token("http://box:7745/api/v1", "hb_secret_val")
            .unwrap();
        assert_eq!(backend, CredentialBackend::File);

        #[cfg(unix)]
        {
            let mode = fs::metadata(&path).unwrap().permissions().mode() & 0o777;
            assert_eq!(mode, 0o600);
        }

        let got = store.get_token("http://box:7745/api/v1").unwrap();
        assert_eq!(
            got,
            Some(("hb_secret_val".to_string(), CredentialBackend::File))
        );

        assert!(store.delete_token("http://box:7745/api/v1").unwrap());
        assert_eq!(store.get_token("http://box:7745/api/v1").unwrap(), None);
        assert!(!store.delete_token("http://box:7745/api/v1").unwrap());
    }

    #[test]
    fn test_auto_store_insecure_mode_uses_file_only() {
        let dir = tempdir().unwrap();
        let path = dir.path().join("credentials.json");
        let store = AutoSecretStore::new(
            KeyringSecretStore::new("hbctl-test-unused"),
            FileSecretStore::new(path.clone()),
            true,
        );

        let mut err_buf = Vec::new();
        let backend = store
            .set_token_with_notice("http://box:7745/api/v1", "hb_tok", &mut err_buf)
            .unwrap();
        assert_eq!(backend, CredentialBackend::File);
        assert!(path.is_file());

        let loaded = store.get_token("http://box:7745/api/v1").unwrap();
        assert_eq!(
            loaded,
            Some(("hb_tok".to_string(), CredentialBackend::File))
        );

        assert!(store.delete_token("http://box:7745/api/v1").unwrap());
        assert_eq!(store.get_token("http://box:7745/api/v1").unwrap(), None);
    }

    #[test]
    fn test_credential_account_key_and_profile_isolation() {
        let url = "http://box:7745/api/v1";
        assert_eq!(credential_account_key(None, url), url);
        assert_eq!(credential_account_key(Some("  "), url), url);
        assert_eq!(
            credential_account_key(Some("staging"), url),
            "profile:staging:http://box:7745/api/v1"
        );

        let dir = tempdir().unwrap();
        let store = FileSecretStore::new(dir.path().join("credentials.json"));
        let k_home = credential_account_key(Some("homelab"), url);
        let k_stage = credential_account_key(Some("staging"), url);

        store.set_token(&k_home, "hb_homelab").unwrap();
        store.set_token(&k_stage, "hb_staging").unwrap();

        assert_eq!(
            store.get_token(&k_home).unwrap(),
            Some(("hb_homelab".to_string(), CredentialBackend::File))
        );
        assert_eq!(
            store.get_token(&k_stage).unwrap(),
            Some(("hb_staging".to_string(), CredentialBackend::File))
        );

        assert!(store.delete_token(&k_stage).unwrap());
        assert_eq!(store.get_token(&k_stage).unwrap(), None);
        assert_eq!(
            store.get_token(&k_home).unwrap(),
            Some(("hb_homelab".to_string(), CredentialBackend::File))
        );
    }

    #[test]
    fn test_display_paths_and_auto_store_set_token() {
        assert_eq!(CredentialBackend::Keyring.to_string(), "keyring");
        assert_eq!(CredentialBackend::File.to_string(), "file");
        assert_eq!(TokenType::ApiKey.to_string(), "api_key");
        assert_eq!(TokenType::Jwt.to_string(), "jwt");

        let dir = tempdir().unwrap();
        let path = dir.path().join("creds.json");
        let file_store = FileSecretStore::new(path.clone());
        assert_eq!(file_store.path(), path.as_path());

        let auto_store = AutoSecretStore::new(
            KeyringSecretStore::new("hbctl-test-unused"),
            file_store,
            true,
        );
        assert_eq!(auto_store.file_path(), path.as_path());
        let backend = auto_store
            .set_token("http://box:7745/api/v1", "hb_direct")
            .unwrap();
        assert_eq!(backend, CredentialBackend::File);
        assert_eq!(
            auto_store.get_token("http://box:7745/api/v1").unwrap(),
            Some(("hb_direct".to_string(), CredentialBackend::File))
        );
    }
}

# Authentication & Security

## :lock: Credential Storage & Headless Fallback

`hbctl auth login` stores API keys and JWT session tokens outside your configuration files:

- **OS Keyring (Default):** Attempts native platform storage under service `hbctl` (`Secret Service`/D-Bus on Linux, Keychain on macOS, Credential Manager on Windows).
- **`0600` File Fallback:** If the OS keyring is unavailable, locked, or running in a headless/SSH/container environment, `hbctl` prints a notice to `stderr` and writes credentials to `~/.config/hbctl/credentials.json` (or `$XDG_CONFIG_HOME/hbctl/credentials.json`) with `0600` file permissions inside a `0700` directory.
- **Explicit File Store:** Pass `--insecure-storage` to `auth login`, `auth refresh`, or `auth logout`, or set `HBCTL_INSECURE_STORAGE=1` (also `true` / `yes`), to target the `0600` file store directly without querying the OS keyring.
- **Profile Isolation:** Legacy single-instance logins store tokens under the normalized base URL. Named profiles store tokens under `profile:<name>:<base_url>` so homelab, staging, and production credentials remain isolated.

Only non-secret metadata (`url`, `token_type`, `expires_at`, `credential_backend`) is persisted in `~/.config/hbctl/config.toml`.

## :key: Authentication Methods & Token Lifecycle

`hbctl` supports both Homebox static API keys (`hb_...`) and short-lived JWT session tokens:

```bash
# 1. Static API key via stdin (recommended for scripts and CI/agents)
echo "$HOMEBOX_API_KEY" | hbctl auth login --url http://192.168.1.50:7745 --with-token

# 2. Interactive email/password login (POST /api/v1/users/login)
hbctl auth login --url http://192.168.1.50:7745 --username you@example.com

# 3. Non-interactive password login via stdin (avoids shell history leaks)
printf '%s\n' "$HOMEBOX_PASSWORD" | hbctl auth login --url http://192.168.1.50:7745 -u you@example.com --password-stdin

# Refresh an active JWT session token
hbctl auth refresh

# Validate active credentials against Homebox
hbctl auth status

# Remove stored credentials from keyring and local fallback store
hbctl auth logout
```

`hbctl` normalizes tokens automatically so both `hb_...` keys and `Bearer ...` strings map to a single `Authorization: Bearer <token>` header without double-prefixing.

## :shield: Secret Redaction & Dry-Run Safety

- **`Bearer ***` Masking:** `hbctl auth status`, `--dry-run` request previews, and HTTP diagnostics always redact the `Authorization` header to `Bearer ***`.
- **Diagnostic Scrubbing:** Error handlers pass messages through `redact_secret` so accidental occurrences of the active API key or JWT are replaced with `***` before printing to `stderr`.
- **Safe Mutation Preview:** Prefix any mutating command (`item create`, `item update`, `item upsert`, `item delete`, `attachment upload`, `tag create`, etc.) with `--dry-run` to inspect the HTTP method, target URL, redacted headers, and JSON body without modifying Homebox.

## :warning: Local Config & Secret Hygiene

- Keep `.env`, `.hbctl.toml`, and `credentials.json` out of version control (`.gitignore` already excludes `.env`, `.env.*`, `.hbctl.toml`, and `config.toml`).
- Prefer `hbctl auth login --with-token` or environment variables (`HBCTL_API_KEY` / `HOMEBOX_API_KEY`) over writing plaintext `api_key` values into TOML files.
- Never use blanket staging (`git add .` / `git add -A`) in repositories containing local `.env` or `.hbctl.toml` files.

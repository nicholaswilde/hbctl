# Configuration

`hbctl` supports TOML configuration files at both user-global (`~/.config/hbctl/config.toml`) and project-local (`.hbctl.toml`) scopes. A fully commented template documenting all options is provided in [`assets/config.example.toml`](https://github.com/nicholaswilde/hbctl/blob/main/assets/config.example.toml) (also bundled in release archives as `config.example.toml`).

To initialize a user-global configuration from the template:

```bash
mkdir -p ~/.config/hbctl
cp assets/config.example.toml ~/.config/hbctl/config.toml
```

## :1234: Layered Precedence

Settings resolve in strict hierarchical precedence order (highest to lowest):

1. **CLI Flags:** `--url`, `--api-key`, `--profile` (`-P`), `--output`, `--json`, `--config` (`-C`).
2. **Environment Variables & Local `.env`:** `HBCTL_URL` > `HOMEBOX_URL` > `HOMEBOX_IP`, `HBCTL_API_KEY` > `HOMEBOX_API_KEY`, `HBCTL_PROFILE`, `HBCTL_OUTPUT`, `HBCTL_INSECURE_STORAGE`.
3. **Project-Local Config:** `./.hbctl.toml` in the current working directory.
4. **User-Global Config & Stored Auth:** `~/.config/hbctl/config.toml` (or `$XDG_CONFIG_HOME/hbctl/config.toml`) plus credentials stored by `hbctl auth login` in the OS keyring or `~/.config/hbctl/credentials.json`.
5. **Built-In Defaults:** `output = "table"`, `timeout_secs = 30`, `download_timeout_secs = 120`, `auto_optimize = false`, `max_image_kb = 500`, `max_image_dimension = 1920`.

!!! note
    Passing `-C` / `--config <path>` loads only that explicit TOML file instead of `~/.config/hbctl/config.toml` and `./.hbctl.toml`.

### URL Normalization & `HOMEBOX_IP`

- `url` values work with or without `/api/v1` (both `http://192.168.1.50:7745` and `http://192.168.1.50:7745/api/v1/` resolve to `http://192.168.1.50:7745/api/v1`). Missing schemes default to `http://`.
- `HOMEBOX_IP` expands bare IPs/hostnames (for example `192.168.1.50`) to `http://192.168.1.50:7745` (port `7745`), unless a port or `http(s)://` scheme is already included.

## :card_index_dividers: Multi-Instance Profiles

Manage multiple Homebox environments (such as `homelab` and `staging`) inside a single `~/.config/hbctl/config.toml` using `[profiles.<name>]` sections and `default_profile`:

```bash
# Authenticate separate profiles (credentials are isolated per profile)
echo "$HOMELAB_KEY" | hbctl --profile homelab auth login --url http://192.168.1.50:7745 --with-token
echo "$STAGING_KEY" | hbctl --profile staging auth login --url https://homebox-staging.example.com --with-token

# Target an instance via flag or environment variable
hbctl -P staging item list
HBCTL_PROFILE=staging hbctl item list
```

Profile names allow ASCII letters, digits, `-`, `_`, and `.`. Stored credentials use `profile:<name>:<base_url>` as the keyring/file account key so switching profiles never leaks tokens across instances.

## :framed_picture: Image Upload Guard & Auto-Optimization

By default, `hbctl` rejects image uploads exceeding `500` KB (`max_image_kb = 500`) unless you pass `--force` or enable optimization:

- **On-Demand (`--optimize`):** Pass `--optimize` to `item create`, `item upsert`, `item import`, or `attachment upload`.
- **Always On (`auto_optimize = true`):** Enable globally or per profile in `config.toml`.
- **Pipeline:** Decodes JPEG, PNG, or WebP in memory, applies EXIF orientation, resizes images exceeding `max_image_dimension` (`1920` px) using Catmull-Rom filtering, attempts native PNG/WebP re-encoding when smaller than `max_image_kb`, and otherwise steps through a JPEG quality ladder (`85` down to `35`) and `0.75x` dimension scaling rounds until under budget. Transparent images flatten onto white before JPEG fallback.

## :gear: Example Configuration

=== "Single Instance"

    ```toml title="~/.config/hbctl/config.toml"
    url = "http://192.168.1.50:7745"
    output = "table"
    timeout_secs = 30
    download_timeout_secs = 120
    auto_optimize = true
    max_image_kb = 500
    max_image_dimension = 1920
    ```

=== "Multi-Instance Profiles"

    ```toml title="~/.config/hbctl/config.toml"
    default_profile = "homelab"
    output = "table"
    timeout_secs = 30
    download_timeout_secs = 120
    auto_optimize = false
    max_image_kb = 500
    max_image_dimension = 1920

    [profiles.homelab]
    url = "http://192.168.1.50:7745"

    [profiles.staging]
    url = "https://homebox-staging.example.com"
    output = "json"
    timeout_secs = 15
    auto_optimize = true
    ```

## :earth_americas: Environment Variables Reference

| Variable | Config Option | CLI Flag | Description |
| :--- | :--- | :--- | :--- |
| `HBCTL_URL` | `url` | `--url` | Homebox base URL (highest env precedence) |
| `HOMEBOX_URL` | `url` | `--url` | Fallback Homebox base URL |
| `HOMEBOX_IP` | `url` | `--url` | Host/IP expanded to `http://<HOMEBOX_IP>:7745` |
| `HBCTL_API_KEY` | `api_key` | `--api-key` | Homebox API key (`hb_...`) or Bearer token (highest env precedence) |
| `HOMEBOX_API_KEY` | `api_key` | `--api-key` | Fallback Homebox API key or Bearer token |
| `HBCTL_PROFILE` | `default_profile` | `-P`, `--profile` | Active named profile from `config.toml` |
| `HBCTL_OUTPUT` | `output` | `--output`, `--json` | Output format (`table`, `json`, or `plain`) |
| `HBCTL_INSECURE_STORAGE` | N/A | `--insecure-storage` | Set to `1`, `true`, or `yes` to bypass OS keyring and use `0600` file store |
| `XDG_CONFIG_HOME` | N/A | `-C`, `--config` | Base directory for `~/.config/hbctl/config.toml` and `credentials.json` |

# :package: hbctl :house:

![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/nicholaswilde/hbctl?style=for-the-badge)
[![ci](https://img.shields.io/github/actions/workflow/status/nicholaswilde/hbctl/ci.yml?label=ci&style=for-the-badge&branch=main&logo=github-actions)](https://github.com/nicholaswilde/hbctl/actions/workflows/ci.yml)
[![Coveralls](https://img.shields.io/coveralls/github/nicholaswilde/hbctl/main?style=for-the-badge&logo=coveralls)](https://coveralls.io/github/nicholaswilde/hbctl?branch=main)
[![task](https://img.shields.io/badge/Task-Enabled-brightgreen?style=for-the-badge&logo=task&logoColor=white)](https://taskfile.dev/#/)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg?style=for-the-badge)](../LICENSE)

A fast, zero-dependency, agent-friendly Rust CLI client for interacting with remote Homebox v0.26+ instances over the REST API. Centralizes inventory CRUD, upsert, bulk import, deduplication, multi-file attachment management, typed custom fields, tag/entity-type resolution, and filtered exports.

> [!WARNING]
> This project is currently in a `v0.X.X` development stage. Features and configurations are subject to change.

---

## :rocket:&nbsp; TL;DR

### :floppy_disk:&nbsp; Installation

```bash
# Homebrew
brew install nicholaswilde/homebrew-tap/hbctl
```

```powershell
# Scoop (Windows)
scoop bucket add nicholaswilde https://github.com/nicholaswilde/scoop-bucket
scoop install nicholaswilde/hbctl
```

```bash
# Cargo (from source)
cargo install --git https://github.com/nicholaswilde/hbctl
```

### :gear:&nbsp; Usage

```bash
# Authenticate (API key via stdin, stored in OS keyring with 0600 file fallback)
echo "$HOMEBOX_API_KEY" | hbctl auth login --url http://192.168.1.50:7745 --with-token

# Or authenticate with email & password
hbctl auth login --url http://192.168.1.50:7745 --username you@example.com

# Check active session status (redacted Bearer ***)
hbctl auth status

# List items with compact JSON and field projection
hbctl item list --tag electronics --json --select id,name,quantity

# Create an item with typed custom fields (auto-persisted via follow-up PUT)
hbctl item create --name "ESP32 DevKit" --tag microcontroller --field Voltage=3.3

# Idempotent upsert by name
hbctl item upsert --name "ESP32 DevKit" --field QuantityInBin=5 --field-type number

# Two-pass deduplication preview or merge
hbctl item dedup --threshold 0.8 --merge --dry-run

# Upload multiple attachments (skip existing by default)
hbctl attachment upload <ITEM_ID> manual.pdf schematic.png

# Stream download all PDF attachments
hbctl attachment download <ITEM_ID> --all --ext pdf --out ./manuals

# Export filtered Markdown table
hbctl export --tag electronics --field Manufacturer --field Voltage --format markdown

# Check for or install the latest GitHub release
hbctl update --check
```

---

## :wrench:&nbsp; Configuration

Layered precedence (highest to lowest):

1. CLI flags (`--url`, `--api-key`, `--output`, `--config`)
2. Environment variables / local `.env` (`HBCTL_URL` > `HOMEBOX_URL` > `HOMEBOX_IP`, `HBCTL_API_KEY` > `HOMEBOX_API_KEY`, `HBCTL_OUTPUT`)
3. Project-local `.hbctl.toml`
4. User global `~/.config/hbctl/config.toml` + stored `hbctl auth` credentials (OS keyring with automatic `0600` `~/.config/hbctl/credentials.json` fallback)
5. Built-in defaults (`output = "table"`, `timeout_secs = 30`, `download_timeout_secs = 120`)

See [`assets/config.example.toml`](../assets/config.example.toml).

---

## :balance_scale:&nbsp; License

[Apache License 2.0](../LICENSE)

---

## :pencil:&nbsp; Author

This project was started in 2026 by [Nicholas Wilde](https://github.com/nicholaswilde/).

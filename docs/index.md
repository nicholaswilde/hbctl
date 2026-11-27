# hbctl

![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/nicholaswilde/hbctl?style=for-the-badge)
[![ci](https://img.shields.io/github/actions/workflow/status/nicholaswilde/hbctl/ci.yml?label=ci&style=for-the-badge&branch=main&logo=github-actions)](https://github.com/nicholaswilde/hbctl/actions/workflows/ci.yml)
[![Coveralls](https://img.shields.io/coveralls/github/nicholaswilde/hbctl/main?style=for-the-badge&logo=coveralls)](https://coveralls.io/github/nicholaswilde/hbctl?branch=main)
[![task](https://img.shields.io/badge/Task-Enabled-brightgreen?style=for-the-badge&logo=task&logoColor=white)](https://taskfile.dev/#/)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg?style=for-the-badge)](https://github.com/nicholaswilde/hbctl/blob/main/LICENSE)

A fast, zero-dependency, agent-friendly Rust CLI client for interacting with remote Homebox v0.26+ instances over the REST API. Centralizes inventory CRUD, upsert, bulk import, deduplication, multi-file attachment management, typed custom fields, tag/entity-type resolution, and filtered exports.

!!! warning
    This project is currently in a `v0.X.X` development stage. Features and configurations are subject to change, and breaking changes may be introduced at any time.

## :rocket: TL;DR

### :floppy_disk: Installation

=== "Homebrew"

    ```bash
    brew install nicholaswilde/homebrew-tap/hbctl
    ```

=== "APT"

    ```bash
    # After adding https://nicholaswilde.io/apt (see Installation page)
    sudo apt update && sudo apt install hbctl
    ```

=== "Scoop"

    ```powershell
    scoop bucket add nicholaswilde https://github.com/nicholaswilde/scoop-bucket
    scoop install nicholaswilde/hbctl
    ```

=== "Cargo"

    ```bash
    cargo install --git https://github.com/nicholaswilde/hbctl
    ```

### :gear: Usage

```bash title="Quickstart commands"
# Authenticate (API key via stdin, stored in OS keyring with 0600 file fallback)
echo "$HOMEBOX_API_KEY" | hbctl auth login --url http://192.168.1.50:7745 --with-token

# Check remote server connectivity and version (no auth required)
hbctl status --url http://192.168.1.50:7745

# Check active session status (redacted Bearer ***)
hbctl auth status

# Create a location entity type
hbctl entity-types create "Storage Bin" --description "Container" --is-location

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

## :star: Contributing

See [Contributing](./CONTRIBUTING.md).

## :sparkles: Code of Conduct

See [Code of Conduct](./CODE_OF_CONDUCT.md).

## :balance_scale: License

[Apache License 2.0][1]

## :pencil: Author

This project was started in 2026 by [Nicholas Wilde].

[Nicholas Wilde]: https://github.com/nicholaswilde/
[1]: https://github.com/nicholaswilde/hbctl/blob/main/LICENSE

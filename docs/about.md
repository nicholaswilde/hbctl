# About

`hbctl` is a fast, single-binary Rust CLI client built for interacting with remote [Homebox][1] v0.26+ instances over the `/api/v1` REST API. It is designed for both interactive terminal workflows and scriptable AI-agent automation, providing deterministic JSON output, safe read-modify-write updates, deduplication, bulk import, attachment management, and filtered exports.

## :sparkles: Features

- **Agent-Friendly Output:** Emit compact JSON (`--json` / `--output json`), project top-level or custom fields (`--select`), print only affected IDs (`-q` / `--quiet`), or preview mutating HTTP calls without touching the server (`--dry-run`). Data writes cleanly to `stdout` while diagnostics stay on `stderr`.
- **Full Item Lifecycle:** Create, read, update, upsert, delete, move, and render parent/location hierarchies (`hbctl item tree`). Custom fields supplied during `item create` are automatically persisted via a follow-up `PUT`.
- **Two-Pass Deduplication:** Detect exact and near-duplicate inventory items (`hbctl item dedup`) using Pass 1 exact case-insensitive name matching and Pass 2 Jaccard token similarity (stripping version numbers and common stop-words). Deterministic keeper selection retains the most descriptive entry and optionally sums quantities (`--merge`).
- **Bulk Import & Idempotent Upsert:** Import JSON or CSV records (`hbctl item import`) or upsert single items (`hbctl item upsert`) with configurable match keys (`name`, `model`, `serial`, `field:KEY`), match modes (`exact`, `contains`, `fuzzy`), conflict actions (`update`, `skip`, `attach-only`), and `--fill-missing` preservation.
- **Attachments & Image Optimization:** Upload local files, stdin streams, or remote HTTP(S) URLs (`--attach`, `--attach-url`) with duplicate skipping by default, stream-download attachments individually or across tagged/filtered items, and automatically resize/compress oversized images in memory (`--optimize` / `auto_optimize`).
- **Structured Search & Typed Custom Fields:** Query items by free-text, tag, model, serial, manufacturer, or custom field (`KEY` / `KEY=VAL`) with AND or OR (`--any`) semantics, and manage typed custom fields (`text`, `number`, `boolean`) via `hbctl field`.
- **Tags, Entity Types & Hierarchy:** Resolve tags and entity types by name or UUID, auto-create missing tags on item creation, and manage location/container entity types (`--is-location`).
- **Multi-Instance Profiles:** Configure named `[profiles.<name>]` entries in `~/.config/hbctl/config.toml` and switch targets seamlessly with `--profile` / `-P` or `HBCTL_PROFILE`, with profile-isolated credential storage.
- **Filtered Exports:** Export matching inventory items to JSON, CSV, or Markdown tables with custom column ordering, header aliases (`key=Header Alias`), column alignment, and empty-cell placeholders.
- **Portable Single Binary:** Prebuilt binaries for Linux (AMD64, ARM64, ARMv7, ARMv6), macOS, and Windows, complete with shell completions, a UNIX man page, and an integrated GitHub release self-updater (`hbctl update`).

## :shield: Security & Reliability Architecture

- **OS Keyring with `0600` Fallback:** Credentials saved via `hbctl auth login` are stored in the system keyring (`Secret Service`/D-Bus on Linux, Keychain on macOS, Credential Manager on Windows) and automatically fall back to a `0600` local file (`~/.config/hbctl/credentials.json` inside a `0700` directory) in headless environments. See [Credential Storage & Headless Fallback](./security.md#credential-storage-headless-fallback).
- **Mandatory Secret Redaction:** `Authorization` headers are always masked as `Bearer ***` in `hbctl auth status`, `--dry-run` request previews, and error diagnostics, with raw secret strings scrubbed from error text. See [Secret Redaction & Dry-Run Safety](./security.md#secret-redaction-dry-run-safety).
- **Safe `GET -> Merge -> PUT` Mutations:** Item updates and custom field changes fetch the current server state, merge changes locally, and submit a complete `PUT` payload so unrelated fields and attachments are never clobbered.
- **Go-`null` Tolerant Deserialization:** REST models handle Homebox v0.26+ nullable arrays (`null` instead of `[]`) and snake/camel-case JSON aliases cleanly without deserialization failures.

[1]: https://github.com/sysadminsmedia/homebox

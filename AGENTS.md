# AGENTS.md

Conventions and architecture for AI agents working on `hbx`.

---

<!-- rtk-begin -->
## RTK Command Guidelines

- **Git Operations**: Prefix `git` commands with `rtk` (e.g., `rtk git status`, `rtk git diff`).
- **GitHub CLI**: Prefix `gh` commands with `rtk` and pipe to `cat` (e.g., `rtk gh issue list | cat`).
- **File & Directory Inspection**: Use `rtk ls`, `rtk tree`, `rtk fd`, or `rtk read`.
- **Searching**: Use `rtk rg` or `rg` (ripgrep).
- **TOML / Markdown**: Use `rtk taplo fmt` / `rtk taplo lint`, `rtk rumdl check .` / `rtk rumdl fmt .`.
- **Ripwire**: Invoke via CLI (`rtk ripwire <dir> --for="<task>"`), never MCP.
- **Build & Test**: Use `rtk err` / `rtk test`.
- **Exceptions**: Skip `rtk` inside `ctx_execute` / `ctx_batch_execute`.
<!-- rtk-end -->

<!-- context-mode-begin -->
## Context-Mode Routing Guidelines

- Use `context-mode` MCP (`ServerName: "context-mode_context-mode"`) for sandbox analysis (`ctx_execute`, `ctx_execute_file`, `ctx_batch_execute`, `ctx_search`).
- Print derived results only; avoid dumping whole files into context.
<!-- context-mode-end -->

<!-- sensitive-information-protection-begin -->
## Sensitive Information & Secret Protection

NEVER commit or stage `.env`, `.hbx.toml`, API keys (`hb_*`), Bearer tokens, or credentials. Always redact `Authorization` as `Bearer ***`.
<!-- sensitive-information-protection-end -->

---

## 1. Project Overview & Architecture

**`hbx`**: Rust CLI client for remote Homebox v0.26+ REST API.

### Modules

- `src/main.rs` — thin binary entrypoint delegating to `hbx::run()`
- `src/lib.rs` — public exports and top-level dispatch
- `src/auth_store.rs` — OS keyring (`keyring`) + `0600` file fallback credential storage
- `src/cli.rs` — `clap` derive CLI parser, global flags, subcommands, completions/man
- `src/config.rs` — layered config (`CLI > env/.env > .hbx.toml > ~/.config/hbx/config.toml & stored auth > defaults`)
- `src/error.rs` — typed `HbxError` (`thiserror`)
- `src/client/` — `mod.rs` (HTTP client, URL/auth normalization, redaction, `GET -> Merge -> PUT`, follow-up `PUT`, streaming downloads), `models.rs` (Homebox v0.26+ serde types with Go-`null` tolerance), `resolve.rs` (tag/entity-type resolution)
- `src/commands/` — `mod.rs`, `auth.rs`, `item.rs`, `attachment.rs`, `search.rs`, `field.rs`, `tag.rs`, `entity_type.rs`, `export.rs`
- `src/dedup.rs` — two-pass exact + Jaccard duplicate detector and keeper selector
- `src/output.rs` — table, compact JSON (`--select`), plain, CSV, Markdown renderers (`stdout` data / `stderr` diagnostics)

---

## 2. Quality Gates (`Taskfile.yml`)

```bash
task check        # fmt:check + clippy (-D warnings) + cargo test
task test         # full validation suite
task fmt          # rustfmt
task lint:md      # rumdl markdown lint
task build:local  # release build
```

# AGENTS.md

Conventions and architecture for AI agents working on `hbctl`.

---

<!-- rtk-begin -->
## RTK Command Guidelines

- **Git Operations**: Prefix `git` commands with `rtk` (e.g., `rtk git status`, `rtk git diff`, `rtk git log`, `rtk git commit`, `rtk git push`).
- **GitHub CLI**: Prefix `gh` commands with `rtk` and pipe to `cat` (e.g., `rtk gh issue list | cat`, `rtk gh pr status | cat`).
- **File & Directory Inspection**: Use `rtk ls`, `rtk tree`, `rtk fd`, or `rtk read`.
- **Searching**: Use `rtk rg` or `rg` (ripgrep).
- **TOML / Markdown**: Use `rtk taplo fmt` / `rtk taplo lint`, `rtk rumdl check .` / `rtk rumdl fmt .`.
- **Ripwire**: Invoke via CLI (`rtk ripwire <dir> --for="<task>"`), never MCP.
- **Node / Python / UV**: Prefix `npx` with `rtk npx`; run Python via `rtk uv run <script|cmd>` (never bare `python`, `python3`, or `uv`).
- **Build & Test**: Use `rtk err` / `rtk test` (e.g., `rtk test cargo test`).
- **Exceptions**: Skip `rtk` inside `ctx_execute` / `ctx_batch_execute`. Drop `rtk` when raw bytes required.
<!-- rtk-end -->

<!-- context-mode-begin -->
## Context-Mode Routing Guidelines

- **Derive, Do Not Dump**: Print only needed value, match, count, or line range; avoid dumping whole files into context.
- **MCP Surface**: Call `context-mode` plugin MCP (`ServerName: "context-mode_context-mode"`) for `ctx_execute`, `ctx_execute_file`, `ctx_batch_execute`, `ctx_fetch_and_index`, `ctx_search`, `ctx_index`. Do NOT duplicate `context-mode` in `~/.gemini/config/mcp_config.json`.
- **Routing**: Use `ctx_execute` / `ctx_execute_file` / `ctx_batch_execute` for analysis, filtering, parsing, multi-command recon, or large shell output; use native `read_file` only for small files or verbatim edits.
<!-- context-mode-end -->

<!-- ponytail-begin -->
## Ponytail (Lazy Senior Dev Mode) Guidelines

- **Stop at first rung that holds**:
  1. Need to exist? (YAGNI)
  2. Already in codebase? Reuse helper/util/pattern.
  3. Stdlib does it? Use it.
  4. Native platform feature covers it? Use it.
  5. Installed dependency solves it? Use it.
  6. One line possible? One line.
  7. Only then: minimum working code.
- **Bug fix = root cause, not symptom**: Fix shared path once.
- **Rules**: Deletion over addition; boring over clever; fewest files; no speculative abstractions; mark deliberate simplifications with `// ponytail: [reason] -> [upgrade path]`; leave one runnable check for non-trivial logic.
<!-- ponytail-end -->

<!-- caveman-begin -->
## Caveman Guidelines

Respond terse like smart caveman. Keep 100% technical substance; drop fluff.

- Drop articles, filler, pleasantries, hedging. Fragments OK. Technical terms, paths, commands, code unchanged.
- Pattern: `[thing] [action] [reason]. [next step].`
- Auto-Clarity: normal prose for security warnings, irreversible actions, ambiguous steps.
- Code, commits, PRs written normal.
<!-- caveman-end -->

<!-- codegraph-begin -->
## CodeGraph

When `.codegraph/` exists at repo root, query CodeGraph BEFORE grep/find/read loops:

- **MCP**: `codegraph_explore` returns source + call path + blast radius in one call.
- **CLI**: `codegraph explore "<symbol or question>"` (`codegraph status`, `codegraph sync`).
- Skip CodeGraph if `.codegraph/` absent.
<!-- codegraph-end -->

<!-- serena-begin -->
## Serena Semantic Navigation & LSP Integration

Use Serena (`serena`) MCP tools for AST navigation, LSP diagnostics, and project memories:

1. **Map first**: `get_symbols_overview` before reading whole files.
2. **Read target symbol**: `find_symbol` with `include_body: true`.
3. **Check callers**: `find_referencing_symbols` / `find_implementations` before signature changes.
4. **Edit by symbol**: `replace_symbol_body`, `insert_after_symbol`, `insert_before_symbol`, `rename_symbol`.
5. **Verify diagnostics**: `get_diagnostics_for_file` after edits.
<!-- serena-end -->

<!-- headroom-begin -->
## Headroom MCP (Context Window Compression)

Use Headroom (`headroom`) MCP tools for large tool outputs:

- `headroom_compress`: Shrink large payloads.
- `headroom_retrieve`: Fetch original content by hash when exact details needed.
- `headroom_stats`: Inspect cache/savings stats.
<!-- headroom-end -->

<!-- ripwire-begin -->
## Ripwire CLI Guidelines

Use `ripwire` CLI (`rtk ripwire`) for AST map, call graph, blast radius, structural queries:

- **CLI Only**: Invoke `rtk ripwire <dir> [flags]`; never register/use MCP.
- **Orient / Bundle**: `rtk ripwire <dir> --for="<task>"` or `--pack-task="<task>" --legend=compact`.
- **Trace**: `rtk ripwire <dir> --from-trace=FILE --legend=compact` (`-` for stdin).
- **Graph / Impact**: `--callers=SYM`, `--callees=SYM`, `--uses=SYM`, `--impact=SYM --legend=compact`.
- **Gates**: `--quality-delta --legend=compact`, `--test-gate --legend=compact`.
- **Atomic Edits**: `--replace-symbol-body=SYM --edit-payload=FILE` without whole-file re-reads.
<!-- ripwire-end -->

<!-- ripgrep-guidelines-begin -->
## Ripgrep Guidelines

- Use `rg` / `rtk rg` instead of `grep -r` for pattern searches across repo.
- Scope with `-t rust`, `-l` for file listing, small context (`-C 1`).
<!-- ripgrep-guidelines-end -->

<!-- taplo-rules-begin -->
## Taplo TOML Rules

- Prefix `taplo` with `rtk` in interactive shells (`rtk taplo fmt`, `rtk taplo lint`, `rtk taplo check`).
- Format TOML files (`Cargo.toml`, `.rumdl.toml`, `assets/config.example.toml`) with `rtk taplo fmt` and validate with `rtk taplo lint`.
<!-- taplo-rules-end -->

<!-- uv-rules-begin -->
## Python & `uv` Guidelines

- **Prefix Execution**: Run Python scripts/commands via `rtk uv run <script|cmd>` (e.g., `rtk uv run scripts/release_summary.py`); never bare `python`, `python3`, `pip`, or bare `uv`.
- **Lockfile Sync**: Keep `uv.lock` and `pyproject.toml` synchronized (`rtk uv lock` / `rtk uv sync`) whenever Python dependencies or project metadata change.
<!-- uv-rules-end -->

<!-- issue-management-begin -->
## GitHub Issue Management

- **Features**: Prefix title `[feat]:`, label `enhancement`.
- **Bugs**: Prefix title `[bug]:`, label `bug`.
- **Commit Closing**: GitHub issues only close automatically when commits containing `Fixes #<number>` are pushed to remote repository.
<!-- issue-management-end -->

<!-- sensitive-information-protection-begin -->
## Sensitive Information & Secret Protection

NEVER commit or stage `.env`, `.hbctl.toml`, API keys (`hb_*`), Bearer tokens, or credentials:

1. **Redaction & Storage**: Always redact `Authorization` as `Bearer ***`. Store secrets in OS `keyring` or SOPS (`task encrypt` / `task decrypt`), never plaintext in repo.
2. **Explicit Staging**: Never use blanket staging (`git add .` / `git add -A`) when untracked secret/config files exist; stage files explicitly by name.
<!-- sensitive-information-protection-end -->

---

## 1. Project Overview & Architecture

**`hbctl`**: Rust CLI client for remote Homebox v0.26+ REST API.

### Modules

- `src/main.rs` — thin binary entrypoint delegating to `hbctl::run()`
- `src/lib.rs` — public exports and top-level dispatch
- `src/auth_store.rs` — OS keyring (`keyring`) + `0600` file fallback credential storage
- `src/cli.rs` — `clap` derive CLI parser, global flags, subcommands, completions/man
- `src/config.rs` — layered config (`CLI > env/.env > .hbctl.toml > ~/.config/hbctl/config.toml & stored auth > defaults`)
- `src/error.rs` — typed `HbctlError` (`thiserror`)
- `src/client/` — `mod.rs` (HTTP client, URL/auth normalization, redaction, `GET -> Merge -> PUT`, follow-up `PUT`, streaming downloads), `models.rs` (Homebox v0.26+ serde types with Go-`null` tolerance), `resolve.rs` (tag/entity-type resolution)
- `src/commands/` — `mod.rs`, `auth.rs`, `item.rs`, `attachment.rs`, `search.rs`, `field.rs`, `tag.rs`, `entity_type.rs`, `export.rs`
- `src/dedup.rs` — two-pass exact + Jaccard duplicate detector and keeper selector
- `src/output.rs` — table, compact JSON (`--select`), plain, CSV, Markdown renderers (`stdout` data / `stderr` diagnostics)
- `src/update.rs` — GitHub release self-updater (`hbctl update` / `hbctl self-update`)

---

## 2. Quality Gates (`Taskfile.yml`)

```bash
task check        # fmt:check + clippy (-D warnings) + cargo test
task test         # full validation suite
task fmt          # rustfmt
task lint:md      # rumdl markdown lint
task build:local  # release build
```

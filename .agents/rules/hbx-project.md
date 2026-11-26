# HBX Project Rules

- **Pure-Rust HTTP**: Keep `reqwest` on `default-features = false` with `blocking`, `json`, `multipart`, `rustls-tls` for clean `cross` multi-arch builds without OpenSSL/tokio.
- **Stream Separation**: Write data strictly to `stdout`; diagnostics, warnings, and errors strictly to `stderr`.
- **Secret Redaction**: Always mask API keys and `Authorization` headers as `Bearer ***` in `--dry-run`, logs, and errors.
- **Homebox v0.26+ Quirks**: Preserve Go `null`-tolerant deserializers, follow-up `PUT` after `POST /api/v1/entities` when `fields` non-empty, `GET -> Merge -> PUT` updates, and detail hydration when list responses omit `fields`.
- **Quality Gates**: `task check` (`cargo fmt --all -- --check`, `cargo clippy --workspace --all-targets --all-features -- -D warnings`, `cargo test`) must pass with zero warnings.

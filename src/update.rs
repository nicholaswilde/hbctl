use std::io::{IsTerminal, Write};

use self_update::update::ReleaseAsset;
use self_update::{ReleaseStatus, UpdateStrategy};
use serde::Serialize;

use crate::config::OutputFormat;
use crate::output::{write_compact_json, OutputContext};

pub const REPO_OWNER: &str = "nicholaswilde";
pub const REPO_NAME: &str = "hbx";
pub const BIN_NAME: &str = "hbx";
pub const CURRENT_VERSION: &str = env!("CARGO_PKG_VERSION");

/// Options for the `hbx update` (`self-update`) command.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct SelfUpdateOptions {
    pub check: bool,
    pub yes: bool,
    pub version: Option<String>,
}

#[derive(Debug, Serialize)]
struct UpdateCheckOutput {
    current_version: String,
    latest_version: String,
    update_available: bool,
    target: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    asset: Option<String>,
}

/// Map the host target triple to the corresponding release target built by CI.
pub fn resolve_target(raw_target: &str) -> &str {
    match raw_target {
        "x86_64-unknown-linux-gnu" | "x86_64-unknown-linux-musl" => "x86_64-unknown-linux-musl",
        "aarch64-unknown-linux-gnu" | "aarch64-unknown-linux-musl" => "aarch64-unknown-linux-musl",
        "armv7-unknown-linux-gnueabihf" | "armv7-unknown-linux-musleabihf" => {
            "armv7-unknown-linux-musleabihf"
        }
        "arm-unknown-linux-gnueabihf"
        | "arm-unknown-linux-gnueabi"
        | "arm-unknown-linux-musleabihf"
        | "arm-unknown-linux-musleabi" => "arm-unknown-linux-musleabi",
        "x86_64-apple-darwin" => "x86_64-apple-darwin",
        "aarch64-apple-darwin" => "aarch64-apple-darwin",
        "x86_64-pc-windows-msvc" | "x86_64-pc-windows-gnu" => "x86_64-pc-windows-msvc",
        "i686-pc-windows-msvc" | "i686-pc-windows-gnu" => "i686-pc-windows-msvc",
        other => other,
    }
}

/// Return the release archive extension for the given target triple.
pub fn archive_extension_for_target(target: &str) -> &'static str {
    if target.contains("windows") {
        ".zip"
    } else {
        ".tar.gz"
    }
}

/// Select the matching release archive asset, ignoring checksum (`.sha256`) and `.deb` files.
pub fn select_release_asset(assets: &[ReleaseAsset], target: &str) -> Option<ReleaseAsset> {
    let ext = archive_extension_for_target(target);
    assets
        .iter()
        .find(|asset| asset.name().contains(target) && asset.name().ends_with(ext))
        .cloned()
}

/// Normalize a user-supplied version or tag string to a `v`-prefixed GitHub tag.
pub fn normalize_version_tag(version: &str) -> String {
    let trimmed = version.trim();
    if let Some(rest) = trimmed
        .strip_prefix('v')
        .or_else(|| trimmed.strip_prefix('V'))
    {
        format!("v{rest}")
    } else {
        format!("v{trimmed}")
    }
}

fn strip_v_prefix(version: &str) -> &str {
    let trimmed = version.trim();
    trimmed
        .strip_prefix('v')
        .or_else(|| trimmed.strip_prefix('V'))
        .unwrap_or(trimmed)
}

/// Return `true` if `candidate` is strictly newer than `current` according to SemVer.
pub fn is_newer_version(current: &str, candidate: &str) -> anyhow::Result<bool> {
    let newer =
        self_update::version::bump_is_greater(strip_v_prefix(current), strip_v_prefix(candidate))?;
    Ok(newer)
}

fn build_updater(
    opts: &SelfUpdateOptions,
    target: &str,
    silent: bool,
) -> anyhow::Result<self_update::backends::github::Update> {
    let matcher_target = target.to_string();
    let mut builder = self_update::backends::github::Update::configure();
    builder
        .repo_owner(REPO_OWNER)
        .repo_name(REPO_NAME)
        .bin_name(BIN_NAME)
        .current_version(CURRENT_VERSION)
        .target(target)
        .bin_path_in_archive("hbx-{{ version }}-{{ target }}/{{ bin }}")
        .asset_matcher(move |assets| select_release_asset(assets, &matcher_target))
        .update_strategy(UpdateStrategy::Latest)
        .show_download_progress(!opts.check && !silent)
        .show_output(!opts.check && !silent)
        .no_confirm(opts.yes)
        .check_install_path_writable(!opts.check)
        .auth_token_from_env();

    if let Some(ref ver) = opts.version {
        builder.release_tag(normalize_version_tag(ver));
    }

    Ok(builder.build()?)
}

/// Check for or install an `hbx` release from GitHub.
pub fn run_self_update(
    opts: SelfUpdateOptions,
    ctx: &OutputContext,
    out_writer: &mut dyn Write,
) -> anyhow::Result<()> {
    let target = resolve_target(self_update::get_target()).to_string();
    let silent = ctx.quiet || ctx.format == OutputFormat::Json;

    if !opts.check && !opts.yes && !std::io::stdin().is_terminal() {
        anyhow::bail!(
            "Cannot confirm update in non-interactive mode; pass --yes (-y) to skip confirmation."
        );
    }

    let updater = build_updater(&opts, &target, silent)?;

    if opts.check {
        let release = if let Some(ref ver) = opts.version {
            updater.get_release_version(&normalize_version_tag(ver))?
        } else {
            updater
                .get_latest_release()?
                .into_vec()
                .into_iter()
                .next()
                .ok_or_else(|| anyhow::anyhow!("No releases found for {REPO_OWNER}/{REPO_NAME}"))?
        };

        let latest_ver = release.version();
        let update_available = is_newer_version(CURRENT_VERSION, latest_ver)?;
        let asset_name =
            select_release_asset(release.assets(), &target).map(|a| a.name().to_string());

        if ctx.quiet {
            writeln!(out_writer, "{}", normalize_version_tag(latest_ver))?;
            return Ok(());
        }
        if ctx.format == OutputFormat::Json {
            let payload = UpdateCheckOutput {
                current_version: normalize_version_tag(CURRENT_VERSION),
                latest_version: normalize_version_tag(latest_ver),
                update_available,
                target,
                asset: asset_name,
            };
            write_compact_json(&payload, ctx.select.as_deref(), out_writer)?;
            return Ok(());
        }

        if update_available {
            writeln!(
                out_writer,
                "Update available: v{CURRENT_VERSION} -> v{latest_ver}"
            )?;
        } else if strip_v_prefix(latest_ver) == strip_v_prefix(CURRENT_VERSION) {
            writeln!(out_writer, "hbx is up to date (v{CURRENT_VERSION}).")?;
        } else {
            writeln!(
                out_writer,
                "Release v{latest_ver} found (current: v{CURRENT_VERSION})."
            )?;
        }

        match asset_name {
            Some(name) => writeln!(out_writer, "Asset: {name}")?,
            None => writeln!(
                out_writer,
                "Warning: no release asset found for target '{target}'."
            )?,
        }
        return Ok(());
    }

    match updater.update_extended() {
        Ok(ReleaseStatus::UpToDate) => {
            if ctx.quiet {
                writeln!(out_writer, "v{CURRENT_VERSION}")?;
            } else if ctx.format == OutputFormat::Json {
                let payload = serde_json::json!({
                    "status": "up_to_date",
                    "current_version": format!("v{CURRENT_VERSION}"),
                });
                write_compact_json(&payload, ctx.select.as_deref(), out_writer)?;
            } else {
                writeln!(
                    out_writer,
                    "hbx is already up to date (v{CURRENT_VERSION})."
                )?;
            }
        }
        Ok(ReleaseStatus::Updated(release)) => {
            let ver = release.version();
            if ctx.quiet {
                writeln!(out_writer, "{}", normalize_version_tag(ver))?;
            } else if ctx.format == OutputFormat::Json {
                let payload = serde_json::json!({
                    "status": "updated",
                    "from": format!("v{CURRENT_VERSION}"),
                    "to": normalize_version_tag(ver),
                });
                write_compact_json(&payload, ctx.select.as_deref(), out_writer)?;
            } else {
                writeln!(
                    out_writer,
                    "Successfully updated hbx from v{CURRENT_VERSION} to v{ver}."
                )?;
            }
        }
        Ok(other) => {
            let ver = other
                .into_version_status(CURRENT_VERSION.to_string())
                .version()
                .to_string();
            if ctx.quiet {
                writeln!(out_writer, "{}", normalize_version_tag(&ver))?;
            } else if ctx.format == OutputFormat::Json {
                let payload = serde_json::json!({
                    "status": "complete",
                    "version": normalize_version_tag(&ver),
                });
                write_compact_json(&payload, ctx.select.as_deref(), out_writer)?;
            } else {
                writeln!(out_writer, "Update status: v{ver}.")?;
            }
        }
        Err(self_update::errors::Error::Aborted) => {
            writeln!(out_writer, "Update cancelled.")?;
        }
        Err(err) => {
            return Err(anyhow::Error::from(err).context("Failed to self-update hbx"));
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn mock_asset(name: &str) -> ReleaseAsset {
        ReleaseAsset::new(name, format!("https://example.com/{name}"))
    }

    #[test]
    fn test_resolve_target_mappings() {
        assert_eq!(
            resolve_target("x86_64-unknown-linux-gnu"),
            "x86_64-unknown-linux-musl"
        );
        assert_eq!(
            resolve_target("x86_64-unknown-linux-musl"),
            "x86_64-unknown-linux-musl"
        );
        assert_eq!(
            resolve_target("aarch64-unknown-linux-gnu"),
            "aarch64-unknown-linux-musl"
        );
        assert_eq!(
            resolve_target("aarch64-unknown-linux-musl"),
            "aarch64-unknown-linux-musl"
        );
        assert_eq!(
            resolve_target("armv7-unknown-linux-gnueabihf"),
            "armv7-unknown-linux-musleabihf"
        );
        assert_eq!(
            resolve_target("armv7-unknown-linux-musleabihf"),
            "armv7-unknown-linux-musleabihf"
        );
        assert_eq!(
            resolve_target("arm-unknown-linux-gnueabihf"),
            "arm-unknown-linux-musleabi"
        );
        assert_eq!(
            resolve_target("arm-unknown-linux-musleabi"),
            "arm-unknown-linux-musleabi"
        );
        assert_eq!(resolve_target("x86_64-apple-darwin"), "x86_64-apple-darwin");
        assert_eq!(
            resolve_target("aarch64-apple-darwin"),
            "aarch64-apple-darwin"
        );
        assert_eq!(
            resolve_target("x86_64-pc-windows-msvc"),
            "x86_64-pc-windows-msvc"
        );
        assert_eq!(
            resolve_target("x86_64-pc-windows-gnu"),
            "x86_64-pc-windows-msvc"
        );
        assert_eq!(
            resolve_target("i686-pc-windows-msvc"),
            "i686-pc-windows-msvc"
        );
        assert_eq!(
            resolve_target("riscv64gc-unknown-linux-gnu"),
            "riscv64gc-unknown-linux-gnu"
        );
    }

    #[test]
    fn test_archive_extension_for_target() {
        assert_eq!(
            archive_extension_for_target("x86_64-unknown-linux-musl"),
            ".tar.gz"
        );
        assert_eq!(
            archive_extension_for_target("aarch64-apple-darwin"),
            ".tar.gz"
        );
        assert_eq!(
            archive_extension_for_target("x86_64-pc-windows-msvc"),
            ".zip"
        );
        assert_eq!(archive_extension_for_target("i686-pc-windows-msvc"), ".zip");
    }

    #[test]
    fn test_select_release_asset_skips_sha256_and_deb() {
        let assets = vec![
            mock_asset("hbx-0.1.0-x86_64-unknown-linux-musl.tar.gz.sha256"),
            mock_asset("hbx-0.1.0-x86_64-unknown-linux-musl.tar.gz"),
            mock_asset("hbx-0.1.0-aarch64-unknown-linux-musl.tar.gz"),
            mock_asset("hbx-0.1.0-x86_64-pc-windows-msvc.zip.sha256"),
            mock_asset("hbx-0.1.0-x86_64-pc-windows-msvc.zip"),
            mock_asset("hbx_0.1.0-1_amd64.deb"),
        ];

        let linux = select_release_asset(&assets, "x86_64-unknown-linux-musl").unwrap();
        assert_eq!(linux.name(), "hbx-0.1.0-x86_64-unknown-linux-musl.tar.gz");

        let win = select_release_asset(&assets, "x86_64-pc-windows-msvc").unwrap();
        assert_eq!(win.name(), "hbx-0.1.0-x86_64-pc-windows-msvc.zip");

        assert!(select_release_asset(&assets, "aarch64-apple-darwin").is_none());
    }

    #[test]
    fn test_normalize_version_tag() {
        assert_eq!(normalize_version_tag("0.1.0"), "v0.1.0");
        assert_eq!(normalize_version_tag("v0.1.0"), "v0.1.0");
        assert_eq!(normalize_version_tag("V0.2.0"), "v0.2.0");
        assert_eq!(normalize_version_tag("  0.2.0  "), "v0.2.0");
    }

    #[test]
    fn test_is_newer_version() {
        assert!(is_newer_version("0.1.0", "0.1.1").unwrap());
        assert!(is_newer_version("0.1.0", "0.2.0").unwrap());
        assert!(is_newer_version("0.1.0", "1.0.0").unwrap());
        assert!(is_newer_version("v0.1.0", "v0.1.1").unwrap());
        assert!(!is_newer_version("0.1.0", "0.1.0").unwrap());
        assert!(!is_newer_version("0.1.1", "0.1.0").unwrap());
        assert!(!is_newer_version("0.2.0", "0.2.0-rc.1").unwrap());
        assert!(is_newer_version("0.2.0-rc.1", "0.2.0").unwrap());
    }

    #[test]
    fn test_build_updater_succeeds() {
        let opts = SelfUpdateOptions {
            check: true,
            yes: false,
            version: Some("0.1.0".to_string()),
        };
        let target = resolve_target(self_update::get_target());
        assert!(build_updater(&opts, target, true).is_ok());
    }

    #[test]
    fn test_cli_update_and_self_update_parsing() {
        use crate::cli::{Cli, Commands, Parser};

        let cli = Cli::try_parse_from(["hbx", "update"]).unwrap();
        assert!(matches!(
            cli.command,
            Commands::Update {
                check: false,
                yes: false,
                version: None
            }
        ));

        let cli_flags =
            Cli::try_parse_from(["hbx", "update", "--check", "-y", "--version", "0.2.0"]).unwrap();
        assert!(matches!(
            cli_flags.command,
            Commands::Update {
                check: true,
                yes: true,
                version: Some(ref v)
            } if v == "0.2.0"
        ));

        let cli_alias = Cli::try_parse_from(["hbx", "self-update", "--yes"]).unwrap();
        assert!(matches!(
            cli_alias.command,
            Commands::Update {
                check: false,
                yes: true,
                version: None
            }
        ));
    }
}

pub mod cli;
pub mod client;
pub mod commands;
pub mod config;
pub mod dedup;
pub mod error;
pub mod output;

use std::io::{self, Write};

use clap::Parser;

use crate::cli::{Cli, Commands};
use crate::config::AppConfig;
use crate::output::OutputContext;

/// Main library entrypoint invoked by `src/main.rs`.
pub fn run() -> anyhow::Result<()> {
    let cli = Cli::parse();
    let mut stdout = io::stdout();
    let mut stderr = io::stderr();
    run_with_io(cli, &mut stdout, &mut stderr)
}

/// Testable entrypoint with injectable `stdout` and `stderr` writers.
pub fn run_with_io(cli: Cli, out: &mut dyn Write, err: &mut dyn Write) -> anyhow::Result<()> {
    match &cli.command {
        Commands::Completions { shell } => {
            cli::generate_completions(*shell, out);
            return Ok(());
        }
        Commands::Man => {
            cli::generate_manpage(out)?;
            return Ok(());
        }
        _ => {}
    }

    let config = AppConfig::load(&cli.config_overrides())?;
    let output_ctx = OutputContext::new(config.output, cli.select.clone(), cli.quiet);

    commands::dispatch(&cli, &config, &output_ctx, out, err)?;
    Ok(())
}

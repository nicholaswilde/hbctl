use std::io::Write;

use crate::cli::BarcodeArgs;
use crate::client::HomeboxClient;
use crate::config::{AppConfig, OutputFormat};
use crate::error::{HbctlError, Result};
use crate::output::{
    write_compact_json, write_dry_run, write_quiet_ids, write_selected_table, write_table_or_plain,
    OutputContext,
};

pub fn handle(
    args: &BarcodeArgs,
    dry_run: bool,
    config: &AppConfig,
    ctx: &OutputContext,
    out: &mut dyn Write,
) -> Result<()> {
    let code = args.code.trim();
    if code.is_empty() {
        return Err(HbctlError::InvalidInput(
            "barcode cannot be empty".to_string(),
        ));
    }

    if dry_run {
        let base_url = config.require_base_url()?;
        let preview = HomeboxClient::build_api_dry_run(
            base_url,
            "GET",
            "products/search-from-barcode",
            &[("productEAN".to_string(), code.to_string())],
            None,
        )?;
        return write_dry_run(&[preview], ctx, out);
    }

    let client = HomeboxClient::from_config(config)?;
    let products = client.search_barcode(code)?;
    if products.is_empty() {
        return Err(HbctlError::NotFound {
            kind: "barcode product".to_string(),
            query: code.to_string(),
        });
    }

    if ctx.quiet {
        let names: Vec<String> = products
            .iter()
            .map(|p| {
                p.effective_name()
                    .map(ToOwned::to_owned)
                    .unwrap_or_else(|| p.barcode.clone())
            })
            .collect();
        return write_quiet_ids(&names, out);
    }

    if ctx.format == OutputFormat::Json {
        return write_compact_json(&products, ctx.select.as_deref(), out);
    }

    if let Some(ref select) = ctx.select {
        return write_selected_table(&products, select, ctx.format, out);
    }

    let headers = vec![
        "BARCODE".to_string(),
        "NAME".to_string(),
        "MANUFACTURER".to_string(),
        "MODEL".to_string(),
        "SOURCE".to_string(),
        "DESCRIPTION".to_string(),
    ];
    let rows: Vec<Vec<String>> = products
        .iter()
        .map(|p| {
            let barcode = if p.barcode.trim().is_empty() {
                code.to_string()
            } else {
                p.barcode.clone()
            };
            vec![
                barcode,
                p.effective_name().unwrap_or("").to_string(),
                p.effective_manufacturer().unwrap_or("").to_string(),
                p.effective_model_number().unwrap_or("").to_string(),
                p.search_engine_name.clone(),
                p.effective_description().unwrap_or("").to_string(),
            ]
        })
        .collect();

    write_table_or_plain(&headers, &rows, ctx.format, out)
}

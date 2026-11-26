use std::io::Write;
use std::path::PathBuf;

pub use clap::{Args, CommandFactory, Parser, Subcommand, ValueEnum};
pub use clap_complete::Shell;

use crate::client::models::FieldValueType;
use crate::config::{CliConfigOverrides, OutputFormat};

#[derive(Parser, Debug, Clone)]
#[command(name = "hbx")]
#[command(
    author,
    version = env!("PROJECT_VERSION"),
    about = "Fast, agent-friendly Rust CLI for remote Homebox v0.26+ instances",
    long_about = None
)]
pub struct Cli {
    /// Homebox base URL (env: HBX_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)
    #[arg(long, global = true)]
    pub url: Option<String>,

    /// Homebox API key or Bearer token (env: HBX_API_KEY > HOMEBOX_API_KEY)
    #[arg(long, global = true)]
    pub api_key: Option<String>,

    /// Output format (table, json, plain) [env: HBX_OUTPUT]
    #[arg(long, global = true, value_enum)]
    pub output: Option<OutputFormat>,

    /// Shorthand for --output json (emits compact JSON)
    #[arg(long, global = true)]
    pub json: bool,

    /// Comma-separated field projection for JSON/table output (e.g. id,name,fields)
    #[arg(long, global = true, value_delimiter = ',')]
    pub select: Option<Vec<String>>,

    /// Preview mutating requests without hitting the server (redacts Authorization)
    #[arg(long, global = true)]
    pub dry_run: bool,

    /// Output only created/affected IDs for shell piping
    #[arg(short = 'q', long, global = true)]
    pub quiet: bool,

    /// Path to explicit TOML configuration file
    #[arg(short = 'C', long, global = true)]
    pub config: Option<PathBuf>,

    #[command(subcommand)]
    pub command: Commands,
}

impl Cli {
    pub fn config_overrides(&self) -> CliConfigOverrides {
        CliConfigOverrides {
            url: self.url.clone(),
            api_key: self.api_key.clone(),
            output: self.output,
            json: self.json,
            config_path: self.config.clone(),
        }
    }
}

#[derive(Subcommand, Debug, Clone)]
pub enum Commands {
    /// Authenticate with a remote Homebox instance (login, status, logout, refresh)
    Auth(AuthArgs),

    /// Manage inventory items (/api/v1/entities)
    Item(ItemArgs),

    /// Manage item attachments (/api/v1/entities/{id}/attachments)
    Attachment(AttachmentArgs),

    /// Full-text and structured item search
    Search(SearchArgs),

    /// Get or set typed custom fields on an item
    Field(FieldArgs),

    /// Manage tags (/api/v1/tags)
    Tag(TagArgs),

    /// List Homebox entity types (/api/v1/entity-types)
    #[command(name = "entity-types", visible_alias = "entity-type")]
    EntityTypes(EntityTypeArgs),

    /// Export filtered items to JSON, CSV, or Markdown
    Export(ExportArgs),

    /// Generate shell completion scripts
    Completions {
        /// Shell to generate completions for
        #[arg(value_enum)]
        shell: Shell,
    },

    /// Generate UNIX roff man page
    Man,

    /// Check for and install the latest hbx release from GitHub
    #[command(visible_alias = "self-update")]
    Update {
        /// Check for available updates without installing
        #[arg(long)]
        check: bool,
        /// Skip confirmation prompt before installing
        #[arg(short = 'y', long)]
        yes: bool,
        /// Target a specific release version or tag (e.g. 0.1.0 or v0.1.0)
        #[arg(long, value_name = "VERSION")]
        version: Option<String>,
    },
}

// -----------------------------------------------------------------------------
// Auth
// -----------------------------------------------------------------------------

#[derive(Args, Debug, Clone)]
pub struct AuthArgs {
    #[command(subcommand)]
    pub command: AuthCommands,
}

#[derive(Subcommand, Debug, Clone)]
pub enum AuthCommands {
    /// Authenticate with Homebox via API key (--with-token) or email/password
    Login(AuthLoginArgs),
    /// Check authentication status and validate the active session
    Status,
    /// Remove stored credentials from OS keyring and local fallback store
    Logout(AuthLogoutArgs),
    /// Refresh an active JWT session token
    Refresh(AuthRefreshArgs),
}

#[derive(Args, Debug, Clone)]
pub struct AuthLoginArgs {
    /// Read a Homebox API key (hb_...) or Bearer token from stdin
    #[arg(long, conflicts_with_all = ["username", "password_stdin"])]
    pub with_token: bool,

    /// Email or username for password login (POST /api/v1/users/login)
    #[arg(short = 'u', long)]
    pub username: Option<String>,

    /// Read login password from stdin instead of prompting interactively
    #[arg(long)]
    pub password_stdin: bool,

    /// Store token in 0600 local file store instead of OS keyring
    #[arg(long)]
    pub insecure_storage: bool,
}

#[derive(Args, Debug, Clone)]
pub struct AuthLogoutArgs {
    /// Skip OS keyring and only clear local 0600 fallback store
    #[arg(long)]
    pub insecure_storage: bool,
}

#[derive(Args, Debug, Clone)]
pub struct AuthRefreshArgs {
    /// Store refreshed token in 0600 local file store instead of OS keyring
    #[arg(long)]
    pub insecure_storage: bool,
}

// -----------------------------------------------------------------------------
// Item
// -----------------------------------------------------------------------------

#[derive(Args, Debug, Clone)]
pub struct ItemArgs {
    #[command(subcommand)]
    pub command: ItemCommands,
}

#[derive(Subcommand, Debug, Clone)]
pub enum ItemCommands {
    /// List inventory items
    List(ItemListArgs),
    /// Fetch a single item by ID
    Get(ItemGetArgs),
    /// Create a new item (auto-persists custom fields via follow-up PUT)
    Create(ItemCreateArgs),
    /// Update an existing item via GET -> Merge -> PUT
    Update(ItemUpdateArgs),
    /// Create or update an item matched by name
    Upsert(ItemUpsertArgs),
    /// Delete an item by ID
    Delete(ItemDeleteArgs),
    /// Bulk import items from JSON or CSV (file or '-' for stdin)
    Import(ItemImportArgs),
    /// Detect (and optionally delete or merge) duplicate items
    Dedup(ItemDedupArgs),
}

#[derive(Args, Debug, Clone)]
pub struct ItemListArgs {
    /// Filter by tag name or UUID
    #[arg(long)]
    pub tag: Option<String>,

    /// Filter by entity type name or UUID
    #[arg(long = "type")]
    pub entity_type: Option<String>,

    /// Only include items having the named custom field (hydrates details if missing)
    #[arg(long)]
    pub has_field: Option<String>,

    /// Page size for listing
    #[arg(long)]
    pub page_size: Option<u32>,

    /// Fetch all pages
    #[arg(long)]
    pub all: bool,
}

#[derive(Args, Debug, Clone)]
pub struct ItemGetArgs {
    /// Entity ID
    pub id: String,
}

#[derive(Args, Debug, Clone)]
pub struct ItemCreateArgs {
    /// Item name (required unless supplied via --from-json)
    #[arg(long)]
    pub name: Option<String>,

    /// Item description
    #[arg(long)]
    pub description: Option<String>,

    /// Entity type name or UUID
    #[arg(long = "type")]
    pub entity_type: Option<String>,

    /// Tag name or UUID (repeatable; missing tags auto-created)
    #[arg(long = "tag")]
    pub tags: Vec<String>,

    /// Manufacturer (normalized into custom field 'Manufacturer')
    #[arg(long)]
    pub manufacturer: Option<String>,

    /// Model number (normalized into custom field 'Model Number')
    #[arg(long)]
    pub model: Option<String>,

    /// Notes (normalized into custom field 'Notes')
    #[arg(long)]
    pub notes: Option<String>,

    /// Item quantity
    #[arg(long)]
    pub quantity: Option<i64>,

    /// Purchase price
    #[arg(long)]
    pub purchase_price: Option<f64>,

    /// Purchase date (YYYY-MM-DD)
    #[arg(long)]
    pub purchase_date: Option<String>,

    /// Purchase vendor/source
    #[arg(long)]
    pub purchase_from: Option<String>,

    /// Custom field KEY=VAL (repeatable)
    #[arg(long = "field")]
    pub fields: Vec<String>,

    /// Value type for --field entries
    #[arg(long, value_enum, default_value_t = FieldValueType::Text)]
    pub field_type: FieldValueType,

    /// Load initial item JSON from file path or '-' for stdin
    #[arg(long)]
    pub from_json: Option<String>,
}

#[derive(Args, Debug, Clone)]
pub struct ItemUpdateArgs {
    /// Entity ID to update
    pub id: String,

    /// Updated item name
    #[arg(long)]
    pub name: Option<String>,

    /// Updated item description
    #[arg(long)]
    pub description: Option<String>,

    /// Entity type name or UUID
    #[arg(long = "type")]
    pub entity_type: Option<String>,

    /// Tag name or UUID to merge (repeatable)
    #[arg(long = "tag")]
    pub tags: Vec<String>,

    /// Manufacturer (merged into custom field 'Manufacturer')
    #[arg(long)]
    pub manufacturer: Option<String>,

    /// Model number (merged into custom field 'Model Number')
    #[arg(long)]
    pub model: Option<String>,

    /// Updated quantity
    #[arg(long)]
    pub quantity: Option<i64>,

    /// Updated purchase price
    #[arg(long)]
    pub purchase_price: Option<f64>,

    /// Updated purchase date (YYYY-MM-DD)
    #[arg(long)]
    pub purchase_date: Option<String>,

    /// Updated purchase source
    #[arg(long)]
    pub purchase_from: Option<String>,

    /// Notes (merged into custom field 'Notes')
    #[arg(long)]
    pub notes: Option<String>,

    /// Custom field KEY=VAL to upsert (repeatable)
    #[arg(long = "field")]
    pub fields: Vec<String>,

    /// Value type for --field entries
    #[arg(long, value_enum, default_value_t = FieldValueType::Text)]
    pub field_type: FieldValueType,

    /// Load patch JSON from file path or '-' for stdin
    #[arg(long)]
    pub from_json: Option<String>,
}

#[derive(Args, Debug, Clone)]
pub struct ItemUpsertArgs {
    /// Item name to match or create
    #[arg(long)]
    pub name: String,

    /// Item description
    #[arg(long)]
    pub description: Option<String>,

    /// Entity type name or UUID
    #[arg(long = "type")]
    pub entity_type: Option<String>,

    /// Tag name or UUID (repeatable; missing tags auto-created)
    #[arg(long = "tag")]
    pub tags: Vec<String>,

    /// Manufacturer
    #[arg(long)]
    pub manufacturer: Option<String>,

    /// Model number
    #[arg(long)]
    pub model: Option<String>,

    /// Notes
    #[arg(long)]
    pub notes: Option<String>,

    /// Quantity
    #[arg(long)]
    pub quantity: Option<i64>,

    /// Purchase price
    #[arg(long)]
    pub purchase_price: Option<f64>,

    /// Purchase date (YYYY-MM-DD)
    #[arg(long)]
    pub purchase_date: Option<String>,

    /// Purchase source
    #[arg(long)]
    pub purchase_from: Option<String>,

    /// Custom field KEY=VAL (repeatable)
    #[arg(long = "field")]
    pub fields: Vec<String>,

    /// Value type for --field entries
    #[arg(long, value_enum, default_value_t = FieldValueType::Text)]
    pub field_type: FieldValueType,
}

#[derive(Args, Debug, Clone)]
pub struct ItemDeleteArgs {
    /// Entity ID to delete
    pub id: String,

    /// Skip interactive confirmation prompt
    #[arg(long)]
    pub force: bool,
}

#[derive(ValueEnum, Clone, Copy, Debug, PartialEq, Eq)]
pub enum ImportFormat {
    Json,
    Csv,
}

#[derive(Args, Debug, Clone)]
pub struct ItemImportArgs {
    /// Input file path or '-' for stdin
    pub file: String,

    /// Input format (inferred from extension if omitted; defaults to json for stdin)
    #[arg(long, value_enum)]
    pub format: Option<ImportFormat>,

    /// Skip items whose name already exists in Homebox
    #[arg(long, conflicts_with = "update_existing")]
    pub skip_existing: bool,

    /// Update items whose name already exists in Homebox
    #[arg(long, conflicts_with = "skip_existing")]
    pub update_existing: bool,
}

#[derive(Args, Debug, Clone)]
pub struct ItemDedupArgs {
    /// Jaccard similarity threshold for near-duplicate detection (0.0..=1.0)
    #[arg(long, default_value_t = 0.8)]
    pub threshold: f64,

    /// Delete detected duplicate items, retaining only the keeper
    #[arg(long)]
    pub delete: bool,

    /// Sum duplicate quantities onto the keeper before deleting duplicates (implies --delete)
    #[arg(long)]
    pub merge: bool,
}

// -----------------------------------------------------------------------------
// Attachment
// -----------------------------------------------------------------------------

#[derive(Args, Debug, Clone)]
pub struct AttachmentArgs {
    #[command(subcommand)]
    pub command: AttachmentCommands,
}

#[derive(Subcommand, Debug, Clone)]
pub enum AttachmentCommands {
    /// Upload one or more files as item attachments
    Upload(AttachmentUploadArgs),
    /// List attachments on an item
    List(AttachmentListArgs),
    /// Stream-download one or all attachments from an item
    Download(AttachmentDownloadArgs),
    /// Delete an attachment from an item
    Delete(AttachmentDeleteArgs),
}

#[derive(Args, Debug, Clone)]
pub struct AttachmentUploadArgs {
    /// Target entity ID
    pub item_id: String,

    /// Local file path(s) to upload
    #[arg(required = true)]
    pub files: Vec<PathBuf>,

    /// Skip files that already exist on the item (default behavior)
    #[arg(long, conflicts_with = "overwrite")]
    pub skip_existing: bool,

    /// Delete and re-upload files that already exist on the item
    #[arg(long, conflicts_with = "skip_existing")]
    pub overwrite: bool,

    /// Allow uploading images larger than 500KB
    #[arg(long)]
    pub force: bool,
}

#[derive(Args, Debug, Clone)]
pub struct AttachmentListArgs {
    /// Target entity ID
    pub item_id: String,
}

#[derive(Args, Debug, Clone)]
pub struct AttachmentDownloadArgs {
    /// Target entity ID
    pub item_id: String,

    /// Specific attachment ID to download (omit when using --all)
    pub attachment_id: Option<String>,

    /// Download all matching attachments on the item
    #[arg(long)]
    pub all: bool,

    /// Filter attachments by MIME type (e.g. application/pdf)
    #[arg(long)]
    pub mime: Option<String>,

    /// Filter attachments by file extension (e.g. pdf)
    #[arg(long)]
    pub ext: Option<String>,

    /// Output file path (single download) or directory (multi-download / --all)
    #[arg(long)]
    pub out: Option<PathBuf>,

    /// Overwrite existing local files instead of skipping
    #[arg(long)]
    pub overwrite: bool,
}

#[derive(Args, Debug, Clone)]
pub struct AttachmentDeleteArgs {
    /// Target entity ID
    pub item_id: String,

    /// Attachment ID to delete
    pub attachment_id: String,
}

// -----------------------------------------------------------------------------
// Search
// -----------------------------------------------------------------------------

#[derive(Args, Debug, Clone)]
pub struct SearchArgs {
    /// Optional free-text search query
    pub query: Option<String>,

    /// Filter by tag name or UUID
    #[arg(long)]
    pub tag: Option<String>,

    /// Filter by model number (exact or substring, case-insensitive)
    #[arg(long)]
    pub model: Option<String>,

    /// Filter by serial number (exact or substring, case-insensitive)
    #[arg(long)]
    pub serial: Option<String>,

    /// Filter by manufacturer (exact or substring, case-insensitive)
    #[arg(long)]
    pub manufacturer: Option<String>,
}

// -----------------------------------------------------------------------------
// Field
// -----------------------------------------------------------------------------

#[derive(Args, Debug, Clone)]
pub struct FieldArgs {
    #[command(subcommand)]
    pub command: FieldCommands,
}

#[derive(Subcommand, Debug, Clone)]
pub enum FieldCommands {
    /// Get a custom field value from an item
    Get {
        /// Entity ID
        item_id: String,
        /// Custom field name
        key: String,
    },
    /// Set a typed custom field on an item via GET -> Merge -> PUT
    Set {
        /// Entity ID
        item_id: String,
        /// Custom field name
        key: String,
        /// Custom field value
        value: String,
        /// Custom field value type
        #[arg(long = "type", value_enum, default_value_t = FieldValueType::Text)]
        field_type: FieldValueType,
    },
}

// -----------------------------------------------------------------------------
// Tag
// -----------------------------------------------------------------------------

#[derive(Args, Debug, Clone)]
pub struct TagArgs {
    #[command(subcommand)]
    pub command: TagCommands,
}

#[derive(Subcommand, Debug, Clone)]
pub enum TagCommands {
    /// List all tags
    List,
    /// Create a new tag
    Create {
        /// Tag name
        name: String,
    },
}

// -----------------------------------------------------------------------------
// Entity Types
// -----------------------------------------------------------------------------

#[derive(Args, Debug, Clone)]
pub struct EntityTypeArgs {
    #[command(subcommand)]
    pub command: Option<EntityTypeCommands>,
}

#[derive(Subcommand, Debug, Clone)]
pub enum EntityTypeCommands {
    /// List all entity types
    List,
}

// -----------------------------------------------------------------------------
// Export
// -----------------------------------------------------------------------------

#[derive(ValueEnum, Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum ExportSort {
    #[default]
    Name,
    Id,
}

#[derive(ValueEnum, Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum ExportFormat {
    #[default]
    Json,
    Csv,
    Markdown,
}

#[derive(Args, Debug, Clone)]
pub struct ExportArgs {
    /// Filter by tag name or UUID
    #[arg(long)]
    pub tag: Option<String>,

    /// Require items to have the named custom field
    #[arg(long)]
    pub has_field: Option<String>,

    /// Custom field column(s) to include in export (repeatable)
    #[arg(long = "field")]
    pub fields: Vec<String>,

    /// Sort exported items by name or id
    #[arg(long, value_enum, default_value_t = ExportSort::Name)]
    pub sort: ExportSort,

    /// Export format (json, csv, markdown)
    #[arg(long, value_enum, default_value_t = ExportFormat::Json)]
    pub format: ExportFormat,
}

// -----------------------------------------------------------------------------
// Shell completions & man page helpers (mirroring tfa)
// -----------------------------------------------------------------------------

pub fn generate_completions(shell: Shell, out: &mut dyn Write) {
    let mut cmd = Cli::command();
    let bin_name = cmd.get_name().to_string();
    clap_complete::generate(shell, &mut cmd, bin_name, out);
}

pub fn generate_manpage(out: &mut dyn Write) -> std::io::Result<()> {
    let cmd = Cli::command();
    let man = clap_mangen::Man::new(cmd);
    man.render(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_cli_parse_global_and_subcommands() {
        let cli = Cli::try_parse_from([
            "hbx",
            "--url",
            "http://127.0.0.1:7745",
            "--api-key",
            "hb_test",
            "--json",
            "--select",
            "id,name,fields",
            "item",
            "create",
            "--name",
            "ESP32",
            "--tag",
            "mcu",
            "--field",
            "Voltage=3.3",
            "--dry-run",
        ])
        .unwrap();

        assert_eq!(cli.url.as_deref(), Some("http://127.0.0.1:7745"));
        assert_eq!(cli.api_key.as_deref(), Some("hb_test"));
        assert!(cli.json);
        assert!(cli.dry_run);
        assert_eq!(
            cli.select.as_deref(),
            Some(&["id".to_string(), "name".to_string(), "fields".to_string()][..])
        );
        assert!(matches!(cli.command, Commands::Item(_)));
    }

    #[test]
    fn test_cli_parse_entity_types_and_export() {
        let cli = Cli::try_parse_from(["hbx", "entity-types"]).unwrap();
        assert!(matches!(cli.command, Commands::EntityTypes(_)));

        let cli = Cli::try_parse_from([
            "hbx",
            "export",
            "--tag",
            "electronics",
            "--field",
            "Voltage",
            "--field",
            "Manufacturer",
            "--sort",
            "id",
            "--format",
            "markdown",
        ])
        .unwrap();
        assert!(matches!(cli.command, Commands::Export(_)));
    }
}

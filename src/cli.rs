use std::fmt;
use std::io::Write;
use std::path::PathBuf;
use std::str::FromStr;

pub use clap::{Args, CommandFactory, Parser, Subcommand, ValueEnum};
pub use clap_complete::Shell;

use crate::client::models::FieldValueType;
use crate::config::{CliConfigOverrides, OutputFormat};
use crate::output::MarkdownAlign;

#[derive(Parser, Debug, Clone)]
#[command(name = "hbctl")]
#[command(
    author,
    version = env!("PROJECT_VERSION"),
    about = "Fast, agent-friendly Rust CLI for remote Homebox v0.26+ instances",
    long_about = None
)]
pub struct Cli {
    /// Homebox base URL (env: HBCTL_URL > HOMEBOX_URL > http://<HOMEBOX_IP>:7745)
    #[arg(long, global = true)]
    pub url: Option<String>,

    /// Homebox API key or Bearer token (env: HBCTL_API_KEY > HOMEBOX_API_KEY)
    #[arg(long, global = true)]
    pub api_key: Option<String>,

    /// Output format (table, json, plain, csv, markdown) [env: HBCTL_OUTPUT]
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

    /// Named configuration profile (env: HBCTL_PROFILE)
    #[arg(short = 'P', long, global = true, value_name = "NAME")]
    pub profile: Option<String>,

    /// Treat item ID arguments as Homebox asset IDs (auto-detected for numeric/dashed IDs like 000-001)
    #[arg(long = "asset-id", global = true)]
    pub asset_id: bool,

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
            profile: self.profile.clone(),
        }
    }
}

#[derive(Subcommand, Debug, Clone)]
#[allow(clippy::large_enum_variant)] // CLI parsed once; keeps Commands::Item(ItemArgs) unboxed
pub enum Commands {
    /// Authenticate with a remote Homebox instance (login, status, logout, refresh)
    Auth(AuthArgs),

    /// Manage inventory items (/api/v1/entities)
    Item(ItemArgs),

    /// Manage item attachments (/api/v1/entities/{id}/attachments)
    Attachment(AttachmentArgs),

    /// Full-text and structured item search
    Search(SearchArgs),

    /// List, get, set, or delete typed custom fields on an item
    Field(FieldArgs),

    /// Manage tags (/api/v1/tags)
    Tag(TagArgs),

    /// Manage Homebox entity types (/api/v1/entity-types)
    #[command(name = "entity-types", visible_alias = "entity-type")]
    EntityTypes(EntityTypeArgs),

    /// Check remote Homebox server connectivity and version (/api/v1/status)
    Status,

    /// Issue a raw authenticated HTTP request against any Homebox API endpoint
    Api(ApiArgs),

    /// Manage maintenance log entries (/api/v1/maintenance)
    Maintenance(MaintenanceArgs),

    /// Export filtered items to JSON, CSV, or Markdown
    Export(ExportArgs),

    /// Create a portable full-inventory backup (directory or .tar.gz archive)
    Backup(BackupArgs),

    /// Generate or print a Homebox item, asset, or location label (/api/v1/labelmaker)
    Label(LabelArgs),

    /// Generate a QR code image (/api/v1/qrcode)
    Qr(QrArgs),

    /// Run Homebox server maintenance actions (/api/v1/actions/*)
    #[command(visible_alias = "action")]
    Actions(ActionsArgs),

    /// Display inventory statistics and breakdowns (/api/v1/groups/statistics*)
    Stats(StatsArgs),

    /// Inspect effective configuration and manage named profiles
    Config(ConfigArgs),

    /// Manage item templates and create items from templates (/api/v1/templates)
    #[command(visible_alias = "templates")]
    Template(TemplateArgs),

    /// Look up product metadata by barcode (/api/v1/products/search-from-barcode)
    Barcode(BarcodeArgs),

    /// Manage Shoutrrr notification channels (/api/v1/notifiers)
    #[command(visible_alias = "notifiers")]
    Notifier(NotifierArgs),

    /// Generate shell completion scripts
    Completions {
        /// Shell to generate completions for
        #[arg(value_enum)]
        shell: Shell,
    },

    /// Generate UNIX roff man page
    Man,

    /// Check for and install the latest hbctl release from GitHub
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
    /// Move an item under a parent item/location (or 'none' to unparent)
    Move(ItemMoveArgs),
    /// Duplicate an existing item one or more times
    Duplicate(ItemDuplicateArgs),
    /// Display the location/parent breadcrumb path for an item
    Path(ItemPathArgs),
    /// Render item parent/location hierarchy as a tree
    Tree(ItemTreeArgs),
}

#[derive(Args, Debug, Clone)]
pub struct ItemListArgs {
    /// Filter by tag name or UUID
    #[arg(long)]
    pub tag: Option<String>,

    /// Filter by entity type name or UUID
    #[arg(long = "type")]
    pub entity_type: Option<String>,

    /// Filter by parent item name, ID, or 'none' for top-level items
    #[arg(long)]
    pub parent: Option<String>,

    /// Only include items having the named custom field (hydrates details if missing)
    #[arg(long)]
    pub has_field: Option<String>,

    /// Page size for listing
    #[arg(long)]
    pub page_size: Option<u32>,

    /// Fetch all pages
    #[arg(long)]
    pub all: bool,

    /// Include archived items in results
    #[arg(long)]
    pub include_archived: bool,

    /// Only show archived items (implies --include-archived)
    #[arg(long)]
    pub archived_only: bool,

    /// Only show items with a warranty expiring within the next DAYS days (excludes lifetime warranties)
    #[arg(long, value_name = "DAYS")]
    pub warranty_expiring: Option<u32>,
}

#[derive(Args, Debug, Clone)]
pub struct ItemGetArgs {
    /// Entity ID
    pub id: String,

    /// Include full location/parent breadcrumb path in output
    #[arg(long)]
    pub with_path: bool,
}

#[derive(Args, Debug, Clone)]
pub struct ItemCreateArgs {
    /// Item name (required unless supplied via --from-json or --from-barcode)
    #[arg(long)]
    pub name: Option<String>,

    /// Item description
    #[arg(long)]
    pub description: Option<String>,

    /// Entity type name or UUID
    #[arg(long = "type")]
    pub entity_type: Option<String>,

    /// Parent item/location name, ID, or 'none'
    #[arg(long)]
    pub parent: Option<String>,

    /// Tag name or UUID (repeatable; missing tags auto-created)
    #[arg(long = "tag")]
    pub tags: Vec<String>,

    /// Manufacturer (normalized into custom field 'Manufacturer')
    #[arg(long)]
    pub manufacturer: Option<String>,

    /// Model number (normalized into custom field 'Model Number')
    #[arg(long)]
    pub model: Option<String>,

    /// Serial number (normalized into custom field 'Serial Number')
    #[arg(long)]
    pub serial: Option<String>,

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

    /// Mark item as archived (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub archived: Option<bool>,

    /// Mark item as insured (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub insured: Option<bool>,

    /// Mark item as having a lifetime warranty (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub lifetime_warranty: Option<bool>,

    /// Warranty expiration date (YYYY-MM-DD or RFC3339)
    #[arg(long, value_name = "DATE")]
    pub warranty_expires: Option<String>,

    /// Warranty details or terms
    #[arg(long)]
    pub warranty_details: Option<String>,

    /// Date/time the item was sold (YYYY-MM-DD or RFC3339)
    #[arg(long, value_name = "DATE")]
    pub sold_time: Option<String>,

    /// Buyer name or recipient the item was sold to
    #[arg(long)]
    pub sold_to: Option<String>,

    /// Sale price
    #[arg(long)]
    pub sold_price: Option<f64>,

    /// Notes about the sale
    #[arg(long)]
    pub sold_notes: Option<String>,

    /// Custom field KEY=VAL (repeatable)
    #[arg(long = "field")]
    pub fields: Vec<String>,

    /// Value type for --field entries
    #[arg(long, value_enum, default_value_t = FieldValueType::Text)]
    pub field_type: FieldValueType,

    /// Load initial item JSON from file path or '-' for stdin
    #[arg(long)]
    pub from_json: Option<String>,

    /// Prefill name, description, manufacturer, and model from a barcode lookup
    #[arg(long, value_name = "CODE")]
    pub from_barcode: Option<String>,

    /// Local file path(s) to attach after creating the item (`FILE` or `FILE=REMOTE_NAME`, repeatable)
    #[arg(long = "attach", value_name = "FILE[=NAME]")]
    pub attach: Vec<String>,

    /// Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)
    #[arg(long = "attach-url", value_name = "URL[=NAME]")]
    pub attach_url: Vec<String>,

    /// Treat attachment failures as non-fatal warnings and include `attachmentErrors` in JSON output
    #[arg(long = "attach-best-effort")]
    pub attach_best_effort: bool,

    /// Automatically resize/compress oversized images before upload
    #[arg(long)]
    pub optimize: bool,

    /// Allow attaching images larger than 500KB
    #[arg(long)]
    pub force: bool,
}

#[derive(Args, Debug, Clone)]
pub struct ItemUpdateArgs {
    /// Entity ID(s) to update (omit when using --items-from or filter selectors)
    #[arg(value_name = "ID")]
    pub ids: Vec<String>,

    /// Read newline-delimited entity IDs to update from a file or '-' (stdin)
    #[arg(long = "items-from", value_name = "FILE|-")]
    pub items_from: Option<PathBuf>,

    /// Select items to update matching this tag name or UUID
    #[arg(long = "filter-tag", value_name = "TAG")]
    pub filter_tag: Option<String>,

    /// Select items to update under this parent item/location name, ID, or 'none'
    #[arg(long = "filter-parent", value_name = "PARENT")]
    pub filter_parent: Option<String>,

    /// Select items to update matching this entity type name or UUID
    #[arg(long = "filter-type", value_name = "TYPE")]
    pub filter_type: Option<String>,

    /// Updated item name
    #[arg(long)]
    pub name: Option<String>,

    /// Updated item description
    #[arg(long)]
    pub description: Option<String>,

    /// Entity type name or UUID
    #[arg(long = "type")]
    pub entity_type: Option<String>,

    /// Parent item/location name, ID, or 'none' to unparent
    #[arg(long)]
    pub parent: Option<String>,

    /// Tag name or UUID to merge (repeatable)
    #[arg(long = "tag")]
    pub tags: Vec<String>,

    /// Tag name or UUID to add while preserving existing tags (repeatable)
    #[arg(long = "add-tag")]
    pub add_tags: Vec<String>,

    /// Tag name or UUID to remove while preserving other existing tags (repeatable)
    #[arg(long = "remove-tag")]
    pub remove_tags: Vec<String>,

    /// Manufacturer (merged into custom field 'Manufacturer')
    #[arg(long)]
    pub manufacturer: Option<String>,

    /// Model number (merged into custom field 'Model Number')
    #[arg(long)]
    pub model: Option<String>,

    /// Serial number (merged into custom field 'Serial Number')
    #[arg(long)]
    pub serial: Option<String>,

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

    /// Mark item as archived (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub archived: Option<bool>,

    /// Mark item as insured (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub insured: Option<bool>,

    /// Mark item as having a lifetime warranty (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub lifetime_warranty: Option<bool>,

    /// Warranty expiration date (YYYY-MM-DD or RFC3339)
    #[arg(long, value_name = "DATE")]
    pub warranty_expires: Option<String>,

    /// Warranty details or terms
    #[arg(long)]
    pub warranty_details: Option<String>,

    /// Date/time the item was sold (YYYY-MM-DD or RFC3339)
    #[arg(long, value_name = "DATE")]
    pub sold_time: Option<String>,

    /// Buyer name or recipient the item was sold to
    #[arg(long)]
    pub sold_to: Option<String>,

    /// Sale price
    #[arg(long)]
    pub sold_price: Option<f64>,

    /// Notes about the sale
    #[arg(long)]
    pub sold_notes: Option<String>,

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

    /// Only populate blank/missing/zero fields; preserve existing non-empty values
    #[arg(long)]
    pub fill_missing: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum MatchKey {
    Name,
    Model,
    Serial,
    Field(String),
}

impl FromStr for MatchKey {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let trimmed = s.trim();
        if trimmed.eq_ignore_ascii_case("name") {
            return Ok(Self::Name);
        }
        if trimmed.eq_ignore_ascii_case("model") {
            return Ok(Self::Model);
        }
        if trimmed.eq_ignore_ascii_case("serial") {
            return Ok(Self::Serial);
        }
        if let Some((prefix, key)) = trimmed.split_once(':') {
            if prefix.eq_ignore_ascii_case("field") {
                let key = key.trim();
                if key.is_empty() {
                    return Err(
                        "invalid --match-by 'field:': field key cannot be empty".to_string()
                    );
                }
                return Ok(Self::Field(key.to_string()));
            }
        }
        Err(format!(
            "invalid --match-by '{s}': expected name, model, serial, or field:KEY"
        ))
    }
}

impl fmt::Display for MatchKey {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Name => f.write_str("name"),
            Self::Model => f.write_str("model"),
            Self::Serial => f.write_str("serial"),
            Self::Field(k) => write!(f, "field:{k}"),
        }
    }
}

#[derive(ValueEnum, Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum MatchMode {
    #[default]
    Exact,
    Contains,
    Fuzzy,
}

impl fmt::Display for MatchMode {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Exact => f.write_str("exact"),
            Self::Contains => f.write_str("contains"),
            Self::Fuzzy => f.write_str("fuzzy"),
        }
    }
}

#[derive(ValueEnum, Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum OnMatchAction {
    #[default]
    Update,
    Skip,
    AttachOnly,
}

impl fmt::Display for OnMatchAction {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Update => f.write_str("update"),
            Self::Skip => f.write_str("skip"),
            Self::AttachOnly => f.write_str("attach-only"),
        }
    }
}

#[derive(Args, Debug, Clone)]
pub struct ItemUpsertArgs {
    /// Item name to match or create (required unless supplied via --from-json)
    #[arg(long)]
    pub name: Option<String>,

    /// Item description
    #[arg(long)]
    pub description: Option<String>,

    /// Entity type name or UUID
    #[arg(long = "type")]
    pub entity_type: Option<String>,

    /// Parent item/location name, ID, or 'none'
    #[arg(long)]
    pub parent: Option<String>,

    /// Tag name or UUID (repeatable; missing tags auto-created)
    #[arg(long = "tag")]
    pub tags: Vec<String>,

    /// Manufacturer
    #[arg(long)]
    pub manufacturer: Option<String>,

    /// Model number
    #[arg(long)]
    pub model: Option<String>,

    /// Serial number
    #[arg(long)]
    pub serial: Option<String>,

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

    /// Mark item as archived (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub archived: Option<bool>,

    /// Mark item as insured (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub insured: Option<bool>,

    /// Mark item as having a lifetime warranty (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub lifetime_warranty: Option<bool>,

    /// Warranty expiration date (YYYY-MM-DD or RFC3339)
    #[arg(long, value_name = "DATE")]
    pub warranty_expires: Option<String>,

    /// Warranty details or terms
    #[arg(long)]
    pub warranty_details: Option<String>,

    /// Date/time the item was sold (YYYY-MM-DD or RFC3339)
    #[arg(long, value_name = "DATE")]
    pub sold_time: Option<String>,

    /// Buyer name or recipient the item was sold to
    #[arg(long)]
    pub sold_to: Option<String>,

    /// Sale price
    #[arg(long)]
    pub sold_price: Option<f64>,

    /// Notes about the sale
    #[arg(long)]
    pub sold_notes: Option<String>,

    /// Custom field KEY=VAL (repeatable)
    #[arg(long = "field")]
    pub fields: Vec<String>,

    /// Value type for --field entries
    #[arg(long, value_enum, default_value_t = FieldValueType::Text)]
    pub field_type: FieldValueType,

    /// When updating an existing item, only populate blank/missing/zero fields
    #[arg(long)]
    pub fill_missing: bool,

    /// Load item JSON from file path or '-' for stdin
    #[arg(long)]
    pub from_json: Option<String>,

    /// Match existing items by key in priority order: name, model, serial, or field:KEY (repeatable; defaults to name)
    #[arg(long = "match-by", value_name = "KEY", value_delimiter = ',')]
    pub match_by: Vec<MatchKey>,

    /// Matching strategy for --match-by keys (exact, contains, fuzzy)
    #[arg(long = "match-mode", value_enum, default_value_t = MatchMode::Exact)]
    pub match_mode: MatchMode,

    /// Action to take when an existing item matches (update, skip, attach-only)
    #[arg(long = "on-match", value_enum, default_value_t = OnMatchAction::Update)]
    pub on_match: OnMatchAction,

    /// Local file path(s) to attach after upserting the item (`FILE` or `FILE=REMOTE_NAME`, repeatable)
    #[arg(long = "attach", value_name = "FILE[=NAME]")]
    pub attach: Vec<String>,

    /// Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)
    #[arg(long = "attach-url", value_name = "URL[=NAME]")]
    pub attach_url: Vec<String>,

    /// Treat attachment failures as non-fatal warnings and include `attachmentErrors` in JSON output
    #[arg(long = "attach-best-effort")]
    pub attach_best_effort: bool,

    /// Automatically resize/compress oversized images before upload
    #[arg(long)]
    pub optimize: bool,

    /// Allow attaching images larger than 500KB
    #[arg(long)]
    pub force: bool,
}

#[derive(Args, Debug, Clone)]
pub struct ItemDeleteArgs {
    /// Entity ID(s) to delete (omit when using --items-from or filter selectors)
    #[arg(value_name = "ID")]
    pub ids: Vec<String>,

    /// Read newline-delimited entity IDs to delete from a file or '-' (stdin)
    #[arg(long = "items-from", value_name = "FILE|-")]
    pub items_from: Option<PathBuf>,

    /// Select items to delete matching this tag name or UUID
    #[arg(long = "tag", visible_alias = "filter-tag", value_name = "TAG")]
    pub tag: Option<String>,

    /// Select items to delete under this parent item/location name, ID, or 'none'
    #[arg(
        long = "parent",
        visible_alias = "filter-parent",
        value_name = "PARENT"
    )]
    pub parent: Option<String>,

    /// Select items to delete matching this entity type name or UUID
    #[arg(long = "type", visible_alias = "filter-type", value_name = "TYPE")]
    pub entity_type: Option<String>,

    /// Skip interactive/bulk confirmation prompt
    #[arg(short = 'y', long = "yes")]
    pub yes: bool,

    /// Skip interactive/bulk confirmation prompt
    #[arg(long)]
    pub force: bool,
}

impl ItemDeleteArgs {
    pub fn skip_confirm(&self) -> bool {
        self.yes || self.force
    }
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

    /// With --update-existing, only populate blank/missing/zero fields on existing items
    #[arg(long, requires = "update_existing", conflicts_with = "skip_existing")]
    pub fill_missing: bool,

    /// Match existing items by key in priority order: name, model, serial, or field:KEY (repeatable; defaults to name)
    #[arg(long = "match-by", value_name = "KEY", value_delimiter = ',')]
    pub match_by: Vec<MatchKey>,

    /// Matching strategy for --match-by keys (exact, contains, fuzzy)
    #[arg(long = "match-mode", value_enum, default_value_t = MatchMode::Exact)]
    pub match_mode: MatchMode,

    /// Default parent item/location name, ID, or 'none' for imported records without one
    #[arg(long)]
    pub parent: Option<String>,

    /// Local file path(s) to attach to each imported item (`FILE` or `FILE=REMOTE_NAME`, repeatable)
    #[arg(long = "attach", value_name = "FILE[=NAME]")]
    pub attach: Vec<String>,

    /// Automatically resize/compress oversized images before upload
    #[arg(long)]
    pub optimize: bool,

    /// Allow attaching images larger than 500KB
    #[arg(long)]
    pub force: bool,
}

#[derive(Args, Debug, Clone)]
pub struct ItemMoveArgs {
    /// Entity ID(s) followed by target parent (`<ID>... <PARENT>`), or `<ID>...` when `--to` is set
    #[arg(value_name = "ID_OR_PARENT")]
    pub ids: Vec<String>,

    /// Target parent item name, ID, or 'none' to unparent (required when using selectors without trailing positional parent)
    #[arg(long = "to", value_name = "PARENT")]
    pub to: Option<String>,

    /// Read newline-delimited entity IDs to move from a file or '-' (stdin)
    #[arg(long = "items-from", value_name = "FILE|-")]
    pub items_from: Option<PathBuf>,

    /// Select items to move matching this tag name or UUID
    #[arg(long = "tag", visible_alias = "filter-tag", value_name = "TAG")]
    pub tag: Option<String>,

    /// Select items to move under this parent item/location name, ID, or 'none'
    #[arg(
        long = "parent",
        visible_alias = "filter-parent",
        value_name = "PARENT"
    )]
    pub parent: Option<String>,

    /// Select items to move matching this entity type name or UUID
    #[arg(long = "type", visible_alias = "filter-type", value_name = "TYPE")]
    pub entity_type: Option<String>,
}

impl ItemMoveArgs {
    /// Split positional arguments and `--to` into `(explicit_item_ids, destination_parent)`.
    pub fn split_targets_and_destination(&self) -> crate::error::Result<(Vec<String>, String)> {
        let has_selector = self.items_from.is_some()
            || self.tag.is_some()
            || self.parent.is_some()
            || self.entity_type.is_some();

        if let Some(ref dest) = self.to {
            if dest.trim().is_empty() {
                return Err(crate::error::HbctlError::InvalidInput(
                    "target parent cannot be empty".to_string(),
                ));
            }
            return Ok((self.ids.clone(), dest.clone()));
        }

        if has_selector {
            let Some((dest, targets)) = self.ids.split_last() else {
                return Err(crate::error::HbctlError::InvalidInput(
                    "missing target parent: pass --to <PARENT>".to_string(),
                ));
            };
            if dest.trim().is_empty() {
                return Err(crate::error::HbctlError::InvalidInput(
                    "target parent cannot be empty".to_string(),
                ));
            }
            return Ok((targets.to_vec(), dest.clone()));
        }

        if self.ids.len() < 2 {
            return Err(crate::error::HbctlError::InvalidInput(
                "specify <ID>... <PARENT> or use --to <PARENT> with --items-from/--tag/--parent/--type".to_string(),
            ));
        }
        let (dest, targets) = self.ids.split_last().expect("checked len >= 2 above");
        if dest.trim().is_empty() {
            return Err(crate::error::HbctlError::InvalidInput(
                "target parent cannot be empty".to_string(),
            ));
        }
        Ok((targets.to_vec(), dest.clone()))
    }
}

#[derive(Args, Debug, Clone)]
pub struct ItemDuplicateArgs {
    /// Entity ID to duplicate
    pub id: String,

    /// Number of duplicates to create
    #[arg(long, default_value_t = 1, value_name = "N")]
    pub count: usize,
}

#[derive(Args, Debug, Clone)]
pub struct ItemPathArgs {
    /// Entity ID
    pub id: String,
}

#[derive(Args, Debug, Clone)]
pub struct ItemTreeArgs {
    /// Optional root item name or ID to start the tree from
    #[arg(long)]
    pub root: Option<String>,

    /// Optional maximum depth to display (0 = roots only)
    #[arg(long)]
    pub max_depth: Option<usize>,
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
    /// Stream-download attachments from one or multiple items
    Download(AttachmentDownloadArgs),
    /// Delete an attachment from an item
    Delete(AttachmentDeleteArgs),
    /// Mark an existing attachment as the item's primary photo
    SetPrimary(AttachmentSetPrimaryArgs),
    /// Update attachment metadata (title, type, primary)
    Update(AttachmentUpdateArgs),
    /// Attach an external HTTP(S) URL link to an item
    AddLink(AttachmentAddLinkArgs),
}

#[derive(Args, Debug, Clone)]
pub struct AttachmentUploadArgs {
    /// Target entity ID or asset ID
    pub item_id: String,

    /// Local file path(s) to upload (or '-' for stdin when combined with --name)
    #[arg(required_unless_present = "attach_url")]
    pub files: Vec<PathBuf>,

    /// Remote HTTP(S) URL(s) to download and attach (`URL` or `URL=REMOTE_NAME`, repeatable)
    #[arg(long = "attach-url", value_name = "URL[=NAME]")]
    pub attach_url: Vec<String>,

    /// Override remote filename/title (for single-file or stdin '-' uploads)
    #[arg(long)]
    pub name: Option<String>,

    /// Mark the uploaded attachment as the item's primary photo
    #[arg(long)]
    pub primary: bool,

    /// Skip files that already exist on the item (default behavior)
    #[arg(long, conflicts_with = "overwrite")]
    pub skip_existing: bool,

    /// Delete and re-upload files that already exist on the item
    #[arg(long, conflicts_with = "skip_existing")]
    pub overwrite: bool,

    /// Automatically resize/compress oversized images before upload
    #[arg(long)]
    pub optimize: bool,

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
    /// Target entity ID (omit when using --all-items, --tag, or --items-from)
    pub item_id: Option<String>,

    /// Specific attachment ID to download (omit when using --all or bulk selectors)
    pub attachment_id: Option<String>,

    /// Download all matching attachments on the item
    #[arg(long)]
    pub all: bool,

    /// Download matching attachments across all items
    #[arg(long, conflicts_with_all = ["item_id", "attachment_id", "tag", "items_from"])]
    pub all_items: bool,

    /// Download matching attachments across items matching this tag name or UUID
    #[arg(long, value_name = "TAG", conflicts_with_all = ["item_id", "attachment_id", "all_items", "items_from"])]
    pub tag: Option<String>,

    /// Download matching attachments for newline-delimited entity IDs from a file or '-' (stdin)
    #[arg(long, value_name = "FILE|-", conflicts_with_all = ["item_id", "attachment_id", "all_items", "tag"])]
    pub items_from: Option<PathBuf>,

    /// Filter attachments by MIME type (e.g. application/pdf)
    #[arg(long)]
    pub mime: Option<String>,

    /// Filter attachments by file extension (e.g. pdf)
    #[arg(long)]
    pub ext: Option<String>,

    /// Output file path (single download) or directory (multi-download / --all / bulk)
    #[arg(long)]
    pub out: Option<PathBuf>,

    /// Overwrite existing local files instead of skipping
    #[arg(long)]
    pub overwrite: bool,
}

#[derive(Args, Debug, Clone)]
pub struct AttachmentDeleteArgs {
    /// Target entity ID or asset ID
    pub item_id: String,

    /// Attachment ID to delete
    pub attachment_id: String,
}

#[derive(Args, Debug, Clone)]
pub struct AttachmentSetPrimaryArgs {
    /// Target entity ID or asset ID
    pub item_id: String,

    /// Attachment ID to mark as primary
    pub attachment_id: String,
}

#[derive(Args, Debug, Clone)]
pub struct AttachmentUpdateArgs {
    /// Target entity ID or asset ID
    pub item_id: String,

    /// Attachment ID to update
    pub attachment_id: String,

    /// Updated attachment title
    #[arg(long)]
    pub title: Option<String>,

    /// Updated attachment type (e.g. photo, manual, warranty, receipt, attachment)
    #[arg(long = "type", value_name = "TYPE")]
    pub attachment_type: Option<String>,

    /// Mark or unmark as the primary attachment (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub primary: Option<bool>,
}

#[derive(Args, Debug, Clone)]
pub struct AttachmentAddLinkArgs {
    /// Target entity ID or asset ID
    pub item_id: String,

    /// External HTTP(S) URL to attach
    #[arg(value_name = "URL")]
    pub link: String,

    /// Display title for the external link (defaults to sanitized URL)
    #[arg(long)]
    pub title: Option<String>,

    /// Attachment type (photo, manual, warranty, receipt, attachment)
    #[arg(long = "type", value_name = "TYPE")]
    pub attachment_type: Option<String>,
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

    /// Filter by entity type name or UUID
    #[arg(long = "type")]
    pub entity_type: Option<String>,

    /// Filter by parent item name, ID, or 'none' for top-level items
    #[arg(long)]
    pub parent: Option<String>,

    /// Maximum number of matching results to return
    #[arg(long, value_name = "N")]
    pub limit: Option<usize>,

    /// Include archived items in search results
    #[arg(long)]
    pub include_archived: bool,

    /// Only search archived items (implies --include-archived)
    #[arg(long)]
    pub archived_only: bool,

    /// Only include items with a warranty expiring within the next DAYS days (excludes lifetime warranties)
    #[arg(long, value_name = "DAYS")]
    pub warranty_expiring: Option<u32>,

    /// Filter by model number (exact or substring, case-insensitive)
    #[arg(long)]
    pub model: Option<String>,

    /// Filter by serial number (exact or substring, case-insensitive)
    #[arg(long)]
    pub serial: Option<String>,

    /// Filter by manufacturer (exact or substring, case-insensitive)
    #[arg(long)]
    pub manufacturer: Option<String>,

    /// Filter by custom field existence (KEY) or substring value (KEY=VAL), case-insensitive (repeatable)
    #[arg(long = "field", value_name = "KEY[=VAL]")]
    pub fields: Vec<String>,

    /// Match items satisfying ANY provided filter (OR) instead of ALL filters (AND)
    #[arg(long)]
    pub any: bool,

    /// Include full location/parent breadcrumb path for each matching item
    #[arg(long)]
    pub with_path: bool,
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
    /// List all custom fields on an item
    List {
        /// Entity ID
        item_id: String,
    },
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
    /// Delete a custom field from an item via GET -> Remove -> PUT
    Delete {
        /// Entity ID
        item_id: String,
        /// Custom field name
        key: String,
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
    /// Update an existing tag by ID
    Update {
        /// Tag ID
        id: String,
        /// Updated tag name
        #[arg(long)]
        name: Option<String>,
        /// Updated tag description
        #[arg(long)]
        description: Option<String>,
        /// Updated tag hex color
        #[arg(long)]
        color: Option<String>,
    },
    /// Delete a tag by ID
    Delete {
        /// Tag ID
        id: String,
        /// Skip interactive confirmation prompt
        #[arg(long)]
        force: bool,
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
    /// Create a new entity type
    Create {
        /// Entity type name
        name: String,
        /// Optional description
        #[arg(long)]
        description: Option<String>,
        /// Mark this entity type as a location/container
        #[arg(long)]
        is_location: bool,
    },
    /// Delete an entity type by ID
    Delete {
        /// Entity type ID
        id: String,
        /// Skip interactive confirmation prompt
        #[arg(long)]
        force: bool,
    },
}

// -----------------------------------------------------------------------------
// Raw API
// -----------------------------------------------------------------------------

#[derive(Args, Debug, Clone)]
pub struct ApiArgs {
    /// HTTP method (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS)
    pub method: String,

    /// Homebox API endpoint path (e.g. groups, /maintenance, /api/v1/templates)
    pub path: String,

    /// Inline JSON request body
    #[arg(
        short = 'd',
        long = "data",
        value_name = "JSON",
        conflicts_with = "from_json"
    )]
    pub data: Option<String>,

    /// Read JSON request body from a file path or '-' for stdin
    #[arg(long = "from-json", value_name = "FILE|-", conflicts_with = "data")]
    pub from_json: Option<String>,

    /// Query parameter KEY=VALUE (repeatable; appended to any inline path query)
    #[arg(long = "query", value_name = "KEY=VALUE")]
    pub query: Vec<String>,
}

// -----------------------------------------------------------------------------
// Maintenance
// -----------------------------------------------------------------------------

#[derive(ValueEnum, Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum MaintenanceStatus {
    #[default]
    Both,
    Completed,
    Scheduled,
}

impl MaintenanceStatus {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Both => "both",
            Self::Completed => "completed",
            Self::Scheduled => "scheduled",
        }
    }
}

#[derive(Args, Debug, Clone)]
pub struct MaintenanceArgs {
    #[command(subcommand)]
    pub command: MaintenanceCommands,
}

#[derive(Subcommand, Debug, Clone)]
pub enum MaintenanceCommands {
    /// List maintenance log entries (globally or for a specific entity)
    List {
        /// Optional entity UUID
        entity: Option<String>,

        /// Filter by maintenance status (both, completed, scheduled)
        #[arg(long, value_enum, default_value_t = MaintenanceStatus::Both)]
        status: MaintenanceStatus,
    },
    /// Create a maintenance log entry on an entity
    Create(MaintenanceCreateArgs),
    /// Update an existing maintenance log entry by entry ID
    Update(MaintenanceUpdateArgs),
    /// Delete a maintenance log entry by entry ID
    Delete {
        /// Maintenance entry UUID
        entry_id: String,
        /// Skip interactive confirmation prompt
        #[arg(long)]
        force: bool,
    },
}

#[derive(Args, Debug, Clone)]
pub struct MaintenanceCreateArgs {
    /// Target entity UUID
    pub entity: String,

    /// Maintenance task/entry name
    #[arg(long)]
    pub name: String,

    /// Completion date (YYYY-MM-DD or YYYY-MM)
    #[arg(long, value_name = "YYYY-MM-DD")]
    pub completed_date: Option<String>,

    /// Scheduled date (YYYY-MM-DD or YYYY-MM)
    #[arg(long, value_name = "YYYY-MM-DD")]
    pub scheduled_date: Option<String>,

    /// Maintenance cost (e.g. 29.99 or $29.99)
    #[arg(long, value_name = "COST")]
    pub cost: Option<String>,

    /// Maintenance description or notes
    #[arg(long, value_name = "TEXT")]
    pub description: Option<String>,
}

#[derive(Args, Debug, Clone)]
pub struct MaintenanceUpdateArgs {
    /// Maintenance entry UUID
    pub entry_id: String,

    /// Updated maintenance task/entry name
    #[arg(long)]
    pub name: Option<String>,

    /// Updated completion date (YYYY-MM-DD or YYYY-MM)
    #[arg(long, value_name = "YYYY-MM-DD")]
    pub completed_date: Option<String>,

    /// Updated scheduled date (YYYY-MM-DD or YYYY-MM)
    #[arg(long, value_name = "YYYY-MM-DD")]
    pub scheduled_date: Option<String>,

    /// Updated maintenance cost (e.g. 29.99 or $29.99)
    #[arg(long, value_name = "COST")]
    pub cost: Option<String>,

    /// Updated maintenance description or notes
    #[arg(long, value_name = "TEXT")]
    pub description: Option<String>,
}

// -----------------------------------------------------------------------------
// Export
// -----------------------------------------------------------------------------

#[derive(ValueEnum, Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum ExportSort {
    #[default]
    Name,
    Id,
    PurchasePrice,
    PurchaseDate,
    UpdatedAt,
    AssetId,
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

    /// Sort exported items (name, id, purchase-price, purchase-date, updated-at, asset-id)
    #[arg(long, value_enum, default_value_t = ExportSort::Name)]
    pub sort: ExportSort,

    /// Export format (json, csv, markdown)
    #[arg(long, value_enum, default_value_t = ExportFormat::Json)]
    pub format: ExportFormat,

    /// Custom column list and order (comma-separated or repeatable; supports 'key=Header Alias')
    #[arg(long = "columns", value_name = "COL[=ALIAS]", value_delimiter = ',')]
    pub columns: Vec<String>,

    /// Markdown table column alignment (default, left, right, center)
    #[arg(long, value_enum, default_value_t = MarkdownAlign::Default)]
    pub align: MarkdownAlign,

    /// Placeholder string for empty/missing cells
    #[arg(long, value_name = "STR", default_value = "")]
    pub empty: String,
}

// -----------------------------------------------------------------------------
// Backup
// -----------------------------------------------------------------------------

#[derive(Args, Debug, Clone)]
pub struct BackupArgs {
    /// Destination directory or .tar.gz / .tgz archive path
    #[arg(short = 'o', long = "out", value_name = "PATH")]
    pub out: PathBuf,

    /// Skip downloading attachment binary files (attachment metadata stays in entities.json)
    #[arg(long)]
    pub no_attachments: bool,

    /// Exclude archived items from the backup (archived items are included by default)
    #[arg(long)]
    pub exclude_archived: bool,

    /// Overwrite an existing archive file or write into a non-empty directory
    #[arg(long)]
    pub overwrite: bool,
}

// -----------------------------------------------------------------------------
// Label, QR & Server Actions
// -----------------------------------------------------------------------------

#[derive(ValueEnum, Clone, Copy, Debug, Default, PartialEq, Eq)]
pub enum LabelTargetKind {
    #[default]
    Auto,
    Item,
    Asset,
    Location,
}

#[derive(Args, Debug, Clone)]
pub struct LabelArgs {
    /// Item UUID, location UUID, or asset ID (e.g. 000-001)
    pub id: String,

    /// Output file path, or '-' to write raw label bytes to stdout
    #[arg(short = 'o', long, value_name = "FILE|-", conflicts_with = "print")]
    pub out: Option<PathBuf>,

    /// Target label endpoint kind (auto detects numeric/dashed asset IDs)
    #[arg(long = "kind", value_enum, default_value_t = LabelTargetKind::Auto)]
    pub kind: LabelTargetKind,

    /// Send the label directly to the server's configured printer (?print=true)
    #[arg(long)]
    pub print: bool,

    /// Overwrite output file if it already exists
    #[arg(long)]
    pub overwrite: bool,
}

#[derive(Args, Debug, Clone)]
pub struct QrArgs {
    /// Item UUID, asset ID, URL, or raw data (with --raw)
    pub id: String,

    /// Output file path, or '-' to write raw QR image bytes to stdout
    #[arg(short = 'o', long, value_name = "FILE|-")]
    pub out: Option<PathBuf>,

    /// Encode <ID> verbatim as QR `data` instead of building a Homebox item/asset URL
    #[arg(long)]
    pub raw: bool,

    /// Overwrite output file if it already exists
    #[arg(long)]
    pub overwrite: bool,
}

#[derive(Args, Debug, Clone)]
pub struct ActionsArgs {
    #[command(subcommand)]
    pub command: ActionsCommands,
}

#[derive(Subcommand, Debug, Clone)]
pub enum ActionsCommands {
    /// Ensure all items in Homebox have an asset ID assigned (/api/v1/actions/ensure-asset-ids)
    EnsureAssetIds,
    /// Create thumbnails for attachments missing them (/api/v1/actions/create-missing-thumbnails)
    CreateMissingThumbnails,
}

// -----------------------------------------------------------------------------
// Stats & Config
// -----------------------------------------------------------------------------

#[derive(Args, Debug, Clone)]
pub struct StatsArgs {
    /// Also count non-lifetime warranties expiring within DAYS days
    #[arg(long, value_name = "DAYS")]
    pub warranty_days: Option<u32>,

    #[command(subcommand)]
    pub command: Option<StatsCommands>,
}

#[derive(Subcommand, Debug, Clone)]
pub enum StatsCommands {
    /// Group-wide overview statistics (/api/v1/groups/statistics + upcoming maintenance)
    Overview,
    /// Tag purchase-value breakdown (/api/v1/groups/statistics/tags)
    Tags,
    /// Location purchase-value breakdown (/api/v1/groups/statistics/locations)
    Locations,
    /// Entity-type count and purchase-value breakdown
    #[command(name = "entity-types", visible_alias = "types")]
    EntityTypes,
    /// Purchase value over time (/api/v1/groups/statistics/purchase-price)
    #[command(name = "purchase-price", visible_alias = "price")]
    PurchasePrice {
        /// Start date (YYYY-MM-DD)
        #[arg(long, value_name = "YYYY-MM-DD")]
        start: Option<String>,
        /// End date (YYYY-MM-DD)
        #[arg(long, value_name = "YYYY-MM-DD")]
        end: Option<String>,
    },
}

#[derive(Args, Debug, Clone)]
pub struct ConfigArgs {
    #[command(subcommand)]
    pub command: ConfigCommands,
}

#[derive(Subcommand, Debug, Clone)]
pub enum ConfigCommands {
    /// Display effective resolved configuration (secrets redacted as Bearer ***)
    Show,
    /// List configured profiles and indicate active/default selection
    Profiles,
    /// Switch the active default profile in user config
    Use {
        /// Profile name to set as default_profile
        profile: String,
    },
}

// -----------------------------------------------------------------------------
// Templates, Barcode & Notifiers
// -----------------------------------------------------------------------------

#[derive(Args, Debug, Clone)]
pub struct TemplateArgs {
    #[command(subcommand)]
    pub command: TemplateCommands,
}

#[derive(Subcommand, Debug, Clone)]
pub enum TemplateCommands {
    /// List all entity templates
    List,
    /// Fetch a single entity template by ID
    Get {
        /// Template UUID
        id: String,
    },
    /// Create a new entity template
    Create(TemplateCreateArgs),
    /// Update an existing entity template (GET -> Merge -> PUT)
    Update(TemplateUpdateArgs),
    /// Delete an entity template
    Delete {
        /// Template UUID
        id: String,
        /// Skip interactive confirmation prompt
        #[arg(short = 'y', long = "yes")]
        yes: bool,
        /// Skip interactive confirmation prompt
        #[arg(long)]
        force: bool,
    },
    /// Create a new item from a template (/api/v1/templates/{id}/create-item)
    Apply(TemplateApplyArgs),
}

#[derive(Args, Debug, Clone)]
pub struct TemplateCreateArgs {
    /// Template name
    #[arg(long)]
    pub name: String,

    /// Template description
    #[arg(long)]
    pub description: Option<String>,

    /// Template notes
    #[arg(long)]
    pub notes: Option<String>,

    /// Default item name
    #[arg(long)]
    pub default_name: Option<String>,

    /// Default item description
    #[arg(long)]
    pub default_description: Option<String>,

    /// Default item quantity
    #[arg(long)]
    pub default_quantity: Option<f64>,

    /// Default item manufacturer
    #[arg(long)]
    pub default_manufacturer: Option<String>,

    /// Default item model number
    #[arg(long = "default-model")]
    pub default_model: Option<String>,

    /// Default insured flag (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub default_insured: Option<bool>,

    /// Default lifetime warranty flag (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub default_lifetime_warranty: Option<bool>,

    /// Default warranty details
    #[arg(long)]
    pub default_warranty_details: Option<String>,

    /// Default location name or UUID
    #[arg(long)]
    pub default_location: Option<String>,

    /// Default tag name or UUID (repeatable; missing tags auto-created)
    #[arg(long = "default-tag")]
    pub default_tags: Vec<String>,

    /// Include warranty fields on created items (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub include_warranty_fields: Option<bool>,

    /// Include purchase fields on created items (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub include_purchase_fields: Option<bool>,

    /// Include sold fields on created items (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub include_sold_fields: Option<bool>,

    /// Default custom field KEY=VAL (repeatable)
    #[arg(long = "field")]
    pub fields: Vec<String>,

    /// Value type for --field entries
    #[arg(long, value_enum, default_value_t = FieldValueType::Text)]
    pub field_type: FieldValueType,
}

#[derive(Args, Debug, Clone)]
pub struct TemplateUpdateArgs {
    /// Template UUID
    pub id: String,

    /// Updated template name
    #[arg(long)]
    pub name: Option<String>,

    /// Updated template description
    #[arg(long)]
    pub description: Option<String>,

    /// Updated template notes
    #[arg(long)]
    pub notes: Option<String>,

    /// Updated default item name
    #[arg(long)]
    pub default_name: Option<String>,

    /// Updated default item description
    #[arg(long)]
    pub default_description: Option<String>,

    /// Updated default item quantity
    #[arg(long)]
    pub default_quantity: Option<f64>,

    /// Updated default item manufacturer
    #[arg(long)]
    pub default_manufacturer: Option<String>,

    /// Updated default item model number
    #[arg(long = "default-model")]
    pub default_model: Option<String>,

    /// Updated default insured flag (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub default_insured: Option<bool>,

    /// Updated default lifetime warranty flag (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub default_lifetime_warranty: Option<bool>,

    /// Updated default warranty details
    #[arg(long)]
    pub default_warranty_details: Option<String>,

    /// Updated default location name, UUID, or 'none'
    #[arg(long)]
    pub default_location: Option<String>,

    /// Updated default tag name or UUID (repeatable; replaces tag list)
    #[arg(long = "default-tag")]
    pub default_tags: Vec<String>,

    /// Include warranty fields on created items (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub include_warranty_fields: Option<bool>,

    /// Include purchase fields on created items (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub include_purchase_fields: Option<bool>,

    /// Include sold fields on created items (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub include_sold_fields: Option<bool>,

    /// Default custom field KEY=VAL to add/update (repeatable)
    #[arg(long = "field")]
    pub fields: Vec<String>,

    /// Value type for --field entries
    #[arg(long, value_enum, default_value_t = FieldValueType::Text)]
    pub field_type: FieldValueType,
}

#[derive(Args, Debug, Clone)]
pub struct TemplateApplyArgs {
    /// Template UUID
    pub id: String,

    /// Item name (defaults to template's defaultName if omitted)
    #[arg(long)]
    pub name: Option<String>,

    /// Item description (defaults to template's defaultDescription if omitted)
    #[arg(long)]
    pub description: Option<String>,

    /// Parent item/location name, ID, or 'none'
    #[arg(long)]
    pub parent: Option<String>,

    /// Location name or ID (falls back to template's defaultLocation if omitted)
    #[arg(long)]
    pub location: Option<String>,

    /// Entity type name or UUID
    #[arg(long = "type")]
    pub entity_type: Option<String>,

    /// Tag name or UUID (repeatable; defaults to template's defaultTags if omitted)
    #[arg(long = "tag")]
    pub tags: Vec<String>,

    /// Item quantity override
    #[arg(long)]
    pub quantity: Option<f64>,
}

#[derive(Args, Debug, Clone)]
pub struct BarcodeArgs {
    /// Barcode / EAN / UPC string to look up
    #[arg(value_name = "CODE")]
    pub code: String,
}

#[derive(Args, Debug, Clone)]
pub struct NotifierArgs {
    #[command(subcommand)]
    pub command: NotifierCommands,
}

#[derive(Subcommand, Debug, Clone)]
pub enum NotifierCommands {
    /// List configured notifiers (URLs redacted unless --reveal is passed)
    List {
        /// Display unredacted notifier URLs
        #[arg(long)]
        reveal: bool,
    },
    /// Create a new notifier
    Create(NotifierCreateArgs),
    /// Update an existing notifier
    Update(NotifierUpdateArgs),
    /// Delete a notifier
    Delete {
        /// Notifier UUID
        id: String,
        /// Skip interactive confirmation prompt
        #[arg(short = 'y', long = "yes")]
        yes: bool,
        /// Skip interactive confirmation prompt
        #[arg(long)]
        force: bool,
    },
    /// Send a test notification to a notifier ID/name or Shoutrrr URL
    Test {
        /// Notifier ID, name, or Shoutrrr URL
        #[arg(value_name = "ID|URL")]
        target: String,
    },
}

#[derive(Args, Debug, Clone)]
pub struct NotifierCreateArgs {
    /// Notifier display name
    #[arg(long)]
    pub name: String,

    /// Shoutrrr destination URL
    #[arg(
        long = "notifier-url",
        visible_alias = "target",
        value_name = "SHOUTRRR_URL"
    )]
    pub notifier_url: String,

    /// Whether the notifier is active (true/false; bare flag means true, defaults to true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub active: Option<bool>,
}

#[derive(Args, Debug, Clone)]
pub struct NotifierUpdateArgs {
    /// Notifier UUID
    pub id: String,

    /// Updated notifier name
    #[arg(long)]
    pub name: Option<String>,

    /// Updated Shoutrrr destination URL
    #[arg(
        long = "notifier-url",
        visible_alias = "target",
        value_name = "SHOUTRRR_URL"
    )]
    pub notifier_url: Option<String>,

    /// Updated active state (true/false; bare flag means true)
    #[arg(long, num_args = 0..=1, default_missing_value = "true")]
    pub active: Option<bool>,
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
            "hbctl",
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
        let cli = Cli::try_parse_from(["hbctl", "entity-types"]).unwrap();
        assert!(matches!(cli.command, Commands::EntityTypes(_)));

        let cli = Cli::try_parse_from([
            "hbctl",
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

    #[test]
    fn test_cli_parse_crud_gap_commands_and_flags() {
        let cli = Cli::try_parse_from(["hbctl", "field", "list", "ent-1"]).unwrap();
        assert!(matches!(
            cli.command,
            Commands::Field(FieldArgs {
                command: FieldCommands::List { .. }
            })
        ));

        let cli = Cli::try_parse_from(["hbctl", "field", "delete", "ent-1", "Voltage"]).unwrap();
        assert!(matches!(
            cli.command,
            Commands::Field(FieldArgs {
                command: FieldCommands::Delete { .. }
            })
        ));

        let cli = Cli::try_parse_from([
            "hbctl",
            "tag",
            "update",
            "tag-1",
            "--name",
            "Sensors",
            "--description",
            "All sensors",
            "--color",
            "#ff0000",
        ])
        .unwrap();
        assert!(matches!(
            cli.command,
            Commands::Tag(TagArgs {
                command: TagCommands::Update { .. }
            })
        ));

        let cli = Cli::try_parse_from(["hbctl", "tag", "delete", "tag-1", "--force"]).unwrap();
        assert!(matches!(
            cli.command,
            Commands::Tag(TagArgs {
                command: TagCommands::Delete { force: true, .. }
            })
        ));

        let cli = Cli::try_parse_from([
            "hbctl", "item", "create", "--name", "Scope", "--serial", "SN-1",
        ])
        .unwrap();
        match cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Create(a),
            }) => assert_eq!(a.serial.as_deref(), Some("SN-1")),
            other => panic!("unexpected command: {other:?}"),
        }

        let cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "update",
            "ent-1",
            "--add-tag",
            "tools",
            "--remove-tag",
            "legacy",
            "--serial",
            "SN-2",
        ])
        .unwrap();
        match cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Update(a),
            }) => {
                assert_eq!(a.add_tags, vec!["tools"]);
                assert_eq!(a.remove_tags, vec!["legacy"]);
                assert_eq!(a.serial.as_deref(), Some("SN-2"));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let cli = Cli::try_parse_from([
            "hbctl", "item", "upsert", "--name", "Scope", "--serial", "SN-3",
        ])
        .unwrap();
        match cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Upsert(a),
            }) => assert_eq!(a.serial.as_deref(), Some("SN-3")),
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_parse_fill_missing_flags() {
        let cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "update",
            "ent-1",
            "--fill-missing",
            "--description",
            "Desc",
        ])
        .unwrap();
        match cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Update(a),
            }) => assert!(a.fill_missing),
            other => panic!("unexpected command: {other:?}"),
        }

        let cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "upsert",
            "--name",
            "Scope",
            "--fill-missing",
        ])
        .unwrap();
        match cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Upsert(a),
            }) => assert!(a.fill_missing),
            other => panic!("unexpected command: {other:?}"),
        }

        let cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "import",
            "items.json",
            "--update-existing",
            "--fill-missing",
        ])
        .unwrap();
        match cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Import(a),
            }) => {
                assert!(a.update_existing);
                assert!(a.fill_missing);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        assert!(
            Cli::try_parse_from(["hbctl", "item", "import", "items.json", "--fill-missing"])
                .is_err()
        );
        assert!(Cli::try_parse_from([
            "hbctl",
            "item",
            "import",
            "items.json",
            "--skip-existing",
            "--fill-missing",
        ])
        .is_err());
    }

    #[test]
    fn test_cli_parse_match_by_and_upsert_from_json() {
        let cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "upsert",
            "--from-json",
            "item.json",
            "--match-by",
            "serial",
            "--match-by",
            "model",
            "--match-by",
            "field:SKU",
        ])
        .unwrap();
        match cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Upsert(a),
            }) => {
                assert!(a.name.is_none());
                assert_eq!(a.from_json.as_deref(), Some("item.json"));
                assert_eq!(
                    a.match_by,
                    vec![
                        MatchKey::Serial,
                        MatchKey::Model,
                        MatchKey::Field("SKU".into()),
                    ]
                );
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "upsert",
            "--name",
            "Scope",
            "--match-by",
            "serial,model,name",
        ])
        .unwrap();
        match cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Upsert(a),
            }) => {
                assert_eq!(a.name.as_deref(), Some("Scope"));
                assert_eq!(
                    a.match_by,
                    vec![MatchKey::Serial, MatchKey::Model, MatchKey::Name]
                );
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "import",
            "items.json",
            "--update-existing",
            "--match-by",
            "field:Asset Tag",
            "--match-by",
            "name",
        ])
        .unwrap();
        match cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Import(a),
            }) => {
                assert_eq!(
                    a.match_by,
                    vec![MatchKey::Field("Asset Tag".into()), MatchKey::Name]
                );
            }
            other => panic!("unexpected command: {other:?}"),
        }

        assert!(Cli::try_parse_from([
            "hbctl",
            "item",
            "upsert",
            "--name",
            "Scope",
            "--match-by",
            "bogus",
        ])
        .is_err());
        assert!(Cli::try_parse_from([
            "hbctl",
            "item",
            "upsert",
            "--name",
            "Scope",
            "--match-by",
            "field:",
        ])
        .is_err());
    }

    #[test]
    fn test_cli_parse_search_field_filters() {
        let cli = Cli::try_parse_from([
            "hbctl",
            "search",
            "meter",
            "--tag",
            "electronics",
            "--manufacturer",
            "Fluke",
            "--model",
            "87V",
            "--serial",
            "SN-1",
            "--field",
            "ASIN",
            "--field",
            "Order Number=112-99",
        ])
        .unwrap();
        match cli.command {
            Commands::Search(a) => {
                assert!(!a.any);
                assert_eq!(a.query.as_deref(), Some("meter"));
                assert_eq!(a.tag.as_deref(), Some("electronics"));
                assert_eq!(a.manufacturer.as_deref(), Some("Fluke"));
                assert_eq!(a.model.as_deref(), Some("87V"));
                assert_eq!(a.serial.as_deref(), Some("SN-1"));
                assert_eq!(
                    a.fields,
                    vec!["ASIN".to_string(), "Order Number=112-99".to_string()]
                );
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let any_cli = Cli::try_parse_from([
            "hbctl",
            "search",
            "--any",
            "--model",
            "ABC",
            "--field",
            "Notes=B001",
        ])
        .unwrap();
        match any_cli.command {
            Commands::Search(a) => {
                assert!(a.any);
                assert_eq!(a.model.as_deref(), Some("ABC"));
                assert_eq!(a.fields, vec!["Notes=B001".to_string()]);
            }
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_parse_export_columns_align_empty() {
        let cli = Cli::try_parse_from([
            "hbctl",
            "--select",
            "id,name",
            "export",
            "--format",
            "markdown",
            "--columns",
            "name=Container / Item,Tare Weight (g)",
            "--align",
            "right",
            "--empty",
            "—",
        ])
        .unwrap();
        assert_eq!(cli.select, Some(vec!["id".to_string(), "name".to_string()]));
        match cli.command {
            Commands::Export(a) => {
                assert_eq!(a.format, ExportFormat::Markdown);
                assert_eq!(
                    a.columns,
                    vec![
                        "name=Container / Item".to_string(),
                        "Tare Weight (g)".to_string(),
                    ]
                );
                assert_eq!(a.align, MarkdownAlign::Right);
                assert_eq!(a.empty, "—");
            }
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_parse_parent_move_and_tree() {
        let list_cli =
            Cli::try_parse_from(["hbctl", "item", "list", "--parent", "Shelf A"]).unwrap();
        match list_cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::List(a),
            }) => assert_eq!(a.parent.as_deref(), Some("Shelf A")),
            other => panic!("unexpected command: {other:?}"),
        }

        let create_cli = Cli::try_parse_from([
            "hbctl", "item", "create", "--name", "Sensor", "--parent", "Shelf A",
        ])
        .unwrap();
        match create_cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Create(a),
            }) => assert_eq!(a.parent.as_deref(), Some("Shelf A")),
            other => panic!("unexpected command: {other:?}"),
        }

        let update_cli =
            Cli::try_parse_from(["hbctl", "item", "update", "ent-1", "--parent", "none"]).unwrap();
        match update_cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Update(a),
            }) => assert_eq!(a.parent.as_deref(), Some("none")),
            other => panic!("unexpected command: {other:?}"),
        }

        let upsert_cli = Cli::try_parse_from([
            "hbctl", "item", "upsert", "--name", "Sensor", "--parent", "Bin 1",
        ])
        .unwrap();
        match upsert_cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Upsert(a),
            }) => assert_eq!(a.parent.as_deref(), Some("Bin 1")),
            other => panic!("unexpected command: {other:?}"),
        }

        let import_cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "import",
            "items.json",
            "--parent",
            "Garage",
        ])
        .unwrap();
        match import_cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Import(a),
            }) => assert_eq!(a.parent.as_deref(), Some("Garage")),
            other => panic!("unexpected command: {other:?}"),
        }

        let move_cli = Cli::try_parse_from(["hbctl", "item", "move", "ent-1", "Garage"]).unwrap();
        match move_cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Move(a),
            }) => {
                assert_eq!(
                    a.split_targets_and_destination().unwrap(),
                    (vec!["ent-1".to_string()], "Garage".to_string())
                );
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let tree_cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "tree",
            "--root",
            "Garage",
            "--max-depth",
            "2",
        ])
        .unwrap();
        match tree_cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Tree(a),
            }) => {
                assert_eq!(a.root.as_deref(), Some("Garage"));
                assert_eq!(a.max_depth, Some(2));
            }
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_parse_attach_and_upload_name_stdin() {
        let create_cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "create",
            "--name",
            "Board",
            "--attach",
            "photo.jpg",
            "--attach",
            "/tmp/manual_compressed.pdf=Manual.pdf",
            "--attach-url",
            "https://example.com/spec.pdf=Spec.pdf",
            "--attach-best-effort",
            "--optimize",
            "--force",
        ])
        .unwrap();
        match create_cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Create(a),
            }) => {
                assert_eq!(
                    a.attach,
                    vec![
                        "photo.jpg".to_string(),
                        "/tmp/manual_compressed.pdf=Manual.pdf".to_string()
                    ]
                );
                assert_eq!(
                    a.attach_url,
                    vec!["https://example.com/spec.pdf=Spec.pdf".to_string()]
                );
                assert!(a.attach_best_effort);
                assert!(a.optimize);
                assert!(a.force);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let upsert_cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "upsert",
            "--name",
            "Board",
            "--attach",
            "photo.jpg=Main.jpg",
            "--attach-url",
            "https://example.com/pic.png",
            "--attach-best-effort",
            "--optimize",
            "--force",
        ])
        .unwrap();
        match upsert_cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Upsert(a),
            }) => {
                assert_eq!(a.attach, vec!["photo.jpg=Main.jpg".to_string()]);
                assert_eq!(
                    a.attach_url,
                    vec!["https://example.com/pic.png".to_string()]
                );
                assert!(a.attach_best_effort);
                assert!(a.optimize);
                assert!(a.force);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let import_cli = Cli::try_parse_from([
            "hbctl",
            "item",
            "import",
            "items.json",
            "--attach",
            "invoice.pdf=Receipt.pdf",
            "--optimize",
            "--force",
        ])
        .unwrap();
        match import_cli.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Import(a),
            }) => {
                assert_eq!(a.attach, vec!["invoice.pdf=Receipt.pdf".to_string()]);
                assert!(a.optimize);
                assert!(a.force);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let upload_url_cli = Cli::try_parse_from([
            "hbctl",
            "attachment",
            "upload",
            "ent-1",
            "--attach-url",
            "https://example.com/a.jpg=Item.jpg",
        ])
        .unwrap();
        match upload_url_cli.command {
            Commands::Attachment(AttachmentArgs {
                command: AttachmentCommands::Upload(a),
            }) => {
                assert!(a.files.is_empty());
                assert_eq!(
                    a.attach_url,
                    vec!["https://example.com/a.jpg=Item.jpg".to_string()]
                );
            }
            other => panic!("unexpected command: {other:?}"),
        }

        assert!(Cli::try_parse_from(["hbctl", "attachment", "upload", "ent-1"]).is_err());

        let upload_cli = Cli::try_parse_from([
            "hbctl",
            "attachment",
            "upload",
            "ent-1",
            "-",
            "--name",
            "receipt.pdf",
            "--optimize",
        ])
        .unwrap();
        match upload_cli.command {
            Commands::Attachment(AttachmentArgs {
                command: AttachmentCommands::Upload(a),
            }) => {
                assert_eq!(a.item_id, "ent-1");
                assert_eq!(a.files, vec![PathBuf::from("-")]);
                assert_eq!(a.name.as_deref(), Some("receipt.pdf"));
                assert!(a.optimize);
            }
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_parse_bulk_attachment_download() {
        let all_cli = Cli::try_parse_from([
            "hbctl",
            "attachment",
            "download",
            "--all-items",
            "--ext",
            "pdf",
            "--out",
            "./dir",
        ])
        .unwrap();
        match all_cli.command {
            Commands::Attachment(AttachmentArgs {
                command: AttachmentCommands::Download(a),
            }) => {
                assert!(a.item_id.is_none());
                assert!(a.attachment_id.is_none());
                assert!(a.all_items);
                assert_eq!(a.ext.as_deref(), Some("pdf"));
                assert_eq!(a.out, Some(PathBuf::from("./dir")));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let tag_cli = Cli::try_parse_from([
            "hbctl",
            "attachment",
            "download",
            "--tag",
            "appliances",
            "--mime",
            "application/pdf",
            "--overwrite",
        ])
        .unwrap();
        match tag_cli.command {
            Commands::Attachment(AttachmentArgs {
                command: AttachmentCommands::Download(a),
            }) => {
                assert!(a.item_id.is_none());
                assert_eq!(a.tag.as_deref(), Some("appliances"));
                assert_eq!(a.mime.as_deref(), Some("application/pdf"));
                assert!(a.overwrite);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let file_cli =
            Cli::try_parse_from(["hbctl", "attachment", "download", "--items-from", "ids.txt"])
                .unwrap();
        match file_cli.command {
            Commands::Attachment(AttachmentArgs {
                command: AttachmentCommands::Download(a),
            }) => {
                assert!(a.item_id.is_none());
                assert_eq!(a.items_from, Some(PathBuf::from("ids.txt")));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let stdin_cli =
            Cli::try_parse_from(["hbctl", "attachment", "download", "--items-from", "-"]).unwrap();
        match stdin_cli.command {
            Commands::Attachment(AttachmentArgs {
                command: AttachmentCommands::Download(a),
            }) => {
                assert!(a.item_id.is_none());
                assert_eq!(a.items_from, Some(PathBuf::from("-")));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        // Parse-time conflict rejections
        assert!(
            Cli::try_parse_from(["hbctl", "attachment", "download", "ent-1", "--all-items"])
                .is_err()
        );
        assert!(Cli::try_parse_from([
            "hbctl",
            "attachment",
            "download",
            "--all-items",
            "--tag",
            "x"
        ])
        .is_err());
        assert!(Cli::try_parse_from([
            "hbctl",
            "attachment",
            "download",
            "--tag",
            "x",
            "--items-from",
            "ids.txt"
        ])
        .is_err());
        assert!(Cli::try_parse_from([
            "hbctl",
            "attachment",
            "download",
            "ent-1",
            "--items-from",
            "ids.txt"
        ])
        .is_err());
    }

    #[test]
    fn test_cli_parse_status_and_entity_types_crud() {
        let status_cli = Cli::try_parse_from(["hbctl", "status"]).unwrap();
        assert!(matches!(status_cli.command, Commands::Status));

        let bare_et = Cli::try_parse_from(["hbctl", "entity-types"]).unwrap();
        match bare_et.command {
            Commands::EntityTypes(EntityTypeArgs { command }) => assert!(command.is_none()),
            other => panic!("unexpected command: {other:?}"),
        }

        let list_et = Cli::try_parse_from(["hbctl", "entity-types", "list"]).unwrap();
        match list_et.command {
            Commands::EntityTypes(EntityTypeArgs { command }) => {
                assert!(matches!(command, Some(EntityTypeCommands::List)));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let create_et = Cli::try_parse_from([
            "hbctl",
            "entity-types",
            "create",
            "Bin",
            "--description",
            "Container",
            "--is-location",
        ])
        .unwrap();
        match create_et.command {
            Commands::EntityTypes(EntityTypeArgs {
                command:
                    Some(EntityTypeCommands::Create {
                        name,
                        description,
                        is_location,
                    }),
            }) => {
                assert_eq!(name, "Bin");
                assert_eq!(description.as_deref(), Some("Container"));
                assert!(is_location);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let delete_et =
            Cli::try_parse_from(["hbctl", "entity-types", "delete", "et-1", "--force"]).unwrap();
        match delete_et.command {
            Commands::EntityTypes(EntityTypeArgs {
                command: Some(EntityTypeCommands::Delete { id, force }),
            }) => {
                assert_eq!(id, "et-1");
                assert!(force);
            }
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_parse_profile_flag() {
        let before =
            Cli::try_parse_from(["hbctl", "--profile", "staging", "item", "list"]).unwrap();
        assert_eq!(before.profile.as_deref(), Some("staging"));
        assert_eq!(
            before.config_overrides().profile.as_deref(),
            Some("staging")
        );

        let after = Cli::try_parse_from(["hbctl", "auth", "status", "-P", "homelab"]).unwrap();
        assert_eq!(after.profile.as_deref(), Some("homelab"));
    }

    #[test]
    fn test_cli_parse_match_mode_and_on_match() {
        let default_upsert =
            Cli::try_parse_from(["hbctl", "item", "upsert", "--name", "Lock"]).unwrap();
        match default_upsert.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Upsert(a),
            }) => {
                assert_eq!(a.match_mode, MatchMode::Exact);
                assert_eq!(a.on_match, OnMatchAction::Update);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        for (mode_arg, mode_val) in [
            ("exact", MatchMode::Exact),
            ("contains", MatchMode::Contains),
            ("fuzzy", MatchMode::Fuzzy),
        ] {
            for (action_arg, action_val) in [
                ("update", OnMatchAction::Update),
                ("skip", OnMatchAction::Skip),
                ("attach-only", OnMatchAction::AttachOnly),
            ] {
                let parsed = Cli::try_parse_from([
                    "hbctl",
                    "item",
                    "upsert",
                    "--name",
                    "Lock",
                    "--match-mode",
                    mode_arg,
                    "--on-match",
                    action_arg,
                ])
                .unwrap();
                match parsed.command {
                    Commands::Item(ItemArgs {
                        command: ItemCommands::Upsert(a),
                    }) => {
                        assert_eq!(a.match_mode, mode_val);
                        assert_eq!(a.on_match, action_val);
                    }
                    other => panic!("unexpected command: {other:?}"),
                }
            }
        }

        let import_default =
            Cli::try_parse_from(["hbctl", "item", "import", "items.json"]).unwrap();
        match import_default.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Import(a),
            }) => assert_eq!(a.match_mode, MatchMode::Exact),
            other => panic!("unexpected command: {other:?}"),
        }

        let import_fuzzy = Cli::try_parse_from([
            "hbctl",
            "item",
            "import",
            "items.json",
            "--match-mode",
            "fuzzy",
        ])
        .unwrap();
        match import_fuzzy.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Import(a),
            }) => assert_eq!(a.match_mode, MatchMode::Fuzzy),
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_parse_api_command() {
        let cli = Cli::try_parse_from([
            "hbctl",
            "--json",
            "--select",
            "id,name",
            "--dry-run",
            "api",
            "POST",
            "/api/v1/maintenance",
            "--query",
            "status=both",
            "--query",
            "limit=10",
            "--data",
            r#"{"name":"Filter"}"#,
        ])
        .unwrap();
        assert!(cli.json);
        assert!(cli.dry_run);
        assert_eq!(cli.select, Some(vec!["id".to_string(), "name".to_string()]));
        match cli.command {
            Commands::Api(a) => {
                assert_eq!(a.method, "POST");
                assert_eq!(a.path, "/api/v1/maintenance");
                assert_eq!(a.query, vec!["status=both", "limit=10"]);
                assert_eq!(a.data.as_deref(), Some(r#"{"name":"Filter"}"#));
                assert_eq!(a.from_json, None);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let from_stdin =
            Cli::try_parse_from(["hbctl", "api", "PUT", "templates/t1", "--from-json", "-"])
                .unwrap();
        match from_stdin.command {
            Commands::Api(a) => {
                assert_eq!(a.method, "PUT");
                assert_eq!(a.path, "templates/t1");
                assert_eq!(a.from_json.as_deref(), Some("-"));
                assert_eq!(a.data, None);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        // `--data` and `--from-json` conflict
        assert!(Cli::try_parse_from([
            "hbctl",
            "api",
            "POST",
            "groups",
            "--data",
            "{}",
            "--from-json",
            "body.json",
        ])
        .is_err());
    }

    #[test]
    fn test_cli_parse_maintenance_commands() {
        let list_default = Cli::try_parse_from(["hbctl", "maintenance", "list"]).unwrap();
        match list_default.command {
            Commands::Maintenance(MaintenanceArgs {
                command: MaintenanceCommands::List { entity, status },
            }) => {
                assert_eq!(entity, None);
                assert_eq!(status, MaintenanceStatus::Both);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let list_filtered = Cli::try_parse_from([
            "hbctl",
            "maintenance",
            "list",
            "ent-1",
            "--status",
            "scheduled",
        ])
        .unwrap();
        match list_filtered.command {
            Commands::Maintenance(MaintenanceArgs {
                command: MaintenanceCommands::List { entity, status },
            }) => {
                assert_eq!(entity.as_deref(), Some("ent-1"));
                assert_eq!(status, MaintenanceStatus::Scheduled);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let create = Cli::try_parse_from([
            "hbctl",
            "maintenance",
            "create",
            "ent-1",
            "--name",
            "Filter Swap",
            "--completed-date",
            "2026-11-27",
            "--scheduled-date",
            "2027-05-27",
            "--cost",
            "$29.99",
            "--description",
            "MERV 13",
        ])
        .unwrap();
        match create.command {
            Commands::Maintenance(MaintenanceArgs {
                command: MaintenanceCommands::Create(a),
            }) => {
                assert_eq!(a.entity, "ent-1");
                assert_eq!(a.name, "Filter Swap");
                assert_eq!(a.completed_date.as_deref(), Some("2026-11-27"));
                assert_eq!(a.scheduled_date.as_deref(), Some("2027-05-27"));
                assert_eq!(a.cost.as_deref(), Some("$29.99"));
                assert_eq!(a.description.as_deref(), Some("MERV 13"));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let update = Cli::try_parse_from([
            "hbctl",
            "maintenance",
            "update",
            "m-1",
            "--name",
            "Renamed",
            "--cost",
            "15.50",
        ])
        .unwrap();
        match update.command {
            Commands::Maintenance(MaintenanceArgs {
                command: MaintenanceCommands::Update(a),
            }) => {
                assert_eq!(a.entry_id, "m-1");
                assert_eq!(a.name.as_deref(), Some("Renamed"));
                assert_eq!(a.cost.as_deref(), Some("15.50"));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let del =
            Cli::try_parse_from(["hbctl", "maintenance", "delete", "m-1", "--force"]).unwrap();
        match del.command {
            Commands::Maintenance(MaintenanceArgs {
                command: MaintenanceCommands::Delete { entry_id, force },
            }) => {
                assert_eq!(entry_id, "m-1");
                assert!(force);
            }
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_enum_display_and_maintenance_status_as_str() {
        assert_eq!(MatchKey::Name.to_string(), "name");
        assert_eq!(MatchKey::Model.to_string(), "model");
        assert_eq!(MatchKey::Serial.to_string(), "serial");
        assert_eq!(MatchKey::Field("Volt".into()).to_string(), "field:Volt");
        assert!("field:".parse::<MatchKey>().is_err());

        assert_eq!(MatchMode::Exact.to_string(), "exact");
        assert_eq!(MatchMode::Contains.to_string(), "contains");
        assert_eq!(MatchMode::Fuzzy.to_string(), "fuzzy");

        assert_eq!(OnMatchAction::Update.to_string(), "update");
        assert_eq!(OnMatchAction::Skip.to_string(), "skip");
        assert_eq!(OnMatchAction::AttachOnly.to_string(), "attach-only");

        assert_eq!(MaintenanceStatus::Both.as_str(), "both");
        assert_eq!(MaintenanceStatus::Completed.as_str(), "completed");
        assert_eq!(MaintenanceStatus::Scheduled.as_str(), "scheduled");
    }

    #[test]
    fn test_cli_parse_warranty_archived_sold_search_and_export_sort() {
        let create = Cli::try_parse_from([
            "hbctl",
            "item",
            "create",
            "--name",
            "Router",
            "--archived",
            "--insured=false",
            "--lifetime-warranty",
            "--warranty-expires",
            "2028-01-01",
            "--warranty-details",
            "3-year",
            "--sold-time",
            "2026-11-01",
            "--sold-to",
            "Bob",
            "--sold-price",
            "99.5",
            "--sold-notes",
            "Local pickup",
        ])
        .unwrap();
        match create.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Create(a),
            }) => {
                assert_eq!(a.archived, Some(true));
                assert_eq!(a.insured, Some(false));
                assert_eq!(a.lifetime_warranty, Some(true));
                assert_eq!(a.warranty_expires.as_deref(), Some("2028-01-01"));
                assert_eq!(a.warranty_details.as_deref(), Some("3-year"));
                assert_eq!(a.sold_time.as_deref(), Some("2026-11-01"));
                assert_eq!(a.sold_to.as_deref(), Some("Bob"));
                assert_eq!(a.sold_price, Some(99.5));
                assert_eq!(a.sold_notes.as_deref(), Some("Local pickup"));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let update = Cli::try_parse_from([
            "hbctl",
            "item",
            "update",
            "ent-1",
            "--archived",
            "false",
            "--insured",
        ])
        .unwrap();
        match update.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Update(a),
            }) => {
                assert_eq!(a.archived, Some(false));
                assert_eq!(a.insured, Some(true));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let upsert = Cli::try_parse_from([
            "hbctl",
            "item",
            "upsert",
            "--name",
            "NAS",
            "--archived=true",
            "--warranty-expires",
            "2027-05-01",
        ])
        .unwrap();
        match upsert.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Upsert(a),
            }) => {
                assert_eq!(a.archived, Some(true));
                assert_eq!(a.warranty_expires.as_deref(), Some("2027-05-01"));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let list = Cli::try_parse_from([
            "hbctl",
            "item",
            "list",
            "--include-archived",
            "--archived-only",
            "--warranty-expiring",
            "30",
        ])
        .unwrap();
        match list.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::List(a),
            }) => {
                assert!(a.include_archived);
                assert!(a.archived_only);
                assert_eq!(a.warranty_expiring, Some(30));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let search = Cli::try_parse_from([
            "hbctl",
            "search",
            "drill",
            "--parent",
            "Garage",
            "--type",
            "Item",
            "--limit",
            "5",
            "--include-archived",
            "--warranty-expiring",
            "14",
        ])
        .unwrap();
        match search.command {
            Commands::Search(a) => {
                assert_eq!(a.query.as_deref(), Some("drill"));
                assert_eq!(a.parent.as_deref(), Some("Garage"));
                assert_eq!(a.entity_type.as_deref(), Some("Item"));
                assert_eq!(a.limit, Some(5));
                assert!(a.include_archived);
                assert!(!a.archived_only);
                assert_eq!(a.warranty_expiring, Some(14));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        for (raw, expected) in [
            ("name", ExportSort::Name),
            ("id", ExportSort::Id),
            ("purchase-price", ExportSort::PurchasePrice),
            ("purchase-date", ExportSort::PurchaseDate),
            ("updated-at", ExportSort::UpdatedAt),
            ("asset-id", ExportSort::AssetId),
        ] {
            let exp = Cli::try_parse_from(["hbctl", "export", "--sort", raw]).unwrap();
            match exp.command {
                Commands::Export(a) => assert_eq!(a.sort, expected),
                other => panic!("unexpected command: {other:?}"),
            }
        }
    }

    #[test]
    fn test_cli_parse_wave2_bulk_duplicate_and_path() {
        let upd = Cli::try_parse_from([
            "hbctl",
            "item",
            "update",
            "ent-1",
            "ent-2",
            "--items-from",
            "-",
            "--filter-tag",
            "tools",
            "--filter-parent",
            "Garage",
            "--filter-type",
            "Item",
            "--tag",
            "new-tag",
            "--archived",
        ])
        .unwrap();
        match upd.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Update(a),
            }) => {
                assert_eq!(a.ids, vec!["ent-1", "ent-2"]);
                assert_eq!(a.items_from, Some(PathBuf::from("-")));
                assert_eq!(a.filter_tag.as_deref(), Some("tools"));
                assert_eq!(a.filter_parent.as_deref(), Some("Garage"));
                assert_eq!(a.filter_type.as_deref(), Some("Item"));
                assert_eq!(a.tags, vec!["new-tag"]);
                assert_eq!(a.archived, Some(true));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let mv_multi =
            Cli::try_parse_from(["hbctl", "item", "move", "ent-1", "ent-2", "--to", "Garage"])
                .unwrap();
        match mv_multi.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Move(a),
            }) => {
                assert_eq!(
                    a.split_targets_and_destination().unwrap(),
                    (
                        vec!["ent-1".to_string(), "ent-2".to_string()],
                        "Garage".to_string()
                    )
                );
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let mv_sel =
            Cli::try_parse_from(["hbctl", "item", "move", "--tag", "tools", "--to", "none"])
                .unwrap();
        match mv_sel.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Move(a),
            }) => {
                assert_eq!(a.tag.as_deref(), Some("tools"));
                assert_eq!(
                    a.split_targets_and_destination().unwrap(),
                    (Vec::<String>::new(), "none".to_string())
                );
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let mv_missing_dest =
            Cli::try_parse_from(["hbctl", "item", "move", "--tag", "tools"]).unwrap();
        match mv_missing_dest.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Move(a),
            }) => assert!(a.split_targets_and_destination().is_err()),
            other => panic!("unexpected command: {other:?}"),
        }

        let del = Cli::try_parse_from([
            "hbctl",
            "item",
            "delete",
            "ent-1",
            "ent-2",
            "--items-from",
            "ids.txt",
            "--filter-tag",
            "old",
            "-y",
        ])
        .unwrap();
        match del.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Delete(a),
            }) => {
                assert_eq!(a.ids, vec!["ent-1", "ent-2"]);
                assert_eq!(a.items_from, Some(PathBuf::from("ids.txt")));
                assert_eq!(a.tag.as_deref(), Some("old"));
                assert!(a.yes);
                assert!(a.skip_confirm());
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let dup =
            Cli::try_parse_from(["hbctl", "item", "duplicate", "ent-1", "--count", "3"]).unwrap();
        match dup.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Duplicate(a),
            }) => {
                assert_eq!(a.id, "ent-1");
                assert_eq!(a.count, 3);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let path = Cli::try_parse_from(["hbctl", "item", "path", "ent-1"]).unwrap();
        match path.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Path(a),
            }) => assert_eq!(a.id, "ent-1"),
            other => panic!("unexpected command: {other:?}"),
        }

        let get_wp = Cli::try_parse_from(["hbctl", "item", "get", "ent-1", "--with-path"]).unwrap();
        match get_wp.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Get(a),
            }) => assert!(a.with_path),
            other => panic!("unexpected command: {other:?}"),
        }

        let search_wp = Cli::try_parse_from(["hbctl", "search", "drill", "--with-path"]).unwrap();
        match search_wp.command {
            Commands::Search(a) => assert!(a.with_path),
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_parse_wave3_asset_label_qr_actions_and_attachments() {
        let with_asset =
            Cli::try_parse_from(["hbctl", "--asset-id", "item", "get", "000-001"]).unwrap();
        assert!(with_asset.asset_id);

        let label = Cli::try_parse_from([
            "hbctl",
            "label",
            "000-001",
            "--kind",
            "asset",
            "--out",
            "label.png",
            "--overwrite",
        ])
        .unwrap();
        match label.command {
            Commands::Label(a) => {
                assert_eq!(a.id, "000-001");
                assert_eq!(a.kind, LabelTargetKind::Asset);
                assert_eq!(a.out, Some(PathBuf::from("label.png")));
                assert!(a.overwrite);
                assert!(!a.print);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let label_print = Cli::try_parse_from(["hbctl", "label", "ent-1", "--print"]).unwrap();
        match label_print.command {
            Commands::Label(a) => assert!(a.print),
            other => panic!("unexpected command: {other:?}"),
        }

        assert!(
            Cli::try_parse_from(["hbctl", "label", "ent-1", "--print", "--out", "a.png"]).is_err()
        );

        let qr = Cli::try_parse_from(["hbctl", "qr", "000-001", "--raw", "-o", "qr.jpg"]).unwrap();
        match qr.command {
            Commands::Qr(a) => {
                assert_eq!(a.id, "000-001");
                assert!(a.raw);
                assert_eq!(a.out, Some(PathBuf::from("qr.jpg")));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let act1 = Cli::try_parse_from(["hbctl", "actions", "ensure-asset-ids"]).unwrap();
        assert!(matches!(
            act1.command,
            Commands::Actions(ActionsArgs {
                command: ActionsCommands::EnsureAssetIds
            })
        ));

        let act2 = Cli::try_parse_from(["hbctl", "action", "create-missing-thumbnails"]).unwrap();
        assert!(matches!(
            act2.command,
            Commands::Actions(ActionsArgs {
                command: ActionsCommands::CreateMissingThumbnails
            })
        ));

        let up = Cli::try_parse_from([
            "hbctl",
            "attachment",
            "upload",
            "ent-1",
            "photo.jpg",
            "--primary",
        ])
        .unwrap();
        match up.command {
            Commands::Attachment(AttachmentArgs {
                command: AttachmentCommands::Upload(a),
            }) => assert!(a.primary),
            other => panic!("unexpected command: {other:?}"),
        }

        let sp =
            Cli::try_parse_from(["hbctl", "attachment", "set-primary", "ent-1", "att-2"]).unwrap();
        match sp.command {
            Commands::Attachment(AttachmentArgs {
                command: AttachmentCommands::SetPrimary(a),
            }) => {
                assert_eq!(a.item_id, "ent-1");
                assert_eq!(a.attachment_id, "att-2");
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let upd = Cli::try_parse_from([
            "hbctl",
            "attachment",
            "update",
            "ent-1",
            "att-2",
            "--title",
            "Front View",
            "--type",
            "photo",
            "--primary",
        ])
        .unwrap();
        match upd.command {
            Commands::Attachment(AttachmentArgs {
                command: AttachmentCommands::Update(a),
            }) => {
                assert_eq!(a.title.as_deref(), Some("Front View"));
                assert_eq!(a.attachment_type.as_deref(), Some("photo"));
                assert_eq!(a.primary, Some(true));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let link = Cli::try_parse_from([
            "hbctl",
            "attachment",
            "add-link",
            "ent-1",
            "https://example.com/manual.pdf",
            "--title",
            "Manual",
            "--type",
            "manual",
        ])
        .unwrap();
        match link.command {
            Commands::Attachment(AttachmentArgs {
                command: AttachmentCommands::AddLink(a),
            }) => {
                assert_eq!(a.link, "https://example.com/manual.pdf");
                assert_eq!(a.title.as_deref(), Some("Manual"));
                assert_eq!(a.attachment_type.as_deref(), Some("manual"));
            }
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_parse_wave4_stats_config_and_output_formats() {
        let csv_out = Cli::try_parse_from(["hbctl", "--output", "csv", "stats"]).unwrap();
        assert_eq!(csv_out.output, Some(OutputFormat::Csv));
        assert!(matches!(
            csv_out.command,
            Commands::Stats(StatsArgs {
                warranty_days: None,
                command: None
            })
        ));

        let md_alias =
            Cli::try_parse_from(["hbctl", "--output", "md", "stats", "--warranty-days", "30"])
                .unwrap();
        assert_eq!(md_alias.output, Some(OutputFormat::Markdown));
        assert!(matches!(
            md_alias.command,
            Commands::Stats(StatsArgs {
                warranty_days: Some(30),
                command: None
            })
        ));

        let stats_ov = Cli::try_parse_from(["hbctl", "stats", "overview"]).unwrap();
        assert!(matches!(
            stats_ov.command,
            Commands::Stats(StatsArgs {
                command: Some(StatsCommands::Overview),
                ..
            })
        ));

        let stats_tags = Cli::try_parse_from(["hbctl", "stats", "tags"]).unwrap();
        assert!(matches!(
            stats_tags.command,
            Commands::Stats(StatsArgs {
                command: Some(StatsCommands::Tags),
                ..
            })
        ));

        let stats_locs = Cli::try_parse_from(["hbctl", "stats", "locations"]).unwrap();
        assert!(matches!(
            stats_locs.command,
            Commands::Stats(StatsArgs {
                command: Some(StatsCommands::Locations),
                ..
            })
        ));

        let stats_types = Cli::try_parse_from(["hbctl", "stats", "types"]).unwrap();
        assert!(matches!(
            stats_types.command,
            Commands::Stats(StatsArgs {
                command: Some(StatsCommands::EntityTypes),
                ..
            })
        ));

        let stats_pp = Cli::try_parse_from([
            "hbctl",
            "stats",
            "price",
            "--start",
            "2026-01-01",
            "--end",
            "2026-11-27",
        ])
        .unwrap();
        match stats_pp.command {
            Commands::Stats(StatsArgs {
                command: Some(StatsCommands::PurchasePrice { start, end }),
                ..
            }) => {
                assert_eq!(start.as_deref(), Some("2026-01-01"));
                assert_eq!(end.as_deref(), Some("2026-11-27"));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let cfg_show = Cli::try_parse_from(["hbctl", "config", "show"]).unwrap();
        assert!(matches!(
            cfg_show.command,
            Commands::Config(ConfigArgs {
                command: ConfigCommands::Show
            })
        ));

        let cfg_profiles = Cli::try_parse_from(["hbctl", "config", "profiles"]).unwrap();
        assert!(matches!(
            cfg_profiles.command,
            Commands::Config(ConfigArgs {
                command: ConfigCommands::Profiles
            })
        ));

        let cfg_use = Cli::try_parse_from(["hbctl", "config", "use", "staging"]).unwrap();
        match cfg_use.command {
            Commands::Config(ConfigArgs {
                command: ConfigCommands::Use { profile },
            }) => assert_eq!(profile, "staging"),
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_parse_wave5_template_barcode_and_notifier() {
        let tpl_list = Cli::try_parse_from(["hbctl", "template", "list"]).unwrap();
        assert!(matches!(
            tpl_list.command,
            Commands::Template(TemplateArgs {
                command: TemplateCommands::List
            })
        ));

        let tpl_get = Cli::try_parse_from(["hbctl", "templates", "get", "tpl-1"]).unwrap();
        assert!(matches!(
            tpl_get.command,
            Commands::Template(TemplateArgs {
                command: TemplateCommands::Get { .. }
            })
        ));

        let tpl_create = Cli::try_parse_from([
            "hbctl",
            "template",
            "create",
            "--name",
            "Power Tool",
            "--default-name",
            "Drill",
            "--default-quantity",
            "2",
            "--default-insured",
            "--default-tag",
            "tools",
            "--field",
            "Voltage=20V",
        ])
        .unwrap();
        match tpl_create.command {
            Commands::Template(TemplateArgs {
                command: TemplateCommands::Create(a),
            }) => {
                assert_eq!(a.name, "Power Tool");
                assert_eq!(a.default_name.as_deref(), Some("Drill"));
                assert_eq!(a.default_quantity, Some(2.0));
                assert_eq!(a.default_insured, Some(true));
                assert_eq!(a.default_tags, vec!["tools"]);
                assert_eq!(a.fields, vec!["Voltage=20V"]);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let tpl_update = Cli::try_parse_from([
            "hbctl",
            "template",
            "update",
            "tpl-1",
            "--default-model",
            "DCD771",
            "--include-warranty-fields",
            "false",
        ])
        .unwrap();
        match tpl_update.command {
            Commands::Template(TemplateArgs {
                command: TemplateCommands::Update(a),
            }) => {
                assert_eq!(a.id, "tpl-1");
                assert_eq!(a.default_model.as_deref(), Some("DCD771"));
                assert_eq!(a.include_warranty_fields, Some(false));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let tpl_del =
            Cli::try_parse_from(["hbctl", "template", "delete", "tpl-1", "--yes"]).unwrap();
        assert!(matches!(
            tpl_del.command,
            Commands::Template(TemplateArgs {
                command: TemplateCommands::Delete { yes: true, .. }
            })
        ));

        let tpl_apply = Cli::try_parse_from([
            "hbctl",
            "template",
            "apply",
            "tpl-1",
            "--name",
            "Router",
            "--location",
            "Office",
            "--quantity",
            "3",
        ])
        .unwrap();
        match tpl_apply.command {
            Commands::Template(TemplateArgs {
                command: TemplateCommands::Apply(a),
            }) => {
                assert_eq!(a.id, "tpl-1");
                assert_eq!(a.name.as_deref(), Some("Router"));
                assert_eq!(a.location.as_deref(), Some("Office"));
                assert_eq!(a.quantity, Some(3.0));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let barcode = Cli::try_parse_from(["hbctl", "barcode", "5035048748428"]).unwrap();
        match barcode.command {
            Commands::Barcode(a) => assert_eq!(a.code, "5035048748428"),
            other => panic!("unexpected command: {other:?}"),
        }

        let item_bar = Cli::try_parse_from([
            "hbctl",
            "item",
            "create",
            "--from-barcode",
            "5035048748428",
            "--name",
            "Override Name",
        ])
        .unwrap();
        match item_bar.command {
            Commands::Item(ItemArgs {
                command: ItemCommands::Create(a),
            }) => {
                assert_eq!(a.from_barcode.as_deref(), Some("5035048748428"));
                assert_eq!(a.name.as_deref(), Some("Override Name"));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let not_list = Cli::try_parse_from(["hbctl", "notifier", "list", "--reveal"]).unwrap();
        assert!(matches!(
            not_list.command,
            Commands::Notifier(NotifierArgs {
                command: NotifierCommands::List { reveal: true }
            })
        ));

        let not_create = Cli::try_parse_from([
            "hbctl",
            "--url",
            "http://127.0.0.1:7745",
            "notifiers",
            "create",
            "--name",
            "Discord",
            "--notifier-url",
            "discord://tok@123",
            "--active=false",
        ])
        .unwrap();
        assert_eq!(not_create.url.as_deref(), Some("http://127.0.0.1:7745"));
        match not_create.command {
            Commands::Notifier(NotifierArgs {
                command: NotifierCommands::Create(a),
            }) => {
                assert_eq!(a.name, "Discord");
                assert_eq!(a.notifier_url, "discord://tok@123");
                assert_eq!(a.active, Some(false));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let not_update = Cli::try_parse_from([
            "hbctl",
            "notifier",
            "update",
            "not-1",
            "--name",
            "Renamed",
            "--target",
            "ntfy://ntfy.sh/alerts",
            "--active",
        ])
        .unwrap();
        match not_update.command {
            Commands::Notifier(NotifierArgs {
                command: NotifierCommands::Update(a),
            }) => {
                assert_eq!(a.id, "not-1");
                assert_eq!(a.name.as_deref(), Some("Renamed"));
                assert_eq!(a.notifier_url.as_deref(), Some("ntfy://ntfy.sh/alerts"));
                assert_eq!(a.active, Some(true));
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let not_del = Cli::try_parse_from(["hbctl", "notifier", "delete", "not-1", "-y"]).unwrap();
        assert!(matches!(
            not_del.command,
            Commands::Notifier(NotifierArgs {
                command: NotifierCommands::Delete { yes: true, .. }
            })
        ));

        let not_test =
            Cli::try_parse_from(["hbctl", "notifier", "test", "discord://tok@123"]).unwrap();
        match not_test.command {
            Commands::Notifier(NotifierArgs {
                command: NotifierCommands::Test { target },
            }) => assert_eq!(target, "discord://tok@123"),
            other => panic!("unexpected command: {other:?}"),
        }
    }

    #[test]
    fn test_cli_parse_wave6_backup() {
        let basic = Cli::try_parse_from(["hbctl", "backup", "--out", "./bk"]).unwrap();
        match basic.command {
            Commands::Backup(args) => {
                assert_eq!(args.out, PathBuf::from("./bk"));
                assert!(!args.no_attachments);
                assert!(!args.exclude_archived);
                assert!(!args.overwrite);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        let full = Cli::try_parse_from([
            "hbctl",
            "--dry-run",
            "--json",
            "backup",
            "-o",
            "/tmp/inv.tar.gz",
            "--no-attachments",
            "--exclude-archived",
            "--overwrite",
        ])
        .unwrap();
        assert!(full.dry_run);
        assert!(full.json);
        match full.command {
            Commands::Backup(args) => {
                assert_eq!(args.out, PathBuf::from("/tmp/inv.tar.gz"));
                assert!(args.no_attachments);
                assert!(args.exclude_archived);
                assert!(args.overwrite);
            }
            other => panic!("unexpected command: {other:?}"),
        }

        assert!(Cli::try_parse_from(["hbctl", "backup"]).is_err());
    }
}

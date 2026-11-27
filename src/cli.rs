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

    /// Output format (table, json, plain) [env: HBCTL_OUTPUT]
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

    /// Custom field KEY=VAL (repeatable)
    #[arg(long = "field")]
    pub fields: Vec<String>,

    /// Value type for --field entries
    #[arg(long, value_enum, default_value_t = FieldValueType::Text)]
    pub field_type: FieldValueType,

    /// Load initial item JSON from file path or '-' for stdin
    #[arg(long)]
    pub from_json: Option<String>,

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
    /// Entity ID to move
    pub id: String,

    /// Target parent item name, ID, or 'none' to unparent
    pub parent: String,
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
}

#[derive(Args, Debug, Clone)]
pub struct AttachmentUploadArgs {
    /// Target entity ID
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

    /// Filter by custom field existence (KEY) or substring value (KEY=VAL), case-insensitive (repeatable)
    #[arg(long = "field", value_name = "KEY[=VAL]")]
    pub fields: Vec<String>,

    /// Match items satisfying ANY provided filter (OR) instead of ALL filters (AND)
    #[arg(long)]
    pub any: bool,
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
                assert_eq!(a.id, "ent-1");
                assert_eq!(a.parent, "Garage");
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
}

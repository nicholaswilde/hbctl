use thiserror::Error;

/// Domain error type for `hbx`.
#[derive(Debug, Error)]
pub enum HbxError {
    #[error(
        "Homebox URL is not configured (set --url, HBX_URL, HOMEBOX_URL, HOMEBOX_IP, or config file)"
    )]
    MissingUrl,

    #[error(
        "Homebox API key is not configured (set --api-key, HBX_API_KEY, HOMEBOX_API_KEY, or config file)"
    )]
    MissingApiKey,

    #[error("configuration error: {0}")]
    Config(String),

    #[error("invalid URL '{url}': {reason}")]
    InvalidUrl { url: String, reason: String },

    #[error("HTTP {status} from Homebox API: {message}")]
    Http { status: u16, message: String },

    #[error("network error: {0}")]
    Network(#[from] reqwest::Error),

    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    #[error("JSON error: {0}")]
    Json(#[from] serde_json::Error),

    #[error("CSV error: {0}")]
    Csv(#[from] csv::Error),

    #[error("{kind} not found: '{query}'")]
    NotFound { kind: String, query: String },

    #[error("invalid input: {0}")]
    InvalidInput(String),

    #[error(
        "image '{path}' is {size_bytes} bytes (exceeds {max_bytes} byte limit); pass --force to upload anyway"
    )]
    ImageTooLarge {
        path: String,
        size_bytes: u64,
        max_bytes: u64,
    },
}

pub type Result<T> = std::result::Result<T, HbxError>;

use std::collections::BTreeMap;

use clap::ValueEnum;
use serde::{Deserialize, Deserializer, Serialize};
use serde_json::{Map, Value};

use crate::error::{HbctlError, Result};

/// Deserializes `null` or omitted JSON values into `T::default()` (Go nil-slice tolerance).
pub fn deserialize_null_default<'de, D, T>(deserializer: D) -> std::result::Result<T, D::Error>
where
    T: Default + Deserialize<'de>,
    D: Deserializer<'de>,
{
    let opt = Option::deserialize(deserializer)?;
    Ok(opt.unwrap_or_default())
}

/// Deserializes `null` or omitted JSON arrays into an empty `Vec<T>` without requiring `T: Default`.
pub fn deserialize_null_vec<'de, D, T>(deserializer: D) -> std::result::Result<Vec<T>, D::Error>
where
    T: Deserialize<'de>,
    D: Deserializer<'de>,
{
    let opt = Option::<Vec<T>>::deserialize(deserializer)?;
    Ok(opt.unwrap_or_default())
}

fn default_quantity() -> i64 {
    1
}

fn deserialize_null_quantity<'de, D>(deserializer: D) -> std::result::Result<i64, D::Error>
where
    D: Deserializer<'de>,
{
    let opt = Option::<i64>::deserialize(deserializer)?;
    Ok(opt.unwrap_or_else(default_quantity))
}

fn default_field_type() -> String {
    "text".to_string()
}

/// Serialize `Option<f64>` as an integer when whole (Homebox v0.26+ Go `NumberValue` is `int`
/// and rejects `5.0` floats during `PUT /api/v1/entities/{id}` JSON decoding).
fn serialize_opt_clean_number<S>(
    val: &Option<f64>,
    serializer: S,
) -> std::result::Result<S::Ok, S::Error>
where
    S: serde::Serializer,
{
    match val {
        None => serializer.serialize_none(),
        Some(n)
            if n.is_finite()
                && n.fract() == 0.0
                && *n >= (i64::MIN as f64)
                && *n <= (i64::MAX as f64) =>
        {
            serializer.serialize_i64(*n as i64)
        }
        Some(n) => serializer.serialize_f64(*n),
    }
}

/// Supported custom field value types in Homebox v0.26+.
#[derive(ValueEnum, Clone, Copy, Debug, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum FieldValueType {
    #[default]
    Text,
    Number,
    Boolean,
}

impl FieldValueType {
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Text => "text",
            Self::Number => "number",
            Self::Boolean => "boolean",
        }
    }
}

/// Homebox custom field object on an entity.
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct CustomField {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,

    #[serde(default)]
    pub name: String,

    #[serde(rename = "type", default = "default_field_type")]
    pub field_type: String,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub value: Option<Value>,

    #[serde(rename = "textValue", default, skip_serializing_if = "Option::is_none")]
    pub text_value: Option<String>,

    #[serde(
        rename = "numberValue",
        default,
        skip_serializing_if = "Option::is_none",
        serialize_with = "serialize_opt_clean_number"
    )]
    pub number_value: Option<f64>,

    #[serde(
        rename = "booleanValue",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub boolean_value: Option<bool>,

    #[serde(flatten)]
    pub extra: BTreeMap<String, Value>,
}

impl CustomField {
    /// Construct a typed `CustomField` populating `value`, `textValue`, and
    /// (`numberValue` / `booleanValue`) consistently for Homebox v0.26+.
    pub fn new_typed(
        name: impl Into<String>,
        kind: FieldValueType,
        raw_value: &str,
    ) -> Result<Self> {
        let name = name.into();
        let trimmed = raw_value.trim();

        match kind {
            FieldValueType::Text => Ok(Self {
                id: None,
                name,
                field_type: "text".to_string(),
                value: Some(Value::String(raw_value.to_string())),
                text_value: Some(raw_value.to_string()),
                number_value: None,
                boolean_value: None,
                extra: BTreeMap::new(),
            }),
            FieldValueType::Number => {
                let num = parse_number_tolerant(trimmed).ok_or_else(|| {
                    HbctlError::InvalidInput(format!(
                        "invalid number '{raw_value}' for field '{name}'"
                    ))
                })?;
                let canonical = num.to_string();
                Ok(Self {
                    id: None,
                    name,
                    field_type: "number".to_string(),
                    value: Some(Value::String(canonical.clone())),
                    text_value: Some(canonical),
                    number_value: Some(num),
                    boolean_value: None,
                    extra: BTreeMap::new(),
                })
            }
            FieldValueType::Boolean => {
                let b = parse_bool_loose(trimmed).ok_or_else(|| {
                    HbctlError::InvalidInput(format!(
                        "invalid boolean '{raw_value}' for field '{name}' (expected true/false)"
                    ))
                })?;
                let canonical = b.to_string();
                Ok(Self {
                    id: None,
                    name,
                    field_type: "boolean".to_string(),
                    value: Some(Value::String(canonical.clone())),
                    text_value: Some(canonical),
                    number_value: None,
                    boolean_value: Some(b),
                    extra: BTreeMap::new(),
                })
            }
        }
    }

    /// Return the normalized string representation of this field's value.
    /// Respects `field_type` (Homebox v0.26+ returns zero-valued `numberValue: 0` and
    /// `booleanValue: false` on every field regardless of type).
    pub fn display_value(&self) -> String {
        if self.field_type.eq_ignore_ascii_case("number") {
            if let Some(n) = self.number_value {
                return n.to_string();
            }
        }
        if self.field_type.eq_ignore_ascii_case("boolean") {
            if let Some(b) = self.boolean_value {
                return b.to_string();
            }
        }
        if let Some(ref val) = self.value {
            match val {
                Value::Null => {}
                Value::String(s) if !s.is_empty() => return s.clone(),
                Value::String(_) => {}
                Value::Number(n) => return n.to_string(),
                Value::Bool(b) => return b.to_string(),
                other => return other.to_string(),
            }
        }
        if let Some(ref text) = self.text_value {
            if !text.is_empty() {
                return text.clone();
            }
        }
        if self.field_type.eq_ignore_ascii_case("text") {
            return String::new();
        }
        if let Some(n) = self.number_value {
            return n.to_string();
        }
        if let Some(b) = self.boolean_value {
            return b.to_string();
        }
        String::new()
    }

    /// Parse a `KEY=VALUE` pair using the given field type.
    pub fn parse_key_value(spec: &str, kind: FieldValueType) -> Result<Self> {
        let (key, val) = spec.split_once('=').ok_or_else(|| {
            HbctlError::InvalidInput(format!(
                "invalid --field '{spec}': expected KEY=VALUE format"
            ))
        })?;
        let key = key.trim();
        if key.is_empty() {
            return Err(HbctlError::InvalidInput(format!(
                "invalid --field '{spec}': key cannot be empty"
            )));
        }
        Self::new_typed(key, kind, val)
    }
}

fn parse_bool_loose(s: &str) -> Option<bool> {
    match s.to_ascii_lowercase().as_str() {
        "true" | "1" | "yes" | "y" => Some(true),
        "false" | "0" | "no" | "n" => Some(false),
        _ => None,
    }
}

/// Parse a numeric custom field value, tolerating leading currency symbols (`$`, `€`, `£`)
/// and common trailing unit suffixes (`g`, `kg`, `oz`, `lb`, `V`, `mA`, `%`, etc.).
pub fn parse_number_tolerant(raw: &str) -> Option<f64> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return None;
    }

    if let Ok(num) = trimmed.parse::<f64>() {
        if num.is_finite() {
            return Some(if num == 0.0 { 0.0 } else { num });
        }
        return None;
    }

    if let Some(rest) = trimmed
        .strip_prefix('$')
        .or_else(|| trimmed.strip_prefix('€'))
        .or_else(|| trimmed.strip_prefix('£'))
    {
        let after_sym = rest.trim();
        if after_sym.is_empty() || after_sym.starts_with(['+', '-']) {
            return None;
        }
        let num: f64 = after_sym.parse().ok()?;
        if num.is_finite() && num >= 0.0 {
            return Some(if num == 0.0 { 0.0 } else { num });
        }
        return None;
    }

    let mut split_idx = trimmed.len();
    for (idx, ch) in trimmed.char_indices().rev() {
        if ch.is_ascii_alphabetic() || ch == '%' {
            split_idx = idx;
        } else {
            break;
        }
    }

    if split_idx == 0 || split_idx == trimmed.len() {
        return None;
    }

    let num_part = trimmed[..split_idx].trim();
    let unit_part = &trimmed[split_idx..];
    if num_part.is_empty() {
        return None;
    }

    let allow_negative = match unit_part.to_ascii_lowercase().as_str() {
        "g" | "gram" | "grams" | "kg" | "mg" | "oz" | "lb" | "lbs" | "mm" | "cm" | "m" | "in"
        | "ft" | "ml" | "l" | "w" | "kw" | "hz" | "khz" | "mhz" | "ohm" | "mah" | "wh" => false,
        "v" | "mv" | "a" | "ma" | "%" => true,
        _ => return None,
    };

    let num: f64 = num_part.parse().ok()?;
    if !num.is_finite() || (!allow_negative && num < 0.0) {
        return None;
    }
    Some(if num == 0.0 { 0.0 } else { num })
}

/// Homebox auth login / refresh response (`/api/v1/users/login`, `/api/v1/users/refresh`).
/// Note: `/api/v1/users/login` returns `"token"`, whereas `/api/v1/users/refresh` returns `"raw"`.
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct LoginResponse {
    #[serde(alias = "raw")]
    pub token: String,

    #[serde(rename = "expiresAt", default, skip_serializing_if = "Option::is_none")]
    pub expires_at: Option<String>,
}

/// Authenticated Homebox user profile (`/api/v1/users/self`).
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct UserProfile {
    #[serde(default)]
    pub id: String,

    #[serde(default)]
    pub name: String,

    #[serde(default)]
    pub email: String,

    #[serde(rename = "groupId", default, skip_serializing_if = "Option::is_none")]
    pub group_id: Option<String>,

    #[serde(rename = "groupName", default, skip_serializing_if = "Option::is_none")]
    pub group_name: Option<String>,

    #[serde(flatten)]
    pub extra: BTreeMap<String, Value>,
}

/// Homebox `/api/v1/users/self` may wrap the profile under `{"item": {...}}` or return it flat.
#[derive(Debug, Clone, Deserialize)]
#[serde(untagged)]
pub enum UserSelfResponse {
    Wrapped { item: UserProfile },
    Flat(UserProfile),
}

impl UserSelfResponse {
    pub fn into_profile(self) -> UserProfile {
        match self {
            Self::Wrapped { item } => item,
            Self::Flat(profile) => profile,
        }
    }
}

/// Homebox tag (`/api/v1/tags`).
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct Tag {
    #[serde(default)]
    pub id: String,

    #[serde(default)]
    pub name: String,

    #[serde(default, deserialize_with = "deserialize_null_default")]
    pub description: String,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub color: Option<String>,

    #[serde(flatten)]
    pub extra: BTreeMap<String, Value>,
}

/// Homebox entity type (`/api/v1/entity-types`).
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct EntityType {
    #[serde(default)]
    pub id: String,

    #[serde(default)]
    pub name: String,

    #[serde(default, deserialize_with = "deserialize_null_default")]
    pub description: String,

    #[serde(rename = "isLocation", default)]
    pub is_location: bool,

    #[serde(flatten)]
    pub extra: BTreeMap<String, Value>,
}

/// Payload for `POST /api/v1/entity-types`.
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct CreateEntityTypeRequest {
    pub name: String,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,

    #[serde(rename = "isLocation")]
    pub is_location: bool,
}

/// Homebox server status response (`GET /api/v1/status`).
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct ServerStatus {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub version: Option<String>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub commit: Option<String>,

    #[serde(
        rename = "buildTime",
        alias = "build_time",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub build_time: Option<String>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub health: Option<bool>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub message: Option<String>,

    #[serde(flatten)]
    pub extra: BTreeMap<String, Value>,
}

/// Homebox entity attachment (`title` / `name` / `mimeType`).
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct Attachment {
    #[serde(default)]
    pub id: String,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,

    #[serde(
        rename = "mimeType",
        alias = "mime_type",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub mime_type: Option<String>,

    #[serde(rename = "type", default, skip_serializing_if = "Option::is_none")]
    pub attachment_type: Option<String>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub primary: Option<bool>,

    #[serde(rename = "createdAt", default, skip_serializing_if = "Option::is_none")]
    pub created_at: Option<String>,

    #[serde(flatten)]
    pub extra: BTreeMap<String, Value>,
}

impl Attachment {
    /// Effective display/filename preferring non-empty `title`, then `name`.
    pub fn effective_name(&self) -> Option<&str> {
        self.title
            .as_deref()
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .or_else(|| {
                self.name
                    .as_deref()
                    .map(str::trim)
                    .filter(|s| !s.is_empty())
            })
    }

    /// True if either `title` or `name` matches `filename` case-insensitively.
    pub fn matches_filename(&self, filename: &str) -> bool {
        let target = filename.trim();
        self.title
            .as_deref()
            .map(|t| t.trim().eq_ignore_ascii_case(target))
            .unwrap_or(false)
            || self
                .name
                .as_deref()
                .map(|n| n.trim().eq_ignore_ascii_case(target))
                .unwrap_or(false)
    }
}

/// Homebox v0.26+ entity (`/api/v1/entities`).
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct Entity {
    #[serde(default)]
    pub id: String,

    #[serde(default)]
    pub name: String,

    #[serde(default, deserialize_with = "deserialize_null_default")]
    pub description: String,

    #[serde(
        default = "default_quantity",
        deserialize_with = "deserialize_null_quantity"
    )]
    pub quantity: i64,

    #[serde(rename = "assetId", default, skip_serializing_if = "Option::is_none")]
    pub asset_id: Option<String>,

    #[serde(
        rename = "entityTypeId",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub entity_type_id: Option<String>,

    #[serde(
        rename = "entityType",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub entity_type: Option<EntityType>,

    #[serde(rename = "parentId", default, skip_serializing_if = "Option::is_none")]
    pub parent_id: Option<String>,

    #[serde(default, deserialize_with = "deserialize_null_default")]
    pub tags: Vec<Tag>,

    #[serde(
        rename = "tagIds",
        default,
        deserialize_with = "deserialize_null_default"
    )]
    pub tag_ids: Vec<String>,

    /// `None` when omitted or `null` in list summaries (signals hydration needed).
    #[serde(default)]
    pub fields: Option<Vec<CustomField>>,

    #[serde(default, deserialize_with = "deserialize_null_default")]
    pub attachments: Vec<Attachment>,

    #[serde(
        rename = "purchasePrice",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub purchase_price: Option<f64>,

    #[serde(
        rename = "purchaseDate",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub purchase_date: Option<String>,

    #[serde(
        rename = "purchaseFrom",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub purchase_from: Option<String>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub manufacturer: Option<String>,

    #[serde(
        rename = "modelNumber",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub model_number: Option<String>,

    #[serde(
        rename = "serialNumber",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub serial_number: Option<String>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub notes: Option<String>,

    #[serde(rename = "createdAt", default, skip_serializing_if = "Option::is_none")]
    pub created_at: Option<String>,

    #[serde(rename = "updatedAt", default, skip_serializing_if = "Option::is_none")]
    pub updated_at: Option<String>,

    #[serde(flatten)]
    pub extra: BTreeMap<String, Value>,
}

impl Entity {
    /// Safe slice view over `fields` (empty when `None`).
    pub fn fields_slice(&self) -> &[CustomField] {
        self.fields.as_deref().unwrap_or(&[])
    }

    /// True if `fields` was omitted or `null` and should be hydrated via `GET /entities/{id}`.
    pub fn needs_field_hydration(&self) -> bool {
        self.fields.is_none()
    }

    /// Look up a custom field by name (case-insensitive).
    pub fn find_field(&self, key: &str) -> Option<&CustomField> {
        let needle = key.trim();
        self.fields_slice()
            .iter()
            .find(|f| f.name.trim().eq_ignore_ascii_case(needle))
    }

    /// Look up a custom field display value (falling back to non-empty top-level alias properties).
    pub fn field_value(&self, key: &str) -> Option<String> {
        if let Some(f) = self.find_field(key) {
            return Some(f.display_value());
        }
        let fallback = match key.trim().to_ascii_lowercase().as_str() {
            "manufacturer" => self.manufacturer.as_deref(),
            "model" | "modelnumber" | "model_number" | "model number" => {
                self.model_number.as_deref()
            }
            "serial" | "serialnumber" | "serial_number" | "serial number" => {
                self.serial_number.as_deref()
            }
            "notes" => self.notes.as_deref(),
            _ => None,
        };
        fallback
            .map(str::trim)
            .filter(|s| !s.is_empty())
            .map(ToOwned::to_owned)
    }

    /// Effective tag IDs combining explicit `tagIds` and embedded `tags`.
    pub fn effective_tag_ids(&self) -> Vec<String> {
        let mut out = Vec::new();
        for id in &self.tag_ids {
            if !id.is_empty() && !out.contains(id) {
                out.push(id.clone());
            }
        }
        for tag in &self.tags {
            if !tag.id.is_empty() && !out.contains(&tag.id) {
                out.push(tag.id.clone());
            }
        }
        out
    }

    /// Effective entity type ID preferring `entityTypeId`, falling back to `entityType.id`.
    pub fn effective_entity_type_id(&self) -> Option<&str> {
        self.entity_type_id
            .as_deref()
            .filter(|s| !s.is_empty())
            .or_else(|| {
                self.entity_type
                    .as_ref()
                    .map(|et| et.id.as_str())
                    .filter(|s| !s.is_empty())
            })
    }
}

/// Paginated or array list response from Homebox endpoints.
#[derive(Debug, Clone, Deserialize)]
#[serde(untagged, bound(deserialize = "T: Deserialize<'de>"))]
pub enum ListResponse<T> {
    Paginated(PaginatedResponse<T>),
    Array(Vec<T>),
}

impl<T> ListResponse<T> {
    pub fn into_parts(self) -> (Vec<T>, Option<u64>) {
        match self {
            Self::Paginated(p) => (p.items, p.total.and_then(|t| u64::try_from(t).ok())),
            Self::Array(items) => {
                let len = items.len() as u64;
                (items, Some(len))
            }
        }
    }
}

#[derive(Debug, Clone, Deserialize)]
#[serde(bound(deserialize = "T: Deserialize<'de>"))]
pub struct PaginatedResponse<T> {
    #[serde(default = "Vec::new", deserialize_with = "deserialize_null_vec")]
    pub items: Vec<T>,

    /// Homebox returns `-1` when `page` query parameter is omitted.
    #[serde(default)]
    pub page: Option<i64>,

    #[serde(rename = "pageSize", default)]
    pub page_size: Option<i64>,

    #[serde(alias = "totalCount", alias = "totalItems", default)]
    pub total: Option<i64>,
}

/// Payload for creating a new entity (`POST /api/v1/entities`).
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct CreateEntityRequest {
    pub name: String,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub quantity: Option<i64>,

    #[serde(
        rename = "entityTypeId",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub entity_type_id: Option<String>,

    #[serde(rename = "parentId", default, skip_serializing_if = "Option::is_none")]
    pub parent_id: Option<String>,

    #[serde(rename = "tagIds", default, skip_serializing_if = "Vec::is_empty")]
    pub tag_ids: Vec<String>,

    #[serde(
        rename = "purchasePrice",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub purchase_price: Option<f64>,

    #[serde(
        rename = "purchaseDate",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub purchase_date: Option<String>,

    #[serde(
        rename = "purchaseFrom",
        default,
        skip_serializing_if = "Option::is_none"
    )]
    pub purchase_from: Option<String>,

    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub fields: Vec<CustomField>,
}

/// Partial update patch applied onto an existing `Entity` via `GET -> Merge -> PUT`.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct EntityPatch {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub quantity: Option<i64>,

    #[serde(rename = "entityTypeId", skip_serializing_if = "Option::is_none")]
    pub entity_type_id: Option<String>,

    #[serde(default, rename = "parentId", skip_serializing_if = "Option::is_none")]
    pub parent_id: Option<Option<String>>,

    #[serde(rename = "tagIds", skip_serializing_if = "Option::is_none")]
    pub tag_ids: Option<Vec<String>>,

    #[serde(rename = "purchasePrice", skip_serializing_if = "Option::is_none")]
    pub purchase_price: Option<f64>,

    #[serde(rename = "purchaseDate", skip_serializing_if = "Option::is_none")]
    pub purchase_date: Option<String>,

    #[serde(rename = "purchaseFrom", skip_serializing_if = "Option::is_none")]
    pub purchase_from: Option<String>,

    #[serde(default, rename = "addTagIds", skip_serializing_if = "Vec::is_empty")]
    pub add_tag_ids: Vec<String>,

    #[serde(
        default,
        rename = "removeTagIds",
        skip_serializing_if = "Vec::is_empty"
    )]
    pub remove_tag_ids: Vec<String>,

    #[serde(
        default,
        rename = "removeFields",
        skip_serializing_if = "Vec::is_empty"
    )]
    pub remove_fields: Vec<String>,

    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub fields: Vec<CustomField>,

    #[serde(
        default,
        rename = "fillMissing",
        skip_serializing_if = "std::ops::Not::not"
    )]
    pub fill_missing: bool,
}

/// Upsert a slice of custom fields into `existing` by case-insensitive field name
/// without clobbering unrelated fields.
pub fn upsert_custom_fields(existing: &mut Vec<CustomField>, updates: &[CustomField]) {
    for upd in updates {
        if let Some(slot) = existing
            .iter_mut()
            .find(|f| f.name.trim().eq_ignore_ascii_case(upd.name.trim()))
        {
            let preserved_id = slot.id.clone();
            *slot = upd.clone();
            if slot.id.is_none() {
                slot.id = preserved_id;
            }
        } else {
            existing.push(upd.clone());
        }
    }
}

fn is_blank_opt_str(val: Option<&str>) -> bool {
    match val {
        None => true,
        Some(s) => s.trim().is_empty(),
    }
}

fn is_blank_date(val: Option<&str>) -> bool {
    match val {
        None => true,
        Some(s) => {
            let trimmed = s.trim();
            trimmed.is_empty() || trimmed.starts_with("0001-01-01")
        }
    }
}

fn is_empty_opt_price(val: Option<f64>) -> bool {
    match val {
        None => true,
        Some(v) => v == 0.0,
    }
}

fn has_non_empty_top_level_alias(entity: &Entity, key: &str) -> bool {
    let fallback = match key.trim().to_ascii_lowercase().as_str() {
        "manufacturer" => entity.manufacturer.as_deref(),
        "model" | "modelnumber" | "model_number" | "model number" => entity.model_number.as_deref(),
        "serial" | "serialnumber" | "serial_number" | "serial number" => {
            entity.serial_number.as_deref()
        }
        "notes" => entity.notes.as_deref(),
        _ => None,
    };
    !is_blank_opt_str(fallback)
}

/// Fill missing/blank custom fields without overwriting existing non-empty values.
fn fill_missing_custom_fields(
    existing_fields: &mut Vec<CustomField>,
    updates: &[CustomField],
    existing_entity: &Entity,
    removed_fields: &[String],
) {
    for upd in updates {
        if let Some(slot) = existing_fields
            .iter_mut()
            .find(|f| f.name.trim().eq_ignore_ascii_case(upd.name.trim()))
        {
            if !slot.display_value().trim().is_empty() {
                continue;
            }
            let preserved_id = slot.id.clone();
            *slot = upd.clone();
            if slot.id.is_none() {
                slot.id = preserved_id;
            }
        } else {
            let was_removed = removed_fields
                .iter()
                .any(|rm| upd.name.trim().eq_ignore_ascii_case(rm.trim()));
            if was_removed || !has_non_empty_top_level_alias(existing_entity, &upd.name) {
                existing_fields.push(upd.clone());
            }
        }
    }
}

/// Merge an `EntityPatch` onto an existing `Entity` for safe `GET -> Merge -> PUT`.
pub fn merge_entity_patch(existing: &Entity, patch: &EntityPatch) -> Entity {
    let mut merged = existing.clone();

    if let Some(ref name) = patch.name {
        if !patch.fill_missing || merged.name.trim().is_empty() {
            merged.name = name.clone();
        }
    }
    if let Some(ref desc) = patch.description {
        if !patch.fill_missing || merged.description.trim().is_empty() {
            merged.description = desc.clone();
        }
    }
    if let Some(qty) = patch.quantity {
        if !patch.fill_missing || merged.quantity == 0 {
            merged.quantity = qty;
        }
    }
    if let Some(ref et_id) = patch.entity_type_id {
        if !patch.fill_missing || existing.effective_entity_type_id().is_none() {
            merged.entity_type_id = Some(et_id.clone());
        } else if merged.entity_type_id.is_none() {
            merged.entity_type_id = existing.effective_entity_type_id().map(ToOwned::to_owned);
        }
    } else if merged.entity_type_id.is_none() {
        merged.entity_type_id = existing.effective_entity_type_id().map(ToOwned::to_owned);
    }
    if let Some(ref parent_opt) = patch.parent_id {
        match parent_opt {
            Some(pid) => {
                if !patch.fill_missing || is_blank_opt_str(merged.parent_id.as_deref()) {
                    merged.parent_id = Some(pid.clone());
                }
            }
            None => {
                if !patch.fill_missing {
                    merged.parent_id = None;
                }
            }
        }
    }
    if let Some(price) = patch.purchase_price {
        if !patch.fill_missing || is_empty_opt_price(merged.purchase_price) {
            merged.purchase_price = Some(price);
        }
    }
    if let Some(ref date) = patch.purchase_date {
        if !patch.fill_missing || is_blank_date(merged.purchase_date.as_deref()) {
            merged.purchase_date = Some(date.clone());
        }
    }
    if let Some(ref from) = patch.purchase_from {
        if !patch.fill_missing || is_blank_opt_str(merged.purchase_from.as_deref()) {
            merged.purchase_from = Some(from.clone());
        }
    }

    // Preserve existing tag IDs, merge additive tags, and apply explicit removals
    let mut tag_ids = existing.effective_tag_ids();
    if let Some(ref new_tags) = patch.tag_ids {
        for tid in new_tags {
            if !tid.is_empty() && !tag_ids.contains(tid) {
                tag_ids.push(tid.clone());
            }
        }
    }
    for tid in &patch.add_tag_ids {
        if !tid.is_empty() && !tag_ids.contains(tid) {
            tag_ids.push(tid.clone());
        }
    }
    if !patch.remove_tag_ids.is_empty() {
        tag_ids.retain(|id| !patch.remove_tag_ids.contains(id));
        merged.tags.retain(|t| tag_ids.contains(&t.id));
    }
    merged.tag_ids = tag_ids;

    // Remove requested fields and merge updates without clobbering unrelated fields
    let mut fields = existing.fields.clone().unwrap_or_default();
    if !patch.remove_fields.is_empty() {
        fields.retain(|f| {
            !patch
                .remove_fields
                .iter()
                .any(|rm| f.name.trim().eq_ignore_ascii_case(rm.trim()))
        });
    }
    if patch.fill_missing {
        fill_missing_custom_fields(&mut fields, &patch.fields, existing, &patch.remove_fields);
    } else {
        upsert_custom_fields(&mut fields, &patch.fields);
    }
    merged.fields = Some(fields);

    merged
}

/// Normalize top-level aliases in JSON input (`manufacturer`/`Manufacturer`,
/// `modelNumber`/`model_number`/`Model Number`, `serialNumber`/`serial_number`/`Serial Number`,
/// `notes`/`Notes`) into `.fields` text entries so Homebox v0.26+ custom fields persist uniformly.
pub fn normalize_json_aliases(raw: &mut Value) -> Vec<CustomField> {
    let mut extracted = Vec::new();
    let Some(obj) = raw.as_object_mut() else {
        return extracted;
    };

    // First collect any already-present fields from JSON
    if let Some(Value::Array(arr)) = obj.get("fields") {
        for item in arr {
            if let Ok(cf) = serde_json::from_value::<CustomField>(item.clone()) {
                extracted.push(cf);
            }
        }
    }

    let alias_groups: &[(&[&str], &str)] = &[
        (&["manufacturer", "Manufacturer"], "Manufacturer"),
        (
            &["modelNumber", "model_number", "Model Number"],
            "Model Number",
        ),
        (
            &["serialNumber", "serial_number", "Serial Number", "serial"],
            "Serial Number",
        ),
        (&["notes", "Notes"], "Notes"),
    ];

    for (aliases, canonical) in alias_groups {
        if let Some(val) = take_first_string_alias(obj, aliases) {
            if !val.trim().is_empty() {
                if let Ok(cf) = CustomField::new_typed(*canonical, FieldValueType::Text, &val) {
                    upsert_custom_fields(&mut extracted, &[cf]);
                }
            }
        }
    }

    if !extracted.is_empty() {
        if let Ok(arr) = serde_json::to_value(&extracted) {
            obj.insert("fields".to_string(), arr);
        }
    }

    extracted
}

fn take_first_string_alias(obj: &mut Map<String, Value>, aliases: &[&str]) -> Option<String> {
    let mut found = None;
    for alias in aliases {
        if let Some(v) = obj.remove(*alias) {
            if found.is_none() {
                found = match v {
                    Value::String(s) => Some(s),
                    Value::Number(n) => Some(n.to_string()),
                    Value::Bool(b) => Some(b.to_string()),
                    _ => None,
                };
            }
        }
    }
    found
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_deserialize_null_slices_and_typed_fields() {
        let raw = json!({
            "id": "ent-1",
            "name": "ESP32 DevKit",
            "description": null,
            "quantity": null,
            "tags": null,
            "tagIds": null,
            "fields": null,
            "attachments": null,
            "purchasePrice": 12.50,
            "purchaseDate": "2026-01-15",
            "purchaseFrom": "Mouser"
        });
        let entity: Entity = serde_json::from_value(raw).unwrap();
        assert_eq!(entity.id, "ent-1");
        assert_eq!(entity.description, "");
        assert_eq!(entity.quantity, 1);
        assert!(entity.tags.is_empty());
        assert!(entity.tag_ids.is_empty());
        assert!(entity.needs_field_hydration());
        assert!(entity.fields_slice().is_empty());
        assert!(entity.attachments.is_empty());
        assert_eq!(entity.purchase_price, Some(12.50));
        assert_eq!(entity.purchase_date.as_deref(), Some("2026-01-15"));
        assert_eq!(entity.purchase_from.as_deref(), Some("Mouser"));
    }

    #[test]
    fn test_attachment_title_and_name_resolution() {
        let a1: Attachment = serde_json::from_value(json!({
            "id": "att-1",
            "title": "manual.pdf",
            "name": "file_123.pdf",
            "mimeType": "application/pdf"
        }))
        .unwrap();
        assert_eq!(a1.effective_name(), Some("manual.pdf"));
        assert!(a1.matches_filename("MANUAL.PDF"));
        assert!(a1.matches_filename("file_123.pdf"));

        let a2: Attachment = serde_json::from_value(json!({
            "id": "att-2",
            "title": "",
            "name": "schematic.png"
        }))
        .unwrap();
        assert_eq!(a2.effective_name(), Some("schematic.png"));
    }

    #[test]
    fn test_typed_custom_fields_and_numeric_precedence() {
        let num = CustomField::new_typed("Voltage", FieldValueType::Number, "3.3").unwrap();
        assert_eq!(num.field_type, "number");
        assert_eq!(num.value, Some(json!("3.3")));
        assert_eq!(num.text_value.as_deref(), Some("3.3"));
        assert_eq!(num.number_value, Some(3.3));
        assert_eq!(num.display_value(), "3.3");

        // When reading a numeric field, prefer non-null numberValue over value / textValue
        let server_num: CustomField = serde_json::from_value(json!({
            "name": "Voltage",
            "type": "number",
            "value": "old",
            "textValue": "stale",
            "numberValue": 5.0
        }))
        .unwrap();
        assert_eq!(server_num.display_value(), "5");

        let flag = CustomField::new_typed("Active", FieldValueType::Boolean, "true").unwrap();
        assert_eq!(flag.field_type, "boolean");
        assert_eq!(flag.boolean_value, Some(true));
        assert_eq!(flag.display_value(), "true");

        // Whole numbers MUST serialize as JSON integers (Homebox Go NumberValue is int)
        let whole = CustomField::new_typed("Pins", FieldValueType::Number, "38").unwrap();
        let serialized = serde_json::to_string(&whole).unwrap();
        assert!(serialized.contains("\"numberValue\":38"));
        assert!(!serialized.contains("\"numberValue\":38.0"));

        // Unit-tolerant numeric parsing
        assert_eq!(parse_number_tolerant("250"), Some(250.0));
        assert_eq!(parse_number_tolerant("-10"), Some(-10.0));
        assert_eq!(parse_number_tolerant("250g"), Some(250.0));
        assert_eq!(parse_number_tolerant("250 G"), Some(250.0));
        assert_eq!(parse_number_tolerant("490 grams"), Some(490.0));
        assert_eq!(parse_number_tolerant("2.5kg"), Some(2.5));
        assert_eq!(parse_number_tolerant("16oz"), Some(16.0));
        assert_eq!(parse_number_tolerant("5.2 lb"), Some(5.2));
        assert_eq!(parse_number_tolerant("5.2 lbs"), Some(5.2));
        assert_eq!(parse_number_tolerant("3.3V"), Some(3.3));
        assert_eq!(parse_number_tolerant("-3.3V"), Some(-3.3));
        assert_eq!(parse_number_tolerant("500mA"), Some(500.0));
        assert_eq!(parse_number_tolerant("100W"), Some(100.0));
        assert_eq!(parse_number_tolerant("50%"), Some(50.0));
        assert_eq!(parse_number_tolerant("$19.99"), Some(19.99));
        assert_eq!(parse_number_tolerant("$ 19.99"), Some(19.99));
        assert_eq!(parse_number_tolerant("€12.50"), Some(12.5));
        assert_eq!(parse_number_tolerant("£9.99"), Some(9.99));

        let tare =
            CustomField::new_typed("Tare Weight (g)", FieldValueType::Number, "250g").unwrap();
        assert_eq!(tare.number_value, Some(250.0));
        assert_eq!(tare.display_value(), "250");

        for invalid in [
            "invalid", "", "   ", "g", "$", "250abc", "$250g", "250 g kg", "-250g", "-10kg",
            "$-5.00", "-$5.00", "NaN", "inf", "-inf",
        ] {
            assert_eq!(
                parse_number_tolerant(invalid),
                None,
                "expected '{invalid}' to fail"
            );
            assert!(
                CustomField::new_typed("Test", FieldValueType::Number, invalid).is_err(),
                "expected CustomField::new_typed('{invalid}') to fail"
            );
        }

        // Empty Homebox v0.27+ text field with zero-valued numberValue/booleanValue returns ""
        let empty_text: CustomField = serde_json::from_value(json!({
            "name": "Notes",
            "type": "text",
            "textValue": "",
            "numberValue": 0,
            "booleanValue": false
        }))
        .unwrap();
        assert_eq!(empty_text.display_value(), "");

        // Refresh response uses "raw" instead of "token"
        let refreshed: LoginResponse = serde_json::from_value(json!({
            "raw": "ROTATED_TOKEN",
            "expiresAt": "2026-12-03T05:54:45Z"
        }))
        .unwrap();
        assert_eq!(refreshed.token, "ROTATED_TOKEN");
        assert_eq!(
            refreshed.expires_at.as_deref(),
            Some("2026-12-03T05:54:45Z")
        );

        // Empty top-level alias strings from Homebox v0.27+ must NOT look like populated fields
        let empty_aliases: Entity = serde_json::from_value(json!({
            "id": "ent-empty",
            "name": "Bare Item",
            "manufacturer": "",
            "modelNumber": "",
            "serialNumber": "",
            "notes": "",
            "fields": []
        }))
        .unwrap();
        assert_eq!(empty_aliases.field_value("Manufacturer"), None);
        assert_eq!(empty_aliases.field_value("Model Number"), None);
        assert_eq!(empty_aliases.field_value("Serial Number"), None);
        assert_eq!(empty_aliases.field_value("Notes"), None);

        // Homebox v0.27+ returns `"page": -1` when `page` query parameter is omitted
        let paged: ListResponse<Entity> = serde_json::from_value(json!({
            "page": -1,
            "pageSize": 5,
            "total": 175,
            "items": [{"id": "ent-1", "name": "Resistor", "quantity": 0}]
        }))
        .unwrap();
        let (items, total) = paged.into_parts();
        assert_eq!(items.len(), 1);
        assert_eq!(items[0].quantity, 0);
        assert_eq!(total, Some(175));
    }

    #[test]
    fn test_normalize_json_aliases_into_fields() {
        let mut payload = json!({
            "name": "Multimeter",
            "manufacturer": "Fluke",
            "model_number": "87V",
            "Notes": "Calibrated 2026"
        });
        let fields = normalize_json_aliases(&mut payload);
        assert_eq!(fields.len(), 3);
        assert_eq!(fields[0].name, "Manufacturer");
        assert_eq!(fields[0].display_value(), "Fluke");
        assert_eq!(fields[1].name, "Model Number");
        assert_eq!(fields[1].display_value(), "87V");
        assert_eq!(fields[2].name, "Notes");
        assert_eq!(fields[2].display_value(), "Calibrated 2026");
        assert!(payload.get("manufacturer").is_none());
        assert!(payload.get("model_number").is_none());
        assert!(payload.get("Notes").is_none());
    }

    #[test]
    fn test_merge_entity_patch_preserves_unrelated_fields_and_tags() {
        let existing = Entity {
            id: "ent-1".into(),
            name: "Sensor".into(),
            description: "Old desc".into(),
            quantity: 2,
            tags: vec![Tag {
                id: "tag-1".into(),
                name: "electronics".into(),
                ..Default::default()
            }],
            fields: Some(vec![
                CustomField::new_typed("Manufacturer", FieldValueType::Text, "Bosch").unwrap(),
                CustomField::new_typed("Voltage", FieldValueType::Number, "3.3").unwrap(),
            ]),
            ..Default::default()
        };

        let patch = EntityPatch {
            quantity: Some(5),
            tag_ids: Some(vec!["tag-2".into()]),
            fields: vec![
                CustomField::new_typed("voltage", FieldValueType::Number, "5").unwrap(),
                CustomField::new_typed("Notes", FieldValueType::Text, "Bin A").unwrap(),
            ],
            ..Default::default()
        };

        let merged = merge_entity_patch(&existing, &patch);
        assert_eq!(merged.name, "Sensor");
        assert_eq!(merged.description, "Old desc");
        assert_eq!(merged.quantity, 5);
        assert_eq!(merged.tag_ids, vec!["tag-1", "tag-2"]);
        let fields = merged.fields.unwrap();
        assert_eq!(fields.len(), 3);
        assert_eq!(fields[0].name, "Manufacturer");
        assert_eq!(fields[0].display_value(), "Bosch");
        assert_eq!(fields[1].display_value(), "5");
        assert_eq!(fields[2].name, "Notes");
        assert_eq!(fields[2].display_value(), "Bin A");
    }

    #[test]
    fn test_merge_entity_patch_add_remove_tags_and_remove_fields() {
        let existing = Entity {
            id: "ent-1".into(),
            name: "Sensor".into(),
            quantity: 1,
            tags: vec![
                Tag {
                    id: "tag-1".into(),
                    name: "electronics".into(),
                    ..Default::default()
                },
                Tag {
                    id: "tag-2".into(),
                    name: "legacy".into(),
                    ..Default::default()
                },
            ],
            tag_ids: vec!["tag-1".into(), "tag-2".into()],
            fields: Some(vec![
                CustomField::new_typed("Manufacturer", FieldValueType::Text, "Bosch").unwrap(),
                CustomField::new_typed("Voltage", FieldValueType::Number, "3.3").unwrap(),
            ]),
            ..Default::default()
        };

        let patch = EntityPatch {
            add_tag_ids: vec!["tag-3".into()],
            remove_tag_ids: vec!["tag-2".into()],
            remove_fields: vec!["voltage".into()],
            ..Default::default()
        };

        let merged = merge_entity_patch(&existing, &patch);
        assert_eq!(merged.tag_ids, vec!["tag-1", "tag-3"]);
        assert_eq!(merged.tags.len(), 1);
        assert_eq!(merged.tags[0].id, "tag-1");
        let fields = merged.fields.unwrap();
        assert_eq!(fields.len(), 1);
        assert_eq!(fields[0].name, "Manufacturer");
    }

    #[test]
    fn test_normalize_json_aliases_extracts_serial_number() {
        let mut payload = json!({
            "name": "Scope",
            "serialNumber": "SN-123"
        });
        let fields = normalize_json_aliases(&mut payload);
        assert_eq!(fields.len(), 1);
        assert_eq!(fields[0].name, "Serial Number");
        assert_eq!(fields[0].display_value(), "SN-123");
        assert!(payload.get("serialNumber").is_none());

        let mut payload2 = json!({
            "name": "Scope",
            "serial_number": "SN-456"
        });
        let fields2 = normalize_json_aliases(&mut payload2);
        assert_eq!(fields2.len(), 1);
        assert_eq!(fields2[0].name, "Serial Number");
        assert_eq!(fields2[0].display_value(), "SN-456");
    }

    #[test]
    fn test_merge_entity_patch_fill_missing_preserves_existing_and_populates_blanks() {
        let existing = Entity {
            id: "ent-1".into(),
            name: "Sensor".into(),
            description: "Existing desc".into(),
            quantity: 3,
            entity_type_id: Some("et-item".into()),
            purchase_price: Some(12.5),
            purchase_date: Some("2026-01-10".into()),
            purchase_from: Some("Mouser".into()),
            tags: vec![Tag {
                id: "tag-1".into(),
                name: "electronics".into(),
                ..Default::default()
            }],
            tag_ids: vec!["tag-1".into()],
            fields: Some(vec![
                CustomField::new_typed("Manufacturer", FieldValueType::Text, "Bosch").unwrap(),
                CustomField::new_typed("Voltage", FieldValueType::Number, "3.3").unwrap(),
                CustomField {
                    id: Some("fld-model".into()),
                    name: "Model Number".into(),
                    field_type: "text".into(),
                    value: Some(Value::String(String::new())),
                    text_value: Some(String::new()),
                    ..Default::default()
                },
            ]),
            ..Default::default()
        };

        let patch = EntityPatch {
            name: Some("New Name".into()),
            description: Some("New Desc".into()),
            quantity: Some(9),
            entity_type_id: Some("et-other".into()),
            tag_ids: Some(vec!["tag-2".into()]),
            add_tag_ids: vec!["tag-3".into()],
            purchase_price: Some(99.0),
            purchase_date: Some("2026-05-01".into()),
            purchase_from: Some("DigiKey".into()),
            fields: vec![
                CustomField::new_typed("Manufacturer", FieldValueType::Text, "Fluke").unwrap(),
                CustomField::new_typed("voltage", FieldValueType::Number, "5").unwrap(),
                CustomField::new_typed("Model Number", FieldValueType::Text, "M-200").unwrap(),
                CustomField::new_typed("Notes", FieldValueType::Text, "Backfilled").unwrap(),
            ],
            fill_missing: true,
            ..Default::default()
        };

        let merged = merge_entity_patch(&existing, &patch);
        assert_eq!(merged.name, "Sensor");
        assert_eq!(merged.description, "Existing desc");
        assert_eq!(merged.quantity, 3);
        assert_eq!(merged.entity_type_id.as_deref(), Some("et-item"));
        assert_eq!(merged.purchase_price, Some(12.5));
        assert_eq!(merged.purchase_date.as_deref(), Some("2026-01-10"));
        assert_eq!(merged.purchase_from.as_deref(), Some("Mouser"));
        assert_eq!(merged.tag_ids, vec!["tag-1", "tag-2", "tag-3"]);

        let fields = merged.fields.unwrap();
        assert_eq!(fields.len(), 4);
        assert_eq!(fields[0].name, "Manufacturer");
        assert_eq!(fields[0].display_value(), "Bosch");
        assert_eq!(fields[1].name, "Voltage");
        assert_eq!(fields[1].display_value(), "3.3");
        assert_eq!(fields[2].name, "Model Number");
        assert_eq!(fields[2].id.as_deref(), Some("fld-model"));
        assert_eq!(fields[2].display_value(), "M-200");
        assert_eq!(fields[3].name, "Notes");
        assert_eq!(fields[3].display_value(), "Backfilled");
    }

    #[test]
    fn test_merge_entity_patch_fill_missing_populates_missing_and_zero_fields() {
        let existing_nested_type = Entity {
            id: "ent-2".into(),
            name: String::new(),
            description: "   ".into(),
            quantity: 0,
            entity_type_id: None,
            entity_type: Some(EntityType {
                id: "et-nested".into(),
                name: "Item".into(),
                ..Default::default()
            }),
            purchase_price: Some(0.0),
            purchase_date: Some("0001-01-01T00:00:00Z".into()),
            purchase_from: Some("  ".into()),
            manufacturer: Some("LegacyMfg".into()),
            fields: Some(vec![]),
            ..Default::default()
        };

        let patch = EntityPatch {
            name: Some("Filled Name".into()),
            description: Some("Filled Desc".into()),
            quantity: Some(4),
            entity_type_id: Some("et-new".into()),
            purchase_price: Some(42.0),
            purchase_date: Some("2026-04-01".into()),
            purchase_from: Some("DigiKey".into()),
            fields: vec![
                CustomField::new_typed("Manufacturer", FieldValueType::Text, "OverrideMfg")
                    .unwrap(),
                CustomField::new_typed("Serial Number", FieldValueType::Text, "SN-9").unwrap(),
            ],
            fill_missing: true,
            ..Default::default()
        };

        let merged = merge_entity_patch(&existing_nested_type, &patch);
        assert_eq!(merged.name, "Filled Name");
        assert_eq!(merged.description, "Filled Desc");
        assert_eq!(merged.quantity, 4);
        assert_eq!(merged.entity_type_id.as_deref(), Some("et-nested"));
        assert_eq!(merged.purchase_price, Some(42.0));
        assert_eq!(merged.purchase_date.as_deref(), Some("2026-04-01"));
        assert_eq!(merged.purchase_from.as_deref(), Some("DigiKey"));
        let fields = merged.fields.unwrap();
        assert_eq!(fields.len(), 1);
        assert_eq!(fields[0].name, "Serial Number");
        assert_eq!(fields[0].display_value(), "SN-9");

        let existing_no_type = Entity {
            id: "ent-3".into(),
            name: "Item".into(),
            quantity: 1,
            ..Default::default()
        };
        let merged_no_type = merge_entity_patch(&existing_no_type, &patch);
        assert_eq!(merged_no_type.entity_type_id.as_deref(), Some("et-new"));
        assert_eq!(merged_no_type.purchase_price, Some(42.0));
        assert_eq!(merged_no_type.purchase_date.as_deref(), Some("2026-04-01"));
        assert_eq!(merged_no_type.purchase_from.as_deref(), Some("DigiKey"));
    }

    #[test]
    fn test_merge_entity_patch_parent_id_set_unparent_and_fill_missing() {
        let existing_no_parent = Entity {
            id: "ent-1".into(),
            name: "Sensor".into(),
            quantity: 1,
            ..Default::default()
        };

        // Set parent_id
        let set_patch = EntityPatch {
            parent_id: Some(Some("parent-a".into())),
            ..Default::default()
        };
        let set_merged = merge_entity_patch(&existing_no_parent, &set_patch);
        assert_eq!(set_merged.parent_id.as_deref(), Some("parent-a"));

        // Untouched when patch.parent_id is None
        let untouched = merge_entity_patch(&set_merged, &EntityPatch::default());
        assert_eq!(untouched.parent_id.as_deref(), Some("parent-a"));

        // fill_missing preserves existing non-empty parent_id and populates blank parent_id
        let fill_overwrite = EntityPatch {
            parent_id: Some(Some("parent-b".into())),
            fill_missing: true,
            ..Default::default()
        };
        let preserved = merge_entity_patch(&set_merged, &fill_overwrite);
        assert_eq!(preserved.parent_id.as_deref(), Some("parent-a"));

        let blank_parent = Entity {
            id: "ent-1".into(),
            name: "Sensor".into(),
            quantity: 1,
            parent_id: Some("  ".into()),
            ..Default::default()
        };
        let backfilled = merge_entity_patch(&blank_parent, &fill_overwrite);
        assert_eq!(backfilled.parent_id.as_deref(), Some("parent-b"));

        // fill_missing does not unparent when patch.parent_id is Some(None)
        let unparent_patch_fill = EntityPatch {
            parent_id: Some(None),
            fill_missing: true,
            ..Default::default()
        };
        let kept = merge_entity_patch(&set_merged, &unparent_patch_fill);
        assert_eq!(kept.parent_id.as_deref(), Some("parent-a"));

        // Explicit unparent (Some(None)) clears parent_id
        let unparent_patch = EntityPatch {
            parent_id: Some(None),
            ..Default::default()
        };
        let cleared = merge_entity_patch(&set_merged, &unparent_patch);
        assert_eq!(cleared.parent_id, None);
    }

    #[test]
    fn test_server_status_and_create_entity_type_serde() {
        let raw = json!({
            "version": "v0.26.2",
            "commit": "deadbeef",
            "build_time": "2026-01-10T00:00:00Z",
            "title": "Homebox",
            "health": true,
            "extraField": 42
        });
        let status: ServerStatus = serde_json::from_value(raw).unwrap();
        assert_eq!(status.version.as_deref(), Some("v0.26.2"));
        assert_eq!(status.commit.as_deref(), Some("deadbeef"));
        assert_eq!(status.build_time.as_deref(), Some("2026-01-10T00:00:00Z"));
        assert_eq!(status.title.as_deref(), Some("Homebox"));
        assert_eq!(status.health, Some(true));
        assert_eq!(status.extra.get("extraField"), Some(&json!(42)));

        let req = CreateEntityTypeRequest {
            name: "Storage Bin".into(),
            description: Some("Container".into()),
            is_location: true,
        };
        let serialized = serde_json::to_value(&req).unwrap();
        assert_eq!(
            serialized,
            json!({
                "name": "Storage Bin",
                "description": "Container",
                "isLocation": true
            })
        );
    }
}

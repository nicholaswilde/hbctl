use std::collections::BTreeMap;

use clap::ValueEnum;
use serde::{Deserialize, Deserializer, Serialize};
use serde_json::{Map, Value};

use crate::error::{HbxError, Result};

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
        skip_serializing_if = "Option::is_none"
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
                let num: f64 = trimmed.parse().map_err(|_| {
                    HbxError::InvalidInput(format!(
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
                    HbxError::InvalidInput(format!(
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
    /// For numeric fields, prefers non-null `numberValue` over `value` / `textValue`.
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
            HbxError::InvalidInput(format!(
                "invalid --field '{spec}': expected KEY=VALUE format"
            ))
        })?;
        let key = key.trim();
        if key.is_empty() {
            return Err(HbxError::InvalidInput(format!(
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

/// Homebox auth login / refresh response (`/api/v1/users/login`, `/api/v1/users/refresh`).
#[derive(Debug, Clone, Default, PartialEq, Serialize, Deserialize)]
pub struct LoginResponse {
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

    /// Look up a custom field display value (falling back to top-level alias properties).
    pub fn field_value(&self, key: &str) -> Option<String> {
        if let Some(f) = self.find_field(key) {
            return Some(f.display_value());
        }
        match key.trim().to_ascii_lowercase().as_str() {
            "manufacturer" => self.manufacturer.clone(),
            "model" | "modelnumber" | "model_number" | "model number" => self.model_number.clone(),
            "serial" | "serialnumber" | "serial_number" | "serial number" => {
                self.serial_number.clone()
            }
            "notes" => self.notes.clone(),
            _ => None,
        }
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
            Self::Paginated(p) => (p.items, p.total),
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

    #[serde(default)]
    pub page: Option<u32>,

    #[serde(rename = "pageSize", default)]
    pub page_size: Option<u32>,

    #[serde(alias = "totalCount", alias = "totalItems", default)]
    pub total: Option<u64>,
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

    #[serde(rename = "tagIds", skip_serializing_if = "Option::is_none")]
    pub tag_ids: Option<Vec<String>>,

    #[serde(rename = "purchasePrice", skip_serializing_if = "Option::is_none")]
    pub purchase_price: Option<f64>,

    #[serde(rename = "purchaseDate", skip_serializing_if = "Option::is_none")]
    pub purchase_date: Option<String>,

    #[serde(rename = "purchaseFrom", skip_serializing_if = "Option::is_none")]
    pub purchase_from: Option<String>,

    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub fields: Vec<CustomField>,
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

/// Merge an `EntityPatch` onto an existing `Entity` for safe `GET -> Merge -> PUT`.
pub fn merge_entity_patch(existing: &Entity, patch: &EntityPatch) -> Entity {
    let mut merged = existing.clone();

    if let Some(ref name) = patch.name {
        merged.name = name.clone();
    }
    if let Some(ref desc) = patch.description {
        merged.description = desc.clone();
    }
    if let Some(qty) = patch.quantity {
        merged.quantity = qty;
    }
    if let Some(ref et_id) = patch.entity_type_id {
        merged.entity_type_id = Some(et_id.clone());
    } else if merged.entity_type_id.is_none() {
        merged.entity_type_id = existing.effective_entity_type_id().map(ToOwned::to_owned);
    }
    if let Some(price) = patch.purchase_price {
        merged.purchase_price = Some(price);
    }
    if let Some(ref date) = patch.purchase_date {
        merged.purchase_date = Some(date.clone());
    }
    if let Some(ref from) = patch.purchase_from {
        merged.purchase_from = Some(from.clone());
    }

    // Preserve existing tag IDs and merge any new ones without clobbering
    let mut tag_ids = existing.effective_tag_ids();
    if let Some(ref new_tags) = patch.tag_ids {
        for tid in new_tags {
            if !tid.is_empty() && !tag_ids.contains(tid) {
                tag_ids.push(tid.clone());
            }
        }
    }
    merged.tag_ids = tag_ids;

    // Merge custom fields without clobbering unrelated fields
    let mut fields = existing.fields.clone().unwrap_or_default();
    upsert_custom_fields(&mut fields, &patch.fields);
    merged.fields = Some(fields);

    merged
}

/// Normalize top-level aliases in JSON input (`manufacturer`/`Manufacturer`,
/// `modelNumber`/`model_number`/`Model Number`, `notes`/`Notes`) into `.fields`
/// text entries so Homebox v0.26+ custom fields persist uniformly.
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
}

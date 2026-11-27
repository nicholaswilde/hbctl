use crate::client::models::{Entity, EntityType, Tag};
use crate::client::{HomeboxClient, ListEntitiesQuery};
use crate::error::{HbctlError, Result};

/// Case-insensitive name-to-UUID resolver for Homebox tags, entity types, and parent items.
/// Caches list responses within a single command execution.
pub struct Resolver<'a> {
    client: &'a HomeboxClient,
    tags_cache: Option<Vec<Tag>>,
    entity_types_cache: Option<Vec<EntityType>>,
    entities_cache: Option<Vec<Entity>>,
}

impl<'a> Resolver<'a> {
    pub fn new(client: &'a HomeboxClient) -> Self {
        Self {
            client,
            tags_cache: None,
            entity_types_cache: None,
            entities_cache: None,
        }
    }

    fn tags(&mut self) -> Result<&mut Vec<Tag>> {
        if self.tags_cache.is_none() {
            self.tags_cache = Some(self.client.list_tags()?);
        }
        Ok(self.tags_cache.as_mut().expect("tags cache populated"))
    }

    fn entity_types(&mut self) -> Result<&[EntityType]> {
        if self.entity_types_cache.is_none() {
            self.entity_types_cache = Some(self.client.list_entity_types()?);
        }
        Ok(self
            .entity_types_cache
            .as_deref()
            .expect("entity types cache populated"))
    }

    fn entities(&mut self) -> Result<&[Entity]> {
        if self.entities_cache.is_none() {
            self.entities_cache = Some(
                self.client
                    .list_entities(&ListEntitiesQuery::default(), true)?,
            );
        }
        Ok(self
            .entities_cache
            .as_deref()
            .expect("entities cache populated"))
    }

    /// Resolve a tag name or UUID case-insensitively.
    /// When `auto_create` is true, creates missing tags via `POST /api/v1/tags`.
    pub fn resolve_tag_id(&mut self, name_or_id: &str, auto_create: bool) -> Result<String> {
        let needle = name_or_id.trim();
        if needle.is_empty() {
            return Err(HbctlError::InvalidInput("tag cannot be empty".to_string()));
        }

        let tags = self.tags()?;
        if let Some(found) = tags
            .iter()
            .find(|t| t.id == needle || t.name.trim().eq_ignore_ascii_case(needle))
        {
            return Ok(found.id.clone());
        }

        if auto_create {
            if is_uuid_like(needle) {
                return Ok(needle.to_string());
            }
            let created = self.client.create_tag(needle)?;
            let id = created.id.clone();
            self.tags()?.push(created);
            Ok(id)
        } else if is_uuid_like(needle) {
            Ok(needle.to_string())
        } else {
            Err(HbctlError::NotFound {
                kind: "tag".to_string(),
                query: needle.to_string(),
            })
        }
    }

    /// Resolve a list of tag names/IDs into deduplicated tag IDs.
    pub fn resolve_tag_ids(&mut self, tags: &[String], auto_create: bool) -> Result<Vec<String>> {
        let mut ids = Vec::new();
        for tag in tags {
            let id = self.resolve_tag_id(tag, auto_create)?;
            if !ids.contains(&id) {
                ids.push(id);
            }
        }
        Ok(ids)
    }

    /// Resolve an entity type name or UUID case-insensitively via `GET /api/v1/entity-types`.
    pub fn resolve_entity_type_id(&mut self, name_or_id: &str) -> Result<String> {
        let needle = name_or_id.trim();
        if needle.is_empty() {
            return Err(HbctlError::InvalidInput(
                "entity type cannot be empty".to_string(),
            ));
        }

        let types = self.entity_types()?;
        if let Some(found) = types
            .iter()
            .find(|et| et.id == needle || et.name.trim().eq_ignore_ascii_case(needle))
        {
            return Ok(found.id.clone());
        }

        if is_uuid_like(needle) {
            Ok(needle.to_string())
        } else {
            Err(HbctlError::NotFound {
                kind: "entity type".to_string(),
                query: needle.to_string(),
            })
        }
    }

    /// Resolve a parent item name, UUID, or `'none'` (returns `Ok(None)`).
    pub fn resolve_parent_id(&mut self, name_or_id: &str) -> Result<Option<String>> {
        let needle = name_or_id.trim();
        if needle.is_empty() {
            return Err(HbctlError::InvalidInput(
                "parent cannot be empty".to_string(),
            ));
        }
        if needle.eq_ignore_ascii_case("none") {
            return Ok(None);
        }

        let entities = self.entities()?;
        if let Some(found) = entities.iter().find(|e| e.id == needle) {
            return Ok(Some(found.id.clone()));
        }
        let needle_asset = normalize_asset_id(needle);
        if !needle_asset.is_empty() && is_asset_id_like(needle) {
            if let Some(found) = entities.iter().find(|e| {
                e.asset_id
                    .as_deref()
                    .map(normalize_asset_id)
                    .filter(|a| !a.is_empty())
                    .is_some_and(|a| a == needle_asset)
            }) {
                return Ok(Some(found.id.clone()));
            }
        }
        if let Some(found) = entities
            .iter()
            .find(|e| e.name.trim().eq_ignore_ascii_case(needle))
        {
            return Ok(Some(found.id.clone()));
        }

        if is_uuid_like(needle) {
            Ok(Some(needle.to_string()))
        } else {
            Err(HbctlError::NotFound {
                kind: "parent item".to_string(),
                query: needle.to_string(),
            })
        }
    }
}

/// Returns true if `s` looks like a standard 36-character UUID (`8-4-4-4-12` hex).
pub fn is_uuid_like(s: &str) -> bool {
    let bytes = s.as_bytes();
    if bytes.len() != 36 {
        return false;
    }
    for (idx, &b) in bytes.iter().enumerate() {
        if matches!(idx, 8 | 13 | 18 | 23) {
            if b != b'-' {
                return false;
            }
        } else if !b.is_ascii_hexdigit() {
            return false;
        }
    }
    true
}

/// Normalize a Homebox asset ID by trimming whitespace and an optional leading `#`.
pub fn normalize_asset_id(raw: &str) -> String {
    let trimmed = raw.trim();
    trimmed
        .strip_prefix('#')
        .unwrap_or(trimmed)
        .trim()
        .to_string()
}

/// Returns true if `s` looks like a Homebox numeric/dashed asset ID (e.g. `000-001`, `42`, `#000-042`).
///
/// Strings containing letters (e.g. `ent-1`, `loc-2`, or UUIDs) return `false`.
pub fn is_asset_id_like(s: &str) -> bool {
    let trimmed = s.trim();
    if trimmed.is_empty() || is_uuid_like(trimmed) {
        return false;
    }
    let clean = normalize_asset_id(trimmed);
    if clean.is_empty() || clean.starts_with('-') || clean.ends_with('-') || clean.contains("--") {
        return false;
    }
    if !clean.bytes().all(|b| b.is_ascii_digit() || b == b'-') {
        return false;
    }
    let compact: String = clean.chars().filter(|&c| c != '-').collect();
    !compact.is_empty() && compact.parse::<u64>().is_ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_is_uuid_like() {
        assert!(is_uuid_like("550e8400-e29b-41d4-a716-446655440000"));
        assert!(is_uuid_like("ABCDEF01-2345-6789-ABCD-EF0123456789"));
        assert!(!is_uuid_like("electronics"));
        assert!(!is_uuid_like("550e8400-e29b-41d4-a716-44665544000"));
        assert!(!is_uuid_like("550e8400xe29b-41d4-a716-446655440000"));
    }

    #[test]
    fn test_is_asset_id_like_and_normalize() {
        assert!(is_asset_id_like("000-001"));
        assert!(is_asset_id_like("12345"));
        assert!(is_asset_id_like("#000-042"));
        assert!(is_asset_id_like(" 1 "));
        assert!(!is_asset_id_like("ent-1"));
        assert!(!is_asset_id_like("loc-2"));
        assert!(!is_asset_id_like("550e8400-e29b-41d4-a716-446655440000"));
        assert!(!is_asset_id_like(""));
        assert!(!is_asset_id_like("#"));
        assert!(!is_asset_id_like("-1"));
        assert!(!is_asset_id_like("000--001"));
        assert!(!is_asset_id_like("123-"));

        assert_eq!(normalize_asset_id(" #000-042 "), "000-042");
        assert_eq!(normalize_asset_id("000-001"), "000-001");
    }
}

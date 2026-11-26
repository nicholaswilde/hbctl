pub mod models;
pub mod resolve;

use std::collections::BTreeMap;
use std::fs::{self, File};
use std::io;
use std::path::Path;
use std::time::Duration;

use reqwest::blocking::{multipart, Client, Response};
use reqwest::header::{AUTHORIZATION, CONTENT_TYPE};
use serde::de::DeserializeOwned;
use serde::Serialize;
use serde_json::{json, Value};

use crate::client::models::{
    merge_entity_patch, upsert_custom_fields, Attachment, CreateEntityRequest, Entity, EntityPatch,
    EntityType, ListResponse, LoginResponse, Tag, UserProfile, UserSelfResponse,
};
use crate::config::{
    normalize_auth_header, normalize_base_url, redact_auth_header, redact_secret, AppConfig,
    DEFAULT_DOWNLOAD_TIMEOUT_SECS, DEFAULT_TIMEOUT_SECS,
};
use crate::error::{HbctlError, Result};

/// Redacted preview of a mutating request emitted during `--dry-run`.
#[derive(Debug, Clone, Serialize)]
pub struct DryRunRequest {
    pub method: String,
    pub url: String,
    pub headers: BTreeMap<String, String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub body: Option<Value>,
}

/// Query parameters for `GET /api/v1/entities`.
#[derive(Debug, Clone, Default)]
pub struct ListEntitiesQuery {
    pub query: Option<String>,
    pub tag_ids: Vec<String>,
    pub entity_type_id: Option<String>,
    pub page: Option<u32>,
    pub page_size: Option<u32>,
}

/// Blocking REST client for Homebox v0.26+.
#[derive(Debug, Clone)]
pub struct HomeboxClient {
    base_url: String,
    auth_header: String,
    raw_secret: String,
    http: Client,
    download_http: Client,
}

impl HomeboxClient {
    pub fn from_config(cfg: &AppConfig) -> Result<Self> {
        let base_url = cfg.require_base_url()?;
        let api_key = cfg.require_api_key()?;
        Self::new(
            base_url,
            api_key,
            cfg.timeout_secs,
            cfg.download_timeout_secs,
        )
    }

    pub fn new(
        base_url: &str,
        api_key: &str,
        timeout_secs: u64,
        download_timeout_secs: u64,
    ) -> Result<Self> {
        let normalized_url = normalize_base_url(base_url)?;
        let auth_header = normalize_auth_header(api_key);
        let http = Client::builder()
            .timeout(Duration::from_secs(timeout_secs.max(1)))
            .build()?;
        let download_http = Client::builder()
            .timeout(Duration::from_secs(download_timeout_secs.max(1)))
            .build()?;

        Ok(Self {
            base_url: normalized_url,
            auth_header,
            raw_secret: api_key.to_string(),
            http,
            download_http,
        })
    }

    pub fn with_defaults(base_url: &str, api_key: &str) -> Result<Self> {
        Self::new(
            base_url,
            api_key,
            DEFAULT_TIMEOUT_SECS,
            DEFAULT_DOWNLOAD_TIMEOUT_SECS,
        )
    }

    pub fn base_url(&self) -> &str {
        &self.base_url
    }

    pub fn endpoint(&self, path: &str) -> String {
        let clean = path.trim_start_matches('/');
        format!("{}/{clean}", self.base_url)
    }

    /// Build a redacted `--dry-run` request preview with `Authorization: Bearer ***`.
    pub fn build_dry_run(
        base_url: &str,
        method: &str,
        path: &str,
        body: Option<Value>,
    ) -> DryRunRequest {
        let clean = path.trim_start_matches('/');
        let mut headers = BTreeMap::new();
        headers.insert(
            "Authorization".to_string(),
            redact_auth_header("Bearer secret").to_string(),
        );
        if body.is_some() {
            headers.insert("Content-Type".to_string(), "application/json".to_string());
        }
        DryRunRequest {
            method: method.to_uppercase(),
            url: format!("{base_url}/{clean}"),
            headers,
            body,
        }
    }

    fn handle_response<T: DeserializeOwned>(&self, resp: Response) -> Result<T> {
        let status = resp.status();
        let text = resp.text()?;
        if !status.is_success() {
            let safe_msg = redact_secret(&text, &self.raw_secret);
            return Err(HbctlError::Http {
                status: status.as_u16(),
                message: safe_msg,
            });
        }
        serde_json::from_str(&text).map_err(HbctlError::from)
    }

    fn handle_empty_response(&self, resp: Response) -> Result<()> {
        let status = resp.status();
        if !status.is_success() {
            let text = resp.text().unwrap_or_default();
            let safe_msg = redact_secret(&text, &self.raw_secret);
            return Err(HbctlError::Http {
                status: status.as_u16(),
                message: safe_msg,
            });
        }
        Ok(())
    }

    // -------------------------------------------------------------------------
    // Entities (`/api/v1/entities`)
    // -------------------------------------------------------------------------

    pub fn list_entities_page(
        &self,
        query: &ListEntitiesQuery,
    ) -> Result<(Vec<Entity>, Option<u64>)> {
        let mut req = self
            .http
            .get(self.endpoint("entities"))
            .header(AUTHORIZATION, &self.auth_header);

        let mut params: Vec<(&str, String)> = Vec::new();
        if let Some(ref q) = query.query {
            if !q.trim().is_empty() {
                params.push(("q", q.clone()));
            }
        }
        for tid in &query.tag_ids {
            params.push(("tags", tid.clone()));
        }
        if let Some(ref et) = query.entity_type_id {
            params.push(("entityTypeId", et.clone()));
        }
        if let Some(page) = query.page {
            params.push(("page", page.to_string()));
        }
        if let Some(ps) = query.page_size {
            params.push(("pageSize", ps.to_string()));
        }
        if !params.is_empty() {
            req = req.query(&params);
        }

        let resp = req.send()?;
        let parsed: ListResponse<Entity> = self.handle_response(resp)?;
        Ok(parsed.into_parts())
    }

    /// List entities, automatically paginating when `fetch_all` is true.
    pub fn list_entities(&self, query: &ListEntitiesQuery, fetch_all: bool) -> Result<Vec<Entity>> {
        if !fetch_all {
            let (items, _) = self.list_entities_page(query)?;
            return Ok(items);
        }

        let page_size = query.page_size.unwrap_or(50).max(1);
        let mut page = query.page.unwrap_or(1).max(1);
        let mut all = Vec::new();

        loop {
            let mut page_query = query.clone();
            page_query.page = Some(page);
            page_query.page_size = Some(page_size);

            let (items, total) = self.list_entities_page(&page_query)?;
            let batch_len = items.len();
            all.extend(items);

            if batch_len == 0 || (batch_len as u32) < page_size {
                break;
            }
            if let Some(t) = total {
                if (all.len() as u64) >= t {
                    break;
                }
            }
            page += 1;
        }

        Ok(all)
    }

    pub fn get_entity(&self, id: &str) -> Result<Entity> {
        let resp = self
            .http
            .get(self.endpoint(&format!("entities/{id}")))
            .header(AUTHORIZATION, &self.auth_header)
            .send()?;
        self.handle_response(resp)
    }

    /// Hydrate entities whose `fields` were omitted or `null` in list summaries.
    pub fn hydrate_entity_fields(&self, entities: Vec<Entity>) -> Result<Vec<Entity>> {
        let mut hydrated = Vec::with_capacity(entities.len());
        for entity in entities {
            if entity.needs_field_hydration() && !entity.id.is_empty() {
                hydrated.push(self.get_entity(&entity.id)?);
            } else {
                hydrated.push(entity);
            }
        }
        Ok(hydrated)
    }

    /// Create an entity via `POST /api/v1/entities`.
    /// Workaround for Homebox v0.26+: because `POST /api/v1/entities` ignores custom
    /// `fields` on initial creation, automatically issues a follow-up `PUT /api/v1/entities/{id}`
    /// whenever `req.fields` is non-empty.
    pub fn create_entity(&self, req: &CreateEntityRequest) -> Result<Entity> {
        let resp = self
            .http
            .post(self.endpoint("entities"))
            .header(AUTHORIZATION, &self.auth_header)
            .header(CONTENT_TYPE, "application/json")
            .json(req)
            .send()?;

        let mut created: Entity = self.handle_response(resp)?;

        if !req.fields.is_empty() {
            let mut merged = created.clone();
            // Ensure tagIds & purchase metadata from request aren't dropped by PUT
            if merged.tag_ids.is_empty() {
                merged.tag_ids = if !created.effective_tag_ids().is_empty() {
                    created.effective_tag_ids()
                } else {
                    req.tag_ids.clone()
                };
            }
            if merged.entity_type_id.is_none() {
                merged.entity_type_id = created
                    .effective_entity_type_id()
                    .map(ToOwned::to_owned)
                    .or_else(|| req.entity_type_id.clone());
            }
            if merged.purchase_price.is_none() {
                merged.purchase_price = req.purchase_price;
            }
            if merged.purchase_date.is_none() {
                merged.purchase_date = req.purchase_date.clone();
            }
            if merged.purchase_from.is_none() {
                merged.purchase_from = req.purchase_from.clone();
            }

            let mut fields = merged.fields.clone().unwrap_or_default();
            upsert_custom_fields(&mut fields, &req.fields);
            merged.fields = Some(fields);

            created = self.put_entity(&created.id, &merged)?;
        }

        Ok(created)
    }

    /// Full entity replacement via `PUT /api/v1/entities/{id}`.
    pub fn put_entity(&self, id: &str, entity: &Entity) -> Result<Entity> {
        let resp = self
            .http
            .put(self.endpoint(&format!("entities/{id}")))
            .header(AUTHORIZATION, &self.auth_header)
            .header(CONTENT_TYPE, "application/json")
            .json(entity)
            .send()?;
        self.handle_response(resp)
    }

    /// Safe `GET -> Merge -> PUT` update for an entity.
    pub fn update_entity(&self, id: &str, patch: &EntityPatch) -> Result<Entity> {
        let existing = self.get_entity(id)?;
        let merged = merge_entity_patch(&existing, patch);
        self.put_entity(id, &merged)
    }

    pub fn delete_entity(&self, id: &str) -> Result<()> {
        let resp = self
            .http
            .delete(self.endpoint(&format!("entities/{id}")))
            .header(AUTHORIZATION, &self.auth_header)
            .send()?;
        self.handle_empty_response(resp)
    }

    // -------------------------------------------------------------------------
    // Tags (`/api/v1/tags`)
    // -------------------------------------------------------------------------

    pub fn list_tags(&self) -> Result<Vec<Tag>> {
        let resp = self
            .http
            .get(self.endpoint("tags"))
            .header(AUTHORIZATION, &self.auth_header)
            .send()?;
        let parsed: ListResponse<Tag> = self.handle_response(resp)?;
        Ok(parsed.into_parts().0)
    }

    pub fn create_tag(&self, name: &str) -> Result<Tag> {
        let resp = self
            .http
            .post(self.endpoint("tags"))
            .header(AUTHORIZATION, &self.auth_header)
            .header(CONTENT_TYPE, "application/json")
            .json(&json!({ "name": name }))
            .send()?;
        self.handle_response(resp)
    }

    // -------------------------------------------------------------------------
    // Entity Types (`/api/v1/entity-types`)
    // -------------------------------------------------------------------------

    pub fn list_entity_types(&self) -> Result<Vec<EntityType>> {
        let resp = self
            .http
            .get(self.endpoint("entity-types"))
            .header(AUTHORIZATION, &self.auth_header)
            .send()?;
        let parsed: ListResponse<EntityType> = self.handle_response(resp)?;
        Ok(parsed.into_parts().0)
    }

    // -------------------------------------------------------------------------
    // Attachments (`/api/v1/entities/{id}/attachments`)
    // -------------------------------------------------------------------------

    pub fn upload_attachment(&self, entity_id: &str, file_path: &Path) -> Result<Attachment> {
        let basename = file_path
            .file_name()
            .and_then(|n| n.to_str())
            .ok_or_else(|| {
                HbctlError::InvalidInput(format!("invalid file path '{}'", file_path.display()))
            })?
            .to_string();

        let mime = mime_guess::from_path(file_path).first_or_octet_stream();
        let bytes = fs::read(file_path)?;

        let file_part = multipart::Part::bytes(bytes)
            .file_name(basename.clone())
            .mime_str(mime.essence_str())
            .map_err(|e| HbctlError::InvalidInput(format!("invalid MIME type: {e}")))?;

        let form = multipart::Form::new()
            .part("file", file_part)
            .text("name", basename)
            .text(
                "type",
                if mime.type_() == "image" {
                    "photo"
                } else {
                    "attachment"
                },
            );

        let resp = self
            .http
            .post(self.endpoint(&format!("entities/{entity_id}/attachments")))
            .header(AUTHORIZATION, &self.auth_header)
            .multipart(form)
            .send()?;

        // Homebox may return either the created Attachment directly or the updated Entity
        let status = resp.status();
        let text = resp.text()?;
        if !status.is_success() {
            let safe_msg = redact_secret(&text, &self.raw_secret);
            return Err(HbctlError::Http {
                status: status.as_u16(),
                message: safe_msg,
            });
        }

        if let Ok(att) = serde_json::from_str::<Attachment>(&text) {
            if !att.id.is_empty() && !att.extra.contains_key("attachments") {
                return Ok(att);
            }
        }
        if let Ok(ent) = serde_json::from_str::<Entity>(&text) {
            if let Some(last) = ent.attachments.into_iter().last() {
                return Ok(last);
            }
        }
        serde_json::from_str::<Attachment>(&text).map_err(HbctlError::from)
    }

    /// Stream an attachment directly to disk using `download_timeout_secs`.
    pub fn download_attachment(
        &self,
        entity_id: &str,
        attachment_id: &str,
        dest_path: &Path,
    ) -> Result<u64> {
        if let Some(parent) = dest_path.parent() {
            if !parent.as_os_str().is_empty() {
                fs::create_dir_all(parent)?;
            }
        }

        let mut resp = self
            .download_http
            .get(self.endpoint(&format!("entities/{entity_id}/attachments/{attachment_id}")))
            .header(AUTHORIZATION, &self.auth_header)
            .send()?;

        let status = resp.status();
        if !status.is_success() {
            let text = resp.text().unwrap_or_default();
            let safe_msg = redact_secret(&text, &self.raw_secret);
            return Err(HbctlError::Http {
                status: status.as_u16(),
                message: safe_msg,
            });
        }

        let mut file = File::create(dest_path)?;
        let written = io::copy(&mut resp, &mut file)?;
        Ok(written)
    }

    pub fn delete_attachment(&self, entity_id: &str, attachment_id: &str) -> Result<()> {
        let resp = self
            .http
            .delete(self.endpoint(&format!("entities/{entity_id}/attachments/{attachment_id}")))
            .header(AUTHORIZATION, &self.auth_header)
            .send()?;
        self.handle_empty_response(resp)
    }

    // -------------------------------------------------------------------------
    // Authentication (`/api/v1/users/login`, `/users/self`, `/users/refresh`)
    // -------------------------------------------------------------------------

    /// Authenticate with email/username and password via `POST /api/v1/users/login`.
    pub fn login(
        base_url: &str,
        username: &str,
        password: &str,
        timeout_secs: u64,
    ) -> Result<LoginResponse> {
        let normalized = normalize_base_url(base_url)?;
        let http = Client::builder()
            .timeout(Duration::from_secs(timeout_secs.max(1)))
            .build()?;

        let resp = http
            .post(format!("{normalized}/users/login"))
            .header(CONTENT_TYPE, "application/json")
            .json(&json!({
                "username": username,
                "password": password,
                "stayLoggedIn": true,
            }))
            .send()?;

        let status = resp.status();
        let text = resp.text()?;
        if !status.is_success() {
            let safe = redact_secret(&text, password);
            return Err(HbctlError::Http {
                status: status.as_u16(),
                message: safe,
            });
        }
        serde_json::from_str(&text).map_err(HbctlError::from)
    }

    /// Fetch the authenticated user's profile (`GET /api/v1/users/self`).
    pub fn get_current_user(&self) -> Result<UserProfile> {
        let resp = self
            .http
            .get(self.endpoint("users/self"))
            .header(AUTHORIZATION, &self.auth_header)
            .send()?;
        let parsed: UserSelfResponse = self.handle_response(resp)?;
        Ok(parsed.into_profile())
    }

    /// Refresh an active JWT session (`GET /api/v1/users/refresh`, falling back to `POST` on 405).
    pub fn refresh_token(&self) -> Result<LoginResponse> {
        let resp = self
            .http
            .get(self.endpoint("users/refresh"))
            .header(AUTHORIZATION, &self.auth_header)
            .send()?;

        if resp.status().as_u16() == 405 {
            let post_resp = self
                .http
                .post(self.endpoint("users/refresh"))
                .header(AUTHORIZATION, &self.auth_header)
                .send()?;
            return self.handle_response(post_resp);
        }

        self.handle_response(resp)
    }
}

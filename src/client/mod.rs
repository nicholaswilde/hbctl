pub mod models;
pub mod resolve;

use std::collections::BTreeMap;
use std::fs::{self, File};
use std::io;
use std::path::Path;
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use reqwest::blocking::{multipart, Client, RequestBuilder, Response};
use reqwest::header::{AUTHORIZATION, CONTENT_TYPE, RETRY_AFTER};
use serde::de::DeserializeOwned;
use serde::Serialize;
use serde_json::{json, Value};

use crate::client::models::{
    merge_entity_patch, upsert_custom_fields, Attachment, CreateEntityRequest,
    CreateEntityTypeRequest, Entity, EntityPatch, EntityType, ListResponse, LoginResponse,
    ServerStatus, Tag, UserProfile, UserSelfResponse,
};
use crate::config::{
    normalize_auth_header, normalize_base_url, redact_auth_header, redact_secret, AppConfig,
    DEFAULT_DOWNLOAD_TIMEOUT_SECS, DEFAULT_TIMEOUT_SECS,
};
use crate::error::{HbctlError, Result};

pub const DEFAULT_MAX_RETRIES: usize = 3;
pub const DEFAULT_RETRY_BASE_DELAY_MS: u64 = 200;
pub const DEFAULT_RETRY_MAX_DELAY_SECS: u64 = 10;
pub const DEFAULT_HYDRATE_CONCURRENCY: usize = 8;

/// Exponential backoff and `Retry-After` configuration for transient HTTP failures.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RetryPolicy {
    pub max_retries: usize,
    pub base_delay: Duration,
    pub max_delay: Duration,
}

impl Default for RetryPolicy {
    fn default() -> Self {
        Self {
            max_retries: DEFAULT_MAX_RETRIES,
            base_delay: Duration::from_millis(DEFAULT_RETRY_BASE_DELAY_MS),
            max_delay: Duration::from_secs(DEFAULT_RETRY_MAX_DELAY_SECS),
        }
    }
}

impl RetryPolicy {
    /// Compute sleep duration before retry `attempt` (0-indexed), honoring `Retry-After` if given.
    pub fn delay_for_attempt(&self, attempt: usize, retry_after: Option<Duration>) -> Duration {
        if let Some(ra) = retry_after {
            return ra.min(self.max_delay);
        }
        let factor = u32::try_from(attempt)
            .ok()
            .and_then(|shift| 1u32.checked_shl(shift))
            .unwrap_or(u32::MAX);
        self.base_delay.saturating_mul(factor).min(self.max_delay)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum RetryMode {
    /// GET / PUT / DELETE: retry 429, 502, 503, 504 and transient network errors.
    Idempotent,
    /// POST (create_entity, create_tag, upload_attachment, login, refresh POST):
    /// retry only 429, 503, and TCP/TLS connect errors so writes are never duplicated.
    SafeMutation,
}

fn is_retryable_status(status: u16, mode: RetryMode) -> bool {
    match mode {
        RetryMode::Idempotent => matches!(status, 429 | 502 | 503 | 504),
        RetryMode::SafeMutation => matches!(status, 429 | 503),
    }
}

fn is_retryable_network_error(err: &reqwest::Error, mode: RetryMode) -> bool {
    match mode {
        RetryMode::Idempotent => {
            err.is_timeout()
                || err.is_connect()
                || (err.is_request() && !err.is_builder() && !err.is_redirect())
        }
        RetryMode::SafeMutation => err.is_connect(),
    }
}

fn parse_retry_after(resp: &Response) -> Option<Duration> {
    let raw = resp.headers().get(RETRY_AFTER)?.to_str().ok()?;
    parse_retry_after_at(raw, SystemTime::now())
}

fn parse_retry_after_at(value: &str, now: SystemTime) -> Option<Duration> {
    let trimmed = value.trim();
    if let Ok(secs) = trimmed.parse::<u64>() {
        return Some(Duration::from_secs(secs));
    }

    // RFC 9110 IMF-fixdate: "Wed, 21 Oct 2015 07:28:00 GMT"
    let mut parts = trimmed.split_ascii_whitespace();
    let dow = parts.next()?;
    let day_s = parts.next()?;
    let mon_s = parts.next()?;
    let year_s = parts.next()?;
    let hms_s = parts.next()?;
    let tz = parts.next()?;
    if parts.next().is_some() || !dow.ends_with(',') || !tz.eq_ignore_ascii_case("GMT") {
        return None;
    }

    let day: u32 = day_s.parse().ok()?;
    if !(1..=31).contains(&day) {
        return None;
    }
    let month: u32 = match mon_s {
        "Jan" => 1,
        "Feb" => 2,
        "Mar" => 3,
        "Apr" => 4,
        "May" => 5,
        "Jun" => 6,
        "Jul" => 7,
        "Aug" => 8,
        "Sep" => 9,
        "Oct" => 10,
        "Nov" => 11,
        "Dec" => 12,
        _ => return None,
    };
    let year: i64 = year_s.parse().ok()?;
    if !(1970..=9999).contains(&year) {
        return None;
    }

    let mut hms = hms_s.split(':');
    let hour: u32 = hms.next()?.parse().ok()?;
    let min: u32 = hms.next()?.parse().ok()?;
    let sec: u32 = hms.next()?.parse().ok()?;
    if hms.next().is_some() || hour > 23 || min > 59 || sec > 60 {
        return None;
    }

    // Howard Hinnant's civil-from-days inverse (days since 1970-01-01).
    let y = if month <= 2 { year - 1 } else { year };
    let era = y.div_euclid(400);
    let yoe = (y - era * 400) as u64;
    let m = month as u64;
    let doy = (153 * (if m > 2 { m - 3 } else { m + 9 }) + 2) / 5 + (day as u64) - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    let days = era * 146_097 + (doe as i64) - 719_468;

    let target_secs = days * 86_400 + (hour as i64) * 3600 + (min as i64) * 60 + (sec as i64);
    let now_secs = now.duration_since(UNIX_EPOCH).ok()?.as_secs() as i64;
    if target_secs <= now_secs {
        Some(Duration::ZERO)
    } else {
        Some(Duration::from_secs((target_secs - now_secs) as u64))
    }
}

fn send_request_with_retry<F>(
    policy: RetryPolicy,
    mode: RetryMode,
    mut build_req: F,
) -> Result<Response>
where
    F: FnMut() -> Result<RequestBuilder>,
{
    for attempt in 0..=policy.max_retries {
        let req = build_req()?;
        match req.send() {
            Ok(resp) => {
                let status = resp.status().as_u16();
                if attempt < policy.max_retries && is_retryable_status(status, mode) {
                    let delay = policy.delay_for_attempt(attempt, parse_retry_after(&resp));
                    drop(resp);
                    if !delay.is_zero() {
                        thread::sleep(delay);
                    }
                    continue;
                }
                return Ok(resp);
            }
            Err(err) => {
                if attempt < policy.max_retries && is_retryable_network_error(&err, mode) {
                    let delay = policy.delay_for_attempt(attempt, None);
                    if !delay.is_zero() {
                        thread::sleep(delay);
                    }
                    continue;
                }
                return Err(HbctlError::Network(err));
            }
        }
    }
    unreachable!("retry loop always returns on final attempt")
}

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
    retry_policy: RetryPolicy,
    hydrate_concurrency: usize,
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
            retry_policy: RetryPolicy::default(),
            hydrate_concurrency: DEFAULT_HYDRATE_CONCURRENCY,
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

    pub fn with_retry_policy(mut self, policy: RetryPolicy) -> Self {
        self.retry_policy = policy;
        self
    }

    pub fn with_hydrate_concurrency(mut self, concurrency: usize) -> Self {
        self.hydrate_concurrency = concurrency.max(1);
        self
    }

    fn send_with_retry<F>(&self, mode: RetryMode, build_req: F) -> Result<Response>
    where
        F: FnMut() -> Result<RequestBuilder>,
    {
        send_request_with_retry(self.retry_policy, mode, build_req)
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

        let url = self.endpoint("entities");
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            let mut req = self.http.get(&url).header(AUTHORIZATION, &self.auth_header);
            if !params.is_empty() {
                req = req.query(&params);
            }
            Ok(req)
        })?;
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
        let url = self.endpoint(&format!("entities/{id}"));
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self.http.get(&url).header(AUTHORIZATION, &self.auth_header))
        })?;
        self.handle_response(resp)
    }

    fn fetch_entities_indexed(&self, work: &[(usize, String)]) -> Result<Vec<(usize, Entity)>> {
        if work.is_empty() {
            return Ok(Vec::new());
        }

        if work.len() == 1 || self.hydrate_concurrency <= 1 {
            let mut out = Vec::with_capacity(work.len());
            for (idx, id) in work {
                out.push((*idx, self.get_entity(id)?));
            }
            return Ok(out);
        }

        let worker_count = self.hydrate_concurrency.max(1).min(work.len());
        let next = AtomicUsize::new(0);
        let failed = AtomicBool::new(false);

        let outcomes = thread::scope(|s| {
            let mut handles = Vec::with_capacity(worker_count);
            for _ in 0..worker_count {
                handles.push(s.spawn(|| {
                    let mut local = Vec::new();
                    loop {
                        if failed.load(Ordering::Acquire) {
                            break;
                        }
                        let pos = next.fetch_add(1, Ordering::Relaxed);
                        if pos >= work.len() {
                            break;
                        }
                        let (orig_idx, ref id) = work[pos];
                        match self.get_entity(id) {
                            Ok(ent) => local.push((orig_idx, ent)),
                            Err(err) => {
                                failed.store(true, Ordering::Release);
                                return Err((orig_idx, err));
                            }
                        }
                    }
                    Ok(local)
                }));
            }

            let mut results = Vec::with_capacity(handles.len());
            for handle in handles {
                let res = handle
                    .join()
                    .map_err(|_| {
                        (
                            usize::MAX,
                            HbctlError::InvalidInput("hydration worker panicked".to_string()),
                        )
                    })
                    .and_then(|inner| inner);
                results.push(res);
            }
            results
        });

        let mut first_err: Option<(usize, HbctlError)> = None;
        let mut fetched = Vec::with_capacity(work.len());
        for outcome in outcomes {
            match outcome {
                Ok(local) => fetched.extend(local),
                Err((idx, err)) => match &first_err {
                    Some((best_idx, _)) if idx >= *best_idx => {}
                    _ => first_err = Some((idx, err)),
                },
            }
        }

        if let Some((_, err)) = first_err {
            return Err(err);
        }

        Ok(fetched)
    }

    /// Hydrate entities whose `fields` were omitted or `null` in list summaries.
    pub fn hydrate_entity_fields(&self, mut entities: Vec<Entity>) -> Result<Vec<Entity>> {
        let work: Vec<(usize, String)> = entities
            .iter()
            .enumerate()
            .filter(|(_, e)| e.needs_field_hydration() && !e.id.is_empty())
            .map(|(idx, e)| (idx, e.id.clone()))
            .collect();

        for (orig_idx, ent) in self.fetch_entities_indexed(&work)? {
            entities[orig_idx] = ent;
        }
        Ok(entities)
    }

    /// Hydrate entities whose `attachments` were omitted or `null` in list summaries.
    pub fn hydrate_entity_attachments(&self, mut entities: Vec<Entity>) -> Result<Vec<Entity>> {
        let work: Vec<(usize, String)> = entities
            .iter()
            .enumerate()
            .filter(|(_, e)| e.attachments.is_empty() && !e.id.is_empty())
            .map(|(idx, e)| (idx, e.id.clone()))
            .collect();

        for (orig_idx, ent) in self.fetch_entities_indexed(&work)? {
            entities[orig_idx] = ent;
        }
        Ok(entities)
    }

    /// Fetch multiple entities by ID concurrently, preserving input order.
    pub fn get_entities_by_ids(&self, ids: &[String]) -> Result<Vec<Entity>> {
        let work: Vec<(usize, String)> = ids.iter().cloned().enumerate().collect();
        let mut fetched = self.fetch_entities_indexed(&work)?;
        fetched.sort_by_key(|(idx, _)| *idx);
        Ok(fetched.into_iter().map(|(_, e)| e).collect())
    }

    /// Create an entity via `POST /api/v1/entities`.
    /// Workaround for Homebox v0.26+: because `POST /api/v1/entities` ignores custom
    /// `fields` on initial creation, automatically issues a follow-up `PUT /api/v1/entities/{id}`
    /// whenever `req.fields` is non-empty.
    pub fn create_entity(&self, req: &CreateEntityRequest) -> Result<Entity> {
        let url = self.endpoint("entities");
        let resp = self.send_with_retry(RetryMode::SafeMutation, || {
            Ok(self
                .http
                .post(&url)
                .header(AUTHORIZATION, &self.auth_header)
                .header(CONTENT_TYPE, "application/json")
                .json(req))
        })?;

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
            if merged.parent_id.is_none() {
                merged.parent_id = req.parent_id.clone();
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
        let url = self.endpoint(&format!("entities/{id}"));
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self
                .http
                .put(&url)
                .header(AUTHORIZATION, &self.auth_header)
                .header(CONTENT_TYPE, "application/json")
                .json(entity))
        })?;
        self.handle_response(resp)
    }

    /// Safe `GET -> Merge -> PUT` update for an entity.
    pub fn update_entity(&self, id: &str, patch: &EntityPatch) -> Result<Entity> {
        let existing = self.get_entity(id)?;
        let merged = merge_entity_patch(&existing, patch);
        self.put_entity(id, &merged)
    }

    pub fn delete_entity(&self, id: &str) -> Result<()> {
        let url = self.endpoint(&format!("entities/{id}"));
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self
                .http
                .delete(&url)
                .header(AUTHORIZATION, &self.auth_header))
        })?;
        self.handle_empty_response(resp)
    }

    // -------------------------------------------------------------------------
    // Tags (`/api/v1/tags`)
    // -------------------------------------------------------------------------

    pub fn list_tags(&self) -> Result<Vec<Tag>> {
        let url = self.endpoint("tags");
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self.http.get(&url).header(AUTHORIZATION, &self.auth_header))
        })?;
        let parsed: ListResponse<Tag> = self.handle_response(resp)?;
        Ok(parsed.into_parts().0)
    }

    pub fn create_tag(&self, name: &str) -> Result<Tag> {
        let url = self.endpoint("tags");
        let body = json!({ "name": name });
        let resp = self.send_with_retry(RetryMode::SafeMutation, || {
            Ok(self
                .http
                .post(&url)
                .header(AUTHORIZATION, &self.auth_header)
                .header(CONTENT_TYPE, "application/json")
                .json(&body))
        })?;
        self.handle_response(resp)
    }

    pub fn get_tag(&self, id: &str) -> Result<Tag> {
        let url = self.endpoint(&format!("tags/{id}"));
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self.http.get(&url).header(AUTHORIZATION, &self.auth_header))
        })?;
        self.handle_response(resp)
    }

    pub fn update_tag(&self, id: &str, tag: &Tag) -> Result<Tag> {
        let url = self.endpoint(&format!("tags/{id}"));
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self
                .http
                .put(&url)
                .header(AUTHORIZATION, &self.auth_header)
                .header(CONTENT_TYPE, "application/json")
                .json(tag))
        })?;
        self.handle_response(resp)
    }

    pub fn delete_tag(&self, id: &str) -> Result<()> {
        let url = self.endpoint(&format!("tags/{id}"));
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self
                .http
                .delete(&url)
                .header(AUTHORIZATION, &self.auth_header))
        })?;
        self.handle_empty_response(resp)
    }

    // -------------------------------------------------------------------------
    // Entity Types (`/api/v1/entity-types`)
    // -------------------------------------------------------------------------

    pub fn list_entity_types(&self) -> Result<Vec<EntityType>> {
        let url = self.endpoint("entity-types");
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self.http.get(&url).header(AUTHORIZATION, &self.auth_header))
        })?;
        let parsed: ListResponse<EntityType> = self.handle_response(resp)?;
        Ok(parsed.into_parts().0)
    }

    pub fn create_entity_type(&self, req: &CreateEntityTypeRequest) -> Result<EntityType> {
        let url = self.endpoint("entity-types");
        let resp = self.send_with_retry(RetryMode::SafeMutation, || {
            Ok(self
                .http
                .post(&url)
                .header(AUTHORIZATION, &self.auth_header)
                .header(CONTENT_TYPE, "application/json")
                .json(req))
        })?;
        self.handle_response(resp)
    }

    pub fn delete_entity_type(&self, id: &str) -> Result<()> {
        let url = self.endpoint(&format!("entity-types/{id}"));
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self
                .http
                .delete(&url)
                .header(AUTHORIZATION, &self.auth_header))
        })?;
        self.handle_empty_response(resp)
    }

    // -------------------------------------------------------------------------
    // Attachments (`/api/v1/entities/{id}/attachments`)
    // -------------------------------------------------------------------------

    pub fn upload_attachment(&self, entity_id: &str, file_path: &Path) -> Result<Attachment> {
        self.upload_attachment_as(entity_id, file_path, None)
    }

    /// Upload a local file as an attachment with an optional overridden remote filename.
    pub fn upload_attachment_as(
        &self,
        entity_id: &str,
        file_path: &Path,
        remote_name: Option<&str>,
    ) -> Result<Attachment> {
        let effective_name = match remote_name {
            Some(name) => {
                let trimmed = name.trim();
                if trimmed.is_empty() {
                    return Err(HbctlError::InvalidInput(
                        "attachment filename cannot be empty".to_string(),
                    ));
                }
                trimmed.to_string()
            }
            None => file_path
                .file_name()
                .and_then(|n| n.to_str())
                .ok_or_else(|| {
                    HbctlError::InvalidInput(format!("invalid file path '{}'", file_path.display()))
                })?
                .to_string(),
        };

        let bytes = fs::read(file_path)?;
        self.upload_attachment_bytes(entity_id, &effective_name, bytes)
    }

    /// Upload raw attachment bytes under the given `remote_name`.
    pub fn upload_attachment_bytes(
        &self,
        entity_id: &str,
        remote_name: &str,
        bytes: Vec<u8>,
    ) -> Result<Attachment> {
        let effective_name = remote_name.trim();
        if effective_name.is_empty() {
            return Err(HbctlError::InvalidInput(
                "attachment filename cannot be empty".to_string(),
            ));
        }

        let mime = mime_guess::from_path(effective_name).first_or_octet_stream();
        let att_type = if mime.type_() == "image" {
            "photo"
        } else {
            "attachment"
        };
        let url = self.endpoint(&format!("entities/{entity_id}/attachments"));

        let resp = self.send_with_retry(RetryMode::SafeMutation, || {
            let file_part = multipart::Part::bytes(bytes.clone())
                .file_name(effective_name.to_string())
                .mime_str(mime.essence_str())
                .map_err(|e| HbctlError::InvalidInput(format!("invalid MIME type: {e}")))?;

            let form = multipart::Form::new()
                .part("file", file_part)
                .text("name", effective_name.to_string())
                .text("type", att_type);

            Ok(self
                .http
                .post(&url)
                .header(AUTHORIZATION, &self.auth_header)
                .multipart(form))
        })?;

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
        let url = self.endpoint(&format!("entities/{entity_id}/attachments/{attachment_id}"));
        let mut resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self
                .download_http
                .get(&url)
                .header(AUTHORIZATION, &self.auth_header))
        })?;

        let status = resp.status();
        if !status.is_success() {
            let text = resp.text().unwrap_or_default();
            let safe_msg = redact_secret(&text, &self.raw_secret);
            return Err(HbctlError::Http {
                status: status.as_u16(),
                message: safe_msg,
            });
        }

        if let Some(parent) = dest_path.parent() {
            if !parent.as_os_str().is_empty() {
                fs::create_dir_all(parent)?;
            }
        }

        let mut file = File::create(dest_path)?;
        let written = io::copy(&mut resp, &mut file)?;
        Ok(written)
    }

    pub fn delete_attachment(&self, entity_id: &str, attachment_id: &str) -> Result<()> {
        let url = self.endpoint(&format!("entities/{entity_id}/attachments/{attachment_id}"));
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self
                .http
                .delete(&url)
                .header(AUTHORIZATION, &self.auth_header))
        })?;
        self.handle_empty_response(resp)
    }

    // -------------------------------------------------------------------------
    // Status (`/api/v1/status`) & Authentication (`/api/v1/users/login`, `/users/self`, `/users/refresh`)
    // -------------------------------------------------------------------------

    /// Fetch remote Homebox server status without authentication (`GET /api/v1/status`).
    pub fn get_status(base_url: &str, timeout_secs: u64) -> Result<ServerStatus> {
        let normalized = normalize_base_url(base_url)?;
        let http = Client::builder()
            .timeout(Duration::from_secs(timeout_secs.max(1)))
            .build()?;

        let url = format!("{normalized}/status");
        let resp = send_request_with_retry(RetryPolicy::default(), RetryMode::Idempotent, || {
            Ok(http.get(&url))
        })?;

        let status = resp.status();
        let text = resp.text()?;
        if !status.is_success() {
            return Err(HbctlError::Http {
                status: status.as_u16(),
                message: text,
            });
        }
        if text.trim().is_empty() {
            return Ok(ServerStatus::default());
        }
        serde_json::from_str(&text).map_err(HbctlError::from)
    }

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

        let url = format!("{normalized}/users/login");
        let body = json!({
            "username": username,
            "password": password,
            "stayLoggedIn": true,
        });
        let resp =
            send_request_with_retry(RetryPolicy::default(), RetryMode::SafeMutation, || {
                Ok(http
                    .post(&url)
                    .header(CONTENT_TYPE, "application/json")
                    .json(&body))
            })?;

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
        let url = self.endpoint("users/self");
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self.http.get(&url).header(AUTHORIZATION, &self.auth_header))
        })?;
        let parsed: UserSelfResponse = self.handle_response(resp)?;
        Ok(parsed.into_profile())
    }

    /// Refresh an active JWT session (`GET /api/v1/users/refresh`, falling back to `POST` on 405).
    pub fn refresh_token(&self) -> Result<LoginResponse> {
        let url = self.endpoint("users/refresh");
        let resp = self.send_with_retry(RetryMode::Idempotent, || {
            Ok(self.http.get(&url).header(AUTHORIZATION, &self.auth_header))
        })?;

        if resp.status().as_u16() == 405 {
            drop(resp);
            let post_resp = self.send_with_retry(RetryMode::SafeMutation, || {
                Ok(self
                    .http
                    .post(&url)
                    .header(AUTHORIZATION, &self.auth_header))
            })?;
            return self.handle_response(post_resp);
        }

        self.handle_response(resp)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::{Read, Write};
    use std::net::TcpListener;
    use std::sync::Arc;

    use mockito::{Matcher, Server};
    use tempfile::tempdir;

    use crate::client::models::CustomField;

    fn fast_policy() -> RetryPolicy {
        RetryPolicy {
            max_retries: 3,
            base_delay: Duration::from_millis(1),
            max_delay: Duration::from_millis(20),
        }
    }

    fn test_client(base_url: &str) -> HomeboxClient {
        HomeboxClient::new(base_url, "hb_super_secret_key", 5, 5)
            .expect("client")
            .with_retry_policy(fast_policy())
    }

    #[test]
    fn test_parse_retry_after_seconds_and_http_date() {
        let now = UNIX_EPOCH + Duration::from_secs(1_445_412_470); // 2015-10-21 07:27:50 GMT
        assert_eq!(parse_retry_after_at("0", now), Some(Duration::ZERO));
        assert_eq!(parse_retry_after_at("5", now), Some(Duration::from_secs(5)));
        assert_eq!(
            parse_retry_after_at(" 12 ", now),
            Some(Duration::from_secs(12))
        );
        assert_eq!(
            parse_retry_after_at("Wed, 21 Oct 2015 07:28:00 GMT", now),
            Some(Duration::from_secs(10))
        );
        assert_eq!(
            parse_retry_after_at("Wed, 21 Oct 2015 07:27:00 GMT", now),
            Some(Duration::ZERO)
        );
        assert_eq!(parse_retry_after_at("not-a-date", now), None);
        assert_eq!(
            parse_retry_after_at("Wed, 21 Foo 2015 07:28:00 GMT", now),
            None
        );
        assert_eq!(
            parse_retry_after_at("Wed, 21 Oct 2015 25:00:00 GMT", now),
            None
        );
    }

    #[test]
    fn test_retry_policy_backoff_and_retry_after_cap() {
        let policy = RetryPolicy {
            max_retries: 4,
            base_delay: Duration::from_millis(100),
            max_delay: Duration::from_millis(350),
        };
        assert_eq!(
            policy.delay_for_attempt(0, None),
            Duration::from_millis(100)
        );
        assert_eq!(
            policy.delay_for_attempt(1, None),
            Duration::from_millis(200)
        );
        assert_eq!(
            policy.delay_for_attempt(2, None),
            Duration::from_millis(350)
        );
        assert_eq!(
            policy.delay_for_attempt(100, None),
            Duration::from_millis(350)
        );
        assert_eq!(
            policy.delay_for_attempt(0, Some(Duration::ZERO)),
            Duration::ZERO
        );
        assert_eq!(
            policy.delay_for_attempt(0, Some(Duration::from_secs(5))),
            Duration::from_millis(350)
        );
    }

    #[test]
    fn test_retryable_status_modes() {
        for s in [429, 502, 503, 504] {
            assert!(is_retryable_status(s, RetryMode::Idempotent));
        }
        for s in [400, 401, 404, 405, 500] {
            assert!(!is_retryable_status(s, RetryMode::Idempotent));
        }

        assert!(is_retryable_status(429, RetryMode::SafeMutation));
        assert!(is_retryable_status(503, RetryMode::SafeMutation));
        for s in [502, 504, 400, 401, 404, 500] {
            assert!(!is_retryable_status(s, RetryMode::SafeMutation));
        }
    }

    #[test]
    fn test_get_retries_transient_statuses_and_respects_retry_after() {
        let mut server = Server::new();

        let m_429 = server
            .mock("GET", "/api/v1/entities/ent-1")
            .with_status(429)
            .with_header("Retry-After", "0")
            .with_body("rate limited")
            .expect(1)
            .create();
        let m_503 = server
            .mock("GET", "/api/v1/entities/ent-1")
            .with_status(503)
            .with_body("unavailable")
            .expect(1)
            .create();
        let m_200 = server
            .mock("GET", "/api/v1/entities/ent-1")
            .with_status(200)
            .with_body(r#"{"id":"ent-1","name":"Multimeter","quantity":1,"fields":[]}"#)
            .expect(1)
            .create();

        let client = test_client(&server.url());
        let ent = client.get_entity("ent-1").expect("retry should recover");
        assert_eq!(ent.name, "Multimeter");
        m_429.assert();
        m_503.assert();
        m_200.assert();

        let m_502 = server
            .mock("GET", "/api/v1/entities/ent-2")
            .with_status(502)
            .expect(1)
            .create();
        let m_504 = server
            .mock("GET", "/api/v1/entities/ent-2")
            .with_status(504)
            .expect(1)
            .create();
        let m_200_2 = server
            .mock("GET", "/api/v1/entities/ent-2")
            .with_status(200)
            .with_body(r#"{"id":"ent-2","name":"Scope","quantity":1,"fields":[]}"#)
            .expect(1)
            .create();

        let ent2 = client.get_entity("ent-2").expect("502/504 should recover");
        assert_eq!(ent2.name, "Scope");
        m_502.assert();
        m_504.assert();
        m_200_2.assert();
    }

    #[test]
    fn test_get_does_not_retry_client_errors_and_redacts_on_exhaustion() {
        let mut server = Server::new();

        let m_401 = server
            .mock("GET", "/api/v1/entities/ent-401")
            .with_status(401)
            .with_body("unauthorized")
            .expect(1)
            .create();

        let client = test_client(&server.url());
        let err = client.get_entity("ent-401").unwrap_err();
        assert!(matches!(err, HbctlError::Http { status: 401, .. }));
        m_401.assert();

        let m_503_all = server
            .mock("GET", "/api/v1/entities/ent-503")
            .with_status(503)
            .with_body("backend failed for token hb_super_secret_key")
            .expect(4)
            .create();

        let err = client.get_entity("ent-503").unwrap_err();
        match err {
            HbctlError::Http { status, message } => {
                assert_eq!(status, 503);
                assert!(!message.contains("hb_super_secret_key"));
                assert!(message.contains("***"));
            }
            other => panic!("expected Http error, got {other:?}"),
        }
        m_503_all.assert();
    }

    #[test]
    fn test_put_delete_and_safe_post_retry_semantics() {
        let mut server = Server::new();
        let client = test_client(&server.url());

        let m_put_502 = server
            .mock("PUT", "/api/v1/entities/ent-1")
            .with_status(502)
            .expect(1)
            .create();
        let m_put_200 = server
            .mock("PUT", "/api/v1/entities/ent-1")
            .with_status(200)
            .with_body(r#"{"id":"ent-1","name":"Updated","quantity":1,"fields":[]}"#)
            .expect(1)
            .create();
        let put_ent = client
            .put_entity(
                "ent-1",
                &Entity {
                    id: "ent-1".to_string(),
                    name: "Updated".to_string(),
                    quantity: 1,
                    ..Default::default()
                },
            )
            .expect("put retry");
        assert_eq!(put_ent.name, "Updated");
        m_put_502.assert();
        m_put_200.assert();

        let m_del_503 = server
            .mock("DELETE", "/api/v1/entities/ent-1")
            .with_status(503)
            .expect(1)
            .create();
        let m_del_204 = server
            .mock("DELETE", "/api/v1/entities/ent-1")
            .with_status(204)
            .expect(1)
            .create();
        client.delete_entity("ent-1").expect("delete retry");
        m_del_503.assert();
        m_del_204.assert();

        let m_post_429 = server
            .mock("POST", "/api/v1/entities")
            .with_status(429)
            .with_header("Retry-After", "0")
            .expect(1)
            .create();
        let m_post_201 = server
            .mock("POST", "/api/v1/entities")
            .with_status(201)
            .with_body(r#"{"id":"ent-new","name":"Widget","quantity":1,"fields":[]}"#)
            .expect(1)
            .create();
        let created = client
            .create_entity(&CreateEntityRequest {
                name: "Widget".to_string(),
                quantity: Some(1),
                ..Default::default()
            })
            .expect("post 429 retry");
        assert_eq!(created.id, "ent-new");
        m_post_429.assert();
        m_post_201.assert();

        // POST must NOT retry 502 (avoid duplicate creates after server-side processing).
        let m_post_502 = server
            .mock("POST", "/api/v1/entities")
            .with_status(502)
            .expect(1)
            .create();
        let err = client
            .create_entity(&CreateEntityRequest {
                name: "NoRetry502".to_string(),
                quantity: Some(1),
                ..Default::default()
            })
            .unwrap_err();
        assert!(matches!(err, HbctlError::Http { status: 502, .. }));
        m_post_502.assert();

        // Upload attachment retries 503 and rebuilds multipart form cleanly.
        let dir = tempdir().expect("tempdir");
        let upload_path = dir.path().join("manual.txt");
        fs::write(&upload_path, b"hello homebox").expect("write upload");

        let m_up_503 = server
            .mock("POST", "/api/v1/entities/ent-1/attachments")
            .match_body(Matcher::Regex("hello homebox".to_string()))
            .with_status(503)
            .expect(1)
            .create();
        let m_up_201 = server
            .mock("POST", "/api/v1/entities/ent-1/attachments")
            .match_body(Matcher::Regex("hello homebox".to_string()))
            .with_status(201)
            .with_body(r#"{"id":"att-1","title":"manual.txt"}"#)
            .expect(1)
            .create();
        let att = client
            .upload_attachment("ent-1", &upload_path)
            .expect("upload retry");
        assert_eq!(att.id, "att-1");
        m_up_503.assert();
        m_up_201.assert();

        // Download attachment retries 503 and does not leave a truncated file on failed attempts.
        let dl_path = dir.path().join("sub/downloaded.txt");
        let m_dl_503 = server
            .mock("GET", "/api/v1/entities/ent-1/attachments/att-1")
            .with_status(503)
            .expect(1)
            .create();
        let m_dl_200 = server
            .mock("GET", "/api/v1/entities/ent-1/attachments/att-1")
            .with_status(200)
            .with_body(b"pdf-bytes")
            .expect(1)
            .create();
        let bytes = client
            .download_attachment("ent-1", "att-1", &dl_path)
            .expect("download retry");
        assert_eq!(bytes, 9);
        assert_eq!(fs::read(&dl_path).expect("read dl"), b"pdf-bytes");
        m_dl_503.assert();
        m_dl_200.assert();
    }

    fn read_http_headers(stream: &mut std::net::TcpStream) -> String {
        let mut buf = [0u8; 4096];
        let mut collected = Vec::new();
        loop {
            match stream.read(&mut buf) {
                Ok(0) => break,
                Ok(n) => {
                    collected.extend_from_slice(&buf[..n]);
                    if collected.windows(4).any(|w| w == b"\r\n\r\n") {
                        break;
                    }
                }
                Err(_) => break,
            }
        }
        String::from_utf8_lossy(&collected).into_owned()
    }

    #[test]
    fn test_get_retries_transient_network_drop() {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind");
        let addr = listener.local_addr().expect("addr");

        let handle = thread::spawn(move || {
            // 1st connection: drop immediately after accepting to force EOF network error.
            let (conn1, _) = listener.accept().expect("accept 1");
            drop(conn1);

            // 2nd connection: read request headers, reply 200 OK.
            let (mut conn2, _) = listener.accept().expect("accept 2");
            let _ = read_http_headers(&mut conn2);
            let body = r#"{"id":"ent-net","name":"Recovered","quantity":1,"fields":[]}"#;
            let resp = format!(
                "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                body.len(),
                body
            );
            conn2.write_all(resp.as_bytes()).expect("write");
            conn2.flush().expect("flush");
        });

        let client = test_client(&format!("http://{addr}"));
        let ent = client
            .get_entity("ent-net")
            .expect("network drop should retry and succeed");
        assert_eq!(ent.name, "Recovered");
        handle.join().expect("server thread");
    }

    #[test]
    fn test_hydrate_entity_fields_concurrent_preserves_order_and_skips_hydrated() {
        let mut server = Server::new();
        let mut mocks = Vec::new();
        let mut input = Vec::new();

        for idx in 0..12usize {
            let id = format!("ent-{idx}");
            if idx % 3 == 0 {
                // Already hydrated: fields is Some(...)
                input.push(Entity {
                    id,
                    name: format!("Already-{idx}"),
                    quantity: 1,
                    fields: Some(vec![CustomField {
                        name: "Slot".to_string(),
                        value: Some(Value::String(idx.to_string())),
                        ..Default::default()
                    }]),
                    ..Default::default()
                });
            } else if idx == 11 {
                // Empty id should not be fetched.
                input.push(Entity {
                    id: String::new(),
                    name: "NoId".to_string(),
                    quantity: 1,
                    fields: None,
                    ..Default::default()
                });
            } else {
                let path = format!("/api/v1/entities/{id}");
                let body = format!(
                    r#"{{"id":"{id}","name":"Hydrated-{idx}","quantity":1,"fields":[{{"name":"Idx","type":"text","value":"{idx}","textValue":"{idx}"}}]}}"#
                );
                mocks.push(
                    server
                        .mock("GET", path.as_str())
                        .with_status(200)
                        .with_body(body)
                        .expect(1)
                        .create(),
                );
                input.push(Entity {
                    id,
                    name: format!("Summary-{idx}"),
                    quantity: 1,
                    fields: None,
                    ..Default::default()
                });
            }
        }

        let client = test_client(&server.url()).with_hydrate_concurrency(4);
        let hydrated = client.hydrate_entity_fields(input).expect("hydrate");
        assert_eq!(hydrated.len(), 12);

        for (idx, ent) in hydrated.iter().enumerate() {
            if idx % 3 == 0 {
                assert_eq!(ent.id, format!("ent-{idx}"));
                assert_eq!(ent.name, format!("Already-{idx}"));
                assert_eq!(
                    ent.field_value("Slot").as_deref(),
                    Some(idx.to_string().as_str())
                );
            } else if idx == 11 {
                assert!(ent.id.is_empty());
                assert_eq!(ent.name, "NoId");
                assert!(ent.fields.is_none());
            } else {
                assert_eq!(ent.id, format!("ent-{idx}"));
                assert_eq!(ent.name, format!("Hydrated-{idx}"));
                assert_eq!(
                    ent.field_value("Idx").as_deref(),
                    Some(idx.to_string().as_str())
                );
            }
        }

        for m in mocks {
            m.assert();
        }
    }

    #[test]
    fn test_hydrate_entity_fields_executes_concurrently() {
        let listener = TcpListener::bind("127.0.0.1:0").expect("bind");
        let addr = listener.local_addr().expect("addr");

        let in_flight = Arc::new(AtomicUsize::new(0));
        let max_in_flight = Arc::new(AtomicUsize::new(0));
        let in_flight_srv = Arc::clone(&in_flight);
        let max_srv = Arc::clone(&max_in_flight);

        let srv_handle = thread::spawn(move || {
            let mut conn_handles = Vec::new();
            for _ in 0..4 {
                let (mut stream, _) = listener.accept().expect("accept");
                let cur = Arc::clone(&in_flight_srv);
                let max = Arc::clone(&max_srv);
                conn_handles.push(thread::spawn(move || {
                    let active = cur.fetch_add(1, Ordering::SeqCst) + 1;
                    max.fetch_max(active, Ordering::SeqCst);

                    let req = read_http_headers(&mut stream);
                    let first_line = req.lines().next().unwrap_or("");
                    let id = first_line
                        .split_whitespace()
                        .nth(1)
                        .and_then(|p| p.rsplit('/').next())
                        .unwrap_or("unknown");

                    thread::sleep(Duration::from_millis(30));

                    let body = format!(
                        r#"{{"id":"{id}","name":"Item-{id}","quantity":1,"fields":[]}}"#
                    );
                    let resp = format!(
                        "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
                        body.len(),
                        body
                    );
                    stream.write_all(resp.as_bytes()).expect("write");
                    stream.flush().expect("flush");
                    cur.fetch_sub(1, Ordering::SeqCst);
                }));
            }
            for h in conn_handles {
                h.join().expect("conn thread");
            }
        });

        let entities: Vec<Entity> = (0..4)
            .map(|i| Entity {
                id: format!("e-{i}"),
                name: format!("Summary-{i}"),
                quantity: 1,
                fields: None,
                ..Default::default()
            })
            .collect();

        let client = test_client(&format!("http://{addr}")).with_hydrate_concurrency(4);
        let hydrated = client
            .hydrate_entity_fields(entities)
            .expect("concurrent hydrate");
        srv_handle.join().expect("server thread");

        assert_eq!(hydrated.len(), 4);
        for (i, ent) in hydrated.iter().enumerate() {
            assert_eq!(ent.id, format!("e-{i}"));
            assert_eq!(ent.name, format!("Item-e-{i}"));
        }
        assert!(
            max_in_flight.load(Ordering::SeqCst) >= 2,
            "expected >= 2 concurrent requests, observed {}",
            max_in_flight.load(Ordering::SeqCst)
        );
    }

    #[test]
    fn test_hydrate_entity_fields_propagates_error_and_noop() {
        let mut server = Server::new();
        let client = test_client(&server.url()).with_hydrate_concurrency(4);

        // Empty and already-hydrated inputs make zero requests.
        assert!(client.hydrate_entity_fields(Vec::new()).unwrap().is_empty());
        let already = vec![Entity {
            id: "ok-1".to_string(),
            name: "Done".to_string(),
            quantity: 1,
            fields: Some(Vec::new()),
            ..Default::default()
        }];
        let out = client.hydrate_entity_fields(already.clone()).unwrap();
        assert_eq!(out, already);

        // One failing entity returns Err(404).
        let _ok_mocks: Vec<_> = (0..5)
            .filter(|i| *i != 2)
            .map(|i| {
                server
                    .mock("GET", format!("/api/v1/entities/ent-{i}").as_str())
                    .with_status(200)
                    .with_body(format!(
                        r#"{{"id":"ent-{i}","name":"Item-{i}","quantity":1,"fields":[]}}"#
                    ))
                    .expect_at_most(1)
                    .create()
            })
            .collect();
        let m_404 = server
            .mock("GET", "/api/v1/entities/ent-2")
            .with_status(404)
            .with_body("missing")
            .expect(1)
            .create();

        let entities: Vec<Entity> = (0..5)
            .map(|i| Entity {
                id: format!("ent-{i}"),
                name: format!("Summary-{i}"),
                quantity: 1,
                fields: None,
                ..Default::default()
            })
            .collect();

        let err = client.hydrate_entity_fields(entities).unwrap_err();
        assert!(matches!(err, HbctlError::Http { status: 404, .. }));
        m_404.assert();
    }

    #[test]
    fn test_tag_get_update_delete_and_retry() {
        let mut server = Server::new();
        let client = test_client(&server.url());

        let m_get = server
            .mock("GET", "/api/v1/tags/tag-1")
            .with_status(200)
            .with_body(r#"{"id":"tag-1","name":"electronics","description":"Electronic parts"}"#)
            .expect(1)
            .create();
        let tag = client.get_tag("tag-1").expect("get tag");
        assert_eq!(tag.name, "electronics");
        m_get.assert();

        let m_put_503 = server
            .mock("PUT", "/api/v1/tags/tag-1")
            .with_status(503)
            .expect(1)
            .create();
        let m_put_200 = server
            .mock("PUT", "/api/v1/tags/tag-1")
            .with_status(200)
            .with_body(
                r##"{"id":"tag-1","name":"Electronics v2","description":"Electronic parts","color":"#00ff00"}"##,
            )
            .expect(1)
            .create();
        let updated = client
            .update_tag(
                "tag-1",
                &Tag {
                    id: "tag-1".to_string(),
                    name: "Electronics v2".to_string(),
                    description: "Electronic parts".to_string(),
                    color: Some("#00ff00".to_string()),
                    ..Default::default()
                },
            )
            .expect("update tag");
        assert_eq!(updated.name, "Electronics v2");
        assert_eq!(updated.color.as_deref(), Some("#00ff00"));
        m_put_503.assert();
        m_put_200.assert();

        let m_del = server
            .mock("DELETE", "/api/v1/tags/tag-1")
            .with_status(204)
            .expect(1)
            .create();
        client.delete_tag("tag-1").expect("delete tag");
        m_del.assert();
    }

    #[test]
    fn test_status_and_entity_type_create_delete() {
        let mut server = Server::new();

        let m_status = server
            .mock("GET", "/api/v1/status")
            .match_header("authorization", Matcher::Missing)
            .with_status(200)
            .with_body(r#"{"version":"v0.26.2","commit":"abc1234","health":true}"#)
            .expect(1)
            .create();
        let st = HomeboxClient::get_status(&server.url(), 10).expect("get status");
        assert_eq!(st.version.as_deref(), Some("v0.26.2"));
        assert_eq!(st.commit.as_deref(), Some("abc1234"));
        assert_eq!(st.health, Some(true));
        m_status.assert();

        let client = test_client(&server.url());
        let m_create = server
            .mock("POST", "/api/v1/entity-types")
            .match_body(Matcher::PartialJson(json!({
                "name": "Storage Bin",
                "description": "Container",
                "isLocation": true
            })))
            .with_status(201)
            .with_body(
                r#"{"id":"et-bin","name":"Storage Bin","description":"Container","isLocation":true}"#,
            )
            .expect(1)
            .create();
        let created = client
            .create_entity_type(&CreateEntityTypeRequest {
                name: "Storage Bin".into(),
                description: Some("Container".into()),
                is_location: true,
            })
            .expect("create entity type");
        assert_eq!(created.id, "et-bin");
        assert!(created.is_location);
        m_create.assert();

        let m_del = server
            .mock("DELETE", "/api/v1/entity-types/et-bin")
            .with_status(204)
            .expect(1)
            .create();
        client
            .delete_entity_type("et-bin")
            .expect("delete entity type");
        m_del.assert();
    }
}

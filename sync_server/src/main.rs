use std::collections::{HashMap, VecDeque};
use std::net::SocketAddr;
use std::str::FromStr;
use std::sync::Arc;
use std::time::{Duration, Instant};

use anyhow::{bail, Context};
use axum::extract::{Query, State};
use axum::http::{header, HeaderValue, Method, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::{Deserialize, Serialize};
use sqlx::sqlite::SqliteConnectOptions;
use sqlx::sqlite::SqlitePoolOptions;
use sqlx::{Executor, Pool, Row, Sqlite, Transaction};
use tower_http::cors::{Any, CorsLayer};
use tower_http::limit::RequestBodyLimitLayer;
use tower_http::trace::TraceLayer;
use tracing::{error, info};
use tracing_subscriber::EnvFilter;

mod auth;
mod metrics;
mod web;

const MAX_RECORD_B64_LEN: usize = 512 * 1024; // per-field b64 string length cap
const MAX_PULL_LIMIT: i64 = 500;
const DEFAULT_BODY_LIMIT_BYTES: usize = 5 * 1024 * 1024;
const DEFAULT_MAX_PUSH_RECORDS: usize = 500;

const TYPE_TODO_ATTACHMENT: &str = "todo_attachment";
const TYPE_TODO_ATTACHMENT_CHUNK: &str = "todo_attachment_chunk";
const TYPE_TODO_ATTACHMENT_COMMIT: &str = "todo_attachment_commit";

#[derive(Debug, Clone)]
struct BillingConfig {
    default_base_storage_b64: Option<i64>,
    default_base_outbound_bytes: Option<i64>,
    plans: HashMap<String, SubscriptionPlan>,
}

impl BillingConfig {
    fn load_from_env() -> anyhow::Result<Self> {
        let default_base_storage_b64 = env_i64("BASE_USER_STORAGE_B64")
            .or_else(|| env_i64("MAX_TOTAL_B64_PER_USER"))
            .filter(|v| *v >= 0);

        let default_base_outbound_bytes = env_i64("BASE_USER_OUTBOUND_BYTES").filter(|v| *v >= 0);

        let plans = load_subscription_plans_from_env().context("load SUBSCRIPTION_PLANS_JSON")?;

        Ok(Self {
            default_base_storage_b64,
            default_base_outbound_bytes,
            plans,
        })
    }
}

#[derive(Debug, Clone, Deserialize)]
struct SubscriptionPlanConfig {
    id: String,
    name: String,
    #[serde(rename = "durationDays")]
    duration_days: Option<i64>,
    #[serde(rename = "durationSeconds")]
    duration_seconds: Option<i64>,
    #[serde(rename = "durationMs")]
    duration_ms: Option<i64>,
    #[serde(rename = "extraStorageB64")]
    extra_storage_b64: Option<i64>,
    #[serde(rename = "extraOutboundBytes")]
    extra_outbound_bytes: Option<i64>,
}

#[derive(Debug, Clone)]
struct SubscriptionPlan {
    id: String,
    name: String,
    duration_ms: i64,
    extra_storage_b64: i64,
    extra_outbound_bytes: i64,
}

impl SubscriptionPlan {
    fn from_config(cfg: SubscriptionPlanConfig) -> anyhow::Result<Self> {
        let id = cfg.id.trim().to_lowercase();
        if id.is_empty() {
            bail!("subscription plan id is required");
        }

        let name = cfg.name.trim().to_string();
        if name.is_empty() {
            bail!("subscription plan name is required: {id}");
        }

        let duration_ms = cfg
            .duration_ms
            .or_else(|| cfg.duration_seconds.map(|v| v.saturating_mul(1000)))
            .or_else(|| {
                cfg.duration_days
                    .map(|v| v.saturating_mul(24 * 60 * 60 * 1000))
            })
            .unwrap_or(0);
        if duration_ms <= 0 {
            bail!("subscription plan duration is required: {id}");
        }

        let extra_storage_b64 = cfg.extra_storage_b64.unwrap_or(0).max(0);
        let extra_outbound_bytes = cfg.extra_outbound_bytes.unwrap_or(0).max(0);

        Ok(Self {
            id,
            name,
            duration_ms,
            extra_storage_b64,
            extra_outbound_bytes,
        })
    }
}

#[derive(Debug, Clone)]
struct AdminConfig {
    entry_path: String,
    username: Option<String>,
    password: Option<String>,
    session_ttl_secs: i64,
}

impl AdminConfig {
    fn load_from_env() -> Self {
        let entry_path = normalize_path_prefix(
            std::env::var("ADMIN_ENTRY_PATH").unwrap_or_else(|_| "/admin".to_string()),
        );
        let username = std::env::var("ADMIN_USERNAME")
            .ok()
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty());
        let password = std::env::var("ADMIN_PASSWORD")
            .ok()
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty());
        let session_ttl_secs = env_i64("ADMIN_SESSION_TTL_SECS")
            .unwrap_or(12 * 60 * 60)
            .max(60);

        Self {
            entry_path,
            username,
            password,
            session_ttl_secs,
        }
    }

    fn enabled(&self) -> bool {
        self.username.is_some() && self.password.is_some()
    }
}

#[derive(Clone)]
struct AppState {
    db: Pool<Sqlite>,
    limiter: Arc<tokio::sync::Mutex<RateLimiter>>,
    auth_limiter: Arc<tokio::sync::Mutex<RateLimiter>>,
    auth: Arc<auth::AuthService>,
    max_push_records: usize,
    max_records_per_user: Option<i64>,
    billing: Arc<BillingConfig>,
    admin: AdminConfig,
    metrics: Arc<metrics::Metrics>,
    started_at: Instant,
    site_created_at_ms_utc: Option<i64>,
}

struct RateLimiter {
    per_key: HashMap<String, (Instant, u32, u64)>,
    lru: VecDeque<(String, u64)>,
    window: Duration,
    max_requests: u32,
    max_entries: usize,
    next_id: u64,
}

impl RateLimiter {
    fn new(window: Duration, max_requests: u32, max_entries: usize) -> Self {
        Self {
            per_key: HashMap::new(),
            lru: VecDeque::new(),
            window,
            max_requests,
            max_entries: max_entries.max(1),
            next_id: 0,
        }
    }

    fn check(&mut self, key: &str) -> bool {
        let now = Instant::now();
        self.next_id = self.next_id.wrapping_add(1);
        let id = self.next_id;

        let key = key.to_string();
        let allowed = {
            let entry = self.per_key.entry(key.clone()).or_insert((now, 0, id));
            entry.2 = id;

            if now.duration_since(entry.0) > self.window {
                *entry = (now, 0, id);
            }

            if entry.1 >= self.max_requests {
                false
            } else {
                entry.1 += 1;
                true
            }
        };

        self.lru.push_back((key, id));
        self.evict_if_needed();
        if !allowed {
            return false;
        }
        true
    }

    fn evict_if_needed(&mut self) {
        // Drop stale LRU pointers.
        while let Some((k, id)) = self.lru.front() {
            let Some(cur) = self.per_key.get(k) else {
                self.lru.pop_front();
                continue;
            };
            if cur.2 != *id {
                self.lru.pop_front();
                continue;
            }
            break;
        }

        while self.per_key.len() > self.max_entries {
            let Some((k, id)) = self.lru.pop_front() else {
                break;
            };
            if self.per_key.get(&k).map(|cur| cur.2) == Some(id) {
                self.per_key.remove(&k);
            }
        }

        // Avoid unbounded growth when the same few keys are hit repeatedly.
        if self.lru.len() > self.max_entries.saturating_mul(4) {
            self.lru.clear();
            for (k, cur) in self.per_key.iter() {
                self.lru.push_back((k.clone(), cur.2));
            }
        }
    }
}

#[derive(Serialize)]
struct ErrorBody {
    error: String,
}

fn json_error(status: StatusCode, msg: impl Into<String>) -> (StatusCode, Json<ErrorBody>) {
    (status, Json(ErrorBody { error: msg.into() }))
}

async fn track_api_metrics(
    State(state): State<AppState>,
    req: axum::http::Request<axum::body::Body>,
    next: axum::middleware::Next,
) -> Response {
    let method = req.method().clone();
    let path = req.uri().path().to_string();
    let at_ms = now_ms_utc();
    let in_bytes = req
        .headers()
        .get(header::CONTENT_LENGTH)
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.parse::<i64>().ok())
        .unwrap_or(0)
        .max(0);

    let should_track = path.starts_with("/v1/")
        && path != "/v1/health"
        && method != Method::OPTIONS
        && method != Method::HEAD;

    let resp = next.run(req).await;

    if should_track {
        let out_bytes = resp
            .headers()
            .get(header::CONTENT_LENGTH)
            .and_then(|v| v.to_str().ok())
            .and_then(|s| s.parse::<i64>().ok())
            .unwrap_or_else(|| {
                use axum::body::HttpBody as _;
                resp.body()
                    .size_hint()
                    .exact()
                    .or_else(|| resp.body().size_hint().upper())
                    .unwrap_or(0) as i64
            })
            .max(0);

        state.metrics.record_api_request(at_ms, in_bytes, out_bytes);
    }

    resp
}

fn json_bytes<T: Serialize>(value: &T) -> Result<(Response, i64), (StatusCode, Json<ErrorBody>)> {
    let bytes = serde_json::to_vec(value)
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "serialize error"))?;
    let len = bytes.len() as i64;
    let mut resp = Response::new(axum::body::Body::from(bytes));
    resp.headers_mut().insert(
        header::CONTENT_TYPE,
        HeaderValue::from_static("application/json"),
    );
    Ok((resp, len))
}

#[derive(Debug, Clone)]
struct UserBillingRow {
    base_storage_b64: Option<i64>,
    base_outbound_bytes: Option<i64>,
    subscription_plan_id: Option<String>,
    subscription_expires_at_ms_utc: Option<i64>,
    banned_at_ms_utc: Option<i64>,
    stored_b64: i64,
    api_outbound_bytes: i64,
}

#[derive(Debug, Clone)]
struct EffectiveQuota {
    base_storage_b64: Option<i64>,
    base_outbound_bytes: Option<i64>,
    bonus_storage_b64: i64,
    bonus_outbound_bytes: i64,
    allowed_storage_b64: Option<i64>,
    allowed_outbound_bytes: Option<i64>,
    active_plan_id: Option<String>,
    active_plan_name: Option<String>,
    active_plan_expires_at_ms_utc: Option<i64>,
}

fn compute_effective_quota(
    billing: &BillingConfig,
    user: &UserBillingRow,
    now_ms_utc: i64,
) -> EffectiveQuota {
    let base_storage_b64 = user
        .base_storage_b64
        .or(billing.default_base_storage_b64)
        .filter(|v| *v >= 0);
    let base_outbound_bytes = user
        .base_outbound_bytes
        .or(billing.default_base_outbound_bytes)
        .filter(|v| *v >= 0);

    let mut bonus_storage_b64 = 0i64;
    let mut bonus_outbound_bytes = 0i64;
    let mut active_plan_id = None;
    let mut active_plan_name = None;

    let expires_at = user.subscription_expires_at_ms_utc.unwrap_or(0);
    if expires_at > now_ms_utc {
        if let Some(plan_id) = user
            .subscription_plan_id
            .as_deref()
            .map(|s| s.trim().to_lowercase())
            .filter(|s| !s.is_empty())
        {
            if let Some(plan) = billing.plans.get(&plan_id) {
                bonus_storage_b64 = plan.extra_storage_b64.max(0);
                bonus_outbound_bytes = plan.extra_outbound_bytes.max(0);
                active_plan_id = Some(plan.id.clone());
                active_plan_name = Some(plan.name.clone());
            }
        }
    }

    let allowed_storage_b64 = base_storage_b64.map(|v| v.saturating_add(bonus_storage_b64));
    let allowed_outbound_bytes =
        base_outbound_bytes.map(|v| v.saturating_add(bonus_outbound_bytes));

    EffectiveQuota {
        base_storage_b64,
        base_outbound_bytes,
        bonus_storage_b64,
        bonus_outbound_bytes,
        allowed_storage_b64,
        allowed_outbound_bytes,
        active_plan_id,
        active_plan_name,
        active_plan_expires_at_ms_utc: user
            .subscription_expires_at_ms_utc
            .filter(|v| *v > now_ms_utc),
    }
}

async fn clear_subscription_if_expired<'e, E>(
    executor: E,
    user_id: i64,
    subscription_plan_id: &Option<String>,
    subscription_expires_at_ms_utc: Option<i64>,
    now_ms_utc: i64,
) -> Result<bool, sqlx::Error>
where
    E: Executor<'e, Database = Sqlite>,
{
    let has_plan = subscription_plan_id
        .as_deref()
        .map(|s| !s.trim().is_empty())
        .unwrap_or(false);
    if !has_plan {
        return Ok(false);
    }

    let expires_at = subscription_expires_at_ms_utc.unwrap_or(0);
    if expires_at > now_ms_utc {
        return Ok(false);
    }

    let updated = sqlx::query(
        r#"UPDATE users
           SET subscription_plan_id = NULL,
               subscription_expires_at_ms_utc = NULL
           WHERE id = ?
             AND subscription_plan_id IS NOT NULL
             AND TRIM(subscription_plan_id) != ''
             AND (subscription_expires_at_ms_utc IS NULL OR subscription_expires_at_ms_utc <= ?)"#,
    )
    .bind(user_id)
    .bind(now_ms_utc)
    .execute(executor)
    .await?;

    Ok(updated.rows_affected() > 0)
}

async fn ensure_user(
    tx: &mut Transaction<'_, Sqlite>,
    oauth_provider: &str,
    oauth_sub: &str,
    now_ms_utc: i64,
) -> anyhow::Result<(i64, bool)> {
    let existing: Option<i64> =
        sqlx::query_scalar(r#"SELECT id FROM users WHERE oauth_provider = ? AND oauth_sub = ?"#)
            .bind(oauth_provider)
            .bind(oauth_sub)
            .fetch_optional(&mut **tx)
            .await?;
    if let Some(id) = existing {
        return Ok((id, false));
    }

    let created = sqlx::query(
        r#"INSERT INTO users (oauth_provider, oauth_sub, created_at_ms_utc)
       VALUES (?, ?, ?)"#,
    )
    .bind(oauth_provider)
    .bind(oauth_sub)
    .bind(now_ms_utc)
    .execute(&mut **tx)
    .await?;

    Ok((created.last_insert_rowid(), true))
}

fn now_ms_utc() -> i64 {
    use std::time::{SystemTime, UNIX_EPOCH};
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as i64
}

async fn reset_user_api_outbound_if_new_month<'e, E>(
    executor: E,
    user_id: i64,
    now_ms_utc: i64,
) -> Result<(), sqlx::Error>
where
    E: Executor<'e, Database = Sqlite>,
{
    // `api_outbound_bytes` is tracked per UTC month. When the month rolls over, reset usage to 0.
    sqlx::query(
        r#"UPDATE users
           SET api_outbound_bytes = 0,
               api_outbound_month_utc = CAST(strftime('%Y%m', ? / 1000, 'unixepoch') AS INTEGER)
           WHERE id = ?
             AND api_outbound_month_utc != CAST(strftime('%Y%m', ? / 1000, 'unixepoch') AS INTEGER)"#,
    )
    .bind(now_ms_utc)
    .bind(user_id)
    .bind(now_ms_utc)
    .execute(executor)
    .await?;
    Ok(())
}

async fn reset_all_users_api_outbound_if_new_month<'e, E>(
    executor: E,
    now_ms_utc: i64,
) -> Result<(), sqlx::Error>
where
    E: Executor<'e, Database = Sqlite>,
{
    sqlx::query(
        r#"UPDATE users
           SET api_outbound_bytes = 0,
               api_outbound_month_utc = CAST(strftime('%Y%m', ? / 1000, 'unixepoch') AS INTEGER)
           WHERE api_outbound_month_utc != CAST(strftime('%Y%m', ? / 1000, 'unixepoch') AS INTEGER)"#,
    )
    .bind(now_ms_utc)
    .bind(now_ms_utc)
    .execute(executor)
    .await?;
    Ok(())
}

fn normalize_database_url(url: String) -> String {
    if url == "sqlite::memory:" {
        return url;
    }

    let cwd = std::env::current_dir().ok();

    if let Some(rest) = url.strip_prefix("sqlite://") {
        if rest.starts_with('/') {
            return url;
        }
        if let Some(cwd) = cwd {
            return format!("sqlite://{}", cwd.join(rest).display());
        }
        return url;
    }

    if let Some(rest) = url.strip_prefix("sqlite:") {
        if rest.starts_with('/') {
            return format!("sqlite://{rest}");
        }
        if let Some(cwd) = cwd {
            return format!("sqlite://{}", cwd.join(rest).display());
        }
        return url;
    }

    url
}

fn env_i64(key: &str) -> Option<i64> {
    std::env::var(key).ok().and_then(|s| s.trim().parse().ok())
}

fn unquote_env_json(raw: &str) -> String {
    let trimmed = raw.trim();
    trimmed
        .strip_prefix('\'')
        .and_then(|s| s.strip_suffix('\''))
        .or_else(|| trimmed.strip_prefix('"').and_then(|s| s.strip_suffix('"')))
        .unwrap_or(trimmed)
        .to_string()
}

fn load_subscription_plans_from_env() -> anyhow::Result<HashMap<String, SubscriptionPlan>> {
    let raw = std::env::var("SUBSCRIPTION_PLANS_JSON").unwrap_or_else(|_| "[]".to_string());
    let json = unquote_env_json(&raw);
    let list: Vec<SubscriptionPlanConfig> =
        serde_json::from_str(&json).context("parse SUBSCRIPTION_PLANS_JSON")?;

    let mut out = HashMap::new();
    for cfg in list {
        let plan = SubscriptionPlan::from_config(cfg)?;
        if out.contains_key(&plan.id) {
            bail!("duplicate subscription plan id: {}", plan.id);
        }
        out.insert(plan.id.clone(), plan);
    }
    Ok(out)
}

fn normalize_path_prefix(raw: String) -> String {
    let mut s = raw.trim().to_string();
    if s.is_empty() {
        s = "/admin".to_string();
    }
    if !s.starts_with('/') {
        s.insert(0, '/');
    }
    while s.ends_with('/') && s.len() > 1 {
        s.pop();
    }
    s
}

#[derive(Debug, Deserialize)]
struct PutKeyBundleRequest {
    #[serde(rename = "expectedBundleVersion")]
    expected_bundle_version: i64,
    bundle: serde_json::Value,
}

async fn get_key_bundle(
    State(state): State<AppState>,
    user: auth::AuthedUser,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    let now_ms = now_ms_utc();
    let row = sqlx::query(
        r#"SELECT bundle_version, bundle_json
       FROM key_bundles WHERE user_id = ?"#,
    )
    .bind(user.user_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    match row {
        None => Err(json_error(StatusCode::NOT_FOUND, "key bundle not found")),
        Some(row) => {
            let bundle_version: i64 = row
                .try_get("bundle_version")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
            let bundle_json: String = row
                .try_get("bundle_json")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

            let mut bundle: serde_json::Value = serde_json::from_str(&bundle_json)
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "corrupt key bundle"))?;
            bundle["bundleVersion"] = serde_json::Value::from(bundle_version);

            let (resp, bytes_len) = json_bytes(&bundle)?;
            reset_user_api_outbound_if_new_month(&state.db, user.user_id, now_ms)
                .await
                .ok();
            sqlx::query(
                r#"UPDATE users SET api_outbound_bytes = api_outbound_bytes + ? WHERE id = ?"#,
            )
            .bind(bytes_len)
            .bind(user.user_id)
            .execute(&state.db)
            .await
            .ok();

            state.metrics.record_active_user(now_ms, user.user_id);
            Ok(resp)
        }
    }
}

async fn put_key_bundle(
    State(state): State<AppState>,
    user: auth::AuthedUser,
    Json(req): Json<PutKeyBundleRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    let now_ms = now_ms_utc();

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let current_version: i64 =
        sqlx::query_scalar(r#"SELECT bundle_version FROM key_bundles WHERE user_id = ?"#)
            .bind(user.user_id)
            .fetch_optional(&mut *tx)
            .await
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?
            .unwrap_or(0);
    if req.expected_bundle_version != current_version {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::CONFLICT, "bundle version mismatch"));
    }

    let new_version = current_version + 1;
    let mut bundle = req.bundle;
    bundle["bundleVersion"] = serde_json::Value::from(new_version);
    bundle["updatedAtMsUtc"] = serde_json::Value::from(now_ms);
    let bundle_json = serde_json::to_string(&bundle)
        .map_err(|_| json_error(StatusCode::BAD_REQUEST, "invalid bundle"))?;

    sqlx::query(
        r#"INSERT INTO key_bundles (user_id, bundle_version, bundle_json, updated_at_ms_utc)
       VALUES (?, ?, ?, ?)
       ON CONFLICT(user_id) DO UPDATE SET
         bundle_version = excluded.bundle_version,
         bundle_json = excluded.bundle_json,
         updated_at_ms_utc = excluded.updated_at_ms_utc"#,
    )
    .bind(user.user_id)
    .bind(new_version)
    .bind(bundle_json)
    .bind(now_ms)
    .execute(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let (resp, bytes_len) = json_bytes(&bundle)?;
    reset_user_api_outbound_if_new_month(&state.db, user.user_id, now_ms)
        .await
        .ok();
    sqlx::query(r#"UPDATE users SET api_outbound_bytes = api_outbound_bytes + ? WHERE id = ?"#)
        .bind(bytes_len)
        .bind(user.user_id)
        .execute(&state.db)
        .await
        .ok();

    state.metrics.record_active_user(now_ms, user.user_id);
    Ok(resp)
}

async fn upsert_attachment_refs(
    State(state): State<AppState>,
    user: auth::AuthedUser,
    Json(req): Json<UpsertAttachmentRefsRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    if req.refs.len() > 5000 {
        return Err(json_error(StatusCode::BAD_REQUEST, "too many refs"));
    }

    let now_ms = now_ms_utc();

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    for r in req.refs {
        let attachment_id = r.attachment_id.trim();
        let todo_id = r.todo_id.trim();
        if attachment_id.is_empty() || todo_id.is_empty() {
            continue;
        }

        sqlx::query(
            r#"INSERT INTO attachment_refs (user_id, attachment_id, todo_id, updated_at_ms_utc)
               VALUES (?, ?, ?, ?)
               ON CONFLICT(user_id, attachment_id) DO UPDATE SET
                 todo_id = excluded.todo_id,
                 updated_at_ms_utc = excluded.updated_at_ms_utc"#,
        )
        .bind(user.user_id)
        .bind(attachment_id)
        .bind(todo_id)
        .bind(now_ms)
        .execute(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    }

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    Ok(Json(OkResponse { ok: true }))
}

#[derive(Debug, Deserialize, Serialize, Clone)]
struct Hlc {
    #[serde(rename = "wallTimeMsUtc")]
    wall_time_ms_utc: i64,
    counter: i64,
    #[serde(rename = "deviceId")]
    device_id: String,
}

#[derive(Debug, Deserialize, Serialize, Clone)]
struct SyncRecordEnvelope {
    r#type: String,
    #[serde(rename = "recordId")]
    record_id: String,
    hlc: Hlc,
    #[serde(rename = "deletedAtMsUtc")]
    deleted_at_ms_utc: Option<i64>,
    #[serde(rename = "schemaVersion")]
    schema_version: i64,
    #[serde(rename = "dekId")]
    dek_id: String,
    #[serde(rename = "payloadAlgo")]
    payload_algo: String,
    nonce: String,
    ciphertext: String,
}

#[derive(Debug, Deserialize)]
struct PushRequest {
    records: Vec<SyncRecordEnvelope>,
}

#[derive(Debug, Serialize)]
struct PushAccepted {
    r#type: String,
    #[serde(rename = "recordId")]
    record_id: String,
    #[serde(rename = "serverSeq")]
    server_seq: i64,
}

#[derive(Debug, Serialize)]
struct PushRejected {
    r#type: String,
    #[serde(rename = "recordId")]
    record_id: String,
    reason: String,
}

#[derive(Debug, Serialize)]
struct PushResponse {
    accepted: Vec<PushAccepted>,
    rejected: Vec<PushRejected>,
}

#[derive(Debug, Serialize)]
struct OkResponse {
    ok: bool,
}

#[derive(Debug, Deserialize)]
struct AttachmentRefIn {
    #[serde(rename = "attachmentId")]
    attachment_id: String,
    #[serde(rename = "todoId")]
    todo_id: String,
}

#[derive(Debug, Deserialize)]
struct UpsertAttachmentRefsRequest {
    refs: Vec<AttachmentRefIn>,
}

fn hlc_is_newer(a: &Hlc, b: &Hlc) -> bool {
    (a.wall_time_ms_utc, a.counter, &a.device_id) > (b.wall_time_ms_utc, b.counter, &b.device_id)
}

fn is_attachment_staged_type(t: &str) -> bool {
    t == TYPE_TODO_ATTACHMENT || t == TYPE_TODO_ATTACHMENT_CHUNK
}

fn parse_chunk_index(record_id: &str) -> Option<i64> {
    record_id.rsplit_once(':')?.1.parse().ok()
}

async fn recompute_and_store_user_b64(
    tx: &mut Transaction<'_, Sqlite>,
    user_id: i64,
) -> anyhow::Result<i64> {
    let total_b64: i64 = sqlx::query_scalar(
        r#"SELECT
             (SELECT IFNULL(SUM(LENGTH(nonce) + LENGTH(ciphertext)), 0) FROM records WHERE user_id = ?)
           + (SELECT IFNULL(SUM(LENGTH(nonce) + LENGTH(ciphertext)), 0) FROM staged_records WHERE user_id = ?)"#,
    )
    .bind(user_id)
    .bind(user_id)
    .fetch_one(&mut **tx)
    .await?;

    sqlx::query(r#"UPDATE users SET stored_b64 = ? WHERE id = ?"#)
        .bind(total_b64)
        .bind(user_id)
        .execute(&mut **tx)
        .await?;

    Ok(total_b64)
}

async fn gc_staged_records(db: &Pool<Sqlite>, ttl_ms: i64) -> anyhow::Result<i64> {
    if ttl_ms <= 0 {
        return Ok(0);
    }

    let now_ms = now_ms_utc();
    let cutoff = now_ms.saturating_sub(ttl_ms);

    let mut tx = db.begin().await?;

    let user_ids: Vec<i64> = sqlx::query_scalar(
        r#"SELECT DISTINCT user_id
           FROM staged_records
           WHERE updated_at_ms_utc < ?"#,
    )
    .bind(cutoff)
    .fetch_all(&mut *tx)
    .await?;

    if user_ids.is_empty() {
        tx.rollback().await.ok();
        return Ok(0);
    }

    let deleted = sqlx::query(
        r#"DELETE FROM staged_records
           WHERE updated_at_ms_utc < ?"#,
    )
    .bind(cutoff)
    .execute(&mut *tx)
    .await?
    .rows_affected() as i64;

    for user_id in user_ids {
        let _ = recompute_and_store_user_b64(&mut tx, user_id).await?;
    }

    tx.commit().await?;
    Ok(deleted)
}

async fn delete_staged_attachment(
    tx: &mut Transaction<'_, Sqlite>,
    user_id: i64,
    attachment_id: &str,
) -> anyhow::Result<(i64, i64)> {
    let pattern = format!("{attachment_id}:%");
    let (count, bytes): (i64, i64) = sqlx::query_as(
        r#"SELECT
             COUNT(*) AS c,
             IFNULL(SUM(LENGTH(nonce) + LENGTH(ciphertext)), 0) AS b
           FROM staged_records
           WHERE user_id = ?
             AND (
               (type = ? AND record_id = ?)
               OR (type = ? AND record_id LIKE ?)
             )"#,
    )
    .bind(user_id)
    .bind(TYPE_TODO_ATTACHMENT)
    .bind(attachment_id)
    .bind(TYPE_TODO_ATTACHMENT_CHUNK)
    .bind(&pattern)
    .fetch_one(&mut **tx)
    .await?;

    if count > 0 {
        sqlx::query(
            r#"DELETE FROM staged_records
               WHERE user_id = ?
                 AND (
                   (type = ? AND record_id = ?)
                   OR (type = ? AND record_id LIKE ?)
                 )"#,
        )
        .bind(user_id)
        .bind(TYPE_TODO_ATTACHMENT)
        .bind(attachment_id)
        .bind(TYPE_TODO_ATTACHMENT_CHUNK)
        .bind(pattern)
        .execute(&mut **tx)
        .await?;
    }

    Ok((count, bytes))
}

async fn compact_committed_attachment_chunks(
    tx: &mut Transaction<'_, Sqlite>,
    user_id: i64,
    attachment_id: &str,
    deleted_at_ms_utc: i64,
) -> anyhow::Result<i64> {
    let now_ms = now_ms_utc();
    let pattern = format!("{attachment_id}:%");

    let rows = sqlx::query(
        r#"SELECT
             record_id,
             hlc_wall_ms_utc,
             deleted_at_ms_utc,
             LENGTH(nonce) AS nonce_len,
             LENGTH(ciphertext) AS ciphertext_len
           FROM records
           WHERE user_id = ? AND type = ? AND record_id LIKE ?"#,
    )
    .bind(user_id)
    .bind(TYPE_TODO_ATTACHMENT_CHUNK)
    .bind(pattern)
    .fetch_all(&mut **tx)
    .await?;

    let mut compacted = 0_i64;

    for row in rows {
        let record_id: String = row.try_get("record_id")?;
        let existing_wall: i64 = row.try_get("hlc_wall_ms_utc")?;
        let existing_deleted: Option<i64> = row.try_get("deleted_at_ms_utc")?;
        let nonce_len: i64 = row.try_get("nonce_len")?;
        let ciphertext_len: i64 = row.try_get("ciphertext_len")?;

        // Already compacted tombstone; no need to bump server_seq repeatedly.
        if existing_deleted.is_some() && nonce_len == 0 && ciphertext_len == 0 {
            continue;
        }

        let server_seq = alloc_server_seq(tx, user_id).await?;
        let new_wall = std::cmp::max(existing_wall, now_ms).saturating_add(1);

        sqlx::query(
            r#"UPDATE records
               SET hlc_wall_ms_utc = ?,
                   hlc_counter = 0,
                   hlc_device_id = 'server',
                   deleted_at_ms_utc = ?,
                   nonce = '',
                   ciphertext = '',
                   server_seq = ?,
                   updated_at_ms_utc = ?
               WHERE user_id = ? AND type = ? AND record_id = ?"#,
        )
        .bind(new_wall)
        .bind(deleted_at_ms_utc)
        .bind(server_seq)
        .bind(now_ms)
        .bind(user_id)
        .bind(TYPE_TODO_ATTACHMENT_CHUNK)
        .bind(record_id)
        .execute(&mut **tx)
        .await?;

        compacted += 1;
    }

    Ok(compacted)
}

async fn alloc_server_seq(tx: &mut Transaction<'_, Sqlite>, user_id: i64) -> anyhow::Result<i64> {
    sqlx::query(
        r#"INSERT INTO server_seq (user_id, next_seq)
       VALUES (?, 0)
       ON CONFLICT(user_id) DO NOTHING"#,
    )
    .bind(user_id)
    .execute(&mut **tx)
    .await?;

    sqlx::query(r#"UPDATE server_seq SET next_seq = next_seq + 1 WHERE user_id = ?"#)
        .bind(user_id)
        .execute(&mut **tx)
        .await?;

    let next_seq: i64 = sqlx::query_scalar(r#"SELECT next_seq FROM server_seq WHERE user_id = ?"#)
        .bind(user_id)
        .fetch_one(&mut **tx)
        .await?;

    Ok(next_seq)
}

#[derive(Debug, Clone)]
struct StoredRow {
    r#type: String,
    record_id: String,
    hlc: Hlc,
    deleted_at_ms_utc: Option<i64>,
    schema_version: i64,
    dek_id: String,
    payload_algo: String,
    nonce: String,
    ciphertext: String,
}

async fn commit_staged_attachment(
    tx: &mut Transaction<'_, Sqlite>,
    user_id: i64,
    attachment_id: &str,
) -> anyhow::Result<()> {
    let staged_meta = sqlx::query(
        r#"SELECT
         type,
         record_id,
         hlc_wall_ms_utc,
         hlc_counter,
         hlc_device_id,
         deleted_at_ms_utc,
         schema_version,
         dek_id,
         algo,
         nonce,
         ciphertext
       FROM staged_records
       WHERE user_id = ? AND type = ? AND record_id = ?"#,
    )
    .bind(user_id)
    .bind(TYPE_TODO_ATTACHMENT)
    .bind(attachment_id)
    .fetch_optional(&mut **tx)
    .await?;

    let pattern = format!("{attachment_id}:%");
    let staged_chunks = sqlx::query(
        r#"SELECT
         type,
         record_id,
         hlc_wall_ms_utc,
         hlc_counter,
         hlc_device_id,
         deleted_at_ms_utc,
         schema_version,
         dek_id,
         algo,
         nonce,
         ciphertext
       FROM staged_records
       WHERE user_id = ? AND type = ? AND record_id LIKE ?"#,
    )
    .bind(user_id)
    .bind(TYPE_TODO_ATTACHMENT_CHUNK)
    .bind(pattern)
    .fetch_all(&mut **tx)
    .await?;

    let mut rows: Vec<StoredRow> = Vec::with_capacity(staged_chunks.len() + 1);
    if let Some(row) = staged_meta {
        rows.push(StoredRow {
            r#type: row.try_get("type")?,
            record_id: row.try_get("record_id")?,
            hlc: Hlc {
                wall_time_ms_utc: row.try_get("hlc_wall_ms_utc")?,
                counter: row.try_get("hlc_counter")?,
                device_id: row.try_get("hlc_device_id")?,
            },
            deleted_at_ms_utc: row.try_get("deleted_at_ms_utc")?,
            schema_version: row.try_get("schema_version")?,
            dek_id: row.try_get("dek_id")?,
            payload_algo: row.try_get("algo")?,
            nonce: row.try_get("nonce")?,
            ciphertext: row.try_get("ciphertext")?,
        });
    }

    for row in staged_chunks {
        rows.push(StoredRow {
            r#type: row.try_get("type")?,
            record_id: row.try_get("record_id")?,
            hlc: Hlc {
                wall_time_ms_utc: row.try_get("hlc_wall_ms_utc")?,
                counter: row.try_get("hlc_counter")?,
                device_id: row.try_get("hlc_device_id")?,
            },
            deleted_at_ms_utc: row.try_get("deleted_at_ms_utc")?,
            schema_version: row.try_get("schema_version")?,
            dek_id: row.try_get("dek_id")?,
            payload_algo: row.try_get("algo")?,
            nonce: row.try_get("nonce")?,
            ciphertext: row.try_get("ciphertext")?,
        });
    }

    // Ensure metadata is committed before chunks so clients can initialize
    // local state before applying chunk payloads.
    rows.sort_by(|a, b| {
        let a_is_chunk = a.r#type == TYPE_TODO_ATTACHMENT_CHUNK;
        let b_is_chunk = b.r#type == TYPE_TODO_ATTACHMENT_CHUNK;
        match (a_is_chunk, b_is_chunk) {
            (false, true) => std::cmp::Ordering::Less,
            (true, false) => std::cmp::Ordering::Greater,
            (false, false) => std::cmp::Ordering::Equal,
            (true, true) => {
                let ai = parse_chunk_index(&a.record_id).unwrap_or(i64::MAX);
                let bi = parse_chunk_index(&b.record_id).unwrap_or(i64::MAX);
                ai.cmp(&bi)
            }
        }
    });

    for row in &rows {
        let existing = sqlx::query(
            r#"SELECT
                 hlc_wall_ms_utc, hlc_counter, hlc_device_id
         FROM records
         WHERE user_id = ? AND type = ? AND record_id = ?"#,
        )
        .bind(user_id)
        .bind(&row.r#type)
        .bind(&row.record_id)
        .fetch_optional(&mut **tx)
        .await?;

        if let Some(existing) = existing {
            let stored = Hlc {
                wall_time_ms_utc: existing.try_get("hlc_wall_ms_utc")?,
                counter: existing.try_get("hlc_counter")?,
                device_id: existing.try_get("hlc_device_id")?,
            };
            if !hlc_is_newer(&row.hlc, &stored) {
                continue;
            }
        }

        let server_seq = alloc_server_seq(tx, user_id).await?;
        let now_ms = now_ms_utc();
        sqlx::query(
            r#"INSERT INTO records (
           user_id, type, record_id,
           hlc_wall_ms_utc, hlc_counter, hlc_device_id,
           deleted_at_ms_utc,
           schema_version, dek_id,
           algo, nonce, ciphertext,
           server_seq, updated_at_ms_utc
         ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
         ON CONFLICT(user_id, type, record_id) DO UPDATE SET
           hlc_wall_ms_utc = excluded.hlc_wall_ms_utc,
           hlc_counter = excluded.hlc_counter,
           hlc_device_id = excluded.hlc_device_id,
           deleted_at_ms_utc = excluded.deleted_at_ms_utc,
           schema_version = excluded.schema_version,
           dek_id = excluded.dek_id,
           algo = excluded.algo,
           nonce = excluded.nonce,
           ciphertext = excluded.ciphertext,
           server_seq = excluded.server_seq,
           updated_at_ms_utc = excluded.updated_at_ms_utc"#,
        )
        .bind(user_id)
        .bind(&row.r#type)
        .bind(&row.record_id)
        .bind(row.hlc.wall_time_ms_utc)
        .bind(row.hlc.counter)
        .bind(&row.hlc.device_id)
        .bind(row.deleted_at_ms_utc)
        .bind(row.schema_version)
        .bind(&row.dek_id)
        .bind(&row.payload_algo)
        .bind(&row.nonce)
        .bind(&row.ciphertext)
        .bind(server_seq)
        .bind(now_ms)
        .execute(&mut **tx)
        .await?;
    }

    if !rows.is_empty() {
        // Clean up staged rows even if already committed, to keep commits idempotent.
        let pattern = format!("{attachment_id}:%");
        sqlx::query(
            r#"DELETE FROM staged_records
               WHERE user_id = ?
                 AND (
                   (type = ? AND record_id = ?)
                   OR (type = ? AND record_id LIKE ?)
                 )"#,
        )
        .bind(user_id)
        .bind(TYPE_TODO_ATTACHMENT)
        .bind(attachment_id)
        .bind(TYPE_TODO_ATTACHMENT_CHUNK)
        .bind(pattern)
        .execute(&mut **tx)
        .await?;
    }

    Ok(())
}

async fn push_sync(
    State(state): State<AppState>,
    user: auth::AuthedUser,
    Json(req): Json<PushRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    if req.records.len() > state.max_push_records {
        return Err(json_error(StatusCode::BAD_REQUEST, "too many records"));
    }

    let now_ms = now_ms_utc();

    let mut accepted = Vec::new();
    let mut rejected = Vec::new();
    let mut did_compact_records = false;

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    reset_user_api_outbound_if_new_month(&mut *tx, user.user_id, now_ms)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let billing_row = sqlx::query(
        r#"SELECT
             base_storage_b64,
             base_outbound_bytes,
             subscription_plan_id,
             subscription_expires_at_ms_utc,
             banned_at_ms_utc,
             stored_b64,
             api_outbound_bytes
           FROM users
           WHERE id = ?"#,
    )
    .bind(user.user_id)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let Some(billing_row) = billing_row else {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::UNAUTHORIZED, "unauthorized"));
    };

    let mut subscription_plan_id: Option<String> = billing_row
        .try_get("subscription_plan_id")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let mut subscription_expires_at_ms_utc: Option<i64> = billing_row
        .try_get("subscription_expires_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let has_plan = subscription_plan_id
        .as_deref()
        .map(|s| !s.trim().is_empty())
        .unwrap_or(false);
    let expires_at = subscription_expires_at_ms_utc.unwrap_or(0);
    if has_plan && expires_at <= now_ms {
        clear_subscription_if_expired(
            &mut *tx,
            user.user_id,
            &subscription_plan_id,
            subscription_expires_at_ms_utc,
            now_ms,
        )
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
        subscription_plan_id = None;
        subscription_expires_at_ms_utc = None;
    }

    let user_billing = UserBillingRow {
        base_storage_b64: billing_row
            .try_get("base_storage_b64")
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
        base_outbound_bytes: billing_row
            .try_get("base_outbound_bytes")
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
        subscription_plan_id,
        subscription_expires_at_ms_utc,
        banned_at_ms_utc: billing_row
            .try_get("banned_at_ms_utc")
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
        stored_b64: billing_row
            .try_get("stored_b64")
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
        api_outbound_bytes: billing_row
            .try_get("api_outbound_bytes")
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
    };

    if user_billing.banned_at_ms_utc.is_some_and(|ms| ms > 0) {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::FORBIDDEN, "banned"));
    }

    let quota = compute_effective_quota(&state.billing, &user_billing, now_ms);

    // Include staged attachment bytes in quota checks so users can't exceed
    // storage limits by uploading uncommitted blobs.
    let mut record_count: i64 = sqlx::query_scalar(
        r#"SELECT
             (SELECT COUNT(*) FROM records WHERE user_id = ?)
           + (SELECT COUNT(*) FROM staged_records WHERE user_id = ?)"#,
    )
    .bind(user.user_id)
    .bind(user.user_id)
    .fetch_one(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let mut total_b64: i64 = sqlx::query_scalar(
        r#"SELECT
             (SELECT IFNULL(SUM(LENGTH(nonce) + LENGTH(ciphertext)), 0) FROM records WHERE user_id = ?)
           + (SELECT IFNULL(SUM(LENGTH(nonce) + LENGTH(ciphertext)), 0) FROM staged_records WHERE user_id = ?)"#,
    )
    .bind(user.user_id)
    .bind(user.user_id)
    .fetch_one(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    if let Some(max) = quota.allowed_outbound_bytes {
        if user_billing.api_outbound_bytes > max {
            tx.rollback().await.ok();
            return Err(json_error(StatusCode::PAYMENT_REQUIRED, "quota_exceeded"));
        }
    }

    let mut commit_requests: Vec<(String, Option<i64>)> = Vec::new();

    for r in req.records {
        if r.nonce.len() > MAX_RECORD_B64_LEN || r.ciphertext.len() > MAX_RECORD_B64_LEN {
            rejected.push(PushRejected {
                r#type: r.r#type,
                record_id: r.record_id,
                reason: "record_too_large".to_string(),
            });
            continue;
        }

        if r.r#type == TYPE_TODO_ATTACHMENT_COMMIT {
            commit_requests.push((r.record_id, r.deleted_at_ms_utc));
            continue;
        }

        let committed_existing = sqlx::query(
            r#"SELECT
                 hlc_wall_ms_utc, hlc_counter, hlc_device_id,
                 LENGTH(nonce) AS nonce_len,
                 LENGTH(ciphertext) AS ciphertext_len
         FROM records
         WHERE user_id = ? AND type = ? AND record_id = ?"#,
        )
        .bind(user.user_id)
        .bind(&r.r#type)
        .bind(&r.record_id)
        .fetch_optional(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

        let is_staged_type = is_attachment_staged_type(&r.r#type);

        // Once an attachment is deleted (tombstoned metadata in `records`), the
        // server must reject any subsequent chunk/meta uploads regardless of
        // HLC, otherwise stale/out-of-order clients could recreate staged data.
        if is_staged_type && r.deleted_at_ms_utc.is_none() {
            let attachment_id = if r.r#type == TYPE_TODO_ATTACHMENT {
                Some(r.record_id.as_str())
            } else {
                r.record_id.rsplit_once(':').map(|(a, _)| a)
            };

            if let Some(attachment_id) = attachment_id {
                let deleted: Option<i64> = sqlx::query_scalar(
                    r#"SELECT deleted_at_ms_utc
                       FROM records
                       WHERE user_id = ? AND type = ? AND record_id = ?"#,
                )
                .bind(user.user_id)
                .bind(TYPE_TODO_ATTACHMENT)
                .bind(attachment_id)
                .fetch_optional(&mut *tx)
                .await
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

                if deleted.is_some_and(|ms| ms > 0) {
                    rejected.push(PushRejected {
                        r#type: r.r#type,
                        record_id: r.record_id,
                        reason: "attachment_deleted".to_string(),
                    });
                    continue;
                }
            }
        }

        let staged_existing = if committed_existing.is_none() && is_staged_type {
            sqlx::query(
                r#"SELECT
                     hlc_wall_ms_utc, hlc_counter, hlc_device_id,
                     LENGTH(nonce) AS nonce_len,
                     LENGTH(ciphertext) AS ciphertext_len
             FROM staged_records
             WHERE user_id = ? AND type = ? AND record_id = ?"#,
            )
            .bind(user.user_id)
            .bind(&r.r#type)
            .bind(&r.record_id)
            .fetch_optional(&mut *tx)
            .await
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?
        } else {
            None
        };

        let mut existing_hlc: Option<Hlc> = None;
        let mut existing_size: i64 = 0;
        let mut exists_committed = false;
        let mut exists_staged = false;

        if let Some(row) = &committed_existing {
            exists_committed = true;
            existing_hlc = Some(Hlc {
                wall_time_ms_utc: row
                    .try_get("hlc_wall_ms_utc")
                    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
                counter: row
                    .try_get("hlc_counter")
                    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
                device_id: row
                    .try_get("hlc_device_id")
                    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
            });
            let nonce_len: i64 = row
                .try_get("nonce_len")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
            let ciphertext_len: i64 = row
                .try_get("ciphertext_len")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
            existing_size = nonce_len + ciphertext_len;
        } else if let Some(row) = &staged_existing {
            exists_staged = true;
            existing_hlc = Some(Hlc {
                wall_time_ms_utc: row
                    .try_get("hlc_wall_ms_utc")
                    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
                counter: row
                    .try_get("hlc_counter")
                    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
                device_id: row
                    .try_get("hlc_device_id")
                    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
            });
            let nonce_len: i64 = row
                .try_get("nonce_len")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
            let ciphertext_len: i64 = row
                .try_get("ciphertext_len")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
            existing_size = nonce_len + ciphertext_len;
        }

        let should_accept = existing_hlc
            .as_ref()
            .map(|stored| hlc_is_newer(&r.hlc, stored))
            .unwrap_or(true);

        if !should_accept {
            rejected.push(PushRejected {
                r#type: r.r#type,
                record_id: r.record_id,
                reason: "older_hlc".to_string(),
            });
            continue;
        }

        // For attachments/chunks, a tombstone before commit should simply
        // remove any staged data and remain invisible to other devices.
        if is_staged_type && r.deleted_at_ms_utc.is_some() && !exists_committed {
            if r.r#type == TYPE_TODO_ATTACHMENT {
                let attachment_id = r.record_id.clone();
                let (deleted_count, deleted_bytes) =
                    delete_staged_attachment(&mut tx, user.user_id, &attachment_id)
                        .await
                        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
                if deleted_count > 0 {
                    total_b64 = (total_b64 - deleted_bytes).max(0);
                    record_count = (record_count - deleted_count).max(0);
                    did_compact_records = true;
                }

                accepted.push(PushAccepted {
                    r#type: r.r#type,
                    record_id: r.record_id,
                    server_seq: 0,
                });
                continue;
            }

            if exists_staged {
                sqlx::query(
                    r#"DELETE FROM staged_records WHERE user_id = ? AND type = ? AND record_id = ?"#,
                )
                .bind(user.user_id)
                .bind(&r.r#type)
                .bind(&r.record_id)
                .execute(&mut *tx)
                .await
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

                total_b64 = (total_b64 - existing_size).max(0);
                record_count = (record_count - 1).max(0);
            }

            accepted.push(PushAccepted {
                r#type: r.r#type,
                record_id: r.record_id,
                server_seq: 0,
            });
            continue;
        }

        let new_size: i64 = (r.nonce.len() + r.ciphertext.len()) as i64;

        let new_total_b64 = total_b64 + (new_size - existing_size);
        let new_record_count = record_count
            + if !exists_committed && !exists_staged {
                1
            } else {
                0
            };

        if let Some(max) = state.max_records_per_user {
            if new_record_count > max {
                rejected.push(PushRejected {
                    r#type: r.r#type,
                    record_id: r.record_id,
                    reason: "quota_exceeded".to_string(),
                });
                continue;
            }
        }
        if let Some(max) = quota.allowed_storage_b64 {
            // Allow deletes/size reductions even when the user is already over
            // quota, so they can free space. Block only mutations that would
            // increase stored bytes while remaining above the limit.
            let increases_storage = new_total_b64 > total_b64;
            if new_total_b64 > max && increases_storage {
                rejected.push(PushRejected {
                    r#type: r.r#type,
                    record_id: r.record_id,
                    reason: "quota_exceeded".to_string(),
                });
                continue;
            }
        }

        let should_stage = is_staged_type && !exists_committed;
        if should_stage {
            let now_ms = now_ms_utc();
            sqlx::query(
                r#"INSERT INTO staged_records (
               user_id, type, record_id,
               hlc_wall_ms_utc, hlc_counter, hlc_device_id,
               deleted_at_ms_utc,
               schema_version, dek_id,
               algo, nonce, ciphertext,
               updated_at_ms_utc
             ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT(user_id, type, record_id) DO UPDATE SET
               hlc_wall_ms_utc = excluded.hlc_wall_ms_utc,
               hlc_counter = excluded.hlc_counter,
               hlc_device_id = excluded.hlc_device_id,
               deleted_at_ms_utc = excluded.deleted_at_ms_utc,
               schema_version = excluded.schema_version,
               dek_id = excluded.dek_id,
               algo = excluded.algo,
               nonce = excluded.nonce,
               ciphertext = excluded.ciphertext,
               updated_at_ms_utc = excluded.updated_at_ms_utc"#,
            )
            .bind(user.user_id)
            .bind(&r.r#type)
            .bind(&r.record_id)
            .bind(r.hlc.wall_time_ms_utc)
            .bind(r.hlc.counter)
            .bind(&r.hlc.device_id)
            .bind(r.deleted_at_ms_utc)
            .bind(r.schema_version)
            .bind(&r.dek_id)
            .bind(&r.payload_algo)
            .bind(&r.nonce)
            .bind(&r.ciphertext)
            .bind(now_ms)
            .execute(&mut *tx)
            .await
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

            accepted.push(PushAccepted {
                r#type: r.r#type,
                record_id: r.record_id,
                server_seq: 0,
            });
        } else {
            let server_seq = alloc_server_seq(&mut tx, user.user_id).await.map_err(|e| {
                error!(error = %e, "alloc_server_seq failed");
                json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error")
            })?;

            let now_ms = now_ms_utc();
            sqlx::query(
                r#"INSERT INTO records (
               user_id, type, record_id,
               hlc_wall_ms_utc, hlc_counter, hlc_device_id,
               deleted_at_ms_utc,
               schema_version, dek_id,
               algo, nonce, ciphertext,
               server_seq, updated_at_ms_utc
             ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
             ON CONFLICT(user_id, type, record_id) DO UPDATE SET
               hlc_wall_ms_utc = excluded.hlc_wall_ms_utc,
               hlc_counter = excluded.hlc_counter,
               hlc_device_id = excluded.hlc_device_id,
               deleted_at_ms_utc = excluded.deleted_at_ms_utc,
               schema_version = excluded.schema_version,
               dek_id = excluded.dek_id,
               algo = excluded.algo,
               nonce = excluded.nonce,
               ciphertext = excluded.ciphertext,
               server_seq = excluded.server_seq,
               updated_at_ms_utc = excluded.updated_at_ms_utc"#,
            )
            .bind(user.user_id)
            .bind(&r.r#type)
            .bind(&r.record_id)
            .bind(r.hlc.wall_time_ms_utc)
            .bind(r.hlc.counter)
            .bind(&r.hlc.device_id)
            .bind(r.deleted_at_ms_utc)
            .bind(r.schema_version)
            .bind(&r.dek_id)
            .bind(&r.payload_algo)
            .bind(&r.nonce)
            .bind(&r.ciphertext)
            .bind(server_seq)
            .bind(now_ms)
            .execute(&mut *tx)
            .await
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

            let record_type = r.r#type.clone();
            let record_id = r.record_id.clone();
            let is_attachment_delete =
                r.r#type == TYPE_TODO_ATTACHMENT && r.deleted_at_ms_utc.is_some();
            let deleted_at_ms_utc = r.deleted_at_ms_utc.unwrap_or(now_ms);

            accepted.push(PushAccepted {
                r#type: record_type,
                record_id,
                server_seq,
            });

            // Attachment deletion should compact all committed chunk payloads
            // (so future pulls don't transfer old ciphertext) and clear any
            // in-flight staged data without requiring per-chunk tombstones
            // from the client.
            if is_attachment_delete {
                let attachment_id = r.record_id;

                let _ = delete_staged_attachment(&mut tx, user.user_id, &attachment_id)
                    .await
                    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

                compact_committed_attachment_chunks(
                    &mut tx,
                    user.user_id,
                    &attachment_id,
                    deleted_at_ms_utc,
                )
                .await
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

                did_compact_records = true;
            }
        }

        total_b64 = new_total_b64;
        record_count = new_record_count;
    }

    for (attachment_id, deleted_at_ms_utc) in commit_requests {
        if deleted_at_ms_utc.is_some() {
            // Tombstoning the commit marker is used by clients to cancel a
            // pending commit while deleting an in-progress attachment upload.
            accepted.push(PushAccepted {
                r#type: TYPE_TODO_ATTACHMENT_COMMIT.to_string(),
                record_id: attachment_id,
                server_seq: 0,
            });
            continue;
        }

        let committed_deleted: Option<i64> = sqlx::query_scalar(
            r#"SELECT deleted_at_ms_utc
               FROM records
               WHERE user_id = ? AND type = ? AND record_id = ?"#,
        )
        .bind(user.user_id)
        .bind(TYPE_TODO_ATTACHMENT)
        .bind(&attachment_id)
        .fetch_optional(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

        if committed_deleted.is_some_and(|ms| ms > 0) {
            rejected.push(PushRejected {
                r#type: TYPE_TODO_ATTACHMENT_COMMIT.to_string(),
                record_id: attachment_id,
                reason: "attachment_deleted".to_string(),
            });
            continue;
        }

        let has_committed_meta: Option<i64> = sqlx::query_scalar(
            r#"SELECT 1
               FROM records
               WHERE user_id = ? AND type = ? AND record_id = ? AND deleted_at_ms_utc IS NULL
               LIMIT 1"#,
        )
        .bind(user.user_id)
        .bind(TYPE_TODO_ATTACHMENT)
        .bind(&attachment_id)
        .fetch_optional(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

        let has_staged_meta: Option<i64> = sqlx::query_scalar(
            r#"SELECT 1 FROM staged_records WHERE user_id = ? AND type = ? AND record_id = ? LIMIT 1"#,
        )
        .bind(user.user_id)
        .bind(TYPE_TODO_ATTACHMENT)
        .bind(&attachment_id)
        .fetch_optional(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

        if has_committed_meta.is_none() && has_staged_meta.is_none() {
            rejected.push(PushRejected {
                r#type: TYPE_TODO_ATTACHMENT_COMMIT.to_string(),
                record_id: attachment_id,
                reason: "missing_attachment_meta".to_string(),
            });
            continue;
        }

        commit_staged_attachment(&mut tx, user.user_id, &attachment_id)
            .await
            .map_err(|e| {
                error!(error = %e, "commit_staged_attachment failed");
                json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error")
            })?;

        accepted.push(PushAccepted {
            r#type: TYPE_TODO_ATTACHMENT_COMMIT.to_string(),
            record_id: attachment_id,
            server_seq: 0,
        });
    }

    let body = PushResponse { accepted, rejected };
    let (resp, bytes_len) = json_bytes(&body)?;

    if did_compact_records {
        total_b64 = recompute_and_store_user_b64(&mut tx, user.user_id)
            .await
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    }

    sqlx::query(r#"UPDATE users SET stored_b64 = ?, api_outbound_bytes = api_outbound_bytes + ? WHERE id = ?"#)
        .bind(total_b64)
        .bind(bytes_len)
        .bind(user.user_id)
        .execute(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    state.metrics.record_active_user(now_ms, user.user_id);
    Ok(resp)
}

#[derive(Debug, Deserialize)]
struct PullQuery {
    since: Option<i64>,
    limit: Option<i64>,
    #[serde(rename = "excludeDeviceId")]
    exclude_device_id: Option<String>,
}

#[derive(Debug, Serialize)]
struct PullResponse {
    records: Vec<SyncRecordEnvelope>,
    #[serde(rename = "nextSince")]
    next_since: i64,
}

async fn pull_sync(
    State(state): State<AppState>,
    user: auth::AuthedUser,
    Query(q): Query<PullQuery>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    let since = q.since.unwrap_or(0).max(0);
    let limit = q.limit.unwrap_or(200).clamp(1, MAX_PULL_LIMIT) as i64;
    let exclude_device_id = q
        .exclude_device_id
        .as_deref()
        .map(|s| s.trim())
        .filter(|s| !s.is_empty())
        .map(|s| s.to_string());

    let now_ms = now_ms_utc();

    reset_user_api_outbound_if_new_month(&state.db, user.user_id, now_ms)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let billing_row = sqlx::query(
        r#"SELECT
             base_storage_b64,
             base_outbound_bytes,
             subscription_plan_id,
             subscription_expires_at_ms_utc,
             banned_at_ms_utc,
             stored_b64,
             api_outbound_bytes
           FROM users
           WHERE id = ?"#,
    )
    .bind(user.user_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let Some(billing_row) = billing_row else {
        return Err(json_error(StatusCode::UNAUTHORIZED, "unauthorized"));
    };

    let mut subscription_plan_id: Option<String> = billing_row
        .try_get("subscription_plan_id")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let mut subscription_expires_at_ms_utc: Option<i64> = billing_row
        .try_get("subscription_expires_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let has_plan = subscription_plan_id
        .as_deref()
        .map(|s| !s.trim().is_empty())
        .unwrap_or(false);
    let expires_at = subscription_expires_at_ms_utc.unwrap_or(0);
    if has_plan && expires_at <= now_ms {
        clear_subscription_if_expired(
            &state.db,
            user.user_id,
            &subscription_plan_id,
            subscription_expires_at_ms_utc,
            now_ms,
        )
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
        subscription_plan_id = None;
        subscription_expires_at_ms_utc = None;
    }

    let user_billing = UserBillingRow {
        base_storage_b64: billing_row
            .try_get("base_storage_b64")
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
        base_outbound_bytes: billing_row
            .try_get("base_outbound_bytes")
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
        subscription_plan_id,
        subscription_expires_at_ms_utc,
        banned_at_ms_utc: billing_row
            .try_get("banned_at_ms_utc")
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
        stored_b64: billing_row
            .try_get("stored_b64")
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
        api_outbound_bytes: billing_row
            .try_get("api_outbound_bytes")
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
    };

    if user_billing.banned_at_ms_utc.is_some_and(|ms| ms > 0) {
        return Err(json_error(StatusCode::FORBIDDEN, "banned"));
    }

    let quota = compute_effective_quota(&state.billing, &user_billing, now_ms);
    if let Some(max) = quota.allowed_storage_b64 {
        if user_billing.stored_b64 > max {
            return Err(json_error(StatusCode::PAYMENT_REQUIRED, "quota_exceeded"));
        }
    }
    if let Some(max) = quota.allowed_outbound_bytes {
        if user_billing.api_outbound_bytes > max {
            return Err(json_error(StatusCode::PAYMENT_REQUIRED, "quota_exceeded"));
        }
    }

    let rows = sqlx::query(
        r#"SELECT
         type,
         record_id,
         hlc_wall_ms_utc,
         hlc_counter,
         hlc_device_id,
         deleted_at_ms_utc,
         schema_version,
         dek_id,
         algo,
         nonce,
         ciphertext,
         server_seq
       FROM records
       WHERE user_id = ? AND server_seq > ? AND (? IS NULL OR hlc_device_id != ?)
       ORDER BY server_seq ASC
       LIMIT ?"#,
    )
    .bind(user.user_id)
    .bind(since)
    .bind(&exclude_device_id)
    .bind(&exclude_device_id)
    .bind(limit)
    .fetch_all(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    // `nextSince` should help clients detect server rollbacks / DB resets.
    //
    // If we return `nextSince = since` on an empty page, a client with a cursor
    // ahead of the current server head (e.g. server DB reset) will never detect
    // the rollback and will appear "stuck" at a higher `lastServerSeq`.
    if rows.is_empty() {
        let head: i64 = sqlx::query_scalar(
            r#"SELECT COALESCE(MAX(server_seq), 0) FROM records WHERE user_id = ?"#,
        )
        .bind(user.user_id)
        .fetch_one(&state.db)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

        let body = PullResponse {
            records: Vec::new(),
            next_since: head,
        };
        let (resp, bytes_len) = json_bytes(&body)?;
        if let Some(limit) = quota.allowed_outbound_bytes {
            let updated = sqlx::query(
                r#"UPDATE users
                   SET api_outbound_bytes = api_outbound_bytes + ?
                   WHERE id = ? AND api_outbound_bytes + ? <= ?"#,
            )
            .bind(bytes_len)
            .bind(user.user_id)
            .bind(bytes_len)
            .bind(limit)
            .execute(&state.db)
            .await
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
            if updated.rows_affected() == 0 {
                return Err(json_error(StatusCode::PAYMENT_REQUIRED, "quota_exceeded"));
            }
        } else {
            sqlx::query(
                r#"UPDATE users SET api_outbound_bytes = api_outbound_bytes + ? WHERE id = ?"#,
            )
            .bind(bytes_len)
            .bind(user.user_id)
            .execute(&state.db)
            .await
            .ok();
        }
        state.metrics.record_active_user(now_ms, user.user_id);
        return Ok(resp);
    }

    let mut next_since = since;
    let mut records = Vec::with_capacity(rows.len());

    for row in rows {
        let server_seq: i64 = row
            .try_get("server_seq")
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
        next_since = next_since.max(server_seq);

        records.push(SyncRecordEnvelope {
            r#type: row
                .try_get("type")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
            record_id: row
                .try_get("record_id")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
            hlc: Hlc {
                wall_time_ms_utc: row
                    .try_get("hlc_wall_ms_utc")
                    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
                counter: row
                    .try_get("hlc_counter")
                    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
                device_id: row
                    .try_get("hlc_device_id")
                    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
            },
            deleted_at_ms_utc: row
                .try_get("deleted_at_ms_utc")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
            schema_version: row
                .try_get("schema_version")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
            dek_id: row
                .try_get("dek_id")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
            payload_algo: row
                .try_get("algo")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
            nonce: row
                .try_get("nonce")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
            ciphertext: row
                .try_get("ciphertext")
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
        });
    }

    let body = PullResponse {
        records,
        next_since,
    };
    let (resp, bytes_len) = json_bytes(&body)?;

    if let Some(limit) = quota.allowed_outbound_bytes {
        let updated = sqlx::query(
            r#"UPDATE users
               SET api_outbound_bytes = api_outbound_bytes + ?
               WHERE id = ? AND api_outbound_bytes + ? <= ?"#,
        )
        .bind(bytes_len)
        .bind(user.user_id)
        .bind(bytes_len)
        .bind(limit)
        .execute(&state.db)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
        if updated.rows_affected() == 0 {
            return Err(json_error(StatusCode::PAYMENT_REQUIRED, "quota_exceeded"));
        }
    } else {
        sqlx::query(r#"UPDATE users SET api_outbound_bytes = api_outbound_bytes + ? WHERE id = ?"#)
            .bind(bytes_len)
            .bind(user.user_id)
            .execute(&state.db)
            .await
            .ok();
    }

    state.metrics.record_active_user(now_ms, user.user_id);
    Ok(resp)
}

async fn health() -> impl IntoResponse {
    "ok"
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();

    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env().add_directive("info".parse()?))
        .init();

    let database_url = normalize_database_url(
        std::env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite://./sync.db".to_string()),
    );
    let host = std::env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(8787);

    let auth_config = auth::AuthConfig::load_from_env().context("load auth config")?;
    info!(
        base_url = %auth_config.base_url,
        enabled_providers = ?auth_config.enabled_providers,
        configured_providers = ?auth_config.providers.keys().collect::<Vec<_>>(),
        "auth config loaded"
    );
    let auth_service = Arc::new(auth::AuthService::new(auth_config).context("init auth")?);

    let max_push_records: usize = std::env::var("MAX_PUSH_RECORDS")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(DEFAULT_MAX_PUSH_RECORDS);

    let max_records_per_user: Option<i64> = std::env::var("MAX_RECORDS_PER_USER")
        .ok()
        .and_then(|s| s.parse().ok());

    let body_limit_bytes: usize = std::env::var("BODY_LIMIT_BYTES")
        .ok()
        .and_then(|s| s.parse().ok())
        .unwrap_or(DEFAULT_BODY_LIMIT_BYTES);

    let billing = Arc::new(BillingConfig::load_from_env().context("load billing config")?);
    let admin = AdminConfig::load_from_env();

    let site_created_at_ms_utc: Option<i64> = std::env::var("SITE_CREATED_AT_MS_UTC")
        .ok()
        .and_then(|s| s.trim().parse().ok())
        .filter(|ms: &i64| *ms > 0);

    let connect_options = SqliteConnectOptions::from_str(&database_url)
        .with_context(|| format!("parse DATABASE_URL: {database_url}"))?
        .create_if_missing(true)
        .foreign_keys(true);

    let pool = SqlitePoolOptions::new()
        .max_connections(10)
        .connect_with(connect_options)
        .await
        .with_context(|| format!("connect db: {database_url}"))?;

    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .context("run migrations")?;

    let metrics = metrics::Metrics::start(pool.clone());

    let state = AppState {
        db: pool,
        limiter: Arc::new(tokio::sync::Mutex::new(RateLimiter::new(
            Duration::from_secs(1),
            50,
            8192,
        ))),
        auth_limiter: Arc::new(tokio::sync::Mutex::new(RateLimiter::new(
            Duration::from_secs(1),
            10,
            8192,
        ))),
        auth: auth_service,
        max_push_records,
        max_records_per_user,
        billing,
        admin,
        metrics,
        started_at: Instant::now(),
        site_created_at_ms_utc,
    };

    let staged_record_ttl_ms: i64 = env_i64("STAGED_RECORD_TTL_MS").unwrap_or(24 * 60 * 60 * 1000);
    let staged_gc_interval_secs: i64 = env_i64("STAGED_GC_INTERVAL_SECS").unwrap_or(60 * 60);
    if staged_record_ttl_ms > 0 && staged_gc_interval_secs > 0 {
        let db = state.db.clone();
        tokio::spawn(async move {
            let mut ticker =
                tokio::time::interval(Duration::from_secs(staged_gc_interval_secs as u64));
            loop {
                ticker.tick().await;
                match gc_staged_records(&db, staged_record_ttl_ms).await {
                    Ok(deleted) => {
                        if deleted > 0 {
                            info!(deleted, "staged_records GC");
                        }
                    }
                    Err(e) => {
                        error!(error = %e, "staged_records GC failed");
                    }
                }
            }
        });
    }

    let admin_entry_path = state.admin.entry_path.clone();

    let app = Router::new()
        .merge(web::web_router(admin_entry_path))
        .route("/v1/health", get(health))
        .nest("/v1/auth", auth::AuthService::auth_router())
        .route("/v1/key-bundle", get(get_key_bundle).put(put_key_bundle))
        .route("/v1/sync/push", post(push_sync))
        .route("/v1/sync/pull", get(pull_sync))
        .route("/v1/attachments/refs", post(upsert_attachment_refs))
        // Dev-friendly CORS for Flutter Web on a different port (e.g. localhost:8080).
        // For production deployments, replace with a strict allowlist.
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods([Method::GET, Method::POST, Method::PUT, Method::OPTIONS])
                .allow_headers(Any),
        )
        .layer(RequestBodyLimitLayer::new(body_limit_bytes))
        .layer(
            TraceLayer::new_for_http().make_span_with(|req: &axum::http::Request<_>| {
                tracing::info_span!(
                    "http_request",
                    method = %req.method(),
                    path = %req.uri().path()
                )
            }),
        )
        .layer(axum::middleware::from_fn_with_state(
            state.clone(),
            track_api_metrics,
        ))
        .with_state(state);

    let addr: SocketAddr = format!("{host}:{port}").parse().context("parse addr")?;
    info!(%addr, "sync server listening");

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(
        listener,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .await?;
    Ok(())
}

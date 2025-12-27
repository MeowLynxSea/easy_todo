use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Arc;
use std::time::{Duration, Instant};

use anyhow::Context;
use axum::extract::{Query, State};
use axum::http::{header, HeaderMap, Method, StatusCode};
use axum::response::IntoResponse;
use axum::routing::{get, post};
use axum::{Json, Router};
use serde::{Deserialize, Serialize};
use sqlx::sqlite::SqlitePoolOptions;
use sqlx::{Pool, Row, Sqlite, Transaction};
use tower_http::cors::{Any, CorsLayer};
use tower_http::limit::RequestBodyLimitLayer;
use tower_http::trace::TraceLayer;
use tracing::{error, info};
use tracing_subscriber::EnvFilter;

const MAX_RECORD_B64_LEN: usize = 512 * 1024; // per-field b64 string length cap
const MAX_PULL_LIMIT: i64 = 500;
const BODY_LIMIT_BYTES: usize = 5 * 1024 * 1024;

#[derive(Clone)]
struct AppState {
    db: Pool<Sqlite>,
    limiter: Arc<tokio::sync::Mutex<RateLimiter>>,
}

struct RateLimiter {
    per_user: HashMap<String, (Instant, u32)>,
    window: Duration,
    max_requests: u32,
}

impl RateLimiter {
    fn new(window: Duration, max_requests: u32) -> Self {
        Self {
            per_user: HashMap::new(),
            window,
            max_requests,
        }
    }

    fn check(&mut self, user_key: &str) -> bool {
        let now = Instant::now();
        let entry = self
            .per_user
            .entry(user_key.to_string())
            .or_insert((now, 0));

        if now.duration_since(entry.0) > self.window {
            *entry = (now, 0);
        }

        if entry.1 >= self.max_requests {
            return false;
        }
        entry.1 += 1;
        true
    }
}

#[derive(Debug, Clone)]
struct AuthedUser {
    user_id: i64,
}

#[derive(Serialize)]
struct ErrorBody {
    error: String,
}

fn json_error(status: StatusCode, msg: impl Into<String>) -> (StatusCode, Json<ErrorBody>) {
    (status, Json(ErrorBody { error: msg.into() }))
}

async fn dev_auth(
    state: &AppState,
    headers: &HeaderMap,
) -> Result<AuthedUser, (StatusCode, Json<ErrorBody>)> {
    let auth = headers
        .get(header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");

    let token = auth.strip_prefix("Bearer ").unwrap_or("").trim();
    if token.is_empty() {
        return Err(json_error(StatusCode::UNAUTHORIZED, "missing bearer token"));
    }

    {
        let mut limiter = state.limiter.lock().await;
        if !limiter.check(token) {
            return Err(json_error(StatusCode::TOO_MANY_REQUESTS, "rate limited"));
        }
    }

    let now_ms = now_ms_utc();
    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let user_id = ensure_user(&mut tx, "dev", token, now_ms)
        .await
        .map_err(|e| {
            error!(error = %e, "ensure_user failed");
            json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error")
        })?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    Ok(AuthedUser { user_id })
}

async fn ensure_user(
    tx: &mut Transaction<'_, Sqlite>,
    oauth_provider: &str,
    oauth_sub: &str,
    now_ms_utc: i64,
) -> anyhow::Result<i64> {
    let existing: Option<i64> = sqlx::query_scalar(r#"SELECT id FROM users WHERE oauth_sub = ?"#)
        .bind(oauth_sub)
        .fetch_optional(&mut **tx)
        .await?;
    if let Some(id) = existing {
        return Ok(id);
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

    Ok(created.last_insert_rowid())
}

fn now_ms_utc() -> i64 {
    use std::time::{SystemTime, UNIX_EPOCH};
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_millis() as i64
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

#[derive(Debug, Deserialize)]
struct PutKeyBundleRequest {
    #[serde(rename = "expectedBundleVersion")]
    expected_bundle_version: i64,
    bundle: serde_json::Value,
}

async fn get_key_bundle(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    let user = dev_auth(&state, &headers).await?;

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
            Ok(Json(bundle))
        }
    }
}

async fn put_key_bundle(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<PutKeyBundleRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    let user = dev_auth(&state, &headers).await?;
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

    Ok(Json(bundle))
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

fn hlc_is_newer(a: &Hlc, b: &Hlc) -> bool {
    (a.wall_time_ms_utc, a.counter, &a.device_id) > (b.wall_time_ms_utc, b.counter, &b.device_id)
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

async fn push_sync(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<PushRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    let user = dev_auth(&state, &headers).await?;

    let mut accepted = Vec::new();
    let mut rejected = Vec::new();

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    for r in req.records {
        if r.nonce.len() > MAX_RECORD_B64_LEN || r.ciphertext.len() > MAX_RECORD_B64_LEN {
            rejected.push(PushRejected {
                r#type: r.r#type,
                record_id: r.record_id,
                reason: "record_too_large".to_string(),
            });
            continue;
        }

        let existing = sqlx::query(
            r#"SELECT hlc_wall_ms_utc, hlc_counter, hlc_device_id
         FROM records
         WHERE user_id = ? AND type = ? AND record_id = ?"#,
        )
        .bind(user.user_id)
        .bind(&r.r#type)
        .bind(&r.record_id)
        .fetch_optional(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

        let should_accept = match existing {
            None => true,
            Some(row) => {
                let stored = Hlc {
                    wall_time_ms_utc: row
                        .try_get("hlc_wall_ms_utc")
                        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
                    counter: row
                        .try_get("hlc_counter")
                        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
                    device_id: row
                        .try_get("hlc_device_id")
                        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?,
                };
                hlc_is_newer(&r.hlc, &stored)
            }
        };

        if !should_accept {
            rejected.push(PushRejected {
                r#type: r.r#type,
                record_id: r.record_id,
                reason: "older_hlc".to_string(),
            });
            continue;
        }

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

        accepted.push(PushAccepted {
            r#type: r.r#type,
            record_id: r.record_id,
            server_seq,
        });
    }

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    Ok(Json(PushResponse { accepted, rejected }))
}

#[derive(Debug, Deserialize)]
struct PullQuery {
    since: Option<i64>,
    limit: Option<i64>,
}

#[derive(Debug, Serialize)]
struct PullResponse {
    records: Vec<SyncRecordEnvelope>,
    #[serde(rename = "nextSince")]
    next_since: i64,
}

async fn pull_sync(
    State(state): State<AppState>,
    headers: HeaderMap,
    Query(q): Query<PullQuery>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    let user = dev_auth(&state, &headers).await?;

    let since = q.since.unwrap_or(0).max(0);
    let limit = q.limit.unwrap_or(200).clamp(1, MAX_PULL_LIMIT) as i64;

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
       WHERE user_id = ? AND server_seq > ?
       ORDER BY server_seq ASC
       LIMIT ?"#,
    )
    .bind(user.user_id)
    .bind(since)
    .bind(limit)
    .fetch_all(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

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

    Ok(Json(PullResponse {
        records,
        next_since,
    }))
}

async fn health() -> impl IntoResponse {
    "ok"
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
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

    let pool = SqlitePoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
        .with_context(|| format!("connect db: {database_url}"))?;

    sqlx::migrate!("./migrations")
        .run(&pool)
        .await
        .context("run migrations")?;

    let state = AppState {
        db: pool,
        limiter: Arc::new(tokio::sync::Mutex::new(RateLimiter::new(
            Duration::from_secs(1),
            50,
        ))),
    };

    let app = Router::new()
        .route("/v1/health", get(health))
        .route("/v1/key-bundle", get(get_key_bundle).put(put_key_bundle))
        .route("/v1/sync/push", post(push_sync))
        .route("/v1/sync/pull", get(pull_sync))
        // Dev-friendly CORS for Flutter Web on a different port (e.g. localhost:8080).
        // For production deployments, replace with a strict allowlist.
        .layer(
            CorsLayer::new()
                .allow_origin(Any)
                .allow_methods([Method::GET, Method::POST, Method::PUT, Method::OPTIONS])
                .allow_headers(Any),
        )
        .layer(RequestBodyLimitLayer::new(BODY_LIMIT_BYTES))
        .layer(TraceLayer::new_for_http())
        .with_state(state);

    let addr: SocketAddr = format!("{host}:{port}").parse().context("parse addr")?;
    info!(%addr, "sync server listening");

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;
    Ok(())
}

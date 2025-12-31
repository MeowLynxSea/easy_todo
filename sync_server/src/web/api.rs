use std::net::SocketAddr;
use std::collections::HashSet;

use axum::extract::{ConnectInfo, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::Json;
use serde::{Deserialize, Serialize};
use sqlx::Row;

use crate::{clear_subscription_if_expired, json_error, now_ms_utc, AppState, ErrorBody};

use super::session::{apply_set_cookie_headers, authenticate_web, clear_auth_cookies};
use super::util::check_same_origin;

const TYPE_TODO: &str = "todo";
const TYPE_TODO_ATTACHMENT: &str = "todo_attachment";
const TYPE_TODO_ATTACHMENT_CHUNK: &str = "todo_attachment_chunk";

#[derive(Debug, Serialize)]
struct MeResponse {
    #[serde(rename = "userId")]
    user_id: i64,
}

pub(super) async fn web_me(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    let (user_id, maybe_set_cookies) = authenticate_web(&state, &headers, Some(addr.ip())).await?;

    let mut resp = Json(MeResponse { user_id }).into_response();
    if let Some(set) = maybe_set_cookies {
        apply_set_cookie_headers(resp.headers_mut(), set);
    }
    Ok(resp)
}

#[derive(Debug, Deserialize)]
pub(super) struct ActivateCdkeyRequest {
    code: String,
}

#[derive(Debug, Serialize)]
struct ActivateCdkeyResponse {
    ok: bool,
    #[serde(rename = "planId")]
    plan_id: String,
    #[serde(rename = "planName")]
    plan_name: String,
    #[serde(rename = "expiresAtMsUtc")]
    expires_at_ms_utc: i64,
}

pub(super) async fn web_activate_cdkey(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Json(req): Json<ActivateCdkeyRequest>,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !check_same_origin(&state, &headers) {
        return Err(json_error(StatusCode::FORBIDDEN, "forbidden"));
    }

    let (user_id, maybe_set_cookies) = authenticate_web(&state, &headers, Some(addr.ip())).await?;

    let code = req.code.trim().to_uppercase();
    if code.is_empty() {
        return Err(json_error(StatusCode::BAD_REQUEST, "cdkey required"));
    }

    let now_ms = now_ms_utc();

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let sub_row = sqlx::query(
        r#"SELECT subscription_plan_id, subscription_expires_at_ms_utc FROM users WHERE id = ?"#,
    )
    .bind(user_id)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let Some(sub_row) = sub_row else {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::UNAUTHORIZED, "unauthorized"));
    };

    let mut current_plan_id: Option<String> = sub_row
        .try_get("subscription_plan_id")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let mut current_expires_at: Option<i64> = sub_row
        .try_get("subscription_expires_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let has_plan = current_plan_id
        .as_deref()
        .map(|s| !s.trim().is_empty())
        .unwrap_or(false);
    let expires_at = current_expires_at.unwrap_or(0);
    if has_plan && expires_at <= now_ms {
        clear_subscription_if_expired(
            &mut *tx,
            user_id,
            &current_plan_id,
            current_expires_at,
            now_ms,
        )
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
        current_plan_id = None;
        current_expires_at = None;
    }

    let has_active_sub = current_expires_at.unwrap_or(0) > now_ms
        && current_plan_id
            .as_deref()
            .map(|s| !s.trim().is_empty())
            .unwrap_or(false);
    if has_active_sub {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::CONFLICT, "already_subscribed"));
    }

    let plan_row = sqlx::query(r#"SELECT plan_id FROM cdkeys WHERE code = ?"#)
        .bind(&code)
        .fetch_optional(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let Some(plan_row) = plan_row else {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::NOT_FOUND, "cdkey_not_found"));
    };

    let plan_id_raw: String = plan_row
        .try_get("plan_id")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let plan_id = plan_id_raw.trim().to_lowercase();
    let Some(plan) = state.billing.plans.get(&plan_id) else {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::BAD_REQUEST, "unknown_plan"));
    };

    let deleted = sqlx::query(r#"DELETE FROM cdkeys WHERE code = ?"#)
        .bind(&code)
        .execute(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    if deleted.rows_affected() == 0 {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::NOT_FOUND, "cdkey_not_found"));
    }

    let expires_at_ms_utc = now_ms.saturating_add(plan.duration_ms);

    sqlx::query(
        r#"UPDATE users
           SET subscription_plan_id = ?, subscription_expires_at_ms_utc = ?
           WHERE id = ?"#,
    )
    .bind(&plan.id)
    .bind(expires_at_ms_utc)
    .bind(user_id)
    .execute(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    state.metrics.record_cdkey_activation(now_ms);

    let mut resp = Json(ActivateCdkeyResponse {
        ok: true,
        plan_id: plan.id.clone(),
        plan_name: plan.name.clone(),
        expires_at_ms_utc,
    })
    .into_response();
    if let Some(set) = maybe_set_cookies {
        apply_set_cookie_headers(resp.headers_mut(), set);
    }
    Ok(resp)
}

#[derive(Debug, Deserialize)]
pub(super) struct DeleteRequest {
    confirm: String,
}

#[derive(Debug, Serialize)]
struct OkResponse {
    ok: bool,
}

pub(super) async fn web_delete_me(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
    Json(req): Json<DeleteRequest>,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !check_same_origin(&state, &headers) {
        return Err(json_error(StatusCode::FORBIDDEN, "forbidden"));
    }

    let (user_id, maybe_set_cookies) = authenticate_web(&state, &headers, Some(addr.ip())).await?;

    if req.confirm.trim().to_uppercase() != "DELETE" {
        return Err(json_error(StatusCode::BAD_REQUEST, "confirm required"));
    }

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    sqlx::query(r#"DELETE FROM users WHERE id = ?"#)
        .bind(user_id)
        .execute(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let mut resp = Json(OkResponse { ok: true }).into_response();
    if let Some(set) = maybe_set_cookies {
        apply_set_cookie_headers(resp.headers_mut(), set);
    }
    apply_set_cookie_headers(resp.headers_mut(), clear_auth_cookies(&state));
    Ok(resp)
}

pub(super) async fn web_refresh(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !check_same_origin(&state, &headers) {
        return Err(json_error(StatusCode::FORBIDDEN, "forbidden"));
    }

    let (_user_id, maybe_set_cookies) = authenticate_web(&state, &headers, Some(addr.ip())).await?;
    let mut resp = Json(OkResponse { ok: true }).into_response();
    if let Some(set) = maybe_set_cookies {
        apply_set_cookie_headers(resp.headers_mut(), set);
    }
    Ok(resp)
}

fn escape_like_prefix(value: &str) -> String {
    value
        .replace('\\', "\\\\")
        .replace('%', "\\%")
        .replace('_', "\\_")
}

#[derive(Debug, Serialize)]
struct GcGhostFilesResponse {
    ok: bool,
    #[serde(rename = "deletedAttachments")]
    deleted_attachments: i64,
    #[serde(rename = "deletedRecords")]
    deleted_records: i64,
    #[serde(rename = "freedBytes")]
    freed_bytes: i64,
    #[serde(rename = "storedBytes")]
    stored_bytes: i64,
}

pub(super) async fn web_gc_ghost_files(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !check_same_origin(&state, &headers) {
        return Err(json_error(StatusCode::FORBIDDEN, "forbidden"));
    }

    let (user_id, maybe_set_cookies) = authenticate_web(&state, &headers, Some(addr.ip())).await?;

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let stored_before: Option<i64> =
        sqlx::query_scalar(r#"SELECT stored_b64 FROM users WHERE id = ?"#)
            .bind(user_id)
            .fetch_optional(&mut *tx)
            .await
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let Some(stored_before) = stored_before else {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::UNAUTHORIZED, "unauthorized"));
    };

    let has_live_todo: bool = sqlx::query_scalar::<_, i64>(
        r#"SELECT 1
           FROM records
           WHERE user_id = ?
             AND type = ?
             AND deleted_at_ms_utc IS NULL
           LIMIT 1"#,
    )
    .bind(user_id)
    .bind(TYPE_TODO)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?
    .is_some();

    // Ghost attachment = attachment exists server-side but its owning todo no
    // longer exists (or was tombstoned). Attachment ownership comes from
    // `attachment_refs` populated by clients.
    let orphan_attachment_ids: Vec<String> = sqlx::query_scalar(
        r#"SELECT attachment_id
           FROM attachment_refs ar
           WHERE ar.user_id = ?
             AND NOT EXISTS (
               SELECT 1
               FROM records t
               WHERE t.user_id = ar.user_id
                 AND t.type = ?
                 AND t.record_id = ar.todo_id
                 AND t.deleted_at_ms_utc IS NULL
               LIMIT 1
             )"#,
    )
    .bind(user_id)
    .bind(TYPE_TODO)
    .fetch_all(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    // Fallback: if the user has no live todos at all, any stored attachments
    // cannot be referenced by an existing todo, so treat them as ghosts even
    // when `attachment_refs` is empty (e.g. before the app backfills refs).
    let mut attachment_ids: HashSet<String> = orphan_attachment_ids
        .into_iter()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    if !has_live_todo {
        let direct_meta_ids: Vec<String> = sqlx::query_scalar(
            r#"SELECT record_id FROM records WHERE user_id = ? AND type = ?"#,
        )
        .bind(user_id)
        .bind(TYPE_TODO_ATTACHMENT)
        .fetch_all(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
        for id in direct_meta_ids {
            let id = id.trim();
            if !id.is_empty() {
                attachment_ids.insert(id.to_string());
            }
        }

        // Also include attachments that may have chunk rows but missing meta.
        let chunk_prefix_ids: Vec<String> = sqlx::query_scalar(
            r#"SELECT DISTINCT substr(record_id, 1, instr(record_id, ':') - 1)
               FROM records
               WHERE user_id = ? AND type = ? AND instr(record_id, ':') > 0"#,
        )
        .bind(user_id)
        .bind(TYPE_TODO_ATTACHMENT_CHUNK)
        .fetch_all(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
        for id in chunk_prefix_ids {
            let id = id.trim();
            if !id.is_empty() {
                attachment_ids.insert(id.to_string());
            }
        }
    }

    let mut deleted_attachments = 0_i64;
    let mut deleted_records = 0_i64;

    for attachment_id in attachment_ids {
        let attachment_id = attachment_id.trim().to_string();
        if attachment_id.is_empty() {
            continue;
        }

        let escaped = escape_like_prefix(&attachment_id);
        let chunk_pattern = format!("{escaped}:%");

        let mut deleted_any = 0_i64;

        deleted_any += sqlx::query(
            r#"DELETE FROM records WHERE user_id = ? AND type = ? AND record_id = ?"#,
        )
        .bind(user_id)
        .bind(TYPE_TODO_ATTACHMENT)
        .bind(&attachment_id)
        .execute(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?
        .rows_affected() as i64;

        deleted_any += sqlx::query(
            r#"DELETE FROM records
               WHERE user_id = ? AND type = ? AND record_id LIKE ? ESCAPE '\'"#,
        )
        .bind(user_id)
        .bind(TYPE_TODO_ATTACHMENT_CHUNK)
        .bind(&chunk_pattern)
        .execute(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?
        .rows_affected() as i64;

        deleted_any += sqlx::query(
            r#"DELETE FROM staged_records WHERE user_id = ? AND type = ? AND record_id = ?"#,
        )
        .bind(user_id)
        .bind(TYPE_TODO_ATTACHMENT)
        .bind(&attachment_id)
        .execute(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?
        .rows_affected() as i64;

        deleted_any += sqlx::query(
            r#"DELETE FROM staged_records
               WHERE user_id = ? AND type = ? AND record_id LIKE ? ESCAPE '\'"#,
        )
        .bind(user_id)
        .bind(TYPE_TODO_ATTACHMENT_CHUNK)
        .bind(&chunk_pattern)
        .execute(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?
        .rows_affected() as i64;

        let _ = sqlx::query(r#"DELETE FROM attachment_refs WHERE user_id = ? AND attachment_id = ?"#)
            .bind(user_id)
            .bind(&attachment_id)
            .execute(&mut *tx)
            .await;

        if deleted_any > 0 {
            deleted_attachments += 1;
        }
        deleted_records += deleted_any;
    }

    let stored_after: i64 = sqlx::query_scalar(
        r#"SELECT
             (SELECT IFNULL(SUM(LENGTH(nonce) + LENGTH(ciphertext)), 0) FROM records WHERE user_id = ?)
           + (SELECT IFNULL(SUM(LENGTH(nonce) + LENGTH(ciphertext)), 0) FROM staged_records WHERE user_id = ?)"#,
    )
    .bind(user_id)
    .bind(user_id)
    .fetch_one(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    sqlx::query(r#"UPDATE users SET stored_b64 = ? WHERE id = ?"#)
        .bind(stored_after)
        .bind(user_id)
        .execute(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let freed_bytes = (stored_before - stored_after).max(0);

    let mut resp = Json(GcGhostFilesResponse {
        ok: true,
        deleted_attachments,
        deleted_records,
        freed_bytes,
        stored_bytes: stored_after,
    })
    .into_response();

    if let Some(set) = maybe_set_cookies {
        apply_set_cookie_headers(resp.headers_mut(), set);
    }
    Ok(resp)
}

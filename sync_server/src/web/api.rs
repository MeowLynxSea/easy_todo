use std::net::SocketAddr;

use axum::extract::{ConnectInfo, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::Json;
use serde::{Deserialize, Serialize};
use sqlx::Row;

use crate::{clear_subscription_if_expired, json_error, now_ms_utc, AppState, ErrorBody};

use super::session::{apply_set_cookie_headers, authenticate_web, clear_auth_cookies};
use super::util::check_same_origin;

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

    let stats = crate::ghost_gc::gc_ghost_files_for_user_with_stored_before(
        &mut tx,
        user_id,
        stored_before,
        crate::ghost_gc::GhostGcOptions {
            include_unreferenced_when_no_live_todo: true,
            min_ref_age_ms: 0,
        },
    )
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let freed_bytes = (stats.stored_before - stats.stored_after).max(0);

    let mut resp = Json(GcGhostFilesResponse {
        ok: true,
        deleted_attachments: stats.deleted_attachments,
        deleted_records: stats.deleted_records,
        freed_bytes,
        stored_bytes: stats.stored_after,
    })
    .into_response();

    if let Some(set) = maybe_set_cookies {
        apply_set_cookie_headers(resp.headers_mut(), set);
    }
    Ok(resp)
}

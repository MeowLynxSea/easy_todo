use std::net::SocketAddr;

use axum::extract::{ConnectInfo, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::Json;
use serde::{Deserialize, Serialize};

use crate::{json_error, AppState, ErrorBody};

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

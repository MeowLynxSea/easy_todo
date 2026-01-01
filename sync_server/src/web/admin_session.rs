use axum::http::{HeaderMap, HeaderValue, StatusCode};
use axum::Json;
use jsonwebtoken::{decode, encode, Algorithm, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};

use crate::{json_error, now_ms_utc, AppState, ErrorBody};

use super::session::cookie_value;

const ADMIN_COOKIE: &str = "easy_todo_admin";
const ADMIN_ISSUER: &str = "easy_todo_admin";

#[derive(Debug, Serialize, Deserialize)]
struct AdminClaims {
    iss: String,
    sub: String,
    iat: usize,
    exp: usize,
}

pub(super) fn authenticate_admin(
    state: &AppState,
    headers: &HeaderMap,
) -> Result<(), (StatusCode, Json<ErrorBody>)> {
    if !state.admin.enabled() {
        return Err(json_error(StatusCode::NOT_FOUND, "not found"));
    }

    let Some(token) = cookie_value(headers, ADMIN_COOKIE) else {
        return Err(json_error(StatusCode::UNAUTHORIZED, "unauthorized"));
    };

    let mut validation = Validation::new(Algorithm::HS256);
    validation.set_issuer(&[ADMIN_ISSUER]);
    decode::<AdminClaims>(
        &token,
        &DecodingKey::from_secret(state.auth.config.jwt_secret.as_bytes()),
        &validation,
    )
    .map_err(|_| json_error(StatusCode::UNAUTHORIZED, "unauthorized"))?;

    Ok(())
}

pub(super) fn build_admin_login_cookie(
    state: &AppState,
) -> Result<Vec<HeaderValue>, (StatusCode, Json<ErrorBody>)> {
    if !state.admin.enabled() {
        return Err(json_error(StatusCode::NOT_FOUND, "not found"));
    }

    let now = now_ms_utc();
    let iat = (now / 1000).max(0) as usize;
    let exp = iat.saturating_add(state.admin.session_ttl_secs.max(60) as usize);

    let claims = AdminClaims {
        iss: ADMIN_ISSUER.to_string(),
        sub: "admin".to_string(),
        iat,
        exp,
    };
    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(state.auth.config.jwt_secret.as_bytes()),
    )
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "encode error"))?;

    let secure = cookie_secure_flag(&state.auth.config.base_url);
    Ok(vec![set_cookie(
        ADMIN_COOKIE,
        &token,
        state.admin.session_ttl_secs,
        secure,
        &state.admin.entry_path,
    )])
}

pub(super) fn clear_admin_cookies(state: &AppState) -> Vec<HeaderValue> {
    let secure = cookie_secure_flag(&state.auth.config.base_url);
    vec![set_cookie(ADMIN_COOKIE, "", 0, secure, &state.admin.entry_path)]
}

fn set_cookie(name: &str, value: &str, max_age_secs: i64, secure: bool, path: &str) -> HeaderValue {
    let mut s = String::new();
    s.push_str(name);
    s.push('=');
    s.push_str(value);
    s.push_str("; Path=");
    s.push_str(path);
    s.push_str("; HttpOnly; SameSite=Lax; Max-Age=");
    s.push_str(&max_age_secs.to_string());
    if secure {
        s.push_str("; Secure");
    }
    s.push_str("; Priority=High");
    HeaderValue::from_str(&s).unwrap_or_else(|_| HeaderValue::from_static(""))
}

fn cookie_secure_flag(base_url: &str) -> bool {
    base_url.trim_start().to_lowercase().starts_with("https://")
}

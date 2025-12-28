use axum::http::{header, HeaderMap, HeaderValue, StatusCode};
use axum::Json;

use crate::{json_error, now_ms_utc, AppState, ErrorBody};

const ACCESS_COOKIE: &str = "easy_todo_access";
const REFRESH_COOKIE: &str = "easy_todo_refresh";

pub(super) fn apply_set_cookie_headers(
    headers: &mut HeaderMap,
    set_cookie_values: Vec<HeaderValue>,
) {
    for v in set_cookie_values {
        headers.append(header::SET_COOKIE, v);
    }
}

pub(super) fn cookie_value(headers: &HeaderMap, name: &str) -> Option<String> {
    let raw = headers.get(header::COOKIE)?.to_str().ok()?;
    for part in raw.split(';') {
        let part = part.trim();
        if part.is_empty() {
            continue;
        }
        let (k, v) = part.split_once('=')?;
        if k.trim() == name {
            return Some(v.trim().to_string());
        }
    }
    None
}

pub(super) fn clear_auth_cookies(state: &AppState) -> Vec<HeaderValue> {
    let secure = cookie_secure_flag(&state.auth.config.base_url);
    vec![
        set_cookie(ACCESS_COOKIE, "", 0, secure),
        set_cookie(REFRESH_COOKIE, "", 0, secure),
    ]
}

pub(super) async fn authenticate_web(
    state: &AppState,
    headers: &HeaderMap,
    remote_ip: Option<std::net::IpAddr>,
) -> Result<(i64, Option<Vec<HeaderValue>>), (StatusCode, Json<ErrorBody>)> {
    if let Some(access) = cookie_value(headers, ACCESS_COOKIE) {
        let mut h = HeaderMap::new();
        let auth = HeaderValue::from_str(&format!("Bearer {access}"))
            .map_err(|_| json_error(StatusCode::UNAUTHORIZED, "unauthorized"))?;
        h.insert(header::AUTHORIZATION, auth);
        if let Ok(user) = state
            .auth
            .authenticate_request(&state.db, &state.limiter, &h, remote_ip)
            .await
        {
            return Ok((user.user_id, None));
        }
    }

    let Some(refresh) = cookie_value(headers, REFRESH_COOKIE) else {
        return Err(json_error(StatusCode::UNAUTHORIZED, "unauthorized"));
    };

    let now_ms = now_ms_utc();
    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let (user_id, tokens) = state
        .auth
        .rotate_refresh_token(&mut tx, &refresh, now_ms)
        .await
        .map_err(|_| json_error(StatusCode::UNAUTHORIZED, "unauthorized"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let set = build_auth_cookies(
        state,
        &tokens.access_token,
        tokens.expires_in,
        &tokens.refresh_token,
    );

    Ok((user_id, Some(set)))
}

fn build_auth_cookies(
    state: &AppState,
    access_token: &str,
    access_max_age_secs: i64,
    refresh_token: &str,
) -> Vec<HeaderValue> {
    let secure = cookie_secure_flag(&state.auth.config.base_url);
    let refresh_max_age = state.auth.config.refresh_token_ttl.as_secs() as i64;

    let mut out = Vec::new();
    out.push(set_cookie(
        ACCESS_COOKIE,
        access_token,
        access_max_age_secs,
        secure,
    ));
    out.push(set_cookie(
        REFRESH_COOKIE,
        refresh_token,
        refresh_max_age,
        secure,
    ));
    out
}

fn set_cookie(name: &str, value: &str, max_age_secs: i64, secure: bool) -> HeaderValue {
    let mut s = String::new();
    s.push_str(name);
    s.push('=');
    s.push_str(value);
    s.push_str("; Path=/; HttpOnly; SameSite=Lax; Max-Age=");
    s.push_str(&max_age_secs.to_string());
    if secure {
        s.push_str("; Secure");
    }
    HeaderValue::from_str(&s).unwrap_or_else(|_| HeaderValue::from_static(""))
}

fn cookie_secure_flag(base_url: &str) -> bool {
    base_url.trim_start().to_lowercase().starts_with("https://")
}

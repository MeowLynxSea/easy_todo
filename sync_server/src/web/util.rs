use std::time::Duration;

use axum::http::{header, HeaderMap, HeaderValue, StatusCode};
use axum::response::Response;
use url::{form_urlencoded, Url};

use crate::AppState;

pub(super) fn h(input: &str) -> String {
    input
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#x27;")
}

pub(super) fn url_encode(input: &str) -> String {
    form_urlencoded::byte_serialize(input.as_bytes()).collect()
}

pub(super) fn validate_return_to(input: &str) -> Option<&str> {
    let s = input.trim();
    if !s.starts_with('/') {
        return None;
    }
    if s.starts_with("//") {
        return None;
    }
    if s.contains("://") || s.contains('\\') {
        return None;
    }
    Some(s)
}

pub(super) fn format_number(n: i64) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().rev().enumerate() {
        if i != 0 && i % 3 == 0 {
            out.push(',');
        }
        out.push(ch);
    }
    out.chars().rev().collect()
}

pub(super) fn format_bytes(b64_len: i64) -> String {
    let b = b64_len.max(0) as f64;
    let units = ["B", "KB", "MB", "GB", "TB"];
    let mut v = b;
    let mut i = 0usize;
    while v >= 1024.0 && i + 1 < units.len() {
        v /= 1024.0;
        i += 1;
    }
    if i == 0 {
        format!("{:.0} {}", v, units[i])
    } else {
        format!("{:.2} {}", v, units[i])
    }
}

pub(super) fn format_uptime(d: Duration) -> String {
    let secs = d.as_secs().max(0);
    let days = secs / 86400;
    let hours = (secs % 86400) / 3600;
    let mins = (secs % 3600) / 60;
    if days > 0 {
        format!("{days}d {hours}h")
    } else if hours > 0 {
        format!("{hours}h {mins}m")
    } else {
        format!("{mins}m")
    }
}

pub(super) fn provider_display_name(state: &AppState, provider: &str) -> String {
    let key = provider.trim().to_lowercase();
    state
        .auth
        .config
        .providers
        .get(&key)
        .map(|p| p.name.trim().to_string())
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| provider.to_string())
}

pub(super) fn provider_icon_text(display_name: &str) -> String {
    display_name
        .chars()
        .filter(|c| c.is_ascii_alphanumeric())
        .take(2)
        .collect::<String>()
        .to_uppercase()
        .chars()
        .chain(std::iter::repeat('O'))
        .take(2)
        .collect()
}

pub(super) fn see_other(location: &str) -> Response {
    let mut resp = Response::new(axum::body::Body::empty());
    *resp.status_mut() = StatusCode::SEE_OTHER;
    resp.headers_mut().insert(
        header::LOCATION,
        HeaderValue::from_str(location).unwrap_or_else(|_| HeaderValue::from_static("/")),
    );
    resp
}

pub(super) fn check_same_origin(state: &AppState, headers: &HeaderMap) -> bool {
    let base_url = state.auth.config.base_url.trim_end_matches('/');
    let base_origin = base_url_origin(base_url).unwrap_or_else(|| base_url.to_string());

    if let Some(origin) = headers.get(header::ORIGIN).and_then(|v| v.to_str().ok()) {
        return origin.trim_end_matches('/') == base_origin;
    }

    let Some(referer) = headers.get(header::REFERER).and_then(|v| v.to_str().ok()) else {
        // Strict by default: if neither Origin nor Referer are present, treat the request as
        // potentially cross-site.
        return false;
    };

    let Ok(url) = Url::parse(referer) else {
        return false;
    };
    let host = url.host_str().unwrap_or("");
    if host.is_empty() {
        return false;
    }

    let mut origin = format!("{}://{}", url.scheme(), host);
    if let Some(port) = url.port() {
        origin.push(':');
        origin.push_str(&port.to_string());
    }
    origin.trim_end_matches('/') == base_origin
}

fn base_url_origin(base_url: &str) -> Option<String> {
    let url = Url::parse(base_url).ok()?;
    let host = url.host_str()?;
    let mut out = format!("{}://{}", url.scheme(), host);
    if let Some(port) = url.port() {
        out.push(':');
        out.push_str(&port.to_string());
    }
    Some(out)
}

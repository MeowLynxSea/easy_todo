use std::collections::HashMap;
use std::net::{IpAddr, SocketAddr};
use std::time::Duration;

use anyhow::Context;
use async_trait::async_trait;
use axum::extract::{ConnectInfo, FromRequestParts, Query, State};
use axum::http::request::Parts;
use axum::http::{header, HeaderMap, StatusCode};
use axum::response::{Html, IntoResponse, Redirect};
use axum::routing::{get, post};
use axum::{Json, Router};
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use base64::Engine;
use rand::RngCore;
use reqwest::header::{ACCEPT, USER_AGENT};
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use sqlx::{Pool, Row, Sqlite, Transaction};
use url::Url;

use crate::{json_error, now_ms_utc, AppState, ErrorBody, RateLimiter};

#[derive(Debug, Clone, Deserialize)]
pub struct OAuthProviderConfig {
    pub name: String,
    #[serde(rename = "authorizeUrl")]
    pub authorize_url: String,
    #[serde(rename = "tokenUrl")]
    pub token_url: String,
    #[serde(rename = "userinfoUrl")]
    pub userinfo_url: String,
    #[serde(rename = "clientId")]
    pub client_id: String,
    #[serde(rename = "clientSecret")]
    pub client_secret: String,
    pub scope: Option<String>,
    /// Dot-path for the user unique identifier in userinfo JSON. Example: "id", "data.id", "user.sub".
    #[serde(rename = "idField")]
    pub id_field: Option<String>,
    /// Field name in token response that contains the access token. Default: "access_token".
    #[serde(rename = "accessTokenField")]
    pub access_token_field: Option<String>,
    /// Extra query params appended to the authorize URL.
    #[serde(rename = "extraAuthorizeParams")]
    pub extra_authorize_params: Option<HashMap<String, String>>,
    /// Extra form params appended to the token request.
    #[serde(rename = "extraTokenParams")]
    pub extra_token_params: Option<HashMap<String, String>>,
    /// Token endpoint client authentication method.
    ///
    /// - "basic" (default for Linux.do): send client_id/client_secret via HTTP Basic auth.
    /// - "post": send client_id/client_secret in the form body.
    #[serde(rename = "tokenAuthMethod")]
    pub token_auth_method: Option<String>,
}

#[derive(Debug, Clone)]
pub struct AuthConfig {
    pub base_url: String,
    pub jwt_secret: String,
    pub jwt_issuer: String,
    pub token_pepper: String,
    pub app_redirect_allowlist: Vec<String>,
    pub access_token_ttl: Duration,
    pub refresh_token_ttl: Duration,
    pub login_attempt_ttl: Duration,
    pub ticket_ttl: Duration,
    pub enabled_providers: Vec<String>,
    pub providers: HashMap<String, OAuthProviderConfig>,
}

impl AuthConfig {
    pub fn load_from_env() -> anyhow::Result<Self> {
        let base_url =
            std::env::var("BASE_URL").unwrap_or_else(|_| "http://127.0.0.1:8787".to_string());

        let jwt_secret =
            std::env::var("JWT_SECRET").unwrap_or_else(|_| "dev-secret-change-me".to_string());
        let jwt_issuer =
            std::env::var("JWT_ISSUER").unwrap_or_else(|_| "easy_todo_sync_server".to_string());
        let token_pepper =
            std::env::var("TOKEN_PEPPER").unwrap_or_else(|_| "dev-pepper-change-me".to_string());

        let app_redirect_allowlist = std::env::var("APP_REDIRECT_ALLOWLIST")
            .unwrap_or_else(|_| "easy_todo://".to_string())
            .split(',')
            .map(|s| s.trim().to_string())
            .filter(|s| !s.is_empty())
            .collect::<Vec<_>>();

        let providers = load_oauth_providers_from_env()
            .context("load oauth providers (OAUTH_PROVIDERS_JSON)")?;

        let enabled_providers = match std::env::var("AUTH_PROVIDERS") {
            Ok(v) => v
                .split(',')
                .map(|s| s.trim().to_lowercase())
                .filter(|s| !s.is_empty())
                .collect::<Vec<_>>(),
            Err(_) => {
                let mut keys = providers.keys().cloned().collect::<Vec<_>>();
                keys.sort();
                keys
            }
        };

        let access_token_ttl = Duration::from_secs(
            std::env::var("ACCESS_TOKEN_TTL_SECS")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(15 * 60),
        );
        let refresh_token_ttl = Duration::from_secs(
            std::env::var("REFRESH_TOKEN_TTL_SECS")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(30 * 24 * 60 * 60),
        );
        let login_attempt_ttl = Duration::from_secs(
            std::env::var("LOGIN_ATTEMPT_TTL_SECS")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(10 * 60),
        );
        let ticket_ttl = Duration::from_secs(
            std::env::var("TICKET_TTL_SECS")
                .ok()
                .and_then(|s| s.parse().ok())
                .unwrap_or(120),
        );

        Ok(Self {
            base_url,
            jwt_secret,
            jwt_issuer,
            token_pepper,
            app_redirect_allowlist,
            access_token_ttl,
            refresh_token_ttl,
            login_attempt_ttl,
            ticket_ttl,
            enabled_providers,
            providers,
        })
    }
}

#[derive(Clone)]
pub struct AuthService {
    pub config: AuthConfig,
    http: reqwest::Client,
}

impl AuthService {
    pub fn new(config: AuthConfig) -> anyhow::Result<Self> {
        let http = reqwest::Client::builder()
            .timeout(Duration::from_secs(15))
            .build()
            .context("build http client")?;
        Ok(Self { config, http })
    }

    fn redirect_uri(&self) -> String {
        format!(
            "{}/v1/auth/callback",
            self.config.base_url.trim_end_matches('/')
        )
    }

    fn is_allowed_app_redirect(&self, app_redirect: &str) -> bool {
        self.config
            .app_redirect_allowlist
            .iter()
            .any(|prefix| app_redirect.starts_with(prefix))
    }

    fn random_token_b64(&self, bytes_len: usize) -> String {
        let mut bytes = vec![0u8; bytes_len];
        rand::thread_rng().fill_bytes(&mut bytes);
        URL_SAFE_NO_PAD.encode(bytes)
    }

    fn hash_token(&self, token: &str) -> String {
        let mut h = Sha256::new();
        h.update(self.config.token_pepper.as_bytes());
        h.update(b":");
        h.update(token.as_bytes());
        hex_encode(&h.finalize())
    }

    fn append_ticket(&self, app_redirect: &str, ticket: &str) -> String {
        let ticket_enc: String = url::form_urlencoded::byte_serialize(ticket.as_bytes()).collect();
        let (base, fragment) = match app_redirect.split_once('#') {
            Some((b, f)) => (b, Some(f)),
            None => (app_redirect, None),
        };

        let sep = if base.ends_with('?') || base.ends_with('&') {
            ""
        } else if base.contains('?') {
            "&"
        } else {
            "?"
        };
        let mut url = format!("{base}{sep}ticket={ticket_enc}");
        if let Some(frag) = fragment {
            url.push('#');
            url.push_str(frag);
        }
        url
    }

    fn html_result_page(
        &self,
        title: &str,
        message: &str,
        maybe_redirect: Option<&str>,
    ) -> Html<String> {
        let title = html_escape(title);
        let message = html_escape(message);
        let redirect_raw = maybe_redirect.map(|s| s.to_string());
        let redirect_html = maybe_redirect.map(html_escape);

        let mut body = String::new();
        body.push_str("<!doctype html><html><head><meta charset=\"utf-8\" />");
        body.push_str("<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />");
        body.push_str(&format!("<title>{title}</title>"));
        body.push_str("<style>body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Helvetica,Arial;max-width:720px;margin:40px auto;padding:0 16px}a,button{font-size:16px}code{background:#f4f4f4;padding:2px 6px;border-radius:6px}</style>");
        body.push_str("</head><body>");
        body.push_str(&format!("<h1>{title}</h1><p>{message}</p>"));
        if let (Some(r_html), Some(r_raw)) = (&redirect_html, &redirect_raw) {
            body.push_str(&format!(
                "<p><a href=\"{r_html}\">Return to app</a></p><script>window.location.href={};</script>",
                serde_json::to_string(r_raw).unwrap_or_else(|_| "\"\"".to_string())
            ));
        }
        body.push_str("</body></html>");
        Html(body)
    }

    pub fn auth_router() -> Router<AppState> {
        Router::new()
            .route("/providers", get(auth_providers))
            .route("/start", get(auth_start))
            .route("/callback", get(auth_callback))
            .route("/exchange", post(auth_exchange))
            .route("/refresh", post(auth_refresh))
            .route("/logout", post(auth_logout))
    }

    async fn oauth_authorize_url(&self, provider: &str, state: &str) -> anyhow::Result<String> {
        let provider = provider.to_lowercase();
        let cfg = self
            .config
            .providers
            .get(&provider)
            .with_context(|| format!("provider not configured: {provider}"))?;

        let redirect_uri = self.redirect_uri();

        let mut url = Url::parse(&cfg.authorize_url).context("parse authorize_url")?;
        {
            let mut qp = url.query_pairs_mut();
            qp.append_pair("client_id", &cfg.client_id);
            qp.append_pair("redirect_uri", &redirect_uri);
            qp.append_pair("response_type", "code");
            qp.append_pair("state", state);
            if let Some(scope) = &cfg.scope {
                if !scope.trim().is_empty() {
                    qp.append_pair("scope", scope);
                }
            }
            if let Some(extra) = &cfg.extra_authorize_params {
                for (k, v) in extra {
                    qp.append_pair(k, v);
                }
            }
        }

        Ok(url.to_string())
    }

    async fn oauth_exchange_code(&self, provider: &str, code: &str) -> anyhow::Result<String> {
        let provider = provider.to_lowercase();
        let cfg = self
            .config
            .providers
            .get(&provider)
            .with_context(|| format!("provider not configured: {provider}"))?;

        let redirect_uri = self.redirect_uri();

        let mut params: Vec<(String, String)> = vec![
            ("code".to_string(), code.to_string()),
            ("redirect_uri".to_string(), redirect_uri),
            ("grant_type".to_string(), "authorization_code".to_string()),
        ];
        if let Some(extra) = &cfg.extra_token_params {
            for (k, v) in extra {
                params.push((k.clone(), v.clone()));
            }
        }

        let token_auth_method = cfg
            .token_auth_method
            .as_deref()
            .unwrap_or("basic")
            .to_lowercase();

        let mut req = self
            .http
            .post(&cfg.token_url)
            .header(ACCEPT, "application/json");

        match token_auth_method.as_str() {
            "basic" => {
                req = req.basic_auth(cfg.client_id.clone(), Some(cfg.client_secret.clone()));
            }
            "post" => {
                params.push(("client_id".to_string(), cfg.client_id.clone()));
                params.push(("client_secret".to_string(), cfg.client_secret.clone()));
            }
            other => anyhow::bail!("unsupported tokenAuthMethod: {other}"),
        }

        let resp = req.form(&params).send().await.context("token request")?;
        let status = resp.status();
        let text = resp.text().await.context("read token response")?;
        if !status.is_success() {
            anyhow::bail!("token response status: {status}");
        }

        let access_token_field = cfg.access_token_field.as_deref().unwrap_or("access_token");

        // JSON first
        if let Ok(val) = serde_json::from_str::<serde_json::Value>(&text) {
            if let Some(token) = val.get(access_token_field).and_then(|v| v.as_str()) {
                if !token.is_empty() {
                    return Ok(token.to_string());
                }
            }
        }

        // Fallback: x-www-form-urlencoded response
        let mut token: Option<String> = None;
        for (k, v) in url::form_urlencoded::parse(text.as_bytes()) {
            if k == access_token_field {
                token = Some(v.to_string());
                break;
            }
        }
        token.context("missing access_token in token response")
    }

    async fn oauth_fetch_subject(
        &self,
        provider: &str,
        access_token: &str,
    ) -> anyhow::Result<String> {
        let provider = provider.to_lowercase();
        let cfg = self
            .config
            .providers
            .get(&provider)
            .with_context(|| format!("provider not configured: {provider}"))?;

        let id_field = cfg.id_field.as_deref().unwrap_or("id");

        let resp = self
            .http
            .get(&cfg.userinfo_url)
            .header(USER_AGENT, "easy_todo_sync_server")
            .bearer_auth(access_token)
            .send()
            .await
            .context("userinfo request")?;
        let status = resp.status();
        let val = resp
            .json::<serde_json::Value>()
            .await
            .context("userinfo json")?;
        if !status.is_success() {
            anyhow::bail!("userinfo response status: {status}");
        }

        extract_json_string_field(&val, id_field)
            .with_context(|| format!("missing user id field: {id_field}"))
    }

    pub async fn authenticate_request(
        &self,
        pool: &Pool<Sqlite>,
        limiter: &tokio::sync::Mutex<RateLimiter>,
        headers: &HeaderMap,
        remote_ip: Option<IpAddr>,
    ) -> Result<AuthedUser, (StatusCode, Json<ErrorBody>)> {
        let token = extract_bearer(headers)
            .ok_or_else(|| json_error(StatusCode::UNAUTHORIZED, "missing bearer token"))?;
        {
            let mut limiter = limiter.lock().await;
            let ip = remote_ip
                .map(|v| v.to_string())
                .unwrap_or_else(|| "unknown".to_string());
            if !limiter.check(&format!("api_ip:{ip}")) {
                return Err(json_error(StatusCode::TOO_MANY_REQUESTS, "rate limited"));
            }
        }

        let user_id = self
            .verify_access_token(pool, &token)
            .await
            .map_err(|_| json_error(StatusCode::UNAUTHORIZED, "invalid access token"))?;
        {
            let mut limiter = limiter.lock().await;
            if !limiter.check(&format!("api_user:{user_id}")) {
                return Err(json_error(StatusCode::TOO_MANY_REQUESTS, "rate limited"));
            }
        }
        Ok(AuthedUser { user_id })
    }

    async fn verify_access_token(&self, pool: &Pool<Sqlite>, jwt: &str) -> anyhow::Result<i64> {
        #[derive(Debug, Serialize, Deserialize)]
        struct Claims {
            sub: String,
            sid: i64,
            iss: String,
            iat: usize,
            exp: usize,
        }

        let mut validation = jsonwebtoken::Validation::new(jsonwebtoken::Algorithm::HS256);
        validation.set_issuer(&[self.config.jwt_issuer.clone()]);
        let data = jsonwebtoken::decode::<Claims>(
            jwt,
            &jsonwebtoken::DecodingKey::from_secret(self.config.jwt_secret.as_bytes()),
            &validation,
        )
        .context("decode access jwt")?;

        let user_id: i64 = data.claims.sub.parse().context("sub not i64")?;
        let session_id = data.claims.sid;

        let now_ms = now_ms_utc();
        let row = sqlx::query(
            r#"SELECT user_id, expires_at_ms_utc, revoked_at_ms_utc
               FROM refresh_tokens WHERE id = ?"#,
        )
        .bind(session_id)
        .fetch_optional(pool)
        .await
        .context("load session")?;

        let Some(row) = row else {
            anyhow::bail!("session not found");
        };

        let sid_user_id: i64 = row.try_get("user_id")?;
        let expires_at_ms_utc: i64 = row.try_get("expires_at_ms_utc")?;
        let revoked_at_ms_utc: Option<i64> = row.try_get("revoked_at_ms_utc")?;

        if sid_user_id != user_id {
            anyhow::bail!("session user mismatch");
        }
        if revoked_at_ms_utc.is_some() {
            anyhow::bail!("session revoked");
        }
        if expires_at_ms_utc <= now_ms {
            anyhow::bail!("session expired");
        }

        Ok(user_id)
    }

    fn sign_access_token(&self, user_id: i64, session_id: i64) -> anyhow::Result<(String, i64)> {
        #[derive(Debug, Serialize, Deserialize)]
        struct Claims<'a> {
            sub: String,
            sid: i64,
            iss: &'a str,
            iat: usize,
            exp: usize,
        }

        let now_ms = now_ms_utc();
        let now_sec = (now_ms / 1000).max(0) as usize;
        let exp_sec = now_sec + self.config.access_token_ttl.as_secs() as usize;
        let expires_in = self.config.access_token_ttl.as_secs() as i64;

        let claims = Claims {
            sub: user_id.to_string(),
            sid: session_id,
            iss: &self.config.jwt_issuer,
            iat: now_sec,
            exp: exp_sec,
        };

        let token = jsonwebtoken::encode(
            &jsonwebtoken::Header::new(jsonwebtoken::Algorithm::HS256),
            &claims,
            &jsonwebtoken::EncodingKey::from_secret(self.config.jwt_secret.as_bytes()),
        )
        .context("encode access jwt")?;

        Ok((token, expires_in))
    }

    async fn new_session(
        &self,
        tx: &mut Transaction<'_, Sqlite>,
        user_id: i64,
        rotated_from_id: Option<i64>,
        now_ms: i64,
    ) -> anyhow::Result<(i64, String)> {
        let refresh_token = self.random_token_b64(32);
        let token_hash = self.hash_token(&refresh_token);
        let expires_at_ms = now_ms + self.config.refresh_token_ttl.as_millis() as i64;

        let res = sqlx::query(
            r#"INSERT INTO refresh_tokens (
                   user_id, token_hash, created_at_ms_utc, expires_at_ms_utc, rotated_from_id
               ) VALUES (?, ?, ?, ?, ?)"#,
        )
        .bind(user_id)
        .bind(token_hash)
        .bind(now_ms)
        .bind(expires_at_ms)
        .bind(rotated_from_id)
        .execute(&mut **tx)
        .await
        .context("insert refresh token")?;

        let sid = res.last_insert_rowid();
        Ok((sid, refresh_token))
    }
}

#[derive(Debug, Clone)]
pub struct AuthedUser {
    pub user_id: i64,
}

#[async_trait]
impl FromRequestParts<AppState> for AuthedUser {
    type Rejection = (StatusCode, Json<ErrorBody>);

    async fn from_request_parts(
        parts: &mut Parts,
        state: &AppState,
    ) -> Result<Self, Self::Rejection> {
        let remote_ip = parts
            .extensions
            .get::<ConnectInfo<SocketAddr>>()
            .map(|ci| ci.0.ip());
        state
            .auth
            .authenticate_request(&state.db, &state.limiter, &parts.headers, remote_ip)
            .await
    }
}

fn extract_bearer(headers: &HeaderMap) -> Option<String> {
    let auth = headers
        .get(header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("");
    let token = auth.strip_prefix("Bearer ").unwrap_or("").trim();
    if token.is_empty() {
        None
    } else {
        Some(token.to_string())
    }
}

fn hex_encode(bytes: &[u8]) -> String {
    const LUT: &[u8; 16] = b"0123456789abcdef";
    let mut out = String::with_capacity(bytes.len() * 2);
    for &b in bytes {
        out.push(LUT[(b >> 4) as usize] as char);
        out.push(LUT[(b & 0x0f) as usize] as char);
    }
    out
}

fn html_escape(input: &str) -> String {
    input
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&#x27;")
}

fn extract_json_string_field(val: &serde_json::Value, path: &str) -> anyhow::Result<String> {
    let mut cur = val;
    for key in path.split('.').filter(|s| !s.is_empty()) {
        cur = cur
            .get(key)
            .with_context(|| format!("missing key: {key}"))?;
    }
    match cur {
        serde_json::Value::String(s) if !s.is_empty() => Ok(s.clone()),
        serde_json::Value::Number(n) => Ok(n.to_string()),
        _ => anyhow::bail!("unsupported id field type"),
    }
}

fn load_oauth_providers_from_env() -> anyhow::Result<HashMap<String, OAuthProviderConfig>> {
    let raw = std::env::var("OAUTH_PROVIDERS_JSON").unwrap_or_else(|_| "[]".to_string());
    let trimmed = raw.trim();
    let json = trimmed
        .strip_prefix('\'')
        .and_then(|s| s.strip_suffix('\''))
        .or_else(|| trimmed.strip_prefix('"').and_then(|s| s.strip_suffix('"')))
        .unwrap_or(trimmed)
        .to_string();
    let list: Vec<OAuthProviderConfig> = match serde_json::from_str(&json) {
        Ok(v) => v,
        Err(e) => {
            // A very common mistake when configuring env vars via shell/systemd is
            // forgetting to quote the entire JSON value, which strips all inner
            // quotes and makes it invalid JSON (e.g. `[{name:linuxdo,...}]`).
            let looks_shell_unquoted = json.contains("name:")
                || json.contains("authorizeUrl:")
                || json.contains("tokenUrl:")
                || json.contains("userinfoUrl:")
                || json.contains("clientId:")
                || json.contains("clientSecret:");

            let hint = if looks_shell_unquoted {
                "parse OAUTH_PROVIDERS_JSON (hint: wrap the whole JSON in single quotes, e.g. OAUTH_PROVIDERS_JSON='[{\"name\":\"linuxdo\",...}]')"
            } else {
                "parse OAUTH_PROVIDERS_JSON"
            };

            return Err(anyhow::Error::new(e).context(hint));
        }
    };

    let mut map = HashMap::new();
    for p in list {
        let name = p.name.trim().to_lowercase();
        if name.is_empty() {
            continue;
        }
        map.insert(name, p);
    }
    Ok(map)
}

#[derive(Debug, Deserialize)]
struct StartQuery {
    provider: String,
    app_redirect: String,
    client: Option<String>,
}

async fn auth_start(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Query(q): Query<StartQuery>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    {
        let mut limiter = state.auth_limiter.lock().await;
        if !limiter.check(&format!("auth_start:{}", addr.ip())) {
            return Err(json_error(StatusCode::TOO_MANY_REQUESTS, "rate limited"));
        }
    }

    let provider = q.provider.to_lowercase();
    if !state.auth.config.providers.contains_key(&provider) {
        return Err(json_error(
            StatusCode::BAD_REQUEST,
            "provider not configured",
        ));
    }

    if !state.auth.config.enabled_providers.contains(&provider) {
        return Err(json_error(StatusCode::BAD_REQUEST, "provider not enabled"));
    }

    if !state.auth.is_allowed_app_redirect(&q.app_redirect) {
        return Err(json_error(
            StatusCode::BAD_REQUEST,
            "app_redirect not allowed",
        ));
    }

    let client = q.client.unwrap_or_else(|| "easy_todo".to_string());
    let state_token = state.auth.random_token_b64(24);
    let now_ms = now_ms_utc();
    let expires_at_ms = now_ms + state.auth.config.login_attempt_ttl.as_millis() as i64;

    sqlx::query(
        r#"INSERT INTO auth_login_attempts
           (state, provider, app_redirect, client, created_at_ms_utc, expires_at_ms_utc)
           VALUES (?, ?, ?, ?, ?, ?)"#,
    )
    .bind(&state_token)
    .bind(&provider)
    .bind(&q.app_redirect)
    .bind(&client)
    .bind(now_ms)
    .bind(expires_at_ms)
    .execute(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let url = state
        .auth
        .oauth_authorize_url(&provider, &state_token)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "oauth config error"))?;

    Ok(Redirect::temporary(&url))
}

#[derive(Debug, Deserialize)]
struct CallbackQuery {
    state: String,
    code: Option<String>,
    error: Option<String>,
    error_description: Option<String>,
}

async fn auth_callback(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Query(q): Query<CallbackQuery>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    {
        let mut limiter = state.auth_limiter.lock().await;
        if !limiter.check(&format!("auth_callback:{}", addr.ip())) {
            return Err(json_error(StatusCode::TOO_MANY_REQUESTS, "rate limited"));
        }
    }

    if let Some(err) = q.error {
        let desc = q
            .error_description
            .unwrap_or_else(|| "OAuth error".to_string());
        return Ok(state
            .auth
            .html_result_page("Login failed", &format!("{err}: {desc}"), None));
    }

    let Some(code) = q.code else {
        return Ok(state
            .auth
            .html_result_page("Login failed", "missing code", None));
    };

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let row = sqlx::query(
        r#"SELECT provider, app_redirect, expires_at_ms_utc
           FROM auth_login_attempts WHERE state = ?"#,
    )
    .bind(&q.state)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let Some(row) = row else {
        tx.rollback().await.ok();
        return Ok(state
            .auth
            .html_result_page("Login failed", "invalid or expired state", None));
    };

    let provider: String = row
        .try_get("provider")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let app_redirect: String = row
        .try_get("app_redirect")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let expires_at_ms_utc: i64 = row
        .try_get("expires_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let now_ms = now_ms_utc();
    if expires_at_ms_utc <= now_ms {
        sqlx::query(r#"DELETE FROM auth_login_attempts WHERE state = ?"#)
            .bind(&q.state)
            .execute(&mut *tx)
            .await
            .ok();
        tx.commit().await.ok();
        return Ok(state
            .auth
            .html_result_page("Login failed", "state expired", None));
    }

    // One-time state.
    sqlx::query(r#"DELETE FROM auth_login_attempts WHERE state = ?"#)
        .bind(&q.state)
        .execute(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let access_token = match state.auth.oauth_exchange_code(&provider, &code).await {
        Ok(t) => t,
        Err(_) => {
            return Ok(state.auth.html_result_page(
                "Login failed",
                "OAuth code exchange failed",
                None,
            ))
        }
    };

    let sub = match state
        .auth
        .oauth_fetch_subject(&provider, &access_token)
        .await
    {
        Ok(s) => s,
        Err(_) => {
            return Ok(state
                .auth
                .html_result_page("Login failed", "OAuth userinfo failed", None))
        }
    };

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let user_id = crate::ensure_user(&mut tx, &provider, &sub, now_ms)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let ticket = state.auth.random_token_b64(32);
    let ticket_hash = state.auth.hash_token(&ticket);
    let ticket_expires_at = now_ms + state.auth.config.ticket_ttl.as_millis() as i64;

    sqlx::query(
        r#"INSERT INTO auth_tickets
           (ticket_hash, user_id, created_at_ms_utc, expires_at_ms_utc, consumed_at_ms_utc)
           VALUES (?, ?, ?, ?, NULL)"#,
    )
    .bind(ticket_hash)
    .bind(user_id)
    .bind(now_ms)
    .bind(ticket_expires_at)
    .execute(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let return_url = state.auth.append_ticket(&app_redirect, &ticket);
    Ok(state.auth.html_result_page(
        "Login succeeded",
        "You can return to the app now.",
        Some(&return_url),
    ))
}

#[derive(Debug, Deserialize)]
struct ExchangeRequest {
    ticket: String,
}

#[derive(Debug, Serialize)]
struct TokenResponse {
    #[serde(rename = "accessToken")]
    access_token: String,
    #[serde(rename = "expiresIn")]
    expires_in: i64,
    #[serde(rename = "refreshToken")]
    refresh_token: String,
}

async fn auth_exchange(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<ExchangeRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    {
        let mut limiter = state.auth_limiter.lock().await;
        if !limiter.check(&format!("auth_exchange:{}", addr.ip())) {
            return Err(json_error(StatusCode::TOO_MANY_REQUESTS, "rate limited"));
        }
    }

    let now_ms = now_ms_utc();
    let ticket_hash = state.auth.hash_token(&req.ticket);

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let row = sqlx::query(
        r#"SELECT user_id, expires_at_ms_utc, consumed_at_ms_utc
           FROM auth_tickets WHERE ticket_hash = ?"#,
    )
    .bind(&ticket_hash)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let Some(row) = row else {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::UNAUTHORIZED, "invalid ticket"));
    };

    let user_id: i64 = row
        .try_get("user_id")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let expires_at_ms_utc: i64 = row
        .try_get("expires_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let consumed_at_ms_utc: Option<i64> = row
        .try_get("consumed_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    if consumed_at_ms_utc.is_some() || expires_at_ms_utc <= now_ms {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::UNAUTHORIZED, "ticket expired"));
    }

    let updated = sqlx::query(
        r#"UPDATE auth_tickets
           SET consumed_at_ms_utc = ?
           WHERE ticket_hash = ? AND consumed_at_ms_utc IS NULL"#,
    )
    .bind(now_ms)
    .bind(&ticket_hash)
    .execute(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    if updated.rows_affected() != 1 {
        tx.rollback().await.ok();
        return Err(json_error(
            StatusCode::UNAUTHORIZED,
            "ticket already consumed",
        ));
    }

    let (session_id, refresh_token) = state
        .auth
        .new_session(&mut tx, user_id, None, now_ms)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let (access_token, expires_in) = state
        .auth
        .sign_access_token(user_id, session_id)
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "token error"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    Ok(Json(TokenResponse {
        access_token,
        expires_in,
        refresh_token,
    }))
}

#[derive(Debug, Deserialize)]
struct RefreshRequest {
    #[serde(rename = "refreshToken")]
    refresh_token: String,
}

async fn auth_refresh(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<RefreshRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    {
        let mut limiter = state.auth_limiter.lock().await;
        if !limiter.check(&format!("auth_refresh:{}", addr.ip())) {
            return Err(json_error(StatusCode::TOO_MANY_REQUESTS, "rate limited"));
        }
    }

    let now_ms = now_ms_utc();
    let token_hash = state.auth.hash_token(&req.refresh_token);

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let row = sqlx::query(
        r#"SELECT id, user_id, expires_at_ms_utc, revoked_at_ms_utc
           FROM refresh_tokens WHERE token_hash = ?"#,
    )
    .bind(&token_hash)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let Some(row) = row else {
        tx.rollback().await.ok();
        return Err(json_error(
            StatusCode::UNAUTHORIZED,
            "invalid refresh token",
        ));
    };

    let old_id: i64 = row
        .try_get("id")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let user_id: i64 = row
        .try_get("user_id")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let expires_at_ms_utc: i64 = row
        .try_get("expires_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let revoked_at_ms_utc: Option<i64> = row
        .try_get("revoked_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    if revoked_at_ms_utc.is_some() || expires_at_ms_utc <= now_ms {
        tx.rollback().await.ok();
        return Err(json_error(
            StatusCode::UNAUTHORIZED,
            "refresh token expired",
        ));
    }

    // Rotation: revoke the old token and issue a new one.
    sqlx::query(
        r#"UPDATE refresh_tokens
           SET revoked_at_ms_utc = ?, last_used_at_ms_utc = ?
           WHERE id = ? AND revoked_at_ms_utc IS NULL"#,
    )
    .bind(now_ms)
    .bind(now_ms)
    .bind(old_id)
    .execute(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let (new_session_id, refresh_token) = state
        .auth
        .new_session(&mut tx, user_id, Some(old_id), now_ms)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let (access_token, expires_in) = state
        .auth
        .sign_access_token(user_id, new_session_id)
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "token error"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    Ok(Json(TokenResponse {
        access_token,
        expires_in,
        refresh_token,
    }))
}

#[derive(Debug, Deserialize)]
struct LogoutRequest {
    #[serde(rename = "refreshToken")]
    refresh_token: String,
}

#[derive(Debug, Serialize)]
struct OkResponse {
    ok: bool,
}

async fn auth_logout(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    Json(req): Json<LogoutRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    {
        let mut limiter = state.auth_limiter.lock().await;
        if !limiter.check(&format!("auth_logout:{}", addr.ip())) {
            return Err(json_error(StatusCode::TOO_MANY_REQUESTS, "rate limited"));
        }
    }

    let now_ms = now_ms_utc();
    let token_hash = state.auth.hash_token(&req.refresh_token);

    sqlx::query(
        r#"UPDATE refresh_tokens
           SET revoked_at_ms_utc = ?
           WHERE token_hash = ? AND revoked_at_ms_utc IS NULL"#,
    )
    .bind(now_ms)
    .bind(token_hash)
    .execute(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    Ok(Json(OkResponse { ok: true }))
}

#[derive(Debug, Serialize)]
struct ProviderItem {
    name: String,
}

#[derive(Debug, Serialize)]
struct ProvidersResponse {
    providers: Vec<ProviderItem>,
}

async fn auth_providers(
    State(state): State<AppState>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    let mut providers = state
        .auth
        .config
        .enabled_providers
        .iter()
        .filter(|p| state.auth.config.providers.contains_key(*p))
        .cloned()
        .collect::<Vec<_>>();
    providers.sort();
    providers.dedup();

    Ok(Json(ProvidersResponse {
        providers: providers
            .into_iter()
            .map(|name| ProviderItem { name })
            .collect(),
    }))
}

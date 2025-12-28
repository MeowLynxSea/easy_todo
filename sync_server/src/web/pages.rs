use std::net::SocketAddr;
use std::time::Duration;

use axum::extract::{ConnectInfo, OriginalUri, Query, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::{Html, IntoResponse, Redirect, Response};
use axum::Json;
use serde::Deserialize;
use sqlx::Row;

use crate::{json_error, now_ms_utc, AppState, ErrorBody};

use super::layout::{nav_bar, page_shell, stat_card, stat_card_ms, stat_card_ms_opt};
use super::session::{
    apply_set_cookie_headers, authenticate_web, clear_auth_cookies, cookie_value,
};
use super::util::{
    check_same_origin, format_bytes, format_number, format_uptime, h, provider_display_name,
    provider_icon_text, quota_summary, url_encode, validate_return_to,
};

const REFRESH_COOKIE: &str = "easy_todo_refresh";

#[derive(Debug, Deserialize)]
pub(super) struct LoginQuery {
    next: Option<String>,
}

pub(super) async fn home_page(
    State(state): State<AppState>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    let users_count: i64 = sqlx::query_scalar(r#"SELECT COUNT(*) FROM users"#)
        .fetch_one(&state.db)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let records_count: i64 = sqlx::query_scalar(r#"SELECT COUNT(*) FROM records"#)
        .fetch_one(&state.db)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let total_b64: i64 = sqlx::query_scalar(
        r#"SELECT IFNULL(SUM(LENGTH(nonce) + LENGTH(ciphertext)), 0) FROM records"#,
    )
    .fetch_one(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let service_duration = state
        .site_created_at_ms_utc
        .and_then(|created_ms| {
            let now_ms = now_ms_utc();
            if now_ms <= created_ms {
                return None;
            }
            let secs = ((now_ms - created_ms) / 1000).max(0) as u64;
            Some(Duration::from_secs(secs))
        })
        .unwrap_or_else(|| state.started_at.elapsed());

    let base_url = state.auth.config.base_url.trim_end_matches('/').to_string();
    let server_link = h(&base_url);

    let body = format!(
        r#"
<div class="min-h-screen bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-slate-50">
  {nav}
  <main class="mx-auto max-w-5xl px-4 pb-16 pt-10">
    <div class="space-y-2">
      <h1 class="text-3xl font-semibold tracking-tight">轻单 同步服务</h1>
      <p class="text-sm text-slate-600 dark:text-slate-300">Easy Todo Sync Service</p>
    </div>

    <div class="mt-8 grid gap-4 md:grid-cols-4">
      {stat_users}
      {stat_records}
      {stat_storage}
      {stat_uptime}
    </div>

    <div class="mt-10 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
      <h2 class="text-base font-semibold">使用教程</h2>
      <ol class="mt-3 list-decimal space-y-2 pl-5 text-sm text-slate-700 dark:text-slate-200">
        <li>复制下方的「服务器链接」</li>
        <li>打开应用 → 云同步 → 服务器配置</li>
        <li>粘贴并保存</li>
      </ol>

      <div class="mt-5">
        <div class="flex items-center justify-between gap-3">
          <div>
            <div class="text-xs font-medium text-slate-500 dark:text-slate-400">服务器链接</div>
            <div class="mt-1 font-mono text-sm">{server_link}</div>
          </div>
          <button id="copy-link" class="shrink-0 rounded-xl border border-slate-200 bg-slate-50 px-4 py-2 text-sm font-medium hover:bg-slate-100 dark:border-slate-800 dark:bg-slate-950 dark:hover:bg-slate-900">
            复制
          </button>
        </div>
        <p id="copy-hint" class="mt-2 hidden text-xs text-emerald-600 dark:text-emerald-400">已复制</p>
      </div>
    </div>

    <div class="mt-6 flex flex-wrap items-center justify-between gap-3">
      <div class="text-xs text-slate-500 dark:text-slate-400">
        API: <a class="underline decoration-slate-300 underline-offset-4 hover:text-slate-700 dark:decoration-slate-700 dark:hover:text-slate-200" href="/v1/health">/v1/health</a>
      </div>
      <a class="rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-100" href="/dashboard">
        进入仪表盘
      </a>
    </div>
  </main>
</div>
<script>
(() => {{
  const text = {server_link_js};
  const btn = document.getElementById('copy-link');
  const hint = document.getElementById('copy-hint');
  function showHint() {{
    hint.classList.remove('hidden');
    window.setTimeout(() => hint.classList.add('hidden'), 1200);
  }}
  btn?.addEventListener('click', async () => {{
    try {{
      await navigator.clipboard.writeText(text);
      showHint();
    }} catch {{
      const ta = document.createElement('textarea');
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      document.body.removeChild(ta);
      showHint();
    }}
  }});
}})();
</script>
"#,
        nav = nav_bar(None),
        stat_users = stat_card("注册用户", &format_number(users_count)),
        stat_records = stat_card("累计记录数", &format_number(records_count)),
        stat_storage = stat_card("累计用量", &format_bytes(total_b64)),
        stat_uptime = stat_card("已提供服务", &format_uptime(service_duration)),
        server_link = server_link,
        server_link_js = serde_json::to_string(&base_url).unwrap_or_else(|_| "\"\"".to_string()),
    );

    Ok(Html(page_shell("轻单 同步服务", &body)))
}

pub(super) async fn dashboard_login_page(
    State(state): State<AppState>,
    Query(q): Query<LoginQuery>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    let next = q
        .next
        .as_deref()
        .and_then(validate_return_to)
        .unwrap_or("/dashboard");

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

    let items = providers
        .into_iter()
        .map(|p| {
            let display = provider_display_name(&state, &p);
            let href = format!(
                "/v1/auth/web/start?provider={}&return_to={}",
                url_encode(&p),
                url_encode(next)
            );
            format!(
                r#"<a class="group flex items-center justify-between rounded-2xl border border-slate-200 bg-white px-5 py-4 shadow-sm transition hover:-translate-y-0.5 hover:shadow-md dark:border-slate-800 dark:bg-slate-900" href="{href}">
  <div class="flex items-center gap-3">
    <div class="flex h-10 w-10 items-center justify-center rounded-xl bg-slate-100 text-sm font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200">{icon}</div>
    <div>
      <div class="text-sm font-semibold">{display}</div>
      <div class="text-xs text-slate-500 dark:text-slate-400">OAuth 登录</div>
    </div>
  </div>
  <div class="text-slate-400 group-hover:text-slate-700 dark:group-hover:text-slate-200">→</div>
</a>"#,
                href = h(&href),
                display = h(&display),
                icon = h(&provider_icon_text(&display)),
            )
        })
        .collect::<Vec<_>>()
        .join("\n");

    let body = format!(
        r#"
<div class="min-h-screen bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-slate-50">
  {nav}
  <main class="mx-auto max-w-xl px-4 pb-16 pt-10">
    <div class="space-y-2">
      <h1 class="text-2xl font-semibold tracking-tight">登录仪表盘</h1>
      <p class="text-sm text-slate-600 dark:text-slate-300">请选择一个 Provider 继续</p>
    </div>

    <div class="mt-8 space-y-3">
      {items}
    </div>

    <p class="mt-8 text-xs text-slate-500 dark:text-slate-400">
      登录后仅用于查看你的同步用量与管理数据，不会跳转回客户端。
    </p>
  </main>
</div>
"#,
        nav = nav_bar(Some("登录")),
        items = items,
    );

    Ok(Html(page_shell("登录仪表盘", &body)))
}

pub(super) async fn dashboard_page(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    let auth = authenticate_web(&state, &headers, Some(addr.ip())).await;
    let (user_id, maybe_set_cookies) = match auth {
        Ok(v) => v,
        Err(_) => {
            return Ok(Redirect::temporary("/dashboard/login?next=/dashboard").into_response());
        }
    };

    let user_row =
        sqlx::query(r#"SELECT created_at_ms_utc, oauth_provider FROM users WHERE id = ?"#)
            .bind(user_id)
            .fetch_optional(&state.db)
            .await
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let Some(user_row) = user_row else {
        return Ok(Redirect::temporary("/dashboard/login?next=/dashboard").into_response());
    };

    let created_at_ms: i64 = user_row
        .try_get("created_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let oauth_provider: String = user_row
        .try_get("oauth_provider")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let oauth_provider_display = provider_display_name(&state, &oauth_provider);

    let total_records: i64 =
        sqlx::query_scalar(r#"SELECT COUNT(*) FROM records WHERE user_id = ?"#)
            .bind(user_id)
            .fetch_one(&state.db)
            .await
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let deleted_records: i64 = sqlx::query_scalar(
        r#"SELECT COUNT(*) FROM records WHERE user_id = ? AND deleted_at_ms_utc IS NOT NULL"#,
    )
    .bind(user_id)
    .fetch_one(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let total_b64: i64 = sqlx::query_scalar(
        r#"SELECT IFNULL(SUM(LENGTH(nonce) + LENGTH(ciphertext)), 0) FROM records WHERE user_id = ?"#,
    )
    .bind(user_id)
    .fetch_one(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let last_sync_at_ms: Option<i64> =
        sqlx::query_scalar(r#"SELECT MAX(updated_at_ms_utc) FROM records WHERE user_id = ?"#)
            .bind(user_id)
            .fetch_one(&state.db)
            .await
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let active_sessions: i64 = sqlx::query_scalar(
        r#"SELECT COUNT(*) FROM refresh_tokens
           WHERE user_id = ? AND revoked_at_ms_utc IS NULL AND expires_at_ms_utc > ?"#,
    )
    .bind(user_id)
    .bind(now_ms_utc())
    .fetch_one(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let quotas = quota_summary(&state);

    let body = format!(
        r#"
<div class="min-h-screen bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-slate-50">
  {nav}
  <main class="mx-auto max-w-5xl px-4 pb-16 pt-10">
    <div class="flex flex-wrap items-start justify-between gap-4">
      <div>
        <h1 class="text-2xl font-semibold tracking-tight">仪表盘</h1>
        <p class="mt-1 text-sm text-slate-600 dark:text-slate-300">管理你的同步数据与账户</p>
      </div>
      <form method="post" action="/dashboard/logout">
        <button class="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:hover:bg-slate-800" type="submit">
          退出登录
        </button>
      </form>
    </div>

    <div class="mt-8 grid gap-4 md:grid-cols-3">
      {stat_created}
      {stat_records}
      {stat_storage}
    </div>

    <div class="mt-4 grid gap-4 md:grid-cols-3">
      {stat_deleted}
      {stat_last_sync}
      {stat_sessions}
    </div>

    <div class="mt-10 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-900">
      <h2 class="text-base font-semibold">账户信息</h2>
      <dl class="mt-4 grid gap-3 text-sm md:grid-cols-2">
        <div class="rounded-xl bg-slate-50 p-4 dark:bg-slate-950">
          <dt class="text-xs font-medium text-slate-500 dark:text-slate-400">OAuth Provider</dt>
          <dd class="mt-1 font-mono">{provider}</dd>
        </div>
        <div class="rounded-xl bg-slate-50 p-4 dark:bg-slate-950">
          <dt class="text-xs font-medium text-slate-500 dark:text-slate-400">配额</dt>
          <dd class="mt-1">{quota}</dd>
        </div>
      </dl>
    </div>

    <div class="mt-6 rounded-2xl border border-rose-200 bg-rose-50 p-6 shadow-sm dark:border-rose-900/60 dark:bg-rose-950/40">
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div>
          <h2 class="text-base font-semibold text-rose-900 dark:text-rose-200">危险操作：清除数据</h2>
          <p class="mt-1 text-sm text-rose-800/90 dark:text-rose-200/80">
            将清除与你账号关联的所有数据，并删除数据库中的账户。此操作不可撤销。
          </p>
        </div>
        <button id="open-delete" class="rounded-xl bg-rose-600 px-4 py-2 text-sm font-semibold text-white hover:bg-rose-500" type="button">
          清除数据
        </button>
      </div>
    </div>
  </main>
</div>

<div id="delete-modal" class="fixed inset-0 hidden items-center justify-center bg-black/50 p-4">
  <div class="w-full max-w-lg rounded-2xl border border-slate-200 bg-white p-6 shadow-xl dark:border-slate-800 dark:bg-slate-900">
    <h3 class="text-lg font-semibold">二次确认</h3>
    <p class="mt-2 text-sm text-slate-600 dark:text-slate-300">
      请输入 <span class="font-mono font-semibold">DELETE</span> 以确认删除。
    </p>
    <input id="delete-input" class="mt-4 w-full rounded-xl border border-slate-200 bg-white px-4 py-3 font-mono text-sm text-slate-900 placeholder:text-slate-400 outline-none focus:ring-2 focus:ring-rose-500 dark:border-slate-800 dark:bg-slate-950 dark:text-slate-50 dark:placeholder:text-slate-500" placeholder="DELETE" />
    <div class="mt-5 flex items-center justify-end gap-3">
      <button id="cancel-delete" class="rounded-xl border border-slate-200 bg-white px-4 py-2 text-sm font-semibold hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:hover:bg-slate-800" type="button">取消</button>
      <button id="confirm-delete" class="rounded-xl bg-rose-600 px-4 py-2 text-sm font-semibold text-white opacity-50" type="button" disabled>确认删除</button>
    </div>
    <p id="delete-error" class="mt-3 hidden text-sm text-rose-600 dark:text-rose-400"></p>
  </div>
</div>

<script>
(() => {{
  const modal = document.getElementById('delete-modal');
  const openBtn = document.getElementById('open-delete');
  const cancelBtn = document.getElementById('cancel-delete');
  const input = document.getElementById('delete-input');
  const confirmBtn = document.getElementById('confirm-delete');
  const err = document.getElementById('delete-error');

  function open() {{
    err.classList.add('hidden');
    err.textContent = '';
    input.value = '';
    confirmBtn.disabled = true;
    confirmBtn.classList.add('opacity-50');
    modal.classList.remove('hidden');
    modal.classList.add('flex');
    input.focus();
  }}

  function close() {{
    modal.classList.add('hidden');
    modal.classList.remove('flex');
  }}

  openBtn?.addEventListener('click', open);
  cancelBtn?.addEventListener('click', close);
  modal?.addEventListener('click', (e) => {{
    if (e.target === modal) close();
  }});

  input?.addEventListener('input', () => {{
    const ok = (input.value || '').trim().toUpperCase() === 'DELETE';
    confirmBtn.disabled = !ok;
    confirmBtn.classList.toggle('opacity-50', !ok);
  }});

  confirmBtn?.addEventListener('click', async () => {{
    confirmBtn.disabled = true;
    confirmBtn.classList.add('opacity-50');
    err.classList.add('hidden');
    err.textContent = '';
    try {{
      const resp = await fetch('/web/api/me/delete', {{
        method: 'POST',
        headers: {{ 'Content-Type': 'application/json' }},
        credentials: 'same-origin',
        body: JSON.stringify({{ confirm: 'DELETE' }}),
      }});
      if (!resp.ok) {{
        const data = await resp.json().catch(() => ({{}}));
        throw new Error(data.error || 'delete failed');
      }}
      window.location.href = '/';
    }} catch (e) {{
      err.textContent = e?.message || 'delete failed';
      err.classList.remove('hidden');
      confirmBtn.disabled = false;
      confirmBtn.classList.remove('opacity-50');
    }}
  }});
}})();
</script>

<script>
(() => {{
  function fmt(id) {{
    const el = document.getElementById(id);
    if (!el) return;
    const ms = Number(el.dataset.ms || '0');
    if (!ms) return;
    try {{
      el.textContent = new Date(ms).toLocaleString();
    }} catch {{}}
  }}
  fmt('created-at');
  fmt('last-sync');
}})();
</script>
"#,
        nav = nav_bar(Some("仪表盘")),
        stat_created = stat_card_ms("注册时间", created_at_ms, "created-at"),
        stat_records = stat_card("记录数", &format_number(total_records)),
        stat_storage = stat_card("用量（nonce+ciphertext）", &format_bytes(total_b64)),
        stat_deleted = stat_card("已删除标记", &format_number(deleted_records)),
        stat_last_sync = stat_card_ms_opt("最近同步", last_sync_at_ms, "last-sync"),
        stat_sessions = stat_card("活跃会话", &format_number(active_sessions)),
        provider = h(&oauth_provider_display),
        quota = h(&quotas),
    );

    let mut resp = Html(page_shell("仪表盘", &body)).into_response();
    if let Some(headers) = maybe_set_cookies {
        apply_set_cookie_headers(resp.headers_mut(), headers);
    }
    Ok(resp)
}

pub(super) async fn dashboard_logout(
    State(state): State<AppState>,
    ConnectInfo(addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !check_same_origin(&state, &headers) {
        return Err(json_error(StatusCode::FORBIDDEN, "forbidden"));
    }

    let refresh = cookie_value(&headers, REFRESH_COOKIE);
    if let Some(refresh) = refresh {
        let now_ms = now_ms_utc();
        state
            .auth
            .revoke_refresh_token(&state.db, &refresh, now_ms)
            .await
            .ok();
        {
            let mut limiter = state.auth_limiter.lock().await;
            limiter.check(&format!("web_logout:{}", addr.ip()));
        }
    }

    let mut resp = super::layout::see_other("/");
    apply_set_cookie_headers(resp.headers_mut(), clear_auth_cookies(&state));
    Ok(resp)
}

pub(super) async fn fallback_page(
    OriginalUri(uri): OriginalUri,
    _headers: HeaderMap,
) -> impl IntoResponse {
    let path = uri.path();
    if path.starts_with("/v1/") || path.starts_with("/web/api/") {
        return (
            StatusCode::NOT_FOUND,
            Json(ErrorBody {
                error: "not found".to_string(),
            }),
        )
            .into_response();
    }

    let body = format!(
        r#"
<div class="min-h-screen bg-slate-50 text-slate-900 dark:bg-slate-950 dark:text-slate-50">
  {nav}
  <main class="mx-auto max-w-xl px-4 pb-16 pt-20 text-center">
    <h1 class="text-2xl font-semibold">页面不存在</h1>
    <p class="mt-2 text-sm text-slate-600 dark:text-slate-300">Not Found</p>
    <div class="mt-6">
      <a class="rounded-xl bg-slate-900 px-4 py-2 text-sm font-semibold text-white hover:bg-slate-800 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-100" href="/">
        返回主页
      </a>
    </div>
  </main>
</div>
"#,
        nav = nav_bar(Some("404")),
    );
    (StatusCode::NOT_FOUND, Html(page_shell("Not Found", &body))).into_response()
}

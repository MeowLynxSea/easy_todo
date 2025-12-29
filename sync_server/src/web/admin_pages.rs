use std::net::SocketAddr;
use std::time::Duration;

use axum::extract::{ConnectInfo, Query, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::{Html, IntoResponse, Redirect, Response};
use axum::routing::{get, post};
use axum::{Form, Json, Router};
use serde::Deserialize;
use sqlx::Row;

use crate::{json_error, now_ms_utc, AppState, ErrorBody};

use super::admin_api;
use super::admin_session::{authenticate_admin, build_admin_login_cookie, clear_admin_cookies};
use super::layout::{page_shell, stat_card};
use super::session::apply_set_cookie_headers;
use super::util::{
    check_same_origin, format_bytes, format_number, format_uptime, h, url_encode,
    validate_return_to,
};

#[derive(Debug, Deserialize)]
pub(super) struct AdminLoginQuery {
    next: Option<String>,
    error: Option<String>,
}

#[derive(Debug, Deserialize)]
pub(super) struct AdminLoginForm {
    username: String,
    password: String,
    next: Option<String>,
}

pub(super) fn admin_router(admin_entry_path: &str) -> Router<AppState> {
    let base = admin_entry_path.trim_end_matches('/').to_string();
    let login = format!("{base}/login");
    let logout = format!("{base}/logout");

    Router::new()
        .route(&base, get(admin_dashboard_page))
        .route(&login, get(admin_login_page).post(admin_login))
        .route(&logout, post(admin_logout))
        .route(
            &format!("{base}/api/cdkeys/generate"),
            post(admin_api::admin_generate_cdkeys),
        )
        .route(
            &format!("{base}/api/cdkeys/delete"),
            post(admin_api::admin_delete_cdkeys),
        )
        .route(
            &format!("{base}/api/users/:id"),
            get(admin_api::admin_get_user),
        )
        .route(
            &format!("{base}/api/users/update"),
            post(admin_api::admin_update_user),
        )
}

fn admin_nav(base: &str) -> String {
    let logout_action = format!("{base}/logout");
    format!(
        r#"<header class="nav-shell sticky top-0 z-50">
  <div class="mx-auto flex max-w-6xl items-center justify-between gap-3 px-4 py-4">
    <div class="flex min-w-0 items-center gap-3">
      <a href="/" class="nav-brand flex min-w-0 items-center gap-3 text-sm font-semibold tracking-tight">
        <span class="icon-chip" aria-hidden="true">⎈</span>
        <span class="truncate">轻单 同步服务</span>
      </a>
      <span class="badge hidden sm:inline-flex">管理员后台</span>
    </div>
    <div class="flex flex-wrap items-center justify-end gap-2">
      <div class="hidden md:flex items-center gap-2">
        <a class="btn btn-secondary" href="/dashboard">用户仪表盘</a>
        <form method="post" action="{logout_action}">
          <button class="btn btn-secondary" type="submit">退出</button>
        </form>
      </div>
      <button class="btn btn-ghost btn-icon" type="button" aria-label="切换明暗主题" data-theme-toggle>
        <svg class="icon theme-icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M21 12.79A9 9 0 1 1 11.21 3a7 7 0 0 0 9.79 9.79z"></path>
        </svg>
        <svg class="icon theme-icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <circle cx="12" cy="12" r="4"></circle>
          <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"></path>
        </svg>
      </button>
      <button class="btn btn-secondary btn-icon mobile-menu-btn md:hidden" type="button" aria-label="打开菜单" aria-controls="admin-mobile-menu" aria-expanded="false" data-mobile-menu-btn data-open="0">
        <svg class="icon icon-menu" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M4 6h16M4 12h16M4 18h16"></path>
        </svg>
        <svg class="icon icon-close" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
          <path d="M18 6L6 18M6 6l12 12"></path>
        </svg>
      </button>
    </div>
  </div>
</header>

<div id="admin-mobile-menu" class="mobile-menu-overlay fixed inset-0 z-[60] md:hidden" data-open="0" aria-hidden="true">
  <div class="mobile-menu-backdrop absolute inset-0 bg-black/60 backdrop-blur-xl" data-mobile-menu-close></div>
  <div class="relative mx-auto max-w-6xl px-4 pt-20">
    <div class="card card-static mobile-menu-panel mobile-menu-inner p-4" role="dialog" aria-modal="true" aria-label="管理员菜单">
      <div class="flex items-center justify-between gap-3">
        <div class="text-xs font-mono tracking-widest subtle">ADMIN</div>
        <button class="btn btn-ghost btn-icon" type="button" aria-label="关闭菜单" data-mobile-menu-close>
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M18 6L6 18M6 6l12 12"></path>
          </svg>
        </button>
      </div>

      <div class="mt-4 grid gap-2">
        <a class="btn btn-primary w-full" href="/dashboard" data-mobile-menu-link>用户仪表盘</a>
        <a class="btn btn-secondary w-full" href="/" data-mobile-menu-link>返回主页</a>
        <form method="post" action="{logout_action}">
          <button class="btn btn-secondary w-full" type="submit">退出</button>
        </form>
      </div>

      <div class="mt-4 flex items-center justify-between gap-3">
        <div class="text-xs subtle">Theme</div>
        <button class="btn btn-secondary btn-icon" type="button" aria-label="切换明暗主题" data-theme-toggle>
          <svg class="icon theme-icon-moon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M21 12.79A9 9 0 1 1 11.21 3a7 7 0 0 0 9.79 9.79z"></path>
          </svg>
          <svg class="icon theme-icon-sun" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="4"></circle>
            <path d="M12 2v2M12 20v2M4.93 4.93l1.41 1.41M17.66 17.66l1.41 1.41M2 12h2M20 12h2M4.93 19.07l1.41-1.41M17.66 6.34l1.41-1.41"></path>
          </svg>
        </button>
      </div>
    </div>
  </div>
</div>"#,
        logout_action = h(&logout_action)
    )
}

pub(super) async fn admin_login_page(
    State(state): State<AppState>,
    Query(q): Query<AdminLoginQuery>,
    headers: HeaderMap,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !state.admin.enabled() {
        return Err(json_error(StatusCode::NOT_FOUND, "not found"));
    }

    if authenticate_admin(&state, &headers).is_ok() {
        let next = q
            .next
            .as_deref()
            .and_then(validate_return_to)
            .unwrap_or(&state.admin.entry_path);
        return Ok(Redirect::temporary(next).into_response());
    }

    let next = q
        .next
        .as_deref()
        .and_then(validate_return_to)
        .unwrap_or(&state.admin.entry_path);
    let show_error = q.error.as_deref().unwrap_or("").trim() == "1";

    let base = state.admin.entry_path.trim_end_matches('/').to_string();
    let action = format!("{base}/login");

    let body = format!(
        r#"
{nav}
<main class="mx-auto max-w-md px-4 pb-20 pt-14">
  <div class="space-y-3">
    <h1 class="text-3xl font-semibold tracking-tight heading-grad">管理员登录</h1>
    <p class="text-sm muted">请输入管理员账户与密码</p>
  </div>

  <form class="card mt-8 space-y-4 p-6" data-spotlight method="post" action="{action}">
    <input type="hidden" name="next" value="{next}" />
    <p class="rounded-xl border border-rose-500/20 bg-rose-500/5 px-4 py-3 text-sm text-rose-800 dark:text-rose-200 {err_hide}">
      账户或密码错误
    </p>
    <label class="block">
      <span class="text-xs font-medium subtle">账户</span>
      <input name="username" class="input mt-2 text-sm" />
    </label>
    <label class="block">
      <span class="text-xs font-medium subtle">密码</span>
      <input name="password" type="password" class="input mt-2 text-sm" />
    </label>
    <button class="btn btn-primary h-11 w-full" type="submit">登录</button>
  </form>
</main>
"#,
        nav = admin_nav(&base),
        action = h(&action),
        next = h(next),
        err_hide = if show_error { "" } else { "hidden" },
    );

    Ok(Html(page_shell("管理员登录", &body)).into_response())
}

pub(super) async fn admin_login(
    State(state): State<AppState>,
    headers: HeaderMap,
    Form(form): Form<AdminLoginForm>,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !state.admin.enabled() {
        return Err(json_error(StatusCode::NOT_FOUND, "not found"));
    }
    if !check_same_origin(&state, &headers) {
        return Err(json_error(StatusCode::FORBIDDEN, "forbidden"));
    }

    let username_ok = state
        .admin
        .username
        .as_deref()
        .map(|u| u == form.username.trim())
        .unwrap_or(false);
    let password_ok = state
        .admin
        .password
        .as_deref()
        .map(|p| p == form.password)
        .unwrap_or(false);
    if !username_ok || !password_ok {
        let next = form
            .next
            .as_deref()
            .and_then(validate_return_to)
            .unwrap_or(&state.admin.entry_path);
        let location = format!(
            "{}/login?next={}&error=1",
            state.admin.entry_path,
            url_encode(next)
        );
        return Ok(Redirect::temporary(&location).into_response());
    }

    let next = form
        .next
        .as_deref()
        .and_then(validate_return_to)
        .unwrap_or(&state.admin.entry_path)
        .to_string();

    let mut resp = super::layout::see_other(&next);
    let cookies = build_admin_login_cookie(&state)?;
    apply_set_cookie_headers(resp.headers_mut(), cookies);
    Ok(resp)
}

pub(super) async fn admin_logout(
    State(state): State<AppState>,
    headers: HeaderMap,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !state.admin.enabled() {
        return Err(json_error(StatusCode::NOT_FOUND, "not found"));
    }
    if !check_same_origin(&state, &headers) {
        return Err(json_error(StatusCode::FORBIDDEN, "forbidden"));
    }

    let mut resp = super::layout::see_other("/");
    apply_set_cookie_headers(resp.headers_mut(), clear_admin_cookies(&state));
    Ok(resp)
}

pub(super) async fn admin_dashboard_page(
    State(state): State<AppState>,
    ConnectInfo(_addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !state.admin.enabled() {
        return Err(json_error(StatusCode::NOT_FOUND, "not found"));
    }

    if authenticate_admin(&state, &headers).is_err() {
        let login = format!(
            "{}/login?next={}",
            state.admin.entry_path,
            url_encode(&state.admin.entry_path)
        );
        return Ok(Redirect::temporary(&login).into_response());
    }

    let now_ms = now_ms_utc();
    sqlx::query(
        r#"UPDATE users
           SET subscription_plan_id = NULL,
               subscription_expires_at_ms_utc = NULL
           WHERE subscription_plan_id IS NOT NULL
             AND TRIM(subscription_plan_id) != ''
             AND (subscription_expires_at_ms_utc IS NULL OR subscription_expires_at_ms_utc <= ?)"#,
    )
    .bind(now_ms)
    .execute(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let users_count: i64 = sqlx::query_scalar(r#"SELECT COUNT(*) FROM users"#)
        .fetch_one(&state.db)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let cdkeys_count: i64 = sqlx::query_scalar(r#"SELECT COUNT(*) FROM cdkeys"#)
        .fetch_one(&state.db)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let total_b64: i64 = sqlx::query_scalar(
        r#"SELECT IFNULL(SUM(LENGTH(nonce) + LENGTH(ciphertext)), 0) FROM records"#,
    )
    .fetch_one(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let rows = sqlx::query(
        r#"SELECT
             id,
             oauth_provider,
             created_at_ms_utc,
             banned_at_ms_utc,
             stored_b64,
             api_outbound_bytes,
             subscription_plan_id,
             subscription_expires_at_ms_utc
           FROM users
           ORDER BY id DESC
           LIMIT 50"#,
    )
    .fetch_all(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let mut user_rows = String::new();
    for row in rows {
        let id: i64 = row.try_get("id").unwrap_or(0);
        let provider: String = row.try_get("oauth_provider").unwrap_or_default();
        let created_at: i64 = row.try_get("created_at_ms_utc").unwrap_or(0);
        let banned_at: Option<i64> = row.try_get("banned_at_ms_utc").unwrap_or(None);
        let stored_b64: i64 = row.try_get("stored_b64").unwrap_or(0);
        let outbound: i64 = row.try_get("api_outbound_bytes").unwrap_or(0);
        let sub_plan: Option<String> = row.try_get("subscription_plan_id").unwrap_or(None);
        let sub_exp: Option<i64> = row
            .try_get("subscription_expires_at_ms_utc")
            .unwrap_or(None);

        let sub = sub_plan.as_deref().unwrap_or("—").trim().to_string();
        let sub = if sub.is_empty() {
            "—".to_string()
        } else {
            sub
        };
        let status = if banned_at.is_some_and(|ms| ms > 0) {
            "封禁"
        } else {
            "正常"
        };

        user_rows.push_str(&format!(
            r#"<tr class="table-row">
  <td class="px-3 py-2 font-mono text-xs">{id}</td>
  <td class="px-3 py-2 text-xs">{provider}</td>
  <td class="px-3 py-2 text-xs font-mono" data-ms="{created_at}">—</td>
  <td class="px-3 py-2 text-xs">{status}</td>
  <td class="px-3 py-2 text-xs">{stored}</td>
  <td class="px-3 py-2 text-xs">{out}</td>
  <td class="px-3 py-2 text-xs font-mono">{sub}</td>
  <td class="px-3 py-2 text-xs font-mono" data-ms="{sub_exp}">—</td>
</tr>"#,
            id = id,
            provider = h(&provider),
            created_at = created_at,
            status = h(status),
            stored = h(&format_bytes(stored_b64)),
            out = h(&format_bytes(outbound)),
            sub = h(&sub),
            sub_exp = sub_exp.unwrap_or(0),
        ));
    }

    let base = state.admin.entry_path.trim_end_matches('/').to_string();
    let base_js = serde_json::to_string(&base).unwrap_or_else(|_| "\"\"".to_string());

    let plans = {
        let mut keys = state.billing.plans.keys().cloned().collect::<Vec<_>>();
        keys.sort();
        keys.into_iter()
            .map(|id| {
                let name = state
                    .billing
                    .plans
                    .get(&id)
                    .map(|p| p.name.clone())
                    .unwrap_or_default();
                format!(
                    r#"<option value="{id}">{id} · {name}</option>"#,
                    id = h(&id),
                    name = h(&name)
                )
            })
            .collect::<Vec<_>>()
            .join("\n")
    };

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

    let body = format!(
        r#"
{nav}
<main class="mx-auto max-w-6xl px-4 pb-20 pt-14">
  <div class="space-y-3">
    <h1 class="text-3xl font-semibold tracking-tight heading-grad">管理员后台</h1>
    <p class="text-sm muted">CDKEY、订阅与用户配额管理</p>
  </div>

  <div class="mt-10 grid gap-4 md:grid-cols-4">
    {stat_users}
    {stat_cdkeys}
    {stat_storage}
    {stat_uptime}
  </div>

  <div class="mt-10 grid gap-6 lg:grid-cols-2">
    <div class="card p-6" data-spotlight>
      <h2 class="text-base font-semibold">批量生成 CDKEY</h2>
      <div class="mt-4 grid gap-3 sm:grid-cols-2">
        <label class="block">
          <span class="text-xs font-medium subtle">订阅方案</span>
          <select id="plan-generate" class="input mt-2 text-sm">
            {plans}
          </select>
        </label>
        <label class="block">
          <span class="text-xs font-medium subtle">数量</span>
          <input id="count-generate" type="number" value="10" min="1" max="2000" class="input mt-2 text-sm" />
        </label>
      </div>
      <button id="btn-generate" class="btn btn-primary mt-4 w-full sm:w-auto" type="button">生成</button>
      <p id="gen-error" class="mt-3 hidden text-sm text-rose-600 dark:text-rose-400"></p>
      <textarea id="gen-output" class="codeblock mt-4 hidden h-40 w-full font-mono text-xs" spellcheck="false"></textarea>
    </div>

    <div class="card p-6" data-spotlight>
      <h2 class="text-base font-semibold">批量删除 CDKEY</h2>
      <div class="mt-4 grid gap-3 sm:grid-cols-2">
        <label class="block">
          <span class="text-xs font-medium subtle">订阅方案</span>
          <select id="plan-delete" class="input mt-2 text-sm">
            {plans}
          </select>
        </label>
        <div class="flex items-end">
          <button id="btn-delete" class="btn btn-secondary h-11 w-full" type="button">
            删除该方案全部未激活 CDKEY
          </button>
        </div>
      </div>
      <p id="del-hint" class="mt-3 hidden text-sm text-emerald-700 dark:text-emerald-300"></p>
      <p id="del-error" class="mt-3 hidden text-sm text-rose-600 dark:text-rose-400"></p>
    </div>
  </div>

  <div class="mt-6 card p-6" data-spotlight>
    <h2 class="text-base font-semibold">用户管理</h2>
    <div class="mt-4 grid gap-3 sm:grid-cols-3">
      <label class="block sm:col-span-1">
        <span class="text-xs font-medium subtle">用户ID</span>
        <input id="user-id" type="number" min="1" class="input mt-2 text-sm" />
      </label>
      <div class="flex items-end sm:col-span-1">
        <button id="btn-load-user" class="btn btn-secondary h-11 w-full" type="button">加载用户</button>
      </div>
      <div class="flex items-end sm:col-span-1">
        <button id="btn-update-user" class="btn btn-primary h-11 w-full" type="button" disabled>
          保存修改
        </button>
      </div>
    </div>

    <div id="user-form" class="mt-5 hidden grid gap-3 md:grid-cols-2">
      <label class="block">
        <span class="text-xs font-medium subtle">基础存储配额（留空=使用默认）</span>
        <div class="mt-2 flex gap-2">
          <input id="base-storage" type="number" min="0" step="any" class="input w-full flex-1 text-sm" />
          <select id="base-storage-unit" class="input w-28 text-sm">
            <option value="GB">GB</option>
            <option value="MB">MB</option>
            <option value="KB">KB</option>
            <option value="B">B</option>
          </select>
        </div>
      </label>
      <label class="block">
        <span class="text-xs font-medium subtle">基础出站配额（留空=使用默认）</span>
        <div class="mt-2 flex gap-2">
          <input id="base-outbound" type="number" min="0" step="any" class="input w-full flex-1 text-sm" />
          <select id="base-outbound-unit" class="input w-28 text-sm">
            <option value="GB">GB</option>
            <option value="MB">MB</option>
            <option value="KB">KB</option>
            <option value="B">B</option>
          </select>
        </div>
      </label>
      <label class="block">
        <span class="text-xs font-medium subtle">订阅方案（留空=无订阅）</span>
        <input id="sub-plan" class="input mt-2 font-mono text-sm" />
      </label>
      <label class="block">
        <span class="text-xs font-medium subtle">订阅到期时间</span>
        <input id="sub-expires" type="datetime-local" class="input mt-2 text-sm" />
      </label>
      <label class="flex items-center gap-2 pt-2">
        <input id="banned" type="checkbox" class="h-4 w-4 rounded border-black/20 dark:border-white/20 accent-[color:var(--accent)]" />
        <span class="text-sm">封禁该用户</span>
      </label>
    </div>

    <p id="user-hint" class="mt-4 hidden text-sm text-emerald-700 dark:text-emerald-300"></p>
    <p id="user-error" class="mt-4 hidden text-sm text-rose-600 dark:text-rose-400"></p>
    <pre id="user-raw" class="codeblock mt-4 hidden overflow-x-auto text-xs"></pre>
  </div>

  <div class="mt-6 card p-6" data-spotlight>
    <h2 class="text-base font-semibold">最近用户（最多 50）</h2>
    <div class="table-wrap mt-4 overflow-x-auto">
      <table class="table w-full text-left text-xs">
        <thead class="subtle">
          <tr>
            <th class="px-3 py-2">ID</th>
            <th class="px-3 py-2">Provider</th>
            <th class="px-3 py-2">注册</th>
            <th class="px-3 py-2">状态</th>
            <th class="px-3 py-2">存储</th>
            <th class="px-3 py-2">出站</th>
            <th class="px-3 py-2">订阅</th>
            <th class="px-3 py-2">到期时间</th>
          </tr>
        </thead>
        <tbody>
          {user_rows}
        </tbody>
      </table>
    </div>
  </div>
</main>

<script>
(() => {{
  const base = {base_js};
  const statCdkeys = document.getElementById('stat-cdkeys');
  let cdkeysCount = Number(statCdkeys?.dataset.count || '0');
  const selGen = document.getElementById('plan-generate');
  const inputCount = document.getElementById('count-generate');
  const btnGen = document.getElementById('btn-generate');
  const out = document.getElementById('gen-output');
  const err = document.getElementById('gen-error');

  const selDel = document.getElementById('plan-delete');
  const btnDel = document.getElementById('btn-delete');
  const delHint = document.getElementById('del-hint');
  const delErr = document.getElementById('del-error');

  const userId = document.getElementById('user-id');
  const btnLoad = document.getElementById('btn-load-user');
  const btnUpdate = document.getElementById('btn-update-user');
  const userForm = document.getElementById('user-form');
  const baseStorage = document.getElementById('base-storage');
  const baseStorageUnit = document.getElementById('base-storage-unit');
  const baseOutbound = document.getElementById('base-outbound');
  const baseOutboundUnit = document.getElementById('base-outbound-unit');
  const subPlan = document.getElementById('sub-plan');
  const subExpires = document.getElementById('sub-expires');
  const banned = document.getElementById('banned');
  const userHint = document.getElementById('user-hint');
  const userErr = document.getElementById('user-error');
  const userRaw = document.getElementById('user-raw');

  function show(el, on) {{
    el?.classList.toggle('hidden', !on);
  }}

  function renderCdkeysCount() {{
    if (!statCdkeys) return;
    cdkeysCount = Math.max(0, cdkeysCount);
    statCdkeys.dataset.count = String(cdkeysCount);
    try {{
      statCdkeys.textContent = cdkeysCount.toLocaleString();
    }} catch {{
      statCdkeys.textContent = String(cdkeysCount);
    }}
  }}

  function pad2(n) {{
    return String(n).padStart(2, '0');
  }}

  const STORAGE_UNITS = {{
    B: 1,
    KB: 1024,
    MB: 1024 * 1024,
    GB: 1024 * 1024 * 1024,
  }};
  const STORAGE_UNIT_ORDER = ['GB', 'MB', 'KB', 'B'];
  const STORAGE_SCALE = 10000n;

  function fmtScaledValue(scaled) {{
    const intPart = scaled / STORAGE_SCALE;
    const frac = scaled % STORAGE_SCALE;
    if (frac === 0n) return intPart.toString();
    const fracStr = frac
      .toString()
      .padStart(4, '0')
      .replace(/0+$/, '');
    return `${{intPart.toString()}}.${{fracStr}}`;
  }}

  function setBytesInput(bytes, inputEl, unitEl) {{
    if (!inputEl || !unitEl) return;
    if (bytes === null || bytes === undefined) {{
      inputEl.value = '';
      unitEl.value = 'GB';
      return;
    }}
    const b = Number(bytes);
    if (!Number.isFinite(b) || b < 0) {{
      inputEl.value = '';
      unitEl.value = 'GB';
      return;
    }}
    try {{
      const bi = BigInt(Math.trunc(b));
      if (bi === 0n) {{
        unitEl.value = 'B';
        inputEl.value = '0';
        return;
      }}
      const scaled = bi * STORAGE_SCALE;
      let unit = 'B';
      let value = bi.toString();
      for (const u of STORAGE_UNIT_ORDER) {{
        const factor = BigInt(STORAGE_UNITS[u] || 1);
        if (scaled % factor !== 0n) continue;
        unit = u;
        value = fmtScaledValue(scaled / factor);
        break;
      }}
      unitEl.value = unit;
      inputEl.value = value;
    }} catch {{
      unitEl.value = 'B';
      inputEl.value = String(Math.trunc(b));
    }}
  }}

  function getBytesInput(inputEl, unitEl) {{
    if (!inputEl) return null;
    const raw = String(inputEl.value || '').trim();
    if (!raw) return null;
    const n = Number(raw);
    if (!Number.isFinite(n) || n < 0) return null;
    const unit = unitEl?.value || 'B';
    const factor = STORAGE_UNITS[unit] || 1;
    const bytes = Math.round(n * factor);
    return Number.isFinite(bytes) && bytes >= 0 ? bytes : null;
  }}

  function setBaseStorageB64(bytes) {{
    setBytesInput(bytes, baseStorage, baseStorageUnit);
  }}

  function getBaseStorageB64() {{
    return getBytesInput(baseStorage, baseStorageUnit);
  }}

  function setBaseOutboundBytes(bytes) {{
    setBytesInput(bytes, baseOutbound, baseOutboundUnit);
  }}

  function getBaseOutboundBytes() {{
    return getBytesInput(baseOutbound, baseOutboundUnit);
  }}

  function msToLocalInputValue(ms) {{
    const v = Number(ms || 0);
    if (!v) return '';
    const d = new Date(v);
    if (!Number.isFinite(d.getTime())) return '';
    return `${{d.getFullYear()}}-${{pad2(d.getMonth() + 1)}}-${{pad2(d.getDate())}}T${{pad2(d.getHours())}}:${{pad2(d.getMinutes())}}`;
  }}

  function localInputValueToMs(value) {{
    const s = String(value || '').trim();
    if (!s) return null;
    const m = s.match(/^(\d{{4}})-(\d{{2}})-(\d{{2}})T(\d{{2}}):(\d{{2}})/);
    if (!m) return null;
    const y = Number(m[1]);
    const mo = Number(m[2]) - 1;
    const da = Number(m[3]);
    const h = Number(m[4]);
    const mi = Number(m[5]);
    const d = new Date(y, mo, da, h, mi, 0, 0);
    const ms = d.getTime();
    return Number.isFinite(ms) ? ms : null;
  }}

  async function postJson(path, payload) {{
    const resp = await fetch(path, {{
      method: 'POST',
      headers: {{ 'Content-Type': 'application/json' }},
      credentials: 'same-origin',
      body: JSON.stringify(payload),
    }});
    const data = await resp.json().catch(() => ({{}}));
    if (!resp.ok) {{
      throw new Error(data.error || 'request failed');
    }}
    return data;
  }}

  btnGen?.addEventListener('click', async () => {{
    show(err, false);
    show(out, false);
    out.value = '';
    try {{
      const count = Number(inputCount?.value || '1');
      const data = await postJson(`${{base}}/api/cdkeys/generate`, {{
        planId: selGen?.value || '',
        count: count,
      }});
      const codes = Array.isArray(data.codes) ? data.codes : [];
      out.value = codes.join('\n');
      show(out, true);
      cdkeysCount += codes.length;
      renderCdkeysCount();
    }} catch (e) {{
      err.textContent = e?.message || 'generate failed';
      show(err, true);
    }}
  }});

  btnDel?.addEventListener('click', async () => {{
    show(delHint, false);
    show(delErr, false);
    try {{
      const data = await postJson(`${{base}}/api/cdkeys/delete`, {{
        planId: selDel?.value || '',
      }});
      const deleted = Number(data.deleted || 0);
      delHint.textContent = `已删除 ${{deleted}} 个 CDKEY`;
      show(delHint, true);
      cdkeysCount = Math.max(0, cdkeysCount - deleted);
      renderCdkeysCount();
    }} catch (e) {{
      delErr.textContent = e?.message || 'delete failed';
      show(delErr, true);
    }}
  }});

  async function loadUser() {{
    show(userHint, false);
    show(userErr, false);
    show(userRaw, false);
    btnUpdate.disabled = true;
    btnUpdate.classList.add('opacity-50');
    userForm.classList.add('hidden');
    const id = Number(userId?.value || '0');
    if (!id) {{
      userErr.textContent = 'user id required';
      show(userErr, true);
      return;
    }}
    try {{
      const resp = await fetch(`${{base}}/api/users/${{id}}`, {{ credentials: 'same-origin' }});
      const data = await resp.json().catch(() => ({{}}));
      if (!resp.ok) throw new Error(data.error || 'load failed');
      setBaseStorageB64(data.baseStorageB64);
      setBaseOutboundBytes(data.baseOutboundBytes);
      subPlan.value = data.subscriptionPlanId ?? '';
      subExpires.value = msToLocalInputValue(data.subscriptionExpiresAtMsUtc);
      banned.checked = !!data.bannedAtMsUtc;
      userRaw.textContent = JSON.stringify(data, null, 2);
      show(userRaw, true);
      userForm.classList.remove('hidden');
      btnUpdate.disabled = false;
      btnUpdate.classList.remove('opacity-50');
    }} catch (e) {{
      userErr.textContent = e?.message || 'load failed';
      show(userErr, true);
    }}
  }}

  btnLoad?.addEventListener('click', loadUser);

  btnUpdate?.addEventListener('click', async () => {{
    show(userHint, false);
    show(userErr, false);
    const id = Number(userId?.value || '0');
    if (!id) {{
      userErr.textContent = 'user id required';
      show(userErr, true);
      return;
    }}
    const payload = {{
      userId: id,
      baseStorageB64: getBaseStorageB64(),
      baseOutboundBytes: getBaseOutboundBytes(),
      subscriptionPlanId: subPlan.value === '' ? null : subPlan.value,
      subscriptionExpiresAtMsUtc: subExpires.value === '' ? null : localInputValueToMs(subExpires.value),
      banned: banned.checked,
    }};
    btnUpdate.disabled = true;
    btnUpdate.classList.add('opacity-50');
    try {{
      await postJson(`${{base}}/api/users/update`, payload);
      userHint.textContent = '已保存';
      show(userHint, true);
      await loadUser();
    }} catch (e) {{
      userErr.textContent = e?.message || 'update failed';
      show(userErr, true);
    }} finally {{
      btnUpdate.disabled = false;
      btnUpdate.classList.remove('opacity-50');
    }}
  }});

  function fmtCells() {{
    for (const el of document.querySelectorAll('[data-ms]')) {{
      const ms = Number(el.dataset.ms || '0');
      if (!ms) continue;
      try {{ el.textContent = new Date(ms).toLocaleString(); }} catch {{}}
    }}
  }}
  fmtCells();
  renderCdkeysCount();
}})();
</script>
"#,
        nav = admin_nav(&base),
        stat_users = stat_card("注册用户", &format_number(users_count)),
        stat_cdkeys = format!(
            r#"<div class="card p-5" data-spotlight>
  <div class="text-xs font-medium subtle">未激活 CDKEY</div>
  <div id="stat-cdkeys" data-count="{count}" class="mt-2 text-2xl font-semibold tracking-tight">{value}</div>
</div>"#,
            count = cdkeys_count,
            value = h(&format_number(cdkeys_count)),
        ),
        stat_storage = stat_card("累计存储", &format_bytes(total_b64)),
        stat_uptime = stat_card("已提供服务", &format_uptime(service_duration)),
        user_rows = user_rows,
        plans = plans,
        base_js = base_js,
    );

    let mut resp = Html(page_shell("管理员后台", &body)).into_response();
    resp.headers_mut().insert(
        axum::http::header::CACHE_CONTROL,
        axum::http::HeaderValue::from_static("no-store"),
    );

    Ok(resp)
}

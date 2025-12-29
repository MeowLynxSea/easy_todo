use std::net::SocketAddr;
use std::time::Duration;

use axum::extract::{ConnectInfo, Query, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::{Html, IntoResponse, Redirect, Response};
use axum::routing::{get, post};
use axum::{Form, Json, Router};
use serde::Deserialize;

use crate::{json_error, now_ms_utc, AppState, ErrorBody};

use super::admin_api;
use super::admin_cdkeys;
use super::admin_session::{authenticate_admin, build_admin_login_cookie, clear_admin_cookies};
use super::admin_stats;
use super::admin_users;
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
    let cdkeys = format!("{base}/cdkeys");
    let login = format!("{base}/login");
    let logout = format!("{base}/logout");
    let stats = format!("{base}/stats");
    let users = format!("{base}/users");

    Router::new()
        .route(&base, get(admin_dashboard_page))
        .route(&cdkeys, get(admin_cdkeys::admin_cdkeys_page))
        .route(&stats, get(admin_stats::admin_stats_page))
        .route(&users, get(admin_users::admin_users_page))
        .route(&login, get(admin_login_page).post(admin_login))
        .route(&logout, post(admin_logout))
        .route(
            &format!("{base}/api/cdkeys/list"),
            get(admin_api::admin_list_cdkeys),
        )
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

pub(super) fn admin_nav(base: &str) -> String {
    let base_href = base.trim_end_matches('/').to_string();
    let logout_action = format!("{base}/logout");
    let stats_href = format!("{base}/stats");
    let users_href = format!("{base}/users");
    let cdkeys_href = format!("{base}/cdkeys");
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
        <a class="btn btn-secondary" href="{base_href}">概览</a>
        <a class="btn btn-secondary" href="{stats_href}">统计</a>
        <a class="btn btn-secondary" href="{users_href}">用户</a>
        <a class="btn btn-secondary" href="{cdkeys_href}">CDKEY</a>
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
        <a class="btn btn-secondary w-full" href="{base_href}" data-mobile-menu-link>概览</a>
        <a class="btn btn-secondary w-full" href="{stats_href}" data-mobile-menu-link>统计分析</a>
        <a class="btn btn-secondary w-full" href="{users_href}" data-mobile-menu-link>用户管理</a>
        <a class="btn btn-secondary w-full" href="{cdkeys_href}" data-mobile-menu-link>CDKEY 管理</a>
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
        base_href = h(&base_href),
        logout_action = h(&logout_action),
        stats_href = h(&stats_href),
        users_href = h(&users_href),
        cdkeys_href = h(&cdkeys_href),
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

    let base = state.admin.entry_path.trim_end_matches('/').to_string();
    let stats_href = format!("{base}/stats");
    let users_href = format!("{base}/users");
    let cdkeys_href = format!("{base}/cdkeys");

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
    <p class="text-sm muted">概览</p>
  </div>

  <div class="mt-10 grid gap-4 md:grid-cols-4">
    {stat_users}
    {stat_cdkeys}
    {stat_storage}
    {stat_uptime}
  </div>

  <div class="mt-10 grid gap-6 md:grid-cols-3">
    <a class="card p-6 block" data-spotlight href="{stats_href}">
      <div class="text-xs font-medium subtle">统计</div>
      <div class="mt-2 text-base font-semibold">趋势图与总计</div>
      <div class="mt-2 text-xs subtle">请求/流量/新增/活跃/激活</div>
    </a>
    <a class="card p-6 block" data-spotlight href="{users_href}">
      <div class="text-xs font-medium subtle">用户</div>
      <div class="mt-2 text-base font-semibold">配额/订阅/封禁</div>
      <div class="mt-2 text-xs subtle">查询与修改用户信息</div>
    </a>
    <a class="card p-6 block" data-spotlight href="{cdkeys_href}">
      <div class="text-xs font-medium subtle">CDKEY</div>
      <div class="mt-2 text-base font-semibold">批量生成/删除</div>
      <div class="mt-2 text-xs subtle">仅管理未激活 CDKEY</div>
    </a>
  </div>
</main>
"#,
        nav = admin_nav(&base),
        stat_users = stat_card("注册用户", &format_number(users_count)),
        stat_cdkeys = stat_card("未激活 CDKEY", &format_number(cdkeys_count)),
        stat_storage = stat_card("累计存储", &format_bytes(total_b64)),
        stat_uptime = stat_card("已提供服务", &format_uptime(service_duration)),
        stats_href = h(&stats_href),
        users_href = h(&users_href),
        cdkeys_href = h(&cdkeys_href),
    );

    let mut resp = Html(page_shell("管理员后台", &body)).into_response();
    resp.headers_mut().insert(
        axum::http::header::CACHE_CONTROL,
        axum::http::HeaderValue::from_static("no-store"),
    );

    Ok(resp)
}

use std::net::SocketAddr;
use std::time::Duration;

use axum::body::Body;
use axum::extract::{ConnectInfo, OriginalUri, Query, State};
use axum::http::{header, HeaderMap, StatusCode};
use axum::response::{Html, IntoResponse, Redirect, Response};
use axum::Json;
use serde::Deserialize;
use sqlx::Row;

use crate::{
    clear_subscription_if_expired, compute_effective_quota, json_error, now_ms_utc,
    reset_user_api_outbound_if_new_month, AppState, ErrorBody, UserBillingRow,
};

use super::layout::{nav_bar, page_shell, stat_card, stat_card_ms, stat_card_ms_opt};
use super::session::{
    apply_set_cookie_headers, authenticate_web, clear_auth_cookies, cookie_value,
};
use super::util::{
    check_same_origin, format_bytes, format_number, format_uptime, h, provider_display_name,
    provider_icon_text, url_encode, validate_return_to,
};

const REFRESH_COOKIE: &str = "easy_todo_refresh";

pub(super) async fn favicon_png() -> Response {
    Response::builder()
        .status(StatusCode::OK)
        .header(header::CONTENT_TYPE, "image/png")
        .body(Body::from(&include_bytes!("favicon.png")[..]))
        .unwrap_or_else(|_| StatusCode::INTERNAL_SERVER_ERROR.into_response())
}

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

    let fmt_limit = |v: Option<i64>| match v {
        Some(v) => format_bytes(v),
        None => "不限".to_string(),
    };

    let mut plans = state.billing.plans.values().collect::<Vec<_>>();
    plans.sort_by(|a, b| {
        a.duration_ms
            .cmp(&b.duration_ms)
            .then_with(|| a.id.cmp(&b.id))
    });

    let base_storage_b64 = state.billing.default_base_storage_b64.filter(|v| *v >= 0);
    let base_outbound_bytes = state
        .billing
        .default_base_outbound_bytes
        .filter(|v| *v >= 0);

    let plan_rows = if plans.is_empty() {
        r#"<tr class="table-row"><td class="px-3 py-3 text-xs muted" colspan="4">未配置订阅方案</td></tr>"#
            .to_string()
    } else {
        plans
            .into_iter()
            .map(|plan| {
                let duration_secs = (plan.duration_ms / 1000).max(0) as u64;
                let duration_display = if duration_secs % 86400 == 0 {
                    format!("{} 天", duration_secs / 86400)
                } else {
                    format_uptime(Duration::from_secs(duration_secs))
                };

                let total_storage =
                    base_storage_b64.map(|v| v.saturating_add(plan.extra_storage_b64.max(0)));
                let total_outbound =
                    base_outbound_bytes.map(|v| v.saturating_add(plan.extra_outbound_bytes.max(0)));

                format!(
                    r#"<tr class="table-row">
  <td class="px-3 py-2 text-xs font-semibold">{name}</td>
  <td class="px-3 py-2 text-xs font-mono">{duration}</td>
  <td class="px-3 py-2 text-xs font-mono">{storage}</td>
  <td class="px-3 py-2 text-xs font-mono">{outbound}</td>
</tr>"#,
                    name = h(plan.name.trim()),
                    duration = h(&duration_display),
                    storage = h(&fmt_limit(total_storage)),
                    outbound = h(&fmt_limit(total_outbound)),
                )
            })
            .collect::<Vec<_>>()
            .join("\n")
    };

    let plans_section = format!(
        r#"<div class="mt-10 card p-6" data-spotlight>
  <h2 class="text-base font-semibold">订阅方案</h2>
  <p class="mt-2 text-sm muted">总限额 = 基础配额 + 订阅额外配额</p>
  <dl class="mt-4 grid gap-3 text-sm md:grid-cols-2">
    <div class="subcard">
      <dt class="text-xs font-medium subtle">基础存储配额</dt>
      <dd class="mt-1 font-mono">{base_storage}</dd>
    </div>
    <div class="subcard">
      <dt class="text-xs font-medium subtle">基础出站配额</dt>
      <dd class="mt-1 font-mono">{base_outbound}</dd>
    </div>
  </dl>
  <div class="table-wrap mt-4 overflow-x-auto">
    <table class="table w-full text-left text-xs">
      <thead class="subtle">
        <tr>
          <th class="px-3 py-2">名称</th>
          <th class="px-3 py-2">有效期</th>
          <th class="px-3 py-2">总存储限额</th>
          <th class="px-3 py-2">总出站限额</th>
        </tr>
      </thead>
      <tbody>
        {rows}
      </tbody>
    </table>
  </div>
</div>"#,
        base_storage = h(&fmt_limit(base_storage_b64)),
        base_outbound = h(&fmt_limit(base_outbound_bytes)),
        rows = plan_rows
    );

    let body = format!(
        r#"
{nav}
<main class="mx-auto max-w-5xl px-4 pb-20 pt-14">
  <div class="space-y-3 parallax-hero" data-parallax-hero>
    <div class="inline-flex items-center gap-2 text-xs font-mono tracking-widest subtle">
      <span class="badge">SYNC</span>
      <span>SERVER</span>
    </div>
    <h1 class="text-4xl font-semibold tracking-tight md:text-5xl heading-grad">轻单 同步服务</h1>
    <p class="text-sm muted md:text-base">Easy Todo Sync Service</p>
  </div>

  <div class="mt-10 grid gap-4 md:grid-cols-4">
    {stat_users}
    {stat_records}
    {stat_storage}
    {stat_uptime}
  </div>

  <div class="mt-10 card p-6" data-spotlight>
    <h2 class="text-base font-semibold">使用教程</h2>
    <ol class="mt-4 list-decimal space-y-2 pl-5 text-sm muted">
      <li>复制下方的「服务器链接」</li>
      <li>打开应用 → 云同步 → 服务器配置</li>
      <li>粘贴并保存</li>
    </ol>

    <div class="mt-6">
      <div class="grid gap-3 sm:grid-cols-[1fr_auto] sm:items-end">
        <label class="block">
          <span class="text-xs font-medium subtle">服务器链接</span>
          <input class="input mt-2 font-mono text-sm" value="{server_link}" readonly />
        </label>
        <button id="copy-link" class="btn btn-secondary h-11 w-full sm:w-auto" type="button">复制</button>
      </div>
      <p id="copy-hint" class="mt-2 hidden text-xs text-emerald-600 dark:text-emerald-400">已复制</p>
    </div>
  </div>

  {plans}

    <div class="mt-8 flex flex-wrap items-center justify-between gap-3">
      <div class="text-xs subtle">
        API: <a class="link" href="/v1/health">/v1/health</a>
      </div>
      <a class="btn btn-primary w-full sm:w-auto" href="/dashboard">进入仪表盘</a>
    </div>
</main>
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
        plans = plans_section,
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
                r#"<a class="card group flex items-center justify-between px-5 py-4" data-spotlight href="{href}">
  <div class="flex items-center gap-3">
    <div class="icon-chip text-sm font-semibold">{icon}</div>
    <div>
      <div class="text-sm font-semibold">{display}</div>
      <div class="text-xs muted">OAuth 登录</div>
    </div>
  </div>
  <div class="subtle transition duration-200 group-hover:translate-x-0.5 group-hover:text-[color:var(--foreground)]">→</div>
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
{nav}
<main class="mx-auto max-w-xl px-4 pb-20 pt-14">
  <div class="space-y-3">
    <h1 class="text-3xl font-semibold tracking-tight heading-grad">登录仪表盘</h1>
    <p class="text-sm muted">请选择一个 Provider 继续</p>
  </div>

  <div class="mt-8 space-y-3">
    {items}
  </div>

  <p class="mt-8 text-xs subtle">
    登录后仅用于查看你的同步用量与管理数据，不会跳转回客户端。
  </p>
</main>
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

    let now_ms = now_ms_utc();
    reset_user_api_outbound_if_new_month(&state.db, user_id, now_ms)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let user_row = sqlx::query(
        r#"SELECT
             created_at_ms_utc,
             oauth_provider,
             base_storage_b64,
             base_outbound_bytes,
             subscription_plan_id,
             subscription_expires_at_ms_utc,
             banned_at_ms_utc,
             stored_b64,
             api_outbound_bytes
           FROM users
           WHERE id = ?"#,
    )
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

    let base_storage_b64: Option<i64> = user_row
        .try_get("base_storage_b64")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let base_outbound_bytes: Option<i64> = user_row
        .try_get("base_outbound_bytes")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let mut subscription_plan_id: Option<String> = user_row
        .try_get("subscription_plan_id")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let mut subscription_expires_at_ms_utc: Option<i64> = user_row
        .try_get("subscription_expires_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let banned_at_ms_utc: Option<i64> = user_row
        .try_get("banned_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let stored_b64: i64 = user_row
        .try_get("stored_b64")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let api_outbound_bytes: i64 = user_row
        .try_get("api_outbound_bytes")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let has_plan = subscription_plan_id
        .as_deref()
        .map(|s| !s.trim().is_empty())
        .unwrap_or(false);
    let expires_at = subscription_expires_at_ms_utc.unwrap_or(0);
    if has_plan && expires_at <= now_ms {
        clear_subscription_if_expired(
            &state.db,
            user_id,
            &subscription_plan_id,
            subscription_expires_at_ms_utc,
            now_ms,
        )
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
        subscription_plan_id = None;
        subscription_expires_at_ms_utc = None;
    }

    let total_records: i64 =
        sqlx::query_scalar(r#"SELECT COUNT(*) FROM records WHERE user_id = ?"#)
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

    let user_billing = UserBillingRow {
        base_storage_b64,
        base_outbound_bytes,
        subscription_plan_id: subscription_plan_id.clone(),
        subscription_expires_at_ms_utc,
        banned_at_ms_utc,
        stored_b64,
        api_outbound_bytes,
    };
    let quota = compute_effective_quota(&state.billing, &user_billing, now_ms);

    let over_storage = quota
        .allowed_storage_b64
        .is_some_and(|limit| stored_b64 > limit);
    let over_outbound = quota
        .allowed_outbound_bytes
        .is_some_and(|limit| api_outbound_bytes > limit);
    let over_any = over_storage || over_outbound;
    let is_banned = banned_at_ms_utc.is_some_and(|ms| ms > 0);
    let has_active_subscription = subscription_expires_at_ms_utc.unwrap_or(0) > now_ms
        && subscription_plan_id
            .as_deref()
            .map(|s| !s.trim().is_empty())
            .unwrap_or(false);

    let fmt_limit = |v: Option<i64>| match v {
        Some(v) => format_bytes(v),
        None => "不限".to_string(),
    };

    let sub_active = quota
        .active_plan_expires_at_ms_utc
        .unwrap_or(0)
        .saturating_sub(now_ms);
    let sub_active = (sub_active / 1000).max(0) as u64;
    let sub_remaining = format_uptime(Duration::from_secs(sub_active));

    let (sub_status, sub_plan_display, sub_expires_at_ms, sub_remaining_display) =
        if let (Some(name), Some(_id), Some(exp)) = (
            quota.active_plan_name.as_deref(),
            quota.active_plan_id.as_deref(),
            quota.active_plan_expires_at_ms_utc,
        ) {
            let plan_name = name.trim();
            let plan_name = if plan_name.is_empty() {
                "订阅"
            } else {
                plan_name
            };
            (
                "生效中".to_string(),
                plan_name.to_string(),
                exp,
                sub_remaining.clone(),
            )
        } else if has_active_subscription {
            (
                "生效中（未知方案）".to_string(),
                "未知方案".to_string(),
                subscription_expires_at_ms_utc.unwrap_or(0),
                sub_remaining.clone(),
            )
        } else {
            ("无订阅".to_string(), "—".to_string(), 0, "—".to_string())
        };

    let subscription_section = format!(
        r#"<div class="mt-6 card p-6" data-spotlight>
  <h2 class="text-base font-semibold">当前订阅</h2>
  <dl class="mt-4 grid gap-3 text-sm md:grid-cols-2">
    <div class="subcard">
      <dt class="text-xs font-medium subtle">状态</dt>
      <dd class="mt-1 font-mono">{status}</dd>
    </div>
    <div class="subcard">
      <dt class="text-xs font-medium subtle">方案</dt>
      <dd class="mt-1 font-mono">{plan}</dd>
    </div>
    <div class="subcard">
      <dt class="text-xs font-medium subtle">到期时间</dt>
      <dd id="sub-exp" data-ms="{exp}" class="mt-1 font-mono">—</dd>
    </div>
    <div class="subcard">
      <dt class="text-xs font-medium subtle">剩余</dt>
      <dd class="mt-1 font-mono">{remain}</dd>
    </div>
  </dl>
  <p class="mt-4 text-xs subtle">订阅期间额外提升：存储 +{bonus_storage}，出站 +{bonus_out}</p>
</div>"#,
        status = h(&sub_status),
        plan = h(&sub_plan_display),
        exp = sub_expires_at_ms,
        remain = h(&sub_remaining_display),
        bonus_storage = h(&format_bytes(quota.bonus_storage_b64)),
        bonus_out = h(&format_bytes(quota.bonus_outbound_bytes)),
    );

    let next_reset_at_ms_utc: i64 = sqlx::query_scalar(
        r#"SELECT CAST(strftime('%s', ? / 1000, 'unixepoch', 'start of month', '+1 month') AS INTEGER) * 1000"#,
    )
    .bind(now_ms)
    .fetch_one(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let mins_until_reset = next_reset_at_ms_utc
        .saturating_sub(now_ms)
        .max(0)
        .saturating_div(60_000);
    let days_until_reset = mins_until_reset / (24 * 60);
    let hours_until_reset = (mins_until_reset % (24 * 60)) / 60;
    let minutes_until_reset = mins_until_reset % 60;
    let reset_in = format!(
        "{}天{}时{}分后重置",
        days_until_reset, hours_until_reset, minutes_until_reset
    );

    let fmt_ratio = |used: i64, limit: Option<i64>| {
        let used = format_bytes(used);
        let limit = match limit {
            Some(v) => format_bytes(v),
            None => "不限".to_string(),
        };
        format!("{used}/{limit}")
    };

    let fmt_percent = |used: i64, limit: Option<i64>| match limit.filter(|v| *v > 0) {
        Some(max) => {
            let pct = (used.max(0) as f64 / max as f64) * 100.0;
            format!("{:.0}%", pct.max(0.0))
        }
        None => "不限".to_string(),
    };

    let bar_width = |used: i64, limit: Option<i64>| match limit.filter(|v| *v > 0) {
        Some(max) => {
            let pct = (used.max(0) as f64 / max as f64) * 100.0;
            pct.clamp(0.0, 100.0).round() as i64
        }
        None => 0i64,
    };

    let usage_card = format!(
        r#"<div class="card p-6 md:col-span-2 md:row-span-2" data-spotlight>
  <div class="flex flex-wrap items-start justify-between gap-4">
    <div>
      <div class="text-xs font-medium subtle">用量</div>
      <div class="mt-1 text-sm muted">存储与本月出站流量</div>
    </div>
    <div class="text-xs font-medium subtle">{reset_in}</div>
  </div>

  <div class="mt-6 grid gap-6">
    <div>
	      <div class="flex items-end justify-between gap-3">
	        <div class="text-sm font-semibold tracking-tight">存储用量</div>
	        <div class="text-sm font-mono font-semibold tracking-tight">{storage_ratio}</div>
	      </div>
	      <div class="mt-3 h-2 rounded-full bg-black/10 dark:bg-white/10 overflow-hidden">
	        <div class="h-2 rounded-full {storage_bar} transition-[width] duration-300 ease-out" style="width:{storage_width}%"></div>
	      </div>
	      <div class="mt-2 text-xs font-mono subtle text-right">{storage_pct}</div>
	    </div>
	
	    <div>
	      <div class="flex items-end justify-between gap-3">
	        <div class="text-sm font-semibold tracking-tight">本月出站流量</div>
	        <div class="text-sm font-mono font-semibold tracking-tight">{out_ratio}</div>
	      </div>
	      <div class="mt-3 h-2 rounded-full bg-black/10 dark:bg-white/10 overflow-hidden">
	        <div class="h-2 rounded-full {out_bar} transition-[width] duration-300 ease-out" style="width:{out_width}%"></div>
	      </div>
	      <div class="mt-2 text-xs font-mono subtle text-right">{out_pct}</div>
	    </div>
	  </div>
</div>"#,
        reset_in = h(&reset_in),
        storage_ratio = h(&fmt_ratio(stored_b64, quota.allowed_storage_b64)),
        storage_pct = h(&fmt_percent(stored_b64, quota.allowed_storage_b64)),
        storage_width = bar_width(stored_b64, quota.allowed_storage_b64),
        storage_bar = if over_storage {
            "bg-rose-500"
        } else {
            "bg-[color:var(--accent)]"
        },
        out_ratio = h(&fmt_ratio(api_outbound_bytes, quota.allowed_outbound_bytes)),
        out_pct = h(&fmt_percent(
            api_outbound_bytes,
            quota.allowed_outbound_bytes
        )),
        out_width = bar_width(api_outbound_bytes, quota.allowed_outbound_bytes),
        out_bar = if over_outbound {
            "bg-rose-500"
        } else {
            "bg-[color:var(--accent)]"
        },
    );

    let quota_section = format!(
        r#"<div class="mt-10 card p-6" data-spotlight>
  <h2 class="text-base font-semibold">当前配额</h2>
  <div class="mt-4 grid gap-3 md:grid-cols-2">
    <div class="subcard">
      <div class="text-xs font-medium subtle">存储</div>
      <div class="mt-2 grid gap-1 text-sm">
        <div>已用：<span class="font-mono font-semibold">{storage_used}</span></div>
        <div>可用：<span class="font-mono font-semibold">{storage_allowed}</span></div>
        <div class="text-xs subtle">组成：基础 {storage_base} + 订阅 {storage_bonus}</div>
      </div>
    </div>
    <div class="subcard">
      <div class="text-xs font-medium subtle">本月出站流量</div>
      <div class="mt-2 grid gap-1 text-sm">
        <div>已用：<span class="font-mono font-semibold">{out_used}</span></div>
        <div>可用：<span class="font-mono font-semibold">{out_allowed}</span></div>
        <div class="text-xs subtle">组成：基础 {out_base} + 订阅 {out_bonus}</div>
      </div>
    </div>
  </div>
  <div class="mt-4 rounded-xl border border-rose-500/20 bg-rose-500/5 p-4 text-sm {warn_hide}">
    <div class="font-semibold text-rose-700 dark:text-rose-200">已超出允许配额</div>
    <div class="mt-1 text-xs subtle">为保证资源可控，服务器将拒绝你的推送/拉取；你仍可正常登录与删除账户（不会自动删除数据）。</div>
  </div>
  <div class="mt-4 rounded-xl border border-rose-500/20 bg-rose-500/5 p-4 text-sm {ban_hide}">
    <div class="font-semibold text-rose-700 dark:text-rose-200">账号已被封禁</div>
    <div class="mt-1 text-xs subtle">如需解封请联系管理员。</div>
  </div>
</div>"#,
        storage_used = h(&format_bytes(stored_b64)),
        storage_allowed = h(&fmt_limit(quota.allowed_storage_b64)),
        storage_base = h(&fmt_limit(quota.base_storage_b64)),
        storage_bonus = h(&format_bytes(quota.bonus_storage_b64)),
        out_used = h(&format_bytes(api_outbound_bytes)),
        out_allowed = h(&fmt_limit(quota.allowed_outbound_bytes)),
        out_base = h(&fmt_limit(quota.base_outbound_bytes)),
        out_bonus = h(&format_bytes(quota.bonus_outbound_bytes)),
        warn_hide = if over_any { "" } else { "hidden" },
        ban_hide = if is_banned { "" } else { "hidden" },
    );

    let cdkey_disabled = has_active_subscription;
    let cdkey_section = format!(
        r#"<div class="mt-6 card p-6" data-spotlight>
  <h2 class="text-base font-semibold">激活 CDKEY</h2>
  <p class="mt-1 text-sm muted">仅支持在「无订阅」状态下激活；若已有订阅，将拒绝激活且不消耗CDKEY。</p>
  <div class="mt-4 grid gap-3 sm:grid-cols-[1fr_auto] sm:items-center">
    <input id="cdkey-input" class="input font-mono text-sm" placeholder="输入CDKEY" {disabled} />
    <button id="cdkey-btn" class="btn btn-primary h-11 w-full sm:w-auto {btn_disabled}" type="button" {btn_attr}>激活</button>
  </div>
  <p id="cdkey-hint" class="mt-3 hidden text-sm text-emerald-700 dark:text-emerald-300"></p>
  <p id="cdkey-error" class="mt-3 hidden text-sm text-rose-600 dark:text-rose-400"></p>
</div>
<script>
(() => {{
  const input = document.getElementById('cdkey-input');
  const btn = document.getElementById('cdkey-btn');
  const hint = document.getElementById('cdkey-hint');
  const err = document.getElementById('cdkey-error');
  function show(el, on) {{ el?.classList.toggle('hidden', !on); }}
  btn?.addEventListener('click', async () => {{
    show(hint, false);
    show(err, false);
    const code = (input?.value || '').trim();
    if (!code) {{
      err.textContent = '请输入CDKEY';
      show(err, true);
      return;
    }}
    btn.disabled = true;
    btn.classList.add('opacity-50');
    try {{
      const resp = await fetch('/web/api/me/activate-cdkey', {{
        method: 'POST',
        headers: {{ 'Content-Type': 'application/json' }},
        credentials: 'same-origin',
        body: JSON.stringify({{ code }}),
      }});
      const data = await resp.json().catch(() => ({{}}));
      if (!resp.ok) throw new Error(data.error || 'activate failed');
      hint.textContent = `已激活：${{data.planName || data.planId}}`;
      show(hint, true);
      window.setTimeout(() => window.location.reload(), 600);
    }} catch (e) {{
      err.textContent = e?.message || 'activate failed';
      show(err, true);
    }} finally {{
      btn.disabled = false;
      btn.classList.remove('opacity-50');
    }}
  }});
}})();
</script>"#,
        disabled = if cdkey_disabled { "disabled" } else { "" },
        btn_disabled = if cdkey_disabled { "opacity-50" } else { "" },
        btn_attr = if cdkey_disabled { "disabled" } else { "" },
    );

    let body = format!(
        r#"
{nav}
<main class="mx-auto max-w-5xl px-4 pb-20 pt-14">
  <div class="flex flex-wrap items-start justify-between gap-4">
    <div>
      <h1 class="text-3xl font-semibold tracking-tight heading-grad">仪表盘</h1>
      <p class="mt-2 text-sm muted">管理你的同步数据与账户</p>
    </div>
    <form method="post" action="/dashboard/logout">
      <button class="btn btn-secondary" type="submit">退出登录</button>
    </form>
  </div>

  <div class="mt-10 grid gap-4 md:grid-cols-4">
    {stat_created}
    {stat_records}
    {usage_card}
    {stat_last_sync}
    {stat_user_id}
  </div>

  <div class="mt-10 card p-6" data-spotlight>
    <h2 class="text-base font-semibold">账户信息</h2>
    <dl class="mt-4 grid gap-3 text-sm">
      <div class="subcard">
        <dt class="text-xs font-medium subtle">OAuth Provider</dt>
        <dd class="mt-1 font-mono">{provider}</dd>
      </div>
    </dl>
  </div>

  {subscription_section}
  {quota_section}
  {cdkey_section}

  <div class="mt-6 rounded-2xl border border-rose-500/20 bg-rose-500/5 p-6 shadow-[0_0_0_1px_rgba(244,63,94,0.12),0_18px_50px_rgba(0,0,0,0.18)]">
    <div class="flex flex-wrap items-start justify-between gap-4">
      <div>
        <h2 class="text-base font-semibold text-rose-900 dark:text-rose-200">危险操作：清除数据</h2>
        <p class="mt-1 text-sm text-rose-800/90 dark:text-rose-200/80">
          将清除与你账号关联的所有数据，并删除数据库中的账户。此操作不可撤销。
        </p>
      </div>
      <button id="open-delete" class="btn btn-danger" type="button">清除数据</button>
    </div>
  </div>
</main>

<div id="delete-modal" class="fixed inset-0 z-[70] hidden items-center justify-center bg-black/60 p-4 backdrop-blur-sm">
  <div class="card card-static w-full max-w-lg p-6">
    <h3 class="text-lg font-semibold">二次确认</h3>
    <p class="mt-2 text-sm muted">
      请输入 <span class="font-mono font-semibold">DELETE</span> 以确认删除。
    </p>
    <input id="delete-input" class="input input-danger mt-4 font-mono text-sm" placeholder="DELETE" />
    <div class="mt-5 flex items-center justify-end gap-3">
      <button id="cancel-delete" class="btn btn-secondary" type="button">取消</button>
      <button id="confirm-delete" class="btn btn-danger opacity-50" type="button" disabled>确认删除</button>
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
  fmt('sub-exp');
}})();
</script>
"#,
        nav = nav_bar(Some("仪表盘")),
        stat_user_id = stat_card("用户ID", &format_number(user_id)),
        stat_created = stat_card_ms("注册时间", created_at_ms, "created-at"),
        stat_records = stat_card("记录数", &format_number(total_records)),
        usage_card = usage_card,
        stat_last_sync = stat_card_ms_opt("最近同步", last_sync_at_ms, "last-sync"),
        provider = h(&oauth_provider_display),
        subscription_section = subscription_section,
        quota_section = quota_section,
        cdkey_section = cdkey_section,
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
{nav}
<main class="mx-auto max-w-xl px-4 pb-20 pt-24 text-center">
  <h1 class="text-3xl font-semibold tracking-tight heading-grad">页面不存在</h1>
  <p class="mt-3 text-sm muted">Not Found</p>
  <div class="mt-8">
    <a class="btn btn-primary" href="/">返回主页</a>
  </div>
</main>
"#,
        nav = nav_bar(Some("404")),
    );
    (StatusCode::NOT_FOUND, Html(page_shell("Not Found", &body))).into_response()
}

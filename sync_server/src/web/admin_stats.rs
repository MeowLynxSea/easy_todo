use std::collections::HashMap;

use axum::extract::{ConnectInfo, OriginalUri, Query, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::{Html, IntoResponse, Redirect, Response};
use axum::Json;
use serde::Deserialize;
use sqlx::Row;

use crate::{json_error, metrics, now_ms_utc, AppState, ErrorBody};

use super::admin_pages::admin_nav;
use super::admin_session::authenticate_admin;
use super::layout::page_shell;
use super::util::{format_bytes, format_number, h, url_encode};

#[derive(Debug, Deserialize)]
pub(super) struct AdminStatsQuery {
    start: Option<String>,
    end: Option<String>,
    granularity: Option<String>,
    metric: Option<String>,
}

#[derive(Debug, Clone, Copy)]
enum Granularity {
    Day,
    Month,
    Year,
}

impl Granularity {
    fn from_str(raw: Option<&str>) -> Self {
        match raw.unwrap_or("").trim().to_lowercase().as_str() {
            "month" | "m" => Self::Month,
            "year" | "y" => Self::Year,
            _ => Self::Day,
        }
    }

    fn label(&self) -> &'static str {
        match self {
            Self::Day => "日",
            Self::Month => "月",
            Self::Year => "年",
        }
    }
}

#[derive(Debug, Clone, Copy)]
enum Metric {
    ApiRequests,
    ApiInBytes,
    ApiOutBytes,
    NewUsers,
    CdkeyActivations,
    ActiveUsers,
}

impl Metric {
    fn from_str(raw: Option<&str>) -> Self {
        match raw.unwrap_or("").trim().to_lowercase().as_str() {
            "api_in_bytes" | "in" | "in_bytes" => Self::ApiInBytes,
            "api_out_bytes" | "out" | "out_bytes" => Self::ApiOutBytes,
            "new_users" | "new" => Self::NewUsers,
            "cdkey_activations" | "cdkey" | "activations" => Self::CdkeyActivations,
            "active_users" | "active" | "dau" => Self::ActiveUsers,
            _ => Self::ApiRequests,
        }
    }

    fn as_value(&self) -> &'static str {
        match self {
            Self::ApiRequests => "api_requests",
            Self::ApiInBytes => "api_in_bytes",
            Self::ApiOutBytes => "api_out_bytes",
            Self::NewUsers => "new_users",
            Self::CdkeyActivations => "cdkey_activations",
            Self::ActiveUsers => "active_users",
        }
    }

    fn label(&self) -> &'static str {
        match self {
            Self::ApiRequests => "请求数",
            Self::ApiInBytes => "入站流量",
            Self::ApiOutBytes => "出站流量",
            Self::NewUsers => "新增用户",
            Self::CdkeyActivations => "CDKEY 激活",
            Self::ActiveUsers => "活跃用户",
        }
    }

    fn format_value(&self, v: i64) -> String {
        match self {
            Self::ApiInBytes | Self::ApiOutBytes => format_bytes(v),
            _ => format_number(v),
        }
    }

    fn pick(&self, row: &StatsRow) -> i64 {
        match self {
            Self::ApiRequests => row.api_requests,
            Self::ApiInBytes => row.api_in_bytes,
            Self::ApiOutBytes => row.api_out_bytes,
            Self::NewUsers => row.new_users,
            Self::CdkeyActivations => row.cdkey_activations,
            Self::ActiveUsers => row.active_users,
        }
    }
}

#[derive(Debug, Clone)]
struct StatsRow {
    bucket: String,
    api_requests: i64,
    api_in_bytes: i64,
    api_out_bytes: i64,
    new_users: i64,
    cdkey_activations: i64,
    active_users: i64,
}

pub(super) async fn admin_stats_page(
    State(state): State<AppState>,
    OriginalUri(uri): OriginalUri,
    headers: HeaderMap,
    Query(q): Query<AdminStatsQuery>,
    ConnectInfo(addr): ConnectInfo<std::net::SocketAddr>,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !state.admin.enabled() {
        return Err(json_error(StatusCode::NOT_FOUND, "not found"));
    }

    {
        let mut limiter = state.admin_limiter.lock().await;
        if !limiter.check(&format!("admin:stats:page:{}", addr.ip())) {
            return Err(json_error(StatusCode::TOO_MANY_REQUESTS, "rate limited"));
        }
    }

    if authenticate_admin(&state, &headers).is_err() {
        let next = uri
            .path_and_query()
            .map(|pq| pq.as_str())
            .unwrap_or(&state.admin.entry_path);
        let login = format!("{}/login?next={}", state.admin.entry_path, url_encode(next));
        return Ok(Redirect::temporary(&login).into_response());
    }

    let now_ms = now_ms_utc();
    let end_default_days =
        metrics::parse_day_utc(&metrics::day_utc_from_unix_ms(now_ms)).unwrap_or(0);
    let start_default_days = end_default_days.saturating_sub(29);

    let mut start_days = q
        .start
        .as_deref()
        .and_then(metrics::parse_day_utc)
        .unwrap_or(start_default_days);
    let mut end_days = q
        .end
        .as_deref()
        .and_then(metrics::parse_day_utc)
        .unwrap_or(end_default_days);
    if start_days > end_days {
        std::mem::swap(&mut start_days, &mut end_days);
    }

    let start_day = metrics::format_day_utc_from_days(start_days);
    let end_day = metrics::format_day_utc_from_days(end_days);

    let granularity = Granularity::from_str(q.granularity.as_deref());
    let metric = Metric::from_str(q.metric.as_deref());

    let mut rows = query_rows(&state, granularity, &start_day, &end_day)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    if let Granularity::Day = granularity {
        rows = fill_missing_days(rows, start_days, end_days);
    }

    let totals = rows.iter().fold(DailyAgg::default(), |mut acc, r| {
        acc.api_requests = acc.api_requests.saturating_add(r.api_requests.max(0));
        acc.api_in_bytes = acc.api_in_bytes.saturating_add(r.api_in_bytes.max(0));
        acc.api_out_bytes = acc.api_out_bytes.saturating_add(r.api_out_bytes.max(0));
        acc.new_users = acc.new_users.saturating_add(r.new_users.max(0));
        acc.cdkey_activations = acc
            .cdkey_activations
            .saturating_add(r.cdkey_activations.max(0));
        acc.active_users = acc.active_users.saturating_add(r.active_users.max(0));
        acc
    });

    let unique_active_users: i64 = sqlx::query_scalar(
        r#"SELECT COUNT(DISTINCT user_id)
           FROM metrics_daily_active_users
           WHERE day_utc >= ? AND day_utc <= ?"#,
    )
    .bind(&start_day)
    .bind(&end_day)
    .fetch_one(&state.db)
    .await
    .unwrap_or(0);

    let buckets = rows.len().max(1) as i64;
    let avg_active = totals.active_users / buckets;

    let chart_values = rows.iter().map(|r| metric.pick(r)).collect::<Vec<_>>();
    let chart_labels = rows.iter().map(|r| r.bucket.clone()).collect::<Vec<_>>();
    let chart_svg = line_chart_svg(&chart_labels, &chart_values, metric);

    let table_rows = rows
        .iter()
        .map(|r| {
            format!(
                r#"<tr class="table-row">
  <td class="px-3 py-2 font-mono text-xs">{bucket}</td>
  <td class="px-3 py-2 text-xs">{req}</td>
  <td class="px-3 py-2 text-xs">{inb}</td>
  <td class="px-3 py-2 text-xs">{outb}</td>
  <td class="px-3 py-2 text-xs">{newu}</td>
  <td class="px-3 py-2 text-xs">{cdk}</td>
  <td class="px-3 py-2 text-xs">{act}</td>
</tr>"#,
                bucket = h(&r.bucket),
                req = h(&format_number(r.api_requests)),
                inb = h(&format_bytes(r.api_in_bytes)),
                outb = h(&format_bytes(r.api_out_bytes)),
                newu = h(&format_number(r.new_users)),
                cdk = h(&format_number(r.cdkey_activations)),
                act = h(&format_number(r.active_users)),
            )
        })
        .collect::<Vec<_>>()
        .join("\n");

    let base = state.admin.entry_path.trim_end_matches('/').to_string();
    let action = format!("{base}/stats");

    let body = format!(
        r#"
{nav}
<main class="mx-auto max-w-6xl px-4 pb-20 pt-14">
  <div class="space-y-3">
    <h1 class="text-3xl font-semibold tracking-tight heading-grad">统计分析</h1>
    <p class="text-sm muted">指标按 UTC 日期聚合；仅统计 API（/v1/*，不含 /v1/health）。</p>
    <p class="text-xs subtle">自启动以来丢弃的事件: {dropped}</p>
  </div>

  <form class="mt-8 card p-6" method="get" action="{action}" data-spotlight>
    <div class="grid gap-3 md:grid-cols-4">
      <label class="block">
        <span class="text-xs font-medium subtle">粒度</span>
        <select name="granularity" class="input mt-2 text-sm">
          <option value="day" {g_day}>日</option>
          <option value="month" {g_month}>月</option>
          <option value="year" {g_year}>年</option>
        </select>
      </label>

      <label class="block">
        <span class="text-xs font-medium subtle">趋势指标</span>
        <select name="metric" class="input mt-2 text-sm">
          <option value="api_requests" {m_req}>请求数</option>
          <option value="api_in_bytes" {m_in}>入站流量</option>
          <option value="api_out_bytes" {m_out}>出站流量</option>
          <option value="new_users" {m_new}>新增用户</option>
          <option value="cdkey_activations" {m_cdk}>CDKEY 激活</option>
          <option value="active_users" {m_act}>活跃用户</option>
        </select>
      </label>

      <label class="block">
        <span class="text-xs font-medium subtle">开始日期（UTC）</span>
        <input name="start" type="date" value="{start}" class="input mt-2 text-sm font-mono" />
      </label>

      <label class="block">
        <span class="text-xs font-medium subtle">结束日期（UTC）</span>
        <input name="end" type="date" value="{end}" class="input mt-2 text-sm font-mono" />
      </label>
    </div>

    <div class="mt-4 flex flex-wrap items-center gap-2">
      <button class="btn btn-primary" type="submit">查询</button>
      <a class="btn btn-secondary" href="{action}?granularity=day&metric={metric}&start={start_7}&end={end}">最近7天</a>
      <a class="btn btn-secondary" href="{action}?granularity=day&metric={metric}&start={start_30}&end={end}">最近30天</a>
      <a class="btn btn-secondary" href="{action}?granularity=day&metric={metric}&start={start_90}&end={end}">最近90天</a>
    </div>
  </form>

  <div class="mt-8 grid gap-4 md:grid-cols-4">
    {stat_req}
    {stat_in}
    {stat_out}
    {stat_active}
  </div>
  <div class="mt-4 grid gap-4 md:grid-cols-4">
    {stat_new}
    {stat_cdk}
    {stat_unique_active}
    {stat_avg_active}
  </div>

  <div class="mt-8 card p-6" data-spotlight>
    <div class="flex flex-wrap items-start justify-between gap-3">
      <div>
        <h2 class="text-base font-semibold">{metric_label} · 趋势</h2>
        <p class="mt-1 text-xs subtle">范围：{start} ～ {end}（{granularity_label}）</p>
      </div>
      <div class="text-sm font-mono font-semibold">{metric_total}</div>
    </div>
    <div class="mt-4">
      {chart_svg}
    </div>
  </div>

  <div class="mt-6 card p-6" data-spotlight>
    <h2 class="text-base font-semibold">明细</h2>
    <div class="table-wrap mt-4 overflow-x-auto">
      <table class="table w-full text-left text-xs">
        <thead class="subtle">
          <tr>
            <th class="px-3 py-2">{bucket_label}</th>
            <th class="px-3 py-2">请求</th>
            <th class="px-3 py-2">入站</th>
            <th class="px-3 py-2">出站</th>
            <th class="px-3 py-2">新增用户</th>
            <th class="px-3 py-2">CDKEY 激活</th>
            <th class="px-3 py-2">活跃用户</th>
          </tr>
        </thead>
        <tbody>
          {table_rows}
        </tbody>
      </table>
    </div>
  </div>
</main>
"#,
        nav = admin_nav(&base),
        action = h(&action),
        dropped = h(&state.metrics.dropped_events().to_string()),
        g_day = if matches!(granularity, Granularity::Day) {
            "selected"
        } else {
            ""
        },
        g_month = if matches!(granularity, Granularity::Month) {
            "selected"
        } else {
            ""
        },
        g_year = if matches!(granularity, Granularity::Year) {
            "selected"
        } else {
            ""
        },
        m_req = if matches!(metric, Metric::ApiRequests) {
            "selected"
        } else {
            ""
        },
        m_in = if matches!(metric, Metric::ApiInBytes) {
            "selected"
        } else {
            ""
        },
        m_out = if matches!(metric, Metric::ApiOutBytes) {
            "selected"
        } else {
            ""
        },
        m_new = if matches!(metric, Metric::NewUsers) {
            "selected"
        } else {
            ""
        },
        m_cdk = if matches!(metric, Metric::CdkeyActivations) {
            "selected"
        } else {
            ""
        },
        m_act = if matches!(metric, Metric::ActiveUsers) {
            "selected"
        } else {
            ""
        },
        metric = h(metric.as_value()),
        start = h(&start_day),
        end = h(&end_day),
        start_7 = h(&metrics::format_day_utc_from_days(
            end_days.saturating_sub(6)
        )),
        start_30 = h(&metrics::format_day_utc_from_days(
            end_days.saturating_sub(29)
        )),
        start_90 = h(&metrics::format_day_utc_from_days(
            end_days.saturating_sub(89)
        )),
        stat_req = stat_card("请求数", &format_number(totals.api_requests)),
        stat_in = stat_card("入站流量", &format_bytes(totals.api_in_bytes)),
        stat_out = stat_card("出站流量", &format_bytes(totals.api_out_bytes)),
        stat_active = stat_card("活跃用户（累计）", &format_number(totals.active_users)),
        stat_new = stat_card("新增用户", &format_number(totals.new_users)),
        stat_cdk = stat_card("CDKEY 激活", &format_number(totals.cdkey_activations)),
        stat_unique_active = stat_card("活跃用户（去重）", &format_number(unique_active_users)),
        stat_avg_active = stat_card("平均活跃用户", &format_number(avg_active.max(0))),
        metric_label = h(metric.label()),
        metric_total = h(&metric.format_value(metric_total(metric, &totals))),
        granularity_label = h(granularity.label()),
        bucket_label = h(match granularity {
            Granularity::Day => "日期",
            Granularity::Month => "月份",
            Granularity::Year => "年份",
        }),
        chart_svg = chart_svg,
        table_rows = table_rows,
    );

    let mut resp = Html(page_shell("统计分析", &body)).into_response();
    resp.headers_mut().insert(
        axum::http::header::CACHE_CONTROL,
        axum::http::HeaderValue::from_static("no-store"),
    );
    Ok(resp)
}

#[derive(Debug, Default, Clone, Copy)]
struct DailyAgg {
    api_requests: i64,
    api_in_bytes: i64,
    api_out_bytes: i64,
    new_users: i64,
    cdkey_activations: i64,
    active_users: i64,
}

fn metric_total(metric: Metric, totals: &DailyAgg) -> i64 {
    match metric {
        Metric::ApiRequests => totals.api_requests,
        Metric::ApiInBytes => totals.api_in_bytes,
        Metric::ApiOutBytes => totals.api_out_bytes,
        Metric::NewUsers => totals.new_users,
        Metric::CdkeyActivations => totals.cdkey_activations,
        Metric::ActiveUsers => totals.active_users,
    }
}

fn stat_card(label: &str, value: &str) -> String {
    format!(
        r#"<div class="card p-5" data-spotlight>
  <div class="text-xs font-medium subtle">{label}</div>
  <div class="mt-2 text-2xl font-semibold tracking-tight">{value}</div>
</div>"#,
        label = h(label),
        value = h(value),
    )
}

async fn query_rows(
    state: &AppState,
    granularity: Granularity,
    start_day: &str,
    end_day: &str,
) -> Result<Vec<StatsRow>, sqlx::Error> {
    match granularity {
        Granularity::Day => {
            let rows = sqlx::query(
                r#"SELECT
                     day_utc AS bucket,
                     api_requests,
                     api_in_bytes,
                     api_out_bytes,
                     new_users,
                     cdkey_activations,
                     active_users
                   FROM metrics_daily
                   WHERE day_utc >= ? AND day_utc <= ?
                   ORDER BY day_utc ASC"#,
            )
            .bind(start_day)
            .bind(end_day)
            .fetch_all(&state.db)
            .await?;
            Ok(rows
                .into_iter()
                .map(|row| StatsRow {
                    bucket: row.try_get("bucket").unwrap_or_default(),
                    api_requests: row.try_get("api_requests").unwrap_or(0),
                    api_in_bytes: row.try_get("api_in_bytes").unwrap_or(0),
                    api_out_bytes: row.try_get("api_out_bytes").unwrap_or(0),
                    new_users: row.try_get("new_users").unwrap_or(0),
                    cdkey_activations: row.try_get("cdkey_activations").unwrap_or(0),
                    active_users: row.try_get("active_users").unwrap_or(0),
                })
                .collect())
        }
        Granularity::Month => {
            let rows = sqlx::query(
                r#"SELECT
                     SUBSTR(day_utc, 1, 7) AS bucket,
                     IFNULL(SUM(api_requests), 0) AS api_requests,
                     IFNULL(SUM(api_in_bytes), 0) AS api_in_bytes,
                     IFNULL(SUM(api_out_bytes), 0) AS api_out_bytes,
                     IFNULL(SUM(new_users), 0) AS new_users,
                     IFNULL(SUM(cdkey_activations), 0) AS cdkey_activations,
                     IFNULL(SUM(active_users), 0) AS active_users
                   FROM metrics_daily
                   WHERE day_utc >= ? AND day_utc <= ?
                   GROUP BY bucket
                   ORDER BY bucket ASC"#,
            )
            .bind(start_day)
            .bind(end_day)
            .fetch_all(&state.db)
            .await?;
            Ok(rows
                .into_iter()
                .map(|row| StatsRow {
                    bucket: row.try_get("bucket").unwrap_or_default(),
                    api_requests: row.try_get("api_requests").unwrap_or(0),
                    api_in_bytes: row.try_get("api_in_bytes").unwrap_or(0),
                    api_out_bytes: row.try_get("api_out_bytes").unwrap_or(0),
                    new_users: row.try_get("new_users").unwrap_or(0),
                    cdkey_activations: row.try_get("cdkey_activations").unwrap_or(0),
                    active_users: row.try_get("active_users").unwrap_or(0),
                })
                .collect())
        }
        Granularity::Year => {
            let rows = sqlx::query(
                r#"SELECT
                     SUBSTR(day_utc, 1, 4) AS bucket,
                     IFNULL(SUM(api_requests), 0) AS api_requests,
                     IFNULL(SUM(api_in_bytes), 0) AS api_in_bytes,
                     IFNULL(SUM(api_out_bytes), 0) AS api_out_bytes,
                     IFNULL(SUM(new_users), 0) AS new_users,
                     IFNULL(SUM(cdkey_activations), 0) AS cdkey_activations,
                     IFNULL(SUM(active_users), 0) AS active_users
                   FROM metrics_daily
                   WHERE day_utc >= ? AND day_utc <= ?
                   GROUP BY bucket
                   ORDER BY bucket ASC"#,
            )
            .bind(start_day)
            .bind(end_day)
            .fetch_all(&state.db)
            .await?;
            Ok(rows
                .into_iter()
                .map(|row| StatsRow {
                    bucket: row.try_get("bucket").unwrap_or_default(),
                    api_requests: row.try_get("api_requests").unwrap_or(0),
                    api_in_bytes: row.try_get("api_in_bytes").unwrap_or(0),
                    api_out_bytes: row.try_get("api_out_bytes").unwrap_or(0),
                    new_users: row.try_get("new_users").unwrap_or(0),
                    cdkey_activations: row.try_get("cdkey_activations").unwrap_or(0),
                    active_users: row.try_get("active_users").unwrap_or(0),
                })
                .collect())
        }
    }
}

fn fill_missing_days(mut rows: Vec<StatsRow>, start_days: i64, end_days: i64) -> Vec<StatsRow> {
    let mut map = HashMap::new();
    for r in rows.drain(..) {
        map.insert(r.bucket.clone(), r);
    }

    let mut out = Vec::new();
    for day in start_days..=end_days {
        let key = metrics::format_day_utc_from_days(day);
        if let Some(r) = map.remove(&key) {
            out.push(r);
        } else {
            out.push(StatsRow {
                bucket: key,
                api_requests: 0,
                api_in_bytes: 0,
                api_out_bytes: 0,
                new_users: 0,
                cdkey_activations: 0,
                active_users: 0,
            });
        }
    }
    out
}

fn line_chart_svg(labels: &[String], values: &[i64], metric: Metric) -> String {
    let width: f64 = 900.0;
    let height: f64 = 220.0;
    let pad_x: f64 = 18.0;
    let pad_y: f64 = 18.0;

    let n = values.len().max(1) as f64;
    let max_v = values.iter().cloned().max().unwrap_or(0).max(1) as f64;

    let inner_w = (width - pad_x * 2.0).max(1.0);
    let inner_h = (height - pad_y * 2.0).max(1.0);

    let points = values
        .iter()
        .enumerate()
        .map(|(i, v)| {
            let x = if values.len() <= 1 {
                width / 2.0
            } else {
                pad_x + inner_w * (i as f64) / (n - 1.0)
            };
            let y = pad_y + inner_h * (1.0 - ((*v).max(0) as f64 / max_v));
            (x, y)
        })
        .collect::<Vec<_>>();

    let poly = points
        .iter()
        .map(|(x, y)| format!("{:.2},{:.2}", x, y))
        .collect::<Vec<_>>()
        .join(" ");

    let mut area_path = String::new();
    if let Some((x0, y0)) = points.first().copied() {
        area_path.push_str(&format!("M {:.2} {:.2} ", x0, y0));
        for (x, y) in points.iter().skip(1) {
            area_path.push_str(&format!("L {:.2} {:.2} ", x, y));
        }
        if let Some((xn, _)) = points.last().copied() {
            area_path.push_str(&format!(
                "L {:.2} {:.2} L {:.2} {:.2} Z",
                xn,
                height - pad_y,
                x0,
                height - pad_y
            ));
        }
    }

    let dots = points
        .iter()
        .enumerate()
        .map(|(i, (x, y))| {
            let label = labels.get(i).cloned().unwrap_or_default();
            let v = values.get(i).copied().unwrap_or(0);
            format!(
                r#"<circle cx="{x:.2}" cy="{y:.2}" r="3.2" fill="var(--accent)">
  <title>{title}</title>
</circle>"#,
                x = x,
                y = y,
                title = h(&format!("{label}: {}", metric.format_value(v))),
            )
        })
        .collect::<Vec<_>>()
        .join("\n");

    format!(
        r#"<svg viewBox="0 0 {w} {h}" class="w-full" role="img" aria-label="{aria}">
  <defs>
    <linearGradient id="line-fill" x1="0" x2="0" y1="0" y2="1">
      <stop offset="0%" stop-color="var(--accent-glow)" stop-opacity="0.9" />
      <stop offset="100%" stop-color="var(--accent-glow)" stop-opacity="0.08" />
    </linearGradient>
  </defs>
  <rect x="0" y="0" width="{w}" height="{h}" rx="14" fill="rgba(255,255,255,0.02)" stroke="rgba(255,255,255,0.06)"></rect>
  <path d="{area_path}" fill="url(#line-fill)"></path>
  <polyline points="{poly}" fill="none" stroke="var(--accent)" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"></polyline>
  {dots}
</svg>"#,
        w = width,
        h = height,
        aria = h(metric.label()),
        area_path = area_path,
        poly = poly,
        dots = dots,
    )
}

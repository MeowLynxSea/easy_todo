use std::net::SocketAddr;
use std::time::Duration;

use axum::extract::{ConnectInfo, OriginalUri, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::{Html, IntoResponse, Redirect, Response};
use axum::Json;
use sqlx::Row;

use crate::{
    json_error, now_ms_utc, reset_all_users_api_outbound_if_new_month, AppState, ErrorBody,
};

use super::admin_pages::admin_nav;
use super::admin_session::authenticate_admin;
use super::layout::{page_shell, stat_card};
use super::util::{format_bytes, format_number, format_uptime, h, url_encode};

pub(super) async fn admin_users_page(
    State(state): State<AppState>,
    OriginalUri(uri): OriginalUri,
    ConnectInfo(_addr): ConnectInfo<SocketAddr>,
    headers: HeaderMap,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !state.admin.enabled() {
        return Err(json_error(StatusCode::NOT_FOUND, "not found"));
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
    reset_all_users_api_outbound_if_new_month(&state.db, now_ms)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
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

    let base = state.admin.entry_path.trim_end_matches('/').to_string();
    let base_js = serde_json::to_string(&base).unwrap_or_else(|_| "\"\"".to_string());

    let body = format!(
        r#"
{nav}
<main class="mx-auto max-w-6xl px-4 pb-20 pt-14">
  <div class="space-y-3">
    <h1 class="text-3xl font-semibold tracking-tight heading-grad">用户管理</h1>
    <p class="text-sm muted">查询/修改用户配额、订阅与封禁状态</p>
  </div>

  <div class="mt-10 grid gap-4 md:grid-cols-4">
    {stat_users}
    {stat_storage}
    {stat_uptime}
  </div>

  <div class="mt-10 card p-6" data-spotlight>
    <h2 class="text-base font-semibold">用户详情</h2>
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
            <th class="px-3 py-2">本月出站</th>
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
    const v = getBytesInput(baseStorage, baseStorageUnit);
    return v === null ? null : v;
  }}

  function setBaseOutboundBytes(bytes) {{
    setBytesInput(bytes, baseOutbound, baseOutboundUnit);
  }}

  function getBaseOutboundBytes() {{
    const v = getBytesInput(baseOutbound, baseOutboundUnit);
    return v === null ? null : v;
  }}

  function pad2(n) {{
    return String(n).padStart(2, '0');
  }}

  function msToLocalInputValue(ms) {{
    const m = Number(ms || 0);
    if (!m) return '';
    const d = new Date(m);
    if (Number.isNaN(d.getTime())) return '';
    return `${{d.getFullYear()}}-${{pad2(d.getMonth() + 1)}}-${{pad2(d.getDate())}}T${{pad2(d.getHours())}}:${{pad2(d.getMinutes())}}`;
  }}

  function localInputValueToMs(value) {{
    const s = String(value || '').trim();
    if (!s) return null;
    const m = s.match(/^(\d{{4}})-(\d{{2}})-(\d{{2}})T(\d{{2}}):(\d{{2}})(?::(\d{{2}}))?/);
    if (!m) return null;
    const y = Number(m[1]);
    const mo = Number(m[2]) - 1;
    const da = Number(m[3]);
    const h = Number(m[4]);
    const mi = Number(m[5]);
    const se = Number(m[6] || '0');
    const d = new Date(y, mo, da, h, mi, se, 0);
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
    const expiresMs =
      subExpires.value === '' ? null : localInputValueToMs(subExpires.value);
    if (subExpires.value !== '' && expiresMs === null) {{
      userErr.textContent = '订阅到期时间格式无效';
      show(userErr, true);
      return;
    }}

    const payload = {{
      userId: id,
      baseStorageB64: getBaseStorageB64(),
      baseOutboundBytes: getBaseOutboundBytes(),
      subscriptionPlanId: subPlan.value === '' ? null : subPlan.value,
      subscriptionExpiresAtMsUtc: expiresMs,
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
}})();
</script>
"#,
        nav = admin_nav(&base),
        base_js = base_js,
        stat_users = stat_card("注册用户", &format_number(users_count)),
        stat_storage = stat_card("累计存储", &format_bytes(total_b64)),
        stat_uptime = stat_card("已提供服务", &format_uptime(service_duration)),
        user_rows = user_rows,
    );

    let mut resp = Html(page_shell("用户管理", &body)).into_response();
    resp.headers_mut().insert(
        axum::http::header::CACHE_CONTROL,
        axum::http::HeaderValue::from_static("no-store"),
    );
    Ok(resp)
}

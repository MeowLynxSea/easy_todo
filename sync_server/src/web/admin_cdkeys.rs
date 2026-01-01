use axum::extract::{ConnectInfo, OriginalUri, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::{Html, IntoResponse, Redirect, Response};
use axum::Json;

use crate::{json_error, AppState, ErrorBody};

use super::admin_pages::admin_nav;
use super::admin_session::authenticate_admin;
use super::layout::page_shell;
use super::util::{format_number, h, url_encode};

pub(super) async fn admin_cdkeys_page(
    State(state): State<AppState>,
    OriginalUri(uri): OriginalUri,
    headers: HeaderMap,
    ConnectInfo(addr): ConnectInfo<std::net::SocketAddr>,
) -> Result<Response, (StatusCode, Json<ErrorBody>)> {
    if !state.admin.enabled() {
        return Err(json_error(StatusCode::NOT_FOUND, "not found"));
    }

    {
        let mut limiter = state.admin_limiter.lock().await;
        if !limiter.check(&format!("admin:cdkeys:page:{}", addr.ip())) {
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

    let cdkeys_count: i64 = sqlx::query_scalar(r#"SELECT COUNT(*) FROM cdkeys"#)
        .fetch_one(&state.db)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

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

    let base = state.admin.entry_path.trim_end_matches('/').to_string();
    let base_js = serde_json::to_string(&base).unwrap_or_else(|_| "\"\"".to_string());

    let body = format!(
        r#"
{nav}
<main class="mx-auto max-w-6xl px-4 pb-20 pt-14">
  <div class="space-y-3">
    <h1 class="text-3xl font-semibold tracking-tight heading-grad">CDKEY 管理</h1>
    <p class="text-sm muted">批量生成 / 批量删除（未激活）</p>
  </div>

  <div class="mt-10 grid gap-4 md:grid-cols-4">
    <div class="card p-5" data-spotlight>
      <div class="text-xs font-medium subtle">未激活 CDKEY</div>
      <div id="stat-cdkeys" data-count="{count}" class="mt-2 text-2xl font-semibold tracking-tight">{value}</div>
    </div>
  </div>

  <div class="mt-10 card p-6" data-spotlight>
    <h2 class="text-base font-semibold">查询未激活 CDKEY</h2>
    <p class="mt-1 text-sm muted">可选按订阅方案筛选；数据为服务器当前全部未激活 CDKEY。</p>
    <div class="mt-4 grid gap-3 sm:grid-cols-[1fr_auto] sm:items-end">
      <label class="block">
        <span class="text-xs font-medium subtle">订阅方案（可选）</span>
        <select id="plan-list" class="input mt-2 text-sm">
          <option value="">全部方案</option>
          {plans}
        </select>
      </label>
      <button id="btn-list" class="btn btn-secondary h-11 w-full sm:w-auto" type="button">查询</button>
    </div>
    <p id="list-hint" class="mt-3 hidden text-sm text-emerald-700 dark:text-emerald-300"></p>
    <p id="list-error" class="mt-3 hidden text-sm text-rose-600 dark:text-rose-400"></p>
    <textarea id="list-output" class="codeblock mt-4 hidden h-56 w-full font-mono text-xs" spellcheck="false"></textarea>
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
      <div class="mt-4 grid gap-3 sm:grid-cols-3">
        <label class="block">
          <span class="text-xs font-medium subtle">订阅方案</span>
          <select id="plan-delete" class="input mt-2 text-sm">
            {plans}
          </select>
        </label>
        <label class="block">
          <span class="text-xs font-medium subtle">数量（留空=全部）</span>
          <input id="count-delete" type="number" min="1" max="2000" class="input mt-2 text-sm" placeholder="全部" />
        </label>
        <div class="flex items-end">
          <button id="btn-delete" class="btn btn-secondary h-11 w-full" type="button">删除</button>
        </div>
      </div>
      <p id="del-hint" class="mt-3 hidden text-sm text-emerald-700 dark:text-emerald-300"></p>
      <p id="del-error" class="mt-3 hidden text-sm text-rose-600 dark:text-rose-400"></p>
      <textarea id="del-output" class="codeblock mt-4 hidden h-56 w-full font-mono text-xs" spellcheck="false"></textarea>
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
  const inputDelCount = document.getElementById('count-delete');
  const btnDel = document.getElementById('btn-delete');
  const delHint = document.getElementById('del-hint');
  const delErr = document.getElementById('del-error');
  const delOut = document.getElementById('del-output');

  const selList = document.getElementById('plan-list');
  const btnList = document.getElementById('btn-list');
  const listHint = document.getElementById('list-hint');
  const listErr = document.getElementById('list-error');
  const listOut = document.getElementById('list-output');

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
    show(delOut, false);
    delOut.value = '';
    try {{
      const raw = String(inputDelCount?.value || '').trim();
      let count = null;
      if (raw) {{
        const n = Number(raw);
        if (!Number.isFinite(n) || n <= 0) {{
          throw new Error('数量必须是正整数');
        }}
        count = Math.min(2000, Math.floor(n));
      }}
      const data = await postJson(`${{base}}/api/cdkeys/delete`, {{
        planId: selDel?.value || '',
        count,
      }});
      const codes = Array.isArray(data.codes) ? data.codes : [];
      const deleted = Number(data.deleted || codes.length || 0);
      delHint.textContent = count
        ? `已删除 ${{deleted}} 个 CDKEY（请求删除 ${{count}} 个）`
        : `已删除 ${{deleted}} 个 CDKEY`;
      show(delHint, true);
      delOut.value = codes.map((s) => String(s || '').trim()).filter(Boolean).join('\n');
      show(delOut, true);
      cdkeysCount = Math.max(0, cdkeysCount - deleted);
      renderCdkeysCount();
    }} catch (e) {{
      delErr.textContent = e?.message || 'delete failed';
      show(delErr, true);
    }}
  }});

  btnList?.addEventListener('click', async () => {{
    show(listHint, false);
    show(listErr, false);
    show(listOut, false);
    listOut.value = '';

    const planId = String(selList?.value || '').trim();
    const qs = planId ? `?planId=${{encodeURIComponent(planId)}}` : '';

    btnList.disabled = true;
    btnList.classList.add('opacity-50');
    try {{
      const resp = await fetch(`${{base}}/api/cdkeys/list${{qs}}`, {{
        method: 'GET',
        credentials: 'same-origin',
      }});
      const data = await resp.json().catch(() => ({{}}));
      if (!resp.ok) throw new Error(data.error || 'list failed');
      const items = Array.isArray(data.cdkeys) ? data.cdkeys : [];
      const lines = [];
      for (const it of items) {{
        const code = String(it.code || '').trim();
        const pid = String(it.planId || '').trim();
        if (!code) continue;
        if (planId) {{
          lines.push(code);
        }} else {{
          lines.push(pid ? `${{code}}\t${{pid}}` : code);
        }}
      }}
      listOut.value = lines.join('\n');
      listHint.textContent = planId
        ? `共 ${{lines.length}} 个未激活 CDKEY（方案：${{planId}}）`
        : `共 ${{lines.length}} 个未激活 CDKEY`;
      show(listHint, true);
      show(listOut, true);
    }} catch (e) {{
      listErr.textContent = e?.message || 'list failed';
      show(listErr, true);
    }} finally {{
      btnList.disabled = false;
      btnList.classList.remove('opacity-50');
    }}
  }});

  renderCdkeysCount();
}})();
</script>
"#,
        nav = admin_nav(&base),
        base_js = base_js,
        count = cdkeys_count,
        value = h(&format_number(cdkeys_count)),
        plans = plans,
    );

    let mut resp = Html(page_shell("CDKEY 管理", &body)).into_response();
    resp.headers_mut().insert(
        axum::http::header::CACHE_CONTROL,
        axum::http::HeaderValue::from_static("no-store"),
    );
    Ok(resp)
}

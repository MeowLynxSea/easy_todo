use axum::response::Response;

use super::util::h;

pub(super) fn page_shell(title: &str, body: &str) -> String {
    let title = h(title);
    format!(
        r#"<!doctype html>
<html lang="zh" class="h-full">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{title}</title>
  <script>
  (() => {{
    const stored = localStorage.getItem('theme');
    const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
    if (stored === 'dark' || (!stored && prefersDark)) {{
      document.documentElement.classList.add('dark');
    }}
  }})();
  </script>
  <script src="https://cdn.tailwindcss.com"></script>
  <script>tailwind.config = {{ darkMode: 'class' }};</script>
</head>
<body class="h-full antialiased">
{body}
<script>
(() => {{
  const btn = document.getElementById('theme-toggle');
  btn?.addEventListener('click', () => {{
    const root = document.documentElement;
    const dark = root.classList.toggle('dark');
    localStorage.setItem('theme', dark ? 'dark' : 'light');
  }});
}})();
</script>
</body>
</html>"#,
        title = title,
        body = body
    )
}

pub(super) fn nav_bar(active: Option<&str>) -> String {
    let active = active.unwrap_or("");
    format!(
        r#"<header class="border-b border-slate-200 bg-white/70 backdrop-blur dark:border-slate-800 dark:bg-slate-950/60">
  <div class="mx-auto flex max-w-5xl items-center justify-between px-4 py-4">
    <div class="flex items-center gap-3">
      <a href="/" class="text-sm font-semibold tracking-tight">轻单 同步服务</a>
      <span class="text-xs text-slate-400 dark:text-slate-500">{active}</span>
    </div>
    <div class="flex items-center gap-2">
      <a class="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-semibold hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:hover:bg-slate-800" href="/dashboard">仪表盘</a>
      <button id="theme-toggle" class="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm font-semibold hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:hover:bg-slate-800" type="button">
        明/暗
      </button>
    </div>
  </div>
</header>"#,
        active = h(active)
    )
}

pub(super) fn stat_card(label: &str, value: &str) -> String {
    format!(
        r#"<div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
  <div class="text-xs font-medium text-slate-500 dark:text-slate-400">{label}</div>
  <div class="mt-2 text-2xl font-semibold tracking-tight">{value}</div>
</div>"#,
        label = h(label),
        value = h(value)
    )
}

pub(super) fn stat_card_ms(label: &str, ms: i64, id: &str) -> String {
    format!(
        r#"<div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
  <div class="text-xs font-medium text-slate-500 dark:text-slate-400">{label}</div>
  <div id="{id}" data-ms="{ms}" class="mt-2 text-sm font-semibold tracking-tight text-slate-700 dark:text-slate-200">—</div>
</div>"#,
        label = h(label),
        id = h(id),
        ms = ms
    )
}

pub(super) fn stat_card_ms_opt(label: &str, ms: Option<i64>, id: &str) -> String {
    let ms = ms.unwrap_or(0);
    format!(
        r#"<div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-slate-900">
  <div class="text-xs font-medium text-slate-500 dark:text-slate-400">{label}</div>
  <div id="{id}" data-ms="{ms}" class="mt-2 text-sm font-semibold tracking-tight text-slate-700 dark:text-slate-200">—</div>
</div>"#,
        label = h(label),
        id = h(id),
        ms = ms
    )
}

pub(super) fn see_other(location: &str) -> Response {
    super::util::see_other(location)
}

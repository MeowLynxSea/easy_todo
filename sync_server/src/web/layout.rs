use axum::response::Response;

use super::util::h;

const GLOBAL_CSS: &str = r#"
:root {
  --bg-deep: #f3f4fb;
  --bg-base: #f8fafc;
  --bg-elevated: #ffffff;
  --surface: rgba(0,0,0,0.03);
  --surface-hover: rgba(0,0,0,0.05);
  --foreground: #0b0b10;
  --foreground-muted: rgba(17,24,39,0.70);
  --foreground-subtle: rgba(17,24,39,0.55);
  --accent: #5E6AD2;
  --accent-bright: #6872D9;
  --accent-glow: rgba(94,106,210,0.22);
  --border-default: rgba(17,24,39,0.10);
  --border-hover: rgba(17,24,39,0.16);
  --border-accent: rgba(94,106,210,0.30);
  --ease-expo: cubic-bezier(0.16, 1, 0.3, 1);
  --dur-quick: 200ms;
  --dur: 300ms;
}
html.dark {
  --bg-deep: #020203;
  --bg-base: #050506;
  --bg-elevated: #0a0a0c;
  --surface: rgba(255,255,255,0.05);
  --surface-hover: rgba(255,255,255,0.08);
  --foreground: #EDEDEF;
  --foreground-muted: #8A8F98;
  --foreground-subtle: rgba(255,255,255,0.60);
  --accent: #5E6AD2;
  --accent-bright: #6872D9;
  --accent-glow: rgba(94,106,210,0.30);
  --border-default: rgba(255,255,255,0.06);
  --border-hover: rgba(255,255,255,0.10);
  --border-accent: rgba(94,106,210,0.30);
}

html { color-scheme: light; }
html.dark { color-scheme: dark; }
body {
  margin: 0;
  background: var(--bg-base);
  color: var(--foreground);
  font-family: Inter, ui-sans-serif, system-ui, -apple-system, Segoe UI, Roboto, Helvetica,
    Arial, "Apple Color Emoji", "Segoe UI Emoji";
  text-rendering: geometricPrecision;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
a { color: inherit; }
::selection { background: rgba(94,106,210,0.35); color: var(--foreground); }

.app-root { position: relative; min-height: 100vh; isolation: isolate; }
.app-content { position: relative; z-index: 10; min-height: 100vh; }
.app-bg { position: absolute; inset: 0; overflow: hidden; pointer-events: none; z-index: 0; }
.app-bg-base {
  position: absolute;
  inset: 0;
  background: radial-gradient(ellipse at top, #ffffff 0%, #f3f4fb 45%, #eef0f7 100%);
}
html.dark .app-bg-base {
  background: radial-gradient(ellipse at top, #0a0a0f 0%, #050506 50%, #020203 100%);
}
.app-grid {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(to right, rgba(17,24,39,0.06) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(17,24,39,0.06) 1px, transparent 1px);
  background-size: 64px 64px;
  opacity: 0.05;
  mask-image: radial-gradient(ellipse at top, rgba(0,0,0,0.55), transparent 70%);
}
html.dark .app-grid {
  background-image:
    linear-gradient(to right, rgba(255,255,255,0.04) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(255,255,255,0.04) 1px, transparent 1px);
  opacity: 0.20;
}
.app-noise {
  position: absolute;
  inset: 0;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='200' height='200'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.7' numOctaves='3' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='200' height='200' filter='url(%23n)' opacity='.32'/%3E%3C/svg%3E");
  opacity: 0.03;
  mix-blend-mode: overlay;
}
html.dark .app-noise { opacity: 0.015; }

.blob {
  position: absolute;
  border-radius: 9999px;
  filter: blur(140px);
  transform: translate3d(0,0,0);
  opacity: 0.9;
  animation: float 9000ms ease-in-out infinite;
}
html.dark .blob { opacity: 0.75; }
.blob-1 {
  width: 900px;
  height: 1400px;
  left: 50%;
  top: -720px;
  margin-left: -450px;
  background: radial-gradient(circle at 35% 25%, rgba(94,106,210,0.28), transparent 60%);
}
.blob-2 {
  width: 640px;
  height: 860px;
  left: -220px;
  top: 180px;
  background: radial-gradient(circle at 40% 30%, rgba(168,85,247,0.18), transparent 62%);
  animation-duration: 10000ms;
}
.blob-3 {
  width: 520px;
  height: 760px;
  right: -240px;
  top: 340px;
  background: radial-gradient(circle at 35% 30%, rgba(99,102,241,0.16), transparent 62%);
  animation-duration: 8000ms;
}
.blob-4 {
  width: 680px;
  height: 680px;
  left: 20%;
  bottom: -420px;
  background: radial-gradient(circle at 35% 30%, rgba(94,106,210,0.14), transparent 62%);
  animation-duration: 12000ms;
}
@keyframes float {
  0%, 100% { transform: translateY(0) rotate(0deg); }
  50% { transform: translateY(-20px) rotate(1deg); }
}

.heading-grad {
  background: linear-gradient(to bottom, rgba(255,255,255,1), rgba(255,255,255,0.72));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
html:not(.dark) .heading-grad { color: var(--foreground); background: none; }
.parallax-hero { will-change: transform, opacity; transform-origin: top center; }

.card {
  position: relative;
  border-radius: 16px;
  border: 1px solid var(--border-default);
  background: linear-gradient(to bottom, rgba(255,255,255,0.70), rgba(255,255,255,0.40));
  box-shadow:
    0 0 0 1px rgba(17,24,39,0.06),
    0 10px 30px rgba(2,6,23,0.10);
  transition:
    transform var(--dur) var(--ease-expo),
    box-shadow var(--dur) var(--ease-expo),
    border-color var(--dur-quick) var(--ease-expo),
    background var(--dur) var(--ease-expo);
}
html.dark .card {
  background: linear-gradient(to bottom, rgba(255,255,255,0.08), rgba(255,255,255,0.02));
  box-shadow:
    0 0 0 1px rgba(255,255,255,0.06),
    0 2px 20px rgba(0,0,0,0.40),
    0 0 40px rgba(0,0,0,0.20);
}
.card:hover {
  transform: translateY(-4px);
  border-color: var(--border-hover);
  box-shadow:
    0 0 0 1px rgba(17,24,39,0.12),
    0 18px 45px rgba(2,6,23,0.14);
}
html.dark .card:hover {
  box-shadow:
    0 0 0 1px rgba(255,255,255,0.10),
    0 8px 40px rgba(0,0,0,0.50),
    0 0 80px rgba(94,106,210,0.10);
}
.card:focus-visible {
  outline: none;
  box-shadow:
    0 0 0 2px rgba(94,106,210,0.45),
    0 0 0 4px rgba(5,5,6,0.85),
    0 0 0 1px rgba(17,24,39,0.10),
    0 18px 45px rgba(2,6,23,0.12);
}
html.dark .card:focus-visible {
  box-shadow:
    0 0 0 2px rgba(94,106,210,0.45),
    0 0 0 4px rgba(5,5,6,0.85),
    0 0 0 1px rgba(255,255,255,0.10),
    0 8px 40px rgba(0,0,0,0.50),
    0 0 80px rgba(94,106,210,0.10);
}
html:not(.dark) .card:focus-visible {
  box-shadow:
    0 0 0 2px rgba(94,106,210,0.35),
    0 0 0 4px rgba(255,255,255,0.90),
    0 0 0 1px rgba(17,24,39,0.10),
    0 18px 45px rgba(2,6,23,0.12);
}
.card::after {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: inherit;
  pointer-events: none;
  opacity: 0;
  transition: opacity var(--dur-quick) var(--ease-expo);
  background: linear-gradient(to bottom, rgba(94,106,210,0.20), transparent 45%);
}
.card:hover::after { opacity: 1; }

[data-spotlight]::before {
  content: "";
  position: absolute;
  inset: -1px;
  border-radius: inherit;
  pointer-events: none;
  opacity: 0;
  transition: opacity var(--dur-quick) var(--ease-expo);
  background: radial-gradient(
    300px circle at var(--mx, 50%) var(--my, 50%),
    var(--accent-glow),
    transparent 60%
  );
}
[data-spotlight]:hover::before { opacity: 1; }

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  border-radius: 10px;
  padding: 0.55rem 0.95rem;
  font-size: 0.875rem;
  font-weight: 600;
  line-height: 1.2;
  transition:
    transform var(--dur-quick) var(--ease-expo),
    box-shadow var(--dur) var(--ease-expo),
    background var(--dur-quick) var(--ease-expo),
    border-color var(--dur-quick) var(--ease-expo),
    color var(--dur-quick) var(--ease-expo);
  user-select: none;
  -webkit-tap-highlight-color: transparent;
}
.btn-icon {
  padding: 0.55rem;
  width: 2.5rem;
  height: 2.5rem;
}
.icon {
  width: 18px;
  height: 18px;
  display: block;
}
.theme-icon-sun { display: none; }
html.dark .theme-icon-sun { display: block; }
html.dark .theme-icon-moon { display: none; }
.mobile-menu-btn .icon-close { display: none; }
.mobile-menu-btn[data-open="1"] .icon-menu { display: none; }
.mobile-menu-btn[data-open="1"] .icon-close { display: block; }

.btn:active { transform: scale(0.98); }
.btn:disabled { opacity: 0.5; cursor: not-allowed; }
.btn:focus-visible {
  outline: none;
  box-shadow: 0 0 0 2px rgba(94,106,210,0.45), 0 0 0 4px rgba(5,5,6,0.85);
}
html:not(.dark) .btn:focus-visible {
  box-shadow: 0 0 0 2px rgba(94,106,210,0.35), 0 0 0 4px rgba(255,255,255,0.90);
}
.btn-primary {
  background: var(--accent);
  color: #ffffff;
  box-shadow:
    0 0 0 1px rgba(94,106,210,0.50),
    0 8px 22px rgba(94,106,210,0.22),
    inset 0 1px 0 rgba(255,255,255,0.18);
}
.btn-primary:hover { background: var(--accent-bright); }
.btn-secondary {
  background: var(--surface);
  color: var(--foreground);
  border: 1px solid var(--border-default);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.06);
}
.btn-secondary:hover { background: var(--surface-hover); border-color: var(--border-hover); }
.btn-ghost {
  background: transparent;
  color: var(--foreground-muted);
}
.btn-ghost:hover { background: var(--surface); color: var(--foreground); }

.input {
  width: 100%;
  border-radius: 10px;
  border: 1px solid rgba(17,24,39,0.12);
  background: rgba(255,255,255,0.85);
  padding: 0.75rem 1rem;
  color: var(--foreground);
  outline: none;
  transition:
    border-color var(--dur-quick) var(--ease-expo),
    box-shadow var(--dur-quick) var(--ease-expo),
    background var(--dur-quick) var(--ease-expo);
}
html.dark .input {
  border-color: rgba(255,255,255,0.10);
  background: #0F0F12;
  color: var(--foreground);
}
.input::placeholder { color: var(--foreground-subtle); }
.input:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 3px rgba(94,106,210,0.22);
}

.mobile-menu-overlay { display: none; }
.mobile-menu-overlay[data-open="1"] { display: block; }
.mobile-menu-backdrop {
  opacity: 0;
  transition: opacity var(--dur) var(--ease-expo);
}
.mobile-menu-panel {
  opacity: 0;
  transform: translateY(-8px) scale(0.98);
  transition:
    opacity var(--dur) var(--ease-expo),
    transform var(--dur) var(--ease-expo);
}
.mobile-menu-overlay[data-open="1"] .mobile-menu-backdrop { opacity: 1; }
.mobile-menu-overlay[data-open="1"] .mobile-menu-panel {
  opacity: 1;
  transform: translateY(0) scale(1);
}
.mobile-menu-inner {
  padding-bottom: calc(1rem + env(safe-area-inset-bottom));
}

.kbd {
  border-radius: 8px;
  border: 1px solid var(--border-default);
  background: var(--surface);
  padding: 0.1rem 0.4rem;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono",
    "Courier New", monospace;
  font-size: 0.8em;
}

.muted { color: var(--foreground-muted); }
.subtle { color: var(--foreground-subtle); }

.badge {
  display: inline-flex;
  align-items: center;
  border-radius: 9999px;
  border: 1px solid var(--border-accent);
  background: rgba(94,106,210,0.10);
  padding: 0.15rem 0.55rem;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.02em;
  color: var(--foreground);
}
html:not(.dark) .badge { background: rgba(94,106,210,0.08); }

.icon-chip {
  display: inline-flex;
  height: 2.5rem;
  width: 2.5rem;
  align-items: center;
  justify-content: center;
  border-radius: 12px;
  border: 1px solid var(--border-default);
  background: var(--surface);
  color: var(--foreground);
  box-shadow: inset 0 1px 0 rgba(255,255,255,0.08);
}

.subcard {
  border-radius: 12px;
  border: 1px solid var(--border-default);
  background: var(--surface);
  padding: 1rem;
}

.codeblock {
  border-radius: 12px;
  border: 1px solid var(--border-default);
  background: rgba(255,255,255,0.65);
  padding: 1rem;
  color: var(--foreground);
}
html.dark .codeblock { background: rgba(255,255,255,0.03); }
.codeblock:focus {
  outline: none;
  border-color: var(--accent);
  box-shadow: 0 0 0 3px rgba(94,106,210,0.18);
}

.table-wrap {
  border-radius: 12px;
  border: 1px solid var(--border-default);
  background: rgba(255,255,255,0.55);
  overflow: hidden;
  -webkit-overflow-scrolling: touch;
}
html.dark .table-wrap { background: rgba(255,255,255,0.02); }
.table { border-collapse: collapse; }
.table thead tr { border-bottom: 1px solid var(--border-default); }
.table-row { border-top: 1px solid var(--border-default); }
.table-row:hover { background: var(--surface); }

.input-danger:focus {
  border-color: rgba(244,63,94,0.95);
  box-shadow: 0 0 0 3px rgba(244,63,94,0.22);
}

.card-static:hover { transform: none; }
.card-static:hover::after { opacity: 0; }
.card-static[data-spotlight]:hover::before { opacity: 0; }

.link {
  color: var(--foreground-muted);
  text-decoration: underline;
  text-decoration-color: rgba(94,106,210,0.35);
  text-underline-offset: 4px;
  transition: color var(--dur-quick) var(--ease-expo);
}
.link:hover { color: var(--foreground); }

.btn-danger {
  background: rgba(244,63,94,0.90);
  color: #ffffff;
  box-shadow:
    0 0 0 1px rgba(244,63,94,0.30),
    0 10px 26px rgba(244,63,94,0.16),
    inset 0 1px 0 rgba(255,255,255,0.14);
}
.btn-danger:hover { background: rgba(244,63,94,1.0); }

.nav-shell {
  border-bottom: 1px solid var(--border-default);
  background: rgba(255,255,255,0.65);
  backdrop-filter: blur(18px);
}
html.dark .nav-shell { background: rgba(5,5,6,0.60); }
.nav-brand { border-radius: 12px; }
.nav-brand:focus-visible {
  outline: none;
  box-shadow: 0 0 0 2px rgba(94,106,210,0.40), 0 0 0 4px rgba(5,5,6,0.85);
}
html:not(.dark) .nav-brand:focus-visible {
  box-shadow: 0 0 0 2px rgba(94,106,210,0.30), 0 0 0 4px rgba(255,255,255,0.90);
}

@media (max-width: 768px) {
  .input { font-size: 16px; }
}

@media (hover: none) {
  .card:hover { transform: none; }
  .card:hover::after { opacity: 0; }
  [data-spotlight]:hover::before { opacity: 0; }
}

@media (prefers-reduced-motion: reduce) {
  .blob { animation: none !important; }
  .card, .btn, .input { transition-duration: 0.01ms !important; }
  .card:hover { transform: none; }
}
"#;

const GLOBAL_JS: &str = r#"
(() => {
  for (const btn of document.querySelectorAll('[data-theme-toggle]')) {
    btn.addEventListener('click', () => {
      const root = document.documentElement;
      const dark = root.classList.toggle('dark');
      localStorage.setItem('theme', dark ? 'dark' : 'light');
    }, { passive: true });
  }

  const mobileMenus = [];
  for (const btn of document.querySelectorAll('[data-mobile-menu-btn]')) {
    const id = btn.getAttribute('aria-controls') || '';
    if (!id) continue;
    const overlay = document.getElementById(id);
    if (!overlay) continue;
    mobileMenus.push({ btn, overlay });

    const setOpen = (open) => {
      overlay.dataset.open = open ? '1' : '0';
      overlay.setAttribute('aria-hidden', open ? 'false' : 'true');
      btn.dataset.open = open ? '1' : '0';
      btn.setAttribute('aria-expanded', open ? 'true' : 'false');
      document.body.style.overflow = open ? 'hidden' : '';
      if (open) {
        const focusTarget = overlay.querySelector('a, button, input, select, textarea, [tabindex]:not([tabindex=\"-1\"])');
        focusTarget?.focus?.();
      }
    };

    setOpen(false);

    btn.addEventListener('click', () => {
      const open = overlay.dataset.open === '1';
      setOpen(!open);
    });

    overlay.addEventListener('click', (e) => {
      const target = e.target;
      if (!(target instanceof Element)) return;
      if (target.closest('[data-mobile-menu-close]')) setOpen(false);
    });

    for (const el of overlay.querySelectorAll('[data-mobile-menu-link]')) {
      el.addEventListener('click', () => setOpen(false));
    }
  }

  document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;
    for (const { btn, overlay } of mobileMenus) {
      if (overlay.dataset.open !== '1') continue;
      overlay.dataset.open = '0';
      overlay.setAttribute('aria-hidden', 'true');
      btn.dataset.open = '0';
      btn.setAttribute('aria-expanded', 'false');
      document.body.style.overflow = '';
    }
  });

  const reduced = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (!reduced) {
    for (const el of document.querySelectorAll('[data-spotlight]')) {
      let rect = null;
      const update = () => { rect = el.getBoundingClientRect(); };
      el.addEventListener('pointerenter', update, { passive: true });
      el.addEventListener('pointermove', (e) => {
        if (!rect) update();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        el.style.setProperty('--mx', `${x}px`);
        el.style.setProperty('--my', `${y}px`);
      }, { passive: true });
      el.addEventListener('pointerleave', () => {
        rect = null;
        el.style.removeProperty('--mx');
        el.style.removeProperty('--my');
      }, { passive: true });
    }

    const heroes = document.querySelectorAll('[data-parallax-hero]');
    if (heroes.length) {
      let ticking = false;
      const updateHero = () => {
        ticking = false;
        const max = Math.max(1, window.innerHeight * 0.5);
        const y = Math.max(0, window.scrollY || 0);
        const t = Math.min(1, y / max);
        const opacity = String(1 - t);
        const translate = (t * 100).toFixed(2);
        const scale = (1 - t * 0.05).toFixed(4);
        for (const hero of heroes) {
          hero.style.opacity = opacity;
          hero.style.transform = `translateY(${translate}px) scale(${scale})`;
        }
      };
      const onScroll = () => {
        if (ticking) return;
        ticking = true;
        requestAnimationFrame(updateHero);
      };
      updateHero();
      window.addEventListener('scroll', onScroll, { passive: true });
      window.addEventListener('resize', onScroll, { passive: true });
    }
  }
})();
"#;

pub(super) fn page_shell(title: &str, body: &str) -> String {
    let title = h(title);
    format!(
        r#"<!doctype html>
<html lang="zh" class="h-full">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <meta name="color-scheme" content="dark light" />
  <link rel="icon" type="image/png" href="/favicon.png" />
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
  <style>{css}</style>
</head>
<body class="h-full antialiased">
<div class="app-root">
  <div class="app-bg" aria-hidden="true">
    <div class="app-bg-base"></div>
    <div class="blob blob-1"></div>
    <div class="blob blob-2"></div>
    <div class="blob blob-3"></div>
    <div class="blob blob-4"></div>
    <div class="app-grid"></div>
    <div class="app-noise"></div>
  </div>
  <div class="app-content">
{body}
  </div>
</div>
<script>{js}</script>
</body>
</html>"#,
        title = title,
        body = body,
        css = GLOBAL_CSS,
        js = GLOBAL_JS
    )
}

pub(super) fn nav_bar(active: Option<&str>) -> String {
    let active = active.unwrap_or("");
    let badge = if active.trim().is_empty() {
        String::new()
    } else {
        format!(
            r#"<span class="badge hidden sm:inline-flex">{}</span>"#,
            h(active)
        )
    };
    format!(
        r#"<header class="nav-shell sticky top-0 z-50">
  <div class="mx-auto flex max-w-5xl items-center justify-between gap-3 px-4 py-4">
    <div class="flex min-w-0 items-center gap-3">
      <a href="/" class="nav-brand flex min-w-0 items-center gap-3 text-sm font-semibold tracking-tight">
        <span class="icon-chip" aria-hidden="true">⎈</span>
        <span class="truncate">轻单 同步服务</span>
      </a>
      {badge}
    </div>
    <div class="flex items-center gap-2">
      <div class="hidden md:flex items-center gap-2">
        <a class="btn btn-secondary" href="/dashboard">仪表盘</a>
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
      <button class="btn btn-secondary btn-icon mobile-menu-btn md:hidden" type="button" aria-label="打开菜单" aria-controls="mobile-menu" aria-expanded="false" data-mobile-menu-btn data-open="0">
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

<div id="mobile-menu" class="mobile-menu-overlay fixed inset-0 z-[60] md:hidden" data-open="0" aria-hidden="true">
  <div class="mobile-menu-backdrop absolute inset-0 bg-black/60 backdrop-blur-xl" data-mobile-menu-close></div>
  <div class="relative mx-auto max-w-5xl px-4 pt-20">
    <div class="card card-static mobile-menu-panel mobile-menu-inner p-4" role="dialog" aria-modal="true" aria-label="菜单">
      <div class="flex items-center justify-between gap-3">
        <div class="text-xs font-mono tracking-widest subtle">MENU</div>
        <button class="btn btn-ghost btn-icon" type="button" aria-label="关闭菜单" data-mobile-menu-close>
          <svg class="icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M18 6L6 18M6 6l12 12"></path>
          </svg>
        </button>
      </div>

      <div class="mt-4 grid gap-2">
        <a class="btn btn-primary w-full" href="/dashboard" data-mobile-menu-link>进入仪表盘</a>
        <a class="btn btn-secondary w-full" href="/" data-mobile-menu-link>返回主页</a>
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
        badge = badge
    )
}

pub(super) fn stat_card(label: &str, value: &str) -> String {
    format!(
        r#"<div class="card p-5" data-spotlight>
  <div class="text-xs font-medium subtle">{label}</div>
  <div class="mt-2 text-2xl font-semibold tracking-tight">{value}</div>
</div>"#,
        label = h(label),
        value = h(value)
    )
}

pub(super) fn stat_card_ms(label: &str, ms: i64, id: &str) -> String {
    format!(
        r#"<div class="card p-5" data-spotlight>
  <div class="text-xs font-medium subtle">{label}</div>
  <div id="{id}" data-ms="{ms}" class="mt-2 text-sm font-semibold tracking-tight">—</div>
</div>"#,
        label = h(label),
        id = h(id),
        ms = ms
    )
}

pub(super) fn stat_card_ms_opt(label: &str, ms: Option<i64>, id: &str) -> String {
    let ms = ms.unwrap_or(0);
    format!(
        r#"<div class="card p-5" data-spotlight>
  <div class="text-xs font-medium subtle">{label}</div>
  <div id="{id}" data-ms="{ms}" class="mt-2 text-sm font-semibold tracking-tight">—</div>
</div>"#,
        label = h(label),
        id = h(id),
        ms = ms
    )
}

pub(super) fn see_other(location: &str) -> Response {
    super::util::see_other(location)
}

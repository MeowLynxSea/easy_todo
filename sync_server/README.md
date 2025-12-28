# Easy Todo Sync Server

Rust `axum` sync server for Easy Todo E2EE sync protocol.

## Run (SQLite)

```bash
cd sync_server
export DATABASE_URL="sqlite://./sync.db"
cargo run
```

## Auth modes

### Production mode (OAuth + SyncServer tokens)

Configure an OAuth provider. The client only holds the
sync server’s `accessToken`/`refreshToken` (the sync server holds provider tokens
server-side only during login).

Key env vars:

- `BASE_URL=https://your-server.example.com`
- Register this redirect/callback URL in your OAuth provider: `BASE_URL/v1/auth/callback`
- `JWT_SECRET=...` (HS256)
- `TOKEN_PEPPER=...` (hashing refresh tokens & tickets)
- `APP_REDIRECT_ALLOWLIST=easy_todo://auth,https://your-web.example.com/auth/callback`
- `AUTH_PROVIDERS=your_provider_name` (comma-separated allowlist; defaults to all configured)
- `OAUTH_PROVIDERS_JSON=[{...}, {...}]` (see `sync_server/.env.example`; when exporting via shell/systemd, wrap the whole JSON in single quotes)

### Custom providers (no hardcoding)

Providers are fully config-driven via `OAUTH_PROVIDERS_JSON`.

Important fields:

- `authorizeUrl`: provider authorization endpoint (full URL, usually ends with `/authorize`)
- `tokenUrl`: provider token endpoint
- `userinfoUrl`: provider profile endpoint (returns JSON)
- `scope`: provider scopes (optional; provider-specific)
- `idField`: JSON dot-path for a stable unique user id in `userinfoUrl` response (default: `id`)
- `accessTokenField`: token response field name (default: `access_token`)
- `extraAuthorizeParams`: extra query params appended to `authorizeUrl` (optional)
- `extraTokenParams`: extra form params appended to `tokenUrl` request (optional)
- `tokenAuthMethod`: `"basic"` (default) or `"post"`

Linux.do example profile payload:

```json
{"id":1189,"username":"Reno", "...": "..."}
```

Use `idField: "id"` (numeric id is fine; it will be stringified for storage).

OAuth endpoints:

- `GET /v1/auth/providers` (public; lists configured providers)
- `GET /v1/auth/start?provider=your_provider_name&app_redirect=easy_todo://auth&client=easy_todo`
- `GET /v1/auth/web/start?provider=your_provider_name&return_to=/dashboard` (OAuth login for server web dashboard)
- `GET /v1/auth/callback?code=...&state=...` (returns minimal HTML “login success → return to app”)
- `POST /v1/auth/exchange` `{ "ticket": "..." }` → `{ accessToken, expiresIn, refreshToken }`
- `POST /v1/auth/refresh` `{ "refreshToken": "..." }` → rotated `{ accessToken, expiresIn, refreshToken }`
- `POST /v1/auth/logout` `{ "refreshToken": "..." }` → revokes session (access tokens become invalid immediately)

Sync endpoints (require `Authorization: Bearer <accessToken>`):

- `GET /v1/key-bundle`
- `PUT /v1/key-bundle`
- `POST /v1/sync/push`
- `GET /v1/sync/pull?since=<serverSeq>&limit=<n>`

## Web UI

- `GET /` renders a minimal home page with the configured `BASE_URL` to copy into the app’s sync server setting.
- `GET /dashboard` renders a minimal dashboard (OAuth login required; uses HttpOnly cookies).
- `GET /dashboard/login` provider picker for the dashboard.

Notes:

- Set `BASE_URL` to your actual public origin (scheme + host + optional port). If you deploy behind a proxy, make sure it matches what users see in the browser.
- If `BASE_URL` is `https://...`, dashboard cookies are marked `Secure`.
- Optional: set `SITE_CREATED_AT_MS_UTC=<unix_ms>` to show “service age” on the home page (otherwise it shows process uptime).

## Notes

- Server stores only plaintext metadata + encrypted payload (`nonce`/`ciphertext`).
- Conflict resolution is HLC-based: only accepts updates with strictly newer HLC.
- `serverSeq` is per-user and increments only for accepted writes.

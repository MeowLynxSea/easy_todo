# Easy Todo Sync Server (MVP)

Rust `axum` sync server for Easy Todo E2EE sync protocol.

## Run (SQLite)

```bash
cd sync_server
export DATABASE_URL="sqlite://./sync.db"
cargo run
```

Then call:

- `GET /v1/key-bundle`
- `PUT /v1/key-bundle`
- `POST /v1/sync/push`
- `GET /v1/sync/pull?since=<serverSeq>&limit=<n>`

## Temporary auth (dev)

Send `Authorization: Bearer <token>`.

The server treats the bearer token as a stable user identifier (like `oauth_sub`)
and auto-creates the user row on first request.

## Notes

- Server stores only plaintext metadata + encrypted payload (`nonce`/`ciphertext`).
- Conflict resolution is HLC-based: only accepts updates with strictly newer HLC.
- `serverSeq` is per-user and increments only for accepted writes.

PRAGMA foreign_keys = OFF;

-- Rebuild users table to allow multiple OAuth providers.
CREATE TABLE IF NOT EXISTS users_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  oauth_provider TEXT NOT NULL,
  oauth_sub TEXT NOT NULL,
  created_at_ms_utc INTEGER NOT NULL,
  UNIQUE (oauth_provider, oauth_sub)
);

INSERT INTO users_new (id, oauth_provider, oauth_sub, created_at_ms_utc)
SELECT id, oauth_provider, oauth_sub, created_at_ms_utc
FROM users;

DROP TABLE users;
ALTER TABLE users_new RENAME TO users;

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS auth_login_attempts (
  state TEXT PRIMARY KEY,
  provider TEXT NOT NULL,
  app_redirect TEXT NOT NULL,
  client TEXT NOT NULL,
  created_at_ms_utc INTEGER NOT NULL,
  expires_at_ms_utc INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS auth_tickets (
  ticket_hash TEXT PRIMARY KEY,
  user_id INTEGER NOT NULL,
  created_at_ms_utc INTEGER NOT NULL,
  expires_at_ms_utc INTEGER NOT NULL,
  consumed_at_ms_utc INTEGER,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  token_hash TEXT NOT NULL UNIQUE,
  created_at_ms_utc INTEGER NOT NULL,
  expires_at_ms_utc INTEGER NOT NULL,
  last_used_at_ms_utc INTEGER,
  revoked_at_ms_utc INTEGER,
  rotated_from_id INTEGER,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(rotated_from_id) REFERENCES refresh_tokens(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user
  ON refresh_tokens (user_id);

CREATE INDEX IF NOT EXISTS idx_auth_tickets_user
  ON auth_tickets (user_id);


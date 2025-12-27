PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  oauth_provider TEXT NOT NULL,
  oauth_sub TEXT NOT NULL UNIQUE,
  created_at_ms_utc INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS key_bundles (
  user_id INTEGER PRIMARY KEY,
  bundle_version INTEGER NOT NULL,
  bundle_json TEXT NOT NULL,
  updated_at_ms_utc INTEGER NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS server_seq (
  user_id INTEGER PRIMARY KEY,
  next_seq INTEGER NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS records (
  user_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  record_id TEXT NOT NULL,
  hlc_wall_ms_utc INTEGER NOT NULL,
  hlc_counter INTEGER NOT NULL,
  hlc_device_id TEXT NOT NULL,
  deleted_at_ms_utc INTEGER,
  schema_version INTEGER NOT NULL,
  dek_id TEXT NOT NULL,
  algo TEXT NOT NULL,
  nonce TEXT NOT NULL,
  ciphertext TEXT NOT NULL,
  server_seq INTEGER NOT NULL,
  updated_at_ms_utc INTEGER NOT NULL,
  PRIMARY KEY (user_id, type, record_id),
  UNIQUE (user_id, server_seq),
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_records_user_seq
  ON records (user_id, server_seq);


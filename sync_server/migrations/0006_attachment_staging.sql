PRAGMA foreign_keys = ON;

-- Staging area for attachment metadata/chunks while the uploading device is
-- still pushing blocks. These records are invisible to `/v1/sync/pull` until a
-- `todo_attachment_commit` marker is received.
CREATE TABLE IF NOT EXISTS staged_records (
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
  updated_at_ms_utc INTEGER NOT NULL,
  PRIMARY KEY (user_id, type, record_id),
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_staged_records_user_type
  ON staged_records (user_id, type);

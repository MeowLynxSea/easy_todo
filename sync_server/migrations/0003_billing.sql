PRAGMA foreign_keys = ON;

ALTER TABLE users ADD COLUMN base_storage_b64 INTEGER;
ALTER TABLE users ADD COLUMN base_outbound_bytes INTEGER;
ALTER TABLE users ADD COLUMN subscription_plan_id TEXT;
ALTER TABLE users ADD COLUMN subscription_expires_at_ms_utc INTEGER;
ALTER TABLE users ADD COLUMN banned_at_ms_utc INTEGER;
ALTER TABLE users ADD COLUMN stored_b64 INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN api_outbound_bytes INTEGER NOT NULL DEFAULT 0;

-- Backfill cached storage usage for existing users.
UPDATE users
SET stored_b64 = (
  SELECT IFNULL(SUM(LENGTH(nonce) + LENGTH(ciphertext)), 0)
  FROM records
  WHERE records.user_id = users.id
);

CREATE TABLE IF NOT EXISTS cdkeys (
  code TEXT PRIMARY KEY,
  plan_id TEXT NOT NULL,
  created_at_ms_utc INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_cdkeys_plan_id
  ON cdkeys (plan_id);

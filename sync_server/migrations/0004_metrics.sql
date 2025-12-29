PRAGMA foreign_keys = ON;

-- Daily aggregated metrics (UTC).
CREATE TABLE IF NOT EXISTS metrics_daily (
  day_utc TEXT PRIMARY KEY,
  api_requests INTEGER NOT NULL DEFAULT 0,
  api_in_bytes INTEGER NOT NULL DEFAULT 0,
  api_out_bytes INTEGER NOT NULL DEFAULT 0,
  new_users INTEGER NOT NULL DEFAULT 0,
  cdkey_activations INTEGER NOT NULL DEFAULT 0,
  active_users INTEGER NOT NULL DEFAULT 0
);

-- Per-day unique active users (used to dedupe active_users).
-- Keep historical rows even if a user is deleted.
CREATE TABLE IF NOT EXISTS metrics_daily_active_users (
  day_utc TEXT NOT NULL,
  user_id INTEGER NOT NULL,
  PRIMARY KEY (day_utc, user_id)
);

CREATE INDEX IF NOT EXISTS idx_metrics_daily_active_users_day
  ON metrics_daily_active_users(day_utc);


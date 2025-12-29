PRAGMA foreign_keys = ON;

-- Track which UTC month `api_outbound_bytes` belongs to, so we can reset usage monthly.
-- Month key format: YYYYMM (e.g. 202512). `0` means "unknown" and will be reset lazily.
ALTER TABLE users ADD COLUMN api_outbound_month_utc INTEGER NOT NULL DEFAULT 0;


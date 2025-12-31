PRAGMA foreign_keys = ON;

-- Attachment -> Todo reference index for server-side garbage collection.
--
-- This is populated by clients and allows the server to remove attachments
-- whose owning todo has been deleted, without decrypting payloads.
CREATE TABLE IF NOT EXISTS attachment_refs (
  user_id INTEGER NOT NULL,
  attachment_id TEXT NOT NULL,
  todo_id TEXT NOT NULL,
  updated_at_ms_utc INTEGER NOT NULL,
  PRIMARY KEY (user_id, attachment_id),
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_attachment_refs_user_todo
  ON attachment_refs (user_id, todo_id);

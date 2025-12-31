use std::collections::HashSet;

use anyhow::anyhow;
use sqlx::{Pool, Sqlite, Transaction};

const TYPE_TODO: &str = "todo";

#[derive(Debug, Clone, Copy)]
pub(crate) struct GhostGcOptions {
    pub include_unreferenced_when_no_live_todo: bool,
    pub min_ref_age_ms: i64,
}

#[derive(Debug, Clone, Copy)]
pub(crate) struct GhostGcStats {
    pub deleted_attachments: i64,
    pub deleted_records: i64,
    pub stored_before: i64,
    pub stored_after: i64,
}

fn escape_like_prefix(value: &str) -> String {
    value
        .replace('\\', "\\\\")
        .replace('%', "\\%")
        .replace('_', "\\_")
}

pub(crate) async fn gc_ghost_files_for_user(
    tx: &mut Transaction<'_, Sqlite>,
    user_id: i64,
    opts: GhostGcOptions,
) -> anyhow::Result<GhostGcStats> {
    let stored_before: i64 = sqlx::query_scalar(r#"SELECT stored_b64 FROM users WHERE id = ?"#)
        .bind(user_id)
        .fetch_optional(&mut **tx)
        .await?
        .ok_or_else(|| anyhow!("user not found"))?;

    gc_ghost_files_for_user_with_stored_before(tx, user_id, stored_before, opts).await
}

pub(crate) async fn gc_ghost_files_for_user_with_stored_before(
    tx: &mut Transaction<'_, Sqlite>,
    user_id: i64,
    stored_before: i64,
    opts: GhostGcOptions,
) -> anyhow::Result<GhostGcStats> {
    let now_ms = crate::now_ms_utc();

    let has_live_todo: bool = sqlx::query_scalar::<_, i64>(
        r#"SELECT 1
           FROM records
           WHERE user_id = ?
             AND type = ?
             AND deleted_at_ms_utc IS NULL
           LIMIT 1"#,
    )
    .bind(user_id)
    .bind(TYPE_TODO)
    .fetch_optional(&mut **tx)
    .await?
    .is_some();

    let orphan_attachment_ids: Vec<String> = if opts.min_ref_age_ms > 0 {
        let cutoff = now_ms.saturating_sub(opts.min_ref_age_ms);
        sqlx::query_scalar(
            r#"SELECT attachment_id
               FROM attachment_refs ar
               WHERE ar.user_id = ?
                 AND ar.updated_at_ms_utc <= ?
                 AND NOT EXISTS (
                   SELECT 1
                   FROM records t
                   WHERE t.user_id = ar.user_id
                     AND t.type = ?
                     AND t.record_id = ar.todo_id
                     AND t.deleted_at_ms_utc IS NULL
                   LIMIT 1
                 )"#,
        )
        .bind(user_id)
        .bind(cutoff)
        .bind(TYPE_TODO)
        .fetch_all(&mut **tx)
        .await?
    } else {
        sqlx::query_scalar(
            r#"SELECT attachment_id
               FROM attachment_refs ar
               WHERE ar.user_id = ?
                 AND NOT EXISTS (
                   SELECT 1
                   FROM records t
                   WHERE t.user_id = ar.user_id
                     AND t.type = ?
                     AND t.record_id = ar.todo_id
                     AND t.deleted_at_ms_utc IS NULL
                   LIMIT 1
                 )"#,
        )
        .bind(user_id)
        .bind(TYPE_TODO)
        .fetch_all(&mut **tx)
        .await?
    };

    // Ghost attachment = attachment exists server-side but its owning todo no
    // longer exists (or was tombstoned). Attachment ownership comes from
    // `attachment_refs` populated by clients.
    let mut attachment_ids: HashSet<String> = orphan_attachment_ids
        .into_iter()
        .map(|s| s.trim().to_string())
        .filter(|s| !s.is_empty())
        .collect();

    // Fallback (manual GC use-case): if the user has no live todos at all, any
    // stored attachments cannot be referenced by an existing todo, so treat
    // them as ghosts even when `attachment_refs` is empty.
    if opts.include_unreferenced_when_no_live_todo && !has_live_todo {
        let direct_meta_ids: Vec<String> =
            sqlx::query_scalar(r#"SELECT record_id FROM records WHERE user_id = ? AND type = ?"#)
                .bind(user_id)
                .bind(crate::TYPE_TODO_ATTACHMENT)
                .fetch_all(&mut **tx)
                .await?;
        for id in direct_meta_ids {
            let id = id.trim();
            if !id.is_empty() {
                attachment_ids.insert(id.to_string());
            }
        }

        // Also include attachments that may have chunk rows but missing meta.
        let chunk_prefix_ids: Vec<String> = sqlx::query_scalar(
            r#"SELECT DISTINCT substr(record_id, 1, instr(record_id, ':') - 1)
               FROM records
               WHERE user_id = ? AND type = ? AND instr(record_id, ':') > 0"#,
        )
        .bind(user_id)
        .bind(crate::TYPE_TODO_ATTACHMENT_CHUNK)
        .fetch_all(&mut **tx)
        .await?;
        for id in chunk_prefix_ids {
            let id = id.trim();
            if !id.is_empty() {
                attachment_ids.insert(id.to_string());
            }
        }
    }

    let mut deleted_attachments = 0_i64;
    let mut deleted_records = 0_i64;

    for attachment_id in attachment_ids {
        let attachment_id = attachment_id.trim().to_string();
        if attachment_id.is_empty() {
            continue;
        }

        let escaped = escape_like_prefix(&attachment_id);
        let chunk_pattern = format!("{escaped}:%");

        let mut deleted_any = 0_i64;

        deleted_any +=
            sqlx::query(r#"DELETE FROM records WHERE user_id = ? AND type = ? AND record_id = ?"#)
                .bind(user_id)
                .bind(crate::TYPE_TODO_ATTACHMENT)
                .bind(&attachment_id)
                .execute(&mut **tx)
                .await?
                .rows_affected() as i64;

        deleted_any += sqlx::query(
            r#"DELETE FROM records
               WHERE user_id = ? AND type = ? AND record_id LIKE ? ESCAPE '\'"#,
        )
        .bind(user_id)
        .bind(crate::TYPE_TODO_ATTACHMENT_CHUNK)
        .bind(&chunk_pattern)
        .execute(&mut **tx)
        .await?
        .rows_affected() as i64;

        deleted_any += sqlx::query(
            r#"DELETE FROM staged_records WHERE user_id = ? AND type = ? AND record_id = ?"#,
        )
        .bind(user_id)
        .bind(crate::TYPE_TODO_ATTACHMENT)
        .bind(&attachment_id)
        .execute(&mut **tx)
        .await?
        .rows_affected() as i64;

        deleted_any += sqlx::query(
            r#"DELETE FROM staged_records
               WHERE user_id = ? AND type = ? AND record_id LIKE ? ESCAPE '\'"#,
        )
        .bind(user_id)
        .bind(crate::TYPE_TODO_ATTACHMENT_CHUNK)
        .bind(&chunk_pattern)
        .execute(&mut **tx)
        .await?
        .rows_affected() as i64;

        let _ =
            sqlx::query(r#"DELETE FROM attachment_refs WHERE user_id = ? AND attachment_id = ?"#)
                .bind(user_id)
                .bind(&attachment_id)
                .execute(&mut **tx)
                .await;

        if deleted_any > 0 {
            deleted_attachments += 1;
        }
        deleted_records += deleted_any;
    }

    let stored_after = crate::recompute_and_store_user_b64(tx, user_id).await?;

    Ok(GhostGcStats {
        deleted_attachments,
        deleted_records,
        stored_before,
        stored_after,
    })
}

pub(crate) async fn select_users_with_orphan_attachment_refs(
    db: &Pool<Sqlite>,
    min_ref_age_ms: i64,
    max_users: i64,
) -> anyhow::Result<Vec<i64>> {
    let max_users = max_users.clamp(1, 10_000);
    let now_ms = crate::now_ms_utc();

    let user_ids: Vec<i64> = if min_ref_age_ms > 0 {
        let cutoff = now_ms.saturating_sub(min_ref_age_ms);
        sqlx::query_scalar(
            r#"SELECT DISTINCT ar.user_id
               FROM attachment_refs ar
               WHERE ar.updated_at_ms_utc <= ?
                 AND NOT EXISTS (
                   SELECT 1
                   FROM records t
                   WHERE t.user_id = ar.user_id
                     AND t.type = ?
                     AND t.record_id = ar.todo_id
                     AND t.deleted_at_ms_utc IS NULL
                   LIMIT 1
                 )
               LIMIT ?"#,
        )
        .bind(cutoff)
        .bind(TYPE_TODO)
        .bind(max_users)
        .fetch_all(db)
        .await?
    } else {
        sqlx::query_scalar(
            r#"SELECT DISTINCT ar.user_id
               FROM attachment_refs ar
               WHERE NOT EXISTS (
                 SELECT 1
                 FROM records t
                 WHERE t.user_id = ar.user_id
                   AND t.type = ?
                   AND t.record_id = ar.todo_id
                   AND t.deleted_at_ms_utc IS NULL
                 LIMIT 1
               )
               LIMIT ?"#,
        )
        .bind(TYPE_TODO)
        .bind(max_users)
        .fetch_all(db)
        .await?
    };

    Ok(user_ids)
}

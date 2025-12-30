use axum::extract::{Path, Query, State};
use axum::http::{HeaderMap, StatusCode};
use axum::response::IntoResponse;
use axum::Json;
use rand::RngCore;
use serde::de::Deserializer;
use serde::{Deserialize, Serialize};
use sqlx::{QueryBuilder, Row, Sqlite};

use crate::{
    clear_subscription_if_expired, compute_effective_quota, json_error, now_ms_utc,
    reset_user_api_outbound_if_new_month, AppState, ErrorBody, UserBillingRow,
};

use super::admin_session::authenticate_admin;
use super::util::check_same_origin;

#[derive(Debug, Clone, Copy)]
enum PatchField<T> {
    Missing,
    Clear,
    Value(T),
}

impl<T> Default for PatchField<T> {
    fn default() -> Self {
        Self::Missing
    }
}

impl<'de, T> Deserialize<'de> for PatchField<T>
where
    T: Deserialize<'de>,
{
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let opt = Option::<T>::deserialize(deserializer)?;
        Ok(match opt {
            Some(v) => Self::Value(v),
            None => Self::Clear,
        })
    }
}

fn normalize_plan_id(raw: &str) -> Option<String> {
    let id = raw.trim().to_lowercase();
    if id.is_empty() {
        None
    } else {
        Some(id)
    }
}

fn generate_cdkey(rng: &mut impl RngCore) -> String {
    const CHARS: &[u8] = b"ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    let mut out = String::with_capacity(24);
    for i in 0..20usize {
        if i != 0 && i % 5 == 0 {
            out.push('-');
        }
        let idx = (rng.next_u32() as usize) % CHARS.len();
        out.push(CHARS[idx] as char);
    }
    out
}

#[derive(Debug, Deserialize)]
pub(super) struct AdminGenerateCdkeysRequest {
    #[serde(rename = "planId")]
    plan_id: String,
    count: Option<i64>,
}

#[derive(Debug, Serialize)]
struct AdminGenerateCdkeysResponse {
    codes: Vec<String>,
}

pub(super) async fn admin_generate_cdkeys(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<AdminGenerateCdkeysRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    authenticate_admin(&state, &headers)?;
    if !check_same_origin(&state, &headers) {
        return Err(json_error(StatusCode::FORBIDDEN, "forbidden"));
    }

    let Some(plan_id) = normalize_plan_id(&req.plan_id) else {
        return Err(json_error(StatusCode::BAD_REQUEST, "plan_id required"));
    };
    if !state.billing.plans.contains_key(&plan_id) {
        return Err(json_error(StatusCode::BAD_REQUEST, "unknown_plan"));
    }

    let count = req.count.unwrap_or(1).clamp(1, 2000) as usize;
    let now_ms = now_ms_utc();

    let mut codes = Vec::with_capacity(count);

    while codes.len() < count {
        let code = {
            let mut rng = rand::thread_rng();
            generate_cdkey(&mut rng)
        };
        let inserted = sqlx::query(
            r#"INSERT OR IGNORE INTO cdkeys (code, plan_id, created_at_ms_utc)
               VALUES (?, ?, ?)"#,
        )
        .bind(&code)
        .bind(&plan_id)
        .bind(now_ms)
        .execute(&state.db)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
        if inserted.rows_affected() == 1 {
            codes.push(code);
        }
    }

    Ok(Json(AdminGenerateCdkeysResponse { codes }))
}

#[derive(Debug, Deserialize)]
pub(super) struct AdminDeleteCdkeysRequest {
    #[serde(rename = "planId")]
    plan_id: String,
    count: Option<i64>,
}

#[derive(Debug, Serialize)]
struct AdminDeleteCdkeysResponse {
    deleted: i64,
    codes: Vec<String>,
}

#[derive(Debug, Deserialize)]
pub(super) struct AdminListCdkeysQuery {
    #[serde(rename = "planId")]
    plan_id: Option<String>,
}

#[derive(Debug, Serialize)]
struct AdminCdkeyRow {
    code: String,
    #[serde(rename = "planId")]
    plan_id: String,
    #[serde(rename = "createdAtMsUtc")]
    created_at_ms_utc: i64,
}

#[derive(Debug, Serialize)]
struct AdminListCdkeysResponse {
    cdkeys: Vec<AdminCdkeyRow>,
    total: i64,
}

pub(super) async fn admin_list_cdkeys(
    State(state): State<AppState>,
    headers: HeaderMap,
    Query(q): Query<AdminListCdkeysQuery>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    authenticate_admin(&state, &headers)?;
    if !check_same_origin(&state, &headers) {
        return Err(json_error(StatusCode::FORBIDDEN, "forbidden"));
    }

    let plan_id = q
        .plan_id
        .as_deref()
        .map(|s| s.trim().to_lowercase())
        .filter(|s| !s.is_empty());

    let rows = if let Some(plan_id) = &plan_id {
        sqlx::query(
            r#"SELECT code, plan_id, created_at_ms_utc
               FROM cdkeys
               WHERE plan_id = ?
               ORDER BY created_at_ms_utc DESC, code ASC"#,
        )
        .bind(plan_id)
        .fetch_all(&state.db)
        .await
    } else {
        sqlx::query(
            r#"SELECT code, plan_id, created_at_ms_utc
               FROM cdkeys
               ORDER BY created_at_ms_utc DESC, code ASC"#,
        )
        .fetch_all(&state.db)
        .await
    }
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let mut cdkeys = Vec::with_capacity(rows.len());
    for row in rows {
        let code: String = row.try_get("code").unwrap_or_default();
        let plan_id: String = row.try_get("plan_id").unwrap_or_default();
        let created_at_ms_utc: i64 = row.try_get("created_at_ms_utc").unwrap_or(0);
        if code.trim().is_empty() {
            continue;
        }
        cdkeys.push(AdminCdkeyRow {
            code,
            plan_id,
            created_at_ms_utc,
        });
    }

    Ok(Json(AdminListCdkeysResponse {
        total: cdkeys.len() as i64,
        cdkeys,
    }))
}

pub(super) async fn admin_delete_cdkeys(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<AdminDeleteCdkeysRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    authenticate_admin(&state, &headers)?;
    if !check_same_origin(&state, &headers) {
        return Err(json_error(StatusCode::FORBIDDEN, "forbidden"));
    }

    let Some(plan_id) = normalize_plan_id(&req.plan_id) else {
        return Err(json_error(StatusCode::BAD_REQUEST, "plan_id required"));
    };

    let count = req.count.unwrap_or(0);
    if count < 0 {
        return Err(json_error(StatusCode::BAD_REQUEST, "invalid_count"));
    }
    let count = count.clamp(0, 2000);

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let mut codes: Vec<String> = if count == 0 {
        sqlx::query_scalar(
            r#"SELECT code
               FROM cdkeys
               WHERE plan_id = ?
               ORDER BY created_at_ms_utc DESC, code ASC"#,
        )
        .bind(&plan_id)
        .fetch_all(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?
    } else {
        sqlx::query_scalar(
            r#"SELECT code
               FROM cdkeys
               WHERE plan_id = ?
               ORDER BY created_at_ms_utc DESC, code ASC
               LIMIT ?"#,
        )
        .bind(&plan_id)
        .bind(count)
        .fetch_all(&mut *tx)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?
    };
    codes.retain(|s| !s.trim().is_empty());

    let deleted = if codes.is_empty() {
        0i64
    } else if count == 0 {
        sqlx::query(r#"DELETE FROM cdkeys WHERE plan_id = ?"#)
            .bind(&plan_id)
            .execute(&mut *tx)
            .await
            .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?
            .rows_affected() as i64
    } else {
        let mut deleted_total: i64 = 0;
        for chunk in codes.chunks(400) {
            let mut qb = QueryBuilder::<Sqlite>::new("DELETE FROM cdkeys WHERE code IN (");
            {
                let mut sep = qb.separated(", ");
                for code in chunk {
                    sep.push_bind(code);
                }
            }
            qb.push(")");
            let res = qb
                .build()
                .execute(&mut *tx)
                .await
                .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
            deleted_total = deleted_total.saturating_add(res.rows_affected() as i64);
        }
        deleted_total
    };

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    Ok(Json(AdminDeleteCdkeysResponse { deleted, codes }))
}

#[derive(Debug, Serialize)]
struct AdminUserQuotaResponse {
    #[serde(rename = "baseStorageB64")]
    base_storage_b64: Option<i64>,
    #[serde(rename = "baseOutboundBytes")]
    base_outbound_bytes: Option<i64>,
    #[serde(rename = "bonusStorageB64")]
    bonus_storage_b64: i64,
    #[serde(rename = "bonusOutboundBytes")]
    bonus_outbound_bytes: i64,
    #[serde(rename = "allowedStorageB64")]
    allowed_storage_b64: Option<i64>,
    #[serde(rename = "allowedOutboundBytes")]
    allowed_outbound_bytes: Option<i64>,
    #[serde(rename = "activePlanId")]
    active_plan_id: Option<String>,
    #[serde(rename = "activePlanName")]
    active_plan_name: Option<String>,
    #[serde(rename = "activePlanExpiresAtMsUtc")]
    active_plan_expires_at_ms_utc: Option<i64>,
    #[serde(rename = "overStorage")]
    over_storage: bool,
    #[serde(rename = "overOutbound")]
    over_outbound: bool,
}

#[derive(Debug, Serialize)]
struct AdminGetUserResponse {
    #[serde(rename = "userId")]
    user_id: i64,
    #[serde(rename = "oauthProvider")]
    oauth_provider: String,
    #[serde(rename = "oauthSub")]
    oauth_sub: String,
    #[serde(rename = "createdAtMsUtc")]
    created_at_ms_utc: i64,
    #[serde(rename = "bannedAtMsUtc")]
    banned_at_ms_utc: Option<i64>,
    #[serde(rename = "storedB64")]
    stored_b64: i64,
    #[serde(rename = "apiOutboundBytes")]
    api_outbound_bytes: i64,
    #[serde(rename = "baseStorageB64")]
    base_storage_b64: Option<i64>,
    #[serde(rename = "baseOutboundBytes")]
    base_outbound_bytes: Option<i64>,
    #[serde(rename = "subscriptionPlanId")]
    subscription_plan_id: Option<String>,
    #[serde(rename = "subscriptionExpiresAtMsUtc")]
    subscription_expires_at_ms_utc: Option<i64>,
    quota: AdminUserQuotaResponse,
}

pub(super) async fn admin_get_user(
    State(state): State<AppState>,
    headers: HeaderMap,
    Path(user_id): Path<i64>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    authenticate_admin(&state, &headers)?;

    let now_ms = now_ms_utc();
    reset_user_api_outbound_if_new_month(&state.db, user_id, now_ms)
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let row = sqlx::query(
        r#"SELECT
             id,
             oauth_provider,
             oauth_sub,
             created_at_ms_utc,
             banned_at_ms_utc,
             stored_b64,
             api_outbound_bytes,
             base_storage_b64,
             base_outbound_bytes,
             subscription_plan_id,
             subscription_expires_at_ms_utc
           FROM users
           WHERE id = ?"#,
    )
    .bind(user_id)
    .fetch_optional(&state.db)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let Some(row) = row else {
        return Err(json_error(StatusCode::NOT_FOUND, "user_not_found"));
    };

    let oauth_provider: String = row
        .try_get("oauth_provider")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let oauth_sub: String = row
        .try_get("oauth_sub")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let created_at_ms_utc: i64 = row
        .try_get("created_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let base_storage_b64: Option<i64> = row
        .try_get("base_storage_b64")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let base_outbound_bytes: Option<i64> = row
        .try_get("base_outbound_bytes")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let mut subscription_plan_id: Option<String> = row
        .try_get("subscription_plan_id")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let mut subscription_expires_at_ms_utc: Option<i64> = row
        .try_get("subscription_expires_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let banned_at_ms_utc: Option<i64> = row
        .try_get("banned_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let banned_at_ms_utc = banned_at_ms_utc.filter(|ms| *ms > 0);
    let stored_b64: i64 = row
        .try_get("stored_b64")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let api_outbound_bytes: i64 = row
        .try_get("api_outbound_bytes")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let has_plan = subscription_plan_id
        .as_deref()
        .map(|s| !s.trim().is_empty())
        .unwrap_or(false);
    let expires_at = subscription_expires_at_ms_utc.unwrap_or(0);
    if has_plan && expires_at <= now_ms {
        clear_subscription_if_expired(
            &state.db,
            user_id,
            &subscription_plan_id,
            subscription_expires_at_ms_utc,
            now_ms,
        )
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
        subscription_plan_id = None;
        subscription_expires_at_ms_utc = None;
    }

    let user_billing = UserBillingRow {
        base_storage_b64,
        base_outbound_bytes,
        subscription_plan_id: subscription_plan_id.clone(),
        subscription_expires_at_ms_utc,
        banned_at_ms_utc,
        stored_b64,
        api_outbound_bytes,
    };
    let quota = compute_effective_quota(&state.billing, &user_billing, now_ms);

    let over_storage = quota
        .allowed_storage_b64
        .is_some_and(|limit| stored_b64 > limit);
    let over_outbound = quota
        .allowed_outbound_bytes
        .is_some_and(|limit| api_outbound_bytes > limit);

    Ok(Json(AdminGetUserResponse {
        user_id,
        oauth_provider,
        oauth_sub,
        created_at_ms_utc,
        banned_at_ms_utc,
        stored_b64,
        api_outbound_bytes,
        base_storage_b64,
        base_outbound_bytes,
        subscription_plan_id,
        subscription_expires_at_ms_utc,
        quota: AdminUserQuotaResponse {
            base_storage_b64: quota.base_storage_b64,
            base_outbound_bytes: quota.base_outbound_bytes,
            bonus_storage_b64: quota.bonus_storage_b64,
            bonus_outbound_bytes: quota.bonus_outbound_bytes,
            allowed_storage_b64: quota.allowed_storage_b64,
            allowed_outbound_bytes: quota.allowed_outbound_bytes,
            active_plan_id: quota.active_plan_id,
            active_plan_name: quota.active_plan_name,
            active_plan_expires_at_ms_utc: quota.active_plan_expires_at_ms_utc,
            over_storage,
            over_outbound,
        },
    }))
}

#[derive(Debug, Deserialize)]
pub(super) struct AdminUpdateUserRequest {
    #[serde(rename = "userId")]
    user_id: i64,
    #[serde(rename = "baseStorageB64")]
    #[serde(default)]
    base_storage_b64: PatchField<i64>,
    #[serde(rename = "baseOutboundBytes")]
    #[serde(default)]
    base_outbound_bytes: PatchField<i64>,
    #[serde(rename = "subscriptionPlanId")]
    #[serde(default)]
    subscription_plan_id: PatchField<String>,
    #[serde(rename = "subscriptionExpiresAtMsUtc")]
    #[serde(default)]
    subscription_expires_at_ms_utc: PatchField<i64>,
    banned: Option<bool>,
}

#[derive(Debug, Serialize)]
struct OkResponse {
    ok: bool,
}

pub(super) async fn admin_update_user(
    State(state): State<AppState>,
    headers: HeaderMap,
    Json(req): Json<AdminUpdateUserRequest>,
) -> Result<impl IntoResponse, (StatusCode, Json<ErrorBody>)> {
    authenticate_admin(&state, &headers)?;
    if !check_same_origin(&state, &headers) {
        return Err(json_error(StatusCode::FORBIDDEN, "forbidden"));
    }

    let now_ms = now_ms_utc();

    let mut tx = state
        .db
        .begin()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    let existing = sqlx::query(
        r#"SELECT
             base_storage_b64,
             base_outbound_bytes,
             subscription_plan_id,
             subscription_expires_at_ms_utc,
             banned_at_ms_utc
           FROM users
           WHERE id = ?"#,
    )
    .bind(req.user_id)
    .fetch_optional(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let Some(existing) = existing else {
        tx.rollback().await.ok();
        return Err(json_error(StatusCode::NOT_FOUND, "user_not_found"));
    };

    let mut base_storage_b64: Option<i64> = existing
        .try_get("base_storage_b64")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let mut base_outbound_bytes: Option<i64> = existing
        .try_get("base_outbound_bytes")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let existing_plan_id: Option<String> = existing
        .try_get("subscription_plan_id")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let existing_expires_at: Option<i64> = existing
        .try_get("subscription_expires_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    let mut banned_at_ms_utc: Option<i64> = existing
        .try_get("banned_at_ms_utc")
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;
    banned_at_ms_utc = banned_at_ms_utc.filter(|ms| *ms > 0);

    match req.base_storage_b64 {
        PatchField::Missing => {}
        PatchField::Clear => {
            base_storage_b64 = None;
        }
        PatchField::Value(n) => {
            if n < 0 {
                tx.rollback().await.ok();
                return Err(json_error(
                    StatusCode::BAD_REQUEST,
                    "invalid_base_storage_b64",
                ));
            }
            base_storage_b64 = Some(n);
        }
    }

    match req.base_outbound_bytes {
        PatchField::Missing => {}
        PatchField::Clear => {
            base_outbound_bytes = None;
        }
        PatchField::Value(n) => {
            if n < 0 {
                tx.rollback().await.ok();
                return Err(json_error(
                    StatusCode::BAD_REQUEST,
                    "invalid_base_outbound_bytes",
                ));
            }
            base_outbound_bytes = Some(n);
        }
    }

    let mut subscription_plan_id = existing_plan_id.clone();
    let mut subscription_expires_at_ms_utc = existing_expires_at;

    let plan_patch_is_missing = matches!(&req.subscription_plan_id, PatchField::Missing);

    match req.subscription_plan_id {
        PatchField::Missing => {}
        PatchField::Clear => {
            subscription_plan_id = None;
            subscription_expires_at_ms_utc = None;
        }
        PatchField::Value(v) => {
            let new_plan_id = v.trim().to_string();
            if new_plan_id.is_empty() {
                subscription_plan_id = None;
                subscription_expires_at_ms_utc = None;
            } else {
                let Some(norm) = normalize_plan_id(&new_plan_id) else {
                    tx.rollback().await.ok();
                    return Err(json_error(
                        StatusCode::BAD_REQUEST,
                        "invalid_subscription_plan_id",
                    ));
                };
                let Some(plan) = state.billing.plans.get(&norm) else {
                    tx.rollback().await.ok();
                    return Err(json_error(StatusCode::BAD_REQUEST, "unknown_plan"));
                };
                subscription_plan_id = Some(plan.id.clone());
                let exp_ms = match req.subscription_expires_at_ms_utc {
                    PatchField::Value(v) => v,
                    PatchField::Clear | PatchField::Missing => {
                        now_ms.saturating_add(plan.duration_ms)
                    }
                };
                if exp_ms < 0 {
                    tx.rollback().await.ok();
                    return Err(json_error(
                        StatusCode::BAD_REQUEST,
                        "invalid_subscription_expires_at_ms_utc",
                    ));
                }
                if exp_ms <= now_ms {
                    subscription_plan_id = None;
                    subscription_expires_at_ms_utc = None;
                } else {
                    subscription_expires_at_ms_utc = Some(exp_ms);
                }
            }
        }
    }

    if plan_patch_is_missing {
        match req.subscription_expires_at_ms_utc {
            PatchField::Missing => {}
            PatchField::Clear => {
                subscription_plan_id = None;
                subscription_expires_at_ms_utc = None;
            }
            PatchField::Value(exp_ms) => {
                if exp_ms < 0 {
                    tx.rollback().await.ok();
                    return Err(json_error(
                        StatusCode::BAD_REQUEST,
                        "invalid_subscription_expires_at_ms_utc",
                    ));
                }
                let Some(norm) = existing_plan_id.as_deref().and_then(normalize_plan_id) else {
                    tx.rollback().await.ok();
                    return Err(json_error(
                        StatusCode::BAD_REQUEST,
                        "subscription_plan_id_required",
                    ));
                };
                if exp_ms <= now_ms {
                    subscription_plan_id = None;
                    subscription_expires_at_ms_utc = None;
                } else {
                    subscription_plan_id = Some(norm);
                    subscription_expires_at_ms_utc = Some(exp_ms);
                }
            }
        }
    }

    if let Some(banned) = req.banned {
        banned_at_ms_utc = if banned { Some(now_ms) } else { None };
    }

    sqlx::query(
        r#"UPDATE users
           SET
             base_storage_b64 = ?,
             base_outbound_bytes = ?,
             subscription_plan_id = ?,
             subscription_expires_at_ms_utc = ?,
             banned_at_ms_utc = ?
           WHERE id = ?"#,
    )
    .bind(base_storage_b64)
    .bind(base_outbound_bytes)
    .bind(subscription_plan_id)
    .bind(subscription_expires_at_ms_utc)
    .bind(banned_at_ms_utc)
    .bind(req.user_id)
    .execute(&mut *tx)
    .await
    .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    tx.commit()
        .await
        .map_err(|_| json_error(StatusCode::INTERNAL_SERVER_ERROR, "db error"))?;

    Ok(Json(OkResponse { ok: true }))
}

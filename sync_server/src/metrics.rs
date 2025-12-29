use std::collections::{HashMap, HashSet};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;
use std::time::Duration;

use sqlx::{Pool, QueryBuilder, Sqlite};
use tokio::sync::mpsc;
use tokio::time::MissedTickBehavior;
use tracing::error;

const MS_PER_DAY: i64 = 86_400_000;
const FLUSH_INTERVAL: Duration = Duration::from_secs(5);
const CHANNEL_CAPACITY: usize = 8192;
const ACTIVE_USERS_INSERT_CHUNK: usize = 400;

#[derive(Debug, Clone)]
pub(crate) struct Metrics {
    tx: mpsc::Sender<MetricsEvent>,
    dropped: Arc<AtomicU64>,
}

impl Metrics {
    pub(crate) fn start(pool: Pool<Sqlite>) -> Arc<Self> {
        let (tx, rx) = mpsc::channel(CHANNEL_CAPACITY);
        let dropped = Arc::new(AtomicU64::new(0));
        let metrics = Arc::new(Self { tx, dropped });
        tokio::spawn(run_metrics_writer(pool, rx));
        metrics
    }

    pub(crate) fn dropped_events(&self) -> u64 {
        self.dropped.load(Ordering::Relaxed)
    }

    pub(crate) fn record_api_request(&self, at_ms_utc: i64, in_bytes: i64, out_bytes: i64) {
        self.send(MetricsEvent::ApiRequest {
            at_ms_utc,
            in_bytes: in_bytes.max(0),
            out_bytes: out_bytes.max(0),
        });
    }

    pub(crate) fn record_new_user(&self, at_ms_utc: i64) {
        self.send(MetricsEvent::NewUser { at_ms_utc });
    }

    pub(crate) fn record_cdkey_activation(&self, at_ms_utc: i64) {
        self.send(MetricsEvent::CdkeyActivation { at_ms_utc });
    }

    pub(crate) fn record_active_user(&self, at_ms_utc: i64, user_id: i64) {
        if user_id <= 0 {
            return;
        }
        self.send(MetricsEvent::ActiveUser { at_ms_utc, user_id });
    }

    fn send(&self, event: MetricsEvent) {
        if self.tx.try_send(event).is_err() {
            self.dropped.fetch_add(1, Ordering::Relaxed);
        }
    }
}

#[derive(Debug)]
enum MetricsEvent {
    ApiRequest {
        at_ms_utc: i64,
        in_bytes: i64,
        out_bytes: i64,
    },
    NewUser {
        at_ms_utc: i64,
    },
    CdkeyActivation {
        at_ms_utc: i64,
    },
    ActiveUser {
        at_ms_utc: i64,
        user_id: i64,
    },
}

#[derive(Debug, Default, Clone, Copy)]
struct DailyAgg {
    api_requests: i64,
    api_in_bytes: i64,
    api_out_bytes: i64,
    new_users: i64,
    cdkey_activations: i64,
}

async fn run_metrics_writer(pool: Pool<Sqlite>, mut rx: mpsc::Receiver<MetricsEvent>) {
    let mut interval = tokio::time::interval(FLUSH_INTERVAL);
    interval.set_missed_tick_behavior(MissedTickBehavior::Delay);

    let mut daily: HashMap<String, DailyAgg> = HashMap::new();
    let mut active_users: HashMap<String, HashSet<i64>> = HashMap::new();

    loop {
        tokio::select! {
            Some(event) = rx.recv() => {
                handle_event(&mut daily, &mut active_users, event);
            }
            _ = interval.tick() => {
                flush(&pool, &mut daily, &mut active_users).await;
            }
            else => break,
        }
    }

    flush(&pool, &mut daily, &mut active_users).await;
}

fn handle_event(
    daily: &mut HashMap<String, DailyAgg>,
    active_users: &mut HashMap<String, HashSet<i64>>,
    event: MetricsEvent,
) {
    match event {
        MetricsEvent::ApiRequest {
            at_ms_utc,
            in_bytes,
            out_bytes,
        } => {
            let day = day_utc_from_unix_ms(at_ms_utc);
            let agg = daily.entry(day).or_default();
            agg.api_requests = agg.api_requests.saturating_add(1);
            agg.api_in_bytes = agg.api_in_bytes.saturating_add(in_bytes.max(0));
            agg.api_out_bytes = agg.api_out_bytes.saturating_add(out_bytes.max(0));
        }
        MetricsEvent::NewUser { at_ms_utc } => {
            let day = day_utc_from_unix_ms(at_ms_utc);
            let agg = daily.entry(day).or_default();
            agg.new_users = agg.new_users.saturating_add(1);
        }
        MetricsEvent::CdkeyActivation { at_ms_utc } => {
            let day = day_utc_from_unix_ms(at_ms_utc);
            let agg = daily.entry(day).or_default();
            agg.cdkey_activations = agg.cdkey_activations.saturating_add(1);
        }
        MetricsEvent::ActiveUser { at_ms_utc, user_id } => {
            let day = day_utc_from_unix_ms(at_ms_utc);
            active_users.entry(day).or_default().insert(user_id);
        }
    }
}

async fn flush(
    pool: &Pool<Sqlite>,
    daily: &mut HashMap<String, DailyAgg>,
    active_users: &mut HashMap<String, HashSet<i64>>,
) {
    if daily.is_empty() && active_users.is_empty() {
        return;
    }

    let daily_snapshot = std::mem::take(daily);
    for (day, agg) in daily_snapshot {
        if agg.api_requests == 0
            && agg.api_in_bytes == 0
            && agg.api_out_bytes == 0
            && agg.new_users == 0
            && agg.cdkey_activations == 0
        {
            continue;
        }

        if let Err(e) = sqlx::query(
            r#"INSERT INTO metrics_daily (
                 day_utc,
                 api_requests,
                 api_in_bytes,
                 api_out_bytes,
                 new_users,
                 cdkey_activations,
                 active_users
               ) VALUES (?, ?, ?, ?, ?, ?, 0)
               ON CONFLICT(day_utc) DO UPDATE SET
                 api_requests = api_requests + excluded.api_requests,
                 api_in_bytes = api_in_bytes + excluded.api_in_bytes,
                 api_out_bytes = api_out_bytes + excluded.api_out_bytes,
                 new_users = new_users + excluded.new_users,
                 cdkey_activations = cdkey_activations + excluded.cdkey_activations"#,
        )
        .bind(&day)
        .bind(agg.api_requests.max(0))
        .bind(agg.api_in_bytes.max(0))
        .bind(agg.api_out_bytes.max(0))
        .bind(agg.new_users.max(0))
        .bind(agg.cdkey_activations.max(0))
        .execute(pool)
        .await
        {
            error!(error = %e, day = %day, "metrics: flush daily failed");
        }
    }

    let active_snapshot = std::mem::take(active_users);
    for (day, users) in active_snapshot {
        if users.is_empty() {
            continue;
        }

        let mut ids = users.into_iter().filter(|v| *v > 0).collect::<Vec<_>>();
        if ids.is_empty() {
            continue;
        }
        ids.sort_unstable();

        let mut inserted_total: i64 = 0;
        for chunk in ids.chunks(ACTIVE_USERS_INSERT_CHUNK) {
            let mut qb = QueryBuilder::<Sqlite>::new(
                "INSERT OR IGNORE INTO metrics_daily_active_users (day_utc, user_id) ",
            );
            qb.push_values(chunk, |mut b, user_id| {
                b.push_bind(&day);
                b.push_bind(*user_id);
            });
            match qb.build().execute(pool).await {
                Ok(res) => {
                    inserted_total = inserted_total.saturating_add(res.rows_affected() as i64)
                }
                Err(e) => {
                    error!(error = %e, day = %day, "metrics: flush active users insert failed");
                }
            }
        }

        if inserted_total > 0 {
            if let Err(e) = sqlx::query(
                r#"INSERT INTO metrics_daily (day_utc, active_users)
                   VALUES (?, ?)
                   ON CONFLICT(day_utc) DO UPDATE SET
                     active_users = active_users + excluded.active_users"#,
            )
            .bind(&day)
            .bind(inserted_total)
            .execute(pool)
            .await
            {
                error!(error = %e, day = %day, "metrics: flush active users increment failed");
            }
        }
    }
}

pub(crate) fn day_utc_from_unix_ms(ms_utc: i64) -> String {
    format_day_utc_from_days(ms_utc.div_euclid(MS_PER_DAY))
}

pub(crate) fn format_day_utc_from_days(days_since_epoch: i64) -> String {
    let (y, m, d) = civil_from_days(days_since_epoch);
    format!("{:04}-{:02}-{:02}", y, m, d)
}

pub(crate) fn parse_day_utc(s: &str) -> Option<i64> {
    let (y, m, d) = parse_ymd(s)?;
    Some(days_from_civil(y, m, d))
}

fn parse_ymd(s: &str) -> Option<(i32, u32, u32)> {
    let s = s.trim();
    let mut it = s.split('-');
    let y: i32 = it.next()?.parse().ok()?;
    let m: u32 = it.next()?.parse().ok()?;
    let d: u32 = it.next()?.parse().ok()?;
    if it.next().is_some() {
        return None;
    }
    if !(1..=12).contains(&m) {
        return None;
    }
    if !(1..=31).contains(&d) {
        return None;
    }
    Some((y, m, d))
}

// Date conversions without external deps (proleptic Gregorian calendar).
// Based on Howard Hinnant's "civil_from_days/days_from_civil".
fn civil_from_days(days_since_epoch: i64) -> (i32, u32, u32) {
    let z = days_since_epoch + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let mut y = (yoe + era * 400) as i32;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = (doy - (153 * mp + 2) / 5 + 1) as u32;
    let m = (mp + if mp < 10 { 3 } else { -9 }) as i32;
    if m <= 2 {
        y += 1;
    }
    (y, m as u32, d)
}

fn days_from_civil(year: i32, month: u32, day: u32) -> i64 {
    let mut y = year as i64;
    let m = month as i64;
    let d = day as i64;
    y -= if m <= 2 { 1 } else { 0 };
    let era = if y >= 0 { y } else { y - 399 } / 400;
    let yoe = y - era * 400;
    let mp = m + if m > 2 { -3 } else { 9 };
    let doy = (153 * mp + 2) / 5 + d - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    era * 146_097 + doe - 719_468
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn day_round_trip_examples() {
        assert_eq!(day_utc_from_unix_ms(0), "1970-01-01");
        assert_eq!(parse_day_utc("1970-01-01"), Some(0));
        assert_eq!(format_day_utc_from_days(0), "1970-01-01");

        let day = parse_day_utc("2025-12-29").expect("parse");
        assert_eq!(format_day_utc_from_days(day), "2025-12-29");

        let day2 = parse_day_utc("2000-02-29").expect("leap");
        assert_eq!(format_day_utc_from_days(day2), "2000-02-29");
    }
}

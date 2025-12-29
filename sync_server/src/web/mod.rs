mod admin_api;
mod admin_cdkeys;
mod admin_pages;
mod admin_session;
mod admin_stats;
mod admin_users;
mod api;
mod layout;
mod pages;
mod session;
mod util;

use axum::routing::{get, post};
use axum::Router;

use crate::AppState;

pub fn web_router(admin_entry_path: String) -> Router<AppState> {
    Router::new()
        .route("/favicon.png", get(pages::favicon_png))
        .route("/favicon.ico", get(pages::favicon_png))
        .route("/", get(pages::home_page))
        .route("/dashboard", get(pages::dashboard_page))
        .route("/dashboard/login", get(pages::dashboard_login_page))
        .route("/dashboard/logout", post(pages::dashboard_logout))
        .route("/web/api/me", get(api::web_me))
        .route("/web/api/me/activate-cdkey", post(api::web_activate_cdkey))
        .route("/web/api/me/delete", post(api::web_delete_me))
        .route("/web/api/auth/refresh", post(api::web_refresh))
        .merge(admin_pages::admin_router(&admin_entry_path))
        .fallback(pages::fallback_page)
}

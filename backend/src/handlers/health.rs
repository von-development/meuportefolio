use axum::http::StatusCode;

/// Check if the API is running
#[utoipa::path(
    get,
    path = "/health",
    tag = "health",
    responses(
        (status = 200, description = "API is healthy", body = String),
        (status = 500, description = "API is not healthy")
    )
)]
pub async fn health_check() -> &'static str {
    "ok"
}

/// Check if the database connection is working
#[utoipa::path(
    get,
    path = "/db-health",
    tag = "health",
    responses(
        (status = 200, description = "Database connection is healthy", body = String),
        (status = 500, description = "Database connection failed")
    )
)]
pub async fn db_health_check() -> Result<&'static str, (StatusCode, String)> {
    let mut client = crate::db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("DB connect error: {}", e)))?;

    client.simple_query("SELECT 1").await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Query error: {}", e)))?;

    Ok("database: ok")
} 
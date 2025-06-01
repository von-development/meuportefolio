use axum::{response::Json, http::StatusCode};
use serde_json::{json, Value};
use utoipa::ToSchema;
use crate::db::get_db_client;

/// Basic health check response
#[derive(serde::Serialize, ToSchema)]
pub struct HealthResponse {
    pub status: String,
    pub timestamp: String,
    pub version: String,
}

/// Database health check response
#[derive(serde::Serialize, ToSchema)]
pub struct DbHealthResponse {
    pub status: String,
    pub database: String,
    pub connection: String,
    pub timestamp: String,
}

/// Basic health check endpoint
/// 
/// Returns the current status of the API service
#[utoipa::path(
    get,
    path = "/health",
    responses(
        (status = 200, description = "Service is healthy", body = HealthResponse)
    ),
    tag = "health"
)]
pub async fn health_check() -> Json<Value> {
    Json(json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now().to_rfc3339(),
        "version": "1.0.0",
        "service": "Portfolio API"
    }))
}

/// Database connectivity health check
/// 
/// Tests the connection to the SQL Server database
#[utoipa::path(
    get,
    path = "/db-health",
    responses(
        (status = 200, description = "Database connection is healthy", body = DbHealthResponse),
        (status = 503, description = "Database connection failed")
    ),
    tag = "health"
)]
pub async fn db_health_check() -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    match get_db_client().await {
        Ok(_client) => {
            Ok(Json(json!({
                "status": "healthy",
                "database": "connected",
                "connection": "SQL Server",
                "timestamp": chrono::Utc::now().to_rfc3339(),
                "message": "Database connection successful"
            })))
        }
        Err(e) => {
            eprintln!("Database health check failed: {}", e);
            Err((
                StatusCode::SERVICE_UNAVAILABLE,
                Json(json!({
                    "status": "unhealthy",
                    "database": "disconnected",
                    "connection": "SQL Server",
                    "timestamp": chrono::Utc::now().to_rfc3339(),
                    "error": format!("Database connection failed: {}", e)
                }))
            ))
        }
    }
} 
use crate::db;

pub async fn health_check() -> &'static str {
    "ok"
}

pub async fn db_health_check() -> String {
    match db::get_db_client().await {
        Ok(_) => "database: ok".to_string(),
        Err(e) => format!("database: error - {}", e),
    }
} 
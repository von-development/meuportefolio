use axum::{Router, routing::get, Json};
use tiberius::{Client, Config, AuthMethod};
use tokio::net::TcpStream;
use tokio_util::compat::TokioAsyncWriteCompatExt;
use serde::Serialize;
use anyhow::Result;
use tiberius::time::chrono;
use futures_util::TryStreamExt;

#[derive(Serialize)]
pub struct Asset {
    pub asset_id: i32,
    pub name: String,
    pub symbol: String,
    pub asset_type: String,
    pub price: f64,
    pub volume: i64,
    pub available_shares: f64,
    pub last_updated: String,
}

// Health check that doesn't depend on database
async fn health_check() -> &'static str {
    "ok"
}

// Database health check
async fn db_health_check() -> String {
    // Read connection info from env or use defaults
    let db_host = std::env::var("DB_HOST").unwrap_or_else(|_| "db".to_string());
    let db_port = std::env::var("DB_PORT").ok().and_then(|p| p.parse().ok()).unwrap_or(1433);
    let db_user = std::env::var("DB_USER").unwrap_or_else(|_| "sa".to_string());
    let db_pass = std::env::var("DB_PASS").unwrap_or_else(|_| "meuportefolio!23".to_string());
    let db_name = std::env::var("DB_NAME").unwrap_or_else(|_| "meuportefolio".to_string());

    let mut config = Config::new();
    config.host(&db_host);
    config.port(db_port);
    config.authentication(AuthMethod::sql_server(&db_user, &db_pass));
    config.trust_cert();
    config.database(&db_name);

    match TcpStream::connect(config.get_addr()).await {
        Ok(tcp) => {
            let tcp = tcp.compat_write();
            match Client::connect(config, tcp).await {
                Ok(_) => "database: ok".to_string(),
                Err(e) => format!("database: error - {}", e),
            }
        }
        Err(e) => format!("database: error - {}", e),
    }
}

async fn list_assets() -> Result<Json<Vec<Asset>>, (axum::http::StatusCode, String)> {
    let mut config = Config::new();
    config.host("db");
    config.port(1433);
    config.authentication(AuthMethod::sql_server("sa", "meuportefolio!23"));
    config.trust_cert();
    config.database("meuportefolio");

    let tcp = TcpStream::connect(config.get_addr()).await.map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, format!("DB connect error: {}", e)))?;
    let tcp = tcp.compat_write();
    let mut client = Client::connect(config, tcp).await.map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, format!("DB client error: {}", e)))?;

    let query = "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated FROM portfolio.Assets";
    let stream = client.query(query, &[]).await.map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, format!("Query error: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| (axum::http::StatusCode::INTERNAL_SERVER_ERROR, format!("Row error: {}", e)))?;
    
    let assets = rows.into_iter().map(|row| Asset {
        asset_id: row.get("AssetID").unwrap_or_default(),
        name: row.get::<&str, _>("Name").unwrap_or("").to_string(),
        symbol: row.get::<&str, _>("Symbol").unwrap_or("").to_string(),
        asset_type: row.get::<&str, _>("AssetType").unwrap_or("").to_string(),
        price: row.get::<tiberius::numeric::Numeric, _>("Price")
            .map(|n| n.to_string().parse::<f64>().unwrap_or_default())
            .unwrap_or_default(),
        volume: row.get::<i64, _>("Volume").unwrap_or_default(),
        available_shares: row.get::<tiberius::numeric::Numeric, _>("AvailableShares")
            .map(|n| n.to_string().parse::<f64>().unwrap_or_default())
            .unwrap_or_default(),
        last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    }).collect();

    Ok(Json(assets))
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    
    let app = Router::new()
        .route("/health", get(health_check))
        .route("/db-health", get(db_health_check))
        .route("/assets", get(list_assets));

    // Start the server
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await?;
    println!("Server running on http://0.0.0.0:8080");
    println!("Health check available at http://localhost:8080/health");
    println!("Database health check available at http://localhost:8080/db-health");
    axum::serve(listener, app).await?;
    
    Ok(())
}

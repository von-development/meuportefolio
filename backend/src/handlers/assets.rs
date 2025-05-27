use axum::Json;
use crate::{models::Asset, db};
use tiberius::time::chrono;

/// List all assets
#[utoipa::path(
    get,
    path = "/assets",
    tag = "assets",
    responses(
        (status = 200, description = "List of assets retrieved successfully", body = Vec<Asset>),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn list_assets() -> Result<Json<Vec<Asset>>, (axum::http::StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (axum::http::StatusCode::INTERNAL_SERVER_ERROR, format!("DB connect error: {}", e)))?;

    let query = "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated FROM portfolio.Assets";
    let stream = client.query(query, &[]).await.map_err(|e| 
        (axum::http::StatusCode::INTERNAL_SERVER_ERROR, format!("Query error: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (axum::http::StatusCode::INTERNAL_SERVER_ERROR, format!("Row error: {}", e)))?;
    
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
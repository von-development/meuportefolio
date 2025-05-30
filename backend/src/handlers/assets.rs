use axum::{Json, extract::{Path, Query}};
use crate::{models::{Asset, AssetPriceHistory}, db};
use serde::Deserialize;
use axum::http::StatusCode;
use tiberius::time::chrono;

#[derive(Deserialize)]
pub struct AssetSearchQuery {
    pub query: Option<String>,
    pub asset_type: Option<String>,
}

/// List all assets with optional filtering
#[utoipa::path(
    get,
    path = "/api/v1/assets",
    tag = "assets",
    params(
        ("query" = Option<String>, Query, description = "Search term for asset name or symbol"),
        ("asset_type" = Option<String>, Query, description = "Filter by asset type")
    ),
    responses(
        (status = 200, description = "List of assets retrieved successfully", body = Vec<Asset>),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn list_assets(
    Query(params): Query<AssetSearchQuery>
) -> Result<Json<Vec<Asset>>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("DB connect error: {}", e)))?;

    struct QueryParams {
        query: String,
        params: Vec<Box<dyn tiberius::ToSql>>,
    }

    let query_params = match (&params.query, &params.asset_type) {
        (Some(search), Some(type_filter)) => {
            let pattern = format!("%{}%", search);
            QueryParams {
                query: "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated 
                       FROM portfolio.Assets 
                       WHERE (Name LIKE @P1 OR Symbol LIKE @P1) AND AssetType = @P2".to_string(),
                params: vec![
                    Box::new(pattern),
                    Box::new(type_filter.clone())
                ],
            }
        },
        (Some(search), None) => {
            let pattern = format!("%{}%", search);
            QueryParams {
                query: "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated 
                       FROM portfolio.Assets 
                       WHERE Name LIKE @P1 OR Symbol LIKE @P1".to_string(),
                params: vec![Box::new(pattern)],
            }
        },
        (None, Some(type_filter)) => QueryParams {
            query: "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated 
                   FROM portfolio.Assets 
                   WHERE AssetType = @P1".to_string(),
            params: vec![Box::new(type_filter.clone())],
        },
        (None, None) => QueryParams {
            query: "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated 
                   FROM portfolio.Assets".to_string(),
            params: vec![],
        },
    };

    let param_refs: Vec<&(dyn tiberius::ToSql)> = query_params.params.iter()
        .map(|p| p.as_ref() as &(dyn tiberius::ToSql))
        .collect();

    let stream = client.query(&query_params.query, &param_refs[..]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Query error: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Row error: {}", e)))?;
    
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

/// Get asset details by ID
#[utoipa::path(
    get,
    path = "/api/v1/assets/{assetId}",
    tag = "assets",
    params(
        ("assetId" = i32, Path, description = "Asset ID to fetch")
    ),
    responses(
        (status = 200, description = "Asset details retrieved successfully", body = Asset),
        (status = 404, description = "Asset not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_asset(Path(asset_id): Path<i32>) -> Result<Json<Asset>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let query = "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated 
                 FROM portfolio.Assets WHERE AssetID = @P1";
    
    let stream = client.query(query, &[&asset_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let row = stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::NOT_FOUND, "Asset not found".to_string()))?;

    let asset = Asset {
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
    };

    Ok(Json(asset))
}

/// Get asset price history
#[utoipa::path(
    get,
    path = "/api/v1/assets/{assetId}/price-history",
    tag = "assets",
    params(
        ("assetId" = i32, Path, description = "Asset ID to fetch price history for")
    ),
    responses(
        (status = 200, description = "Asset price history retrieved successfully", body = Vec<AssetPriceHistory>),
        (status = 404, description = "Asset not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_asset_price_history(Path(asset_id): Path<i32>) -> Result<Json<Vec<AssetPriceHistory>>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // First check if asset exists
    let check_query = "SELECT COUNT(*) as count FROM portfolio.Assets WHERE AssetID = @P1";
    let stream = client.query(check_query, &[&asset_id]).await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check asset existence: {}", e)))?;
    
    let result = stream.into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch asset check results: {}", e)))?;
    
    let count: i32 = result.first()
        .and_then(|row| row.get("count"))
        .unwrap_or(0);

    if count == 0 {
        return Err((StatusCode::NOT_FOUND, "Asset not found".to_string()));
    }

    let query = "SELECT 
                    ph.AssetID,
                    ph.Symbol,
                    ph.ClosePrice as Price,
                    ph.Volume,
                    ph.PriceDate as LastUpdated
                 FROM portfolio.vw_AssetPriceHistory ph
                 WHERE ph.AssetID = @P1 
                 ORDER BY ph.PriceDate DESC";

    let stream = client.query(query, &[&asset_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?;

    let history = rows.into_iter().map(|row| AssetPriceHistory {
        asset_id: row.get("AssetID").unwrap_or_default(),
        symbol: row.get::<&str, _>("Symbol").unwrap_or_default().to_string(),
        price: row.get::<tiberius::numeric::Numeric, _>("Price")
            .map(|n| n.to_string().parse::<f64>().unwrap_or_default())
            .unwrap_or_default(),
        volume: row.get::<i64, _>("Volume").unwrap_or_default(),
        timestamp: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    }).collect();

    Ok(Json(history))
}

/// List company assets
#[utoipa::path(
    get,
    path = "/api/v1/assets/companies",
    tag = "assets",
    responses(
        (status = 200, description = "List of company assets retrieved successfully", body = Vec<Asset>),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn list_companies() -> Result<Json<Vec<Asset>>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let query = "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated 
                 FROM portfolio.Assets WHERE AssetType = 'Company' ORDER BY Name";
    
    let stream = client.query(query, &[]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?;

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

/// List index assets
#[utoipa::path(
    get,
    path = "/api/v1/assets/indices",
    tag = "assets",
    responses(
        (status = 200, description = "List of index assets retrieved successfully", body = Vec<Asset>),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn list_indices() -> Result<Json<Vec<Asset>>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let query = "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated 
                 FROM portfolio.Assets WHERE AssetType = 'Index' ORDER BY Name";
    
    let stream = client.query(query, &[]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?;

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
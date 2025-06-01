use axum::{Json, extract::{Path, Query, Multipart}};
use crate::{models::{Asset, AssetPriceHistory, CreateAssetRequest, UpdateAssetRequest, CompleteAsset, StockDetails, CryptoDetails, CsvImportRequest, CsvImportResult, CsvRow, UpdatePriceRequest, UpdatePriceResponse, AssetFactory, AssetUtils}, db};
use serde::Deserialize;
use axum::http::StatusCode;
use tiberius::time::chrono;
use serde_json;

// Helper function to safely convert SQL Server Numeric to f64
fn numeric_to_f64(numeric: tiberius::numeric::Numeric) -> f64 {
    numeric.to_string().parse::<f64>().unwrap_or(0.0)
}

// Helper function to parse financial numbers from CSV (handles commas and K/M suffixes)
fn parse_financial_number(value: &str) -> Result<f64, String> {
    let cleaned = value.replace(",", "").replace("\"", "").trim().to_string();
    
    if cleaned.is_empty() || cleaned == "-" {
        return Ok(0.0);
    }
    
    // Handle K/M suffixes for volume
    if cleaned.ends_with('K') {
        let num_part = &cleaned[..cleaned.len()-1];
        num_part.parse::<f64>().map(|n| n * 1000.0).map_err(|_| format!("Invalid number format: {}", value))
    } else if cleaned.ends_with('M') {
        let num_part = &cleaned[..cleaned.len()-1];
        num_part.parse::<f64>().map(|n| n * 1000000.0).map_err(|_| format!("Invalid number format: {}", value))
    } else {
        cleaned.parse::<f64>().map_err(|_| format!("Invalid number format: {}", value))
    }
}

// Helper function to parse percentage values from CSV (handles % symbol)
fn parse_percentage(value: &str) -> Result<Option<f64>, String> {
    let cleaned = value.replace(",", "").replace("\"", "").replace("%", "").trim().to_string();
    
    if cleaned.is_empty() || cleaned == "-" {
        return Ok(None);
    }
    
    cleaned.parse::<f64>()
        .map(|v| Some(v))
        .map_err(|_| format!("Invalid percentage format: {}", value))
}

// Helper function to parse date from MM/DD/YYYY format
fn parse_csv_date(date_str: &str) -> Result<chrono::NaiveDateTime, String> {
    let cleaned = date_str.replace("\"", "").trim().to_string();
    chrono::NaiveDate::parse_from_str(&cleaned, "%m/%d/%Y")
        .map(|date| date.and_hms_opt(0, 0, 0).unwrap())
        .map_err(|_| format!("Invalid date format: {}", date_str))
}

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
            .map(numeric_to_f64)
            .unwrap_or_default(),
        volume: row.get::<i64, _>("Volume").unwrap_or_default(),
        available_shares: row.get::<tiberius::numeric::Numeric, _>("AvailableShares")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    }).collect();

    Ok(Json(assets))
}

/// Create a new asset
#[utoipa::path(
    post,
    path = "/api/v1/assets",
    tag = "assets",
    request_body = CreateAssetRequest,
    responses(
        (status = 201, description = "Asset created successfully", body = Asset),
        (status = 400, description = "Invalid request data"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn create_asset(Json(request): Json<CreateAssetRequest>) -> Result<Json<Asset>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Validate basic asset data using AssetUtils
    AssetUtils::validate_basic_asset_data(
        &request.symbol,
        &request.name,
        request.initial_price,
        request.initial_volume,
        request.available_shares
    ).map_err(|e| (StatusCode::BAD_REQUEST, e))?;

    // Validate asset type using AssetFactory
    let asset_type = AssetFactory::validate_asset_type(&request.asset_type)
        .map_err(|e| (StatusCode::BAD_REQUEST, e))?;

    // Normalize symbol
    let normalized_symbol = AssetUtils::normalize_symbol(&request.symbol);

    // Call stored procedure to create or get existing asset
    // Since handling OUTPUT parameters is complex in Tiberius, we'll use a different approach
    
    // First check if asset already exists
    let check_query = "SELECT AssetID FROM portfolio.Assets WHERE Symbol = @P1";
    let check_stream = client.query(check_query, &[&normalized_symbol]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check existing asset: {}", e)))?;
    
    let existing_result = check_stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch asset check: {}", e)))?;
    
    let asset_id: Option<i32> = existing_result.first().and_then(|row| row.get("AssetID"));
    
    if asset_id.is_none() {
        // Asset doesn't exist, create it directly
        let insert_query = "INSERT INTO portfolio.Assets (Symbol, Name, AssetType, Price, Volume, AvailableShares) 
                           VALUES (@P1, @P2, @P3, @P4, @P5, @P6)";
        let insert_stream = client.query(
            insert_query,
            &[
                &normalized_symbol,
                &request.name,
                &asset_type.to_string(),
                &request.initial_price.unwrap_or(0.0),
                &request.initial_volume.unwrap_or(0),
                &request.available_shares.unwrap_or(0.0)
            ],
        ).await.map_err(|e| {
            let error_msg = format!("{}", e);
            if error_msg.contains("UNIQUE KEY constraint") || error_msg.contains("duplicate") {
                // Another thread might have created it, that's ok
                (StatusCode::OK, "Asset already exists".to_string())
            } else {
                (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to create asset: {}", e))
            }
        })?;
        
        // Consume the insert result
        let _result = insert_stream.into_first_result().await.map_err(|e| 
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute insert: {}", e)))?;
    }

    // Now find the asset by symbol to get the ID
    let find_query = "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated 
                      FROM portfolio.Assets WHERE Symbol = @P1";
    
    let find_stream = client.query(find_query, &[&normalized_symbol]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to find created asset: {}", e)))?;
    
    let row = find_stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch created asset: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "Failed to retrieve created asset".to_string()))?;

    let asset = Asset {
        asset_id: row.get("AssetID").unwrap_or_default(),
        name: row.get::<&str, _>("Name").unwrap_or("").to_string(),
        symbol: row.get::<&str, _>("Symbol").unwrap_or("").to_string(),
        asset_type: row.get::<&str, _>("AssetType").unwrap_or("").to_string(),
        price: row.get::<tiberius::numeric::Numeric, _>("Price")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        volume: row.get::<i64, _>("Volume").unwrap_or_default(),
        available_shares: row.get::<tiberius::numeric::Numeric, _>("AvailableShares")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    };

    Ok(Json(asset))
}

/// Get asset details by ID
#[utoipa::path(
    get,
    path = "/api/v1/assets/{asset_id}",
    tag = "assets",
    params(
        ("asset_id" = i32, Path, description = "Asset ID to fetch")
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
            .map(numeric_to_f64)
            .unwrap_or_default(),
        volume: row.get::<i64, _>("Volume").unwrap_or_default(),
        available_shares: row.get::<tiberius::numeric::Numeric, _>("AvailableShares")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    };

    Ok(Json(asset))
}

/// Update asset basic information
#[utoipa::path(
    put,
    path = "/api/v1/assets/{asset_id}",
    tag = "assets",
    params(
        ("asset_id" = i32, Path, description = "Asset ID to update")
    ),
    request_body = UpdateAssetRequest,
    responses(
        (status = 200, description = "Asset updated successfully", body = Asset),
        (status = 404, description = "Asset not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn update_asset(
    Path(asset_id): Path<i32>,
    Json(request): Json<UpdateAssetRequest>
) -> Result<Json<Asset>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Check if asset exists
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

    // Build update query dynamically
    let mut set_clauses = Vec::new();
    let mut params: Vec<Box<dyn tiberius::ToSql>> = vec![Box::new(asset_id)];
    let mut param_index = 2;

    if let Some(name) = &request.name {
        set_clauses.push(format!("Name = @P{}", param_index));
        params.push(Box::new(name.clone()));
        param_index += 1;
    }

    if let Some(price) = request.price {
        set_clauses.push(format!("Price = @P{}", param_index));
        params.push(Box::new(price));
        param_index += 1;
    }

    if let Some(volume) = request.volume {
        set_clauses.push(format!("Volume = @P{}", param_index));
        params.push(Box::new(volume));
        param_index += 1;
    }

    if let Some(available_shares) = request.available_shares {
        set_clauses.push(format!("AvailableShares = @P{}", param_index));
        params.push(Box::new(available_shares));
    }

    if set_clauses.is_empty() {
        return Err((StatusCode::BAD_REQUEST, "No fields to update".to_string()));
    }

    let update_query = format!(
        "UPDATE portfolio.Assets SET {} WHERE AssetID = @P1",
        set_clauses.join(", ")
    );

    let param_refs: Vec<&(dyn tiberius::ToSql)> = params.iter()
        .map(|p| p.as_ref() as &(dyn tiberius::ToSql))
        .collect();

    let stream = client.query(&update_query, &param_refs[..]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to update asset: {}", e)))?;
    
    stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to confirm update: {}", e)))?;

    // Return updated asset
    get_asset(Path(asset_id)).await
}

/// Delete an asset and all its related data
#[utoipa::path(
    delete,
    path = "/api/v1/assets/{asset_id}",
    tag = "assets",
    params(
        ("asset_id" = i32, Path, description = "Asset ID to delete")
    ),
    responses(
        (status = 204, description = "Asset deleted successfully"),
        (status = 404, description = "Asset not found"),
        (status = 409, description = "Cannot delete asset with active holdings or transactions"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn delete_asset(Path(asset_id): Path<i32>) -> Result<StatusCode, (StatusCode, String)> {
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

    // Check for active holdings that would prevent deletion
    let holdings_query = "SELECT COUNT(*) as count FROM portfolio.PortfolioHoldings WHERE AssetID = @P1";
    let holdings_stream = client.query(holdings_query, &[&asset_id]).await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check asset holdings: {}", e)))?;
    
    let holdings_result = holdings_stream.into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch holdings check results: {}", e)))?;
    
    let holdings_count: i32 = holdings_result.first()
        .and_then(|row| row.get("count"))
        .unwrap_or(0);

    if holdings_count > 0 {
        return Err((StatusCode::CONFLICT, "Cannot delete asset with active holdings. Please ensure no portfolios hold this asset.".to_string()));
    }

    // Check for existing transactions that would prevent deletion
    let transactions_query = "SELECT COUNT(*) as count FROM portfolio.Transactions WHERE AssetID = @P1";
    let trans_stream = client.query(transactions_query, &[&asset_id]).await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check asset transactions: {}", e)))?;
    
    let trans_result = trans_stream.into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch transactions check results: {}", e)))?;
    
    let trans_count: i32 = trans_result.first()
        .and_then(|row| row.get("count"))
        .unwrap_or(0);

    if trans_count > 0 {
        return Err((StatusCode::CONFLICT, "Cannot delete asset with existing transaction history. Contact support if deletion is required.".to_string()));
    }

    // Delete the asset - cascade deletes will handle:
    // - AssetPrices (ON DELETE CASCADE)
    // - StockDetails (ON DELETE CASCADE)
    // - CryptoDetails (ON DELETE CASCADE)
    // - CommodityDetails (ON DELETE CASCADE)
    // - IndexDetails (ON DELETE CASCADE)
    let delete_query = "DELETE FROM portfolio.Assets WHERE AssetID = @P1";
    let delete_stream = client.query(delete_query, &[&asset_id]).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("REFERENCE constraint") || error_msg.contains("FOREIGN KEY") {
            (StatusCode::CONFLICT, "Cannot delete asset due to related data. Contact support if needed.".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to delete asset: {}", e))
        }
    })?;
    
    delete_stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to confirm deletion: {}", e)))?;

    Ok(StatusCode::NO_CONTENT)
}

/// Update asset current price
#[utoipa::path(
    post,
    path = "/api/v1/assets/{asset_id}/price",
    tag = "assets",
    params(
        ("asset_id" = i32, Path, description = "Asset ID to update price for")
    ),
    request_body = UpdatePriceRequest,
    responses(
        (status = 200, description = "Price updated successfully", body = UpdatePriceResponse),
        (status = 404, description = "Asset not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn update_asset_price(
    Path(asset_id): Path<i32>,
    Json(request): Json<UpdatePriceRequest>
) -> Result<Json<UpdatePriceResponse>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let volume = request.volume.unwrap_or(0);
    let query = "EXEC portfolio.sp_UpdateAssetPrice @P1, @P2, @P3";
    let stream = client.query(
        query,
        &[&asset_id, &request.price, &volume],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("Asset not found") {
            (StatusCode::NOT_FOUND, "Asset not found".to_string())
        } else if error_msg.contains("Price cannot be negative") {
            (StatusCode::BAD_REQUEST, "Price cannot be negative".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to update price: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch result: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned".to_string()))?;

    let response = UpdatePriceResponse {
        status: row.get::<&str, _>("Status").unwrap_or("SUCCESS").to_string(),
        message: row.get::<&str, _>("Message").unwrap_or("Price updated successfully").to_string(),
    };

    Ok(Json(response))
}

/// Get complete asset information with details
#[utoipa::path(
    get,
    path = "/api/v1/assets/{asset_id}/complete",
    tag = "assets",
    params(
        ("asset_id" = i32, Path, description = "Asset ID to fetch complete info for")
    ),
    responses(
        (status = 200, description = "Complete asset info retrieved successfully", body = CompleteAsset),
        (status = 404, description = "Asset not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_complete_asset(Path(asset_id): Path<i32>) -> Result<Json<CompleteAsset>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let query = "EXEC portfolio.sp_GetAssetComplete @P1";
    let stream = client.query(query, &[&asset_id]).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("Asset not found") {
            (StatusCode::NOT_FOUND, "Asset not found".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get complete asset: {}", e))
        }
    })?;

    // The stored procedure returns multiple result sets
    let results = stream.into_results().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?;

    if results.is_empty() {
        return Err((StatusCode::NOT_FOUND, "Asset not found".to_string()));
    }

    // First result set: basic asset info
    let asset_row = results[0].first()
        .ok_or((StatusCode::NOT_FOUND, "Asset not found".to_string()))?;

    let asset = Asset {
        asset_id: asset_row.get("AssetID").unwrap_or_default(),
        name: asset_row.get::<&str, _>("Name").unwrap_or("").to_string(),
        symbol: asset_row.get::<&str, _>("Symbol").unwrap_or("").to_string(),
        asset_type: asset_row.get::<&str, _>("AssetType").unwrap_or("").to_string(),
        price: asset_row.get::<tiberius::numeric::Numeric, _>("Price")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        volume: asset_row.get::<i64, _>("Volume").unwrap_or_default(),
        available_shares: asset_row.get::<tiberius::numeric::Numeric, _>("AvailableShares")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        last_updated: asset_row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    };

    // Initialize detail fields
    let mut stock_details = None;
    let mut crypto_details = None;
    let commodity_details = None;
    let index_details = None;

    // Second result set: asset-specific details (based on asset type)
    if results.len() > 1 && !results[1].is_empty() {
        match asset.asset_type.as_str() {
            "Stock" => {
                if let Some(detail_row) = results[1].first() {
                    stock_details = Some(StockDetails {
                        asset_id,
                        sector: detail_row.get::<&str, _>("Sector").unwrap_or("").to_string(),
                        country: detail_row.get::<&str, _>("Country").unwrap_or("").to_string(),
                        market_cap: detail_row.get::<tiberius::numeric::Numeric, _>("MarketCap")
                            .map(numeric_to_f64)
                            .unwrap_or_default(),
                        last_updated: detail_row.get::<chrono::NaiveDateTime, _>("LastUpdated")
                            .map(|dt| dt.to_string())
                            .unwrap_or_default(),
                    });
                }
            },
            "Cryptocurrency" => {
                if let Some(detail_row) = results[1].first() {
                    crypto_details = Some(CryptoDetails {
                        asset_id,
                        blockchain: detail_row.get::<&str, _>("Blockchain").unwrap_or("").to_string(),
                        max_supply: detail_row.get::<tiberius::numeric::Numeric, _>("MaxSupply")
                            .map(numeric_to_f64),
                        circulating_supply: detail_row.get::<tiberius::numeric::Numeric, _>("CirculatingSupply")
                            .map(numeric_to_f64)
                            .unwrap_or_default(),
                        last_updated: detail_row.get::<chrono::NaiveDateTime, _>("LastUpdated")
                            .map(|dt| dt.to_string())
                            .unwrap_or_default(),
                    });
                }
            },
            _ => {} // Handle other types as needed
        }
    }

    // Third result set: price history
    let mut recent_prices = Vec::new();
    if results.len() > 2 {
        println!("🔍 Processing price history result set with {} rows", results[2].len());
        
        recent_prices = results[2].iter().enumerate().map(|(index, row)| {
            let price = row.get::<tiberius::numeric::Numeric, _>("Price")
                .map(numeric_to_f64)
                .unwrap_or_default();
            let volume = row.get::<i64, _>("Volume").unwrap_or_default();
            let timestamp = row.get::<chrono::NaiveDateTime, _>("AsOf")
                .map(|dt| dt.to_string())
                .unwrap_or_default();
            
            // Try to get DaysAgo field if available (from new migration)
            let days_ago = row.get::<i32, _>("DaysAgo").unwrap_or(-1); // -1 indicates not available
            
            // Debug logging for first few and last few records
            if index < 3 || index >= results[2].len() - 3 {
                if days_ago >= 0 {
                    println!("📊 Price record {}: Date={}, Price={}, DaysAgo={}", index, timestamp, price, days_ago);
                } else {
                    println!("📊 Price record {}: Date={}, Price={}", index, timestamp, price);
                }
            }
            
            AssetPriceHistory {
                asset_id,
                symbol: asset.symbol.clone(),
                price,
                volume,
                timestamp,
            }
        }).collect();
        
        println!("✅ Loaded {} price history records for asset {}", recent_prices.len(), asset_id);
        
        // Log date range for debugging
        if !recent_prices.is_empty() {
            println!("📅 Date range: {} to {}", 
                recent_prices.first().unwrap().timestamp,
                recent_prices.last().unwrap().timestamp
            );
        }
    } else {
        println!("⚠️ No price history result set found for asset {}", asset_id);
    }

    let complete_asset = CompleteAsset {
        asset,
        stock_details,
        crypto_details,
        commodity_details,
        index_details,
        recent_prices,
    };

    Ok(Json(complete_asset))
}

/// Import asset price data from CSV file
#[utoipa::path(
    post,
    path = "/api/v1/assets/import/csv",
    tag = "assets",
    request_body(content = String, description = "Multipart form with CSV file and metadata"),
    responses(
        (status = 200, description = "CSV imported successfully", body = CsvImportResult),
        (status = 400, description = "Invalid CSV format or data"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn import_csv_prices(mut multipart: Multipart) -> Result<Json<CsvImportResult>, (StatusCode, String)> {
    let mut csv_content = String::new();
    let mut import_params = CsvImportRequest {
        symbol: String::new(),
        asset_name: None,
        asset_type: String::new(),
        update_current_price: Some(true),
        create_if_not_exists: Some(true),
        // Stock-specific fields
        sector: None,
        country: None,
        market_cap: None,
        // Crypto-specific fields
        blockchain: None,
        max_supply: None,
        circulating_supply: None,
        // Index-specific fields
        region: None,
        index_type: None,
        component_count: None,
        // Commodity-specific fields
        category: None,
        unit: None,
    };

    // Parse multipart form data
    while let Some(field) = multipart.next_field().await.map_err(|e| 
        (StatusCode::BAD_REQUEST, format!("Failed to parse form data: {}", e)))? {
        
        let name = field.name().unwrap_or("");
        
        match name {
            "file" => {
                csv_content = field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read file: {}", e)))?;
            },
            "symbol" => {
                import_params.symbol = field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read symbol: {}", e)))?;
            },
            "asset_name" => {
                import_params.asset_name = Some(field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read asset_name: {}", e)))?);
            },
            "asset_type" => {
                import_params.asset_type = field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read asset_type: {}", e)))?;
            },
            // Stock-specific fields
            "sector" => {
                import_params.sector = Some(field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read sector: {}", e)))?);
            },
            "country" => {
                import_params.country = Some(field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read country: {}", e)))?);
            },
            "market_cap" => {
                let text = field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read market_cap: {}", e)))?;
                import_params.market_cap = text.parse().ok();
            },
            // Crypto-specific fields
            "blockchain" => {
                import_params.blockchain = Some(field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read blockchain: {}", e)))?);
            },
            "max_supply" => {
                let text = field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read max_supply: {}", e)))?;
                import_params.max_supply = text.parse().ok();
            },
            "circulating_supply" => {
                let text = field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read circulating_supply: {}", e)))?;
                import_params.circulating_supply = text.parse().ok();
            },
            // Index-specific fields
            "region" => {
                import_params.region = Some(field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read region: {}", e)))?);
            },
            "index_type" => {
                import_params.index_type = Some(field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read index_type: {}", e)))?);
            },
            "component_count" => {
                let text = field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read component_count: {}", e)))?;
                import_params.component_count = text.parse().ok();
            },
            // Commodity-specific fields
            "category" => {
                import_params.category = Some(field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read category: {}", e)))?);
            },
            "unit" => {
                import_params.unit = Some(field.text().await.map_err(|e| 
                    (StatusCode::BAD_REQUEST, format!("Failed to read unit: {}", e)))?);
            },
            _ => {}
        }
    }

    if csv_content.is_empty() || import_params.symbol.is_empty() || import_params.asset_type.is_empty() {
        return Err((StatusCode::BAD_REQUEST, "CSV file, symbol and asset_type are required".to_string()));
    }

    // Validate asset type
    let _asset_type_enum = AssetFactory::validate_asset_type(&import_params.asset_type)
        .map_err(|e| (StatusCode::BAD_REQUEST, e))?;

    // Parse CSV content (same logic as before)
    let mut reader = csv::Reader::from_reader(csv_content.as_bytes());
    let mut records = Vec::new();
    let mut errors = Vec::new();

    for (line_num, result) in reader.records().enumerate() {
        match result {
            Ok(record) => {
                if record.len() >= 6 {
                    let csv_row = CsvRow {
                        date: record.get(0).unwrap_or("").to_string(),
                        price: record.get(1).unwrap_or("").to_string(),
                        open: record.get(2).unwrap_or("").to_string(),
                        high: record.get(3).unwrap_or("").to_string(),
                        low: record.get(4).unwrap_or("").to_string(),
                        volume: record.get(5).unwrap_or("").to_string(),
                        change_percent: record.get(6).unwrap_or("").to_string(),
                        // Enhanced optional fields
                        market_cap: record.get(7).map(|s| s.to_string()),
                        circulating_supply: record.get(8).map(|s| s.to_string()),
                        dividend_yield: record.get(9).map(|s| s.to_string()),
                        pe_ratio: record.get(10).map(|s| s.to_string()),
                    };
                    records.push((line_num + 2, csv_row)); // +2 because header is line 1, first data is line 2
                } else {
                    errors.push(format!("Line {}: Insufficient columns", line_num + 2));
                }
            },
            Err(e) => {
                errors.push(format!("Line {}: {}", line_num + 2, e));
            }
        }
    }

    if records.is_empty() {
        return Err((StatusCode::BAD_REQUEST, "No valid records found in CSV".to_string()));
    }

    // Process the records with database
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Ensure asset exists (same logic as before but with asset_type)
    let asset_id: i32;
    if import_params.create_if_not_exists.unwrap_or(true) {
        let asset_name = import_params.asset_name.as_ref()
            .map(|s| s.clone())
            .unwrap_or_else(|| import_params.symbol.clone());
        
        // First check if asset already exists
        let check_query = "SELECT AssetID FROM portfolio.Assets WHERE Symbol = @P1";
        let check_stream = client.query(check_query, &[&import_params.symbol]).await.map_err(|e| 
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check existing asset: {}", e)))?;
        
        let existing_result = check_stream.into_first_result().await.map_err(|e| 
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch asset check: {}", e)))?;
        
        let existing_asset_id: Option<i32> = existing_result.first().and_then(|row| row.get("AssetID"));
        
        if existing_asset_id.is_none() {
            // Asset doesn't exist, create it directly
            let insert_query = "INSERT INTO portfolio.Assets (Symbol, Name, AssetType, Price, Volume, AvailableShares) 
                               VALUES (@P1, @P2, @P3, @P4, @P5, @P6)";
            let insert_stream = client.query(
                insert_query,
                &[
                    &import_params.symbol.to_uppercase(),
                    &asset_name,
                    &import_params.asset_type,
                    &0.0f64, // initial price
                    &0i64,   // initial volume
                    &0.0f64  // available shares
                ],
            ).await.map_err(|e| {
                let error_msg = format!("{}", e);
                if error_msg.contains("UNIQUE KEY constraint") || error_msg.contains("duplicate") {
                    // Another thread might have created it, that's ok
                    (StatusCode::OK, "Asset already exists".to_string())
                } else {
                    (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to create asset: {}", e))
                }
            })?;
            
            // Consume the insert result
            let _result = insert_stream.into_first_result().await.map_err(|e| 
                (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute insert: {}", e)))?;
        }

        // Now find the asset by symbol to get the ID
        let find_query = "SELECT AssetID FROM portfolio.Assets WHERE Symbol = @P1";
        let find_stream = client.query(find_query, &[&import_params.symbol]).await.map_err(|e| 
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to find asset: {}", e)))?;
        
        let find_result = find_stream.into_first_result().await.map_err(|e| 
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch asset: {}", e)))?;
        
        asset_id = find_result.first()
            .and_then(|row| row.get("AssetID"))
            .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "Failed to get asset ID".to_string()))?;
    } else {
        // Find existing asset
        let find_query = "SELECT AssetID FROM portfolio.Assets WHERE Symbol = @P1";
        let find_stream = client.query(find_query, &[&import_params.symbol]).await.map_err(|e| 
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to find asset: {}", e)))?;
        
        let find_result = find_stream.into_first_result().await.map_err(|e| 
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch asset: {}", e)))?;
        
        asset_id = find_result.first()
            .and_then(|row| row.get("AssetID"))
            .ok_or((StatusCode::NOT_FOUND, "Asset not found".to_string()))?;
    }

    // Insert asset-specific details
    let details_status = insert_asset_details(&mut client, asset_id, &import_params.asset_type, &import_params).await
        .unwrap_or_else(|e| format!("Details insertion failed: {}", e));

    // Import price records (same logic as before)
    let mut records_imported = 0;
    let mut records_updated = 0;
    let mut records_failed = 0;

    for (line_num, record) in records {
        match process_csv_record(asset_id, &record, &mut client, import_params.update_current_price.unwrap_or(true)).await {
            Ok(was_update) => {
                if was_update {
                    records_updated += 1;
                } else {
                    records_imported += 1;
                }
            },
            Err(e) => {
                records_failed += 1;
                errors.push(format!("Line {}: {}", line_num, e));
            }
        }
    }

    let result = CsvImportResult {
        status: "SUCCESS".to_string(),
        asset_id,
        symbol: import_params.symbol,
        asset_type: import_params.asset_type,
        records_imported,
        records_updated,
        records_failed,
        errors,
        details_status: Some(details_status),
    };

    Ok(Json(result))
}

async fn process_csv_record(
    asset_id: i32,
    record: &CsvRow,
    client: &mut tiberius::Client<tokio_util::compat::Compat<tokio::net::TcpStream>>,
    update_current_price: bool
) -> Result<bool, String> {
    // Parse date
    let price_date = parse_csv_date(&record.date)?;
    
    // Parse prices
    let price = parse_financial_number(&record.price)?;
    let open_price = parse_financial_number(&record.open)?;
    let high_price = parse_financial_number(&record.high)?;
    let low_price = parse_financial_number(&record.low)?;
    let volume = parse_financial_number(&record.volume)? as i64;

    // Parse change percentage
    let change_percent = parse_percentage(&record.change_percent)?;

    // Import the price data with change percentage
    let query = "EXEC portfolio.sp_import_asset_price @P1, @P2, @P3, @P4, @P5, @P6, @P7, @P8, @P9";
    let stream = client.query(
        query,
        &[
            &asset_id,
            &price,
            &price_date,
            &open_price,
            &high_price,
            &low_price,
            &volume,
            &change_percent,
            &update_current_price,
        ],
    ).await.map_err(|e| format!("Database error: {}", e))?;

    let _results = stream.into_first_result().await
        .map_err(|e| format!("Failed to get import result: {}", e))?;

    // Check if this was an update vs insert (you'd need to adjust based on your procedure output)
    Ok(false) // Assuming new record for now
}

/// Get asset price history
#[utoipa::path(
    get,
    path = "/api/v1/assets/{asset_id}/price-history",
    tag = "assets",
    params(
        ("asset_id" = i32, Path, description = "Asset ID to fetch price history for")
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

    // Use the enhanced asset price history view for better performance and more data
    let query = "SELECT AssetID, Symbol, AssetName, ClosePrice, Volume, PriceDate,
                        OpenPrice, HighPrice, LowPrice, DailyChangePercent, DailyChangeAmount
                 FROM portfolio.vw_AssetPriceHistory 
                 WHERE AssetID = @P1 
                 ORDER BY PriceDate DESC";

    let stream = client.query(query, &[&asset_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?;

    let price_history: Vec<AssetPriceHistory> = rows.into_iter().map(|row| {
        AssetPriceHistory {
            asset_id: row.get("AssetID").unwrap_or_default(),
            symbol: row.get::<&str, _>("Symbol").unwrap_or("").to_string(),
            price: row.get::<tiberius::numeric::Numeric, _>("ClosePrice")
                .map(numeric_to_f64)
                .unwrap_or_default(),
            volume: row.get::<i64, _>("Volume").unwrap_or_default(),
            timestamp: row.get::<chrono::NaiveDateTime, _>("PriceDate")
                .map(|dt| dt.to_string())
                .unwrap_or_default(),
        }
    }).collect();

    println!("📊 Retrieved {} price history records for asset {} using vw_AssetPriceHistory view", 
        price_history.len(), asset_id);

    Ok(Json(price_history))
}

/// List companies (stocks only)
#[utoipa::path(
    get,
    path = "/api/v1/assets/companies",
    tag = "assets",
    responses(
        (status = 200, description = "List of companies retrieved successfully", body = Vec<Asset>),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn list_companies() -> Result<Json<Vec<Asset>>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("DB connect error: {}", e)))?;

    let query = "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated 
                 FROM portfolio.Assets WHERE AssetType = 'Stock'";
    let stream = client.query(query, &[]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Query error: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Row error: {}", e)))?;
    
    let assets = rows.into_iter().map(|row| Asset {
        asset_id: row.get("AssetID").unwrap_or_default(),
        name: row.get::<&str, _>("Name").unwrap_or("").to_string(),
        symbol: row.get::<&str, _>("Symbol").unwrap_or("").to_string(),
        asset_type: row.get::<&str, _>("AssetType").unwrap_or("").to_string(),
        price: row.get::<tiberius::numeric::Numeric, _>("Price")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        volume: row.get::<i64, _>("Volume").unwrap_or_default(),
        available_shares: row.get::<tiberius::numeric::Numeric, _>("AvailableShares")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    }).collect();

    Ok(Json(assets))
}

/// List indices only
#[utoipa::path(
    get,
    path = "/api/v1/assets/indices",
    tag = "assets",
    responses(
        (status = 200, description = "List of indices retrieved successfully", body = Vec<Asset>),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn list_indices() -> Result<Json<Vec<Asset>>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("DB connect error: {}", e)))?;

    let query = "SELECT AssetID, Name, Symbol, AssetType, Price, Volume, AvailableShares, LastUpdated 
                 FROM portfolio.Assets WHERE AssetType = 'Index'";
    let stream = client.query(query, &[]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Query error: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Row error: {}", e)))?;
    
    let assets = rows.into_iter().map(|row| Asset {
        asset_id: row.get("AssetID").unwrap_or_default(),
        name: row.get::<&str, _>("Name").unwrap_or("").to_string(),
        symbol: row.get::<&str, _>("Symbol").unwrap_or("").to_string(),
        asset_type: row.get::<&str, _>("AssetType").unwrap_or("").to_string(),
        price: row.get::<tiberius::numeric::Numeric, _>("Price")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        volume: row.get::<i64, _>("Volume").unwrap_or_default(),
        available_shares: row.get::<tiberius::numeric::Numeric, _>("AvailableShares")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    }).collect();

    Ok(Json(assets))
}

// Helper function to insert asset-specific details
async fn insert_asset_details(
    client: &mut tiberius::Client<tokio_util::compat::Compat<tokio::net::TcpStream>>,
    asset_id: i32,
    asset_type: &str,
    import_params: &CsvImportRequest,
) -> Result<String, String> {
    match asset_type {
        "Stock" => {
            if let (Some(sector), Some(country)) = (&import_params.sector, &import_params.country) {
                // Validate stock data
                AssetFactory::validate_stock_data(sector, country, import_params.market_cap)
                    .map_err(|e| format!("Stock validation failed: {}", e))?;

                let query = "INSERT INTO portfolio.StockDetails (AssetID, Sector, Country, MarketCap) VALUES (@P1, @P2, @P3, @P4)";
                let stream = client.query(
                    query,
                    &[&asset_id, sector, country, &import_params.market_cap.unwrap_or(0.0)],
                ).await.map_err(|e| format!("Failed to insert stock details: {}", e))?;

                stream.into_first_result().await.map_err(|e| 
                    format!("Failed to confirm stock details insert: {}", e))?;

                Ok("Stock details created successfully".to_string())
            } else {
                Ok("Stock created without detailed information".to_string())
            }
        },
        "Cryptocurrency" => {
            if let Some(blockchain) = &import_params.blockchain {
                // Validate crypto data
                AssetFactory::validate_crypto_data(blockchain, import_params.max_supply, import_params.circulating_supply)
                    .map_err(|e| format!("Crypto validation failed: {}", e))?;

                let query = "INSERT INTO portfolio.CryptoDetails (AssetID, Blockchain, MaxSupply, CirculatingSupply) VALUES (@P1, @P2, @P3, @P4)";
                let stream = client.query(
                    query,
                    &[&asset_id, blockchain, &import_params.max_supply, &import_params.circulating_supply.unwrap_or(0.0)],
                ).await.map_err(|e| format!("Failed to insert crypto details: {}", e))?;

                stream.into_first_result().await.map_err(|e| 
                    format!("Failed to confirm crypto details insert: {}", e))?;

                Ok("Cryptocurrency details created successfully".to_string())
            } else {
                Ok("Cryptocurrency created without detailed information".to_string())
            }
        },
        "Index" => {
            if let (Some(country), Some(region), Some(index_type)) = (&import_params.country, &import_params.region, &import_params.index_type) {
                // Validate index data
                AssetFactory::validate_index_data(country, region, index_type, import_params.component_count)
                    .map_err(|e| format!("Index validation failed: {}", e))?;

                let query = "INSERT INTO portfolio.IndexDetails (AssetID, Country, Region, IndexType, ComponentCount) VALUES (@P1, @P2, @P3, @P4, @P5)";
                let stream = client.query(
                    query,
                    &[&asset_id, country, region, index_type, &import_params.component_count],
                ).await.map_err(|e| format!("Failed to insert index details: {}", e))?;

                stream.into_first_result().await.map_err(|e| 
                    format!("Failed to confirm index details insert: {}", e))?;

                Ok("Index details created successfully".to_string())
            } else {
                Ok("Index created without detailed information".to_string())
            }
        },
        "Commodity" => {
            if let (Some(category), Some(unit)) = (&import_params.category, &import_params.unit) {
                // Validate commodity data
                AssetFactory::validate_commodity_data(category, unit)
                    .map_err(|e| format!("Commodity validation failed: {}", e))?;

                let query = "INSERT INTO portfolio.CommodityDetails (AssetID, Category, Unit) VALUES (@P1, @P2, @P3)";
                let stream = client.query(
                    query,
                    &[&asset_id, category, unit],
                ).await.map_err(|e| format!("Failed to insert commodity details: {}", e))?;

                stream.into_first_result().await.map_err(|e| 
                    format!("Failed to confirm commodity details insert: {}", e))?;

                Ok("Commodity details created successfully".to_string())
            } else {
                Ok("Commodity created without detailed information".to_string())
            }
        },
        _ => Ok(format!("Asset type '{}' created without specific details", asset_type))
    }
}

/// Get enhanced asset details using the vw_AssetDetails view
#[utoipa::path(
    get,
    path = "/api/v1/assets/{asset_id}/enhanced",
    tag = "assets",
    params(
        ("asset_id" = i32, Path, description = "Asset ID to fetch enhanced details for")
    ),
    responses(
        (status = 200, description = "Enhanced asset details retrieved successfully", body = serde_json::Value),
        (status = 404, description = "Asset not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_enhanced_asset_details(Path(asset_id): Path<i32>) -> Result<Json<serde_json::Value>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Use the enhanced asset details view
    let query = "SELECT * FROM portfolio.vw_AssetDetails WHERE AssetID = @P1";
    
    let stream = client.query(query, &[&asset_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let row = stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::NOT_FOUND, "Asset not found".to_string()))?;

    // Build enhanced asset details response
    let mut enhanced_details = serde_json::Map::new();
    
    // Basic asset info
    enhanced_details.insert("asset_id".to_string(), serde_json::Value::Number(serde_json::Number::from(asset_id)));
    enhanced_details.insert("name".to_string(), serde_json::Value::String(row.get::<&str, _>("Name").unwrap_or("").to_string()));
    enhanced_details.insert("symbol".to_string(), serde_json::Value::String(row.get::<&str, _>("Symbol").unwrap_or("").to_string()));
    enhanced_details.insert("asset_type".to_string(), serde_json::Value::String(row.get::<&str, _>("AssetType").unwrap_or("").to_string()));
    enhanced_details.insert("price".to_string(), serde_json::Value::Number(
        serde_json::Number::from_f64(row.get::<tiberius::numeric::Numeric, _>("Price").map(numeric_to_f64).unwrap_or_default()).unwrap()
    ));
    enhanced_details.insert("volume".to_string(), serde_json::Value::Number(serde_json::Number::from(row.get::<i64, _>("Volume").unwrap_or_default())));
    enhanced_details.insert("available_shares".to_string(), serde_json::Value::Number(
        serde_json::Number::from_f64(row.get::<tiberius::numeric::Numeric, _>("AvailableShares").map(numeric_to_f64).unwrap_or_default()).unwrap()
    ));
    enhanced_details.insert("last_updated".to_string(), serde_json::Value::String(
        row.get::<chrono::NaiveDateTime, _>("LastUpdated").map(|dt| dt.to_string()).unwrap_or_default()
    ));

    // Enhanced fields from the view
    if let Some(category_info) = row.get::<&str, _>("CategoryInfo") {
        enhanced_details.insert("category_info".to_string(), serde_json::Value::String(category_info.to_string()));
    }
    if let Some(additional_info) = row.get::<&str, _>("AdditionalInfo") {
        enhanced_details.insert("additional_info".to_string(), serde_json::Value::String(additional_info.to_string()));
    }
    if let Some(market_metric) = row.get::<tiberius::numeric::Numeric, _>("MarketMetric") {
        enhanced_details.insert("market_metric".to_string(), serde_json::Value::Number(
            serde_json::Number::from_f64(numeric_to_f64(market_metric)).unwrap()
        ));
    }
    if let Some(price_30_days_ago) = row.get::<tiberius::numeric::Numeric, _>("Price30DaysAgo") {
        enhanced_details.insert("price_30_days_ago".to_string(), serde_json::Value::Number(
            serde_json::Number::from_f64(numeric_to_f64(price_30_days_ago)).unwrap()
        ));
    }

    // Holdings statistics
    enhanced_details.insert("total_quantity_held".to_string(), serde_json::Value::Number(
        serde_json::Number::from_f64(row.get::<tiberius::numeric::Numeric, _>("TotalQuantityHeld").map(numeric_to_f64).unwrap_or_default()).unwrap()
    ));
    enhanced_details.insert("total_portfolios_holding".to_string(), serde_json::Value::Number(
        serde_json::Number::from(row.get::<i32, _>("TotalPortfoliosHolding").unwrap_or_default())
    ));

    Ok(Json(serde_json::Value::Object(enhanced_details)))
} 
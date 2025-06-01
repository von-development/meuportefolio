// LEMBRAR DO THROWBACK EM SQL 

use axum::{Json, extract::{Path, Query}};
use crate::{models::{Portfolio, CreatePortfolioRequest, UpdatePortfolioRequest, PortfolioSummary, AssetHolding, BuyAssetRequest, BuyAssetResponse, SellAssetRequest, SellAssetResponse, PortfolioBalance, PortfolioHoldingsSummary, PortfolioHolding}, db};
use uuid::Uuid;
use axum::http::StatusCode;
use serde::Deserialize;

// Helper function to safely convert SQL Server Numeric to f64
fn numeric_to_f64(numeric: tiberius::numeric::Numeric) -> f64 {
    numeric.to_string().parse::<f64>().unwrap_or(0.0)
}

#[derive(Deserialize)]
pub struct ListPortfoliosQuery {
    pub user_id: Option<Uuid>,
}

/// List all portfolios for a user
#[utoipa::path(
    get,
    path = "/api/v1/portfolios",
    tag = "portfolios",
    params(
        ("user_id" = Option<String>, Query, description = "Filter portfolios by user ID")
    ),
    responses(
        (status = 200, description = "List of portfolios retrieved successfully", body = Vec<Portfolio>),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn list_portfolios(
    Query(query): Query<ListPortfoliosQuery>
) -> Result<Json<Vec<Portfolio>>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Store the UUID bytes in a variable that lives for the entire function
    let uuid_bytes = query.user_id.map(|id| tiberius::Uuid::from_bytes(*id.as_bytes()));
    
    let (query_str, params) = if let Some(ref uuid) = uuid_bytes {
        (
            "SELECT PortfolioID, UserID, Name, CreationDate, CurrentFunds, CurrentProfitPct, LastUpdated 
             FROM portfolio.Portfolios 
             WHERE UserID = @P1 
             ORDER BY CreationDate DESC",
            vec![uuid as &(dyn tiberius::ToSql)]
        )
    } else {
        (
            "SELECT PortfolioID, UserID, Name, CreationDate, CurrentFunds, CurrentProfitPct, LastUpdated 
             FROM portfolio.Portfolios 
             ORDER BY CreationDate DESC",
            vec![]
        )
    };

    let stream = client.query(query_str, &params[..])
        .await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?;
    
    let portfolios = rows.into_iter().map(|row| {
        let current_funds = row.get::<tiberius::numeric::Numeric, _>("CurrentFunds")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default();
            
        let current_profit_pct = row.get::<tiberius::numeric::Numeric, _>("CurrentProfitPct")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default();

        Portfolio {
            portfolio_id: row.get("PortfolioID").unwrap_or_default(),
            user_id: row.get::<tiberius::Uuid, _>("UserID")
                .map(|uuid| Uuid::from_bytes(*uuid.as_bytes()))
                .unwrap_or_default(),
            name: row.get::<&str, _>("Name").unwrap_or_default().to_string(),
            creation_date: row.get::<chrono::NaiveDateTime, _>("CreationDate")
                .map(|dt| dt.to_string())
                .unwrap_or_default(),
            current_funds,
            current_profit_pct,
            last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
                .map(|dt| dt.to_string())
                .unwrap_or_default(),
        }
    }).collect();

    Ok(Json(portfolios))
}

/// Create a new portfolio
#[utoipa::path(
    post,
    path = "/api/v1/portfolios",
    tag = "portfolios",
    request_body = CreatePortfolioRequest,
    responses(
        (status = 201, description = "Portfolio created successfully", body = Portfolio),
        (status = 400, description = "Invalid request data"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn create_portfolio(Json(portfolio): Json<CreatePortfolioRequest>) -> Result<Json<Portfolio>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Use 0.0 as default if initial_funds is not provided
    let initial_funds = portfolio.initial_funds.unwrap_or(0.0);
    
    // Use stored procedure for creation
    let query = "EXEC portfolio.sp_CreatePortfolio @P1, @P2, @P3";
    
    let stream = client.query(
        query,
        &[
            &tiberius::Uuid::from_bytes(*portfolio.user_id.as_bytes()),
            &portfolio.name,
            &initial_funds,
        ],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User does not exist") {
            (StatusCode::BAD_REQUEST, "User does not exist".to_string())
        } else if error_msg.contains("Portfolio name is required") {
            (StatusCode::BAD_REQUEST, "Portfolio name is required".to_string())
        } else if error_msg.contains("Initial funds cannot be negative") {
            (StatusCode::BAD_REQUEST, "Initial funds cannot be negative".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to create portfolio: {}", e))
        }
    })?;

    let row = stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get created portfolio: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned from create portfolio".to_string()))?;

    let created_portfolio = Portfolio {
        portfolio_id: row.get("PortfolioID").unwrap_or_default(),
        user_id: portfolio.user_id,
        name: row.get::<&str, _>("Name").unwrap_or_default().to_string(),
        creation_date: row.get::<chrono::NaiveDateTime, _>("CreationDate")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
        current_funds: row.get::<tiberius::numeric::Numeric, _>("CurrentFunds")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default(),
        current_profit_pct: row.get::<tiberius::numeric::Numeric, _>("CurrentProfitPct")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default(),
        last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    };

    Ok(Json(created_portfolio))
}

/// Get portfolio details
#[utoipa::path(
    get,
    path = "/api/v1/portfolios/{portfolio_id}",
    tag = "portfolios",
    params(
        ("portfolio_id" = i32, Path, description = "Portfolio ID to fetch")
    ),
    responses(
        (status = 200, description = "Portfolio found successfully", body = Portfolio),
        (status = 404, description = "Portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_portfolio(Path(portfolio_id): Path<i32>) -> Result<Json<Portfolio>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let query = "SELECT * FROM portfolio.Portfolios WHERE PortfolioID = @P1";
    let stream = client.query(query, &[&portfolio_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let row = stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::NOT_FOUND, "Portfolio not found".to_string()))?;

    let portfolio = Portfolio {
        portfolio_id: row.get("PortfolioID").unwrap_or_default(),
        user_id: row.get::<tiberius::Uuid, _>("UserID")
            .map(|uuid| Uuid::from_bytes(*uuid.as_bytes()))
            .unwrap_or_default(),
        name: row.get::<&str, _>("Name").unwrap_or_default().to_string(),
        creation_date: row.get::<chrono::NaiveDateTime, _>("CreationDate")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
        current_funds: row.get::<tiberius::numeric::Numeric, _>("CurrentFunds")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default(),
        current_profit_pct: row.get::<tiberius::numeric::Numeric, _>("CurrentProfitPct")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default(),
        last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    };

    Ok(Json(portfolio))
}

/// Get portfolio summary
#[utoipa::path(
    get,
    path = "/api/v1/portfolios/{portfolio_id}/summary",
    tag = "portfolios",
    params(
        ("portfolio_id" = i32, Path, description = "Portfolio ID to fetch summary for")
    ),
    responses(
        (status = 200, description = "Portfolio summary retrieved successfully", body = PortfolioSummary),
        (status = 404, description = "Portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_portfolio_summary(Path(portfolio_id): Path<i32>) -> Result<Json<PortfolioSummary>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // First check if portfolio exists
    let check_query = "SELECT COUNT(*) as count FROM portfolio.Portfolios WHERE PortfolioID = @P1";
    let stream = client.query(check_query, &[&portfolio_id]).await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check portfolio existence: {}", e)))?;
    
    let result = stream.into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch portfolio check results: {}", e)))?;
    
    let count: i32 = result.first()
        .and_then(|row| row.get("count"))
        .unwrap_or(0);

    if count == 0 {
        return Err((StatusCode::NOT_FOUND, "Portfolio not found".to_string()));
    }

    // Use the enhanced portfolio summary view
    let query = "SELECT * FROM portfolio.vw_PortfolioSummary WHERE PortfolioID = @P1";
    let stream = client.query(query, &[&portfolio_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let row = stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::NOT_FOUND, "Portfolio summary not found".to_string()))?;

    let summary = PortfolioSummary {
        portfolio_id: row.get("PortfolioID").unwrap_or_default(),
        portfolio_name: row.get::<&str, _>("PortfolioName").unwrap_or_default().to_string(),
        owner: row.get::<&str, _>("OwnerName").unwrap_or_default().to_string(),
        current_funds: row.get::<tiberius::numeric::Numeric, _>("CurrentFunds")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default(),
        current_profit_pct: row.get::<tiberius::numeric::Numeric, _>("UnrealizedGainLossPercent")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default(),
        creation_date: row.get::<chrono::NaiveDateTime, _>("CreationDate")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
        total_trades: row.get("TotalTrades").unwrap_or_default(),
    };

    Ok(Json(summary))
}

/// Get portfolio holdings
#[utoipa::path(
    get,
    path = "/api/v1/portfolios/{portfolio_id}/holdings",
    tag = "portfolios",
    params(
        ("portfolio_id" = i32, Path, description = "Portfolio ID to fetch holdings for")
    ),
    responses(
        (status = 200, description = "Portfolio holdings retrieved successfully", body = Vec<AssetHolding>),
        (status = 404, description = "Portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_portfolio_holdings(Path(portfolio_id): Path<i32>) -> Result<Json<Vec<AssetHolding>>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // First check if portfolio exists
    let check_query = "SELECT COUNT(*) as count FROM portfolio.Portfolios WHERE PortfolioID = @P1";
    let stream = client.query(check_query, &[&portfolio_id]).await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check portfolio existence: {}", e)))?;
    
    let result = stream.into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch portfolio check results: {}", e)))?;
    
    let count: i32 = result.first()
        .and_then(|row| row.get("count"))
        .unwrap_or(0);

    if count == 0 {
        return Err((StatusCode::NOT_FOUND, "Portfolio not found".to_string()));
    }

    // Use the correct view name for portfolio holdings
    let query = "SELECT * FROM portfolio.vw_PortfolioHoldings WHERE PortfolioID = @P1";
    let stream = client.query(query, &[&portfolio_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?;

    let holdings = rows.into_iter().map(|row| {
        AssetHolding {
            portfolio_id: row.get("PortfolioID").unwrap_or_default(),
            portfolio_name: row.get::<&str, _>("PortfolioName").unwrap_or_default().to_string(),
            asset_id: row.get("AssetID").unwrap_or_default(),
            asset_name: row.get::<&str, _>("AssetName").unwrap_or_default().to_string(),
            symbol: row.get::<&str, _>("Symbol").unwrap_or_default().to_string(),
            asset_type: row.get::<&str, _>("AssetType").unwrap_or_default().to_string(),
            quantity_held: row.get::<tiberius::numeric::Numeric, _>("QuantityHeld")
                .map(|n| numeric_to_f64(n))
                .unwrap_or_default(),
            current_price: row.get::<tiberius::numeric::Numeric, _>("CurrentPrice")
                .map(|n| numeric_to_f64(n))
                .unwrap_or_default(),
            market_value: row.get::<tiberius::numeric::Numeric, _>("CurrentValue")
                .map(|n| numeric_to_f64(n))
                .unwrap_or_default(),
        }
    }).collect();

    Ok(Json(holdings))
}

/// Update portfolio
#[utoipa::path(
    put,
    path = "/api/v1/portfolios/{portfolio_id}",
    tag = "portfolios",
    params(
        ("portfolio_id" = i32, Path, description = "Portfolio ID to update")
    ),
    request_body = UpdatePortfolioRequest,
    responses(
        (status = 200, description = "Portfolio updated successfully", body = Portfolio),
        (status = 404, description = "Portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn update_portfolio(
    Path(portfolio_id): Path<i32>,
    Json(update): Json<UpdatePortfolioRequest>
) -> Result<Json<Portfolio>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Use stored procedure for update
    let query = "EXEC portfolio.sp_UpdatePortfolio @P1, @P2, @P3";
    
    // Prepare parameters - pass NULL for fields that shouldn't be updated
    let name_param: Option<&str> = update.name.as_deref();
    let funds_param: Option<f64> = update.current_funds;

    let stream = client.query(
        query,
        &[
            &portfolio_id,
            &name_param,
            &funds_param,
        ],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("Portfolio not found") {
            (StatusCode::NOT_FOUND, "Portfolio not found".to_string())
        } else if error_msg.contains("No fields to update") {
            (StatusCode::BAD_REQUEST, "No fields to update".to_string())
        } else if error_msg.contains("Portfolio name cannot be empty") {
            (StatusCode::BAD_REQUEST, "Portfolio name cannot be empty".to_string())
        } else if error_msg.contains("Current funds cannot be negative") {
            (StatusCode::BAD_REQUEST, "Current funds cannot be negative".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to update portfolio: {}", e))
        }
    })?;
    
    let row = stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch updated portfolio: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::NOT_FOUND, "Portfolio not found".to_string()))?;

    let portfolio = Portfolio {
        portfolio_id: row.get("PortfolioID").unwrap_or_default(),
        user_id: row.get::<tiberius::Uuid, _>("UserID")
            .map(|uuid| Uuid::from_bytes(*uuid.as_bytes()))
            .unwrap_or_default(),
        name: row.get::<&str, _>("Name").unwrap_or_default().to_string(),
        creation_date: row.get::<chrono::NaiveDateTime, _>("CreationDate")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
        current_funds: row.get::<tiberius::numeric::Numeric, _>("CurrentFunds")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default(),
        current_profit_pct: row.get::<tiberius::numeric::Numeric, _>("CurrentProfitPct")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default(),
        last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    };

    Ok(Json(portfolio))
}

/// Delete portfolio
#[utoipa::path(
    delete,
    path = "/api/v1/portfolios/{portfolio_id}",
    tag = "portfolios",
    params(
        ("portfolio_id" = i32, Path, description = "Portfolio ID to delete")
    ),
    responses(
        (status = 204, description = "Portfolio deleted successfully"),
        (status = 404, description = "Portfolio not found"),
        (status = 409, description = "Cannot delete portfolio with active holdings or transactions"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn delete_portfolio(Path(portfolio_id): Path<i32>) -> Result<StatusCode, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // First check if portfolio exists
    let check_query = "SELECT COUNT(*) as count FROM portfolio.Portfolios WHERE PortfolioID = @P1";
    let stream = client.query(check_query, &[&portfolio_id]).await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check portfolio existence: {}", e)))?;
    
    let result = stream.into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch portfolio check results: {}", e)))?;
    
    let count: i32 = result.first()
        .and_then(|row| row.get("count"))
        .unwrap_or(0);

    if count == 0 {
        return Err((StatusCode::NOT_FOUND, "Portfolio not found".to_string()));
    }

    // Check for active holdings that would prevent deletion
    let holdings_query = "SELECT COUNT(*) as count FROM portfolio.PortfolioHoldings WHERE PortfolioID = @P1";
    let holdings_stream = client.query(holdings_query, &[&portfolio_id]).await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check portfolio holdings: {}", e)))?;
    
    let holdings_result = holdings_stream.into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch holdings check results: {}", e)))?;
    
    let holdings_count: i32 = holdings_result.first()
        .and_then(|row| row.get("count"))
        .unwrap_or(0);

    if holdings_count > 0 {
        return Err((StatusCode::CONFLICT, "Cannot delete portfolio with active holdings. Please sell all assets first.".to_string()));
    }

    // Try to delete the portfolio - foreign key constraints will handle cleanup of related data
    let delete_query = "DELETE FROM portfolio.Portfolios WHERE PortfolioID = @P1";
    let delete_stream = client.query(delete_query, &[&portfolio_id]).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("REFERENCE constraint") || error_msg.contains("FOREIGN KEY") {
            (StatusCode::CONFLICT, "Cannot delete portfolio due to related transactions. Contact support if needed.".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to delete portfolio: {}", e))
        }
    })?;
    
    delete_stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to confirm deletion: {}", e)))?;

    Ok(StatusCode::NO_CONTENT)
}

// =============================================================
// TRADING ENDPOINTS
// =============================================================

/// Buy an asset in a portfolio
#[utoipa::path(
    post,
    path = "/api/v1/portfolios/buy",
    tag = "portfolios",
    request_body = BuyAssetRequest,
    responses(
        (status = 200, description = "Asset purchased successfully", body = BuyAssetResponse),
        (status = 400, description = "Invalid request data or insufficient funds"),
        (status = 404, description = "User, portfolio or asset not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn buy_asset(
    Json(request): Json<BuyAssetRequest>
) -> Result<Json<BuyAssetResponse>, (StatusCode, String)> {
    if request.quantity <= 0.0 {
        return Err((StatusCode::BAD_REQUEST, "Quantity must be positive".to_string()));
    }

    if let Some(price) = request.unit_price {
        if price <= 0.0 {
            return Err((StatusCode::BAD_REQUEST, "Unit price must be positive".to_string()));
        }
    }

    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Get the user ID from the portfolio - this is needed for the stored procedure
    let user_query = "SELECT UserID FROM portfolio.Portfolios WHERE PortfolioID = @P1";
    let user_stream = client.query(user_query, &[&request.portfolio_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get portfolio owner: {}", e)))?;
    
    let user_rows = user_stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch portfolio owner: {}", e)))?;
    
    let user_id = user_rows.into_iter().next()
        .and_then(|row| row.get::<tiberius::Uuid, _>("UserID"))
        .ok_or((StatusCode::NOT_FOUND, "Portfolio not found".to_string()))?;

    // Use the comprehensive stored procedure that handles PortfolioHoldings automatically
    let query = "EXEC portfolio.sp_BuyAsset @P1, @P2, @P3, @P4, @P5";
    let unit_price_param: Option<f64> = request.unit_price;
    let stream = client.query(
        query,
        &[
            &user_id, 
            &request.portfolio_id, 
            &request.asset_id, 
            &request.quantity, 
            &unit_price_param
        ],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User not found") || error_msg.contains("does not belong to user") {
            (StatusCode::NOT_FOUND, "User or portfolio not found".to_string())
        } else if error_msg.contains("Asset not found") {
            (StatusCode::NOT_FOUND, "Asset not found".to_string())
        } else if error_msg.contains("Insufficient funds") {
            (StatusCode::BAD_REQUEST, "Insufficient portfolio funds to buy asset".to_string())
        } else if error_msg.contains("Insufficient available shares") {
            (StatusCode::BAD_REQUEST, "Insufficient available shares".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to buy asset: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch buy result: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned from buy operation".to_string()))?;

    let transaction_id: i64 = row.get("TransactionID").unwrap_or(0);
    let quantity_purchased: f64 = row.get::<tiberius::numeric::Numeric, _>("QuantityPurchased")
        .map(|n| numeric_to_f64(n))
        .unwrap_or(request.quantity);
    let price_per_share: f64 = row.get::<tiberius::numeric::Numeric, _>("PricePerShare")
        .map(|n| numeric_to_f64(n))
        .unwrap_or_default();
    let total_cost: f64 = row.get::<tiberius::numeric::Numeric, _>("TotalCost")
        .map(|n| numeric_to_f64(n))
        .unwrap_or_default();
    let remaining_funds: f64 = row.get::<tiberius::numeric::Numeric, _>("RemainingFunds")
        .map(|n| numeric_to_f64(n))
        .unwrap_or_default();

    Ok(Json(BuyAssetResponse {
        status: "Success".to_string(),
        transaction_id,
        quantity_purchased,
        price_per_share,
        total_cost,
        remaining_funds,
    }))
}

/// Sell an asset from a portfolio
#[utoipa::path(
    post,
    path = "/api/v1/portfolios/sell",
    tag = "portfolios",
    request_body = SellAssetRequest,
    responses(
        (status = 200, description = "Asset sold successfully", body = SellAssetResponse),
        (status = 400, description = "Invalid request data or insufficient holdings"),
        (status = 404, description = "User, portfolio, asset or holdings not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn sell_asset(
    Json(request): Json<SellAssetRequest>
) -> Result<Json<SellAssetResponse>, (StatusCode, String)> {
    if request.quantity <= 0.0 {
        return Err((StatusCode::BAD_REQUEST, "Quantity must be positive".to_string()));
    }

    if let Some(price) = request.unit_price {
        if price <= 0.0 {
            return Err((StatusCode::BAD_REQUEST, "Unit price must be positive".to_string()));
        }
    }

    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Get the user ID from the portfolio - this is needed for the stored procedure
    let user_query = "SELECT UserID FROM portfolio.Portfolios WHERE PortfolioID = @P1";
    let user_stream = client.query(user_query, &[&request.portfolio_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get portfolio owner: {}", e)))?;
    
    let user_rows = user_stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch portfolio owner: {}", e)))?;
    
    let user_id = user_rows.into_iter().next()
        .and_then(|row| row.get::<tiberius::Uuid, _>("UserID"))
        .ok_or((StatusCode::NOT_FOUND, "Portfolio not found".to_string()))?;

    // Use the comprehensive stored procedure that handles PortfolioHoldings automatically
    let query = "EXEC portfolio.sp_SellAsset @P1, @P2, @P3, @P4, @P5";
    let unit_price_param: Option<f64> = request.unit_price;
    let stream = client.query(
        query,
        &[
            &user_id, 
            &request.portfolio_id, 
            &request.asset_id, 
            &request.quantity, 
            &unit_price_param
        ],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User not found") || error_msg.contains("does not belong to user") {
            (StatusCode::NOT_FOUND, "User or portfolio not found".to_string())
        } else if error_msg.contains("Asset not found") {
            (StatusCode::NOT_FOUND, "Asset not found".to_string())
        } else if error_msg.contains("No holdings found") || error_msg.contains("Insufficient holdings") {
            (StatusCode::BAD_REQUEST, "Insufficient holdings to sell".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to sell asset: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch sell result: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned from sell operation".to_string()))?;

    let transaction_id: i64 = row.get("TransactionID").unwrap_or(0);
    let quantity_sold: f64 = row.get::<tiberius::numeric::Numeric, _>("QuantitySold")
        .map(|n| numeric_to_f64(n))
        .unwrap_or(request.quantity);
    let price_per_share: f64 = row.get::<tiberius::numeric::Numeric, _>("PricePerShare")
        .map(|n| numeric_to_f64(n))
        .unwrap_or_default();
    let total_proceeds: f64 = row.get::<tiberius::numeric::Numeric, _>("TotalProceeds")
        .map(|n| numeric_to_f64(n))
        .unwrap_or_default();
    let new_funds_balance: f64 = row.get::<tiberius::numeric::Numeric, _>("NewFunds")
        .map(|n| numeric_to_f64(n))
        .unwrap_or_default();

    Ok(Json(SellAssetResponse {
        status: "Success".to_string(),
        transaction_id,
        quantity_sold,
        price_per_share,
        total_proceeds,
        new_funds_balance,
    }))
}

/// Get portfolio balance information
#[utoipa::path(
    get,
    path = "/api/v1/portfolios/{portfolio_id}/balance",
    tag = "portfolios",
    params(
        ("portfolio_id" = i32, Path, description = "Portfolio ID to get balance for")
    ),
    responses(
        (status = 200, description = "Portfolio balance retrieved successfully", body = PortfolioBalance),
        (status = 404, description = "Portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_portfolio_balance(
    Path(portfolio_id): Path<i32>
) -> Result<Json<PortfolioBalance>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Use the enhanced portfolio summary view for consistent data
    let query = "SELECT * FROM portfolio.vw_PortfolioSummary WHERE PortfolioID = @P1";
    let stream = client.query(query, &[&portfolio_id]).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("not found") {
            (StatusCode::NOT_FOUND, "Portfolio not found".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get portfolio balance: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch portfolio balance: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::NOT_FOUND, "Portfolio not found".to_string()))?;

    let cash_balance = row.get::<tiberius::numeric::Numeric, _>("CurrentFunds")
        .map(|n| numeric_to_f64(n))
        .unwrap_or_default();
    let holdings_value = row.get::<tiberius::numeric::Numeric, _>("CurrentMarketValue")
        .map(|n| numeric_to_f64(n))
        .unwrap_or_default();

    let balance = PortfolioBalance {
        portfolio_id,
        portfolio_name: row.get::<&str, _>("PortfolioName").unwrap_or("").to_string(),
        cash_balance,
        holdings_value,
        total_portfolio_value: cash_balance + holdings_value,
        holdings_count: row.get::<i32, _>("TotalHoldings"),
    };

    Ok(Json(balance))
}

/// Get detailed portfolio holdings information
#[utoipa::path(
    get,
    path = "/api/v1/portfolios/{portfolio_id}/holdings-summary",
    tag = "portfolios",
    params(
        ("portfolio_id" = i32, Path, description = "Portfolio ID to get holdings summary for")
    ),
    responses(
        (status = 200, description = "Portfolio holdings summary retrieved successfully", body = PortfolioHoldingsSummary),
        (status = 404, description = "Portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_portfolio_holdings_summary(
    Path(portfolio_id): Path<i32>
) -> Result<Json<PortfolioHoldingsSummary>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // First check if portfolio exists and get its name
    let portfolio_query = "SELECT Name FROM portfolio.Portfolios WHERE PortfolioID = @P1";
    let portfolio_stream = client.query(portfolio_query, &[&portfolio_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get portfolio: {}", e)))?;
    
    let portfolio_rows = portfolio_stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch portfolio: {}", e)))?;
    
    let portfolio_name = portfolio_rows.into_iter().next()
        .and_then(|row| row.get::<&str, _>("Name").map(|s| s.to_string()))
        .ok_or((StatusCode::NOT_FOUND, "Portfolio not found".to_string()))?;

    // Use the enhanced portfolio holdings view for detailed information
    let holdings_query = "SELECT * FROM portfolio.vw_PortfolioHoldings WHERE PortfolioID = @P1";
    
    let holdings_stream = client.query(holdings_query, &[&portfolio_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get holdings: {}", e)))?;
    
    let holdings_rows = holdings_stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch holdings: {}", e)))?;

    let mut holdings = Vec::new();
    let mut total_holdings_value = 0.0;
    let mut total_cost_basis = 0.0;

    for row in holdings_rows {
        let current_value: f64 = row.get::<tiberius::numeric::Numeric, _>("CurrentValue")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default();
        let total_cost: f64 = row.get::<tiberius::numeric::Numeric, _>("TotalCost")
            .map(|n| numeric_to_f64(n))
            .unwrap_or_default();

        total_holdings_value += current_value;
        total_cost_basis += total_cost;

        let holding = PortfolioHolding {
            holding_id: row.get("HoldingID").unwrap_or(0),
            portfolio_id: row.get("PortfolioID").unwrap_or(0),
            asset_id: row.get("AssetID").unwrap_or(0),
            asset_name: row.get::<&str, _>("AssetName").unwrap_or("").to_string(),
            symbol: row.get::<&str, _>("Symbol").unwrap_or("").to_string(),
            asset_type: row.get::<&str, _>("AssetType").unwrap_or("").to_string(),
            quantity_held: row.get::<tiberius::numeric::Numeric, _>("QuantityHeld")
                .map(|n| numeric_to_f64(n))
                .unwrap_or_default(),
            average_price: row.get::<tiberius::numeric::Numeric, _>("AveragePrice")
                .map(|n| numeric_to_f64(n))
                .unwrap_or_default(),
            total_cost,
            current_price: row.get::<tiberius::numeric::Numeric, _>("CurrentPrice")
                .map(|n| numeric_to_f64(n))
                .unwrap_or_default(),
            current_value,
            unrealized_gain_loss: row.get::<tiberius::numeric::Numeric, _>("UnrealizedGainLoss")
                .map(|n| numeric_to_f64(n))
                .unwrap_or_default(),
            last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
                .map(|dt| dt.to_string())
                .unwrap_or_default(),
        };
        
        holdings.push(holding);
    }

    let total_unrealized_gain_loss = total_holdings_value - total_cost_basis;
    let assets_count = holdings.len() as i32;

    let summary = PortfolioHoldingsSummary {
        portfolio_id,
        portfolio_name,
        holdings,
        total_holdings_value,
        total_cost_basis,
        total_unrealized_gain_loss,
        assets_count,
    };

    Ok(Json(summary))
}

/// Get portfolio balance using stored procedure for better performance
#[utoipa::path(
    get,
    path = "/api/v1/portfolios/{portfolio_id}/balance-sp",
    tag = "portfolios",
    params(
        ("portfolio_id" = i32, Path, description = "Portfolio ID to get balance for")
    ),
    responses(
        (status = 200, description = "Portfolio balance retrieved successfully using stored procedure", body = PortfolioBalance),
        (status = 404, description = "Portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_portfolio_balance_sp(
    Path(portfolio_id): Path<i32>
) -> Result<Json<PortfolioBalance>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Use the enhanced stored procedure for portfolio balance
    let query = "EXEC portfolio.sp_GetPortfolioBalance @P1";
    let stream = client.query(query, &[&portfolio_id]).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("Portfolio not found") {
            (StatusCode::NOT_FOUND, "Portfolio not found".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get portfolio balance: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch portfolio balance: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::NOT_FOUND, "Portfolio not found".to_string()))?;

    let cash_balance = row.get::<tiberius::numeric::Numeric, _>("CurrentFunds")
        .map(numeric_to_f64)
        .unwrap_or_default();
    let holdings_value = row.get::<tiberius::numeric::Numeric, _>("CurrentMarketValue")
        .map(numeric_to_f64)
        .unwrap_or_default();

    let balance = PortfolioBalance {
        portfolio_id,
        portfolio_name: row.get::<&str, _>("Name").unwrap_or("").to_string(),
        cash_balance,
        holdings_value,
        total_portfolio_value: cash_balance + holdings_value,
        holdings_count: None, // Not returned by this procedure
    };

    Ok(Json(balance))
}

/// Get detailed portfolio holdings using stored procedure for better performance  
#[utoipa::path(
    get,
    path = "/api/v1/portfolios/{portfolio_id}/holdings-summary-sp",
    tag = "portfolios",
    params(
        ("portfolio_id" = i32, Path, description = "Portfolio ID to get holdings summary for")
    ),
    responses(
        (status = 200, description = "Portfolio holdings summary retrieved successfully using stored procedure", body = PortfolioHoldingsSummary),
        (status = 404, description = "Portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_portfolio_holdings_summary_sp(
    Path(portfolio_id): Path<i32>
) -> Result<Json<PortfolioHoldingsSummary>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // First get portfolio name
    let portfolio_query = "SELECT Name FROM portfolio.Portfolios WHERE PortfolioID = @P1";
    let portfolio_stream = client.query(portfolio_query, &[&portfolio_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get portfolio: {}", e)))?;
    
    let portfolio_rows = portfolio_stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch portfolio: {}", e)))?;
    
    let portfolio_name = portfolio_rows.into_iter().next()
        .and_then(|row| row.get::<&str, _>("Name").map(|s| s.to_string()))
        .ok_or((StatusCode::NOT_FOUND, "Portfolio not found".to_string()))?;

    // Use the enhanced stored procedure for holdings summary
    let holdings_query = "EXEC portfolio.sp_GetPortfolioHoldingsSummary @P1";
    
    let holdings_stream = client.query(holdings_query, &[&portfolio_id]).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("Portfolio not found") {
            (StatusCode::NOT_FOUND, "Portfolio not found".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get holdings: {}", e))
        }
    })?;
    
    let holdings_rows = holdings_stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch holdings: {}", e)))?;

    let mut holdings = Vec::new();
    let mut total_holdings_value = 0.0;
    let mut total_cost_basis = 0.0;

    for row in holdings_rows {
        let total_cost = row.get::<tiberius::numeric::Numeric, _>("TotalCost")
            .map(numeric_to_f64)
            .unwrap_or_default();
        let current_value = row.get::<tiberius::numeric::Numeric, _>("CurrentValue")
            .map(numeric_to_f64)
            .unwrap_or_default();

        total_holdings_value += current_value;
        total_cost_basis += total_cost;

        let holding = PortfolioHolding {
            holding_id: row.get("HoldingID").unwrap_or(0),
            portfolio_id: row.get("PortfolioID").unwrap_or(0),
            asset_id: row.get("AssetID").unwrap_or(0),
            asset_name: row.get::<&str, _>("AssetName").unwrap_or("").to_string(),
            symbol: row.get::<&str, _>("AssetSymbol").unwrap_or("").to_string(),
            asset_type: row.get::<&str, _>("AssetType").unwrap_or("").to_string(),
            quantity_held: row.get::<tiberius::numeric::Numeric, _>("QuantityHeld")
                .map(numeric_to_f64)
                .unwrap_or_default(),
            average_price: row.get::<tiberius::numeric::Numeric, _>("AveragePrice")
                .map(numeric_to_f64)
                .unwrap_or_default(),
            total_cost,
            current_price: row.get::<tiberius::numeric::Numeric, _>("CurrentPrice")
                .map(numeric_to_f64)
                .unwrap_or_default(),
            current_value,
            unrealized_gain_loss: row.get::<tiberius::numeric::Numeric, _>("UnrealizedGainLoss")
                .map(numeric_to_f64)
                .unwrap_or_default(),
            last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
                .map(|dt| dt.to_string())
                .unwrap_or_default(),
        };
        
        holdings.push(holding);
    }

    let total_unrealized_gain_loss = total_holdings_value - total_cost_basis;
    let assets_count = holdings.len() as i32;

    let summary = PortfolioHoldingsSummary {
        portfolio_id,
        portfolio_name,
        holdings,
        total_holdings_value,
        total_cost_basis,
        total_unrealized_gain_loss,
        assets_count,
    };

    Ok(Json(summary))
} 
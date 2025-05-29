use axum::{Json, extract::{Path, Query}};
use crate::{models::{Portfolio, CreatePortfolioRequest, UpdatePortfolioRequest, PortfolioSummary, AssetHolding}, db};
use uuid::Uuid;
use axum::http::StatusCode;
use serde::Deserialize;


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
            .map(|n| n.value() as f64)
            .unwrap_or_default();
            
        let current_profit_pct = row.get::<tiberius::numeric::Numeric, _>("CurrentProfitPct")
            .map(|n| n.value() as f64)
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

    // First verify the user exists
    let user_exists = client.query(
        "SELECT 1 FROM portfolio.Users WHERE UserID = @P1",
        &[&tiberius::Uuid::from_bytes(*portfolio.user_id.as_bytes())]
    ).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to verify user: {}", e)))?
    .into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch user verification: {}", e)))?
    .len() > 0;

    if !user_exists {
        return Err((StatusCode::BAD_REQUEST, "User does not exist".to_string()));
    }

    let query = "INSERT INTO portfolio.Portfolios (UserID, Name, CurrentFunds, CreationDate, LastUpdated) 
                 OUTPUT INSERTED.* 
                 VALUES (@P1, @P2, @P3, SYSDATETIME(), SYSDATETIME())";
    
    let stream = client.query(
        query,
        &[
            &tiberius::Uuid::from_bytes(*portfolio.user_id.as_bytes()),
            &portfolio.name,
            &portfolio.initial_funds,
        ],
    ).await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to create portfolio: {}", e)))?;

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
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        current_profit_pct: row.get::<tiberius::numeric::Numeric, _>("CurrentProfitPct")
            .map(|n| n.value() as f64)
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
    path = "/api/v1/portfolios/{portfolioId}",
    tag = "portfolios",
    params(
        ("portfolioId" = i32, Path, description = "Portfolio ID to fetch")
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
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        current_profit_pct: row.get::<tiberius::numeric::Numeric, _>("CurrentProfitPct")
            .map(|n| n.value() as f64)
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
    path = "/api/v1/portfolios/{portfolioId}/summary",
    tag = "portfolios",
    params(
        ("portfolioId" = i32, Path, description = "Portfolio ID to fetch summary for")
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
        owner: row.get::<&str, _>("Owner").unwrap_or_default().to_string(),
        current_funds: row.get::<tiberius::numeric::Numeric, _>("CurrentFunds")
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        current_profit_pct: row.get::<tiberius::numeric::Numeric, _>("CurrentProfitPct")
            .map(|n| n.value() as f64)
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
    path = "/api/v1/portfolios/{portfolioId}/holdings",
    tag = "portfolios",
    params(
        ("portfolioId" = i32, Path, description = "Portfolio ID to fetch holdings for")
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

    let query = "SELECT * FROM portfolio.vw_AssetHoldings WHERE PortfolioID = @P1";
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
                .map(|n| n.value() as f64)
                .unwrap_or_default(),
            current_price: row.get::<tiberius::numeric::Numeric, _>("CurrentPrice")
                .map(|n| n.value() as f64)
                .unwrap_or_default(),
            market_value: row.get::<tiberius::numeric::Numeric, _>("MarketValue")
                .map(|n| n.value() as f64)
                .unwrap_or_default(),
        }
    }).collect();

    Ok(Json(holdings))
}

/// Update portfolio
#[utoipa::path(
    put,
    path = "/api/v1/portfolios/{portfolioId}",
    tag = "portfolios",
    params(
        ("portfolioId" = i32, Path, description = "Portfolio ID to update")
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

    let mut updates = Vec::new();
    let mut values = Vec::new();  // Store owned values
    let mut sql_params: Vec<&(dyn tiberius::ToSql)> = Vec::new();
    let mut param_index = 1;

    if let Some(name) = &update.name {
        updates.push(format!("Name = @P{}", param_index));
        sql_params.push(name);
        param_index += 1;
    }

    if let Some(funds) = update.current_funds {
        updates.push(format!("CurrentFunds = @P{}", param_index));
        values.push(funds);  // Store the value
        sql_params.push(values.last().unwrap());  // Reference the stored value
        param_index += 1;
    }

    if updates.is_empty() {
        return Err((StatusCode::BAD_REQUEST, "No fields to update".to_string()));
    }

    updates.push("LastUpdated = SYSDATETIME()".to_string());
    sql_params.push(&portfolio_id);

    let query = format!(
        "UPDATE portfolio.Portfolios SET {} WHERE PortfolioID = @P{} OUTPUT INSERTED.*",
        updates.join(", "),
        param_index
    );

    let stream = client.query(&query, &sql_params[..]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to update portfolio: {}", e)))?;
    
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
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        current_profit_pct: row.get::<tiberius::numeric::Numeric, _>("CurrentProfitPct")
            .map(|n| n.value() as f64)
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
    path = "/api/v1/portfolios/{portfolioId}",
    tag = "portfolios",
    params(
        ("portfolioId" = i32, Path, description = "Portfolio ID to delete")
    ),
    responses(
        (status = 204, description = "Portfolio deleted successfully"),
        (status = 404, description = "Portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn delete_portfolio(Path(portfolio_id): Path<i32>) -> Result<StatusCode, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let query = "DELETE FROM portfolio.Portfolios WHERE PortfolioID = @P1";
    let stream = client.query(query, &[&portfolio_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to delete portfolio: {}", e)))?;
    
    let rows_affected = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to confirm deletion: {}", e)))?.len();

    if rows_affected == 0 {
        return Err((StatusCode::NOT_FOUND, "Portfolio not found".to_string()));
    }

    Ok(StatusCode::NO_CONTENT)
} 
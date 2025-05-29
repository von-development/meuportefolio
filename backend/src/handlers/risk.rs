use axum::{Json, extract::Path};
use uuid::Uuid;
use crate::{models::{RiskAnalysis, PortfolioRiskAnalysis, RiskSummary}, db};
use axum::http::StatusCode;

/// Get user risk metrics
#[utoipa::path(
    get,
    path = "/api/v1/risk/metrics/user/{userId}",
    tag = "risk",
    params(
        ("userId" = String, Path, description = "User ID to fetch risk metrics for")
    ),
    responses(
        (status = 200, description = "Risk metrics retrieved successfully", body = RiskAnalysis),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_user_risk_metrics(
    Path(user_id): Path<Uuid>
) -> Result<Json<RiskAnalysis>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Check if user exists
    let check_query = "SELECT COUNT(*) as count FROM portfolio.Users WHERE UserID = @P1";
    let tiberius_uuid = tiberius::Uuid::from_bytes(*user_id.as_bytes());
    let stream = client.query(check_query, &[&tiberius_uuid]).await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check user existence: {}", e)))?;
    
    let result = stream.into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch user check results: {}", e)))?;
    
    let count: i32 = result.first()
        .and_then(|row| row.get("count"))
        .unwrap_or(0);

    if count == 0 {
        return Err((StatusCode::NOT_FOUND, "User not found".to_string()));
    }

    let query = "SELECT * FROM portfolio.vw_RiskAnalysis WHERE UserID = @P1";
    let stream = client.query(query, &[&tiberius_uuid]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let row = stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::NOT_FOUND, "Risk analysis not found".to_string()))?;

    let risk_analysis = RiskAnalysis {
        user_id,
        user_name: row.get::<&str, _>("UserName").unwrap_or_default().to_string(),
        user_type: row.get::<&str, _>("UserType").unwrap_or_default().to_string(),
        total_portfolios: row.get("TotalPortfolios").unwrap_or_default(),
        total_investment: row.get::<tiberius::numeric::Numeric, _>("TotalInvestment")
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        maximum_drawdown: row.get::<tiberius::numeric::Numeric, _>("MaximumDrawdown")
            .map(|n| n.value() as f64),
        sharpe_ratio: row.get::<tiberius::numeric::Numeric, _>("SharpeRatio")
            .map(|n| n.value() as f64),
        risk_level: row.get::<&str, _>("RiskLevel").unwrap_or_default().to_string(),
        last_updated: row.get::<chrono::NaiveDateTime, _>("LastUpdated")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    };

    Ok(Json(risk_analysis))
}

/// Get portfolio risk analysis
#[utoipa::path(
    get,
    path = "/api/v1/risk/metrics/portfolio/{portfolioId}",
    tag = "risk",
    params(
        ("portfolioId" = i32, Path, description = "Portfolio ID to fetch risk analysis for")
    ),
    responses(
        (status = 200, description = "Portfolio risk analysis retrieved successfully", body = PortfolioRiskAnalysis),
        (status = 404, description = "Portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_portfolio_risk_analysis(
    Path(portfolio_id): Path<i32>
) -> Result<Json<PortfolioRiskAnalysis>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // First check if portfolio exists and get basic info
    let portfolio_query = "SELECT p.*, rm.* FROM portfolio.Portfolios p 
        LEFT JOIN portfolio.RiskMetrics rm ON rm.UserID = p.UserID 
        WHERE p.PortfolioID = @P1";
    let stream = client.query(portfolio_query, &[&portfolio_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let row = stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::NOT_FOUND, "Portfolio not found".to_string()))?;

    let risk_analysis = PortfolioRiskAnalysis {
        portfolio_id,
        portfolio_name: row.get::<&str, _>("Name").unwrap_or_default().to_string(),
        current_funds: row.get::<tiberius::numeric::Numeric, _>("CurrentFunds")
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        current_profit_pct: row.get::<tiberius::numeric::Numeric, _>("CurrentProfitPct")
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        maximum_drawdown: row.get::<tiberius::numeric::Numeric, _>("MaximumDrawdown")
            .map(|n| n.value() as f64),
        beta: row.get::<tiberius::numeric::Numeric, _>("Beta")
            .map(|n| n.value() as f64),
        sharpe_ratio: row.get::<tiberius::numeric::Numeric, _>("SharpeRatio")
            .map(|n| n.value() as f64),
        risk_level: row.get::<&str, _>("RiskLevel").unwrap_or_default().to_string(),
    };

    Ok(Json(risk_analysis))
}

/// Get overall risk summary
#[utoipa::path(
    get,
    path = "/api/v1/risk/summary",
    tag = "risk",
    responses(
        (status = 200, description = "Risk summary retrieved successfully", body = RiskSummary),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_risk_summary() -> Result<Json<RiskSummary>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let query = "
        SELECT 
            COUNT(DISTINCT u.UserID) as TotalUsers,
            COUNT(DISTINCT p.PortfolioID) as TotalPortfolios,
            SUM(p.CurrentFunds) as TotalAssetsUnderManagement,
            AVG(CAST(rm.VolatilityScore as float)) as AverageSystemRisk
        FROM portfolio.Users u
        LEFT JOIN portfolio.Portfolios p ON p.UserID = u.UserID
        LEFT JOIN portfolio.RiskMetrics rm ON rm.UserID = u.UserID";

    let stream = client.query(query, &[]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let row = stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "Failed to get risk summary".to_string()))?;

    let summary = RiskSummary {
        total_users: row.get("TotalUsers").unwrap_or_default(),
        total_portfolios: row.get("TotalPortfolios").unwrap_or_default(),
        total_assets_under_management: row.get::<tiberius::numeric::Numeric, _>("TotalAssetsUnderManagement")
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        average_system_risk: row.get::<tiberius::numeric::Numeric, _>("AverageSystemRisk")
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        calculated_at: chrono::Utc::now().naive_utc().to_string(),
    };

    Ok(Json(summary))
}

/// Get portfolio-specific risk summary
#[utoipa::path(
    get,
    path = "/api/v1/risk/summary/portfolio/{portfolioId}",
    tag = "risk",
    params(
        ("portfolioId" = i32, Path, description = "Portfolio ID to fetch risk summary for")
    ),
    responses(
        (status = 200, description = "Portfolio risk summary retrieved successfully", body = RiskSummary),
        (status = 404, description = "Portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_portfolio_risk_summary(
    Path(portfolio_id): Path<i32>
) -> Result<Json<RiskSummary>, (StatusCode, String)> {
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

    let query = "
        SELECT 
            1 as TotalUsers,
            1 as TotalPortfolios,
            p.CurrentFunds as TotalAssetsUnderManagement,
            COALESCE(rm.VolatilityScore, 0) as AverageSystemRisk
        FROM portfolio.Portfolios p
        LEFT JOIN portfolio.RiskMetrics rm ON rm.UserID = p.UserID
        WHERE p.PortfolioID = @P1";

    let stream = client.query(query, &[&portfolio_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let row = stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "Failed to get risk summary".to_string()))?;

    let summary = RiskSummary {
        total_users: row.get("TotalUsers").unwrap_or_default(),
        total_portfolios: row.get("TotalPortfolios").unwrap_or_default(),
        total_assets_under_management: row.get::<tiberius::numeric::Numeric, _>("TotalAssetsUnderManagement")
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        average_system_risk: row.get::<tiberius::numeric::Numeric, _>("AverageSystemRisk")
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        calculated_at: chrono::Utc::now().naive_utc().to_string(),
    };

    Ok(Json(summary))
}

/// Get user-specific risk summary
#[utoipa::path(
    get,
    path = "/api/v1/risk/summary/user/{userId}",
    tag = "risk",
    params(
        ("userId" = String, Path, description = "User ID to fetch risk summary for")
    ),
    responses(
        (status = 200, description = "User risk summary retrieved successfully", body = RiskSummary),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_user_risk_summary(
    Path(user_id): Path<Uuid>
) -> Result<Json<RiskSummary>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Check if user exists
    let check_query = "SELECT COUNT(*) as count FROM portfolio.Users WHERE UserID = @P1";
    let tiberius_uuid = tiberius::Uuid::from_bytes(*user_id.as_bytes());
    let stream = client.query(check_query, &[&tiberius_uuid]).await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check user existence: {}", e)))?;
    
    let result = stream.into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch user check results: {}", e)))?;
    
    let count: i32 = result.first()
        .and_then(|row| row.get("count"))
        .unwrap_or(0);

    if count == 0 {
        return Err((StatusCode::NOT_FOUND, "User not found".to_string()));
    }

    let query = "
        SELECT 
            1 as TotalUsers,
            COUNT(DISTINCT p.PortfolioID) as TotalPortfolios,
            SUM(p.CurrentFunds) as TotalAssetsUnderManagement,
            COALESCE(rm.VolatilityScore, 0) as AverageSystemRisk
        FROM portfolio.Users u
        LEFT JOIN portfolio.Portfolios p ON p.UserID = u.UserID
        LEFT JOIN portfolio.RiskMetrics rm ON rm.UserID = u.UserID
        WHERE u.UserID = @P1
        GROUP BY rm.VolatilityScore";

    let stream = client.query(query, &[&tiberius_uuid]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let row = stream.into_first_result().await
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?
        .into_iter()
        .next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "Failed to get risk summary".to_string()))?;

    let summary = RiskSummary {
        total_users: row.get("TotalUsers").unwrap_or_default(),
        total_portfolios: row.get("TotalPortfolios").unwrap_or_default(),
        total_assets_under_management: row.get::<tiberius::numeric::Numeric, _>("TotalAssetsUnderManagement")
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        average_system_risk: row.get::<tiberius::numeric::Numeric, _>("AverageSystemRisk")
            .map(|n| n.value() as f64)
            .unwrap_or_default(),
        calculated_at: chrono::Utc::now().naive_utc().to_string(),
    };

    Ok(Json(summary))
} 
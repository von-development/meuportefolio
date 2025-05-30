use serde::Serialize;
use utoipa::ToSchema;
use uuid::Uuid;

/// Risk metrics for a user from the database
#[derive(Serialize, ToSchema)]
pub struct RiskMetrics {
    #[schema(example = "1")]
    pub metric_id: i32,
    #[schema(value_type = String, format = "uuid", example = "123e4567-e89b-12d3-a456-426614174000")]
    pub user_id: Uuid,
    #[schema(example = "-15.5")]
    pub maximum_drawdown: Option<f64>,
    #[schema(example = "1.2")]
    pub beta: Option<f64>,
    #[schema(example = "0.8")]
    pub sharpe_ratio: Option<f64>,
    #[schema(example = "25.5")]
    pub absolute_return: Option<f64>,
    #[schema(example = "0.75")]
    pub volatility_score: Option<f64>,
    #[schema(example = "Moderate")]
    pub risk_level: String,
    #[schema(example = "2024-03-20T10:00:00")]
    pub captured_at: String,
}

/// Risk analysis from the database view
#[derive(Serialize, ToSchema)]
pub struct RiskAnalysis {
    #[schema(value_type = String, format = "uuid", example = "123e4567-e89b-12d3-a456-426614174000")]
    pub user_id: Uuid,
    #[schema(example = "John Doe")]
    pub user_name: String,
    #[schema(example = "Premium")]
    pub user_type: String,
    #[schema(example = "3")]
    pub total_portfolios: i32,
    #[schema(example = "150000.50")]
    pub total_investment: f64,
    #[schema(example = "-15.5")]
    pub maximum_drawdown: Option<f64>,
    #[schema(example = "0.8")]
    pub sharpe_ratio: Option<f64>,
    #[schema(example = "Moderate")]
    pub risk_level: String,
    #[schema(example = "2024-03-20T10:00:00")]
    pub last_updated: String,
}

/// Portfolio risk analysis response
#[derive(Serialize, ToSchema)]
pub struct PortfolioRiskAnalysis {
    #[schema(example = "1")]
    pub portfolio_id: i32,
    #[schema(example = "Tech Growth Portfolio")]
    pub portfolio_name: String,
    #[schema(example = "150000.50")]
    pub current_funds: f64,
    #[schema(example = "25.5")]
    pub current_profit_pct: f64,
    #[schema(example = "-15.5")]
    pub maximum_drawdown: Option<f64>,
    #[schema(example = "1.2")]
    pub beta: Option<f64>,
    #[schema(example = "0.8")]
    pub sharpe_ratio: Option<f64>,
    #[schema(example = "Moderate")]
    pub risk_level: String,
}

/// Overall risk summary response
#[derive(Serialize, ToSchema)]
pub struct RiskSummary {
    #[schema(example = "3")]
    pub total_users: i32,
    #[schema(example = "10")]
    pub total_portfolios: i32,
    #[schema(example = "1500000.50")]
    pub total_assets_under_management: f64,
    #[schema(example = "0.75")]
    pub average_system_risk: f64,
    #[schema(example = "2024-03-20T10:00:00")]
    pub calculated_at: String,
} 
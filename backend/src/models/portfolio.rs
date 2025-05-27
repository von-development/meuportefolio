use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

/// Represents a portfolio in the system
#[derive(Serialize, Deserialize, ToSchema)]
pub struct Portfolio {
    #[schema(example = "1")]
    pub portfolio_id: i32,
    #[schema(value_type = String, format = "uuid", example = "123e4567-e89b-12d3-a456-426614174000")]
    pub user_id: Uuid,
    #[schema(example = "Tech Growth Portfolio")]
    pub name: String,
    #[schema(example = "2024-03-20T10:00:00")]
    pub creation_date: String,
    #[schema(example = "10000.50")]
    pub current_funds: f64,
    #[schema(example = "15.5")]
    pub current_profit_pct: f64,
    #[schema(example = "2024-03-20T10:00:00")]
    pub last_updated: String,
}

/// Request payload for creating a new portfolio
#[derive(Deserialize, ToSchema)]
pub struct CreatePortfolioRequest {
    #[schema(example = "Tech Growth Portfolio")]
    pub name: String,
    #[schema(example = "10000.50")]
    pub initial_funds: f64,
}

/// Request payload for updating a portfolio
#[derive(Deserialize, ToSchema)]
pub struct UpdatePortfolioRequest {
    #[schema(example = "Tech Growth Portfolio Updated")]
    pub name: Option<String>,
    #[schema(example = "15000.75")]
    pub current_funds: Option<f64>,
}

/// Portfolio summary from the database view
#[derive(Serialize, ToSchema)]
pub struct PortfolioSummary {
    #[schema(example = "1")]
    pub portfolio_id: i32,
    #[schema(example = "Tech Growth Portfolio")]
    pub portfolio_name: String,
    #[schema(example = "John Doe")]
    pub owner: String,
    #[schema(example = "10000.50")]
    pub current_funds: f64,
    #[schema(example = "15.5")]
    pub current_profit_pct: f64,
    #[schema(example = "2024-03-20T10:00:00")]
    pub creation_date: String,
    #[schema(example = "42")]
    pub total_trades: i32,
}

/// Portfolio holdings from the database view
#[derive(Serialize, ToSchema)]
pub struct AssetHolding {
    #[schema(example = "1")]
    pub portfolio_id: i32,
    #[schema(example = "Tech Growth Portfolio")]
    pub portfolio_name: String,
    #[schema(example = "1")]
    pub asset_id: i32,
    #[schema(example = "Apple Inc")]
    pub asset_name: String,
    #[schema(example = "AAPL")]
    pub symbol: String,
    #[schema(example = "Company")]
    pub asset_type: String,
    #[schema(example = "100")]
    pub quantity_held: f64,
    #[schema(example = "175.50")]
    pub current_price: f64,
    #[schema(example = "17550.00")]
    pub market_value: f64,
} 
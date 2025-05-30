use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

/// Request to buy an asset
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct BuyAssetRequest {
    /// Portfolio ID to buy asset in
    pub portfolio_id: i32,
    /// Asset ID to buy
    pub asset_id: i32,
    /// Quantity to buy (must be positive)
    pub quantity: f64,
    /// Optional unit price (if not provided, uses current market price)
    pub unit_price: Option<f64>,
}

/// Request to sell an asset
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct SellAssetRequest {
    /// Portfolio ID to sell asset from
    pub portfolio_id: i32,
    /// Asset ID to sell
    pub asset_id: i32,
    /// Quantity to sell (must be positive)
    pub quantity: f64,
    /// Optional unit price (if not provided, uses current market price)
    pub unit_price: Option<f64>,
}

/// Response for buy operation
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct BuyAssetResponse {
    /// Operation status
    pub status: String,
    /// Transaction ID
    pub transaction_id: i64,
    /// Quantity purchased
    pub quantity_purchased: f64,
    /// Price per share
    pub price_per_share: f64,
    /// Total cost of purchase
    pub total_cost: f64,
    /// Remaining cash funds in portfolio
    pub remaining_funds: f64,
}

/// Response for sell operation
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct SellAssetResponse {
    /// Operation status
    pub status: String,
    /// Transaction ID
    pub transaction_id: i64,
    /// Quantity sold
    pub quantity_sold: f64,
    /// Price per share
    pub price_per_share: f64,
    /// Total proceeds from sale
    pub total_proceeds: f64,
    /// New cash funds balance in portfolio
    pub new_funds_balance: f64,
}

/// Portfolio holding information
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct PortfolioHolding {
    /// Holding ID
    pub holding_id: i64,
    /// Portfolio ID
    pub portfolio_id: i32,
    /// Asset ID
    pub asset_id: i32,
    /// Asset name
    pub asset_name: String,
    /// Asset symbol
    pub symbol: String,
    /// Asset type
    pub asset_type: String,
    /// Quantity held
    pub quantity_held: f64,
    /// Average purchase price
    pub average_price: f64,
    /// Total cost basis
    pub total_cost: f64,
    /// Current market price
    pub current_price: f64,
    /// Current market value
    pub current_value: f64,
    /// Unrealized gain/loss
    pub unrealized_gain_loss: f64,
    /// Last updated timestamp
    pub last_updated: String,
}

/// Trading transaction record
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct TradingTransaction {
    /// Transaction ID
    pub transaction_id: i64,
    /// User ID
    pub user_id: Uuid,
    /// Portfolio ID
    pub portfolio_id: i32,
    /// Asset ID
    pub asset_id: i32,
    /// Asset symbol
    pub symbol: String,
    /// Asset name
    pub asset_name: String,
    /// Transaction type (Buy or Sell)
    pub transaction_type: String,
    /// Quantity traded
    pub quantity: f64,
    /// Unit price
    pub unit_price: f64,
    /// Total value (quantity * unit_price)
    pub total_value: f64,
    /// Transaction status
    pub status: String,
    /// Transaction timestamp
    pub transaction_date: String,
}

/// Portfolio holdings summary
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct PortfolioHoldingsSummary {
    /// Portfolio ID
    pub portfolio_id: i32,
    /// Portfolio name
    pub portfolio_name: String,
    /// List of holdings
    pub holdings: Vec<PortfolioHolding>,
    /// Total holdings value
    pub total_holdings_value: f64,
    /// Total cost basis
    pub total_cost_basis: f64,
    /// Total unrealized gain/loss
    pub total_unrealized_gain_loss: f64,
    /// Number of different assets
    pub assets_count: i32,
} 
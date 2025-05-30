use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

/// Request to deposit funds to user account
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct DepositRequest {
    /// Amount to deposit (must be positive)
    pub amount: f64,
    /// Optional description for the deposit
    pub description: Option<String>,
}

/// Request to withdraw funds from user account
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct WithdrawRequest {
    /// Amount to withdraw (must be positive)
    pub amount: f64,
    /// Optional description for the withdrawal
    pub description: Option<String>,
}

/// Request to allocate funds from user account to portfolio
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct AllocateRequest {
    /// Portfolio ID to allocate funds to
    pub portfolio_id: i32,
    /// Amount to allocate (must be positive)
    pub amount: f64,
}

/// Request to deallocate funds from portfolio back to user account
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct DeallocateRequest {
    /// Portfolio ID to deallocate funds from
    pub portfolio_id: i32,
    /// Amount to deallocate (must be positive)
    pub amount: f64,
}

/// Request to upgrade user to premium
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct UpgradePremiumRequest {
    /// Number of months for subscription (default: 1)
    pub subscription_months: Option<i32>,
    /// Monthly rate (default: 50.00)
    pub monthly_rate: Option<f64>,
}

/// Response for fund operations (deposit, withdraw, allocate, deallocate)
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct FundOperationResponse {
    /// Operation status
    pub status: String,
    /// Amount processed
    pub amount: f64,
    /// New user account balance
    pub new_balance: f64,
    /// New portfolio funds (for allocate/deallocate operations)
    pub new_portfolio_funds: Option<f64>,
}

/// Response for premium upgrade
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct PremiumUpgradeResponse {
    /// Operation status
    pub status: String,
    /// Amount paid for upgrade
    pub amount_paid: f64,
    /// Number of subscription months
    pub subscription_months: i32,
    /// New account balance after payment
    pub new_balance: f64,
}

/// User account summary with portfolio information
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct AccountSummary {
    /// User ID
    pub user_id: Uuid,
    /// User name
    pub name: String,
    /// User type (Basic or Premium)
    pub user_type: String,
    /// Current account balance (cash)
    pub account_balance: f64,
    /// Total value of all portfolios
    pub total_portfolio_value: f64,
    /// Total net worth (account balance + portfolio value)
    pub total_net_worth: f64,
    /// Number of portfolios owned
    pub portfolio_count: i32,
}

/// Portfolio balance summary
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct PortfolioBalance {
    /// Portfolio ID
    pub portfolio_id: i32,
    /// Portfolio name
    pub portfolio_name: String,
    /// Cash balance in portfolio
    pub cash_balance: f64,
    /// Total market value of holdings
    pub holdings_value: f64,
    /// Total portfolio value (cash + holdings)
    pub total_portfolio_value: f64,
    /// Number of different assets held
    pub holdings_count: Option<i32>,
}

/// Fund transaction record
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct FundTransaction {
    /// Transaction ID
    pub fund_transaction_id: i64,
    /// User ID
    pub user_id: Uuid,
    /// Portfolio ID (if applicable)
    pub portfolio_id: Option<i32>,
    /// Transaction type
    pub transaction_type: String,
    /// Transaction amount
    pub amount: f64,
    /// Account balance after transaction
    pub balance_after: f64,
    /// Transaction description
    pub description: Option<String>,
    /// Related asset transaction ID (if applicable)
    pub related_asset_transaction_id: Option<i64>,
    /// Transaction timestamp
    pub created_at: String,
} 
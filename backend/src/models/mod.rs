use serde::{Serialize, Deserialize};
use utoipa::ToSchema;

// Re-export all module types
pub mod user;
mod portfolio;
mod risk;
mod funds;
mod trading;
mod assets;

pub use user::*;
pub use portfolio::*;
pub use risk::*;
pub use funds::*;
pub use trading::*;
pub use assets::*;

// =============================================================
// CORE ASSET MODELS
// =============================================================

#[derive(Serialize, ToSchema)]
pub struct Asset {
    pub asset_id: i32,
    pub name: String,
    pub symbol: String,
    pub asset_type: String,
    pub price: f64,
    pub volume: i64,
    pub available_shares: f64,
    pub last_updated: String,
}

#[derive(Serialize, ToSchema)]
pub struct AssetPriceHistory {
    pub asset_id: i32,
    pub symbol: String,
    pub price: f64,
    pub volume: i64,
    pub timestamp: String,
}

#[derive(Deserialize, ToSchema)]
pub struct CreateAssetRequest {
    #[schema(example = "AAPL")]
    pub symbol: String,
    #[schema(example = "Apple Inc.")]
    pub name: String,
    #[schema(example = "Stock")]
    pub asset_type: String,  // Stock, Index, Cryptocurrency, Commodity
    #[schema(example = "150.00")]
    pub initial_price: Option<f64>,
    #[schema(example = "1000000")]
    pub initial_volume: Option<i64>,
    #[schema(example = "1000000.0")]
    pub available_shares: Option<f64>,
}

#[derive(Deserialize, ToSchema)]
pub struct UpdateAssetRequest {
    #[schema(example = "Apple Inc. (Updated)")]
    pub name: Option<String>,
    #[schema(example = "155.00")]
    pub price: Option<f64>,
    #[schema(example = "2000000")]
    pub volume: Option<i64>,
    #[schema(example = "1100000.0")]
    pub available_shares: Option<f64>,
}

#[derive(Deserialize, ToSchema)]
pub struct UpdatePriceRequest {
    #[schema(example = "150.75")]
    pub price: f64,
    #[schema(example = "1500000")]
    pub volume: Option<i64>,
}

#[derive(Serialize, ToSchema)]
pub struct UpdatePriceResponse {
    #[schema(example = "SUCCESS")]
    pub status: String,
    #[schema(example = "Price updated successfully")]
    pub message: String,
}

// =============================================================
// STOCK-SPECIFIC MODELS
// =============================================================

#[derive(Serialize, Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct StockDetails {
    pub asset_id: i32,
    #[schema(example = "Technology")]
    pub sector: String,
    #[schema(example = "United States")]
    pub country: String,
    #[schema(example = "2500000000000.00")]
    pub market_cap: f64,
    pub last_updated: String,
}

#[derive(Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct CreateStockRequest {
    #[schema(example = "AAPL")]
    pub symbol: String,
    #[schema(example = "Apple Inc.")]
    pub name: String,
    #[schema(example = "150.00")]
    pub initial_price: Option<f64>,
    #[schema(example = "1000000")]
    pub initial_volume: Option<i64>,
    #[schema(example = "1000000.0")]
    pub available_shares: Option<f64>,
    // Stock-specific fields
    #[schema(example = "Technology")]
    pub sector: String,
    #[schema(example = "United States")]
    pub country: String,
    #[schema(example = "2500000000000.00")]
    pub market_cap: Option<f64>,
}

#[derive(Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct UpdateStockDetailsRequest {
    #[schema(example = "Technology")]
    pub sector: String,
    #[schema(example = "United States")]
    pub country: String,
    #[schema(example = "2500000000000.00")]
    pub market_cap: f64,
}

// =============================================================
// CRYPTOCURRENCY-SPECIFIC MODELS
// =============================================================

#[derive(Serialize, Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct CryptoDetails {
    pub asset_id: i32,
    #[schema(example = "Bitcoin")]
    pub blockchain: String,
    #[schema(example = "21000000")]
    pub max_supply: Option<f64>,
    #[schema(example = "19500000")]
    pub circulating_supply: f64,
    pub last_updated: String,
}

#[derive(Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct CreateCryptoRequest {
    #[schema(example = "BTC")]
    pub symbol: String,
    #[schema(example = "Bitcoin")]
    pub name: String,
    #[schema(example = "45000.00")]
    pub initial_price: Option<f64>,
    #[schema(example = "100000")]
    pub initial_volume: Option<i64>,
    #[schema(example = "21000000.0")]
    pub available_shares: Option<f64>,
    // Crypto-specific fields
    #[schema(example = "Bitcoin")]
    pub blockchain: String,
    #[schema(example = "21000000")]
    pub max_supply: Option<f64>,
    #[schema(example = "19500000")]
    pub circulating_supply: Option<f64>,
}

#[derive(Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct UpdateCryptoDetailsRequest {
    #[schema(example = "Bitcoin")]
    pub blockchain: String,
    #[schema(example = "21000000")]
    pub max_supply: Option<f64>,
    #[schema(example = "19500000")]
    pub circulating_supply: f64,
}

// =============================================================
// INDEX-SPECIFIC MODELS
// =============================================================

#[derive(Serialize, Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct IndexDetails {
    pub asset_id: i32,
    #[schema(example = "United States")]
    pub country: String,
    #[schema(example = "North America")]
    pub region: String,
    #[schema(example = "Broad Market")]
    pub index_type: String,
    #[schema(example = "500")]
    pub component_count: Option<i32>,
    pub last_updated: String,
}

#[derive(Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct CreateIndexRequest {
    #[schema(example = "SPY")]
    pub symbol: String,
    #[schema(example = "SPDR S&P 500 ETF Trust")]
    pub name: String,
    #[schema(example = "420.00")]
    pub initial_price: Option<f64>,
    #[schema(example = "50000000")]
    pub initial_volume: Option<i64>,
    #[schema(example = "500000000.0")]
    pub available_shares: Option<f64>,
    // Index-specific fields
    #[schema(example = "United States")]
    pub country: String,
    #[schema(example = "North America")]
    pub region: String,
    #[schema(example = "Broad Market")]
    pub index_type: String,
    #[schema(example = "500")]
    pub component_count: Option<i32>,
}

#[derive(Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct UpdateIndexDetailsRequest {
    #[schema(example = "United States")]
    pub country: String,
    #[schema(example = "North America")]
    pub region: String,
    #[schema(example = "Broad Market")]
    pub index_type: String,
    #[schema(example = "500")]
    pub component_count: Option<i32>,
}

// =============================================================
// COMMODITY-SPECIFIC MODELS
// =============================================================

#[derive(Serialize, Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct CommodityDetails {
    pub asset_id: i32,
    #[schema(example = "Precious Metals")]
    pub category: String,
    #[schema(example = "oz")]
    pub unit: String,
    pub last_updated: String,
}

#[derive(Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct CreateCommodityRequest {
    #[schema(example = "GLD")]
    pub symbol: String,
    #[schema(example = "Gold")]
    pub name: String,
    #[schema(example = "1800.00")]
    pub initial_price: Option<f64>,
    #[schema(example = "10000")]
    pub initial_volume: Option<i64>,
    #[schema(example = "1000000.0")]
    pub available_shares: Option<f64>,
    // Commodity-specific fields
    #[schema(example = "Precious Metals")]
    pub category: String,
    #[schema(example = "oz")]
    pub unit: String,
}

#[derive(Deserialize, ToSchema)]
#[allow(dead_code)]
pub struct UpdateCommodityDetailsRequest {
    #[schema(example = "Precious Metals")]
    pub category: String,
    #[schema(example = "oz")]
    pub unit: String,
}

// =============================================================
// COMPLETE ASSET MODEL (WITH ALL DETAILS)
// =============================================================

#[derive(Serialize, ToSchema)]
pub struct CompleteAsset {
    pub asset: Asset,
    pub stock_details: Option<StockDetails>,
    pub crypto_details: Option<CryptoDetails>,
    pub commodity_details: Option<CommodityDetails>,
    pub index_details: Option<IndexDetails>,
    pub recent_prices: Vec<AssetPriceHistory>,
}

// =============================================================
// CSV IMPORT MODELS
// =============================================================

#[derive(Deserialize, ToSchema)]
pub struct CsvImportRequest {
    #[schema(example = "BTCUSD")]
    pub symbol: String,
    #[schema(example = "Bitcoin USD")]
    pub asset_name: Option<String>,
    #[schema(example = "Cryptocurrency")]
    pub asset_type: String, // Now required - Stock, Cryptocurrency, Index, Commodity
    #[schema(example = "true")]
    pub update_current_price: Option<bool>,
    #[schema(example = "true")]
    pub create_if_not_exists: Option<bool>,
    // Stock-specific fields (optional)
    #[schema(example = "Technology")]
    pub sector: Option<String>,
    #[schema(example = "United States")]
    pub country: Option<String>,
    #[schema(example = "2500000000000.00")]
    pub market_cap: Option<f64>,
    // Crypto-specific fields (optional)
    #[schema(example = "Bitcoin")]
    pub blockchain: Option<String>,
    #[schema(example = "21000000")]
    pub max_supply: Option<f64>,
    #[schema(example = "19500000")]
    pub circulating_supply: Option<f64>,
    // Index-specific fields (optional)
    #[schema(example = "North America")]
    pub region: Option<String>,
    #[schema(example = "Broad Market")]
    pub index_type: Option<String>,
    #[schema(example = "500")]
    pub component_count: Option<i32>,
    // Commodity-specific fields (optional)
    #[schema(example = "Precious Metals")]
    pub category: Option<String>,
    #[schema(example = "oz")]
    pub unit: Option<String>,
}

#[derive(Serialize, ToSchema)]
pub struct CsvImportResult {
    #[schema(example = "SUCCESS")]
    pub status: String,
    #[schema(example = "5")]
    pub asset_id: i32,
    #[schema(example = "BTCUSD")]
    pub symbol: String,
    #[schema(example = "Cryptocurrency")]
    pub asset_type: String,
    #[schema(example = "15")]
    pub records_imported: i32,
    #[schema(example = "2")]
    pub records_updated: i32,
    #[schema(example = "0")]
    pub records_failed: i32,
    pub errors: Vec<String>,
    #[schema(example = "Asset details created successfully")]
    pub details_status: Option<String>,
}

// Enhanced CSV row structure that can handle different asset types
#[derive(Deserialize)]
#[allow(dead_code)]
pub struct CsvRow {
    pub date: String,           // "05/27/2025"
    pub price: String,          // "110,124.6" (Close price)
    pub open: String,           // "109,455.3"
    pub high: String,           // "110,718.7"
    pub low: String,            // "107,572.2"
    pub volume: String,         // "60.84K"
    pub change_percent: String, // "0.61%"
    // Additional optional columns for enhanced data
    pub market_cap: Option<String>,        // For stocks: "2500000000000.00"
    pub circulating_supply: Option<String>, // For crypto: "19500000"
    pub dividend_yield: Option<String>,     // For stocks: "2.5%"
    pub pe_ratio: Option<String>,          // For stocks: "25.5"
} 
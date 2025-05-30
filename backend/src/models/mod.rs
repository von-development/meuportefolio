use serde::{Serialize};
use utoipa::ToSchema;


pub mod user;
mod portfolio;
mod risk;
mod funds;
mod trading;

pub use user::*;
pub use portfolio::*;
pub use risk::*;
pub use funds::*;
pub use trading::*;

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
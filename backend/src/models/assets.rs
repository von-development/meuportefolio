use serde::{Serialize, Deserialize};
use utoipa::ToSchema;

// =============================================================
// ASSET TRAIT AND IMPLEMENTATIONS
// =============================================================

/// Common trait for all asset types
#[allow(dead_code)]
pub trait AssetDetails {
    fn get_asset_id(&self) -> i32;
    fn get_asset_type(&self) -> &str;
    fn validate(&self) -> Result<(), String>;
}

/// Asset type enumeration for better type safety
#[derive(Debug, Clone, Serialize, Deserialize, ToSchema)]
pub enum AssetType {
    Stock,
    Cryptocurrency,
    Index,
    Commodity,
}

impl std::fmt::Display for AssetType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AssetType::Stock => write!(f, "Stock"),
            AssetType::Cryptocurrency => write!(f, "Cryptocurrency"),
            AssetType::Index => write!(f, "Index"),
            AssetType::Commodity => write!(f, "Commodity"),
        }
    }
}

impl AssetType {
    pub fn from_str(s: &str) -> Result<AssetType, String> {
        match s.to_lowercase().as_str() {
            "stock" => Ok(AssetType::Stock),
            "cryptocurrency" | "crypto" => Ok(AssetType::Cryptocurrency),
            "index" => Ok(AssetType::Index),
            "commodity" => Ok(AssetType::Commodity),
            _ => Err(format!("Invalid asset type: {}", s)),
        }
    }

    #[allow(dead_code)]
    pub fn valid_types() -> Vec<&'static str> {
        vec!["Stock", "Cryptocurrency", "Index", "Commodity"]
    }
}

// =============================================================
// ASSET CREATION FACTORY
// =============================================================

/// Factory for creating different types of assets
#[allow(dead_code)]
pub struct AssetFactory;

impl AssetFactory {
    pub fn validate_asset_type(asset_type: &str) -> Result<AssetType, String> {
        AssetType::from_str(asset_type)
    }

    #[allow(dead_code)]
    pub fn validate_stock_data(sector: &str, country: &str, market_cap: Option<f64>) -> Result<(), String> {
        if sector.trim().is_empty() {
            return Err("Sector cannot be empty for stocks".to_string());
        }
        
        if country.trim().is_empty() {
            return Err("Country cannot be empty for stocks".to_string());
        }

        if let Some(cap) = market_cap {
            if cap < 0.0 {
                return Err("Market cap cannot be negative".to_string());
            }
        }

        Ok(())
    }

    #[allow(dead_code)]
    pub fn validate_crypto_data(blockchain: &str, max_supply: Option<f64>, circulating_supply: Option<f64>) -> Result<(), String> {
        if blockchain.trim().is_empty() {
            return Err("Blockchain cannot be empty for cryptocurrencies".to_string());
        }

        if let Some(max) = max_supply {
            if max <= 0.0 {
                return Err("Max supply must be positive".to_string());
            }
        }

        if let Some(circulating) = circulating_supply {
            if circulating < 0.0 {
                return Err("Circulating supply cannot be negative".to_string());
            }

            if let Some(max) = max_supply {
                if circulating > max {
                    return Err("Circulating supply cannot exceed max supply".to_string());
                }
            }
        }

        Ok(())
    }

    #[allow(dead_code)]
    pub fn validate_index_data(country: &str, region: &str, index_type: &str, component_count: Option<i32>) -> Result<(), String> {
        if country.trim().is_empty() {
            return Err("Country cannot be empty for indices".to_string());
        }

        if region.trim().is_empty() {
            return Err("Region cannot be empty for indices".to_string());
        }

        if index_type.trim().is_empty() {
            return Err("Index type cannot be empty".to_string());
        }

        if let Some(count) = component_count {
            if count <= 0 {
                return Err("Component count must be positive".to_string());
            }
        }

        Ok(())
    }

    #[allow(dead_code)]
    pub fn validate_commodity_data(category: &str, unit: &str) -> Result<(), String> {
        if category.trim().is_empty() {
            return Err("Category cannot be empty for commodities".to_string());
        }

        if unit.trim().is_empty() {
            return Err("Unit cannot be empty for commodities".to_string());
        }

        Ok(())
    }
}

// =============================================================
// ASSET UTILITY FUNCTIONS
// =============================================================

/// Utility functions for asset operations
#[allow(dead_code)]
pub struct AssetUtils;

impl AssetUtils {
    /// Normalize asset symbol (uppercase, trim)
    pub fn normalize_symbol(symbol: &str) -> String {
        symbol.trim().to_uppercase()
    }

    /// Validate basic asset data
    pub fn validate_basic_asset_data(symbol: &str, name: &str, price: Option<f64>, volume: Option<i64>, shares: Option<f64>) -> Result<(), String> {
        if symbol.trim().is_empty() {
            return Err("Symbol cannot be empty".to_string());
        }

        if name.trim().is_empty() {
            return Err("Name cannot be empty".to_string());
        }

        if let Some(p) = price {
            if p < 0.0 {
                return Err("Price cannot be negative".to_string());
            }
        }

        if let Some(v) = volume {
            if v < 0 {
                return Err("Volume cannot be negative".to_string());
            }
        }

        if let Some(s) = shares {
            if s < 0.0 {
                return Err("Available shares cannot be negative".to_string());
            }
        }

        Ok(())
    }

    /// Calculate market value
    #[allow(dead_code)]
    pub fn calculate_market_value(price: f64, shares: f64) -> f64 {
        price * shares
    }

    /// Format price for display
    #[allow(dead_code)]
    pub fn format_price(price: f64, asset_type: &AssetType) -> String {
        match asset_type {
            AssetType::Stock | AssetType::Index => format!("${:.2}", price),
            AssetType::Cryptocurrency => {
                if price >= 1.0 {
                    format!("${:.2}", price)
                } else {
                    format!("${:.6}", price)
                }
            }
            AssetType::Commodity => format!("${:.2}", price),
        }
    }

    /// Get typical volume ranges by asset type
    #[allow(dead_code)]
    pub fn get_volume_range(asset_type: &AssetType) -> (i64, i64) {
        match asset_type {
            AssetType::Stock => (100_000, 100_000_000),
            AssetType::Cryptocurrency => (1_000, 10_000_000),
            AssetType::Index => (10_000_000, 1_000_000_000),
            AssetType::Commodity => (1_000, 50_000_000),
        }
    }
} 
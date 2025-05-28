use rust_decimal::prelude::*;
use rust_decimal::Decimal;

/// Converts an Option<Decimal> to f64, with a default of 0.0 if None or conversion fails
pub fn decimal_to_f64(decimal: Option<Decimal>) -> f64 {
    decimal
        .and_then(|d| d.to_f64())
        .unwrap_or_default()
}

/// Converts a SQL decimal string to Decimal
pub fn sql_decimal_to_decimal(value: Option<&str>) -> Option<Decimal> {
    value.and_then(|s| s.parse::<Decimal>().ok())
}

/// Converts a numeric value to a SQL-compatible string representation
/// This function handles both the conversion and ensures the string lives
/// long enough for SQL queries
pub fn to_sql_numeric<T: ToString>(value: T) -> String {
    value.to_string()
} 
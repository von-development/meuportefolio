use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

mod portfolio;
mod risk;
pub use portfolio::*;
pub use risk::*;

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

/// Represents a user in the system
#[derive(Serialize, Deserialize, ToSchema)]
pub struct User {
    #[schema(value_type = String, format = "uuid", example = "123e4567-e89b-12d3-a456-426614174000")]
    pub user_id: Uuid,
    #[schema(example = "John Doe")]
    pub name: String,
    #[schema(example = "john.doe@example.com")]
    pub email: String,
    #[schema(example = "United States")]
    pub country_of_residence: String,
    #[schema(example = "US123456789")]
    pub iban: String,
    #[schema(example = "regular")]
    pub user_type: String,
    #[schema(example = "2024-03-20T10:00:00Z")]
    pub created_at: String,
    #[schema(example = "2024-03-20T10:00:00Z")]
    pub updated_at: String,
}

/// Request payload for creating a new user
#[derive(Deserialize, ToSchema)]
pub struct CreateUserRequest {
    #[schema(example = "John Doe")]
    pub name: String,
    #[schema(example = "john.doe@example.com")]
    pub email: String,
    #[schema(example = "strongPassword123")]
    pub password: String,
    #[schema(example = "United States")]
    pub country_of_residence: String,
    #[schema(example = "US123456789")]
    pub iban: String,
    #[schema(example = "regular")]
    pub user_type: String,
}

/// Request payload for updating a user
#[derive(Deserialize, ToSchema)]
pub struct UpdateUserRequest {
    #[schema(example = "John Doe Updated")]
    pub name: Option<String>,
    #[schema(example = "john.updated@example.com")]
    pub email: Option<String>,
    #[schema(example = "United States")]
    pub country_of_residence: Option<String>,
    #[schema(example = "US987654321")]
    pub iban: Option<String>,
    #[schema(example = "premium")]
    pub user_type: Option<String>,
}

/// Request payload for user login
#[derive(Deserialize, ToSchema)]
pub struct LoginRequest {
    #[schema(example = "john.doe@example.com")]
    pub email: String,
    #[schema(example = "strongPassword123")]
    pub password: String,
}

/// Response payload for successful login
#[derive(Serialize, ToSchema)]
pub struct LoginResponse {
    #[schema(example = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")]
    pub token: String,
    pub user: User,
} 
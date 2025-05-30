use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

/// Basic user model (backward compatible)
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
    #[schema(example = "Premium")]
    pub user_type: String,
    #[schema(example = "2024-03-20T10:00:00Z")]
    pub created_at: String,
    #[schema(example = "2024-03-20T10:00:00Z")]
    pub updated_at: String,
}

/// Extended user model with payment and subscription info
#[derive(Serialize, Deserialize, ToSchema)]
pub struct ExtendedUser {
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
    #[schema(example = "Premium")]
    pub user_type: String,
    #[schema(example = 1000.50)]
    pub account_balance: f64,
    
    // Payment Method Fields
    #[schema(example = "CreditCard")]
    pub payment_method_type: Option<String>,
    #[schema(example = "VISA ****4582")]
    pub payment_method_details: Option<String>,
    #[schema(example = "2027-12-31")]
    pub payment_method_expiry: Option<String>,
    pub payment_method_active: bool,
    
    // Subscription Fields
    pub is_premium: bool,
    #[schema(example = "2024-01-01T00:00:00Z")]
    pub premium_start_date: Option<String>,
    #[schema(example = "2025-01-01T00:00:00Z")]
    pub premium_end_date: Option<String>,
    #[schema(example = 50.00)]
    pub monthly_subscription_rate: Option<f64>,
    pub auto_renew_subscription: bool,
    #[schema(example = "2024-01-01T00:00:00Z")]
    pub last_subscription_payment: Option<String>,
    #[schema(example = "2024-02-01T00:00:00Z")]
    pub next_subscription_payment: Option<String>,
    
    // Calculated fields
    pub days_remaining_in_subscription: i32,
    pub subscription_expired: bool,
    
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
    #[schema(example = "Basic")]
    pub user_type: String,
}

/// Request payload for updating a user
#[derive(Deserialize, ToSchema)]
pub struct UpdateUserRequest {
    #[schema(example = "John Doe Updated")]
    pub name: Option<String>,
    #[schema(example = "john.updated@example.com")]
    pub email: Option<String>,
    #[schema(example = "newPassword123")]
    pub password: Option<String>,
    #[schema(example = "United States")]
    pub country_of_residence: Option<String>,
    #[schema(example = "US987654321")]
    pub iban: Option<String>,
    #[schema(example = "Premium")]
    pub user_type: Option<String>,
}

/// Request to set/update user payment method
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct SetPaymentMethodRequest {
    #[schema(example = "CreditCard")]
    pub payment_method_type: String,
    #[schema(example = "VISA ****4582")]
    pub payment_method_details: String,
    #[schema(example = "2027-12-31")]
    pub payment_method_expiry: Option<String>,
}

/// Request to manage subscription
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct ManageSubscriptionRequest {
    #[schema(example = "ACTIVATE")]
    pub action: String, // ACTIVATE, RENEW, CANCEL
    #[schema(example = 3)]
    pub months_to_add: Option<i32>,
    #[schema(example = 50.00)]
    pub monthly_rate: Option<f64>,
}

/// Response for payment method operations
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct PaymentMethodResponse {
    pub status: String,
    pub message: String,
}

/// Response for subscription operations
#[derive(Debug, Serialize, Deserialize, ToSchema)]
pub struct SubscriptionResponse {
    pub status: String,
    pub amount_paid: Option<f64>,
    pub months_added: Option<i32>,
    pub new_balance: Option<f64>,
    pub message: Option<String>,
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
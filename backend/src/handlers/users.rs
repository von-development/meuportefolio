use axum::{Json, extract::Path};
use crate::{models::{User, ExtendedUser, CreateUserRequest, UpdateUserRequest, LoginRequest, LoginResponse, DepositRequest, WithdrawRequest, AllocateRequest, DeallocateRequest, UpgradePremiumRequest, FundOperationResponse, PremiumUpgradeResponse, AccountSummary, SetPaymentMethodRequest, PaymentMethodResponse, ManageSubscriptionRequest, SubscriptionResponse}, db};
use tiberius::time::chrono;
use uuid::Uuid;
use jsonwebtoken::{encode, Header, EncodingKey};
use serde::{Serialize, Deserialize};
use axum::http::header::{AUTHORIZATION, SET_COOKIE};
use axum::response::Response;
use axum::http::{StatusCode, response::Builder};
use std::time::{SystemTime, UNIX_EPOCH};

// Helper function to safely convert SQL Server Numeric to f64
fn numeric_to_f64(numeric: tiberius::numeric::Numeric) -> f64 {
    numeric.to_string().parse::<f64>().unwrap_or(0.0)
}

// Helper function to safely convert SQL Server integer to boolean
fn int_to_bool(value: Option<i32>) -> bool {
    value.unwrap_or(0) != 0
}

/// List all users
#[utoipa::path(
    get,
    path = "/api/v1/users",
    tag = "users",
    responses(
        (status = 200, description = "List of users retrieved successfully", body = Vec<User>),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn list_users() -> Result<Json<Vec<User>>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let query = "SELECT UserID, Name, Email, CountryOfResidence, IBAN, UserType, CreatedAt, UpdatedAt FROM portfolio.Users ORDER BY CreatedAt DESC";
    let stream = client.query(query, &[]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?;
    
    let users = rows.into_iter().map(|row| {
        User {
            user_id: row.get::<tiberius::Uuid, _>("UserID")
                .map(|uuid| Uuid::from_bytes(*uuid.as_bytes()))
                .unwrap_or_default(),
            name: row.get::<&str, _>("Name").unwrap_or("").to_string(),
            email: row.get::<&str, _>("Email").unwrap_or("").to_string(),
            country_of_residence: row.get::<&str, _>("CountryOfResidence").unwrap_or("").to_string(),
            iban: row.get::<&str, _>("IBAN").unwrap_or("").to_string(),
            user_type: row.get::<&str, _>("UserType").unwrap_or("").to_string(),
            created_at: row.get::<chrono::NaiveDateTime, _>("CreatedAt")
                .map(|dt| dt.to_string())
                .unwrap_or_default(),
            updated_at: row.get::<chrono::NaiveDateTime, _>("UpdatedAt")
                .map(|dt| dt.to_string())
                .unwrap_or_default(),
        }
    }).collect();

    Ok(Json(users))
}

/// Get a specific user by ID
#[utoipa::path(
    get,
    path = "/api/v1/users/{user_id}",
    tag = "users",
    params(
        ("user_id" = String, Path, description = "User ID to fetch")
    ),
    responses(
        (status = 200, description = "User found successfully", body = User),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_user(Path(user_id): Path<Uuid>) -> Result<Json<User>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());

    // Use simple query for basic user info
    let query = "SELECT UserID, Name, Email, CountryOfResidence, IBAN, UserType, CreatedAt, UpdatedAt FROM portfolio.Users WHERE UserID = @P1";
    let stream = client.query(query, &[&tiberius_user_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::NOT_FOUND, "User not found".to_string()))?;

    let user = User {
        user_id: Uuid::from_bytes(*tiberius_user_id.as_bytes()),
        name: row.get::<&str, _>("Name").unwrap_or("").to_string(),
        email: row.get::<&str, _>("Email").unwrap_or("").to_string(),
        country_of_residence: row.get::<&str, _>("CountryOfResidence").unwrap_or("").to_string(),
        iban: row.get::<&str, _>("IBAN").unwrap_or("").to_string(),
        user_type: row.get::<&str, _>("UserType").unwrap_or("").to_string(),
        created_at: row.get::<chrono::NaiveDateTime, _>("CreatedAt")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
        updated_at: row.get::<chrono::NaiveDateTime, _>("UpdatedAt")
            .map(|dt| dt.to_string())
            .unwrap_or_default(),
    };

    Ok(Json(user))
}

/// Get complete user info including payment and subscription details
#[utoipa::path(
    get,
    path = "/api/v1/users/{user_id}/complete",
    tag = "users",
    params(
        ("user_id" = String, Path, description = "User ID to fetch complete info for")
    ),
    responses(
        (status = 200, description = "Complete user info retrieved successfully", body = ExtendedUser),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_user_extended(Path(user_id): Path<Uuid>) -> Result<Json<ExtendedUser>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());

    // Use the stored procedure for complete user info
    let query = "EXEC portfolio.sp_GetUserCompleteInfo @P1";
    let stream = client.query(query, &[&tiberius_user_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::NOT_FOUND, "User not found".to_string()))?;

    let user = ExtendedUser {
        user_id: Uuid::from_bytes(*tiberius_user_id.as_bytes()),
        name: row.get::<&str, _>("Name").unwrap_or("").to_string(),
        email: row.get::<&str, _>("Email").unwrap_or("").to_string(),
        country_of_residence: row.get::<&str, _>("CountryOfResidence").unwrap_or("").to_string(),
        iban: row.get::<&str, _>("IBAN").unwrap_or("").to_string(),
        user_type: row.get::<&str, _>("UserType").unwrap_or("").to_string(),
        account_balance: row.get::<tiberius::numeric::Numeric, _>("AccountBalance")
            .map(numeric_to_f64).unwrap_or_default(),
        
        // Payment Method Fields
        payment_method_type: row.get::<&str, _>("PaymentMethodType").map(|s| s.to_string()),
        payment_method_details: row.get::<&str, _>("PaymentMethodDetails").map(|s| s.to_string()),
        payment_method_expiry: row.get::<chrono::NaiveDate, _>("PaymentMethodExpiry")
            .map(|d| d.format("%Y-%m-%d").to_string()),
        payment_method_active: row.get::<bool, _>("PaymentMethodActive").unwrap_or(false),
        
        // Subscription Fields
        is_premium: row.get::<bool, _>("IsPremium").unwrap_or(false),
        premium_start_date: row.get::<chrono::NaiveDateTime, _>("PremiumStartDate")
            .map(|dt| dt.format("%Y-%m-%dT%H:%M:%SZ").to_string()),
        premium_end_date: row.get::<chrono::NaiveDateTime, _>("PremiumEndDate")
            .map(|dt| dt.format("%Y-%m-%dT%H:%M:%SZ").to_string()),
        monthly_subscription_rate: row.get::<tiberius::numeric::Numeric, _>("MonthlySubscriptionRate")
            .map(numeric_to_f64),
        auto_renew_subscription: row.get::<bool, _>("AutoRenewSubscription").unwrap_or(false),
        last_subscription_payment: row.get::<chrono::NaiveDateTime, _>("LastSubscriptionPayment")
            .map(|dt| dt.format("%Y-%m-%dT%H:%M:%SZ").to_string()),
        next_subscription_payment: row.get::<chrono::NaiveDateTime, _>("NextSubscriptionPayment")
            .map(|dt| dt.format("%Y-%m-%dT%H:%M:%SZ").to_string()),
        
        // Calculated fields
        days_remaining_in_subscription: row.get::<i32, _>("DaysRemainingInSubscription").unwrap_or(0),
        subscription_expired: row.get::<bool, _>("SubscriptionExpired").unwrap_or(false),
        
        created_at: row.get::<chrono::NaiveDateTime, _>("CreatedAt")
            .map(|dt| dt.format("%Y-%m-%dT%H:%M:%SZ").to_string())
            .unwrap_or_default(),
        updated_at: row.get::<chrono::NaiveDateTime, _>("UpdatedAt")
            .map(|dt| dt.format("%Y-%m-%dT%H:%M:%SZ").to_string())
            .unwrap_or_default(),
    };

    Ok(Json(user))
}

/// Create a new user
#[utoipa::path(
    post,
    path = "/api/v1/users",
    tag = "users",
    request_body = CreateUserRequest,
    responses(
        (status = 201, description = "User created successfully", body = User),
        (status = 400, description = "Invalid request data"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn create_user(Json(user): Json<CreateUserRequest>) -> Result<Json<User>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    // Check if email already exists
    let check_query = "SELECT COUNT(*) as count FROM portfolio.Users WHERE Email = @P1";
    let stream = client.query(check_query, &[&user.email]).await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check email: {}", e)))?;
    
    let result = stream.into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch email check results: {}", e)))?;
    
    let count: i32 = result.first()
        .and_then(|row| row.get("count"))
        .unwrap_or(0);

    if count > 0 {
        return Err((StatusCode::BAD_REQUEST, "Email already exists".to_string()));
    }

    let query = "EXEC portfolio.sp_CreateUser @P1, @P2, @P3, @P4, @P5, @P6";
    let stream = client.query(
        query,
        &[
            &user.name,
            &user.email,
            &user.password,
            &user.country_of_residence,
            &user.iban,
            &user.user_type,
        ],
    ).await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to create user: {}", e)))?;

    let result = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get created user: {}", e)))?;
    
    let row = result.into_iter().next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned from create user".to_string()))?;
    
    let user_id = row.get::<tiberius::Uuid, _>("UserID")
        .map(|uuid| Uuid::from_bytes(*uuid.as_bytes()))
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "UserID was null".to_string()))?;

    get_user(Path(user_id)).await.map(|user| Json(user.0))
}

/// Update a user
#[utoipa::path(
    put,
    path = "/api/v1/users/{user_id}",
    tag = "users",
    request_body = UpdateUserRequest,
    params(
        ("user_id" = String, Path, description = "User ID to update")
    ),
    responses(
        (status = 200, description = "User updated successfully", body = User),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn update_user(Path(user_id): Path<Uuid>, Json(update): Json<UpdateUserRequest>) -> Result<Json<User>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());

    // Use stored procedure for update
    let query = "EXEC portfolio.sp_UpdateUser @P1, @P2, @P3, @P4, @P5, @P6, @P7";
    
    // Prepare parameters - pass NULL for fields that shouldn't be updated
    let name_param: Option<&str> = update.name.as_deref();
    let email_param: Option<&str> = update.email.as_deref();
    let password_param: Option<&str> = update.password.as_deref();
    let country_param: Option<&str> = update.country_of_residence.as_deref();
    let iban_param: Option<&str> = update.iban.as_deref();
    let user_type_param: Option<&str> = update.user_type.as_deref();

    let stream = client.query(
        query,
        &[
            &tiberius_user_id,
            &name_param,
            &email_param,
            &password_param,
            &country_param,
            &iban_param,
            &user_type_param,
        ],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User not found") {
            (StatusCode::NOT_FOUND, "User not found".to_string())
        } else if error_msg.contains("Email already exists") {
            (StatusCode::BAD_REQUEST, "Email already exists".to_string())
        } else if error_msg.contains("No fields to update") {
            (StatusCode::BAD_REQUEST, "No fields to update".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to update user: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch updated user: {}", e)))?;

    let user = rows.into_iter().next().map(|row| {
        User {
            user_id: row.get::<tiberius::Uuid, _>("UserID")
                .map(|uuid| Uuid::from_bytes(*uuid.as_bytes()))
                .unwrap_or_default(),
            name: row.get::<&str, _>("Name").unwrap_or("").to_string(),
            email: row.get::<&str, _>("Email").unwrap_or("").to_string(),
            country_of_residence: row.get::<&str, _>("CountryOfResidence").unwrap_or("").to_string(),
            iban: row.get::<&str, _>("IBAN").unwrap_or("").to_string(),
            user_type: row.get::<&str, _>("UserType").unwrap_or("").to_string(),
            created_at: row.get::<chrono::NaiveDateTime, _>("CreatedAt")
                .map(|dt| dt.to_string())
                .unwrap_or_default(),
            updated_at: row.get::<chrono::NaiveDateTime, _>("UpdatedAt")
                .map(|dt| dt.to_string())
                .unwrap_or_default(),
        }
    }).ok_or((StatusCode::NOT_FOUND, "User not found after update".to_string()))?;

    Ok(Json(user))
}

/// Delete a user
#[utoipa::path(
    delete,
    path = "/api/v1/users/{user_id}",
    tag = "users",
    params(
        ("user_id" = String, Path, description = "User ID to delete")
    ),
    responses(
        (status = 204, description = "User deleted successfully"),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn delete_user(Path(user_id): Path<Uuid>) -> Result<StatusCode, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());

    // Check if user exists
    let check_query = "SELECT COUNT(*) as count FROM portfolio.Users WHERE UserID = @P1";
    let stream = client.query(check_query, &[&tiberius_user_id]).await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check user existence: {}", e)))?;
    
    let result = stream.into_first_result().await.map_err(|e|
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch user check results: {}", e)))?;
    
    let count: i32 = result.first()
        .and_then(|row| row.get("count"))
        .unwrap_or(0);

    if count == 0 {
        return Err((StatusCode::NOT_FOUND, "User not found".to_string()));
    }

    let query = "DELETE FROM portfolio.Users WHERE UserID = @P1";
    let stream = client.query(query, &[&tiberius_user_id]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to delete user: {}", e)))?;
    
    stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to confirm deletion: {}", e)))?;

    Ok(StatusCode::NO_CONTENT)
}

/// User login
#[utoipa::path(
    post,
    path = "/api/v1/users/login",
    tag = "users",
    request_body = LoginRequest,
    responses(
        (status = 200, description = "Login successful", body = LoginResponse),
        (status = 401, description = "Invalid credentials"),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn login(Json(login): Json<LoginRequest>) -> Result<Response<String>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("DB connect error: {}", e)))?;

    let query = "SELECT * FROM portfolio.Users WHERE Email = @P1";
    let stream = client.query(query, &[&login.email]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Query error: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Row error: {}", e)))?;

    let user = rows.into_iter().next().map(|row| {
        let user_id = row.get::<tiberius::Uuid, _>("UserID")
            .map(|uuid| Uuid::from_bytes(*uuid.as_bytes()))
            .unwrap_or_default();
            
        (
            row.get::<&str, _>("Password").unwrap_or("").to_string(),
            User {
                user_id,
                name: row.get::<&str, _>("Name").unwrap_or("").to_string(),
                email: row.get::<&str, _>("Email").unwrap_or("").to_string(),
                country_of_residence: row.get::<&str, _>("CountryOfResidence").unwrap_or("").to_string(),
                iban: row.get::<&str, _>("IBAN").unwrap_or("").to_string(),
                user_type: row.get::<&str, _>("UserType").unwrap_or("").to_string(),
                created_at: row.get::<chrono::NaiveDateTime, _>("CreatedAt")
                    .map(|dt| dt.to_string())
                    .unwrap_or_default(),
                updated_at: row.get::<chrono::NaiveDateTime, _>("UpdatedAt")
                    .map(|dt| dt.to_string())
                    .unwrap_or_default(),
            }
        )
    }).ok_or((StatusCode::UNAUTHORIZED, "Invalid credentials".to_string()))?;

    let (password, user) = user;

    // Verify password (now using plain text comparison)
    if password != login.password {
        return Err((StatusCode::UNAUTHORIZED, "Invalid credentials".to_string()));
    }

    // Create JWT token
    let expiration = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap()
        .as_secs() as usize + 24 * 3600; // 24 hours from now

    let claims = Claims {
        sub: user.user_id.to_string(),
        exp: expiration,
    };

    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret("your-secret-key".as_bytes()) // Use environment variable in production
    ).map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Token creation error: {}", e)))?;

    // Create response with token in header and cookie
    let response = Builder::new()
        .status(StatusCode::OK)
        .header(AUTHORIZATION, format!("Bearer {}", token))
        .header(SET_COOKIE, format!("token={}; HttpOnly; Path=/; Max-Age=86400", token))
        .body(serde_json::to_string(&LoginResponse { token: token.clone(), user }).unwrap())
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Response creation error: {}", e)))?;

    Ok(response)
}

/// User logout
#[utoipa::path(
    post,
    path = "/api/v1/users/logout",
    tag = "users",
    responses(
        (status = 200, description = "Logout successful"),
        (status = 500, description = "Internal server error")
    )
)]
pub async fn logout() -> Result<Response<String>, (StatusCode, String)> {
    // Clear the token cookie
    let response = Builder::new()
        .status(StatusCode::OK)
        .header(SET_COOKIE, "token=; HttpOnly; Path=/; Max-Age=0")
        .body("Logged out successfully".to_string())
        .map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, format!("Response creation error: {}", e)))?;

    Ok(response)
}

// JWT claims structure
#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: String, // user_id
    exp: usize,  // expiration time
}

// =============================================================
// FUND MANAGEMENT ENDPOINTS
// =============================================================

/// Deposit funds to user account
#[utoipa::path(
    post,
    path = "/api/v1/users/{user_id}/deposit",
    tag = "users",
    request_body = DepositRequest,
    params(
        ("user_id" = String, Path, description = "User ID to deposit funds to")
    ),
    responses(
        (status = 200, description = "Funds deposited successfully", body = FundOperationResponse),
        (status = 400, description = "Invalid request data"),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn deposit_funds(
    Path(user_id): Path<Uuid>, 
    Json(request): Json<DepositRequest>
) -> Result<Json<FundOperationResponse>, (StatusCode, String)> {
    if request.amount <= 0.0 {
        return Err((StatusCode::BAD_REQUEST, "Amount must be positive".to_string()));
    }

    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());
    let description = request.description.unwrap_or_else(|| "Deposit via API".to_string());

    let query = "EXEC portfolio.sp_DepositFunds @P1, @P2, @P3";
    let stream = client.query(
        query,
        &[&tiberius_user_id, &request.amount, &description],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User not found") {
            (StatusCode::NOT_FOUND, "User not found".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to deposit funds: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch deposit result: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned from deposit".to_string()))?;

    let new_balance: f64 = row.get::<tiberius::numeric::Numeric, _>("NewBalance")
        .map(numeric_to_f64)
        .unwrap_or_default();

    Ok(Json(FundOperationResponse {
        status: "Success".to_string(),
        amount: request.amount,
        new_balance,
        new_portfolio_funds: None,
    }))
}

/// Withdraw funds from user account
#[utoipa::path(
    post,
    path = "/api/v1/users/{user_id}/withdraw",
    tag = "users",
    request_body = WithdrawRequest,
    params(
        ("user_id" = String, Path, description = "User ID to withdraw funds from")
    ),
    responses(
        (status = 200, description = "Funds withdrawn successfully", body = FundOperationResponse),
        (status = 400, description = "Invalid request data or insufficient balance"),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn withdraw_funds(
    Path(user_id): Path<Uuid>, 
    Json(request): Json<WithdrawRequest>
) -> Result<Json<FundOperationResponse>, (StatusCode, String)> {
    if request.amount <= 0.0 {
        return Err((StatusCode::BAD_REQUEST, "Amount must be positive".to_string()));
    }

    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());
    let description = request.description.unwrap_or_else(|| "Withdrawal via API".to_string());

    let query = "EXEC portfolio.sp_WithdrawFunds @P1, @P2, @P3";
    let stream = client.query(
        query,
        &[&tiberius_user_id, &request.amount, &description],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User not found") {
            (StatusCode::NOT_FOUND, "User not found".to_string())
        } else if error_msg.contains("Insufficient balance") {
            (StatusCode::BAD_REQUEST, "Insufficient account balance".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to withdraw funds: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch withdrawal result: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned from withdrawal".to_string()))?;

    let new_balance: f64 = row.get::<tiberius::numeric::Numeric, _>("NewBalance")
        .map(numeric_to_f64)
        .unwrap_or_default();

    Ok(Json(FundOperationResponse {
        status: "Success".to_string(),
        amount: request.amount,
        new_balance,
        new_portfolio_funds: None,
    }))
}

/// Allocate funds from user account to portfolio
#[utoipa::path(
    post,
    path = "/api/v1/users/{user_id}/allocate",
    tag = "users",
    request_body = AllocateRequest,
    params(
        ("user_id" = String, Path, description = "User ID to allocate funds from")
    ),
    responses(
        (status = 200, description = "Funds allocated successfully", body = FundOperationResponse),
        (status = 400, description = "Invalid request data or insufficient balance"),
        (status = 404, description = "User or portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn allocate_funds(
    Path(user_id): Path<Uuid>, 
    Json(request): Json<AllocateRequest>
) -> Result<Json<FundOperationResponse>, (StatusCode, String)> {
    if request.amount <= 0.0 {
        return Err((StatusCode::BAD_REQUEST, "Amount must be positive".to_string()));
    }

    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());

    let query = "EXEC portfolio.sp_AllocateFunds @P1, @P2, @P3";
    let stream = client.query(
        query,
        &[&tiberius_user_id, &request.portfolio_id, &request.amount],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User not found") {
            (StatusCode::NOT_FOUND, "User not found".to_string())
        } else if error_msg.contains("Portfolio not found") {
            (StatusCode::NOT_FOUND, "Portfolio not found".to_string())
        } else if error_msg.contains("Insufficient balance") {
            (StatusCode::BAD_REQUEST, "Insufficient account balance".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to allocate funds: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch allocation result: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned from allocation".to_string()))?;

    let new_balance: f64 = row.get::<tiberius::numeric::Numeric, _>("NewUserBalance")
        .map(numeric_to_f64)
        .unwrap_or_default();
    let new_portfolio_funds: f64 = row.get::<tiberius::numeric::Numeric, _>("NewPortfolioFunds")
        .map(numeric_to_f64)
        .unwrap_or_default();

    Ok(Json(FundOperationResponse {
        status: "Success".to_string(),
        amount: request.amount,
        new_balance,
        new_portfolio_funds: Some(new_portfolio_funds),
    }))
}

/// Deallocate funds from portfolio back to user account
#[utoipa::path(
    post,
    path = "/api/v1/users/{user_id}/deallocate",
    tag = "users",
    request_body = DeallocateRequest,
    params(
        ("user_id" = String, Path, description = "User ID to deallocate funds to")
    ),
    responses(
        (status = 200, description = "Funds deallocated successfully", body = FundOperationResponse),
        (status = 400, description = "Invalid request data or insufficient portfolio funds"),
        (status = 404, description = "User or portfolio not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn deallocate_funds(
    Path(user_id): Path<Uuid>, 
    Json(request): Json<DeallocateRequest>
) -> Result<Json<FundOperationResponse>, (StatusCode, String)> {
    if request.amount <= 0.0 {
        return Err((StatusCode::BAD_REQUEST, "Amount must be positive".to_string()));
    }

    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());

    let query = "EXEC portfolio.sp_DeallocateFunds @P1, @P2, @P3";
    let stream = client.query(
        query,
        &[&tiberius_user_id, &request.portfolio_id, &request.amount],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User not found") {
            (StatusCode::NOT_FOUND, "User not found".to_string())
        } else if error_msg.contains("Portfolio not found") {
            (StatusCode::NOT_FOUND, "Portfolio not found".to_string())
        } else if error_msg.contains("Insufficient funds") {
            (StatusCode::BAD_REQUEST, "Insufficient portfolio funds".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to deallocate funds: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch deallocation result: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned from deallocation".to_string()))?;

    let new_balance: f64 = row.get::<tiberius::numeric::Numeric, _>("NewUserBalance")
        .map(numeric_to_f64)
        .unwrap_or_default();
    let new_portfolio_funds: f64 = row.get::<tiberius::numeric::Numeric, _>("NewPortfolioFunds")
        .map(numeric_to_f64)
        .unwrap_or_default();

    Ok(Json(FundOperationResponse {
        status: "Success".to_string(),
        amount: request.amount,
        new_balance,
        new_portfolio_funds: Some(new_portfolio_funds),
    }))
}

/// Upgrade user to premium
#[utoipa::path(
    post,
    path = "/api/v1/users/{user_id}/upgrade-premium",
    tag = "users",
    request_body = UpgradePremiumRequest,
    params(
        ("user_id" = String, Path, description = "User ID to upgrade")
    ),
    responses(
        (status = 200, description = "User upgraded to premium successfully", body = PremiumUpgradeResponse),
        (status = 400, description = "Invalid request data or insufficient balance"),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn upgrade_to_premium(
    Path(user_id): Path<Uuid>, 
    Json(request): Json<UpgradePremiumRequest>
) -> Result<Json<PremiumUpgradeResponse>, (StatusCode, String)> {
    let subscription_months = request.subscription_months.unwrap_or(1);
    let monthly_rate = request.monthly_rate.unwrap_or(50.0);

    if subscription_months <= 0 {
        return Err((StatusCode::BAD_REQUEST, "Subscription months must be positive".to_string()));
    }

    if monthly_rate <= 0.0 {
        return Err((StatusCode::BAD_REQUEST, "Monthly rate must be positive".to_string()));
    }

    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());

    let query = "EXEC portfolio.sp_UpgradeToPremium @P1, @P2, @P3";
    let stream = client.query(
        query,
        &[&tiberius_user_id, &subscription_months, &monthly_rate],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User not found") {
            (StatusCode::NOT_FOUND, "User not found".to_string())
        } else if error_msg.contains("Insufficient balance") {
            (StatusCode::BAD_REQUEST, "Insufficient account balance for premium upgrade".to_string())
        } else if error_msg.contains("already Premium") {
            (StatusCode::BAD_REQUEST, "User is already Premium".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to upgrade to premium: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch upgrade result: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned from upgrade".to_string()))?;

    let new_balance: f64 = row.get::<tiberius::numeric::Numeric, _>("NewBalance")
        .map(numeric_to_f64)
        .unwrap_or_default();
    let amount_paid = subscription_months as f64 * monthly_rate;

    Ok(Json(PremiumUpgradeResponse {
        status: "Success".to_string(),
        amount_paid,
        subscription_months,
        new_balance,
    }))
}

/// Get user account summary
#[utoipa::path(
    get,
    path = "/api/v1/users/{user_id}/account-summary",
    tag = "users",
    params(
        ("user_id" = String, Path, description = "User ID to get account summary for")
    ),
    responses(
        (status = 200, description = "Account summary retrieved successfully", body = AccountSummary),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn get_account_summary(
    Path(user_id): Path<Uuid>
) -> Result<Json<AccountSummary>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());

    let query = "EXEC portfolio.sp_GetUserAccountSummary @P1";
    let stream = client.query(query, &[&tiberius_user_id]).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User not found") {
            (StatusCode::NOT_FOUND, "User not found".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to get account summary: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch account summary: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::NOT_FOUND, "User not found".to_string()))?;

    let summary = AccountSummary {
        user_id,
        name: row.get::<&str, _>("Name").unwrap_or("").to_string(),
        user_type: row.get::<&str, _>("UserType").unwrap_or("").to_string(),
        account_balance: row.get::<tiberius::numeric::Numeric, _>("AccountBalance")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        total_portfolio_value: row.get::<tiberius::numeric::Numeric, _>("TotalPortfolioValue")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        total_net_worth: row.get::<tiberius::numeric::Numeric, _>("TotalNetWorth")
            .map(numeric_to_f64)
            .unwrap_or_default(),
        portfolio_count: row.get("PortfolioCount").unwrap_or(0),
    };

    Ok(Json(summary))
}

/// Set/update user payment method
#[utoipa::path(
    put,
    path = "/api/v1/users/{user_id}/payment-method",
    tag = "users",
    params(
        ("user_id" = String, Path, description = "User ID to set payment method for")
    ),
    request_body = SetPaymentMethodRequest,
    responses(
        (status = 200, description = "Payment method updated successfully", body = PaymentMethodResponse),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn set_payment_method(
    Path(user_id): Path<Uuid>,
    Json(request): Json<SetPaymentMethodRequest>
) -> Result<Json<PaymentMethodResponse>, (StatusCode, String)> {
    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());
    
    // Parse expiry date if provided
    let expiry_date: Option<&str> = request.payment_method_expiry.as_deref();

    let query = "EXEC portfolio.sp_SetUserPaymentMethod @P1, @P2, @P3, @P4";
    let stream = client.query(
        query,
        &[&tiberius_user_id, &request.payment_method_type, &request.payment_method_details, &expiry_date],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User not found") {
            (StatusCode::NOT_FOUND, "User not found".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to set payment method: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch result: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned".to_string()))?;

    let status: String = row.get::<&str, _>("Status").unwrap_or("Unknown").to_string();
    let message: String = row.get::<&str, _>("Message").unwrap_or("Payment method updated").to_string();

    Ok(Json(PaymentMethodResponse { status, message }))
}

/// Manage user subscription (activate, renew, cancel)
#[utoipa::path(
    post,
    path = "/api/v1/users/{user_id}/subscription",
    tag = "users",
    params(
        ("user_id" = String, Path, description = "User ID to manage subscription for")
    ),
    request_body = ManageSubscriptionRequest,
    responses(
        (status = 200, description = "Subscription managed successfully", body = SubscriptionResponse),
        (status = 400, description = "Invalid request or insufficient balance"),
        (status = 404, description = "User not found"),
        (status = 500, description = "Internal server error", body = String)
    )
)]
pub async fn manage_subscription(
    Path(user_id): Path<Uuid>,
    Json(request): Json<ManageSubscriptionRequest>
) -> Result<Json<SubscriptionResponse>, (StatusCode, String)> {
    // Validate action
    if !["ACTIVATE", "RENEW", "CANCEL"].contains(&request.action.as_str()) {
        return Err((StatusCode::BAD_REQUEST, "Invalid action. Use ACTIVATE, RENEW, or CANCEL".to_string()));
    }

    let months_to_add = request.months_to_add.unwrap_or(1);
    let monthly_rate = request.monthly_rate.unwrap_or(50.0);

    if months_to_add <= 0 {
        return Err((StatusCode::BAD_REQUEST, "Months to add must be positive".to_string()));
    }

    if monthly_rate <= 0.0 {
        return Err((StatusCode::BAD_REQUEST, "Monthly rate must be positive".to_string()));
    }

    let mut client = db::get_db_client().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to connect to database: {}", e)))?;

    let tiberius_user_id = tiberius::Uuid::from_bytes(*user_id.as_bytes());

    let query = "EXEC portfolio.sp_ManageSubscription @P1, @P2, @P3, @P4";
    let stream = client.query(
        query,
        &[&tiberius_user_id, &request.action, &months_to_add, &monthly_rate],
    ).await.map_err(|e| {
        let error_msg = format!("{}", e);
        if error_msg.contains("User not found") {
            (StatusCode::NOT_FOUND, "User not found".to_string())
        } else if error_msg.contains("Insufficient") {
            (StatusCode::BAD_REQUEST, "Insufficient account balance for subscription".to_string())
        } else if error_msg.contains("Invalid action") {
            (StatusCode::BAD_REQUEST, "Invalid action specified".to_string())
        } else {
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to manage subscription: {}", e))
        }
    })?;

    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch result: {}", e)))?;

    let row = rows.into_iter().next()
        .ok_or((StatusCode::INTERNAL_SERVER_ERROR, "No result returned".to_string()))?;

    let status: String = row.get::<&str, _>("Status").unwrap_or("Unknown").to_string();
    
    if request.action == "CANCEL" {
        let message: String = row.get::<&str, _>("Message").unwrap_or("Subscription cancelled").to_string();
        Ok(Json(SubscriptionResponse {
            status,
            amount_paid: None,
            months_added: None,
            new_balance: None,
            message: Some(message),
        }))
    } else {
        let amount_paid: Option<f64> = row.get::<tiberius::numeric::Numeric, _>("AmountPaid")
            .map(numeric_to_f64);
        let months_added: Option<i32> = row.get("MonthsAdded");
        let new_balance: Option<f64> = row.get::<tiberius::numeric::Numeric, _>("NewBalance")
            .map(numeric_to_f64);

        Ok(Json(SubscriptionResponse {
            status,
            amount_paid,
            months_added,
            new_balance,
            message: Some("Subscription updated successfully".to_string()),
        }))
    }
} 
use axum::{Json, extract::Path};
use crate::{models::{User, CreateUserRequest, UpdateUserRequest, LoginRequest, LoginResponse}, db};
use tiberius::time::chrono;
use uuid::Uuid;
use jsonwebtoken::{encode, Header, EncodingKey};
use serde::{Serialize, Deserialize};
use axum::http::header::{AUTHORIZATION, SET_COOKIE};
use axum::response::Response;
use axum::http::{StatusCode, response::Builder};
use std::time::{SystemTime, UNIX_EPOCH};

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
            name: row.get::<&str, _>("Name").unwrap_or_default().to_string(),
            email: row.get::<&str, _>("Email").unwrap_or_default().to_string(),
            country_of_residence: row.get::<&str, _>("CountryOfResidence").unwrap_or_default().to_string(),
            iban: row.get::<&str, _>("IBAN").unwrap_or_default().to_string(),
            user_type: row.get::<&str, _>("UserType").unwrap_or_default().to_string(),
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

    let query = "SELECT UserID, Name, Email, CountryOfResidence, IBAN, UserType, CreatedAt, UpdatedAt FROM portfolio.Users WHERE UserID = @P1";
    let stream = client.query(query, &[&tiberius::Uuid::from_bytes(*user_id.as_bytes())]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to execute query: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch results: {}", e)))?;
    
    let user = rows.into_iter().next().map(|row| {
        User {
            user_id: row.get::<tiberius::Uuid, _>("UserID")
                .map(|uuid| Uuid::from_bytes(*uuid.as_bytes()))
                .unwrap_or_default(),
            name: row.get::<&str, _>("Name").unwrap_or_default().to_string(),
            email: row.get::<&str, _>("Email").unwrap_or_default().to_string(),
            country_of_residence: row.get::<&str, _>("CountryOfResidence").unwrap_or_default().to_string(),
            iban: row.get::<&str, _>("IBAN").unwrap_or_default().to_string(),
            user_type: row.get::<&str, _>("UserType").unwrap_or_default().to_string(),
            created_at: row.get::<chrono::NaiveDateTime, _>("CreatedAt")
                .map(|dt| dt.to_string())
                .unwrap_or_default(),
            updated_at: row.get::<chrono::NaiveDateTime, _>("UpdatedAt")
                .map(|dt| dt.to_string())
                .unwrap_or_default(),
        }
    }).ok_or((StatusCode::NOT_FOUND, "User not found".to_string()))?;

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

    // If email is being updated, check for duplicates
    if let Some(ref email) = update.email {
        let check_query = "SELECT COUNT(*) as count FROM portfolio.Users WHERE Email = @P1 AND UserID != @P2";
        let stream = client.query(check_query, &[email, &tiberius_user_id]).await.map_err(|e|
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to check email: {}", e)))?;
        
        let result = stream.into_first_result().await.map_err(|e|
            (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch email check results: {}", e)))?;
        
        let count: i32 = result.first()
            .and_then(|row| row.get("count"))
            .unwrap_or(0);

        if count > 0 {
            return Err((StatusCode::BAD_REQUEST, "Email already exists".to_string()));
        }
    }

    // Build dynamic update query
    let mut updates = Vec::new();
    let mut params: Vec<&(dyn tiberius::ToSql)> = Vec::new();
    let mut param_index = 1;

    if let Some(name) = &update.name {
        updates.push(format!("Name = @P{}", param_index));
        params.push(name);
        param_index += 1;
    }
    if let Some(email) = &update.email {
        updates.push(format!("Email = @P{}", param_index));
        params.push(email);
        param_index += 1;
    }
    if let Some(country) = &update.country_of_residence {
        updates.push(format!("CountryOfResidence = @P{}", param_index));
        params.push(country);
        param_index += 1;
    }
    if let Some(iban) = &update.iban {
        updates.push(format!("IBAN = @P{}", param_index));
        params.push(iban);
        param_index += 1;
    }
    if let Some(user_type) = &update.user_type {
        updates.push(format!("UserType = @P{}", param_index));
        params.push(user_type);
        param_index += 1;
    }

    if updates.is_empty() {
        return Err((StatusCode::BAD_REQUEST, "No fields to update".to_string()));
    }

    // Add UserID to params
    params.push(&tiberius_user_id);

    let query = format!(
        "UPDATE portfolio.Users SET {}, UpdatedAt = SYSDATETIME() WHERE UserID = @P{} OUTPUT INSERTED.*",
        updates.join(", "),
        param_index
    );

    let stream = client.query(&query, &params[..]).await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to update user: {}", e)))?;
    
    let rows = stream.into_first_result().await.map_err(|e| 
        (StatusCode::INTERNAL_SERVER_ERROR, format!("Failed to fetch updated user: {}", e)))?;

    let user = rows.into_iter().next().map(|row| {
        User {
            user_id: row.get::<tiberius::Uuid, _>("UserID")
                .map(|uuid| Uuid::from_bytes(*uuid.as_bytes()))
                .unwrap_or_default(),
            name: row.get::<&str, _>("Name").unwrap_or_default().to_string(),
            email: row.get::<&str, _>("Email").unwrap_or_default().to_string(),
            country_of_residence: row.get::<&str, _>("CountryOfResidence").unwrap_or_default().to_string(),
            iban: row.get::<&str, _>("IBAN").unwrap_or_default().to_string(),
            user_type: row.get::<&str, _>("UserType").unwrap_or_default().to_string(),
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
            row.get::<&str, _>("PasswordHash").unwrap_or("").to_string(),
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

    let (password_hash, user) = user;

    // Verify password (in production, use proper password hashing)
    if password_hash != login.password {
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
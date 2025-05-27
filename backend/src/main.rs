mod models;
mod handlers;
mod db;

use axum::{Router, routing::{get, post, put, delete}};
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;
use tower_http::cors::{CorsLayer, Any};

/// API Documentation
#[derive(OpenApi)]
#[openapi(
    paths(
        handlers::health_check,
        handlers::db_health_check,
        handlers::list_assets,
        handlers::list_users,
        handlers::create_user,
        handlers::get_user,
        handlers::update_user,
        handlers::delete_user,
        handlers::login,
        handlers::logout,
        handlers::list_portfolios,
        handlers::create_portfolio,
        handlers::get_portfolio,
        handlers::update_portfolio,
        handlers::delete_portfolio,
        handlers::get_portfolio_summary,
        handlers::get_portfolio_holdings
    ),
    components(
        schemas(
            models::Asset,
            models::User,
            models::CreateUserRequest,
            models::UpdateUserRequest,
            models::LoginRequest,
            models::LoginResponse,
            models::Portfolio,
            models::CreatePortfolioRequest,
            models::UpdatePortfolioRequest,
            models::PortfolioSummary,
            models::AssetHolding
        )
    ),
    tags(
        (name = "health", description = "Health check endpoints"),
        (name = "users", description = "User management endpoints"),
        (name = "assets", description = "Asset management endpoints"),
        (name = "portfolios", description = "Portfolio management endpoints")
    ),
    info(
        title = "Portfolio API",
        version = "1.0.0",
        description = "API for managing portfolio users and assets"
    )
)]
struct ApiDoc;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    
    // Configure CORS for development
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);
    
    let app = Router::new()
        .merge(SwaggerUi::new("/swagger-ui")
            .url("/api-docs/openapi.json", ApiDoc::openapi()))
        .route("/health", get(handlers::health_check))
        .route("/db-health", get(handlers::db_health_check))
        .route("/users", get(handlers::list_users))
        .route("/users", post(handlers::create_user))
        .route("/users/login", post(handlers::login))
        .route("/users/logout", post(handlers::logout))
        .route("/users/{id}", get(handlers::get_user))
        .route("/users/{id}", put(handlers::update_user))
        .route("/users/{id}", delete(handlers::delete_user))
        .route("/portfolios", get(handlers::list_portfolios))
        .route("/portfolios", post(handlers::create_portfolio))
        .route("/portfolios/{id}", get(handlers::get_portfolio))
        .route("/portfolios/{id}", put(handlers::update_portfolio))
        .route("/portfolios/{id}", delete(handlers::delete_portfolio))
        .route("/portfolios/{id}/summary", get(handlers::get_portfolio_summary))
        .route("/portfolios/{id}/holdings", get(handlers::get_portfolio_holdings))
        .route("/assets", get(handlers::list_assets))
        .layer(cors);

    // Start the server
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await?;
    println!("Server running on http://0.0.0.0:8080");
    println!("API documentation available at http://localhost:8080/swagger-ui");
    println!("Health check available at http://localhost:8080/health");
    println!("Database health check available at http://localhost:8080/db-health");
    axum::serve(listener, app).await?;
    
    Ok(())
}

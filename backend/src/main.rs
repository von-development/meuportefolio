mod models;
mod handlers;
mod db;
mod utils;

use axum::{Router, routing::{get, post, put, delete}};
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;
use tower_http::cors::{CorsLayer, Any};
use axum::http::{Method, HeaderName, header};

/// API Documentation
#[derive(OpenApi)]
#[openapi(
    paths(
        handlers::health_check,
        handlers::db_health_check,
        handlers::list_assets,
        handlers::get_asset,
        handlers::get_asset_price_history,
        handlers::list_companies,
        handlers::list_indices,
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
            models::AssetPriceHistory,
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
    
    // Configure CORS for development with explicit settings
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods([
            Method::GET,
            Method::POST,
            Method::PUT,
            Method::DELETE,
            Method::OPTIONS,
        ])
        .allow_headers([
            header::AUTHORIZATION,
            header::ACCEPT,
            header::CONTENT_TYPE,
            HeaderName::from_static("x-requested-with"),
        ])
        .max_age(std::time::Duration::from_secs(3600));
    
    // User routes first
    let user_routes = Router::new()
        .route("/users", get(handlers::list_users))
        .route("/users", post(handlers::create_user))
        .route("/users/login", post(handlers::login))
        .route("/users/logout", post(handlers::logout))
        .route("/users/{id}", get(handlers::get_user))
        .route("/users/{id}", put(handlers::update_user))
        .route("/users/{id}", delete(handlers::delete_user));

    // Portfolio routes second
    let portfolio_routes = Router::new()
        .route("/portfolios", get(handlers::list_portfolios))
        .route("/portfolios", post(handlers::create_portfolio))
        .route("/portfolios/{id}", get(handlers::get_portfolio))
        .route("/portfolios/{id}", put(handlers::update_portfolio))
        .route("/portfolios/{id}", delete(handlers::delete_portfolio))
        .route("/portfolios/{id}/summary", get(handlers::get_portfolio_summary))
        .route("/portfolios/{id}/holdings", get(handlers::get_portfolio_holdings));

    // Asset routes last
    let asset_routes = Router::new()
        .route("/assets", get(handlers::list_assets))
        .route("/assets/{id}", get(handlers::get_asset))
        .route("/assets/{id}/price-history", get(handlers::get_asset_price_history))
        .route("/assets/companies", get(handlers::list_companies))
        .route("/assets/indices", get(handlers::list_indices));

    // Combine all API routes under v1
    let api_v1 = Router::new()
        .merge(user_routes)
        .merge(portfolio_routes)
        .merge(asset_routes);

    let app = Router::new()
        .merge(SwaggerUi::new("/swagger-ui")
            .url("/api-docs/openapi.json", ApiDoc::openapi()))
        .route("/health", get(handlers::health_check))
        .route("/db-health", get(handlers::db_health_check))
        .nest("/api/v1", api_v1)
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

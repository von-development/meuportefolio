mod models;
mod handlers;
mod db;


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
        handlers::get_portfolio_holdings,
        handlers::get_user_risk_metrics,
        handlers::get_portfolio_risk_analysis,
        handlers::get_risk_summary,
        handlers::get_portfolio_risk_summary,
        handlers::get_user_risk_summary
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
            models::AssetHolding,
            models::RiskMetrics,
            models::RiskAnalysis,
            models::PortfolioRiskAnalysis,
            models::RiskSummary
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
        .route("/users/{userId}", get(handlers::get_user))
        .route("/users/{userId}", put(handlers::update_user))
        .route("/users/{userId}", delete(handlers::delete_user));

    // Portfolio routes second
    let portfolio_routes = Router::new()
        .route("/portfolios", get(handlers::list_portfolios))
        .route("/portfolios", post(handlers::create_portfolio))
        .route("/portfolios/{portfolioId}", get(handlers::get_portfolio))
        .route("/portfolios/{portfolioId}", put(handlers::update_portfolio))
        .route("/portfolios/{portfolioId}", delete(handlers::delete_portfolio))
        .route("/portfolios/{portfolioId}/summary", get(handlers::get_portfolio_summary))
        .route("/portfolios/{portfolioId}/holdings", get(handlers::get_portfolio_holdings));

    // Asset routes last
    let asset_routes = Router::new()
        .route("/assets", get(handlers::list_assets))
        .route("/assets/{assetId}", get(handlers::get_asset))
        .route("/assets/{assetId}/price-history", get(handlers::get_asset_price_history))
        .route("/assets/companies", get(handlers::list_companies))
        .route("/assets/indices", get(handlers::list_indices));

    // Risk routes
    let risk_routes = Router::new()
        .route("/risk/metrics/user/{userId}", get(handlers::get_user_risk_metrics))
        .route("/risk/metrics/portfolio/{portfolioId}", get(handlers::get_portfolio_risk_analysis))
        .route("/risk/summary", get(handlers::get_risk_summary))
        .route("/risk/summary/portfolio/{portfolioId}", get(handlers::get_portfolio_risk_summary))
        .route("/risk/summary/user/{userId}", get(handlers::get_user_risk_summary));

    // Combine all API routes under v1
    let api_v1 = Router::new()
        .merge(user_routes)
        .merge(portfolio_routes)
        .merge(asset_routes)
        .merge(risk_routes);

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

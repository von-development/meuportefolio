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
        handlers::get_user_extended,
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
        handlers::get_user_risk_summary,
        // Fund Management Endpoints
        handlers::deposit_funds,
        handlers::withdraw_funds,
        handlers::allocate_funds,
        handlers::deallocate_funds,
        handlers::upgrade_to_premium,
        handlers::get_account_summary,
        // Trading Endpoints
        handlers::buy_asset,
        handlers::sell_asset,
        handlers::get_portfolio_balance,
        handlers::get_portfolio_holdings_summary,
        handlers::set_payment_method,
        handlers::manage_subscription
    ),
    components(
        schemas(
            models::Asset,
            models::AssetPriceHistory,
            models::User,
            models::ExtendedUser,
            models::CreateUserRequest,
            models::UpdateUserRequest,
            models::LoginRequest,
            models::LoginResponse,
            models::SetPaymentMethodRequest,
            models::PaymentMethodResponse,
            models::ManageSubscriptionRequest,
            models::SubscriptionResponse,
            models::Portfolio,
            models::CreatePortfolioRequest,
            models::UpdatePortfolioRequest,
            models::PortfolioSummary,
            models::AssetHolding,
            models::RiskMetrics,
            models::RiskAnalysis,
            models::PortfolioRiskAnalysis,
            models::RiskSummary,
            // Fund Management Models
            models::DepositRequest,
            models::WithdrawRequest,
            models::AllocateRequest,
            models::DeallocateRequest,
            models::UpgradePremiumRequest,
            models::FundOperationResponse,
            models::PremiumUpgradeResponse,
            models::AccountSummary,
            models::PortfolioBalance,
            models::FundTransaction,
            // Trading Models
            models::BuyAssetRequest,
            models::SellAssetRequest,
            models::BuyAssetResponse,
            models::SellAssetResponse,
            models::PortfolioHolding,
            models::TradingTransaction,
            models::PortfolioHoldingsSummary
        )
    ),
    tags(
        (name = "health", description = "Health check endpoints"),
        (name = "users", description = "User management and fund management endpoints"),
        (name = "assets", description = "Asset management endpoints"),
        (name = "portfolios", description = "Portfolio management and trading endpoints"),
        (name = "risk", description = "Risk analysis endpoints")
    ),
    info(
        title = "Portfolio API",
        version = "1.0.0",
        description = "API for managing portfolio users, assets, funds, and trading"
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
        .route("/users/{userId}/complete", get(handlers::get_user_extended))
        .route("/users/{userId}", put(handlers::update_user))
        .route("/users/{userId}", delete(handlers::delete_user))
        .route("/users/{userId}/payment-method", put(handlers::set_payment_method))
        .route("/users/{userId}/subscription", post(handlers::manage_subscription))
        // Fund Management Routes
        .route("/users/{userId}/deposit", post(handlers::deposit_funds))
        .route("/users/{userId}/withdraw", post(handlers::withdraw_funds))
        .route("/users/{userId}/allocate", post(handlers::allocate_funds))
        .route("/users/{userId}/deallocate", post(handlers::deallocate_funds))
        .route("/users/{userId}/upgrade-premium", post(handlers::upgrade_to_premium))
        .route("/users/{userId}/account-summary", get(handlers::get_account_summary));

    // Portfolio routes second
    let portfolio_routes = Router::new()
        .route("/portfolios", get(handlers::list_portfolios))
        .route("/portfolios", post(handlers::create_portfolio))
        .route("/portfolios/{portfolioId}", get(handlers::get_portfolio))
        .route("/portfolios/{portfolioId}", put(handlers::update_portfolio))
        .route("/portfolios/{portfolioId}", delete(handlers::delete_portfolio))
        .route("/portfolios/{portfolioId}/summary", get(handlers::get_portfolio_summary))
        .route("/portfolios/{portfolioId}/holdings", get(handlers::get_portfolio_holdings))
        // Trading Routes
        .route("/portfolios/buy", post(handlers::buy_asset))
        .route("/portfolios/sell", post(handlers::sell_asset))
        .route("/portfolios/{portfolioId}/balance", get(handlers::get_portfolio_balance))
        .route("/portfolios/{portfolioId}/holdings-summary", get(handlers::get_portfolio_holdings_summary));

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

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
        // Enhanced Asset Management Endpoints
        handlers::list_assets,
        handlers::create_asset,
        handlers::get_asset,
        handlers::update_asset,
        handlers::update_asset_price,
        handlers::get_complete_asset,
        handlers::get_asset_price_history,
        handlers::import_csv_prices,
        handlers::list_companies,
        handlers::list_indices,
        // User Management Endpoints
        handlers::list_users,
        handlers::create_user,
        handlers::get_user,
        handlers::get_user_extended,
        handlers::update_user,
        handlers::delete_user,
        handlers::login,
        handlers::logout,
        // Portfolio Management Endpoints
        handlers::list_portfolios,
        handlers::create_portfolio,
        handlers::get_portfolio,
        handlers::update_portfolio,
        handlers::delete_portfolio,
        handlers::get_portfolio_summary,
        handlers::get_portfolio_holdings,
        // Risk Analysis Endpoints
        handlers::get_user_risk_metrics,
        handlers::get_portfolio_risk_analysis,
        handlers::get_risk_summary,
        handlers::get_portfolio_risk_summary,
        handlers::get_user_risk_summary,
        handlers::get_user_latest_risk_metrics,
        handlers::calculate_user_risk_metrics,
        handlers::get_user_risk_trend,
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
        // Payment & Subscription Endpoints
        handlers::set_payment_method,
        handlers::manage_subscription,
        handlers::get_enhanced_asset_details,
        handlers::get_enhanced_account_summary,
        handlers::get_fund_transaction_history,
        handlers::get_portfolio_balance_sp,
        handlers::get_portfolio_holdings_summary_sp
    ),
    components(
        schemas(
            // Enhanced Asset Management Models
            models::Asset,
            models::CreateAssetRequest,
            models::UpdateAssetRequest,
            models::AssetPriceHistory,
            models::CompleteAsset,
            models::UpdatePriceRequest,
            models::UpdatePriceResponse,
            // Stock-Specific Models
            models::StockDetails,
            models::CreateStockRequest,
            models::UpdateStockDetailsRequest,
            // Cryptocurrency Models
            models::CryptoDetails,
            models::CreateCryptoRequest,
            models::UpdateCryptoDetailsRequest,
            // Index Models
            models::IndexDetails,
            models::CreateIndexRequest,
            models::UpdateIndexDetailsRequest,
            // Commodity Models
            models::CommodityDetails,
            models::CreateCommodityRequest,
            models::UpdateCommodityDetailsRequest,
            // Asset Utils
            models::AssetType,
            // CSV Import Models
            models::CsvImportRequest,
            models::CsvImportResult,
            // User Management Models
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
            // Portfolio Management Models
            models::Portfolio,
            models::CreatePortfolioRequest,
            models::UpdatePortfolioRequest,
            models::PortfolioSummary,
            models::AssetHolding,
            // Risk Analysis Models
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
        (name = "assets", description = "Comprehensive asset management, price data import, and market data endpoints"),
        (name = "users", description = "User management, authentication, and fund management endpoints"),
        (name = "portfolios", description = "Portfolio management and trading endpoints"),
        (name = "risk", description = "Risk analysis and portfolio analytics endpoints")
    ),
    info(
        title = "Portfolio Management API v2.0",
        version = "2.0.0",
        description = "Comprehensive API for managing portfolios with enhanced asset management, CSV data import, real-time price tracking, and comprehensive trading functionality"
    )
)]
struct ApiDoc;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    dotenvy::dotenv().ok();
    
    // Check command line arguments for test mode
    let args: Vec<String> = std::env::args().collect();
    if args.len() > 1 && args[1] == "--test-db" {
        println!("Running database connectivity test...\n");
        return db::test_database_connectivity().await;
    }
    
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
    
    // Enhanced Asset Management Routes
    let asset_routes = Router::new()
        // Core Asset CRUD Operations
        .route("/assets", get(handlers::list_assets))
        .route("/assets", post(handlers::create_asset))
        .route("/assets/{asset_id}", get(handlers::get_asset))
        .route("/assets/{asset_id}", put(handlers::update_asset))
        .route("/assets/{asset_id}/complete", get(handlers::get_complete_asset))
        .route("/assets/{asset_id}/enhanced", get(handlers::get_enhanced_asset_details))
        .route("/assets/{asset_id}", delete(handlers::delete_asset))
        // Price Management
        .route("/assets/{asset_id}/price", post(handlers::update_asset_price))
        .route("/assets/{asset_id}/price-history", get(handlers::get_asset_price_history))
        // CSV Data Import
        .route("/assets/import/csv", post(handlers::import_csv_prices))
        // Asset Type Filters
        .route("/assets/companies", get(handlers::list_companies))
        .route("/assets/indices", get(handlers::list_indices));

    // User Management Routes
    let user_routes = Router::new()
        // Core User Operations
        .route("/users", get(handlers::list_users))
        .route("/users", post(handlers::create_user))
        .route("/users/login", post(handlers::login))
        .route("/users/logout", post(handlers::logout))
        .route("/users/{userId}", get(handlers::get_user))
        .route("/users/{userId}/complete", get(handlers::get_user_extended))
        .route("/users/{userId}", put(handlers::update_user))
        .route("/users/{userId}", delete(handlers::delete_user))
        // Payment & Subscription Management
        .route("/users/{userId}/payment-method", put(handlers::set_payment_method))
        .route("/users/{userId}/subscription", post(handlers::manage_subscription))
        // Fund Management Operations
        .route("/users/{userId}/deposit", post(handlers::deposit_funds))
        .route("/users/{userId}/withdraw", post(handlers::withdraw_funds))
        .route("/users/{userId}/allocate", post(handlers::allocate_funds))
        .route("/users/{userId}/deallocate", post(handlers::deallocate_funds))
        .route("/users/{userId}/upgrade-premium", post(handlers::upgrade_to_premium))
        .route("/users/{userId}/account-summary", get(handlers::get_account_summary))
        .route("/users/{userId}/account-summary-enhanced", get(handlers::get_enhanced_account_summary))
        .route("/users/{userId}/fund-transactions", get(handlers::get_fund_transaction_history));

    // Portfolio Management Routes
    let portfolio_routes = Router::new()
        // Core Portfolio Operations
        .route("/portfolios", get(handlers::list_portfolios))
        .route("/portfolios", post(handlers::create_portfolio))
        .route("/portfolios/{portfolio_id}", get(handlers::get_portfolio))
        .route("/portfolios/{portfolio_id}", put(handlers::update_portfolio))
        .route("/portfolios/{portfolio_id}", delete(handlers::delete_portfolio))
        .route("/portfolios/{portfolio_id}/summary", get(handlers::get_portfolio_summary))
        .route("/portfolios/{portfolio_id}/holdings", get(handlers::get_portfolio_holdings))
        // Trading Operations
        .route("/portfolios/buy", post(handlers::buy_asset))
        .route("/portfolios/sell", post(handlers::sell_asset))
        .route("/portfolios/{portfolio_id}/balance", get(handlers::get_portfolio_balance))
        .route("/portfolios/{portfolio_id}/balance-sp", get(handlers::get_portfolio_balance_sp))
        .route("/portfolios/{portfolio_id}/holdings-summary", get(handlers::get_portfolio_holdings_summary))
        .route("/portfolios/{portfolio_id}/holdings-summary-sp", get(handlers::get_portfolio_holdings_summary_sp));

    // Risk Analysis Routes
    let risk_routes = Router::new()
        .route("/risk/metrics/user/{userId}", get(handlers::get_user_risk_metrics))
        .route("/risk/metrics/portfolio/{portfolio_id}", get(handlers::get_portfolio_risk_analysis))
        .route("/risk/summary", get(handlers::get_risk_summary))
        .route("/risk/summary/portfolio/{portfolio_id}", get(handlers::get_portfolio_risk_summary))
        .route("/risk/summary/user/{userId}", get(handlers::get_user_risk_summary))
        .route("/risk/latest/{userId}", get(handlers::get_user_latest_risk_metrics))
        .route("/risk/calculate/{userId}", post(handlers::calculate_user_risk_metrics))
        .route("/risk/trend/{userId}", get(handlers::get_user_risk_trend));

    // Combine all API routes under v1
    let api_v1 = Router::new()
        .merge(asset_routes)
        .merge(user_routes)
        .merge(portfolio_routes)
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
    println!("=== Database Connection Details ===");
    println!("Host: {}", std::env::var("DB_HOST").unwrap_or_else(|_| "localhost".to_string()));
    println!("Port: {}", std::env::var("DB_PORT").unwrap_or_else(|_| "1433".to_string()));
    println!("User: {}", std::env::var("DB_USER").unwrap_or_else(|_| "sa".to_string()));
    println!("Database: {}", std::env::var("DB_NAME").unwrap_or_else(|_| "portfolio".to_string()));
    println!("===================================");
    axum::serve(listener, app).await?;
    
    Ok(())
}

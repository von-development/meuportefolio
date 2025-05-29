# Portfolio Management System API Documentation

## Table of Contents
- [Overview](#overview)
- [Base URL](#base-url)
- [Authentication](#authentication)
- [Data Structures](#data-structures)
- [API Endpoints Summary](#api-endpoints-summary)
- [Detailed API Endpoints](#detailed-api-endpoints)

## Overview
This document provides detailed information about the Portfolio Management System API endpoints, data structures, and request/response formats.

## Base URL
```typescript
const API_BASE = 'http://localhost:8080/api/v1';
```

## Authentication
Authentication is handled via session cookies. Login and logout endpoints manage the authentication state.

## Data Structures

### User
```typescript
interface User {
    user_id: string;  // UUID
    name: string;  // Example: "John Doe"
    email: string;  // Example: "john.doe@example.com"
    country_of_residence: string;  // Example: "United States"
    iban: string;  // Example: "US123456789"
    user_type: string;  // Example: "regular"
    created_at: string;  // Example: "2024-03-20T10:00:00Z"
    updated_at: string;  // Example: "2024-03-20T10:00:00Z"
}
```

### Portfolio
```typescript
interface Portfolio {
    portfolio_id: number;  // Example: 1
    user_id: string;  // UUID
    name: string;  // Example: "Tech Growth Portfolio"
    creation_date: string;  // Example: "2024-03-20T10:00:00"
    current_funds: number;  // Example: 10000.50, minimum: 0
    current_profit_pct: number;  // Example: 15.5
    last_updated: string;  // Example: "2024-03-20T10:00:00"
}
```

### Asset
```typescript
interface Asset {
    asset_id: number;  // Example: 1
    name: string;  // Example: "Apple Inc"
    symbol: string;  // Example: "AAPL"
    asset_type: string;  // Example: "Company"
    price: number;  // Example: 175.50
    volume: number;  // Example: 1000000
    available_shares: number;  // Example: 16500000000
    last_updated: string;  // Example: "2024-03-20T10:00:00"
}
```

### Risk Analysis
```typescript
interface RiskAnalysis {
    user_id: string;  // UUID, Example: "123e4567-e89b-12d3-a456-426614174000"
    user_name: string;  // Example: "John Doe"
    user_type: string;  // Example: "Premium"
    total_portfolios: number;  // Example: 3
    total_investment: number;  // Example: 150000.50
    maximum_drawdown: number | null;  // Example: -15.5
    sharpe_ratio: number | null;  // Example: 0.8
    risk_level: string;  // Example: "Moderate"
    last_updated: string;  // Example: "2024-03-20T10:00:00"
}
```

### Portfolio Risk Analysis
```typescript
interface PortfolioRiskAnalysis {
    portfolio_id: number;  // Example: 1
    portfolio_name: string;  // Example: "Tech Growth Portfolio"
    current_funds: number;  // Example: 150000.50
    current_profit_pct: number;  // Example: 25.5
    maximum_drawdown: number | null;  // Example: -15.5
    beta: number | null;  // Example: 1.2
    sharpe_ratio: number | null;  // Example: 0.8
    risk_level: string;  // Example: "Moderate"
}
```

### Risk Summary
```typescript
interface RiskSummary {
    total_users: number;  // Example: 3
    total_portfolios: number;  // Example: 10
    total_assets_under_management: number;  // Example: 1500000.50
    average_system_risk: number;  // Example: 0.75
    calculated_at: string;  // Example: "2024-03-20T10:00:00"
}
```

### Portfolio Summary
```typescript
interface PortfolioSummary {
    portfolio_id: number;  // Example: 1
    portfolio_name: string;  // Example: "Tech Growth Portfolio"
    owner: string;  // Example: "John Doe"
    current_funds: number;  // Example: 10000.50, minimum: 0
    current_profit_pct: number;  // Example: 15.5
    creation_date: string;  // Example: "2024-03-20T10:00:00"
    total_trades: number;  // Example: 42
}
```

### Asset Holding
```typescript
interface AssetHolding {
    portfolio_id: number;  // Example: 1
    portfolio_name: string;  // Example: "Tech Growth Portfolio"
    asset_id: number;  // Example: 1
    asset_name: string;  // Example: "Apple Inc"
    symbol: string;  // Example: "AAPL"
    asset_type: string;  // Example: "Company"
    quantity_held: number;  // Example: 100, minimum: 0
    current_price: number;  // Example: 175.50, minimum: 0
    market_value: number;  // Example: 17550.00, minimum: 0
}
```

## API Endpoints Summary

Total Endpoints: 24

1. Health Check Endpoints (2)
2. User Management Endpoints (7)
3. Asset Management Endpoints (5)
4. Portfolio Management Endpoints (7)
5. Risk Analysis Endpoints (5)

## Detailed API Endpoints

### 1. Health Check Endpoints
```typescript
// 1.1 Basic Health Check
GET /health
Description: Check if the API is running
Response: { status: "ok" }

// 1.2 Database Health Check
GET /db-health
Description: Check if the database connection is working
Response: { status: "ok", message: string }
```

### 2. User Management Endpoints
```typescript
// 2.1 List Users
GET /api/v1/users
Description: List all users
Response: User[]

// 2.2 Create User
POST /api/v1/users
Description: Create a new user
Request: CreateUserRequest
Response: User

// 2.3 Get User
GET /api/v1/users/{userId}
Description: Get a specific user by ID
Response: User

// 2.4 Update User
PUT /api/v1/users/{userId}
Description: Update a user
Request: UpdateUserRequest
Response: User

// 2.5 Delete User
DELETE /api/v1/users/{userId}
Description: Delete a user
Response: 204 No Content

// 2.6 User Login
POST /api/v1/users/login
Description: User login
Request: LoginRequest
Response: LoginResponse

// 2.7 User Logout
POST /api/v1/users/logout
Description: User logout
Response: 204 No Content
```

### 3. Asset Management Endpoints
```typescript
// 3.1 List Assets
GET /api/v1/assets
Description: List all assets with optional filtering
Query Parameters: query?: string, asset_type?: string
Response: Asset[]

// 3.2 Get Asset
GET /api/v1/assets/{assetId}
Description: Get asset details by ID
Response: Asset

// 3.3 Get Asset Price History
GET /api/v1/assets/{assetId}/price-history
Description: Get asset price history
Response: AssetPriceHistory[]

// 3.4 List Companies
GET /api/v1/assets/companies
Description: List company assets
Response: Asset[]

// 3.5 List Indices
GET /api/v1/assets/indices
Description: List index assets
Response: Asset[]
```

### 4. Portfolio Management Endpoints
```typescript
// 4.1 List Portfolios
GET /api/v1/portfolios
Description: List all portfolios for a user
Query Parameters: user_id: string
Response: Portfolio[]

// 4.2 Create Portfolio
POST /api/v1/portfolios
Description: Create a new portfolio
Request: CreatePortfolioRequest
Response: Portfolio

// 4.3 Get Portfolio
GET /api/v1/portfolios/{portfolioId}
Description: Get portfolio details
Response: Portfolio

// 4.4 Update Portfolio
PUT /api/v1/portfolios/{portfolioId}
Description: Update portfolio
Request: UpdatePortfolioRequest
Response: Portfolio

// 4.5 Delete Portfolio
DELETE /api/v1/portfolios/{portfolioId}
Description: Delete portfolio
Response: 204 No Content

// 4.6 Get Portfolio Holdings
GET /api/v1/portfolios/{portfolioId}/holdings
Description: Get portfolio holdings
Response: AssetHolding[]

// 4.7 Get Portfolio Summary
GET /api/v1/portfolios/{portfolioId}/summary
Description: Get portfolio summary
Response: PortfolioSummary
```

### 5. Risk Analysis Endpoints
```typescript
// 5.1 Get User Risk Metrics
GET /api/v1/risk/metrics/user/{userId}
Description: Get user risk metrics
Response: RiskAnalysis

// 5.2 Get Portfolio Risk Analysis
GET /api/v1/risk/metrics/portfolio/{portfolioId}
Description: Get portfolio risk analysis
Response: PortfolioRiskAnalysis

// 5.3 Get Risk Summary
GET /api/v1/risk/summary
Description: Get overall risk summary
Response: RiskSummary

// 5.4 Get Portfolio Risk Summary
GET /api/v1/risk/summary/portfolio/{portfolioId}
Description: Get portfolio-specific risk summary
Response: RiskSummary

// 5.5 Get User Risk Summary
GET /api/v1/risk/summary/user/{userId}
Description: Get user-specific risk summary
Response: RiskSummary
```

## Error Handling

All endpoints may return the following error responses:

```typescript
interface ErrorResponse {
    status: number;
    message: string;
}
```

Common error status codes:
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 500: Internal Server Error

## Response Headers

All successful responses include:
```
Content-Type: application/json
```

Authentication-related endpoints also manage:
```
Set-Cookie: session=<token>
``` 
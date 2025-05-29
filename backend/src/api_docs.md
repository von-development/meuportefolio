# Backend API Structure

## API Endpoints

### Health Endpoints
```
GET /health      - Basic service health check
GET /db-health   - Database connection health check
```

### User Management
```
POST   /api/v1/users              - Register new user
GET    /api/v1/users/:id          - Get user details
PUT    /api/v1/users/:id          - Update user information
DELETE /api/v1/users/:id          - Delete user account
POST   /api/v1/users/login        - User login
POST   /api/v1/users/logout       - User logout
```

### Portfolio Management
```
POST   /api/v1/portfolios                    - Create new portfolio
GET    /api/v1/portfolios                    - List user's portfolios
GET    /api/v1/portfolios/:id                - Get portfolio details
PUT    /api/v1/portfolios/:id                - Update portfolio information
DELETE /api/v1/portfolios/:id                - Delete portfolio
GET    /api/v1/portfolios/:id/summary        - Get portfolio summary (uses vw_PortfolioSummary)
GET    /api/v1/portfolios/:id/holdings       - Get portfolio holdings (uses vw_AssetHoldings)
GET    /api/v1/portfolios/:id/performance    - Get portfolio performance metrics
```

### Asset Operations
```
GET    /api/v1/assets                        - List all available assets
GET    /api/v1/assets/{id}                    - Get asset details
GET    /api/v1/assets/{id}/price-history      - Get asset price history (uses vw_AssetPriceHistory)
GET    /api/v1/assets/companies              - List company assets with details
GET    /api/v1/assets/indices                - List index assets with details
GET    /api/v1/assets/search                 - Search assets by symbol or name
```

### Transaction Management
```
POST   /api/v1/transactions                  - Execute new transaction
GET    /api/v1/transactions/{id}              - Get transaction details
GET    /api/v1/transactions/portfolio/{id}    - List portfolio transactions
GET    /api/v1/transactions/user/{id}         - List user transactions
```

### Risk Analysis
```
GET    /api/v1/risk/metrics/{userId}          - Get user risk metrics (uses vw_RiskAnalysis)
GET    /api/v1/risk/portfolio/{id}            - Get portfolio risk analysis
GET    /api/v1/risk/summary                  - Get overall risk summary
```

### Subscription Management
```
POST   /api/v1/subscriptions                 - Create new subscription
GET    /api/v1/subscriptions/:userId         - Get user subscription details
PUT    /api/v1/subscriptions/{id}             - Update subscription
DELETE /api/v1/subscriptions/{id}             - Cancel subscription
```

### Payment Methods
```
POST   /api/v1/payment-methods               - Add new payment method
GET    /api/v1/payment-methods/user/{id}      - List user payment methods
PUT    /api/v1/payment-methods/{id}           - Update payment method
DELETE /api/v1/payment-methods/{id}           - Remove payment method
```

## Data Structures

### User
```typescript
interface User {
    userId: string;              // UNIQUEIDENTIFIER
    name: string;                // NVARCHAR(100)
    email: string;               // NVARCHAR(100)
    countryOfResidence: string;  // NVARCHAR(100)
    iban: string;                // NVARCHAR(34)
    userType: 'Basic' | 'Premium';
    createdAt: Date;
    updatedAt: Date;
}
```

### Portfolio
```typescript
interface Portfolio {
    portfolioId: number;
    userId: string;
    name: string;
    creationDate: Date;
    currentFunds: number;
    currentProfitPct: number;
    lastUpdated: Date;
}
```

### Asset
```typescript
interface Asset {
    assetId: number;
    name: string;
    symbol: string;
    assetType: 'Company' | 'Index' | 'Cryptocurrency' | 'Commodity';
    price: number;
    volume: number;
    availableShares: number;
    lastUpdated: Date;
}
```

### Transaction
```typescript
interface Transaction {
    transactionId: number;
    userId: string;
    portfolioId: number;
    assetId: number;
    transactionType: 'Buy' | 'Sell';
    quantity: number;
    unitPrice: number;
    transactionDate: Date;
    status: string;
}
```

### RiskMetrics
```typescript
interface RiskMetrics {
    metricId: number;
    userId: string;
    maximumDrawdown: number;
    beta: number;
    sharpeRatio: number;
    absoluteReturn: number;
    volatilityScore: number;
    riskLevel: string;
    capturedAt: Date;
}
```

## Important Notes

1. **Authentication**
   - All endpoints except `/health`, `/db-health`, and authentication endpoints require a valid JWT token
   - Token should be sent in Authorization header: `Authorization: Bearer <token>`

2. **Database Views**
   - Several endpoints utilize optimized database views for better performance
   - View-based endpoints are noted in the endpoint descriptions

3. **Rate Limiting**
   - Basic users: 100 requests/minute
   - Premium users: 300 requests/minute

4. **Error Handling**
   - All endpoints return standard error format:
   ```json
   {
     "error": {
       "code": "ERROR_CODE",
       "message": "Human readable message",
       "details": {}
     }
   }
   ```

5. **Pagination**
   - List endpoints support pagination via query parameters:
     - `page`: Page number (default: 1)
     - `limit`: Items per page (default: 20, max: 100)

6. **Filtering and Sorting**
   - List endpoints support filtering via query parameters
   - Sort using `sort` parameter (e.g., `sort=createdAt:desc`)

7. **Database Procedures**
   - Use stored procedures for complex operations:
     - `sp_CreateUser` for user registration
     - `sp_ExecuteTransaction` for transaction processing
     - `sp_UpdateAssetPrice` for price updates
     - `sp_import_asset_price` for historical data import

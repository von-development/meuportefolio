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
POST   /api/v1/portfolios         - Create new portfolio
GET    /api/v1/portfolios         - List user's portfolios
GET    /api/v1/portfolios/:id     - Get portfolio details
PUT    /api/v1/portfolios/:id     - Update portfolio
DELETE /api/v1/portfolios/:id     - Delete portfolio
GET    /api/v1/portfolios/:id/performance - Get portfolio performance metrics
```

### Asset Management
```
GET    /api/v1/assets             - List all assets
GET    /api/v1/assets/:id         - Get asset details
GET    /api/v1/assets/types/:type - List assets by type
GET    /api/v1/assets/:id/price   - Get asset current price
GET    /api/v1/assets/:id/history - Get asset price history
```

### Transaction Management
```
POST   /api/v1/transactions           - Create new transaction
GET    /api/v1/transactions/:id       - Get transaction details
GET    /api/v1/transactions           - List transactions (with filters)
GET    /api/v1/portfolios/:id/transactions - Get portfolio transactions
```

### Risk Metrics
```
GET    /api/v1/portfolios/:id/metrics/risk     - Get risk metrics
GET    /api/v1/portfolios/:id/metrics/returns  - Get return metrics
```

## API Response Format

All API responses will follow a consistent format:

```json
{
    "success": boolean,
    "data": object | array | null,
    "error": {
        "code": string,
        "message": string
    } | null
}
```

## Authentication

- JWT-based authentication
- Tokens provided in Authorization header
- Refresh token mechanism for extended sessions

## Error Handling

Standard HTTP status codes will be used:
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 500: Internal Server Error

## Rate Limiting

- Basic users: 100 requests/minute
- Premium users: 300 requests/minute

## Implementation Priority

1. User Authentication & Authorization
2. Asset Management
3. Portfolio Management
4. Transaction Processing
5. Risk Metrics
6. Advanced Features (Price History, Performance Analytics)

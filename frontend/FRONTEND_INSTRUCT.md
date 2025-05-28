# Portfolio API Documentation & Frontend Implementation Guide

## Table of Contents
1. [API Endpoints Overview](#api-endpoints-overview)
2. [Data Structures](#data-structures)
3. [Screen Designs](#screen-designs)
4. [Implementation Guide](#implementation-guide)
5. [Docker Setup](#docker-setup)

## API Endpoints Overview

### Health Check Endpoints
- `GET /health` - Basic API health check
- `GET /db-health` - Database connectivity check

### Asset Management
- `GET /api/v1/assets` - List all assets with filtering
- `GET /api/v1/assets/{id}` - Get asset details
- `GET /api/v1/assets/{id}/price-history` - Get asset price history
- `GET /api/v1/assets/companies` - List company assets
- `GET /api/v1/assets/indices` - List index assets

### User Management
- `GET /api/v1/users` - List users
- `POST /api/v1/users` - Create user
- `GET /api/v1/users/{id}` - Get user details
- `PUT /api/v1/users/{id}` - Update user
- `DELETE /api/v1/users/{id}` - Delete user
- `POST /api/v1/users/login` - User login
- `POST /api/v1/users/logout` - User logout

### Portfolio Management
- `GET /api/v1/portfolios` - List portfolios
- `POST /api/v1/portfolios` - Create portfolio
- `GET /api/v1/portfolios/{id}` - Get portfolio details
- `PUT /api/v1/portfolios/{id}` - Update portfolio
- `DELETE /api/v1/portfolios/{id}` - Delete portfolio
- `GET /api/v1/portfolios/{id}/summary` - Get portfolio summary
- `GET /api/v1/portfolios/{id}/holdings` - Get portfolio holdings

## Data Structures

### Asset Types
```typescript
interface Asset {
    asset_id: number;
    name: string;
    symbol: string;
    asset_type: string;
    price: number;
    volume: number;
    available_shares: number;
    last_updated: string;
}

interface AssetPriceHistory {
    asset_id: number;
    symbol: string;
    price: number;
    volume: number;
    timestamp: string;
}
```

### User Types
```typescript
interface User {
    user_id: string;
    name: string;
    email: string;
    country_of_residence: string;
    iban: string;
    user_type: 'Basic' | 'Premium';
    created_at: string;
    updated_at: string;
}

interface LoginRequest {
    email: string;
    password: string;
}

interface LoginResponse {
    token: string;
    user: User;
}
```

### Portfolio Types
```typescript
interface Portfolio {
    portfolio_id: number;
    name: string;
    creation_date: string;
    current_funds: number;
    current_profit_pct: number;
    last_updated: string;
}

interface PortfolioSummary {
    portfolio_id: number;
    total_value: number;
    total_profit: number;
    profit_percentage: number;
    number_of_assets: number;
    last_updated: string;
}

interface AssetHolding {
    asset_id: number;
    symbol: string;
    quantity: number;
    average_price: number;
    current_price: number;
    total_value: number;
    profit_loss: number;
}
```

## Screen Designs

### Assets List Screen
```
+----------------------------------+
|   Assets                    🔍   |
+----------------------------------+
| Filter: [All ▼] Search: [     ] |
+----------------------------------+
| Symbol  | Name   | Price | Type  |
|---------|--------|-------|-------|
| AAPL    | Apple  | 150.5 | Stock |
| ^GSPC   | S&P500 | 4500  | Index |
+----------------------------------+
```

### Asset Details Screen
```
+----------------------------------+
|   Asset Details                  |
+----------------------------------+
| Symbol: AAPL                     |
| Name: Apple Inc.                 |
| Current Price: $150.50           |
| Volume: 1.2M                     |
| Available Shares: 16.5B          |
| Last Updated: 2024-03-21 14:30   |
+----------------------------------+
|   Price History                  |
|                      📈          |
|            [Chart Area]          |
+----------------------------------+
```

### User Management Screen
```
+----------------------------------+
|   Users                     ➕   |
+----------------------------------+
| Name    | Type    | Country     |
|---------|---------|-------------|
| John D. | Premium | USA         |
| Maria G.| Basic   | Spain       |
+----------------------------------+
```

### Portfolio Dashboard
```
+----------------------------------+
|   My Portfolios             ➕   |
+----------------------------------+
| Name     | Value  | Profit      |
|----------|--------|-------------|
| Tech     | $50K   | +15.2%     |
| Dividend | $30K   | +5.8%      |
+----------------------------------+
```

### Portfolio Details Screen
```
+----------------------------------+
|   Portfolio: Tech Stocks         |
+----------------------------------+
| Total Value: $50,000             |
| Profit/Loss: +15.2%             |
| Holdings: 12 assets             |
+----------------------------------+
| Symbol | Qty | Value  | P/L     |
|--------|-----|--------|---------|
| AAPL   | 50  | $7.5K  | +12.3% |
| MSFT   | 30  | $9.0K  | +8.7%  |
+----------------------------------+
```

## Implementation Guide

### Project Structure
```
src/
├── components/
│   ├── Assets/
│   │   ├── AssetList.tsx
│   │   ├── AssetDetail.tsx
│   │   └── PriceHistory.tsx
│   ├── Users/
│   │   ├── UserList.tsx
│   │   ├── UserForm.tsx
│   │   └── Login.tsx
│   └── Portfolios/
│       ├── PortfolioList.tsx
│       ├── PortfolioDetail.tsx
│       └── Holdings.tsx
├── services/
│   ├── api.ts
│   └── auth.ts
└── App.tsx
```

### API Service Example
```typescript
// services/api.ts
const API_BASE = 'http://localhost:8080/api/v1';

export const api = {
    // Assets
    getAssets: () => fetch(`${API_BASE}/assets`).then(res => res.json()),
    getAssetDetails: (id: number) => fetch(`${API_BASE}/assets/${id}`).then(res => res.json()),
    getAssetPriceHistory: (id: number) => fetch(`${API_BASE}/assets/${id}/price-history`).then(res => res.json()),

    // Users
    login: (credentials: LoginRequest) => fetch(`${API_BASE}/users/login`, {
        method: 'POST',
        body: JSON.stringify(credentials),
    }).then(res => res.json()),

    // Portfolios
    getPortfolios: () => fetch(`${API_BASE}/portfolios`).then(res => res.json()),
    createPortfolio: (data: any) => fetch(`${API_BASE}/portfolios`, {
        method: 'POST',
        body: JSON.stringify(data),
    }).then(res => res.json()),
};
```

### Component Example
```typescript
// components/Assets/AssetList.tsx
import React, { useEffect, useState } from 'react';
import { api } from '../../services/api';

export const AssetList = () => {
    const [assets, setAssets] = useState<Asset[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        api.getAssets()
            .then(setAssets)
            .finally(() => setLoading(false));
    }, []);

    return (
        <div className="asset-list">
            <h1>Assets</h1>
            {loading ? (
                <p>Loading...</p>
            ) : (
                <table>
                    <thead>
                        <tr>
                            <th>Symbol</th>
                            <th>Name</th>
                            <th>Price</th>
                            <th>Type</th>
                        </tr>
                    </thead>
                    <tbody>
                        {assets.map(asset => (
                            <tr key={asset.asset_id}>
                                <td>{asset.symbol}</td>
                                <td>{asset.name}</td>
                                <td>${asset.price}</td>
                                <td>{asset.asset_type}</td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}
        </div>
    );
};
```

### Styling Recommendation
Use a modern CSS framework like Tailwind CSS or Material-UI for consistent styling and responsive design. Example Tailwind classes for the asset list:

```tsx
<div className="container mx-auto p-4">
    <h1 className="text-2xl font-bold mb-4">Assets</h1>
    <table className="min-w-full bg-white shadow-md rounded">
        <thead className="bg-gray-100">
            <tr>
                <th className="px-4 py-2">Symbol</th>
                <th className="px-4 py-2">Name</th>
                <th className="px-4 py-2">Price</th>
                <th className="px-4 py-2">Type</th>
            </tr>
        </thead>
        <tbody>
            {/* ... rows ... */}
        </tbody>
    </table>
</div>
```

### Getting Started
1. Create a new React project:
   ```bash
   npx create-react-app portfolio-frontend --template typescript
   ```

2. Install dependencies:
   ```bash
   npm install @tanstack/react-query axios tailwindcss @headlessui/react
   ```

3. Set up Tailwind CSS:
   ```bash
   npx tailwindcss init
   ```

4. Start implementing components following the structure above.

5. Test API endpoints using the provided service layer.

Remember to handle:
- Authentication state
- Loading states
- Error boundaries
- Responsive design
- Form validation
- Real-time updates where needed

## Docker Setup

The application uses Docker Compose to run both the backend API and the SQL Server database. Here's the infrastructure setup:

### Services

#### Database (SQL Server)
```yaml
db:
  image: mcr.microsoft.com/mssql/server:2022-latest
  environment:
    ACCEPT_EULA: "Y"
    SA_PASSWORD: "meuportefolio!23"
  volumes:
    - sqlportfolio_data:/var/opt/mssql
  ports:
    - "1433:1433"
```
- Uses SQL Server 2022
- Exposed on port 1433
- Persistent data storage using Docker volume
- Default SA password: meuportefolio!23

#### Backend API
```yaml
api:
  build:
    context: ./backend
    dockerfile: ./Dockerfile
  environment:
    DATABASE_URL: "Server=db,1433;Database=meuportefolio;User Id=sa;Password=meuportefolio!23;TrustServerCertificate=true"
  depends_on:
    - db
  ports:
    - "8080:8080"
```
- Custom built from local Dockerfile
- Depends on database service
- Exposed on port 8080
- Automatically connects to SQL Server

### Getting Started with Docker

1. Start the services:
   ```bash
   docker-compose up -d
   ```

2. Check service status:
   ```bash
   docker-compose ps
   ```

3. View logs:
   ```bash
   docker-compose logs -f
   ```

4. Stop services:
   ```bash
   docker-compose down
   ```

### Development Workflow

When developing the frontend:

1. Ensure Docker services are running:
   ```bash
   docker-compose up -d
   ```

2. The API will be available at `http://localhost:8080`

3. Configure your frontend API service to use this base URL:
   ```typescript
   // services/api.ts
   const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8080/api/v1';
   ```

4. For local development, create a `.env` file in your frontend project:
   ```env
   REACT_APP_API_URL=http://localhost:8080/api/v1
   ```

### Database Connection Details

- **Server**: localhost,1433
- **Database**: meuportefolio
- **User**: sa
- **Password**: meuportefolio!23
- **Trust Server Certificate**: true

### Volume Management

The database uses a named volume `sqlportfolio_data` for persistence. To manage data:

- Backup volume:
  ```bash
  docker volume backup sqlportfolio_data
  ```

- Reset data:
  ```bash
  docker-compose down -v
  docker-compose up -d
  ```

### Troubleshooting

1. If the API can't connect to the database:
   - Ensure the database container is running
   - Check the database logs: `docker-compose logs db`
   - Verify the connection string in the API environment

2. If the frontend can't connect to the API:
   - Verify the API is running: `curl http://localhost:8080/health`
   - Check CORS settings in the API
   - Verify the API_BASE URL in your frontend configuration

3. For database connection issues:
   - Wait a few seconds after starting containers (SQL Server needs time to initialize)
   - Verify the SA password matches in both services
   - Check if port 1433 is available on your host machine
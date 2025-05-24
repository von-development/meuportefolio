# Migrations Folder - meuPortfolio

This folder contains migration scripts for the meuPortfolio database. Migrations are used to create, update, or version the database schema in a reproducible and organized way.

## Main Migration Script

### `002_full_schema_flat.sql`
- **Purpose:**
  - This is a single, flat SQL script that creates the entire database schema, including all tables, indexes, functions, triggers, views, and stored procedures.
  - It is designed for direct execution in SQL Server Management Studio (SSMS) or via `sqlcmd`.
- **How to use:**
  1. Open the script in SSMS.
  2. Connect to your SQL Server instance.
  3. Execute the script (F5).
  4. The full schema will be created in the correct order.

## Objects Created

### **Tables**
- `Users` — User accounts (Basic/Premium)
- `Portfolios` — Investment portfolios per user
- `Assets` — All tradable assets (Company, Index, Crypto, Commodity)
- `CompanyDetails` — Extra info for company assets
- `IndexDetails` — Extra info for index assets
- `Transactions` — Buy/Sell operations
- `Subscriptions` — Premium subscriptions (one per user)
- `RiskMetrics` — Portfolio risk metrics per user
- `PaymentMethods` — User payment methods

### **Indexes**
- On key columns for `Users`, `Assets`, `Transactions`

### **Functions**
- `fn_CalculatePortfolioValue` — Calculates total value of a portfolio
- `fn_CalculatePortfolioProfit` — Calculates profit % of a portfolio

### **Triggers**
- `TR_Users_UpdateTimestamp` — Updates `UpdatedAt` on user update
- `TR_Assets_UpdateTimestamp` — Updates `LastUpdated` on asset update

### **Views**
- `vw_PortfolioSummary` — Portfolio summary per user
- `vw_AssetHoldings` — Asset holdings per portfolio
- `vw_UserSubscriptions` — User subscription status

### **Stored Procedures**
- `sp_CreateUser` — Add a new user
- `sp_CreatePortfolio` — Add a new portfolio
- `sp_ExecuteTransaction` — Buy/Sell asset and update portfolio
- `sp_UpdateAssetPrice` — Update asset price and change %

## Schema Coverage Checklist
- [x] All core tables from the Chen diagram and project requirements
- [x] All relationships and foreign keys
- [x] All required indexes for performance
- [x] All business logic functions and triggers
- [x] All reporting views
- [x] All main stored procedures
- [x] Data types and constraints match requirements
- [x] Unique constraints and correct references

## Missing or Optional Elements
- No seed/test data included (add in a separate script if needed)
- No advanced error handling or logging procedures
- No historical/audit tables (can be added if required)
- No user roles/permissions setup (handled at the SQL Server level)

## How to Extend
- Add new migration scripts for future changes (e.g., `003_add_new_feature.sql`)
- Keep this folder as the single source of truth for schema evolution

---

**If you need to add seed data, more advanced features, or want to automate migrations, create new scripts in this folder and document them here.** 
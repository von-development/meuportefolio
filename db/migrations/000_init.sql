/* ------------------------------------------------------------
meuPortfolio – Database Initialization  (v2025-05-24)
------------------------------------------------------------ */

USE master;
GO

/* ============================================================
1. Database Recreation
============================================================ */
IF DB_ID(N'meuportefolio') IS NOT NULL
BEGIN
    ALTER DATABASE meuportefolio SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE meuportefolio;
END
GO

CREATE DATABASE meuportefolio;
GO

USE meuportefolio;
GO

/* ============================================================
2. Drop All Objects (if exist)
============================================================ */

-- Drop views
IF OBJECT_ID('portfolio.vw_PortfolioSummary', 'V') IS NOT NULL DROP VIEW portfolio.vw_PortfolioSummary;
IF OBJECT_ID('portfolio.vw_AssetHoldings', 'V') IS NOT NULL DROP VIEW portfolio.vw_AssetHoldings;
IF OBJECT_ID('portfolio.vw_RiskAnalysis', 'V') IS NOT NULL DROP VIEW portfolio.vw_RiskAnalysis;
IF OBJECT_ID('portfolio.vw_AssetPriceHistory', 'V') IS NOT NULL DROP VIEW portfolio.vw_AssetPriceHistory;
GO

-- Drop stored procedures
IF OBJECT_ID('portfolio.sp_CreateUser', 'P') IS NOT NULL DROP PROCEDURE portfolio.sp_CreateUser;
IF OBJECT_ID('portfolio.sp_CreatePortfolio', 'P') IS NOT NULL DROP PROCEDURE portfolio.sp_CreatePortfolio;
IF OBJECT_ID('portfolio.sp_ExecuteTransaction', 'P') IS NOT NULL DROP PROCEDURE portfolio.sp_ExecuteTransaction;
IF OBJECT_ID('portfolio.sp_UpdateAssetPrice', 'P') IS NOT NULL DROP PROCEDURE portfolio.sp_UpdateAssetPrice;
GO

-- Drop functions
IF OBJECT_ID('portfolio.fn_PortfolioMarketValue', 'FN') IS NOT NULL DROP FUNCTION portfolio.fn_PortfolioMarketValue;
IF OBJECT_ID('portfolio.fn_PortfolioProfitPct', 'FN') IS NOT NULL DROP FUNCTION portfolio.fn_PortfolioProfitPct;
GO

-- Drop triggers
IF OBJECT_ID('portfolio.TR_Users_UpdateTimestamp', 'TR') IS NOT NULL DROP TRIGGER portfolio.TR_Users_UpdateTimestamp;
IF OBJECT_ID('portfolio.TR_Assets_UpdateTimestamp', 'TR') IS NOT NULL DROP TRIGGER portfolio.TR_Assets_UpdateTimestamp;
GO

-- Drop tables (in correct dependency order)
IF OBJECT_ID('portfolio.PaymentMethods', 'U') IS NOT NULL DROP TABLE portfolio.PaymentMethods;
IF OBJECT_ID('portfolio.RiskMetrics', 'U') IS NOT NULL DROP TABLE portfolio.RiskMetrics;
IF OBJECT_ID('portfolio.Subscriptions', 'U') IS NOT NULL DROP TABLE portfolio.Subscriptions;
IF OBJECT_ID('portfolio.Transactions', 'U') IS NOT NULL DROP TABLE portfolio.Transactions;
IF OBJECT_ID('portfolio.AssetPrices', 'U') IS NOT NULL DROP TABLE portfolio.AssetPrices;
IF OBJECT_ID('portfolio.CompanyDetails', 'U') IS NOT NULL DROP TABLE portfolio.CompanyDetails;
IF OBJECT_ID('portfolio.IndexDetails', 'U') IS NOT NULL DROP TABLE portfolio.IndexDetails;
IF OBJECT_ID('portfolio.Portfolios', 'U') IS NOT NULL DROP TABLE portfolio.Portfolios;
IF OBJECT_ID('portfolio.Assets', 'U') IS NOT NULL DROP TABLE portfolio.Assets;
IF OBJECT_ID('portfolio.Users', 'U') IS NOT NULL DROP TABLE portfolio.Users;
GO

-- Drop schema
IF SCHEMA_ID('portfolio') IS NOT NULL DROP SCHEMA portfolio;
GO

/* ============================================================
3. Create Schema
============================================================ */
CREATE SCHEMA portfolio;
GO

/* ----------------  END OF SCRIPT ---------------- */ 
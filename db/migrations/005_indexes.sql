/* ------------------------------------------------------------
meuPortfolio – Indexes  (v2025-05-24)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
1. User Indexes
============================================================ */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_Email')
CREATE NONCLUSTERED INDEX IX_Users_Email 
ON portfolio.Users(Email);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_UserType')
CREATE NONCLUSTERED INDEX IX_Users_UserType 
ON portfolio.Users(UserType);

/* ============================================================
2. Asset Indexes
============================================================ */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Assets_Symbol')
CREATE NONCLUSTERED INDEX IX_Assets_Symbol 
ON portfolio.Assets(Symbol);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Assets_AssetType')
CREATE NONCLUSTERED INDEX IX_Assets_AssetType 
ON portfolio.Assets(AssetType);

/* ============================================================
3. Transaction Indexes
============================================================ */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Transactions_PortfolioAsset')
CREATE NONCLUSTERED INDEX IX_Transactions_PortfolioAsset 
ON portfolio.Transactions(PortfolioID, AssetID)
INCLUDE (TransactionType, Quantity, UnitPrice);

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Transactions_Date')
CREATE NONCLUSTERED INDEX IX_Transactions_Date 
ON portfolio.Transactions(TransactionDate)
INCLUDE (TransactionType, Quantity, UnitPrice);

/* ============================================================
4. Asset Price Indexes
============================================================ */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AssetPrices_AssetID_AsOf')
CREATE NONCLUSTERED INDEX IX_AssetPrices_AssetID_AsOf 
ON portfolio.AssetPrices(AssetID, AsOf DESC)
INCLUDE (Price, OpenPrice, HighPrice, LowPrice);

/* ============================================================
5. Portfolio Performance Indexes
============================================================ */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Portfolios_UserID')
CREATE NONCLUSTERED INDEX IX_Portfolios_UserID 
ON portfolio.Portfolios(UserID)
INCLUDE (CurrentFunds, CurrentProfitPct);

/* ============================================================
6. Risk Metrics Indexes
============================================================ */
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_RiskMetrics_UserID_CapturedAt')
CREATE NONCLUSTERED INDEX IX_RiskMetrics_UserID_CapturedAt 
ON portfolio.RiskMetrics(UserID, CapturedAt DESC)
INCLUDE (MaximumDrawdown, SharpeRatio, RiskLevel);

/* ----------------  END OF SCRIPT ---------------- */ 
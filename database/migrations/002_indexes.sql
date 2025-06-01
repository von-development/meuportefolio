/* ============================================================
meuPortfolio – Database Indexes v2.0 (Consolidated)
============================================================ */

USE p6g4;
GO

/* ============================================================
1. USER INDEXES
============================================================ */

CREATE NONCLUSTERED INDEX IX_Users_Email 
ON portfolio.Users(Email);

CREATE NONCLUSTERED INDEX IX_Users_UserType 
ON portfolio.Users(UserType);

/* ============================================================
2. ASSET INDEXES
============================================================ */

CREATE NONCLUSTERED INDEX IX_Assets_Symbol 
ON portfolio.Assets(Symbol);

CREATE NONCLUSTERED INDEX IX_Assets_AssetType 
ON portfolio.Assets(AssetType);

/* ============================================================
3. TRANSACTION INDEXES
============================================================ */

CREATE NONCLUSTERED INDEX IX_Transactions_PortfolioAsset 
ON portfolio.Transactions(PortfolioID, AssetID)
INCLUDE (TransactionType, Quantity, UnitPrice);

CREATE NONCLUSTERED INDEX IX_Transactions_Date 
ON portfolio.Transactions(TransactionDate)
INCLUDE (TransactionType, Quantity, UnitPrice);

/* ============================================================
4. ASSET PRICE INDEXES
============================================================ */

CREATE NONCLUSTERED INDEX IX_AssetPrices_AssetID_AsOf 
ON portfolio.AssetPrices(AssetID, AsOf DESC)
INCLUDE (Price, OpenPrice, HighPrice, LowPrice);

/* ============================================================
5. PORTFOLIO INDEXES
============================================================ */

CREATE NONCLUSTERED INDEX IX_Portfolios_UserID 
ON portfolio.Portfolios(UserID)
INCLUDE (CurrentFunds, CurrentProfitPct);

/* ============================================================
6. RISK METRICS INDEXES
============================================================ */

CREATE NONCLUSTERED INDEX IX_RiskMetrics_UserID_CapturedAt 
ON portfolio.RiskMetrics(UserID, CapturedAt DESC)
INCLUDE (MaximumDrawdown, SharpeRatio, RiskLevel);

/* ============================================================
7. FUND TRANSACTIONS INDEXES
============================================================ */

CREATE NONCLUSTERED INDEX IX_FundTransactions_UserID_Date 
ON portfolio.FundTransactions(UserID, CreatedAt DESC);

CREATE NONCLUSTERED INDEX IX_FundTransactions_TransactionType 
ON portfolio.FundTransactions(TransactionType, CreatedAt DESC);

/* ============================================================
8. PORTFOLIO HOLDINGS INDEXES (CRITICAL for API performance)
============================================================ */

CREATE NONCLUSTERED INDEX IX_PortfolioHoldings_PortfolioID 
ON portfolio.PortfolioHoldings(PortfolioID)
INCLUDE (AssetID, QuantityHeld, AveragePrice, TotalCost);

/* ============================================================
9. USERS ENHANCED FIELD INDEXES (Business Logic)
============================================================ */

CREATE NONCLUSTERED INDEX IX_Users_IsPremium 
ON portfolio.Users(IsPremium, UserType);

/* ============================================================
10. APPLICATION LOGS INDEXES
============================================================ */

CREATE NONCLUSTERED INDEX IX_ApplicationLogs_CreatedAt 
ON portfolio.ApplicationLogs(CreatedAt DESC)
INCLUDE (LogLevel, EventType, UserID);

CREATE NONCLUSTERED INDEX IX_ApplicationLogs_UserID_Date 
ON portfolio.ApplicationLogs(UserID, CreatedAt DESC)
WHERE UserID IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_ApplicationLogs_EventType_Table 
ON portfolio.ApplicationLogs(EventType, TableName, CreatedAt DESC);

/* ============================================================
11. INDEX DETAILS INDEXES
============================================================ */

CREATE NONCLUSTERED INDEX IX_IndexDetails_Country_Region 
ON portfolio.IndexDetails(Country, Region);

PRINT 'All database indexes created successfully!'; 
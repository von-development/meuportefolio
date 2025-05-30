/* ============================================================
meuPortfolio – Views v2.0 (Consolidated & Enhanced)
Modern database views for portfolio management system
============================================================ */

USE p6g4;
GO

/* ============================================================
1. PORTFOLIO VIEWS
============================================================ */

-- Enhanced Portfolio Summary (updated for v2)
CREATE OR ALTER VIEW portfolio.vw_PortfolioSummary AS
SELECT
    p.PortfolioID,
    p.Name AS PortfolioName,
    u.UserID,
    u.Name AS OwnerName,
    u.UserType,
    u.IsPremium,
    p.CurrentFunds,
    p.CurrentProfitPct,
    p.CreationDate,
    p.LastUpdated,
    
    -- Holdings Statistics
    ISNULL(holdings.TotalHoldings, 0) AS TotalHoldings,
    ISNULL(holdings.TotalInvested, 0) AS TotalInvested,
    ISNULL(holdings.CurrentMarketValue, 0) AS CurrentMarketValue,
    
    -- Performance Metrics
    CASE 
        WHEN holdings.TotalInvested > 0 
        THEN ((holdings.CurrentMarketValue - holdings.TotalInvested) / holdings.TotalInvested) * 100
        ELSE 0 
    END AS UnrealizedGainLossPercent,
    
    -- Total Portfolio Value (Cash + Investments)
    p.CurrentFunds + ISNULL(holdings.CurrentMarketValue, 0) AS TotalPortfolioValue,
    
    -- Transaction Statistics
    ISNULL(trans.TotalTrades, 0) AS TotalTrades,
    trans.LastTradeDate
    
FROM portfolio.Portfolios p
JOIN portfolio.Users u ON u.UserID = p.UserID
LEFT JOIN (
    -- Holdings aggregation
    SELECT 
        ph.PortfolioID,
        COUNT(*) AS TotalHoldings,
        SUM(ph.TotalCost) AS TotalInvested,
        SUM(ph.QuantityHeld * a.Price) AS CurrentMarketValue
    FROM portfolio.PortfolioHoldings ph
    JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
    GROUP BY ph.PortfolioID
) holdings ON holdings.PortfolioID = p.PortfolioID
LEFT JOIN (
    -- Transaction statistics
    SELECT 
        t.PortfolioID,
        COUNT(*) AS TotalTrades,
        MAX(t.TransactionDate) AS LastTradeDate
    FROM portfolio.Transactions t
    WHERE t.Status = 'Executed'
    GROUP BY t.PortfolioID
) trans ON trans.PortfolioID = p.PortfolioID;
GO

-- Current Portfolio Holdings (v2 - using PortfolioHoldings table)
CREATE OR ALTER VIEW portfolio.vw_PortfolioHoldings AS
SELECT
    ph.HoldingID,
    ph.PortfolioID,
    p.Name AS PortfolioName,
    p.UserID,
    u.Name AS OwnerName,
    
    -- Asset Information
    ph.AssetID,
    a.Name AS AssetName,
    a.Symbol,
    a.AssetType,
    
    -- Holding Details
    ph.QuantityHeld,
    ph.AveragePrice,
    ph.TotalCost,
    a.Price AS CurrentPrice,
    ph.LastUpdated,
    
    -- Performance Calculations
    (ph.QuantityHeld * a.Price) AS CurrentValue,
    ((ph.QuantityHeld * a.Price) - ph.TotalCost) AS UnrealizedGainLoss,
    CASE 
        WHEN ph.TotalCost > 0 
        THEN (((ph.QuantityHeld * a.Price) - ph.TotalCost) / ph.TotalCost) * 100
        ELSE 0 
    END AS GainLossPercentage,
    
    -- Portfolio Allocation
    CASE 
        WHEN portfolio_totals.TotalMarketValue > 0 
        THEN ((ph.QuantityHeld * a.Price) / portfolio_totals.TotalMarketValue) * 100
        ELSE 0 
    END AS PortfolioWeightPercent
    
FROM portfolio.PortfolioHoldings ph
JOIN portfolio.Portfolios p ON p.PortfolioID = ph.PortfolioID
JOIN portfolio.Users u ON u.UserID = p.UserID
JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
CROSS APPLY (
    -- Calculate total portfolio market value for allocation percentages
    SELECT SUM(ph2.QuantityHeld * a2.Price) AS TotalMarketValue
    FROM portfolio.PortfolioHoldings ph2
    JOIN portfolio.Assets a2 ON a2.AssetID = ph2.AssetID
    WHERE ph2.PortfolioID = ph.PortfolioID
) portfolio_totals;
GO

/* ============================================================
2. USER & ACCOUNT VIEWS
============================================================ */

-- Comprehensive User Account Summary (v2 with payment & subscription)
CREATE OR ALTER VIEW portfolio.vw_UserAccountSummary AS
SELECT
    u.UserID,
    u.Name,
    u.Email,
    u.CountryOfResidence,
    u.UserType,
    u.AccountBalance,
    u.CreatedAt,
    u.UpdatedAt,
    
    -- Payment Method Info
    u.PaymentMethodType,
    u.PaymentMethodDetails,
    u.PaymentMethodExpiry,
    u.PaymentMethodActive,
    
    -- Subscription Info
    u.IsPremium,
    u.PremiumStartDate,
    u.PremiumEndDate,
    u.MonthlySubscriptionRate,
    u.AutoRenewSubscription,
    u.LastSubscriptionPayment,
    u.NextSubscriptionPayment,
    
    -- Calculated Subscription Fields
    CASE 
        WHEN u.IsPremium = 1 AND u.PremiumEndDate > SYSDATETIME() 
        THEN DATEDIFF(DAY, SYSDATETIME(), u.PremiumEndDate)
        ELSE 0
    END AS DaysRemainingInSubscription,
    
    CASE 
        WHEN u.IsPremium = 1 AND u.PremiumEndDate <= SYSDATETIME() 
        THEN 1 ELSE 0
    END AS SubscriptionExpired,
    
    -- Portfolio Statistics
    ISNULL(portfolios.TotalPortfolios, 0) AS TotalPortfolios,
    ISNULL(portfolios.TotalFundsInPortfolios, 0) AS TotalFundsInPortfolios,
    ISNULL(portfolios.TotalMarketValue, 0) AS TotalMarketValue,
    
    -- Total Net Worth
    u.AccountBalance + ISNULL(portfolios.TotalFundsInPortfolios, 0) + ISNULL(portfolios.TotalMarketValue, 0) AS TotalNetWorth,
    
    -- Recent Activity
    recent_activity.LastFundTransactionDate,
    recent_activity.LastTradeDate
    
FROM portfolio.Users u
LEFT JOIN (
    -- Portfolio aggregations
    SELECT 
        p.UserID,
        COUNT(*) AS TotalPortfolios,
        SUM(p.CurrentFunds) AS TotalFundsInPortfolios,
        SUM(ISNULL(holdings.MarketValue, 0)) AS TotalMarketValue
    FROM portfolio.Portfolios p
    LEFT JOIN (
        SELECT 
            ph.PortfolioID,
            SUM(ph.QuantityHeld * a.Price) AS MarketValue
        FROM portfolio.PortfolioHoldings ph
        JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
        GROUP BY ph.PortfolioID
    ) holdings ON holdings.PortfolioID = p.PortfolioID
    GROUP BY p.UserID
) portfolios ON portfolios.UserID = u.UserID
LEFT JOIN (
    -- Recent activity dates
    SELECT 
        u.UserID,
        (SELECT TOP 1 ft.CreatedAt 
         FROM portfolio.FundTransactions ft 
         WHERE ft.UserID = u.UserID 
         ORDER BY ft.CreatedAt DESC) AS LastFundTransactionDate,
        (SELECT TOP 1 t.TransactionDate 
         FROM portfolio.Transactions t 
         JOIN portfolio.Portfolios p ON p.PortfolioID = t.PortfolioID
         WHERE p.UserID = u.UserID AND t.Status = 'Executed'
         ORDER BY t.TransactionDate DESC) AS LastTradeDate
    FROM portfolio.Users u
) recent_activity ON recent_activity.UserID = u.UserID;
GO

/* ============================================================
3. FUND TRANSACTION VIEWS
============================================================ */

-- Fund Transaction History with Context
CREATE OR ALTER VIEW portfolio.vw_FundTransactionHistory AS
SELECT
    ft.FundTransactionID,
    ft.UserID,
    u.Name AS UserName,
    ft.PortfolioID,
    p.Name AS PortfolioName,
    ft.TransactionType,
    ft.Amount,
    ft.BalanceAfter,
    ft.Description,
    ft.RelatedAssetTransactionID,
    ft.CreatedAt,
    
    -- Transaction Categories
    CASE 
        WHEN ft.TransactionType IN ('Deposit', 'Withdrawal') THEN 'Account Management'
        WHEN ft.TransactionType IN ('Allocation', 'Deallocation') THEN 'Portfolio Funding'
        WHEN ft.TransactionType = 'PremiumUpgrade' THEN 'Subscription'
        WHEN ft.TransactionType IN ('AssetPurchase', 'AssetSale') THEN 'Trading'
        ELSE 'Other'
    END AS TransactionCategory,
    
    -- Related Asset Information (for trading transactions)
    CASE 
        WHEN ft.RelatedAssetTransactionID IS NOT NULL THEN
            (SELECT a.Symbol + ' - ' + a.Name 
             FROM portfolio.Transactions t 
             JOIN portfolio.Assets a ON a.AssetID = t.AssetID
             WHERE t.TransactionID = ft.RelatedAssetTransactionID)
        ELSE NULL
    END AS RelatedAssetInfo
    
FROM portfolio.FundTransactions ft
JOIN portfolio.Users u ON u.UserID = ft.UserID
LEFT JOIN portfolio.Portfolios p ON p.PortfolioID = ft.PortfolioID;
GO

/* ============================================================
4. ASSET & MARKET VIEWS
============================================================ */

-- Enhanced Asset Information with Details
CREATE OR ALTER VIEW portfolio.vw_AssetDetails AS
SELECT
    a.AssetID,
    a.Name,
    a.Symbol,
    a.AssetType,
    a.Price,
    a.Volume,
    a.AvailableShares,
    a.LastUpdated,
    
    -- Asset-specific details
    CASE 
        WHEN a.AssetType = 'Stock' THEN sd.Sector
        WHEN a.AssetType = 'Cryptocurrency' THEN cd.Blockchain
        WHEN a.AssetType = 'Commodity' THEN comd.Category
        ELSE NULL
    END AS CategoryInfo,
    
    CASE 
        WHEN a.AssetType = 'Stock' THEN sd.Country
        WHEN a.AssetType = 'Commodity' THEN comd.Unit
        ELSE NULL
    END AS AdditionalInfo,
    
    CASE 
        WHEN a.AssetType = 'Stock' THEN sd.MarketCap
        WHEN a.AssetType = 'Cryptocurrency' THEN cd.CirculatingSupply
        ELSE NULL
    END AS MarketMetric,
    
    -- Recent price performance (last 30 days)
    (SELECT TOP 1 ap.Price 
     FROM portfolio.AssetPrices ap 
     WHERE ap.AssetID = a.AssetID AND ap.AsOf <= DATEADD(DAY, -30, SYSDATETIME())
     ORDER BY ap.AsOf DESC) AS Price30DaysAgo,
    
    -- Holdings statistics
    ISNULL(holdings.TotalQuantityHeld, 0) AS TotalQuantityHeld,
    ISNULL(holdings.TotalPortfoliosHolding, 0) AS TotalPortfoliosHolding
    
FROM portfolio.Assets a
LEFT JOIN portfolio.StockDetails sd ON sd.AssetID = a.AssetID
LEFT JOIN portfolio.CryptoDetails cd ON cd.AssetID = a.AssetID  
LEFT JOIN portfolio.CommodityDetails comd ON comd.AssetID = a.AssetID
LEFT JOIN (
    -- Holdings aggregation
    SELECT 
        ph.AssetID,
        SUM(ph.QuantityHeld) AS TotalQuantityHeld,
        COUNT(DISTINCT ph.PortfolioID) AS TotalPortfoliosHolding
    FROM portfolio.PortfolioHoldings ph
    GROUP BY ph.AssetID
) holdings ON holdings.AssetID = a.AssetID;
GO

-- Asset Price History with Performance Metrics (updated)
CREATE OR ALTER VIEW portfolio.vw_AssetPriceHistory AS
SELECT
    a.AssetID,
    a.Symbol,
    a.Name AS AssetName,
    a.AssetType,
    ap.PriceID,
    ap.AsOf AS PriceDate,
    ap.OpenPrice,
    ap.HighPrice,
    ap.LowPrice,
    ap.Price AS ClosePrice,
    ap.Volume,
    
    -- Daily Performance
    ((ap.Price - ap.OpenPrice) / ap.OpenPrice) * 100 AS DailyChangePercent,
    ap.Price - ap.OpenPrice AS DailyChangeAmount,
    
    -- Volatility (High-Low range)
    ((ap.HighPrice - ap.LowPrice) / ap.OpenPrice) * 100 AS DailyVolatilityPercent
    
FROM portfolio.Assets a
JOIN portfolio.AssetPrices ap ON ap.AssetID = a.AssetID;
GO

/* ============================================================
5. RISK & ANALYTICS VIEWS
============================================================ */

-- Enhanced Risk Analysis (updated for v2)
CREATE OR ALTER VIEW portfolio.vw_RiskAnalysis AS
SELECT
    u.UserID,
    u.Name AS UserName,
    u.Email,
    u.UserType,
    u.IsPremium,
    u.AccountBalance,
    
    -- Portfolio Statistics  
    ISNULL(portfolios.TotalPortfolios, 0) AS TotalPortfolios,
    ISNULL(portfolios.TotalInvestment, 0) AS TotalInvestment,
    ISNULL(portfolios.TotalMarketValue, 0) AS TotalMarketValue,
    ISNULL(portfolios.TotalUnrealizedGainLoss, 0) AS TotalUnrealizedGainLoss,
    
    -- Risk Metrics (if available)
    rm.MaximumDrawdown,
    rm.Beta,
    rm.SharpeRatio,
    rm.AbsoluteReturn,
    rm.VolatilityScore,
    rm.RiskLevel,
    rm.CapturedAt AS RiskMetricsLastUpdated,
    
    -- Diversification Metrics
    portfolios.UniqueAssetsHeld,
    portfolios.AssetTypesHeld
    
FROM portfolio.Users u
LEFT JOIN (
    -- Portfolio aggregations with diversification metrics
    SELECT 
        p.UserID,
        COUNT(DISTINCT p.PortfolioID) AS TotalPortfolios,
        SUM(ISNULL(ph.TotalCost, 0)) AS TotalInvestment,
        SUM(ISNULL(ph.QuantityHeld * a.Price, 0)) AS TotalMarketValue,
        SUM(ISNULL((ph.QuantityHeld * a.Price) - ph.TotalCost, 0)) AS TotalUnrealizedGainLoss,
        COUNT(DISTINCT ph.AssetID) AS UniqueAssetsHeld,
        COUNT(DISTINCT a.AssetType) AS AssetTypesHeld
    FROM portfolio.Portfolios p
    LEFT JOIN portfolio.PortfolioHoldings ph ON ph.PortfolioID = p.PortfolioID
    LEFT JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
    GROUP BY p.UserID
) portfolios ON portfolios.UserID = u.UserID
LEFT JOIN portfolio.RiskMetrics rm ON rm.UserID = u.UserID;
GO

PRINT 'Database views v2.0 created successfully!';
PRINT '';
PRINT 'SUMMARY OF VIEWS CREATED:';
PRINT '✅ vw_PortfolioSummary - Enhanced portfolio overview with performance metrics';
PRINT '✅ vw_PortfolioHoldings - Current holdings using PortfolioHoldings table';
PRINT '✅ vw_UserAccountSummary - Comprehensive user info with payment/subscription';
PRINT '✅ vw_FundTransactionHistory - Fund transaction history with context';
PRINT '✅ vw_AssetDetails - Asset information with type-specific details';
PRINT '✅ vw_AssetPriceHistory - Price history with performance metrics (updated)';
PRINT '✅ vw_RiskAnalysis - Enhanced risk analysis with diversification metrics';
PRINT '';
PRINT 'KEY V2 IMPROVEMENTS:';
PRINT '🚀 Uses PortfolioHoldings table for better performance';
PRINT '🚀 Includes payment method and subscription data';
PRINT '🚀 Comprehensive fund transaction tracking';
PRINT '🚀 Enhanced asset details with type-specific information';
PRINT '🚀 Better risk analysis with diversification metrics';
PRINT '🚀 Real-time performance calculations and portfolio analytics'; 
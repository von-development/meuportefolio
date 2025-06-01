/* ============================================================
meuPortfolio - Portfolio Analytics & Performance Reports
Analysis of portfolio performance, holdings, and trading activity
============================================================ */

USE p6g4;
GO

PRINT '============================================================';
PRINT 'PORTFOLIO ANALYTICS & PERFORMANCE REPORTS';
PRINT '============================================================';

-- 1. PORTFOLIO PERFORMANCE OVERVIEW
PRINT '';
PRINT ' PORTFOLIO PERFORMANCE OVERVIEW:';
SELECT 
    p.Name AS PortfolioName,
    u.Name AS OwnerName,
    p.CurrentFunds,
    p.CurrentProfitPct,
    portfolio.fn_PortfolioMarketValueV2(p.PortfolioID) AS MarketValue,
    portfolio.fn_PortfolioTotalInvestment(p.PortfolioID) AS TotalInvestment,
    portfolio.fn_PortfolioUnrealizedGainLoss(p.PortfolioID) AS UnrealizedPL,
    portfolio.fn_PortfolioUnrealizedGainLossPct(p.PortfolioID) AS UnrealizedPLPct,
    portfolio.fn_PortfolioTotalValue(p.PortfolioID) AS TotalValue
FROM portfolio.Portfolios p
JOIN portfolio.Users u ON u.UserID = p.UserID
ORDER BY portfolio.fn_PortfolioTotalValue(p.PortfolioID) DESC;

-- 2. TOP PERFORMING PORTFOLIOS
PRINT '';
PRINT ' TOP 10 PERFORMING PORTFOLIOS (by % gain):';
SELECT TOP 10
    p.Name AS PortfolioName,
    u.Name AS OwnerName,
    portfolio.fn_PortfolioUnrealizedGainLossPct(p.PortfolioID) AS GainLossPercent,
    portfolio.fn_PortfolioUnrealizedGainLoss(p.PortfolioID) AS GainLossAmount,
    portfolio.fn_PortfolioTotalValue(p.PortfolioID) AS TotalValue
FROM portfolio.Portfolios p
JOIN portfolio.Users u ON u.UserID = p.UserID
WHERE portfolio.fn_PortfolioTotalInvestment(p.PortfolioID) > 0
ORDER BY portfolio.fn_PortfolioUnrealizedGainLossPct(p.PortfolioID) DESC;

-- 3. PORTFOLIO DIVERSIFICATION ANALYSIS
PRINT '';
PRINT ' PORTFOLIO DIVERSIFICATION ANALYSIS:';
SELECT 
    p.Name AS PortfolioName,
    u.Name AS OwnerName,
    COUNT(DISTINCT ph.AssetID) AS UniqueAssets,
    COUNT(DISTINCT a.AssetType) AS AssetTypes,
    SUM(ph.QuantityHeld * a.Price) AS TotalMarketValue
FROM portfolio.Portfolios p
JOIN portfolio.Users u ON u.UserID = p.UserID
JOIN portfolio.PortfolioHoldings ph ON ph.PortfolioID = p.PortfolioID
JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
GROUP BY p.PortfolioID, p.Name, u.Name
ORDER BY COUNT(DISTINCT ph.AssetID) DESC;

-- 4. LARGEST HOLDINGS BY VALUE
PRINT '';
PRINT ' LARGEST HOLDINGS BY VALUE:';
SELECT TOP 20
    p.Name AS PortfolioName,
    u.Name AS OwnerName,
    a.Symbol,
    a.Name AS AssetName,
    a.AssetType,
    ph.QuantityHeld,
    a.Price AS CurrentPrice,
    ph.AveragePrice,
    (ph.QuantityHeld * a.Price) AS CurrentValue,
    portfolio.fn_HoldingUnrealizedGainLoss(ph.HoldingID) AS UnrealizedPL,
    portfolio.fn_HoldingGainLossPercentage(ph.HoldingID) AS GainLossPercent
FROM portfolio.PortfolioHoldings ph
JOIN portfolio.Portfolios p ON p.PortfolioID = ph.PortfolioID
JOIN portfolio.Users u ON u.UserID = p.UserID
JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
ORDER BY (ph.QuantityHeld * a.Price) DESC;

-- 5. ASSET TYPE ALLOCATION ACROSS ALL PORTFOLIOS
PRINT '';
PRINT ' ASSET TYPE ALLOCATION:';
SELECT 
    a.AssetType,
    COUNT(DISTINCT ph.PortfolioID) AS PortfoliosHolding,
    SUM(ph.QuantityHeld * a.Price) AS TotalMarketValue,
    AVG(ph.QuantityHeld * a.Price) AS AvgHoldingValue,
    COUNT(*) AS TotalHoldings
FROM portfolio.PortfolioHoldings ph
JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
GROUP BY a.AssetType
ORDER BY SUM(ph.QuantityHeld * a.Price) DESC;

-- 6. RECENT TRADING ACTIVITY
PRINT '';
PRINT ' RECENT TRADING ACTIVITY (Last 30 days):';
SELECT 
    u.Name AS UserName,
    p.Name AS PortfolioName,
    a.Symbol,
    a.Name AS AssetName,
    t.TransactionType,
    t.Quantity,
    t.UnitPrice,
    (t.Quantity * t.UnitPrice) AS TotalValue,
    t.TransactionDate,
    t.Status
FROM portfolio.Transactions t
JOIN portfolio.Users u ON u.UserID = t.UserID
JOIN portfolio.Portfolios p ON p.PortfolioID = t.PortfolioID
JOIN portfolio.Assets a ON a.AssetID = t.AssetID
WHERE t.TransactionDate >= DATEADD(DAY, -30, SYSDATETIME())
ORDER BY t.TransactionDate DESC;

PRINT '';
PRINT ' Portfolio analytics completed!'; 
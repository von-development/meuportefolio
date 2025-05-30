/* ------------------------------------------------------------
meuPortfolio – Views Creation  (v2025-05-24)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
1. Portfolio Summary View
============================================================ */
CREATE OR ALTER VIEW portfolio.vw_PortfolioSummary AS
SELECT
    p.PortfolioID,
    p.Name AS PortfolioName,
    u.Name AS Owner,
    p.CurrentFunds,
    p.CurrentProfitPct,
    p.CreationDate,
    COUNT(t.TransactionID) AS TotalTrades
FROM portfolio.Portfolios p
    JOIN portfolio.Users u ON u.UserID = p.UserID
    LEFT JOIN portfolio.Transactions t ON t.PortfolioID = p.PortfolioID
GROUP BY
    p.PortfolioID,
    p.Name,
    u.Name,
    p.CurrentFunds,
    p.CurrentProfitPct,
    p.CreationDate;
GO

/* ============================================================
2. Asset Holdings View
============================================================ */
CREATE OR ALTER VIEW portfolio.vw_AssetHoldings AS
SELECT
    p.PortfolioID,
    p.Name AS PortfolioName,
    a.AssetID,
    a.Name AS AssetName,
    a.Symbol,
    a.AssetType,
    SUM(
        CASE
            WHEN t.TransactionType = 'Buy' THEN t.Quantity
            WHEN t.TransactionType = 'Sell' THEN -t.Quantity
        END
    ) AS QuantityHeld,
    a.Price AS CurrentPrice,
    SUM(
        CASE
            WHEN t.TransactionType = 'Buy' THEN t.Quantity
            WHEN t.TransactionType = 'Sell' THEN -t.Quantity
        END
    ) * a.Price AS MarketValue
FROM portfolio.Portfolios p
    JOIN portfolio.Transactions t ON t.PortfolioID = p.PortfolioID
    JOIN portfolio.Assets a ON a.AssetID = t.AssetID
GROUP BY
    p.PortfolioID,
    p.Name,
    a.AssetID,
    a.Name,
    a.Symbol,
    a.AssetType,
    a.Price;
GO

/* ============================================================
3. Risk Analysis View
============================================================ */
CREATE OR ALTER VIEW portfolio.vw_RiskAnalysis AS
SELECT
    u.UserID,
    u.Name AS UserName,
    u.UserType,
    COUNT(DISTINCT p.PortfolioID) AS TotalPortfolios,
    SUM(p.CurrentFunds) AS TotalInvestment,
    rm.MaximumDrawdown,
    rm.SharpeRatio,
    rm.RiskLevel,
    rm.CapturedAt AS LastUpdated
FROM portfolio.Users u
    LEFT JOIN portfolio.Portfolios p ON p.UserID = u.UserID
    LEFT JOIN portfolio.RiskMetrics rm ON rm.UserID = u.UserID
GROUP BY
    u.UserID,
    u.Name,
    u.UserType,
    rm.MaximumDrawdown,
    rm.SharpeRatio,
    rm.RiskLevel,
    rm.CapturedAt;
GO

/* ============================================================
4. Asset Price History View
============================================================ */
CREATE OR ALTER VIEW portfolio.vw_AssetPriceHistory AS
SELECT
    a.AssetID,
    a.Symbol,
    a.AssetType,
    ap.AsOf AS PriceDate,
    ap.OpenPrice,
    ap.HighPrice,
    ap.LowPrice,
    ap.Price AS ClosePrice,
    ((ap.Price - ap.OpenPrice) / ap.OpenPrice) * 100 AS DailyChange,
    ap.Volume
FROM portfolio.Assets a
    JOIN portfolio.AssetPrices ap ON ap.AssetID = a.AssetID;
GO

/* ----------------  END OF SCRIPT ---------------- */ 
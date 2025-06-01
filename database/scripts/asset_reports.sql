/* ============================================================
meuPortfolio - Asset Management & Market Analysis
Asset information, price analysis, and market data reports
============================================================ */

USE p6g4;
GO

PRINT '============================================================';
PRINT 'ASSET MANAGEMENT & MARKET ANALYSIS';
PRINT '============================================================';

-- 1. ASSET OVERVIEW BY TYPE
PRINT '';
PRINT '📊 ASSET OVERVIEW BY TYPE:';
SELECT 
    AssetType,
    COUNT(*) AS AssetCount,
    AVG(Price) AS AvgPrice,
    MIN(Price) AS MinPrice,
    MAX(Price) AS MaxPrice,
    SUM(Volume) AS TotalVolume
FROM portfolio.Assets
GROUP BY AssetType
ORDER BY COUNT(*) DESC;

-- 2. MOST POPULAR ASSETS (by holdings)
PRINT '';
PRINT '🔥 MOST POPULAR ASSETS (by number of portfolios holding):';
SELECT TOP 20
    a.Symbol,
    a.Name,
    a.AssetType,
    a.Price,
    COUNT(DISTINCT ph.PortfolioID) AS PortfoliosHolding,
    SUM(ph.QuantityHeld) AS TotalQuantityHeld,
    SUM(ph.QuantityHeld * a.Price) AS TotalMarketValue
FROM portfolio.Assets a
LEFT JOIN portfolio.PortfolioHoldings ph ON ph.AssetID = a.AssetID
GROUP BY a.AssetID, a.Symbol, a.Name, a.AssetType, a.Price
ORDER BY COUNT(DISTINCT ph.PortfolioID) DESC;

-- 3. HIGHEST VALUE ASSETS
PRINT '';
PRINT '💎 HIGHEST VALUE ASSETS:';
SELECT TOP 15
    Symbol,
    Name,
    AssetType,
    Price,
    Volume,
    AvailableShares,
    LastUpdated
FROM portfolio.Assets
ORDER BY Price DESC;

-- 4. ASSET PERFORMANCE ANALYSIS (if price history exists)
PRINT '';
PRINT '📈 RECENT ASSET PRICE ACTIVITY:';
SELECT TOP 20
    a.Symbol,
    a.Name AS AssetName,
    a.AssetType,
    ap.Price AS HistoricalPrice,
    a.Price AS CurrentPrice,
    ((a.Price - ap.Price) / ap.Price * 100) AS PriceChangePercent,
    ap.AsOf AS PriceDate
FROM portfolio.Assets a
JOIN portfolio.AssetPrices ap ON ap.AssetID = a.AssetID
WHERE ap.AsOf >= DATEADD(DAY, -7, SYSDATETIME())
ORDER BY ABS((a.Price - ap.Price) / ap.Price * 100) DESC;

-- 5. STOCK DETAILS OVERVIEW
PRINT '';
PRINT '🏢 STOCK DETAILS OVERVIEW:';
SELECT 
    a.Symbol,
    a.Name,
    sd.Sector,
    sd.Country,
    sd.MarketCap,
    a.Price
FROM portfolio.Assets a
JOIN portfolio.StockDetails sd ON sd.AssetID = a.AssetID
ORDER BY sd.MarketCap DESC;

-- 6. CRYPTOCURRENCY OVERVIEW
PRINT '';
PRINT '₿ CRYPTOCURRENCY OVERVIEW:';
SELECT 
    a.Symbol,
    a.Name,
    cd.Blockchain,
    cd.MaxSupply,
    cd.CirculatingSupply,
    a.Price,
    (a.Price * cd.CirculatingSupply) AS MarketCap
FROM portfolio.Assets a
JOIN portfolio.CryptoDetails cd ON cd.AssetID = a.AssetID
ORDER BY (a.Price * cd.CirculatingSupply) DESC;

-- 7. COMMODITY OVERVIEW
PRINT '';
PRINT '🌾 COMMODITY OVERVIEW:';
SELECT 
    a.Symbol,
    a.Name,
    cmd.Category,
    cmd.Unit,
    a.Price,
    a.Volume
FROM portfolio.Assets a
JOIN portfolio.CommodityDetails cmd ON cmd.AssetID = a.AssetID
ORDER BY cmd.Category, a.Price DESC;

-- 8. INDEX OVERVIEW
PRINT '';
PRINT '📊 INDEX OVERVIEW:';
SELECT 
    a.Symbol,
    a.Name,
    id.Country,
    id.Region,
    id.IndexType,
    id.ComponentCount,
    a.Price
FROM portfolio.Assets a
JOIN portfolio.IndexDetails id ON id.AssetID = a.AssetID
ORDER BY id.Country, a.Price DESC;

-- 9. ASSETS WITHOUT HOLDINGS
PRINT '';
PRINT '🚫 ASSETS NOT CURRENTLY HELD:';
SELECT 
    a.Symbol,
    a.Name,
    a.AssetType,
    a.Price,
    a.LastUpdated
FROM portfolio.Assets a
LEFT JOIN portfolio.PortfolioHoldings ph ON ph.AssetID = a.AssetID
WHERE ph.AssetID IS NULL
ORDER BY a.AssetType, a.Symbol;

PRINT '';
PRINT '✅ Asset reports completed!'; 
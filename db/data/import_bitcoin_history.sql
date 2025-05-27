/* ------------------------------------------------------------
meuPortfolio – Import Bitcoin Historical Data (v2024-03-21)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
1. Ensure Bitcoin exists in Assets table
============================================================ */
IF NOT EXISTS (SELECT 1 FROM portfolio.Assets WHERE Symbol = 'BTC')
BEGIN
    INSERT INTO portfolio.Assets (Symbol, Name, AssetType, Currency)
    VALUES ('BTC', 'Bitcoin', 'Cryptocurrency', 'USD');
END

/* ============================================================
2. Create temporary table for data import
============================================================ */
CREATE TABLE #TempBitcoinPrices
(
    [Date] DATE,
    [Price] DECIMAL(18,2),
    [Open] DECIMAL(18,2),
    [High] DECIMAL(18,2),
    [Low] DECIMAL(18,2),
    [Volume] DECIMAL(18,2),
    [Change] DECIMAL(18,2)
);

/* ============================================================
3. Insert cleaned CSV data
============================================================ */
-- Note: You'll need to use BULK INSERT or a similar tool to import the CSV
-- For now, we'll insert a few rows manually as example
INSERT INTO #TempBitcoinPrices ([Date], Price, [Open], High, Low, Volume, Change)
VALUES 
    ('2025-05-27', 110124.60, 109455.30, 110718.70, 107572.20, 60840, 0.61),
    ('2025-05-26', 109455.30, 109014.90, 110401.40, 108694.00, 48010, 0.40),
    ('2025-05-25', 109021.10, 107763.00, 109203.40, 106648.30, 52490, 1.17);

/* ============================================================
4. Insert into AssetPrices table
============================================================ */
INSERT INTO portfolio.AssetPrices (AssetID, Price, PriceDate, OpenPrice, HighPrice, LowPrice, Volume)
SELECT 
    a.AssetID,
    t.Price,
    t.[Date],
    t.[Open],
    t.High,
    t.Low,
    t.Volume
FROM #TempBitcoinPrices t
CROSS JOIN portfolio.Assets a
WHERE a.Symbol = 'BTC'
AND NOT EXISTS (
    SELECT 1 
    FROM portfolio.AssetPrices ap 
    WHERE ap.AssetID = a.AssetID 
    AND ap.PriceDate = t.[Date]
);

/* ============================================================
5. Cleanup
============================================================ */
DROP TABLE #TempBitcoinPrices;
GO 
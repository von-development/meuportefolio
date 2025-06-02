/* ============================================================
Verification: Check ChangePercent Data Population
Description: Verify that ChangePercent values were successfully imported
============================================================ */

USE p6g4;
GO

PRINT '========================================';
PRINT 'CHANGEPERCENT DATA VERIFICATION';
PRINT '========================================';
PRINT '';

-- Show sample records with ChangePercent values
PRINT 'Sample records with ChangePercent values:';
SELECT TOP 10
    a.Symbol,
    ap.AssetID,
    ap.Price,
    ap.AsOf,
    ap.ChangePercent
FROM portfolio.AssetPrices ap
INNER JOIN portfolio.Assets a ON ap.AssetID = a.AssetID
WHERE ap.ChangePercent IS NOT NULL
ORDER BY ap.AsOf DESC;

PRINT '';

-- Count records with and without ChangePercent
DECLARE @TotalRecords INT, @WithChangePercent INT, @WithoutChangePercent INT;

SELECT @TotalRecords = COUNT(*) FROM portfolio.AssetPrices;
SELECT @WithChangePercent = COUNT(*) FROM portfolio.AssetPrices WHERE ChangePercent IS NOT NULL;
SELECT @WithoutChangePercent = COUNT(*) FROM portfolio.AssetPrices WHERE ChangePercent IS NULL;

PRINT 'Data Summary:';
PRINT 'Total Records: ' + CAST(@TotalRecords AS VARCHAR(10));
PRINT 'Records WITH ChangePercent: ' + CAST(@WithChangePercent AS VARCHAR(10));
PRINT 'Records WITHOUT ChangePercent: ' + CAST(@WithoutChangePercent AS VARCHAR(10));

-- Show breakdown by asset
PRINT '';
PRINT 'ChangePercent by Asset (Top 10):';
SELECT TOP 10
    a.Symbol,
    a.AssetType,
    COUNT(*) as TotalRecords,
    COUNT(ap.ChangePercent) as WithChangePercent,
    COUNT(*) - COUNT(ap.ChangePercent) as WithoutChangePercent
FROM portfolio.Assets a
LEFT JOIN portfolio.AssetPrices ap ON a.AssetID = ap.AssetID
GROUP BY a.Symbol, a.AssetType
ORDER BY WithChangePercent DESC;

PRINT '';
PRINT '========================================';
PRINT 'VERIFICATION COMPLETE';
PRINT '========================================'; 
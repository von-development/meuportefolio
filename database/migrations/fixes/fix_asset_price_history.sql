/* ============================================================
FIX: Asset Price History Data Issue
meuPortfolio - Price History Chart Fix

ISSUE: The chart was showing only May-June 2025 dates instead of January data
CAUSE: The stored procedure was using TOP 30 instead of proper date filtering
       and ordering data DESC instead of chronological ASC order

RUN THIS WHEN READY TO FIX THE BACKEND DATABASE
============================================================ */

USE p6g4;
GO

PRINT 'Starting Asset Price History Fix...';
PRINT '=====================================';
PRINT '';
PRINT 'ISSUE DESCRIPTION:';
PRINT '- Chart showing only May-June 2025 dates despite having January data';
PRINT '- Frontend receives limited/wrong date range from backend';
PRINT '- Stored procedure sp_GetAssetComplete needs optimization';
PRINT '';
PRINT 'SOLUTION:';
PRINT '- Remove TOP 30 limit (get all available data)';
PRINT '- Change ORDER BY from DESC to ASC (chronological order)';
PRINT '- Add debug field (DaysAgo) to help troubleshoot';
PRINT '- Let frontend decide how much data to display';
PRINT '';
GO

-- Get complete asset information with details (FIXED VERSION)
CREATE OR ALTER PROCEDURE portfolio.sp_GetAssetComplete (
    @AssetID INT
) AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM portfolio.Assets WHERE AssetID = @AssetID)
    BEGIN
        RAISERROR('Asset not found', 16, 1);
        RETURN;
    END
    
    -- Basic asset info (unchanged)
    SELECT 
        AssetID,
        Name,
        Symbol,
        AssetType,
        Price,
        Volume,
        AvailableShares,
        LastUpdated
    FROM portfolio.Assets 
    WHERE AssetID = @AssetID;
    
    -- Asset-specific details based on type (unchanged)
    DECLARE @AssetType NVARCHAR(20);
    SELECT @AssetType = AssetType FROM portfolio.Assets WHERE AssetID = @AssetID;
    
    IF @AssetType = 'Stock'
    BEGIN
        SELECT * FROM portfolio.StockDetails WHERE AssetID = @AssetID;
    END
    ELSE IF @AssetType = 'Cryptocurrency'
    BEGIN
        SELECT * FROM portfolio.CryptoDetails WHERE AssetID = @AssetID;
    END
    ELSE IF @AssetType = 'Commodity'
    BEGIN
        SELECT * FROM portfolio.CommodityDetails WHERE AssetID = @AssetID;
    END
    ELSE IF @AssetType = 'Index'
    BEGIN
        SELECT * FROM portfolio.IndexDetails WHERE AssetID = @AssetID;
    END
    
    -- FIXED: Enhanced price history query
    -- BEFORE: SELECT TOP 30 ... ORDER BY AsOf DESC
    -- AFTER:  SELECT ALL ... ORDER BY AsOf ASC (chronological)
    SELECT 
        PriceID,
        Price,
        AsOf,
        OpenPrice,
        HighPrice,
        LowPrice,
        Volume,
        -- DEBUG: Add days ago calculation to help troubleshoot
        DATEDIFF(DAY, AsOf, GETDATE()) AS DaysAgo
    FROM portfolio.AssetPrices 
    WHERE AssetID = @AssetID
    ORDER BY AsOf ASC;  -- CHANGED: ASC for chronological order, frontend can limit if needed
END;
GO

PRINT '';
PRINT '✅ sp_GetAssetComplete procedure updated successfully!';
PRINT '';
PRINT 'WHAT CHANGED:';
PRINT '1. Removed TOP 30 limit - now returns ALL price history data';
PRINT '2. Changed ORDER BY AsOf DESC to ASC (chronological order)';
PRINT '3. Added DaysAgo debug field for troubleshooting';
PRINT '4. Frontend can now decide how much data to display';
PRINT '';
PRINT 'NEXT STEPS:';
PRINT '1. Update Rust backend to handle the new DaysAgo field';
PRINT '2. Test the chart with an asset that has January data';
PRINT '3. Frontend should now show full date range chronologically';
PRINT '';
PRINT 'Asset Price History Fix completed!';
PRINT '==================================='; 
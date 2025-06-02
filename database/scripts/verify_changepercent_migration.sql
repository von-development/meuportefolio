/* ============================================================
Verification Script: Check ChangePercent Migration Status
Description: Verifies that ChangePercent column and updated stored procedure exist
============================================================ */

USE p6g4;
GO

PRINT '========================================';
PRINT 'MIGRATION VERIFICATION REPORT';
PRINT '========================================';
PRINT '';

-- 1. Check if ChangePercent column exists in AssetPrices table
PRINT '1. CHECKING CHANGEPERCENT COLUMN...';
IF EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'portfolio' 
    AND TABLE_NAME = 'AssetPrices' 
    AND COLUMN_NAME = 'ChangePercent'
)
BEGIN
    PRINT '✅ SUCCESS: ChangePercent column exists in portfolio.AssetPrices';
    
    -- Show column details
    SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        NUMERIC_PRECISION,
        NUMERIC_SCALE,
        IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'portfolio' 
    AND TABLE_NAME = 'AssetPrices' 
    AND COLUMN_NAME = 'ChangePercent';
END
ELSE
BEGIN
    PRINT '❌ FAILED: ChangePercent column NOT found in portfolio.AssetPrices';
END

PRINT '';

-- 2. Check if stored procedure exists and has ChangePercent parameter
PRINT '2. CHECKING STORED PROCEDURE...';
IF EXISTS (SELECT 1 FROM sys.procedures WHERE schema_id = SCHEMA_ID('portfolio') AND name = 'sp_import_asset_price')
BEGIN
    PRINT '✅ SUCCESS: portfolio.sp_import_asset_price procedure exists';
    
    -- Check if procedure has ChangePercent parameter
    IF EXISTS (
        SELECT 1 
        FROM sys.parameters p
        INNER JOIN sys.procedures pr ON p.object_id = pr.object_id
        WHERE pr.schema_id = SCHEMA_ID('portfolio') 
        AND pr.name = 'sp_import_asset_price'
        AND p.name = '@ChangePercent'
    )
    BEGIN
        PRINT '✅ SUCCESS: @ChangePercent parameter exists in stored procedure';
        
        -- Show all parameters
        PRINT '';
        PRINT 'Stored Procedure Parameters:';
        SELECT 
            p.name AS ParameterName,
            TYPE_NAME(p.user_type_id) AS DataType,
            p.max_length,
            p.precision,
            p.scale,
            p.is_output
        FROM sys.parameters p
        INNER JOIN sys.procedures pr ON p.object_id = pr.object_id
        WHERE pr.schema_id = SCHEMA_ID('portfolio') 
        AND pr.name = 'sp_import_asset_price'
        ORDER BY p.parameter_id;
    END
    ELSE
    BEGIN
        PRINT '❌ FAILED: @ChangePercent parameter NOT found in stored procedure';
    END
END
ELSE
BEGIN
    PRINT '❌ FAILED: portfolio.sp_import_asset_price procedure NOT found';
END

PRINT '';

-- 3. Show sample data from AssetPrices to check ChangePercent values
PRINT '3. CHECKING SAMPLE DATA...';
IF EXISTS (SELECT 1 FROM portfolio.AssetPrices)
BEGIN
    PRINT 'Sample AssetPrices records (showing ChangePercent column):';
    SELECT TOP 5
        AssetID,
        Price,
        AsOf,
        ChangePercent
    FROM portfolio.AssetPrices
    ORDER BY AsOf DESC;
    
    -- Count records with and without ChangePercent
    DECLARE @TotalRecords INT, @WithChangePercent INT, @WithoutChangePercent INT;
    
    SELECT @TotalRecords = COUNT(*) FROM portfolio.AssetPrices;
    SELECT @WithChangePercent = COUNT(*) FROM portfolio.AssetPrices WHERE ChangePercent IS NOT NULL;
    SELECT @WithoutChangePercent = COUNT(*) FROM portfolio.AssetPrices WHERE ChangePercent IS NULL;
    
    PRINT '';
    PRINT 'Data Summary:';
    PRINT 'Total Records: ' + CAST(@TotalRecords AS VARCHAR(10));
    PRINT 'Records WITH ChangePercent: ' + CAST(@WithChangePercent AS VARCHAR(10));
    PRINT 'Records WITHOUT ChangePercent: ' + CAST(@WithoutChangePercent AS VARCHAR(10));
END
ELSE
BEGIN
    PRINT 'No data found in portfolio.AssetPrices table';
END

PRINT '';
PRINT '========================================';
PRINT 'VERIFICATION COMPLETE';
PRINT '========================================'; 
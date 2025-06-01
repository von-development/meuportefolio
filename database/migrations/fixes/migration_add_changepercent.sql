/* ============================================================
Migration Script: Add ChangePercent to AssetPrices Table
Description: Adds ChangePercent column to store percentage change data from CSV imports
Date: 2024-01-01
============================================================ */

USE p6g4;
GO

-- Check if column already exists before adding it
IF NOT EXISTS (
    SELECT 1 
    FROM INFORMATION_SCHEMA.COLUMNS 
    WHERE TABLE_SCHEMA = 'portfolio' 
    AND TABLE_NAME = 'AssetPrices' 
    AND COLUMN_NAME = 'ChangePercent'
)
BEGIN
    -- Add ChangePercent column to AssetPrices table
    ALTER TABLE portfolio.AssetPrices 
    ADD ChangePercent DECIMAL(10,4) NULL;
    
    PRINT 'ChangePercent column added to portfolio.AssetPrices table successfully.';
END
ELSE
BEGIN
    PRINT 'ChangePercent column already exists in portfolio.AssetPrices table.';
END
GO

-- Update the stored procedure sp_import_asset_price if it exists
IF EXISTS (SELECT 1 FROM sys.procedures WHERE schema_id = SCHEMA_ID('portfolio') AND name = 'sp_import_asset_price')
BEGIN
    DROP PROCEDURE portfolio.sp_import_asset_price;
    PRINT 'Existing sp_import_asset_price procedure dropped for recreation.';
END
GO

-- Recreate the stored procedure with ChangePercent parameter
CREATE PROCEDURE portfolio.sp_import_asset_price
    @AssetID INT,
    @Price DECIMAL(18,2),
    @PriceDate DATETIME,
    @OpenPrice DECIMAL(18,2),
    @HighPrice DECIMAL(18,2),
    @LowPrice DECIMAL(18,2),
    @Volume BIGINT,
    @ChangePercent DECIMAL(10,4) = NULL,
    @UpdateCurrentPrice BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate asset exists
        IF NOT EXISTS (SELECT 1 FROM portfolio.Assets WHERE AssetID = @AssetID)
        BEGIN
            RAISERROR('Asset not found', 16, 1);
            RETURN;
        END
        
        -- Validate price data
        IF @Price < 0 OR @OpenPrice < 0 OR @HighPrice < 0 OR @LowPrice < 0
        BEGIN
            RAISERROR('Prices cannot be negative', 16, 1);
            RETURN;
        END
        
        IF @HighPrice < @LowPrice
        BEGIN
            RAISERROR('High price cannot be less than low price', 16, 1);
            RETURN;
        END
        
        -- Update the current price if requested
        IF @UpdateCurrentPrice = 1
        BEGIN
            UPDATE portfolio.Assets 
            SET 
                Price = @Price,
                Volume = @Volume
            WHERE AssetID = @AssetID;
        END
        
        -- Insert historical price if not exists
        IF NOT EXISTS (
            SELECT 1 
            FROM portfolio.AssetPrices 
            WHERE AssetID = @AssetID 
            AND AsOf = @PriceDate
        )
        BEGIN
            INSERT INTO portfolio.AssetPrices (
                AssetID,
                Price,
                AsOf,
                OpenPrice,
                HighPrice,
                LowPrice,
                Volume,
                ChangePercent
            )
            VALUES (
                @AssetID,
                @Price,
                @PriceDate,
                @OpenPrice,
                @HighPrice,
                @LowPrice,
                @Volume,
                @ChangePercent
            );
        END
        ELSE
        BEGIN
            -- Update existing price record
            UPDATE portfolio.AssetPrices 
            SET 
                Price = @Price,
                OpenPrice = @OpenPrice,
                HighPrice = @HighPrice,
                LowPrice = @LowPrice,
                Volume = @Volume,
                ChangePercent = @ChangePercent
            WHERE AssetID = @AssetID AND AsOf = @PriceDate;
        END
        
        COMMIT TRANSACTION;
        
        SELECT 'SUCCESS' AS Status, 'Price data imported successfully' AS Message;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
        RETURN 1;
    END CATCH
END;
GO

PRINT 'Migration completed successfully. ChangePercent column and updated stored procedure are now available.';
GO 
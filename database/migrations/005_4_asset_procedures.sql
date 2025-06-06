/* ============================================================
meuPortfolio – Asset Management Procedures v2.0
Asset creation, price management and data import operations
============================================================ */

USE p6g4;
GO

/* ============================================================
1. ASSET CREATION & MANAGEMENT
============================================================ */

-- Ensure asset exists (create if doesn't exist)
CREATE PROCEDURE portfolio.sp_ensure_asset
    @Symbol NVARCHAR(20),
    @Name NVARCHAR(100),
    @AssetType NVARCHAR(20), -- 'Stock', 'Index', 'Cryptocurrency', 'Commodity'
    @InitialPrice DECIMAL(18,2) = 0.00,
    @InitialVolume BIGINT = 0,
    @AvailableShares DECIMAL(18,6) = 0.00,
    @AssetID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate asset type
        IF @AssetType NOT IN ('Stock', 'Index', 'Cryptocurrency', 'Commodity')
        BEGIN
            RAISERROR('Invalid asset type. Use Stock, Index, Cryptocurrency, or Commodity', 16, 1);
            RETURN;
        END
        
        -- Check if asset already exists
        SELECT @AssetID = AssetID 
        FROM portfolio.Assets 
        WHERE Symbol = @Symbol;
        
        -- If doesn't exist, create it
        IF @AssetID IS NULL
        BEGIN
            INSERT INTO portfolio.Assets (
                Symbol, 
                Name, 
                AssetType, 
                Price,
                Volume,
                AvailableShares
            )
            VALUES (
                UPPER(LTRIM(RTRIM(@Symbol))),
                LTRIM(RTRIM(@Name)),
                @AssetType,
                @InitialPrice,
                @InitialVolume,
                @AvailableShares
            );
            
            SET @AssetID = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            -- Asset exists, optionally update name if provided
            IF @Name IS NOT NULL AND LTRIM(RTRIM(@Name)) != ''
            BEGIN
                UPDATE portfolio.Assets 
                SET Name = LTRIM(RTRIM(@Name))
                WHERE AssetID = @AssetID;
            END
        END
        
        -- Return the asset ID
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        THROW;
        RETURN 1;
    END CATCH
END;
GO

-- Update current asset price
CREATE PROCEDURE portfolio.sp_UpdateAssetPrice (
    @AssetID INT,
    @NewPrice DECIMAL(18,2),
    @NewVolume BIGINT = NULL
) AS
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
        
        -- Validate price
        IF @NewPrice < 0
        BEGIN
            RAISERROR('Price cannot be negative', 16, 1);
            RETURN;
        END
        
        -- Insert price history record
        INSERT INTO portfolio.AssetPrices (
            AssetID, Price, OpenPrice, HighPrice, LowPrice, Volume
        )
        VALUES (
            @AssetID, @NewPrice, @NewPrice, @NewPrice, @NewPrice, 
            ISNULL(@NewVolume, 0)
        );
        
        -- Update current asset price and volume
        UPDATE portfolio.Assets
        SET Price = @NewPrice,
            Volume = ISNULL(@NewVolume, Volume)
        WHERE AssetID = @AssetID;
        
        COMMIT;
        
        SELECT 'SUCCESS' AS Status, 'Asset price updated successfully' AS Message;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

/* ============================================================
2. PRICE DATA IMPORT
============================================================ */

-- Import comprehensive asset price data (enhanced)
CREATE PROCEDURE portfolio.sp_import_asset_price
    @AssetID INT,
    @Price DECIMAL(18,2),
    @PriceDate DATETIME,
    @OpenPrice DECIMAL(18,2),
    @HighPrice DECIMAL(18,2),
    @LowPrice DECIMAL(18,2),
    @Volume BIGINT,
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
                Volume
            )
            VALUES (
                @AssetID,
                @Price,
                @PriceDate,
                @OpenPrice,
                @HighPrice,
                @LowPrice,
                @Volume
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
                Volume = @Volume
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

/* ============================================================
3. ASSET DETAIL MANAGEMENT
============================================================ */

-- Create or update stock details
CREATE PROCEDURE portfolio.sp_UpsertStockDetails (
    @AssetID INT,
    @Sector NVARCHAR(100),
    @Country NVARCHAR(100),
    @MarketCap DECIMAL(18,2)
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate asset exists and is a stock
        IF NOT EXISTS (
            SELECT 1 FROM portfolio.Assets 
            WHERE AssetID = @AssetID AND AssetType = 'Stock'
        )
        BEGIN
            RAISERROR('Asset not found or is not a stock', 16, 1);
            RETURN;
        END
        
        -- Upsert stock details
        IF EXISTS (SELECT 1 FROM portfolio.StockDetails WHERE AssetID = @AssetID)
        BEGIN
            UPDATE portfolio.StockDetails 
            SET 
                Sector = @Sector,
                Country = @Country,
                MarketCap = @MarketCap
            WHERE AssetID = @AssetID;
        END
        ELSE
        BEGIN
            INSERT INTO portfolio.StockDetails (AssetID, Sector, Country, MarketCap)
            VALUES (@AssetID, @Sector, @Country, @MarketCap);
        END
        
        SELECT 'SUCCESS' AS Status, 'Stock details updated successfully' AS Message;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- Create or update cryptocurrency details
CREATE PROCEDURE portfolio.sp_UpsertCryptoDetails (
    @AssetID INT,
    @Blockchain NVARCHAR(50),
    @MaxSupply DECIMAL(18,0) = NULL,
    @CirculatingSupply DECIMAL(18,0)
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate asset exists and is cryptocurrency
        IF NOT EXISTS (
            SELECT 1 FROM portfolio.Assets 
            WHERE AssetID = @AssetID AND AssetType = 'Cryptocurrency'
        )
        BEGIN
            RAISERROR('Asset not found or is not a cryptocurrency', 16, 1);
            RETURN;
        END
        
        -- Upsert crypto details
        IF EXISTS (SELECT 1 FROM portfolio.CryptoDetails WHERE AssetID = @AssetID)
        BEGIN
            UPDATE portfolio.CryptoDetails 
            SET 
                Blockchain = @Blockchain,
                MaxSupply = @MaxSupply,
                CirculatingSupply = @CirculatingSupply
            WHERE AssetID = @AssetID;
        END
        ELSE
        BEGIN
            INSERT INTO portfolio.CryptoDetails (AssetID, Blockchain, MaxSupply, CirculatingSupply)
            VALUES (@AssetID, @Blockchain, @MaxSupply, @CirculatingSupply);
        END
        
        SELECT 'SUCCESS' AS Status, 'Cryptocurrency details updated successfully' AS Message;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- Create or update commodity details
CREATE PROCEDURE portfolio.sp_UpsertCommodityDetails (
    @AssetID INT,
    @Category NVARCHAR(50),
    @Unit NVARCHAR(20)
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate asset exists and is commodity
        IF NOT EXISTS (
            SELECT 1 FROM portfolio.Assets 
            WHERE AssetID = @AssetID AND AssetType = 'Commodity'
        )
        BEGIN
            RAISERROR('Asset not found or is not a commodity', 16, 1);
            RETURN;
        END
        
        -- Upsert commodity details
        IF EXISTS (SELECT 1 FROM portfolio.CommodityDetails WHERE AssetID = @AssetID)
        BEGIN
            UPDATE portfolio.CommodityDetails 
            SET 
                Category = @Category,
                Unit = @Unit
            WHERE AssetID = @AssetID;
        END
        ELSE
        BEGIN
            INSERT INTO portfolio.CommodityDetails (AssetID, Category, Unit)
            VALUES (@AssetID, @Category, @Unit);
        END
        
        SELECT 'SUCCESS' AS Status, 'Commodity details updated successfully' AS Message;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

/* ============================================================
4. ASSET DATA RETRIEVAL
============================================================ */

-- Get complete asset information with details
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

-- Bulk price update procedure
CREATE PROCEDURE portfolio.sp_BulkUpdateAssetPrices (
    @PriceData NVARCHAR(MAX) -- JSON format: [{"AssetID":1,"Price":100.50,"Volume":1000}, ...]
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Parse JSON and update prices
        UPDATE a
        SET Price = CAST(JSON_VALUE(value, '$.Price') AS DECIMAL(18,2)),
            Volume = CAST(JSON_VALUE(value, '$.Volume') AS BIGINT)
        FROM portfolio.Assets a
        CROSS APPLY OPENJSON(@PriceData) 
        WHERE a.AssetID = CAST(JSON_VALUE(value, '$.AssetID') AS INT);
        
        COMMIT;
        
        SELECT 'SUCCESS' AS Status, 'Bulk price update completed' AS Message;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE portfolio.sp_UpsertIndexDetails (
    @AssetID INT,
    @Country NVARCHAR(100),
    @Region NVARCHAR(50),
    @IndexType NVARCHAR(50),
    @ComponentCount INT = NULL
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate asset exists and is an index
        IF NOT EXISTS (
            SELECT 1 FROM portfolio.Assets 
            WHERE AssetID = @AssetID AND AssetType = 'Index'
        )
        BEGIN
            RAISERROR('Asset not found or is not an index', 16, 1);
            RETURN;
        END
        
        -- Upsert index details
        IF EXISTS (SELECT 1 FROM portfolio.IndexDetails WHERE AssetID = @AssetID)
        BEGIN
            UPDATE portfolio.IndexDetails 
            SET 
                Country = @Country,
                Region = @Region,
                IndexType = @IndexType,
                ComponentCount = @ComponentCount
            WHERE AssetID = @AssetID;
        END
        ELSE
        BEGIN
            INSERT INTO portfolio.IndexDetails (AssetID, Country, Region, IndexType, ComponentCount)
            VALUES (@AssetID, @Country, @Region, @IndexType, @ComponentCount);
        END
        
        SELECT 'SUCCESS' AS Status, 'Index details updated successfully' AS Message;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

PRINT 'Specific asset procedures created successfully!';



IF EXISTS (
    SELECT 1
    FROM sys.procedures
    WHERE
        schema_id = SCHEMA_ID ('portfolio')
        AND name = 'sp_import_asset_price'
)
BEGIN
DROP PROCEDURE portfolio.sp_import_asset_price;

PRINT 'Existing sp_import_asset_price procedure dropped for recreation.';

END

-- Recreate the stored procedure with ChangePercent parameter
CREATE OR ALTER PROCEDURE portfolio.sp_import_asset_price
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

USE p6g4;
GO

-- Create or update index details
CREATE PROCEDURE portfolio.sp_UpsertIndexDetails (
    @AssetID INT,
    @Country NVARCHAR(100),
    @Region NVARCHAR(50),
    @IndexType NVARCHAR(50),
    @ComponentCount INT = NULL
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate asset exists and is an index
        IF NOT EXISTS (
            SELECT 1 FROM portfolio.Assets 
            WHERE AssetID = @AssetID AND AssetType = 'Index'
        )
        BEGIN
            RAISERROR('Asset not found or is not an index', 16, 1);
            RETURN;
        END
        
        -- Upsert index details
        IF EXISTS (SELECT 1 FROM portfolio.IndexDetails WHERE AssetID = @AssetID)
        BEGIN
            UPDATE portfolio.IndexDetails 
            SET 
                Country = @Country,
                Region = @Region,
                IndexType = @IndexType,
                ComponentCount = @ComponentCount
            WHERE AssetID = @AssetID;
        END
        ELSE
        BEGIN
            INSERT INTO portfolio.IndexDetails (AssetID, Country, Region, IndexType, ComponentCount)
            VALUES (@AssetID, @Country, @Region, @IndexType, @ComponentCount);
        END
        
        SELECT 'SUCCESS' AS Status, 'Index details updated successfully' AS Message;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

PRINT 'Index management procedures created successfully!';
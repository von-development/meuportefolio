/* ============================================================
meuPortfolio – Index Management Procedures v2.0
Index details management for market indices
============================================================ */

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

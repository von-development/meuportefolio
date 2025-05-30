/* ------------------------------------------------------------
meuPortfolio – Import Asset Price Procedure (v2024-03-21)
------------------------------------------------------------ */

USE meuportefolio;
GO

CREATE OR ALTER PROCEDURE portfolio.sp_import_asset_price
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
            
        -- Atualiza o preço atual se solicitado
        IF @UpdateCurrentPrice = 1
        BEGIN
            UPDATE portfolio.Assets 
            SET 
                Price = @Price,
                Volume = @Volume,
                LastUpdated = GETDATE()
            WHERE AssetID = @AssetID;
        END;
        
        -- Insere o preço histórico se não existir
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
        END;
        
        COMMIT TRANSACTION;
        RETURN 0;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        -- Relança o erro para o chamador
        THROW;
        RETURN 1;
    END CATCH;
END;
GO 
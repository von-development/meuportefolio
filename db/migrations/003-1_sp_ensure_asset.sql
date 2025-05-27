/* ------------------------------------------------------------
meuPortfolio – Ensure Asset Exists Procedure (v2024-03-21)
------------------------------------------------------------ */

USE meuportefolio;
GO

CREATE OR ALTER PROCEDURE portfolio.sp_ensure_asset
    @Symbol NVARCHAR(20),
    @Name NVARCHAR(100),
    @AssetType NVARCHAR(20),
    @InitialPrice DECIMAL(18,2) = 0.00,
    @InitialVolume BIGINT = 0,
    @AvailableShares DECIMAL(18,6) = 0.00,
    @AssetID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verifica se o ativo já existe
    SELECT @AssetID = AssetID 
    FROM portfolio.Assets 
    WHERE Symbol = @Symbol;
    
    -- Se não existe, cria
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
            @Symbol,
            @Name,
            @AssetType,
            @InitialPrice,
            @InitialVolume,
            @AvailableShares
        );
        
        SET @AssetID = SCOPE_IDENTITY();
    END;
    
    -- Retorna o ID do ativo
    RETURN 0;
END;
GO 
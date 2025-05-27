/* ------------------------------------------------------------
meuPortfolio – Stored Procedures  (v2025-05-24)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
1. User Management
============================================================ */
CREATE PROCEDURE portfolio.sp_CreateUser (
    @Name NVARCHAR(100),
    @Email NVARCHAR(100),
    @PasswordHash CHAR(60),
    @CountryOfResidence NVARCHAR(100),
    @IBAN NVARCHAR(34),
    @UserType NVARCHAR(20)
) AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserID UNIQUEIDENTIFIER = NEWID();
    
    INSERT INTO portfolio.Users (
        UserID, Name, Email, PasswordHash, 
        CountryOfResidence, IBAN, UserType
    )
    VALUES (
        @UserID, @Name, @Email, @PasswordHash,
        @CountryOfResidence, @IBAN, @UserType
    );
    
    SELECT @UserID AS UserID;
END;
GO

/* ============================================================
2. Portfolio Management
============================================================ */
CREATE PROCEDURE portfolio.sp_CreatePortfolio (
    @UserID UNIQUEIDENTIFIER,
    @Name NVARCHAR(100)
) AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO portfolio.Portfolios (UserID, Name)
    VALUES (@UserID, @Name);
    
    SELECT SCOPE_IDENTITY() AS PortfolioID;
END;
GO

/* ============================================================
3. Transaction Management
============================================================ */
CREATE PROCEDURE portfolio.sp_ExecuteTransaction (
    @UserID UNIQUEIDENTIFIER,
    @PortfolioID INT,
    @AssetID INT,
    @TransactionType NVARCHAR(10),
    @Quantity DECIMAL(18,6),
    @UnitPrice DECIMAL(18,4)
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
            
        INSERT INTO portfolio.Transactions (
            UserID, PortfolioID, AssetID,
            TransactionType, Quantity, UnitPrice
        )
        VALUES (
            @UserID, @PortfolioID, @AssetID,
            @TransactionType, @Quantity, @UnitPrice
        );
        
        UPDATE portfolio.Portfolios
        SET CurrentFunds = portfolio.fn_PortfolioMarketValue(@PortfolioID),
            CurrentProfitPct = portfolio.fn_PortfolioProfitPct(@PortfolioID),
            LastUpdated = SYSDATETIME()
        WHERE PortfolioID = @PortfolioID;
        
        COMMIT;
        SELECT SCOPE_IDENTITY() AS TransactionID;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH
END;
GO

/* ============================================================
4. Asset Price Management
============================================================ */
CREATE PROCEDURE portfolio.sp_UpdateAssetPrice (
    @AssetID INT,
    @NewPrice DECIMAL(18,2)
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        INSERT INTO portfolio.AssetPrices (AssetID, Price)
        VALUES (@AssetID, @NewPrice);
        
        UPDATE portfolio.Assets
        SET Price = @NewPrice,
            LastUpdated = SYSDATETIME()
        WHERE AssetID = @AssetID;
        
        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;
        THROW;
    END CATCH
END;
GO 
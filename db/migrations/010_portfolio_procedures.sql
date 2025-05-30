/* ------------------------------------------------------------
meuPortfolio – Portfolio Stored Procedures (v2025-05-30)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
Create Portfolio Management Stored Procedures
============================================================ */

-- Drop existing procedures if they exist
DROP PROCEDURE IF EXISTS portfolio.sp_CreatePortfolio;
DROP PROCEDURE IF EXISTS portfolio.sp_UpdatePortfolio;
GO

-- Create Portfolio procedure
CREATE PROCEDURE portfolio.sp_CreatePortfolio (
    @UserID UNIQUEIDENTIFIER,
    @Name NVARCHAR(100),
    @InitialFunds DECIMAL(18,2) = 0
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Check if user exists
        IF NOT EXISTS (SELECT 1 FROM portfolio.Users WHERE UserID = @UserID)
        BEGIN
            RAISERROR('User does not exist', 16, 1);
            RETURN;
        END
        
        -- Validate portfolio name
        IF @Name IS NULL OR LTRIM(RTRIM(@Name)) = ''
        BEGIN
            RAISERROR('Portfolio name is required', 16, 1);
            RETURN;
        END
        
        -- Validate initial funds (should be non-negative)
        IF @InitialFunds < 0
        BEGIN
            RAISERROR('Initial funds cannot be negative', 16, 1);
            RETURN;
        END
        
        -- Create the portfolio
        DECLARE @PortfolioID INT;
        
        INSERT INTO portfolio.Portfolios (
            UserID, 
            Name, 
            CurrentFunds, 
            CreationDate, 
            LastUpdated
        )
        VALUES (
            @UserID, 
            LTRIM(RTRIM(@Name)), 
            @InitialFunds, 
            SYSDATETIME(), 
            SYSDATETIME()
        );
        
        SET @PortfolioID = SCOPE_IDENTITY();
        
        -- Return the created portfolio
        SELECT 
            PortfolioID,
            UserID,
            Name,
            CreationDate,
            CurrentFunds,
            CurrentProfitPct,
            LastUpdated
        FROM portfolio.Portfolios 
        WHERE PortfolioID = @PortfolioID;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- Update Portfolio procedure
CREATE PROCEDURE portfolio.sp_UpdatePortfolio (
    @PortfolioID INT,
    @Name NVARCHAR(100) = NULL,
    @CurrentFunds DECIMAL(18,2) = NULL
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Check if portfolio exists
        IF NOT EXISTS (SELECT 1 FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID)
        BEGIN
            RAISERROR('Portfolio not found', 16, 1);
            RETURN;
        END
        
        -- Check if any fields are provided for update
        IF @Name IS NULL AND @CurrentFunds IS NULL
        BEGIN
            RAISERROR('No fields to update', 16, 1);
            RETURN;
        END
        
        -- Validate name if provided
        IF @Name IS NOT NULL AND LTRIM(RTRIM(@Name)) = ''
        BEGIN
            RAISERROR('Portfolio name cannot be empty', 16, 1);
            RETURN;
        END
        
        -- Validate funds if provided
        IF @CurrentFunds IS NOT NULL AND @CurrentFunds < 0
        BEGIN
            RAISERROR('Current funds cannot be negative', 16, 1);
            RETURN;
        END
        
        -- Perform the update with only non-null fields
        UPDATE portfolio.Portfolios 
        SET 
            Name = COALESCE(LTRIM(RTRIM(@Name)), Name),
            CurrentFunds = COALESCE(@CurrentFunds, CurrentFunds),
            LastUpdated = SYSDATETIME()
        WHERE PortfolioID = @PortfolioID;
        
        -- Check if update actually affected any rows
        IF @@ROWCOUNT = 0
        BEGIN
            RAISERROR('Portfolio not found after update', 16, 1);
            RETURN;
        END
        
        -- Return the updated portfolio data
        SELECT 
            PortfolioID,
            UserID,
            Name,
            CreationDate,
            CurrentFunds,
            CurrentProfitPct,
            LastUpdated
        FROM portfolio.Portfolios 
        WHERE PortfolioID = @PortfolioID;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

PRINT 'Portfolio stored procedures created successfully'; 
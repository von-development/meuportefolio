/* ============================================================
meuPortfolio – Portfolio & Fund Management Procedures v2.0
Portfolio operations and fund management system
============================================================ */

USE meuportefolio;
GO

/* ============================================================
1. PORTFOLIO MANAGEMENT
============================================================ */

-- Create new portfolio (enhanced with validations)
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

-- Update portfolio information
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
            CurrentFunds = COALESCE(@CurrentFunds, CurrentFunds)
            -- LastUpdated will be set automatically by trigger
        WHERE PortfolioID = @PortfolioID;
        
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

/* ============================================================
2. FUND MANAGEMENT - USER ACCOUNT
============================================================ */

-- Deposit funds to user account
CREATE PROCEDURE portfolio.sp_DepositFunds (
    @UserID UNIQUEIDENTIFIER,
    @Amount DECIMAL(18,2),
    @Description NVARCHAR(255) = NULL
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate amount
        IF @Amount <= 0
        BEGIN
            RAISERROR('Deposit amount must be positive', 16, 1);
            RETURN;
        END
        
        -- Check if user exists
        IF NOT EXISTS (SELECT 1 FROM portfolio.Users WHERE UserID = @UserID)
        BEGIN
            RAISERROR('User not found', 16, 1);
            RETURN;
        END
        
        -- Update user balance
        UPDATE portfolio.Users 
        SET AccountBalance = AccountBalance + @Amount
        WHERE UserID = @UserID;
        
        -- Get new balance for audit
        DECLARE @NewBalance DECIMAL(18,2);
        SELECT @NewBalance = AccountBalance FROM portfolio.Users WHERE UserID = @UserID;
        
        -- Record transaction
        INSERT INTO portfolio.FundTransactions (
            UserID, TransactionType, Amount, BalanceAfter, Description
        ) VALUES (
            @UserID, 'Deposit', @Amount, @NewBalance, COALESCE(@Description, 'Account deposit')
        );
        
        COMMIT;
        
        -- Return success with new balance
        SELECT 
            'SUCCESS' AS Status,
            @Amount AS AmountDeposited,
            @NewBalance AS NewBalance;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Withdraw funds from user account
CREATE PROCEDURE portfolio.sp_WithdrawFunds (
    @UserID UNIQUEIDENTIFIER,
    @Amount DECIMAL(18,2),
    @Description NVARCHAR(255) = NULL
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate amount
        IF @Amount <= 0
        BEGIN
            RAISERROR('Withdrawal amount must be positive', 16, 1);
            RETURN;
        END
        
        -- Check current balance
        DECLARE @CurrentBalance DECIMAL(18,2);
        SELECT @CurrentBalance = AccountBalance 
        FROM portfolio.Users 
        WHERE UserID = @UserID;
        
        IF @CurrentBalance IS NULL
        BEGIN
            RAISERROR('User not found', 16, 1);
            RETURN;
        END
        
        IF @CurrentBalance < @Amount
        BEGIN
            RAISERROR('Insufficient funds for withdrawal', 16, 1);
            RETURN;
        END
        
        -- Update user balance
        UPDATE portfolio.Users 
        SET AccountBalance = AccountBalance - @Amount
        WHERE UserID = @UserID;
        
        -- Get new balance for audit
        DECLARE @NewBalance DECIMAL(18,2);
        SELECT @NewBalance = AccountBalance FROM portfolio.Users WHERE UserID = @UserID;
        
        -- Record transaction
        INSERT INTO portfolio.FundTransactions (
            UserID, TransactionType, Amount, BalanceAfter, Description
        ) VALUES (
            @UserID, 'Withdrawal', -@Amount, @NewBalance, COALESCE(@Description, 'Account withdrawal')
        );
        
        COMMIT;
        
        -- Return success with new balance
        SELECT 
            'SUCCESS' AS Status,
            @Amount AS AmountWithdrawn,
            @NewBalance AS NewBalance;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

/* ============================================================
3. FUND MANAGEMENT - PORTFOLIO ALLOCATION
============================================================ */

-- Allocate funds from user account to portfolio
CREATE PROCEDURE portfolio.sp_AllocateFunds (
    @UserID UNIQUEIDENTIFIER,
    @PortfolioID INT,
    @Amount DECIMAL(18,2)
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate amount
        IF @Amount <= 0
        BEGIN
            RAISERROR('Allocation amount must be positive', 16, 1);
            RETURN;
        END
        
        -- Check if portfolio belongs to user
        IF NOT EXISTS (
            SELECT 1 FROM portfolio.Portfolios 
            WHERE PortfolioID = @PortfolioID AND UserID = @UserID
        )
        BEGIN
            RAISERROR('Portfolio not found or does not belong to user', 16, 1);
            RETURN;
        END
        
        -- Check user balance
        DECLARE @CurrentBalance DECIMAL(18,2);
        SELECT @CurrentBalance = AccountBalance 
        FROM portfolio.Users 
        WHERE UserID = @UserID;
        
        IF @CurrentBalance < @Amount
        BEGIN
            RAISERROR('Insufficient account balance for allocation', 16, 1);
            RETURN;
        END
        
        -- Update user balance (decrease)
        UPDATE portfolio.Users 
        SET AccountBalance = AccountBalance - @Amount
        WHERE UserID = @UserID;
        
        -- Update portfolio funds (increase)
        UPDATE portfolio.Portfolios 
        SET CurrentFunds = CurrentFunds + @Amount
        WHERE PortfolioID = @PortfolioID;
        
        -- Get new balances
        DECLARE @NewUserBalance DECIMAL(18,2), @NewPortfolioFunds DECIMAL(18,2);
        SELECT @NewUserBalance = AccountBalance FROM portfolio.Users WHERE UserID = @UserID;
        SELECT @NewPortfolioFunds = CurrentFunds FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID;
        
        -- Record transaction
        INSERT INTO portfolio.FundTransactions (
            UserID, PortfolioID, TransactionType, Amount, BalanceAfter, Description
        ) VALUES (
            @UserID, @PortfolioID, 'Allocation', -@Amount, @NewUserBalance, 
            'Funds allocated to portfolio'
        );
        
        COMMIT;
        
        -- Return success with balances
        SELECT 
            'SUCCESS' AS Status,
            @Amount AS AmountAllocated,
            @NewUserBalance AS NewUserBalance,
            @NewPortfolioFunds AS NewPortfolioFunds;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Deallocate funds from portfolio back to user account
CREATE PROCEDURE portfolio.sp_DeallocateFunds (
    @UserID UNIQUEIDENTIFIER,
    @PortfolioID INT,
    @Amount DECIMAL(18,2)
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate amount
        IF @Amount <= 0
        BEGIN
            RAISERROR('Deallocation amount must be positive', 16, 1);
            RETURN;
        END
        
        -- Check if portfolio belongs to user
        IF NOT EXISTS (
            SELECT 1 FROM portfolio.Portfolios 
            WHERE PortfolioID = @PortfolioID AND UserID = @UserID
        )
        BEGIN
            RAISERROR('Portfolio not found or does not belong to user', 16, 1);
            RETURN;
        END
        
        -- Check portfolio funds
        DECLARE @CurrentPortfolioFunds DECIMAL(18,2);
        SELECT @CurrentPortfolioFunds = CurrentFunds 
        FROM portfolio.Portfolios 
        WHERE PortfolioID = @PortfolioID;
        
        IF @CurrentPortfolioFunds < @Amount
        BEGIN
            RAISERROR('Insufficient portfolio funds for deallocation', 16, 1);
            RETURN;
        END
        
        -- Update portfolio funds (decrease)
        UPDATE portfolio.Portfolios 
        SET CurrentFunds = CurrentFunds - @Amount
        WHERE PortfolioID = @PortfolioID;
        
        -- Update user balance (increase)
        UPDATE portfolio.Users 
        SET AccountBalance = AccountBalance + @Amount
        WHERE UserID = @UserID;
        
        -- Get new balances
        DECLARE @NewUserBalance DECIMAL(18,2), @NewPortfolioFunds DECIMAL(18,2);
        SELECT @NewUserBalance = AccountBalance FROM portfolio.Users WHERE UserID = @UserID;
        SELECT @NewPortfolioFunds = CurrentFunds FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID;
        
        -- Record transaction
        INSERT INTO portfolio.FundTransactions (
            UserID, PortfolioID, TransactionType, Amount, BalanceAfter, Description
        ) VALUES (
            @UserID, @PortfolioID, 'Deallocation', @Amount, @NewUserBalance, 
            'Funds deallocated from portfolio'
        );
        
        COMMIT;
        
        -- Return success with balances
        SELECT 
            'SUCCESS' AS Status,
            @Amount AS AmountDeallocated,
            @NewUserBalance AS NewUserBalance,
            @NewPortfolioFunds AS NewPortfolioFunds;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

/* ============================================================
4. ACCOUNT SUMMARY
============================================================ */

-- Get user account summary (balances, portfolios, recent transactions)
CREATE PROCEDURE portfolio.sp_GetAccountSummary (
    @UserID UNIQUEIDENTIFIER
) AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM portfolio.Users WHERE UserID = @UserID)
    BEGIN
        RAISERROR('User not found', 16, 1);
        RETURN;
    END
    
    -- User balance and basic info
    SELECT 
        UserID,
        Name,
        UserType,
        AccountBalance,
        IsPremium,
        PremiumEndDate
    FROM portfolio.Users 
    WHERE UserID = @UserID;
    
    -- Portfolio summary
    SELECT 
        PortfolioID,
        Name,
        CurrentFunds,
        CurrentProfitPct,
        CreationDate,
        LastUpdated
    FROM portfolio.Portfolios 
    WHERE UserID = @UserID
    ORDER BY CreationDate DESC;
    
    -- Recent fund transactions (last 10)
    SELECT TOP 10
        FundTransactionID,
        PortfolioID,
        TransactionType,
        Amount,
        BalanceAfter,
        Description,
        CreatedAt
    FROM portfolio.FundTransactions 
    WHERE UserID = @UserID
    ORDER BY CreatedAt DESC;
END;
GO

PRINT 'Portfolio and fund management procedures created successfully!';
PRINT '';
PRINT 'SUMMARY OF PORTFOLIO PROCEDURES CREATED:';
PRINT '✅ sp_CreatePortfolio - Create new portfolios with validation';
PRINT '✅ sp_UpdatePortfolio - Update portfolio information';
PRINT '✅ sp_DepositFunds - Deposit funds to user account';
PRINT '✅ sp_WithdrawFunds - Withdraw funds from user account';
PRINT '✅ sp_AllocateFunds - Move funds from user to portfolio';
PRINT '✅ sp_DeallocateFunds - Move funds from portfolio to user';
PRINT '✅ sp_GetAccountSummary - Complete account overview';
PRINT '';
PRINT 'FEATURES:';
PRINT '🚀 Complete fund management lifecycle';
PRINT '🚀 Automatic transaction logging and audit trail';
PRINT '🚀 Enhanced validation and error handling';
PRINT '🚀 Trigger-compatible for automatic timestamps'; 
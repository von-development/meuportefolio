/* ------------------------------------------------------------
meuPortfolio – Fund Management System (v2025-05-30)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
1. Add AccountBalance to Users Table
============================================================ */

-- Add AccountBalance field to Users table
ALTER TABLE portfolio.Users 
ADD AccountBalance DECIMAL(18,2) NOT NULL DEFAULT 0.00;
GO

-- Add constraint to ensure positive balance
ALTER TABLE portfolio.Users 
ADD CONSTRAINT CK_Users_AccountBalance_NonNegative 
CHECK (AccountBalance >= 0);
GO

/* ============================================================
2. Create Fund Transactions Audit Table
============================================================ */

CREATE TABLE portfolio.FundTransactions (
    FundTransactionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID UNIQUEIDENTIFIER NOT NULL REFERENCES portfolio.Users(UserID) ON DELETE CASCADE,
    PortfolioID INT NULL REFERENCES portfolio.Portfolios(PortfolioID),
    TransactionType NVARCHAR(20) NOT NULL CHECK (TransactionType IN ('Deposit', 'Withdrawal', 'Allocation', 'Deallocation', 'PremiumUpgrade', 'AssetPurchase', 'AssetSale')),
    Amount DECIMAL(18,2) NOT NULL,
    BalanceAfter DECIMAL(18,2) NOT NULL,
    Description NVARCHAR(255) NULL,
    RelatedAssetTransactionID BIGINT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT SYSDATETIME()
);
GO

-- Add index for performance
CREATE NONCLUSTERED INDEX IX_FundTransactions_UserID_Date 
ON portfolio.FundTransactions(UserID, CreatedAt DESC);
GO

/* ============================================================
3. Create Portfolio Holdings Table (for performance)
============================================================ */

CREATE TABLE portfolio.PortfolioHoldings (
    HoldingID BIGINT IDENTITY(1,1) PRIMARY KEY,
    PortfolioID INT NOT NULL REFERENCES portfolio.Portfolios(PortfolioID) ON DELETE CASCADE,
    AssetID INT NOT NULL REFERENCES portfolio.Assets(AssetID) ON DELETE CASCADE,
    QuantityHeld DECIMAL(18,6) NOT NULL,
    AveragePrice DECIMAL(18,4) NOT NULL,
    TotalCost DECIMAL(18,2) NOT NULL,
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT UK_PortfolioHoldings_Portfolio_Asset UNIQUE(PortfolioID, AssetID)
);
GO

-- Add constraint to ensure positive quantities
ALTER TABLE portfolio.PortfolioHoldings 
ADD CONSTRAINT CK_PortfolioHoldings_QuantityHeld_Positive 
CHECK (QuantityHeld > 0);
GO

/* ============================================================
4. Update Transactions Table Status
============================================================ */

-- Update the status constraint to include more statuses
ALTER TABLE portfolio.Transactions 
DROP CONSTRAINT IF EXISTS CK_Transactions_Status;
GO

ALTER TABLE portfolio.Transactions 
ADD CONSTRAINT CK_Transactions_Status 
CHECK (Status IN ('Pending', 'Executed', 'Failed', 'Cancelled'));
GO

/* ============================================================
5. Fund Management Stored Procedures
============================================================ */

-- Deposit Funds to User Account
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
        SET AccountBalance = AccountBalance + @Amount,
            UpdatedAt = SYSDATETIME()
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

-- Withdraw Funds from User Account
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
        SET AccountBalance = AccountBalance - @Amount,
            UpdatedAt = SYSDATETIME()
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

-- Allocate Funds from User Account to Portfolio
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
        SET AccountBalance = AccountBalance - @Amount,
            UpdatedAt = SYSDATETIME()
        WHERE UserID = @UserID;
        
        -- Update portfolio funds (increase)
        UPDATE portfolio.Portfolios 
        SET CurrentFunds = CurrentFunds + @Amount,
            LastUpdated = SYSDATETIME()
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
        
        -- Return success
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

-- Deallocate Funds from Portfolio back to User Account
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
        SET CurrentFunds = CurrentFunds - @Amount,
            LastUpdated = SYSDATETIME()
        WHERE PortfolioID = @PortfolioID;
        
        -- Update user balance (increase)
        UPDATE portfolio.Users 
        SET AccountBalance = AccountBalance + @Amount,
            UpdatedAt = SYSDATETIME()
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
        
        -- Return success
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

-- Upgrade to Premium (deduct from user balance)
CREATE PROCEDURE portfolio.sp_UpgradeToPremium (
    @UserID UNIQUEIDENTIFIER,
    @SubscriptionMonths INT = 1,
    @MonthlyRate DECIMAL(18,2) = 50.00
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Calculate total cost
        DECLARE @TotalCost DECIMAL(18,2) = @SubscriptionMonths * @MonthlyRate;
        
        -- Check if user exists and is not already premium
        DECLARE @CurrentUserType NVARCHAR(20), @CurrentBalance DECIMAL(18,2);
        SELECT @CurrentUserType = UserType, @CurrentBalance = AccountBalance
        FROM portfolio.Users 
        WHERE UserID = @UserID;
        
        IF @CurrentUserType IS NULL
        BEGIN
            RAISERROR('User not found', 16, 1);
            RETURN;
        END
        
        IF @CurrentUserType = 'Premium'
        BEGIN
            RAISERROR('User is already Premium', 16, 1);
            RETURN;
        END
        
        IF @CurrentBalance < @TotalCost
        BEGIN
            RAISERROR('Insufficient account balance for Premium upgrade', 16, 1);
            RETURN;
        END
        
        -- Update user to Premium and deduct cost
        UPDATE portfolio.Users 
        SET UserType = 'Premium',
            AccountBalance = AccountBalance - @TotalCost,
            UpdatedAt = SYSDATETIME()
        WHERE UserID = @UserID;
        
        -- Create subscription record
        INSERT INTO portfolio.Subscriptions (
            UserID, StartDate, EndDate, AmountPaid, PaymentStatus
        ) VALUES (
            @UserID, 
            SYSDATETIME(), 
            DATEADD(MONTH, @SubscriptionMonths, SYSDATETIME()),
            @TotalCost,
            'Completed'
        );
        
        -- Get new balance
        DECLARE @NewBalance DECIMAL(18,2);
        SELECT @NewBalance = AccountBalance FROM portfolio.Users WHERE UserID = @UserID;
        
        -- Record transaction
        INSERT INTO portfolio.FundTransactions (
            UserID, TransactionType, Amount, BalanceAfter, Description
        ) VALUES (
            @UserID, 'PremiumUpgrade', -@TotalCost, @NewBalance, 
            CONCAT('Premium subscription for ', @SubscriptionMonths, ' months')
        );
        
        COMMIT;
        
        -- Return success
        SELECT 
            'SUCCESS' AS Status,
            @TotalCost AS AmountPaid,
            @SubscriptionMonths AS SubscriptionMonths,
            @NewBalance AS NewBalance;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

PRINT 'Fund management system created successfully!';
PRINT 'Added AccountBalance to Users table';
PRINT 'Created FundTransactions audit table';
PRINT 'Created PortfolioHoldings table';
PRINT 'Created stored procedures: sp_DepositFunds, sp_WithdrawFunds, sp_AllocateFunds, sp_DeallocateFunds, sp_UpgradeToPremium'; 
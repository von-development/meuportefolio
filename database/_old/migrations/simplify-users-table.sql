/* ============================================================
SIMPLIFY USERS TABLE - ADD PAYMENT & SUBSCRIPTION FIELDS
============================================================ */

USE meuportefolio;
GO

-- Add payment method and subscription fields directly to Users table
ALTER TABLE portfolio.Users 
ADD 
    -- Payment Method Fields (one per user)
    PaymentMethodType NVARCHAR(30) NULL,              -- 'CreditCard', 'BankTransfer', 'PayPal', etc.
    PaymentMethodDetails NVARCHAR(255) NULL,          -- 'VISA ****4582', 'Bank of America', etc.
    PaymentMethodExpiry DATE NULL,                    -- For credit cards
    PaymentMethodActive BIT DEFAULT 1,                -- Whether payment method is active
    
    -- Subscription Fields (current subscription only)
    IsPremium BIT DEFAULT 0,                          -- Simple boolean flag
    PremiumStartDate DATETIME NULL,                   -- When premium started
    PremiumEndDate DATETIME NULL,                     -- When premium expires
    MonthlySubscriptionRate DECIMAL(18,2) DEFAULT 50.00,  -- Current monthly rate
    AutoRenewSubscription BIT DEFAULT 1,              -- Auto renewal setting
    LastSubscriptionPayment DATETIME NULL,           -- Last payment date
    NextSubscriptionPayment DATETIME NULL;           -- Next payment due date
GO

-- Add constraints for data integrity
ALTER TABLE portfolio.Users 
ADD CONSTRAINT CK_Users_PaymentMethodType 
CHECK (PaymentMethodType IN ('CreditCard', 'BankTransfer', 'PayPal', 'Other') OR PaymentMethodType IS NULL);

ALTER TABLE portfolio.Users 
ADD CONSTRAINT CK_Users_SubscriptionLogic 
CHECK (
    (IsPremium = 0) OR 
    (IsPremium = 1 AND PremiumStartDate IS NOT NULL AND PremiumEndDate IS NOT NULL)
);

ALTER TABLE portfolio.Users 
ADD CONSTRAINT CK_Users_SubscriptionRate_Positive 
CHECK (MonthlySubscriptionRate > 0);
GO

-- Migrate existing data from separate tables (if they exist)
-- First, migrate payment methods (take the default one for each user)
UPDATE u 
SET 
    PaymentMethodType = CASE 
        WHEN pm.MethodType LIKE '%Credit Card%' THEN 'CreditCard'
        WHEN pm.MethodType LIKE '%Bank%' THEN 'BankTransfer'
        WHEN pm.MethodType LIKE '%PayPal%' THEN 'PayPal'
        ELSE 'Other'
    END,
    PaymentMethodDetails = pm.Details,
    PaymentMethodExpiry = pm.ValidationDate,
    PaymentMethodActive = CASE WHEN pm.Status = 'Active' THEN 1 ELSE 0 END
FROM portfolio.Users u
INNER JOIN portfolio.PaymentMethods pm ON pm.UserID = u.UserID
WHERE pm.IsDefault = 1;  -- Only take the default payment method

-- Migrate subscription data (take the active/completed subscription)
UPDATE u 
SET 
    IsPremium = CASE WHEN u.UserType = 'Premium' THEN 1 ELSE 0 END,
    PremiumStartDate = s.StartDate,
    PremiumEndDate = s.EndDate,
    MonthlySubscriptionRate = CASE 
        WHEN s.AmountPaid > 0 THEN s.AmountPaid 
        ELSE 50.00 
    END,
    LastSubscriptionPayment = s.StartDate,
    NextSubscriptionPayment = CASE 
        WHEN s.EndDate > SYSDATETIME() THEN s.EndDate
        ELSE NULL 
    END,
    AutoRenewSubscription = 1
FROM portfolio.Users u
INNER JOIN portfolio.Subscriptions s ON s.UserID = u.UserID
WHERE s.PaymentStatus = 'Completed';

-- Set IsPremium based on UserType for users without subscription records
UPDATE portfolio.Users 
SET IsPremium = CASE WHEN UserType = 'Premium' THEN 1 ELSE 0 END
WHERE IsPremium IS NULL;

-- Set default values for NULL fields
UPDATE portfolio.Users 
SET 
    IsPremium = ISNULL(IsPremium, 0),
    PaymentMethodActive = ISNULL(PaymentMethodActive, 1),
    MonthlySubscriptionRate = ISNULL(MonthlySubscriptionRate, 50.00),
    AutoRenewSubscription = ISNULL(AutoRenewSubscription, 1);

GO

-- Create simple stored procedures for the new unified approach

-- Set/Update User Payment Method
CREATE OR ALTER PROCEDURE portfolio.sp_SetUserPaymentMethod (
    @UserID UNIQUEIDENTIFIER,
    @PaymentMethodType NVARCHAR(30),
    @PaymentMethodDetails NVARCHAR(255),
    @PaymentMethodExpiry DATE = NULL
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate user exists
        IF NOT EXISTS (SELECT 1 FROM portfolio.Users WHERE UserID = @UserID)
        BEGIN
            RAISERROR('User not found', 16, 1);
            RETURN;
        END
        
        -- Update payment method
        UPDATE portfolio.Users 
        SET 
            PaymentMethodType = @PaymentMethodType,
            PaymentMethodDetails = @PaymentMethodDetails,
            PaymentMethodExpiry = @PaymentMethodExpiry,
            PaymentMethodActive = 1,
            UpdatedAt = SYSDATETIME()
        WHERE UserID = @UserID;
        
        SELECT 'SUCCESS' AS Status, 'Payment method updated successfully' AS Message;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- Manage Premium Subscription (Activate, Renew, Cancel)
CREATE OR ALTER PROCEDURE portfolio.sp_ManageSubscription (
    @UserID UNIQUEIDENTIFIER,
    @Action NVARCHAR(20), -- 'ACTIVATE', 'RENEW', 'CANCEL'
    @MonthsToAdd INT = 1,
    @MonthlyRate DECIMAL(18,2) = 50.00
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Check if user exists
        DECLARE @CurrentBalance DECIMAL(18,2), @CurrentUserType NVARCHAR(20);
        SELECT @CurrentBalance = AccountBalance, @CurrentUserType = UserType
        FROM portfolio.Users WHERE UserID = @UserID;
        
        IF @CurrentUserType IS NULL
        BEGIN
            RAISERROR('User not found', 16, 1);
            RETURN;
        END
        
        IF @Action = 'ACTIVATE' OR @Action = 'RENEW'
        BEGIN
            DECLARE @TotalCost DECIMAL(18,2) = @MonthsToAdd * @MonthlyRate;
            
            -- Check sufficient balance
            IF @CurrentBalance < @TotalCost
            BEGIN
                RAISERROR('Insufficient account balance for subscription', 16, 1);
                RETURN;
            END
            
            -- Deduct cost from user balance
            UPDATE portfolio.Users 
            SET AccountBalance = AccountBalance - @TotalCost
            WHERE UserID = @UserID;
            
            -- Update subscription info
            UPDATE portfolio.Users 
            SET 
                UserType = 'Premium',
                IsPremium = 1,
                PremiumStartDate = CASE 
                    WHEN IsPremium = 0 OR PremiumStartDate IS NULL THEN SYSDATETIME() 
                    ELSE PremiumStartDate 
                END,
                PremiumEndDate = CASE 
                    WHEN IsPremium = 0 OR PremiumEndDate IS NULL OR PremiumEndDate <= SYSDATETIME() 
                    THEN DATEADD(MONTH, @MonthsToAdd, SYSDATETIME())
                    ELSE DATEADD(MONTH, @MonthsToAdd, PremiumEndDate)
                END,
                MonthlySubscriptionRate = @MonthlyRate,
                LastSubscriptionPayment = SYSDATETIME(),
                NextSubscriptionPayment = CASE 
                    WHEN IsPremium = 0 OR PremiumEndDate IS NULL OR PremiumEndDate <= SYSDATETIME() 
                    THEN DATEADD(MONTH, @MonthsToAdd, SYSDATETIME())
                    ELSE DATEADD(MONTH, @MonthsToAdd, PremiumEndDate)
                END,
                AutoRenewSubscription = 1,
                UpdatedAt = SYSDATETIME()
            WHERE UserID = @UserID;
            
            -- Record fund transaction
            INSERT INTO portfolio.FundTransactions (
                UserID, TransactionType, Amount, 
                BalanceAfter, Description
            ) VALUES (
                @UserID, 'PremiumUpgrade', -@TotalCost,
                (SELECT AccountBalance FROM portfolio.Users WHERE UserID = @UserID),
                CONCAT('Premium subscription - ', @MonthsToAdd, ' months at $', @MonthlyRate, '/month')
            );
            
            SELECT 
                'SUCCESS' AS Status, 
                @TotalCost AS AmountPaid, 
                @MonthsToAdd AS MonthsAdded,
                (SELECT AccountBalance FROM portfolio.Users WHERE UserID = @UserID) AS NewBalance;
        END
        ELSE IF @Action = 'CANCEL'
        BEGIN
            UPDATE portfolio.Users 
            SET 
                UserType = 'Basic',
                IsPremium = 0,
                AutoRenewSubscription = 0,
                UpdatedAt = SYSDATETIME()
            WHERE UserID = @UserID;
            
            SELECT 'SUCCESS' AS Status, 'Subscription cancelled successfully' AS Message;
        END
        ELSE
        BEGIN
            RAISERROR('Invalid action. Use ACTIVATE, RENEW, or CANCEL', 16, 1);
            RETURN;
        END
        
        COMMIT;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

-- Get Complete User Info (including payment and subscription)
CREATE OR ALTER PROCEDURE portfolio.sp_GetUserCompleteInfo (
    @UserID UNIQUEIDENTIFIER
) AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        UserID,
        Name,
        Email,
        CountryOfResidence,
        IBAN,
        UserType,
        AccountBalance,
        
        -- Payment Method Info
        PaymentMethodType,
        PaymentMethodDetails,
        PaymentMethodExpiry,
        PaymentMethodActive,
        
        -- Subscription Info
        IsPremium,
        PremiumStartDate,
        PremiumEndDate,
        MonthlySubscriptionRate,
        AutoRenewSubscription,
        LastSubscriptionPayment,
        NextSubscriptionPayment,
        
        -- Calculated Fields
        CASE 
            WHEN IsPremium = 1 AND PremiumEndDate > SYSDATETIME() 
            THEN DATEDIFF(DAY, SYSDATETIME(), PremiumEndDate)
            ELSE 0
        END AS DaysRemainingInSubscription,
        
        CASE 
            WHEN IsPremium = 1 AND PremiumEndDate <= SYSDATETIME() 
            THEN 1 ELSE 0
        END AS SubscriptionExpired,
        
        CreatedAt,
        UpdatedAt
    FROM portfolio.Users
    WHERE UserID = @UserID;
END;
GO

-- Now we can safely drop the old tables (optional - keep for now as backup)
-- DROP TABLE IF EXISTS portfolio.PaymentMethods;
-- DROP TABLE IF EXISTS portfolio.Subscriptions;

PRINT 'Users table simplified successfully!';
PRINT '';
PRINT 'SUMMARY OF CHANGES:';
PRINT '✅ Added payment method fields to Users table:';
PRINT '   • PaymentMethodType, PaymentMethodDetails, PaymentMethodExpiry, PaymentMethodActive';
PRINT '✅ Added subscription fields to Users table:';
PRINT '   • IsPremium, PremiumStartDate, PremiumEndDate, MonthlySubscriptionRate';
PRINT '   • AutoRenewSubscription, LastSubscriptionPayment, NextSubscriptionPayment';
PRINT '✅ Migrated existing data from PaymentMethods and Subscriptions tables';
PRINT '✅ Created simple stored procedures:';
PRINT '   • sp_SetUserPaymentMethod - Manage user payment method';
PRINT '   • sp_ManageSubscription - Activate/renew/cancel subscription';
PRINT '   • sp_GetUserCompleteInfo - Get all user info in one call';
PRINT '';
PRINT 'BENEFITS:';
PRINT '🚀 Much simpler - everything in one table';
PRINT '🚀 Better performance - no complex joins needed';
PRINT '🚀 Easier API development - one endpoint covers everything';
PRINT '🚀 One payment method per user (covers 95% of use cases)';
PRINT '🚀 Focus on current subscription state, not history'; 
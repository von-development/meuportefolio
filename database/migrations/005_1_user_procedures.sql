/* ============================================================
meuPortfolio – User Management Procedures v2.0
User authentication, profile management, payment & subscription
============================================================ */

USE p6g4;
GO

/* ============================================================
1. USER AUTHENTICATION & CREATION
============================================================ */

-- Create new user (updated for v2 structure)
CREATE PROCEDURE portfolio.sp_CreateUser (
    @Name NVARCHAR(100),
    @Email NVARCHAR(100),
    @Password NVARCHAR(100),  -- Plain text for development (v2 change)
    @CountryOfResidence NVARCHAR(100),
    @IBAN NVARCHAR(34),
    @UserType NVARCHAR(20) = 'Basic'
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Validate inputs
        IF @Name IS NULL OR LTRIM(RTRIM(@Name)) = ''
        BEGIN
            RAISERROR('Name is required', 16, 1);
            RETURN;
        END
        
        IF @Email IS NULL OR LTRIM(RTRIM(@Email)) = ''
        BEGIN
            RAISERROR('Email is required', 16, 1);
            RETURN;
        END
        
        -- Check if email already exists
        IF EXISTS (SELECT 1 FROM portfolio.Users WHERE Email = @Email)
        BEGIN
            RAISERROR('Email already exists', 16, 1);
            RETURN;
        END
        
        DECLARE @UserID UNIQUEIDENTIFIER = NEWID();
        
        INSERT INTO portfolio.Users (
            UserID, Name, Email, Password, 
            CountryOfResidence, IBAN, UserType
        )
        VALUES (
            @UserID, LTRIM(RTRIM(@Name)), LTRIM(RTRIM(@Email)), @Password,
            @CountryOfResidence, @IBAN, @UserType
        );
        
        -- Return the created user info
        SELECT 
            @UserID AS UserID,
            @Name AS Name,
            @Email AS Email,
            @UserType AS UserType,
            SYSDATETIME() AS CreatedAt;
            
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- Update user information (trigger-compatible)
CREATE PROCEDURE portfolio.sp_UpdateUser (
    @UserID UNIQUEIDENTIFIER,
    @Name NVARCHAR(100) = NULL,
    @Email NVARCHAR(100) = NULL,
    @Password NVARCHAR(100) = NULL,
    @CountryOfResidence NVARCHAR(100) = NULL,
    @IBAN NVARCHAR(34) = NULL,
    @UserType NVARCHAR(20) = NULL
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Check if user exists
        IF NOT EXISTS (SELECT 1 FROM portfolio.Users WHERE UserID = @UserID)
        BEGIN
            RAISERROR('User not found', 16, 1);
            RETURN;
        END
        
        -- If email is being updated, check for duplicates
        IF @Email IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM portfolio.Users WHERE Email = @Email AND UserID != @UserID)
            BEGIN
                RAISERROR('Email already exists', 16, 1);
                RETURN;
            END
        END
        
        -- Check if any fields are provided for update
        IF @Name IS NULL AND @Email IS NULL AND @Password IS NULL 
           AND @CountryOfResidence IS NULL AND @IBAN IS NULL AND @UserType IS NULL
        BEGIN
            RAISERROR('No fields to update', 16, 1);
            RETURN;
        END
        
        -- Perform the update with only non-null fields
        UPDATE portfolio.Users 
        SET 
            Name = COALESCE(LTRIM(RTRIM(@Name)), Name),
            Email = COALESCE(LTRIM(RTRIM(@Email)), Email),
            Password = COALESCE(@Password, Password),
            CountryOfResidence = COALESCE(@CountryOfResidence, CountryOfResidence),
            IBAN = COALESCE(@IBAN, IBAN),
            UserType = COALESCE(@UserType, UserType)
            -- Note: UpdatedAt will be set automatically by the trigger
        WHERE UserID = @UserID;
        
        -- Return the updated user data
        SELECT 
            UserID,
            Name,
            Email,
            CountryOfResidence,
            IBAN,
            UserType,
            AccountBalance,
            CreatedAt,
            UpdatedAt
        FROM portfolio.Users 
        WHERE UserID = @UserID;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

/* ============================================================
2. PAYMENT METHOD MANAGEMENT
============================================================ */

-- Set or update user payment method
CREATE PROCEDURE portfolio.sp_SetUserPaymentMethod (
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
        
        -- Validate payment method type
        IF @PaymentMethodType NOT IN ('CreditCard', 'BankTransfer', 'PayPal', 'Other')
        BEGIN
            RAISERROR('Invalid payment method type', 16, 1);
            RETURN;
        END
        
        -- Update payment method
        UPDATE portfolio.Users 
        SET 
            PaymentMethodType = @PaymentMethodType,
            PaymentMethodDetails = @PaymentMethodDetails,
            PaymentMethodExpiry = @PaymentMethodExpiry,
            PaymentMethodActive = 1
            -- UpdatedAt will be set automatically by trigger
        WHERE UserID = @UserID;
        
        SELECT 'SUCCESS' AS Status, 'Payment method updated successfully' AS Message;
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

/* ============================================================
3. SUBSCRIPTION MANAGEMENT
============================================================ */

-- Manage premium subscription (activate, renew, cancel)
CREATE PROCEDURE portfolio.sp_ManageSubscription (
    @UserID UNIQUEIDENTIFIER,
    @Action NVARCHAR(20), -- 'ACTIVATE', 'RENEW', 'CANCEL'
    @MonthsToAdd INT = 1,
    @MonthlyRate DECIMAL(18,2) = 50.00
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Validate action
        IF @Action NOT IN ('ACTIVATE', 'RENEW', 'CANCEL')
        BEGIN
            RAISERROR('Invalid action. Use ACTIVATE, RENEW, or CANCEL', 16, 1);
            RETURN;
        END
        
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
            -- Validate parameters
            IF @MonthsToAdd <= 0
            BEGIN
                RAISERROR('Months to add must be positive', 16, 1);
                RETURN;
            END
            
            IF @MonthlyRate <= 0
            BEGIN
                RAISERROR('Monthly rate must be positive', 16, 1);
                RETURN;
            END
            
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
                AutoRenewSubscription = 1
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
                AutoRenewSubscription = 0
            WHERE UserID = @UserID;
            
            SELECT 'SUCCESS' AS Status, 'Subscription cancelled successfully' AS Message;
        END
        
        COMMIT;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
GO

/* ============================================================
4. USER DATA RETRIEVAL
============================================================ */

-- Get complete user information (v2 with payment & subscription)
CREATE PROCEDURE portfolio.sp_GetUserCompleteInfo (
    @UserID UNIQUEIDENTIFIER
) AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM portfolio.Users WHERE UserID = @UserID)
    BEGIN
        RAISERROR('User not found', 16, 1);
        RETURN;
    END
    
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
        CAST(PaymentMethodActive AS BIT) AS PaymentMethodActive,
        
        -- Subscription Info
        CAST(IsPremium AS BIT) AS IsPremium,
        PremiumStartDate,
        PremiumEndDate,
        MonthlySubscriptionRate,
        CAST(AutoRenewSubscription AS BIT) AS AutoRenewSubscription,
        LastSubscriptionPayment,
        NextSubscriptionPayment,
        
        -- Calculated Fields
        CASE 
            WHEN IsPremium = 1 AND PremiumEndDate > SYSDATETIME() 
            THEN DATEDIFF(DAY, SYSDATETIME(), PremiumEndDate)
            ELSE 0
        END AS DaysRemainingInSubscription,
        
        CAST(CASE 
            WHEN IsPremium = 1 AND PremiumEndDate <= SYSDATETIME() 
            THEN 1 ELSE 0
        END AS BIT) AS SubscriptionExpired,
        
        CreatedAt,
        UpdatedAt
    FROM portfolio.Users
    WHERE UserID = @UserID;
END;
GO

PRINT 'User management procedures created successfully!';
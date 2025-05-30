/* ------------------------------------------------------------
Fix Boolean Fields in sp_GetUserCompleteInfo
------------------------------------------------------------ */

USE meuportefolio;
GO

-- Fix the stored procedure to properly cast boolean fields
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

PRINT 'sp_GetUserCompleteInfo procedure updated with proper boolean casting!'; 
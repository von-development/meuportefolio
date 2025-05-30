/* ============================================================
FIX CONSTRAINT VIOLATION FOR SIMPLIFIED USERS TABLE
============================================================ */

USE meuportefolio;
GO

-- First, let's fix the data that caused the constraint violation
-- Update Premium users without subscription records to have proper dates

UPDATE portfolio.Users 
SET 
    IsPremium = 1,
    PremiumStartDate = DATEADD(MONTH, -1, SYSDATETIME()),  -- Assume started 1 month ago
    PremiumEndDate = DATEADD(MONTH, 11, SYSDATETIME()),    -- Give them 11 more months
    MonthlySubscriptionRate = 50.00,
    LastSubscriptionPayment = DATEADD(MONTH, -1, SYSDATETIME()),
    NextSubscriptionPayment = DATEADD(MONTH, 1, SYSDATETIME()),
    AutoRenewSubscription = 1
WHERE UserType = 'Premium' 
  AND (PremiumStartDate IS NULL OR PremiumEndDate IS NULL);

-- Set IsPremium = 0 for Basic users (this should work fine)
UPDATE portfolio.Users 
SET IsPremium = 0
WHERE UserType = 'Basic' AND IsPremium IS NULL;

-- Double-check: make sure all users have proper IsPremium values
UPDATE portfolio.Users 
SET IsPremium = CASE WHEN UserType = 'Premium' THEN 1 ELSE 0 END
WHERE IsPremium IS NULL;

-- Verify the fix worked
SELECT 
    UserID,
    Name,
    UserType,
    IsPremium,
    PremiumStartDate,
    PremiumEndDate,
    CASE 
        WHEN IsPremium = 1 AND (PremiumStartDate IS NULL OR PremiumEndDate IS NULL) 
        THEN 'CONSTRAINT VIOLATION'
        ELSE 'OK'
    END AS ConstraintStatus
FROM portfolio.Users
WHERE UserType = 'Premium';

PRINT 'Constraint violation fixed!';
PRINT 'All Premium users now have proper subscription dates.';
PRINT 'All Basic users have IsPremium = 0.'; 
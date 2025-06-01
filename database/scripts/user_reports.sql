/* ============================================================
meuPortfolio - User Management & Reports
Quick queries for user administration and statistics
============================================================ */

USE p6g4;
GO

PRINT '============================================================';
PRINT 'USER MANAGEMENT & REPORTS';
PRINT '============================================================';

-- 1. USER OVERVIEW
PRINT '';
PRINT ' USER OVERVIEW:';
SELECT 
    UserType,
    IsPremium,
    COUNT(*) AS UserCount,
    AVG(AccountBalance) AS AvgAccountBalance,
    SUM(AccountBalance) AS TotalAccountBalance
FROM portfolio.Users
GROUP BY UserType, IsPremium
ORDER BY UserType, IsPremium;

-- 2. PREMIUM SUBSCRIPTION STATUS
PRINT '';
PRINT ' PREMIUM SUBSCRIPTION STATUS:';
SELECT 
    Name,
    Email,
    UserType,
    IsPremium,
    PremiumStartDate,
    PremiumEndDate,
    CASE 
        WHEN IsPremium = 1 AND PremiumEndDate > SYSDATETIME() THEN 'Active'
        WHEN IsPremium = 1 AND PremiumEndDate <= SYSDATETIME() THEN 'Expired'
        ELSE 'Not Premium'
    END AS SubscriptionStatus,
    CASE 
        WHEN IsPremium = 1 AND PremiumEndDate > SYSDATETIME() 
        THEN DATEDIFF(DAY, SYSDATETIME(), PremiumEndDate)
        ELSE 0
    END AS DaysRemaining
FROM portfolio.Users
WHERE IsPremium = 1
ORDER BY PremiumEndDate;

-- 3. TOP USERS BY NET WORTH
PRINT '';
PRINT ' TOP 10 USERS BY NET WORTH:';
SELECT TOP 10
    u.Name,
    u.Email,
    u.UserType,
    u.AccountBalance,
    portfolio.fn_UserNetWorth(u.UserID) AS TotalNetWorth
FROM portfolio.Users u
ORDER BY portfolio.fn_UserNetWorth(u.UserID) DESC;

-- 4. USERS WITH MULTIPLE PORTFOLIOS
PRINT '';
PRINT ' USERS WITH MULTIPLE PORTFOLIOS:';
SELECT 
    u.Name,
    u.Email,
    COUNT(p.PortfolioID) AS PortfolioCount,
    SUM(p.CurrentFunds) AS TotalPortfolioFunds
FROM portfolio.Users u
JOIN portfolio.Portfolios p ON p.UserID = u.UserID
GROUP BY u.UserID, u.Name, u.Email
HAVING COUNT(p.PortfolioID) > 1
ORDER BY COUNT(p.PortfolioID) DESC;

-- 5. RECENT USER ACTIVITY
PRINT '';
PRINT ' RECENT USER ACTIVITY (Last 30 days):';
SELECT 
    u.Name,
    u.Email,
    MAX(ft.CreatedAt) AS LastFundTransaction,
    MAX(t.TransactionDate) AS LastTrade
FROM portfolio.Users u
LEFT JOIN portfolio.FundTransactions ft ON ft.UserID = u.UserID 
    AND ft.CreatedAt >= DATEADD(DAY, -30, SYSDATETIME())
LEFT JOIN portfolio.Transactions t ON t.UserID = u.UserID 
    AND t.TransactionDate >= DATEADD(DAY, -30, SYSDATETIME())
WHERE ft.CreatedAt IS NOT NULL OR t.TransactionDate IS NOT NULL
GROUP BY u.UserID, u.Name, u.Email
ORDER BY COALESCE(MAX(ft.CreatedAt), MAX(t.TransactionDate)) DESC;

PRINT '';
PRINT ' User reports completed!'; 
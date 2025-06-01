/* ============================================================
meuPortfolio - Quick Utility Queries
Fast, common queries for daily database operations
============================================================ */

USE p6g4;
GO

PRINT '============================================================';
PRINT 'QUICK UTILITY QUERIES - MEUPORTEFOLIO';
PRINT '============================================================';

-- Quick table counts
PRINT '';
PRINT ' QUICK TABLE COUNTS:';
SELECT 'Users' AS TableName, COUNT(*) AS RowCount FROM portfolio.Users
UNION ALL SELECT 'Portfolios', COUNT(*) FROM portfolio.Portfolios
UNION ALL SELECT 'Assets', COUNT(*) FROM portfolio.Assets
UNION ALL SELECT 'Holdings', COUNT(*) FROM portfolio.PortfolioHoldings
UNION ALL SELECT 'Transactions', COUNT(*) FROM portfolio.Transactions
UNION ALL SELECT 'FundTransactions', COUNT(*) FROM portfolio.FundTransactions
UNION ALL SELECT 'RiskMetrics', COUNT(*) FROM portfolio.RiskMetrics
UNION ALL SELECT 'ApplicationLogs', COUNT(*) FROM portfolio.ApplicationLogs;

-- Recent activity summary
PRINT '';
PRINT ' RECENT ACTIVITY (Today):';
SELECT 
    'New Users' AS ActivityType,
    COUNT(*) AS Count
FROM portfolio.Users 
WHERE CAST(CreatedAt AS DATE) = CAST(SYSDATETIME() AS DATE)

UNION ALL

SELECT 
    'Today Transactions' AS ActivityType,
    COUNT(*) AS Count
FROM portfolio.Transactions 
WHERE CAST(TransactionDate AS DATE) = CAST(SYSDATETIME() AS DATE)

UNION ALL

SELECT 
    'Today Fund Movements' AS ActivityType,
    COUNT(*) AS Count
FROM portfolio.FundTransactions 
WHERE CAST(CreatedAt AS DATE) = CAST(SYSDATETIME() AS DATE);

-- System health indicators
PRINT '';
PRINT ' SYSTEM HEALTH INDICATORS:';
SELECT 
    'Total Platform Value' AS Metric,
    FORMAT(SUM(AccountBalance), 'C') AS Value
FROM portfolio.Users

UNION ALL

SELECT 
    'Total Portfolios' AS Metric,
    FORMAT(COUNT(*), 'N0') AS Value
FROM portfolio.Portfolios

UNION ALL

SELECT 
    'Active Premium Users' AS Metric,
    FORMAT(COUNT(*), 'N0') AS Value
FROM portfolio.Users 
WHERE IsPremium = 1 AND PremiumEndDate > SYSDATETIME()

UNION ALL

SELECT 
    'Available Assets' AS Metric,
    FORMAT(COUNT(*), 'N0') AS Value
FROM portfolio.Assets;

PRINT '';
PRINT ' Quick queries completed!';

-- ============================================================
-- COMMON QUICK QUERIES (Copy and paste as needed)
-- ============================================================

PRINT '';
PRINT '📝 COMMON QUICK QUERIES:';
PRINT '';
PRINT '-- Find user by email:';
PRINT '-- SELECT * FROM portfolio.Users WHERE Email = ''user@example.com'';';
PRINT '';
PRINT '-- Get user portfolio summary:';
PRINT '-- SELECT * FROM portfolio.vw_PortfolioSummary WHERE OwnerName = ''User Name'';';
PRINT '';
PRINT '-- Check portfolio holdings:';
PRINT '-- SELECT * FROM portfolio.vw_PortfolioHoldings WHERE PortfolioID = 1;';
PRINT '';
PRINT '-- Recent transactions:';
PRINT '-- SELECT * FROM portfolio.Transactions WHERE TransactionDate >= DATEADD(DAY, -7, SYSDATETIME()) ORDER BY TransactionDate DESC;';
PRINT '';
PRINT '-- Asset search:';
PRINT '-- SELECT * FROM portfolio.Assets WHERE Symbol LIKE ''%BTC%'' OR Name LIKE ''%Bitcoin%'';';
PRINT '';
PRINT '-- User net worth:';
PRINT '-- SELECT Name, portfolio.fn_UserNetWorth(UserID) AS NetWorth FROM portfolio.Users ORDER BY portfolio.fn_UserNetWorth(UserID) DESC;'; 
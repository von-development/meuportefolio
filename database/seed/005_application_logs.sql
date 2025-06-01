/* ============================================================
meuPortfolio - Application Logs and System Events
Creates application logs for system monitoring (transactions are handled by procedures)
============================================================ */

USE p6g4;
GO

BEGIN TRANSACTION;

PRINT 'Creating application logs and system events...';

-- ============================================================
-- NOTE: Fund Transactions and Asset Transactions are now handled automatically by:
-- - sp_DepositFunds (creates fund transactions)
-- - sp_AllocateFunds (creates fund transactions) 
-- - sp_BuyAsset (creates both asset transactions and fund transactions)
-- - sp_SellAsset (creates both asset transactions and fund transactions)
-- 
-- This file now only creates sample application logs for system monitoring
-- ============================================================

-- User variables for reference (get from database)
DECLARE @MariaUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'maria.silva@email.com');
DECLARE @JoaoUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'joao.santos@email.com');
DECLARE @AnaUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'ana.costa@gmail.com');
DECLARE @CarlosUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'carlos.oliveira@hotmail.com');
DECLARE @IsabellaUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'isabella.rodriguez@yahoo.com');
DECLARE @ThomasUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'thomas.mueller@gmail.de');
DECLARE @SophieUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'sophie.dubois@orange.fr');
DECLARE @JamesUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'james.wilson@btinternet.com');
DECLARE @LucaUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'luca.rossi@libero.it');
DECLARE @EmmaUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'emma.johnson@rogers.ca');

-- ============================================================
-- APPLICATION LOGS (System Events and Monitoring)
-- ============================================================

INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, UserID, Message, CreatedAt) VALUES 

-- User account creation events
('INFO', 'INSERT', 'Users', @MariaUserID, 'New user account created: Maria Silva (Portugal)', DATEADD(day, -90, SYSDATETIME())),
('INFO', 'INSERT', 'Users', @JoaoUserID, 'New premium user account created: João Santos (Portugal)', DATEADD(day, -60, SYSDATETIME())),
('INFO', 'INSERT', 'Users', @AnaUserID, 'New user account created: Ana Costa (Portugal)', DATEADD(day, -120, SYSDATETIME())),
('INFO', 'INSERT', 'Users', @CarlosUserID, 'New user account created: Carlos Oliveira (Brazil)', DATEADD(day, -45, SYSDATETIME())),
('INFO', 'INSERT', 'Users', @IsabellaUserID, 'High net worth user registered: Isabella Rodriguez (USA)', DATEADD(day, -180, SYSDATETIME())),
('INFO', 'INSERT', 'Users', @ThomasUserID, 'New user account created: Thomas Mueller (Germany)', DATEADD(day, -15, SYSDATETIME())),
('INFO', 'INSERT', 'Users', @SophieUserID, 'New user account created: Sophie Dubois (France)', DATEADD(day, -75, SYSDATETIME())),
('INFO', 'INSERT', 'Users', @JamesUserID, 'New user account created: James Wilson (UK)', DATEADD(day, -20, SYSDATETIME())),
('INFO', 'INSERT', 'Users', @LucaUserID, 'New user account created: Luca Rossi (Italy)', DATEADD(day, -45, SYSDATETIME())),
('INFO', 'INSERT', 'Users', @EmmaUserID, 'New user account created: Emma Johnson (Canada)', DATEADD(day, -10, SYSDATETIME())),

-- Portfolio creation events
('INFO', 'INSERT', 'Portfolios', @MariaUserID, 'Portfolio created: Crescimento Conservador', DATEADD(day, -85, SYSDATETIME())),
('INFO', 'INSERT', 'Portfolios', @JoaoUserID, 'Portfolio created: Carteira Diversificada', DATEADD(day, -55, SYSDATETIME())),
('INFO', 'INSERT', 'Portfolios', @JoaoUserID, 'Portfolio created: Cripto & Commodities', DATEADD(day, -25, SYSDATETIME())),
('INFO', 'INSERT', 'Portfolios', @AnaUserID, 'Portfolio created: Rendimento & Dividendos', DATEADD(day, -115, SYSDATETIME())),
('INFO', 'INSERT', 'Portfolios', @IsabellaUserID, 'Portfolio created: Mercado Americano', DATEADD(day, -175, SYSDATETIME())),

-- Premium subscription events
('INFO', 'UPDATE', 'Users', @JoaoUserID, 'Premium subscription activated', DATEADD(day, -30, SYSDATETIME())),
('INFO', 'UPDATE', 'Users', @AnaUserID, 'Premium subscription activated', DATEADD(day, -120, SYSDATETIME())),
('INFO', 'UPDATE', 'Users', @IsabellaUserID, 'Premium subscription activated', DATEADD(day, -180, SYSDATETIME())),
('INFO', 'UPDATE', 'Users', @SophieUserID, 'Premium subscription activated', DATEADD(day, -75, SYSDATETIME())),
('INFO', 'UPDATE', 'Users', @LucaUserID, 'Premium subscription activated', DATEADD(day, -45, SYSDATETIME())),

-- Large transaction events
('INFO', 'TRANSACTION', 'FundTransactions', @JoaoUserID, 'Large deposit processed: €15,800', DATEADD(day, -50, SYSDATETIME())),
('INFO', 'TRANSACTION', 'FundTransactions', @IsabellaUserID, 'Large deposit processed: $32,500', DATEADD(day, -180, SYSDATETIME())),
('INFO', 'TRANSACTION', 'FundTransactions', @SophieUserID, 'Large deposit processed: €18,800', DATEADD(day, -75, SYSDATETIME())),
('INFO', 'TRANSACTION', 'FundTransactions', @LucaUserID, 'Large deposit processed: €12,350', DATEADD(day, -45, SYSDATETIME())),

-- Asset trading events
('INFO', 'TRANSACTION', 'Transactions', @JoaoUserID, 'Large position acquired: AAPL (45 shares)', DATEADD(day, -50, SYSDATETIME())),
('INFO', 'TRANSACTION', 'Transactions', @IsabellaUserID, 'High-value trade executed: AAPL (85 shares)', DATEADD(day, -170, SYSDATETIME())),
('INFO', 'TRANSACTION', 'Transactions', @SophieUserID, 'European index purchase: DAX', DATEADD(day, -65, SYSDATETIME())),
('INFO', 'TRANSACTION', 'Transactions', @AnaUserID, 'Dividend stock purchase: GALP (350 shares)', DATEADD(day, -95, SYSDATETIME())),

-- Crypto trading warnings
('WARN', 'TRANSACTION', 'Transactions', @JamesUserID, 'Crypto transaction with high volatility: BTC', DATEADD(day, -18, SYSDATETIME())),
('WARN', 'TRANSACTION', 'Transactions', @JoaoUserID, 'Large crypto allocation detected: ETH', DATEADD(day, -35, SYSDATETIME())),
('WARN', 'TRANSACTION', 'Transactions', @AnaUserID, 'Speculative crypto trade: DOGE', DATEADD(day, -25, SYSDATETIME())),

-- Risk calculation events
('INFO', 'SELECT', 'RiskMetrics', @JoaoUserID, 'Risk metrics calculated successfully', DATEADD(day, -30, SYSDATETIME())),
('INFO', 'SELECT', 'RiskMetrics', @AnaUserID, 'Conservative risk profile confirmed', DATEADD(day, -35, SYSDATETIME())),
('INFO', 'SELECT', 'RiskMetrics', @IsabellaUserID, 'Aggressive risk profile detected', DATEADD(day, -45, SYSDATETIME())),
('INFO', 'SELECT', 'RiskMetrics', @SophieUserID, 'Moderate risk profile with commodity exposure', DATEADD(day, -25, SYSDATETIME())),
('INFO', 'SELECT', 'RiskMetrics', @LucaUserID, 'Balanced risk profile maintained', DATEADD(day, -20, SYSDATETIME())),

-- System events and errors
('ERROR', 'TRANSACTION', 'Transactions', @CarlosUserID, 'Transaction failed due to insufficient funds', DATEADD(day, -22, SYSDATETIME())),
('WARN', 'SELECT', 'AssetPrices', NULL, 'High volume price queries detected during market hours', DATEADD(hour, -2, SYSDATETIME())),
('ERROR', 'TRANSACTION', 'FundTransactions', @ThomasUserID, 'Payment method validation failed', DATEADD(day, -8, SYSDATETIME())),
('WARN', 'UPDATE', 'Assets', NULL, 'Asset price update delayed for crypto markets', DATEADD(hour, -6, SYSDATETIME())),
('INFO', 'SELECT', 'PortfolioHoldings', NULL, 'Bulk portfolio valuation completed', DATEADD(hour, -1, SYSDATETIME())),

-- Login and security events
('INFO', 'LOGIN', 'Users', @JoaoUserID, 'Premium user login from Portugal', DATEADD(hour, -3, SYSDATETIME())),
('INFO', 'LOGIN', 'Users', @IsabellaUserID, 'High net worth user login from USA', DATEADD(hour, -8, SYSDATETIME())),
('WARN', 'LOGIN', 'Users', @JamesUserID, 'Multiple failed login attempts detected', DATEADD(day, -5, SYSDATETIME())),
('INFO', 'LOGIN', 'Users', @SophieUserID, 'Mobile app login from France', DATEADD(hour, -12, SYSDATETIME())),

-- Performance monitoring
('INFO', 'SELECT', 'AssetPrices', NULL, 'Daily asset price synchronization completed', DATEADD(hour, -24, SYSDATETIME())),
('WARN', 'SELECT', 'Portfolios', NULL, 'Portfolio performance calculation took longer than expected', DATEADD(day, -1, SYSDATETIME())),
('INFO', 'UPDATE', 'PortfolioHoldings', NULL, 'Automated holdings rebalancing completed', DATEADD(day, -7, SYSDATETIME()));

PRINT 'Created comprehensive application logs for system monitoring';
PRINT '';

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

PRINT '=== APPLICATION LOGS SUMMARY ===';
SELECT 
    LogLevel,
    EventType,
    COUNT(*) as EventCount,
    MIN(CreatedAt) as EarliestEvent,
    MAX(CreatedAt) as LatestEvent
FROM portfolio.ApplicationLogs
GROUP BY LogLevel, EventType
ORDER BY EventCount DESC;

PRINT '';
PRINT '=== RECENT SYSTEM EVENTS ===';
SELECT TOP 10
    LogLevel,
    EventType,
    TableName,
    Message,
    CreatedAt
FROM portfolio.ApplicationLogs
ORDER BY CreatedAt DESC;

PRINT '';
PRINT '=== ERROR AND WARNING SUMMARY ===';
SELECT 
    u.Name as UserName,
    al.LogLevel,
    al.Message,
    al.CreatedAt
FROM portfolio.ApplicationLogs al
LEFT JOIN portfolio.Users u ON al.UserID = u.UserID
WHERE al.LogLevel IN ('ERROR', 'WARN')
ORDER BY al.CreatedAt DESC;

PRINT 'Application logs created successfully!';
PRINT '';
PRINT '*** NOTE: Transactions and Fund Transactions are now automatically created by stored procedures ***';
PRINT 'Fund management: sp_DepositFunds, sp_WithdrawFunds, sp_AllocateFunds, sp_DeallocateFunds';
PRINT 'Asset trading: sp_BuyAsset, sp_SellAsset';
PRINT 'All procedures create proper audit trails automatically.';

COMMIT TRANSACTION; 
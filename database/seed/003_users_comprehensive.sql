/* ============================================================
meuPortfolio - Comprehensive User Seed Data
Creates realistic sample users using stored procedures
============================================================ */

USE p6g4;
GO

BEGIN TRANSACTION;

PRINT 'Creating comprehensive user seed data using stored procedures...';

-- ============================================================
-- CLEANUP EXISTING SAMPLE USERS (PREVENT DUPLICATES ON RE-RUN)
-- ============================================================

PRINT 'Cleaning up existing sample users to prevent duplicates...';

-- Define sample user emails for cleanup
DECLARE @SampleUserEmails TABLE (Email NVARCHAR(100));
INSERT INTO @SampleUserEmails VALUES 
('maria.silva@email.com'),
('joao.santos@email.com'),
('ana.costa@gmail.com'),
('carlos.oliveira@hotmail.com'),
('isabella.rodriguez@yahoo.com'),
('thomas.mueller@gmail.de'),
('sophie.dubois@orange.fr'),
('james.wilson@btinternet.com'),
('luca.rossi@libero.it'),
('emma.johnson@rogers.ca');

-- Delete all related data for sample users (foreign key constraints order)
-- 1. Portfolio Holdings
DELETE ph FROM portfolio.PortfolioHoldings ph
INNER JOIN portfolio.Portfolios p ON ph.PortfolioID = p.PortfolioID
INNER JOIN portfolio.Users u ON p.UserID = u.UserID
INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

-- 2. Transactions
DELETE t FROM portfolio.Transactions t
INNER JOIN portfolio.Users u ON t.UserID = u.UserID
INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

-- 3. Fund Transactions
DELETE ft FROM portfolio.FundTransactions ft
INNER JOIN portfolio.Users u ON ft.UserID = u.UserID
INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

-- 4. Risk Metrics
DELETE rm FROM portfolio.RiskMetrics rm
INNER JOIN portfolio.Users u ON rm.UserID = u.UserID
INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

-- 5. Application Logs (optional - keep for audit trail)
-- DELETE al FROM portfolio.ApplicationLogs al
-- INNER JOIN portfolio.Users u ON al.UserID = u.UserID
-- INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

-- 6. Portfolios
DELETE p FROM portfolio.Portfolios p
INNER JOIN portfolio.Users u ON p.UserID = u.UserID
INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

-- 7. Finally, delete users
DELETE u FROM portfolio.Users u
INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

PRINT 'Cleanup completed - existing sample users and all related data removed';
PRINT '';

-- ============================================================
-- SAMPLE USERS CREATION USING STORED PROCEDURES
-- ============================================================

DECLARE @UserID UNIQUEIDENTIFIER;

-- User 1: Maria Silva (Basic - Portugal)
EXEC portfolio.sp_CreateUser 
    @Name = 'Maria Silva',
    @Email = 'maria.silva@email.com',
    @Password = 'senha123',
    @CountryOfResidence = 'Portugal',
    @IBAN = 'PT50000201231234567890154',
    @UserType = 'Basic';

-- Get the created UserID for further setup
SELECT @UserID = UserID FROM portfolio.Users WHERE Email = 'maria.silva@email.com';

-- Deposit initial funds
EXEC portfolio.sp_DepositFunds @UserID, 3200.00, 'Initial account setup';

-- Set payment method
EXEC portfolio.sp_SetUserPaymentMethod @UserID, 'CreditCard', 'VISA ****4582', '2027-12-31';

PRINT 'Created user: Maria Silva (Basic)';

-- User 2: João Santos (Premium - Portugal)
EXEC portfolio.sp_CreateUser 
    @Name = 'João Santos',
    @Email = 'joao.santos@email.com',
    @Password = 'senha123',
    @CountryOfResidence = 'Portugal',
    @IBAN = 'PT50003300000045445557772',
    @UserType = 'Basic'; -- Start as Basic, then upgrade

SELECT @UserID = UserID FROM portfolio.Users WHERE Email = 'joao.santos@email.com';

-- Deposit funds and upgrade to premium
EXEC portfolio.sp_DepositFunds @UserID, 16300.00, 'Initial premium account funding';  -- Increased for portfolio needs
EXEC portfolio.sp_SetUserPaymentMethod @UserID, 'BankTransfer', 'Caixa Geral de Depósitos', NULL;
EXEC portfolio.sp_ManageSubscription @UserID, 'ACTIVATE', 12, 50.00; -- 12 months premium

PRINT 'Created user: João Santos (Premium)';

-- User 3: Ana Costa (Premium - Portugal)
EXEC portfolio.sp_CreateUser 
    @Name = 'Ana Costa',
    @Email = 'ana.costa@gmail.com',
    @Password = 'senha123',
    @CountryOfResidence = 'Portugal',
    @IBAN = 'PT50001801231234567890142',
    @UserType = 'Basic';

SELECT @UserID = UserID FROM portfolio.Users WHERE Email = 'ana.costa@gmail.com';

EXEC portfolio.sp_DepositFunds @UserID, 9050.00, 'Initial premium account funding';  -- Increased for portfolio needs
EXEC portfolio.sp_SetUserPaymentMethod @UserID, 'PayPal', 'PayPal ****@gmail.com', NULL;
EXEC portfolio.sp_ManageSubscription @UserID, 'ACTIVATE', 12, 50.00;

PRINT 'Created user: Ana Costa (Premium)';

-- User 4: Carlos Oliveira (Basic - Brazil)
EXEC portfolio.sp_CreateUser 
    @Name = 'Carlos Oliveira',
    @Email = 'carlos.oliveira@hotmail.com',
    @Password = 'senha123',
    @CountryOfResidence = 'Brazil',
    @IBAN = 'BR1500000000000000001234567',
    @UserType = 'Basic';

SELECT @UserID = UserID FROM portfolio.Users WHERE Email = 'carlos.oliveira@hotmail.com';

EXEC portfolio.sp_DepositFunds @UserID, 800.00, 'Initial account setup';  -- Increased for portfolio needs
EXEC portfolio.sp_SetUserPaymentMethod @UserID, 'CreditCard', 'Mastercard ****7891', '2026-08-31';

PRINT 'Created user: Carlos Oliveira (Basic)';

-- User 5: Isabella Rodriguez (Premium - USA)
EXEC portfolio.sp_CreateUser 
    @Name = 'Isabella Rodriguez',
    @Email = 'isabella.rodriguez@yahoo.com',
    @Password = 'senha123',
    @CountryOfResidence = 'United States',
    @IBAN = 'US12345678901234567890',
    @UserType = 'Basic';

SELECT @UserID = UserID FROM portfolio.Users WHERE Email = 'isabella.rodriguez@yahoo.com';

EXEC portfolio.sp_DepositFunds @UserID, 32300.00, 'Initial high-value account funding';  -- Adjusted for portfolio needs
EXEC portfolio.sp_SetUserPaymentMethod @UserID, 'CreditCard', 'AMEX ****1007', '2028-03-31';
EXEC portfolio.sp_ManageSubscription @UserID, 'ACTIVATE', 12, 50.00;

PRINT 'Created user: Isabella Rodriguez (Premium)';

-- User 6: Thomas Mueller (Basic - Germany)
EXEC portfolio.sp_CreateUser 
    @Name = 'Thomas Mueller',
    @Email = 'thomas.mueller@gmail.de',
    @Password = 'senha123',
    @CountryOfResidence = 'Germany',
    @IBAN = 'DE89370400440532013000',
    @UserType = 'Basic';

SELECT @UserID = UserID FROM portfolio.Users WHERE Email = 'thomas.mueller@gmail.de';

EXEC portfolio.sp_DepositFunds @UserID, 1800.00, 'Initial account setup';  -- Increased for portfolio needs
EXEC portfolio.sp_SetUserPaymentMethod @UserID, 'BankTransfer', 'Deutsche Bank', NULL;

PRINT 'Created user: Thomas Mueller (Basic)';

-- User 7: Sophie Dubois (Premium - France)
EXEC portfolio.sp_CreateUser 
    @Name = 'Sophie Dubois',
    @Email = 'sophie.dubois@orange.fr',
    @Password = 'senha123',
    @CountryOfResidence = 'France',
    @IBAN = 'FR1420041010050500013M02606',
    @UserType = 'Basic';

SELECT @UserID = UserID FROM portfolio.Users WHERE Email = 'sophie.dubois@orange.fr';

EXEC portfolio.sp_DepositFunds @UserID, 19050.00, 'Initial premium account funding';  -- Increased for portfolio needs
EXEC portfolio.sp_SetUserPaymentMethod @UserID, 'CreditCard', 'VISA ****9876', '2027-06-30';
EXEC portfolio.sp_ManageSubscription @UserID, 'ACTIVATE', 12, 50.00;

PRINT 'Created user: Sophie Dubois (Premium)';

-- User 8: James Wilson (Basic - UK)
EXEC portfolio.sp_CreateUser 
    @Name = 'James Wilson',
    @Email = 'james.wilson@btinternet.com',
    @Password = 'senha123',
    @CountryOfResidence = 'United Kingdom',
    @IBAN = 'GB82WEST12345698765432',
    @UserType = 'Basic';

SELECT @UserID = UserID FROM portfolio.Users WHERE Email = 'james.wilson@btinternet.com';

EXEC portfolio.sp_DepositFunds @UserID, 850.00, 'Initial account setup';  -- Increased for portfolio needs
EXEC portfolio.sp_SetUserPaymentMethod @UserID, 'PayPal', 'PayPal ****@btinternet.com', NULL;

PRINT 'Created user: James Wilson (Basic)';

-- User 9: Luca Rossi (Premium - Italy)
EXEC portfolio.sp_CreateUser 
    @Name = 'Luca Rossi',
    @Email = 'luca.rossi@libero.it',
    @Password = 'senha123',
    @CountryOfResidence = 'Italy',
    @IBAN = 'IT60X0542811101000000123456',
    @UserType = 'Basic';

SELECT @UserID = UserID FROM portfolio.Users WHERE Email = 'luca.rossi@libero.it';

EXEC portfolio.sp_DepositFunds @UserID, 12050.00, 'Initial premium account funding';  -- Adjusted for portfolio needs
EXEC portfolio.sp_SetUserPaymentMethod @UserID, 'BankTransfer', 'UniCredit Banca', NULL;
EXEC portfolio.sp_ManageSubscription @UserID, 'ACTIVATE', 12, 50.00;

PRINT 'Created user: Luca Rossi (Premium)';

-- User 10: Emma Johnson (Basic - Canada)
EXEC portfolio.sp_CreateUser 
    @Name = 'Emma Johnson',
    @Email = 'emma.johnson@rogers.ca',
    @Password = 'senha123',
    @CountryOfResidence = 'Canada',
    @IBAN = 'CA12345678901234567890',
    @UserType = 'Basic';

SELECT @UserID = UserID FROM portfolio.Users WHERE Email = 'emma.johnson@rogers.ca';

EXEC portfolio.sp_DepositFunds @UserID, 1450.00, 'Initial account setup';  -- Increased for portfolio needs
EXEC portfolio.sp_SetUserPaymentMethod @UserID, 'CreditCard', 'VISA ****3456', '2026-11-30';

PRINT 'Created user: Emma Johnson (Basic)';

PRINT '';
PRINT 'Created 10 sample users (4 Basic, 6 Premium) from 8 different countries';

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

PRINT '';
PRINT '=== USER VERIFICATION ===';

-- Summary by user type
SELECT 
    UserType,
    COUNT(*) as UserCount,
    AVG(AccountBalance) as AvgBalance,
    SUM(AccountBalance) as TotalBalance
FROM portfolio.Users
GROUP BY UserType;

PRINT '';
PRINT '=== DETAILED USER INFORMATION ===';

-- Detailed user list
SELECT 
    Name,
    Email,
    UserType,
    CountryOfResidence,
    AccountBalance,
    IsPremium,
    PaymentMethodType,
    CASE 
        WHEN IsPremium = 1 THEN DATEDIFF(day, SYSDATETIME(), PremiumEndDate)
        ELSE NULL 
    END as DaysUntilPremiumExpiry
FROM portfolio.Users
ORDER BY UserType DESC, AccountBalance DESC;

PRINT 'User seed data created successfully using stored procedures!';

COMMIT TRANSACTION; 
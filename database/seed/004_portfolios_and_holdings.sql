/* ============================================================
meuPortfolio - Sample Portfolios and Holdings
Creates realistic portfolios and current holdings using stored procedures
============================================================ */

USE p6g4;
GO

BEGIN TRANSACTION;

PRINT 'Creating sample portfolios and holdings using stored procedures...';

-- ============================================================
-- CLEANUP EXISTING DATA (PREVENT DUPLICATES ON RE-RUN)
-- ============================================================

PRINT 'Cleaning up existing sample data to prevent duplicates...';

-- Get user IDs for cleanup
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

-- Delete existing portfolio holdings first (foreign key constraints)
DELETE ph FROM portfolio.PortfolioHoldings ph
INNER JOIN portfolio.Portfolios p ON ph.PortfolioID = p.PortfolioID
INNER JOIN portfolio.Users u ON p.UserID = u.UserID
INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

-- Delete existing transactions for sample users' portfolios
DELETE t FROM portfolio.Transactions t
INNER JOIN portfolio.Portfolios p ON t.PortfolioID = p.PortfolioID
INNER JOIN portfolio.Users u ON p.UserID = u.UserID
INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

-- Delete existing portfolios for sample users
DELETE p FROM portfolio.Portfolios p
INNER JOIN portfolio.Users u ON p.UserID = u.UserID
INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

-- Delete fund transactions for sample users (but keep user account balances)
DELETE ft FROM portfolio.FundTransactions ft
INNER JOIN portfolio.Users u ON ft.UserID = u.UserID
INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

-- Reset account balances to 0 for fresh start
UPDATE u SET AccountBalance = 0.00
FROM portfolio.Users u
INNER JOIN @SampleUserEmails sue ON u.Email = sue.Email;

PRINT 'Cleanup completed - existing sample portfolios and holdings removed';
PRINT '';

-- ============================================================
-- GET USER IDS BY EMAIL
-- ============================================================

-- Get user IDs by email (safer than hardcoded UUIDs)
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
-- ENSURE SUFFICIENT FUNDS - ADDITIONAL DEPOSITS IF NEEDED
-- ============================================================

PRINT 'Ensuring all users have sufficient funds for portfolio allocations...';

-- Check and ensure basic users have enough funds
DECLARE @CurrentBalance DECIMAL(18,2);

-- Maria Silva - ensure she has at least €3,200
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @MariaUserID;
PRINT 'Maria current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 3200.00
BEGIN
    EXEC portfolio.sp_DepositFunds @MariaUserID, 3200.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Maria account';
END

-- Carlos Oliveira - ensure he has at least €800
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @CarlosUserID;
PRINT 'Carlos current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 800.00
BEGIN
    EXEC portfolio.sp_DepositFunds @CarlosUserID, 800.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Carlos account';
END

-- Thomas Mueller - ensure he has at least €1,800
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @ThomasUserID;
PRINT 'Thomas current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 1800.00
BEGIN
    EXEC portfolio.sp_DepositFunds @ThomasUserID, 1800.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Thomas account';
END

-- James Wilson - ensure he has at least €850
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @JamesUserID;
PRINT 'James current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 850.00
BEGIN
    EXEC portfolio.sp_DepositFunds @JamesUserID, 850.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to James account';
END

-- Emma Johnson - ensure she has at least €1,450
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @EmmaUserID;
PRINT 'Emma current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 1450.00
BEGIN
    EXEC portfolio.sp_DepositFunds @EmmaUserID, 1450.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Emma account';
END

-- João Santos - ensure he has at least €16,000 (Premium user)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @JoaoUserID;
PRINT 'João current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 16000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @JoaoUserID, 16000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to João account';
END

-- Ana Costa - ensure she has at least €9,000 (Premium user)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @AnaUserID;
PRINT 'Ana current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 9000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @AnaUserID, 9000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Ana account';
END

-- Isabella Rodriguez - ensure she has at least €32,000 (Premium user)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @IsabellaUserID;
PRINT 'Isabella current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 32000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @IsabellaUserID, 32000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Isabella account';
END

-- Sophie Dubois - ensure she has at least €19,000 (Premium user)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @SophieUserID;
PRINT 'Sophie current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 19000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @SophieUserID, 19000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Sophie account';
END

-- Luca Rossi - ensure he has at least €12,000 (Premium user)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @LucaUserID;
PRINT 'Luca current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 12000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @LucaUserID, 12000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Luca account';
END

PRINT 'All users now have sufficient funds for portfolio allocations';
PRINT '';

-- ============================================================
-- CREATE PORTFOLIOS USING STORED PROCEDURES
-- ============================================================

DECLARE @PortfolioID INT;

-- Portfolio 1: Maria's Conservative Growth
EXEC portfolio.sp_CreatePortfolio @MariaUserID, 'Crescimento Conservador', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @MariaUserID AND Name = 'Crescimento Conservador');
EXEC portfolio.sp_AllocateFunds @MariaUserID, @PortfolioID, 3100.00;  -- Increased from 2400 to cover purchases
PRINT 'Created portfolio: Maria - Crescimento Conservador';
PRINT 'Maria portfolio allocated: €3,100.00 (needs ~€3,032 for purchases)';

PRINT 'Starting Maria portfolio purchases - Portfolio ID: ' + CAST(@PortfolioID AS VARCHAR(10));
SELECT 'Maria Portfolio After Allocation' as Info, CurrentFunds FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID;

PRINT 'Attempting purchase: AAPL - 12.5 shares at €185.25 = €2,315.63';
EXEC portfolio.sp_BuyAsset @MariaUserID, @PortfolioID, @AAPL_ID, 12.500000, 185.25;

-- Portfolio 2: Carlos's Brazilian Focus (Basic User)
EXEC portfolio.sp_CreatePortfolio @CarlosUserID, 'Foco Brasil', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @CarlosUserID AND Name = 'Foco Brasil');
EXEC portfolio.sp_AllocateFunds @CarlosUserID, @PortfolioID, 775.00;  -- Increased from 700 to cover purchases
PRINT 'Created portfolio: Carlos - Foco Brasil';
PRINT 'Carlos portfolio allocated: €775.00 (needs ~€775 for purchases)';

-- Portfolio 3: Thomas's European Stocks (Basic User)
EXEC portfolio.sp_CreatePortfolio @ThomasUserID, 'Ações Europeias', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @ThomasUserID AND Name = 'Ações Europeias');
EXEC portfolio.sp_AllocateFunds @ThomasUserID, @PortfolioID, 1760.00;  -- Increased from 1100 to cover purchases
PRINT 'Created portfolio: Thomas - Ações Europeias';
PRINT 'Thomas portfolio allocated: €1,760.00 (needs ~€1,758 for purchases)';

-- Portfolio 4: James's Crypto Starter (Basic User)
EXEC portfolio.sp_CreatePortfolio @JamesUserID, 'Cripto Iniciante', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JamesUserID AND Name = 'Cripto Iniciante');
EXEC portfolio.sp_AllocateFunds @JamesUserID, @PortfolioID, 830.00;  -- Increased from 420 to cover purchases
PRINT 'Created portfolio: James - Cripto Iniciante';
PRINT 'James portfolio allocated: €830.00 (needs ~€830 for purchases)';

-- Portfolio 5: Emma's Tech & Growth (Basic User)
EXEC portfolio.sp_CreatePortfolio @EmmaUserID, 'Tecnologia & Crescimento', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @EmmaUserID AND Name = 'Tecnologia & Crescimento');
EXEC portfolio.sp_AllocateFunds @EmmaUserID, @PortfolioID, 1410.00;  -- Increased from 950 to cover purchases
PRINT 'Created portfolio: Emma - Tecnologia & Crescimento';
PRINT 'Emma portfolio allocated: €1,410.00 (needs ~€1,408 for purchases)';

-- Portfolio 6: João's Diversified Portfolio (Premium User)
PRINT '=== Checking João Santos Balance ===';
SELECT 'João Balance Check' as Info, AccountBalance, IsPremium, PremiumEndDate 
FROM portfolio.Users WHERE UserID = @JoaoUserID;

EXEC portfolio.sp_CreatePortfolio @JoaoUserID, 'Carteira Diversificada', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JoaoUserID AND Name = 'Carteira Diversificada');
EXEC portfolio.sp_AllocateFunds @JoaoUserID, @PortfolioID, 14000.00;  -- Reduced from 14500 (account for subscription fees)
PRINT 'Created portfolio: João - Carteira Diversificada';

-- Portfolio 7: João's Crypto & Commodities (Premium User)
EXEC portfolio.sp_CreatePortfolio @JoaoUserID, 'Cripto & Commodities', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JoaoUserID AND Name = 'Cripto & Commodities');
EXEC portfolio.sp_AllocateFunds @JoaoUserID, @PortfolioID, 1200.00;  -- Reduced from 1250
PRINT 'Created portfolio: João - Cripto & Commodities';

-- Portfolio 8: Ana's Income & Dividend (Premium User)
PRINT '=== Checking Ana Costa Balance ===';
SELECT 'Ana Balance Check' as Info, AccountBalance, IsPremium, PremiumEndDate 
FROM portfolio.Users WHERE UserID = @AnaUserID;

EXEC portfolio.sp_CreatePortfolio @AnaUserID, 'Rendimento & Dividendos', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @AnaUserID AND Name = 'Rendimento & Dividendos');
EXEC portfolio.sp_AllocateFunds @AnaUserID, @PortfolioID, 7500.00;  -- Reduced from 7800 to 7500
PRINT 'Created portfolio: Ana - Rendimento & Dividendos';

-- Portfolio 9: Ana's Speculative Plays (Premium User)
EXEC portfolio.sp_CreatePortfolio @AnaUserID, 'Investimentos Especulativos', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @AnaUserID AND Name = 'Investimentos Especulativos');
EXEC portfolio.sp_AllocateFunds @AnaUserID, @PortfolioID, 900.00;  -- Reduced from 1000 to 900
PRINT 'Created portfolio: Ana - Investimentos Especulativos';

-- Portfolio 10: Isabella's US Market Portfolio (Premium User)
PRINT '=== Checking Isabella Rodriguez Balance ===';
SELECT 'Isabella Balance Check' as Info, AccountBalance, IsPremium, PremiumEndDate 
FROM portfolio.Users WHERE UserID = @IsabellaUserID;

EXEC portfolio.sp_CreatePortfolio @IsabellaUserID, 'Mercado Americano', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @IsabellaUserID AND Name = 'Mercado Americano');
EXEC portfolio.sp_AllocateFunds @IsabellaUserID, @PortfolioID, 28000.00;  -- Reduced from 28500 to be extra safe
PRINT 'Created portfolio: Isabella - Mercado Americano';

-- Portfolio 11: Isabella's Alternative Investments (Premium User)
EXEC portfolio.sp_CreatePortfolio @IsabellaUserID, 'Investimentos Alternativos', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @IsabellaUserID AND Name = 'Investimentos Alternativos');
EXEC portfolio.sp_AllocateFunds @IsabellaUserID, @PortfolioID, 3200.00;  -- Reduced from 3400 to 3200
PRINT 'Created portfolio: Isabella - Investimentos Alternativos';

-- Portfolio 12: Sophie's European Focus (Premium User)
EXEC portfolio.sp_CreatePortfolio @SophieUserID, 'Foco Europeu', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @SophieUserID AND Name = 'Foco Europeu');
EXEC portfolio.sp_AllocateFunds @SophieUserID, @PortfolioID, 16200.00;
PRINT 'Created portfolio: Sophie - Foco Europeu';

-- Portfolio 13: Sophie's Commodity Trading (Premium User)
EXEC portfolio.sp_CreatePortfolio @SophieUserID, 'Trading de Commodities', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @SophieUserID AND Name = 'Trading de Commodities');
EXEC portfolio.sp_AllocateFunds @SophieUserID, @PortfolioID, 2100.00;
PRINT 'Created portfolio: Sophie - Trading de Commodities';

-- Portfolio 14: Luca's Balanced Growth (Premium User)
EXEC portfolio.sp_CreatePortfolio @LucaUserID, 'Crescimento Equilibrado', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @LucaUserID AND Name = 'Crescimento Equilibrado');
EXEC portfolio.sp_AllocateFunds @LucaUserID, @PortfolioID, 11500.00;
PRINT 'Created portfolio: Luca - Crescimento Equilibrado';

PRINT 'Created 14 sample portfolios for 9 users using stored procedures';

-- ============================================================
-- PORTFOLIO BALANCE VERIFICATION BEFORE PURCHASES
-- ============================================================

PRINT '';
PRINT '=== PORTFOLIO BALANCES VERIFICATION ===';
SELECT 
    p.PortfolioID,
    u.Name as UserName,
    p.Name as PortfolioName,
    p.CurrentFunds as AvailableFunds
FROM portfolio.Portfolios p
JOIN portfolio.Users u ON p.UserID = u.UserID
WHERE u.Email IN (
    'maria.silva@email.com', 'carlos.oliveira@hotmail.com', 'thomas.mueller@gmail.de',
    'james.wilson@btinternet.com', 'emma.johnson@rogers.ca', 'joao.santos@email.com',
    'ana.costa@gmail.com', 'isabella.rodriguez@yahoo.com', 'sophie.dubois@orange.fr',
    'luca.rossi@libero.it'
)
ORDER BY p.PortfolioID;

PRINT '';
PRINT '=== PLANNED PURCHASE COSTS CALCULATION ===';
-- Show cost of Maria's first purchase (most likely to fail)
SELECT 
    'Maria Portfolio 1 - First Purchase' as PurchaseInfo,
    a.Symbol,
    a.Price as UnitPrice,
    12.500000 as PlannedQuantity,
    (a.Price * 12.500000) as TotalCost
FROM portfolio.Assets a
WHERE a.Symbol = 'AAPL';

-- Show total cost for Maria's portfolio
SELECT 
    'Maria Portfolio 1 - All Purchases Total' as PurchaseInfo,
    (SELECT Price FROM portfolio.Assets WHERE Symbol = 'AAPL') * 12.500000 +
    (SELECT Price FROM portfolio.Assets WHERE Symbol = 'EDP') * 45.000000 +
    (SELECT Price FROM portfolio.Assets WHERE Symbol = 'SPX') * 0.100000 as TotalNeeded;

PRINT '';

-- ============================================================
-- GET ASSET IDs FOR BUYING
-- ============================================================

DECLARE @AAPL_ID INT, @GOOGL_ID INT, @META_ID INT, @GALP_ID INT, @EDP_ID INT;
DECLARE @VALE_ID INT, @PBR_ID INT, @BBAS3_ID INT;
DECLARE @BTC_ID INT, @ETH_ID INT, @XRP_ID INT, @ADA_ID INT, @DOGE_ID INT, @SOL_ID INT;
DECLARE @CL_ID INT, @NG_ID INT, @GC_ID INT, @SI_ID INT, @HG_ID INT, @CC_ID INT;
DECLARE @SPX_ID INT, @DJI_ID INT, @NDX_ID INT, @PSI20_ID INT, @BVSP_ID INT, @UKX_ID INT, @DAX_ID INT, @CAC_ID INT;

-- Get Stock IDs
SELECT @AAPL_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'AAPL';
SELECT @GOOGL_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'GOOGL';
SELECT @META_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'META';
SELECT @GALP_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'GALP';
SELECT @EDP_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'EDP';
SELECT @VALE_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'VALE';
SELECT @PBR_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'PBR';
SELECT @BBAS3_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'BBAS3';

-- Get Crypto IDs
SELECT @BTC_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'BTC';
SELECT @ETH_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'ETH';
SELECT @XRP_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'XRP';
SELECT @ADA_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'ADA';
SELECT @DOGE_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'DOGE';
SELECT @SOL_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'SOL';

-- Get Commodity IDs
SELECT @CL_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'CL';
SELECT @NG_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'NG';
SELECT @GC_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'GC';
SELECT @SI_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'SI';
SELECT @HG_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'HG';
SELECT @CC_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'CC';

-- Get Index IDs  
SELECT @SPX_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'SPX';
SELECT @DJI_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'DJI';
SELECT @NDX_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'NDX';
SELECT @PSI20_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'PSI20';
SELECT @BVSP_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'BVSP';
SELECT @UKX_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'UKX';
SELECT @DAX_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'DAX';
SELECT @CAC_ID = AssetID FROM portfolio.Assets WHERE Symbol = 'CAC';

-- ============================================================
-- CREATE HOLDINGS USING sp_BuyAsset PROCEDURE
-- ============================================================

PRINT 'Creating holdings using sp_BuyAsset procedure...';

-- Portfolio 1: Maria's Conservative Growth
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @MariaUserID AND Name = 'Crescimento Conservador');
EXEC portfolio.sp_AllocateFunds @MariaUserID, @PortfolioID, 3100.00;  -- Increased from 2400 to cover purchases
PRINT 'Created portfolio: Maria - Crescimento Conservador';
PRINT 'Maria portfolio allocated: €3,100.00 (needs ~€3,032 for purchases)';

PRINT 'Starting Maria portfolio purchases - Portfolio ID: ' + CAST(@PortfolioID AS VARCHAR(10));
SELECT 'Maria Portfolio After Allocation' as Info, CurrentFunds FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID;

PRINT 'Attempting purchase: AAPL - 12.5 shares at €185.25 = €2,315.63';
EXEC portfolio.sp_BuyAsset @MariaUserID, @PortfolioID, @AAPL_ID, 12.500000, 185.25;
EXEC portfolio.sp_BuyAsset @MariaUserID, @PortfolioID, @EDP_ID, 45.000000, 3.85;
EXEC portfolio.sp_BuyAsset @MariaUserID, @PortfolioID, @SPX_ID, 0.100000, 5432.10;

-- Portfolio 2: Carlos's Brazilian Focus
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @CarlosUserID AND Name = 'Foco Brasil');
EXEC portfolio.sp_BuyAsset @CarlosUserID, @PortfolioID, @VALE_ID, 30.000000, 8.95;
EXEC portfolio.sp_BuyAsset @CarlosUserID, @PortfolioID, @PBR_ID, 15.000000, 15.80;
EXEC portfolio.sp_BuyAsset @CarlosUserID, @PortfolioID, @BBAS3_ID, 12.000000, 22.45;

-- Portfolio 3: Thomas's European Stocks
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @ThomasUserID AND Name = 'Ações Europeias');
EXEC portfolio.sp_BuyAsset @ThomasUserID, @PortfolioID, @DAX_ID, 0.075000, 18420.00;
EXEC portfolio.sp_BuyAsset @ThomasUserID, @PortfolioID, @CAC_ID, 0.050000, 7550.00;

-- Portfolio 4: James's Crypto Starter
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JamesUserID AND Name = 'Cripto Iniciante');
EXEC portfolio.sp_BuyAsset @JamesUserID, @PortfolioID, @BTC_ID, 0.006500, 68500.00;
EXEC portfolio.sp_BuyAsset @JamesUserID, @PortfolioID, @ETH_ID, 0.100000, 3850.00;

-- Portfolio 5: Emma's Tech & Growth
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @EmmaUserID AND Name = 'Tecnologia & Crescimento');
EXEC portfolio.sp_BuyAsset @EmmaUserID, @PortfolioID, @AAPL_ID, 3.250000, 182.50;
EXEC portfolio.sp_BuyAsset @EmmaUserID, @PortfolioID, @GOOGL_ID, 1.750000, 172.85;
EXEC portfolio.sp_BuyAsset @EmmaUserID, @PortfolioID, @META_ID, 0.875000, 520.00;

-- Portfolio 6: João's Diversified Portfolio
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JoaoUserID AND Name = 'Carteira Diversificada');
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @AAPL_ID, 45.000000, 180.25;
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @GOOGL_ID, 25.000000, 168.50;
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @META_ID, 8.500000, 495.00;
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @GALP_ID, 200.000000, 13.20;
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @EDP_ID, 180.000000, 3.75;
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @BTC_ID, 0.025000, 65000.00;
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @ETH_ID, 0.750000, 3600.00;
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @SPX_ID, 0.180000, 5200.00;

-- Portfolio 7: João's Crypto & Commodities
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JoaoUserID AND Name = 'Cripto & Commodities');
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @BTC_ID, 0.012000, 67500.00;
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @ETH_ID, 0.185000, 3750.00;
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @GC_ID, 0.350000, 2580.00;

-- Portfolio 8: Ana's Income & Dividend
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @AnaUserID AND Name = 'Rendimento & Dividendos');
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @AAPL_ID, 25.000000, 178.00;
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @GALP_ID, 350.000000, 12.85;
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @EDP_ID, 400.000000, 3.65;
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @PBR_ID, 120.000000, 14.20;

-- Portfolio 9: Ana's Speculative Plays
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @AnaUserID AND Name = 'Investimentos Especulativos');
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @DOGE_ID, 2500.000000, 0.085;
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @SOL_ID, 5.000000, 145.00;

-- Portfolio 10: Isabella's US Market Portfolio  
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @IsabellaUserID AND Name = 'Mercado Americano');
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @AAPL_ID, 85.000000, 175.50;
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @GOOGL_ID, 65.000000, 162.25;
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @META_ID, 22.500000, 480.00;
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @SPX_ID, 0.450000, 5150.00;

-- Portfolio 11: Isabella's Alternative Investments
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @IsabellaUserID AND Name = 'Investimentos Alternativos');
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @BTC_ID, 0.045000, 62000.00;
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @GC_ID, 1.250000, 2520.00;

-- Portfolio 12: Sophie's European Focus
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @SophieUserID AND Name = 'Foco Europeu');
EXEC portfolio.sp_BuyAsset @SophieUserID, @PortfolioID, @DAX_ID, 0.650000, 17850.00;
EXEC portfolio.sp_BuyAsset @SophieUserID, @PortfolioID, @CAC_ID, 0.450000, 7350.00;
EXEC portfolio.sp_BuyAsset @SophieUserID, @PortfolioID, @UKX_ID, 0.320000, 8120.00;

-- Portfolio 13: Sophie's Commodity Trading
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @SophieUserID AND Name = 'Trading de Commodities');
EXEC portfolio.sp_BuyAsset @SophieUserID, @PortfolioID, @GC_ID, 1.150000, 2545.00;

-- Portfolio 14: Luca's Balanced Growth
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @LucaUserID AND Name = 'Crescimento Equilibrado');
EXEC portfolio.sp_BuyAsset @LucaUserID, @PortfolioID, @AAPL_ID, 35.000000, 179.50;
EXEC portfolio.sp_BuyAsset @LucaUserID, @PortfolioID, @GOOGL_ID, 18.500000, 165.80;
EXEC portfolio.sp_BuyAsset @LucaUserID, @PortfolioID, @DAX_ID, 0.285000, 18125.00;
EXEC portfolio.sp_BuyAsset @LucaUserID, @PortfolioID, @BTC_ID, 0.018500, 64500.00;

PRINT 'Created realistic holdings across 14 portfolios using stored procedures';
PRINT '';

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

PRINT '=== PORTFOLIO SUMMARY ===';
SELECT 
    p.PortfolioID,
    u.Name as UserName,
    p.Name as PortfolioName,
    p.CurrentFunds,
    p.CurrentProfitPct,
    COUNT(ph.HoldingID) as TotalHoldings,
    SUM(ph.TotalCost) as TotalInvested
FROM portfolio.Portfolios p
JOIN portfolio.Users u ON p.UserID = u.UserID
LEFT JOIN portfolio.PortfolioHoldings ph ON p.PortfolioID = ph.PortfolioID
GROUP BY p.PortfolioID, u.Name, p.Name, p.CurrentFunds, p.CurrentProfitPct
ORDER BY TotalInvested DESC;

PRINT '';
PRINT '=== HOLDINGS BY ASSET TYPE ===';
SELECT 
    a.AssetType,
    COUNT(ph.HoldingID) as TotalHoldings,
    SUM(ph.TotalCost) as TotalInvested,
    AVG(ph.TotalCost) as AvgPositionSize
FROM portfolio.PortfolioHoldings ph
JOIN portfolio.Assets a ON ph.AssetID = a.AssetID
GROUP BY a.AssetType
ORDER BY TotalInvested DESC;

PRINT 'Portfolio and holdings created successfully using stored procedures!';

COMMIT TRANSACTION; 
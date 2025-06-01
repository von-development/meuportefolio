/* ============================================================
meuPortfolio - Sample Portfolios and Holdings (FIXED VERSION)
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

-- Maria Silva - ensure she has at least €5,000 (increased from €3,200)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @MariaUserID;
PRINT 'Maria current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 5000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @MariaUserID, 5000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Maria account';
END

-- Carlos Oliveira - ensure he has at least €2,000 (increased from €800)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @CarlosUserID;
PRINT 'Carlos current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 2000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @CarlosUserID, 2000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Carlos account';
END

-- Thomas Mueller - ensure he has at least €3,500 (increased from €1,800)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @ThomasUserID;
PRINT 'Thomas current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 3500.00
BEGIN
    EXEC portfolio.sp_DepositFunds @ThomasUserID, 3500.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Thomas account';
END

-- James Wilson - ensure he has at least €2,500 (increased from €850)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @JamesUserID;
PRINT 'James current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 2500.00
BEGIN
    EXEC portfolio.sp_DepositFunds @JamesUserID, 2500.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to James account';
END

-- Emma Johnson - ensure she has at least €3,000 (increased from €1,450)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @EmmaUserID;
PRINT 'Emma current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 3000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @EmmaUserID, 3000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Emma account';
END

-- João Santos - ensure he has at least €25,000 (increased from €16,000, Premium user)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @JoaoUserID;
PRINT 'João current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 25000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @JoaoUserID, 25000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to João account';
END

-- Ana Costa - ensure she has at least €15,000 (increased from €9,000, Premium user)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @AnaUserID;
PRINT 'Ana current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 15000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @AnaUserID, 15000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Ana account';
END

-- Isabella Rodriguez - ensure she has at least €50,000 (increased from €32,000, Premium user)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @IsabellaUserID;
PRINT 'Isabella current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 50000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @IsabellaUserID, 50000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Isabella account';
END

-- Sophie Dubois - ensure she has at least €30,000 (increased from €19,000, Premium user)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @SophieUserID;
PRINT 'Sophie current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 30000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @SophieUserID, 30000.00, 'Portfolio allocation preparation';
    PRINT 'Added funds to Sophie account';
END

-- Luca Rossi - ensure he has at least €20,000 (increased from €12,000, Premium user)
SELECT @CurrentBalance = AccountBalance FROM portfolio.Users WHERE UserID = @LucaUserID;
PRINT 'Luca current balance: ' + CAST(@CurrentBalance AS VARCHAR(20));
IF @CurrentBalance < 20000.00
BEGIN
    EXEC portfolio.sp_DepositFunds @LucaUserID, 20000.00, 'Portfolio allocation preparation';
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
EXEC portfolio.sp_AllocateFunds @MariaUserID, @PortfolioID, 2000.00;
PRINT 'Created portfolio: Maria - Crescimento Conservador';

-- Debug: Check Maria's balances after allocation
DECLARE @MariaAccountBalance DECIMAL(18,2), @MariaPortfolioFunds DECIMAL(18,2);
SELECT @MariaAccountBalance = AccountBalance FROM portfolio.Users WHERE UserID = @MariaUserID;
SELECT @MariaPortfolioFunds = CurrentFunds FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID;
PRINT 'DEBUG: Maria Account Balance after allocation: €' + CAST(@MariaAccountBalance AS VARCHAR(20));
PRINT 'DEBUG: Maria Portfolio Funds after allocation: €' + CAST(@MariaPortfolioFunds AS VARCHAR(20));

-- Portfolio 2: Carlos's Brazilian Focus (Basic User)
EXEC portfolio.sp_CreatePortfolio @CarlosUserID, 'Foco Brasil', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @CarlosUserID AND Name = 'Foco Brasil');
EXEC portfolio.sp_AllocateFunds @CarlosUserID, @PortfolioID, 1200.00;
PRINT 'Created portfolio: Carlos - Foco Brasil';

-- Portfolio 3: Thomas's European Stocks (Basic User)
EXEC portfolio.sp_CreatePortfolio @ThomasUserID, 'Ações Europeias', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @ThomasUserID AND Name = 'Ações Europeias');
EXEC portfolio.sp_AllocateFunds @ThomasUserID, @PortfolioID, 2500.00;
PRINT 'Created portfolio: Thomas - Ações Europeias';

-- Portfolio 4: James's Crypto Starter (Basic User)
EXEC portfolio.sp_CreatePortfolio @JamesUserID, 'Cripto Iniciante', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JamesUserID AND Name = 'Cripto Iniciante');
EXEC portfolio.sp_AllocateFunds @JamesUserID, @PortfolioID, 1500.00;
PRINT 'Created portfolio: James - Cripto Iniciante';

-- Portfolio 5: Emma's Tech & Growth (Basic User)
EXEC portfolio.sp_CreatePortfolio @EmmaUserID, 'Tecnologia & Crescimento', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @EmmaUserID AND Name = 'Tecnologia & Crescimento');
EXEC portfolio.sp_AllocateFunds @EmmaUserID, @PortfolioID, 2200.00;
PRINT 'Created portfolio: Emma - Tecnologia & Crescimento';

-- Portfolio 6: João's Diversified Portfolio (Premium User)
EXEC portfolio.sp_CreatePortfolio @JoaoUserID, 'Carteira Diversificada', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JoaoUserID AND Name = 'Carteira Diversificada');
EXEC portfolio.sp_AllocateFunds @JoaoUserID, @PortfolioID, 15000.00;
PRINT 'Created portfolio: João - Carteira Diversificada';

-- Portfolio 7: João's Crypto & Commodities (Premium User)
EXEC portfolio.sp_CreatePortfolio @JoaoUserID, 'Cripto & Commodities', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JoaoUserID AND Name = 'Cripto & Commodities');
EXEC portfolio.sp_AllocateFunds @JoaoUserID, @PortfolioID, 3000.00;
PRINT 'Created portfolio: João - Cripto & Commodities';

-- Portfolio 8: Ana's Income & Dividend (Premium User)
EXEC portfolio.sp_CreatePortfolio @AnaUserID, 'Rendimento & Dividendos', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @AnaUserID AND Name = 'Rendimento & Dividendos');
EXEC portfolio.sp_AllocateFunds @AnaUserID, @PortfolioID, 8000.00;
PRINT 'Created portfolio: Ana - Rendimento & Dividendos';

-- Portfolio 9: Ana's Speculative Plays (Premium User)
EXEC portfolio.sp_CreatePortfolio @AnaUserID, 'Investimentos Especulativos', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @AnaUserID AND Name = 'Investimentos Especulativos');
EXEC portfolio.sp_AllocateFunds @AnaUserID, @PortfolioID, 2000.00;
PRINT 'Created portfolio: Ana - Investimentos Especulativos';

-- Portfolio 10: Isabella's US Market Portfolio (Premium User)
EXEC portfolio.sp_CreatePortfolio @IsabellaUserID, 'Mercado Americano', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @IsabellaUserID AND Name = 'Mercado Americano');
EXEC portfolio.sp_AllocateFunds @IsabellaUserID, @PortfolioID, 30000.00;
PRINT 'Created portfolio: Isabella - Mercado Americano';

-- Portfolio 11: Isabella's Alternative Investments (Premium User)
EXEC portfolio.sp_CreatePortfolio @IsabellaUserID, 'Investimentos Alternativos', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @IsabellaUserID AND Name = 'Investimentos Alternativos');
EXEC portfolio.sp_AllocateFunds @IsabellaUserID, @PortfolioID, 8000.00;
PRINT 'Created portfolio: Isabella - Investimentos Alternativos';

-- Portfolio 12: Sophie's European Focus (Premium User)
EXEC portfolio.sp_CreatePortfolio @SophieUserID, 'Foco Europeu', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @SophieUserID AND Name = 'Foco Europeu');
EXEC portfolio.sp_AllocateFunds @SophieUserID, @PortfolioID, 18000.00;
PRINT 'Created portfolio: Sophie - Foco Europeu';

-- Portfolio 13: Sophie's Commodity Trading (Premium User)
EXEC portfolio.sp_CreatePortfolio @SophieUserID, 'Trading de Commodities', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @SophieUserID AND Name = 'Trading de Commodities');
EXEC portfolio.sp_AllocateFunds @SophieUserID, @PortfolioID, 4000.00;
PRINT 'Created portfolio: Sophie - Trading de Commodities';

-- Portfolio 14: Luca's Balanced Growth (Premium User)
EXEC portfolio.sp_CreatePortfolio @LucaUserID, 'Crescimento Equilibrado', 0;
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @LucaUserID AND Name = 'Crescimento Equilibrado');
EXEC portfolio.sp_AllocateFunds @LucaUserID, @PortfolioID, 12000.00;
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

-- Debug: Show Maria's portfolio balance before purchase
DECLARE @MariaPortfolioBalance DECIMAL(18,2);
SELECT @MariaPortfolioBalance = CurrentFunds FROM portfolio.Portfolios WHERE PortfolioID = @PortfolioID;
PRINT 'DEBUG: Maria Portfolio Balance: €' + CAST(@MariaPortfolioBalance AS VARCHAR(20));

-- Debug: Show AAPL price and calculated cost
DECLARE @AAPLPrice DECIMAL(18,2);
SELECT @AAPLPrice = Price FROM portfolio.Assets WHERE AssetID = @AAPL_ID;
DECLARE @PurchaseCost DECIMAL(18,2) = @AAPLPrice * 12.500000;
PRINT 'DEBUG: AAPL Price: €' + CAST(@AAPLPrice AS VARCHAR(20));
PRINT 'DEBUG: Purchase Cost (12.5 shares): €' + CAST(@PurchaseCost AS VARCHAR(20));

-- Use actual current prices from database
DECLARE @EDPPrice DECIMAL(18,2), @SPXPrice DECIMAL(18,2);
SELECT @EDPPrice = Price FROM portfolio.Assets WHERE AssetID = @EDP_ID;
SELECT @SPXPrice = Price FROM portfolio.Assets WHERE AssetID = @SPX_ID;

-- Debug: Show all prices for Maria's portfolio calculation
PRINT 'DEBUG: Asset Prices for Maria portfolio:';
PRINT 'DEBUG: AAPL Price: €' + CAST(@AAPLPrice AS VARCHAR(20));
PRINT 'DEBUG: EDP Price: €' + CAST(@EDPPrice AS VARCHAR(20));
PRINT 'DEBUG: SPX Price: €' + CAST(@SPXPrice AS VARCHAR(20));

-- Calculate affordable quantities for €2,000 budget (reduced from €3,100)
DECLARE @AAPLQuantity DECIMAL(18,6) = 3.000000;  -- 3 × €200.85 = €602.55
DECLARE @EDPQuantity DECIMAL(18,6) = 15.000000;  -- 15 × €3.95 = €59.25  
DECLARE @SPXQuantity DECIMAL(18,6) = 0.010000;   -- 0.01 × €5,911.69 = €59.12
-- Total: €602.55 + €59.25 + €59.12 = €720.92 (well within €2,000 budget)

PRINT 'DEBUG: Calculated costs:';
PRINT 'DEBUG: AAPL: ' + CAST(@AAPLQuantity AS VARCHAR(20)) + ' shares × €' + CAST(@AAPLPrice AS VARCHAR(20)) + ' = €' + CAST(@AAPLQuantity * @AAPLPrice AS VARCHAR(20));
PRINT 'DEBUG: EDP: ' + CAST(@EDPQuantity AS VARCHAR(20)) + ' shares × €' + CAST(@EDPPrice AS VARCHAR(20)) + ' = €' + CAST(@EDPQuantity * @EDPPrice AS VARCHAR(20));
PRINT 'DEBUG: SPX: ' + CAST(@SPXQuantity AS VARCHAR(20)) + ' shares × €' + CAST(@SPXPrice AS VARCHAR(20)) + ' = €' + CAST(@SPXQuantity * @SPXPrice AS VARCHAR(20));
PRINT 'DEBUG: Total estimated cost: €' + CAST((@AAPLQuantity * @AAPLPrice) + (@EDPQuantity * @EDPPrice) + (@SPXQuantity * @SPXPrice) AS VARCHAR(20));

-- Adjusted quantities for current market prices (€2,000 budget)
EXEC portfolio.sp_BuyAsset @MariaUserID, @PortfolioID, @AAPL_ID, @AAPLQuantity, @AAPLPrice;  
EXEC portfolio.sp_BuyAsset @MariaUserID, @PortfolioID, @EDP_ID, @EDPQuantity, @EDPPrice;    
EXEC portfolio.sp_BuyAsset @MariaUserID, @PortfolioID, @SPX_ID, @SPXQuantity, @SPXPrice;

-- Portfolio 2: Carlos's Brazilian Focus (€1,200 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @CarlosUserID AND Name = 'Foco Brasil');
EXEC portfolio.sp_BuyAsset @CarlosUserID, @PortfolioID, @VALE_ID, 15.000000, 12.45;  -- Reduced from 30
EXEC portfolio.sp_BuyAsset @CarlosUserID, @PortfolioID, @PBR_ID, 8.000000, 14.85;    -- Reduced from 15
EXEC portfolio.sp_BuyAsset @CarlosUserID, @PortfolioID, @BBAS3_ID, 5.000000, 28.50;  -- Reduced from 12

-- Portfolio 3: Thomas's European Stocks (€2,500 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @ThomasUserID AND Name = 'Ações Europeias');
EXEC portfolio.sp_BuyAsset @ThomasUserID, @PortfolioID, @DAX_ID, 0.050000, 18420.00;  -- Reduced from 0.075
EXEC portfolio.sp_BuyAsset @ThomasUserID, @PortfolioID, @CAC_ID, 0.030000, 7550.00;   -- Reduced from 0.050

-- Portfolio 4: James's Crypto Starter (€1,500 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JamesUserID AND Name = 'Cripto Iniciante');
EXEC portfolio.sp_BuyAsset @JamesUserID, @PortfolioID, @BTC_ID, 0.003000, 104167.60;  -- Reduced from 0.0065
EXEC portfolio.sp_BuyAsset @JamesUserID, @PortfolioID, @ETH_ID, 0.200000, 2501.66;    -- Reduced from 0.100

-- Portfolio 5: Emma's Tech & Growth (€2,200 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @EmmaUserID AND Name = 'Tecnologia & Crescimento');
EXEC portfolio.sp_BuyAsset @EmmaUserID, @PortfolioID, @AAPL_ID, 2.000000, 200.85;     -- Reduced from 3.25
EXEC portfolio.sp_BuyAsset @EmmaUserID, @PortfolioID, @GOOGL_ID, 1.000000, 175.25;    -- Reduced from 1.75
EXEC portfolio.sp_BuyAsset @EmmaUserID, @PortfolioID, @META_ID, 0.500000, 485.30;     -- Reduced from 0.875

-- Portfolio 6: João's Diversified Portfolio (€15,000 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JoaoUserID AND Name = 'Carteira Diversificada');
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @AAPL_ID, 20.000000, 200.85;    -- Reduced from 45
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @GOOGL_ID, 12.000000, 175.25;   -- Reduced from 25
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @META_ID, 4.000000, 485.30;     -- Reduced from 8.5
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @GALP_ID, 80.000000, 16.85;     -- Reduced from 200
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @EDP_ID, 80.000000, 3.95;       -- Reduced from 180
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @BTC_ID, 0.010000, 104167.60;   -- Reduced from 0.025
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @ETH_ID, 0.400000, 2501.66;     -- Reduced from 0.75
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @SPX_ID, 0.080000, 5911.69;     -- Reduced from 0.18

-- Portfolio 7: João's Crypto & Commodities (€3,000 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @JoaoUserID AND Name = 'Cripto & Commodities');
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @BTC_ID, 0.008000, 104167.60;   -- Reduced from 0.012
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @ETH_ID, 0.120000, 2501.66;     -- Reduced from 0.185
EXEC portfolio.sp_BuyAsset @JoaoUserID, @PortfolioID, @GC_ID, 0.200000, 3315.40;      -- Reduced from 0.35

-- Portfolio 8: Ana's Income & Dividend (€8,000 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @AnaUserID AND Name = 'Rendimento & Dividendos');
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @AAPL_ID, 12.000000, 200.85;     -- Reduced from 25
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @GALP_ID, 150.000000, 16.85;     -- Reduced from 350
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @EDP_ID, 200.000000, 3.95;       -- Reduced from 400
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @PBR_ID, 60.000000, 14.85;       -- Reduced from 120

-- Portfolio 9: Ana's Speculative Plays (€2,000 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @AnaUserID AND Name = 'Investimentos Especulativos');
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @DOGE_ID, 1200.000000, 0.1888;   -- Reduced from 2500
EXEC portfolio.sp_BuyAsset @AnaUserID, @PortfolioID, @SOL_ID, 3.000000, 152.80;       -- Reduced from 5

-- Portfolio 10: Isabella's US Market Portfolio (€30,000 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @IsabellaUserID AND Name = 'Mercado Americano');
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @AAPL_ID, 40.000000, 200.85;   -- Reduced from 85
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @GOOGL_ID, 30.000000, 175.25;  -- Reduced from 65
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @META_ID, 10.000000, 485.30;   -- Reduced from 22.5
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @SPX_ID, 0.200000, 5911.69;    -- Reduced from 0.45

-- Portfolio 11: Isabella's Alternative Investments (€8,000 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @IsabellaUserID AND Name = 'Investimentos Alternativos');
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @BTC_ID, 0.020000, 104167.60;  -- Reduced from 0.045
EXEC portfolio.sp_BuyAsset @IsabellaUserID, @PortfolioID, @GC_ID, 0.600000, 3315.40;     -- Reduced from 1.25

-- Portfolio 12: Sophie's European Focus (€18,000 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @SophieUserID AND Name = 'Foco Europeu');
EXEC portfolio.sp_BuyAsset @SophieUserID, @PortfolioID, @DAX_ID, 0.300000, 18420.00;     -- Reduced from 0.65
EXEC portfolio.sp_BuyAsset @SophieUserID, @PortfolioID, @CAC_ID, 0.200000, 7550.00;      -- Reduced from 0.45
EXEC portfolio.sp_BuyAsset @SophieUserID, @PortfolioID, @UKX_ID, 0.150000, 8285.50;      -- Reduced from 0.32

-- Portfolio 13: Sophie's Commodity Trading (€4,000 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @SophieUserID AND Name = 'Trading de Commodities');
EXEC portfolio.sp_BuyAsset @SophieUserID, @PortfolioID, @GC_ID, 0.500000, 3315.40;       -- Reduced from 1.15

-- Portfolio 14: Luca's Balanced Growth (€12,000 budget)
SET @PortfolioID = (SELECT PortfolioID FROM portfolio.Portfolios WHERE UserID = @LucaUserID AND Name = 'Crescimento Equilibrado');
EXEC portfolio.sp_BuyAsset @LucaUserID, @PortfolioID, @AAPL_ID, 15.000000, 200.85;       -- Reduced from 35
EXEC portfolio.sp_BuyAsset @LucaUserID, @PortfolioID, @GOOGL_ID, 10.000000, 175.25;      -- Reduced from 18.5
EXEC portfolio.sp_BuyAsset @LucaUserID, @PortfolioID, @DAX_ID, 0.150000, 18420.00;       -- Reduced from 0.285
EXEC portfolio.sp_BuyAsset @LucaUserID, @PortfolioID, @BTC_ID, 0.010000, 104167.60;      -- Reduced from 0.0185

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
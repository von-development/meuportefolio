/* ------------------------------------------------------------
meuPortfolio – Additional Seed Data (v2025-05-24)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
1. Additional Portfolio Data
============================================================ */

-- Get UserIDs
DECLARE @JoaoID UNIQUEIDENTIFIER;
DECLARE @MariaID UNIQUEIDENTIFIER;
DECLARE @PedroID UNIQUEIDENTIFIER;
DECLARE @AnaID UNIQUEIDENTIFIER;
DECLARE @CarlosID UNIQUEIDENTIFIER;

SELECT @JoaoID = UserID FROM portfolio.Users WHERE Email = 'joao.silva@email.com';
SELECT @MariaID = UserID FROM portfolio.Users WHERE Email = 'maria.santos@email.com';
SELECT @PedroID = UserID FROM portfolio.Users WHERE Email = 'pedro.oliveira@email.com';
SELECT @AnaID = UserID FROM portfolio.Users WHERE Email = 'ana.pereira@email.com';
SELECT @CarlosID = UserID FROM portfolio.Users WHERE Email = 'carlos.ferreira@email.com';

-- Create new portfolios for commodities and indices
INSERT INTO portfolio.Portfolios (UserID, Name, CurrentFunds, CurrentProfitPct)
VALUES 
    (@JoaoID, 'Commodities Portfolio', 75000.00, 12.8),
    (@MariaID, 'Global Indices', 150000.00, 9.5),
    (@CarlosID, 'Commodities Trading', 120000.00, 15.3),
    (@PedroID, 'Index Investment', 45000.00, 7.8),
    (@AnaID, 'Mixed Assets', 85000.00, 11.2);

/* ============================================================
2. Additional Asset Price History
============================================================ */

-- Add some historical prices for new assets
INSERT INTO portfolio.AssetPrices (AssetID, Price, AsOf, OpenPrice, HighPrice, LowPrice, Volume)
VALUES
    -- Polkadot Historical Prices
    (9, 43.21, '2025-05-20', 42.85, 44.12, 42.10, 854721963),
    (9, 44.56, '2025-05-21', 43.21, 45.00, 43.15, 963852741),
    (9, 45.78, '2025-05-22', 44.56, 46.25, 44.32, 741852963),
    
    -- Cardano Historical Prices
    (10, 2.65, '2025-05-20', 2.60, 2.70, 2.58, 789456123),
    (10, 2.75, '2025-05-21', 2.65, 2.80, 2.63, 852963741),
    (10, 2.85, '2025-05-22', 2.75, 2.90, 2.72, 963741852),
    
    -- S&P 500 Historical Prices
    (13, 5250.45, '2025-05-20', 5245.32, 5260.45, 5240.12, 1234567890),
    (13, 5265.78, '2025-05-21', 5250.45, 5275.89, 5248.65, 987654321),
    (13, 5280.45, '2025-05-22', 5265.78, 5285.96, 5262.14, 789456123),
    
    -- Gold Historical Prices
    (18, 2325.45, '2025-05-20', 2320.12, 2330.45, 2318.96, 456789123),
    (18, 2335.89, '2025-05-21', 2325.45, 2340.12, 2324.78, 789123456),
    (18, 2345.67, '2025-05-22', 2335.89, 2350.45, 2334.56, 654321987);

/* ============================================================
3. Additional Risk Metrics
============================================================ */

-- Add more detailed risk metrics for portfolios
INSERT INTO portfolio.RiskMetrics (UserID, MaximumDrawdown, Beta, SharpeRatio, AbsoluteReturn, VolatilityScore, RiskLevel)
VALUES 
    -- Additional metrics for existing users with new portfolios
    (@JoaoID, -12.3, 0.95, 1.9, 19.8, 6.2, 'Conservative'),
    (@MariaID, -16.7, 1.3, 1.7, 21.5, 7.8, 'Moderate'),
    (@CarlosID, -19.5, 1.6, 2.0, 24.3, 8.5, 'Aggressive'),
    (@PedroID, -14.2, 1.1, 1.4, 16.9, 6.9, 'Moderate'),
    (@AnaID, -11.8, 0.85, 1.5, 17.2, 5.8, 'Conservative');

/* ============================================================
4. Additional Transactions
============================================================ */

-- Get new PortfolioIDs
DECLARE @JoaoCommoditiesID INT;
DECLARE @MariaIndicesID INT;
DECLARE @CarlosCommoditiesID INT;
DECLARE @PedroIndexID INT;
DECLARE @AnaMixedID INT;

SELECT @JoaoCommoditiesID = PortfolioID FROM portfolio.Portfolios WHERE UserID = @JoaoID AND Name = 'Commodities Portfolio';
SELECT @MariaIndicesID = PortfolioID FROM portfolio.Portfolios WHERE UserID = @MariaID AND Name = 'Global Indices';
SELECT @CarlosCommoditiesID = PortfolioID FROM portfolio.Portfolios WHERE UserID = @CarlosID AND Name = 'Commodities Trading';
SELECT @PedroIndexID = PortfolioID FROM portfolio.Portfolios WHERE UserID = @PedroID AND Name = 'Index Investment';
SELECT @AnaMixedID = PortfolioID FROM portfolio.Portfolios WHERE UserID = @AnaID AND Name = 'Mixed Assets';

-- Insert new transactions
INSERT INTO portfolio.Transactions (UserID, PortfolioID, AssetID, TransactionType, Quantity, UnitPrice, TransactionDate, Status)
VALUES
    -- João - Commodities Portfolio
    (@JoaoID, @JoaoCommoditiesID, 18, 'Buy', 25, 2345.67, '2025-05-29 09:30:00', 'Completed'),
    (@JoaoID, @JoaoCommoditiesID, 19, 'Buy', 1000, 28.45, '2025-05-29 10:15:00', 'Completed'),
    (@JoaoID, @JoaoCommoditiesID, 20, 'Buy', 100, 95.78, '2025-05-29 11:00:00', 'Completed'),
    
    -- Maria - Global Indices
    (@MariaID, @MariaIndicesID, 13, 'Buy', 15, 5280.45, '2025-05-29 09:45:00', 'Completed'),
    (@MariaID, @MariaIndicesID, 14, 'Buy', 10, 18456.78, '2025-05-29 10:30:00', 'Completed'),
    (@MariaID, @MariaIndicesID, 16, 'Buy', 500, 6789.12, '2025-05-29 11:15:00', 'Completed'),
    
    -- Carlos - Commodities Trading
    (@CarlosID, @CarlosCommoditiesID, 18, 'Buy', 40, 2345.67, '2025-05-29 13:30:00', 'Completed'),
    (@CarlosID, @CarlosCommoditiesID, 20, 'Buy', 500, 95.78, '2025-05-29 14:15:00', 'Completed'),
    (@CarlosID, @CarlosCommoditiesID, 22, 'Buy', 2000, 4.32, '2025-05-29 15:00:00', 'Completed'),
    
    -- Pedro - Index Investment
    (@PedroID, @PedroIndexID, 13, 'Buy', 5, 5280.45, '2025-05-29 13:45:00', 'Completed'),
    (@PedroID, @PedroIndexID, 15, 'Buy', 25, 128945.67, '2025-05-29 14:30:00', 'Completed'),
    
    -- Ana - Mixed Assets
    (@AnaID, @AnaMixedID, 13, 'Buy', 8, 5280.45, '2025-05-29 15:15:00', 'Completed'),
    (@AnaID, @AnaMixedID, 18, 'Buy', 15, 2345.67, '2025-05-29 15:45:00', 'Completed'),
    (@AnaID, @AnaMixedID, 9, 'Buy', 500, 45.78, '2025-05-29 16:15:00', 'Completed');

/* ----------------  END OF SCRIPT ---------------- */ 
/* ------------------------------------------------------------
meuPortfolio – Clean and Seed Data (v2025-05-24)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
0. Clean Existing Data
============================================================ */

-- Desabilitar verificação de chaves estrangeiras
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Limpar dados das tabelas na ordem correta
DELETE FROM portfolio.PaymentMethods;
DELETE FROM portfolio.Subscriptions;
DELETE FROM portfolio.RiskMetrics;
DELETE FROM portfolio.Transactions;
DELETE FROM portfolio.Portfolios;
DELETE FROM portfolio.IndexDetails;
DELETE FROM portfolio.CompanyDetails;
DELETE FROM portfolio.AssetPrices;
DELETE FROM portfolio.Assets;
DELETE FROM portfolio.Users;

-- Habilitar verificação de chaves estrangeiras
EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

/* ============================================================
1. Users Data
============================================================ */

INSERT INTO portfolio.Users (Name, Email, PasswordHash, CountryOfResidence, IBAN, UserType)
VALUES 
    ('João Silva', 'joao.silva@email.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyBAWwqeQfgH6.', 'Brasil', 'BR9876543210987654321098765', 'Premium'),
    ('Maria Santos', 'maria.santos@email.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyBAWwqeQfgH6.', 'Portugal', 'PT9876543210987654321098765', 'Premium'),
    ('Pedro Oliveira', 'pedro.oliveira@email.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyBAWwqeQfgH6.', 'Brasil', 'BR8765432109876543210987654', 'Basic'),
    ('Ana Pereira', 'ana.pereira@email.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyBAWwqeQfgH6.', 'Portugal', 'PT8765432109876543210987654', 'Basic'),
    ('Carlos Ferreira', 'carlos.ferreira@email.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewKyBAWwqeQfgH6.', 'Brasil', 'BR7654321098765432109876543', 'Premium');

/* ============================================================
2. Assets Data - All Types
============================================================ */

-- Reset Identity para Assets
DBCC CHECKIDENT ('portfolio.Assets', RESEED, 0);

-- Tech Companies
INSERT INTO portfolio.Assets (Symbol, Name, AssetType, Price, Volume, AvailableShares)
VALUES
    ('AAPL', 'Apple Inc.', 'Company', 178.66, 2345678901, 1000000000),
    ('NVDA', 'NVIDIA Corporation', 'Company', 135.43, 1234567890, 1000000000),
    ('META', 'Meta Platforms Inc.', 'Company', 641.36, 987654321, 1000000000),
    ('MSFT', 'Microsoft Corporation', 'Company', 378.92, 2345678901, 1000000000),
    ('GOOGL', 'Alphabet Inc.', 'Company', 2890.45, 1234567890, 1000000000),
    ('AMZN', 'Amazon.com Inc.', 'Company', 3456.78, 987654321, 1000000000),
    ('TSLA', 'Tesla, Inc.', 'Company', 890.23, 456789123, 1000000000);

-- Cryptocurrencies
INSERT INTO portfolio.Assets (Symbol, Name, AssetType, Price, Volume, AvailableShares)
VALUES
    ('BTC', 'Bitcoin', 'Cryptocurrency', 45000.78, 987654321, 1000000000),
    ('ETH', 'Ethereum', 'Cryptocurrency', 3200.85, 789456123, 1000000000),
    ('SOL', 'Solana', 'Cryptocurrency', 120.32, 456789123, 1000000000),
    ('DOT', 'Polkadot', 'Cryptocurrency', 45.78, 987654321, 1000000000),
    ('ADA', 'Cardano', 'Cryptocurrency', 2.85, 789456123, 1000000000),
    ('AVAX', 'Avalanche', 'Cryptocurrency', 89.32, 456789123, 1000000000),
    ('MATIC', 'Polygon', 'Cryptocurrency', 3.45, 741852963, 1000000000),
    ('LINK', 'Chainlink', 'Cryptocurrency', 52.14, 369258147, 1000000000);

-- Stock Market Indices
INSERT INTO portfolio.Assets (Symbol, Name, AssetType, Price, Volume, AvailableShares)
VALUES
    ('SPX', 'S&P 500', 'Index', 5280.45, 1234567890, 1000000000),
    ('NDX', 'NASDAQ-100', 'Index', 18456.78, 987654321, 1000000000),
    ('IBOV', 'Ibovespa', 'Index', 128945.67, 456789123, 1000000000),
    ('PSI', 'Portuguese Stock Index', 'Index', 6789.12, 789123456, 1000000000),
    ('DAX', 'DAX 40', 'Index', 17234.56, 654321987, 1000000000);

-- Commodities
INSERT INTO portfolio.Assets (Symbol, Name, AssetType, Price, Volume, AvailableShares)
VALUES
    ('GC', 'Gold', 'Commodity', 2345.67, 987654321, 1000000000),
    ('SI', 'Silver', 'Commodity', 28.45, 789456123, 1000000000),
    ('CL', 'Crude Oil', 'Commodity', 95.78, 456789123, 1000000000),
    ('NG', 'Natural Gas', 'Commodity', 4.32, 741852963, 1000000000),
    ('HG', 'Copper', 'Commodity', 4.85, 369258147, 1000000000);

/* ============================================================
3. Company Details
============================================================ */

INSERT INTO portfolio.CompanyDetails (AssetID, Sector, Industry, Country, MarketCap, EmployeeCount, YearFounded)
VALUES 
    -- Apple Inc.
    (1, 'Technology', 'Consumer Electronics', 'United States', 2890000000000.00, 164000, 1976),
    -- NVIDIA Corporation
    (2, 'Technology', 'Semiconductors', 'United States', 1750000000000.00, 26196, 1993),
    -- Meta Platforms Inc.
    (3, 'Technology', 'Internet Content & Information', 'United States', 1020000000000.00, 86482, 2004),
    -- Microsoft
    (4, 'Technology', 'Software Infrastructure', 'United States', 2850000000000.00, 221000, 1975),
    -- Alphabet
    (5, 'Technology', 'Internet Content & Information', 'United States', 1890000000000.00, 156500, 1998),
    -- Amazon
    (6, 'Consumer Cyclical', 'Internet Retail', 'United States', 1680000000000.00, 1608000, 1994),
    -- Tesla
    (7, 'Consumer Cyclical', 'Auto Manufacturers', 'United States', 890000000000.00, 127855, 2003);

/* ============================================================
4. Index Details
============================================================ */

INSERT INTO portfolio.IndexDetails (AssetID, Country, Region, Methodology, NumberOfComponents, RebalanceFrequency, BaseValue, BaseDate)
VALUES
    -- S&P 500
    (13, 'United States', 'North America', 'Market Cap Weighted', 500, 'Quarterly', 100.00, '1957-03-04'),
    -- NASDAQ-100
    (14, 'United States', 'North America', 'Modified Market Cap Weighted', 100, 'Quarterly', 125.00, '1985-01-31'),
    -- Ibovespa
    (15, 'Brasil', 'South America', 'Trading Volume Weighted', 92, 'Quarterly', 100.00, '1968-01-02'),
    -- PSI
    (16, 'Portugal', 'Europe', 'Free Float Market Cap Weighted', 20, 'Quarterly', 3000.00, '1992-12-31'),
    -- DAX
    (17, 'Germany', 'Europe', 'Free Float Market Cap Weighted', 40, 'Quarterly', 1000.00, '1987-12-30');

/* ============================================================
5. Get User IDs for Reference
============================================================ */

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

/* ============================================================
6. Initial Portfolios
============================================================ */

-- Reset Identity para Portfolios
DBCC CHECKIDENT ('portfolio.Portfolios', RESEED, 0);

-- Insert Initial Portfolios
INSERT INTO portfolio.Portfolios (UserID, Name, CurrentFunds, CurrentProfitPct)
VALUES 
    (@JoaoID, 'Investimentos Tech', 100000.00, 15.5),
    (@JoaoID, 'Crypto Portfolio', 50000.00, 22.3),
    (@MariaID, 'Long Term Growth', 75000.00, 8.7),
    (@MariaID, 'Crypto Trading', 25000.00, 31.2),
    (@PedroID, 'Minha Carteira', 15000.00, 5.4),
    (@AnaID, 'Investimentos 2025', 30000.00, 12.8),
    (@CarlosID, 'Tech Stocks', 200000.00, 18.9),
    (@CarlosID, 'Crypto Assets', 100000.00, 25.6);

-- Insert Additional Portfolios
INSERT INTO portfolio.Portfolios (UserID, Name, CurrentFunds, CurrentProfitPct)
VALUES 
    (@JoaoID, 'Commodities Portfolio', 75000.00, 12.8),
    (@MariaID, 'Global Indices', 150000.00, 9.5),
    (@CarlosID, 'Commodities Trading', 120000.00, 15.3),
    (@PedroID, 'Index Investment', 45000.00, 7.8),
    (@AnaID, 'Mixed Assets', 85000.00, 11.2);

/* ============================================================
7. Initial Transactions
============================================================ */

-- Get Initial PortfolioIDs
DECLARE @JoaoTechID INT;
DECLARE @JoaoCryptoID INT;
DECLARE @MariaCryptoID INT;
DECLARE @CarlosTechID INT;

SELECT @JoaoTechID = PortfolioID FROM portfolio.Portfolios WHERE UserID = @JoaoID AND Name = 'Investimentos Tech';
SELECT @JoaoCryptoID = PortfolioID FROM portfolio.Portfolios WHERE UserID = @JoaoID AND Name = 'Crypto Portfolio';
SELECT @MariaCryptoID = PortfolioID FROM portfolio.Portfolios WHERE UserID = @MariaID AND Name = 'Crypto Trading';
SELECT @CarlosTechID = PortfolioID FROM portfolio.Portfolios WHERE UserID = @CarlosID AND Name = 'Tech Stocks';

-- Reset Identity para Transactions
DBCC CHECKIDENT ('portfolio.Transactions', RESEED, 0);

-- Insert Initial Transactions
INSERT INTO portfolio.Transactions (UserID, PortfolioID, AssetID, TransactionType, Quantity, UnitPrice, TransactionDate, Status)
VALUES
    -- João - Tech Portfolio
    (@JoaoID, @JoaoTechID, 1, 'Buy', 100, 178.66, '2025-05-27 10:30:00', 'Completed'),
    (@JoaoID, @JoaoTechID, 2, 'Buy', 50, 135.43, '2025-05-27 11:15:00', 'Completed'),
    (@JoaoID, @JoaoTechID, 3, 'Buy', 25, 641.36, '2025-05-27 14:20:00', 'Completed'),
    
    -- João - Crypto Portfolio
    (@JoaoID, @JoaoCryptoID, 8, 'Buy', 1000, 45.78, '2025-05-26 09:45:00', 'Completed'),
    (@JoaoID, @JoaoCryptoID, 9, 'Buy', 5000, 2.85, '2025-05-26 10:30:00', 'Completed'),
    
    -- Maria - Crypto Trading
    (@MariaID, @MariaCryptoID, 10, 'Buy', 200, 89.32, '2025-05-25 15:20:00', 'Completed'),
    (@MariaID, @MariaCryptoID, 11, 'Buy', 1500, 3.45, '2025-05-25 16:10:00', 'Completed'),
    
    -- Carlos - Tech Stocks
    (@CarlosID, @CarlosTechID, 1, 'Buy', 500, 178.66, '2025-05-24 11:30:00', 'Completed'),
    (@CarlosID, @CarlosTechID, 2, 'Buy', 300, 135.43, '2025-05-24 13:45:00', 'Completed'),
    (@CarlosID, @CarlosTechID, 3, 'Buy', 100, 641.36, '2025-05-24 15:20:00', 'Completed');

/* ============================================================
8. Additional Transactions
============================================================ */

-- Get Additional PortfolioIDs
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

-- Insert Additional Transactions
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

/* ============================================================
9. Asset Price History
============================================================ */

-- Add historical prices for assets
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
10. Risk Metrics Data
============================================================ */

-- Insert Initial Risk Metrics
INSERT INTO portfolio.RiskMetrics (UserID, MaximumDrawdown, Beta, SharpeRatio, AbsoluteReturn, VolatilityScore, RiskLevel)
VALUES 
    (@JoaoID, -15.5, 1.2, 1.8, 22.3, 7.5, 'Moderate'),
    (@MariaID, -12.8, 0.9, 1.5, 18.7, 6.8, 'Conservative'),
    (@PedroID, -18.2, 1.4, 1.2, 15.4, 8.2, 'Aggressive'),
    (@AnaID, -10.5, 0.8, 1.6, 16.8, 5.9, 'Conservative'),
    (@CarlosID, -20.1, 1.5, 2.1, 25.6, 8.8, 'Aggressive');

-- Insert Additional Risk Metrics
INSERT INTO portfolio.RiskMetrics (UserID, MaximumDrawdown, Beta, SharpeRatio, AbsoluteReturn, VolatilityScore, RiskLevel)
VALUES 
    (@JoaoID, -12.3, 0.95, 1.9, 19.8, 6.2, 'Conservative'),
    (@MariaID, -16.7, 1.3, 1.7, 21.5, 7.8, 'Moderate'),
    (@CarlosID, -19.5, 1.6, 2.0, 24.3, 8.5, 'Aggressive'),
    (@PedroID, -14.2, 1.1, 1.4, 16.9, 6.9, 'Moderate'),
    (@AnaID, -11.8, 0.85, 1.5, 17.2, 5.8, 'Conservative');

/* ============================================================
11. Subscriptions Data
============================================================ */

INSERT INTO portfolio.Subscriptions (UserID, StartDate, EndDate, AmountPaid, PaymentStatus)
VALUES 
    (@JoaoID, '2025-01-01', '2026-01-01', 299.99, 'Completed'),
    (@MariaID, '2025-02-15', '2026-02-15', 299.99, 'Completed'),
    (@CarlosID, '2025-03-10', '2026-03-10', 299.99, 'Completed');

/* ============================================================
12. Payment Methods Data
============================================================ */

INSERT INTO portfolio.PaymentMethods (UserID, MethodType, Details, IsDefault, LastUsed, Status, ValidationDate)
VALUES 
    (@JoaoID, 'Credit Card', 'VISA ****4582', 1, '2025-05-27', 'Active', '2027-12-31'),
    (@JoaoID, 'Bank Transfer', 'Banco do Brasil', 0, '2025-04-15', 'Active', '2026-12-31'),
    (@MariaID, 'Credit Card', 'MasterCard ****7891', 1, '2025-05-26', 'Active', '2026-08-31'),
    (@PedroID, 'Bank Transfer', 'Itaú', 1, '2025-05-20', 'Active', '2026-12-31'),
    (@AnaID, 'Credit Card', 'VISA ****2345', 1, '2025-05-25', 'Active', '2027-03-31'),
    (@CarlosID, 'Credit Card', 'American Express ****9012', 1, '2025-05-24', 'Active', '2026-11-30'),
    (@CarlosID, 'Bank Transfer', 'Santander', 0, '2025-04-30', 'Active', '2026-12-31');

/* ----------------  END OF SCRIPT ---------------- */ 
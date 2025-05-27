/* ------------------------------------------------------------
meuPortfolio – Seed Data (v2024-03-21)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
1. Sample Users
============================================================ */
INSERT INTO portfolio.Users (Name, Email, PasswordHash, CountryOfResidence, IBAN, UserType)
VALUES 
    ('João Silva', 'joao.silva@email.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4tbQU.Tvt6', 'Brasil', 'BR9876543210987654321098765', 'Premium'),
    ('Maria Santos', 'maria.santos@email.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4tbQU.Tvt6', 'Portugal', 'PT9876543210987654321098765', 'Basic');

/* ============================================================
2. Sample Assets (Top Tech Companies)
============================================================ */
INSERT INTO portfolio.Assets (Symbol, Name, AssetType, Currency)
VALUES 
    ('AAPL', 'Apple Inc.', 'Stock', 'USD'),
    ('MSFT', 'Microsoft Corporation', 'Stock', 'USD'),
    ('GOOGL', 'Alphabet Inc.', 'Stock', 'USD'),
    ('AMZN', 'Amazon.com Inc.', 'Stock', 'USD'),
    ('NVDA', 'NVIDIA Corporation', 'Stock', 'USD');

/* ============================================================
3. Current Asset Prices
============================================================ */
INSERT INTO portfolio.AssetPrices (AssetID, Price, PriceDate)
SELECT 
    a.AssetID,
    CASE 
        WHEN a.Symbol = 'AAPL' THEN 172.62
        WHEN a.Symbol = 'MSFT' THEN 425.22
        WHEN a.Symbol = 'GOOGL' THEN 147.60
        WHEN a.Symbol = 'AMZN' THEN 178.15
        WHEN a.Symbol = 'NVDA' THEN 878.35
    END as Price,
    GETDATE() as PriceDate
FROM portfolio.Assets a;

/* ============================================================
4. Sample Portfolios
============================================================ */
INSERT INTO portfolio.Portfolios (UserID, Name, Description)
SELECT 
    u.UserID,
    'Portfólio Principal',
    'Portfólio de investimentos em tecnologia'
FROM portfolio.Users u
WHERE u.Email = 'joao.silva@email.com';

INSERT INTO portfolio.Portfolios (UserID, Name, Description)
SELECT 
    u.UserID,
    'Meus Investimentos',
    'Carteira diversificada'
FROM portfolio.Users u
WHERE u.Email = 'maria.santos@email.com';

/* ============================================================
5. Sample Transactions
============================================================ */
-- João's transactions
INSERT INTO portfolio.Transactions (PortfolioID, AssetID, TransactionType, Quantity, Price, TransactionDate)
SELECT 
    p.PortfolioID,
    a.AssetID,
    'Buy',
    10,
    165.50,
    DATEADD(day, -30, GETDATE())
FROM portfolio.Portfolios p
JOIN portfolio.Users u ON p.UserID = u.UserID
CROSS JOIN portfolio.Assets a
WHERE u.Email = 'joao.silva@email.com'
AND a.Symbol = 'AAPL';

INSERT INTO portfolio.Transactions (PortfolioID, AssetID, TransactionType, Quantity, Price, TransactionDate)
SELECT 
    p.PortfolioID,
    a.AssetID,
    'Buy',
    5,
    410.25,
    DATEADD(day, -15, GETDATE())
FROM portfolio.Portfolios p
JOIN portfolio.Users u ON p.UserID = u.UserID
CROSS JOIN portfolio.Assets a
WHERE u.Email = 'joao.silva@email.com'
AND a.Symbol = 'MSFT';

-- Maria's transactions
INSERT INTO portfolio.Transactions (PortfolioID, AssetID, TransactionType, Quantity, Price, TransactionDate)
SELECT 
    p.PortfolioID,
    a.AssetID,
    'Buy',
    2,
    850.75,
    DATEADD(day, -20, GETDATE())
FROM portfolio.Portfolios p
JOIN portfolio.Users u ON p.UserID = u.UserID
CROSS JOIN portfolio.Assets a
WHERE u.Email = 'maria.santos@email.com'
AND a.Symbol = 'NVDA';

-- Assets
INSERT INTO portfolio.Assets (Name, Symbol, AssetType, Price, Volume, AvailableShares)
VALUES
('Apple Inc.', 'AAPL', 'Company', 180.50, 1000000, 500000.000000),
('Microsoft Corp.', 'MSFT', 'Company', 320.10, 800000, 400000.000000),
('S&P 500', 'SPX', 'Index', 4200.00, 200000, 100000.000000),
('Bitcoin', 'BTC', 'Cryptocurrency', 65000.00, 21000000, 19000000.000000),
('Gold', 'XAU', 'Commodity', 2300.00, 50000, 50000.000000),
('Euro Stoxx 50', 'SX5E', 'Index', 4300.00, 100000, 80000.000000),
('Ethereum', 'ETH', 'Cryptocurrency', 3500.00, 120000000, 110000000.000000),
('Tesla Inc.', 'TSLA', 'Company', 900.00, 500000, 300000.000000);
GO

-- Asset Prices (history)
INSERT INTO portfolio.AssetPrices (AssetID, Price, AsOf)
VALUES
(1, 175.00, '2024-05-01'), (1, 180.50, '2024-05-24'),
(2, 310.00, '2024-05-01'), (2, 320.10, '2024-05-24'),
(3, 4100.00, '2024-05-01'), (3, 4200.00, '2024-05-24'),
(4, 60000.00, '2024-05-01'), (4, 65000.00, '2024-05-24'),
(5, 2200.00, '2024-05-01'), (5, 2300.00, '2024-05-24'),
(6, 4200.00, '2024-05-01'), (6, 4300.00, '2024-05-24'),
(7, 3000.00, '2024-05-01'), (7, 3500.00, '2024-05-24'),
(8, 850.00, '2024-05-01'), (8, 900.00, '2024-05-24');
GO

-- Company Details
INSERT INTO portfolio.CompanyDetails (AssetID, Sector, Industry, Country)
VALUES
(1, 'Technology', 'Consumer Electronics', 'USA'),
(2, 'Technology', 'Software', 'USA'),
(8, 'Automotive', 'Electric Vehicles', 'USA');
GO

-- Index Details
INSERT INTO portfolio.IndexDetails (AssetID, Country)
VALUES
(3, 'USA'),
(6, 'Europe');
GO

-- Transactions
DECLARE @AliceID UNIQUEIDENTIFIER = '7d1d74f3-5b5d-4bf9-9c9d-9c9d9c9d9c9d';
DECLARE @BobID UNIQUEIDENTIFIER = '8e2e85f4-6c6e-5cf0-0d0e-0d0e0d0e0d0e';
DECLARE @CarlosID UNIQUEIDENTIFIER = '9f3f96f5-7d7f-6df1-1e1f-1e1f1e1f1e1f';
DECLARE @DianaID UNIQUEIDENTIFIER = 'a04fa7f6-8e8f-7ef2-2f2f-2f2f2f2f2f2f';
DECLARE @EvaID UNIQUEIDENTIFIER = 'b15fb8f7-9f9f-8ff3-3f3f-3f3f3f3f3f3f';

INSERT INTO portfolio.Transactions (UserID, PortfolioID, AssetID, TransactionType, Quantity, UnitPrice, TransactionDate)
VALUES
(@AliceID, 1, 1, 'Buy', 10.000000, 170.00, '2024-05-01'),
(@AliceID, 1, 2, 'Buy', 5.000000, 300.00, '2024-05-02'),
(@AliceID, 2, 4, 'Buy', 0.100000, 60000.00, '2024-05-03'),
(@BobID, 3, 3, 'Buy', 2.000000, 4000.00, '2024-05-04'),
(@CarlosID, 4, 5, 'Buy', 1.000000, 2100.00, '2024-05-05'),
(@DianaID, 5, 6, 'Buy', 3.000000, 4100.00, '2024-05-06'),
(@EvaID, 6, 7, 'Buy', 5.000000, 3200.00, '2024-05-07'),
(@AliceID, 1, 1, 'Sell', 2.000000, 180.00, '2024-05-10'),
(@BobID, 3, 3, 'Sell', 1.000000, 4200.00, '2024-05-12'),
(@CarlosID, 4, 5, 'Sell', 0.500000, 2300.00, '2024-05-13');
GO

-- Subscriptions
DECLARE @AliceID UNIQUEIDENTIFIER = '7d1d74f3-5b5d-4bf9-9c9d-9c9d9c9d9c9d';
DECLARE @CarlosID UNIQUEIDENTIFIER = '9f3f96f5-7d7f-6df1-1e1f-1e1f1e1f1e1f';
DECLARE @EvaID UNIQUEIDENTIFIER = 'b15fb8f7-9f9f-8ff3-3f3f-3f3f3f3f3f3f';

INSERT INTO portfolio.Subscriptions (UserID, StartDate, EndDate, AmountPaid)
VALUES
(@AliceID, '2024-01-01', '2025-01-01', 99.99),
(@CarlosID, '2024-02-01', '2025-02-01', 99.99),
(@EvaID, '2024-03-01', '2025-03-01', 99.99);
GO

-- Risk Metrics
DECLARE @AliceID UNIQUEIDENTIFIER = '7d1d74f3-5b5d-4bf9-9c9d-9c9d9c9d9c9d';
DECLARE @BobID UNIQUEIDENTIFIER = '8e2e85f4-6c6e-5cf0-0d0e-0d0e0d0e0d0e';
DECLARE @CarlosID UNIQUEIDENTIFIER = '9f3f96f5-7d7f-6df1-1e1f-1e1f1e1f1e1f';
DECLARE @DianaID UNIQUEIDENTIFIER = 'a04fa7f6-8e8f-7ef2-2f2f-2f2f2f2f2f2f';
DECLARE @EvaID UNIQUEIDENTIFIER = 'b15fb8f7-9f9f-8ff3-3f3f-3f3f3f3f3f3f';

INSERT INTO portfolio.RiskMetrics (UserID, MaximumDrawdown, Beta, SharpeRatio, AbsoluteReturn, CapturedAt)
VALUES
(@AliceID, -10.5, 1.2, 1.5, 12.0, '2024-05-24'),
(@BobID, -5.0, 0.9, 1.1, 8.0, '2024-05-24'),
(@CarlosID, -7.2, 1.0, 1.3, 10.0, '2024-05-24'),
(@DianaID, -12.0, 1.4, 1.7, 15.0, '2024-05-24'),
(@EvaID, -8.3, 1.1, 1.2, 9.5, '2024-05-24');
GO

-- Payment Methods
DECLARE @AliceID UNIQUEIDENTIFIER = '7d1d74f3-5b5d-4bf9-9c9d-9c9d9c9d9c9d';
DECLARE @BobID UNIQUEIDENTIFIER = '8e2e85f4-6c6e-5cf0-0d0e-0d0e0d0e0d0e';
DECLARE @CarlosID UNIQUEIDENTIFIER = '9f3f96f5-7d7f-6df1-1e1f-1e1f1e1f1e1f';
DECLARE @DianaID UNIQUEIDENTIFIER = 'a04fa7f6-8e8f-7ef2-2f2f-2f2f2f2f2f2f';
DECLARE @EvaID UNIQUEIDENTIFIER = 'b15fb8f7-9f9f-8ff3-3f3f-3f3f3f3f3f3f';

INSERT INTO portfolio.PaymentMethods (UserID, MethodType, Details)
VALUES
(@AliceID, 'Credit Card', 'Visa **** 1234'),
(@BobID, 'Bank Transfer', 'IBAN: ES9121000418450200051332'),
(@CarlosID, 'PayPal', 'carlos@paypal.com'),
(@DianaID, 'Credit Card', 'Mastercard **** 5678'),
(@EvaID, 'Bank Transfer', 'IBAN: DE89370400440532013000');
GO 
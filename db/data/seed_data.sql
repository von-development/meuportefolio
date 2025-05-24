-- meuPortfolio Seed Data Script
-- Run this after the schema is created to populate the database with sample data

USE meuportefolio;
GO

-- Users
INSERT INTO portfolio.Users (Name, Email, PasswordHash, CountryOfResidence, IBAN, UserType)
VALUES
('Alice Smith', 'alice@example.com', '$argon2id$v=19$m=4096,t=3,p=1$abc$xyz', 'Portugal', 'PT50000201231234567890154', 'Premium'),
('Bob Johnson', 'bob@example.com', '$argon2id$v=19$m=4096,t=3,p=1$def$uvw', 'Spain', 'ES9121000418450200051332', 'Basic'),
('Carlos Silva', 'carlos@example.com', '$argon2id$v=19$m=4096,t=3,p=1$ghi$rst', 'Brazil', 'BR1500000000000010932840814P2', 'Premium'),
('Diana Costa', 'diana@example.com', '$argon2id$v=19$m=4096,t=3,p=1$jkl$opq', 'France', 'FR7630006000011234567890189', 'Basic'),
('Eva Müller', 'eva@example.com', '$argon2id$v=19$m=4096,t=3,p=1$mno$lmn', 'Germany', 'DE89370400440532013000', 'Premium');
GO

-- Portfolios
INSERT INTO portfolio.Portfolios (UserID, Name)
VALUES
(1, 'Alice Growth'),
(1, 'Alice Crypto'),
(2, 'Bob Retirement'),
(3, 'Carlos Main'),
(4, 'Diana Index'),
(5, 'Eva Wealth');
GO

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
INSERT INTO portfolio.Transactions (UserID, PortfolioID, AssetID, TransactionType, Quantity, UnitPrice, TransactionDate)
VALUES
(1, 1, 1, 'Buy', 10.000000, 170.00, '2024-05-01'),
(1, 1, 2, 'Buy', 5.000000, 300.00, '2024-05-02'),
(1, 2, 4, 'Buy', 0.100000, 60000.00, '2024-05-03'),
(2, 3, 3, 'Buy', 2.000000, 4000.00, '2024-05-04'),
(3, 4, 5, 'Buy', 1.000000, 2100.00, '2024-05-05'),
(4, 5, 6, 'Buy', 3.000000, 4100.00, '2024-05-06'),
(5, 6, 7, 'Buy', 5.000000, 3200.00, '2024-05-07'),
(1, 1, 1, 'Sell', 2.000000, 180.00, '2024-05-10'),
(2, 3, 3, 'Sell', 1.000000, 4200.00, '2024-05-12'),
(3, 4, 5, 'Sell', 0.500000, 2300.00, '2024-05-13');
GO

-- Subscriptions
INSERT INTO portfolio.Subscriptions (UserID, StartDate, EndDate, AmountPaid)
VALUES
(1, '2024-01-01', '2025-01-01', 99.99),
(3, '2024-02-01', '2025-02-01', 99.99),
(5, '2024-03-01', '2025-03-01', 99.99);
GO

-- Risk Metrics
INSERT INTO portfolio.RiskMetrics (UserID, MaximumDrawdown, Beta, SharpeRatio, AbsoluteReturn, CapturedAt)
VALUES
(1, -10.5, 1.2, 1.5, 12.0, '2024-05-24'),
(2, -5.0, 0.9, 1.1, 8.0, '2024-05-24'),
(3, -7.2, 1.0, 1.3, 10.0, '2024-05-24'),
(4, -12.0, 1.4, 1.7, 15.0, '2024-05-24'),
(5, -8.3, 1.1, 1.2, 9.5, '2024-05-24');
GO

-- Payment Methods
INSERT INTO portfolio.PaymentMethods (UserID, MethodType, Details)
VALUES
(1, 'Credit Card', 'Visa **** 1234'),
(2, 'Bank Transfer', 'IBAN: ES9121000418450200051332'),
(3, 'PayPal', 'carlos@paypal.com'),
(4, 'Credit Card', 'Mastercard **** 5678'),
(5, 'Bank Transfer', 'IBAN: DE89370400440532013000');
GO 
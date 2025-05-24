-- meuPortfolio Seed Data Script
-- Run this after the schema is created to populate the database with sample data

USE meuPortfolio;
GO

-- Users
INSERT INTO portfolio.Users (Name, Email, Password, CountryOfResidence, IBAN, UserType)
VALUES
('Alice Silva', 'alice@example.com', 'hashedpassword1', 'Portugal', 'PT50000000000000000000001', 'Premium'),
('Bob Costa', 'bob@example.com', 'hashedpassword2', 'Spain', 'ES50000000000000000000002', 'Basic'),
('Carlos Dias', 'carlos@example.com', 'hashedpassword3', 'Brazil', 'BR50000000000000000000003', 'Premium');
GO

-- Portfolios
INSERT INTO portfolio.Portfolios (UserID, Name)
VALUES
(1, 'Alice Portfolio'),
(2, 'Bob Portfolio'),
(3, 'Carlos Portfolio');
GO

-- Assets
INSERT INTO portfolio.Assets (Name, Symbol, AssetType, Price, MinimumValue, MaximumValue, OpeningValue, ChangePercentage, Volume, AvailableShares)
VALUES
('TechCorp', 'TCO', 'Company', 150.00, 120.00, 180.00, 140.00, 2.5, 1000000, 50000.000000),
('GlobalIndex', 'GIX', 'Index', 2500.00, 2000.00, 3000.00, 2400.00, 1.2, 500000, 100000.000000),
('BitSample', 'BTC', 'Cryptocurrency', 30000.00, 25000.00, 35000.00, 29000.00, 3.0, 20000, 21000.000000),
('Gold', 'GLD', 'Commodity', 1800.00, 1700.00, 1900.00, 1750.00, 0.8, 10000, 5000.000000);
GO

-- CompanyDetails
INSERT INTO portfolio.CompanyDetails (AssetID, Sector, Industry, Country)
VALUES
(1, 'Technology', 'Software', 'Portugal');
GO

-- IndexDetails
INSERT INTO portfolio.IndexDetails (AssetID, Country)
VALUES
(2, 'Global');
GO

-- Transactions
INSERT INTO portfolio.Transactions (UserID, PortfolioID, AssetID, TransactionType, PercentageOfStock)
VALUES
(1, 1, 1, 'Buy', 10.00),
(1, 1, 3, 'Buy', 0.50),
(2, 2, 2, 'Buy', 5.00),
(3, 3, 4, 'Buy', 2.00),
(1, 1, 1, 'Sell', 2.00);
GO

-- Subscriptions
INSERT INTO portfolio.Subscriptions (UserID, StartDate, EndDate, Value)
VALUES
(1, '2024-01-01', '2025-01-01', 99.99),
(3, '2024-02-01', '2025-02-01', 99.99);
GO

-- RiskMetrics
INSERT INTO portfolio.RiskMetrics (UserID, MaximumDrawdown, Beta, SharpeRatio, AbsoluteReturn, CurrentDate)
VALUES
(1, -12.5, 1.1, 0.95, 8.2, GETDATE()),
(2, -8.0, 0.9, 1.05, 5.7, GETDATE()),
(3, -15.0, 1.2, 0.85, 10.0, GETDATE());
GO

-- PaymentMethods
INSERT INTO portfolio.PaymentMethods (UserID, MethodType, Details)
VALUES
(1, 'Credit Card', 'Visa ending in 1234'),
(2, 'PayPal', 'bob@paypal.com'),
(3, 'Bank Transfer', 'IBAN: BR50000000000000000000003');
GO 
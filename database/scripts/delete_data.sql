USE p6g4;
GO

-- Delete data from child tables first
DELETE FROM portfolio.ApplicationLogs;

DELETE FROM portfolio.RiskMetrics;

DELETE FROM portfolio.FundTransactions;

DELETE FROM portfolio.PortfolioHoldings;

DELETE FROM portfolio.Transactions;

DELETE FROM portfolio.AssetPrices;

DELETE FROM portfolio.StockDetails;

DELETE FROM portfolio.CryptoDetails;

DELETE FROM portfolio.CommodityDetails;

DELETE FROM portfolio.IndexDetails;

DELETE FROM portfolio.Assets;

DELETE FROM portfolio.Portfolios;

DELETE FROM portfolio.Users;

PRINT 'All data deleted successfully!';
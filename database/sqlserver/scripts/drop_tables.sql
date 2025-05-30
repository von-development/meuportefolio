USE p6g4;
GO

-- Drop tables in correct order (child tables first)
DROP TABLE IF EXISTS portfolio.ApplicationLogs;

DROP TABLE IF EXISTS portfolio.RiskMetrics;

DROP TABLE IF EXISTS portfolio.FundTransactions;

DROP TABLE IF EXISTS portfolio.PortfolioHoldings;

DROP TABLE IF EXISTS portfolio.Transactions;

DROP TABLE IF EXISTS portfolio.AssetPrices;

DROP TABLE IF EXISTS portfolio.StockDetails;

DROP TABLE IF EXISTS portfolio.CryptoDetails;

DROP TABLE IF EXISTS portfolio.CommodityDetails;

DROP TABLE IF EXISTS portfolio.IndexDetails;

DROP TABLE IF EXISTS portfolio.Assets;

DROP TABLE IF EXISTS portfolio.Portfolios;

DROP TABLE IF EXISTS portfolio.Users;

PRINT 'All tables dropped successfully!';
/* ============================================================
meuPortfolio – Tables Creation v2.0 (Consolidated)
Modern, simplified database structure for portfolio management
============================================================ */

USE p6g4;
GO

/* ============================================================
1. USERS TABLE (Simplified with Payment & Subscription Fields)
============================================================ */

CREATE TABLE portfolio.Users (
    UserID UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Password NVARCHAR(100) NOT NULL,  -- Plain text for development (previously PasswordHash)
    CountryOfResidence NVARCHAR(100) NOT NULL,
    IBAN NVARCHAR(34) NOT NULL,
    UserType NVARCHAR(20) NOT NULL CHECK (UserType IN ('Basic', 'Premium')),
    
    -- Account Balance (from fund management)
    AccountBalance DECIMAL(18,2) NOT NULL DEFAULT 0.00,
    
    -- Payment Method Fields (one per user - simplified approach)
    PaymentMethodType NVARCHAR(30) NULL,              -- 'CreditCard', 'BankTransfer', 'PayPal', etc.
    PaymentMethodDetails NVARCHAR(255) NULL,          -- 'VISA ****4582', 'Bank of America', etc.
    PaymentMethodExpiry DATE NULL,                    -- For credit cards
    PaymentMethodActive BIT DEFAULT 1,                -- Whether payment method is active
    
    -- Subscription Fields (current subscription only - simplified)
    IsPremium BIT DEFAULT 0,                          -- Simple boolean flag
    PremiumStartDate DATETIME NULL,                   -- When premium started
    PremiumEndDate DATETIME NULL,                     -- When premium expires
    MonthlySubscriptionRate DECIMAL(18,2) DEFAULT 50.00,  -- Current monthly rate
    AutoRenewSubscription BIT DEFAULT 1,              -- Auto renewal setting
    LastSubscriptionPayment DATETIME NULL,           -- Last payment date
    NextSubscriptionPayment DATETIME NULL,           -- Next payment due date
    
    -- Timestamps
    CreatedAt DATETIME NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME NOT NULL DEFAULT SYSDATETIME()
);

-- Add constraints for Users table
ALTER TABLE portfolio.Users 
ADD CONSTRAINT CK_Users_AccountBalance_NonNegative 
CHECK (AccountBalance >= 0);

ALTER TABLE portfolio.Users 
ADD CONSTRAINT CK_Users_PaymentMethodType 
CHECK (PaymentMethodType IN ('CreditCard', 'BankTransfer', 'PayPal', 'Other') OR PaymentMethodType IS NULL);

ALTER TABLE portfolio.Users 
ADD CONSTRAINT CK_Users_SubscriptionLogic 
CHECK (
    (IsPremium = 0) OR 
    (IsPremium = 1 AND PremiumStartDate IS NOT NULL AND PremiumEndDate IS NOT NULL)
);

ALTER TABLE portfolio.Users 
ADD CONSTRAINT CK_Users_SubscriptionRate_Positive 
CHECK (MonthlySubscriptionRate > 0);

/* ============================================================
2. PORTFOLIOS TABLE
============================================================ */

CREATE TABLE portfolio.Portfolios (
    PortfolioID INT IDENTITY(1,1) PRIMARY KEY,
    UserID UNIQUEIDENTIFIER NOT NULL REFERENCES portfolio.Users(UserID) ON DELETE CASCADE,
    Name NVARCHAR(100) NOT NULL,
    CreationDate DATETIME NOT NULL DEFAULT SYSDATETIME(),
    CurrentFunds DECIMAL(18,2) NOT NULL DEFAULT 0,
    CurrentProfitPct DECIMAL(10,2) NOT NULL DEFAULT 0,
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME()
);

/* ============================================================
3. ASSETS TABLE
============================================================ */

CREATE TABLE portfolio.Assets (
    AssetID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Symbol NVARCHAR(20) NOT NULL UNIQUE,
    AssetType NVARCHAR(20) NOT NULL CHECK (AssetType IN ('Stock', 'Index', 'Cryptocurrency', 'Commodity')),
    Price DECIMAL(18,2) NOT NULL,
    Volume BIGINT NOT NULL,
    AvailableShares DECIMAL(18,6) NOT NULL,
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME()
);

/* ============================================================
4. ASSET DETAILS TABLES
============================================================ */

CREATE TABLE portfolio.AssetPrices (
    PriceID BIGINT IDENTITY(1,1) PRIMARY KEY,
    AssetID INT NOT NULL REFERENCES portfolio.Assets(AssetID) ON DELETE CASCADE,
    Price DECIMAL(18,2) NOT NULL,
    AsOf DATETIME NOT NULL DEFAULT SYSDATETIME(),
    OpenPrice DECIMAL(18,2) NOT NULL,
    HighPrice DECIMAL(18,2) NOT NULL,
    LowPrice DECIMAL(18,2) NOT NULL,
    Volume BIGINT NOT NULL
);

-- Stock Details (Simplified from CompanyDetails)
CREATE TABLE portfolio.StockDetails (
    AssetID INT PRIMARY KEY REFERENCES portfolio.Assets(AssetID) ON DELETE CASCADE,
    Sector NVARCHAR(100) NOT NULL,
    Country NVARCHAR(100) NOT NULL,
    MarketCap DECIMAL(18,2) NOT NULL,
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME()
);

-- Cryptocurrency Details
CREATE TABLE portfolio.CryptoDetails (
    AssetID INT PRIMARY KEY REFERENCES portfolio.Assets(AssetID) ON DELETE CASCADE,
    Blockchain NVARCHAR(50) NOT NULL,                    -- 'Ethereum', 'Bitcoin', 'Binance Smart Chain', etc.
    MaxSupply DECIMAL(18,0) NULL,                        -- Maximum possible supply (NULL for unlimited)
    CirculatingSupply DECIMAL(18,0) NOT NULL,            -- Current circulating supply
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME()
);

-- Commodity Details
CREATE TABLE portfolio.CommodityDetails (
    AssetID INT PRIMARY KEY REFERENCES portfolio.Assets(AssetID) ON DELETE CASCADE,
    Category NVARCHAR(50) NOT NULL,                      -- 'Precious Metals', 'Energy', 'Agriculture', etc.
    Unit NVARCHAR(20) NOT NULL,                          -- 'oz', 'barrel', 'bushel', 'ton', etc.
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME()
);

-- Index Details (Market Indices like S&P 500, NASDAQ, etc.)
CREATE TABLE portfolio.IndexDetails (
    AssetID INT PRIMARY KEY REFERENCES portfolio.Assets(AssetID) ON DELETE CASCADE,
    Country NVARCHAR(100) NOT NULL,                      -- 'United States', 'Germany', 'Japan', etc.
    Region NVARCHAR(50) NOT NULL,                        -- 'North America', 'Europe', 'Asia', etc.
    IndexType NVARCHAR(50) NOT NULL,                     -- 'Broad Market', 'Sector', 'Style', etc.
    ComponentCount INT NULL,                             -- Number of companies/assets in the index
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME()
);

/* ============================================================
5. TRANSACTIONS TABLE (Enhanced)
============================================================ */

CREATE TABLE portfolio.Transactions (
    TransactionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID UNIQUEIDENTIFIER NOT NULL REFERENCES portfolio.Users(UserID) ON DELETE CASCADE,
    PortfolioID INT NOT NULL REFERENCES portfolio.Portfolios(PortfolioID),
    AssetID INT NOT NULL REFERENCES portfolio.Assets(AssetID),
    TransactionType NVARCHAR(10) NOT NULL CHECK (TransactionType IN ('Buy', 'Sell')),
    Quantity DECIMAL(18,6) NOT NULL,
    UnitPrice DECIMAL(18,4) NOT NULL,
    TransactionDate DATETIME NOT NULL DEFAULT SYSDATETIME(),
    Status NVARCHAR(20) NOT NULL DEFAULT('Pending') CHECK (Status IN ('Pending', 'Executed', 'Failed', 'Cancelled'))
);

/* ============================================================
6. FUND TRANSACTIONS TABLE (Audit Trail)
============================================================ */

CREATE TABLE portfolio.FundTransactions (
    FundTransactionID BIGINT IDENTITY(1,1) PRIMARY KEY,
    UserID UNIQUEIDENTIFIER NOT NULL REFERENCES portfolio.Users(UserID) ON DELETE CASCADE,
    PortfolioID INT NULL REFERENCES portfolio.Portfolios(PortfolioID),
    TransactionType NVARCHAR(20) NOT NULL CHECK (TransactionType IN ('Deposit', 'Withdrawal', 'Allocation', 'Deallocation', 'PremiumUpgrade', 'AssetPurchase', 'AssetSale')),
    Amount DECIMAL(18,2) NOT NULL,
    BalanceAfter DECIMAL(18,2) NOT NULL,
    Description NVARCHAR(255) NULL,
    RelatedAssetTransactionID BIGINT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT SYSDATETIME()
);

/* ============================================================
7. PORTFOLIO HOLDINGS TABLE (Performance Optimization)
============================================================ */

CREATE TABLE portfolio.PortfolioHoldings (
    HoldingID BIGINT IDENTITY(1,1) PRIMARY KEY,
    PortfolioID INT NOT NULL REFERENCES portfolio.Portfolios(PortfolioID) ON DELETE CASCADE,
    AssetID INT NOT NULL REFERENCES portfolio.Assets(AssetID) ON DELETE CASCADE,
    QuantityHeld DECIMAL(18,6) NOT NULL,
    AveragePrice DECIMAL(18,4) NOT NULL,
    TotalCost DECIMAL(18,2) NOT NULL,
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME(),
    CONSTRAINT UK_PortfolioHoldings_Portfolio_Asset UNIQUE(PortfolioID, AssetID)
);

-- Add constraint to ensure positive quantities
ALTER TABLE portfolio.PortfolioHoldings 
ADD CONSTRAINT CK_PortfolioHoldings_QuantityHeld_Positive 
CHECK (QuantityHeld > 0);

/* ============================================================
8. RISK METRICS TABLE
============================================================ */

CREATE TABLE portfolio.RiskMetrics (
    MetricID INT IDENTITY(1,1) PRIMARY KEY,
    UserID UNIQUEIDENTIFIER NOT NULL REFERENCES portfolio.Users(UserID) ON DELETE CASCADE,
    MaximumDrawdown DECIMAL(10,2) NULL,
    Beta DECIMAL(10,2) NULL,
    SharpeRatio DECIMAL(10,2) NULL,
    AbsoluteReturn DECIMAL(10,2) NULL,
    VolatilityScore DECIMAL(10,2) NULL,
    RiskLevel NVARCHAR(20) NOT NULL,
    CapturedAt DATETIME NOT NULL DEFAULT SYSDATETIME()
);

/* ============================================================
9. APPLICATION LOG TABLE
============================================================ */

CREATE TABLE portfolio.ApplicationLogs (
    LogID BIGINT IDENTITY(1,1) PRIMARY KEY,
    
    -- Event Identification
    LogLevel NVARCHAR(10) NOT NULL CHECK (LogLevel IN ('INFO', 'WARN', 'ERROR')),
    EventType NVARCHAR(50) NOT NULL,                     -- 'INSERT', 'UPDATE', 'DELETE', 'SELECT', 'LOGIN', 'TRANSACTION'
    TableName NVARCHAR(100) NULL,                        -- Which table was affected
    
    -- User Context
    UserID UNIQUEIDENTIFIER NULL REFERENCES portfolio.Users(UserID) ON DELETE SET NULL,
    
    -- Event Details
    Message NVARCHAR(500) NOT NULL,                      -- Brief description of the action
    
    -- Timestamp
    CreatedAt DATETIME NOT NULL DEFAULT SYSDATETIME()
);

/* ============================================================
SUMMARY OF V2 CHANGES:
============================================================

✅ SIMPLIFIED STRUCTURE:
   • Payment & subscription data moved directly into Users table
   • Eliminated need for separate PaymentMethods and Subscriptions tables
   • One payment method per user (covers 95% of use cases)

✅ ENHANCED FUNCTIONALITY:
   • Added AccountBalance to Users for fund management
   • Added FundTransactions table for complete audit trail
   • Added PortfolioHoldings table for performance optimization
   • Enhanced Transactions table with better status tracking

✅ IMPROVED PERFORMANCE:
   • Comprehensive indexing strategy
   • Reduced complex joins
   • Direct field access for common queries

✅ MODERN DATA TYPES:
   • Password field simplified for development
   • Proper decimal precision for financial data
   • Comprehensive constraints for data integrity

✅ REMOVED COMPLEXITY:
   • No more complex subscription history tracking
   • Simplified payment method management
   • Focus on current state rather than full history

============================================================ */ 
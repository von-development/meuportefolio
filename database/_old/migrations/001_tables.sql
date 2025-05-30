/* ------------------------------------------------------------
meuPortfolio – Tables Creation  (v2025-05-24)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
1. Users and Core Tables
============================================================ */

CREATE TABLE portfolio.Users (
    UserID UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash CHAR(60) NOT NULL,
    CountryOfResidence NVARCHAR(100) NOT NULL,
    IBAN NVARCHAR(34) NOT NULL,
    UserType NVARCHAR(20) NOT NULL CHECK (UserType IN ('Basic', 'Premium')),
    CreatedAt DATETIME NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME NOT NULL DEFAULT SYSDATETIME()
);

CREATE TABLE portfolio.Portfolios (
    PortfolioID INT IDENTITY(1,1) PRIMARY KEY,
    UserID UNIQUEIDENTIFIER NOT NULL REFERENCES portfolio.Users(UserID) ON DELETE CASCADE,
    Name NVARCHAR(100) NOT NULL,
    CreationDate DATETIME NOT NULL DEFAULT SYSDATETIME(),
    CurrentFunds DECIMAL(18,2) NOT NULL DEFAULT 0,
    CurrentProfitPct DECIMAL(10,2) NOT NULL DEFAULT 0,
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME()
);

CREATE TABLE portfolio.Assets (
    AssetID INT IDENTITY(1,1) PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Symbol NVARCHAR(20) NOT NULL UNIQUE,
    AssetType NVARCHAR(20) NOT NULL CHECK (AssetType IN ('Company', 'Index', 'Cryptocurrency', 'Commodity')),
    Price DECIMAL(18,2) NOT NULL,
    Volume BIGINT NOT NULL,
    AvailableShares DECIMAL(18,6) NOT NULL,
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME()
);

/* ============================================================
2. Asset Details Tables
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

CREATE TABLE portfolio.CompanyDetails (
    AssetID INT PRIMARY KEY REFERENCES portfolio.Assets(AssetID) ON DELETE CASCADE,
    Sector NVARCHAR(100) NOT NULL,
    Industry NVARCHAR(100) NOT NULL,
    Country NVARCHAR(100) NOT NULL,
    MarketCap DECIMAL(18,2) NOT NULL,
    EmployeeCount INT NULL,
    YearFounded INT NULL,
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME()
);

CREATE TABLE portfolio.IndexDetails (
    AssetID INT PRIMARY KEY REFERENCES portfolio.Assets(AssetID) ON DELETE CASCADE,
    Country NVARCHAR(100) NOT NULL,
    Region NVARCHAR(100) NOT NULL,
    Methodology NVARCHAR(MAX) NOT NULL,
    NumberOfComponents INT NOT NULL,
    RebalanceFrequency NVARCHAR(50) NOT NULL,
    BaseValue DECIMAL(18,2) NOT NULL,
    BaseDate DATE NOT NULL,
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME()
);

/* ============================================================
3. Transaction and Subscription Tables
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
    Status NVARCHAR(20) NOT NULL DEFAULT('Pending')
);

CREATE TABLE portfolio.Subscriptions (
    SubscriptionID INT IDENTITY(1,1) PRIMARY KEY,
    UserID UNIQUEIDENTIFIER NOT NULL UNIQUE REFERENCES portfolio.Users(UserID) ON DELETE CASCADE,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    AmountPaid DECIMAL(18,2) NOT NULL,
    PaymentStatus NVARCHAR(20) NOT NULL DEFAULT('Pending'),
    CreatedAt DATETIME NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME NOT NULL DEFAULT SYSDATETIME()
);

/* ============================================================
4. Risk and Payment Tables
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

CREATE TABLE portfolio.PaymentMethods (
    PaymentMethodID INT IDENTITY(1,1) PRIMARY KEY,
    UserID UNIQUEIDENTIFIER NOT NULL REFERENCES portfolio.Users(UserID) ON DELETE CASCADE,
    MethodType NVARCHAR(50) NOT NULL,
    Details NVARCHAR(255) NOT NULL,
    IsDefault BIT NOT NULL DEFAULT(0),
    LastUsed DATETIME NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT('Active'),
    ValidationDate DATE NOT NULL,
    CreatedAt DATETIME NOT NULL DEFAULT SYSDATETIME(),
    UpdatedAt DATETIME NOT NULL DEFAULT SYSDATETIME()
);

/* ============================================================
5. Indexes
============================================================ */

CREATE NONCLUSTERED INDEX IX_Users_Email 
ON portfolio.Users(Email);

CREATE NONCLUSTERED INDEX IX_Users_UserType 
ON portfolio.Users(UserType);

CREATE NONCLUSTERED INDEX IX_Assets_Symbol 
ON portfolio.Assets(Symbol);

CREATE NONCLUSTERED INDEX IX_Assets_AssetType 
ON portfolio.Assets(AssetType);

CREATE NONCLUSTERED INDEX IX_Transactions_PortfolioAsset 
ON portfolio.Transactions(PortfolioID, AssetID);

CREATE NONCLUSTERED INDEX IX_Transactions_Date 
ON portfolio.Transactions(TransactionDate);

CREATE NONCLUSTERED INDEX IX_AssetPrices_AssetID_AsOf 
ON portfolio.AssetPrices(AssetID, AsOf DESC);

/* ----------------  END OF SCRIPT ---------------- */ 
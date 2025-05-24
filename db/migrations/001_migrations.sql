/* ------------------------------------------------------------
meuPortfolio – full schema  (v2025-05-24)
------------------------------------------------------------
Tested on SQL Server 2022.
------------------------------------------------------------ */

USE master;
GO
IF DB_ID(N'meuportefolio') IS NULL
BEGIN
    CREATE DATABASE meuportefolio;
END
GO
USE meuportefolio;
GO

-- Drop views
IF OBJECT_ID('portfolio.vw_PortfolioSummary', 'V') IS NOT NULL DROP VIEW portfolio.vw_PortfolioSummary;
IF OBJECT_ID('portfolio.vw_AssetHoldings', 'V') IS NOT NULL DROP VIEW portfolio.vw_AssetHoldings;
GO

-- Drop triggers
IF OBJECT_ID('portfolio.TR_Users_UpdateTimestamp', 'TR') IS NOT NULL DROP TRIGGER portfolio.TR_Users_UpdateTimestamp;
IF OBJECT_ID('portfolio.TR_Assets_UpdateTimestamp', 'TR') IS NOT NULL DROP TRIGGER portfolio.TR_Assets_UpdateTimestamp;
GO

-- Drop procedures
IF OBJECT_ID('portfolio.sp_CreateUser', 'P') IS NOT NULL DROP PROCEDURE portfolio.sp_CreateUser;
IF OBJECT_ID('portfolio.sp_CreatePortfolio', 'P') IS NOT NULL DROP PROCEDURE portfolio.sp_CreatePortfolio;
IF OBJECT_ID('portfolio.sp_ExecuteTransaction', 'P') IS NOT NULL DROP PROCEDURE portfolio.sp_ExecuteTransaction;
IF OBJECT_ID('portfolio.sp_UpdateAssetPrice', 'P') IS NOT NULL DROP PROCEDURE portfolio.sp_UpdateAssetPrice;
GO

-- Drop functions
IF OBJECT_ID('portfolio.fn_PortfolioMarketValue', 'FN') IS NOT NULL DROP FUNCTION portfolio.fn_PortfolioMarketValue;
IF OBJECT_ID('portfolio.fn_PortfolioProfitPct', 'FN') IS NOT NULL DROP FUNCTION portfolio.fn_PortfolioProfitPct;
GO

-- Drop tables (reverse dependency order)
DROP TABLE IF EXISTS portfolio.PaymentMethods;
DROP TABLE IF EXISTS portfolio.RiskMetrics;
DROP TABLE IF EXISTS portfolio.Subscriptions;
DROP TABLE IF EXISTS portfolio.Transactions;
DROP TABLE IF EXISTS portfolio.AssetPrices;
DROP TABLE IF EXISTS portfolio.CompanyDetails;
DROP TABLE IF EXISTS portfolio.IndexDetails;
DROP TABLE IF EXISTS portfolio.Portfolios;
DROP TABLE IF EXISTS portfolio.Assets;
DROP TABLE IF EXISTS portfolio.Users;
GO

/* ------------ schema ------------- */
IF SCHEMA_ID(N'portfolio') IS NULL EXEC('CREATE SCHEMA portfolio');
GO

/* ============================================================
1. Core tables
============================================================ */

CREATE TABLE portfolio.Users (
    UserID INT IDENTITY (1, 1) PRIMARY KEY,
    Name NVARCHAR (100) NOT NULL,
    Email NVARCHAR (100) NOT NULL UNIQUE,
    -- store a bcrypt/argon2 hash, never raw text
    PasswordHash CHAR(60) NOT NULL,
    CountryOfResidence NVARCHAR (100) NOT NULL,
    IBAN NVARCHAR (34) NOT NULL,
    UserType NVARCHAR (20) NOT NULL CHECK (
        UserType IN ('Basic', 'Premium')
    ),
    CreatedAt DATETIME NOT NULL DEFAULT SYSDATETIME (),
    UpdatedAt DATETIME NOT NULL DEFAULT SYSDATETIME ()
);
GO

CREATE TABLE portfolio.Portfolios (
    PortfolioID INT IDENTITY (1, 1) PRIMARY KEY,
    UserID INT NOT NULL REFERENCES portfolio.Users (UserID) ON DELETE CASCADE,
    Name NVARCHAR (100) NOT NULL,
    CreationDate DATETIME NOT NULL DEFAULT SYSDATETIME (),
    CurrentFunds DECIMAL(18, 2) NOT NULL DEFAULT 0,
    CurrentProfitPct DECIMAL(10, 2) NOT NULL DEFAULT 0
);
GO

CREATE TABLE portfolio.Assets (
    AssetID INT IDENTITY (1, 1) PRIMARY KEY,
    Name NVARCHAR (100) NOT NULL,
    Symbol NVARCHAR (20) NOT NULL UNIQUE,
    AssetType NVARCHAR (20) NOT NULL CHECK (
        AssetType IN (
            'Company',
            'Index',
            'Cryptocurrency',
            'Commodity'
        )
    ),
    -- snapshot price (latest known)
    Price DECIMAL(18, 2) NOT NULL,
    Volume BIGINT NOT NULL,
    AvailableShares DECIMAL(18, 6) NOT NULL,
    LastUpdated DATETIME NOT NULL DEFAULT SYSDATETIME ()
);
GO

/* ---- price history ---- */
CREATE TABLE portfolio.AssetPrices (
    PriceID BIGINT IDENTITY (1, 1) PRIMARY KEY,
    AssetID INT NOT NULL REFERENCES portfolio.Assets (AssetID) ON DELETE CASCADE,
    Price DECIMAL(18, 2) NOT NULL,
    AsOf DATETIME NOT NULL DEFAULT SYSDATETIME (),
    INDEX IX_AssetPrices_AssetID_AsOf NONCLUSTERED (AssetID, AsOf DESC)
);
GO

/* ---- specialised details ---- */
CREATE TABLE portfolio.CompanyDetails (
    AssetID INT PRIMARY KEY REFERENCES portfolio.Assets (AssetID) ON DELETE CASCADE,
    Sector NVARCHAR (100),
    Industry NVARCHAR (100),
    Country NVARCHAR (100)
);

CREATE TABLE portfolio.IndexDetails (
    AssetID INT PRIMARY KEY REFERENCES portfolio.Assets (AssetID) ON DELETE CASCADE,
    Country NVARCHAR (100)
);
GO

/* ============================================================
2. Trading & subscriptions
============================================================ */

CREATE TABLE portfolio.Transactions (
    TransactionID BIGINT IDENTITY (1, 1) PRIMARY KEY,
    UserID INT NOT NULL REFERENCES portfolio.Users (UserID) ON DELETE CASCADE,
    PortfolioID INT NOT NULL REFERENCES portfolio.Portfolios (PortfolioID), -- removed ON DELETE CASCADE to avoid multiple cascade paths
    AssetID INT NOT NULL REFERENCES portfolio.Assets (AssetID),
    TransactionType NVARCHAR (10) NOT NULL CHECK (
        TransactionType IN ('Buy', 'Sell')
    ),
    Quantity DECIMAL(18, 6) NOT NULL, -- positive numbers only
    UnitPrice DECIMAL(18, 4) NOT NULL, -- price at execution
    TransactionDate DATETIME NOT NULL DEFAULT SYSDATETIME (),
    INDEX IX_Transactions_PortfolioAsset NONCLUSTERED (PortfolioID, AssetID),
    INDEX IX_Transactions_Date NONCLUSTERED (TransactionDate)
);
GO

CREATE TABLE portfolio.Subscriptions (
    SubscriptionID INT IDENTITY (1, 1) PRIMARY KEY,
    UserID INT NOT NULL UNIQUE REFERENCES portfolio.Users (UserID) ON DELETE CASCADE,
    StartDate DATETIME NOT NULL,
    EndDate DATETIME NOT NULL,
    AmountPaid DECIMAL(18, 2) NOT NULL
);
GO

CREATE TABLE portfolio.RiskMetrics (
    MetricID INT IDENTITY (1, 1) PRIMARY KEY,
    UserID INT NOT NULL REFERENCES portfolio.Users (UserID) ON DELETE CASCADE,
    MaximumDrawdown DECIMAL(10, 2),
    Beta DECIMAL(10, 2),
    SharpeRatio DECIMAL(10, 2),
    AbsoluteReturn DECIMAL(10, 2),
    CapturedAt DATETIME DEFAULT SYSDATETIME ()
);
GO

CREATE TABLE portfolio.PaymentMethods (
    PaymentMethodID INT IDENTITY (1, 1) PRIMARY KEY,
    UserID INT NOT NULL REFERENCES portfolio.Users (UserID) ON DELETE CASCADE,
    MethodType NVARCHAR (50),
    Details NVARCHAR (255)
);
GO

/* ============================================================
3. Indexes
============================================================ */
CREATE NONCLUSTERED INDEX IX_Users_Email ON portfolio.Users (Email);

CREATE NONCLUSTERED INDEX IX_Users_UserType ON portfolio.Users (UserType);

CREATE NONCLUSTERED INDEX IX_Assets_Symbol ON portfolio.Assets (Symbol);

CREATE NONCLUSTERED INDEX IX_Assets_AssetType ON portfolio.Assets (AssetType);
GO

/* ============================================================
4. Helper functions
============================================================ */
GO
CREATE OR ALTER FUNCTION portfolio.fn_PortfolioMarketValue
(@PortfolioID INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Total DECIMAL(18,2) = 0;

    SELECT @Total = SUM(t.Quantity * a.Price)
    FROM   portfolio.Transactions t
    JOIN   portfolio.Assets       a ON a.AssetID = t.AssetID
    WHERE  t.PortfolioID = @PortfolioID
    GROUP  BY t.PortfolioID;

    RETURN ISNULL(@Total, 0);
END;
GO

CREATE OR ALTER FUNCTION portfolio.fn_PortfolioProfitPct
(@PortfolioID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Cost     DECIMAL(18,2) = 0,
            @Market   DECIMAL(18,2) = 0;

    /* cost = Σ buys qty*unitPrice – Σ sells qty*unitPrice */
    SELECT @Cost = SUM(CASE WHEN t.TransactionType='Buy'
                            THEN  t.Quantity * t.UnitPrice
                            ELSE -t.Quantity * t.UnitPrice END)
    FROM   portfolio.Transactions t
    WHERE  t.PortfolioID = @PortfolioID;

    /* market value with latest prices */
    SET @Market = portfolio.fn_PortfolioMarketValue(@PortfolioID);

    RETURN CASE WHEN @Cost = 0 THEN 0
                ELSE ((@Market - @Cost) / @Cost) * 100 END;
END;
GO

/* ============================================================
5. Triggers (timestamp updates)
============================================================ */
GO
CREATE OR ALTER TRIGGER portfolio.TR_Users_UpdateTimestamp
ON portfolio.Users
AFTER UPDATE
AS
BEGIN
    UPDATE u SET UpdatedAt = SYSDATETIME()
    FROM portfolio.Users u
    JOIN inserted i ON i.UserID = u.UserID;
END;
GO

CREATE OR ALTER TRIGGER portfolio.TR_Assets_UpdateTimestamp
ON portfolio.Assets
AFTER UPDATE
AS
BEGIN
    UPDATE a SET LastUpdated = SYSDATETIME()
    FROM portfolio.Assets a
    JOIN inserted i ON i.AssetID = a.AssetID;
END;
GO

/* ============================================================
6. Views
============================================================ */
GO
CREATE
OR
ALTER VIEW portfolio.vw_PortfolioSummary AS
SELECT
    p.PortfolioID,
    p.Name AS PortfolioName,
    u.Name AS Owner,
    p.CurrentFunds,
    p.CurrentProfitPct,
    p.CreationDate,
    COUNT(t.TransactionID) AS TotalTrades
FROM portfolio.Portfolios p
    JOIN portfolio.Users u ON u.UserID = p.UserID
    LEFT JOIN portfolio.Transactions t ON t.PortfolioID = p.PortfolioID
GROUP BY
    p.PortfolioID,
    p.Name,
    u.Name,
    p.CurrentFunds,
    p.CurrentProfitPct,
    p.CreationDate;
GO

CREATE
OR
ALTER VIEW portfolio.vw_AssetHoldings AS
SELECT
    p.PortfolioID,
    p.Name AS PortfolioName,
    a.AssetID,
    a.Name AS AssetName,
    a.Symbol,
    a.AssetType,
    SUM(
        CASE
            WHEN t.TransactionType = 'Buy' THEN t.Quantity
            WHEN t.TransactionType = 'Sell' THEN - t.Quantity
        END
    ) AS QuantityHeld,
    a.Price,
    SUM(
        CASE
            WHEN t.TransactionType = 'Buy' THEN t.Quantity
            WHEN t.TransactionType = 'Sell' THEN - t.Quantity
        END
    ) * a.Price AS MarketValue
FROM portfolio.Portfolios p
    JOIN portfolio.Transactions t ON t.PortfolioID = p.PortfolioID
    JOIN portfolio.Assets a ON a.AssetID = t.AssetID
GROUP BY
    p.PortfolioID,
    p.Name,
    a.AssetID,
    a.Name,
    a.Symbol,
    a.AssetType,
    a.Price;
GO

/* ============================================================
7. Stored procedures
============================================================ */
GO
CREATE OR ALTER PROCEDURE portfolio.sp_CreateUser
    @Name NVARCHAR(100),
    @Email NVARCHAR(100),
    @PasswordHash CHAR(60),
    @CountryOfResidence NVARCHAR(100),
    @IBAN NVARCHAR(34),
    @UserType NVARCHAR(20)
AS
BEGIN
    INSERT INTO portfolio.Users
           (Name, Email, PasswordHash, CountryOfResidence, IBAN, UserType)
    VALUES (@Name,@Email,@PasswordHash,@CountryOfResidence,@IBAN,@UserType);

    SELECT SCOPE_IDENTITY() AS UserID;
END;
GO

CREATE OR ALTER PROCEDURE portfolio.sp_CreatePortfolio
    @UserID INT,
    @Name   NVARCHAR(100)
AS
BEGIN
    INSERT INTO portfolio.Portfolios (UserID, Name)
    VALUES (@UserID, @Name);

    SELECT SCOPE_IDENTITY() AS PortfolioID;
END;
GO

CREATE OR ALTER PROCEDURE portfolio.sp_ExecuteTransaction
    @UserID          INT,
    @PortfolioID     INT,
    @AssetID         INT,
    @TransactionType NVARCHAR(10),
    @Quantity        DECIMAL(18,6),
    @UnitPrice       DECIMAL(18,4)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        INSERT INTO portfolio.Transactions
               (UserID, PortfolioID, AssetID, TransactionType, Quantity, UnitPrice)
        VALUES (@UserID, @PortfolioID, @AssetID, @TransactionType, @Quantity, @UnitPrice);

        /* refresh snapshot funds & profit */
        UPDATE portfolio.Portfolios
        SET CurrentFunds      = portfolio.fn_PortfolioMarketValue(@PortfolioID),
            CurrentProfitPct  = portfolio.fn_PortfolioProfitPct(@PortfolioID)
        WHERE PortfolioID = @PortfolioID;

        COMMIT;
        SELECT SCOPE_IDENTITY() AS TransactionID;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE portfolio.sp_UpdateAssetPrice
    @AssetID   INT,
    @NewPrice  DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        /* store history */
        INSERT INTO portfolio.AssetPrices (AssetID, Price)
        VALUES (@AssetID, @NewPrice);

        /* update snapshot */
        UPDATE portfolio.Assets
        SET Price        = @NewPrice,
            LastUpdated  = SYSDATETIME()
        WHERE AssetID = @AssetID;

        COMMIT;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;

/* ----------------  END OF SCRIPT ---------------- */
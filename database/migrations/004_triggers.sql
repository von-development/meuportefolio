/* ============================================================
meuPortfolio – Triggers & Functions v2.0 (Consolidated)
Automatic timestamp maintenance and portfolio calculations
============================================================ */

USE p6g4;
GO

/* ============================================================
1. PORTFOLIO CALCULATION FUNCTIONS
============================================================ */

-- Calculate portfolio market value based on current asset prices
CREATE FUNCTION portfolio.fn_PortfolioMarketValue (
    @PortfolioID INT
) RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Total DECIMAL(18,2) = 0;

    SELECT @Total = SUM(t.Quantity * a.Price)
    FROM portfolio.Transactions t
    JOIN portfolio.Assets a ON a.AssetID = t.AssetID
    WHERE t.PortfolioID = @PortfolioID
      AND t.Status = 'Executed'
    GROUP BY t.PortfolioID;

    RETURN ISNULL(@Total, 0);
END;
GO

-- Calculate portfolio profit percentage
CREATE FUNCTION portfolio.fn_PortfolioProfitPct (
    @PortfolioID INT
) RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Cost DECIMAL(18,2) = 0,
            @Market DECIMAL(18,2) = 0;

    -- Calculate total cost (buys - sells)
    SELECT @Cost = SUM(
        CASE WHEN t.TransactionType = 'Buy'
             THEN t.Quantity * t.UnitPrice
             ELSE -t.Quantity * t.UnitPrice
        END)
    FROM portfolio.Transactions t
    WHERE t.PortfolioID = @PortfolioID
      AND t.Status = 'Executed';

    -- Current market value
    SET @Market = portfolio.fn_PortfolioMarketValue(@PortfolioID);

    -- Calculate profit percentage
    RETURN CASE WHEN @Cost = 0 THEN 0
                ELSE ((@Market - @Cost) / @Cost) * 100
           END;
END;
GO

/* ============================================================
2. TIMESTAMP MAINTENANCE TRIGGERS
============================================================ */

-- Users table timestamp trigger
CREATE TRIGGER portfolio.TR_Users_UpdateTimestamp
ON portfolio.Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE u
    SET UpdatedAt = SYSDATETIME()
    FROM portfolio.Users u
    JOIN inserted i ON i.UserID = u.UserID;
END;
GO

-- Assets table timestamp trigger
CREATE TRIGGER portfolio.TR_Assets_UpdateTimestamp
ON portfolio.Assets
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE a
    SET LastUpdated = SYSDATETIME()
    FROM portfolio.Assets a
    JOIN inserted i ON i.AssetID = a.AssetID;
END;
GO

-- Portfolios table timestamp trigger
CREATE TRIGGER portfolio.TR_Portfolios_UpdateTimestamp
ON portfolio.Portfolios
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE p
    SET LastUpdated = SYSDATETIME()
    FROM portfolio.Portfolios p
    JOIN inserted i ON i.PortfolioID = p.PortfolioID;
END;
GO

-- StockDetails table timestamp trigger
CREATE TRIGGER portfolio.TR_StockDetails_UpdateTimestamp
ON portfolio.StockDetails
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE sd
    SET LastUpdated = SYSDATETIME()
    FROM portfolio.StockDetails sd
    JOIN inserted i ON i.AssetID = sd.AssetID;
END;
GO

-- CryptoDetails table timestamp trigger
CREATE TRIGGER portfolio.TR_CryptoDetails_UpdateTimestamp
ON portfolio.CryptoDetails
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE cd
    SET LastUpdated = SYSDATETIME()
    FROM portfolio.CryptoDetails cd
    JOIN inserted i ON i.AssetID = cd.AssetID;
END;
GO

-- CommodityDetails table timestamp trigger
CREATE TRIGGER portfolio.TR_CommodityDetails_UpdateTimestamp
ON portfolio.CommodityDetails
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE cmd
    SET LastUpdated = SYSDATETIME()
    FROM portfolio.CommodityDetails cmd
    JOIN inserted i ON i.AssetID = cmd.AssetID;
END;
GO

-- PortfolioHoldings table timestamp trigger
CREATE TRIGGER portfolio.TR_PortfolioHoldings_UpdateTimestamp
ON portfolio.PortfolioHoldings
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE ph
    SET LastUpdated = SYSDATETIME()
    FROM portfolio.PortfolioHoldings ph
    JOIN inserted i ON i.HoldingID = ph.HoldingID;
END;
GO

-- IndexDetails table timestamp trigger (if created from indexes file)
CREATE TRIGGER portfolio.TR_IndexDetails_UpdateTimestamp
ON portfolio.IndexDetails
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE id
    SET LastUpdated = SYSDATETIME()
    FROM portfolio.IndexDetails id
    JOIN inserted i ON i.AssetID = id.AssetID;
END;
GO

PRINT 'All triggers and functions created successfully!';

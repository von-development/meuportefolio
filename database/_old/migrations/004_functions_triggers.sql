/* ------------------------------------------------------------
meuPortfolio – Functions and Triggers  (v2025-05-24)
------------------------------------------------------------ */

USE meuportefolio;
GO

/* ============================================================
1. Portfolio Calculation Functions
============================================================ */
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
    GROUP BY t.PortfolioID;

    RETURN ISNULL(@Total, 0);
END;
GO

CREATE FUNCTION portfolio.fn_PortfolioProfitPct (
    @PortfolioID INT
) RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Cost DECIMAL(18,2) = 0,
            @Market DECIMAL(18,2) = 0;

    -- Cálculo do custo total (compras - vendas)
    SELECT @Cost = SUM(
        CASE WHEN t.TransactionType = 'Buy'
             THEN t.Quantity * t.UnitPrice
             ELSE -t.Quantity * t.UnitPrice
        END)
    FROM portfolio.Transactions t
    WHERE t.PortfolioID = @PortfolioID;

    -- Valor atual de mercado
    SET @Market = portfolio.fn_PortfolioMarketValue(@PortfolioID);

    -- Cálculo do percentual de lucro
    RETURN CASE WHEN @Cost = 0 THEN 0
                ELSE ((@Market - @Cost) / @Cost) * 100
           END;
END;
GO

/* ============================================================
2. Timestamp Maintenance Triggers
============================================================ */
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
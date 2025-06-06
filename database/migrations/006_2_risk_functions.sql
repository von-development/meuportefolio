/* ============================================================
meuPortfolio – Risk Calculation Functions v2.0
Advanced financial risk calculation functions
============================================================ */

USE p6g4;
GO

/* ============================================================
PORTFOLIO RISK CALCULATION FUNCTIONS
============================================================ */

-- Calculate portfolio beta (correlation with market benchmark)
CREATE OR ALTER FUNCTION portfolio.fn_CalculatePortfolioBeta (
    @PortfolioID INT,
    @BenchmarkAssetID INT = NULL,  -- Default to S&P 500 if not provided
    @DaysBack INT = 90
) RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Beta DECIMAL(10,2) = 1.00;
    
    -- If no benchmark provided, use S&P 500
    IF @BenchmarkAssetID IS NULL
        SELECT @BenchmarkAssetID = AssetID FROM portfolio.Assets WHERE Symbol = 'SPX';
    
    -- Calculate portfolio returns vs benchmark returns correlation
    -- This is a simplified beta calculation based on price changes
    WITH PortfolioReturns AS (
        SELECT 
            AsOf,
            ((portfolio.fn_PortfolioMarketValueV2(@PortfolioID) - LAG(portfolio.fn_PortfolioMarketValueV2(@PortfolioID)) OVER (ORDER BY AsOf)) 
             / LAG(portfolio.fn_PortfolioMarketValueV2(@PortfolioID)) OVER (ORDER BY AsOf)) * 100 as PortfolioReturn
        FROM (
            SELECT DISTINCT AsOf 
            FROM portfolio.AssetPrices 
            WHERE AsOf >= DATEADD(DAY, -@DaysBack, SYSDATETIME())
        ) dates
    ),
    BenchmarkReturns AS (
        SELECT 
            AsOf,
            ((Price - LAG(Price) OVER (ORDER BY AsOf)) / LAG(Price) OVER (ORDER BY AsOf)) * 100 as BenchmarkReturn
        FROM portfolio.AssetPrices
        WHERE AssetID = @BenchmarkAssetID
          AND AsOf >= DATEADD(DAY, -@DaysBack, SYSDATETIME())
    )
    SELECT @Beta = CASE 
        WHEN STDEV(br.BenchmarkReturn) = 0 THEN 1.00
        ELSE (
            (AVG(pr.PortfolioReturn * br.BenchmarkReturn) - AVG(pr.PortfolioReturn) * AVG(br.BenchmarkReturn)) /
            POWER(STDEV(br.BenchmarkReturn), 2)
        )
    END
    FROM PortfolioReturns pr
    JOIN BenchmarkReturns br ON pr.AsOf = br.AsOf
    WHERE pr.PortfolioReturn IS NOT NULL AND br.BenchmarkReturn IS NOT NULL;
    
    RETURN ISNULL(@Beta, 1.00);
END;
GO

-- Calculate Sharpe Ratio for a portfolio
CREATE OR ALTER FUNCTION portfolio.fn_CalculatePortfolioSharpeRatio (
    @PortfolioID INT,
    @RiskFreeRate DECIMAL(10,2) = 2.0,  -- Default 2% risk-free rate
    @DaysBack INT = 90
) RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @SharpeRatio DECIMAL(10,2) = 0.00;
    DECLARE @PortfolioReturn DECIMAL(10,2);
    DECLARE @PortfolioVolatility DECIMAL(10,2);
    
    -- Get portfolio return percentage
    SET @PortfolioReturn = portfolio.fn_PortfolioUnrealizedGainLossPct(@PortfolioID);
    
    -- Calculate portfolio volatility (standard deviation of returns)
    WITH DailyReturns AS (
        SELECT 
            AsOf,
            ((portfolio.fn_PortfolioMarketValueV2(@PortfolioID) - LAG(portfolio.fn_PortfolioMarketValueV2(@PortfolioID)) OVER (ORDER BY AsOf)) 
             / LAG(portfolio.fn_PortfolioMarketValueV2(@PortfolioID)) OVER (ORDER BY AsOf)) * 100 as DailyReturn
        FROM (
            SELECT DISTINCT AsOf 
            FROM portfolio.AssetPrices 
            WHERE AsOf >= DATEADD(DAY, -@DaysBack, SYSDATETIME())
        ) dates
    )
    SELECT @PortfolioVolatility = STDEV(DailyReturn) * SQRT(252)  -- Annualized volatility
    FROM DailyReturns
    WHERE DailyReturn IS NOT NULL;
    
    -- Calculate Sharpe Ratio: (Return - Risk Free Rate) / Volatility
    SET @SharpeRatio = CASE 
        WHEN @PortfolioVolatility = 0 THEN 0
        ELSE (@PortfolioReturn - @RiskFreeRate) / @PortfolioVolatility
    END;
    
    RETURN ISNULL(@SharpeRatio, 0.00);
END;
GO

-- Calculate Maximum Drawdown for a portfolio
CREATE OR ALTER FUNCTION portfolio.fn_CalculatePortfolioMaxDrawdown (
    @PortfolioID INT,
    @DaysBack INT = 90
) RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @MaxDrawdown DECIMAL(10,2) = 0.00;
    
    WITH PortfolioValues AS (
        SELECT 
            AsOf,
            portfolio.fn_PortfolioMarketValueV2(@PortfolioID) as PortfolioValue,
            MAX(portfolio.fn_PortfolioMarketValueV2(@PortfolioID)) OVER (ORDER BY AsOf ROWS UNBOUNDED PRECEDING) as PeakValue
        FROM (
            SELECT DISTINCT AsOf 
            FROM portfolio.AssetPrices 
            WHERE AsOf >= DATEADD(DAY, -@DaysBack, SYSDATETIME())
        ) dates
    )
    SELECT @MaxDrawdown = MIN((PortfolioValue - PeakValue) / PeakValue * 100)
    FROM PortfolioValues
    WHERE PeakValue > 0;
    
    RETURN ISNULL(@MaxDrawdown, 0.00);
END;
GO

-- Calculate portfolio volatility score
CREATE OR ALTER FUNCTION portfolio.fn_CalculatePortfolioVolatility (
    @PortfolioID INT,
    @DaysBack INT = 30
) RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Volatility DECIMAL(10,2) = 0.00;
    
    -- Calculate weighted average volatility of all holdings
    SELECT @Volatility = SUM(
        (ph.TotalCost / portfolio.fn_PortfolioTotalInvestment(@PortfolioID)) * 
        portfolio.fn_AssetVolatility(ph.AssetID, @DaysBack)
    )
    FROM portfolio.PortfolioHoldings ph
    WHERE ph.PortfolioID = @PortfolioID;
    
    RETURN ISNULL(@Volatility, 0.00);
END;
GO

PRINT 'Risk calculation functions created successfully!';
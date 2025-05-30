/* ============================================================
meuPortfolio – User-Defined Functions v2.0
Reusable financial calculations and utility functions
============================================================ */

USE p6g4;
GO

/* ============================================================
1. PORTFOLIO FINANCIAL FUNCTIONS (Updated for v2 Holdings)
============================================================ */

-- Calculate portfolio market value using PortfolioHoldings table (v2 optimized)
CREATE OR ALTER FUNCTION portfolio.fn_PortfolioMarketValueV2 (
    @PortfolioID INT
) RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Total DECIMAL(18,2) = 0;

    SELECT @Total = SUM(ph.QuantityHeld * a.Price)
    FROM portfolio.PortfolioHoldings ph
    JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
    WHERE ph.PortfolioID = @PortfolioID;

    RETURN ISNULL(@Total, 0);
END;
GO

-- Calculate portfolio total investment (cost basis)
CREATE OR ALTER FUNCTION portfolio.fn_PortfolioTotalInvestment (
    @PortfolioID INT
) RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Total DECIMAL(18,2) = 0;

    SELECT @Total = SUM(ph.TotalCost)
    FROM portfolio.PortfolioHoldings ph
    WHERE ph.PortfolioID = @PortfolioID;

    RETURN ISNULL(@Total, 0);
END;
GO

-- Calculate portfolio unrealized gain/loss
CREATE OR ALTER FUNCTION portfolio.fn_PortfolioUnrealizedGainLoss (
    @PortfolioID INT
) RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @MarketValue DECIMAL(18,2) = 0;
    DECLARE @TotalCost DECIMAL(18,2) = 0;

    SELECT 
        @MarketValue = SUM(ph.QuantityHeld * a.Price),
        @TotalCost = SUM(ph.TotalCost)
    FROM portfolio.PortfolioHoldings ph
    JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
    WHERE ph.PortfolioID = @PortfolioID;

    RETURN ISNULL(@MarketValue, 0) - ISNULL(@TotalCost, 0);
END;
GO

-- Calculate portfolio unrealized gain/loss percentage
CREATE OR ALTER FUNCTION portfolio.fn_PortfolioUnrealizedGainLossPct (
    @PortfolioID INT
) RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @TotalCost DECIMAL(18,2) = portfolio.fn_PortfolioTotalInvestment(@PortfolioID);
    DECLARE @GainLoss DECIMAL(18,2) = portfolio.fn_PortfolioUnrealizedGainLoss(@PortfolioID);

    RETURN CASE 
        WHEN @TotalCost = 0 THEN 0
        ELSE (@GainLoss / @TotalCost) * 100
    END;
END;
GO

-- Calculate total portfolio value (cash + investments)
CREATE OR ALTER FUNCTION portfolio.fn_PortfolioTotalValue (
    @PortfolioID INT
) RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @CurrentFunds DECIMAL(18,2) = 0;
    DECLARE @MarketValue DECIMAL(18,2) = 0;

    SELECT @CurrentFunds = CurrentFunds 
    FROM portfolio.Portfolios 
    WHERE PortfolioID = @PortfolioID;

    SET @MarketValue = portfolio.fn_PortfolioMarketValueV2(@PortfolioID);

    RETURN ISNULL(@CurrentFunds, 0) + ISNULL(@MarketValue, 0);
END;
GO

/* ============================================================
2. INDIVIDUAL HOLDING FINANCIAL FUNCTIONS
============================================================ */

-- Calculate current value of a specific holding
CREATE OR ALTER FUNCTION portfolio.fn_HoldingCurrentValue (
    @HoldingID BIGINT
) RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @Value DECIMAL(18,2) = 0;

    SELECT @Value = ph.QuantityHeld * a.Price
    FROM portfolio.PortfolioHoldings ph
    JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
    WHERE ph.HoldingID = @HoldingID;

    RETURN ISNULL(@Value, 0);
END;
GO

-- Calculate unrealized gain/loss for a specific holding
CREATE OR ALTER FUNCTION portfolio.fn_HoldingUnrealizedGainLoss (
    @HoldingID BIGINT
) RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @GainLoss DECIMAL(18,2) = 0;

    SELECT @GainLoss = (ph.QuantityHeld * a.Price) - ph.TotalCost
    FROM portfolio.PortfolioHoldings ph
    JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
    WHERE ph.HoldingID = @HoldingID;

    RETURN ISNULL(@GainLoss, 0);
END;
GO

-- Calculate gain/loss percentage for a specific holding
CREATE OR ALTER FUNCTION portfolio.fn_HoldingGainLossPercentage (
    @HoldingID BIGINT
) RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @TotalCost DECIMAL(18,2) = 0;
    DECLARE @GainLoss DECIMAL(18,2) = 0;

    SELECT 
        @TotalCost = ph.TotalCost,
        @GainLoss = (ph.QuantityHeld * a.Price) - ph.TotalCost
    FROM portfolio.PortfolioHoldings ph
    JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
    WHERE ph.HoldingID = @HoldingID;

    RETURN CASE 
        WHEN @TotalCost = 0 THEN 0
        ELSE (@GainLoss / @TotalCost) * 100
    END;
END;
GO

/* ============================================================
3. USER ACCOUNT FUNCTIONS
============================================================ */

-- Calculate user's total net worth (account balance + all portfolio values)
CREATE OR ALTER FUNCTION portfolio.fn_UserNetWorth (
    @UserID UNIQUEIDENTIFIER
) RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @AccountBalance DECIMAL(18,2) = 0;
    DECLARE @TotalFunds DECIMAL(18,2) = 0;
    DECLARE @TotalMarketValue DECIMAL(18,2) = 0;

    -- Get account balance
    SELECT @AccountBalance = AccountBalance
    FROM portfolio.Users
    WHERE UserID = @UserID;

    -- Get total cash funds in all portfolios
    SELECT @TotalFunds = SUM(CurrentFunds)
    FROM portfolio.Portfolios p
    WHERE p.UserID = @UserID;

    -- Get total market value of all holdings
    SELECT @TotalMarketValue = SUM(ph.QuantityHeld * a.Price)
    FROM portfolio.Portfolios p
    JOIN portfolio.PortfolioHoldings ph ON ph.PortfolioID = p.PortfolioID
    JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
    WHERE p.UserID = @UserID;

    RETURN ISNULL(@AccountBalance, 0) + ISNULL(@TotalFunds, 0) + ISNULL(@TotalMarketValue, 0);
END;
GO

-- Calculate days remaining in premium subscription
CREATE OR ALTER FUNCTION portfolio.fn_UserPremiumDaysRemaining (
    @UserID UNIQUEIDENTIFIER
) RETURNS INT
AS
BEGIN
    DECLARE @DaysRemaining INT = 0;

    SELECT @DaysRemaining = CASE 
        WHEN IsPremium = 1 AND PremiumEndDate > SYSDATETIME() 
        THEN DATEDIFF(DAY, SYSDATETIME(), PremiumEndDate)
        ELSE 0
    END
    FROM portfolio.Users
    WHERE UserID = @UserID;

    RETURN ISNULL(@DaysRemaining, 0);
END;
GO

-- Check if user's subscription is expired
CREATE OR ALTER FUNCTION portfolio.fn_UserSubscriptionExpired (
    @UserID UNIQUEIDENTIFIER
) RETURNS BIT
AS
BEGIN
    DECLARE @IsExpired BIT = 0;

    SELECT @IsExpired = CASE 
        WHEN IsPremium = 1 AND PremiumEndDate <= SYSDATETIME() 
        THEN 1 
        ELSE 0
    END
    FROM portfolio.Users
    WHERE UserID = @UserID;

    RETURN ISNULL(@IsExpired, 0);
END;
GO

/* ============================================================
4. ASSET PERFORMANCE FUNCTIONS
============================================================ */

-- Calculate asset price change percentage over specified days
CREATE OR ALTER FUNCTION portfolio.fn_AssetPriceChangePercent (
    @AssetID INT,
    @DaysBack INT
) RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @CurrentPrice DECIMAL(18,2) = 0;
    DECLARE @OldPrice DECIMAL(18,2) = 0;

    -- Get current price
    SELECT @CurrentPrice = Price
    FROM portfolio.Assets
    WHERE AssetID = @AssetID;

    -- Get price N days ago
    SELECT TOP 1 @OldPrice = Price
    FROM portfolio.AssetPrices
    WHERE AssetID = @AssetID 
      AND AsOf <= DATEADD(DAY, -@DaysBack, SYSDATETIME())
    ORDER BY AsOf DESC;

    RETURN CASE 
        WHEN @OldPrice = 0 THEN 0
        ELSE ((@CurrentPrice - @OldPrice) / @OldPrice) * 100
    END;
END;
GO

-- Calculate asset volatility (average daily price range) over specified days
CREATE OR ALTER FUNCTION portfolio.fn_AssetVolatility (
    @AssetID INT,
    @DaysBack INT = 30
) RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @AvgVolatility DECIMAL(10,2) = 0;

    SELECT @AvgVolatility = AVG(
        CASE 
            WHEN OpenPrice > 0 
            THEN ((HighPrice - LowPrice) / OpenPrice) * 100
            ELSE 0
        END
    )
    FROM portfolio.AssetPrices
    WHERE AssetID = @AssetID 
      AND AsOf >= DATEADD(DAY, -@DaysBack, SYSDATETIME());

    RETURN ISNULL(@AvgVolatility, 0);
END;
GO

/* ============================================================
5. TRADING CALCULATION FUNCTIONS
============================================================ */

-- Calculate average price for adding to existing holding
CREATE OR ALTER FUNCTION portfolio.fn_CalculateNewAveragePrice (
    @CurrentQuantity DECIMAL(18,6),
    @CurrentAvgPrice DECIMAL(18,4),
    @AddQuantity DECIMAL(18,6),
    @AddPrice DECIMAL(18,4)
) RETURNS DECIMAL(18,4)
AS
BEGIN
    DECLARE @CurrentTotalCost DECIMAL(18,2) = @CurrentQuantity * @CurrentAvgPrice;
    DECLARE @AddTotalCost DECIMAL(18,2) = @AddQuantity * @AddPrice;
    DECLARE @NewTotalQuantity DECIMAL(18,6) = @CurrentQuantity + @AddQuantity;

    RETURN CASE 
        WHEN @NewTotalQuantity = 0 THEN 0
        ELSE (@CurrentTotalCost + @AddTotalCost) / @NewTotalQuantity
    END;
END;
GO

-- Calculate cost basis for partial sale
CREATE OR ALTER FUNCTION portfolio.fn_CalculatePartialSaleCostBasis (
    @TotalHolding DECIMAL(18,6),
    @TotalCost DECIMAL(18,2),
    @SaleQuantity DECIMAL(18,6)
) RETURNS DECIMAL(18,2)
AS
BEGIN
    RETURN CASE 
        WHEN @TotalHolding = 0 THEN 0
        ELSE (@SaleQuantity / @TotalHolding) * @TotalCost
    END;
END;
GO

/* ============================================================
6. UTILITY FUNCTIONS
============================================================ */

-- Format currency values for display
CREATE OR ALTER FUNCTION portfolio.fn_FormatCurrency (
    @Amount DECIMAL(18,2)
) RETURNS NVARCHAR(50)
AS
BEGIN
    RETURN '$' + FORMAT(@Amount, 'N2');
END;
GO

-- Format percentage values for display
CREATE OR ALTER FUNCTION portfolio.fn_FormatPercentage (
    @Percentage DECIMAL(10,2)
) RETURNS NVARCHAR(20)
AS
BEGIN
    RETURN FORMAT(@Percentage, 'N2') + '%';
END;
GO

PRINT 'User-defined functions created successfully!';
PRINT '';
PRINT 'SUMMARY OF FUNCTIONS CREATED:';
PRINT '';
PRINT '📊 PORTFOLIO FUNCTIONS (6):';
PRINT '✅ fn_PortfolioMarketValueV2 - Market value using PortfolioHoldings';
PRINT '✅ fn_PortfolioTotalInvestment - Total cost basis';
PRINT '✅ fn_PortfolioUnrealizedGainLoss - Unrealized P&L amount';
PRINT '✅ fn_PortfolioUnrealizedGainLossPct - Unrealized P&L percentage';
PRINT '✅ fn_PortfolioTotalValue - Cash + investments total value';
PRINT '';
PRINT '💼 HOLDING FUNCTIONS (3):';
PRINT '✅ fn_HoldingCurrentValue - Current market value of specific holding';
PRINT '✅ fn_HoldingUnrealizedGainLoss - P&L for specific holding';
PRINT '✅ fn_HoldingGainLossPercentage - P&L percentage for specific holding';
PRINT '';
PRINT '👤 USER ACCOUNT FUNCTIONS (3):';
PRINT '✅ fn_UserNetWorth - Total net worth across all accounts';
PRINT '✅ fn_UserPremiumDaysRemaining - Days left in premium subscription';
PRINT '✅ fn_UserSubscriptionExpired - Check if subscription expired';
PRINT '';
PRINT '📈 ASSET PERFORMANCE FUNCTIONS (2):';
PRINT '✅ fn_AssetPriceChangePercent - Price change over N days';
PRINT '✅ fn_AssetVolatility - Average volatility over N days';
PRINT '';
PRINT '💰 TRADING CALCULATION FUNCTIONS (2):';
PRINT '✅ fn_CalculateNewAveragePrice - Average price after adding shares';
PRINT '✅ fn_CalculatePartialSaleCostBasis - Cost basis for partial sales';
PRINT '';
PRINT '🔧 UTILITY FUNCTIONS (2):';
PRINT '✅ fn_FormatCurrency - Format amounts as currency strings';
PRINT '✅ fn_FormatPercentage - Format percentages for display';
PRINT '';
PRINT 'BENEFITS:';
PRINT '🚀 Reusable financial calculations across all procedures';
PRINT '🚀 Consistent calculation logic and formulas';
PRINT '🚀 Performance optimized using PortfolioHoldings table';
PRINT '🚀 Comprehensive portfolio analytics and user metrics'; 
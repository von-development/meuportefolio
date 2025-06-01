/* ============================================================
meuPortfolio – Risk Metrics Management Procedures v2.0
Advanced risk analytics and portfolio performance procedures
============================================================ */

USE p6g4;
GO

/* ============================================================
RISK METRICS CALCULATION PROCEDURES
============================================================ */

-- Calculate and store risk metrics for a user's portfolios
CREATE PROCEDURE portfolio.sp_CalculateUserRiskMetrics (
    @UserID UNIQUEIDENTIFIER,
    @DaysBack INT = 90
) AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Only calculate for premium users
        IF NOT EXISTS (SELECT 1 FROM portfolio.Users WHERE UserID = @UserID AND IsPremium = 1)
        BEGIN
            RAISERROR('Risk metrics only available for premium users', 16, 1);
            RETURN;
        END
        
        DECLARE @TotalPortfolioValue DECIMAL(18,2) = 0;
        DECLARE @TotalInvestment DECIMAL(18,2) = 0;
        DECLARE @AbsoluteReturn DECIMAL(10,2) = 0;
        DECLARE @MaxDrawdown DECIMAL(10,2) = 0;
        DECLARE @Beta DECIMAL(10,2) = 1.00;
        DECLARE @SharpeRatio DECIMAL(10,2) = 0.00;
        DECLARE @VolatilityScore DECIMAL(10,2) = 0.00;
        DECLARE @RiskLevel NVARCHAR(20) = 'Moderate';
        
        -- Calculate aggregated metrics across all user portfolios
        SELECT 
            @TotalPortfolioValue = SUM(portfolio.fn_PortfolioMarketValueV2(p.PortfolioID)),
            @TotalInvestment = SUM(portfolio.fn_PortfolioTotalInvestment(p.PortfolioID))
        FROM portfolio.Portfolios p
        WHERE p.UserID = @UserID;
        
        -- Calculate absolute return
        SET @AbsoluteReturn = CASE 
            WHEN @TotalInvestment = 0 THEN 0
            ELSE ((@TotalPortfolioValue - @TotalInvestment) / @TotalInvestment) * 100
        END;
        
        -- Calculate weighted average metrics across portfolios
        SELECT 
            @MaxDrawdown = AVG(portfolio.fn_CalculatePortfolioMaxDrawdown(p.PortfolioID, @DaysBack)),
            @Beta = AVG(portfolio.fn_CalculatePortfolioBeta(p.PortfolioID, NULL, @DaysBack)),
            @SharpeRatio = AVG(portfolio.fn_CalculatePortfolioSharpeRatio(p.PortfolioID, 2.0, @DaysBack)),
            @VolatilityScore = AVG(portfolio.fn_CalculatePortfolioVolatility(p.PortfolioID, 30))
        FROM portfolio.Portfolios p
        WHERE p.UserID = @UserID;
        
        -- Determine risk level based on volatility and beta
        SET @RiskLevel = CASE 
            WHEN @VolatilityScore <= 10 AND @Beta <= 0.8 THEN 'Conservative'
            WHEN @VolatilityScore >= 20 OR @Beta >= 1.2 THEN 'Aggressive'
            ELSE 'Moderate'
        END;
        
        -- Insert new risk metrics record
        INSERT INTO portfolio.RiskMetrics (
            UserID, MaximumDrawdown, Beta, SharpeRatio, 
            AbsoluteReturn, VolatilityScore, RiskLevel
        )
        VALUES (
            @UserID, @MaxDrawdown, @Beta, @SharpeRatio,
            @AbsoluteReturn, @VolatilityScore, @RiskLevel
        );
        
        -- Return the calculated metrics
        SELECT 
            'SUCCESS' AS Status,
            @AbsoluteReturn AS AbsoluteReturn,
            @MaxDrawdown AS MaximumDrawdown,
            @Beta AS Beta,
            @SharpeRatio AS SharpeRatio,
            @VolatilityScore AS VolatilityScore,
            @RiskLevel AS RiskLevel;
            
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

-- Calculate risk metrics for all premium users
CREATE PROCEDURE portfolio.sp_CalculateAllUserRiskMetrics (
    @DaysBack INT = 90
) AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserID UNIQUEIDENTIFIER;
    DECLARE @ProcessedCount INT = 0;
    DECLARE @ErrorCount INT = 0;
    
    DECLARE user_cursor CURSOR FOR
    SELECT UserID 
    FROM portfolio.Users 
    WHERE IsPremium = 1;
    
    OPEN user_cursor;
    FETCH NEXT FROM user_cursor INTO @UserID;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC portfolio.sp_CalculateUserRiskMetrics @UserID, @DaysBack;
            SET @ProcessedCount = @ProcessedCount + 1;
        END TRY
        BEGIN CATCH
            SET @ErrorCount = @ErrorCount + 1;
            -- Log error but continue processing
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, UserID, Message)
            VALUES ('ERROR', 'RISK_CALCULATION', @UserID, 'Failed to calculate risk metrics: ' + ERROR_MESSAGE());
        END CATCH
        
        FETCH NEXT FROM user_cursor INTO @UserID;
    END
    
    CLOSE user_cursor;
    DEALLOCATE user_cursor;
    
    SELECT 
        'COMPLETED' AS Status,
        @ProcessedCount AS UsersProcessed,
        @ErrorCount AS ErrorCount;
END;
GO

/* ============================================================
RISK REPORTING PROCEDURES
============================================================ */

-- Get latest risk metrics for a user
CREATE PROCEDURE portfolio.sp_GetUserLatestRiskMetrics (
    @UserID UNIQUEIDENTIFIER
) AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT TOP 1
        MetricID,
        UserID,
        MaximumDrawdown,
        Beta,
        SharpeRatio,
        AbsoluteReturn,
        VolatilityScore,
        RiskLevel,
        CapturedAt
    FROM portfolio.RiskMetrics
    WHERE UserID = @UserID
    ORDER BY CapturedAt DESC;
END;
GO

-- Get risk metrics trend for a user
CREATE PROCEDURE portfolio.sp_GetUserRiskTrend (
    @UserID UNIQUEIDENTIFIER,
    @DaysBack INT = 90
) AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        MetricID,
        MaximumDrawdown,
        Beta,
        SharpeRatio,
        AbsoluteReturn,
        VolatilityScore,
        RiskLevel,
        CapturedAt
    FROM portfolio.RiskMetrics
    WHERE UserID = @UserID
      AND CapturedAt >= DATEADD(DAY, -@DaysBack, SYSDATETIME())
    ORDER BY CapturedAt ASC;
END;
GO

PRINT 'Risk management procedures created successfully!';
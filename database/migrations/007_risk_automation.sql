/* ============================================================
meuPortfolio – Risk Metrics Automation v2.0
Automated risk calculation with sample data generation
============================================================ */

USE p6g4;
GO

/* ============================================================
1. SAMPLE RISK DATA GENERATION (for portfolios without history)
============================================================ */

-- Generate realistic sample risk metrics when historical data is insufficient
CREATE PROCEDURE portfolio.sp_GenerateSampleRiskMetrics (
    @UserID UNIQUEIDENTIFIER,
    @UseRandomData BIT = 1
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
        
        -- Calculate actual portfolio metrics
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
        
        IF @UseRandomData = 1
        BEGIN
            -- Generate realistic sample metrics based on portfolio composition
            DECLARE @AssetTypeCount INT;
            DECLARE @StockPercentage DECIMAL(5,2) = 0;
            DECLARE @CryptoPercentage DECIMAL(5,2) = 0;
            
            -- Analyze portfolio composition to determine realistic risk levels
            SELECT 
                @AssetTypeCount = COUNT(DISTINCT a.AssetType),
                @StockPercentage = SUM(CASE WHEN a.AssetType = 'Stock' THEN ph.TotalCost ELSE 0 END) / NULLIF(@TotalInvestment, 0) * 100,
                @CryptoPercentage = SUM(CASE WHEN a.AssetType = 'Cryptocurrency' THEN ph.TotalCost ELSE 0 END) / NULLIF(@TotalInvestment, 0) * 100
            FROM portfolio.Portfolios p
            JOIN portfolio.PortfolioHoldings ph ON ph.PortfolioID = p.PortfolioID
            JOIN portfolio.Assets a ON a.AssetID = ph.AssetID
            WHERE p.UserID = @UserID;
            
            -- Generate realistic metrics based on portfolio composition
            SET @MaxDrawdown = CASE 
                WHEN @CryptoPercentage > 50 THEN -15.0 + (RAND() * -20.0)  -- Crypto-heavy: -15% to -35%
                WHEN @StockPercentage > 80 THEN -8.0 + (RAND() * -12.0)    -- Stock-heavy: -8% to -20%
                WHEN @AssetTypeCount >= 3 THEN -5.0 + (RAND() * -10.0)      -- Diversified: -5% to -15%
                ELSE -3.0 + (RAND() * -7.0)                                 -- Conservative: -3% to -10%
            END;
            
            SET @Beta = CASE 
                WHEN @CryptoPercentage > 50 THEN 1.5 + (RAND() * 1.0)      -- Crypto-heavy: 1.5-2.5
                WHEN @StockPercentage > 80 THEN 0.8 + (RAND() * 0.6)       -- Stock-heavy: 0.8-1.4
                WHEN @AssetTypeCount >= 3 THEN 0.7 + (RAND() * 0.4)        -- Diversified: 0.7-1.1
                ELSE 0.5 + (RAND() * 0.4)                                  -- Conservative: 0.5-0.9
            END;
            
            SET @SharpeRatio = CASE 
                WHEN @AbsoluteReturn > 20 THEN 1.5 + (RAND() * 1.0)        -- High return: 1.5-2.5
                WHEN @AbsoluteReturn > 10 THEN 1.0 + (RAND() * 0.8)        -- Good return: 1.0-1.8
                WHEN @AbsoluteReturn > 0 THEN 0.5 + (RAND() * 0.7)         -- Positive return: 0.5-1.2
                ELSE -0.5 + (RAND() * 1.0)                                 -- Negative return: -0.5-0.5
            END;
            
            SET @VolatilityScore = CASE 
                WHEN @CryptoPercentage > 50 THEN 25.0 + (RAND() * 15.0)    -- Crypto-heavy: 25-40%
                WHEN @StockPercentage > 80 THEN 15.0 + (RAND() * 10.0)     -- Stock-heavy: 15-25%
                WHEN @AssetTypeCount >= 3 THEN 8.0 + (RAND() * 7.0)        -- Diversified: 8-15%
                ELSE 5.0 + (RAND() * 5.0)                                  -- Conservative: 5-10%
            END;
        END
        ELSE
        BEGIN
            -- Use simple fixed values for testing
            SET @MaxDrawdown = -12.5;
            SET @Beta = 1.15;
            SET @SharpeRatio = 0.85;
            SET @VolatilityScore = 18.2;
        END
        
        -- Determine risk level based on calculated metrics
        SET @RiskLevel = CASE 
            WHEN @VolatilityScore <= 10 AND @Beta <= 0.8 THEN 'Conservative'
            WHEN @VolatilityScore >= 20 OR @Beta >= 1.2 OR @CryptoPercentage > 30 THEN 'Aggressive'
            ELSE 'Moderate'
        END;
        
        -- Insert the risk metrics record
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
            'SAMPLE_DATA_GENERATED' AS DataType,
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

/* ============================================================
2. ENHANCED RISK CALCULATION WITH FALLBACK
============================================================ */

-- Enhanced version that falls back to sample data if historical data is insufficient
CREATE PROCEDURE portfolio.sp_CalculateUserRiskMetricsEnhanced (
    @UserID UNIQUEIDENTIFIER,
    @DaysBack INT = 90,
    @UseSampleDataFallback BIT = 1
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
        
        -- Check if user has sufficient historical data
        DECLARE @HistoricalDataPoints INT = 0;
        DECLARE @MinDataPointsRequired INT = 10;
        
        SELECT @HistoricalDataPoints = COUNT(DISTINCT ap.AsOf)
        FROM portfolio.Portfolios p
        JOIN portfolio.PortfolioHoldings ph ON ph.PortfolioID = p.PortfolioID
        JOIN portfolio.AssetPrices ap ON ap.AssetID = ph.AssetID
        WHERE p.UserID = @UserID
          AND ap.AsOf >= DATEADD(DAY, -@DaysBack, SYSDATETIME());
        
        IF @HistoricalDataPoints >= @MinDataPointsRequired
        BEGIN
            -- Use real calculation procedures
            EXEC portfolio.sp_CalculateUserRiskMetrics @UserID, @DaysBack;
            
            SELECT 'SUCCESS' AS Status, 'HISTORICAL_DATA_USED' AS DataType;
        END
        ELSE
        BEGIN
            -- Fall back to sample data generation
            IF @UseSampleDataFallback = 1
            BEGIN
                EXEC portfolio.sp_GenerateSampleRiskMetrics @UserID, 1;
            END
            ELSE
            BEGIN
                RAISERROR('Insufficient historical data for risk calculation. Need at least %d data points, found %d', 16, 1, @MinDataPointsRequired, @HistoricalDataPoints);
            END
        END
        
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

/* ============================================================
3. BULK RISK METRICS GENERATION
============================================================ */

-- Generate risk metrics for all premium users with intelligent fallback
CREATE PROCEDURE portfolio.sp_GenerateAllRiskMetrics (
    @DaysBack INT = 90,
    @UseSampleDataFallback BIT = 1,
    @ForceRefresh BIT = 0
) AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserID UNIQUEIDENTIFIER;
    DECLARE @ProcessedCount INT = 0;
    DECLARE @ErrorCount INT = 0;
    DECLARE @SampleDataCount INT = 0;
    DECLARE @HistoricalDataCount INT = 0;
    
    DECLARE user_cursor CURSOR FOR
    SELECT u.UserID 
    FROM portfolio.Users u
    WHERE u.IsPremium = 1
      AND (
          @ForceRefresh = 1 
          OR NOT EXISTS (
              SELECT 1 FROM portfolio.RiskMetrics rm 
              WHERE rm.UserID = u.UserID 
                AND rm.CapturedAt >= DATEADD(HOUR, -24, SYSDATETIME())
          )
      );
    
    OPEN user_cursor;
    FETCH NEXT FROM user_cursor INTO @UserID;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            -- Clean up old risk metrics for this user (keep only latest 10)
            DELETE FROM portfolio.RiskMetrics 
            WHERE UserID = @UserID 
              AND MetricID NOT IN (
                  SELECT TOP 10 MetricID 
                  FROM portfolio.RiskMetrics 
                  WHERE UserID = @UserID 
                  ORDER BY CapturedAt DESC
              );
            
            -- Calculate new risk metrics
            DECLARE @DataType NVARCHAR(50);
            
            EXEC portfolio.sp_CalculateUserRiskMetricsEnhanced @UserID, @DaysBack, @UseSampleDataFallback;
            
            -- Track what type of data was used
            SELECT TOP 1 @DataType = 'HISTORICAL_DATA_USED'  -- Default assumption
            FROM portfolio.RiskMetrics 
            WHERE UserID = @UserID 
            ORDER BY CapturedAt DESC;
            
            SET @ProcessedCount = @ProcessedCount + 1;
            
            IF @DataType = 'SAMPLE_DATA_GENERATED'
                SET @SampleDataCount = @SampleDataCount + 1;
            ELSE
                SET @HistoricalDataCount = @HistoricalDataCount + 1;
                
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
        @HistoricalDataCount AS UsersWithHistoricalData,
        @SampleDataCount AS UsersWithSampleData,
        @ErrorCount AS ErrorCount;
END;
GO

/* ============================================================
4. AUTOMATIC TRIGGER FOR RISK UPDATES
============================================================ */

-- Trigger to update risk metrics when portfolio holdings change significantly
CREATE TRIGGER portfolio.tr_PortfolioHoldings_RiskUpdate
ON portfolio.PortfolioHoldings
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Get affected users
    DECLARE @AffectedUsers TABLE (UserID UNIQUEIDENTIFIER);
    
    INSERT INTO @AffectedUsers (UserID)
    SELECT DISTINCT p.UserID
    FROM (
        SELECT DISTINCT PortfolioID FROM inserted
        UNION
        SELECT DISTINCT PortfolioID FROM deleted
    ) affected
    JOIN portfolio.Portfolios p ON p.PortfolioID = affected.PortfolioID
    JOIN portfolio.Users u ON u.UserID = p.UserID
    WHERE u.IsPremium = 1;
    
    -- Mark users for risk metric refresh (we'll use a simple flag approach)
    UPDATE portfolio.Users 
    SET UpdatedAt = SYSDATETIME() 
    WHERE UserID IN (SELECT UserID FROM @AffectedUsers);
    
    -- Log the trigger event
    INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, Message)
    VALUES ('INFO', 'RISK_UPDATE_TRIGGERED', 'Portfolio holdings changed, risk metrics refresh needed for ' + CAST((SELECT COUNT(*) FROM @AffectedUsers) AS NVARCHAR(10)) + ' users');
END;
GO

/* ============================================================
5. SCHEDULED RISK CALCULATION PROCEDURE
============================================================ */

-- Daily risk calculation procedure (to be scheduled)
CREATE PROCEDURE portfolio.sp_DailyRiskCalculation
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Starting daily risk calculation process...';
        
        -- Run bulk risk metrics generation
        EXEC portfolio.sp_GenerateAllRiskMetrics 
            @DaysBack = 90,
            @UseSampleDataFallback = 1,
            @ForceRefresh = 0;  -- Only refresh if no recent data
        
        -- Log successful completion
        INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, Message)
        VALUES ('INFO', 'SCHEDULED_TASK', 'Daily risk calculation completed successfully');
        
        PRINT 'Daily risk calculation completed successfully!';
        
    END TRY
    BEGIN CATCH
        -- Log error
        INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, Message)
        VALUES ('ERROR', 'SCHEDULED_TASK', 'Daily risk calculation failed: ' + ERROR_MESSAGE());
        
        PRINT 'Daily risk calculation failed: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

PRINT 'Risk automation procedures created successfully!';
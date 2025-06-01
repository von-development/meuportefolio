/* ============================================================
meuPortfolio – Risk Metrics Setup Script
Quick setup script to deploy risk functionality and populate initial data
============================================================ */

USE p6g4;
GO

PRINT '====================================================================';
PRINT 'meuPortfolio Risk Metrics Setup Script';
PRINT 'This script will deploy all risk-related functionality and populate initial data';
PRINT '====================================================================';
PRINT '';

-- Step 1: Deploy Risk Functions (if not already deployed)
PRINT 'Step 1: Deploying Risk Calculation Functions...';

-- Check if risk functions exist
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'portfolio.fn_CalculatePortfolioBeta') AND type = 'FN')
BEGIN
    PRINT 'Risk functions not found. Please run 006_1_risk_functions.sql first.';
    PRINT 'Location: database/migrations/006_1_risk_functions.sql';
    RAISERROR('Risk functions must be deployed first', 16, 1);
    RETURN;
END
ELSE
BEGIN
    PRINT '✅ Risk calculation functions are available';
END

-- Step 2: Deploy Risk Procedures (if not already deployed)
PRINT '';
PRINT 'Step 2: Checking Risk Procedures...';

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'portfolio.sp_CalculateUserRiskMetrics') AND type = 'P')
BEGIN
    PRINT 'Risk procedures not found. Please run 005_5_risk_procedures.sql first.';
    PRINT 'Location: database/migrations/005_5_risk_procedures.sql';
    RAISERROR('Risk procedures must be deployed first', 16, 1);
    RETURN;
END
ELSE
BEGIN
    PRINT '✅ Risk calculation procedures are available';
END

-- Step 3: Deploy Automation Features (if not already deployed)  
PRINT '';
PRINT 'Step 3: Checking Risk Automation...';

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'portfolio.sp_GenerateSampleRiskMetrics') AND type = 'P')
BEGIN
    PRINT 'Risk automation not found. Please run 007_risk_automation.sql first.';
    PRINT 'Location: database/migrations/007_risk_automation.sql';
    RAISERROR('Risk automation must be deployed first', 16, 1);
    RETURN;
END
ELSE
BEGIN
    PRINT '✅ Risk automation procedures are available';
END

-- Step 4: Check for Premium Users
PRINT '';
PRINT 'Step 4: Checking for Premium Users...';

DECLARE @PremiumUserCount INT;
SELECT @PremiumUserCount = COUNT(*) FROM portfolio.Users WHERE IsPremium = 1;

PRINT 'Found ' + CAST(@PremiumUserCount AS NVARCHAR(10)) + ' premium users';

IF @PremiumUserCount = 0
BEGIN
    PRINT 'No premium users found. Creating sample premium user...';
    
    -- Create a sample premium user if none exists
    DECLARE @SampleUserID UNIQUEIDENTIFIER = NEWID();
    
    INSERT INTO portfolio.Users (
        UserID, Name, Email, Password, CountryOfResidence, IBAN, UserType,
        AccountBalance, IsPremium, PremiumStartDate, PremiumEndDate,
        MonthlySubscriptionRate
    ) VALUES (
        @SampleUserID, 'Sample Premium User', 'premium@example.com', 'password123',
        'United States', 'US123456789012345678901234567890', 'Premium',
        10000.00, 1, SYSDATETIME(), DATEADD(MONTH, 12, SYSDATETIME()),
        50.00
    );
    
    PRINT '✅ Created sample premium user: ' + CAST(@SampleUserID AS NVARCHAR(36));
    SET @PremiumUserCount = 1;
END

-- Step 5: Check for Portfolios and Holdings
PRINT '';
PRINT 'Step 5: Checking Portfolio Data...';

DECLARE @PortfolioCount INT;
DECLARE @HoldingCount INT;

SELECT @PortfolioCount = COUNT(*) 
FROM portfolio.Portfolios p
JOIN portfolio.Users u ON u.UserID = p.UserID
WHERE u.IsPremium = 1;

SELECT @HoldingCount = COUNT(*) 
FROM portfolio.PortfolioHoldings ph
JOIN portfolio.Portfolios p ON p.PortfolioID = ph.PortfolioID
JOIN portfolio.Users u ON u.UserID = p.UserID
WHERE u.IsPremium = 1;

PRINT 'Found ' + CAST(@PortfolioCount AS NVARCHAR(10)) + ' portfolios for premium users';
PRINT 'Found ' + CAST(@HoldingCount AS NVARCHAR(10)) + ' holdings for premium users';

IF @PortfolioCount = 0 OR @HoldingCount = 0
BEGIN
    PRINT '⚠️  Warning: Limited portfolio data available. Risk calculations will use sample data.';
END

-- Step 6: Generate Initial Risk Metrics
PRINT '';
PRINT 'Step 6: Generating Initial Risk Metrics...';

-- Clean up any existing risk metrics for a fresh start
DELETE FROM portfolio.RiskMetrics;
PRINT 'Cleared existing risk metrics data';

-- Generate risk metrics for all premium users
EXEC portfolio.sp_GenerateAllRiskMetrics 
    @DaysBack = 90,
    @UseSampleDataFallback = 1,
    @ForceRefresh = 1;

-- Step 7: Verify Results
PRINT '';
PRINT 'Step 7: Verifying Risk Metrics Generation...';

DECLARE @RiskMetricCount INT;
SELECT @RiskMetricCount = COUNT(*) FROM portfolio.RiskMetrics;

PRINT 'Generated ' + CAST(@RiskMetricCount AS NVARCHAR(10)) + ' risk metric records';

-- Show sample results
IF @RiskMetricCount > 0
BEGIN
    PRINT '';
    PRINT 'Sample Risk Metrics:';
    SELECT TOP 3
        u.Name AS UserName,
        rm.RiskLevel,
        rm.AbsoluteReturn,
        rm.Beta,
        rm.SharpeRatio,
        rm.VolatilityScore,
        rm.CapturedAt
    FROM portfolio.RiskMetrics rm
    JOIN portfolio.Users u ON u.UserID = rm.UserID
    ORDER BY rm.CapturedAt DESC;
END

-- Step 8: Setup Summary
PRINT '';
PRINT '====================================================================';
PRINT 'SETUP COMPLETE! 🎉';
PRINT '====================================================================';
PRINT '';
PRINT 'WHAT WAS DEPLOYED:';
PRINT '✅ Risk calculation functions (Beta, Sharpe Ratio, Max Drawdown, Volatility)';
PRINT '✅ Risk calculation procedures (automated and manual)';
PRINT '✅ Risk automation features (triggers, scheduled tasks)';
PRINT '✅ Initial risk metrics for ' + CAST(@PremiumUserCount AS NVARCHAR(10)) + ' premium users';
PRINT '';
PRINT 'AVAILABLE PROCEDURES:';
PRINT '• portfolio.sp_GenerateAllRiskMetrics - Generate risk metrics for all users';
PRINT '• portfolio.sp_CalculateUserRiskMetricsEnhanced - Calculate for specific user';
PRINT '• portfolio.sp_GenerateSampleRiskMetrics - Generate sample/test data';
PRINT '• portfolio.sp_DailyRiskCalculation - Daily scheduled calculation';
PRINT '';
PRINT 'AUTOMATIC FEATURES:';
PRINT '• Risk metrics auto-update when portfolio holdings change';
PRINT '• Intelligent fallback to sample data when historical data is insufficient';
PRINT '• Comprehensive error logging in portfolio.ApplicationLogs';
PRINT '';
PRINT 'NEXT STEPS:';
PRINT '1. Set up a daily scheduled job: EXEC portfolio.sp_DailyRiskCalculation';
PRINT '2. Query risk data using views: SELECT * FROM portfolio.vw_RiskAnalysis';
PRINT '3. Monitor logs: SELECT * FROM portfolio.ApplicationLogs WHERE EventType LIKE ''%RISK%''';
PRINT '';
PRINT 'MANUAL REFRESH COMMAND:';
PRINT 'EXEC portfolio.sp_GenerateAllRiskMetrics @ForceRefresh = 1';
PRINT '';
PRINT '===================================================================='; 
/* ============================================================
meuPortfolio - Sample Risk Metrics
Creates realistic risk assessment data for premium users using stored procedures
============================================================ */

USE p6g4;
GO

BEGIN TRANSACTION;

PRINT 'Creating sample risk metrics data using stored procedures...';

-- ============================================================
-- RISK METRICS CALCULATION (Premium Feature)
-- ============================================================

-- User variables for premium users only (get from database instead of hardcoded)
DECLARE @JoaoUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'joao.santos@email.com');
DECLARE @AnaUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'ana.costa@gmail.com');
DECLARE @IsabellaUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'isabella.rodriguez@yahoo.com');
DECLARE @SophieUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'sophie.dubois@orange.fr');
DECLARE @LucaUserID UNIQUEIDENTIFIER = (SELECT UserID FROM portfolio.Users WHERE Email = 'luca.rossi@libero.it');

PRINT 'Calculating risk metrics for premium users using stored procedures...';

-- Calculate risk metrics for João Santos (Premium User)
EXEC portfolio.sp_CalculateUserRiskMetrics @JoaoUserID, 90;
PRINT 'Calculated risk metrics for João Santos';

-- Calculate risk metrics for Ana Costa (Premium User) 
EXEC portfolio.sp_CalculateUserRiskMetrics @AnaUserID, 90;
PRINT 'Calculated risk metrics for Ana Costa';

-- Calculate risk metrics for Isabella Rodriguez (Premium User)
EXEC portfolio.sp_CalculateUserRiskMetrics @IsabellaUserID, 90;
PRINT 'Calculated risk metrics for Isabella Rodriguez';

-- Calculate risk metrics for Sophie Dubois (Premium User)
EXEC portfolio.sp_CalculateUserRiskMetrics @SophieUserID, 90;
PRINT 'Calculated risk metrics for Sophie Dubois';

-- Calculate risk metrics for Luca Rossi (Premium User)
EXEC portfolio.sp_CalculateUserRiskMetrics @LucaUserID, 90;
PRINT 'Calculated risk metrics for Luca Rossi';

-- Generate historical risk metrics by running calculations with different time periods
PRINT 'Generating historical risk metrics for trend analysis...';

-- Historical calculations (30, 60, 90 days) for João
EXEC portfolio.sp_CalculateUserRiskMetrics @JoaoUserID, 30;
EXEC portfolio.sp_CalculateUserRiskMetrics @JoaoUserID, 60;

-- Historical calculations for Ana
EXEC portfolio.sp_CalculateUserRiskMetrics @AnaUserID, 30;
EXEC portfolio.sp_CalculateUserRiskMetrics @AnaUserID, 60;

-- Historical calculations for Isabella  
EXEC portfolio.sp_CalculateUserRiskMetrics @IsabellaUserID, 30;
EXEC portfolio.sp_CalculateUserRiskMetrics @IsabellaUserID, 60;

-- Historical calculations for Sophie
EXEC portfolio.sp_CalculateUserRiskMetrics @SophieUserID, 30;
EXEC portfolio.sp_CalculateUserRiskMetrics @SophieUserID, 60;

-- Historical calculations for Luca
EXEC portfolio.sp_CalculateUserRiskMetrics @LucaUserID, 30;
EXEC portfolio.sp_CalculateUserRiskMetrics @LucaUserID, 60;

PRINT 'Created comprehensive risk metrics for 5 premium users using stored procedures';
PRINT '';

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

PRINT '=== RISK METRICS SUMMARY ===';
SELECT 
    u.Name as UserName,
    u.UserType,
    COUNT(rm.MetricID) as TotalRiskAssessments,
    AVG(rm.AbsoluteReturn) as AvgReturn,
    AVG(rm.MaximumDrawdown) as AvgMaxDrawdown,
    AVG(rm.SharpeRatio) as AvgSharpeRatio,
    AVG(rm.VolatilityScore) as AvgVolatility,
    rm.RiskLevel,
    MAX(rm.CapturedAt) as LatestAssessment
FROM portfolio.Users u
LEFT JOIN portfolio.RiskMetrics rm ON u.UserID = rm.UserID
WHERE u.IsPremium = 1  -- Only premium users have risk metrics
GROUP BY u.Name, u.UserType, rm.RiskLevel
ORDER BY AvgReturn DESC;

PRINT '';
PRINT '=== RISK LEVEL DISTRIBUTION ===';
SELECT 
    RiskLevel,
    COUNT(DISTINCT UserID) as UsersInCategory,
    AVG(AbsoluteReturn) as AvgReturn,
    AVG(VolatilityScore) as AvgVolatility,
    AVG(SharpeRatio) as AvgSharpeRatio
FROM portfolio.RiskMetrics
GROUP BY RiskLevel
ORDER BY AvgReturn DESC;

PRINT '';
PRINT '=== LATEST RISK METRICS BY USER ===';
WITH LatestMetrics AS (
    SELECT 
        UserID,
        ROW_NUMBER() OVER (PARTITION BY UserID ORDER BY CapturedAt DESC) as rn,
        MaximumDrawdown,
        Beta,
        SharpeRatio,
        AbsoluteReturn,
        VolatilityScore,
        RiskLevel,
        CapturedAt
    FROM portfolio.RiskMetrics
)
SELECT 
    u.Name as UserName,
    lm.AbsoluteReturn,
    lm.MaximumDrawdown,
    lm.SharpeRatio,
    lm.Beta,
    lm.VolatilityScore,
    lm.RiskLevel,
    lm.CapturedAt as LastAssessment
FROM LatestMetrics lm
JOIN portfolio.Users u ON lm.UserID = u.UserID
WHERE lm.rn = 1
ORDER BY lm.AbsoluteReturn DESC;

PRINT 'Risk metrics calculated successfully using stored procedures!';

COMMIT TRANSACTION; 
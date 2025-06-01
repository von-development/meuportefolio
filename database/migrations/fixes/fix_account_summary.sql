-- Fix for sp_GetUserAccountSummary
USE p6g4;
GO

-- Drop and recreate the procedure with proper NULL handling
DROP PROCEDURE IF EXISTS portfolio.sp_GetUserAccountSummary;
GO

CREATE PROCEDURE portfolio.sp_GetUserAccountSummary (
    @UserID UNIQUEIDENTIFIER
) AS
BEGIN
    SET NOCOUNT ON;
    
    IF NOT EXISTS (SELECT 1 FROM portfolio.Users WHERE UserID = @UserID)
    BEGIN
        RAISERROR('User not found', 16, 1);
        RETURN;
    END
    
    SELECT 
        u.UserID,
        u.Name,
        u.UserType,
        u.AccountBalance,
        COALESCE(SUM(p.CurrentFunds), 0.0) AS TotalPortfolioValue,
        u.AccountBalance + COALESCE(SUM(p.CurrentFunds), 0.0) AS TotalNetWorth,
        CASE 
            WHEN COUNT(p.PortfolioID) = 1 AND MIN(p.PortfolioID) IS NULL THEN 0
            ELSE COUNT(p.PortfolioID)
        END AS PortfolioCount
    FROM portfolio.Users u
    LEFT JOIN portfolio.Portfolios p ON u.UserID = p.UserID
    WHERE u.UserID = @UserID
    GROUP BY 
        u.UserID, u.Name, u.UserType, u.AccountBalance;
END;
GO

PRINT 'Account summary procedure fixed successfully!'; 
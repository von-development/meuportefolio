/* ============================================================
meuPortfolio – Portfolio Creation Risk Trigger v2.0
Automatic risk calculation when new portfolios are created
============================================================ */

USE p6g4;
GO

/* ============================================================
PORTFOLIO CREATION TRIGGER FOR RISK CALCULATION
============================================================ */

-- Trigger to automatically calculate risk metrics when a new portfolio is created for premium users
CREATE TRIGGER portfolio.tr_Portfolio_AutoRiskCalculation
ON portfolio.Portfolios
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Get premium users who just created portfolios
        DECLARE @NewPremiumUsers TABLE (UserID UNIQUEIDENTIFIER);
        
        INSERT INTO @NewPremiumUsers (UserID)
        SELECT DISTINCT i.UserID
        FROM inserted i
        JOIN portfolio.Users u ON u.UserID = i.UserID
        WHERE u.IsPremium = 1;
        
        -- Process each premium user
        DECLARE @UserID UNIQUEIDENTIFIER;
        DECLARE user_cursor CURSOR FOR
        SELECT UserID FROM @NewPremiumUsers;
        
        OPEN user_cursor;
        FETCH NEXT FROM user_cursor INTO @UserID;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Check if user already has recent risk metrics (within last 24 hours)
            IF NOT EXISTS (
                SELECT 1 FROM portfolio.RiskMetrics rm 
                WHERE rm.UserID = @UserID 
                  AND rm.CapturedAt >= DATEADD(HOUR, -24, SYSDATETIME())
            )
            BEGIN
                -- Generate initial risk metrics using sample data (since new portfolio likely has no holdings yet)
                EXEC portfolio.sp_GenerateSampleRiskMetrics @UserID, 1;
                
                -- Log the automatic calculation
                INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, UserID, Message)
                VALUES ('INFO', 'AUTO_RISK_CALCULATION', @UserID, 'Automatic risk metrics generated for new portfolio creation');
            END
            
            FETCH NEXT FROM user_cursor INTO @UserID;
        END
        
        CLOSE user_cursor;
        DEALLOCATE user_cursor;
        
        -- Log the trigger event if any users were processed
        IF EXISTS (SELECT 1 FROM @NewPremiumUsers)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, Message)
            VALUES ('INFO', 'PORTFOLIO_CREATION_TRIGGER', 'New portfolio created, auto risk calculation triggered for ' + CAST((SELECT COUNT(*) FROM @NewPremiumUsers) AS NVARCHAR(10)) + ' premium users');
        END
        
    END TRY
    BEGIN CATCH
        -- Log any errors but don't fail the portfolio creation
        INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, Message)
        VALUES ('ERROR', 'PORTFOLIO_CREATION_TRIGGER', 'Error in portfolio creation risk trigger: ' + ERROR_MESSAGE());
    END CATCH
END;
GO

/* ============================================================
ENHANCED USER UPGRADE TRIGGER (Premium Upgrade)
============================================================ */

-- Trigger to automatically calculate risk metrics when a user upgrades to premium
CREATE TRIGGER portfolio.tr_User_PremiumUpgrade_RiskCalculation
ON portfolio.Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        -- Find users who just became premium (IsPremium changed from 0 to 1)
        DECLARE @NewPremiumUsers TABLE (UserID UNIQUEIDENTIFIER);
        
        INSERT INTO @NewPremiumUsers (UserID)
        SELECT i.UserID
        FROM inserted i
        JOIN deleted d ON d.UserID = i.UserID
        WHERE i.IsPremium = 1 AND d.IsPremium = 0;
        
        -- Generate risk metrics for newly premium users
        DECLARE @UserID UNIQUEIDENTIFIER;
        DECLARE user_cursor CURSOR FOR
        SELECT UserID FROM @NewPremiumUsers;
        
        OPEN user_cursor;
        FETCH NEXT FROM user_cursor INTO @UserID;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            BEGIN TRY
                -- Generate risk metrics for the new premium user
                EXEC portfolio.sp_CalculateUserRiskMetricsEnhanced @UserID, 90, 1;
                
                -- Log the automatic calculation
                INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, UserID, Message)
                VALUES ('INFO', 'PREMIUM_UPGRADE_RISK', @UserID, 'Risk metrics generated automatically after premium upgrade');
                
            END TRY
            BEGIN CATCH
                -- Log error for this specific user but continue with others
                INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, UserID, Message)
                VALUES ('ERROR', 'PREMIUM_UPGRADE_RISK', @UserID, 'Failed to generate risk metrics after premium upgrade: ' + ERROR_MESSAGE());
            END CATCH
            
            FETCH NEXT FROM user_cursor INTO @UserID;
        END
        
        CLOSE user_cursor;
        DEALLOCATE user_cursor;
        
        -- Log the trigger event if any users were processed
        IF EXISTS (SELECT 1 FROM @NewPremiumUsers)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, Message)
            VALUES ('INFO', 'PREMIUM_UPGRADE_TRIGGER', 'Premium upgrade detected, risk metrics generated for ' + CAST((SELECT COUNT(*) FROM @NewPremiumUsers) AS NVARCHAR(10)) + ' users');
        END
        
    END TRY
    BEGIN CATCH
        -- Log any errors but don't fail the user update
        INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, Message)
        VALUES ('ERROR', 'PREMIUM_UPGRADE_TRIGGER', 'Error in premium upgrade risk trigger: ' + ERROR_MESSAGE());
    END CATCH
END;
GO

/* ============================================================
QUICK RISK METRICS POPULATION PROCEDURE
============================================================ */

-- Quick procedure to populate risk metrics for existing users who don't have any
CREATE PROCEDURE portfolio.sp_PopulateInitialRiskMetrics
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        PRINT 'Populating initial risk metrics for premium users without risk data...';
        
        -- Find premium users without any risk metrics
        DECLARE @UsersWithoutRisk TABLE (UserID UNIQUEIDENTIFIER);
        
        INSERT INTO @UsersWithoutRisk (UserID)
        SELECT u.UserID
        FROM portfolio.Users u
        WHERE u.IsPremium = 1
          AND NOT EXISTS (
              SELECT 1 FROM portfolio.RiskMetrics rm 
              WHERE rm.UserID = u.UserID
          );
        
        DECLARE @UserCount INT = (SELECT COUNT(*) FROM @UsersWithoutRisk);
        PRINT 'Found ' + CAST(@UserCount AS NVARCHAR(10)) + ' premium users without risk metrics';
        
        IF @UserCount > 0
        BEGIN
            -- Generate risk metrics for users without any
            DECLARE @UserID UNIQUEIDENTIFIER;
            DECLARE @ProcessedCount INT = 0;
            
            DECLARE user_cursor CURSOR FOR
            SELECT UserID FROM @UsersWithoutRisk;
            
            OPEN user_cursor;
            FETCH NEXT FROM user_cursor INTO @UserID;
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                BEGIN TRY
                    EXEC portfolio.sp_CalculateUserRiskMetricsEnhanced @UserID, 90, 1;
                    SET @ProcessedCount = @ProcessedCount + 1;
                END TRY
                BEGIN CATCH
                    -- Log error but continue
                    INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, UserID, Message)
                    VALUES ('ERROR', 'INITIAL_RISK_POPULATION', @UserID, 'Failed to generate initial risk metrics: ' + ERROR_MESSAGE());
                END CATCH
                
                FETCH NEXT FROM user_cursor INTO @UserID;
            END
            
            CLOSE user_cursor;
            DEALLOCATE user_cursor;
            
            PRINT 'Successfully generated risk metrics for ' + CAST(@ProcessedCount AS NVARCHAR(10)) + ' users';
        END
        ELSE
        BEGIN
            PRINT 'All premium users already have risk metrics!';
        END
        
    END TRY
    BEGIN CATCH
        PRINT 'Error in initial risk metrics population: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

PRINT 'Portfolio creation and premium upgrade triggers created successfully!';
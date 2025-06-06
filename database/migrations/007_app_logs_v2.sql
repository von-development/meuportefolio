    /* ============================================================
    meuPortfolio – Enhanced Application Logging System v2.0
    Comprehensive database activity tracking and API logging
    ============================================================ */

    USE p6g4;
    GO

    /* ============================================================
    1. ENHANCED APPLICATION LOGS TABLE
    ============================================================ */

    -- First, let's enhance the existing ApplicationLogs table
    ALTER TABLE portfolio.ApplicationLogs ADD
        -- Enhanced Event Tracking
        OperationType NVARCHAR(20) NULL,                     -- 'INSERT', 'UPDATE', 'DELETE', 'SELECT', 'API_CALL'
        RecordID NVARCHAR(100) NULL,                         -- Primary key of affected record
        OldValues NVARCHAR(MAX) NULL,                        -- JSON of old values (for updates)
        NewValues NVARCHAR(MAX) NULL,                        -- JSON of new values (for inserts/updates)
        
        -- API and Session Context
        SessionID NVARCHAR(100) NULL,                        -- Session identifier
        IPAddress NVARCHAR(45) NULL,                         -- Client IP address
        UserAgent NVARCHAR(500) NULL,                        -- Client user agent
        APIEndpoint NVARCHAR(200) NULL,                      -- API endpoint called
        HTTPMethod NVARCHAR(10) NULL,                        -- GET, POST, PUT, DELETE
        HTTPStatusCode INT NULL,                             -- Response status code
        ExecutionTimeMS INT NULL,                            -- Execution time in milliseconds
        
        -- Error and Performance Tracking
        ErrorCode NVARCHAR(50) NULL,                         -- Error code if applicable
        StackTrace NVARCHAR(MAX) NULL,                       -- Error stack trace
        QueryPerformance NVARCHAR(MAX) NULL;                 -- Query performance metrics

    -- Update existing constraint to include new operation types
    ALTER TABLE portfolio.ApplicationLogs 
    DROP CONSTRAINT IF EXISTS CK_ApplicationLogs_LogLevel;

    ALTER TABLE portfolio.ApplicationLogs 
    ADD CONSTRAINT CK_ApplicationLogs_LogLevel 
    CHECK (LogLevel IN ('TRACE', 'DEBUG', 'INFO', 'WARN', 'ERROR', 'FATAL'));

    GO

    /* ============================================================
    2. LOGGING HELPER FUNCTIONS
    ============================================================ */

    -- Function to get current session context
    CREATE FUNCTION portfolio.fn_GetCurrentContext()
    RETURNS TABLE
    AS
    RETURN (
        SELECT 
            CAST(SESSION_CONTEXT(N'UserID') AS UNIQUEIDENTIFIER) AS UserID,
            CAST(SESSION_CONTEXT(N'SessionID') AS NVARCHAR(100)) AS SessionID,
            CAST(SESSION_CONTEXT(N'IPAddress') AS NVARCHAR(45)) AS IPAddress,
            CAST(SESSION_CONTEXT(N'UserAgent') AS NVARCHAR(500)) AS UserAgent,
            CAST(SESSION_CONTEXT(N'APIEndpoint') AS NVARCHAR(200)) AS APIEndpoint,
            CAST(SESSION_CONTEXT(N'HTTPMethod') AS NVARCHAR(10)) AS HTTPMethod
    );
    GO

    -- Function to convert values to JSON for logging
    CREATE FUNCTION portfolio.fn_ConvertToLogJSON(
        @TableName NVARCHAR(100),
        @RecordData NVARCHAR(MAX)
    )
    RETURNS NVARCHAR(MAX)
    AS
    BEGIN
        DECLARE @Result NVARCHAR(MAX);
        
        -- Simple JSON conversion (you can enhance this based on your needs)
        SET @Result = CONCAT('{"table":"', @TableName, '","data":', ISNULL(@RecordData, 'null'), '}');
        
        RETURN @Result;
    END;
    GO

    /* ============================================================
    3. CORE LOGGING PROCEDURES
    ============================================================ */

    -- Enhanced logging procedure
    CREATE PROCEDURE portfolio.sp_LogActivity (
        @LogLevel NVARCHAR(10),
        @EventType NVARCHAR(50),
        @TableName NVARCHAR(100) = NULL,
        @OperationType NVARCHAR(20) = NULL,
        @RecordID NVARCHAR(100) = NULL,
        @Message NVARCHAR(500),
        @OldValues NVARCHAR(MAX) = NULL,
        @NewValues NVARCHAR(MAX) = NULL,
        @ErrorCode NVARCHAR(50) = NULL,
        @StackTrace NVARCHAR(MAX) = NULL,
        @HTTPStatusCode INT = NULL,
        @ExecutionTimeMS INT = NULL
    ) AS
    BEGIN
        SET NOCOUNT ON;
        
        DECLARE @UserID UNIQUEIDENTIFIER;
        DECLARE @SessionID NVARCHAR(100);
        DECLARE @IPAddress NVARCHAR(45);
        DECLARE @UserAgent NVARCHAR(500);
        DECLARE @APIEndpoint NVARCHAR(200);
        DECLARE @HTTPMethod NVARCHAR(10);
        
        -- Get current context
        SELECT 
            @UserID = UserID,
            @SessionID = SessionID,
            @IPAddress = IPAddress,
            @UserAgent = UserAgent,
            @APIEndpoint = APIEndpoint,
            @HTTPMethod = HTTPMethod
        FROM portfolio.fn_GetCurrentContext();
        
        INSERT INTO portfolio.ApplicationLogs (
            LogLevel, EventType, TableName, OperationType, RecordID,
            UserID, SessionID, IPAddress, UserAgent, APIEndpoint, HTTPMethod,
            Message, OldValues, NewValues, 
            ErrorCode, StackTrace, HTTPStatusCode, ExecutionTimeMS
        )
        VALUES (
            @LogLevel, @EventType, @TableName, @OperationType, @RecordID,
            @UserID, @SessionID, @IPAddress, @UserAgent, @APIEndpoint, @HTTPMethod,
            @Message, @OldValues, @NewValues,
            @ErrorCode, @StackTrace, @HTTPStatusCode, @ExecutionTimeMS
        );
    END;
    GO

    -- API Call logging procedure
    CREATE PROCEDURE portfolio.sp_LogAPICall (
        @APIEndpoint NVARCHAR(200),
        @HTTPMethod NVARCHAR(10),
        @HTTPStatusCode INT,
        @ExecutionTimeMS INT,
        @UserID UNIQUEIDENTIFIER = NULL,
        @SessionID NVARCHAR(100) = NULL,
        @IPAddress NVARCHAR(45) = NULL,
        @UserAgent NVARCHAR(500) = NULL,
        @RequestData NVARCHAR(MAX) = NULL,
        @ResponseData NVARCHAR(MAX) = NULL,
        @ErrorMessage NVARCHAR(500) = NULL
    ) AS
    BEGIN
        SET NOCOUNT ON;
        
        DECLARE @LogLevel NVARCHAR(10) = CASE 
            WHEN @HTTPStatusCode >= 500 THEN 'ERROR'
            WHEN @HTTPStatusCode >= 400 THEN 'WARN'
            ELSE 'INFO'
        END;
        
        DECLARE @Message NVARCHAR(500) = CONCAT(
            @HTTPMethod, ' ', @APIEndpoint, ' - ', 
            @HTTPStatusCode, ' (', @ExecutionTimeMS, 'ms)'
        );
        
        INSERT INTO portfolio.ApplicationLogs (
            LogLevel, EventType, OperationType, UserID, SessionID, 
            IPAddress, UserAgent, APIEndpoint, HTTPMethod, HTTPStatusCode, 
            ExecutionTimeMS, Message, NewValues, ErrorCode
        )
        VALUES (
            @LogLevel, 'API_CALL', 'API_REQUEST', @UserID, @SessionID,
            @IPAddress, @UserAgent, @APIEndpoint, @HTTPMethod, @HTTPStatusCode,
            @ExecutionTimeMS, ISNULL(@ErrorMessage, @Message), 
            CASE WHEN @RequestData IS NOT NULL OR @ResponseData IS NOT NULL 
                THEN CONCAT('{"request":', ISNULL(@RequestData, 'null'), ',"response":', ISNULL(@ResponseData, 'null'), '}')
                ELSE NULL END,
            CASE WHEN @HTTPStatusCode >= 400 THEN CAST(@HTTPStatusCode AS NVARCHAR(10)) ELSE NULL END
        );
    END;
    GO

    -- User session tracking procedure
    CREATE PROCEDURE portfolio.sp_LogUserSession (
        @UserID UNIQUEIDENTIFIER,
        @SessionID NVARCHAR(100),
        @IPAddress NVARCHAR(45),
        @UserAgent NVARCHAR(500),
        @ActionType NVARCHAR(20), -- 'LOGIN', 'LOGOUT', 'SESSION_EXPIRED'
        @Success BIT = 1
    ) AS
    BEGIN
        SET NOCOUNT ON;
        
        DECLARE @LogLevel NVARCHAR(10) = CASE WHEN @Success = 1 THEN 'INFO' ELSE 'WARN' END;
        DECLARE @Message NVARCHAR(500) = CONCAT('User session ', @ActionType, ' - ', CASE WHEN @Success = 1 THEN 'Success' ELSE 'Failed' END);
        
        INSERT INTO portfolio.ApplicationLogs (
            LogLevel, EventType, OperationType, UserID, SessionID, 
            IPAddress, UserAgent, Message
        )
        VALUES (
            @LogLevel, 'USER_SESSION', @ActionType, @UserID, @SessionID,
            @IPAddress, @UserAgent, @Message
        );
    END;
    GO

    /* ============================================================
    4. DATABASE TRIGGER SYSTEM
    ============================================================ */

    -- Trigger for Users table
    CREATE TRIGGER portfolio.tr_Users_ActivityLog
    ON portfolio.Users
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        
        -- Handle INSERT
        IF EXISTS(SELECT * FROM INSERTED) AND NOT EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, UserID, Message, NewValues)
            SELECT 'INFO', 'USER_MANAGEMENT', 'Users', 'INSERT', CAST(i.UserID AS NVARCHAR(100)), i.UserID,
                CONCAT('New user created: ', i.Name, ' (', i.Email, ')'),
                CONCAT('{"UserID":"', i.UserID, '","Name":"', i.Name, '","Email":"', i.Email, '","UserType":"', i.UserType, '","IsPremium":', CASE WHEN i.IsPremium = 1 THEN 'true' ELSE 'false' END, '}')
            FROM INSERTED i;
        END
        
        -- Handle UPDATE
        IF EXISTS(SELECT * FROM INSERTED) AND EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, UserID, Message, OldValues, NewValues)
            SELECT 'INFO', 'USER_MANAGEMENT', 'Users', 'UPDATE', CAST(i.UserID AS NVARCHAR(100)), i.UserID,
                CONCAT('User updated: ', i.Name),
                CONCAT('{"Name":"', d.Name, '","Email":"', d.Email, '","UserType":"', d.UserType, '","IsPremium":', CASE WHEN d.IsPremium = 1 THEN 'true' ELSE 'false' END, ',"AccountBalance":', d.AccountBalance, '}'),
                CONCAT('{"Name":"', i.Name, '","Email":"', i.Email, '","UserType":"', i.UserType, '","IsPremium":', CASE WHEN i.IsPremium = 1 THEN 'true' ELSE 'false' END, ',"AccountBalance":', i.AccountBalance, '}')
            FROM INSERTED i
            JOIN DELETED d ON i.UserID = d.UserID;
        END
        
        -- Handle DELETE
        IF NOT EXISTS(SELECT * FROM INSERTED) AND EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, UserID, Message, OldValues)
            SELECT 'WARN', 'USER_MANAGEMENT', 'Users', 'DELETE', CAST(d.UserID AS NVARCHAR(100)), d.UserID,
                CONCAT('User deleted: ', d.Name, ' (', d.Email, ')'),
                CONCAT('{"UserID":"', d.UserID, '","Name":"', d.Name, '","Email":"', d.Email, '","UserType":"', d.UserType, '"}')
            FROM DELETED d;
        END
    END;
    GO

    -- Trigger for Portfolios table
    CREATE TRIGGER portfolio.tr_Portfolios_ActivityLog
    ON portfolio.Portfolios
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        
        -- Handle INSERT
        IF EXISTS(SELECT * FROM INSERTED) AND NOT EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, UserID, Message, NewValues)
            SELECT 'INFO', 'PORTFOLIO_MANAGEMENT', 'Portfolios', 'INSERT', CAST(i.PortfolioID AS NVARCHAR(100)), i.UserID,
                CONCAT('New portfolio created: ', i.Name),
                CONCAT('{"PortfolioID":', i.PortfolioID, ',"Name":"', i.Name, '","CurrentFunds":', i.CurrentFunds, '}')
            FROM INSERTED i;
        END
        
        -- Handle UPDATE
        IF EXISTS(SELECT * FROM INSERTED) AND EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, UserID, Message, OldValues, NewValues)
            SELECT 'INFO', 'PORTFOLIO_MANAGEMENT', 'Portfolios', 'UPDATE', CAST(i.PortfolioID AS NVARCHAR(100)), i.UserID,
                CONCAT('Portfolio updated: ', i.Name),
                CONCAT('{"CurrentFunds":', d.CurrentFunds, ',"CurrentProfitPct":', d.CurrentProfitPct, '}'),
                CONCAT('{"CurrentFunds":', i.CurrentFunds, ',"CurrentProfitPct":', i.CurrentProfitPct, '}')
            FROM INSERTED i
            JOIN DELETED d ON i.PortfolioID = d.PortfolioID;
        END
        
        -- Handle DELETE
        IF NOT EXISTS(SELECT * FROM INSERTED) AND EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, UserID, Message, OldValues)
            SELECT 'WARN', 'PORTFOLIO_MANAGEMENT', 'Portfolios', 'DELETE', CAST(d.PortfolioID AS NVARCHAR(100)), d.UserID,
                CONCAT('Portfolio deleted: ', d.Name),
                CONCAT('{"PortfolioID":', d.PortfolioID, ',"Name":"', d.Name, '","CurrentFunds":', d.CurrentFunds, '}')
            FROM DELETED d;
        END
    END;
    GO

    -- Trigger for Transactions table
    CREATE TRIGGER portfolio.tr_Transactions_ActivityLog
    ON portfolio.Transactions
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        
        -- Handle INSERT
        IF EXISTS(SELECT * FROM INSERTED) AND NOT EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, UserID, Message, NewValues)
            SELECT 'INFO', 'TRADING', 'Transactions', 'INSERT', CAST(i.TransactionID AS NVARCHAR(100)), i.UserID,
                CONCAT('New transaction: ', i.TransactionType, ' ', i.Quantity, ' units at $', i.UnitPrice),
                CONCAT('{"TransactionID":', i.TransactionID, ',"TransactionType":"', i.TransactionType, '","Quantity":', i.Quantity, ',"UnitPrice":', i.UnitPrice, ',"AssetID":', i.AssetID, ',"Status":"', i.Status, '"}')
            FROM INSERTED i;
        END
        
        -- Handle UPDATE (mainly for status changes)
        IF EXISTS(SELECT * FROM INSERTED) AND EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, UserID, Message, OldValues, NewValues)
            SELECT 'INFO', 'TRADING', 'Transactions', 'UPDATE', CAST(i.TransactionID AS NVARCHAR(100)), i.UserID,
                CONCAT('Transaction status changed from ', d.Status, ' to ', i.Status),
                CONCAT('{"Status":"', d.Status, '"}'),
                CONCAT('{"Status":"', i.Status, '"}')
            FROM INSERTED i
            JOIN DELETED d ON i.TransactionID = d.TransactionID
            WHERE i.Status != d.Status;
        END
    END;
    GO

    -- Trigger for FundTransactions table
    CREATE TRIGGER portfolio.tr_FundTransactions_ActivityLog
    ON portfolio.FundTransactions
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        
        -- Handle INSERT
        IF EXISTS(SELECT * FROM INSERTED) AND NOT EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, UserID, Message, NewValues)
            SELECT 'INFO', 'FUND_MANAGEMENT', 'FundTransactions', 'INSERT', CAST(i.FundTransactionID AS NVARCHAR(100)), i.UserID,
                CONCAT('Fund transaction: ', i.TransactionType, ' $', i.Amount, ' - ', ISNULL(i.Description, 'No description')),
                CONCAT('{"FundTransactionID":', i.FundTransactionID, ',"TransactionType":"', i.TransactionType, '","Amount":', i.Amount, ',"BalanceAfter":', i.BalanceAfter, ',"Description":"', ISNULL(i.Description, ''), '"}')
            FROM INSERTED i;
        END
    END;
    GO

    -- Trigger for Assets table
    CREATE TRIGGER portfolio.tr_Assets_ActivityLog
    ON portfolio.Assets
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        
        -- Handle INSERT
        IF EXISTS(SELECT * FROM INSERTED) AND NOT EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, Message, NewValues)
            SELECT 'INFO', 'ASSET_MANAGEMENT', 'Assets', 'INSERT', CAST(i.AssetID AS NVARCHAR(100)),
                CONCAT('New asset created: ', i.Symbol, ' - ', i.Name),
                CONCAT('{"AssetID":', i.AssetID, ',"Symbol":"', i.Symbol, '","Name":"', i.Name, '","AssetType":"', i.AssetType, '","Price":', i.Price, '}')
            FROM INSERTED i;
        END
        
        -- Handle UPDATE (price changes)
        IF EXISTS(SELECT * FROM INSERTED) AND EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, Message, OldValues, NewValues)
            SELECT 'INFO', 'ASSET_MANAGEMENT', 'Assets', 'UPDATE', CAST(i.AssetID AS NVARCHAR(100)),
                CONCAT('Asset price updated: ', i.Symbol, ' from $', d.Price, ' to $', i.Price),
                CONCAT('{"Price":', d.Price, ',"Volume":', d.Volume, '}'),
                CONCAT('{"Price":', i.Price, ',"Volume":', i.Volume, '}')
            FROM INSERTED i
            JOIN DELETED d ON i.AssetID = d.AssetID
            WHERE i.Price != d.Price OR i.Volume != d.Volume;
        END
    END;
    GO

    -- Trigger for RiskMetrics table
    CREATE TRIGGER portfolio.tr_RiskMetrics_ActivityLog
    ON portfolio.RiskMetrics
    AFTER INSERT, UPDATE, DELETE
    AS
    BEGIN
        SET NOCOUNT ON;
        
        -- Handle INSERT
        IF EXISTS(SELECT * FROM INSERTED) AND NOT EXISTS(SELECT * FROM DELETED)
        BEGIN
            INSERT INTO portfolio.ApplicationLogs (LogLevel, EventType, TableName, OperationType, RecordID, UserID, Message, NewValues)
            SELECT 'INFO', 'RISK_CALCULATION', 'RiskMetrics', 'INSERT', CAST(i.MetricID AS NVARCHAR(100)), i.UserID,
                CONCAT('Risk metrics calculated: ', i.RiskLevel, ' profile'),
                CONCAT('{"MetricID":', i.MetricID, ',"RiskLevel":"', i.RiskLevel, '","MaximumDrawdown":', ISNULL(CAST(i.MaximumDrawdown AS NVARCHAR(20)), 'null'), ',"Beta":', ISNULL(CAST(i.Beta AS NVARCHAR(20)), 'null'), ',"SharpeRatio":', ISNULL(CAST(i.SharpeRatio AS NVARCHAR(20)), 'null'), ',"VolatilityScore":', ISNULL(CAST(i.VolatilityScore AS NVARCHAR(20)), 'null'), '}')
            FROM INSERTED i;
        END
    END;
    GO

    /* ============================================================
    5. SESSION CONTEXT MANAGEMENT
    ============================================================ */

    -- Procedure to set session context for API calls
    CREATE PROCEDURE portfolio.sp_SetSessionContext (
        @UserID UNIQUEIDENTIFIER = NULL,
        @SessionID NVARCHAR(100) = NULL,
        @IPAddress NVARCHAR(45) = NULL,
        @UserAgent NVARCHAR(500) = NULL,
        @APIEndpoint NVARCHAR(200) = NULL,
        @HTTPMethod NVARCHAR(10) = NULL
    ) AS
    BEGIN
        SET NOCOUNT ON;
        
        IF @UserID IS NOT NULL
            EXEC sp_set_session_context @key = N'UserID', @value = @UserID;
        
        IF @SessionID IS NOT NULL
            EXEC sp_set_session_context @key = N'SessionID', @value = @SessionID;
        
        IF @IPAddress IS NOT NULL
            EXEC sp_set_session_context @key = N'IPAddress', @value = @IPAddress;
        
        IF @UserAgent IS NOT NULL
            EXEC sp_set_session_context @key = N'UserAgent', @value = @UserAgent;
        
        IF @APIEndpoint IS NOT NULL
            EXEC sp_set_session_context @key = N'APIEndpoint', @value = @APIEndpoint;
        
        IF @HTTPMethod IS NOT NULL
            EXEC sp_set_session_context @key = N'HTTPMethod', @value = @HTTPMethod;
    END;
    GO

    /* ============================================================
    6. LOG ANALYSIS AND REPORTING PROCEDURES
    ============================================================ */

    -- Get activity summary for a user
    CREATE PROCEDURE portfolio.sp_GetUserActivitySummary (
        @UserID UNIQUEIDENTIFIER,
        @DaysBack INT = 30
    ) AS
    BEGIN
        SET NOCOUNT ON;
        
        SELECT 
            EventType,
            OperationType,
            COUNT(*) AS EventCount,
            MIN(CreatedAt) AS FirstEvent,
            MAX(CreatedAt) AS LastEvent
        FROM portfolio.ApplicationLogs
        WHERE UserID = @UserID
        AND CreatedAt >= DATEADD(DAY, -@DaysBack, SYSDATETIME())
        GROUP BY EventType, OperationType
        ORDER BY EventCount DESC;
    END;
    GO

    -- Get API performance metrics
    CREATE PROCEDURE portfolio.sp_GetAPIPerformanceMetrics (
        @DaysBack INT = 7
    ) AS
    BEGIN
        SET NOCOUNT ON;
        
        SELECT 
            APIEndpoint,
            HTTPMethod,
            COUNT(*) AS RequestCount,
            AVG(ExecutionTimeMS) AS AvgExecutionTime,
            MIN(ExecutionTimeMS) AS MinExecutionTime,
            MAX(ExecutionTimeMS) AS MaxExecutionTime,
            SUM(CASE WHEN HTTPStatusCode >= 400 THEN 1 ELSE 0 END) AS ErrorCount,
            CAST(SUM(CASE WHEN HTTPStatusCode >= 400 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS ErrorRate
        FROM portfolio.ApplicationLogs
        WHERE EventType = 'API_CALL'
        AND CreatedAt >= DATEADD(DAY, -@DaysBack, SYSDATETIME())
        AND APIEndpoint IS NOT NULL
        GROUP BY APIEndpoint, HTTPMethod
        ORDER BY RequestCount DESC;
    END;
    GO

    -- Get system health overview
    CREATE PROCEDURE portfolio.sp_GetSystemHealthOverview (
        @HoursBack INT = 24
    ) AS
    BEGIN
        SET NOCOUNT ON;
        
        SELECT 
            'Summary' AS MetricType,
            COUNT(*) AS TotalEvents,
            SUM(CASE WHEN LogLevel = 'ERROR' THEN 1 ELSE 0 END) AS ErrorCount,
            SUM(CASE WHEN LogLevel = 'WARN' THEN 1 ELSE 0 END) AS WarningCount,
            COUNT(DISTINCT UserID) AS ActiveUsers,
            COUNT(DISTINCT SessionID) AS ActiveSessions
        FROM portfolio.ApplicationLogs
        WHERE CreatedAt >= DATEADD(HOUR, -@HoursBack, SYSDATETIME())
        
        UNION ALL
        
        SELECT 
            EventType AS MetricType,
            COUNT(*) AS TotalEvents,
            SUM(CASE WHEN LogLevel = 'ERROR' THEN 1 ELSE 0 END) AS ErrorCount,
            SUM(CASE WHEN LogLevel = 'WARN' THEN 1 ELSE 0 END) AS WarningCount,
            COUNT(DISTINCT UserID) AS ActiveUsers,
            COUNT(DISTINCT SessionID) AS ActiveSessions
        FROM portfolio.ApplicationLogs
        WHERE CreatedAt >= DATEADD(HOUR, -@HoursBack, SYSDATETIME())
        GROUP BY EventType
        ORDER BY TotalEvents DESC;
    END;
    GO

PRINT 'Enhanced application logging system created successfully!';
PRINT '';
PRINT 'SUMMARY OF ENHANCED LOGGING FEATURES:';
PRINT '✅ Enhanced ApplicationLogs table with comprehensive tracking fields';
PRINT '✅ Logging helper functions and procedures';
PRINT '✅ Comprehensive database triggers for all major tables';
PRINT '✅ API call logging and session management';
PRINT '✅ Performance monitoring and error tracking';
PRINT '✅ Log analysis and reporting procedures';
PRINT '';
PRINT 'NEW LOGGING CAPABILITIES:';
PRINT '🚀 Complete audit trail of all database operations';
PRINT '🚀 API endpoint performance monitoring'; 
PRINT '🚀 User session tracking and security logging';
PRINT '🚀 Automatic JSON-formatted data capture';
PRINT '🚀 Real-time error and warning detection';
PRINT '🚀 System health monitoring and reporting';
PRINT '';
PRINT 'USAGE EXAMPLES:';
PRINT '-- Log API call: EXEC portfolio.sp_LogAPICall @APIEndpoint=''/api/v1/users'', @HTTPMethod=''GET'', @HTTPStatusCode=200, @ExecutionTimeMS=150';
PRINT '-- Set session context: EXEC portfolio.sp_SetSessionContext @UserID=''...'', @SessionID=''...'', @IPAddress=''127.0.0.1''';
PRINT '-- Get user activity: EXEC portfolio.sp_GetUserActivitySummary @UserID=''...'', @DaysBack=30';
PRINT '-- Get API metrics: EXEC portfolio.sp_GetAPIPerformanceMetrics @DaysBack=7';
PRINT '-- System health: EXEC portfolio.sp_GetSystemHealthOverview @HoursBack=24'; 
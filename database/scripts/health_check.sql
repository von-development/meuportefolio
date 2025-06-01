/* ============================================================
meuPortfolio - Database Health Check Script
Quick overview of database status, table counts, and system health
============================================================ */

USE p6g4;
GO

PRINT '============================================================';
PRINT 'MEUPORTEFOLIO DATABASE HEALTH CHECK';
PRINT 'Executed: ' + CONVERT(NVARCHAR, SYSDATETIME(), 120);
PRINT '============================================================';
PRINT '';

-- Database Information
PRINT ' DATABASE INFORMATION:';
SELECT 
    DB_NAME() AS DatabaseName,
    SUSER_SNAME() AS CurrentUser,
    @@VERSION AS SQLServerVersion;

PRINT '';
PRINT ' SCHEMA OBJECTS COUNT:';

-- Count all objects by type
SELECT 
    'Tables' AS ObjectType,
    COUNT(*) AS Count
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_SCHEMA = 'portfolio' AND TABLE_TYPE = 'BASE TABLE'

UNION ALL

SELECT 
    'Views' AS ObjectType,
    COUNT(*) AS Count
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'portfolio'

UNION ALL

SELECT 
    'Functions' AS ObjectType,
    COUNT(*) AS Count
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_SCHEMA = 'portfolio' AND ROUTINE_TYPE = 'FUNCTION'

UNION ALL

SELECT 
    'Procedures' AS ObjectType,
    COUNT(*) AS Count
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_SCHEMA = 'portfolio' AND ROUTINE_TYPE = 'PROCEDURE';

PRINT '';
PRINT ' TABLE ROW COUNTS:';

-- Table row counts
SELECT 
    t.TABLE_NAME AS TableName,
    ISNULL(p.rows, 0) AS RowCount
FROM INFORMATION_SCHEMA.TABLES t
LEFT JOIN sys.partitions p ON p.object_id = OBJECT_ID('portfolio.' + t.TABLE_NAME)
WHERE t.TABLE_SCHEMA = 'portfolio' 
  AND t.TABLE_TYPE = 'BASE TABLE'
  AND (p.index_id = 0 OR p.index_id = 1)
ORDER BY ISNULL(p.rows, 0) DESC;

PRINT '';
PRINT ' INDEX STATUS:';

-- Index information
SELECT 
    i.name AS IndexName,
    t.name AS TableName,
    i.type_desc AS IndexType
FROM sys.indexes i
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'portfolio'
  AND i.name IS NOT NULL
ORDER BY t.name, i.name;

PRINT '';
PRINT ' Health check completed successfully!'; 
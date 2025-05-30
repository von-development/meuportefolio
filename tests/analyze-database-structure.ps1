# Database Structure Analysis Script
Write-Host "=== MEUPORTEFOLIO DATABASE STRUCTURE ANALYSIS ===" -ForegroundColor Cyan

# Database connection parameters
$serverName = "localhost,1433"
$databaseName = "meuportefolio"
$userId = "sa"
$password = "meuportefolio!23"
$connectionString = "Server=$serverName;Database=$databaseName;User Id=$userId;Password=$password;TrustServerCertificate=true;"

function Execute-SqlQuery {
    param(
        [string]$Query,
        [string]$Description
    )
    
    try {
        Write-Host "`n=== $Description ===" -ForegroundColor Yellow
        
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $command = New-Object System.Data.SqlClient.SqlCommand($Query, $connection)
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
        $dataSet = New-Object System.Data.DataSet
        
        $connection.Open()
        $adapter.Fill($dataSet) | Out-Null
        $connection.Close()
        
        if ($dataSet.Tables[0].Rows.Count -gt 0) {
            $dataSet.Tables[0] | Format-Table -AutoSize | Out-String | Write-Host
        } else {
            Write-Host "No results found." -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 1. Database Overview
Execute-SqlQuery -Description "Database Overview" -Query @"
SELECT 
    DB_NAME() AS DatabaseName,
    (SELECT COUNT(*) FROM sys.tables WHERE schema_id = SCHEMA_ID('portfolio')) AS TableCount,
    (SELECT COUNT(*) FROM sys.views WHERE schema_id = SCHEMA_ID('portfolio')) AS ViewCount,
    (SELECT COUNT(*) FROM sys.procedures WHERE schema_id = SCHEMA_ID('portfolio')) AS StoredProcedureCount,
    (SELECT COUNT(*) FROM sys.indexes WHERE object_id IN (SELECT object_id FROM sys.tables WHERE schema_id = SCHEMA_ID('portfolio'))) AS IndexCount
"@

# 2. All Tables with Row Counts
Execute-SqlQuery -Description "Tables with Row Counts and Sizes" -Query @"
SELECT 
    t.name AS TableName,
    s.name AS SchemaName,
    p.rows AS RowCount,
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'portfolio'
    AND i.object_id > 255
    AND i.index_id <= 1
GROUP BY t.name, s.name, p.rows
ORDER BY RowCount DESC;
"@

# 3. Table Structure and Columns
Execute-SqlQuery -Description "Table Columns and Data Types" -Query @"
SELECT 
    t.TABLE_NAME,
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.CHARACTER_MAXIMUM_LENGTH,
    c.NUMERIC_PRECISION,
    c.NUMERIC_SCALE,
    c.IS_NULLABLE,
    c.COLUMN_DEFAULT,
    CASE WHEN pk.COLUMN_NAME IS NOT NULL THEN 'YES' ELSE 'NO' END AS IS_PRIMARY_KEY
FROM INFORMATION_SCHEMA.TABLES t
LEFT JOIN INFORMATION_SCHEMA.COLUMNS c ON t.TABLE_NAME = c.TABLE_NAME AND t.TABLE_SCHEMA = c.TABLE_SCHEMA
LEFT JOIN (
    SELECT ku.TABLE_NAME, ku.COLUMN_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS tc
    INNER JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS ku
        ON tc.CONSTRAINT_TYPE = 'PRIMARY KEY' 
        AND tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME
    WHERE tc.TABLE_SCHEMA = 'portfolio'
) pk ON c.TABLE_NAME = pk.TABLE_NAME AND c.COLUMN_NAME = pk.COLUMN_NAME
WHERE t.TABLE_SCHEMA = 'portfolio' AND t.TABLE_TYPE = 'BASE TABLE'
ORDER BY t.TABLE_NAME, c.ORDINAL_POSITION;
"@

# 4. Foreign Key Relationships
Execute-SqlQuery -Description "Foreign Key Relationships" -Query @"
SELECT 
    fk.name AS ForeignKeyName,
    tp.name AS ParentTable,
    cp.name AS ParentColumn,
    tr.name AS ReferencedTable,
    cr.name AS ReferencedColumn,
    fk.delete_referential_action_desc AS DeleteAction,
    fk.update_referential_action_desc AS UpdateAction
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tp ON fkc.parent_object_id = tp.object_id
INNER JOIN sys.columns cp ON fkc.parent_object_id = cp.object_id AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.tables tr ON fkc.referenced_object_id = tr.object_id
INNER JOIN sys.columns cr ON fkc.referenced_object_id = cr.object_id AND fkc.referenced_column_id = cr.column_id
WHERE tp.schema_id = SCHEMA_ID('portfolio') OR tr.schema_id = SCHEMA_ID('portfolio')
ORDER BY tp.name, fk.name;
"@

# 5. Indexes Analysis
Execute-SqlQuery -Description "Index Analysis" -Query @"
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.is_primary_key AS IsPrimaryKey,
    i.is_unique_constraint AS IsUniqueConstraint,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS IndexColumns,
    i.fill_factor AS FillFactor
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE t.schema_id = SCHEMA_ID('portfolio')
    AND i.type > 0  -- Exclude heaps
GROUP BY t.name, i.name, i.type_desc, i.is_unique, i.is_primary_key, i.is_unique_constraint, i.fill_factor
ORDER BY t.name, i.name;
"@

# 6. Views Analysis
Execute-SqlQuery -Description "Views in Database" -Query @"
SELECT 
    v.name AS ViewName,
    s.name AS SchemaName,
    v.create_date AS CreatedDate,
    v.modify_date AS ModifiedDate
FROM sys.views v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE s.name = 'portfolio'
ORDER BY v.name;
"@

# 7. Stored Procedures Analysis
Execute-SqlQuery -Description "Stored Procedures" -Query @"
SELECT 
    p.name AS ProcedureName,
    s.name AS SchemaName,
    p.create_date AS CreatedDate,
    p.modify_date AS ModifiedDate,
    para.parameter_count AS ParameterCount
FROM sys.procedures p
INNER JOIN sys.schemas s ON p.schema_id = s.schema_id
LEFT JOIN (
    SELECT object_id, COUNT(*) AS parameter_count
    FROM sys.parameters
    WHERE parameter_id > 0
    GROUP BY object_id
) para ON p.object_id = para.object_id
WHERE s.name = 'portfolio'
ORDER BY p.name;
"@

# 8. Check Constraints
Execute-SqlQuery -Description "Check Constraints" -Query @"
SELECT 
    t.name AS TableName,
    cc.name AS ConstraintName,
    cc.definition AS ConstraintDefinition
FROM sys.check_constraints cc
INNER JOIN sys.tables t ON cc.parent_object_id = t.object_id
WHERE t.schema_id = SCHEMA_ID('portfolio')
ORDER BY t.name, cc.name;
"@

# 9. Trigger Analysis
Execute-SqlQuery -Description "Triggers" -Query @"
SELECT 
    t.name AS TableName,
    tr.name AS TriggerName,
    tr.create_date AS CreatedDate,
    tr.modify_date AS ModifiedDate,
    tr.is_disabled AS IsDisabled,
    CASE tr.type 
        WHEN 'TA' THEN 'Assembly (CLR) trigger'
        WHEN 'TR' THEN 'SQL trigger'
    END AS TriggerType
FROM sys.triggers tr
INNER JOIN sys.tables t ON tr.parent_id = t.object_id
WHERE t.schema_id = SCHEMA_ID('portfolio')
ORDER BY t.name, tr.name;
"@

# 10. Potential Data Redundancies Check
Execute-SqlQuery -Description "Potential Data Redundancies - Duplicate Records Check" -Query @"
-- Check for duplicate users by email
SELECT 'Users - Duplicate Emails' AS Issue, COUNT(*) AS Count
FROM (
    SELECT Email, COUNT(*) as cnt
    FROM portfolio.Users
    GROUP BY Email
    HAVING COUNT(*) > 1
) dup

UNION ALL

-- Check for duplicate asset symbols
SELECT 'Assets - Duplicate Symbols' AS Issue, COUNT(*) AS Count
FROM (
    SELECT Symbol, COUNT(*) as cnt
    FROM portfolio.Assets
    GROUP BY Symbol
    HAVING COUNT(*) > 1
) dup

UNION ALL

-- Check for portfolios with same name for same user
SELECT 'Portfolios - Duplicate Names per User' AS Issue, COUNT(*) AS Count
FROM (
    SELECT UserID, Name, COUNT(*) as cnt
    FROM portfolio.Portfolios
    GROUP BY UserID, Name
    HAVING COUNT(*) > 1
) dup;
"@

# 11. Orphaned Records Check
Execute-SqlQuery -Description "Orphaned Records Check" -Query @"
-- Check for transactions without corresponding portfolios
SELECT 'Transactions without Portfolios' AS Issue, COUNT(*) AS Count
FROM portfolio.Transactions t
LEFT JOIN portfolio.Portfolios p ON t.PortfolioID = p.PortfolioID
WHERE p.PortfolioID IS NULL

UNION ALL

-- Check for transactions without corresponding assets
SELECT 'Transactions without Assets' AS Issue, COUNT(*) AS Count
FROM portfolio.Transactions t
LEFT JOIN portfolio.Assets a ON t.AssetID = a.AssetID
WHERE a.AssetID IS NULL

UNION ALL

-- Check for holdings without corresponding portfolios
SELECT 'Holdings without Portfolios' AS Issue, COUNT(*) AS Count
FROM portfolio.PortfolioHoldings h
LEFT JOIN portfolio.Portfolios p ON h.PortfolioID = p.PortfolioID
WHERE p.PortfolioID IS NULL

UNION ALL

-- Check for holdings without corresponding assets
SELECT 'Holdings without Assets' AS Issue, COUNT(*) AS Count
FROM portfolio.PortfolioHoldings h
LEFT JOIN portfolio.Assets a ON h.AssetID = a.AssetID
WHERE a.AssetID IS NULL;
"@

# 12. Data Consistency Checks
Execute-SqlQuery -Description "Data Consistency Checks" -Query @"
-- Check for negative balances
SELECT 'Users with Negative Account Balance' AS Issue, COUNT(*) AS Count
FROM portfolio.Users
WHERE AccountBalance < 0

UNION ALL

-- Check for negative portfolio funds
SELECT 'Portfolios with Negative Funds' AS Issue, COUNT(*) AS Count
FROM portfolio.Portfolios
WHERE CurrentFunds < 0

UNION ALL

-- Check for zero or negative asset prices
SELECT 'Assets with Invalid Prices' AS Issue, COUNT(*) AS Count
FROM portfolio.Assets
WHERE Price <= 0

UNION ALL

-- Check for holdings with zero quantity
SELECT 'Holdings with Zero Quantity' AS Issue, COUNT(*) AS Count
FROM portfolio.PortfolioHoldings
WHERE QuantityHeld <= 0;
"@

# 13. Performance Analysis - Missing Indexes
Execute-SqlQuery -Description "Tables without Indexes (Potential Performance Issues)" -Query @"
SELECT 
    t.name AS TableName,
    'No non-clustered indexes' AS Issue
FROM sys.tables t
WHERE t.schema_id = SCHEMA_ID('portfolio')
    AND NOT EXISTS (
        SELECT 1 
        FROM sys.indexes i 
        WHERE i.object_id = t.object_id 
            AND i.type = 2  -- Non-clustered index
    )
ORDER BY t.name;
"@

# 14. Schema Dependencies
Execute-SqlQuery -Description "Object Dependencies" -Query @"
SELECT 
    o1.name AS DependentObject,
    o1.type_desc AS DependentType,
    o2.name AS ReferencedObject,
    o2.type_desc AS ReferencedType
FROM sys.sql_dependencies d
INNER JOIN sys.objects o1 ON d.object_id = o1.object_id
INNER JOIN sys.objects o2 ON d.referenced_major_id = o2.object_id
WHERE o1.schema_id = SCHEMA_ID('portfolio') OR o2.schema_id = SCHEMA_ID('portfolio')
ORDER BY o1.name, o2.name;
"@

Write-Host "`n=== DATABASE ANALYSIS COMPLETED ===" -ForegroundColor Green
Write-Host "Review the output above for:" -ForegroundColor Cyan
Write-Host "• Table structure and relationships" -ForegroundColor White
Write-Host "• Data redundancies and inconsistencies" -ForegroundColor White  
Write-Host "• Missing indexes and performance issues" -ForegroundColor White
Write-Host "• Orphaned records" -ForegroundColor White
Write-Host "• Constraint violations" -ForegroundColor White 
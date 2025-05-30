# API and Database Table Usage Analysis
Write-Host "=== API & DATABASE TABLE USAGE ANALYSIS ===" -ForegroundColor Cyan

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

# 1. Check actual data in each table to see usage
Execute-SqlQuery -Description "Table Data Summary (Row Counts)" -Query @"
SELECT 
    'Users' AS TableName,
    COUNT(*) AS RowCount,
    'Core user management' AS Purpose,
    'YES - User CRUD, Auth, Fund Management' AS APIUsage
FROM portfolio.Users

UNION ALL

SELECT 
    'Portfolios' AS TableName,
    COUNT(*) AS RowCount,
    'Portfolio management' AS Purpose,
    'YES - Portfolio CRUD, Trading' AS APIUsage
FROM portfolio.Portfolios

UNION ALL

SELECT 
    'Assets' AS TableName,
    COUNT(*) AS RowCount,
    'Asset information' AS Purpose,
    'YES - Asset listing, Trading' AS APIUsage
FROM portfolio.Assets

UNION ALL

SELECT 
    'Transactions' AS TableName,
    COUNT(*) AS RowCount,
    'Trading transactions' AS Purpose,
    'YES - Buy/Sell operations' AS APIUsage
FROM portfolio.Transactions

UNION ALL

SELECT 
    'PortfolioHoldings' AS TableName,
    COUNT(*) AS RowCount,
    'Current asset holdings' AS Purpose,
    'YES - Holdings summary' AS APIUsage
FROM portfolio.PortfolioHoldings

UNION ALL

SELECT 
    'FundTransactions' AS TableName,
    COUNT(*) AS RowCount,
    'Fund movement audit' AS Purpose,
    'YES - Deposit/Withdraw/Allocate' AS APIUsage
FROM portfolio.FundTransactions

UNION ALL

SELECT 
    'AssetPrices' AS TableName,
    COUNT(*) AS RowCount,
    'Historical price data' AS Purpose,
    'PARTIAL - Price history endpoint' AS APIUsage
FROM portfolio.AssetPrices

UNION ALL

SELECT 
    'CompanyDetails' AS TableName,
    COUNT(*) AS RowCount,
    'Company information' AS Purpose,
    'NO - Missing API endpoints' AS APIUsage
FROM portfolio.CompanyDetails

UNION ALL

SELECT 
    'IndexDetails' AS TableName,
    COUNT(*) AS RowCount,
    'Index information' AS Purpose,
    'NO - Missing API endpoints' AS APIUsage
FROM portfolio.IndexDetails

UNION ALL

SELECT 
    'RiskMetrics' AS TableName,
    COUNT(*) AS RowCount,
    'Risk analysis data' AS Purpose,
    'YES - Risk analysis endpoints' AS APIUsage
FROM portfolio.RiskMetrics

UNION ALL

SELECT 
    'Subscriptions' AS TableName,
    COUNT(*) AS RowCount,
    'Premium subscriptions' AS Purpose,
    'NO - Missing API endpoints' AS APIUsage
FROM portfolio.Subscriptions

UNION ALL

SELECT 
    'PaymentMethods' AS TableName,
    COUNT(*) AS RowCount,
    'User payment methods' AS Purpose,
    'NO - Missing API endpoints' AS APIUsage
FROM portfolio.PaymentMethods

ORDER BY RowCount DESC;
"@

# 2. Check for unused/empty tables
Execute-SqlQuery -Description "Empty or Underutilized Tables" -Query @"
SELECT 
    TableName,
    RowCount,
    CASE 
        WHEN RowCount = 0 THEN 'EMPTY - Consider removing or implementing'
        WHEN RowCount < 5 THEN 'UNDERUTILIZED - Low usage'
        ELSE 'ACTIVE'
    END AS Status,
    Purpose
FROM (
    SELECT 'CompanyDetails' AS TableName, COUNT(*) AS RowCount, 'Company info for stocks' AS Purpose FROM portfolio.CompanyDetails
    UNION ALL
    SELECT 'IndexDetails', COUNT(*), 'Index fund information' FROM portfolio.IndexDetails
    UNION ALL
    SELECT 'Subscriptions', COUNT(*), 'Premium subscription tracking' FROM portfolio.Subscriptions
    UNION ALL
    SELECT 'PaymentMethods', COUNT(*), 'User payment options' FROM portfolio.PaymentMethods
    UNION ALL
    SELECT 'AssetPrices', COUNT(*), 'Historical price data' FROM portfolio.AssetPrices
) t
ORDER BY RowCount;
"@

# 3. Check for missing API functionality based on database structure
Write-Host "`n=== MISSING API FUNCTIONALITY ANALYSIS ===" -ForegroundColor Yellow

$missingEndpoints = @"
MISSING API ENDPOINTS:

🔴 CRITICAL MISSING:
• Payment Methods CRUD (table exists but no API)
• Company Details retrieval (for stock research)
• Index Details retrieval (for index funds)

🟡 MODERATE MISSING:
• Subscription management (Premium upgrade exists but no subscription CRUD)
• Historical price charts (AssetPrices table underutilized)
• Advanced asset filtering (by sector, industry, country)

🟢 NICE TO HAVE:
• Asset price import/update endpoints
• Bulk operations for portfolios
• Advanced reporting endpoints

REDUNDANT/UNUSED FUNCTIONALITY:
• Some stored procedures may not be used
• Views might be over-engineered for current API needs
"@

Write-Host $missingEndpoints

# 4. Check stored procedure usage vs API endpoints
Execute-SqlQuery -Description "Stored Procedures vs API Endpoint Mapping" -Query @"
SELECT 
    ProcedureName,
    CASE ProcedureName
        WHEN 'sp_CreateUser' THEN 'YES - POST /users'
        WHEN 'sp_UpdateUser' THEN 'YES - PUT /users/{id}'
        WHEN 'sp_CreatePortfolio' THEN 'YES - POST /portfolios'
        WHEN 'sp_UpdatePortfolio' THEN 'YES - PUT /portfolios/{id}'
        WHEN 'sp_DepositFunds' THEN 'YES - POST /users/{id}/deposit'
        WHEN 'sp_WithdrawFunds' THEN 'YES - POST /users/{id}/withdraw'
        WHEN 'sp_AllocateFunds' THEN 'YES - POST /users/{id}/allocate'
        WHEN 'sp_DeallocateFunds' THEN 'YES - POST /users/{id}/deallocate'
        WHEN 'sp_UpgradeToPremium' THEN 'YES - POST /users/{id}/upgrade-premium'
        WHEN 'sp_BuyAsset' THEN 'YES - POST /portfolios/buy'
        WHEN 'sp_SellAsset' THEN 'YES - POST /portfolios/sell'
        WHEN 'sp_GetPortfolioBalance' THEN 'YES - GET /portfolios/{id}/balance'
        WHEN 'sp_GetUserAccountSummary' THEN 'YES - GET /users/{id}/account-summary'
        WHEN 'sp_UpdateAssetPrice' THEN 'NO - Missing price update API'
        WHEN 'sp_import_asset_price' THEN 'NO - Missing price import API'
        WHEN 'sp_ensure_asset' THEN 'NO - Internal procedure only'
        ELSE 'UNKNOWN'
    END AS APIMapping,
    ParameterCount
FROM (
    SELECT 
        p.name AS ProcedureName,
        ISNULL(para.parameter_count, 0) AS ParameterCount
    FROM sys.procedures p
    INNER JOIN sys.schemas s ON p.schema_id = s.schema_id
    LEFT JOIN (
        SELECT object_id, COUNT(*) AS parameter_count
        FROM sys.parameters
        WHERE parameter_id > 0
        GROUP BY object_id
    ) para ON p.object_id = para.object_id
    WHERE s.name = 'portfolio'
) sp
ORDER BY 
    CASE WHEN APIMapping LIKE 'YES%' THEN 1 
         WHEN APIMapping LIKE 'NO%' THEN 2 
         ELSE 3 END,
    ProcedureName;
"@

# 5. Check views usage
Execute-SqlQuery -Description "Database Views vs API Usage" -Query @"
SELECT 
    ViewName,
    CASE ViewName
        WHEN 'vw_PortfolioSummary' THEN 'YES - GET /portfolios/{id}/summary'
        WHEN 'vw_AssetHoldings' THEN 'YES - GET /portfolios/{id}/holdings'
        WHEN 'vw_RiskAnalysis' THEN 'YES - Risk analysis endpoints'
        WHEN 'vw_AssetPriceHistory' THEN 'PARTIAL - GET /assets/{id}/price-history'
        ELSE 'NO - Unused view'
    END AS APIUsage,
    'Consider implementing missing endpoints' AS Recommendation
FROM sys.views v
INNER JOIN sys.schemas s ON v.schema_id = s.schema_id
WHERE s.name = 'portfolio'
ORDER BY ViewName;
"@

# 6. Business Logic Recommendations
Write-Host "`n=== BUSINESS LOGIC RECOMMENDATIONS ===" -ForegroundColor Cyan

$recommendations = @"
PRIORITY RECOMMENDATIONS:

🔴 HIGH PRIORITY - Implement Missing Core Features:
1. Payment Methods API (table exists, no endpoints)
   - GET /users/{id}/payment-methods
   - POST /users/{id}/payment-methods
   - PUT /users/{id}/payment-methods/{id}
   - DELETE /users/{id}/payment-methods/{id}

2. Company/Index Details API (for asset research)
   - GET /assets/{id}/company-details
   - GET /assets/{id}/index-details
   - GET /assets/companies (list with filters)
   - GET /assets/indices (list with filters)

🟡 MEDIUM PRIORITY - Enhance Existing Features:
1. Subscription Management API
   - GET /users/{id}/subscription
   - PUT /users/{id}/subscription (modify/extend)
   - DELETE /users/{id}/subscription (cancel)

2. Enhanced Asset Price Management
   - POST /assets/{id}/prices (admin only)
   - GET /assets/{id}/price-history (already exists)

🟢 LOW PRIORITY - Consider Removing Unused:
1. Review if all stored procedures are needed
2. Consider consolidating similar views
3. Evaluate if all columns in tables are used

REDUNDANCY ANALYSIS:
• FundTransactions + Transactions: Both track different types - KEEP BOTH
• CompanyDetails + IndexDetails: Different asset types - KEEP BOTH
• Multiple price-related tables: Serve different purposes - KEEP ALL
"@

Write-Host $recommendations

Write-Host "`n=== ANALYSIS COMPLETED ===" -ForegroundColor Green
Write-Host "Summary: Some tables are underutilized but architecture is sound." -ForegroundColor Cyan 
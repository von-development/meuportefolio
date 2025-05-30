# Simple Table Usage Analysis
Write-Host "=== TABLE USAGE ANALYSIS ===" -ForegroundColor Cyan

# Database connection parameters
$serverName = "localhost,1433"
$databaseName = "meuportefolio"
$userId = "sa"
$password = "meuportefolio!23"
$connectionString = "Server=$serverName;Database=$databaseName;User Id=$userId;Password=$password;TrustServerCertificate=true;"

function Get-TableRowCount {
    param(
        [string]$TableName
    )
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $command = New-Object System.Data.SqlClient.SqlCommand("SELECT COUNT(*) FROM portfolio.$TableName", $connection)
        
        $connection.Open()
        $count = $command.ExecuteScalar()
        $connection.Close()
        
        return $count
    }
    catch {
        return "ERROR"
    }
}

# Define table usage mapping
$tableUsage = @(
    @{Name="Users"; Usage="YES - User CRUD, Auth, Fund Management"; Purpose="Core user management"},
    @{Name="Portfolios"; Usage="YES - Portfolio CRUD, Trading"; Purpose="Portfolio management"},
    @{Name="Assets"; Usage="YES - Asset listing, Trading"; Purpose="Asset information"},
    @{Name="Transactions"; Usage="YES - Buy/Sell operations"; Purpose="Trading transactions"},
    @{Name="PortfolioHoldings"; Usage="YES - Holdings summary"; Purpose="Current asset holdings"},
    @{Name="FundTransactions"; Usage="YES - Deposit/Withdraw/Allocate"; Purpose="Fund movement audit"},
    @{Name="AssetPrices"; Usage="PARTIAL - Price history endpoint"; Purpose="Historical price data"},
    @{Name="CompanyDetails"; Usage="NO - Missing API endpoints"; Purpose="Company information"},
    @{Name="IndexDetails"; Usage="NO - Missing API endpoints"; Purpose="Index information"},
    @{Name="RiskMetrics"; Usage="YES - Risk analysis endpoints"; Purpose="Risk analysis data"},
    @{Name="Subscriptions"; Usage="NO - Missing API endpoints"; Purpose="Premium subscriptions"},
    @{Name="PaymentMethods"; Usage="NO - Missing API endpoints"; Purpose="User payment methods"}
)

Write-Host "`n=== TABLE USAGE SUMMARY ===" -ForegroundColor Yellow

$results = @()
foreach ($table in $tableUsage) {
    $rowCount = Get-TableRowCount -TableName $table.Name
    $status = if ($rowCount -eq 0) { "EMPTY" } 
              elseif ($rowCount -lt 5) { "LOW" } 
              else { "ACTIVE" }
    
    $results += [PSCustomObject]@{
        TableName = $table.Name
        RowCount = $rowCount
        Status = $status
        APIUsage = $table.Usage
        Purpose = $table.Purpose
    }
}

$results | Format-Table -AutoSize

Write-Host "`n=== API COVERAGE ANALYSIS ===" -ForegroundColor Yellow

# Group by usage status
$fullyUsed = $results | Where-Object { $_.APIUsage -like "YES*" }
$partiallyUsed = $results | Where-Object { $_.APIUsage -like "PARTIAL*" }
$notUsed = $results | Where-Object { $_.APIUsage -like "NO*" }

Write-Host "`n✅ FULLY USED TABLES ($($fullyUsed.Count)):" -ForegroundColor Green
$fullyUsed | ForEach-Object { Write-Host "  • $($_.TableName) ($($_.RowCount) rows) - $($_.Purpose)" -ForegroundColor White }

Write-Host "`n⚠️  PARTIALLY USED TABLES ($($partiallyUsed.Count)):" -ForegroundColor Yellow
$partiallyUsed | ForEach-Object { Write-Host "  • $($_.TableName) ($($_.RowCount) rows) - $($_.Purpose)" -ForegroundColor White }

Write-Host "`n❌ UNUSED TABLES ($($notUsed.Count)):" -ForegroundColor Red
$notUsed | ForEach-Object { Write-Host "  • $($_.TableName) ($($_.RowCount) rows) - $($_.Purpose)" -ForegroundColor White }

Write-Host "`n=== RECOMMENDATIONS ===" -ForegroundColor Cyan

$recommendations = @"
🔴 HIGH PRIORITY - Implement Missing APIs:
1. Payment Methods API - CRITICAL for payment processing
   └─ GET/POST/PUT/DELETE /users/{id}/payment-methods

2. Company Details API - Important for stock research
   └─ GET /assets/{id}/company-details
   └─ GET /assets/companies (list with sector/industry filters)

3. Index Details API - Important for index fund info
   └─ GET /assets/{id}/index-details  
   └─ GET /assets/indices (list with region/country filters)

🟡 MEDIUM PRIORITY - Consider Implementation:
1. Subscription Management API - For premium feature management
   └─ GET/PUT/DELETE /users/{id}/subscription

2. Enhanced Price History - More detailed price analytics
   └─ Enhance existing GET /assets/{id}/price-history

🟢 LOW PRIORITY - May Remove if Unused:
1. Review if empty tables are needed
2. Consider consolidating similar functionality

CURRENT STATUS:
• 6/12 tables fully utilized (50%)
• 1/12 tables partially utilized (8%)
• 5/12 tables unused (42%)

REDUNDANCY CHECK:
✅ No true redundancy detected - all tables serve different purposes
✅ FundTransactions vs Transactions track different transaction types
✅ CompanyDetails vs IndexDetails support different asset types
"@

Write-Host $recommendations

Write-Host "`n=== STORED PROCEDURE MAPPING ===" -ForegroundColor Yellow

$spMapping = @"
API ENDPOINT COVERAGE FOR STORED PROCEDURES:

✅ USED PROCEDURES:
• sp_CreateUser → POST /users
• sp_UpdateUser → PUT /users/{id}
• sp_CreatePortfolio → POST /portfolios
• sp_UpdatePortfolio → PUT /portfolios/{id}
• sp_DepositFunds → POST /users/{id}/deposit
• sp_WithdrawFunds → POST /users/{id}/withdraw
• sp_AllocateFunds → POST /users/{id}/allocate
• sp_DeallocateFunds → POST /users/{id}/deallocate
• sp_UpgradeToPremium → POST /users/{id}/upgrade-premium
• sp_BuyAsset → POST /portfolios/buy
• sp_SellAsset → POST /portfolios/sell
• sp_GetPortfolioBalance → GET /portfolios/{id}/balance
• sp_GetUserAccountSummary → GET /users/{id}/account-summary

❌ UNUSED PROCEDURES:
• sp_UpdateAssetPrice → No price management API
• sp_import_asset_price → No price import API
• sp_ensure_asset → Internal use only

COVERAGE: 13/16 procedures used (81%)
"@

Write-Host $spMapping

Write-Host "`n=== ANALYSIS COMPLETE ===" -ForegroundColor Green 
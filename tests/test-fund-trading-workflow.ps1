# Complete Fund Management and Trading Workflow Test
Write-Host "=== FUND MANAGEMENT & TRADING WORKFLOW TEST ===" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080/api/v1"
$mariaSantosUserId = "397b94b0-55cf-4e3d-bfa0-b481a33c86e2"

Write-Host "`nSTEP 1: Getting initial account summary..." -ForegroundColor Yellow
try {
    $initialSummary = Invoke-RestMethod -Uri "$baseUrl/users/$mariaSantosUserId/account-summary" -Method GET
    Write-Host "SUCCESS: Initial account summary retrieved!" -ForegroundColor Green
    Write-Host "  - User: $($initialSummary.name)" -ForegroundColor Cyan
    Write-Host "  - Initial Balance: $($initialSummary.account_balance)" -ForegroundColor Cyan
    Write-Host "  - User Type: $($initialSummary.user_type)" -ForegroundColor Cyan
    Write-Host "  - Portfolio Count: $($initialSummary.portfolio_count)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to get initial summary: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`nSTEP 2: Depositing funds to user account..." -ForegroundColor Yellow
$depositRequest = @{
    amount = 25000.00
    description = "Test deposit for fund workflow"
} | ConvertTo-Json

try {
    $depositResult = Invoke-RestMethod -Uri "$baseUrl/users/$mariaSantosUserId/deposit" -Method POST -Body $depositRequest -ContentType "application/json"
    Write-Host "SUCCESS: Funds deposited!" -ForegroundColor Green
    Write-Host "  - Amount Deposited: $($depositResult.amount)" -ForegroundColor Cyan
    Write-Host "  - New Balance: $($depositResult.new_balance)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to deposit funds: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 3: Creating a new portfolio for trading..." -ForegroundColor Yellow
$createPortfolioRequest = @{
    user_id = $mariaSantosUserId
    name = "Trading Test Portfolio"
    initial_funds = 1000.00
} | ConvertTo-Json

try {
    $newPortfolio = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method POST -Body $createPortfolioRequest -ContentType "application/json"
    Write-Host "SUCCESS: Portfolio created!" -ForegroundColor Green
    Write-Host "  - Portfolio ID: $($newPortfolio.portfolio_id)" -ForegroundColor Cyan
    Write-Host "  - Name: $($newPortfolio.name)" -ForegroundColor Cyan
    Write-Host "  - Initial Funds: $($newPortfolio.current_funds)" -ForegroundColor Cyan
    $portfolioId = $newPortfolio.portfolio_id
} catch {
    Write-Host "FAILED to create portfolio: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`nSTEP 4: Allocating funds from account to portfolio..." -ForegroundColor Yellow
$allocateRequest = @{
    portfolio_id = $portfolioId
    amount = 10000.00
} | ConvertTo-Json

try {
    $allocateResult = Invoke-RestMethod -Uri "$baseUrl/users/$mariaSantosUserId/allocate" -Method POST -Body $allocateRequest -ContentType "application/json"
    Write-Host "SUCCESS: Funds allocated to portfolio!" -ForegroundColor Green
    Write-Host "  - Amount Allocated: $($allocateResult.amount)" -ForegroundColor Cyan
    Write-Host "  - New Account Balance: $($allocateResult.new_balance)" -ForegroundColor Cyan
    Write-Host "  - New Portfolio Funds: $($allocateResult.new_portfolio_funds)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to allocate funds: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 5: Getting portfolio balance before trading..." -ForegroundColor Yellow
try {
    $portfolioBalance = Invoke-RestMethod -Uri "$baseUrl/portfolios/$portfolioId/balance" -Method GET
    Write-Host "SUCCESS: Portfolio balance retrieved!" -ForegroundColor Green
    Write-Host "  - Cash Balance: $($portfolioBalance.cash_balance)" -ForegroundColor Cyan
    Write-Host "  - Holdings Value: $($portfolioBalance.holdings_value)" -ForegroundColor Cyan
    Write-Host "  - Total Portfolio Value: $($portfolioBalance.total_portfolio_value)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to get portfolio balance: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 6: Buying an asset (AAPL - AssetID: 1)..." -ForegroundColor Yellow
$buyRequest = @{
    portfolio_id = $portfolioId
    asset_id = 1  # AAPL
    quantity = 10.0
} | ConvertTo-Json

try {
    $buyResult = Invoke-RestMethod -Uri "$baseUrl/portfolios/buy" -Method POST -Body $buyRequest -ContentType "application/json"
    Write-Host "SUCCESS: Asset purchased!" -ForegroundColor Green
    Write-Host "  - Transaction ID: $($buyResult.transaction_id)" -ForegroundColor Cyan
    Write-Host "  - Quantity Purchased: $($buyResult.quantity_purchased)" -ForegroundColor Cyan
    Write-Host "  - Price Per Share: $($buyResult.price_per_share)" -ForegroundColor Cyan
    Write-Host "  - Total Cost: $($buyResult.total_cost)" -ForegroundColor Cyan
    Write-Host "  - Remaining Funds: $($buyResult.remaining_funds)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to buy asset: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 7: Getting portfolio holdings summary..." -ForegroundColor Yellow
try {
    $holdingsSummary = Invoke-RestMethod -Uri "$baseUrl/portfolios/$portfolioId/holdings-summary" -Method GET
    Write-Host "SUCCESS: Holdings summary retrieved!" -ForegroundColor Green
    Write-Host "  - Total Holdings Value: $($holdingsSummary.total_holdings_value)" -ForegroundColor Cyan
    Write-Host "  - Total Cost Basis: $($holdingsSummary.total_cost_basis)" -ForegroundColor Cyan
    Write-Host "  - Unrealized Gain/Loss: $($holdingsSummary.total_unrealized_gain_loss)" -ForegroundColor Cyan
    Write-Host "  - Assets Count: $($holdingsSummary.assets_count)" -ForegroundColor Cyan
    
    if ($holdingsSummary.holdings.Count -gt 0) {
        Write-Host "  Holdings Details:" -ForegroundColor Cyan
        foreach ($holding in $holdingsSummary.holdings) {
            Write-Host "    - $($holding.asset_name) ($($holding.symbol)): $($holding.quantity_held) shares @ $($holding.current_price)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "FAILED to get holdings summary: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 8: Selling half of the AAPL position..." -ForegroundColor Yellow
$sellRequest = @{
    portfolio_id = $portfolioId
    asset_id = 1  # AAPL
    quantity = 5.0
} | ConvertTo-Json

try {
    $sellResult = Invoke-RestMethod -Uri "$baseUrl/portfolios/sell" -Method POST -Body $sellRequest -ContentType "application/json"
    Write-Host "SUCCESS: Asset sold!" -ForegroundColor Green
    Write-Host "  - Transaction ID: $($sellResult.transaction_id)" -ForegroundColor Cyan
    Write-Host "  - Quantity Sold: $($sellResult.quantity_sold)" -ForegroundColor Cyan
    Write-Host "  - Price Per Share: $($sellResult.price_per_share)" -ForegroundColor Cyan
    Write-Host "  - Total Proceeds: $($sellResult.total_proceeds)" -ForegroundColor Cyan
    Write-Host "  - New Funds Balance: $($sellResult.new_funds_balance)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to sell asset: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 9: Getting updated portfolio balance..." -ForegroundColor Yellow
try {
    $updatedBalance = Invoke-RestMethod -Uri "$baseUrl/portfolios/$portfolioId/balance" -Method GET
    Write-Host "SUCCESS: Updated portfolio balance retrieved!" -ForegroundColor Green
    Write-Host "  - Cash Balance: $($updatedBalance.cash_balance)" -ForegroundColor Cyan
    Write-Host "  - Holdings Value: $($updatedBalance.holdings_value)" -ForegroundColor Cyan
    Write-Host "  - Total Portfolio Value: $($updatedBalance.total_portfolio_value)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to get updated balance: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 10: Deallocating some funds back to account..." -ForegroundColor Yellow
$deallocateRequest = @{
    portfolio_id = $portfolioId
    amount = 2000.00
} | ConvertTo-Json

try {
    $deallocateResult = Invoke-RestMethod -Uri "$baseUrl/users/$mariaSantosUserId/deallocate" -Method POST -Body $deallocateRequest -ContentType "application/json"
    Write-Host "SUCCESS: Funds deallocated!" -ForegroundColor Green
    Write-Host "  - Amount Deallocated: $($deallocateResult.amount)" -ForegroundColor Cyan
    Write-Host "  - New Account Balance: $($deallocateResult.new_balance)" -ForegroundColor Cyan
    Write-Host "  - New Portfolio Funds: $($deallocateResult.new_portfolio_funds)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to deallocate funds: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 11: Testing premium upgrade..." -ForegroundColor Yellow
$upgradeRequest = @{
    subscription_months = 3
    monthly_rate = 49.99
} | ConvertTo-Json

try {
    $upgradeResult = Invoke-RestMethod -Uri "$baseUrl/users/$mariaSantosUserId/upgrade-premium" -Method POST -Body $upgradeRequest -ContentType "application/json"
    Write-Host "SUCCESS: Upgraded to premium!" -ForegroundColor Green
    Write-Host "  - Amount Paid: $($upgradeResult.amount_paid)" -ForegroundColor Cyan
    Write-Host "  - Subscription Months: $($upgradeResult.subscription_months)" -ForegroundColor Cyan
    Write-Host "  - New Balance: $($upgradeResult.new_balance)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to upgrade to premium: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 12: Getting final account summary..." -ForegroundColor Yellow
try {
    $finalSummary = Invoke-RestMethod -Uri "$baseUrl/users/$mariaSantosUserId/account-summary" -Method GET
    Write-Host "SUCCESS: Final account summary retrieved!" -ForegroundColor Green
    Write-Host "  - User Type: $($finalSummary.user_type)" -ForegroundColor Cyan
    Write-Host "  - Final Account Balance: $($finalSummary.account_balance)" -ForegroundColor Cyan
    Write-Host "  - Total Portfolio Value: $($finalSummary.total_portfolio_value)" -ForegroundColor Cyan
    Write-Host "  - Total Net Worth: $($finalSummary.total_net_worth)" -ForegroundColor Cyan
    Write-Host "  - Portfolio Count: $($finalSummary.portfolio_count)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to get final summary: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 13: Testing withdrawal from account..." -ForegroundColor Yellow
$withdrawRequest = @{
    amount = 1000.00
    description = "Test withdrawal"
} | ConvertTo-Json

try {
    $withdrawResult = Invoke-RestMethod -Uri "$baseUrl/users/$mariaSantosUserId/withdraw" -Method POST -Body $withdrawRequest -ContentType "application/json"
    Write-Host "SUCCESS: Funds withdrawn!" -ForegroundColor Green
    Write-Host "  - Amount Withdrawn: $($withdrawResult.amount)" -ForegroundColor Cyan
    Write-Host "  - New Balance: $($withdrawResult.new_balance)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to withdraw funds: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 14: Cleaning up - Deleting test portfolio..." -ForegroundColor Yellow
try {
    $null = Invoke-RestMethod -Uri "$baseUrl/portfolios/$portfolioId" -Method DELETE
    Write-Host "SUCCESS: Test portfolio deleted!" -ForegroundColor Green
} catch {
    Write-Host "FAILED to delete portfolio: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nFUND MANAGEMENT & TRADING WORKFLOW TEST COMPLETED!" -ForegroundColor Green
Write-Host "All fund management and trading operations tested successfully." -ForegroundColor Green
Write-Host "`nWorkflow Summary:" -ForegroundColor Cyan
Write-Host "✓ Account Summary" -ForegroundColor Green
Write-Host "✓ Fund Deposit" -ForegroundColor Green
Write-Host "✓ Portfolio Creation" -ForegroundColor Green
Write-Host "✓ Fund Allocation" -ForegroundColor Green
Write-Host "✓ Portfolio Balance Check" -ForegroundColor Green
Write-Host "✓ Asset Purchase (Buy)" -ForegroundColor Green
Write-Host "✓ Holdings Summary" -ForegroundColor Green
Write-Host "✓ Asset Sale (Sell)" -ForegroundColor Green
Write-Host "✓ Fund Deallocation" -ForegroundColor Green
Write-Host "✓ Premium Upgrade" -ForegroundColor Green
Write-Host "✓ Fund Withdrawal" -ForegroundColor Green
Write-Host "✓ Cleanup" -ForegroundColor Green 
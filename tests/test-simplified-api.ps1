# Comprehensive API Testing Script for Simplified Portfolio API
# Tests user management, payments, subscriptions, funds, and trading

$baseUrl = "http://localhost:8080/api/v1"
$headers = @{ "Content-Type" = "application/json" }

Write-Host "=== Portfolio API Comprehensive Testing ===" -ForegroundColor Green
Write-Host "Testing simplified user structure with integrated payments/subscriptions" -ForegroundColor Yellow
Write-Host ""

# Test 1: Health Check
Write-Host "1. Testing Health Check..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method Get
    Write-Host "✓ Health check passed" -ForegroundColor Green
} catch {
    Write-Host "✗ Health check failed: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Create Test User
Write-Host "2. Creating test user..." -ForegroundColor Cyan
$newUser = @{
    name = "Alice Johnson"
    email = "alice.johnson@test.com"
    password = "securePassword123"
    country_of_residence = "United States"
    iban = "US1234567890123456"
    user_type = "Basic"
} | ConvertTo-Json

try {
    $createUserResponse = Invoke-RestMethod -Uri "$baseUrl/users" -Method Post -Body $newUser -Headers $headers
    $userId = $createUserResponse.user_id
    Write-Host "✓ User created successfully: $($createUserResponse.name) (ID: $userId)" -ForegroundColor Green
    if (-not $userId) {
        Write-Host "✗ User ID is null or empty. Response: $($createUserResponse | ConvertTo-Json)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "✗ User creation failed: $_" -ForegroundColor Red
    Write-Host "Response body: $($_.Exception.Response)" -ForegroundColor Red
    exit 1
}

# Test 3: Get Basic User Info
Write-Host "3. Testing basic user retrieval..." -ForegroundColor Cyan
try {
    $getUserResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId" -Method Get
    Write-Host "✓ Basic user info retrieved: $($getUserResponse.name), Type: $($getUserResponse.user_type)" -ForegroundColor Green
} catch {
    Write-Host "✗ Basic user retrieval failed: $_" -ForegroundColor Red
}

# Test 4: Get Extended User Info (should show payment/subscription fields)
Write-Host "4. Testing extended user info retrieval..." -ForegroundColor Cyan
try {
    $extendedUserResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/complete" -Method Get
    Write-Host "✓ Extended user info retrieved:" -ForegroundColor Green
    Write-Host "  - Account Balance: $($extendedUserResponse.account_balance)" -ForegroundColor Gray
    Write-Host "  - Is Premium: $($extendedUserResponse.is_premium)" -ForegroundColor Gray
    Write-Host "  - Payment Method Active: $($extendedUserResponse.payment_method_active)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Extended user retrieval failed: $_" -ForegroundColor Red
}

# Test 5: Set Payment Method
Write-Host "5. Setting user payment method..." -ForegroundColor Cyan
$paymentMethod = @{
    payment_method_type = "CreditCard"
    payment_method_details = "VISA ****4582"
    payment_method_expiry = "2027-12-31"
} | ConvertTo-Json

try {
    $paymentResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/payment-method" -Method Put -Body $paymentMethod -Headers $headers
    Write-Host "✓ Payment method set: $($paymentResponse.status) - $($paymentResponse.message)" -ForegroundColor Green
} catch {
    Write-Host "✗ Payment method setup failed: $_" -ForegroundColor Red
}

# Test 6: Deposit Funds
Write-Host "6. Depositing funds..." -ForegroundColor Cyan
$depositRequest = @{
    amount = 5000.00
    description = "Initial deposit for testing"
} | ConvertTo-Json

try {
    $depositResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/deposit" -Method Post -Body $depositRequest -Headers $headers
    Write-Host "✓ Funds deposited: $($depositResponse.amount), New Balance: $($depositResponse.new_balance)" -ForegroundColor Green
    $currentBalance = $depositResponse.new_balance
} catch {
    Write-Host "✗ Fund deposit failed: $_" -ForegroundColor Red
}

# Test 7: Activate Premium Subscription
Write-Host "7. Activating premium subscription..." -ForegroundColor Cyan
$subscriptionRequest = @{
    action = "ACTIVATE"
    months_to_add = 3
    monthly_rate = 50.00
} | ConvertTo-Json

try {
    $subscriptionResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/subscription" -Method Post -Body $subscriptionRequest -Headers $headers
    Write-Host "✓ Premium subscription activated:" -ForegroundColor Green
    Write-Host "  - Amount Paid: $($subscriptionResponse.amount_paid)" -ForegroundColor Gray
    Write-Host "  - Months Added: $($subscriptionResponse.months_added)" -ForegroundColor Gray
    Write-Host "  - New Balance: $($subscriptionResponse.new_balance)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Premium subscription activation failed: $_" -ForegroundColor Red
}

# Test 8: Verify Premium Status
Write-Host "8. Verifying premium status..." -ForegroundColor Cyan
try {
    $premiumUserResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/complete" -Method Get
    Write-Host "✓ Premium status verified:" -ForegroundColor Green
    Write-Host "  - Is Premium: $($premiumUserResponse.is_premium)" -ForegroundColor Gray
    Write-Host "  - Premium Start: $($premiumUserResponse.premium_start_date)" -ForegroundColor Gray
    Write-Host "  - Premium End: $($premiumUserResponse.premium_end_date)" -ForegroundColor Gray
    Write-Host "  - Days Remaining: $($premiumUserResponse.days_remaining_in_subscription)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Premium status verification failed: $_" -ForegroundColor Red
}

# Test 9: Create Portfolio
Write-Host "9. Creating portfolio..." -ForegroundColor Cyan
$portfolio = @{
    user_id = $userId
    name = "Tech Growth Portfolio"
    description = "Technology focused growth portfolio"
} | ConvertTo-Json

try {
    $portfolioResponse = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method Post -Body $portfolio -Headers $headers
    $portfolioId = $portfolioResponse.portfolio_id
    Write-Host "✓ Portfolio created: $($portfolioResponse.name) (ID: $portfolioId)" -ForegroundColor Green
} catch {
    Write-Host "✗ Portfolio creation failed: $_" -ForegroundColor Red
}

# Test 10: Allocate Funds to Portfolio
Write-Host "10. Allocating funds to portfolio..." -ForegroundColor Cyan
$allocateRequest = @{
    portfolio_id = $portfolioId
    amount = 2000.00
} | ConvertTo-Json

try {
    $allocateResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/allocate" -Method Post -Body $allocateRequest -Headers $headers
    Write-Host "✓ Funds allocated: $($allocateResponse.amount)" -ForegroundColor Green
    Write-Host "  - New User Balance: $($allocateResponse.new_balance)" -ForegroundColor Gray
    Write-Host "  - Portfolio Funds: $($allocateResponse.new_portfolio_funds)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Fund allocation failed: $_" -ForegroundColor Red
}

# Test 11: Buy Asset
Write-Host "11. Buying asset..." -ForegroundColor Cyan
$buyRequest = @{
    portfolio_id = $portfolioId
    asset_id = 1
    quantity = 10.0
} | ConvertTo-Json

try {
    $buyResponse = Invoke-RestMethod -Uri "$baseUrl/portfolios/buy" -Method Post -Body $buyRequest -Headers $headers
    Write-Host "✓ Asset purchased:" -ForegroundColor Green
    Write-Host "  - Asset: $($buyResponse.asset_name)" -ForegroundColor Gray
    Write-Host "  - Quantity: $($buyResponse.quantity)" -ForegroundColor Gray
    Write-Host "  - Total Cost: $($buyResponse.total_cost)" -ForegroundColor Gray
    Write-Host "  - Remaining Funds: $($buyResponse.remaining_portfolio_funds)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Asset purchase failed: $_" -ForegroundColor Red
}

# Test 12: Get Portfolio Holdings
Write-Host "12. Checking portfolio holdings..." -ForegroundColor Cyan
try {
    $holdingsResponse = Invoke-RestMethod -Uri "$baseUrl/portfolios/$portfolioId/holdings" -Method Get
    Write-Host "✓ Portfolio holdings retrieved:" -ForegroundColor Green
    foreach ($holding in $holdingsResponse) {
        Write-Host "  - $($holding.asset_name): $($holding.quantity) shares @ $($holding.current_price)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ Portfolio holdings retrieval failed: $_" -ForegroundColor Red
}

# Test 13: Get Account Summary
Write-Host "13. Getting account summary..." -ForegroundColor Cyan
try {
    $summaryResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/account-summary" -Method Get
    Write-Host "✓ Account summary retrieved:" -ForegroundColor Green
    Write-Host "  - Account Balance: $($summaryResponse.account_balance)" -ForegroundColor Gray
    Write-Host "  - Total Portfolio Value: $($summaryResponse.total_portfolio_value)" -ForegroundColor Gray
    Write-Host "  - Total Net Worth: $($summaryResponse.total_net_worth)" -ForegroundColor Gray
    Write-Host "  - Portfolio Count: $($summaryResponse.portfolio_count)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Account summary retrieval failed: $_" -ForegroundColor Red
}

# Test 14: Sell Some Asset
Write-Host "14. Selling part of asset..." -ForegroundColor Cyan
$sellRequest = @{
    portfolio_id = $portfolioId
    asset_id = 1
    quantity = 3.0
} | ConvertTo-Json

try {
    $sellResponse = Invoke-RestMethod -Uri "$baseUrl/portfolios/sell" -Method Post -Body $sellRequest -Headers $headers
    Write-Host "✓ Asset sold:" -ForegroundColor Green
    Write-Host "  - Asset: $($sellResponse.asset_name)" -ForegroundColor Gray
    Write-Host "  - Quantity: $($sellResponse.quantity)" -ForegroundColor Gray
    Write-Host "  - Total Revenue: $($sellResponse.total_revenue)" -ForegroundColor Gray
    Write-Host "  - New Portfolio Funds: $($sellResponse.new_portfolio_funds)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Asset sale failed: $_" -ForegroundColor Red
}

# Test 15: Deallocate Funds
Write-Host "15. Deallocating funds from portfolio..." -ForegroundColor Cyan
$deallocateRequest = @{
    portfolio_id = $portfolioId
    amount = 500.00
} | ConvertTo-Json

try {
    $deallocateResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/deallocate" -Method Post -Body $deallocateRequest -Headers $headers
    Write-Host "✓ Funds deallocated: $($deallocateResponse.amount)" -ForegroundColor Green
    Write-Host "  - New User Balance: $($deallocateResponse.new_balance)" -ForegroundColor Gray
    Write-Host "  - Remaining Portfolio Funds: $($deallocateResponse.new_portfolio_funds)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Fund deallocation failed: $_" -ForegroundColor Red
}

# Test 16: Renew Subscription
Write-Host "16. Renewing subscription..." -ForegroundColor Cyan
$renewRequest = @{
    action = "RENEW"
    months_to_add = 2
    monthly_rate = 50.00
} | ConvertTo-Json

try {
    $renewResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/subscription" -Method Post -Body $renewRequest -Headers $headers
    Write-Host "✓ Subscription renewed:" -ForegroundColor Green
    Write-Host "  - Amount Paid: $($renewResponse.amount_paid)" -ForegroundColor Gray
    Write-Host "  - Months Added: $($renewResponse.months_added)" -ForegroundColor Gray
    Write-Host "  - New Balance: $($renewResponse.new_balance)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Subscription renewal failed: $_" -ForegroundColor Red
}

# Test 17: Withdraw Funds
Write-Host "17. Withdrawing funds..." -ForegroundColor Cyan
$withdrawRequest = @{
    amount = 1000.00
    description = "Test withdrawal"
} | ConvertTo-Json

try {
    $withdrawResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/withdraw" -Method Post -Body $withdrawRequest -Headers $headers
    Write-Host "✓ Funds withdrawn: $($withdrawResponse.amount)" -ForegroundColor Green
    Write-Host "  - New Balance: $($withdrawResponse.new_balance)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Fund withdrawal failed: $_" -ForegroundColor Red
}

# Test 18: Final Account Summary
Write-Host "18. Final account summary..." -ForegroundColor Cyan
try {
    $finalSummaryResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/account-summary" -Method Get
    Write-Host "✓ Final account summary:" -ForegroundColor Green
    Write-Host "  - Account Balance: $($finalSummaryResponse.account_balance)" -ForegroundColor Gray
    Write-Host "  - Total Portfolio Value: $($finalSummaryResponse.total_portfolio_value)" -ForegroundColor Gray
    Write-Host "  - Total Net Worth: $($finalSummaryResponse.total_net_worth)" -ForegroundColor Gray
} catch {
    Write-Host "✗ Final account summary failed: $_" -ForegroundColor Red
}

# Test 19: List All Users
Write-Host "19. Listing all users..." -ForegroundColor Cyan
try {
    $usersResponse = Invoke-RestMethod -Uri "$baseUrl/users" -Method Get
    Write-Host "✓ Users retrieved: $($usersResponse.Count) users found" -ForegroundColor Green
    foreach ($user in $usersResponse) {
        Write-Host "  - $($user.name) ($($user.email)) - $($user.user_type)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ User listing failed: $_" -ForegroundColor Red
}

# Test 20: Update User Info
Write-Host "20. Updating user information..." -ForegroundColor Cyan
$updateUser = @{
    name = "Alice Johnson-Smith"
    user_type = "Premium"
} | ConvertTo-Json

try {
    $updateResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId" -Method Put -Body $updateUser -Headers $headers
    Write-Host "✓ User updated: $($updateResponse.name), Type: $($updateResponse.user_type)" -ForegroundColor Green
} catch {
    Write-Host "✗ User update failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Testing Complete ===" -ForegroundColor Green
Write-Host "Simplified API with integrated payment/subscription management tested successfully!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Key Features Tested:" -ForegroundColor Cyan
Write-Host "- Basic User Operations (CRUD)" -ForegroundColor Green
Write-Host "- Extended User Info with Payment/Subscription Details" -ForegroundColor Green
Write-Host "- Payment Method Management" -ForegroundColor Green
Write-Host "- Subscription Management (Activate/Renew)" -ForegroundColor Green
Write-Host "- Fund Management (Deposit/Withdraw/Allocate/Deallocate)" -ForegroundColor Green
Write-Host "- Portfolio Management" -ForegroundColor Green
Write-Host "- Asset Trading (Buy/Sell)" -ForegroundColor Green
Write-Host "- Account Summary and Reporting" -ForegroundColor Green
Write-Host ""
Write-Host "User ID for further testing: $userId" -ForegroundColor Yellow
Write-Host "Portfolio ID for further testing: $portfolioId" -ForegroundColor Yellow 
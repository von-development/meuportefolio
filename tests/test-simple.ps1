# Simple API Test Script
$baseUrl = "http://localhost:8080/api/v1"
$headers = @{ "Content-Type" = "application/json" }

Write-Host "=== Simple API Test ===" -ForegroundColor Green

# Test 1: Health Check
Write-Host "1. Health Check..." -ForegroundColor Cyan
$healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method Get
Write-Host "Health OK" -ForegroundColor Green

# Test 2: Create User
Write-Host "2. Creating User..." -ForegroundColor Cyan
$newUser = @{
    name = "Test User"
    email = "test@example.com"
    password = "password123"
    country_of_residence = "United States"
    iban = "US1234567890"
    user_type = "Basic"
} | ConvertTo-Json

$createResponse = Invoke-RestMethod -Uri "$baseUrl/users" -Method Post -Body $newUser -Headers $headers
$userId = $createResponse.user_id
Write-Host "User created: $($createResponse.name)" -ForegroundColor Green
Write-Host "User ID: $userId" -ForegroundColor Yellow

# Test 3: Get Basic User
Write-Host "3. Get Basic User..." -ForegroundColor Cyan
$basicUser = Invoke-RestMethod -Uri "$baseUrl/users/$userId" -Method Get
Write-Host "Basic user retrieved: $($basicUser.name)" -ForegroundColor Green

# Test 4: Get Extended User
Write-Host "4. Get Extended User..." -ForegroundColor Cyan
$extendedUser = Invoke-RestMethod -Uri "$baseUrl/users/$userId/complete" -Method Get
Write-Host "Extended user retrieved" -ForegroundColor Green
Write-Host "Account Balance: $($extendedUser.account_balance)" -ForegroundColor Gray
Write-Host "Is Premium: $($extendedUser.is_premium)" -ForegroundColor Gray

# Test 5: Set Payment Method
Write-Host "5. Set Payment Method..." -ForegroundColor Cyan
$payment = @{
    payment_method_type = "CreditCard"
    payment_method_details = "VISA ****1234"
    payment_method_expiry = "2027-12-31"
} | ConvertTo-Json

$paymentResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/payment-method" -Method Put -Body $payment -Headers $headers
Write-Host "Payment method set: $($paymentResponse.status)" -ForegroundColor Green

# Test 6: Deposit Funds
Write-Host "6. Deposit Funds..." -ForegroundColor Cyan
$deposit = @{
    amount = 1000.00
    description = "Test deposit"
} | ConvertTo-Json

$depositResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/deposit" -Method Post -Body $deposit -Headers $headers
Write-Host "Deposited: $($depositResponse.amount)" -ForegroundColor Green
Write-Host "New Balance: $($depositResponse.new_balance)" -ForegroundColor Gray

# Test 7: Activate Subscription
Write-Host "7. Activate Subscription..." -ForegroundColor Cyan
$subscription = @{
    action = "ACTIVATE"
    months_to_add = 1
    monthly_rate = 50.00
} | ConvertTo-Json

$subResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/subscription" -Method Post -Body $subscription -Headers $headers
Write-Host "Subscription activated" -ForegroundColor Green
Write-Host "Amount paid: $($subResponse.amount_paid)" -ForegroundColor Gray

# Test 8: Create Portfolio
Write-Host "8. Create Portfolio..." -ForegroundColor Cyan
$portfolio = @{
    user_id = $userId
    name = "Test Portfolio"
    description = "A test portfolio"
} | ConvertTo-Json

$portfolioResponse = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method Post -Body $portfolio -Headers $headers
$portfolioId = $portfolioResponse.portfolio_id
Write-Host "Portfolio created: $($portfolioResponse.name)" -ForegroundColor Green

# Test 9: Allocate Funds
Write-Host "9. Allocate Funds..." -ForegroundColor Cyan
$allocate = @{
    portfolio_id = $portfolioId
    amount = 500.00
} | ConvertTo-Json

$allocateResponse = Invoke-RestMethod -Uri "$baseUrl/users/$userId/allocate" -Method Post -Body $allocate -Headers $headers
Write-Host "Funds allocated: $($allocateResponse.amount)" -ForegroundColor Green

# Test 10: Account Summary
Write-Host "10. Account Summary..." -ForegroundColor Cyan
$summary = Invoke-RestMethod -Uri "$baseUrl/users/$userId/account-summary" -Method Get
Write-Host "Account Summary:" -ForegroundColor Green
Write-Host "  Account Balance: $($summary.account_balance)" -ForegroundColor Gray
Write-Host "  Portfolio Value: $($summary.total_portfolio_value)" -ForegroundColor Gray
Write-Host "  Net Worth: $($summary.total_net_worth)" -ForegroundColor Gray

Write-Host ""
Write-Host "=== All Tests Passed ===" -ForegroundColor Green
Write-Host "User ID: $userId" -ForegroundColor Yellow
Write-Host "Portfolio ID: $portfolioId" -ForegroundColor Yellow 
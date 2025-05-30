# Quick test for the simplified API
$baseUrl = "http://localhost:8080/api/v1"
$headers = @{ "Content-Type" = "application/json" }

Write-Host "=== Testing Simplified API ===" -ForegroundColor Green

# 1. Health Check
Write-Host "1. Health Check..." -ForegroundColor Cyan
try {
    $health = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method Get
    Write-Host "Health: OK" -ForegroundColor Green
} catch {
    Write-Host "Health: FAILED - $_" -ForegroundColor Red
    exit 1
}

# 2. Create unique user
Write-Host "2. Creating User..." -ForegroundColor Cyan
$uniqueId = [System.Guid]::NewGuid().ToString("N").Substring(0,8)
$newUser = @{
    name = "TestUser_$uniqueId"
    email = "testuser$uniqueId@example.com"
    password = "password123"
    country_of_residence = "United States"
    iban = "US1234567890"
    user_type = "Basic"
} | ConvertTo-Json

try {
    $user = Invoke-RestMethod -Uri "$baseUrl/users" -Method Post -Body $newUser -Headers $headers
    $userId = $user.user_id
    Write-Host "User created: $($user.name)" -ForegroundColor Green
    Write-Host "User ID: $userId" -ForegroundColor Yellow
} catch {
    Write-Host "User creation failed: $_" -ForegroundColor Red
    exit 1
}

# 3. Get Basic User Info
Write-Host "3. Basic User Info..." -ForegroundColor Cyan
try {
    $basicUser = Invoke-RestMethod -Uri "$baseUrl/users/$userId" -Method Get
    Write-Host "Basic info retrieved: $($basicUser.name)" -ForegroundColor Green
} catch {
    Write-Host "Basic user retrieval failed: $_" -ForegroundColor Red
}

# 4. Get Extended User Info  
Write-Host "4. Extended User Info..." -ForegroundColor Cyan
try {
    $extendedUser = Invoke-RestMethod -Uri "$baseUrl/users/$userId/complete" -Method Get
    Write-Host "Extended info retrieved successfully!" -ForegroundColor Green
    Write-Host "  Account Balance: $($extendedUser.account_balance)" -ForegroundColor Gray
    Write-Host "  Is Premium: $($extendedUser.is_premium)" -ForegroundColor Gray
    Write-Host "  Payment Active: $($extendedUser.payment_method_active)" -ForegroundColor Gray
    Write-Host "  Subscription Expired: $($extendedUser.subscription_expired)" -ForegroundColor Gray
} catch {
    Write-Host "Extended user retrieval failed: $_" -ForegroundColor Red
}

# 5. Set Payment Method
Write-Host "5. Setting Payment Method..." -ForegroundColor Cyan
$payment = @{
    payment_method_type = "CreditCard"
    payment_method_details = "VISA ****1234"
    payment_method_expiry = "2027-12-31"
} | ConvertTo-Json

try {
    $paymentResult = Invoke-RestMethod -Uri "$baseUrl/users/$userId/payment-method" -Method Put -Body $payment -Headers $headers
    Write-Host "Payment method set: $($paymentResult.status)" -ForegroundColor Green
} catch {
    Write-Host "Payment method failed: $_" -ForegroundColor Red
}

# 6. Deposit Funds
Write-Host "6. Depositing Funds..." -ForegroundColor Cyan
$deposit = @{
    amount = 1000.00
    description = "Test deposit"
} | ConvertTo-Json

try {
    $depositResult = Invoke-RestMethod -Uri "$baseUrl/users/$userId/deposit" -Method Post -Body $deposit -Headers $headers
    Write-Host "Deposited: $($depositResult.amount)" -ForegroundColor Green
    Write-Host "New Balance: $($depositResult.new_balance)" -ForegroundColor Gray
} catch {
    Write-Host "Deposit failed: $_" -ForegroundColor Red
}

# 7. Activate Premium Subscription
Write-Host "7. Activating Premium..." -ForegroundColor Cyan
$subscription = @{
    action = "ACTIVATE"
    months_to_add = 1
    monthly_rate = 50.00
} | ConvertTo-Json

try {
    $subResult = Invoke-RestMethod -Uri "$baseUrl/users/$userId/subscription" -Method Post -Body $subscription -Headers $headers
    Write-Host "Premium activated!" -ForegroundColor Green
    Write-Host "Amount paid: $($subResult.amount_paid)" -ForegroundColor Gray
} catch {
    Write-Host "Premium activation failed: $_" -ForegroundColor Red
}

# 8. Verify Premium Status
Write-Host "8. Verifying Premium Status..." -ForegroundColor Cyan
try {
    $premiumUser = Invoke-RestMethod -Uri "$baseUrl/users/$userId/complete" -Method Get
    Write-Host "Premium verification:" -ForegroundColor Green
    Write-Host "  Is Premium: $($premiumUser.is_premium)" -ForegroundColor Gray
    Write-Host "  Premium Start: $($premiumUser.premium_start_date)" -ForegroundColor Gray
    Write-Host "  Premium End: $($premiumUser.premium_end_date)" -ForegroundColor Gray
    Write-Host "  Days Remaining: $($premiumUser.days_remaining_in_subscription)" -ForegroundColor Gray
} catch {
    Write-Host "Premium verification failed: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Green
Write-Host "User ID for further testing: $userId" -ForegroundColor Yellow 
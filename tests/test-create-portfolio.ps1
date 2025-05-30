# Test Create Portfolio Endpoint
Write-Host "=== TESTING CREATE PORTFOLIO ENDPOINT ===" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080/api/v1"

# Test data - using Maria Santos user ID from previous tests
$mariaSantosUserId = "397b94b0-55cf-4e3d-bfa0-b481a33c86e2"

Write-Host "`n1. Testing VALID portfolio creation..." -ForegroundColor Yellow
$createRequest = @{
    user_id = $mariaSantosUserId
    name = "My Investment Portfolio"
    initial_funds = 10000.00
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method POST -Body $createRequest -ContentType "application/json"
    Write-Host "✅ SUCCESS: Portfolio created" -ForegroundColor Green
    Write-Host "Portfolio ID: $($response.portfolio_id)" -ForegroundColor Green
    Write-Host "Name: $($response.name)" -ForegroundColor Green
    Write-Host "Current Funds: $($response.current_funds)" -ForegroundColor Green
    Write-Host "Creation Date: $($response.creation_date)" -ForegroundColor Green
    
    # Store for later tests
    $script:testPortfolioId = $response.portfolio_id
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
}

Write-Host "`n2. Testing portfolio creation with ZERO initial funds..." -ForegroundColor Yellow
$createZeroRequest = @{
    user_id = $mariaSantosUserId
    name = "Zero Funds Portfolio"
    initial_funds = 0.00
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method POST -Body $createZeroRequest -ContentType "application/json"
    Write-Host "✅ SUCCESS: Portfolio with zero funds created" -ForegroundColor Green
    Write-Host "Portfolio ID: $($response.portfolio_id)" -ForegroundColor Green
    Write-Host "Current Funds: $($response.current_funds)" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n3. Testing portfolio creation with INVALID user ID..." -ForegroundColor Yellow
$invalidUserRequest = @{
    user_id = "00000000-0000-0000-0000-000000000000"
    name = "Invalid User Portfolio"
    initial_funds = 5000.00
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method POST -Body $invalidUserRequest -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: Should have failed with invalid user" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 400) {
        Write-Host "✅ SUCCESS: Correctly rejected invalid user (400)" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED: Wrong status code $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n4. Testing portfolio creation with EMPTY name..." -ForegroundColor Yellow
$emptyNameRequest = @{
    user_id = $mariaSantosUserId
    name = ""
    initial_funds = 5000.00
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method POST -Body $emptyNameRequest -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: Should have failed with empty name" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 400) {
        Write-Host "✅ SUCCESS: Correctly rejected empty name (400)" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED: Wrong status code $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n5. Testing portfolio creation with NEGATIVE funds..." -ForegroundColor Yellow
$negativeFundsRequest = @{
    user_id = $mariaSantosUserId
    name = "Negative Funds Portfolio"
    initial_funds = -1000.00
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method POST -Body $negativeFundsRequest -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: Should have failed with negative funds" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 400) {
        Write-Host "✅ SUCCESS: Correctly rejected negative funds (400)" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED: Wrong status code $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n6. Testing portfolio creation with WHITESPACE-only name..." -ForegroundColor Yellow
$whitespaceNameRequest = @{
    user_id = $mariaSantosUserId
    name = "   "
    initial_funds = 5000.00
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method POST -Body $whitespaceNameRequest -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: Should have failed with whitespace-only name" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 400) {
        Write-Host "✅ SUCCESS: Correctly rejected whitespace-only name (400)" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED: Wrong status code $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n=== CREATE PORTFOLIO TESTS COMPLETED ===" -ForegroundColor Cyan

if ($script:testPortfolioId) {
    Write-Host "`nCreated portfolio ID for update tests: $($script:testPortfolioId)" -ForegroundColor Magenta
} 
# Test Update Portfolio Endpoint
Write-Host "=== TESTING UPDATE PORTFOLIO ENDPOINT ===" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080/api/v1"

# We'll use an existing portfolio ID - let's find one first
Write-Host "`n0. Finding existing portfolio..." -ForegroundColor Yellow

# Using Maria Santos user ID
$mariaSantosUserId = "397b94b0-55cf-4e3d-bfa0-b481a33c86e2"

try {
    $portfolios = Invoke-RestMethod -Uri "$baseUrl/portfolios?user_id=$mariaSantosUserId" -Method GET
    if ($portfolios -and $portfolios.Count -gt 0) {
        $testPortfolioId = $portfolios[0].portfolio_id
        Write-Host "✅ Found portfolio ID: $testPortfolioId" -ForegroundColor Green
        Write-Host "Current Name: $($portfolios[0].name)" -ForegroundColor Green
        Write-Host "Current Funds: $($portfolios[0].current_funds)" -ForegroundColor Green
    } else {
        Write-Host "❌ No portfolios found. Please run test-create-portfolio.ps1 first." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ FAILED to get portfolios: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n1. Testing UPDATE portfolio name only..." -ForegroundColor Yellow
$updateNameRequest = @{
    name = "Updated Investment Portfolio"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId" -Method PUT -Body $updateNameRequest -ContentType "application/json"
    Write-Host "✅ SUCCESS: Portfolio name updated" -ForegroundColor Green
    Write-Host "Portfolio ID: $($response.portfolio_id)" -ForegroundColor Green
    Write-Host "New Name: $($response.name)" -ForegroundColor Green
    Write-Host "Current Funds: $($response.current_funds)" -ForegroundColor Green
    Write-Host "Last Updated: $($response.last_updated)" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $stream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response: $responseBody" -ForegroundColor Red
    }
}

Write-Host "`n2. Testing UPDATE portfolio funds only..." -ForegroundColor Yellow
$updateFundsRequest = @{
    current_funds = 15000.50
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId" -Method PUT -Body $updateFundsRequest -ContentType "application/json"
    Write-Host "✅ SUCCESS: Portfolio funds updated" -ForegroundColor Green
    Write-Host "Portfolio ID: $($response.portfolio_id)" -ForegroundColor Green
    Write-Host "Name: $($response.name)" -ForegroundColor Green
    Write-Host "New Funds: $($response.current_funds)" -ForegroundColor Green
    Write-Host "Last Updated: $($response.last_updated)" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n3. Testing UPDATE both name and funds..." -ForegroundColor Yellow
$updateBothRequest = @{
    name = "Comprehensive Investment Portfolio"
    current_funds = 25000.75
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId" -Method PUT -Body $updateBothRequest -ContentType "application/json"
    Write-Host "✅ SUCCESS: Portfolio name and funds updated" -ForegroundColor Green
    Write-Host "Portfolio ID: $($response.portfolio_id)" -ForegroundColor Green
    Write-Host "New Name: $($response.name)" -ForegroundColor Green
    Write-Host "New Funds: $($response.current_funds)" -ForegroundColor Green
    Write-Host "Last Updated: $($response.last_updated)" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n4. Testing UPDATE with INVALID portfolio ID..." -ForegroundColor Yellow
$invalidPortfolioId = 99999
$updateInvalidRequest = @{
    name = "Should Fail"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios/$invalidPortfolioId" -Method PUT -Body $updateInvalidRequest -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: Should have failed with invalid portfolio ID" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 404) {
        Write-Host "✅ SUCCESS: Correctly rejected invalid portfolio ID (404)" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED: Wrong status code $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n5. Testing UPDATE with EMPTY name..." -ForegroundColor Yellow
$emptyNameRequest = @{
    name = ""
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId" -Method PUT -Body $emptyNameRequest -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: Should have failed with empty name" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 400) {
        Write-Host "✅ SUCCESS: Correctly rejected empty name (400)" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED: Wrong status code $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n6. Testing UPDATE with NEGATIVE funds..." -ForegroundColor Yellow
$negativeFundsRequest = @{
    current_funds = -500.00
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId" -Method PUT -Body $negativeFundsRequest -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: Should have failed with negative funds" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 400) {
        Write-Host "✅ SUCCESS: Correctly rejected negative funds (400)" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED: Wrong status code $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n7. Testing UPDATE with NO fields..." -ForegroundColor Yellow
$emptyUpdateRequest = @{} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId" -Method PUT -Body $emptyUpdateRequest -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: Should have failed with no fields" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 400) {
        Write-Host "✅ SUCCESS: Correctly rejected empty update (400)" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED: Wrong status code $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n8. Testing UPDATE with WHITESPACE-only name..." -ForegroundColor Yellow
$whitespaceNameRequest = @{
    name = "   "
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId" -Method PUT -Body $whitespaceNameRequest -ContentType "application/json"
    Write-Host "❌ UNEXPECTED SUCCESS: Should have failed with whitespace-only name" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 400) {
        Write-Host "✅ SUCCESS: Correctly rejected whitespace-only name (400)" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED: Wrong status code $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n9. Testing UPDATE with ZERO funds (should work)..." -ForegroundColor Yellow
$zeroFundsRequest = @{
    current_funds = 0.00
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId" -Method PUT -Body $zeroFundsRequest -ContentType "application/json"
    Write-Host "✅ SUCCESS: Portfolio funds updated to zero" -ForegroundColor Green
    Write-Host "New Funds: $($response.current_funds)" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== UPDATE PORTFOLIO TESTS COMPLETED ===" -ForegroundColor Cyan 
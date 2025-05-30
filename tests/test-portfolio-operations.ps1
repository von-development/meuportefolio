# Test All Portfolio Operations
Write-Host "=== COMPREHENSIVE PORTFOLIO OPERATIONS TEST ===" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080/api/v1"
$mariaSantosUserId = "397b94b0-55cf-4e3d-bfa0-b481a33c86e2"

Write-Host "`n1. Testing LIST portfolios for user..." -ForegroundColor Yellow
try {
    $portfolios = Invoke-RestMethod -Uri "$baseUrl/portfolios?user_id=$mariaSantosUserId" -Method GET
    Write-Host "✅ SUCCESS: Found $($portfolios.Count) portfolios" -ForegroundColor Green
    foreach ($portfolio in $portfolios) {
        Write-Host "  - Portfolio ID: $($portfolio.portfolio_id), Name: $($portfolio.name), Funds: $($portfolio.current_funds)" -ForegroundColor Cyan
    }
    $testPortfolioId = $portfolios[0].portfolio_id
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n2. Testing GET specific portfolio..." -ForegroundColor Yellow
try {
    $portfolio = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId" -Method GET
    Write-Host "✅ SUCCESS: Retrieved portfolio" -ForegroundColor Green
    Write-Host "  - ID: $($portfolio.portfolio_id)" -ForegroundColor Cyan
    Write-Host "  - Name: $($portfolio.name)" -ForegroundColor Cyan
    Write-Host "  - User ID: $($portfolio.user_id)" -ForegroundColor Cyan
    Write-Host "  - Current Funds: $($portfolio.current_funds)" -ForegroundColor Cyan
    Write-Host "  - Creation Date: $($portfolio.creation_date)" -ForegroundColor Cyan
    Write-Host "  - Last Updated: $($portfolio.last_updated)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n3. Testing GET portfolio summary..." -ForegroundColor Yellow
try {
    $summary = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId/summary" -Method GET
    Write-Host "✅ SUCCESS: Retrieved portfolio summary" -ForegroundColor Green
    Write-Host "  - Portfolio ID: $($summary.portfolio_id)" -ForegroundColor Cyan
    Write-Host "  - Portfolio Name: $($summary.portfolio_name)" -ForegroundColor Cyan
    Write-Host "  - Owner: $($summary.owner)" -ForegroundColor Cyan
    Write-Host "  - Current Funds: $($summary.current_funds)" -ForegroundColor Cyan
    Write-Host "  - Current Profit %: $($summary.current_profit_pct)" -ForegroundColor Cyan
    Write-Host "  - Total Trades: $($summary.total_trades)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n4. Testing GET portfolio holdings..." -ForegroundColor Yellow
try {
    $holdings = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId/holdings" -Method GET
    Write-Host "✅ SUCCESS: Retrieved portfolio holdings" -ForegroundColor Green
    if ($holdings -and $holdings.Count -gt 0) {
        Write-Host "  Found $($holdings.Count) holdings:" -ForegroundColor Cyan
        foreach ($holding in $holdings) {
            Write-Host "    - Asset: $($holding.asset_name) ($($holding.symbol))" -ForegroundColor Cyan
            Write-Host "      Quantity: $($holding.quantity_held), Value: $($holding.market_value)" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  - No holdings found (expected for new portfolio)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n5. Testing GET non-existent portfolio..." -ForegroundColor Yellow
$invalidId = 99999
try {
    $portfolio = Invoke-RestMethod -Uri "$baseUrl/portfolios/$invalidId" -Method GET
    Write-Host "❌ UNEXPECTED SUCCESS: Should have failed with 404" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 404) {
        Write-Host "✅ SUCCESS: Correctly returned 404 for non-existent portfolio" -ForegroundColor Green
    } else {
        Write-Host "❌ FAILED: Wrong status code $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n6. Testing LIST all portfolios (no filter)..." -ForegroundColor Yellow
try {
    $allPortfolios = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method GET
    Write-Host "✅ SUCCESS: Found $($allPortfolios.Count) total portfolios" -ForegroundColor Green
    Write-Host "  - First few portfolios:" -ForegroundColor Cyan
    $allPortfolios | Select-Object -First 3 | ForEach-Object {
        Write-Host "    ID: $($_.portfolio_id), Name: $($_.name), User: $($_.user_id)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n7. Testing CREATE portfolio with very long name..." -ForegroundColor Yellow
$longNameRequest = @{
    user_id = $mariaSantosUserId
    name = "A" * 150  # Very long name (150 characters)
    initial_funds = 1000.00
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method POST -Body $longNameRequest -ContentType "application/json"
    if ($response.name.Length -le 100) {
        Write-Host "✅ SUCCESS: Long name was truncated appropriately to $($response.name.Length) chars" -ForegroundColor Green
    } else {
        Write-Host "⚠️  WARNING: Long name was not truncated (length: $($response.name.Length))" -ForegroundColor Yellow
    }
    Write-Host "Portfolio ID: $($response.portfolio_id)" -ForegroundColor Green
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n8. Testing UPDATE with decimal precision..." -ForegroundColor Yellow
$precisionRequest = @{
    current_funds = 12345.6789
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$baseUrl/portfolios/$testPortfolioId" -Method PUT -Body $precisionRequest -ContentType "application/json"
    Write-Host "✅ SUCCESS: Decimal precision handled" -ForegroundColor Green
    Write-Host "  - Funds set to: $($response.current_funds)" -ForegroundColor Cyan
} catch {
    Write-Host "❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== COMPREHENSIVE PORTFOLIO TESTS COMPLETED ===" -ForegroundColor Cyan 
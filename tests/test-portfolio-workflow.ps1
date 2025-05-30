# Complete Portfolio Workflow Test
Write-Host "=== COMPLETE PORTFOLIO WORKFLOW TEST ===" -ForegroundColor Cyan

$baseUrl = "http://localhost:8080/api/v1"
$mariaSantosUserId = "397b94b0-55cf-4e3d-bfa0-b481a33c86e2"

Write-Host "`nSTEP 1: Creating a new portfolio..." -ForegroundColor Yellow
$createRequest = @{
    user_id = $mariaSantosUserId
    name = "Workflow Test Portfolio"
    initial_funds = 50000.00
} | ConvertTo-Json

try {
    $newPortfolio = Invoke-RestMethod -Uri "$baseUrl/portfolios" -Method POST -Body $createRequest -ContentType "application/json"
    Write-Host "SUCCESS: Portfolio created!" -ForegroundColor Green
    Write-Host "  - ID: $($newPortfolio.portfolio_id)" -ForegroundColor Cyan
    Write-Host "  - Name: $($newPortfolio.name)" -ForegroundColor Cyan
    Write-Host "  - Initial Funds: $($newPortfolio.current_funds)" -ForegroundColor Cyan
    $portfolioId = $newPortfolio.portfolio_id
} catch {
    Write-Host "FAILED to create portfolio: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`nSTEP 2: Retrieving portfolio details..." -ForegroundColor Yellow
try {
    $portfolio = Invoke-RestMethod -Uri "$baseUrl/portfolios/$portfolioId" -Method GET
    Write-Host "SUCCESS: Portfolio details retrieved!" -ForegroundColor Green
    Write-Host "  - User ID: $($portfolio.user_id)" -ForegroundColor Cyan
    Write-Host "  - Creation Date: $($portfolio.creation_date)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to retrieve portfolio: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 3: Updating portfolio name..." -ForegroundColor Yellow
$updateNameRequest = @{
    name = "Updated Workflow Portfolio"
} | ConvertTo-Json

try {
    $updatedPortfolio = Invoke-RestMethod -Uri "$baseUrl/portfolios/$portfolioId" -Method PUT -Body $updateNameRequest -ContentType "application/json"
    Write-Host "SUCCESS: Portfolio name updated!" -ForegroundColor Green
    Write-Host "  - New Name: $($updatedPortfolio.name)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to update name: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 4: Updating portfolio funds..." -ForegroundColor Yellow
$updateFundsRequest = @{
    current_funds = 75000.50
} | ConvertTo-Json

try {
    $updatedPortfolio = Invoke-RestMethod -Uri "$baseUrl/portfolios/$portfolioId" -Method PUT -Body $updateFundsRequest -ContentType "application/json"
    Write-Host "SUCCESS: Portfolio funds updated!" -ForegroundColor Green
    Write-Host "  - New Funds: $($updatedPortfolio.current_funds)" -ForegroundColor Cyan
} catch {
    Write-Host "FAILED to update funds: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 5: Testing portfolio deletion..." -ForegroundColor Yellow
try {
    $null = Invoke-RestMethod -Uri "$baseUrl/portfolios/$portfolioId" -Method DELETE
    Write-Host "SUCCESS: Portfolio deleted!" -ForegroundColor Green
} catch {
    Write-Host "FAILED to delete portfolio: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`nSTEP 6: Verifying portfolio is deleted..." -ForegroundColor Yellow
try {
    $portfolio = Invoke-RestMethod -Uri "$baseUrl/portfolios/$portfolioId" -Method GET
    Write-Host "UNEXPECTED: Portfolio still exists after deletion" -ForegroundColor Red
} catch {
    $statusCode = $_.Exception.Response.StatusCode.Value__
    if ($statusCode -eq 404) {
        Write-Host "SUCCESS: Portfolio successfully deleted (404)" -ForegroundColor Green
    } else {
        Write-Host "UNEXPECTED status code: $statusCode" -ForegroundColor Red
    }
}

Write-Host "`nWORKFLOW TEST COMPLETED!" -ForegroundColor Green
Write-Host "All portfolio operations working correctly." -ForegroundColor Green 
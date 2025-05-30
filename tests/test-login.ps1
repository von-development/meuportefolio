# Test Login Endpoint
Write-Host "Testing Login Endpoint..." -ForegroundColor Yellow

$loginRequest = @{
    email = "test@example.com"
    password = "testpass123"
}

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/login" -Method POST -Body ($loginRequest | ConvertTo-Json) -ContentType "application/json"
    Write-Host "✅ Login successful!" -ForegroundColor Green
    Write-Host "User Info:" -ForegroundColor Cyan
    $response.user | ConvertTo-Json -Depth 3
    Write-Host "`nToken received: $($response.token.Substring(0,50))..." -ForegroundColor Green
} catch {
    Write-Host "❌ Login failed: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
    }
} 
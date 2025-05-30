# Test Create User Endpoint
Write-Host "Testing Create User Endpoint..." -ForegroundColor Yellow

$newUser = @{
    name = "Test User"
    email = "test@example.com"
    password = "testpass123"
    country_of_residence = "Portugal"
    iban = "PT12345678901234567890"
    user_type = "Basic"
}

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users" -Method POST -Body ($newUser | ConvertTo-Json) -ContentType "application/json"
    Write-Host "✅ User created successfully!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Cyan
    $response | ConvertTo-Json -Depth 3
} catch {
    Write-Host "❌ Create user failed: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
        
        try {
            $errorStream = $_.Exception.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorStream)
            $errorText = $reader.ReadToEnd()
            Write-Host "Error details: $errorText" -ForegroundColor Red
        } catch {
            Write-Host "Could not read error details" -ForegroundColor Red
        }
    }
} 
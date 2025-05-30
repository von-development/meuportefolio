# Test Update User Endpoint
Write-Host "Testing Update User Endpoint..." -ForegroundColor Yellow

# First, let's get the test user we created earlier
$testUserEmail = "test@example.com"

# Get the user ID by listing all users and finding our test user
try {
    $users = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users" -Method GET
    $testUser = $users | Where-Object { $_.email -eq $testUserEmail }
    
    if (-not $testUser) {
        Write-Host "❌ Test user not found. Creating one first..." -ForegroundColor Red
        
        # Create a test user first
        $newUser = @{
            name = "Test User"
            email = "testupdate@example.com"
            password = "testpass123"
            country_of_residence = "Portugal"
            iban = "PT12345678901234567890"
            user_type = "Basic"
        }
        
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users" -Method POST -Body ($newUser | ConvertTo-Json) -ContentType "application/json"
        $testUser = $response
        Write-Host "✅ Created test user: $($testUser.user_id)" -ForegroundColor Green
    }
    
    Write-Host "Using test user: $($testUser.user_id)" -ForegroundColor Cyan
    Write-Host "Current name: $($testUser.name)" -ForegroundColor Cyan
    Write-Host "Current email: $($testUser.email)" -ForegroundColor Cyan
    
} catch {
    Write-Host "❌ Failed to get users: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 1: Update only the name
Write-Host "`n=== Test 1: Update Name Only ===" -ForegroundColor Yellow
$updateRequest = @{
    name = "Updated Test User"
}

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/$($testUser.user_id)" -Method PUT -Body ($updateRequest | ConvertTo-Json) -ContentType "application/json"
    Write-Host "✅ Name updated successfully!" -ForegroundColor Green
    Write-Host "New name: $($response.name)" -ForegroundColor Green
    Write-Host "Updated at: $($response.updated_at)" -ForegroundColor Green
} catch {
    Write-Host "❌ Update name failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
    }
}

# Test 2: Update multiple fields
Write-Host "`n=== Test 2: Update Multiple Fields ===" -ForegroundColor Yellow
$updateRequest = @{
    name = "Super Updated User"
    user_type = "Premium"
    country_of_residence = "Spain"
}

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/$($testUser.user_id)" -Method PUT -Body ($updateRequest | ConvertTo-Json) -ContentType "application/json"
    Write-Host "✅ Multiple fields updated successfully!" -ForegroundColor Green
    Write-Host "New name: $($response.name)" -ForegroundColor Green
    Write-Host "New user_type: $($response.user_type)" -ForegroundColor Green
    Write-Host "New country: $($response.country_of_residence)" -ForegroundColor Green
    Write-Host "Updated at: $($response.updated_at)" -ForegroundColor Green
} catch {
    Write-Host "❌ Update multiple fields failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
    }
}

# Test 3: Update password
Write-Host "`n=== Test 3: Update Password ===" -ForegroundColor Yellow
$updateRequest = @{
    password = "newpassword456"
}

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/$($testUser.user_id)" -Method PUT -Body ($updateRequest | ConvertTo-Json) -ContentType "application/json"
    Write-Host "✅ Password updated successfully!" -ForegroundColor Green
    Write-Host "Updated at: $($response.updated_at)" -ForegroundColor Green
    
    # Test login with new password
    Write-Host "`nTesting login with new password..." -ForegroundColor Cyan
    $loginRequest = @{
        email = $response.email
        password = "newpassword456"
    }
    
    $loginResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/login" -Method POST -Body ($loginRequest | ConvertTo-Json) -ContentType "application/json"
    Write-Host "✅ Login with new password successful!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Update password failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
    }
}

# Test 4: Try to update with duplicate email (should fail)
Write-Host "`n=== Test 4: Duplicate Email Test (Should Fail) ===" -ForegroundColor Yellow
$updateRequest = @{
    email = "maria.santos@email.com"  # This email already exists
}

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/$($testUser.user_id)" -Method PUT -Body ($updateRequest | ConvertTo-Json) -ContentType "application/json"
    Write-Host "❌ Duplicate email update should have failed!" -ForegroundColor Red
} catch {
    Write-Host "✅ Duplicate email correctly rejected: $($_.Exception.Message)" -ForegroundColor Green
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status Code: $statusCode" -ForegroundColor Green
    }
}

# Test 5: Try to update with no fields (should fail)
Write-Host "`n=== Test 5: No Fields Test (Should Fail) ===" -ForegroundColor Yellow
$updateRequest = @{}

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/$($testUser.user_id)" -Method PUT -Body ($updateRequest | ConvertTo-Json) -ContentType "application/json"
    Write-Host "❌ Empty update should have failed!" -ForegroundColor Red
} catch {
    Write-Host "✅ Empty update correctly rejected: $($_.Exception.Message)" -ForegroundColor Green
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "Status Code: $statusCode" -ForegroundColor Green
    }
}

Write-Host "`n=== Update User Tests Complete ===" -ForegroundColor Green 
# Portfolio API Test Script
# This script will:
# 1. Apply database migrations 
# 2. Build and run the API with Docker
# 3. Test the API endpoints

Write-Host "=== Portfolio API Setup and Test ===" -ForegroundColor Green

# Step 1: Build and start the containers
Write-Host "`n1. Building and starting Docker containers..." -ForegroundColor Yellow
docker-compose down
docker-compose up --build -d

# Wait for services to be ready
Write-Host "`n2. Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check if API is responding
Write-Host "`n3. Checking API health..." -ForegroundColor Yellow
try {
    $healthResponse = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET
    Write-Host "API Health: $($healthResponse.status)" -ForegroundColor Green
} catch {
    Write-Host "API not ready yet, waiting longer..." -ForegroundColor Red
    Start-Sleep -Seconds 20
}

# Step 2: Apply database migrations (in order)
Write-Host "`n4. Applying database migrations..." -ForegroundColor Yellow

$migrations = @(
    "/scripts/migrations/000_init.sql",
    "/scripts/migrations/001_tables.sql", 
    "/scripts/migrations/002_views.sql",
    "/scripts/migrations/003_procedures.sql",
    "/scripts/migrations/004_functions_triggers.sql",
    "/scripts/migrations/005_indexes.sql",
    "/scripts/migrations/006_password_field_change.sql",
    "/scripts/migrations/007_update_procedures.sql"
)

foreach ($migration in $migrations) {
    $localPath = $migration -replace "/scripts/", "db/"
    if (Test-Path $localPath) {
        Write-Host "Applying: $migration" -ForegroundColor Cyan
        docker exec meuportefolio-db-1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'meuportefolio!23' -i $migration
    } else {
        Write-Host "Migration file not found: $localPath" -ForegroundColor Red
    }
}

# Step 3: Load seed data
Write-Host "`n5. Loading seed data..." -ForegroundColor Yellow
if (Test-Path "db/seed/clean_and_seed.sql") {
    docker exec meuportefolio-db-1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'meuportefolio!23' -i "/scripts/seed/clean_and_seed.sql"
    Write-Host "Seed data loaded successfully" -ForegroundColor Green
}

# Wait a bit more for everything to be ready
Start-Sleep -Seconds 10

# Step 4: Test API endpoints
Write-Host "`n6. Testing API endpoints..." -ForegroundColor Yellow

# Test 1: Health check
Write-Host "`nTesting health check..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/health" -Method GET
    Write-Host "Health Check: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "Health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Database health check
Write-Host "`nTesting database health..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/db-health" -Method GET
    Write-Host "DB Health Check: $($response | ConvertTo-Json)" -ForegroundColor Green
} catch {
    Write-Host "DB health check failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: List users
Write-Host "`nTesting list users..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users" -Method GET
    Write-Host "Users found: $($response.Count)" -ForegroundColor Green
    $response | Select-Object -First 2 | ConvertTo-Json -Depth 3
} catch {
    Write-Host "List users failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Create a new user
Write-Host "`nTesting create user..." -ForegroundColor Cyan
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
    Write-Host "User created successfully:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 3
    $testUserId = $response.user_id
} catch {
    Write-Host "Create user failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorBody = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorBody)
        $errorText = $reader.ReadToEnd()
        Write-Host "Error details: $errorText" -ForegroundColor Red
    }
}

# Test 5: Login with existing user (Maria Santos)
Write-Host "`nTesting login with existing user..." -ForegroundColor Cyan
$loginRequest = @{
    email = "maria.santos@email.com"
    password = "password123"
}

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/login" -Method POST -Body ($loginRequest | ConvertTo-Json) -ContentType "application/json"
    Write-Host "Login successful:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Login failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $errorBody = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorBody)
        $errorText = $reader.ReadToEnd()
        Write-Host "Error details: $errorText" -ForegroundColor Red
    }
}

# Test 6: Login with newly created user
if ($testUserId) {
    Write-Host "`nTesting login with newly created user..." -ForegroundColor Cyan
    $loginRequest = @{
        email = "test@example.com"
        password = "testpass123"
    }

    try {
        $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/users/login" -Method POST -Body ($loginRequest | ConvertTo-Json) -ContentType "application/json"
        Write-Host "New user login successful:" -ForegroundColor Green
        $response.user | ConvertTo-Json -Depth 3
    } catch {
        Write-Host "New user login failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 7: List portfolios for Maria Santos
Write-Host "`nTesting list portfolios..." -ForegroundColor Cyan
try {
    $mariaId = "397b94b0-55cf-4e3d-bfa0-b481a33c86e2"
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/portfolios?user_id=$mariaId" -Method GET
    Write-Host "Portfolios found: $($response.Count)" -ForegroundColor Green
    $response | Select-Object -First 2 | ConvertTo-Json -Depth 3
} catch {
    Write-Host "List portfolios failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 8: Get user risk metrics (the problematic endpoint)
Write-Host "`nTesting user risk metrics..." -ForegroundColor Cyan
try {
    $mariaId = "397b94b0-55cf-4e3d-bfa0-b481a33c86e2"
    $response = Invoke-RestMethod -Uri "http://localhost:8080/api/v1/risk/metrics/user/$mariaId" -Method GET
    Write-Host "Risk metrics retrieved successfully:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 3
} catch {
    Write-Host "Risk metrics failed: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "Status Code: $statusCode" -ForegroundColor Red
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Green
Write-Host "API documentation available at: http://localhost:8080/swagger-ui" -ForegroundColor Yellow 
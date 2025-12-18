# Trust all certificates
if (-not ([System.Management.Automation.PSTypeName]'System.Net.ServicePointManager').Type) {
    Add-Type -AssemblyName System.Net
}
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$headers = @{ "Content-Type" = "application/json" }

# 1. Cleanup: Delete ALL existing activities (including the "Curl Test" ones)
Write-Host "1. Cleaning up existing activities..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "https://localhost:5001/api/activities/delete-all" -Method Delete
    Write-Host "   Cleanup Success: $($response.StatusDescription)" -ForegroundColor Green
} catch {
    Write-Host "   Cleanup Failed: $_" -ForegroundColor Red
}

# 2. Setup for Delete Test: Create a User and Activity
Write-Host "`n2. Setting up test activity..." -ForegroundColor Cyan
$email = "delete_tester_$(Get-Random)@test.com"
$password = "Pa$$w0rd123!"

# Register
$registerBody = @{
    email = $email
    password = $password
    displayName = "Delete Tester"
    username = $email
} | ConvertTo-Json

try {
    Invoke-WebRequest -Uri "https://localhost:5001/api/account/register" -Method Post -Body $registerBody -Headers $headers | Out-Null
    Write-Host "   Registered user: $email"
} catch {
    Write-Host "   Registration Failed: $_" -ForegroundColor Red
    exit
}

# Login
$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    $loginResponse = Invoke-WebRequest -Uri "https://localhost:5001/api/login?useCookies=true" -Method Post -Body $loginBody -Headers $headers -SessionVariable "session"
    Write-Host "   Logged in."
} catch {
    Write-Host "   Login Failed: $_" -ForegroundColor Red
    exit
}

# Create Activity
$activityId = [Guid]::NewGuid().ToString()
$activityBody = @{
    id = $activityId
    title = "Activity To Be Deleted"
    description = "This activity should be deleted shortly"
    category = "test"
    date = (Get-Date).AddDays(1).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    city = "Test City"
    venue = "Test Venue"
    isZoomOnly = $false
} | ConvertTo-Json

try {
    Invoke-WebRequest -Uri "https://localhost:5001/api/activities" -Method Post -Body $activityBody -Headers $headers -WebSession $session | Out-Null
    Write-Host "   Activity Created: $activityId"
} catch {
    Write-Host "   Activity Creation Failed: $_" -ForegroundColor Red
    exit
}

# 3. Test Delete Function
Write-Host "`n3. Testing Delete Function..." -ForegroundColor Cyan
try {
    $deleteResponse = Invoke-WebRequest -Uri "https://localhost:5001/api/activities/$activityId" -Method Delete -Headers $headers -WebSession $session
    Write-Host "   Delete Request Status: $($deleteResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   Delete Request Failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
         $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
         Write-Host "   Details: $($reader.ReadToEnd())"
    }
    exit
}

# 4. Verify Deletion
Write-Host "`n4. Verifying Deletion..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri "https://localhost:5001/api/activities/$activityId" -Method Get -Headers $headers -WebSession $session
    Write-Host "   FAILURE: Activity still exists!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq "NotFound") {
        Write-Host "   SUCCESS: Activity confirmed deleted (404 Not Found)." -ForegroundColor Green
    } else {
        Write-Host "   Unexpected Error during verification: $_" -ForegroundColor Yellow
    }
}

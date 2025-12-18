# Trust all certificates
if (-not ([System.Management.Automation.PSTypeName]'System.Net.ServicePointManager').Type) {
    Add-Type -AssemblyName System.Net
}
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$headers = @{ "Content-Type" = "application/json" }
$baseUrl = "https://localhost:5001/api"

# 1. Register and Login to establish a stable session
Write-Host "1. Authenticating to establish session..." -ForegroundColor Cyan
$email = "cleanup_$(Get-Random)@test.com"
$password = "Pa$$w0rd123!"

$registerBody = @{
    email = $email
    password = $password
    displayName = "Cleanup Agent"
    username = $email
} | ConvertTo-Json

try {
    Invoke-WebRequest -Uri "$baseUrl/account/register" -Method Post -Body $registerBody -Headers $headers | Out-Null
    Write-Host "   Registered: $email"
} catch {
    Write-Host "   Registration Failed: $_" -ForegroundColor Red
    exit 1
}

$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

try {
    # Establish Session
    Invoke-WebRequest -Uri "$baseUrl/login?useCookies=true" -Method Post -Body $loginBody -Headers $headers -SessionVariable "session" | Out-Null
    Write-Host "   Logged in successfully. Session established." -ForegroundColor Green
} catch {
    Write-Host "   Login Failed: $_" -ForegroundColor Red
    exit 1
}

# 2. DELETE ALL existing activities using the session
Write-Host "`n2. Deleting ALL existing activities..." -ForegroundColor Cyan
try {
    # Using the authenticated session might help with connection stability
    $response = Invoke-WebRequest -Uri "$baseUrl/activities/delete-all" -Method Delete -Headers $headers -WebSession $session -TimeoutSec 300
    Write-Host "   Delete All Response: $($response.StatusDescription)" -ForegroundColor Green
} catch {
    Write-Host "   Delete All Failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
         $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
         Write-Host "   Details: $($reader.ReadToEnd())"
    }
    # Don't exit here, just continue to test the individual delete
}

# 3. Create a Test Activity
Write-Host "`n3. Creating Test Activity..." -ForegroundColor Cyan
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
    Invoke-WebRequest -Uri "$baseUrl/activities" -Method Post -Body $activityBody -Headers $headers -WebSession $session | Out-Null
    Write-Host "   Activity Created: $activityId"
} catch {
    Write-Host "   Activity Creation Failed: $_" -ForegroundColor Red
    exit 1
}

# 4. Delete the Single Activity
Write-Host "`n4. Testing Single Delete Function..." -ForegroundColor Cyan
try {
    $deleteResponse = Invoke-WebRequest -Uri "$baseUrl/activities/$activityId" -Method Delete -Headers $headers -WebSession $session
    Write-Host "   Delete Request Status: $($deleteResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "   Delete Request Failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
         $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
         Write-Host "   Details: $($reader.ReadToEnd())"
    }
    exit 1
}

# 5. Verify Deletion
Write-Host "`n5. Verifying Deletion..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri "$baseUrl/activities/$activityId" -Method Get -Headers $headers -WebSession $session
    Write-Host "   FAILURE: Activity still exists!" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq "NotFound") {
        Write-Host "   SUCCESS: Activity confirmed deleted (404 Not Found)." -ForegroundColor Green
    } else {
        Write-Host "   Unexpected Error during verification: $_" -ForegroundColor Yellow
    }
}

# Trust all certificates for this session (for localhost testing)
if (-not ([System.Management.Automation.PSTypeName]'System.Net.ServicePointManager').Type) {
    Add-Type -AssemblyName System.Net
}
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

$headers = @{ "Content-Type" = "application/json" }
$email = "curl_test_$(Get-Random)@test.com"
$password = "Pa$$w0rd123!"

# 0. Register (Attempt to register first)
$registerBody = @{
    email = $email
    password = $password
    displayName = "Curl Tester"
    username = $email
} | ConvertTo-Json

try {
    Write-Host "Registering user $email ..."
    $regResponse = Invoke-WebRequest -Uri "https://localhost:5001/api/account/register" -Method Post -Body $registerBody -Headers $headers
    Write-Host "Registration status: $($regResponse.StatusCode)"
} catch {
    Write-Host "Registration Failed: $_"
    if ($_.Exception.Response) {
         $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
         Write-Host "Error Details: $($reader.ReadToEnd())"
    }
}

$loginBody = @{
    email = $email
    password = $password
} | ConvertTo-Json

# 1. Login
try {
    # Removed -SkipCertificateCheck for compatibility
    $loginResponse = Invoke-WebRequest -Uri "https://localhost:5001/api/login?useCookies=true" -Method Post -Body $loginBody -Headers $headers -SessionVariable "session"
    Write-Host "Login Successful. Status: $($loginResponse.StatusCode)"
} catch {
    Write-Host "Login Failed: $_"
    if ($_.Exception.Response) {
         $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
         Write-Host "Error Details: $($reader.ReadToEnd())"
    }
    exit 1
}

# 2. Create Zoom Activity
$activityDate = (Get-Date).AddDays(1).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$activityBody = @{
    id = [Guid]::NewGuid().ToString()
    title = "Curl Test Zoom Event"
    description = "Created via PowerShell script"
    category = "culture"
    date = $activityDate
    location = @{
        venue = ""
        city = ""
        latitude = 0
        longitude = 0
    }
    isZoomOnly = $true
} | ConvertTo-Json

try {
    # Removed -SkipCertificateCheck for compatibility
    $createResponse = Invoke-WebRequest -Uri "https://localhost:5001/api/activities" -Method Post -Body $activityBody -Headers $headers -WebSession $session
    Write-Host "Activity Creation Response: $($createResponse.Content)"
    Write-Host "Activity Creation Status: $($createResponse.StatusCode)"
} catch {
    Write-Host "Create Activity Failed: $_"
    # Print detailed error if available
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
        Write-Host "Error Details: $($reader.ReadToEnd())"
    }
    exit 1
}

# 3. Verify Activity Details
try {
    # Extract ID from response (response content is the ID string in double quotes)
    $newActivityId = $createResponse.Content.Trim('"')
    
    $getResponse = Invoke-WebRequest -Uri "https://localhost:5001/api/activities/$newActivityId" -Method Get -Headers $headers -WebSession $session
    $activityDetails = $getResponse.Content | ConvertFrom-Json
    
    Write-Host "--------------------------------------------------"
    Write-Host "VERIFICATION RESULTS:"
    Write-Host "Activity ID: $($activityDetails.id)"
    Write-Host "Zoom Meeting ID: $($activityDetails.zoomMeetingId)"
    Write-Host "Zoom Join URL: $($activityDetails.zoomMeetingUrl)"
    
    if (-not [string]::IsNullOrEmpty($activityDetails.zoomMeetingId)) {
        Write-Host "SUCCESS: Zoom ID generated!" -ForegroundColor Green
    } else {
        Write-Host "FAILURE: Zoom ID is missing." -ForegroundColor Red
    }
} catch {
    Write-Host "Failed to get activity details: $_"
}

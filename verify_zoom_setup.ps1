[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }

$loginUrl = "https://localhost:5001/api/account/login"
$activitiesUrl = "https://localhost:5001/api/activities"

Write-Host "1. Logging in to $loginUrl ..." -ForegroundColor Cyan
$loginBody = @{ email = "bob@test.com"; password = "Pa$$w0rd" } | ConvertTo-Json
try {
    $loginResponse = Invoke-WebRequest -Uri $loginUrl -Method Post -Body $loginBody -ContentType "application/json"
    $userDto = $loginResponse.Content | ConvertFrom-Json
    
    if ($userDto.token) {
        Write-Host "   Login Successful. Token received." -ForegroundColor Green
        $token = $userDto.token
        $headers = @{ Authorization = "Bearer $token" }
    } else {
        Write-Host "   Login Successful but NO TOKEN found." -ForegroundColor Yellow
        Write-Host "   Content: $($loginResponse.Content)"
        exit
    }
} catch {
    Write-Host "   Login Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

Write-Host "`n2. Creating New Zoom Activity to Test Integration..." -ForegroundColor Cyan
$activityBody = @{
    title = "Zoom API Integrity Check"
    date = (Get-Date).AddDays(1)
    description = "Automated test to verify Zoom API key configuration."
    category = "music"
    city = "Online"
    venue = "Zoom Meeting"
    isZoomOnly = $true
} | ConvertTo-Json

try {
    # Using Bearer Token Headers instead of Session/Cookies
    $response = Invoke-WebRequest -Uri $activitiesUrl -Method Post -Body $activityBody -Headers $headers -ContentType "application/json"
    $activityId = $response.Content.Trim('"')
    Write-Host "   Activity Created successfully. ID: $activityId" -ForegroundColor Green
    
    # 3. Fetch details to confirm URL
    Write-Host "`n3. Verifying Zoom URL presence..." -ForegroundColor Cyan
    $details = Invoke-RestMethod -Uri "$activitiesUrl/$activityId" -Headers $headers
    
    if (-not [string]::IsNullOrWhiteSpace($details.zoomMeetingUrl)) {
        Write-Host "   SUCCESS: Zoom URL found: $($details.zoomMeetingUrl)" -ForegroundColor Green
        Write-Host "   Meeting ID: $($details.zoomMeetingId)" -ForegroundColor Green
        Write-Host "`n   The Zoom integration is FULLY FUNCTIONAL." -ForegroundColor Cyan
    } else {
        Write-Host "   FAILURE: Activity created but Zoom URL is missing." -ForegroundColor Red
        Write-Host "   Check backend logs for 'Zoom Auth Failed'." -ForegroundColor Red
    }

} catch {
    Write-Host "   FAILURE: Creation Failed." -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
        Write-Host "   Backend Details: $($reader.ReadToEnd())" -ForegroundColor Yellow
    }
}

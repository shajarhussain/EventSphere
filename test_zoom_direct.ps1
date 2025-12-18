[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$accountId = "5poY8ijUQCuZmHZbmJhKYg"
$clientId = "gsvAR0HZSsyBous5eZMzQA"
$clientSecret = "3IbCHwH6hKLo9zizknZh98uyWZ88IORs"

Write-Host "1. Testing Zoom Authentication..." -ForegroundColor Cyan
$authString = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${clientId}:${clientSecret}"))
$headers = @{
    "Authorization" = "Basic $authString"
}

try {
    $tokenResponse = Invoke-RestMethod -Uri "https://zoom.us/oauth/token?grant_type=account_credentials&account_id=$accountId" -Method Post -Headers $headers
    $token = $tokenResponse.access_token
    if ($token) {
        Write-Host "   SUCCESS: Obtained Access Token" -ForegroundColor Green
    } else {
        Write-Host "   FAILURE: No access token in response" -ForegroundColor Red
        exit
    }
} catch {
    Write-Host "   FAILURE: Auth Request Failed" -ForegroundColor Red
    Write-Host "   $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
        Write-Host "   Details: $($reader.ReadToEnd())"
    }
    exit
}

Write-Host "`n2. Testing Meeting Creation..." -ForegroundColor Cyan
$meetingHeaders = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$body = @{
    topic = "PowerShell Connectivity Test"
    type = 2
    start_time = (Get-Date).AddMinutes(10).ToString("yyyy-MM-ddTHH:mm:ssZ")
    duration = 30
} | ConvertTo-Json

try {
    $meetingResponse = Invoke-RestMethod -Uri "https://api.zoom.us/v2/users/me/meetings" -Method Post -Headers $meetingHeaders -Body $body
    Write-Host "   Meeting ID: $($meetingResponse.id)"
    Write-Host "   Join URL: $($meetingResponse.join_url)"
    
    if ($meetingResponse.join_url) {
        Write-Host "   SUCCESS: Meeting Created with Join URL" -ForegroundColor Green
    } else {
        Write-Host "   FAILURE: Meeting created but no Join URL" -ForegroundColor Red
    }
} catch {
    Write-Host "   FAILURE: Meeting Creation Failed" -ForegroundColor Red
    Write-Host "   $_"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
        Write-Host "   Details: $($reader.ReadToEnd())"
    }
}

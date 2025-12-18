# Trust certificates
if (-not ([System.Management.Automation.PSTypeName]'System.Net.ServicePointManager').Type) {
    Add-Type -AssemblyName System.Net
}
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$baseUrl = "https://localhost:5001/api"
$headers = @{ "Content-Type" = "application/json" }

# Create a session
$session = $null

function Get-ActivityCount {
    try {
        $response = Invoke-WebRequest -Uri "$baseUrl/activities" -Method Get -Headers $headers -TimeoutSec 30 -WebSession $script:session -SessionVariable "session"
        $json = $response.Content | ConvertFrom-Json
        if ($json.data) { return $json.data.Count }
        if ($json.Count) { return $json.Count }
        return 0
    } catch {
        Write-Host "Failed to get count: $_" -ForegroundColor Yellow
        return -1
    }
}

Write-Host "Checking current activities..."
$count = Get-ActivityCount
Write-Host "Activities found: $count"

# If count failed, we might still want to try delete
if ($count -eq 0) {
    Write-Host "No activities to delete (or count failed)." -ForegroundColor Yellow
}

Write-Host "Deleting all activities (Timeout set to 300s)..."
try {
    # Use the session if established
    $response = Invoke-WebRequest -Uri "$baseUrl/activities/delete-all" -Method Delete -Headers $headers -TimeoutSec 300 -WebSession $session
    Write-Host "Delete response: $($response.StatusDescription)" -ForegroundColor Green
} catch {
    Write-Host "Delete request failed: $_" -ForegroundColor Red
    if ($_.Exception.Response) {
         $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
         Write-Host "Details: $($reader.ReadToEnd())"
    }
}

Write-Host "Verifying cleanup..."
$finalCount = Get-ActivityCount
if ($finalCount -eq 0) {
    Write-Host "SUCCESS: All activities deleted." -ForegroundColor Green
} else {
    Write-Host "WARNING: $finalCount activities still remain." -ForegroundColor Red
}

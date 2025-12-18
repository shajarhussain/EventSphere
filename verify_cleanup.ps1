# Trust all certificates
if (-not ([System.Management.Automation.PSTypeName]'System.Net.ServicePointManager').Type) {
    Add-Type -AssemblyName System.Net
}
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

$headers = @{ "Content-Type" = "application/json" }
$baseUrl = "https://localhost:5001/api"

# Login to get session
$email = "verify_$(Get-Random)@test.com"
$password = "Pa$$w0rd123!"

$registerBody = @{
    email = $email
    password = $password
    displayName = "Verifier"
    username = $email
} | ConvertTo-Json

try {
    Invoke-WebRequest -Uri "$baseUrl/account/register" -Method Post -Body $registerBody -Headers $headers | Out-Null
    Invoke-WebRequest -Uri "$baseUrl/login?useCookies=true" -Method Post -Body (@{ email=$email; password=$password } | ConvertTo-Json) -Headers $headers -SessionVariable "session" | Out-Null
} catch {
    Write-Host "Login failed, cannot verify."
    exit
}

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/activities" -Method Get -Headers $headers -WebSession $session
    $json = $response.Content | ConvertFrom-Json
    if ($json.data) { $count = $json.data.Count } else { $count = $json.Count }
    
    if ($count -eq 0) {
        Write-Host "CLEANUP VERIFIED: 0 activities found." -ForegroundColor Green
    } else {
        Write-Host "WARNING: $count activities remain." -ForegroundColor Yellow
        # Print titles if possible
        if ($json.data) { $json.data | ForEach-Object { Write-Host " - $($_.title)" } }
    }
} catch {
    Write-Host "Verify failed: $_"
}

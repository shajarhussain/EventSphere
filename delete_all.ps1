# Trust all certificates
if (-not ([System.Management.Automation.PSTypeName]'System.Net.ServicePointManager').Type) {
    Add-Type -AssemblyName System.Net
}
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

try {
    $response = Invoke-WebRequest -Uri "https://localhost:5001/api/activities/delete-all" -Method Delete
    Write-Host "Success: $($response.StatusDescription)"
} catch {
    Write-Host "Error: $_"
    if ($_.Exception.Response) {
         $reader = New-Object System.IO.StreamReader $_.Exception.Response.GetResponseStream()
         Write-Host "Details: $($reader.ReadToEnd())"
    }
}

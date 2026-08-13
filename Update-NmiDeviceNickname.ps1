<#
.SYNOPSIS
    Bulk-updates NMI Customer-Present Cloud POI Device nicknames.

.DESCRIPTION
    Calls NMI's Device Management API:
        POST https://secure.networkmerchants.com/api/v2/devices/update/{poiDeviceId}
    to set a new nickname on one or more registered POI devices (e.g. an
    Ingenico Link/2500 LE), without deregistering them.

.PARAMETER ApiKey
    Your NMI Merchant API (security) key. Sent as a Bearer token.

.PARAMETER Nickname
    The new nickname to apply to every device listed. Must be 1-20 characters:
    letters, numbers, spaces, hyphens, and underscores only (NMI's rule:
    ^[A-Za-z0-9-_ ]{1,20}$).

.PARAMETER DeviceId
    One or more POI Device IDs (GUIDs). Accepts:
      - a single ID:            -DeviceId "414b0420-b31c-4c76-9fc3-8a4f1a6dcffc"
      - multiple as an array:   -DeviceId "guid1","guid2"
      - a single comma-separated string: -DeviceId "guid1,guid2,guid3"

.PARAMETER BaseUrl
    Override the API base URL if needed (e.g. for a sandbox environment).
    Defaults to the production NMI endpoint.

.EXAMPLE
    .\Update-NmiDeviceNickname.ps1 -ApiKey "abc123" -Nickname "Front Counter" -DeviceId "414b0420-b31c-4c76-9fc3-8a4f1a6dcffc"

.EXAMPLE
    .\Update-NmiDeviceNickname.ps1 -ApiKey "abc123" -Nickname "Register 1" -DeviceId "guid1","guid2","guid3"

.NOTES
	Do not save the Merchant API Key in this file.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ApiKey,

    [Parameter(Mandatory = $true)]
    [string]$Nickname,

    [Parameter(Mandatory = $true)]
    [string[]]$DeviceId,

    [string]$BaseUrl = "https://secure.networkmerchants.com/api/v2/devices/update"
)

#Check DeviceId input: allows comma-separated strings, arrays, or a mix ---
$DeviceId = $DeviceId |
    ForEach-Object { $_ -split ',' } |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne '' }

if ($DeviceId.Count -eq 0) {
    Write-Error "No device IDs provided."
    exit 1
}

#Verify nickname against NMI's allowed format
if ($Nickname -notmatch '^[A-Za-z0-9\-_ ]{1,20}$') {
    Write-Error "Nickname '$Nickname' is invalid. It must be 1-20 characters: letters, numbers, spaces, hyphens, and underscores only."
    exit 1
}

Write-Host "Updating $($DeviceId.Count) device(s) to nickname '$Nickname'..." -ForegroundColor Cyan
Write-Host ""

$headers = @{
    Authorization  = "Bearer $ApiKey"
    "Content-Type" = "application/json"
}
$body = @{ deviceNickname = $Nickname } | ConvertTo-Json -Compress

$results = foreach ($id in $DeviceId) {

    $row = [ordered]@{
        DeviceId = $id
        Success  = $false
        Message  = ""
    }

    $uri = "$BaseUrl/$id"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ErrorAction Stop

        if ($response.success -eq $true) {
            $row.Success = $true
            $row.Message = "OK"
        }
        else {
            $row.Message = "API responded without success=true: $($response | ConvertTo-Json -Compress)"
        }
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            try { $statusCode = [int]$_.Exception.Response.StatusCode } catch {}
        }

        # Works on PowerShell 7+ (Invoke-RestMethod populates ErrorDetails.Message)
        $errorBody = $_.ErrorDetails.Message

        # Fallback for Windows PowerShell 5.1
        if (-not $errorBody -and $_.Exception.Response) {
            try {
                $stream = $_.Exception.Response.GetResponseStream()
                $reader = New-Object System.IO.StreamReader($stream)
                $errorBody = $reader.ReadToEnd()
            } catch {}
        }

        $row.Message = "HTTP $statusCode - $($_.Exception.Message)"
        if ($errorBody) { $row.Message += " | $errorBody" }
    }

    [PSCustomObject]$row
}

$results | Format-Table -AutoSize

$failCount = ($results | Where-Object { -not $_.Success }).Count
Write-Host ""
if ($failCount -gt 0) {
    Write-Warning "$failCount of $($results.Count) update(s) failed. See table above."
    exit 1
}
else {
    Write-Host "All $($results.Count) device(s) updated successfully." -ForegroundColor Green
    exit 0
}

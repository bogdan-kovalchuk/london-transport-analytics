param(
    [Parameter(Mandatory = $true)]
    [string]$CredentialsPath
)

if (-not (Test-Path $CredentialsPath)) {
    throw "Credentials file not found: $CredentialsPath"
}

$resolved = (Resolve-Path $CredentialsPath).Path
$env:GOOGLE_APPLICATION_CREDENTIALS = $resolved

Write-Host "GOOGLE_APPLICATION_CREDENTIALS set to $resolved"

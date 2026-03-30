param(
    [switch]$InstallDocker,
    [switch]$InstallDashboardDeps
)

$ErrorActionPreference = "Stop"

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    $packageAlreadyInstalled = winget list --id $Id --exact 2>$null | Select-String -Pattern $Id -Quiet
    if ($packageAlreadyInstalled) {
        Write-Host "$Name is already installed."
        return
    }

    Write-Host "Installing $Name..."
    winget install --id $Id --source winget --accept-source-agreements --accept-package-agreements
}

Install-WingetPackage -Id "Hashicorp.Terraform" -Name "Terraform"
Install-WingetPackage -Id "Google.CloudSDK" -Name "Google Cloud SDK"

if ($InstallDocker) {
    Install-WingetPackage -Id "Docker.DockerDesktop" -Name "Docker Desktop"
}

if ($InstallDashboardDeps) {
    if (-not (Test-Path ".venv")) {
        Write-Host "Creating Python virtual environment..."
        python -m venv .venv
    }

    Write-Host "Installing dashboard dependencies..."
    & ".\.venv\Scripts\python.exe" -m pip install --upgrade pip
    & ".\.venv\Scripts\python.exe" -m pip install -r "dashboard\requirements.txt"
}

Write-Host ""
Write-Host "Bootstrap finished."
Write-Host "If Terraform or gcloud are still not available in the current terminal, open a new shell window."
Write-Host "Docker Desktop may still require manual first-run setup and a restart."

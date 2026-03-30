$ErrorActionPreference = "Stop"

function Resolve-CommandPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName,
        [string[]]$FallbackPatterns = @()
    )

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    foreach ($pattern in $FallbackPatterns) {
        $match = Get-ChildItem -Path $pattern -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 1 -ExpandProperty FullName
        if ($match) {
            return $match
        }
    }

    return $null
}

$tools = @(
    @{
        Name = "Python"
        Command = "python"
        VersionArgs = "--version"
        Required = $true
        FallbackPatterns = @()
    },
    @{
        Name = "Terraform"
        Command = "terraform"
        VersionArgs = "version"
        Required = $true
        FallbackPatterns = @("$env:LOCALAPPDATA\Microsoft\WinGet\Packages\**\terraform.exe")
    },
    @{
        Name = "Google Cloud SDK"
        Command = "gcloud"
        VersionArgs = "--version"
        Required = $true
        FallbackPatterns = @("$env:LOCALAPPDATA\Google\Cloud SDK\**\gcloud.cmd")
    },
    @{
        Name = "Docker"
        Command = "docker"
        VersionArgs = "--version"
        Required = $true
        FallbackPatterns = @(
            "C:\Program Files\Docker\Docker\resources\bin\docker.exe",
            "$env:LOCALAPPDATA\Programs\Docker\Docker\resources\bin\docker.exe"
        )
    }
)

$results = foreach ($tool in $tools) {
    $path = Resolve-CommandPath -CommandName $tool.Command -FallbackPatterns $tool.FallbackPatterns
    $status = if ($path) { "Found" } else { "Missing" }
    $version = ""

    if ($path) {
        try {
            if ($tool.Command -eq "gcloud") {
                $version = (& $path $tool.VersionArgs | Select-Object -First 1).Trim()
            }
            else {
                $version = (& $path $tool.VersionArgs | Select-Object -First 1).Trim()
            }
        }
        catch {
            $version = "Detected, but version lookup failed"
        }
    }

    [PSCustomObject]@{
        Tool    = $tool.Name
        Status  = $status
        Path    = $path
        Version = $version
    }
}

$results | Format-Table -AutoSize

$missingRequired = $results | Where-Object { $_.Status -eq "Missing" }
if ($missingRequired) {
    Write-Host ""
    Write-Host "Missing tools detected. Run scripts\bootstrap_windows.ps1 and reopen the shell if needed."
    exit 1
}

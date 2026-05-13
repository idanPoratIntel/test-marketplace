# VDC CLI Installer (Windows x64)
# Downloads the VDC CLI executable from Intel Artifactory and places it in
# %USERPROFILE%\bin, adding that directory to the user PATH if needed.
#
# Usage:  powershell -ExecutionPolicy Bypass -File install-vdc.ps1
# Requires: Intel network or VPN access (af01p-fm.devtools.intel.com)

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

$ArtifactoryUrl = 'https://af01p-fm.devtools.intel.com/artifactory/vdc-client-fm-local/vdc/cli/prod/win-x64/vdc.exe'
$InstallDir     = Join-Path $env:USERPROFILE 'bin'
$DestExe        = Join-Path $InstallDir 'vdc.exe'

# Ensure install directory exists
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir | Out-Null
}

Write-Host "Downloading VDC CLI from $ArtifactoryUrl ..."
try {
    Invoke-WebRequest -Uri $ArtifactoryUrl -OutFile $DestExe
} catch {
    Write-Error "Failed to download VDC CLI: $_"
    exit 1
}

# Add install dir to user PATH if not already present
$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable('PATH', "$userPath;$InstallDir", 'User')
    Write-Host "Added '$InstallDir' to user PATH." -ForegroundColor Cyan
    # Also update current session PATH so vdc is immediately available
    $env:PATH = "$env:PATH;$InstallDir"
}

# Verify
$ver = & $DestExe --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "VDC CLI verification failed: $ver"
    exit 1
}

Write-Host "VDC CLI $ver installed successfully to $DestExe" -ForegroundColor Green
Write-Host "Run 'vdc --version' (in a new terminal if PATH was just updated) to confirm."

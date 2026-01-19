# Simple installation script for GitMergeWorkflow module

$moduleName = "GitMergeWorkflow"
$currentUserModules = [System.IO.Path]::Combine($env:USERPROFILE, "Documents", "WindowsPowerShell", "Modules")
$destPath = Join-Path $currentUserModules $moduleName

Write-Host "Installing $moduleName to $destPath..." -ForegroundColor Cyan

# Create modules directory if it doesn't exist
if (-not (Test-Path $currentUserModules)) {
    New-Item -Path $currentUserModules -ItemType Directory -Force | Out-Null
}

# Copy module files
$scriptPath = $PSScriptRoot
if (-not $scriptPath) { $scriptPath = Get-Location }

if (Test-Path $destPath) {
    Write-Warning "Module already exists. Updating..."
    Remove-Item $destPath -Recurse -Force
}

Copy-Item -Path $scriptPath -Destination $destPath -Recurse -Force

# Verify installation
if (Test-Path (Join-Path $destPath "$moduleName.psd1")) {
    Write-Host "Installation successful!" -ForegroundColor Green
    Write-Host "You can now run: Import-Module $moduleName" -ForegroundColor Yellow
} else {
    Write-Error "Installation failed."
}

param(
    [string]$SourcePath = "c:\Program Files\Odoo 17.0.20250930\Odoo 18.0.20250930\custom",
    [string]$DestinationPath = "$PSScriptRoot\..\addons"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Syncing Odoo custom addons" -ForegroundColor Cyan
Write-Host " Source     : $SourcePath" -ForegroundColor Yellow
Write-Host " Destination: $DestinationPath" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan

if (-not (Test-Path -Path $SourcePath)) {
    Write-Error "Source path not found: $SourcePath"
    exit 1
}

if (-not (Test-Path -Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath | Out-Null
}

# Remove existing destination content (but leave folder)
Get-ChildItem -Path $DestinationPath -Force | Remove-Item -Recurse -Force

# Copy each addon directory
Get-ChildItem -Path $SourcePath -Directory | ForEach-Object {
    $addonName = $_.Name
    Write-Host "Copying addon: $addonName" -ForegroundColor Green
    Copy-Item -Path $_.FullName -Destination (Join-Path $DestinationPath $addonName) -Recurse -Force
}

# Remove Python cache artefacts to keep the Docker context clean
Get-ChildItem -Path $DestinationPath -Recurse -Include '__pycache__' -Directory | ForEach-Object {
    Remove-Item -Path $_.FullName -Recurse -Force
}
Get-ChildItem -Path $DestinationPath -Recurse -Include '*.pyc','*.pyo' | Remove-Item -Force

Write-Host "All addons have been synced." -ForegroundColor Green

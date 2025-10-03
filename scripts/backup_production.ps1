param(
    [string]$RailwayUrl = "https://aatco-crm-erp-production.up.railway.app",
    [string]$MasterPassword = "",
    [string]$DatabaseName = "aatco",
    [string]$BackupDir = "$env:USERPROFILE\odoo_backups"
)

if ([string]::IsNullOrEmpty($MasterPassword)) {
    $MasterPassword = Read-Host "Enter Railway ADMIN_PASSWORD" -AsSecureString
    $MasterPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($MasterPassword)
    )
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $BackupDir "backup_${DatabaseName}_${timestamp}.zip"

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Backing up production Odoo database" -ForegroundColor Cyan
Write-Host " URL: $RailwayUrl" -ForegroundColor Yellow
Write-Host " Database: $DatabaseName" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    $body = @{
        master_pwd = $MasterPassword
        name = $DatabaseName
        backup_format = "zip"
    }
    
    Write-Host "Requesting backup from server..." -ForegroundColor Green
    Invoke-WebRequest -Uri "$RailwayUrl/web/database/backup" -Method Post -Body $body -OutFile $backupFile
    
    $size = (Get-Item $backupFile).Length / 1MB
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Backup completed successfully!" -ForegroundColor Green
    Write-Host " File: $backupFile" -ForegroundColor Yellow
    Write-Host " Size: $([math]::Round($size, 2)) MB" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Green
    
} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host " Backup failed!" -ForegroundColor Red
    Write-Host " Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Red
    exit 1
}

# Clean up old backups (keep last 30 days)
Write-Host ""
Write-Host "Cleaning old backups (keeping last 30 days)..." -ForegroundColor Cyan
Get-ChildItem -Path $BackupDir -Filter "backup_*.zip" | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    ForEach-Object {
        Write-Host "Deleting: $($_.Name)" -ForegroundColor DarkGray
        Remove-Item $_.FullName
    }

Write-Host "Done." -ForegroundColor Green

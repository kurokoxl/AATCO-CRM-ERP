# Deployment Verification Script for Windows
# Run this to verify all deployment files are properly configured

Write-Host ""
Write-Host "Verifying Railway Deployment Configuration..." -ForegroundColor Cyan
Write-Host ""

$script:Errors = 0
$script:Warnings = 0

function Test-FileExists {
    param($Path, $Name)
    if (Test-Path $Path) {
        Write-Host "OK $Name exists" -ForegroundColor Green
        return $true
    } else {
        Write-Host "ERR $Name is missing" -ForegroundColor Red
        $script:Errors++
        return $false
    }
}

function Test-FileNotEmpty {
    param($Path, $Name)
    if ((Test-Path $Path) -and (Get-Content $Path -ErrorAction SilentlyContinue)) {
        Write-Host "OK $Name has content" -ForegroundColor Green
        return $true
    } else {
        Write-Host "ERR $Name is empty" -ForegroundColor Red
        $script:Errors++
        return $false
    }
}

function Test-FileContains {
    param($Path, $Pattern, $Description)
    if (Test-Path $Path) {
        $content = Get-Content $Path -Raw -ErrorAction SilentlyContinue
        if ($content -match $Pattern) {
            Write-Host "OK $Description" -ForegroundColor Green
            return $true
        } else {
            Write-Host "WARN $Description might be missing" -ForegroundColor Yellow
            $script:Warnings++
            return $false
        }
    } else {
        Write-Host "ERR File not found for checking: $Path" -ForegroundColor Red
        $script:Errors++
        return $false
    }
}

# Set location to deployment folder
$DeploymentPath = "c:\Program Files\Odoo 17.0.20250930\deployment\railway"
if (Test-Path $DeploymentPath) {
    Set-Location $DeploymentPath
} else {
    Write-Host "✗ Deployment folder not found: $DeploymentPath" -ForegroundColor Red
    exit 1
}

Write-Host "Checking Required Files..." -ForegroundColor Yellow
Test-FileExists "Dockerfile" "Dockerfile"
Test-FileExists "entrypoint.sh" "entrypoint.sh"
Test-FileExists "odoo.conf.template" "odoo.conf.template"
Test-FileExists "requirements.txt" "requirements.txt"
Test-FileExists ".dockerignore" ".dockerignore"
Test-FileExists "railway.json" "railway.json"
Write-Host ""

Write-Host "Checking File Contents..." -ForegroundColor Yellow
Test-FileNotEmpty "Dockerfile" "Dockerfile"
Test-FileNotEmpty "entrypoint.sh" "entrypoint.sh"
Test-FileNotEmpty "odoo.conf.template" "odoo.conf.template"
Test-FileNotEmpty ".dockerignore" ".dockerignore"
Write-Host ""

Write-Host "Checking Configuration..." -ForegroundColor Yellow
Test-FileContains "odoo.conf.template" "db_host" "odoo.conf.template contains db_host"
Test-FileContains "odoo.conf.template" "admin_passwd" "odoo.conf.template contains admin_passwd"
Test-FileContains "odoo.conf.template" "addons_path" "odoo.conf.template contains addons_path"
Write-Host ""

Write-Host "Checking Dockerfile..." -ForegroundColor Yellow
Test-FileContains "Dockerfile" "FROM odoo:18.0" "Dockerfile has correct base image"
Test-FileContains "Dockerfile" "COPY addons /mnt/extra-addons" "Dockerfile copies addons"
Test-FileContains "Dockerfile" "ENTRYPOINT" "Dockerfile has ENTRYPOINT"
Write-Host ""

Write-Host "Checking Entrypoint..." -ForegroundColor Yellow
Test-FileContains "entrypoint.sh" "#!/bin/bash" "entrypoint.sh has bash shebang"

# Check if entrypoint has the old exit 0 bug
$entrypoint = Get-Content "entrypoint.sh" -Raw -ErrorAction SilentlyContinue
if ($entrypoint -match 'DO_INIT_DB.*exit 0' -and $entrypoint -notmatch 'Starting Odoo server') {
    Write-Host "ERR entrypoint.sh still exits after DB init (OLD VERSION)" -ForegroundColor Red
    $script:Errors++
} else {
    Write-Host "OK entrypoint.sh continues after DB init (FIXED)" -ForegroundColor Green
}
Write-Host ""

Write-Host "Checking Custom Addons..." -ForegroundColor Yellow
if (Test-Path "addons/fieldservice_navigate") {
    Write-Host "OK Custom addon 'fieldservice_navigate' found" -ForegroundColor Green
    if (Test-Path "addons/fieldservice_navigate/__manifest__.py") {
        Write-Host "OK Manifest file exists" -ForegroundColor Green
    } else {
        Write-Host "ERR Manifest file missing" -ForegroundColor Red
        $script:Errors++
    }
} else {
    Write-Host "WARN Custom addon directory not found" -ForegroundColor Yellow
    $script:Warnings++
}
Write-Host ""

Write-Host ""
Write-Host "Verification Summary" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($script:Errors -eq 0 -and $script:Warnings -eq 0) {
    Write-Host "SUCCESS: All checks passed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your deployment is ready for Railway." -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. git add ."
    Write-Host "  2. git commit -m 'Fix Railway deployment'"
    Write-Host "  3. git push"
    Write-Host "  4. Set environment variables in Railway"
    Write-Host "  5. Deploy!"
    Write-Host ""
    exit 0
} elseif ($script:Errors -eq 0) {
    Write-Host "WARNING: $($script:Warnings) warning(s) found" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Review warnings above. You may still be able to deploy." -ForegroundColor Yellow
    Write-Host ""
    exit 0
} else {
    Write-Host "ERROR: $($script:Errors) error(s) found" -ForegroundColor Red
    if ($script:Warnings -gt 0) {
        Write-Host "WARNING: $($script:Warnings) warning(s) found" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Please fix the errors above before deploying." -ForegroundColor Red
    Write-Host ""
    exit 1
}

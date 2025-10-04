# Deploy Field Service Navigate Module to Railway
# This script commits and pushes the custom module to trigger Railway deployment

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Field Service Navigate Module Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Navigate to railway directory
Set-Location "c:\Program Files\Odoo 17.0.20250930\deployment\railway"

Write-Host "[1/5] Checking current status..." -ForegroundColor Yellow
git status --short

Write-Host ""
Write-Host "[2/5] Staging Field Service Navigate module..." -ForegroundColor Yellow
git add addons/fieldservice_navigate
git add DEPLOY_FIELDSERVICE_NAVIGATE.md

Write-Host ""
Write-Host "[3/5] Committing changes..." -ForegroundColor Yellow
git commit -m "Add Field Service Navigate custom module for AATCO"

Write-Host ""
Write-Host "[4/5] Pushing to GitHub (Railway will auto-deploy)..." -ForegroundColor Yellow
git push origin main

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "✓ Deployment initiated!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Wait 2-3 minutes for Railway to rebuild and redeploy" -ForegroundColor White
Write-Host "2. Go to: https://aatco-crm-erp-production.up.railway.app/web#action=base.open_module_tree" -ForegroundColor White
Write-Host "3. Click Update Apps List (⚙️ icon → Update Apps List)" -ForegroundColor White
Write-Host "4. Search for 'field service navigate'" -ForegroundColor White
Write-Host "5. Click 'Install'" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: You need to install 'Field Service' (base module) FIRST" -ForegroundColor Yellow
Write-Host "if you haven't already. The Navigate module depends on it." -ForegroundColor Yellow
Write-Host ""
Write-Host "See DEPLOY_FIELDSERVICE_NAVIGATE.md for detailed instructions." -ForegroundColor Cyan
Write-Host ""

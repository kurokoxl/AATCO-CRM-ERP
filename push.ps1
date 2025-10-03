Set-Location 'c:\Program Files\Odoo 17.0.20250930\deployment\railway'
git add entrypoint.sh
git commit -m "entrypoint: set ODOO_SKIP_PG_USER_CHECK to bypass postgres user security check"
git push origin main
Write-Host "`n✓ Pushed to GitHub. Railway will rebuild in ~30-45 seconds."
Write-Host "`nCheck: https://aatco-crm-erp-production.up.railway.app"

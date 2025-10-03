# Complete AATCO Database Restore to Railway
# Run this after the initial dump has been loaded via `railway connect Postgres`

Write-Host "Step 1: Reconnecting to Railway Postgres..." -ForegroundColor Cyan
$env:PATH += ";C:\Program Files\Odoo 17.0.20250930\Odoo 18.0.20250930\PostgreSQL\bin"

Write-Host "`nStep 2: Applying ownership and permissions..." -ForegroundColor Cyan
Write-Host "You'll need to run these SQL commands in the Railway psql session:" -ForegroundColor Yellow
Write-Host ""
Write-Host @"
\c railway
\set DB_NAME railway
\set DB_OWNER odoo_user
\i 'C:/Program Files/Odoo 17.0.20250930/deployment/railway/fix_permissions.sql'

-- Verify tables were restored
SELECT count(*) as table_count FROM information_schema.tables 
WHERE table_schema = 'public' AND table_type = 'BASE TABLE';

-- Check if key Odoo tables exist
SELECT EXISTS (SELECT FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'res_users') as has_users;

\q
"@ -ForegroundColor Green

Write-Host "`nStep 3: Update Railway environment variables..." -ForegroundColor Cyan
Write-Host "Run these commands:" -ForegroundColor Yellow
Write-Host @"
railway variables --set "PGDATABASE=railway"
railway variables --set "ODOO_DB_FILTER=^railway$"
railway variables --set "ODOO_LIST_DB=false"
railway variables --set "ODOO_INIT_DB=false"
railway up
"@ -ForegroundColor Green

Write-Host "`nPress Enter to open Railway Postgres connection..." -ForegroundColor Cyan
Read-Host

railway connect Postgres

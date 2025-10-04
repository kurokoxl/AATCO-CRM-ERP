# 🔴 Database Not Initialized - Quick Fix

## Current Issue

Your logs show:
```
ERROR railway odoo.modules.loading: Database railway not initialized, you can force it with `-i base`
KeyError: 'ir.http'
```

**What this means:** The database `railway` exists but has no Odoo tables/modules installed.

## ✅ Quick Fix - Set Environment Variable

### In Railway Dashboard:

1. Go to your **Odoo service**
2. Click **Variables** tab
3. Add or change this variable:

```bash
ODOO_INIT_DB=true
```

4. **Save** (Railway will automatically redeploy)

### What Will Happen:

When Railway redeploys with `ODOO_INIT_DB=true`:

1. ✅ Container starts
2. ✅ Database `railway` is found
3. ✅ Permissions are set
4. ✅ **Odoo initializes with base module** (~2-3 minutes)
5. ✅ Odoo server starts normally
6. ✅ You can access Odoo!

### Expected Logs (Success):

```
[INFO] DO_INIT_DB is True — initializing database by running 'odoo -i base --stop-after-init' as current user
2025-10-04 15:xx:xx,xxx odoo: Odoo version 18.0-20250930
2025-10-04 15:xx:xx,xxx odoo.modules.loading: init db
2025-10-04 15:xx:xx,xxx odoo.modules.loading: loading 1 modules...
2025-10-04 15:xx:xx,xxx odoo.modules.loading: Loading module base (1/1)
...
[INFO] Database initialization complete. Starting Odoo server...
2025-10-04 15:xx:xx,xxx odoo.service.server: HTTP service (werkzeug) running on 0.0.0.0:8069
```

## After First Successful Start

Once Odoo is running and you can access it:

1. **Change the variable back:**
   ```bash
   ODOO_INIT_DB=false
   ```

2. From then on, Odoo will just start normally without re-initializing.

## Why This Happened

The database was created by the provisioning script, but Odoo needs to be explicitly told to initialize it with the base module on first run. The `ODOO_INIT_DB=true` flag tells the entrypoint script to run:

```bash
odoo -i base --stop-after-init
```

Then it continues to start the server normally.

## Summary

**Action needed RIGHT NOW:**
1. Set `ODOO_INIT_DB=true` in Railway
2. Wait ~5 minutes for initialization
3. Access your Odoo
4. Change to `ODOO_INIT_DB=false`
5. Done! ✅

---

**This is a normal first-deployment step!** The database exists, it just needs Odoo's base module installed.

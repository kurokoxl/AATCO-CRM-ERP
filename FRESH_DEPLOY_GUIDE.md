# 🎯 Fresh Odoo 18 Deployment on Railway - FIXED!

## ✅ Problem Solved!

The error `CREATE DATABASE cannot be executed from a function` has been fixed.

### What Was Wrong:
PostgreSQL doesn't allow `CREATE DATABASE` commands inside `DO` blocks (PL/pgSQL functions). The original script tried to create the database inside a function, which caused the error.

### What Was Fixed:
- ✅ Moved `CREATE DATABASE` outside the DO block
- ✅ Split provisioning into 4 clear steps
- ✅ Added database existence check
- ✅ Improved error messages and logging
- ✅ Simplified permissions setup

## 🚀 Deploy Fresh Odoo 18 on Railway

### Step 1: Railway Setup

1. **Create New Project** on Railway
2. **Add PostgreSQL Plugin** (Railway will create an empty database named "railway")
3. **Deploy from GitHub**:
   - Select your repository: `kurokoxl/AATCO-CRM-ERP`
   - Root directory: `deployment/railway`
   - Railway will auto-detect the Dockerfile

### Step 2: Environment Variables

In Railway Dashboard → Your Service → Variables, set:

```bash
# REQUIRED - Set a strong admin password
ADMIN_PASSWORD=YourSuperSecurePassword123!@#

# For fresh deployment with NEW database
ODOO_INIT_DB=true

# Security settings
ODOO_LIST_DB=false
ODOO_AUTO_PROVISION_DB_USER=true
ODOO_DB_FILTER=^railway$

# Database name (Railway's default PostgreSQL database)
DB_NAME=railway

# Application user (will be created automatically)
ODOO_APP_DB_USER=odoo_user
```

**Note**: Railway automatically provides these (don't set them):
- `PGHOST` - PostgreSQL host
- `PGPORT` - PostgreSQL port (5432)
- `PGUSER` - PostgreSQL superuser (postgres)
- `PGPASSWORD` - PostgreSQL password
- `PGDATABASE` - Default database name (railway)

### Step 3: Deploy!

Once you push to GitHub or trigger a manual deploy in Railway:

1. Railway builds the Docker image (~3-5 minutes)
2. Container starts
3. **Entrypoint script will:**
   - ✅ Create `odoo_user` role
   - ✅ Use existing `railway` database (or create if needed)
   - ✅ Set proper ownership and permissions
   - ✅ Initialize Odoo with base module
   - ✅ Start Odoo server

### Step 4: First Deployment (With ODOO_INIT_DB=true)

**What happens:**
```
[INFO] Creating/updating application role...
✓ Created new role: odoo_user

[INFO] Checking database 'railway'...
✓ Database 'railway' already exists. Setting owner...
✓ Database owner updated.

[INFO] Granting connection privileges...
✓ Permissions configured successfully.

[INFO] DO_INIT_DB is True — initializing database...
✓ Database initialization complete. Starting Odoo server...

Odoo version 18.0-20250930
HTTP service running on 0.0.0.0:8069
```

**Timeline**: ~2-3 minutes for DB initialization

### Step 5: After First Deployment

Once Odoo is running:

1. **Change `ODOO_INIT_DB` to `false`** in Railway variables
2. Save (Railway will redeploy automatically)
3. From now on, Odoo will just start normally without re-initializing

### Step 6: Access Your Odoo

- **URL**: Check Railway dashboard for your app URL (e.g., `https://your-app.railway.app`)
- **Username**: `admin`
- **Password**: Whatever you set in `ADMIN_PASSWORD`

## 📊 Expected Logs (Success)

```log
DEBUG: Railway Environment Variables:
  PGHOST = postgres.railway.internal
  PGPORT = 5432
  PGUSER = postgres
  PGDATABASE = railway

[INFO] Provisioning dedicated application role 'odoo_user'...
[INFO] Creating/updating application role...
NOTICE: Created new role: odoo_user
DO

[INFO] Checking database 'railway'...
[INFO] Database 'railway' already exists. Setting owner...
ALTER DATABASE
[INFO] Database owner updated.

[INFO] Granting connection privileges...
GRANT

[INFO] Setting up permissions on database 'railway'...
GRANT
GRANT
GRANT
GRANT
ALTER DEFAULT PRIVILEGES
[INFO] Permissions configured successfully.

[INFO] Application role 'odoo_user' is ready.

Starting Odoo (attempting to drop privileges if possible)...
[INFO] DO_INIT_DB is True — initializing database...
2025-10-04 15:xx:xx,xxx odoo: Odoo version 18.0-20250930
2025-10-04 15:xx:xx,xxx odoo: database: odoo_user@postgres.railway.internal:5432
2025-10-04 15:xx:xx,xxx odoo.modules.loading: init db
2025-10-04 15:xx:xx,xxx odoo.modules.loading: loading 1 modules...
2025-10-04 15:xx:xx,xxx odoo.modules.loading: Loading module base (1/1)
...
[INFO] Database initialization complete. Starting Odoo server...
2025-10-04 15:xx:xx,xxx odoo: HTTP service running on 0.0.0.0:8069
```

## 🎯 Database Architecture

```
┌─────────────────────────────────────────────┐
│         Railway PostgreSQL                  │
├─────────────────────────────────────────────┤
│                                              │
│  Database: railway                          │
│  ├─ Owner: odoo_user (created automatically)│
│  ├─ Schema: public                          │
│  └─ Encoding: UTF8                          │
│                                              │
│  Roles:                                     │
│  ├─ postgres (superuser, for provisioning)  │
│  └─ odoo_user (app user, for Odoo)         │
│                                              │
└─────────────────────────────────────────────┘
```

## 🔧 Troubleshooting

### "Database already exists" (Not an error!)
✅ This is normal. The script detects the existing Railway database and just sets the correct owner.

### Container still exiting?
- Verify `ODOO_INIT_DB=true` for first deploy
- Check `ADMIN_PASSWORD` is set
- Review Railway logs for specific errors

### Can't login?
- Ensure `ADMIN_PASSWORD` environment variable is set
- Default username is `admin`

### "Permission denied" errors?
- The script now handles all permissions automatically
- Both postgres and odoo_user can create objects

## 📝 Post-Deployment Checklist

After first successful deployment:

- [ ] Set `ODOO_INIT_DB=false`
- [ ] Access Odoo web interface
- [ ] Login with admin credentials
- [ ] Install additional modules as needed
- [ ] Configure company settings
- [ ] Set up users and permissions

## 🔐 Production Recommendations

- [ ] Use strong `ADMIN_PASSWORD`
- [ ] Keep `ODOO_LIST_DB=false`
- [ ] Set up custom domain
- [ ] Enable Railway backups
- [ ] Configure email settings in Odoo
- [ ] Set up monitoring

## 🎉 You're Ready!

Your Odoo 18 will deploy with a fresh, clean PostgreSQL database on Railway. The entrypoint script handles all the complex setup automatically.

**Next**: Just push your code and Railway will deploy everything! 🚀

---

**Status**: ✅ Fixed and Ready
**Tested**: PostgreSQL CREATE DATABASE error resolved
**Last Updated**: October 4, 2025

# Quick Deployment Guide

## 🚀 Deploy to Railway - Quick Steps

### 1️⃣ Commit Changes
```powershell
cd "c:\Program Files\Odoo 17.0.20250930"
git add deployment/railway/
git commit -m "Fix Railway deployment configuration"
git push origin main
```

### 2️⃣ Railway Environment Variables
In Railway Dashboard → Your Odoo Service → Variables, set:

```bash
# REQUIRED - Set this to a strong password!
ADMIN_PASSWORD=your-super-secure-password-here

# Database already initialized, so set to false
ODOO_INIT_DB=false

# Security - disable database manager in production
ODOO_LIST_DB=false

# These are auto-set by Railway Postgres plugin:
# PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE
```

### 3️⃣ Deploy
Railway will automatically:
1. Build Docker image
2. Connect to Postgres
3. Start Odoo server
4. Expose via HTTPS

### 4️⃣ Access Your Odoo
- URL: `https://your-app.railway.app`
- Username: `admin`
- Password: (whatever you set for ADMIN_PASSWORD)

## 🔍 What Was Fixed

| Issue | Status |
|-------|--------|
| Empty `odoo.conf.template` | ✅ Created complete config |
| Container exits after DB init | ✅ Fixed entrypoint.sh |
| Empty `.dockerignore` | ✅ Added proper exclusions |
| Empty `requirements.txt` | ✅ Added dependencies |
| DB name mismatch | ✅ Fixed to use "railway" |

## 📊 Expected Deployment Time

- Build: ~3-5 minutes
- Deploy: ~30 seconds
- Total: ~5 minutes

## ✅ Verify Deployment

After deployment, check:
1. Service shows "Active" in Railway
2. Can access URL without errors
3. Login page loads
4. Can login with admin credentials

## 🆘 Troubleshooting

**Container keeps restarting?**
- Set `ODOO_INIT_DB=false`

**Can't login?**
- Check ADMIN_PASSWORD is set
- Try resetting password via Railway shell

**Module not found?**
- Verify addon is in `deployment/railway/addons/`
- Check Dockerfile copied it

**Database errors?**
- Ensure Postgres plugin is linked
- Check environment variables are present

## 📝 Next Steps After Deployment

1. **Install Custom Modules**:
   - Go to Apps menu
   - Search for "Field Service Navigate"
   - Click Install

2. **Configure Settings**:
   - Setup company information
   - Configure email settings
   - Set up users and permissions

3. **Import Data** (if needed):
   - Use Odoo's import feature
   - Or restore from backup

## 🔐 Security Checklist

- [ ] Changed ADMIN_PASSWORD from default
- [ ] Set ODOO_LIST_DB to "false"
- [ ] Configured custom domain with SSL
- [ ] Set up 2FA for admin users
- [ ] Regular database backups enabled
- [ ] Restricted database access

---

**Need Help?** Check `DEPLOYMENT_FIXES.md` for detailed information.

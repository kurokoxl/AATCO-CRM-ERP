# How to Add Railway Volume for Filestore Persistence

## Important: Railway Volume Setup

Railway **bans** the `VOLUME` keyword in Dockerfiles. You must create volumes through Railway's dashboard instead.

---

## ⚠️ Current Limitation

**Without a Railway volume**, uploaded files (images, attachments, etc.) will be **lost on each deployment**.

This means:
- Company logos will disappear after restart
- Uploaded documents will be lost
- Report templates will be reset
- Any file attachments in records will vanish

---

## 🔧 How to Add a Railway Volume

### Option A: Via Railway Dashboard (Easiest)

1. Go to your Railway project: https://railway.app/project/[your-project-id]
2. Click on your **AATCO-CRM-ERP** service
3. Go to the **"Settings"** tab
4. Scroll down to **"Volumes"** section
5. Click **"+ New Volume"**
6. Configure the volume:
   - **Mount Path**: `/var/lib/odoo`
   - **Size**: 1GB (adjust based on your needs)
7. Click **"Add"**
8. Railway will redeploy automatically

### Option B: Via Railway CLI

```bash
# Install Railway CLI if you haven't
npm i -g @railway/cli

# Login to Railway
railway login

# Link to your project
railway link

# Create volume
railway volume create --name odoo-filestore --mount /var/lib/odoo

# Redeploy
railway up
```

---

## 📊 After Adding Volume

Once the volume is added:

✅ **Filestore will persist** across deployments  
✅ **Uploaded files will survive** container restarts  
✅ **Database attachments** will work correctly  
✅ **No more FileNotFoundError** messages

---

## 🧪 Testing File Persistence

After adding the volume:

1. **Login to your Odoo instance**
2. **Go to Settings > Companies**
3. **Upload a company logo**
4. **Save the company**
5. **Trigger a redeploy** in Railway dashboard
6. **Check if logo still appears** after restart

✅ If logo persists → Volume is working!  
❌ If logo disappears → Volume not properly configured

---

## 💾 Volume Storage Notes

- **Railway Free Tier**: No persistent volumes
- **Hobby Plan**: 5GB included storage
- **Pro Plan**: 10GB included storage
- **Additional storage**: Charged per GB

Check your plan limits: https://railway.app/pricing

---

## 🔄 Alternative: Database-Only Storage

If you can't add a volume, you can configure Odoo to store files in the database instead:

**In Railway Environment Variables, add:**
```
ODOO_STORE_ATTACHMENTS_ON_FILESYSTEM=false
```

**Or update entrypoint.sh to add to odoo.conf:**
```ini
data_dir = /tmp/odoo
```

⚠️ **Warning**: Database storage:
- Increases database size significantly
- Slower performance for large files
- Makes backups larger
- Not recommended for production

---

## 🚀 Recommended Setup

For production Railway deployment:

1. ✅ **Add Railway volume** for `/var/lib/odoo`
2. ✅ **Keep current fixes** (WebSocket disabled, health checks)
3. ✅ **Use Hobby plan** minimum (for volume support)
4. ✅ **Set up regular backups** of both database and volume

---

## 📝 Summary

**Current status**: 
- ✅ WebSocket errors fixed
- ✅ Container stability fixed
- ⚠️ File persistence requires manual Railway volume setup

**Next action**: 
Add a Railway volume via dashboard to complete the filestore persistence solution.

---

**Need help?** 
- Railway Volumes Docs: https://docs.railway.com/reference/volumes
- Railway Support: https://railway.app/help

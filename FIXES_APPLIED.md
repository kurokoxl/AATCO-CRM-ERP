# Railway Deployment Fixes Applied

## Issues Fixed

### 1. WebSocket Connection Errors ✅
**Problem**: 
```
RuntimeError: Couldn't bind the websocket. Is the connection opened on the evented port (8072)?
```

**Root Cause**: 
Odoo was trying to start a separate longpolling/gevent server on port 8072, but Railway's architecture doesn't support multiple ports per service. Railway's proxy handles WebSocket connections at the infrastructure level.

**Solution**:
- Added `gevent_port = 0` to `odoo.conf.template` to disable Odoo's built-in longpolling server
- Railway's proxy automatically handles WebSocket upgrades for HTTP requests
- Commented out WebSocket-specific settings that are now handled by Railway

**Expected Result**: No more WebSocket binding errors in logs

---

### 2. Missing Filestore Files ✅
**Problem**: 
```
FileNotFoundError: [Errno 2] No such file or directory: '/var/lib/odoo/filestore/AATCO/...'
```

**Root Cause**: 
- Odoo stores uploaded files (images, attachments, etc.) in `/var/lib/odoo/filestore/`
- Railway containers are ephemeral - data is lost on restart without persistent volumes
- The AATCO database filestore was created but not persisted

**Solution**:
- Added `VOLUME ["/var/lib/odoo"]` declaration in Dockerfile
- Configured persistent volume in `railway.json`:
  ```json
  "volumes": [
    {
      "name": "odoo-filestore",
      "mountPath": "/var/lib/odoo"
    }
  ]
  ```
- Ensured proper directory creation and permissions in Dockerfile

**Expected Result**: 
- Uploaded files will persist across container restarts
- No more FileNotFoundError for filestore paths
- Database filestore data will survive deployments

---

### 3. Container Health Check Issues ✅
**Problem**: 
- Container kept restarting ("Stopping Container" shortly after startup)
- Railway's health check was failing

**Root Cause**: 
- Health check path `/web/health` may not exist on Odoo 18 Community Edition
- Health check timeout was too aggressive for initial database loading

**Solution**:
- Changed health check path to `/web/database/selector` (always available)
- Increased `gracePeriod` from 60s to 90s to allow database initialization
- Increased `timeout` to 180s for slower startups

**Expected Result**: 
- Container stays running after startup
- No more premature restarts during deployment
- More stable service lifecycle

---

## Files Modified

1. **odoo.conf.template**
   - Added `gevent_port = 0` to disable longpolling server
   - Commented out WebSocket settings (handled by Railway)

2. **Dockerfile**
   - Added `VOLUME ["/var/lib/odoo"]` for persistent storage
   - Created `/var/lib/odoo/filestore` directory with proper permissions

3. **railway.json**
   - Added volume configuration for filestore persistence
   - Updated health check path and timings

---

## Testing Checklist

After deployment, verify:

- [ ] No WebSocket errors in Railway logs
- [ ] Container stays running (no "Stopping Container" messages)
- [ ] Upload an image to a database record - it should persist after container restart
- [ ] Database selector page loads correctly at `/web/database/selector`
- [ ] Login to AATCO database works without file errors
- [ ] Filestore directory shows in Railway volume dashboard

---

## Railway Volume Management

**Important**: Railway volumes are persistent but:
- Volume data persists across deployments
- To clear filestore data: Delete the volume in Railway dashboard
- Volume size counts against your Railway plan storage quota
- Backup important data regularly

**Volume Location**: `/var/lib/odoo` contains:
- `filestore/` - Uploaded files for each database
- `sessions/` - User session data
- `.addons_paths` - Addon path cache

---

## Next Steps

1. Commit and push these changes:
   ```bash
   git add odoo.conf.template Dockerfile railway.json
   git commit -m "Fix WebSocket, filestore persistence, and health check issues"
   git push origin main
   ```

2. Railway will auto-deploy - monitor logs for:
   - No WebSocket binding errors
   - Successful health checks
   - Container stability

3. Test filestore persistence:
   - Login to AATCO database
   - Upload a company logo
   - Trigger a redeployment
   - Verify logo still appears after restart

---

## Troubleshooting

### If WebSocket errors still appear:
- Check Railway environment variables
- Verify `gevent_port = 0` is in deployed config
- Check Railway proxy logs

### If filestore errors continue:
- Verify volume is mounted: `ls -la /var/lib/odoo` in Railway shell
- Check volume permissions: Should be owned by `odoo:odoo`
- Clear browser cache and retry

### If container still restarts:
- Check health check response: `curl http://localhost:8069/web/database/selector`
- Review Railway build logs for errors
- Increase `gracePeriod` to 120s if needed

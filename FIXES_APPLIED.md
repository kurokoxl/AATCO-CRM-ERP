# Railway Deployment Fixes Applied

## Issues Fixed

### 1. WebSocket Connection Errors ✅
**Problem**: 
```
RuntimeError: Couldn't bind the websocket. Is the connection opened on the evented port (8072)?
```

**Root Cause**: 
`gevent_port` was forced to `0`, leaving Odoo without an evented worker to accept WebSocket handshakes. When the UI tried to connect to `/websocket`, the HTTP worker could not bind to the disabled evented port, raising runtime errors.

**Solution**:
- Restored the evented service by setting `gevent_port = ${TEMPLATE_GEVENT_PORT}` (defaults to 8072)
- Surface the port configuration through environment variable `ODOO_GEVENT_PORT`
- Documented that Railway handles the single external port while Odoo keeps its internal gevent worker for WebSocket traffic

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
- Ensure `/var/lib/odoo` hierarchy is created with correct ownership during build/startup
- Entry point now warns when the filestore path is not mounted on a persistent Railway volume
- Documentation updated with explicit steps to add a Railway volume for `/var/lib/odoo`

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

1. **entrypoint.sh**
   - Exposes `ODOO_GEVENT_PORT` (default 8072) and injects it into generated config
   - Allows overriding the data directory via `ODOO_DATA_DIR`
   - Emits a warning when `/var/lib/odoo` is not backed by a Railway volume

2. **odoo.conf.template**
   - Uses templated `gevent_port` instead of disabling the evented worker
   - Applies templated `dbfilter`, `list_db`, and `data_dir` values from the entry point

3. **Dockerfile**
   - Ensures `/var/lib/odoo/filestore` exists with proper ownership during image build

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
- Verify `gevent_port = 8072` (or your custom port) is in the deployed config
- Make sure nothing else inside the container is bound to that port

### If filestore errors continue:
- Verify volume is mounted: `ls -la /var/lib/odoo` in Railway shell
- Check volume permissions: Should be owned by `odoo:odoo`
- Clear browser cache and retry

### If container still restarts:
- Check health check response: `curl http://localhost:8069/web/database/selector`
- Review Railway build logs for errors
- Increase `gracePeriod` to 120s if needed

# Deploy Field Service Navigate Module

## Quick Summary
Your custom `fieldservice_navigate` module is ready in the Railway deployment. Follow these steps to make it available in your AATCO database.

## Module Information
- **Name**: Field Service Navigate
- **Technical Name**: `fieldservice_navigate`
- **Version**: 18.0.1.0.0
- **Location**: `/mnt/extra-addons/fieldservice_navigate` (in Railway container)
- **Depends on**: `fieldservice` module (from OCA - Odoo Community Association)

## What This Module Does
Adds a "Navigate" button to Field Service Orders that:
- Opens Google Maps with turn-by-turn navigation
- Routes from your current location to the order's service location
- Works with both address text and GPS coordinates
- Displays location details directly in the order form

---

## Deployment Steps

### Step 1: Push Module to Railway (If Not Already Done)

The module is already in your `deployment/railway/addons/fieldservice_navigate/` directory.

**Deploy to Railway:**
```powershell
cd "c:\Program Files\Odoo 17.0.20250930\deployment\railway"
git add addons/fieldservice_navigate
git commit -m "Add Field Service Navigate custom module"
git push origin main
```

**Wait for Railway to redeploy** (2-3 minutes). Watch the Railway dashboard for:
```
✓ Building Docker image...
✓ Starting container...
✓ Health check passed
```

---

### Step 2: Install Required Dependencies

The `fieldservice_navigate` module depends on the **Field Service** module from OCA (Odoo Community Association).

#### Option A: Install from Odoo Apps (Recommended)

1. **Go to Apps**: https://aatco-crm-erp-production.up.railway.app/web#action=base.open_module_tree
2. **Remove "Apps" filter**: Click the "Apps" button to show ALL modules
3. **Search for**: `fieldservice` or `field service`
4. **Install**: Click "Install" on the **Field Service** module
   - Wait 2-3 minutes for installation
   - This will install the base Field Service functionality

#### Option B: Install via Module Code

If the Field Service module is not available in your Apps list, you need to add the OCA Field Service repository:

**Add OCA Field Service to requirements:**

Edit `c:\Program Files\Odoo 17.0.20250930\deployment\railway\requirements.txt` and add:
```
git+https://github.com/OCA/field-service.git@18.0#subdirectory=fieldservice
```

Then redeploy:
```powershell
git add requirements.txt
git commit -m "Add OCA Field Service dependency"
git push origin main
```

---

### Step 3: Update Apps List

After Railway finishes deploying:

1. **Login to Odoo**: https://aatco-crm-erp-production.up.railway.app
2. **Go to Apps**: Top menu → Apps
3. **Update Apps List**:
   - Click the ⚙️ (gear) icon in the top-right corner
   - Select "Update Apps List"
   - Click "Update" in the confirmation dialog
   - Wait for the process to complete

---

### Step 4: Install Field Service Navigate

1. **Search for the module**: In the Apps page, search for `field service navigate`
2. **Click "Install"**: You should now see the module in the list
3. **Wait for installation**: Takes 30-60 seconds
4. **Refresh the page**

---

### Step 5: Verify Installation

1. **Check Menu**: Go to **Field Service** menu (should appear in the main menu)
2. **Create/Open an Order**: 
   - Click "Field Service" → "Orders"
   - Create a new order or open an existing one
3. **Verify Navigate Button**: 
   - You should see a "Navigate" button in the top-right button box
   - Click it to test Google Maps navigation

---

## Troubleshooting

### Module Not Showing in Apps List

**Cause**: Module not properly scanned by Odoo

**Solution**:
1. Update Apps List (Step 3 above)
2. Check Railway logs for errors:
   ```bash
   railway logs --service odoo
   ```
3. Verify module is in container:
   ```bash
   railway run bash
   ls -la /mnt/extra-addons/fieldservice_navigate
   cat /mnt/extra-addons/fieldservice_navigate/__manifest__.py
   ```

---

### "Module fieldservice not found" Error

**Cause**: Base Field Service module not installed

**Solution**:
1. Install the `fieldservice` module first (Step 2)
2. Then install `fieldservice_navigate`

---

### Navigate Button Not Appearing

**Cause**: Module installed but not properly loaded

**Solution**:
1. **Force restart**: Go to Settings → Technical → Database Structure → Update Apps List
2. **Check module state**:
   - Go to Apps → Remove "Apps" filter
   - Search for `fieldservice_navigate`
   - Verify status is "Installed"
3. **Clear browser cache**: Ctrl+Shift+R (hard refresh)
4. **Check logs** for view inheritance errors

---

### "Location has no valid address" Error

**Cause**: Field Service Order location has no address or coordinates

**Solution**:
1. Open the Field Service Order
2. Click the "Location" field
3. Fill in address details:
   - Street
   - City
   - State
   - ZIP
   - Country
4. OR add GPS coordinates (latitude/longitude)
5. Save and try "Navigate" again

---

## Module Features

### Navigate Button
- **Location**: Top-right button box in Field Service Order form
- **Icon**: Red map marker (🗺️)
- **Action**: Opens Google Maps in new tab with navigation

### Location Display
- Shows full address below the Location field
- Displays:
  - Street address (line 1 & 2)
  - City, State, ZIP
  - Country
  - Phone number (with click-to-call)

### Smart Navigation
- **Prefers GPS coordinates** if available (more accurate)
- **Falls back to address text** if no coordinates
- **Validates data** before opening map (prevents errors)

---

## Customization Options

### Change Navigation Service

Edit `addons/fieldservice_navigate/models/fsm_order.py`:

**Use Waze instead of Google Maps:**
```python
waze_url = f"https://waze.com/ul?q={destination_encoded}&navigate=yes"
```

**Use Apple Maps:**
```python
apple_maps_url = f"https://maps.apple.com/?daddr={destination_encoded}"
```

### Add More Location Fields

Edit `addons/fieldservice_navigate/views/fsm_order_views.xml` to add more fields like:
- Email
- Mobile number
- Location notes
- GPS coordinates display

---

## Support & Documentation

### Module Files
- **Models**: `addons/fieldservice_navigate/models/fsm_order.py`
- **Views**: `addons/fieldservice_navigate/views/fsm_order_views.xml`
- **Manifest**: `addons/fieldservice_navigate/__manifest__.py`

### Related Documentation
- **Field Service OCA**: https://github.com/OCA/field-service
- **Google Maps Directions API**: https://developers.google.com/maps/documentation/urls/get-started

### Need Help?
Check the Railway logs for detailed error messages:
```bash
railway logs --service odoo --tail 100
```

---

## Summary Checklist

- [ ] Module files exist in `deployment/railway/addons/fieldservice_navigate/`
- [ ] Committed and pushed to GitHub
- [ ] Railway redeployed successfully
- [ ] Field Service base module installed
- [ ] Updated Apps List in Odoo
- [ ] Field Service Navigate module installed
- [ ] Navigate button appears in Field Service Orders
- [ ] Google Maps opens correctly when clicked

**Status**: ✅ Module ready for deployment!

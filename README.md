# Railway Deployment Guide for Odoo 18 Community

This directory contains everything required to build and deploy your customised Odoo 18 Community instance on [Railway](https://railway.app/). It is designed so that you can continue developing locally while having a reliable, repeatable production pipeline managed through Git and Railway.

## Contents

| File | Purpose |
|------|---------|
| `.dockerignore` | Keeps the container image lean by excluding unnecessary files from the build context. |
| `Dockerfile` | Builds on the official `odoo:18.0` image, installs extra Python requirements, bundles your custom addons, and configures the runtime entrypoint. |
| `entrypoint.sh` | Generates `odoo.conf` from environment variables supplied by Railway and launches Odoo. |
| `odoo.conf.template` | Template configuration file with sensible production defaults. |
| `requirements.txt` | Add any extra Python dependencies required by your custom modules. |
| `addons/` | Copy of your custom Odoo addons that will be bundled into the container image. |
| `railway.template.json` | Optional helper template showing how to declare the service and Postgres plugin via Railway infrastructure-as-code. |
| `scripts/sync_addons.ps1` | PowerShell utility to sync local custom modules into the `addons/` folder prior to commit. |

## Prerequisites

1. **Railway account** with the Postgres add-on available (a Starter plan is typically sufficient for small teams).
2. **GitHub repository** that will host this deployment directory alongside your source code.
3. **Railway CLI (optional but recommended)**: <https://docs.railway.app/develop/cli>
4. **PowerShell** (already available on Windows) to run the helper scripts when preparing releases.

## One-time setup

1. **Sync custom addons** into this deployment folder:
   ```powershell
   cd "c:\Program Files\Odoo 17.0.20250930\deployment\railway"
   .\scripts\sync_addons.ps1
   ```
   This copies everything from `Odoo 18.0.20250930\custom\` into `deployment\railway\addons\` so the Docker build has the latest code. Re-run whenever you change a custom module.

2. **Review `requirements.txt`**. If your addons require additional Python packages, add them one per line (e.g. `requests==2.32.3`). The Docker build installs them automatically.

3. **Commit and push** the entire `deployment/railway` folder to Git once you are happy with the contents. Railway will build from the Git repository root.

4. **Create a new Railway project**:
   - From the Railway dashboard choose **New Project → Deploy from GitHub Repo** and select your repository.
   - When prompted for the service type pick **Dockerfile** and point it to `deployment/railway/Dockerfile`. Railway will automatically use the `deployment/railway` directory as the build context when you set the root path to that folder in the deployment settings.
   - Attach a **PostgreSQL plugin** to the project. Railway automatically exposes the database credentials as `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, and `PGDATABASE` environment variables.

5. **Set required environment variables** for the service (Railway → Variables tab):
   | Variable | Description |
   |----------|-------------|
   | `ADMIN_PASSWORD` | Master password used by `/web/database/manager`. Generate a long random value and keep it secret. |
   | `DB_NAME` | Primary database name to load. Set to `AATCO` to match your local instance. |
   | `ODOO_HTTP_PORT` | Leave as `8069` unless you have a custom reverse proxy. |
   | `ODOO_DB_FILTER` *(optional)* | Regex matching databases served by this instance. Defaults to the value of `DB_NAME`. |

6. **Configure domains (optional)** by adding a public domain entry in Railway. Railway automatically provisions SSL certificates.

## Deploying updates

1. Ensure your local Odoo instance is in the desired state.
2. Run the sync script to refresh the `addons/` folder:
   ```powershell
   cd "c:\Program Files\Odoo 17.0.20250930\deployment\railway"
   .\scripts\sync_addons.ps1
   ```
3. Commit changes in Git (both the addon code and any deployment adjustments).
4. Push to the branch linked with Railway. Each push triggers a fresh Docker build and deployment.
5. Monitor the build logs from the Railway dashboard. Once complete, validate the instance at the generated Railway URL or your custom domain.

## Rolling back

Railway keeps the previous deployment image. If something goes wrong:
1. Open the Railway project → Deployments tab.
2. Select a known-good deployment and click **Roll Back**. Railway switches traffic back to that image instantly.

## Database backups

Railway Postgres comes with automatic daily snapshots. Still, schedule additional logical backups:
```bash
railway variables set BACKUP_DIR=/tmp/odoo_backups
railway connect --service odoo --command "pg_dump -Fc -f \"$BACKUP_DIR/$(date +%Y%m%d_%H%M%S).dump\" $PGDATABASE"
```
Consider syncing those dumps to object storage (e.g. Backblaze B2 or AWS S3) for long-term retention.

## Health checks

The Dockerfile exposes port 8069. Railway probes `/web/health` (built-in Odoo endpoint). If you modify routes or add maintenance pages, ensure the health endpoint still responds with HTTP 200.

## Support & next steps

- Add more custom modules by dropping them into `addons/` and re-running the sync script.
- Extend the Docker image with custom fonts, wkhtmltopdf, or system packages by editing the `Dockerfile` before the `USER odoo` step.
- Configure scheduled jobs or cron tasks inside Odoo; the worker limits in `odoo.conf.template` are tuned for small Starter plans. Increase limits as you scale.

If you need to automate further (CI/CD, seed data, staging environments), duplicate this folder and adjust environment variables per environment (e.g. `deployment/railway-staging`).

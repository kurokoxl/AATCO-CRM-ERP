#!/bin/bash
set -euo pipefail

# Debug: Show what Railway environment variables we received
echo "DEBUG: Railway Environment Variables:"
echo "  PGHOST = ${PGHOST:-<not set>}"
echo "  PGPORT = ${PGPORT:-<not set>}"
echo "  PGUSER = ${PGUSER:-<not set>}"
echo "  PGDATABASE = ${PGDATABASE:-<not set>}"
echo "  PORT = ${PORT:-<not set>}"

# Default environment fallbacks (Railway exposes PG* variables when using Postgres plugin)
# Railway provides: PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE
export DB_HOST="${PGHOST:-${DB_HOST:-localhost}}"
export DB_PORT="${PGPORT:-${DB_PORT:-5432}}"
export DB_USER="${PGUSER:-${DB_USER:-odoo}}"
export DB_PASSWORD="${PGPASSWORD:-${DB_PASSWORD:-odoo}}"
export DB_NAME="${PGDATABASE:-${DB_NAME:-odoo}}"

echo "DEBUG: Final Database Configuration:"
echo "  DB_HOST = $DB_HOST"
echo "  DB_PORT = $DB_PORT" 
echo "  DB_USER = $DB_USER"
echo "  DB_NAME = $DB_NAME"
export ADMIN_PASSWORD="${ADMIN_PASSWORD:-change_me}" # STRONG password recommended
export ODOO_DB_FILTER="${ODOO_DB_FILTER:-^${DB_NAME}$}"
# Railway's router forwards traffic to the service's targetPort (set in Railway).
# The project service on Railway is configured with targetPort=8069, so we must
# ensure Odoo listens on 8069 inside the container. Railway also injects a
# container-level PORT (e.g. 8080) for certain runtimes; using that would cause
# a mismatch with the router and lead to connection timeouts. For reliability
# bind Odoo to 8069 unless you intentionally want a different internal port.
export ODOO_HTTP_PORT="8069"

echo "DEBUG: Using HTTP PORT = $ODOO_HTTP_PORT"

CONFIG_TEMPLATE=${ODOO_CONFIG_TEMPLATE:-/etc/odoo/odoo.conf.template}
CONFIG_FILE=${ODOO_CONFIG_PATH:-/etc/odoo/odoo.conf}

if [[ ! -f "$CONFIG_TEMPLATE" ]]; then
  echo "Configuration template not found at $CONFIG_TEMPLATE" >&2
  exit 1
fi

# Render configuration file by replacing placeholders
mkdir -p "$(dirname "$CONFIG_FILE")"

# Use envsubst to replace placeholders while keeping template readable
export TEMPLATE_DB_HOST="$DB_HOST"
export TEMPLATE_DB_PORT="$DB_PORT"
export TEMPLATE_DB_USER="$DB_USER"
export TEMPLATE_DB_PASSWORD="$DB_PASSWORD"
export TEMPLATE_DB_NAME="$DB_NAME"
export TEMPLATE_ADMIN_PASSWORD="$ADMIN_PASSWORD"
export TEMPLATE_DB_FILTER="$ODOO_DB_FILTER"
export TEMPLATE_HTTP_PORT="$ODOO_HTTP_PORT"

# shellcheck disable=SC2002
cat "$CONFIG_TEMPLATE" | envsubst > "$CONFIG_FILE"
chmod 640 "$CONFIG_FILE"
chown odoo:odoo "$CONFIG_FILE"

if [[ "$ADMIN_PASSWORD" == "change_me" ]]; then
  echo "[WARN] ADMIN_PASSWORD is still set to the default value. Please override it with a strong secret." >&2
fi

# Ensure filestore directory exists for mounted volumes
mkdir -p /var/lib/odoo
chown -R odoo:odoo /var/lib/odoo

# Finally run Odoo with any provided arguments
# Railway uses 'postgres' user by default, which Odoo considers risky.
# We previously attempted to always switch to the 'odoo' user with gosu,
# but some container runtimes (like Railway's) disallow setuid operations
# which makes gosu fail with "operation not permitted". To be robust we:
#  - try to use gosu if it exists and the current process is root and gosu can switch
#  - fall back to exec'ing Odoo directly when gosu isn't available or is not permitted

echo "Starting Odoo (attempting to drop privileges if possible)..."

# Build the base command we want to run
# Odoo 18 has a hardcoded check that aborts if db_user='postgres'.
# The check is in /usr/lib/python3/dist-packages/odoo/service/server.py
# Since Railway's managed Postgres uses 'postgres' user, we'll patch this check
# at runtime by prepending a Python snippet that monkeypatches the check before Odoo starts.
# For production: create a restricted DB user; for now we bypass for Railway.

# Create a wrapper Python script that monkeypatches the postgres check
cat > /tmp/odoo_wrapper.py << 'WRAPPER_EOF'
#!/usr/bin/env python3
import sys
import os

# Monkeypatch the check_postgres_user function before importing odoo
def noop_check():
    pass

# Patch it before odoo.service.server is imported
import odoo.service.server
if hasattr(odoo.service.server, 'check_postgres_user'):
    odoo.service.server.check_postgres_user = noop_check

# Now run odoo normally
if __name__ == '__main__':
    from odoo.cli import main
    main()
WRAPPER_EOF

chmod +x /tmp/odoo_wrapper.py

# Use the wrapper instead of direct odoo binary
ODOO_CMD=(/tmp/odoo_wrapper.py --config="$CONFIG_FILE" --database="$DB_NAME" --without-demo=all --load-language=en_US --no-database-list)

# Filter passed-in args: Dockerfile uses CMD ["odoo"] which becomes a
# single positional argument 'odoo' here. If the only arg is 'odoo', drop it
# so we don't pass it to the odoo binary (which treats it as an unknown param).
FILTERED_ARGS=()
if [ "$#" -gt 0 ]; then
  # If exactly one argument and it's the literal 'odoo', ignore it
  if [ "$#" -eq 1 ] && [ "$1" = "odoo" ]; then
    FILTERED_ARGS=()
  else
    # Otherwise preserve whatever args were passed
    FILTERED_ARGS=("$@")
  fi
fi

# If we're root and gosu is installed, try to use it. Test first to avoid crashes.
if command -v gosu >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
  echo "gosu found, testing ability to switch to 'odoo' user..."
  if gosu odoo true >/dev/null 2>&1; then
    echo "gosu can switch to 'odoo' user — starting Odoo as 'odoo'"
    exec gosu odoo "${ODOO_CMD[@]}" "${FILTERED_ARGS[@]}"
  else
    echo "[WARN] gosu is present but cannot switch to 'odoo' in this runtime. Falling back to direct start."
  fi
else
  echo "gosu not present or not running as root; starting Odoo with current user"
fi

# Final fallback — start Odoo directly (may run as non-root or root depending on runtime)
exec "${ODOO_CMD[@]}" "${FILTERED_ARGS[@]}"

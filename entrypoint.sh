#!/bin/bash
set -euo pipefail

# Default environment fallbacks (Railway exposes PG* variables when using Postgres plugin)
export DB_HOST="${DB_HOST:-${PGHOST:-postgres}}"
export DB_PORT="${DB_PORT:-${PGPORT:-5432}}"
export DB_USER="${DB_USER:-${PGUSER:-odoo}}"
export DB_PASSWORD="${DB_PASSWORD:-${PGPASSWORD:-odoo}}"
export DB_NAME="${DB_NAME:-${PGDATABASE:-odoo}}"
export ADMIN_PASSWORD="${ADMIN_PASSWORD:-change_me}" # STRONG password recommended
export ODOO_DB_FILTER="${ODOO_DB_FILTER:-^${DB_NAME}$}"
export ODOO_HTTP_PORT="${ODOO_HTTP_PORT:-${PORT:-8069}}"

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
exec /usr/bin/odoo "$@"

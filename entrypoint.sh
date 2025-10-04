#!/bin/bash
set -euo pipefail

# Debug: Show what Railway environment variables we received
echo "DEBUG: Railway Environment Variables:"
echo "  PGHOST = ${PGHOST:-<not set>}"
echo "  PGPORT = ${PGPORT:-<not set>}"
echo "  PGUSER = ${PGUSER:-<not set>}"
echo "  PGDATABASE = ${PGDATABASE:-<not set>}"
echo "  PORT = ${PORT:-<not set>}"

if [[ -z "${LANG:-}" ]]; then
  export LANG="C.UTF-8"
fi
if [[ -z "${LC_ALL:-}" ]]; then
  export LC_ALL="C.UTF-8"
fi

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

AUTO_PROVISION="True"
if [[ -n "${ODOO_AUTO_PROVISION_DB_USER:-}" ]]; then
  case "$(printf '%s' "$ODOO_AUTO_PROVISION_DB_USER" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|on)
      AUTO_PROVISION="True"
      ;;
    0|false|no|off)
      AUTO_PROVISION="False"
      ;;
    *)
      echo "[WARN] ODOO_AUTO_PROVISION_DB_USER has unexpected value '$ODOO_AUTO_PROVISION_DB_USER'; defaulting to True" >&2
      AUTO_PROVISION="True"
      ;;
  esac
fi

sql_escape_literal() {
  local raw="$1"
  raw=${raw//\'/\'\'}
  printf '%s' "$raw"
}

if [[ "$DB_USER" == "postgres" && "$AUTO_PROVISION" == "True" ]]; then
  APP_DB_USER="${ODOO_APP_DB_USER:-odoo_user}"

  APP_DB_PASSWORD="${ODOO_APP_DB_PASSWORD:-}"
  if [[ -z "$APP_DB_PASSWORD" && -n "${ODOO_APP_DB_PASSWORD_FILE:-}" && -f "$ODOO_APP_DB_PASSWORD_FILE" ]]; then
    APP_DB_PASSWORD="$(<"$ODOO_APP_DB_PASSWORD_FILE")"
  fi
  if [[ -z "$APP_DB_PASSWORD" && -n "${DB_PASSWORD:-}" ]]; then
    echo "[WARN] ODOO_APP_DB_PASSWORD not provided; reusing DB_PASSWORD for application role." >&2
    APP_DB_PASSWORD="$DB_PASSWORD"
  fi
  if [[ -z "$APP_DB_PASSWORD" && -n "${PGPASSWORD:-}" ]]; then
    echo "[WARN] Falling back to Railway PGPASSWORD for application role. Set ODOO_APP_DB_PASSWORD to override." >&2
    APP_DB_PASSWORD="$PGPASSWORD"
  fi
  if [[ -z "$APP_DB_PASSWORD" ]]; then
    echo "[ERROR] Unable to determine password for application database role. Set ODOO_APP_DB_PASSWORD or provide ODOO_APP_DB_PASSWORD_FILE." >&2
    exit 1
  fi

  if [[ -z "${PGPASSWORD:-}" ]]; then
    if [[ -n "$DB_PASSWORD" ]]; then
      export PGPASSWORD="$DB_PASSWORD"
    else
      echo "[ERROR] PGPASSWORD is not set; cannot manage Postgres roles. Ensure Railway exposes the superuser password." >&2
      exit 1
    fi
  fi

  echo "[INFO] Provisioning dedicated application role '$APP_DB_USER' for database '$DB_NAME'."

  APP_DB_USER_SQL="$(sql_escape_literal "$APP_DB_USER")"
  APP_DB_PASSWORD_SQL="$(sql_escape_literal "$APP_DB_PASSWORD")"
  APP_DB_NAME_SQL="$(sql_escape_literal "$DB_NAME")"

  # Step 1: Create or update the application role (can be done in DO block)
  echo "[INFO] Creating/updating application role..."
  psql -v ON_ERROR_STOP=1 \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "${ODOO_SUPERUSER_DATABASE:-postgres}" <<SQL
DO \$do\$
DECLARE
    app_user text := '${APP_DB_USER_SQL}';
    app_password text := '${APP_DB_PASSWORD_SQL}';
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = app_user) THEN
        EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L CREATEDB', app_user, app_password);
        RAISE NOTICE 'Created new role: %', app_user;
    ELSE
        EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L CREATEDB', app_user, app_password);
        RAISE NOTICE 'Updated existing role: %', app_user;
    END IF;
END
\$do\$;
SQL

  # Step 2: Check if database exists and handle accordingly (outside DO block)
  echo "[INFO] Checking database '$DB_NAME'..."
  DB_EXISTS=$(psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "${ODOO_SUPERUSER_DATABASE:-postgres}" -tAc "SELECT 1 FROM pg_database WHERE datname='${APP_DB_NAME_SQL}'")
  
  if [[ "$DB_EXISTS" != "1" ]]; then
    echo "[INFO] Database '$DB_NAME' does not exist. Creating it..."
    psql -v ON_ERROR_STOP=1 \
      -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "${ODOO_SUPERUSER_DATABASE:-postgres}" \
      -c "CREATE DATABASE \"${APP_DB_NAME_SQL}\" OWNER \"${APP_DB_USER_SQL}\" TEMPLATE template0 ENCODING 'UTF8';"
    echo "[INFO] Database '$DB_NAME' created successfully."
  else
    echo "[INFO] Database '$DB_NAME' already exists. Setting owner..."
    psql -v ON_ERROR_STOP=1 \
      -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "${ODOO_SUPERUSER_DATABASE:-postgres}" \
      -c "ALTER DATABASE \"${APP_DB_NAME_SQL}\" OWNER TO \"${APP_DB_USER_SQL}\";"
    echo "[INFO] Database owner updated."
  fi

  # Step 3: Grant connection privileges
  echo "[INFO] Granting connection privileges..."
  psql -v ON_ERROR_STOP=1 \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "${ODOO_SUPERUSER_DATABASE:-postgres}" \
    -c "GRANT CONNECT ON DATABASE \"${APP_DB_NAME_SQL}\" TO \"${APP_DB_USER_SQL}\";"
SQL

  # Step 4: Grant schema and object privileges
  echo "[INFO] Setting up permissions on database '$DB_NAME'..."
  psql -v ON_ERROR_STOP=1 \
    -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" <<SQL
-- Grant schema privileges
GRANT USAGE, CREATE ON SCHEMA public TO "${APP_DB_USER_SQL}";

-- Grant privileges on existing objects
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "${APP_DB_USER_SQL}";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "${APP_DB_USER_SQL}";
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO "${APP_DB_USER_SQL}";

-- Set default privileges for future objects created by the app user
ALTER DEFAULT PRIVILEGES FOR ROLE "${APP_DB_USER_SQL}" IN SCHEMA public 
  GRANT ALL PRIVILEGES ON TABLES TO "${APP_DB_USER_SQL}";
ALTER DEFAULT PRIVILEGES FOR ROLE "${APP_DB_USER_SQL}" IN SCHEMA public 
  GRANT ALL PRIVILEGES ON SEQUENCES TO "${APP_DB_USER_SQL}";
ALTER DEFAULT PRIVILEGES FOR ROLE "${APP_DB_USER_SQL}" IN SCHEMA public 
  GRANT ALL PRIVILEGES ON FUNCTIONS TO "${APP_DB_USER_SQL}";

-- Also grant default privileges for objects created by postgres (for initial setup)
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public 
  GRANT ALL PRIVILEGES ON TABLES TO "${APP_DB_USER_SQL}";
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public 
  GRANT ALL PRIVILEGES ON SEQUENCES TO "${APP_DB_USER_SQL}";
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public 
  GRANT ALL PRIVILEGES ON FUNCTIONS TO "${APP_DB_USER_SQL}";
SQL

  echo "[INFO] Permissions configured successfully."

  DB_USER="$APP_DB_USER"
  DB_PASSWORD="$APP_DB_PASSWORD"
  export DB_USER DB_PASSWORD

  export PGUSER="$APP_DB_USER"
  export PGPASSWORD="$APP_DB_PASSWORD"

  echo "[INFO] Application role '$APP_DB_USER' is ready. Continuing with non-superuser credentials."
fi

echo "DEBUG: Final Database Configuration After Provisioning:"
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
export TEMPLATE_DB_MAXCONN="${ODOO_DB_MAXCONN:-16}"

# Toggle database manager visibility (list_db) via ODOO_LIST_DB env var.
# Default stays False for production safety unless explicitly enabled.
if [[ -n "${ODOO_LIST_DB:-}" ]]; then
  case "$(printf '%s' "$ODOO_LIST_DB" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|on)
      export TEMPLATE_LIST_DB="True"
      ;;
    0|false|no|off)
      export TEMPLATE_LIST_DB="False"
      ;;
    *)
      echo "[WARN] ODOO_LIST_DB has unexpected value '$ODOO_LIST_DB'; defaulting to False" >&2
      export TEMPLATE_LIST_DB="False"
      ;;
  esac
else
  export TEMPLATE_LIST_DB="False"
fi

# Optional one-time initialization flag. When ODOO_INIT_DB is set to a
# truthy value (1/true/yes/on) the entrypoint will run Odoo with
# `-i base --stop-after-init` to initialize the database and then exit.
# This is safer than leaving the DB manager open in production.
if [[ -n "${ODOO_INIT_DB:-}" ]]; then
  case "$(printf '%s' "$ODOO_INIT_DB" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|on)
      export DO_INIT_DB="True"
      ;;
    0|false|no|off)
      export DO_INIT_DB="False"
      ;;
    *)
      echo "[WARN] ODOO_INIT_DB has unexpected value '$ODOO_INIT_DB'; defaulting to False" >&2
      export DO_INIT_DB="False"
      ;;
  esac
else
  export DO_INIT_DB="False"
fi

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
ODOO_CMD=(odoo --config="$CONFIG_FILE" --database="$DB_NAME" --without-demo=all --load-language=en_US)

# Allow operators to supply additional Odoo CLI flags (e.g. --log-level=debug_sql)
if [[ -n "${ODOO_EXTRA_ARGS:-}" ]]; then
  echo "Applying extra Odoo arguments from ODOO_EXTRA_ARGS"
  # shellcheck disable=SC2206
  EXTRA_ARGS=( $ODOO_EXTRA_ARGS )
  ODOO_CMD+=("${EXTRA_ARGS[@]}")
fi

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
    # If operator requested a one-time DB initialization, run it first
    if [[ "${DO_INIT_DB}" == "True" ]]; then
      echo "[INFO] DO_INIT_DB is True — initializing database by running 'odoo -i base --stop-after-init' as 'odoo' user"
      gosu odoo odoo --config="$CONFIG_FILE" --database="$DB_NAME" -i base --stop-after-init || {
        echo "[ERROR] Database initialization failed!" >&2
        exit 1
      }
      echo "[INFO] Database initialization complete. Starting Odoo server..."
    fi
    exec gosu odoo "${ODOO_CMD[@]}" "${FILTERED_ARGS[@]}"
  else
    echo "[WARN] gosu is present but cannot switch to 'odoo' in this runtime. Falling back to direct start."
  fi
else
  echo "gosu not present or not running as root; starting Odoo with current user"
fi

# If operator requested a one-time DB initialization and we couldn't use gosu,
# run the initialization as the current user first, then continue.
if [[ "${DO_INIT_DB}" == "True" ]]; then
  echo "[INFO] DO_INIT_DB is True — initializing database by running 'odoo -i base --stop-after-init' as current user"
  odoo --config="$CONFIG_FILE" --database="$DB_NAME" -i base --stop-after-init || {
    echo "[ERROR] Database initialization failed!" >&2
    exit 1
  }
  echo "[INFO] Database initialization complete. Starting Odoo server..."
fi

# Final fallback — start Odoo directly (may run as non-root or root depending on runtime)
exec "${ODOO_CMD[@]}" "${FILTERED_ARGS[@]}"

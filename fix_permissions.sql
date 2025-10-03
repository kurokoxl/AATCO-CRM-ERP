-- Grant necessary privileges to odoo_user for Railway database
-- Run this script as the postgres superuser

-- Connect rights
GRANT CONNECT ON DATABASE railway TO odoo_user;

-- Schema permissions
GRANT USAGE, CREATE ON SCHEMA public TO odoo_user;

-- Existing objects
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO odoo_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO odoo_user;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO odoo_user;

-- Future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL PRIVILEGES ON TABLES TO odoo_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL PRIVILEGES ON SEQUENCES TO odoo_user;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL PRIVILEGES ON FUNCTIONS TO odoo_user;

-- Verify grants
\du odoo_user
\l railway

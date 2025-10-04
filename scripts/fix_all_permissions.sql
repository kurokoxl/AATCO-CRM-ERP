-- Fix all database permissions for odoo_user
-- This script grants proper privileges so Odoo can access the restored database

-- Grant all privileges on all existing tables
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO odoo_user;

-- Grant all privileges on all existing sequences
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO odoo_user;

-- Grant all privileges on all existing functions
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO odoo_user;

-- Grant usage on the public schema
GRANT USAGE ON SCHEMA public TO odoo_user;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO odoo_user;

-- Set default privileges for future sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO odoo_user;

-- Change the database owner to odoo_user
ALTER DATABASE railway OWNER TO odoo_user;

-- Verify permissions
SELECT 'Checking permissions...' AS status;
SELECT has_table_privilege('odoo_user', 'ir_module_module', 'SELECT') AS can_select_ir_module_module;
SELECT 'Permissions fixed successfully!' AS result;

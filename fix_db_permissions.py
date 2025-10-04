import psycopg2
import os
import sys

# Get Railway database credentials from environment or use hardcoded for this fix
db_url = os.environ.get('DATABASE_URL') or 'postgresql://postgres:UovSzBfeGIxGuwmknYrJLCZSWrkNTiRR@nozomi.proxy.rlwy.net:12852/railway'

if not db_url:
    print("ERROR: DATABASE_URL environment variable not set")
    sys.exit(1)

try:
    # Connect to the database
    print("Connecting to Railway PostgreSQL...")
    conn = psycopg2.connect(db_url)
    conn.autocommit = True
    cursor = conn.cursor()
    
    print("\n=== Granting ALL privileges on ALL tables to odoo_user ===")
    
    # Grant privileges on all tables in public schema
    cursor.execute("GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO odoo_user;")
    print("✓ Granted ALL privileges on all tables")
    
    # Grant privileges on all sequences
    cursor.execute("GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO odoo_user;")
    print("✓ Granted ALL privileges on all sequences")
    
    # Grant privileges on all functions
    cursor.execute("GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO odoo_user;")
    print("✓ Granted ALL privileges on all functions")
    
    # Grant usage on schema
    cursor.execute("GRANT USAGE ON SCHEMA public TO odoo_user;")
    print("✓ Granted USAGE on public schema")
    
    # Set default privileges for future objects
    cursor.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO odoo_user;")
    print("✓ Set default privileges for future tables")
    
    cursor.execute("ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO odoo_user;")
    print("✓ Set default privileges for future sequences")
    
    # Change database owner
    cursor.execute("ALTER DATABASE railway OWNER TO odoo_user;")
    print("✓ Changed database owner to odoo_user")
    
    # Verify permissions on a key table
    print("\n=== Verifying permissions ===")
    cursor.execute("SELECT has_table_privilege('odoo_user', 'ir_module_module', 'SELECT');")
    can_select = cursor.fetchone()[0]
    print(f"Can odoo_user SELECT from ir_module_module? {can_select}")
    
    cursor.close()
    conn.close()
    
    print("\n✅ Successfully fixed all database permissions!")
    print("Now redeploy the Odoo service on Railway.")
    
except Exception as e:
    print(f"\n❌ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

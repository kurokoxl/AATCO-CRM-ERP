#!/usr/bin/env python3
"""
Fix the base_registry_signaling error after database restore
"""
import os
import sys

try:
    import psycopg2
except ImportError:
    print("Installing psycopg2-binary...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary"])
    import psycopg2

# Get connection details from Railway environment or use defaults
db_host = os.getenv('PGHOST', 'postgres.railway.internal')
db_port = os.getenv('PGPORT', '5432')
db_name = os.getenv('PGDATABASE', 'railway')
db_user = os.getenv('PGUSER', 'odoo_user')
db_password = os.getenv('PGPASSWORD', 'OdooRailway2025!')

# For external connection, Railway provides a public URL
# We need to get the public connection string
railway_postgres_url = os.getenv('RAILWAY_SERVICE_POSTGRES_URL')
if railway_postgres_url:
    public_host = railway_postgres_url
    # Use the public host if we're connecting from outside Railway
    print(f"Attempting to connect via public host: {public_host}")
    
print(f"Connecting to database '{db_name}' on {db_host}:{db_port} as {db_user}")

try:
    # Try to connect
    conn = psycopg2.connect(
        host=db_host,
        port=db_port,
        database=db_name,
        user=db_user,
        password=db_password,
        connect_timeout=10
    )
    
    print("✓ Connected successfully!")
    
    # Create cursor
    cur = conn.cursor()
    
    # Drop the problematic sequence
    print("\nDropping base_registry_signaling sequence...")
    cur.execute("DROP SEQUENCE IF EXISTS base_registry_signaling CASCADE;")
    conn.commit()
    print("✓ Sequence dropped successfully!")
    
    # Check if it's really gone
    cur.execute("""
        SELECT EXISTS (
            SELECT 1 FROM pg_class 
            WHERE relname = 'base_registry_signaling' 
            AND relkind = 'S'
        );
    """)
    exists = cur.fetchone()[0]
    
    if not exists:
        print("✓ Verified: base_registry_signaling sequence has been removed")
    else:
        print("⚠ Warning: Sequence still exists")
    
    # Get some database stats
    print("\nDatabase information:")
    cur.execute("SELECT version();")
    print(f"  PostgreSQL version: {cur.fetchone()[0]}")
    
    cur.execute("SELECT count(*) FROM pg_tables WHERE schemaname = 'public';")
    table_count = cur.fetchone()[0]
    print(f"  Number of tables: {table_count}")
    
    # Check if key Odoo tables exist
    cur.execute("""
        SELECT tablename FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename IN ('res_users', 'ir_module_module', 'ir_model')
        ORDER BY tablename;
    """)
    key_tables = [row[0] for row in cur.fetchall()]
    if key_tables:
        print(f"  Key Odoo tables found: {', '.join(key_tables)}")
    else:
        print("  ⚠ Warning: Key Odoo tables not found!")
    
    cur.close()
    conn.close()
    
    print("\n✓ Database fix completed successfully!")
    print("\nNext steps:")
    print("1. Update the DB_NAME environment variable in Railway to 'railway'")
    print("2. Redeploy the Odoo service")
    
except psycopg2.OperationalError as e:
    print(f"\n✗ Connection failed: {e}")
    print("\nThis script needs to run FROM WITHIN the Railway environment.")
    print("The database host 'postgres.railway.internal' is only accessible from Railway services.")
    print("\nTo fix this, you need to:")
    print("1. Add this script to your deployment")
    print("2. Run it as a Railway run command or via the Railway shell")
    sys.exit(1)
except Exception as e:
    print(f"\n✗ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

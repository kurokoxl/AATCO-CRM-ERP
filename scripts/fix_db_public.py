#!/usr/bin/env python3
"""
Fix the base_registry_signaling error after database restore
Connects via the public DATABASE_PUBLIC_URL
"""
import sys

try:
    import psycopg2
except ImportError:
    print("Installing psycopg2-binary...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "psycopg2-binary"])
    import psycopg2

# Public connection URL from Railway
DATABASE_PUBLIC_URL = "postgresql://postgres:UovSzBfeGIxGuwmknYrJLCZSWrkNTiRR@nozomi.proxy.rlwy.net:12852/railway"

print(f"Connecting to Railway Postgres database...")

try:
    # Connect using the public URL
    conn = psycopg2.connect(DATABASE_PUBLIC_URL)
    
    print("✓ Connected successfully!")
    
    # Create cursor
    cur = conn.cursor()
    
    # Drop ALL the problematic signaling sequences
    print("\nFinding and dropping ALL Odoo signaling sequences...")
    
    # First, find all signaling sequences
    cur.execute("""
        SELECT relname FROM pg_class 
        WHERE relname LIKE 'base_%signaling%' 
        AND relkind = 'S';
    """)
    sequences_found = [row[0] for row in cur.fetchall()]
    
    if sequences_found:
        print(f"  Found {len(sequences_found)} signaling sequences to drop")
        for seq_name in sequences_found:
            print(f"  Dropping {seq_name}...")
            cur.execute(f"DROP SEQUENCE IF EXISTS {seq_name} CASCADE;")
        
        conn.commit()
        print("✓ All sequences dropped successfully!")
    else:
        print("  No signaling sequences found (already clean)")
    
    # Verify they're gone
    cur.execute("""
        SELECT relname FROM pg_class 
        WHERE relname LIKE 'base_%signaling%' 
        AND relkind = 'S';
    """)
    remaining = [row[0] for row in cur.fetchall()]
    
    if not remaining:
        print("✓ Verified: All signaling sequences have been removed")
    else:
        print(f"⚠ Warning: Some sequences still exist: {', '.join(remaining)}")
    
    # Get some database stats
    print("\nDatabase information:")
    cur.execute("SELECT version();")
    version = cur.fetchone()[0]
    print(f"  PostgreSQL version: {version.split(',')[0]}")
    
    cur.execute("SELECT count(*) FROM pg_tables WHERE schemaname = 'public';")
    table_count = cur.fetchone()[0]
    print(f"  Number of tables: {table_count}")
    
    # Check if key Odoo tables exist
    cur.execute("""
        SELECT tablename FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename IN ('res_users', 'ir_module_module', 'ir_model', 'ir_config_parameter')
        ORDER BY tablename;
    """)
    key_tables = [row[0] for row in cur.fetchall()]
    if key_tables:
        print(f"  Key Odoo tables found: {', '.join(key_tables)}")
    else:
        print("  ⚠ Warning: Key Odoo tables not found!")
    
    # Check for user count
    try:
        cur.execute("SELECT count(*) FROM res_users WHERE active = true;")
        user_count = cur.fetchone()[0]
        print(f"  Active users: {user_count}")
    except:
        print("  Could not query res_users")
    
    cur.close()
    conn.close()
    
    print("\n✓ Database fix completed successfully!")
    print("\nThe Odoo service should now start properly.")
    print("If it doesn't, check the Railway logs for any other errors.")
    
except Exception as e:
    print(f"\n✗ Error: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

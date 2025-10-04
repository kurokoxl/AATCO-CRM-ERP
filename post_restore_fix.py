import os
import psycopg2

DB_URL = os.environ.get("DATABASE_URL") or "postgresql://postgres:UovSzBfeGIxGuwmknYrJLCZSWrkNTiRR@nozomi.proxy.rlwy.net:12852/railway"

with psycopg2.connect(DB_URL) as conn:
    conn.autocommit = True
    with conn.cursor() as cr:
        print("=== res_users head ===")
        cr.execute("SELECT id, login, active FROM res_users ORDER BY id ASC LIMIT 10;")
        for row in cr.fetchall():
            print(row)

        cr.execute("SELECT COUNT(*) FROM res_users WHERE id = 1;")
        exists = cr.fetchone()[0]
        print(f"\nHas superuser (id=1)? {bool(exists)}")

        if not exists:
            print("Superuser missing!\n")
        
        print("\n=== res_lang ===")
        cr.execute("SELECT code, name, active FROM res_lang ORDER BY code;")
        langs = cr.fetchall()
        for row in langs:
            print(row)
        print(f"Total languages: {len(langs)}")

        cr.execute("SELECT COUNT(*) FROM res_lang WHERE active;")
        active_count = cr.fetchone()[0]
        print(f"Active languages: {active_count}")

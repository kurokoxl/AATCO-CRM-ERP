
import os
import psycopg2
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')

class OdooBypass:
    def __init__(self):
        self.db_host = os.environ.get('PGHOST', 'postgres.railway.internal')
        self.db_port = os.environ.get('PGPORT', 5432)
        self.maint_user = os.environ.get('PGUSER', 'postgres')
        self.maint_pass = os.environ.get('PGPASSWORD')
        self.maint_db = os.environ.get('PGDATABASE', 'railway')

    def _get_maint_conn(self):
        """Establishes a connection to the maintenance database."""
        try:
            conn = psycopg2.connect(
                dbname=self.maint_db,
                user=self.maint_user,
                password=self.maint_pass,
                host=self.db_host,
                port=self.db_port
            )
            conn.autocommit = True
            return conn
        except psycopg2.Error as e:
            logging.error(f"Failed to connect to maintenance database '{self.maint_db}': {e}")
            return None

    def drop_db(self, db_name):
        """Drops a specific database."""
        if not db_name:
            logging.error("Database name for dropping not provided.")
            return
        logging.info(f"Attempting to drop database '{db_name}'...")
        with self._get_maint_conn() as conn:
            if conn:
                with conn.cursor() as cursor:
                    try:
                        cursor.execute(f"DROP DATABASE IF EXISTS \"{db_name}\"")
                        logging.info(f"Successfully issued DROP DATABASE command for '{db_name}'.")
                    except psycopg2.Error as e:
                        logging.error(f"Error while trying to drop database '{db_name}': {e}")

# Example of how to run this from the command line:
# python -c "from odoo_bypass import OdooBypass; bypass = OdooBypass(); bypass.drop_db(db_name='AATCO')"

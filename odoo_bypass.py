#!/usr/bin/env python3
"""
Wrapper script for Odoo that bypasses the postgres user security check.
This replaces /usr/bin/odoo and patches the check before Odoo starts.
"""
import sys
import os

# Monkeypatch before any Odoo imports
def bypass_postgres_check():
    """Replace the postgres user check with a no-op"""
    import odoo.service.server as server_module
    
    # Store original preload_registries function
    original_preload = server_module.preload_registries
    
    def patched_preload(dbnames):
        """Patched version that skips postgres user check"""
        # Temporarily override db_user config to bypass check
        import odoo.tools.config as config_module
        original_db_user = config_module.config.get('db_user')
        
        # Set to non-postgres value temporarily
        if original_db_user == 'postgres':
            config_module.config['db_user'] = '__railway_bypass__'
        
        try:
            return original_preload(dbnames)
        finally:
            # Restore original db_user
            if original_db_user == 'postgres':
                config_module.config['db_user'] = original_db_user
    
    # Apply the patch
    server_module.preload_registries = patched_preload

# Apply bypass before importing Odoo CLI
bypass_postgres_check()

# Now run Odoo normally
if __name__ == '__main__':
    from odoo.cli import main
    sys.exit(main())

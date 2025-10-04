# -*- coding: utf-8 -*-
{
    'name': 'Field Service Navigate',
    'version': '18.0.1.0.0',
    'category': 'Services',
    'summary': 'Navigate to partner locations via Google Maps',
    'description': """
        Field Service Navigate
        =======================
        Adds a "Navigate" button to partner records that opens Google Maps
        with directions from your current location to the partner's address.
        
        Works with standard Odoo contacts/partners - no additional modules required.
    """,
    'author': 'Custom',
    'depends': ['base', 'contacts'],
    'data': [
        'views/partner_views.xml',
    ],
    'installable': True,
    'application': False,
    'auto_install': False,
    'license': 'LGPL-3',
}

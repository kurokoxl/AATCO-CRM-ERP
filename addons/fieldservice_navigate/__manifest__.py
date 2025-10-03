# -*- coding: utf-8 -*-
{
    'name': 'Field Service Navigate',
    'version': '18.0.1.0.0',
    'category': 'Field Service',
    'summary': 'Add Navigate button to Field Service Orders',
    'description': """
        Field Service Navigate
        =======================
        Adds a "Navigate" button to Field Service Orders that opens Google Maps
        with directions from your current location to the order's location.
    """,
    'author': 'Custom',
    'depends': ['fieldservice'],
    'data': [
        'views/fsm_order_views.xml',
    ],
    'installable': True,
    'application': False,
    'auto_install': False,
    'license': 'LGPL-3',
}

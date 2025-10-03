#!/usr/bin/env python3
"""Compat shim to dispatch to the stock ``odoo`` executable.

This script used to monkeypatch Odoo's postgres user guard. We now rely on a
dedicated database user, so the bypass is unnecessary. The file remains only to
avoid stale references during transition; it simply forwards all arguments to
the real Odoo entrypoint.
"""

import os
import sys


def main() -> None:
    os.execvp("odoo", ["odoo", *sys.argv[1:]])


if __name__ == "__main__":
    main()

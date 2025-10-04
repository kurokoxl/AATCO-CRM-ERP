"""Restore the local AATCO dump into the Railway database.

This script parses the plain SQL file generated from the pg_dump custom
archive and streams each statement (including COPY blocks) through a
psycopg2 connection so we don't depend on external binaries that have
been flaky in this environment.
"""

from __future__ import annotations

import io
import os
import sys

import psycopg2


SQL_PATH = os.path.join(
    os.path.dirname(__file__),
    "backups",
    "aatco_latest.sql",
)


def main() -> int:
    db_url = os.environ.get("DATABASE_URL") or (
        "postgresql://postgres:UovSzBfeGIxGuwmknYrJLCZSWrkNTiRR@"
        "nozomi.proxy.rlwy.net:12852/railway"
    )

    if not os.path.exists(SQL_PATH):
        print(f"ERROR: SQL dump not found at {SQL_PATH}")
        return 1

    print("Connecting to Railway PostgreSQL...")
    conn = psycopg2.connect(db_url)
    conn.autocommit = False

    try:
        with conn, conn.cursor() as cr, open(SQL_PATH, "r", encoding="utf-8", errors="ignore") as fh:
            statement_lines: list[str] = []
            copy_sql: str | None = None
            copy_payload: list[str] = []
            total_statements = 0
            total_copies = 0

            def log_progress(force: bool = False) -> None:
                if force or (total_statements + total_copies) % 100 == 0:
                    print(
                        f"Progress: statements={total_statements}, copies={total_copies}",
                        flush=True,
                    )

            for line in fh:
                if copy_sql is None:
                    if line.startswith("COPY ") and " FROM stdin;" in line:
                        copy_sql = line.strip()
                        copy_payload = []
                    else:
                        statement_lines.append(line)
                        if line.rstrip().endswith(";"):
                            statement = "".join(statement_lines).strip()
                            statement_lines.clear()
                            if statement:
                                cr.execute(statement)
                                total_statements += 1
                                log_progress()
                else:
                    if line.startswith("\\."):
                        data = "".join(copy_payload)
                        copy_buffer = io.StringIO(data)
                        cr.copy_expert(copy_sql, copy_buffer)
                        total_copies += 1
                        copy_sql = None
                        copy_payload = []
                        log_progress()
                    else:
                        copy_payload.append(line)

            # flush remaining statement if file didn't end with newline
            if statement_lines:
                statement = "".join(statement_lines).strip()
                if statement:
                    cr.execute(statement)
                    total_statements += 1
                    log_progress(force=True)

            conn.commit()
            print(
                f"Executed {total_statements} SQL statements and {total_copies} COPY blocks.",
                flush=True,
            )

    except Exception as exc:  # pragma: no cover - operational script
        conn.rollback()
        print(f"ERROR during restore: {exc}")
        raise
    finally:
        conn.close()

    print("Restore complete!")
    return 0


if __name__ == "__main__":
    sys.exit(main())

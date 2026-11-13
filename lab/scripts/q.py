#!/usr/bin/env python3
"""Run a week's SQL file against the pinned parquet files.

    python scripts/q.py sql/w01_dimension_inventory.sql

SQL files reference `read_parquet('data/raw/yellow_tripdata_*.parquet')`
directly, so they work before any dbt model exists — week 1 should not require
the pipeline to be built first.
"""
from __future__ import annotations

import sys
from pathlib import Path

import duckdb

LAB = Path(__file__).resolve().parents[1]


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    path = Path(sys.argv[1])
    sql = path.read_text()
    con = duckdb.connect()
    rel = con.execute(sql)
    if rel.description is None:
        return 0
    cols = [d[0] for d in rel.description]
    rows = rel.fetchall()
    widths = [max(len(c), *(len(str(r[i])) for r in rows)) if rows else len(c)
              for i, c in enumerate(cols)]
    print("  ".join(c.ljust(widths[i]) for i, c in enumerate(cols)))
    print("  ".join("-" * w for w in widths))
    for row in rows:
        print("  ".join(str(v).ljust(widths[i]) for i, v in enumerate(row)))
    print(f"\n{len(rows)} row(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

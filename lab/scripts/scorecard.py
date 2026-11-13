#!/usr/bin/env python3
"""Print the lab's scorecard, audit and coverage from the built warehouse.

Reading the numbers through one script keeps the output honest: every block
shows its numerator and denominator, and the overall score is printed next to
its coverage and its failed-rule count rather than on its own.

    python scripts/scorecard.py            # everything
    python scripts/scorecard.py --audit    # rules only
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

import duckdb

WAREHOUSE = Path(__file__).resolve().parents[1] / "warehouse.duckdb"


def table(con, sql: str, title: str) -> None:
    print(f"\n{title}\n{'-' * len(title)}")
    rel = con.execute(sql)
    cols = [d[0] for d in rel.description]
    rows = rel.fetchall()
    if not rows:
        print("(no rows)")
        return
    widths = [max(len(c), *(len(str(r[i])) for r in rows)) for i, c in enumerate(cols)]
    print("  ".join(c.ljust(widths[i]) for i, c in enumerate(cols)))
    print("  ".join("-" * w for w in widths))
    for row in rows:
        print("  ".join(str(v).ljust(widths[i]) for i, v in enumerate(row)))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--audit", action="store_true", help="show only the rule audit")
    args = ap.parse_args()

    if not WAREHOUSE.exists():
        sys.exit("no warehouse: run `make build` (or `make check`) first")
    con = duckdb.connect(str(WAREHOUSE), read_only=True)

    try:
        if not args.audit:
            table(con, """
                select month, status, round(overall_score, 4) as score,
                       round(coverage, 2) as coverage, dimensions_measured,
                       failed_rules, critical_failures, certificate_ok
                from dq_overall order by month
            """, "Overall (read with coverage, never alone)")

            table(con, """
                select month, dimension, rules_applied, rules_failed,
                       round(score, 4) as score, worst_rule,
                       round(worst_defect_rate, 5) as worst_rate
                from dq_dimension_scorecard
                order by month, score
            """, "By dimension (worst first)")

            table(con, """
                select month, rule_id, dimension, numerator, denominator,
                       round(defect_rate, 5) as rate, max_rate, status
                from dq_scorecard
                where status <> 'pass'
                order by month, status, defect_rate desc
            """, "Rules that did not pass")

        table(con, """
            select rule_id, dimension, tp, fp, fn, target_rows,
                   round(precision, 2) as precision, round(recall, 2) as recall, verdict
            from dq_rule_audit
            order by verdict, rule_id
        """, "Rule audit (the instrument, measured)")

        table(con, """
            select defect_class, defect_rows, caught_rows, rules_that_fire, verdict
            from dq_class_coverage order by verdict, defect_class
        """, "Defect-class coverage")
    finally:
        con.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

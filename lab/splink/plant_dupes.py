#!/usr/bin/env python3
"""Build a duplicate-infested version of the taxi zone lookup.

Entity resolution needs ground truth to be measurable. TLC's zone table has no
duplicates, so this script plants them: every third zone gets one or two variant
records (typo, abbreviation, case change, missing borough), and every record
carries the `true_location_id` it really belongs to.

This mirrors the job Splink does on an asset or vendor register: the same real
entity arrives spelled three ways, and the question is not "are these strings
equal" but "what is the precision and recall of my linkage".

Deterministic: seeded RNG, same file every run.

    python splink/plant_dupes.py
"""
from __future__ import annotations

import csv
import random
from pathlib import Path

LAB = Path(__file__).resolve().parents[1]
SOURCE = LAB / "data" / "raw" / "taxi_zone_lookup.csv"
OUT = LAB / "splink" / "data" / "zones_dupes.csv"

ABBREVIATIONS = [
    (" St", " Street"),
    (" St.", " Street"),
    (" Ave", " Avenue"),
    (" Rd", " Road"),
    (" Blvd", " Boulevard"),
    (" N ", " North "),
    (" S ", " South "),
    ("E ", "East "),
    ("W ", "West "),
    (" & ", " and "),
]


def typo(name: str, rng: random.Random) -> str:
    if len(name) < 6:
        return name + " "
    i = rng.randrange(1, len(name) - 2)
    return name[:i] + name[i + 1:]


def main() -> None:
    rng = random.Random(42)
    rows = list(csv.DictReader(SOURCE.open()))
    keep = [r for r in rows if r["LocationID"] not in ("264", "265")]

    records: list[dict] = []
    for idx, r in enumerate(keep):
        loc = int(r["LocationID"])
        name = r["Zone"].strip()
        borough = r["Borough"].strip()
        records.append({
            "record_id": f"z{loc:03d}-a",
            "true_location_id": loc,
            "name": name,
            "borough": borough,
        })

        if idx % 3 != 0:
            continue

        variant = name
        for short, long in ABBREVIATIONS:
            if short in variant:
                variant = variant.replace(short, long, 1)
                break
        else:
            variant = typo(variant, rng)

        records.append({
            "record_id": f"z{loc:03d}-b",
            "true_location_id": loc,
            "name": variant.lower() if rng.random() < 0.4 else variant,
            "borough": borough,
        })

        if idx % 9 == 0:
            records.append({
                "record_id": f"z{loc:03d}-c",
                "true_location_id": loc,
                "name": name.upper() + "  ",
                "borough": "",  # missing borough: blocking on it will lose this pair
            })

    OUT.parent.mkdir(parents=True, exist_ok=True)
    with OUT.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=["record_id", "true_location_id", "name", "borough"])
        writer.writeheader()
        writer.writerows(records)

    clusters = {r["true_location_id"] for r in records}
    print(f"wrote {len(records)} records across {len(clusters)} true entities -> {OUT}")


if __name__ == "__main__":
    main()

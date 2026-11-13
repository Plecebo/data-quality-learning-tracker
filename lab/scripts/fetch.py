#!/usr/bin/env python3
"""Download the pinned public files and verify their checksums.

Reproducibility rule for this lab: a number is only meaningful if the bytes
behind it are fixed. The URLs are the publisher's; the sha256 values were
recorded from a real download and are asserted on every fetch, so a silent
republication upstream fails loudly here instead of quietly changing a metric.

    python scripts/fetch.py
"""
from __future__ import annotations

import hashlib
import sys
import urllib.request
from pathlib import Path

DATA = Path(__file__).resolve().parents[1] / "data" / "raw"

FILES = [
    {
        "name": "yellow_tripdata_2024-01.parquet",
        "url": "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2024-01.parquet",
        "sha256": "c4d59da7bbc8abaeeeb1727947ee93d9891a71acb42854bd80db1571b2030510",
        "bytes": 49961641,
    },
    {
        "name": "yellow_tripdata_2025-01.parquet",
        "url": "https://d37ci6vzurychx.cloudfront.net/trip-data/yellow_tripdata_2025-01.parquet",
        "sha256": "9af277e4c0d3f9deb30644da822981e1e7df6af58313170fd3aa8a474485488a",
        "bytes": 59158238,
    },
]


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    DATA.mkdir(parents=True, exist_ok=True)
    for spec in FILES:
        target = DATA / spec["name"]
        if target.exists() and digest(target) == spec["sha256"]:
            print(f"ok       {spec['name']} (checksum matches)")
            continue
        if target.exists():
            print(f"stale    {spec['name']} — checksum mismatch, re-downloading")
        print(f"fetching {spec['name']} ({spec['bytes'] / 1e6:.1f} MB)")
        tmp = target.with_suffix(target.suffix + ".part")
        with urllib.request.urlopen(spec["url"], timeout=120) as resp, tmp.open("wb") as fh:
            while True:
                chunk = resp.read(1 << 20)
                if not chunk:
                    break
                fh.write(chunk)
        actual = digest(tmp)
        if actual != spec["sha256"]:
            tmp.unlink(missing_ok=True)
            print(
                f"FAIL     {spec['name']}\n  expected {spec['sha256']}\n  got      {actual}\n"
                "The publisher changed the file. Do not measure against it until the "
                "checksum and the documented baseline are re-recorded.",
                file=sys.stderr,
            )
            return 1
        tmp.replace(target)
        print(f"ok       {spec['name']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

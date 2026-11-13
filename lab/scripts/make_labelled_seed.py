#!/usr/bin/env python3
"""Generate seeds/labelled_trips.csv — the fixture that scores the rules.

Why a planted fixture exists
----------------------------
A rule is a classifier. To know its precision and recall you need rows whose
true status is known. On the TLC files nobody has labelled 6.4 million trips,
so the lab carries a small set of rows where each defect class is planted on
purpose, plus clean rows that *look* defective to a naive rule (refunds with a
negative fare). That is the only place in this repository where synthetic data
is used, and it is clearly marked.

Run from the lab directory:
    python scripts/make_labelled_seed.py
It is deterministic: same output every time, no randomness.
"""
from __future__ import annotations

import csv
from datetime import datetime, timedelta
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "seeds" / "labelled_trips.csv"

FIELDS = [
    "trip_key", "source_month", "vendor_id", "pickup_at", "dropoff_at",
    "passenger_count", "trip_distance", "ratecode_id", "store_and_fwd_flag",
    "pu_location_id", "do_location_id", "payment_type", "fare_amount", "extra",
    "mta_tax", "tip_amount", "tolls_amount", "improvement_surcharge",
    "total_amount", "congestion_surcharge", "airport_fee", "cbd_congestion_fee",
    "is_defect", "defect_class",
]


def row(
    key: str,
    *,
    month: str = "2024-01",
    vendor: int = 2,
    pickup: datetime | None = None,
    minutes: int = 20,
    passengers: int | None = 1,
    distance: float = 3.2,
    ratecode: int | None = 1,
    flag: str | None = "N",
    pu: int = 161,
    do: int = 237,
    payment: int | None = 1,
    fare: float = 12.50,
    tip: float = 2.5,
    cbd: float | None = None,
    defect: bool = False,
    defect_class: str = "",
    total_override: float | None = None,
    dropoff_override: datetime | None = None,
) -> dict:
    pickup = pickup or datetime(2024, 1, 15, 10, 0, 0)
    dropoff = dropoff_override or (pickup + timedelta(minutes=minutes))
    extra, mta_tax = 1.0, 0.5
    tolls, improvement, congestion, airport = 0.0, 1.0, 2.5, 0.0
    components = (
        fare + extra + mta_tax + tip + tolls + improvement + congestion + airport
        + (cbd or 0.0)
    )
    total = round(total_override if total_override is not None else components, 2)
    return {
        "trip_key": key,
        "source_month": month,
        "vendor_id": vendor,
        "pickup_at": pickup.strftime("%Y-%m-%d %H:%M:%S"),
        "dropoff_at": dropoff.strftime("%Y-%m-%d %H:%M:%S") if dropoff else "",
        "passenger_count": "" if passengers is None else passengers,
        "trip_distance": distance,
        "ratecode_id": "" if ratecode is None else ratecode,
        "store_and_fwd_flag": "" if flag is None else flag,
        "pu_location_id": pu,
        "do_location_id": do,
        "payment_type": "" if payment is None else payment,
        "fare_amount": fare,
        "extra": extra,
        "mta_tax": mta_tax,
        "tip_amount": tip,
        "tolls_amount": tolls,
        "improvement_surcharge": improvement,
        "total_amount": total,
        "congestion_surcharge": congestion,
        "airport_fee": airport,
        "cbd_congestion_fee": "" if cbd is None else cbd,
        "is_defect": "true" if defect else "false",
        "defect_class": defect_class,
    }


rows: list[dict] = []

# --- clean rows -------------------------------------------------------------
for i in range(1, 13):
    rows.append(row(f"clean-{i:03d}"))

# The first clean row is later duplicated on purpose (same six key columns), so
# both copies are labelled as the duplicate defect: the defect belongs to the
# pair, and labelling only the second copy would make an honest rule look
# imprecise.
rows[0]["is_defect"] = "true"
rows[0]["defect_class"] = "duplicate_key"

# Three documented refunds: negative fare, payment_type 3 (no charge) or
# 4 (dispute). These are NOT defects, and a naive `fare_amount < 0` rule
# flags them. This is the false-positive demonstration.
for i, payment in ((13, 3), (14, 3), (15, 4)):
    rows.append(row(f"clean-{i:03d}", payment=payment, fare=-8.0, tip=0.0, distance=0.9))

# A 2025 row with the congestion fee present: proves the scoped rule does not
# fire on a year it applies to.
rows.append(row("clean-2025-ok", month="2025-01", cbd=0.75, pickup=datetime(2025, 1, 9, 8, 30)))
rows.append(row("clean-2025-ok-2", month="2025-01", cbd=0.75, pickup=datetime(2025, 1, 22, 19, 0)))
for i in range(16, 20):
    rows.append(row(f"clean-{i:03d}"))

# --- planted defects --------------------------------------------------------
rows.append(row("def-missing-passengers-1", passengers=None,
                defect=True, defect_class="missing_passenger_count"))
rows.append(row("def-missing-passengers-2", passengers=None, distance=1.4,
                defect=True, defect_class="missing_passenger_count"))
rows.append(row("def-missing-payment", payment=None,
                defect=True, defect_class="missing_payment_type"))
rows.append(row("def-null-dropoff", defect=True, defect_class="null_dropoff"))
# A null drop-off: blank the value rather than passing a datetime.
rows[-1]["dropoff_at"] = ""

rows.append(row("def-cbd-missing", month="2025-01", cbd=None,
                pickup=datetime(2025, 1, 17, 12, 0),
                defect=True, defect_class="cbd_fee_missing"))
rows.append(row("def-vendor-6", vendor=6,
                defect=True, defect_class="undocumented_vendor"))
rows.append(row("def-ratecode-99", ratecode=99,
                defect=True, defect_class="undocumented_ratecode"))
rows.append(row("def-payment-0", payment=0,
                defect=True, defect_class="undocumented_payment_type"))
rows.append(row("def-store-flag", flag="X",
                defect=True, defect_class="bad_store_flag"))
rows.append(row("def-orphan-pickup", pu=999,
                defect=True, defect_class="orphan_pickup_zone"))
rows.append(row("def-orphan-dropoff", do=998,
                defect=True, defect_class="orphan_dropoff_zone"))
rows.append(row("def-negative-duration", minutes=-10,
                defect=True, defect_class="negative_duration"))
rows.append(row("def-total-mismatch", total_override=32.0,
                defect=True, defect_class="fare_sum_mismatch"))
rows.append(row("def-2002-timestamp", pickup=datetime(2002, 12, 31, 22, 59, 39),
                defect=True, defect_class="out_of_window"))
# A duplicate pair: both copies are labelled, because the defect belongs to the
# pair. Labelling only the second copy would make an honest rule look imprecise.
rows.append(row("clean-001", defect=True, defect_class="duplicate_key"))
rows.append(row("def-speed", distance=30.0, minutes=5,
                defect=True, defect_class="implausible_speed"))
rows.append(row("def-sentinel-pickup", pu=264,
                defect=True, defect_class="sentinel_pickup_zone"))
rows.append(row("def-sentinel-dropoff", do=265,
                defect=True, defect_class="sentinel_dropoff_zone"))
rows.append(row("def-negative-fare", fare=-12.0, tip=0.0, payment=1,
                defect=True, defect_class="negative_fare_anomaly"))

assert len(rows) == 40, len(rows)
assert len({r["trip_key"] + r["pickup_at"] for r in rows}) == 39, "one duplicate pair expected"

OUT.parent.mkdir(parents=True, exist_ok=True)
with OUT.open("w", newline="") as fh:
    writer = csv.DictWriter(fh, fieldnames=FIELDS)
    writer.writeheader()
    writer.writerows(rows)
print(f"wrote {len(rows)} rows to {OUT}")

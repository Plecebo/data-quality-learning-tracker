#!/usr/bin/env python3
"""Validate the data contract against the official ODCS JSON Schema.

Two checks, because a schema-valid contract can still be a lie:

1. STRUCTURE — the YAML validates against the vendored ODCS v3.2.0 schema.
2. STORY — every rule id the contract names exists in seeds/trip_rules.csv, so
   the agreement and the executable tests describe the same system.

    python scripts/validate_contract.py
"""
from __future__ import annotations

import csv
import json
import sys
from pathlib import Path

import yaml

LAB = Path(__file__).resolve().parents[1]
CONTRACT = LAB / "contracts" / "tlc_yellow.odcs.yaml"
SCHEMA = LAB / "vendor" / "odcs-json-schema-v3.2.0.json"
RULES = LAB / "seeds" / "trip_rules.csv"


def main() -> int:
    try:
        import jsonschema
    except ImportError:
        print("jsonschema not installed — run `make setup`", file=sys.stderr)
        return 2

    contract = yaml.safe_load(CONTRACT.read_text())
    schema = json.loads(SCHEMA.read_text())
    jsonschema.validate(contract, schema)
    print(f"ok  structure: {CONTRACT.name} validates against ODCS {contract['apiVersion']}")

    documented = {row["rule_id"] for row in csv.DictReader(RULES.open())}
    referenced = set()
    # In ODCS v3.2.0 quality lives on the schema object, not at the contract root.
    for schema_object in contract.get("schema") or []:
        for entry in schema_object.get("quality") or []:
            for prop in entry.get("customProperties") or []:
                if prop.get("property") == "rule_id":
                    referenced.add(prop["value"])

    unknown = referenced - documented
    if unknown:
        print(f"FAIL story: contract references unknown rules: {sorted(unknown)}", file=sys.stderr)
        return 1
    print(f"ok  story: {len(referenced)} rule reference(s) all exist in the registry")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

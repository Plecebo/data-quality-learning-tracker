# Vendored, pinned copies of external specifications.

## odcs-json-schema-v3.2.0.json

- **What:** JSON Schema for the Open Data Contract Standard v3.2.0.
- **Source:** `https://raw.githubusercontent.com/bitol-io/open-data-contract-standard/main/schema/odcs-json-schema-latest.json`
- **Retrieved:** 2026-11-13
- **sha256:** `edb41f33ec46e84780e99872ab2bd67f074959d2bf3e9c9fc54e61f8982b0d93`
- **Licence:** Apache-2.0 (Bitol / LF AI & Data Foundation)

Vendored rather than fetched so that `scripts/validate_contract.py` works
offline and in CI, and so a contract that validated yesterday still validates
against the same schema tomorrow. If the upstream schema changes, that is a
decision to make explicitly — bump the file, its checksum and the `apiVersion`
in the contract together.

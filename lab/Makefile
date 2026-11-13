SHELL := /bin/bash
PY    := .venv/bin/python
DBT   := .venv/bin/dbt
EDR   := .venv/bin/edr
WAREHOUSE ?= $(CURDIR)/warehouse.duckdb
export DQ_WAREHOUSE = $(WAREHOUSE)

.PHONY: help setup data build test scorecard audit elementary splink check clean

help:
	@echo "make setup       create .venv (uv) and install the pinned stack"
	@echo "make data        download + verify the pinned public files (~110 MB)"
	@echo "make build       dbt seed + run + test over the pinned months"
	@echo "make scorecard   print the scorecard, rule audit and class coverage"
	@echo "make audit       print the rule audit only"
	@echo "make elementary  build Elementary's models and write edr_target/elementary_report.html"
	@echo "make splink      entity-resolution quality: fake_1000 and the planted zone fixture"
	@echo "make check       no-data gate: parse, seeds, fixture, audit, registry tests"
	@echo "make clean       remove warehouse, target, logs, dbt_packages"

setup:
	uv venv .venv --python 3.13
	uv pip install --python $(PY) -r requirements.txt
	$(DBT) deps --profiles-dir .

data:
	$(PY) scripts/fetch.py

build: 
	$(DBT) build --profiles-dir .

test:
	$(DBT) test --profiles-dir .

scorecard:
	$(PY) scripts/scorecard.py

audit:
	$(PY) scripts/scorecard.py --audit

# Elementary needs its own models built before it can record anything, and the
# warehouse path must be absolute or edr's bundled dbt project creates a second,
# empty database inside site-packages.
elementary:
	$(DBT) build --select elementary --profiles-dir .
	$(DBT) build --profiles-dir .
	$(EDR) report --profiles-dir . --profile-target dev
	@echo "report: $(CURDIR)/edr_target/elementary_report.html"

splink:
	$(PY) splink/plant_dupes.py
	$(PY) splink/dedupe.py
	$(PY) splink/dedupe.py --dataset zones

# The gate that runs without the 110 MB download: everything that can be
# measured on the committed 40-row fixture and the rule registry.
check:
	$(DBT) parse --profiles-dir .
	$(DBT) build --profiles-dir . \
		--select trip_rules labelled_trips taxi_zone_lookup stg_zones stg_labelled_trips \
		         int_labelled_rule_violations dq_rule_audit dq_class_coverage \
		         assert_registry_matches_predicates assert_registry_hygiene \
		         assert_every_defect_class_is_detected assert_rule_precision_floor
	$(PY) scripts/scorecard.py --audit

clean:
	rm -rf warehouse.duckdb warehouse.duckdb.wal target logs dbt_packages edr_target \
	       splink/data/zones_dupes.csv

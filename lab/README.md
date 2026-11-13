# The lab

A working data-quality measurement environment, built on the tools that run this
kind of work in production: **dbt**, **dbt_expectations**, **Elementary** and
**Splink**. DuckDB is the warehouse so a clone runs on one laptop.

Everything here is real: 6.44 million published trip records, a rule registry of
18 checks across 7 dimensions, and a 40-row labelled fixture that scores the
checks themselves.

## Quickstart

```bash
make setup     # uv venv + pinned stack + dbt deps
make check     # no data needed: parse, seeds, fixture, audit, registry tests
make data      # download + sha256-verify the pinned files (~110 MB)
make build     # dbt build over 2024-01 and 2025-01
make scorecard # the numbers
```

Then, in the order worth reading them:

```bash
make audit       # precision/recall of every rule, and the classes nobody covers
make elementary  # Elementary's models + HTML report in edr_target/
make splink      # linkage quality: ceiling, threshold trade-off, cluster purity
```

## What each tool is doing here

| Tool | Job in this lab |
|---|---|
| **dbt** | the measurement harness: staging → rule violations → scorecard, with tests as the definition of "correct" |
| **dbt_expectations** | property tests on the staged data (ranges, value sets, row counts, uniqueness) — the declarative layer |
| **Elementary** | run history, test-result store, schema-change and volume monitors, and the report a human actually opens |
| **Splink** | entity resolution, measured against known truth: blocking ceiling, precision/recall, cluster purity |

## The layout

```
lab/
├── dbt_project.yml        # vars: which months, the timeliness window, the target score
├── packages.yml           # dbt_utils, dbt_expectations, elementary (pinned)
├── profiles.yml           # two profiles, one DuckDB file; DQ_WAREHOUSE for edr
├── seeds/
│   ├── trip_rules.csv     # the registry: 18 rules, numerator/denominator/rationale
│   ├── dimension_weights.csv
│   └── labelled_trips.csv # 40 rows, 19 planted defects, 3 decoy refunds
├── models/
│   ├── staging/           # stg_trips, stg_zones, stg_labelled_trips + column docs
│   ├── intermediate/      # int_rule_violations, int_labelled_rule_violations
│   ├── quality/           # dq_scorecard → dimension → overall, audit, class coverage
│   └── marts/             # fct_trips (where Elementary monitors attach), dim_zones
├── macros/dq_rules.sql    # the rule predicates (the code half of the registry)
├── tests/                 # registry parity, hygiene, class coverage, precision floor
├── sql/w01..w12           # week → query, with the expected answer recorded
├── scripts/               # fetch (pinned + sha256), scorecard printer, fixture generator
├── splink/                # dedupe.py, plant_dupes.py, vendored fixtures
└── vendor/                # pinned ODCS JSON Schema for contract validation
```

## Three things this lab refuses to fake

1. **A single composite score.** `dq_overall` always prints `coverage`,
   `failed_rules` and `critical_failures` beside the score, and sets
   `certificate_ok` only when all seven dimensions have an applied rule and no
   critical rule failed.
2. **A rule that was never tested.** Every rule is scored against the fixture.
   The deliberately naive negative-fare rule scores precision 0.25 and is
   labelled `noisy` in the output — it ships broken on purpose, because week 5 is
   about fixing it.
3. **A monitor with no history.** `volume_anomalies` has two observations against
   a minimum training set of 14, so it reports insufficient history. That is the
   correct output, not a bug to paper over.

## Known limitations, stated

- The fixture is the only synthetic data in the repository. Rule precision and
  recall need labelled truth; TLC publishes none, so 40 rows were labelled by
  construction (`scripts/make_labelled_seed.py`, deterministic).
- The Splink `zones` exercise trains m from labels and evaluates on the same
  rows, so its numbers are optimistic. Week 7's exercise is to split the fixture
  and re-measure; the `fake` dataset trains unsupervised with EM and does not
  have this problem.
- `fct_trips` timestamps are historical, so freshness monitoring is
  demonstrated on the report rather than on a live SLA.

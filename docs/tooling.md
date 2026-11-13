# Tooling: what each tool does, at which version

This lab is built on the stack that runs data quality in practice, not on a
bespoke engine. Versions below were installed and verified on this machine; the
API notes come from the packages themselves, not from memory.

| Tool | Version | Job here | What it cannot see |
|---|---|---|---|
| **dbt Core** | 1.12.7 | the measurement harness: staging → violations → scorecard, tests as the definition of correct | nothing about data outside the models you built |
| **dbt-duckdb** | 1.11.1 | local warehouse over parquet; no server, no credentials | concurrency, permissions, scale beyond one machine |
| **dbt_utils** | 1.4.1 | generic SQL helpers | — |
| **dbt_expectations** | 0.10.4 (+ dbt_date 0.10.1) | declarative property tests: ranges, value sets, row counts, uniqueness | relationships across sources, history |
| **Elementary** | 0.26.1 | run/test history, schema-change and volume monitors, the report a human opens | the semantics of a change; it reports, it does not judge |
| **Splink** | 5.0.0 | entity resolution, measured against known truth | whether a duplicate actually matters to the business |
| **Great Expectations** | 1.25.0 (not wired) | a comparable assertion framework, used where the estate already has it | same as dbt_expectations, plus its own metadata store to run |
| **Open Data Contract Standard** | 3.2.0 | the contract vocabulary: schema, quality, SLA, ownership | enforcement — it is a specification |

**On dbt v2.** The `dbt` CLI on this machine reports that "dbt v2 is available,
and is the default for new installations". The lab pins Core 1.12.7 deliberately:
the adapter (`dbt-duckdb` 1.11.1) and the two packages this lab depends on are
proven there. Migration is a real decision, not a free upgrade, and it belongs on
the roadmap rather than in a lab README.

---

## dbt: the harness

Three layers, each with one job:

```
staging/      typed, renamed, documented      stg_trips, stg_zones, stg_labelled_trips
intermediate/ one row per (trip, rule)        int_rule_violations
quality/      numerator/denominator per rule  dq_scorecard → dq_dimension_scorecard → dq_overall
marts/        what a consumer queries         fct_trips, dim_zones
```

Why a long `int_rule_violations` table rather than boolean columns: one row per
violation makes the audit a join, keeps the rule list in one place
(`macros/dq_rules.sql`), and lets the identical predicates run against the
labelled fixture. Two models, one definition — that is what makes the rule
measurable at all.

**Data tests (1.12).** dbt renamed "schema tests" to "data tests"; `tests:` is
still accepted as an alias for `data_tests:`. A test is a `select` that returns
failing rows: zero rows is a pass. dbt 1.12 also wants generic-test arguments
nested under `arguments:`, which is why every YAML block in this lab is shaped
that way — the top-level form is deprecated.

**What tests are bad at.** They answer "did the thing I thought of fail". They
cannot tell you a class of defect exists that you did not write a rule for. That
gap is what `dq_class_coverage` closes, against planted defects.

## dbt_expectations: the declarative layer

Used for the properties a consumer would state in a sentence: a distance is not
negative, a code is in a set, a monthly row count is in range, a key is unique.

Two traps this lab hit, and fixed:

1. **`expect_column_values_to_be_in_set` counts NULL as out-of-set.** The
   `store_and_fwd_flag` test reported 680,311 failures — the entire null cohort —
   until it got `row_condition: "store_and_fwd_flag is not null"`. Nulls belong to
   completeness, not conformity.
2. **Warn is an honest severity.** The four warnings in `make build` (143 trips
   over 500 miles, 2 timestamps before 2007, 4 passenger counts over 8, 1
   duplicated key) are real findings. Turning them into errors would stop the
   build; turning them off would hide the data. `warn` is the correct third option,
   provided someone reads the warnings.

## Elementary: history and the human view

Two components: the metadata tables it loads from dbt artifacts, and the tests it
adds (volume, freshness, schema changes, column anomalies, dimension anomalies,
data freshness SLA, execution SLA, metric stability).

What it is genuinely good at, on first contact:

- **Schema change detection.** It compares the current schema to the last run, so
  the 2025 `cbd_congestion_fee` addition is caught without writing a rule.
- **A report a non-engineer can read**, built from the same run results the tests
  produced. No separate instrumentation.

What it honestly cannot do here: **anomaly detection without history.** The lab's
pinned data spans two months, and `volume_anomalies` has a minimum training set of
14 observations. The test reports *insufficient history* — which is the correct
answer and the week 6 lesson. A green tick from a monitor that saw nothing would
be worse than a red one.

Operational detail worth knowing: `edr report` runs dbt from inside its own
package directory, so a relative warehouse path in `profiles.yml` silently creates
a second, empty database. The lab passes an absolute path via `DQ_WAREHOUSE`
(`make elementary`). This is the kind of failure that costs an afternoon and
produces a confusing "table does not exist".

## Splink: measuring a linkage, not just running one

Splink is where "data quality" meets probabilistic reasoning. The lab measures
four things, and the first is the one most projects skip:

1. **Blocking recall ceiling** — 0.692 on `fake_1000`. More than 30% of true pairs
   are discarded before the model runs. No threshold can recover them.
2. **Precision/recall by threshold** — P 0.969 / R 0.562 at 0.50; P 0.997 / R 0.364
   at 0.95. There is no correct threshold, only a stated cost of a false merge
   versus a missed merge.
3. **Cluster purity** — 0.975 of records land in a cluster containing exactly one
   true entity. Pairwise metrics can look healthy while clustering fuses records
   transitively; purity catches it.
4. **The tool's own table**, which uses all N(N−1)/2 pairs as the denominator and
   therefore reports a different precision from (2). Two honest numbers, two
   questions.

Splink 5 API changes that bite if you have Splink 4 code in your fingers:

```python
# registration is explicit; Linker no longer takes db_api=
records = db_api.register(table, dataset_display_name="records")
linker = Linker(records, settings)

# block_on takes separate arguments, not a list
block_on("substr(surname,1,2)", "year(dob)")

# substr() does not bind on a DATE; block on year(dob)
# comparisons used in an EM blocking rule are excluded from that pass
# bf_ prefixes are now mw_; predict()/cluster() return relations in db_api's
# own connection, so query that connection via physical_name
```

## Contracts and SLAs: where measurement becomes an interface

The Open Data Contract Standard v3.2.0 defines the vocabulary a producer and
consumer can agree on: fundamentals, schema, references, **data quality**, support,
pricing, team, roles, **SLA**, servers, authoritative definitions. Its quality
block carries a `dimension` from a seven-value enum — accuracy, completeness,
conformity, consistency, coverage, timeliness, uniqueness — which is why this lab
uses those seven rather than DAMA's six.

That enum is worth noticing: a contract cannot say "validity", so validity becomes
conformity, and a programme migrating from DAMA vocabulary must publish the
crosswalk or argue about words forever.

**SLAs, in the dbt Labs framing:** agreement = availability + freshness + accuracy,
with SLOs as the measurable internal targets and error budgets as the allowance.
The failure mode of data SLAs is writing one that cannot be met or cannot be
measured — a freshness SLA on data that lands monthly is a calendar, not a
commitment. Week 10 asks you to write one that could actually be violated.

## Choosing between them

| If the question is | Use | Because |
|---|---|---|
| "does this property hold?" | dbt test / dbt_expectations | executable, versioned with the model, fails the build |
| "what changed since last run?" | Elementary `schema_changes` | no rule needed; drift is the signal |
| "is this number unusual?" | Elementary anomalies | needs history; good for volume/freshness |
| "how many defects, and how sure?" | dq_scorecard + sampling | numerator/denominator, interval |
| "is my rule any good?" | dq_rule_audit (labelled fixture) | precision/recall, class coverage |
| "are these the same entity?" | Splink + labelled evaluation | probabilistic, measured against truth |
| "what did we promise the consumer?" | ODCS contract + SLA | the agreement is the specification |

None of these is a data quality programme on its own. The programme is the
combination: definitions in a contract, assertions in the pipeline, observability
for the unforeseen, and an audit that scores the whole apparatus.

## Sources

- dbt docs, *Add data tests to your DAG* (renaming note, failing-rows semantics).
- dbt Labs, *Data SLAs best practices* (availability / freshness / accuracy framing).
- Elementary 0.26.1 package (`dbt_packages/elementary`): test macro signatures,
  `edr` CLI behaviour, the `elementary` profile requirement.
- Splink 5.0.0 changelog and release note (API changes above).
- ODCS v3.2.0 README, CHANGELOG and JSON Schema (`lab/vendor/odcs-json-schema-v3.2.0.json`).
- Monte Carlo, *What is data observability* (five pillars: freshness, volume,
  schema, quality/distribution, lineage; data downtime).
- Version numbers: `pip index` / PyPI metadata and `dbt --version` on this machine,
  November 2026.

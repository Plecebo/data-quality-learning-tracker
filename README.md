# Data Quality Learning Track

A 3-month track for learning to **measure the quality of data** — what the dimensions actually mean,
how to turn them into numbers that survive scrutiny, how to test your own checks before you trust
them, and how to keep measuring once the data is live.

Practised on a public, reproducible dataset: NYC TLC yellow-taxi trip records (2.9–3.5 million rows a
month), plus the TLC zone lookup as a reference table. No credentials, no private data — anyone who
clones this repository can reproduce every number in it.

Four parts, each with one job:

| Path | What it is |
|---|---|
| [docs/data-quality-principles.md](docs/data-quality-principles.md) | the models and their disagreements: Wang & Strong, DAMA, ISO/IEC 25012/25024, ISO 8000, ODCS — and what "accuracy" costs to measure |
| [docs/measurement-method.md](docs/measurement-method.md) | the method: operational definitions, indicator forms, thresholds with a reason, sampling and uncertainty, scorecards that don't hide failures |
| [docs/tooling.md](docs/tooling.md) | current practice: dbt, dbt_expectations, Elementary, Splink, Great Expectations — with versions, API traps, contracts, observability and SLAs |
| [docs/data-quality-learning-roadmap.md](docs/data-quality-learning-roadmap.md) | the 12-week roadmap — readings, weekly practice, one check-in artifact per week |
| [DESIGN.md](DESIGN.md), [ledger.md](ledger.md), [rubric.md](rubric.md), [checkin-template.md](checkin-template.md), [weeks/](weeks/), [mastery-tests.md](mastery-tests.md) | the accountability system — did the work happen, and did it get better |
| [lab/](lab/README.md) | **the practice environment**: a working measurement engine, 18 checks over 7 dimensions, a labelled-defect fixture that scores your rules, and DuckDB queries per week |

## Start here

```bash
cd lab
make setup        # uv venv + the pinned stack (dbt, dbt_expectations, Elementary, Splink)
make check        # ~30s, no download: registry, fixture, rule audit, contract
make data         # download the two pinned public files (~110 MB), sha256-verified
make build        # dbt build over 2024-01 and 2025-01: 87 passes, 4 genuine warnings
make scorecard    # the numbers
```

`lab/docs/EXERCISES.md` maps each roadmap week to a runnable command or query, with the *expected*
answer recorded from a real run — so a wrong result is visible, not debatable.

## The one idea this track is built around

> A data-quality check is a classifier, and an unmeasured classifier is a guess.

Most data-quality programmes stop at "did the check pass". This lab makes you measure the check:
every rule is scored against a fixture with planted, labelled defects, giving it a **precision** (how
often a flag is a real defect) and a **recall** (how many real defects it catches). A rule that never
fires is dead weight; a rule that flags 27,000 refunds as "negative fare errors" is a rule that will
be switched off in a week. Both are visible here, in numbers.

```bash
cd lab && make audit    # precision / recall per rule, and the defect classes nobody covered
```

## What this is grounded in

- Measurement theory: Pipino, Lee & Wang (2002), *Data Quality Assessment*, CACM 45(4) — objective
  vs subjective indicators, simple-ratio / min-max / weighted-average forms.
- "Fitness for use": Wang & Strong (1996), *Beyond Accuracy*, JMIS 12(4) — 15 dimensions in four
  categories, judged from the consumer's viewpoint.
- Standards: ISO/IEC 25012:2008 (15 characteristics, inherent vs system-dependent), ISO/IEC 25024
  (measures for those characteristics), ISO 8000-61:2016 (management process), and ISO/IEC 5259-2
  for AI datasets.
- Current practice: the Open Data Contract Standard v3.2.0, dbt data tests, Great Expectations
  (GX Core 1.24), Soda Core 4, and data observability's five pillars (freshness, quality, volume,
  schema, lineage).
- Every claim in `docs/` names its source and its evidence level. Claims that could not be verified
  are labelled as such rather than smoothed over.

## Progress

Progress lives in one place: `ledger.md`, one row per week. The roadmap is the "what", the ledger is
the "did it happen".

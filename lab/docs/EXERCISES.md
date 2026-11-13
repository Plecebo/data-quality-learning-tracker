# Week → exercise

Every week maps to something you run or write. The expected answers below are
recorded from real runs on the pinned files — if you get something else, either
the data changed (check `make data`'s checksum output) or your query is measuring
a different thing. That disagreement is the week's lesson, not a nuisance.

Weeks 4, 8, 11 and 12 are judgement weeks: they produce a written artifact, not a
query. That is deliberate — the hard part of this subject is choosing what to
measure, and no SQL file can do that for you.

| Week | Theme | Run | Expected |
|---|---|---|---|
| 1 | Quality is fitness for use; the dimensions | `python scripts/q.py sql/w01_dimension_inventory.sql` | 4.73% nulls in 2024-01, 15.54% in 2025-01; all five null columns share the same 140,162 / 540,149 rows |
| 2 | Operational definitions in dbt | `make build` then read `models/staging/staging.yml` | vendor 6 (260 rows in 2024-01), vendor 7 (1,206 in 2025-01), ratecode 99 (28,663), payment_type 0 (140,162) |
| 3 | Indicator forms | `python scripts/q.py sql/w03_indicator_forms.sql` | ratio 0.9796 / min-max 0.1073 / weighted 0.9787 for 2024-01 — three numbers, one dataset |
| 4 | **Gate: measurement design** (closed-book) | write the definition card, then `mastery-tests.md` §W4 | numerator, denominator, grain, decision rule, and two error modes the check cannot see |
| 5 | Rule quality: precision and recall | `python scripts/q.py sql/w05_rule_quality.sql`, then `make build && make audit` | 37,448 negative fares; 72% are payment_type 3/4; `cfm_fare_nonnegative` scores precision 0.25, verdict `noisy` |
| 6 | Thresholds from the distribution | `python scripts/q.py sql/w06_thresholds.sql`; `make elementary` | ±$2.50 offset clusters on one vendor (591,045 rows at −2.50); Elementary's volume test reports *insufficient history*, correctly |
| 7 | Sampling and uncertainty | `python scripts/q.py sql/w07_sampling.sql`; `python splink/dedupe.py` | sample 5.0% vs truth 4.73%, Wilson interval 2.15–11.18%; Splink ceiling 0.692, P 0.969 / R 0.562 at 0.50 |
| 8 | **Gate: instrument quality** (transfer test) | predict precision/recall, then measure | every gap > 20 points explained in writing |
| 9 | Integrity vs coverage; uniqueness is key-dependent | `python scripts/q.py sql/w09_integrity_vs_coverage.sql` | 31,527 trips touch zone 264/265, 0 orphans; 1 duplicated pair on the constructed key in 2025-01 |
| 10 | The incident | `python scripts/q.py sql/w10_incident.sql`; then `select rule_id, month, previous_rate, defect_rate, trend from dq_rule_trend where trend <> 'stable'` | schema gains `cbd_congestion_fee`; null cohort 4.73% → 15.54%; vendor 7 appears; `cmp_passenger_count_null` and `cns_total_reconciles` both `worse` |
| 11 | **Capstone** | contract + checks + scorecard + incident + remediation | the full artifact, audited by re-running its queries |
| 12 | **Gate: capstone + retention** | `mastery-tests.md` §W12 | capstone ≥ 2 with one 3; 10-question retention quiz |

## Reading order

1. `docs/data-quality-principles.md` — what the dimensions mean and where the models disagree.
2. `docs/measurement-method.md` — how to turn one into a number that survives review.
3. `docs/tooling.md` — which tool does which job, at which version, and what each cannot see.
4. `docs/data-quality-learning-roadmap.md` — the 12 weeks, with readings.

## The two commands worth running first

```bash
make check     # 30 seconds, no download: proves the registry, the fixture and
               # the audit are coherent, and shows the rule that ships broken
make build     # the full 6.4M-row build: 92 passes, 4 genuine warnings, 0 errors
```

## Then break something

The lab is more useful when you push on it. Three exercises that cost 10 minutes each:

1. Set `cfm_fare_nonnegative`'s `max_rate` to `0.0` in `seeds/trip_rules.csv`, rebuild,
   and watch 2024-01 fail. A threshold is a judgement; this is what changing one does.
2. Delete `cmp_passenger_count_null` from `macros/dq_rules.sql` and rebuild — the
   registry-parity test fails the build. Metadata and code cannot drift silently here.
3. Set `applies_from` on `cmp_cbd_fee_present` to `2024-01`, rebuild, and read the
   failing rule. Then explain, in two sentences, why `not_applicable` is not `pass`.

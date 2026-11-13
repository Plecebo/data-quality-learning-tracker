# Data quality measurement — a 12-week track

Pace assumption: **5–8 hours a week**, one artefact a week, one Sunday check-in
(`checkin-template.md` → `weeks/week-NN.md`, one row into `ledger.md`).

Weeks run Monday–Sunday. Four months, three blocks: **what quality is** (1–4),
**whether your instrument works** (5–8), **operating it** (9–12). Gates at 4, 8
and 12 are closed-book and scored on `rubric.md`.

Everything is practised on the same public dataset — NYC TLC yellow-taxi trips,
2024-01 and 2025-01 — so the weeks compound instead of resetting.

---

## Block 1 — What quality is, and what it costs to measure (weeks 1–4)

### Week 1 — Quality is fitness for use
- **Read:** `docs/data-quality-principles.md` §1–3.
- **Practice:** `make data && python scripts/q.py sql/w01_dimension_inventory.sql`.
- **Artefact:** map each defect you observe to two different dimensions and say
  which vocabulary you used. Note the cohort: five null columns, one cause.
- **The question you should be able to answer:** why is "is this data correct?"
  the wrong first question?

### Week 2 — Operational definitions
- **Read:** `docs/measurement-method.md` §1–3.
- **Practice:** read `seeds/trip_rules.csv` and `macros/dq_rules.sql`; pick one
  rule and rewrite its definition so a stranger could implement it without asking.
- **Artefact:** one definition card (six parts) for a check you wrote, plus the
  dbt test that implements it.
- **Watch for:** a denominator that is "all rows" when it should be "rows where
  the field is contractual".

### Week 3 — Indicator forms and the composite trap
- **Read:** Pipino, Lee & Wang (2002); `docs/data-quality-principles.md` §6.
- **Practice:** `python scripts/q.py sql/w03_indicator_forms.sql`.
- **Artefact:** express one dimension three ways (ratio, min-max, weighted), and
  argue which one you would publish and what the other two hide.

### Week 4 — **GATE: measurement design** (closed-book)
- **Test:** `mastery-tests.md` §W4 — given a dataset and a decision, write the
  operational definition, the check, and two error modes the check cannot see.
- **No reading, no notes, 60–90 minutes.** Pass at ≥ 2 average.

---

## Block 2 — Is your instrument any good? (weeks 5–8)

### Week 5 — Rule quality: precision and recall
- **Read:** `docs/data-quality-principles.md` §7; `docs/measurement-method.md` §5.
- **Practice:** `python scripts/q.py sql/w05_rule_quality.sql`, then
  `make build && make audit`.
- **Artefact:** measure `cfm_fare_nonnegative` (precision 0.25), fix it in
  `macros/dq_rules.sql`, rebuild, and show precision rose without recall falling.
  Then raise the floor in `tests/assert_rule_precision_floor.sql` and say why the
  old floor is no longer defensible.

### Week 6 — Thresholds, and monitors that need history
- **Read:** `docs/measurement-method.md` §4; `docs/tooling.md` §Elementary.
- **Practice:** `python scripts/q.py sql/w06_thresholds.sql`; `make elementary`.
- **Artefact:** a threshold justification for one rule, with the observed
  distribution and the false-alarm cost attached; plus one paragraph on what
  Elementary's *insufficient history* result means and why it is not a failure.

### Week 7 — Sampling, uncertainty, and linkage quality
- **Read:** `docs/measurement-method.md` §7; `docs/tooling.md` §Splink.
- **Practice:** `python scripts/q.py sql/w07_sampling.sql`; `make splink`.
- **Artefact:** size a sample for a ±1-point interval on a 4.7% defect rate, cost
  it in minutes, and compare against just measuring the month. Then explain
  Splink's 0.692 blocking ceiling: what would raise it, and what would it cost?

### Week 8 — **GATE: instrument quality** (transfer test)
- **Test:** `mastery-tests.md` §W8 — on a table you have not used, write three
  checks, predict each one's precision and recall, then measure and explain every
  gap over 20 points.

---

## Block 3 — Operating it (weeks 9–12)

### Week 9 — Integrity, coverage, uniqueness
- **Read:** `docs/data-quality-principles.md` §5.
- **Practice:** `python scripts/q.py sql/w09_integrity_vs_coverage.sql`.
- **Artefact:** one page on why 0 orphans and 31,527 unusable geographies are both
  true, and what a zone-level KPI would have to disclose. Then investigate the one
  duplicated pair in 2025-01: re-submission or key collision? What evidence would
  settle it?

### Week 10 — The incident
- **Read:** `docs/tooling.md` §contracts; `docs/measurement-method.md` §9.
- **Practice:** `python scripts/q.py sql/w10_incident.sql`.
- **Artefact:** a five-part incident write-up (detection, blast radius, root
  cause, remediation, measurement of the fix) for the 4.73% → 15.54% regression,
  plus a freshness SLA you could actually meet or violate.

### Week 11 — Capstone
- **Build:** contract (ODCS) + rule set + scorecard + one incident + remediation,
  on a dataset of your choice — your own work data, another public source, or the
  lab one with a decision you name.
- **Standard:** an auditor can re-run every number from your repository alone.

### Week 12 — **GATE: capstone + retention**
- **Test:** `mastery-tests.md` §W12 — capstone scored (target ≥ 2, one 3), plus a
  10-question retention quiz built from your weekly journal lines.
- **Then:** write the consolidation note and file it in the wiki.

---

## Reading list, in priority order

1. Pipino, Lee & Wang (2002), *Data Quality Assessment*, CACM 45(4). — the
   measurement vocabulary you will use every week.
2. Wang & Strong (1996), *Beyond Accuracy*, JMIS 12(4). — why the consumer's
   definition wins.
3. DAMA UK (2013), *The Six Primary Dimensions for Data Quality Assessment*. —
   short, and the definitions are the ones people quote.
4. ISO/IEC 25012 (data quality model) and ISO/IEC 5259-2 (AI datasets). — read the
   characteristic lists, not the whole standards.
5. ODCS v3.2.0, the *data quality* and *SLA* sections. — the vocabulary a contract
   can carry.
6. dbt docs on data tests; Elementary's test catalogue; Splink's evaluation guide.
   — the three tools you are actually operating.

## Open questions for Larry

1. **Pace is unconfirmed.** 5–8 h/week is an assumption; the ledger's first four
   weeks will show whether it is real. Two missed weeks trigger a scope decision,
   not a guilt loop.
2. **Which dataset for the capstone?** Work data (the CMMS/EAM migration) is the
   highest-value option and the highest-confidentiality one; the lab's public data
   is publishable. This choice changes week 11's artefact, so decide by week 9.
3. **Does this need to be public?** If the capstone uses work data, the repo stays
   private and the portfolio piece is the method plus a public dataset worked
   example.

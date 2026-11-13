# Learning ledger — measuring data quality

One row per week. `Done`: Y / partial / missed. Rubric per `rubric.md`. `Leading
signal` is the forward-looking column — trouble should show up here before it
shows up in `Done`.

Plan starts: 2026-11-16. Assumed pace: 5–8 h/week (unconfirmed — see roadmap open
question 1). Check-ins are Sunday evening, reviewing the week just ending.

| Week | Week of | Done | Rubric 0–3 | Hours (read/prac) | Leading signal | Note |
|---|---|---|---|---|---|---|
| 1 | 2026-11-16 |  |  |  |  |  |
| 2 | 2026-11-23 |  |  |  |  |  |
| 3 | 2026-11-30 |  |  |  |  |  |
| 4 | 2026-12-07 |  |  |  | GATE: measurement design |  |
| 5 | 2026-12-14 |  |  |  |  |  |
| 6 | 2026-12-21 |  |  |  |  |  |
| 7 | 2026-12-28 |  |  |  |  |  |
| 8 | 2027-01-04 |  |  |  | GATE: instrument quality |  |
| 9 | 2027-01-11 |  |  |  | capstone dataset chosen |  |
| 10 | 2027-01-18 |  |  |  |  |  |
| 11 | 2027-01-25 |  |  |  | capstone |  |
| 12 | 2027-02-01 |  |  |  | GATE: capstone + retention |  |

## Baseline recorded before week 1

The instrument this plan is measured with, taken from the lab on 2026-11-13:

- 18 rules, 7 dimensions, all 7 measured (`certificate_ok = true`)
- 2024-01: PASS, overall 0.9937, 0 failures
- 2025-01: WARN, overall 0.9718, 4 failures
- rule audit: 17 of 18 at precision 1.0, one deliberate rule at 0.25 (`noisy`)
- defect-class coverage: 18 of 18 classes covered

Any later claim that "the lab is green" should be read against those numbers.

# Data Quality Learning — Accountability System Design

Companion to `docs/data-quality-learning-roadmap.md` (the "what"). This doc is the "did you actually
do it, and did you get better" layer.

The system is deliberately dogfooded: **the learning plan is itself measured with the seven
dimensions it teaches.** Completion is one dimension. A plan that is 100% complete and 20% applied is
a failed plan, and this design makes that visible instead of letting a streak hide it.

---

## 1. The GQM trace for the learning goal itself

- **Goal:** improve Larry's ability to (a) state what "quality" means for a given dataset, and
  (b) produce measurements of it that another person could audit and reproduce. Purpose: capability.
  Object: Larry's measurement practice. Issue: competence. Viewpoint: Larry (self) + work output.
- **Q1 — Am I doing the work?** → `M1 weekly completion` (weeks completed on schedule / weeks elapsed)
- **Q2 — Is the output any good?** → `M2 artifact score` (0–3 rubric, `rubric.md`)
- **Q3 — Is it sticking?** → `M3 retention score` (spaced re-test at weeks 4/8/12)
- **Q4 — Can I apply it to something real?** → `M4 application score` (capstone, audited by a second
  person who re-runs the queries)
- **Q5 — Are my measurements trustworthy?** → `M5 rule-quality score` (precision/recall of the checks
  written in weeks 5 and 11, from `python -m dq audit`)

M5 is the metric most measurement plans forget. It asks whether the instrument works, not whether
the number was produced.

## 2. The seven dimensions applied to this plan

| Dimension | What it means for the plan | Where it shows up |
|---|---|---|
| **completeness** | Are all 12 weeks' artifacts present? | `ledger.md` Done column |
| **conformity** | Does each artifact meet the rubric's stated form (numbers, sources, counter-example)? | `rubric.md` score |
| **accuracy** | Could another person reproduce the artifact's claims from the repo? | capstone audit, week 11 |
| **consistency** | Do two weeks that use the same definition actually compute it the same way? | week 8 gate |
| **timeliness** | Was the week done in the week, or is there catch-up debt? | ledger `Week of` vs check-in date |
| **uniqueness** | Is the same measurement being re-derived instead of reused? | consolidation note, week 12 |
| **coverage** | Are all seven dimensions exercised at least once? | `dq scorecard` coverage line |

## 3. Where the files live

```
data-quality-learning-tracker/
├── README.md            # index: which doc does what
├── docs/                # the "what": principles, measurement method, monitoring practice, roadmap
├── ledger.md            # one row per week — the single source of progress truth
├── rubric.md            # the 0–3 self-assessment rubric (same scale all 12 weeks)
├── checkin-template.md  # copy per week: weeks/week-01.md .. week-12.md
├── weeks/               # filled check-ins + artifacts live here (or link out)
├── mastery-tests.md     # the week 4/8/12 re-tests and the capstone scoring sheet
└── lab/                 # the practice environment: engine, checks, fixtures, DuckDB queries
                         #   lab/README.md = quickstart, lab/docs/EXERCISES.md = week -> command
```

Plain files, so the tracker survives tool changes and is readable in any editor.

## 4. Weekly check-in (the cadence)

- **When:** Sunday evening, 15–30 minutes.
- **What:** copy `checkin-template.md` into `weeks/week-NN.md`, fill it, append one row to `ledger.md`.
- **The five questions:**
  1. Did the week's reading happen? (yes / partial / no + what got in the way)
  2. Is the check-in artifact done, and where is it? (path or link)
  3. Self-assess the artifact against `rubric.md` (0–3, with one sentence of justification)
  4. Hours spent (reading / practice, separately)
  5. One definition you had to invent this week, and the choice you made inside it — this is the
     journal line that makes week 12's consolidation note trivial to write.
- **Miss rule:** a missed week is recorded as `missed`, not skipped. Two consecutive misses trigger a
  scope decision (drop to the every-other-week pace, or demote a topic to awareness level) rather
  than silent catch-up debt.

## 5. Self-assessment rubric (0–3 per artifact)

Same scale every week so scores are comparable over time. Full anchors in `rubric.md`.

| Score | Meaning |
|---|---|
| **0 — absent** | Artifact not produced |
| **1 — present** | Artifact exists but is generic; could have been written without doing the reading |
| **2 — applied** | Uses the week's framework correctly on the lab dataset; concrete numbers, named columns, reproducible query |
| **3 — critiqued** | Applied *and* self-critiqued: names a weakness in the measure, a way it could be gamed or a false positive it will raise, or a counter-measure |

The 3 anchor is the whole point. Weeks 5, 8 and 10 are explicitly about the weaknesses of measures,
so "critiqued" is the normal outcome for a good artifact, not extra credit.

## 6. Ledger schema (`ledger.md`)

```
| Week | Done (Y/partial/missed) | Rubric 0–3 | Hours (read/prac) | Leading signal | Note |
```

- **Leading signal** = one forward-looking fact ("week 9 dataset not chosen yet"). Completion is
  lagging; this column shows trouble before the week is lost — the leading/lagging distinction from
  week 1, applied to the tracker itself.
- **Note** = the one definition you invented, abbreviated.

## 7. Measuring mastery (weeks 4, 8, 12 gates)

Mastery is not "read the chapter". Three gates, each a written test scored on the shared rubric:

- **Week 4 gate — measurement design (closed-book):** given a dataset and a decision, write the
  operational definition (numerator, denominator, grain, decision rule), one SQL check that
  implements it, and the two error modes the check cannot see. Pass at ≥ 2 average.
- **Week 8 gate — instrument quality (transfer test):** on a table you have not used, write three
  checks, then predict each one's precision and recall before running `dq audit`, and explain every
  gap larger than 20 points. Pass at ≥ 2 average.
- **Week 12 gate — capstone + retention:** the capstone scored on the rubric (target ≥ 2 with at
  least one 3), plus a 10-question mixed self-quiz assembled from the weekly journal lines.

**Retention (spaced):** each gate re-tests the previous gates' skills in one question, so weeks 8 and
12 double as spaced retrieval.

## 8. What this system deliberately does NOT do

- No dashboard for a 12-week personal plan — the ledger is the dashboard.
- No agent-side grading of artifacts: the rubric is self-scored on purpose, because calibration is
  part of the skill. External review happens once, at the week 12 capstone, by re-running the
  artifact's queries.
- No streak mechanics. Two misses trigger one scope decision; three or more means the time budget
  assumption was wrong and the plan itself gets revised.
- No composite "data quality score" without the coverage line and the worst-check line beside it.
  `dq scorecard` refuses to print a certificate when fewer than all seven dimensions are measured.

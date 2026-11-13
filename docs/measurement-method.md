# The measurement method

Nine steps from "we should measure data quality" to a number that survives a
review. Every step names the lab artifact that implements it, so the method is
checkable rather than aspirational.

---

## 0. Name the decision first

A measurement that no decision depends on is a report nobody reads. Write the
decision before the metric:

> "If passenger_completeness drops below 95%, we stop publishing the demand
> dashboard for that month and investigate."

If you cannot name the decision, the honest move is not to measure. This is also
the only step that tells you which dimension matters — the same dataset needs
different measures for a billing use and a capacity-planning use.

## 1. Declare the dataset, its grain, and its key

Grain is the sentence that stops most arguments: **one row per published trip
record**, not "trips". The key is not a detail: TLC publishes no trip id, so the
lab constructs one from six columns (`stg_trips.trip_key`), and every uniqueness
claim is a claim about that construction.

Write both down in the model description. If two people disagree about grain,
they are measuring different populations and will never reconcile their numbers.

## 2. Write operational definitions, not definitions

An operational definition has six parts. Fill all six or you have a slogan:

| Part | Example |
|---|---|
| quantity | defect rate |
| unit | proportion of rows |
| grain | trip record |
| numerator | rows where `passenger_count is null` |
| denominator | all rows in the published month |
| decision rule | fail if > 5% |

The lab enforces this in `seeds/trip_rules.csv`: a rule without a
`numerator_definition`, `denominator_definition`, `max_rate` and a `rationale` of
at least 40 characters fails `assert_registry_hygiene` at build time.

**Denominators are where honesty lives.** `dq_rule_audit` and Splink's own
evaluation table disagree about precision on identical predictions because one
counts only pairs that were compared and the other counts all pairs. Both are
correct; they answer different questions. Say which one you mean.

## 3. Choose the indicator form and say why

Pipino, Lee & Wang (2002) give three forms:

- **simple ratio** — `1 - defects/total`. The default. Use it unless you can say
  why not.
- **min-max** — when the quantity has a meaningful range and both ends are bad.
  Note that it is not comparable across datasets.
- **weighted average** — several measures, weights stated and argued.

`sql/w03_indicator_forms.sql` computes all three for the same quantity and gets
0.9796, 0.1073 and 0.9787. Three defensible numbers from one dataset is not a bug
in the method; it is the reason a bare "quality score" is meaningless.

## 4. Set the threshold from the distribution and the cost asymmetry

Never from a round number. Two inputs, both required:

1. **What the data actually does.** The lab's consistency rule fails on 25.7% of
   2024-01 rows with a tolerance of one cent. Look at the distribution before
   choosing: the disagreement is a ±$2.50 mass on one vendor, so ±2.51 measures
   something real and ±0.01 manufactures 761,838 alerts.
2. **What each error costs.** A false alarm costs attention; a missed defect
   costs a bad decision. If a false alarm costs ten minutes of triage and a miss
   costs a wrong invoice, tolerate more noise than you would for a safety metric.

Record the reasoning in the rule's `rationale`. A threshold with no reason is a
guess with a cron job.

## 5. Score the rules before you trust them

A check is a binary classifier. Measure it:

```
precision = tp / (tp + fp)     recall = tp / (tp + fn)
```

The lab's method: a small fixture with planted defects and known-good decoys
(`seeds/labelled_trips.csv`), the same rule predicates applied to it
(`int_labelled_rule_violations`), and a confusion matrix per rule
(`dq_rule_audit`).

Three verdicts come out of it:

| Verdict | Meaning | What to do |
|---|---|---|
| `noisy` | precision < 0.5 — more flags than defects | fix the rule's definition or retire it |
| `blind` | recall < 0.5 — misses its own target class | widen the definition or add a second rule |
| `never_fires` | no flags at all | the rule is dead weight or scoped out |

`assert_rule_precision_floor` fails the build below precision 0.2. That is a
floor, not a target: it catches a rule that cannot be defended, not one that
needs improving. The lab ships one rule at 0.25 on purpose.

**Why not just label production data?** Because labels are expensive and rare.
Forty constructed rows buy an exact measurement of the instrument; they say
nothing about prevalence in the population. Use both, and never confuse them.

## 6. Roll up with the guards attached

A single score is the most abused object in this field:
it goes up when you delete a rule, and it stays green while a critical rule
fails. `dq_overall` therefore publishes, next to the score:

- `coverage` — dimensions measured / 7
- `failed_rules`, `critical_failures` — the veto
- `certificate_ok` — true only when every dimension has an applied rule **and**
  no critical rule failed

Report the **worst rule** beside the dimension score (`worst_rule`,
`worst_defect_rate`). A mean of 0.98 across seven rules is not good news if one
rule is at 0.30; the mean is hiding the thing you need to fix.

## 7. Sample when the question is a rate, and say how uncertain it is

Full-population rates have no sampling error. They do have definition error, and
they have the problem that "the whole population" is often not the population
that matters.

When you must sample, report an interval. At n=100 with 5 defects, the Wilson 95%
interval is 2.15%–11.18% around a point estimate of 5.0% (the true rate is 4.73%).
That interval can falsify "the rate is above 12%". It cannot certify "the rate is
1%". Sizing follows from which of those claims you actually need:

```
n ≈ z² · p(1-p) / e²      (n ≈ 384 for a ±5-point interval at p=0.5, 95% confidence)
```

`sql/w07_sampling.sql` has the Wilson arithmetic; week 7's exercise is to size a
sample for a ±1-point interval and compare the cost against just measuring the
month.

## 8. Monitor the definitions, not only the data

Once a rule is live, the risks change. The schema will drift, the population will
shift, and the rule will start measuring the wrong thing without failing.

The lab's two monitors for this:

- **Scoped rules.** `cmp_cbd_fee_present` carries `applies_from = 2025-01`. Before
  that date it reports `not_applicable`, not `pass`. The distinction matters: a
  rule that cannot fail because it did not run is not evidence.
- **Schema-change detection.** Elementary's `schema_changes` compares the current
  schema to the previous run. The 2025 `cbd_congestion_fee` column is exactly what
  it exists to catch.

Anomaly detection and assertions are complements, not substitutes. Assertions have
high precision and low recall for failure modes you anticipated; anomaly detection
is the reverse. Neither is a quality programme on its own.

## 9. Close the loop: an incident is a measurement failure too

When a defect reaches a consumer, the post-incident question is not only "what
broke" but "which measure should have caught it, and why didn't it":

1. **Detection** — which rule fired, at which threshold, how long after the data
   landed?
2. **Blast radius** — which downstream numbers moved, and by how much?
3. **Root cause** — one cause or many? The null-cohort query in `w01` is the
   pattern: five columns, one vendor submission.
4. **Remediation** — rule fix, scoping fix, or data fix. Say which one you can
   actually do as the consumer.
5. **Measurement of the fix** — the same rule, same definition, before and after.
   If the definition changed, you have not measured the fix.

Week 10's exercise is a real incident contained in the data: a schema addition
and a completeness regression between two published months.

---

## Anti-patterns, with the lab's counter-example

| Anti-pattern | Why it fails | Counter-example in the lab |
|---|---|---|
| one composite score | improves when rules are deleted | `dq_overall` ships coverage + veto + certificate |
| "all tests pass" | proves only the anticipated classes are absent | `dq_class_coverage` against planted classes |
| % of cells populated | weights rare and critical columns alike | per-attribute numerator/denominator |
| thresholds from round numbers | 0.1% may be noise or harm | ±2.51 derived from the observed distribution |
| accuracy from internal checks | accuracy needs a reference outside the data | `acc_implausible_speed` labelled `PROXY ONLY` |
| more rules = better | a noisy rule trains people to ignore alerts | `cfm_fare_nonnegative` at precision 0.25 |
| sentinel values are valid | 264/265 are keys with no geography | `cov_*` rules separate coverage from integrity |
| "the data is wrong" | names no dimension, no denominator, no owner | the definition card in step 2 |

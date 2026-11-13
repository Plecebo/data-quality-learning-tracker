# Principles of measuring data quality

What "quality" means for data, which models exist, where they disagree, and what it costs to turn
any of it into a number you can defend. `docs/measurement-method.md` is the procedure that follows
from this; `docs/tooling.md` is how it is implemented in the tools this lab uses.

**Evidence levels.** Every claim below is tagged:

- **[standard]** — read in the standard's own text or a published commentary that quotes it.
- **[paper]** — read in the paper.
- **[measured]** — measured on the lab dataset, query included.
- **[secondary]** — reported by a credible secondary source; the primary text was not read.
- **[unverified]** — could not confirm; say so rather than smooth it over.

---

## 1. Quality is fitness for use, not truth

The founding move in the data-quality literature is to stop asking "is this data correct?" and start
asking "is this data fit for this use, for this consumer?" [paper]

Wang & Strong (1996) surveyed data consumers and found 15 dimensions in four categories — intrinsic,
contextual, representational, accessibility — and concluded that accuracy is only one of them, and
not the one consumers weigh most [paper]. Their title says it: *Beyond Accuracy*.

Three consequences follow, and they are the reason this track starts here:

1. **A dataset has no quality in the abstract.** The same 3 million trip records are excellent for
   estimating taxi demand and useless for paying drivers correctly. Any scorecard that does not name
   the use is answering a different question.
2. **The consumer's definition wins.** If the analytics team says "complete" means "has a drop-off
   timestamp", that is the operational definition, even if the vendor disagrees.
3. **Quality is measurable only through a use.** "Fit for use" is not a slogan that excuses
   vagueness; it is what tells you which denominator to choose.

The competing definition — conformance to requirements — is stricter and more operational: quality
is the degree to which data meets stated requirements (ISO 8000's framing, and the practical basis
for data contracts) [standard]. The two definitions are compatible if you treat the requirement as
the written-down form of fitness for use. They diverge when the requirement is stale, which is the
failure mode of every test suite nobody reviews.

## 2. The models, and what they disagree about

There is no canonical list of dimensions. That is not a flaw to be papered over; it is the first
thing a practitioner has to choose, and the choice must be published.

| Model | Dimensions | Point of view |
|---|---|---|
| **Wang & Strong (1996)** | 15, in four categories: intrinsic, contextual, representational, accessibility [paper] | the consumer's perception |
| **DAMA UK (2013)** | completeness, uniqueness, timeliness, validity, accuracy, consistency [standard] | six core dimensions for practice |
| **ISO/IEC 25012 (2008)** | 15 characteristics, split into inherent (accuracy, completeness, consistency, credibility, currentness), system-dependent (availability, portability, recoverability) and both (accessibility, compliance, confidentiality, efficiency, precision, traceability, understandability) [standard] | the data itself vs the system that holds it |
| **ISO 8000-8** | accuracy, completeness, consistency, timeliness, uniqueness, validity [standard] | enterprise master data |
| **ODCS v3.2.0** | accuracy, completeness, conformity, consistency, coverage, timeliness, uniqueness [standard] | contractual checks in a data contract |
| **ISO/IEC 5259-2 (AI/ML)** | inherits 25012/25024 and adds dataset-level characteristics: representativeness, balance, diversity, similarity, relevance, effectiveness, identifiability, auditability [standard] | datasets used to train or evaluate models |

Three disagreements worth knowing:

- **Validity vs conformity.** DAMA calls it validity ("conforms to a set of defined business
  rules"); ODCS calls the same idea conformity. Same measurement, different word. Pick one and map.
- **Coverage is not completeness.** ODCS separates them; DAMA folds coverage into completeness.
  They are different questions: completeness asks whether values are missing, coverage asks whether
  the *entities you need* are present and usable. A location id of 264 ("Unknown") is a
  complete value with no coverage — see §5.
- **Precision and currentness.** ISO 25012 splits detail (precision) and freshness (currentness)
  out as first-class characteristics; ODCS's `timeliness` bundles them. If you are measuring
  either, say which.

The practical rule: **choose one vocabulary, write the crosswalk, and never mix two in one report.**
The lab uses ODCS's seven because that is the vocabulary a data contract can carry; `seeds/dimension_weights.csv`
records the mapping and the weights.

## 3. The seven dimensions, defined so they can be computed

Each definition below is an operational definition, not a dictionary entry: a quantity, a numerator,
a denominator, and an honest statement of what it cannot see.

| Dimension | Definition | Numerator / denominator | Cannot see |
|---|---|---|---|
| **accuracy** | the value correctly represents the real-world event [standard] | requires a reference; not derivable from the data alone | anything, unless you have a reference |
| **completeness** | the attributes you need are populated [standard] | rows with a value / rows where the attribute is required | whether the missing value was optional |
| **conformity** | values obey the declared domain, format, or code set [standard] | values outside the declared set / values present | whether the declared set is still right |
| **consistency** | no contradictions within a row, between rows, or between sources [standard] | rows where A and B disagree / rows where both are present | contradictions in fields you did not pair |
| **coverage** | the population you need is represented and usable [standard] | rows with a usable key / rows needed | whether the missing population is the one that matters |
| **timeliness** | the data is available when it is needed, and describes when it happened [standard] | rows outside the declared window / rows | whether the *process* delivering it is late |
| **uniqueness** | one row per entity, on a stated key [standard] | excess rows (`count(*) - count(distinct key)`) / rows | duplicates under a different key |

Two of those definitions do most of the work in this track:

- **Accuracy is the only dimension that needs the world.** Everything else is internal consistency
  and can be computed from the file. That asymmetry explains why "accuracy" is so often
  mis-reported: it is the expensive one, so programmes quietly substitute a proxy and keep the label.
- **Uniqueness is a claim about a key you chose.** TLC publishes no trip id. The lab's key is six
  columns; "zero duplicates" means "no duplicates on those six columns". Any uniqueness metric is
  half measurement, half definition.

## 4. Accuracy: the dimension that costs money

To measure accuracy you need a reference that is independent of the data under test. There are three
kinds, in ascending order of cost:

1. **A benchmark or authoritative list.** A postal code database, a zone lookup, a published code
   set. Cheap, but it only measures conformance *to that reference* — and if the reference is wrong
   or stale, you have measured the reference.
2. **A physical or system-of-record check.** Weigh the parcel, count the stock, re-read the meter.
   Expensive per record, definitive per record.
3. **An expert-labelled sample.** A human decides, for N records, whether the value is right, against
   a written rule. This is the usual industrial answer, and it is a sampling exercise with a
   confidence interval attached, not a truth machine.

The lab's `acc_implausible_speed` rule is explicitly a **proxy**: an average speed above 80 mph in
NYC traffic is implausible, so the rule stands in for "the distance or the timestamp is wrong". It
is useful and it is not accuracy in the ISO 25012 sense. The roadmap's week 5 exercise is the honest
path: label 100 rows by hand, then measure how well the proxy agrees with the labels.

**[measured]** What a proxy buys you, on the lab data: `acc_implausible_speed` flags 1,107 of
2,964,624 rows in 2024-01 (0.037%). A proxy with a 0.04% hit rate is a needle-finder, not a quality
score — which is fine, as long as the report says so.

## 5. Dimensions are not independent, and their scores do not add

The single most common measurement error in data quality is to treat dimensions as independent
components of a composite. They are not. Three examples from the lab data make the point.

**[measured] One cause, five dimensions.** In 2024-01 exactly 140,162 rows have a null
`passenger_count` — and the same 140,162 rows are null for `RatecodeID`, `store_and_fwd_flag`,
`congestion_surcharge` and `Airport_fee`, with `payment_type = 0`. This is one vendor-submission
defect wearing five column names. Counting it five times, once per completeness rule, inflates the
report and tells the reader nothing new. The lab's registry records the co-occurrence in
`cmp_passenger_count_null`'s rationale so the scorecard reader is not fooled.

**[measured] Referential integrity passes where coverage fails.** Zone ids 264 ("Unknown") and 265
("N/A", outside NYC) are real rows in the published lookup. Every foreign-key check passes; 31,527
trips in 2024-01 (1.06%) still have no usable geography. Two dimensions, two verdicts, same rows.
If you only run the FK check you will report a clean geography dimension.

**[measured] Consistency requires a definition of "parts".** The naive rule "total_amount equals the
sum of the components" fails on 25.7% of 2024-01 rows. It is not the data that is broken: one
vendor's `total_amount` excludes the $2.50 congestion surcharge that the components include, so the
disagreement is a systematic −$2.50 on 591,045 rows and +$2.50 on 129,332. A tolerance of ±2.51
absorbs the known offset; a tolerance picked at ±0.01 would have produced a permanent false alarm
and taught everyone to ignore the rule. **A consistency rule encodes an assumption about field
semantics; when it fires constantly, doubt the assumption before the data.**

The consequence for scorecards: do not sum or average dimension scores as if they were independent
evidence, and never let one composite number stand alone. `dq_overall` therefore publishes
`coverage`, `failed_rules` and `critical_failures` beside the score, and only sets `certificate_ok`
when all seven dimensions have at least one applied rule and no critical rule failed.

## 6. What makes a number a measurement

A number is a measurement when someone else can reproduce it and knows what decision it serves. That
requires, at minimum:

- **a quantity** with a unit (a rate, a count, a duration);
- **a grain** — "one row per trip", not "trips";
- **a numerator and a denominator**, both defined;
- **a decision rule** — the threshold and what happens when it is crossed;
- **an owner** — who acts;
- **a stated tolerance for error**, including sampling error.

Pipino, Lee & Wang (2002) give the three forms objective indicators usually take [paper]:

| Form | Expression | When to use |
|---|---|---|
| simple ratio | `1 - (violations / total)` | the default; a defect rate |
| min-max | `1 - (value - min) / (max - min)` | when the quantity has a meaningful range and both ends are bad |
| weighted average | `Σ wᵢ · mᵢ` | several measures of the same dimension, where the weights are stated and argued |

They also separate **objective** measures (computed from the data) from **subjective** ones
(consumer survey), and **task-independent** from **task-dependent** measures. The distinction that
matters most in practice: subjective measures are not decoration. If your consumers say the data is
unusable while every objective measure is green, the objective set is measuring the wrong thing —
that is the fitness-for-use argument coming back around.

Two properties of the numbers themselves are routinely skipped:

- **Scale.** "Quality = 87" is meaningless without knowing the scale. A rate in [0,1] is
  interpretable; an index is only interpretable next to its calibration and its weights.
- **Uncertainty.** A rate computed over a sample has error. "Zero defects in a sample of 100" is
  consistent with a true defect rate of 3% (95% rule-of-three). Full-population rates (as in this
  lab) have no sampling error, but they have *definition* error — and a rate over 3 million rows
  has no uncertainty at all about the thing it measured, which is often not the thing you wanted.

## 7. A check is a classifier, and an unmeasured classifier is a guess

Every rule — a dbt test, a Soda check, a Great Expectations expectation — is a binary classifier:
it says "this row is (or is associated with) a defect". Once you see it that way, the standard
machinery applies:

- **precision** = of the rows it flags, how many are real defects. Low precision means alert fatigue
  and then silence.
- **recall** = of the real defects, how many it flags. Low recall means the dashboard is green
  during an incident.
- **coverage** = of the *classes* of defect that exist, how many have any detector at all.

The lab's labelled fixture makes these computable. **[measured] `cfm_fare_nonnegative`** flags 4
rows in the fixture to catch 1 real anomaly: precision 0.25, recall 1.0. That is exactly the
behaviour you would see in production on this data, where 27,146 of 37,448 negative fares in
2024-01 are documented refunds (`payment_type` 3 or 4). The rule is not wrong to exist. It is wrong
to trust without a denominator.

This is why `dq_rule_audit` and `dq_class_coverage` are first-class models in the lab rather than a
one-off analysis: **the instrument is part of the measurement.** A programme that tracks data quality
without tracking rule quality is measuring its own optimism.

## 8. What has changed since the standards were written

Three shifts matter for a 2026 practice, and the lab is built around them:

1. **Quality moved left into contracts.** ODCS v3.2.0 makes quality a section of the agreement
   between producer and consumer, alongside schema, SLA and ownership [standard]. The measurement
   becomes part of the interface, not a report someone reads later.
2. **Monitoring became its own discipline.** Data observability's five pillars — freshness, volume,
   schema, distribution ("quality"), lineage — describe what is watched continuously, as opposed to
   what is asserted at build time [secondary]. The two are complements: assertions have high
   precision and low recall for *unknown* failure modes; anomaly detection has the opposite.
3. **AI datasets added properties that rows cannot have.** ISO/IEC 5259-2 measures
   representativeness, balance, diversity and relevance at the dataset level [standard]. No
   row-level test can fail because a sample is unrepresentative. If your quality model tops out at
   row-level rules, it cannot say anything about the thing most likely to be wrong.

## 9. Fallacies to refuse

| Fallacy | Why it fails | What to do instead |
|---|---|---|
| "% of cells populated" | weights a rarely-used column the same as a critical one | per-attribute numerator/denominator, weighted by use |
| one composite quality score | hides which dimension failed and can be improved by deleting rules | score + coverage + worst rule + failed count |
| "all tests pass" | proves only that the tested classes are absent | publish class coverage against a labelled set |
| more rules = better | a noisy rule trains people to ignore alerts | measure precision/recall per rule |
| accuracy from internal checks | accuracy needs a reference outside the data | label a sample; call the rest conformance |
| sentinel values are valid | 264/265 are valid keys with no geography | measure coverage separately from integrity |
| thresholds from round numbers | 0.1% may be below the noise floor or above the harm | derive from the distribution and the cost asymmetry |

## 10. Sources, and what could not be verified

Read for this document:

- Pipino, L., Lee, Y., Wang, R. (2002). *Data Quality Assessment.* Communications of the ACM 45(4).
  Objective/subjective measures; simple ratio, min-max and weighted-average forms. **[paper]**
- Wang, R., Strong, D. (1996). *Beyond Accuracy: What Data Quality Means to Data Consumers.*
  Journal of Management Information Systems 12(4). 15 dimensions, four categories. **[paper]**
- DAMA UK (2013). *The Six Primary Dimensions for Data Quality Assessment.* Definitions of
  completeness, uniqueness, timeliness, validity, accuracy, consistency. **[standard]**
- ISO/IEC 25012:2008, *Data quality model* — 15 characteristics and their inherent /
  system-dependent split, with definitions as quoted by Gualo et al. (2021) and Felderer et al.
  (2019). **[standard]**
- ISO/IEC 25024 — measures for the 25012 characteristics (referenced; the measure catalogue itself
  is paywalled and was not read) **[standard, partially]**
- ISO 8000-61:2016 — data quality management process reference model; ISO 8000-8 dimension set.
  **[standard]**
- ISO/IEC 5259-2 — dataset quality measures for AI/ML; the nine dataset characteristics as
  summarised in CEUR-WS Vol-3916 paper 03. **[standard, via commentary]**
- Open Data Contract Standard v3.2.0 (LF AI & Data / Bitol) — section list and the seven-value
  `dimension` enum in the published JSON Schema. **[standard]**
- NYC TLC *Trip Record Data* page — the publisher's own disclaimer ("TLC makes no representations
  as to the accuracy of these data"), the 2025 `cbd_congestion_fee` addition, and the two-month
  publication delay. **[primary]**

Could not verify, and therefore not asserted anywhere in this repository:

- The full text of ISO/IEC 25012 and ISO/IEC 25024 (paywalled). Characteristic names and definitions
  come from the published commentaries cited above.
- The TLC data dictionary's per-field code tables (the PDF's table did not extract in this research
  pass). Code sets used in the rules are the ones described on the TLC page and observed in the
  data; week 2's exercise is to confirm them against the current dictionary.
- Any claim about which vendor's system produces the ±$2.50 offset. The offset is **[measured]**;
  the attribution is inference, and is labelled as such in `seeds/trip_rules.csv`.

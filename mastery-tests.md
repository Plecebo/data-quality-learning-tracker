# Mastery gates — written tests and scoring (weeks 4, 8, 12)

Score every piece with the shared 0–3 rubric (`rubric.md`). Gate passes at
average ≥ 2. A failed gate means redo the artefact, not repeat the block.

## Week 4 — Measurement design (closed-book)

Given a table you are handed and one decision it should support, write in one
sitting (~60–90 min):

1. The **definition card**: quantity, unit, grain, numerator, denominator,
   decision rule, owner.
2. The **check** that implements it (dbt test, SQL, or a Splink-style rule), and
   the dbt/dbt_expectations form you would actually commit.
3. **Two error modes the check cannot see**, and what you would measure to catch
   them instead.
4. One sentence naming which dimension(s) from your chosen vocabulary this is,
   and why not the neighbouring one.

## Week 8 — Instrument quality (transfer test: unseen table)

On a table you have not used before:

1. Write three checks and, before running anything, **predict each one's precision
   and recall** on a labelled set — or on the fixture, if labels do not exist.
2. Measure them (`dq_rule_audit` or the Splink evaluation table).
3. Explain **every gap larger than 20 points** between prediction and measurement:
   wrong data assumption, wrong denominator, or a genuinely bad rule.
4. State the blocking-equivalent for your rule set: what class of defect could
   never be caught by these three checks?

## Week 12 — Capstone + retention

1. **Capstone** (the portfolio piece): contract + rule set + scorecard + one
   incident + remediation on a dataset you chose. An auditor must be able to
   re-run every number from the repository alone.
   Target: average ≥ 2 with at least one 3.
2. **Retention quiz:** 10 questions assembled from your weekly "one definition I
   had to invent" journal lines — your own weak points, closed-book.
3. Record both, then write the consolidation note for the wiki.

## Score log

| Gate | Date | Pieces & scores | Average | Pass? | Redo notes |
|---|---|---|---|---|---|
| W4 measurement design |  |  |  |  |  |
| W8 instrument quality |  |  |  |  |  |
| W12 capstone |  |  |  |  |  |
| W12 retention quiz (n/10) |  |  |  |  |  |

{{ config(materialized='table') }}

{#
  Dimension rollup. The score is 1 minus the mean defect rate of the rules that
  apply to that month. It is deliberately simple arithmetic on published
  numerators and denominators — not a latent "quality factor" nobody can audit.

  `worst_rule` is here because a mean hides the one rule that is actually
  costing you something.
#}

with scorecard as (

    select * from {{ ref('dq_scorecard') }}

)

select
    month,
    dimension,
    count(*) as rules_total,
    count(*) filter (where not not_applicable) as rules_applied,
    count(*) filter (where passed = false) as rules_failed,
    count(*) filter (where status = 'fail') as rules_failed_hard,
    count(*) filter (where status = 'warn') as rules_warned,
    avg(case when not_applicable then null else defect_rate end) as mean_defect_rate,
    1 - avg(case when not_applicable then null else defect_rate end) as score,
    max(case when not_applicable then null else defect_rate end) as worst_defect_rate,
    arg_max(rule_id, defect_rate) filter (where not not_applicable) as worst_rule
from scorecard
group by month, dimension

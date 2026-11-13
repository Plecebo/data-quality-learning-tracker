{{ config(materialized='table') }}

{#
  The headline number, with its two guards attached.

  A single weighted score is the most abused object in data quality reporting:
  it goes up when you delete a rule, and it stays green while a critical rule
  fails. So this model always publishes, next to the score:
    * dimensions_measured / 7  — how much of the model was actually exercised
    * failed_rules, critical_failures — the veto
    * certificate_ok — true only when every dimension has at least one applied
      rule and no critical rule failed. A score without coverage is not a
      certificate.
#}

with dims as (

    select * from {{ ref('dq_dimension_scorecard') }}

),

weights as (

    select * from {{ ref('dimension_weights') }}

),

agg as (

    select
        d.month,
        sum(w.weight) filter (where d.rules_applied > 0) as measured_weight,
        sum(w.weight * d.score) filter (where d.rules_applied > 0) as weighted_score,
        count(*) filter (where d.rules_applied > 0) as dimensions_measured,
        sum(w.weight) as total_weight
    from dims d
    join weights w using (dimension)
    group by 1

),

rules as (

    select
        month,
        count(*) filter (where passed = false) as failed_rules,
        count(*) filter (where severity = 'critical' and passed = false) as critical_failures,
        count(*) filter (where status = 'warn') as warned_rules
    from {{ ref('dq_scorecard') }}
    group by 1

)

select
    a.month,
    a.dimensions_measured,
    (select count(*) from weights) as dimensions_total,
    a.dimensions_measured::double / (select count(*) from weights) as coverage,
    a.weighted_score / nullif(a.measured_weight, 0) as overall_score,
    r.failed_rules,
    r.critical_failures,
    r.warned_rules,
    case
        when r.critical_failures > 0 then 'FAIL'
        when a.weighted_score / nullif(a.measured_weight, 0) < {{ var('overall_target', 0.98) }} then 'WARN'
        when r.failed_rules > 0 then 'WARN'
        else 'PASS'
    end as status,
    case
        when a.dimensions_measured = (select count(*) from weights)
         and r.critical_failures = 0 then true
        else false
    end as certificate_ok
from agg a
join rules r using (month)

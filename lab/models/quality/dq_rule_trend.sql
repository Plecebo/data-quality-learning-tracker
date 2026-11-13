{{ config(materialized='table') }}

{#
  Month-over-month movement per rule — the number week 10 asks for.

  "The same rule, same definition, before and after" is only answerable if the
  previous rate is computed from the same rule id under the same definition.
  That is what this model does, and why it reads dq_scorecard rather than
  recomputing anything.

  Two deliberate choices:

  * `not_applicable` rows are excluded, not carried forward. A rule scoped by
    applies_from did not run in the earlier month, so treating its earlier
    "rate" as a baseline would invent a zero and call the first real measurement
    a regression. Those rules get `no_baseline` on their first applied month.
  * `stable` is a band, not a point. The threshold is the same 1 percentage
    point tolerance the incident write-up uses; it is a judgement and it is
    named in one place (var trend_epsilon) so it can be argued with.
#}

with applied as (

    select *
    from {{ ref('dq_scorecard') }}
    where not not_applicable

),

with_previous as (

    select
        rule_id,
        dimension,
        severity,
        month,
        status,
        defect_rate,
        max_rate,
        lag(month) over w as previous_month,
        lag(defect_rate) over w as previous_rate,
        lag(status) over w as previous_status
    from applied
    window w as (partition by rule_id order by month)

)

select
    rule_id,
    dimension,
    severity,
    month,
    previous_month,
    previous_status,
    status,
    previous_rate,
    defect_rate,
    defect_rate - previous_rate as delta,
    case
        when previous_rate is null then null
        when previous_rate = 0 then null
        else (defect_rate - previous_rate) / previous_rate
    end as relative_change,
    case
        when previous_rate is null then 'no_baseline'
        when defect_rate - previous_rate > {{ var('trend_epsilon', 0.01) }} then 'worse'
        when previous_rate - defect_rate > {{ var('trend_epsilon', 0.01) }} then 'better'
        else 'stable'
    end as trend,
    max_rate
from with_previous

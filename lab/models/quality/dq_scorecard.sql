{{ config(materialized='table') }}

{#
  The scorecard: one row per (rule, month).

  Every row carries its numerator, its denominator and the rule that produced
  it, so a reader can recompute any number without trusting this model. The
  rate is a defect rate: a rule passes when rate <= max_rate.
#}

with population as (

    select source_month, count(*) as denominator
    from {{ ref('stg_trips') }}
    group by 1

),

violations as (

    select source_month, rule_id, count(distinct trip_key) as numerator
    from {{ ref('int_rule_violations') }}
    group by 1, 2

),

registry as (

    select * from {{ ref('trip_rules') }}

),

joined as (

    select
        r.rule_id,
        r.dimension,
        r.severity,
        r.description,
        r.rationale,
        r.max_rate,
        r.target_class,
        r.applies_from,
        p.source_month as month,
        coalesce(v.numerator, 0) as numerator,
        p.denominator,
        coalesce(v.numerator, 0)::double / p.denominator as defect_rate,
        case
            when r.applies_from is not null and p.source_month < r.applies_from then true
            else false
        end as not_applicable
    from registry r
    cross join population p
    left join violations v
        on v.rule_id = r.rule_id
       and v.source_month = p.source_month

)

select
    rule_id,
    dimension,
    severity,
    description,
    rationale,
    max_rate,
    target_class,
    applies_from,
    month,
    numerator,
    denominator,
    defect_rate,
    not_applicable,
    case
        when not_applicable then null
        else defect_rate <= max_rate
    end as passed,
    case
        when not_applicable then 'not_applicable'
        when defect_rate <= max_rate then 'pass'
        when severity in ('critical', 'error') then 'fail'
        else 'warn'
    end as status
from joined

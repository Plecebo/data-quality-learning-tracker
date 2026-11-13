{{ config(materialized='table') }}

{#
  Defect classes are the unit of coverage that matters: a rule set can look
  healthy and still have one class of defect that nothing detects. This model
  answers "is there a defect with no detector", not "did the rules pass".
#}

with labels as (

    select trip_key, is_defect, defect_class
    from {{ ref('stg_labelled_trips') }}
    where is_defect

),

flagged as (

    select distinct trip_key, rule_id
    from {{ ref('int_labelled_rule_violations') }}

),

per_class as (

    select
        l.defect_class,
        count(distinct l.trip_key) as defect_rows,
        count(distinct f.trip_key) as caught_rows,
        count(distinct l.trip_key) - count(distinct f.trip_key) as missed_rows,
        count(distinct f.rule_id) as rules_that_fire,
        string_agg(distinct f.rule_id, ', ' order by f.rule_id) as detectors
    from labels l
    left join flagged f on f.trip_key = l.trip_key
    group by 1

)

select
    defect_class,
    defect_rows,
    caught_rows,
    missed_rows,
    rules_that_fire,
    detectors,
    caught_rows::double / nullif(defect_rows, 0) as class_coverage,
    case when caught_rows = 0 then 'undetected' else 'covered' end as verdict
from per_class

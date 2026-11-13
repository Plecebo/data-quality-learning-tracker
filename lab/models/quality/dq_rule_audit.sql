{{ config(materialized='table') }}

{#
  The part most quality programmes skip: scoring the rules themselves.

  For each rule the fixture gives a confusion matrix restricted to that rule's
  own target class:

      positives  = rows whose defect_class = this rule's target_class
      tp         = positives the rule flagged
      fn         = positives it missed
      fp         = CLEAN rows it flagged

  Flags on rows belonging to a *different* defect class are neither credited nor
  charged: the row is bad, but not for the reason this rule exists to detect.
  Charging them as false positives would punish a rule for being thorough;
  crediting them as true positives would let a generic rule score well on
  defects it was never designed to find.

  precision = tp/(tp+fp)   recall = tp/(tp+fn)
#}

with labels as (

    select trip_key, is_defect, defect_class
    from {{ ref('stg_labelled_trips') }}

),

flagged as (

    select distinct trip_key, rule_id
    from {{ ref('int_labelled_rule_violations') }}

),

registry as (

    select * from {{ ref('trip_rules') }}

),

matrix as (

    select
        r.rule_id,
        r.dimension,
        r.severity,
        r.max_rate,
        r.target_class,
        count(*) filter (
            where l.defect_class = r.target_class and f.trip_key is not null
        ) as tp,
        count(*) filter (
            where not l.is_defect and f.trip_key is not null
        ) as fp,
        count(*) filter (
            where l.defect_class = r.target_class and f.trip_key is null
        ) as fn,
        count(*) filter (
            where l.is_defect and l.defect_class <> r.target_class
        ) as other_defects,
        count(*) filter (where l.defect_class = r.target_class) as target_rows,
        count(*) filter (where not l.is_defect) as clean_rows
    from registry r
    cross join labels l
    left join flagged f
        on f.trip_key = l.trip_key
       and f.rule_id = r.rule_id
    group by 1, 2, 3, 4, 5

)

select
    rule_id,
    dimension,
    severity,
    target_class,
    tp,
    fp,
    fn,
    target_rows,
    other_defects,
    clean_rows,
    tp + fp as flagged,
    case when tp + fp = 0 then null else tp::double / (tp + fp) end as precision,
    case when tp + fn = 0 then null else tp::double / (tp + fn) end as recall,
    case
        when tp + fp = 0 then 'never_fires'
        when tp::double / (tp + fp) < 0.5 then 'noisy'
        when tp::double / (tp + fn) < 0.5 then 'blind'
        else 'ok'
    end as verdict
from matrix

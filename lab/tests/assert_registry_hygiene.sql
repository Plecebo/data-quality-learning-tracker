{#
  A rule without a reason is a guess with a cron job. This test refuses:
    * a threshold outside [0, 1]
    * a dimension outside the seven the scorecard knows about
    * a severity outside the four the scorecard understands
    * a rationale too short to be an argument
#}

select rule_id, 'threshold_out_of_range' as problem
from {{ ref('trip_rules') }}
where max_rate is null or max_rate < 0 or max_rate > 1

union all

select rule_id, 'unknown_dimension'
from {{ ref('trip_rules') }}
where dimension not in (
    'accuracy', 'completeness', 'conformity', 'consistency',
    'coverage', 'timeliness', 'uniqueness'
)

union all

select rule_id, 'unknown_severity'
from {{ ref('trip_rules') }}
where severity not in ('info', 'warning', 'error', 'critical')

union all

select rule_id, 'rationale_too_short'
from {{ ref('trip_rules') }}
where length(trim(rationale)) < 40

union all

select rule_id, 'missing_operational_definition'
from {{ ref('trip_rules') }}
where length(trim(numerator_definition)) < 5
   or length(trim(denominator_definition)) < 5

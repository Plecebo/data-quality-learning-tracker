{#
  The trend model's arithmetic must hold, and its verdict must agree with it.

  Three ways this could be wrong, all caught here:
    * delta drifting from defect_rate - previous_rate
    * a baseline invented where there was no previous measurement
    * a verdict that contradicts the numbers it was derived from
#}

select rule_id, month, previous_rate, defect_rate, delta, trend, 'delta_mismatch' as problem
from {{ ref('dq_rule_trend') }}
where previous_rate is not null
  and abs(delta - (defect_rate - previous_rate)) > 1e-9

union all

select rule_id, month, previous_rate, defect_rate, delta, trend, 'baseline_invented'
from {{ ref('dq_rule_trend') }}
where previous_rate is not null
  and trend = 'no_baseline'

union all

select rule_id, month, previous_rate, defect_rate, delta, trend, 'baseline_missing'
from {{ ref('dq_rule_trend') }}
where previous_rate is null
  and trend <> 'no_baseline'

union all

select rule_id, month, previous_rate, defect_rate, delta, trend, 'verdict_contradicts_delta'
from {{ ref('dq_rule_trend') }}
where previous_rate is not null
  and (
        (defect_rate - previous_rate > {{ var('trend_epsilon', 0.01) }} and trend <> 'worse')
     or (previous_rate - defect_rate > {{ var('trend_epsilon', 0.01) }} and trend <> 'better')
     or (abs(defect_rate - previous_rate) <= {{ var('trend_epsilon', 0.01) }} and trend <> 'stable')
  )

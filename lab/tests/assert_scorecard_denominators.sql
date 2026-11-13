{#
  A rate without a denominator is a rumour. This test fails the build if a
  scorecard row has no population, or claims more defects than rows.
#}

select rule_id, month, numerator, denominator
from {{ ref('dq_scorecard') }}
where denominator <= 0
   or numerator < 0
   or numerator > denominator

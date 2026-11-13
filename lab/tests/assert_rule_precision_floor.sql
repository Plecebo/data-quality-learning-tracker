{#
  Build-time floor on rule quality. 0.2 is a floor, not a target: it catches a
  rule that flags more noise than signal, and it will pass the deliberately
  naive negative-fare rule (precision 0.25). Week 5's exercise is to raise that
  rule - and then raise this floor.
#}

select rule_id, precision, recall, verdict
from {{ ref('dq_rule_audit') }}
where precision is null
   or precision < 0.2

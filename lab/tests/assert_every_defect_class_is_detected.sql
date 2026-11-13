{#
  No defect class may escape detection. This is the coverage question that a
  pass/fail test suite cannot answer: every rule can pass while an entire class
  of defect goes unseen.
#}

select defect_class, defect_rows, missed_rows, verdict
from {{ ref('dq_class_coverage') }}
where verdict = 'undetected'

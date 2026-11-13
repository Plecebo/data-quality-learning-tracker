{#
  The registry (seeds/trip_rules.csv) and the code (macros/dq_rules.sql) must
  describe the same set of rules. Metadata that drifts from the code is worse
  than no metadata: it documents a check that is not running.
#}

{% set code_rules = rule_predicates() | map(attribute='rule_id') | list %}

with registry as (

    select rule_id from {{ ref('trip_rules') }}

),

code as (

    select rule_id from (
        values
        {% for rule_id in code_rules %}
        ('{{ rule_id }}'){% if not loop.last %},{% endif %}
        {% endfor %}
    ) as t(rule_id)

)

select 'in_code_but_not_in_registry' as problem, rule_id from code
where rule_id not in (select rule_id from registry)

union all

select 'in_registry_but_not_in_code' as problem, rule_id from registry
where rule_id not in (select rule_id from code)

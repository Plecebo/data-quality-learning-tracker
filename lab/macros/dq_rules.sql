{#
  The rule registry's code half.

  Each rule is one predicate over staged trips (alias `t`). The metadata half
  lives in seeds/trip_rules.csv, and tests/assert_registry_matches_predicates.sql
  fails the build if the two lists disagree — a registry that drifts from the
  code is worse than no registry.

  Predicates are kept here rather than in the seed so that a model can be
  compiled and run without the seed having been built first. The trade-off is
  documented in docs/measurement-method.md: one source of truth for logic,
  a second for the metadata humans review.
#}

{% macro rule_predicates() %}
  {#- Vars must be resolved here: a Jinja expression inside a quoted string in
      the list below would be emitted literally, not rendered. -#}
  {%- set window_start = var('window_start', '2024-01-01') -%}
  {%- set window_end = var('window_end', '2025-02-01') -%}
  {#- cfm_fare_nonnegative is deliberately naive: it flags documented refunds.
      Week 5 measures its precision (0.25 on the fixture) and fixes or retires
      it. No Jinja comment may appear inside the list literal below. -#}
  {%- set rules = [
    {
      'rule_id': 'cmp_passenger_count_null',
      'sql': 't.passenger_count is null'
    },
    {
      'rule_id': 'cmp_payment_type_null',
      'sql': 't.payment_type is null'
    },
    {
      'rule_id': 'cmp_dropoff_at_null',
      'sql': 't.dropoff_at is null'
    },
    {
      'rule_id': 'cmp_cbd_fee_present',
      'sql': "t.source_month >= '2025-01' and t.cbd_congestion_fee is null"
    },
    {
      'rule_id': 'cfm_vendor_documented',
      'sql': 't.vendor_id not in (1, 2)'
    },
    {
      'rule_id': 'cfm_ratecode_documented',
      'sql': 't.ratecode_id is not null and t.ratecode_id not in (1, 2, 3, 4, 5, 6)'
    },
    {
      'rule_id': 'cfm_payment_type_documented',
      'sql': 't.payment_type is not null and t.payment_type not in (1, 2, 3, 4, 5, 6)'
    },
    {
      'rule_id': 'cfm_store_fwd_flag_domain',
      'sql': "t.store_and_fwd_flag is not null and t.store_and_fwd_flag not in ('Y', 'N')"
    },
    {
      'rule_id': 'cfm_fare_nonnegative',
      'sql': 't.fare_amount < 0'
    },
    {
      'rule_id': 'cfm_pickup_zone_in_lookup',
      'sql': 'not exists (select 1 from zones z where z.location_id = t.pu_location_id)'
    },
    {
      'rule_id': 'cfm_dropoff_zone_in_lookup',
      'sql': 'not exists (select 1 from zones z where z.location_id = t.do_location_id)'
    },
    {
      'rule_id': 'cns_duration_positive',
      'sql': 't.dropoff_at <= t.pickup_at'
    },
    {
      'rule_id': 'cns_total_reconciles',
      'sql': "abs(t.total_amount - (t.fare_amount + t.extra + t.mta_tax + t.tip_amount
              + t.tolls_amount + t.improvement_surcharge
              + coalesce(t.congestion_surcharge, 0) + coalesce(t.airport_fee, 0)
              + coalesce(t.cbd_congestion_fee, 0))) > 2.51"
    },
    {
      'rule_id': 'tml_pickup_in_window',
      'sql': "t.pickup_at < timestamp '" ~ window_start ~ "'"
             ~ " or t.pickup_at >= timestamp '" ~ window_end ~ "'"
    },
    {
      'rule_id': 'uniq_trip_key_duplicated',
      'sql': 't.trip_key in (select trip_key from duplicated_keys)'
    },
    {
      'rule_id': 'acc_implausible_speed',
      'sql': "t.dropoff_at > t.pickup_at and t.trip_distance > 0"
             ~ " and t.trip_distance / (date_diff('second', t.pickup_at, t.dropoff_at) / 3600.0) > 80"
    },
    {
      'rule_id': 'cov_pickup_zone_usable',
      'sql': 't.pu_location_id in (264, 265)'
    },
    {
      'rule_id': 'cov_dropoff_zone_usable',
      'sql': 't.do_location_id in (264, 265)'
    }
  ] -%}
  {{ return(rules) }}
{% endmacro %}


{#
  Builds the long-form violation table for any relation with the staged
  column contract. Keeping this macro parameterised is what allows the same
  rule definition to be measured on the population (stg_trips) and on the
  labelled fixture (labelled_trips) — a rule you have only ever run against
  one of the two populations is untested.
#}
{% macro violations_from(relation, key_column='trip_key', include_month=true) %}
  {%- set rules = rule_predicates() -%}
with base as (
    select * from {{ relation }}
),
zones as (
    select location_id from {{ ref('stg_zones') }}
),
duplicated_keys as (
    select {{ key_column }} as trip_key
    from base
    group by 1
    having count(*) > 1
),
violations as (
{% for rule in rules %}
    select
        {{ key_column }} as trip_key
        {% if include_month %}, source_month{% endif %},
        '{{ rule['rule_id'] }}' as rule_id
    from base t
    where {{ rule['sql'] }}
    {% if not loop.last %}union all{% endif %}
{% endfor %}
)
select * from violations
{% endmacro %}

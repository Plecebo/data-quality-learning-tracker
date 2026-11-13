{{ config(materialized='table') }}

{# The same rules, measured on rows whose true status is known. #}
{{ violations_from(ref('stg_labelled_trips')) }}

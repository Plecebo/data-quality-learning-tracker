{{ config(materialized='table') }}

{# Long form: one row per (trip, rule) that the trip violates. #}
{{ violations_from(ref('stg_trips')) }}

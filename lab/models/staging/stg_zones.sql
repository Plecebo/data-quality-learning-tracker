{{ config(materialized='view') }}

{#
  The taxi zone lookup: 265 rows, the reference table for location integrity.
  Two of its rows are not places — 264 ("Unknown") and 265 ("N/A", outside NYC).
  Referential integrity therefore passes for those ids while the geography is
  unusable; that gap is what the `cov_*` rules measure. See week 9.
#}

with source as (

    select * from {{ ref('taxi_zone_lookup') }}

)

select
    cast(LocationID as integer) as location_id,
    cast(Borough as varchar) as borough,
    cast(Zone as varchar) as zone,
    cast(service_zone as varchar) as service_zone
from source

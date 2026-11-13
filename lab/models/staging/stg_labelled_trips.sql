{{ config(materialized='view') }}

{#
  The labelled fixture, typed to the same contract as stg_trips so that the
  identical rule definitions can be measured against it. If these columns drift
  from stg_trips, the audit stops meaning anything — which is why the seed's
  schema is asserted in staging.yml.
#}

with source as (

    select * from {{ ref('labelled_trips') }}

)

select
    cast(trip_key as varchar) as trip_key,
    cast(source_month as varchar) as source_month,
    cast(vendor_id as integer) as vendor_id,
    cast(pickup_at as timestamp) as pickup_at,
    cast(dropoff_at as timestamp) as dropoff_at,
    cast(passenger_count as integer) as passenger_count,
    cast(trip_distance as double) as trip_distance,
    cast(ratecode_id as integer) as ratecode_id,
    cast(store_and_fwd_flag as varchar) as store_and_fwd_flag,
    cast(pu_location_id as integer) as pu_location_id,
    cast(do_location_id as integer) as do_location_id,
    cast(payment_type as integer) as payment_type,
    cast(fare_amount as double) as fare_amount,
    cast(extra as double) as extra,
    cast(mta_tax as double) as mta_tax,
    cast(tip_amount as double) as tip_amount,
    cast(tolls_amount as double) as tolls_amount,
    cast(improvement_surcharge as double) as improvement_surcharge,
    cast(total_amount as double) as total_amount,
    cast(congestion_surcharge as double) as congestion_surcharge,
    cast(airport_fee as double) as airport_fee,
    cast(cbd_congestion_fee as double) as cbd_congestion_fee,
    cast(is_defect as boolean) as is_defect,
    cast(defect_class as varchar) as defect_class
from source

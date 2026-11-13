{{ config(materialized='table') }}

{#
  The consumer-facing trip table: staged trips plus the geography a consumer
  would join for themselves, and two derived quantities it would be a mistake
  to recompute differently in every downstream query.

  `implied_mph` is null when the timestamps do not permit a speed. Null is the
  honest value here; a zero would silently join the distribution of real speeds.
#}

with trips as (

    select * from {{ ref('stg_trips') }}

),

zones as (

    select location_id, borough, zone
    from {{ ref('dim_zones') }}

)

select
    t.trip_key,
    t.source_month,
    t.vendor_id,
    t.pickup_at,
    t.dropoff_at,
    t.passenger_count,
    t.trip_distance,
    t.ratecode_id,
    t.store_and_fwd_flag,
    t.pu_location_id,
    t.do_location_id,
    t.payment_type,
    t.fare_amount,
    t.extra,
    t.mta_tax,
    t.tip_amount,
    t.tolls_amount,
    t.improvement_surcharge,
    t.total_amount,
    t.congestion_surcharge,
    t.airport_fee,
    t.cbd_congestion_fee,
    z.borough as pickup_borough,
    z.zone as pickup_zone,
    date_diff('minute', t.pickup_at, t.dropoff_at) as duration_minutes,
    case
        when t.dropoff_at > t.pickup_at and t.trip_distance > 0
        then t.trip_distance / (date_diff('second', t.pickup_at, t.dropoff_at) / 3600.0)
    end as implied_mph
from trips t
left join zones z on z.location_id = t.pu_location_id

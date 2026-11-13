{{ config(materialized='view') }}

{#
  Staged trips: one row per published trip record.

  The two pinned months are read together with `union_by_name` so that the
  2025 addition of `cbd_congestion_fee` shows up as a null column in 2024
  rather than as a broken model. `filename = true` carries the provenance
  through: `source_month` is derived from the file, NOT from the pickup
  timestamp. A trip recorded in the wrong month therefore stays visible as a
  timeliness defect instead of being silently relabelled.
#}

with source as (

    select *
    from read_parquet(
        '{{ var("trips_path") }}',
        union_by_name = true,
        filename = true
    )

),

typed as (

    select
        md5(concat_ws('|',
            cast(VendorID as varchar),
            cast(tpep_pickup_datetime as varchar),
            cast(tpep_dropoff_datetime as varchar),
            cast(PULocationID as varchar),
            cast(DOLocationID as varchar),
            cast(total_amount as varchar)
        )) as trip_key,
        regexp_extract(filename, '([0-9]{4}-[0-9]{2})', 1) as source_month,
        cast(VendorID as integer) as vendor_id,
        cast(tpep_pickup_datetime as timestamp) as pickup_at,
        cast(tpep_dropoff_datetime as timestamp) as dropoff_at,
        cast(passenger_count as integer) as passenger_count,
        cast(trip_distance as double) as trip_distance,
        cast(RatecodeID as integer) as ratecode_id,
        cast(store_and_fwd_flag as varchar) as store_and_fwd_flag,
        cast(PULocationID as integer) as pu_location_id,
        cast(DOLocationID as integer) as do_location_id,
        cast(payment_type as integer) as payment_type,
        cast(fare_amount as double) as fare_amount,
        cast(extra as double) as extra,
        cast(mta_tax as double) as mta_tax,
        cast(tip_amount as double) as tip_amount,
        cast(tolls_amount as double) as tolls_amount,
        cast(improvement_surcharge as double) as improvement_surcharge,
        cast(total_amount as double) as total_amount,
        cast(congestion_surcharge as double) as congestion_surcharge,
        cast("Airport_fee" as double) as airport_fee,
        cast(cbd_congestion_fee as double) as cbd_congestion_fee
    from source

)

select * from typed

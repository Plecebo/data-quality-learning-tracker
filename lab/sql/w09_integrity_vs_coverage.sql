-- Week 9: referential integrity passes where coverage fails.
--
-- 264 ("Unknown") and 265 ("N/A" / outside NYC) are real rows in the published
-- lookup. Every foreign-key check passes for them, and the geography is still
-- unusable.
--
-- Expected (verified 2024-01):
--   trips touching 264 or 265 (either end)   31,527
--   drop-off in 264/265                      28,083
--   pickups in 264                           10,360
--   true orphans (id not in the lookup)           0
--
-- The 0 is the interesting number: the integrity dimension is clean, so a
-- report that only runs the FK check says the geography is fine.

with trips as (
    select * from read_parquet('data/raw/yellow_tripdata_2024-01.parquet')
),

zones as (
    select cast(LocationID as integer) as location_id
    from read_csv_auto('data/raw/taxi_zone_lookup.csv', header = true)
)

select
    count(*) as rows,
    count(*) filter (where PULocationID in (264, 265) or DOLocationID in (264, 265)) as touches_sentinel,
    count(*) filter (where PULocationID = 264) as pickup_unknown,
    count(*) filter (where DOLocationID in (264, 265)) as dropoff_sentinel,
    count(*) filter (where PULocationID not in (select location_id from zones)) as orphan_pickups,
    count(*) filter (where DOLocationID not in (select location_id from zones)) as orphan_dropoffs,
    round(100.0 * count(*) filter (where PULocationID in (264, 265) or DOLocationID in (264, 265)) / count(*), 2)
        as pct_unusable_geography
from trips;

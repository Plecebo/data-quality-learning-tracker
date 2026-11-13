-- Week 3: one defect, three indicators — and the rank order changes.
--
-- The quantity is "trip distance is usable". Define it once, then express it as
--   1. a simple ratio        (the default: 1 - defects/total)
--   2. a min-max indicator   (here: distance scaled into [0,1], capped at 30 mi)
--   3. a weighted average    (share of trips with 0 < distance <= 30)
--
-- Expected: the three indicators disagree in magnitude (0.9796, 0.1073, 0.9787
-- for 2024-01). Same data, three defensible numbers — which is why a single
-- "quality score" is a choice, not a measurement.

with base as (
    select
        regexp_extract(filename, '([0-9]{4}-[0-9]{2})', 1) as source_month,
        trip_distance
    from read_parquet('data/raw/yellow_tripdata_*.parquet', union_by_name = true, filename = true)
),

per_month as (
    select
        source_month,
        count(*) as rows,
        count(*) filter (where trip_distance = 0) as zero_distance,
        avg(least(trip_distance, 30.0) / 30.0) as mean_scaled_distance,
        count(*) filter (where trip_distance > 0 and trip_distance <= 30)::double / count(*) as share_usable
    from base
    group by 1
)

select
    source_month,
    rows,
    zero_distance,
    round(1 - zero_distance::double / rows, 4) as ratio_indicator,
    round(mean_scaled_distance, 4) as minmax_indicator,
    round(share_usable, 4) as weighted_indicator
from per_month
order by source_month;

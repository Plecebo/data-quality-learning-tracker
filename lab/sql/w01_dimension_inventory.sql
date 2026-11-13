-- Week 1: is this data complete? Profit before you measure.
--
-- Expected (verified 2026-11 on the pinned files):
--   2024-01  2,964,624 rows, 140,162 null passenger_count  (4.73%)
--   2025-01  3,475,226 rows, 540,149 null passenger_count  (15.54%)
--
-- Read the second block before believing the first: the nulls are not scattered.

select
    regexp_extract(filename, '([0-9]{4}-[0-9]{2})', 1) as source_month,
    count(*) as rows,
    count(*) filter (where passenger_count is null) as null_passengers,
    round(100.0 * count(*) filter (where passenger_count is null) / count(*), 2) as pct_null
from read_parquet('data/raw/yellow_tripdata_*.parquet', union_by_name = true, filename = true)
group by 1
order by 1;

-- The nulls co-occur. One submission defect, five column names — not five
-- independent completeness failures.
select
    regexp_extract(filename, '([0-9]{4}-[0-9]{2})', 1) as source_month,
    count(*) filter (where passenger_count is null
                       and RatecodeID is null
                       and store_and_fwd_flag is null
                       and congestion_surcharge is null
                       and "Airport_fee" is null) as all_five_null,
    count(*) filter (where payment_type = 0) as payment_type_zero
from read_parquet('data/raw/yellow_tripdata_*.parquet', union_by_name = true, filename = true)
group by 1
order by 1;

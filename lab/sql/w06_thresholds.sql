-- Week 6: thresholds come from the distribution and the cost asymmetry, not from
-- a round number.
--
-- The consistency rule "total_amount = sum of the parts" is the test case.
-- Expected (verified 2024-01), deltas in whole cents:
--     -2.50   591,045 rows
--     +2.50   129,332 rows
--     -4.25    22,451 rows
--     -1.75    18,149 rows
--
-- The ±2.50 mass is a systematic vendor offset, not arithmetic error. Set the
-- tolerance to 2.51 and the rule measures something real; set it to 0.01 and you
-- generate 761,838 alerts, which is how a monitoring programme dies.

with components as (
    select
        regexp_extract(filename, '([0-9]{4}-[0-9]{2})', 1) as source_month,
        round(total_amount - (
            fare_amount + extra + mta_tax + tip_amount + tolls_amount
            + improvement_surcharge + coalesce(congestion_surcharge, 0)
            + coalesce("Airport_fee", 0)
        ), 2) as delta
    from read_parquet('data/raw/yellow_tripdata_*.parquet', union_by_name = true, filename = true)
)

select
    source_month,
    case
        when abs(delta) <= 0.01 then '0.00 (reconciles)'
        when abs(delta) <= 2.51 then '<= 2.51 (known offset)'
        else '> 2.51 (unexplained)'
    end as bucket,
    count(*) as rows
from components
group by 1, 2
order by 1, 2;

-- And the same rows by vendor: the offset is not spread evenly across providers,
-- which is the clue that it is a definitional difference, not a data error.
select
    VendorID,
    count(*) as rows,
    round(avg(total_amount - (
        fare_amount + extra + mta_tax + tip_amount + tolls_amount
        + improvement_surcharge + coalesce(congestion_surcharge, 0)
        + coalesce("Airport_fee", 0)
    )), 2) as mean_delta
from read_parquet('data/raw/yellow_tripdata_2024-01.parquet')
group by 1
order by 2 desc;

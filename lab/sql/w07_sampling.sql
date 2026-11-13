-- Week 7: sampling and uncertainty — what 100 rows can and cannot prove.
--
-- The full population has a 4.73% null rate for passenger_count. Draw a
-- deterministic 100-row sample (no randomness in the lab: take every 29,646th
-- row) and compute a Wilson 95% interval around what the sample shows.
--
-- Expected (verified): sample 5.0% against a population truth of 4.73%, Wilson
-- 95% interval 2.15%–11.18%. That is the point: n=100 can falsify a >12% claim
-- and cannot certify a 1% one.
--
-- Exercise (write it yourself, then compare with the population):
--   1. compute the sample rate and its Wilson interval
--   2. compute the sample size needed for a ±1 point interval at 95%
--   3. decide whether the 2025 regression (4.73% -> 15.54%) needed a sample at
--      all, and say what it would have cost to find it by sampling this table

with numbered as (
    select
        passenger_count,
        row_number() over () as rn
    from read_parquet('data/raw/yellow_tripdata_2024-01.parquet')
),

sample as (
    select passenger_count from numbered where rn % 29646 = 0
),

stats as (
    select
        count(*) as n,
        count(*) filter (where passenger_count is null) as defects,
        count(*) filter (where passenger_count is null)::double / count(*) as p_hat
    from sample
)

select
    n,
    defects,
    round(100 * p_hat, 2) as sample_pct,
    round(100 * (
        p_hat + 1.96 * 1.96 / (2 * n)
        - 1.96 * sqrt((p_hat * (1 - p_hat) + 1.96 * 1.96 / (4 * n)) / n)
    ) / (1 + 1.96 * 1.96 / n), 2) as wilson_low_pct,
    round(100 * (
        p_hat + 1.96 * 1.96 / (2 * n)
        + 1.96 * sqrt((p_hat * (1 - p_hat) + 1.96 * 1.96 / (4 * n)) / n)
    ) / (1 + 1.96 * 1.96 / n), 2) as wilson_high_pct,
    4.73 as population_pct
from stats;

-- Week 10: the incident — a schema change and a completeness regression between
-- two published months.
--
-- Observed (verified):
--   cbd_congestion_fee exists only from 2025-01 (TLC documents the addition)
--   passenger_count nulls: 4.73% -> 15.54%
--   VendorID 7 appears for the first time (1,206 rows)
--   RatecodeID nulls appear with the null cohort
--
-- What to produce (this is the incident write-up, not just the query):
--   1. detection: which rule fired, at which threshold, and when would it fire
--   2. blast radius: what breaks downstream if those 540,149 rows are dropped
--   3. root cause: one cause or many? (the co-occurrence query in w01 is the clue)
--   4. remediation: a rule fix, a scoping fix (applies_from), or a data fix —
--      and which of the three you can actually do as the consumer
--   5. the fix's measurement: the same rule, same definition, before and after

select
    regexp_extract(filename, '([0-9]{4}-[0-9]{2})', 1) as source_month,
    count(*) as rows,
    count(*) filter (where passenger_count is null) as null_passengers,
    count(*) filter (where RatecodeID is null) as null_ratecode,
    count(*) filter (where payment_type = 0) as payment_zero,
    count(*) filter (where cbd_congestion_fee is null) as null_cbd_fee,
    count(distinct VendorID) as vendors,
    count(*) filter (where VendorID not in (1, 2)) as undocumented_vendor_rows
from read_parquet('data/raw/yellow_tripdata_*.parquet', union_by_name = true, filename = true)
group by 1
order by 1;

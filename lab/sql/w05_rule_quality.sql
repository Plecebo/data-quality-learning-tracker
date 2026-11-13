-- Week 5: rule quality — measure the check, not just the data.
--
-- `cfm_fare_nonnegative` (fare_amount < 0) flags 37,448 rows in 2024-01 and
-- 144,118 in 2025-01. Is that 37,448 defects? Answer with payment_type:
--
-- Expected (verified 2024-01):
--   negative fares total                37,448
--   ... payment_type 3 (no charge)       5,740
--   ... payment_type 4 (dispute)        21,406
--   ... payment_type 2 (cash)            8,208
--   ... payment_type 1 (credit)             28
--
-- So 72% of the flags are documented refunds. Now run the audit, which scores
-- the rule against planted truth instead of arguing from plausibility:
--
--     make build && make audit
--     -- look at cfm_fare_nonnegative: precision 0.25, verdict "noisy"
--
-- Then fix the rule in macros/dq_rules.sql (exclude payment_type 3 and 4), rebuild,
-- and confirm precision rises without recall falling.

select
    payment_type,
    count(*) as negative_fares,
    round(100.0 * count(*) / sum(count(*)) over (), 1) as pct_of_flags
from read_parquet('data/raw/yellow_tripdata_*.parquet', union_by_name = true)
where fare_amount < 0
  and regexp_extract(filename, '([0-9]{4}-[0-9]{2})', 1) = '2024-01'
group by 1
order by 2 desc;

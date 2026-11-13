-- Week 2: conformity — declared code sets versus what actually arrives.
--
-- Expected (verified):
--   VendorID   2024-01: 1, 2, and 6 (260 rows)      2025-01: 1, 2, 6 (489), 7 (1,206)
--   RatecodeID 2024-01: 99 (28,663 rows, 28,661 on one vendor)
--   payment_type 0 (140,162 rows in 2024-01) — exactly the null cohort
--
-- A new code is vocabulary drift, not corruption. The rule has to surface it on
-- first appearance without calling it an error.

select 'vendor' as field, VendorID as value,
       regexp_extract(filename, '([0-9]{4}-[0-9]{2})', 1) as source_month,
       count(*) as rows
from read_parquet('data/raw/yellow_tripdata_*.parquet', union_by_name = true, filename = true)
group by 1, 2, 3

union all

select 'ratecode', RatecodeID,
       regexp_extract(filename, '([0-9]{4}-[0-9]{2})', 1),
       count(*)
from read_parquet('data/raw/yellow_tripdata_*.parquet', union_by_name = true, filename = true)
group by 1, 2, 3

union all

select 'payment_type', payment_type,
       regexp_extract(filename, '([0-9]{4}-[0-9]{2})', 1),
       count(*)
from read_parquet('data/raw/yellow_tripdata_*.parquet', union_by_name = true, filename = true)
group by 1, 2, 3

order by field, source_month, rows desc;

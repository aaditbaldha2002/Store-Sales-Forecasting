--PURPOSE: To perform quality checks on the training data to ensure consistency and correctness.


--0. Checking the number of null values in each column
SELECT 
	COUNT(CASE WHEN store IS NULL THEN 1 END) AS store_nulls,
	COUNT(CASE WHEN dept IS NULL THEN 1 END) AS dept_nulls,
	COUNT(CASE WHEN weekly_sales IS NULL THEN 1 END) AS weekly_sales_nulls,
	COUNT(CASE WHEN isholiday IS NULL THEN 1 END) AS isholiday_nulls,
	COUNT(CASE WHEN date IS NULL THEN 1 END) AS date_nulls
FROM raw.train;
--Output: There are no nulls present in any of the columns.

--1. Identify the stores with varying number of entries
SELECT store,COUNT(store) FROM raw.train GROUP BY store ORDER BY store;
--Output: They are having varying number of records for each store.

--2. Checking the number of departemnts present in each store
SELECT store, COUNT(DISTINCT dept) AS num_of_depts FROM raw.train GROUP BY store ORDER BY store;
--Output: They are having varying number of departments in each store.

--3. Checking the number of records according to store-department pair (should be same for each pair)
SELECT store,dept, COUNT(*) AS frequency FROM raw.train GROUP BY store,dept ORDER BY store,dept
--Output: They are having varying number of records for each store-department pair.

--4. Checking the frequency of the frequency of records of the store-department pairs
WITH store_dept_freq AS (
	SELECT store,dept, COUNT(*) AS frequency 
	FROM raw.train GROUP BY store,dept ORDER BY store,dept)

SELECT frequency, COUNT(frequency) FROM store_dept_freq GROUP BY frequency ORDER BY frequency DESC;
--Output: There are varying number of frequencies present for frequency of each store-department pair.


--5.Finding out the number of departments in each store (should be same across stores)
SELECT store, COUNT(DISTINCT dept) FROM raw.train GROUP BY store ORDER BY store;
--Output: They are having varying number of departments in each store.

--6. Checking that each date is 7 days apart for each store-department pair
WITH date_diffs AS (
    SELECT 
        store,
        dept,
        date,
        LEAD(date) OVER (PARTITION BY store, dept ORDER BY date) AS next_date
    FROM raw.train
)
SELECT 
    store,
    dept,
    date,
    next_date,
    -- In Postgres, Date - Date = Integer. No EXTRACT needed.
    (next_date - date) AS days_difference
FROM date_diffs
WHERE next_date IS NOT NULL  -- Exclude the last row of each partition
  AND (next_date - date)!=7 -- Filter to ONLY see the gaps (The Professional move)
ORDER BY days_difference DESC;
--Output: There are some date gaps other than 7 days but they are all multiple of 7.

--7. Calculating the number of weeks needed to be generated to fill the gaps
CREATE TABLE audit.stg_train_gaps AS
WITH date_diffs AS (
    SELECT 
        store,
        dept,
        date,
        LEAD(date) OVER (PARTITION BY store, dept ORDER BY date) AS next_date
    FROM raw.train
)
SELECT 
    store,
    dept,
    date AS gap_start,
    next_date AS gap_end,
    (next_date - date) AS days_missing,
    ((next_date - date) / 7) - 1 AS weeks_to_generate
FROM date_diffs
WHERE next_date IS NOT NULL 
  AND (next_date - date) > 7;

SELECT SUM(weeks_to_generate) AS total_imputed_weeks FROM audit.stg_train_gaps;
--Output: Total 27667 weeks need to be generated to fill the gaps.

--8. Checking the holiday dates consistency across departments of same store
WITH holiday_dates AS (
    SELECT DISTINCT
        store,
        dept,
        date
    FROM raw.train
    WHERE isholiday IS TRUE
),
dept_holiday_counts AS (
    SELECT
        store,
        dept,
        COUNT(DISTINCT date) AS holiday_cnt
    FROM holiday_dates
    GROUP BY store, dept
),
store_consistency AS (
    SELECT
        store,
        CASE
            WHEN MIN(holiday_cnt) = MAX(holiday_cnt)
            THEN 'Consistent'
            ELSE 'Not Consistent'
        END AS holiday_date_consistency
    FROM dept_holiday_counts
    GROUP BY store
)
SELECT *
FROM store_consistency
ORDER BY store;
--Output: All the stores are NOT CONSISTENT with holiday dates across departments.
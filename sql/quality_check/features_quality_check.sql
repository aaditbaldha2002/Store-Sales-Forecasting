--PURPOSE: To perform quality checks on the features data to ensure consistency and correctness.

--1. Identify the stores with varying number of entries
SELECT store,COUNT(store) FROM raw.features GROUP BY store ORDER BY store;
--Output: all the stores have same number of records

--2. Checking the number of records according to date (should be equal to number of stores)
SELECT date,COUNT(date) FROM raw.features GROUP BY date ORDER BY date;
--Output: all the dates have same number of records

--3. Checking the number of holidays being true across different stores on a particular date (should be equal to number of stores)
WITH holiday_freq AS (SELECT 
    date, 
    COUNT(DISTINCT isholiday) AS holiday_variants,
    SUM(CASE WHEN isholiday THEN 1 ELSE 0 END) AS true_count,
    SUM(CASE WHEN NOT isholiday THEN 1 ELSE 0 END) AS false_count
FROM raw.features
GROUP BY date
)

SELECT * FROM holiday_freq WHERE true_count>1;

--4. Checking the consistency of holidays across the years 
-- **Super Bowl:** Feb 12 (2010), Feb 11 (2011), Feb 10 (2012), Feb 08 (2013)
-- **Labor Day:** Sept 10 (2010), Sept 09 (2011), Sept 07 (2012)
-- **Thanksgiving:** Nov 26 (2010), Nov 25 (2011), Nov 23 (2012)
-- **Christmas:** Dec 31 (2010), Dec 30 (2011), Dec 28 (2012)
SELECT date FROM raw.features WHERE isholiday=true GROUP BY date ORDER BY date;
--Output: All the holidays are consistent across the years

--5. Checking for null values in the features table
SELECT
    COUNT(CASE WHEN store IS NULL THEN 1 END) AS store_nulls,
    COUNT(CASE WHEN date IS NULL THEN 1 END) AS date_nulls,
    COUNT(CASE WHEN fuel_price IS NULL THEN 1 END) AS fuel_price_nulls,
	COUNT(CASE WHEN markdown1 IS NULL THEN 1 END) AS markdown1_nulls,
	COUNT(CASE WHEN markdown2 IS NULL THEN 1 END) AS markdown2_nulls,
	COUNT(CASE WHEN markdown3 IS NULL THEN 1 END) AS markdown3_nulls,
	COUNT(CASE WHEN markdown4 IS NULL THEN 1 END) AS markdown4_nulls,
	COUNT(CASE WHEN markdown5 IS NULL THEN 1 END) AS markdown5_nulls,
	COUNT(CASE WHEN cpi IS NULL THEN 1 END) AS cpi_nulls,
	COUNT(CASE WHEN unemployment IS NULL THEN 1 END) AS unemployment_nulls,
	COUNT(CASE WHEN isholiday IS NULL THEN 1 END) AS isholiday_nulls
FROM raw.features;
--Output: There are null values present in markdown columns,cpi and unemployment columns.

--6. Checking the date gaps in the feature tables
WITH date_diffs AS (
    SELECT
        store,
        date,
        LEAD(date) OVER (PARTITION BY store ORDER BY date) AS next_date,
        LEAD(date) OVER (PARTITION BY store ORDER BY date) - date AS diff_days
    FROM raw.features
)
SELECT
    store,
    CASE 
        WHEN MIN(diff_days) = 7 AND MAX(diff_days) = 7 THEN 'Consistent'
        ELSE 'Not Consistent'
    END AS seven_day_gap_status
FROM date_diffs
WHERE next_date IS NOT NULL
GROUP BY store
ORDER BY store;
--Output: All the stores have consistent 7 day gaps between dates.
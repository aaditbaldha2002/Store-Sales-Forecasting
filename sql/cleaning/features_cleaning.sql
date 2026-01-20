-- 1. Create a workspace for cleaned data
CREATE SCHEMA IF NOT EXISTS clean;

-- 2. Drop if exists to make the script idempotent (re-runnable)
DROP TABLE IF EXISTS clean.features;

-- 3. Materialize the cleaned data
CREATE SCHEMA IF NOT EXISTS clean;

CREATE TABLE clean.features AS
SELECT 
    store,
    date,
    temperature,
    fuel_price,
    COALESCE(markdown1,0) AS markdown1,
    COALESCE(markdown2,0) AS markdown2,
    COALESCE(markdown3,0) AS markdown3,
    COALESCE(markdown4,0) AS markdown4,
    COALESCE(markdown5,0) AS markdown5,
    (COALESCE(markdown1,0) + COALESCE(markdown2,0) + COALESCE(markdown3,0) + COALESCE(markdown4,0) + COALESCE(markdown5,0)) AS total_markdown,
    cpi,
    unemployment,
    isholiday
FROM raw.features;

SELECT * FROM clean.features LIMIT 5;

--4. Confirming that the null start and end dates for cpi values are same across the stores
SELECT store,MIN(date) AS null_start_date,MAX(date) AS null_end_date
	FROM clean.features 
	WHERE cpi IS NULL
	GROUP BY store 
	ORDER BY store;
--Output: The null start and end dates for cpi values are same across the stores.

--5. Confirming if there is no different null value start and end dates for any stores in the cpi feature column
WITH null_dates AS(
	SELECT store,MIN(date) AS null_start_date,MAX(date) AS null_end_date
	FROM clean.features 
	WHERE cpi IS NULL
	GROUP BY store 
	ORDER BY store)

SELECT COUNT(DISTINCT null_start_date) AS num_null_start_date,
COUNT(DISTINCT null_end_date) AS num_null_end_date 
FROM null_dates;
--Output: There is only one unique null start date and one unique null end date for cpi feature column across all stores.

--6. Confirming that the null start and end dates for unemployment values are same across the stores
SELECT store,MIN(date) AS null_start_date,MAX(date) AS null_end_date
	FROM clean.features 
	WHERE unemployment IS NULL
	GROUP BY store 
	ORDER BY store;
--Output: The null start and end dates for unemployment values are same across the stores.

--7. Confirming if there is no different null value start and end dates for any stores in the unemployment feature column
WITH null_dates AS(
	SELECT store,MIN(date) AS null_start_date,MAX(date) AS null_end_date
	FROM clean.features 
	WHERE unemployment IS NULL
	GROUP BY store 
	ORDER BY store)

SELECT COUNT(DISTINCT null_start_date) AS num_null_start_date,
COUNT(DISTINCT null_end_date) AS num_null_end_date 
FROM null_dates;
--Output: There is only one unique null start date and one unique null end date for unemployment feature column across all stores.

--8. Confirming the number of null value cpi records are consistent across all the stores
SELECT store,COUNT(CASE WHEN cpi IS NULL THEN 1 END) AS num_null_entries 
FROM raw.features 
WHERE cpi IS NULL
GROUP BY store 
ORDER BY store;
--Output: The number of null value cpi records are consistent across all the stores.

--9. Confirming the number of null value unemployment records are consistent across all the stores
SELECT store,COUNT(CASE WHEN unemployment IS NULL THEN 1 END) AS num_null_entries 
FROM raw.features 
WHERE unemployment IS NULL
GROUP BY store 
ORDER BY store;
--Output: The number of null value unemployment records are consistent across all the stores.
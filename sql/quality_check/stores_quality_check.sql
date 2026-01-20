--1. for finding the number of nulls present in each column
SELECT 
    COUNT(CASE WHEN store IS NULL THEN 1 END) AS store_nulls,
    COUNT(CASE WHEN type IS NULL THEN 1 END)  AS type_nulls,
    COUNT(CASE WHEN size IS NULL THEN 1 END)  AS size_nulls
FROM raw.stores;
--Output: There are no nulls present in any of the columns.

--2. For finding the number of stores based on each store type present in the data
SELECT type,COUNT(type) AS num_of_stores FROM raw.stores GROUP BY type ORDER BY type;
--Output: There are 22 stores of type A, 17 stores of type B and 6 stores of type C.

--3. Average size of stores
SELECT AVG(size) AS store_avg_size FROM raw.stores;
--Output: The average size of the stores is 130287.6 sqft.

--3. Minimum size of stores
SELECT MIN(size) AS store_min_size FROM raw.stores;
--Output: The minimum size of the stores is 34875 sqft.

--3. Maximum size of stores
SELECT MAX(size) AS store_max_size FROM raw.stores;
--Output: The maximum size of the stores is 219622 sqft.
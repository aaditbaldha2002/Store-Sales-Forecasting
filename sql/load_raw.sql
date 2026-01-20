-- 1. Setup Environment
CREATE SCHEMA IF NOT EXISTS raw;

DROP TABLE IF EXISTS raw.features;
DROP TABLE IF EXISTS raw.stores;
DROP TABLE IF EXISTS raw.train;

-- 2. Define Schema with optimized types
CREATE TABLE raw.features (
    store        INTEGER,
    date         DATE,
    temperature  NUMERIC(5,2),
    fuel_price   NUMERIC(10,3),
    markdown1    NUMERIC(15,2),
    markdown2    NUMERIC(15,2),
    markdown3    NUMERIC(15,2),
    markdown4    NUMERIC(15,2),
    markdown5    NUMERIC(15,2),
    cpi          NUMERIC(15,8),
    unemployment NUMERIC(15,4),
    isholiday    BOOLEAN
);

CREATE TABLE raw.stores (
    store INTEGER PRIMARY KEY, -- Enforces uniqueness
    type  VARCHAR(1),
    size  INTEGER
);

CREATE TABLE raw.train (
    store        INTEGER,
    dept         INTEGER,
    date         DATE,
    weekly_sales NUMERIC(15,2),
    isholiday    BOOLEAN
);

-- 3. Data Ingestion
-- Note: Replace relative paths with absolute paths if running from a GUI like pgAdmin.
\copy raw.features FROM './data/raw/features.csv' DELIMITER ',' CSV HEADER;
\copy raw.train FROM './data/raw/train.csv' DELIMITER ',' CSV HEADER;
\copy raw.stores FROM './data/raw/stores.csv' DELIMITER ',' CSV HEADER;
CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE raw.features (
    store INTEGER,
    date DATE,
    temperature FLOAT,
    fuel_price FLOAT,
    markdown1 FLOAT,
    markdown2 FLOAT,
    markdown3 FLOAT,
    markdown4 FLOAT,
    markdown5 FLOAT,
    cpi FLOAT,
    unemployment FLOAT,
    isholiday BOOLEAN
);
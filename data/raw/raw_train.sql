CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE raw.train (
    store INTEGER,
    dept INTEGER,
    date DATE,
    weekly_sales FLOAT,
    isholiday BOOLEAN
);
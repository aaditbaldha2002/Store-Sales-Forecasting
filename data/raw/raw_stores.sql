CREATE SCHEMA IF NOT EXISTS raw;

CREATE TABLE raw.stores (
    store INTEGER,
    type CHAR(1),
    size INTEGER
);
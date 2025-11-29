-- Load features dataset
\copy raw.features FROM './data/raw/features.csv' DELIMITER ',' CSV HEADER;

-- Load training sales dataset
\copy raw.train FROM './data/raw/train.csv' DELIMITER ',' CSV HEADER;

-- Load stores dataset
\copy raw.stores FROM './data/raw/stores.csv' DELIMITER ',' CSV HEADER;
# Store-Sales-Forecasting

## 1. Process Pipeline

1. Data Loading into PostgreSQL
2. Data cleaning and merging through PostgreSQL as much as possible
3. Data Cleaning and final merge in Python through Pandas
4. EDA performed on Python notebooks and PostgreSQL
5. Statistical Tests performed on Python Notebooks
6. Modeling Decisions and Statistical Modeling done in Python notebooks
7. Deployment of necessary models if needed on AWS free tier

## 2. Data Dictionary

### Table: `raw.stores`
**Description:** Metadata providing context for each of the 45 retail outlets. This serves as the primary **Dimension Table** for the project.

| Column | Data Type | Key | Description | Transformation/Logic |
| :--- | :--- | :--- | :--- | :--- |
| **store** | `INTEGER` | PK | Unique identifier for each store. | Primary Key; used for joining Sales and Features. |
| **type** | `VARCHAR(1)` | - | Categorical label for the store (e.g., 'A', 'B', 'C').
| **size** | `INTEGER` | - | The physical size/square footage of the store.

<details>
<summary>📂 View SQL Schema Definition (DDL)</summary>

```
-- DDL for stores dimension table
CREATE TABLE raw.stores (
    store INTEGER PRIMARY KEY, -- Enforces entity integrity
    type  VARCHAR(1),
    size  INTEGER
); 
```

</details>


### Table: `raw.features`
**Description:** Temporal data containing environmental and economic factors that influence consumer behavior.

| Column | Data Type | Description | Cleaning Strategy |
| :--- | :--- | :--- | :--- |
| **store** | `INTEGER` | Store ID. | Foreign Key to `raw.stores`. |
| **date** | `DATE` | The start of the work week. | Temporal index. |
| **temperature** | `NUMERIC` | Average temperature in the region. | Standardize to Celsius/Fahrenheit. |
| **fuel_price** | `NUMERIC` | Cost of fuel in the region. | Check for outliers/inflation spikes. |
| **markdown1-5** | `NUMERIC` | Anonymized promotional data. | **High Sparsity:** Requires Null Imputation (0). |
| **cpi** | `NUMERIC` | Consumer Price Index. | Check for missing trailing data. |
| **unemployment** | `NUMERIC` | Prevailing unemployment rate. | Check for missing trailing data. |
| **isholiday** | `BOOLEAN` | Holiday flag. | Verify alignment with `raw.train`. |

<details>
<summary>📂 View SQL Schema Definition (DDL)</summary>

```
-- DDL for features dimension table
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
```

</details>

### Table: `raw.train`
**Description:** The historical training data, containing sales records for various departments across different stores.

| Column | Data Type | Key | Description | Notes/Business Logic |
| :--- | :--- | :--- | :--- | :--- |
| **store** | `INTEGER` | FK | Unique identifier for each store. | Joins with `raw.stores` and `raw.features`. |
| **dept** | `INTEGER` | - | Unique identifier for the department. | Defines the sub-unit granularity within a store. |
| **date** | `DATE` | - | The start date of the weekly reporting period. | Primary temporal index for time-series analysis. |
| **weekly_sales** | `NUMERIC(15,2)` | - | Total sales for the store-department-week. | **Target Variable.** Contains returns (negative values). |
| **isholiday** | `BOOLEAN` | - | Flag indicating if the week contains a holiday. | Used to model seasonal demand shifts. |

> **Granularity Note:** Data is recorded at the `Store-Department-Week` level. 
> **Data Integrity:** Primary focus during cleaning is identifying duplicate records and handling negative values representing product returns.

<details> 
    <summary>📂 View SQL Schema Definition (DDL)</summary>

```
-- DDL for sales fact table
CREATE TABLE raw.train (
    store        INTEGER, 
    dept         INTEGER,
    date         DATE,
    weekly_sales NUMERIC(15,2),
    isholiday    BOOLEAN
);
```
</details>

### Holiday Logic & Validation
The `isholiday` feature captures four major US retail events. Verification against the US calendar confirms the flag is applied to the following reporting weeks:

- **Super Bowl:** Feb 12 (2010), Feb 11 (2011), Feb 10 (2012), Feb 08 (2013)
- **Labor Day:** Sept 10 (2010), Sept 09 (2011), Sept 07 (2012)
- **Thanksgiving:** Nov 26 (2010), Nov 25 (2011), Nov 23 (2012)
- **Christmas:** Dec 31 (2010), Dec 30 (2011), Dec 28 (2012)

**Validation Status:** ✅ Data is chronologically consistent across all years.

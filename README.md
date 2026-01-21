## Project Title
**Store–Department Level Weekly Sales Forecasting**

## One-Line Business Objective
Develop a robust, time-aware forecasting system to accurately predict weekly sales at the store–department level, enabling proactive inventory planning, labor optimization, and promotion strategy alignment.

---

### Problem Statement
Retail sales demand varies significantly across stores, departments, and time due to seasonality, holidays, promotions, and macroeconomic factors. Manual forecasting or naive historical averaging fails to capture these dynamics, leading to inventory imbalances, increased holding costs, stockouts, and inefficient workforce planning.

The core problem addressed in this project is to **forecast weekly sales at the Store–Department level** in a way that is:
- Time-aware and resistant to data leakage
- Robust to holiday-driven demand spikes
- Scalable across heterogeneous stores and departments
- Interpretable enough to support downstream business decisions

This project explicitly treats sales forecasting as a **decision-support system**, not a pure prediction exercise.

---

### Success Criteria
The solution is considered successful if it meets the following criteria:

- **Forecast Accuracy:**  
  Achieves lower error than naive and baseline statistical models on unseen future weeks using time-based validation.

- **Temporal Generalization:**  
  Maintains stable performance across regular weeks and major holiday periods.

- **Business Usability:**  
  Produces forecasts at a granularity and cadence aligned with inventory, merchandising, and labor planning workflows.

- **Model Reliability:**  
  Demonstrates consistent performance across store types and departments without overfitting to high-volume entities.

**Primary Evaluation Metrics:** WMAPE and RMSE (evaluated using rolling, time-aware splits)

---

## Project Overview
This project focuses on **forecasting weekly retail sales** at the **Store–Department–Week** granularity using historical sales data enriched with economic, environmental, and promotional features. The objective is to design a **production-grade forecasting pipeline** that reflects real-world data engineering and data science practices.

Key principles:
- SQL-first data processing
- Strong data integrity and reproducibility
- Statistically grounded modeling decisions
- Production-aware design with cloud deployment readiness

---

## 1. End-to-End Process Pipeline

1. **Data Ingestion**
   - Raw datasets are ingested into **PostgreSQL** to enforce schemas, constraints, and referential integrity.

2. **SQL-Based Cleaning & Integration**
   - Deduplication, joins, null handling, and preliminary transformations are performed in PostgreSQL wherever possible.

3. **Python-Based Final Processing**
   - Advanced data cleaning, feature engineering, and final dataset preparation are completed using **Pandas**.

4. **Exploratory Data Analysis (EDA)**
   - Conducted using a hybrid approach:
     - SQL for aggregations, sanity checks, and anomaly detection
     - Python notebooks for visualization and trend analysis

5. **Statistical Analysis**
   - Hypothesis testing and distributional analysis performed in Python notebooks to validate assumptions and guide modeling choices.

6. **Modeling**
   - Statistical and machine learning models developed in Python.
   - Model selection driven by interpretability, robustness, and business relevance.

7. **Deployment (Optional)**
   - Selected models deployed using the **AWS Free Tier**, prioritizing cost efficiency and reproducibility.

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

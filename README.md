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

## 3. Data Overview

### Data Sources
The project uses structured historical retail data consisting of sales records enriched with store metadata and external economic indicators. All datasets are ingested into **PostgreSQL** to ensure schema enforcement and data integrity prior to analysis.

### Time Coverage
- **Frequency:** Weekly  
- **Reporting Period:** Multi-year historical data  
- **Temporal Alignment:** All datasets are aligned on the start date of the retail reporting week

### Granularity
- **Primary Granularity:** Store–Department–Week  
- This level of detail enables:
  - Department-specific demand modeling
  - Cross-store comparative analysis
  - Accurate capture of localized seasonality and holiday effects

### Target Variable
- **`weekly_sales`**
  - Represents total weekly sales per store and department
  - Includes negative values corresponding to product returns
  - Modeled directly to preserve real-world business behavior

### Supporting Features
- Store-level attributes (type, size)
- Time-varying economic and environmental indicators
- Promotional markdown signals
- Explicit holiday indicators validated against the US retail calendar

---

## 4. Data Schema & Dictionary

The dataset follows a **star-schema design** optimized for analytical workloads:
- **Fact Table:** `raw.train`
- **Dimension Tables:** `raw.stores`, `raw.features`

Referential joins are primarily executed on the `store` and `date` keys.

---

### Table: `raw.stores`
**Description:**  
Store dimension table providing static metadata for each of the 45 retail outlets. Used to contextualize sales behavior and segment performance.

| Column | Data Type | Key | Description | Transformation / Logic |
|------|----------|-----|------------|------------------------|
| **store** | INTEGER | PK | Unique identifier for each store | Primary join key |
| **type** | VARCHAR(1) | – | Store classification (A/B/C) | Categorical feature |
| **size** | INTEGER | – | Physical store size | Proxy for capacity |

<details>
<summary>📂 SQL Schema Definition (DDL)</summary>

```sql
CREATE TABLE raw.stores (
    store INTEGER PRIMARY KEY,
    type  VARCHAR(1),
    size  INTEGER
);
```

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

## 5. Assumptions & Constraints

Senior data scientists surface constraints upfront to prevent false confidence and rework downstream.

---

### 5.1 Data Availability Assumptions
- Historical data is **complete and reliable** at the Store–Department–Week level.
- No major structural breaks (e.g., store closures, department redefinitions) during the training period.
- External economic indicators (CPI, unemployment, fuel price) are assumed to be **lag-free and accurately reported**.
- Holiday flags are assumed to be **correctly aligned** across datasets.

---

### 5.2 Latency & Cost Constraints
- Forecasts are generated in **batch mode** (weekly cadence).
- No real-time inference requirements.
- Model training and inference constrained to **AWS Free Tier / local compute**.
- Feature engineering favors **pre-computation** over on-the-fly joins to reduce runtime costs.

---

### 5.3 Business & Operational Constraints
- Forecasts must be **explainable** to supply chain and operations teams.
- Error tolerance varies by department; high-volume departments prioritized.
- Negative sales values represent **returns**, not data errors.
- Models must scale across **45 stores and multiple departments** without manual tuning per segment.

---

### 5.4 Modeling Constraints
- No future information leakage (strict temporal integrity).
- Models must generalize across seasonal demand shifts.
- Preference given to models that balance:
  - Accuracy
  - Stability
  - Interpretability
  - Ease of deployment

---
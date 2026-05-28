# Data Profiling Report: Vehicle Master Raw Dataset

**Date:** 05/26/2026
**Dataset Source:** `vehicle_master_raw`

## 1. Executive Summary
* **Overall Quality Score:** Medium
* **Key Finding 1:** Out of 420 vehicle records, 4 records are missing critical `vehicle_id` and 16 records are missing critical `vin` identifiers.
* **Key Finding 2:** Detected 13 total instances of duplicate VINs or registration numbers
* **Key Finding 3:** Detected instances of fuel type label variations that correspond to the same fuel type.
* **Recommendation:** Backfill missing values if possible, quarantine duplicate values and enforce strict validation rules on the ingestion pipeline.

## 2. Dataset Metadata
* **Total Row Count:** 420
* **Target Table:** `raw.vehicle_master_raw`
* **Data Nature:** Fleet Asset Master Data

## 3. Completeness & Uniqueness Analysis

| Metric Field      | Missing Count | Missing % | Distinct Count | Duplicate Status  |
| :---------------- | :-----------: | :-------: | :------------: | :---------------- |
| `asset_no`        |       0       |     0     |       420      | No Duplicates     |
| `vehicle_id`      |       4       |    0.95   |       416      | Minor Duplication |
| `vin`             |       16      |    3.81   |       399      | Minor Duplication |
| `registration_no` |       0       |     0     |       412      | Minor Duplication |

## 4. Duplicate Violations

### 4.1 Duplicate VINs (`vin`)

| vin               | duplicate_count |
|-------------------|-----------------|
| 82BLWKJ5S7035K6EJ | 2               |
| LH50HHSKD243SJ4TN | 2               |
| M8NJM7D5H8UXNCMVV | 2               |
| NKHL73ETEEHYPUE67 | 2               |
| T8YM2VM8WM1FPGVWH | 2               |

### 4.2 Duplicate Registration Numbers (`registration_no`)

| registration_no | duplicate_count |
|-----------------|-----------------|
| CTE4488         | 2               |
| ETP9210         | 2               |
| JIX1955         | 2               |
| KMZ1899         | 2               |
| QGL6636         | 2               |
| QJD5094         | 2               |
| XYD8116         | 2               |
| YMM4816         | 2               |

## 5. Categorical Distribution: Fuel Types (`fuel_type`)

| fuel_type  | record_count |
|------------|--------------|
| ELECTRIC   | 88           |
| Hybrid     | 73           |
| DIESEL     | 62           |
| Gas        | 53           |
| EV         | 43           |
| Gas Hybrid | 33           |
| Dsl        | 22           |
| Gasoline   | 16           |
| petrol     | 15           |
| Unleaded   | 15           |

## 6. Data Quality Issues & Action Plan
* [ ] **Issue 1: Missing Critical Vehicle Identifiers (`vehicle_id` and `vin`)**
    * **Impact:** Prevents reliable tracking, indexing, and downstream system joins. Vehicles cannot be uniquely identified.
    * **Fix:**
        * Extract records where `vehicle_id` or `vin` is null or blank and route them to the operations team for manual verification.
        * Route records to the exception table and exclude them from clean layer joins where the missing identifier is required.

* [ ] **Issue 2: Duplicate Core Assets (`vin` and `registration_no`)**
    * **Impact:** Breaks entity integrity. A single VIN or license plate should never belong to multiple records in a master table.
    * **Fix:**
        * Write a deduplication script using a `ROW_NUMBER() OVER (PARTITION BY vin ORDER BY [last_update_date] DESC)` logic to retain only the newest entry.
        * Check upstream integration logs to see if duplicate records are caused by multiple batch runs or API retry loops.

* [ ] **Issue 3: Inconsistent Naming Conventions in `fuel_type`**
    * **Impact:** Skews fleet metrics and breaks data filters (e.g., searching for "EV" misses records labeled "ELECTRIC")
    * **Fix:**
        * Apply a SQL `CASE WHEN` statement or mapping dictionary during the transformation stage to standardize values to a strict uppercase format:
            * Map `ELECTRIC`, `EV` $\rightarrow$ `ELECTRIC`
            * Map `DIESEL`, `Dsl` $\rightarrow$ `DIESEL`
        * Enforce an explicit allowed-values constraint (ENUM or Lookup table check) for future data entry.
# Data Profiling Report: Fuel Transactions Raw Dataset

**Date:** 05/26/2026  
**Dataset Source:** `fuel_transactions_raw`

## 1. Executive Summary
* **Overall Quality Score:** Low
* **Key Finding 1:** Out of 8,012 fuel transaction records, 12 records appear to be blank rows, 12 records are missing `fuel_txn_id`, 134 records are missing `Asset No`, and 215 records are missing `Odometer`.
* **Key Finding 2:** Detected 222 fuel transactions with non-missing `Asset No` values that do not match a vehicle asset in `raw.vehicle_master_raw`.
* **Key Finding 3:** Detected 1,119 suspicious MPG records, including 65 zero MPG values, 303 very high MPG values, and 739 very low MPG values.
* **Key Finding 4:** Detected 3,476 backward odometer sequence violations, which suggests odometer entry errors, transaction ordering issues, vehicle assignment problems, or unit conversion issues.
* **Key Finding 5:** Fuel product, distance unit, and quantity unit values use multiple naming conventions that should be standardized before clean-layer reporting.
* **Recommendation:** Remove blank rows, quarantine transactions with missing or orphan vehicle identifiers, recompute MPG after standardizing distance and quantity units, review odometer sequence violations, and normalize fuel product/unit fields before loading to the clean fuel transaction layer.

## 2. Dataset Metadata
* **Total Row Count:** 8,012
* **Target Table:** `raw.fuel_transactions_raw`
* **Data Nature:** Fuel Transaction / Usage Data

## 3. Completeness & Validation Analysis

| Metric Field      |   Missing Count |   Missing % | Distinct Count   | Duplicate / Validation Status      |
|:------------------|----------------:|------------:|:-----------------|:-----------------------------------|
| `fuel_txn_id`     |              12 |        0.15 | Not Profiled     | Missing Transaction IDs            |
| `Asset No`        |             134 |        1.67 | Not Profiled     | Missing + Orphan Asset References  |
| `Registration`    |              12 |        0.15 | Not Profiled     | Minor Missingness                  |
| `Odometer`        |             215 |        2.68 | Not Profiled     | Missing + Backward Odometer Values |
| `MPG`             |              12 |        0.15 | Not Profiled     | Suspicious MPG Values Detected     |
| Likely Blank Rows |              12 |        0.15 | N/A              | Blank/Empty Source Records         |

## 4. Referential Integrity Analysis

### 4.1 Orphan Fuel Transactions by Asset Number

| Validation Check                                                                |   Record Count |   % of Total Rows |
|:--------------------------------------------------------------------------------|---------------:|------------------:|
| Fuel transactions with non-missing `Asset No` not found in `vehicle_master_raw` |            222 |              2.77 |

## 5. Unit and Fuel Product Distribution

### 5.1 Distance Unit Values (`Unit`)

| distance_unit   |   record_count |
|:----------------|---------------:|
| Miles           |           3972 |
| Kilometers      |           2024 |
| KM              |           2004 |
| [Blank / NULL]  |             12 |

### 5.2 Fuel Quantity Unit Values (`Qty_UOM`)

| quantity_unit   |   record_count |
|:----------------|---------------:|
| Liters          |           2010 |
| Gallons         |           2005 |
| GAL             |           1999 |
| L               |           1986 |
| [Blank / NULL]  |             12 |

### 5.3 Fuel Product Type Values (`Product`)

| fuel_product   |   record_count |
|:---------------|---------------:|
| DIESEL         |           1938 |
| Electric       |           1059 |
| Unleaded       |           1045 |
| Petrol         |           1016 |
| Dsl            |           1008 |
| Gasoline       |            970 |
| Gas            |            964 |
| [Blank / NULL] |             12 |

## 6. MPG Validation Analysis

| Metric                       |   Record Count |   % of Total Rows |
|:-----------------------------|---------------:|------------------:|
| Invalid or Missing MPG       |             12 |              0.15 |
| Zero MPG                     |             65 |              0.81 |
| Very High MPG (`MPG > 90`)   |            303 |              3.78 |
| Very Low MPG (`0 < MPG < 2`) |            739 |              9.22 |
| Total Suspicious MPG Records |           1119 |             13.97 |

## 7. Odometer Sequence Validation

| Validation Check                                             |   Record Count |   % of Total Rows | Status                            |
|:-------------------------------------------------------------|---------------:|------------------:|:----------------------------------|
| Backward odometer readings by asset over transaction history |           3476 |             43.38 | High Volume of Sequence Anomalies |

## 8. Data Quality Issues & Action Plan

* [ ] **Issue 1: Missing Transaction and Vehicle Identifiers**
    * **Impact:** Missing `fuel_txn_id`, `Asset No`, and `Registration` values reduce traceability and prevent reliable joins to vehicle master records.
    * **Fix:**
        * Remove or quarantine the 12 likely blank rows.
        * Backfill missing transaction IDs and asset references where possible.
        * Add ingestion validation to reject records missing required transaction and vehicle identifiers.

* [ ] **Issue 2: Orphan Fuel Transactions**
    * **Impact:** The 222 orphan fuel records cannot be reliably tied back to a known vehicle asset, which can distort fuel cost, usage, and MPG reporting by vehicle.
    * **Fix:**
        * Reconcile `Asset No` values against `raw.vehicle_master_raw`.
        * Standardize asset number formatting before joins.
        * Route unmatched asset numbers to an exception table for manual review.

* [ ] **Issue 3: Suspicious MPG Values**
    * **Impact:** Zero, very high, and very low MPG values can distort fuel efficiency reporting and may indicate unit conversion, odometer, fuel quantity, or EV-specific logic problems.
    * **Fix:**
        * Standardize `Unit` and `Qty_UOM` before MPG calculations.
        * Recompute MPG from standardized distance and fuel quantity fields.
        * Create exception rules for MPG values outside expected thresholds.
        * Handle electric transactions separately if MPG is not the correct efficiency metric.

* [ ] **Issue 4: Backward Odometer Readings**
    * **Impact:** Backward odometer readings break mileage progression logic and can cause incorrect trip distance, MPG, and maintenance interval calculations.
    * **Fix:**
        * Review transaction ordering by `transaction_date` and `fuel_txn_id`.
        * Investigate data entry errors, odometer replacements, vehicle reassignment, and unit conversion mismatches.
        * Add validation rules that flag decreasing odometer readings unless a documented exception exists.

* [ ] **Issue 5: Inconsistent Unit and Product Labels**
    * **Impact:** Mixed labels such as `Miles`, `Kilometers`, `KM`, `Gallons`, `GAL`, `Liters`, `L`, `DIESEL`, `Dsl`, `Gasoline`, `Gas`, `Petrol`, and `Unleaded` can split metrics that should be grouped together.
    * **Fix:**
        * Normalize distance units to standard values such as `MILES` and `KILOMETERS`.
        * Normalize quantity units to standard values such as `GALLONS` and `LITERS`.
        * Map product labels to standardized fuel categories such as `DIESEL`, `GASOLINE`, and `ELECTRIC`.
        * Apply the same standardized labels consistently across vehicle, fuel, and condition assessment datasets.

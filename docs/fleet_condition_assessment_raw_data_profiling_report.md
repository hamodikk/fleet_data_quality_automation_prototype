# Data Profiling Report: Fleet Condition Assessment Raw Dataset

**Date:** 05/27/2026  
**Dataset Source:** `fleet_condition_assessment_raw`

## 1. Executive Summary
* **Overall Quality Score:** Low
* **Key Finding 1:** Out of 1,500 fleet condition assessment records, 87 records are missing `vehicle_id`, while `assessment_id` and `registration_no` have no missing values.
* **Key Finding 2:** Detected 39 assessments with non-missing `vehicle_id` values that do not match a vehicle in `raw.vehicle_master_raw`.
* **Key Finding 3:** Detected 28 records where `Last_Service_Date` occurs after `assessment_date`.
* **Key Finding 4:** Detected 760 records where `Mileage` and `Odometer_Reading` differ by more than 5,000 units.
* **Key Finding 5:** Cross-source validation found 586 fuel type conflicts across 1,115 compared records between `fleet_condition_assessment_raw` and `vehicle_master_raw`.
* **Recommendation:** Backfill missing vehicle identifiers, quarantine orphan assessments, validate service-date sequencing, reconcile mileage and odometer fields, and resolve fuel type conflicts using a single standardized vehicle fuel-type reference before loading this table into the clean condition assessment layer.

## 2. Dataset Metadata
* **Total Row Count:** 1,500
* **Target Table:** `raw.fleet_condition_assessment_raw`
* **Data Nature:** Fleet Condition Assessment / Inspection Data

## 3. Completeness & Identifier Analysis

| Metric Field      | Missing Count | Missing % | Distinct Count | Validation Status                   |
|:------------------|--------------:|----------:|---------------:|:------------------------------------|
| `assessment_id`   |       0       |      0.00 |   Not Profiled | No Missing Values                   |
| `vehicle_id`      |       87      |      5.80 |            441 | Missing + Orphan Vehicle References |
| `registration_no` |       0       |      0.00 |            462 | No Missing Values                   |

## 4. Referential Integrity Analysis

### 4.1 Orphan Condition Assessments by Vehicle ID

| Validation Check | Record Count | % of Total Rows | % of Non-Missing Vehicle IDs |
|:---|---:|---:|---:|
| Assessments with non-missing `vehicle_id` not found in `vehicle_master_raw` | 39 | 2.60 | 2.76 |

## 5. Date Logic Validation

| Validation Rule | Issue Count | Issue % |
|:---|---:|---:|
| Invalid `assessment_date` values | 0 | 0.00 |
| Invalid `Last_Service_Date` values | 0 | 0.00 |
| `Last_Service_Date` after `assessment_date` | 28 | 1.87 |

## 6. Mileage and Odometer Validation

| Validation Rule | Issue Count | Issue % |
|:---|---:|---:|
| Invalid or missing `Mileage` values | 0 | 0.00 |
| Invalid or missing `Odometer_Reading` values | 0 | 0.00 |
| `Mileage` vs `Odometer_Reading` difference greater than 5,000 | 760 | 50.67 |

## 7. Cross-Source Fuel Type Consistency

**Placement Note:** This check compares values across two datasets, so it is not strictly a single table defect. It is included here because the compared field from this table is `fleet_condition_assessment_raw.Fuel_Type`, but it should also be summarized in an overall cross-source reconciliation or final data quality summary.

| Cross-Source Check | Compared Records | Conflict Count | Conflict % of Compared Records | Conflict % of FCA Rows |
|:---|---:|---:|---:|---:|
| Standardized `Fuel_Type` from condition assessments does not match standardized `fuel_type` from vehicle master | 1,115 | 586 | 52.56 | 39.07 |

## 8. Data Quality Issues & Action Plan

* [ ] **Issue 1: Missing and Orphan Vehicle Identifiers**
    * **Impact:** Missing or unmatched `vehicle_id` values prevent condition assessments from being reliably connected to vehicle master data, maintenance history, fuel transactions, and fleet reporting.
    * **Fix:**
        * Backfill the 87 missing `vehicle_id` values where registration number or source-system history can identify the asset.
        * Reconcile the 39 orphan vehicle IDs against `raw.vehicle_master_raw`.
        * Standardize vehicle identifier formatting before joins.
        * Route unresolved assessment records to an exception table.

* [ ] **Issue 2: Invalid Service Date Logic**
    * **Impact:** Records where `Last_Service_Date` occurs after `assessment_date` can distort inspection recency, preventive maintenance compliance, and condition-based maintenance planning.
    * **Fix:**
        * Review the 28 date sequence violations.
        * Correct swapped or mistyped dates where source evidence is available.
        * Add a validation rule requiring `Last_Service_Date <= assessment_date` when both dates are populated.

* [ ] **Issue 3: Mileage and Odometer Disagreements**
    * **Impact:** Large differences between `Mileage` and `Odometer_Reading` weaken asset utilization metrics and can affect maintenance interval calculations.
    * **Fix:**
        * Confirm whether `Mileage` and `Odometer_Reading` are intended to represent the same measurement or different source-system concepts.
        * Standardize units before comparing values.
        * Recalculate or select one authoritative mileage field for clean-layer reporting.
        * Flag records where the difference remains greater than 5,000 after unit and source validation.

* [ ] **Issue 4: Cross-Source Fuel Type Conflicts**
    * **Impact:** Conflicting fuel type values between condition assessments and vehicle master records can split reporting categories and cause inconsistent asset-level analysis across fleet, fuel, and maintenance domains.
    * **Fix:**
        * Use `vehicle_master_raw` as the primary source of truth for current vehicle fuel type unless the assessment record is intentionally capturing observed field condition.
        * Standardize labels such as `DIESEL`/`Dsl`, `GASOLINE`/`Gas`/`Petrol`/`Unleaded`, and `ELECTRIC`/`EV` before comparison.
        * Review the 586 conflicting records and determine whether they are true source conflicts, stale master data, or coding differences.
        * Include this issue in the final cross-source reconciliation summary, not only in this single-table report.

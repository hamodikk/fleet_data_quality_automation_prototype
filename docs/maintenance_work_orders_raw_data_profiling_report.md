# Data Profiling Report: Maintenance Work Orders Raw Dataset

**Date:** 05/27/2026  
**Dataset Source:** `maintenance_work_orders_raw`

## 1. Executive Summary
* **Overall Quality Score:** Low
* **Key Finding 1:** Out of 4,022 maintenance work order records, 70 records are missing `EQ_EQUIP_NO`, 335 records are missing `vendor_id`, and 76 records are missing `vendor_name`.
* **Key Finding 2:** Detected 22 duplicated `UNIQUE_WORK_ORDER_NO` values across 44 records, creating 22 extra duplicate work order records.
* **Key Finding 3:** Detected 95 non-missing equipment numbers that do not match a vehicle asset in `raw.vehicle_master_raw`.
* **Key Finding 4:** Detected 41 records where the closed date occurs before the open date.
* **Key Finding 5:** Cost validation flagged 66 negative labor cost records, 56 invalid or missing parts cost records, and 224 total cost mismatch records.
* **Recommendation:** Quarantine duplicate and orphan work orders, backfill missing equipment and vendor references, correct date sequence issues, and validate cost calculation rules before loading this table into the clean maintenance work order layer.

## 2. Dataset Metadata
* **Total Row Count:** 4,022
* **Target Table:** `raw.maintenance_work_orders_raw`
* **Data Nature:** Maintenance Work Order Transaction Data

## 3. Completeness & Uniqueness Analysis

| Metric Field           |   Missing Count |   Missing % | Distinct Count   | Duplicate / Validation Status      |
|:-----------------------|----------------:|------------:|:-----------------|:-----------------------------------|
| `UNIQUE_WORK_ORDER_NO` |               0 |           0 | 4000             | Duplicate Work Orders Detected     |
| `EQ_EQUIP_NO`          |              70 |        1.74 | 509              | Missing + Orphan Equipment Numbers |
| `vendor_id`            |             335 |        8.33 | Not Profiled     | Moderate Missingness               |
| `vendor_name`          |              76 |        1.89 | Not Profiled     | Minor Missingness                  |

## 4. Duplicate Violations

### 4.1 Duplicate Work Orders (`UNIQUE_WORK_ORDER_NO`)

| Summary Metric                             |   Value |
|:-------------------------------------------|--------:|
| Duplicate work order values                |      22 |
| Records involved in duplicated work orders |      44 |
| Extra duplicate records                    |      22 |

| UNIQUE_WORK_ORDER_NO   |   duplicate_count |
|:-----------------------|------------------:|
| WO-2024-000036         |                 2 |
| WO-2024-000054         |                 2 |
| WO-2024-001053         |                 2 |
| WO-2024-001800         |                 2 |
| WO-2024-002070         |                 2 |
| WO-2024-003567         |                 2 |
| WO-2025-000496         |                 2 |
| WO-2025-000733         |                 2 |
| WO-2025-001240         |                 2 |
| WO-2025-001258         |                 2 |
| WO-2025-002545         |                 2 |
| WO-2025-002683         |                 2 |
| WO-2025-002809         |                 2 |
| WO-2025-002869         |                 2 |
| WO-2025-003049         |                 2 |
| WO-2025-003499         |                 2 |
| WO-2026-000854         |                 2 |
| WO-2026-000935         |                 2 |
| WO-2026-001358         |                 2 |
| WO-2026-002093         |                 2 |
| WO-2026-002666         |                 2 |
| WO-2026-003845         |                 2 |

## 5. Referential Integrity Analysis

### 5.1 Orphan Work Orders

These records have a non-missing `EQ_EQUIP_NO`, but the equipment number does not match an `asset_no` in `raw.vehicle_master_raw`.

| Referential Integrity Metric   |   Count | Percent of Rows   |
|:-------------------------------|--------:|:------------------|
| Orphan work orders             |      95 | 2.36%             |

### 5.2 Example Orphan Work Orders

| UNIQUE_WORK_ORDER_NO   |   EQ_EQUIP_NO | JOB_TYPE                 | WORK_ORDER_STATUS   | vendor_name               | TOTAL_COST   |
|:-----------------------|--------------:|:-------------------------|:--------------------|:--------------------------|:-------------|
| WO-2025-000223         |         99758 | Repair                   | Finished            | Precision Hydraulics      | 3659.41      |
| WO-2024-000234         |         99326 | REPAIR                   | Open                | FleetPro Service Center   | 3194.22      |
| WO-2025-000271         |         99372 | Repair                   | Finished            | Midwest Diesel Service    | 3668.64      |
| WO-2025-000361         |         99114 | Preventative Maintenance | In Progress         | Urban Fleet Maintenance   | 3061.18      |
| WO-2026-000410         |         99536 | Preventative Maintenance | In Progress         | Evergreen Battery Supply  | 3735.27      |
| WO-2025-000424         |         99830 | PM                       | Cancelled           | Universal Fleet Solutions | 3084.45      |
| WO-2026-000485         |         99779 | Corrective               | Finished            | FleetPro Service Center   | 2415.37      |
| WO-2026-000530         |         99633 | Corrective               | Open                | Universal Fleet Solutions | 1083.06      |
| WO-2026-000614         |         99901 | preventive maint         | CLOSED              | GreenCharge EV Supply     | 3246.37      |
| WO-2026-000665         |         99828 | Preventative Maintenance | Cancelled           | Precision Hydraulics      | 3870.99      |
| WO-2025-000667         |         99853 | PM                       | Open                | FleetPro Service Center   | 403.90       |
| WO-2024-000669         |         99906 | Corrective               | Finished            | Green Charge              | 1314.21      |
| WO-2025-000688         |         99747 | Corrective               | Open                | Green Charge              | 2590.91      |
| WO-2024-000723         |         99162 | REPAIR                   | Cancelled           | Premier Collision Center  | 2971.84      |
| WO-2026-000725         |         99874 | REPAIR                   | Cancelled           | Precision Hydraulics      | 4933.03      |
| WO-2026-000770         |         99798 | PM                       | Closed              | FastLane PM Services      | 2502.24      |
| WO-2025-000775         |         99341 | preventive maint         | CLOSED              | Premier Collision Center  | 5605.07      |
| WO-2024-000798         |         99861 | Preventative Maintenance | CLOSED              | Central Parts Warehouse   | 2489.64      |
| WO-2025-000844         |         99159 | Corrective               | Closed              | Reliable Truck Service    | \$3,400.68   |
| WO-2024-000870         |         99424 | REPAIR                   | In Progress         | Northside Fleet Repair    | \$3,536.47   |
| WO-2024-000888         |         99306 | REPAIR                   | In Progress         | Interstate Repair Depot   | \$2,039.64   |
| WO-2026-000965         |         99714 | PM                       | Open                | Green Charge              | 1657.90      |
| WO-2025-000994         |         99831 | Preventative Maintenance | Finished            | Reliable Truck Service    | 2971.52      |
| WO-2025-001000         |         99414 | Corrective               | In Progress         | Midwest Diesel Service    | 4690.74      |
| WO-2025-001123         |         99880 | PM                       | Finished            | Green Charge              | 3623.75      |

## 6. Date Logic Validation

| Validation Rule                          |   Issue Count |   Issue % |
|:-----------------------------------------|--------------:|----------:|
| Invalid `DATETIME_OPEN` values           |             0 |         0 |
| Invalid `DATETIME_CLOSED` values         |             0 |         0 |
| `DATETIME_CLOSED` before `DATETIME_OPEN` |            41 |      1.02 |

## 7. Cost Field Validation

| Cost Validation Rule                        |   Issue Count |   Issue % |
|:--------------------------------------------|--------------:|----------:|
| Invalid or missing `LABOR_COST`             |             0 |         0 |
| Invalid or missing `PARTS_COST`             |            56 |      1.39 |
| Invalid or missing commercial cost field    |             0 |         0 |
| Invalid or missing `TOTAL_COST`             |             0 |         0 |
| Negative `LABOR_COST`                       |            66 |      1.64 |
| `TOTAL_COST` mismatch vs component cost sum |           224 |      5.57 |

## 8. Data Quality Issues & Action Plan
* [ ] **Issue 1: Missing Core Work Order References (`EQ_EQUIP_NO`, `vendor_id`, and `vendor_name`)**
    * **Impact:** Missing equipment and vendor fields make it difficult to connect work orders to fleet assets, vendors, spend reporting, and maintenance history.
    * **Fix:**
        * Backfill missing `EQ_EQUIP_NO`, `vendor_id`, and `vendor_name` values from the original maintenance source system where possible.
        * Add required-field checks for work orders that should always have an assigned vehicle and vendor.
        * Create exception flags for valid edge cases, such as internal work orders with no external vendor.

* [ ] **Issue 2: Duplicate Work Order Numbers**
    * **Impact:** Duplicate `UNIQUE_WORK_ORDER_NO` values break transaction uniqueness and may double-count maintenance activity or costs.
    * **Fix:**
        * Quarantine the 22 duplicated work order numbers for manual review.
        * Compare duplicated rows across equipment number, vendor, status, dates, and costs to determine whether records are true duplicates or versioned updates.
        * Enforce a uniqueness constraint on `UNIQUE_WORK_ORDER_NO` in the clean layer.

* [ ] **Issue 3: Orphan Equipment References**
    * **Impact:** Work orders cannot be reliably tied back to the vehicle master, which weakens asset-level maintenance history and cost analysis.
    * **Fix:**
        * Review the 95 orphan records against `raw.vehicle_master_raw`.
        * Correct equipment numbers where values are mistyped or use a different identifier standard.
        * If the asset is legitimately missing from the vehicle master, add the asset to the master data or flag the work order as unmatched.

* [ ] **Issue 4: Invalid Date Logic**
    * **Impact:** Closed-before-open records create incorrect maintenance cycle times and can distort operational metrics such as turnaround time or downtime.
    * **Fix:**
        * Review the 41 records where `DATETIME_CLOSED` is earlier than `DATETIME_OPEN`.
        * Correct swapped, mistyped, or defaulted dates.
        * Add a validation rule requiring `DATETIME_CLOSED >= DATETIME_OPEN` when both dates are populated.

* [ ] **Issue 5: Cost Field Problems**
    * **Impact:** Negative labor costs, missing parts costs, and total-cost mismatches can distort maintenance spend reporting.
    * **Fix:**
        * Review negative labor costs and decide whether they represent credits, reversals, or data entry errors.
        * Recalculate `TOTAL_COST` from validated component costs and flag rows where the raw total does not reconcile.
        * Add numeric parsing and reconciliation checks for `LABOR_COST`, `PARTS_COST`, commercial cost, and `TOTAL_COST` during ingestion.

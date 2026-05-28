# Data Profiling Report: Vendor Master Raw Dataset

**Date:** 05/27/2026  
**Dataset Source:** `vendor_master_raw`

## 1. Executive Summary
* **Overall Quality Score:** Medium
* **Key Finding 1:** Out of 70 vendor records, 4 records are missing critical `vendor_id` values and 28 records are missing `contact_email` values.
* **Key Finding 2:** Detected 4 duplicated `vendor_id` values across 9 records, creating 5 extra duplicate vendor ID records.
* **Key Finding 3:** Detected 17 normalized vendor names that appear more than once, which suggests vendor naming repetition or inconsistent naming conventions.
* **Key Finding 4:** `preferred_vendor_flag` uses multiple representations for the same boolean concept, including `Yes`, `Y`, `TRUE`, `No`, `N`, `FALSE`, and blank values.
* **Recommendation:** Standardize vendor identifiers, quarantine duplicate vendor IDs for review, normalize vendor names, and convert preferred-vendor flags into a consistent boolean format before loading to the clean layer.

## 2. Dataset Metadata
* **Total Row Count:** 70
* **Target Table:** `raw.vendor_master_raw`
* **Data Nature:** Vendor / Supplier Master Data

## 3. Completeness & Uniqueness Analysis

| Metric Field            |   Missing Count |   Missing % | Distinct Count   | Duplicate / Validation Status   |
|:------------------------|----------------:|------------:|:-----------------|:--------------------------------|
| `vendor_id`             |               4 |        5.71 | 61               | Duplicate IDs Detected          |
| `vendor_name`           |               0 |           0 | 33               | Repeated/Variant Names Detected |
| `contact_email`         |              28 |          40 | Not Profiled     | High Missingness                |
| `preferred_vendor_flag` |               6 |        8.57 | 6                | Inconsistent Boolean Labels     |

## 4. Duplicate Violations

### 4.1 Duplicate Vendor IDs (`vendor_id`)

| vendor_id   |   duplicate_count |
|:------------|------------------:|
| V2006       |                 3 |
| V2007       |                 2 |
| V2014       |                 2 |
| V2020       |                 2 |

## 5. Vendor Name Variant Analysis

The SQL profiling query normalized vendor names by trimming whitespace, converting names to uppercase, removing apostrophes and periods, and replacing `&` with `AND`. The repeated normalized names below suggest likely duplicate vendors or inconsistent naming patterns that should be reviewed before creating a clean vendor dimension.

| normalized_vendor_name      |   record_count |
|:----------------------------|---------------:|
| PRECISION HYDRAULICS        |              8 |
| PREMIER COLLISION CENTER    |              6 |
| RELIABLE TRUCK SERVICE      |              5 |
| INDUSTRIAL EQUIPMENT REPAIR |              4 |
| APEX MAINTENANCE GROUP      |              3 |
| CENTRAL PARTS WAREHOUSE     |              3 |
| FLEETPRO SERVICE CENTER     |              3 |
| QUICK FUEL PARTNERS         |              3 |
| UNIVERSAL FLEET SOLUTIONS   |              3 |
| URBAN FLEET MAINTENANCE     |              2 |
| ROADREADY REPAIRS           |              2 |
| SUPERIOR BODY SHOP          |              2 |
| GREEN CHARGE                |              2 |
| CITY WIDE TIRE AND BRAKE    |              2 |
| INTERSTATE REPAIR DEPOT     |              2 |
| MIDWEST DIESEL SERVICE      |              2 |
| PARTNER MOBILE MECHANICS    |              2 |

## 6. Categorical Distribution: Preferred Vendor Flags (`preferred_vendor_flag`)

| preferred_vendor_flag   |   record_count |
|:------------------------|---------------:|
| No                      |             15 |
| N                       |             12 |
| Yes                     |             12 |
| TRUE                    |             10 |
| FALSE                   |             10 |
| (blank / NULL)          |              6 |
| Y                       |              5 |

## 7. Data Quality Issues & Action Plan
* [ ] **Issue 1: Missing Critical Vendor Identifiers (`vendor_id`)**
    * **Impact:** Prevents reliable vendor tracking and makes joins to work orders or other vendor-linked tables unreliable.
    * **Fix:**
        * Review the 4 records missing `vendor_id`.
        * Backfill the ID from source files if possible.
        * If no valid ID exists, assign a controlled surrogate key during cleaning and flag the record for audit.

* [ ] **Issue 2: Duplicate Vendor IDs**
    * **Impact:** Breaks entity integrity because a single `vendor_id` should represent one vendor record in the master table.
    * **Fix:**
        * Quarantine duplicate `vendor_id` records.
        * Compare vendor names, contact emails, and other descriptive fields to decide whether records should be merged or corrected.
        * Add a uniqueness validation rule for `vendor_id` in the clean layer.

* [ ] **Issue 3: Missing Contact Emails**
    * **Impact:** Limits the ability to contact vendors and reduces usefulness for vendor management, communications, and downstream operational workflows.
    * **Fix:**
        * Backfill missing emails from source systems where possible.
        * Allow missing email only when the vendor is inactive or contact information is unavailable.
        * Add a validation flag such as `missing_contact_email_flag` during cleaning.

* [ ] **Issue 4: Vendor Name Variants and Repeated Normalized Names**
    * **Impact:** Can create duplicate vendor entities, split spend or maintenance activity across multiple names, and distort vendor-level reporting.
    * **Fix:**
        * Create a standardized vendor name field.
        * Use normalized names as a matching key for review.
        * Maintain a vendor crosswalk table for known aliases and merged vendors.

* [ ] **Issue 5: Inconsistent `preferred_vendor_flag` Values**
    * **Impact:** Boolean reporting is unreliable because equivalent values are stored using different labels.
    * **Fix:**
        * Map `Yes`, `Y`, and `TRUE` to `1` or `TRUE`.
        * Map `No`, `N`, and `FALSE` to `0` or `FALSE`.
        * Keep blank values as `NULL` and flag them for review if the field is required.
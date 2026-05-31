# Data Quality Rules

**Project:** Data Integrity Automation Prototype  
**Document Type:** Data quality rulebook  
**Status:** Prototype Version
**Purpose:** Define how raw fleet-related data should be evaluated before it is trusted for reporting, dashboarding, automation, or exception review.

---

## 1. Purpose

This document defines the general rules used to decide whether a raw record is:

1. Acceptable for clean-layer reporting,
2. Cleanable through a documented transformation,
3. Usable with warning flags,
4. Excluded from specific metrics, or
5. Routed to exception review.

The purpose of these rules is not to make the data perfect. The purpose is to make data handling transparent, reproducible, and auditable.

---

## 2. Core Principles

### 2.1 Preserve Raw Data

Raw data should not be overwritten. All parsing, standardization, flagging, and correction logic should occur in a separate clean layer or exception layer.

**Rule:** Preserve original source values for auditability and reproducibility.

---

### 2.2 Clean Only When the Mapping Is Clear

Some issues can be safely standardized, such as casing differences, known label variations, boolean values, and unit formats.

Examples:

| Raw Values | Clean Value |
|---|---|
| `Y`, `Yes`, `TRUE` | `1` |
| `N`, `No`, `FALSE` | `0` |
| `Miles`, `MILES` | `MILES` |
| `KM`, `Kilometers` | `KILOMETERS` |
| `Gallons`, `GAL` | `GALLONS` |
| `Liters`, `L` | `LITERS` |
| `Diesel`, `DIESEL`, `Dsl` | `DIESEL` |
| `Gas`, `Gasoline`, `Petrol`, `Unleaded` | `GASOLINE` |
| `EV`, `Electric`, `ELECTRIC` | `ELECTRIC` |

**Rule:** Standardize values only when the mapping is low-risk and clearly documented.

---

### 2.3 Flag Instead of Guessing

Some issues require business context. These include duplicate IDs, conflicting source values, negative costs, orphan records, and suspicious odometer or MPG behavior.

**Rule:** If the correct value cannot be confidently determined, flag the record instead of silently changing it.

---

### 2.4 Similar Fields Are Not Automatically Equivalent

Different source systems may use different names for similar concepts.

Examples:

| Concept | Example Fields |
|---|---|
| Vehicle identity | `asset_no`, `vehicle_id`, `EQ_EQUIP_NO`, `Asset No`, `Registration` |
| Mileage / odometer | `Mileage`, `Odometer`, `Odometer_Reading`, `METER_1_READING` |
| Fuel type | `fuel_type`, `Fuel_Type`, `Product` |
| Vendor identity | `vendor_id`, `vendor_name`, `supplier_name` |

**Rule:** Similar looking fields should be profiled and validated before they are treated as equivalent.

---

### 2.5 Retain Records, But Protect Metrics

Depending on severity and use case, a record may either remain in the clean layer with warning flags or be excluded from specific clean outputs while still being preserved in exception logs.

Examples:

- A work order with invalid date logic can remain in the clean view but should not be used for calculations.
- A duplicate work order can remain visible but should not be double counted in spend totals.

**Rule:** Do not let known data quality issues silently distort KPIs.

---

## 3. Severity Definitions

| Severity | Meaning | Typical Handling |
|---|---|---|
| **High** | Issue may break joins, duplicate business activity, block entity tracking, or distort major operational metrics. | Route to exception review. Exclude from affected KPIs while unresolved. |
| **Medium** | Issue affects trust, interpretation, or calculation quality but may not block all analysis. | Standardize if safe; otherwise flag and include with caution. |
| **Low** | Issue is mostly formatting, non-critical completeness, or secondary metadata quality. | Clean automatically where safe or log for awareness. |

---

## 4. Standard Actions

| Action | Meaning |
|---|---|
| `PRESERVE_RAW` | Keep the original source value unchanged. |
| `STANDARDIZE` | Convert known variations into a standard clean value. |
| `BACKFILL_IF_CONFIDENT` | Fill a clean layer value only when a trusted, unique match exists. |
| `FLAG_ONLY` | Keep the record but add a warning or exception flag. |
| `REVIEW_REQUIRED` | Route the record for business or analyst review. |
| `EXCLUDE_FROM_METRIC` | Keep the record but exclude it from specific calculations. |
| `DOCUMENT_LIMITATION` | Record known project or mock data limitations. |

---

## 5. General Rule Families

### 5.1 Critical Key and Identifier Rules

Key fields should support traceability, joins, and entity tracking.

Examples include:

| Area | Example Identifiers |
|---|---|
| Vehicle master | `asset_no`, `vehicle_id`, `vin`, `registration_no` |
| Vendor master | `vendor_id`, `vendor_name` |
| Maintenance work orders | `UNIQUE_WORK_ORDER_NO`, `EQ_EQUIP_NO`, vendor fields |
| Fuel transactions | `fuel_txn_id`, `Asset No`, `Registration` |
| Condition assessments | `assessment_id`, `vehicle_id`, `registration_no` |

**Handling:**

- Missing critical identifiers should be flagged.
- Backfill only when a trusted alternate key exists.
- Do not invent source identifiers such as VINs.
- Use derived clean keys only when the derivation is documented.
- Records with unresolved critical keys may remain in clean views but should be excluded from affected entity level metrics.

---

### 5.2 Duplicate and Entity Integrity Rules

Master data keys and transaction IDs should not create ambiguous entity or event definitions.

Examples:

- Duplicate VINs
- Duplicate registration numbers
- Duplicate vendor IDs
- Duplicate work order numbers

**Handling:**

- Do not automatically merge duplicate master records.
- Route duplicate master data groups to exception review.
- Use duplicate flags in the clean layer.
- Exclude duplicate transaction rows from aggregate metrics until reviewed.
- Use normalized names as review aids, not as automatic merge proof.

---

### 5.3 Referential Integrity and Matching Rules

Records that refer to vehicles or vendors should match the appropriate master data source before being trusted for entity level reporting.

Examples:

- Work order equipment number should match the vehicle master.
- Fuel asset number should match the vehicle master.

**Handling:**

- Match first using the strongest available key.
- Use fallback matching only when it is controlled and defensible.
- Preserve the match method in the clean layer.
- Flag unresolved or orphan references.
- Exclude unresolved records from vehicle level, vendor level, or asset level metrics.

---

### 5.4 Standardization Rules

Known label variations should be standardized into consistent reporting categories.

Examples:

| Field Type | Standardization Approach |
|---|---|
| Boolean flags | Map `Y`, `Yes`, `TRUE` to `1`; map `N`, `No`, `FALSE` to `0`; blanks remain `NULL`. |
| Fuel types/products | Map known values into `DIESEL`, `GASOLINE`, `ELECTRIC`, `HYBRID`, or `UNKNOWN`. |
| Distance units | Convert known values into standard distance units. |
| Fuel quantity units | Convert known values into standard quantity units. |
| Status fields | Map known workflow/status values into controlled categories. |

**Handling:**

- Standardize when the mapping is clear.
- Preserve the raw value.
- Create clean standardized fields.
- Flag blank, unknown, or unmapped values when they affect reporting.

---

### 5.5 Numeric and Calculation Rules

Fields used in calculations should be parseable, standardized, and validated before use.

Examples:

- Cost fields
- Labor hours
- MPG
- Odometer readings
- Mileage values

**Handling:**

- Strip safe formatting characters such as dollar signs and commas.
- Convert parseable values into numeric clean fields.
- Set unparseable clean values to `NULL`.
- Flag numeric fields that are missing, invalid, negative, or outside expected ranges.
- Recalculate derived metrics when source components are available.

---

### 5.6 Cost and Financial Consistency Rules

Maintenance cost fields should be validated before spend reporting.

**Handling:**

- Preserve source total cost.
- Create calculated total cost from parsed components.
- Flag total cost mismatches.
- Flag negative costs for review.
- Do not automatically convert negative values to positive.
- Exclude unresolved financial issues from final spend KPIs where appropriate.

---

### 5.7 Date and Sequence Logic Rules

Date fields should follow logical business sequences.

Examples:

- Work order closed date should not occur before open date.
- Last service date should not occur after assessment date.

**Handling:**

- Parse source dates into clean date/time fields.
- Flag invalid or illogical date sequences.
- Do not calculate cycle time, turnaround time, service recency, or mileage progression from invalid sequences.
- Keep records for traceability while excluding them from affected metrics.

---

### 5.8 Cross-Field and Cross-Source Consistency Rules

Fields that describe the same business concept across systems should be compared after standardization.

Examples:

- Vehicle master fuel type vs. condition assessment fuel type
- Raw MPG vs. recalculated MPG

**Handling:**

- Standardize values before comparing.
- Choose a preferred source only when documented.
- Preserve conflicting source values.
- Flag cross-source conflicts.
- Avoid overwriting one system’s value with another unless a business owner confirms the source of truth.

---

## 6. Clean Layer Record Status

Clean records should receive one of the following statuses.

| Resolution Path | Meaning |
|---|---|
| `AUTO_CLEAN` | The issue can be safely standardized or corrected using documented transformation logic. The record can remain available for intended reporting. |
| `MONITOR_ONLY` | The record is usable for some analysis but contains a known issue or caution flag that should remain visible. |
| `REVIEW_REQUIRED` | The record has an issue that requires analyst or business review before full trust. |
| `AUTO_EXCLUDE` | The record should not enter the clean reporting layer, usually because it is blank, structurally unusable, or not meaningful for analysis. |

In the Alteryx implementation, records with `REVIEW_REQUIRED` issues are separated into review-required outputs and loaded into the SharePoint review queue. Clean outputs only include records that are usable for reporting after safe standardization and blocking exception checks.

---

## 7. Exception Handling

Records should be inserted into `dq.data_quality_exceptions` during the SQL prototype phase or written to an Alteryx exception output such as `all_data_quality_exceptions_alteryx.csv` during the Alteryx workflow phase.

Typical exception categories:

| Category | Examples |
|---|---|
| Completeness | Missing critical identifier, missing vehicle reference |
| Uniqueness | Duplicate VIN, duplicate work order, duplicate vendor ID |
| Referential Integrity | Orphan vehicle, orphan vendor, unmatched equipment number |
| Validity | Non-parseable numeric field, invalid cost value |
| Date Logic | Closed date before open date, last service after assessment |
| Sequence Validation | Backward odometer reading |
| Cross-Field Consistency | Total cost mismatch, mileage vs. odometer disagreement |
| Cross-Source Consistency | Conflicting fuel type across systems |

Each exception should include:

- Source table
- Source record ID
- Issue type
- Issue category
- Severity
- Raw value
- Suggested action
- Review status

---

## 8. Metric Protection Rules

Known bad or unresolved records should not silently distort metrics.

| Metric Area | Protection Rule |
|---|---|
| Maintenance spend | Exclude unresolved duplicate work orders and unresolved serious cost issues. |
| Maintenance cycle time | Exclude work orders with invalid open/close date logic. |
| Vehicle level maintenance history | Exclude or flag work orders without a resolved vehicle match. |
| Fuel efficiency | Use recalculated MPG where possible; exclude suspicious/unresolved MPG records. |
| Mileage progression | Exclude backward or missing odometer values from progression calculations. |
| Vendor performance | Exclude or flag records with unresolved vendor matches. |
| Condition/risk reporting | Flag assessments with unresolved vehicle match or conflicting mileage/odometer fields. |

---

## 9. Prototype and Mock Data Limitations

This project uses mock data designed to test data quality workflows. It should not be interpreted as a perfect simulation of real fleet operations.

Known limitations:

- Some generated vehicle configurations may not be manufacturer accurate.
- Fuel type, transmission type, or engine size may not always match real vehicle model constraints.
- Some values were intentionally randomized to create testable quality issues.
- The rules are designed for a proof of concept, not production level accuracy.

In a production setting, these rules would require business owner validation, system-of-record confirmation, and formal KPI definitions.

Open governance questions include:

1. Which vehicle identifier is the official system-of-record key?
2. Which source owns vendor master data?
3. Should negative costs be treated as errors, credits, or adjustments?
4. Should source total cost or calculated total cost be preferred?
5. What MPG thresholds are appropriate by vehicle type and fuel type?
6. Should electric vehicles use a separate efficiency metric?
7. Which exceptions should block dashboard refreshes?

---

## 10. Maintenance Instructions

Update this document when:

- A new source system is added.
- A new rule family is introduced.
- A rule severity changes.
- A clean layer transformation changes.
- A business owner clarifies a data definition.
- A dashboard metric depends on a new quality assumption.
- A mock data or prototype limitation is discovered.

This document should remain general. Detailed SQL implementation should live in SQL scripts or a separate rule catalog if needed.

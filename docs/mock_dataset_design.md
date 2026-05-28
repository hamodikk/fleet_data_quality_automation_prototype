# Mock Dataset Design

This file documents the technical design of the generated mock raw datasets. It is meant to support reproducibility and data lineage. Personal reflections and research notes should remain in the separate project logs.

## Mock raw datasets created

| File | Grain | Approx. rows | Main purpose |
|---|---|---:|---|
| `vehicle_master_raw.csv` | One row per vehicle/asset | 420 | Central vehicle reference table |
| `vendor_master_raw.csv` | One row per vendor/partner | 70 | Vendor, shop, fuel supplier, and service partner reference table |
| `maintenance_work_orders_raw.csv` | One row per maintenance/work order record | 4,022 | Main maintenance operations transaction table |
| `fuel_transactions_raw.csv` | One row per fuel transaction/usage record | 8,012 | Fuel, odometer, quantity, and MPG transaction table |
| `fleet_condition_assessment_raw.csv` | One row per vehicle condition assessment | 1,500 | Vehicle condition and maintenance-risk source table |

## Reproducibility

The data was generated with a fixed random seed: `20260524`.

The generated files are intentionally messy. Raw files should not be overwritten. Any cleaned outputs should be saved separately under `data/clean/` or `data/exceptions/`.

## Intentional issue types included

- Missing keys
- Orphan vehicle references
- Duplicate vendor names and IDs
- Inconsistent casing and category values
- Invalid date logic
- Negative or blank cost values
- Total cost values that do not match component costs
- Mixed units for distance and fuel quantity
- Odometer values that move backward
- Impossible or suspicious MPG values
- Conflicting vehicle fuel types across source files
- Similar mileage/odometer fields that should not be blindly treated as identical

## Relationship notes

The intended raw relationships are imperfect by design:

- `vehicle_master_raw.asset_no` may match `maintenance_work_orders_raw.EQ_EQUIP_NO`
- `vehicle_master_raw.asset_no` may match `fuel_transactions_raw.Asset No`
- `vehicle_master_raw.registration_no` may match `fuel_transactions_raw.Registration`
- `vehicle_master_raw.vehicle_id` may match `fleet_condition_assessment_raw.vehicle_id`
- `vendor_master_raw.vendor_id` may match `maintenance_work_orders_raw.vendor_id`
- `vendor_master_raw.vendor_name` may match `maintenance_work_orders_raw.vendor_name` or `fuel_transactions_raw.supplier_name`

Some records intentionally fail these relationships to support data quality exception handling.

## Limitations

The mock datasets generated are useful for testing data quality workflows, but it is not a perfect representation of real fleet specifications. Some fields were generated using broad random categories rather than strict real-world compatibilities.

- Fuel type is not constrained by make/model
- Transmission type is not constrained by make/model
- Engine size is not constrained by make/model
- Vehicle model, fuel type, and condition fields are good for workflow testing, but may not be compatible with each other (Electric Ford F-150, a manual transmission Prius, etc.)
- The mock dataset is not intended for real fleet performance claims.
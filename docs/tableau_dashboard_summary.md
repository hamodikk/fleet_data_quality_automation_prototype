# Tableau Dashboard Summary

## Purpose

The Tableau portion of the project provides a reporting layer for both data quality health and clean fleet operations reporting.

## Dashboard 1: Data Quality Command Center

This dashboard uses `all_data_quality_exceptions_alteryx.csv`.

It summarizes:
- total exceptions
- high-severity exceptions
- review-required exceptions
- exceptions by severity
- exceptions by source table
- top exception types
- review status breakdown

The purpose of this dashboard is to show whether the underlying fleet data can be trusted before it is used for business reporting.

## Dashboard 2: Fleet Operations Snapshot

This dashboard uses the clean Alteryx outputs, including:
- `vehicle_master_clean_alteryx.csv`
- `vendor_master_clean_alteryx.csv`
- `maintenance_work_orders_clean_alteryx.csv`
- `fuel_transactions_clean_alteryx.csv`
- `fleet_condition_assessment_clean_alteryx.csv`

It summarizes clean-data reporting examples such as:
- clean vehicle count
- clean vendor count
- maintenance work order volume
- maintenance cost by vendor
- maintenance cost by vehicle
- fuel transaction activity
- MPG by vehicle
- fleet condition assessment metrics

The purpose of this dashboard is to show what operational reporting becomes possible after messy fleet data is cleaned and reviewed.

## Notes

The dashboards are intentionally separated into a data quality view and an operations view. This helps show both the reliability of the data and the business insights that can be created from the cleaned outputs.
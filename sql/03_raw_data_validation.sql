USE DataIntegrityAutomationPrototype;
GO

SELECT
    'vehicle_master_raw' AS table_name,
    COUNT(*) AS row_count
FROM raw.vehicle_master_raw

UNION ALL

SELECT
    'vendor_master_raw' AS table_name,
    COUNT(*) AS row_count
FROM raw.vendor_master_raw

UNION ALL

SELECT
    'maintenance_work_orders_raw' AS table_name,
    COUNT(*) AS row_count
FROM raw.maintenance_work_orders_raw

UNION ALL

SELECT
    'fuel_transactions_raw' AS table_name,
    COUNT(*) AS row_count
FROM raw.fuel_transactions_raw

UNION ALL

SELECT
    'fleet_condition_assessment_raw' AS table_name,
    COUNT(*) AS row_count
FROM raw.fleet_condition_assessment_raw;
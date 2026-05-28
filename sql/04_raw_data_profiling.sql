USE DataIntegrityAutomationPrototype;
GO

SELECT
    'vehicle_master_raw' AS table_name,
    COUNT(*) AS row_count
FROM raw.vehicle_master_raw

UNION ALL

SELECT
    'vendor_master_raw',
    COUNT(*)
FROM raw.vendor_master_raw

UNION ALL

SELECT
    'maintenance_work_orders_raw',
    COUNT(*)
FROM raw.maintenance_work_orders_raw

UNION ALL

SELECT
    'fuel_transactions_raw',
    COUNT(*)
FROM raw.fuel_transactions_raw

UNION ALL

SELECT
    'fleet_condition_assessment_raw',
    COUNT(*)
FROM raw.fleet_condition_assessment_raw;

-- Vehicle Master Profiling

-- Missing and duplicate values for key fields
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN TRIM(ISNULL(asset_no, '')) = '' THEN 1 ELSE 0 END) AS missing_asset_no,
    SUM(CASE WHEN TRIM(ISNULL(vehicle_id, '')) = '' THEN 1 ELSE 0 END) AS missing_vehicle_id,
    SUM(CASE WHEN TRIM(ISNULL(vin, '')) = '' THEN 1 ELSE 0 END) AS missing_vin,
    SUM(CASE WHEN TRIM(ISNULL(registration_no, '')) = '' THEN 1 ELSE 0 END) AS missing_registration_no,

    COUNT(DISTINCT NULLIF(TRIM(asset_no), '')) AS distinct_asset_no,
    COUNT(DISTINCT NULLIF(TRIM(vehicle_id), '')) AS distinct_vehicle_id,
    COUNT(DISTINCT NULLIF(TRIM(vin), '')) AS distinct_vin,
    COUNT(DISTINCT NULLIF(TRIM(registration_no), '')) AS distinct_registration_no
FROM raw.vehicle_master_raw;

-- Duplicate asset numbers
SELECT
    asset_no,
    COUNT(*) AS duplicate_count
FROM raw.vehicle_master_raw
WHERE TRIM(ISNULL(asset_no, '')) <> ''
GROUP BY asset_no
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Duplicate VINs
SELECT
    vin,
    COUNT(*) AS duplicate_count
FROM raw.vehicle_master_raw
WHERE TRIM(ISNULL(vin, '')) <> ''
GROUP BY vin
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Duplicate registration numbers
SELECT
    registration_no,
    COUNT(*) AS duplicate_count
FROM raw.vehicle_master_raw
WHERE TRIM(ISNULL(registration_no, '')) <> ''
GROUP BY registration_no
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Distribution of fuel types
SELECT
    fuel_type,
    COUNT(*) AS record_count
FROM raw.vehicle_master_raw
GROUP BY fuel_type
ORDER BY record_count DESC;

-- Vendor Master Profiling

-- Missing IDs and inconsistent flags
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN TRIM(ISNULL(vendor_id, '')) = '' THEN 1 ELSE 0 END) AS missing_vendor_id,
    SUM(CASE WHEN TRIM(ISNULL(vendor_name, '')) = '' THEN 1 ELSE 0 END) AS missing_vendor_name,
    SUM(CASE WHEN TRIM(ISNULL(contact_email, '')) = '' THEN 1 ELSE 0 END) AS missing_contact_email,

    COUNT(DISTINCT NULLIF(TRIM(vendor_id), '')) AS distinct_vendor_id,
    COUNT(DISTINCT NULLIF(TRIM(vendor_name), '')) AS distinct_vendor_name
FROM raw.vendor_master_raw;

-- Duplicate vendor IDs
SELECT
    vendor_id,
    COUNT(*) AS duplicate_count
FROM raw.vendor_master_raw
WHERE TRIM(ISNULL(vendor_id, '')) <> ''
GROUP BY vendor_id
HAVING COUNT(*) >1
ORDER BY duplicate_count DESC;

-- Vendor name variants
SELECT
    UPPER(
        REPLACE(
            REPLACE(
                REPLACE(TRIM(vendor_name), '''', ''),
            '.', ''),
        '&', 'AND')
    ) AS normalized_vendor_name,
    COUNT(*) AS record_count
FROM raw.vendor_master_raw
WHERE TRIM(ISNULL(vendor_name, '')) <> ''
GROUP BY
    UPPER(
        REPLACE(
            REPLACE(
                REPLACE(TRIM(vendor_name), '''', ''),
            '.', ''),
        '&', 'AND')
    )
HAVING COUNT(*) > 1
ORDER BY record_count DESC;

-- Preferred vendor flag values
SELECT
    preferred_vendor_flag,
    COUNT(*) AS record_count
FROM raw.vendor_master_raw
GROUP BY preferred_vendor_flag
ORDER BY record_count DESC;

SELECT
    partner_type,
    COUNT(*) AS record_count
FROM raw.vendor_master_raw
GROUP BY partner_type
ORDER BY record_count DESC;

-- Maintenance Work Order Profiling

-- Missing keys and basic counts
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN TRIM(ISNULL(UNIQUE_WORK_ORDER_NO, '')) = '' THEN 1 ELSE 0 END) AS missing_unique_work_order_no,
    SUM(CASE WHEN TRIM(ISNULL(EQ_EQUIP_NO, '')) = '' THEN 1 ELSE 0 END) AS missing_equipment_no,
    SUM(CASE WHEN TRIM(ISNULL(vendor_id, '')) = '' THEN 1 ELSE 0 END) AS missing_vendor_id,
    SUM(CASE WHEN TRIM(ISNULL(vendor_name, '')) = '' THEN 1 ELSE 0 END) AS missing_vendor_name,

    COUNT(DISTINCT NULLIF(TRIM(UNIQUE_WORK_ORDER_NO), '')) AS distinct_work_orders,
    COUNT(DISTINCT NULLIF(TRIM(EQ_EQUIP_NO), '')) AS distinct_equipment_numbers
FROM raw.maintenance_work_orders_raw;

--Duplicate work orders
SELECT
    UNIQUE_WORK_ORDER_NO,
    COUNT(*) AS duplicate_count
FROM raw.maintenance_work_orders_raw
WHERE TRIM(ISNULL(UNIQUE_WORK_ORDER_NO, '')) <> ''
GROUP BY UNIQUE_WORK_ORDER_NO
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Work orders that do not match vehicle master
SELECT
    COUNT(*) AS orphan_work_order_count
FROM raw.maintenance_work_orders_raw m
LEFT JOIN raw.vehicle_master_raw v
    ON TRIM(m.EQ_EQUIP_NO) = TRIM(v.asset_no)
WHERE TRIM(ISNULL(m.EQ_EQUIP_NO, '')) <> ''
    AND v.asset_no IS NULL;

-- Examples of orphan work orders
SELECT TOP 25
    m.UNIQUE_WORK_ORDER_NO,
    m.EQ_EQUIP_NO,
    m.JOB_TYPE,
    m.WORK_ORDER_STATUS,
    m.vendor_name,
    m.TOTAL_COST
FROM raw.maintenance_work_orders_raw m
LEFT JOIN raw.vehicle_master_raw v
    ON TRIM(m.EQ_EQUIP_NO) = TRIM(v.asset_no)
WHERE TRIM(ISNULL(m.EQ_EQUIP_NO, '')) <> ''
    AND v.asset_no IS NULL;

-- Date logic problems
WITH parsed_dates AS (
    SELECT
        UNIQUE_WORK_ORDER_NO,
        DATETIME_OPEN,
        DATETIME_CLOSED,

        COALESCE(
            TRY_CONVERT(datetime2, DATETIME_OPEN, 120),
            TRY_CONVERT(datetime2, DATETIME_OPEN, 101),
            TRY_CONVERT(datetime2, DATETIME_OPEN)
        ) AS parsed_open_date,

        COALESCE(
            TRY_CONVERT(datetime2, DATETIME_CLOSED, 120),
            TRY_CONVERT(datetime2, DATETIME_CLOSED, 101),
            TRY_CONVERT(datetime2, DATETIME_CLOSED)
        ) AS parsed_closed_date
    FROM raw.maintenance_work_orders_raw
)
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN parsed_open_date IS NULL THEN 1 ELSE 0 END) AS invalid_open_date,
    SUM(CASE WHEN parsed_closed_date IS NULL THEN 1 ELSE 0 END) AS invalid_closed_date,
    SUM(CASE
            WHEN parsed_open_date IS NOT NULL
            AND parsed_closed_date IS NOT NULL
            AND parsed_closed_date < parsed_open_date
            THEN 1 ELSE 0
        END) AS closed_before_open_count
    FROM parsed_dates;

-- Cost field problems
WITH cost_parse AS (
    SELECT
        UNIQUE_WORK_ORDER_NO,

        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(LABOR_COST), ''), '$', ''), ',', '')) AS labor_cost_num,
        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(PARTS_COST), ''), '$', ''), ',', '')) AS parts_cost_num,
        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(COMML_COST), ''), '$', ''), ',', '')) AS comml_cost_num,
        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(TOTAL_COST), ''), '$', ''), ',', '')) AS total_cost_num
    FROM raw.maintenance_work_orders_raw
)
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN labor_cost_num IS NULL THEN 1 ELSE 0 END) AS invalid_or_missing_labor_cost,
    SUM(CASE WHEN parts_cost_num IS NULL THEN 1 ELSE 0 END) AS invalid_or_missing_parts_cost,
    SUM(CASE WHEN comml_cost_num IS NULL THEN 1 ELSE 0 END) AS invalid_or_missing_comml_cost,
    SUM(CASE WHEN total_cost_num IS NULL THEN 1 ELSE 0 END) AS invalid_or_missing_total_cost,

    SUM(CASE WHEN labor_cost_num < 0 THEN 1 ELSE 0 END) AS negative_labor_cost_count,

    SUM(CASE
            WHEN labor_cost_num IS NOT NULL
            AND parts_cost_num IS NOT NULL
            AND comml_cost_num IS NOT NULL
            AND total_cost_num IS NOT NULL
            AND ABS(total_cost_num - (labor_cost_num + parts_cost_num + comml_cost_num)) > 1
            THEN 1 ELSE 0
        END) AS total_cost_mismatch_count
FROM cost_parse;

-- Fuel Transaction Profiling

-- Missing keys and blank rows
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE
            WHEN TRIM(ISNULL(fuel_txn_id, '')) = ''
            AND TRIM(ISNULL(transaction_date, '')) = ''
            AND TRIM(ISNULL([Asset No], '')) = ''
            AND TRIM(ISNULL(Registration, '')) = ''
            THEN 1 ELSE 0
        END) AS likely_blank_rows,
    
    SUM(CASE WHEN TRIM(ISNULL(fuel_txn_id, '')) = '' THEN 1 ELSE 0 END) AS missing_fuel_txn_id,
    SUM(CASE WHEN TRIM(ISNULL([Asset No], '')) = '' THEN 1 ELSE 0 END) AS missing_asset_no,
    SUM(CASE WHEN TRIM(ISNULL(Registration, '')) = '' THEN 1 ELSE 0 END) AS missing_registration,
    SUM(CASE WHEN TRIM(ISNULL(Odometer, '')) = '' THEN 1 ELSE 0 END) AS missing_odometer
FROM raw.fuel_transactions_raw;

-- Fuel transactions that do not match vehicle master by asset number
SELECT
    COUNT(*) AS orphan_fuel_asset_count
FROM raw.fuel_transactions_raw f
LEFT JOIN raw.vehicle_master_raw v
    ON TRIM(f.[Asset No]) = TRIM(v.asset_no)
WHERE TRIM(ISNULL(f.[Asset No], '')) <> ''
    AND v.asset_no IS NULL;

-- Distance unit values
SELECT
    Unit,
    COUNT(*) AS record_count
FROM raw.fuel_transactions_raw
GROUP BY Unit
ORDER BY record_count DESC;

-- Fuel quantity unit values
SELECT
    Qty_UOM,
    COUNT(*) AS record_count
FROM raw.fuel_transactions_raw
GROUP BY Qty_UOM
ORDER BY record_count DESC;

-- Fuel product types
SELECT
    Product,
    COUNT(*) AS record_count
FROM raw.fuel_transactions_raw
GROUP BY Product
ORDER BY record_count DESC;

-- Suspicious MPG values
WITH mpg_parse AS (
    SELECT
        fuel_txn_id,
        [Asset No],
        Registration,
        Product,
        MPG,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(MPG), '')) AS mpg_num
    FROM raw.fuel_transactions_raw
)
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN mpg_num IS NULL THEN 1 ELSE 0 END) AS invalid_or_missing_mpg,
    SUM(CASE WHEN mpg_num = 0 THEN 1 ELSE 0 END) AS zero_mpg_count,
    SUM(CASE WHEN mpg_num > 90 THEN 1 ELSE 0 END) AS very_high_mpg_count,
    SUM(CASE WHEN mpg_num > 0 AND mpg_num < 2 THEN 1 ELSE 0 END) AS very_low_mpg_count
FROM mpg_parse;

-- Backward odometer readings
WITH parsed_fuel AS (
    SELECT
        fuel_txn_id,
        [Asset No] AS asset_no,
        transaction_date,
        Odometer,

        COALESCE(
            TRY_CONVERT(datetime2, transaction_date, 120),
            TRY_CONVERT(datetime2, transaction_date, 101),
            TRY_CONVERT(datetime2, transaction_date)
        ) AS parsed_transaction_date,

        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(Odometer), '')) AS odometer_num
    FROM raw.fuel_transactions_raw
    WHERE TRIM(ISNULL([Asset NO], '')) <> ''
),
ordered_fuel AS (
    SELECT
        *,
        LAG(odometer_num) OVER (
            PARTITION BY asset_no
            ORDER BY parsed_transaction_date, fuel_txn_id
        ) AS previous_odometer
    FROM parsed_fuel
    WHERE parsed_transaction_date IS NOT NULL
        AND odometer_num IS NOT NULL
)
SELECT
    COUNT(*) AS backward_odometer_count
FROM ordered_fuel
WHERE previous_odometer IS NOT NULL
    AND odometer_num < previous_odometer;

-- Fleet Condition Assessment Profiling

-- Missing vehicle identifiers
SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN TRIM(ISNULL(assessment_id, '')) = '' THEN 1 ELSE 0 END) AS missing_assessment_id,
    SUM(CASE WHEN TRIM(ISNULL(vehicle_id, '')) = '' THEN 1 ELSE 0 END) AS missing_vehicle_id,
    SUM(CASE WHEN TRIM(ISNULL(registration_no, '')) = '' THEN 1 ELSE 0 END) AS missing_registration_no,

    COUNT(DISTINCT NULLIF(TRIM(vehicle_id), '')) AS distinct_vehicle_id,
    COUNT(DISTINCT NULLIF(TRIM(registration_no), '')) AS distinct_registration_no
FROM raw.fleet_condition_assessment_raw;

-- Assessments that do not match vehicle master by vehicle ID
SELECT
    COUNT(*) AS orphan_condition_vehicle_id_count
FROM raw.fleet_condition_assessment_raw c
LEFT JOIN raw.vehicle_master_raw v
    ON TRIM(c.vehicle_id) = TRIM(v.vehicle_id)
WHERE TRIM(ISNULL(c.vehicle_id, '')) <> ''
    AND v.vehicle_id IS NULL;

-- Last service date after assessment date
WITH parsed_dates AS (
    SELECT
        assessment_id,
        assessment_date,
        Last_Service_Date,

        COALESCE(
            TRY_CONVERT(date, assessment_date, 23),
            TRY_CONVERT(date, assessment_date, 101),
            TRY_CONVERT(date, assessment_date)
        ) AS parsed_assessment_date,

        COALESCE(
            TRY_CONVERT(date, Last_Service_Date, 23),
            TRY_CONVERT(date, Last_Service_Date, 101),
            TRY_CONVERT(date, Last_Service_Date)
        ) AS parsed_last_service_date
    FROM raw.fleet_condition_assessment_raw
)
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN parsed_assessment_date IS NULL THEN 1 ELSE 0 END) AS invalid_assessment_date,
    SUM(CASE WHEN parsed_last_service_date IS NULL THEN 1 ELSE 0 END) AS invalid_last_service_date,
    SUM(CASE
            WHEN parsed_assessment_date IS NOT NULL
            AND parsed_last_service_date IS NOT NULL
            AND parsed_last_service_date > parsed_assessment_date
            THEN 1 ELSE 0
        END) AS last_service_after_assessment_count
FROM parsed_dates;

-- Mileage vs odometer disagreement
WITH mileage_parse AS (
    SELECT
        assessment_id,
        vehicle_id,
        Mileage,
        Odometer_Reading,

        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(Mileage), '')) AS mileage_num,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(Odometer_Reading), '')) AS odometer_reading_num
    FROM raw.fleet_condition_assessment_raw
)
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN mileage_num IS NULL THEN 1 ELSE 0 END) AS invalid_or_missing_mileage,
    SUM(CASE WHEN odometer_reading_num IS NULL THEN 1 ELSE 0 END) AS invalid_or_missing_odometer_reading,
    SUM(CASE
            WHEN mileage_num IS NOT NULL
            AND odometer_reading_num IS NOT NULL
            AND ABS(mileage_num - odometer_reading_num) > 5000
            THEN 1 ELSE 0
        END) AS mileage_odometer_large_difference_count
FROM mileage_parse;

-- Cross-source fuel type conflicts
WITH vehicle_fuel AS (
    SELECT
        vehicle_id,
        registration_no,
        fuel_type,

        CASE
            WHEN UPPER(fuel_type) IN ('DIESEL', 'DSL') THEN 'DIESEL'
            WHEN UPPER(fuel_type) IN ('GASOLINE', 'GAS', 'UNLEADED', 'PETROL') THEN 'GASOLINE'
            WHEN UPPER(fuel_type) IN ('ELECTRIC', 'EV') THEN 'ELECTRIC'
            ELSE 'UNKNOWN'
        END AS standardized_vehicle_fuel_type
    FROM raw.vehicle_master_raw
),
condition_fuel AS (
    SELECT
        vehicle_id,
        registration_no,
        Fuel_Type,

        CASE
            WHEN UPPER(Fuel_Type) IN ('DIESEL', 'DSL') THEN 'DIESEL'
            WHEN UPPER(Fuel_Type) IN ('GASOLINE', 'GAS', 'UNLEADED', 'PETROL') THEN 'GASOLINE'
            WHEN UPPER(Fuel_Type) IN ('ELECTRIC', 'EV') THEN 'ELECTRIC'
            ELSE 'UNKNOWN'
        END AS standardized_condition_fuel_type
    FROM raw.fleet_condition_assessment_raw
)
SELECT
    COUNT(*) AS compared_record,
    SUM(CASE
            WHEN vf.standardized_vehicle_fuel_type <> cf.standardized_condition_fuel_type
            THEN 1 ELSE 0
        END) AS conflicting_fuel_type_count
FROM condition_fuel cf
INNER JOIN vehicle_fuel vf
    ON TRIM(cf.vehicle_id) = TRIM(vf.vehicle_id)
WHERE cf.standardized_condition_fuel_type <> 'UNKNOWN'
AND vf.standardized_vehicle_fuel_type <> 'UNKNOWN';
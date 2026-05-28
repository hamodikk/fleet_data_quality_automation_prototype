USE DataIntegrityAutomationPrototype;
GO

IF OBJECT_ID('dq.data_quality_exceptions', 'U') IS NOT NULL
    DROP TABLE dq.data_quality_exceptions;
GO


-- Create a table to store data quality exceptions
CREATE TABLE dq.data_quality_exceptions (
    exception_id INT Identity(1,1) PRIMARY KEY,
    source_table NVARCHAR(100),
    source_record_id NVARCHAR(255),
    issue_type NVARCHAR(100),
    issue_category NVARCHAR(100),
    severity NVARCHAR(50),
    issue_description NVARCHAR(1000),
    raw_value NVARCHAR(1000),
    suggested_action NVARCHAR(1000),
    review_status NVARCHAR(50) DEFAULT 'New',
    created_at DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- Vehicle exceptions
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.vehicle_master_raw',
    asset_no,
    'Missing vehicle_id',
    'Completeness',
    'High',
    'Vehicle record is missing vehicle_id. This may affect joins to downstream systems.',
    ISNULL(vehicle_id, ''),
    'Use asset_no as temporary clean vehicle key only if asset_no is unique, otherwise review with source owner.'
FROM raw.vehicle_master_raw
WHERE TRIM(ISNULL(vehicle_id, '')) = '';

INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.vehicle_master_raw',
    asset_no,
    'Missing VIN',
    'Completeness',
    'Medium',
    'Vehicle record is missing VIN. This may reduce asset traceability but may not block operational reporting.',
    ISNULL(vin, ''),
    'Do not invent a new VIN. Backfill only from authoritative vehicle source if available.'
FROM raw.vehicle_master_raw
WHERE TRIM(ISNULL(vin, '')) = '';

WITH duplicate_vins AS (
    SELECT vin
    FROM raw.vehicle_master_raw
    WHERE TRIM(ISNULL(vin, '')) <> ''
    GROUP BY vin
    HAVING COUNT(*) > 1
)
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.vehicle_master_raw',
    v.asset_no,
    'Duplicate VIN',
    'Uniqueness',
    'High',
    'VIN appears on more than one vehicle record, which can break vehicle entity integrity.',
    v.vin,
    'Quarantine duplicate VIN records and review which vehicle record is authoritative.'
FROM raw.vehicle_master_raw v
INNER JOIN duplicate_vins d
    ON v.vin = d.vin;

WITH duplicate_registrations AS (
    SELECT registration_no
    FROM raw.vehicle_master_raw
    WHERE TRIM(ISNULL(registration_no, '')) <> ''
    GROUP BY registration_no
    HAVING COUNT(*) > 1
)
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.vehicle_master_raw',
    v.asset_no,
    'Duplicate registration number',
    'Uniqueness',
    'High',
    'Registration number appears on more than one vehicle record, which may cause incorrect vehicle matching.',
    v.registration_no,
    'Review duplicate registration groups before using registration number as a matching key.'
FROM raw.vehicle_master_raw v
INNER JOIN duplicate_registrations d
    ON v.registration_no = d.registration_no;

-- Vendor exceptions
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.vendor_master_raw',
    ISNULL(vendor_name, ''),
    'Missing vendor_id',
    'Completeness',
    'High',
    'Vendor record is missing vendor_id, which affects joins to work orders and vendor reporting.',
    ISNULL(vendor_id, ''),
    'Backfill from source system if possible. Otherwise assign a controlled surrogate key and flag for audit.'
FROM raw.vendor_master_raw
WHERE TRIM(ISNULL(vendor_id, '')) = '';

WITH duplicate_vendor_ids AS (
    SELECT vendor_id
    FROM raw.vendor_master_raw
    WHERE TRIM(ISNULL(vendor_id, '')) <> ''
    GROUP BY vendor_id
    HAVING COUNT(*) > 1
)
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.vendor_master_raw',
    v.vendor_id,
    'Duplicate vendor_id',
    'Uniqueness',
    'High',
    'Vendor ID appears on more than one vendor record.',
    CONCAT('vendor_id: ', v.vendor_id, '; vendor_name: ', v.vendor_name),
    'Quarantine duplicate vendor IDs and review whether records should be merged or corrected.'
FROM raw.vendor_master_raw v
INNER JOIN duplicate_vendor_ids d
    ON v.vendor_id = d.vendor_id;

INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.vendor_master_raw',
    ISNULL(vendor_id, vendor_name),
    'Missing contact_email',
    'Completeness',
    'Low',
    'Vendor record is missing contact email.',
    ISNULL(contact_email, ''),
    'Backfill from vendor management source if available. Allow null for inactive vendors if business-approved.'
FROM raw.vendor_master_raw
WHERE TRIM(ISNULL(contact_email, '')) = '';

WITH normalized_vendors AS (
    SELECT
        vendor_id,
        vendor_name,
        UPPER(
            REPLACE(
                REPLACE(
                    REPLACE(TRIM(vendor_name), '''', ''),
                '.', ''),
            '&', 'AND')
        ) AS normalized_vendor_name
    FROM raw.vendor_master_raw
    WHERE TRIM(ISNULL(vendor_name, '')) <> ''
),
repeated_names AS (
    SELECT normalized_vendor_name
    FROM normalized_vendors
    GROUP BY normalized_vendor_name
    HAVING COUNT(*) > 1
)
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.vendor_master_raw',
    ISNULL(nv.vendor_id, nv.vendor_name),
    'Repeated normalized vendor name',
    'Entity Resolution',
    'Medium',
    'Normalized vendor name appears more than once and may represent duplicate vendor entities or repeated vendor records.',
    CONCAT('vendor_name: ', nv.vendor_name, '; normalized_vendor_name: ', nv.normalized_vendor_name),
    'Review repeated normalized vendor groups and maintain a vendor alias/crosswalk table.'
FROM normalized_vendors nv
INNER JOIN repeated_names rn
    ON nv.normalized_vendor_name = rn.normalized_vendor_name;

-- Maintenance exceptions
WITH duplicate_work_orders AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY UNIQUE_WORK_ORDER_NO
            ORDER BY CREATE_DATE, WORK_ORDER_NO
        ) AS duplicate_row_number
    FROM raw.maintenance_work_orders_raw
)
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.maintenance_work_orders_raw',
    UNIQUE_WORK_ORDER_NO,
    'Duplicate work order number',
    'Uniqueness',
    'High',
    'Duplicate UNIQUE_WORK_ORDER_NO may cause double-counting of maintenance activity or costs.',
    UNIQUE_WORK_ORDER_NO,
    'Keep one primary record for clean reporting and route duplicate records for review.'
FROM duplicate_work_orders
WHERE duplicate_row_number > 1;

INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.maintenance_work_orders_raw',
    m.UNIQUE_WORK_ORDER_NO,
    'Orphan equipment reference',
    'Referential Integrity',
    'High',
    'Work order equipment number does not match any asset_no in vehicle master.',
    m.EQ_EQUIP_NO,
    'Review equipment number or vehicle master. Do not include in asset level reporting until resolved.'
FROM raw.maintenance_work_orders_raw m
LEFT JOIN raw.vehicle_master_raw v
    ON TRIM(m.EQ_EQUIP_NO) = TRIM(v.asset_no)
WHERE TRIM(ISNULL(m.EQ_EQUIP_NO, '')) <> ''
    AND v.asset_no IS NULL;

WITH parsed_dates AS (
    SELECT
        UNIQUE_WORK_ORDER_NO,
        DATETIME_OPEN,
        DATETIME_CLOSED,
        COALESCE(
            TRY_CONVERT(datetime2, DATETIME_OPEN, 120),
            TRY_CONVERT(datetime2, DATETIME_OPEN, 101),
            TRY_CONVERT(datetime2, DATETIME_OPEN)
        ) AS open_dt,
        COALESCE(
            TRY_CONVERT(datetime2, DATETIME_CLOSED, 120),
            TRY_CONVERT(datetime2, DATETIME_CLOSED, 101),
            TRY_CONVERT(datetime2, DATETIME_CLOSED)
        ) AS closed_dt
    FROM raw.maintenance_work_orders_raw
)
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.maintenance_work_orders_raw',
    UNIQUE_WORK_ORDER_NO,
    'Closed date before open date',
    'Date Logic',
    'High',
    'DATETIME_CLOSED occurs before DATETIME_OPEN, making turnaround-time calculations unreliable.',
    CONCAT('Open: ', DATETIME_OPEN, '; Closed: ', DATETIME_CLOSED),
    'Exclude from cycle-time metrics until corrected by source owner.'
FROM parsed_dates
WHERE open_dt IS NOT NULL
    AND closed_dt IS NOT NULL
    AND closed_dt < open_dt;

INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.maintenance_work_orders_raw',
    UNIQUE_WORK_ORDER_NO,
    'Missing equipment number',
    'Completeness',
    'High',
    'Work order is missing EQ_EQUIP_NO, preventing reliable vehicle-level reporting.',
    ISNULL(EQ_EQUIP_NO, ''),
    'Backfill from maintenance source system if possible. Otherwise route for review.'
FROM raw.maintenance_work_orders_raw
WHERE TRIM(ISNULL(EQ_EQUIP_NO, '')) = '';

INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.maintenance_work_orders_raw',
    UNIQUE_WORK_ORDER_NO,
    'Missing vendor reference',
    'Completeness',
    'Medium',
    'Work order is missing vendor_id or vendor_name, limiting vendor-level reporting.',
    CONCAT('vendor_id: ', ISNULL(vendor_id, ''), '; vendor_name: ', ISNULL(vendor_name, '')),
    'Backfill vendor reference where possible. Allow valid internal-work-order exceptions if documented.'
FROM raw.maintenance_work_orders_raw
WHERE TRIM(ISNULL(vendor_id, '')) = ''
   OR TRIM(ISNULL(vendor_name, '')) = '';

WITH cost_parse AS (
    SELECT
        UNIQUE_WORK_ORDER_NO,
        LABOR_COST,
        PARTS_COST,
        COMML_COST,
        TOTAL_COST,
        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(LABOR_COST), ''), '$', ''), ',', '')) AS labor_cost_num,
        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(PARTS_COST), ''), '$', ''), ',', '')) AS parts_cost_num,
        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(COMML_COST), ''), '$', ''), ',', '')) AS comml_cost_num,
        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(TOTAL_COST), ''), '$', ''), ',', '')) AS total_cost_num
    FROM raw.maintenance_work_orders_raw
)
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.maintenance_work_orders_raw',
    UNIQUE_WORK_ORDER_NO,
    'Maintenance cost validation issue',
    'Numeric Validation',
    CASE 
        WHEN labor_cost_num < 0 THEN 'High'
        ELSE 'Medium'
    END,
    'Maintenance cost fields contain negative values, missing parts cost, or total-cost reconciliation mismatch.',
    CONCAT(
        'Labor: ', ISNULL(LABOR_COST, ''),
        '; Parts: ', ISNULL(PARTS_COST, ''),
        '; Commercial: ', ISNULL(COMML_COST, ''),
        '; Total: ', ISNULL(TOTAL_COST, '')
    ),
    'Parse cost fields numerically, review negative costs, and recalculate total cost from validated components.'
FROM cost_parse
WHERE labor_cost_num < 0
   OR parts_cost_num IS NULL
   OR (
        total_cost_num IS NOT NULL
        AND labor_cost_num IS NOT NULL
        AND parts_cost_num IS NOT NULL
        AND comml_cost_num IS NOT NULL
        AND ABS(total_cost_num - (labor_cost_num + parts_cost_num + comml_cost_num)) > 1
      );

-- Fuel exceptions
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.fuel_transactions_raw',
    ISNULL(fuel_txn_id, ''),
    'Likely blank row',
    'Completeness',
    'Low',
    'Fuel transaction row appears blank or structurally empty.',
    '',
    'Exclude from clean fuel transaction table'
FROM raw.fuel_transactions_raw
WHERE TRIM(ISNULL(fuel_txn_id, '')) = ''
    AND TRIM(ISNULL(transaction_date, '')) = ''
    AND TRIM(ISNULL([Asset No], '')) = ''
    AND TRIM(ISNULL(Registration, '')) = '';

INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.fuel_transactions_raw',
    f.fuel_txn_id,
    'Orphan fuel asset reference',
    'Referential Integrity',
    'High',
    'Fuel transaction asset number does not match vehicle master.',
    f.[Asset No],
    'Review registration match. If no confident match exists, exclude from vehicle level reporting.'
FROM raw.fuel_transactions_raw f
LEFT JOIN raw.vehicle_master_raw v
    ON TRIM(f.[Asset No]) = TRIM(v.asset_no)
WHERE TRIM(ISNULL(f.[Asset No], '')) <> ''
    AND v.asset_no IS NULL;

WITH mpg_parse AS (
    SELECT
        fuel_txn_id,
        [Asset No],
        MPG,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(MPG), '')) AS mpg_num
    FROM raw.fuel_transactions_raw
)
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.fuel_transactions_raw',
    fuel_txn_id,
    'Suspicious MPG',
    'Range Validation',
    'Medium',
    'MPG value is zero, very low, very high, or not parseable',
    MPG,
    'Recalculate MPG after standardizing distance and fuel quantity units. Treat electric records separately.'
FROM mpg_parse
WHERE mpg_num IS NULL
    OR mpg_num = 0
    OR mpg_num > 90
    OR (mpg_num > 0 AND mpg_num < 2);

INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.fuel_transactions_raw',
    ISNULL(fuel_txn_id, ''),
    'Missing fuel transaction identifier',
    'Completeness',
    'Medium',
    'Fuel transaction is missing fuel_txn_id, reducing traceability.',
    ISNULL(fuel_txn_id, ''),
    'Generate controlled surrogate key only if the rest of the row is usable; otherwise quarantine.'
FROM raw.fuel_transactions_raw
WHERE TRIM(ISNULL(fuel_txn_id, '')) = ''
  AND NOT (
        TRIM(ISNULL(transaction_date, '')) = ''
    AND TRIM(ISNULL([Asset No], '')) = ''
    AND TRIM(ISNULL(Registration, '')) = ''
  );

INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.fuel_transactions_raw',
    ISNULL(fuel_txn_id, ''),
    'Missing vehicle reference',
    'Completeness',
    'High',
    'Fuel transaction is missing Asset No, limiting vehicle-level reporting.',
    CONCAT('Asset No: ', ISNULL([Asset No], ''), '; Registration: ', ISNULL(Registration, '')),
    'Attempt registration-based match. If no confident match exists, quarantine for review.'
FROM raw.fuel_transactions_raw
WHERE TRIM(ISNULL([Asset No], '')) = ''
    AND NOT (
        TRIM(ISNULL(fuel_txn_id, '')) = ''
    AND TRIM(ISNULL(transaction_date, '')) = ''
    AND TRIM(ISNULL(Registration, '')) = ''
    );

INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.fuel_transactions_raw',
    ISNULL(fuel_txn_id, ''),
    'Missing odometer',
    'Completeness',
    'Medium',
    'Fuel transaction is missing odometer, weakening MPG and mileage progression calculations.',
    ISNULL(Odometer, ''),
    'Backfill only from a trusted fuel-card or vehicle telemetry source. Otherwise exclude from odometer-based calculations.'
FROM raw.fuel_transactions_raw
WHERE TRIM(ISNULL(Odometer, '')) = ''
    AND NOT (
        TRIM(ISNULL(fuel_txn_id, '')) = ''
    AND TRIM(ISNULL(transaction_date, '')) = ''
    AND TRIM(ISNULL([Asset No], '')) = ''
    AND TRIM(ISNULL(Registration, '')) = ''
    );

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
    WHERE TRIM(ISNULL([Asset No], '')) <> ''
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
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.fuel_transactions_raw',
    fuel_txn_id,
    'Backward odometer reading',
    'Sequence Validation',
    'Medium',
    'Odometer reading is lower than the previous odometer reading for the same asset.',
    CONCAT('Previous: ', previous_odometer, '; Current: ', odometer_num),
    'Review transaction ordering, vehicle assignment, odometer entry, or unit mismatch before using for mileage progression.'
FROM ordered_fuel
WHERE previous_odometer IS NOT NULL
    AND odometer_num < previous_odometer;

-- Condition assessment exceptions
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.fleet_condition_assessment_raw',
    c.assessment_id,
    'Orphan condition vehicle_id',
    'Referential Integrity',
    'High',
    'Condition assessment vehicle_id does not match vehicle master.',
    c.vehicle_id,
    'Attempt registration match. If no confident match exists, quarantine for review.'
FROM raw.fleet_condition_assessment_raw c
LEFT JOIN raw.vehicle_master_raw v
    ON TRIM(c.vehicle_id) = TRIM(v.vehicle_id)
WHERE TRIM(ISNULL(c.vehicle_id, '')) <> ''
    AND v.vehicle_id IS NULL;

WITH mileage_parse AS (
    SELECT
        assessment_id,
        Mileage,
        Odometer_Reading,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(Mileage), '')) AS mileage_num,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(Odometer_Reading), '')) AS odometer_num
    FROM raw.fleet_condition_assessment_raw
)
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.fleet_condition_assessment_raw',
    assessment_id,
    'Mileage and odometer disagreement',
    'Cross-field Consistency',
    'Medium',
    'Mileage and Odometer_Reading differ by more than 5,000 units.',
    CONCAT('Mileage: ', Mileage, '; Odometer_Reading: ', Odometer_Reading),
    'Confirm whether these fields represent the same measurement or different concepts.'
FROM mileage_parse
WHERE mileage_num IS NOT NULL
    AND odometer_num IS NOT NULL
    AND ABS(mileage_num - odometer_num) > 5000;

INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.fleet_condition_assessment_raw',
    assessment_id,
    'Missing condition vehicle_id',
    'Completeness',
    'High',
    'Condition assessment is missing vehicle_id.',
    ISNULL(vehicle_id, ''),
    'Attempt to backfill from registration_no if it uniquely matches vehicle master.'
FROM raw.fleet_condition_assessment_raw
WHERE TRIM(ISNULL(vehicle_id, '')) = '';

WITH parsed_dates AS (
    SELECT
        assessment_id,
        assessment_date,
        Last_Service_Date,
        COALESCE(
            TRY_CONVERT(date, assessment_date, 23),
            TRY_CONVERT(date, assessment_date, 101),
            TRY_CONVERT(date, assessment_date)
        ) AS assessment_dt,
        COALESCE(
            TRY_CONVERT(date, Last_Service_Date, 23),
            TRY_CONVERT(date, Last_Service_Date, 101),
            TRY_CONVERT(date, Last_Service_Date)
        ) AS last_service_dt
    FROM raw.fleet_condition_assessment_raw
)
INSERT INTO dq.data_quality_exceptions (
    source_table,
    source_record_id,
    issue_type,
    issue_category,
    severity,
    issue_description,
    raw_value,
    suggested_action
)
SELECT
    'raw.fleet_condition_assessment_raw',
    assessment_id,
    'Last service date after assessment date',
    'Date Logic',
    'High',
    'Last_Service_Date occurs after assessment_date.',
    CONCAT('Assessment: ', assessment_date, '; Last Service: ', Last_Service_Date),
    'Exclude from service-recency calculations until source date is corrected.'
FROM parsed_dates
WHERE assessment_dt IS NOT NULL
    AND last_service_dt IS NOT NULL
    AND last_service_dt > assessment_dt;

-- Validate the exceptions table
SELECT
    source_table,
    issue_type,
    severity,
    COUNT(*) AS exception_count
FROM dq.data_quality_exceptions
GROUP BY source_table, issue_type, severity
ORDER BY source_table, exception_count DESC;

SELECT
    severity,
    COUNT(*) AS exception_count
FROM dq.data_quality_exceptions
GROUP BY severity
ORDER BY
    CASE severity
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
        ELSE 4
    END;
USE DataIntegrityAutomationPrototype;
GO
IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'clean'
)
BEGIN
    EXEC('CREATE SCHEMA clean');
END;
GO

-- Clean Maintenance Work Orders View
CREATE OR ALTER VIEW clean.vw_maintenance_work_orders AS

WITH maintenance_base AS (
    SELECT
        m.*,

        NULLIF(TRIM(m.UNIQUE_WORK_ORDER_NO), '') AS work_order_key,
        NULLIF(TRIM(m.EQ_EQUIP_NO), '') AS equipment_no_clean,
        NULLIF(TRIM(m.vendor_id), '') AS vendor_id_clean_raw,

        UPPER(
            REPLACE(
                REPLACE(
                    REPLACE(TRIM(ISNULL(m.vendor_name, '')), '''', ''),
                '.', ''),
            '&', 'AND')
        ) AS normalized_work_order_vendor_name,

        COALESCE(
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.CREATE_DATE), ''), 120),
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.CREATE_DATE), ''), 101),
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.CREATE_DATE), ''))
        ) AS create_datetime_clean,

        COALESCE(
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.DATETIME_OPEN), ''), 120),
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.DATETIME_OPEN), ''), 101),
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.DATETIME_OPEN), ''))
        ) AS open_datetime_clean,

        COALESCE(
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.DATETIME_CLOSED), ''), 120),
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.DATETIME_CLOSED), ''), 101),
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.DATETIME_CLOSED), ''))
        ) AS closed_datetime_clean,

        COALESCE(
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.DATETIME_FINISHED), ''), 120),
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.DATETIME_FINISHED), ''), 101),
            TRY_CONVERT(datetime2, NULLIF(TRIM(m.DATETIME_FINISHED), ''))
        ) AS finished_datetime_clean,

        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(m.LABOR_HOURS), '')) AS labor_hours_num,

        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(m.LABOR_COST), ''), '$', ''), ',', '')) AS labor_cost_num,
        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(m.PARTS_COST), ''), '$', ''), ',', '')) AS parts_cost_num,
        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(m.COMML_COST), ''), '$', ''), ',', '')) AS commercial_cost_num,
        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(m.TOTAL_COST), ''), '$', ''), ',', '')) AS source_total_cost_num,

        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(m.METER_1_READING), '')) AS meter_1_reading_num,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(m.DOWNTIME_HRS_USER), '')) AS downtime_hours_user_num,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(m.DOWNTIME_HRS_SHOP), '')) AS downtime_hours_shop_num
    FROM raw.maintenance_work_orders_raw m
),

maintenance_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY work_order_key
            ORDER BY create_datetime_clean, WORK_ORDER_NO
        ) AS work_order_duplicate_rank
    FROM maintenance_base
),

maintenance_standardized AS (
    SELECT
        mr.*,

        CASE
            WHEN UPPER(TRIM(JOB_TYPE)) IN ('PM', 'PREVENTATIVE MAINTENANCE', 'PREVENTIVE MAINT') THEN 'PREVENTIVE_MAINTENANCE'
            WHEN UPPER(TRIM(JOB_TYPE)) IN ('REPAIR', 'CORRECTIVE') THEN 'REPAIR'
            WHEN TRIM(ISNULL(JOB_TYPE, '')) = '' THEN 'UNKNOWN'
            ELSE 'OTHER'
        END AS standardized_job_type,

        CASE
            WHEN UPPER(TRIM(WORK_ORDER_STATUS)) IN ('CLOSED', 'FINISHED') THEN 'CLOSED'
            WHEN UPPER(TRIM(WORK_ORDER_STATUS)) = 'OPEN' THEN 'OPEN'
            WHEN UPPER(TRIM(WORK_ORDER_STATUS)) = 'IN PROGRESS' THEN 'IN_PROGRESS'
            WHEN UPPER(TRIM(WORK_ORDER_STATUS)) = 'CANCELLED' THEN 'CANCELLED'
            WHEN TRIM(ISNULL(WORK_ORDER_STATUS, '')) = '' THEN 'UNKNOWN'
            ELSE 'OTHER'
        END AS standardized_work_order_status,

        CASE
            WHEN UPPER(TRIM(WARRANTY)) IN ('Y', 'YES', 'TRUE') THEN 1
            WHEN UPPER(TRIM(WARRANTY)) IN ('N', 'NO', 'FALSE') THEN 0
            ELSE NULL
        END AS warranty_flag_clean,

        CASE
            WHEN labor_cost_num IS NOT NULL
            AND parts_cost_num IS NOT NULL
            AND commercial_cost_num IS NOT NULL
            THEN labor_cost_num + parts_cost_num + commercial_cost_num
            ELSE NULL
        END AS calculated_total_cost,

        CASE
            WHEN open_datetime_clean IS NOT NULL
            AND closed_datetime_clean IS NOT NULL
            AND closed_datetime_clean >= open_datetime_clean
            THEN DATEDIFF(hour, open_datetime_clean, closed_datetime_clean)
            ELSE NULL
        END AS cycle_time_hours
    FROM maintenance_ranked mr
)

SELECT
    ms.work_order_key,
    ms.UNIQUE_WORK_ORDER_NO AS source_unique_work_order_no,
    ms.equipment_no_clean,
    vm.clean_vehicle_key,
    CASE
        WHEN ms.equipment_no_clean IS NULL THEN 'MISSING_EQUIPMENT_NO'
        WHEN vm.clean_vehicle_key IS NULL THEN 'ORPHAN_EQUIPMENT_NO'
        ELSE 'MATCHED'
    END AS vehicle_match_status,

    ms.vendor_id_clean_raw,
    ms.vendor_name AS source_vendor_name,
    vmv.clean_vendor_key,
    CASE
        WHEN ms.vendor_id_clean_raw IS NULL AND TRIM(ISNULL(ms.vendor_name, '')) = '' THEN 'MISSING_VENDOR_REFERENCE'
        WHEN vmv.clean_vendor_key IS NULL THEN 'UNMATCHED_VENDOR'
        ELSE 'MATCHED'
    END AS vendor_match_status,

    ms.standardized_job_type,
    ms.standardized_work_order_status,
    ms.warranty_flag_clean,

    ms.create_datetime_clean,
    ms.open_datetime_clean,
    ms.finished_datetime_clean,
    ms.closed_datetime_clean,
    ms.cycle_time_hours,

    ms.meter_1_reading_num,
    ms.downtime_hours_user_num,
    ms.downtime_hours_shop_num,

    ms.labor_hours_num,
    ms.labor_cost_num,
    ms.parts_cost_num,
    ms.commercial_cost_num,
    ms.source_total_cost_num,
    ms.calculated_total_cost,

    CASE
        WHEN ms.source_total_cost_num IS NULL THEN 'SOURCE_TOTAL_MISSING_OR_INVALID'
        WHEN ms.calculated_total_cost IS NULL THEN 'COMPONENT_COST_MISSING_OR_INVALID'
        WHEN ABS(ms.source_total_cost_num - ms.calculated_total_cost) > 1 THEN 'TOTAL_COST_MISMATCH'
        ELSE 'OK'
    END AS cost_reconciliation_status,

    CASE WHEN ms.work_order_duplicate_rank > 1 THEN 1 ELSE 0 END AS duplicate_work_order_flag,
    CASE WHEN ms.equipment_no_clean IS NULL THEN 1 ELSE 0 END AS missing_equipment_no_flag,
    CASE WHEN vm.clean_vehicle_key IS NULL AND ms.equipment_no_clean IS NOT NULL THEN 1 ELSE 0 END AS orphan_equipment_no_flag,
    CASE WHEN ms.closed_datetime_clean < ms.open_datetime_clean THEN 1 ELSE 0 END AS closed_before_open_flag,
    CASE WHEN ms.labor_cost_num < 0 THEN 1 ELSE 0 END AS negative_labor_cost_flag,
    CASE
        WHEN ms.source_total_cost_num IS NOT NULL
        AND ms.calculated_total_cost IS NOT NULL
        AND ABS(ms.source_total_cost_num - ms.calculated_total_cost) > 1
        THEN 1 ELSE 0
    END AS total_cost_mismatch_flag,

    CASE
        WHEN ms.work_order_duplicate_rank > 1 THEN 'REVIEW_REQUIRED'
        WHEN ms.equipment_no_clean IS NULL THEN 'REVIEW_REQUIRED'
        WHEN vm.clean_vehicle_key IS NULL THEN 'REVIEW_REQUIRED'
        WHEN ms.closed_datetime_clean < ms.open_datetime_clean THEN 'REVIEW_REQUIRED'
        WHEN ms.labor_cost_num < 0 THEN 'REVIEW_REQUIRED'
        WHEN ms.source_total_cost_num IS NOT NULL
        AND ms.calculated_total_cost IS NOT NULL
        AND ABS(ms.source_total_cost_num - ms.calculated_total_cost) > 1 THEN 'USABLE_WITH_WARNING'
        ELSE 'OK'
    END AS clean_record_status,

    CASE
        WHEN ms.work_order_duplicate_rank = 1
        AND vm.clean_vehicle_key IS NOT NULL
        THEN 1 ELSE 0
    END AS include_in_asset_level_reporting_flag,

    ms.source_system

FROM maintenance_standardized ms

LEFT JOIN clean.vw_vehicle_master vm
    ON ms.equipment_no_clean = vm.asset_no_clean

OUTER APPLY (
    SELECT TOP 1
        v.clean_vendor_key
    FROM clean.vw_vendor_master v
    WHERE
        ms.vendor_id_clean_raw = v.source_vendor_id
        OR (
            ms.vendor_id_clean_raw IS NULL
            AND ms.normalized_work_order_vendor_name = v.normalized_vendor_name
        )
    ORDER BY
        CASE WHEN ms.vendor_id_clean_raw = v.source_vendor_id THEN 1 ELSE 2 END,
        CASE v.clean_record_status
            WHEN 'OK' THEN 1
            WHEN 'USABLE_WITH_WARNING' THEN 2
            ELSE 3
        END
) vmv;
GO

-- Clean Fuel Transactions View
CREATE OR ALTER VIEW clean.vw_fuel_transactions AS

WITH fuel_base AS (
    SELECT
        f.*,

        NULLIF(TRIM(f.fuel_txn_id), '') AS fuel_txn_id_clean_raw,
        UPPER(NULLIF(TRIM(f.Registration), '')) AS registration_clean,
        NULLIF(TRIM(f.[Asset No]), '') AS asset_no_clean_raw,

        COALESCE(
            TRY_CONVERT(datetime2, NULLIF(TRIM(f.transaction_date), ''), 120),
            TRY_CONVERT(datetime2, NULLIF(TRIM(f.transaction_date), ''), 101),
            TRY_CONVERT(datetime2, NULLIF(TRIM(f.transaction_date), ''))
        ) AS transaction_datetime_clean,

        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(f.Odometer), '')) AS odometer_num,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(f.Distance), '')) AS distance_num,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(f.Fuel_Qty), '')) AS fuel_qty_num,
        TRY_CONVERT(decimal(18,2), REPLACE(REPLACE(NULLIF(TRIM(f.Fuel_Cost), ''), '$', ''), ',', '')) AS fuel_cost_num,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(f.MPG), '')) AS source_mpg_num,

        CASE
            WHEN TRIM(ISNULL(f.fuel_txn_id, '')) = ''
            AND TRIM(ISNULL(f.transaction_date, '')) = ''
            AND TRIM(ISNULL(f.[Asset No], '')) = ''
            AND TRIM(ISNULL(f.Registration, '')) = ''
            THEN 1 ELSE 0
        END AS likely_blank_row_flag
    FROM raw.fuel_transactions_raw f
),

fuel_standardized AS (
    SELECT
        *,

        COALESCE(
            fuel_txn_id_clean_raw,
            CONCAT('DERIVED_FUEL_TXN_', ABS(CHECKSUM(CONCAT(transaction_date, '|', [Asset No], '|', Registration, '|', Odometer, '|', Fuel_Qty))))
        ) AS clean_fuel_txn_key,

        CASE
            WHEN UPPER(TRIM(Unit)) IN ('MILES', 'MILE') THEN 'MILES'
            WHEN UPPER(TRIM(Unit)) IN ('KM', 'KILOMETERS', 'KILOMETER') THEN 'KILOMETERS'
            WHEN TRIM(ISNULL(Unit, '')) = '' THEN 'UNKNOWN'
            ELSE 'UNKNOWN'
        END AS standardized_distance_unit,

        CASE
            WHEN UPPER(TRIM(Qty_UOM)) IN ('GALLONS', 'GAL') THEN 'GALLONS'
            WHEN UPPER(TRIM(Qty_UOM)) IN ('LITERS', 'L') THEN 'LITERS'
            WHEN TRIM(ISNULL(Qty_UOM, '')) = '' THEN 'UNKNOWN'
            ELSE 'UNKNOWN'
        END AS standardized_quantity_unit,

        CASE
            WHEN UPPER(TRIM(Product)) IN ('DIESEL', 'DSL') THEN 'DIESEL'
            WHEN UPPER(TRIM(Product)) IN ('GASOLINE', 'GAS', 'UNLEADED', 'PETROL') THEN 'GASOLINE'
            WHEN UPPER(TRIM(Product)) IN ('ELECTRIC', 'EV') THEN 'ELECTRIC'
            WHEN UPPER(TRIM(Product)) LIKE '%HYBRID%' THEN 'HYBRID'
            WHEN TRIM(ISNULL(Product, '')) = '' THEN 'UNKNOWN'
            ELSE 'UNKNOWN'
        END AS standardized_fuel_product,

        CASE
            WHEN UPPER(TRIM(Unit)) IN ('MILES', 'MILE') THEN distance_num
            WHEN UPPER(TRIM(Unit)) IN ('KM', 'KILOMETERS', 'KILOMETER') THEN distance_num / 1.609344
            ELSE NULL
        END AS distance_miles,

        CASE
            WHEN UPPER(TRIM(Qty_UOM)) IN ('GALLONS', 'GAL') THEN fuel_qty_num
            WHEN UPPER(TRIM(Qty_UOM)) IN ('LITERS', 'L') THEN fuel_qty_num / 3.78541
            ELSE NULL
        END AS fuel_qty_gallons
    FROM fuel_base
),

fuel_with_vehicle AS (
    SELECT
        fs.*,
        vm.clean_vehicle_key,
        vm.asset_no_clean AS matched_asset_no,
        vm.registration_no_clean AS matched_registration_no,
        vm.standardized_fuel_type AS vehicle_master_fuel_type,

        CASE
            WHEN fs.likely_blank_row_flag = 1 THEN 'BLANK_ROW'
            WHEN fs.asset_no_clean_raw IS NOT NULL AND vm.asset_no_clean = fs.asset_no_clean_raw THEN 'MATCHED_BY_ASSET_NO'
            WHEN fs.registration_clean IS NOT NULL AND vm.registration_no_clean = fs.registration_clean THEN 'MATCHED_BY_REGISTRATION'
            WHEN fs.asset_no_clean_raw IS NULL THEN 'MISSING_ASSET_NO'
            ELSE 'ORPHAN_ASSET_NO'
        END AS vehicle_match_status
    FROM fuel_standardized fs

    OUTER APPLY (
        SELECT TOP 1
            v.clean_vehicle_key,
            v.asset_no_clean,
            v.registration_no_clean,
            v.standardized_fuel_type,
            v.clean_record_status
        FROM clean.vw_vehicle_master v
        WHERE
            (
                fs.asset_no_clean_raw IS NOT NULL
                AND fs.asset_no_clean_raw = v.asset_no_clean
            )
            OR (
                fs.registration_clean IS NOT NULL
                AND fs.registration_clean = v.registration_no_clean
            )
        ORDER BY
            CASE WHEN fs.asset_no_clean_raw = v.asset_no_clean THEN 1 ELSE 2 END,
            CASE v.clean_record_status
                WHEN 'OK' THEN 1
                WHEN 'USABLE_WITH_WARNING' THEN 2
                ELSE 3
            END
    ) vm
),

fuel_with_sequence AS (
    SELECT
        *,
        LAG(odometer_num) OVER (
            PARTITION BY COALESCE(clean_vehicle_key, asset_no_clean_raw)
            ORDER BY transaction_datetime_clean, clean_fuel_txn_key
        ) AS previous_odometer_num
    FROM fuel_with_vehicle
    WHERE likely_blank_row_flag = 0
)

SELECT
    clean_fuel_txn_key,
    fuel_txn_id_clean_raw AS source_fuel_txn_id,
    transaction_datetime_clean,

    asset_no_clean_raw AS source_asset_no,
    registration_clean AS source_registration,
    clean_vehicle_key,
    vehicle_match_status,

    Details AS source_vehicle_details,

    Product AS source_product,
    standardized_fuel_product,
    vehicle_master_fuel_type,

    supplier_name,
    fuel_card_id,

    odometer_num,
    previous_odometer_num,
    CASE
        WHEN previous_odometer_num IS NOT NULL
        AND odometer_num IS NOT NULL
        AND odometer_num < previous_odometer_num
        THEN 1 ELSE 0
    END AS backward_odometer_flag,

    Distance AS source_distance,
    Unit AS source_distance_unit,
    standardized_distance_unit,
    distance_miles,

    Fuel_Qty AS source_fuel_qty,
    Qty_UOM AS source_quantity_unit,
    standardized_quantity_unit,
    fuel_qty_gallons,

    fuel_cost_num,
    source_mpg_num,

    CASE
        WHEN standardized_fuel_product = 'ELECTRIC' THEN NULL
        WHEN distance_miles IS NOT NULL
        AND fuel_qty_gallons IS NOT NULL
        AND fuel_qty_gallons > 0
        THEN distance_miles / fuel_qty_gallons
        ELSE NULL
    END AS recalculated_mpg,

    CASE
        WHEN source_mpg_num IS NULL THEN 1
        WHEN source_mpg_num = 0 THEN 1
        WHEN source_mpg_num > 90 THEN 1
        WHEN source_mpg_num > 0 AND source_mpg_num < 2 THEN 1
        ELSE 0
    END AS suspicious_source_mpg_flag,

    likely_blank_row_flag,
    CASE WHEN fuel_txn_id_clean_raw IS NULL AND likely_blank_row_flag = 0 THEN 1 ELSE 0 END AS missing_fuel_txn_id_flag,
    CASE WHEN asset_no_clean_raw IS NULL AND likely_blank_row_flag = 0 THEN 1 ELSE 0 END AS missing_asset_no_flag,
    CASE WHEN odometer_num IS NULL AND likely_blank_row_flag = 0 THEN 1 ELSE 0 END AS missing_odometer_flag,

    CASE
        WHEN likely_blank_row_flag = 1 THEN 'EXCLUDE'
        WHEN clean_vehicle_key IS NULL THEN 'REVIEW_REQUIRED'
        WHEN odometer_num IS NULL THEN 'USABLE_WITH_WARNING'
        WHEN source_mpg_num IS NULL OR source_mpg_num = 0 OR source_mpg_num > 90 OR (source_mpg_num > 0 AND source_mpg_num < 2) THEN 'USABLE_WITH_WARNING'
        WHEN previous_odometer_num IS NOT NULL AND odometer_num < previous_odometer_num THEN 'USABLE_WITH_WARNING'
        ELSE 'OK'
    END AS clean_record_status,

    CASE
        WHEN likely_blank_row_flag = 0
        AND clean_vehicle_key IS NOT NULL
        THEN 1 ELSE 0
    END AS include_in_vehicle_level_reporting_flag,

    driver_department,
    source_file_name

FROM fuel_with_sequence;
GO

-- Clean Fleet Condition Assessment View
CREATE OR ALTER VIEW clean.vw_fleet_condition_assessments AS

WITH condition_base AS (
    SELECT
        c.*,

        NULLIF(TRIM(c.assessment_id), '') AS assessment_id_clean,
        NULLIF(TRIM(c.vehicle_id), '') AS vehicle_id_clean_raw,
        UPPER(NULLIF(TRIM(c.registration_no), '')) AS registration_no_clean,

        COALESCE(
            TRY_CONVERT(date, NULLIF(TRIM(c.assessment_date), ''), 23),
            TRY_CONVERT(date, NULLIF(TRIM(c.assessment_date), ''), 101),
            TRY_CONVERT(date, NULLIF(TRIM(c.assessment_date), ''))
        ) AS assessment_date_clean,

        COALESCE(
            TRY_CONVERT(date, NULLIF(TRIM(c.Last_Service_Date), ''), 23),
            TRY_CONVERT(date, NULLIF(TRIM(c.Last_Service_Date), ''), 101),
            TRY_CONVERT(date, NULLIF(TRIM(c.Last_Service_Date), ''))
        ) AS last_service_date_clean,

        COALESCE(
            TRY_CONVERT(date, NULLIF(TRIM(c.Warranty_Expiry_Date), ''), 23),
            TRY_CONVERT(date, NULLIF(TRIM(c.Warranty_Expiry_Date), ''), 101),
            TRY_CONVERT(date, NULLIF(TRIM(c.Warranty_Expiry_Date), ''))
        ) AS warranty_expiry_date_clean,

        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(c.Mileage), '')) AS mileage_num,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(c.Odometer_Reading), '')) AS odometer_reading_num,
        TRY_CONVERT(int, NULLIF(TRIM(c.Vehicle_Age), '')) AS vehicle_age_num,
        TRY_CONVERT(int, NULLIF(TRIM(c.Reported_Issues), '')) AS reported_issues_num,
        TRY_CONVERT(decimal(18,2), NULLIF(TRIM(c.Fuel_Efficiency), '')) AS fuel_efficiency_num,
        TRY_CONVERT(int, NULLIF(TRIM(c.Need_Maintenance), '')) AS need_maintenance_flag
    FROM raw.fleet_condition_assessment_raw c
),

condition_standardized AS (
    SELECT
        *,

        CASE
            WHEN UPPER(TRIM(Fuel_Type)) IN ('DIESEL', 'DSL') THEN 'DIESEL'
            WHEN UPPER(TRIM(Fuel_Type)) IN ('GASOLINE', 'GAS', 'UNLEADED', 'PETROL') THEN 'GASOLINE'
            WHEN UPPER(TRIM(Fuel_Type)) IN ('ELECTRIC', 'EV') THEN 'ELECTRIC'
            WHEN UPPER(TRIM(Fuel_Type)) LIKE '%HYBRID%' THEN 'HYBRID'
            WHEN TRIM(ISNULL(Fuel_Type, '')) = '' THEN 'UNKNOWN'
            ELSE 'UNKNOWN'
        END AS standardized_condition_fuel_type,

        CASE
            WHEN UPPER(TRIM(Transmission_Type)) IN ('AUTO', 'AUTOMATIC') THEN 'AUTOMATIC'
            WHEN UPPER(TRIM(Transmission_Type)) = 'MANUAL' THEN 'MANUAL'
            WHEN UPPER(TRIM(Transmission_Type)) = 'CVT' THEN 'CVT'
            WHEN TRIM(ISNULL(Transmission_Type, '')) = '' THEN 'UNKNOWN'
            ELSE 'UNKNOWN'
        END AS standardized_transmission_type,

        CASE
            WHEN UPPER(TRIM(Tire_Condition)) IN ('GOOD', 'NEW') THEN 'GOOD'
            WHEN UPPER(TRIM(Tire_Condition)) IN ('WORN', 'WORN OUT', 'POOR') THEN 'NEEDS_REVIEW'
            ELSE 'UNKNOWN'
        END AS standardized_tire_condition,

        CASE
            WHEN UPPER(TRIM(Brake_Condition)) IN ('GOOD', 'NEW') THEN 'GOOD'
            WHEN UPPER(TRIM(Brake_Condition)) IN ('WORN', 'NEEDS SERVICE', 'POOR') THEN 'NEEDS_REVIEW'
            ELSE 'UNKNOWN'
        END AS standardized_brake_condition,

        CASE
            WHEN UPPER(TRIM(Battery_Status)) IN ('GOOD', 'NEW') THEN 'GOOD'
            WHEN UPPER(TRIM(Battery_Status)) IN ('WEAK', 'REPLACE') THEN 'NEEDS_REVIEW'
            ELSE 'UNKNOWN'
        END AS standardized_battery_status
    FROM condition_base
),

condition_with_vehicle AS (
    SELECT
        cs.*,
        vm.clean_vehicle_key,
        vm.vehicle_id_clean AS matched_vehicle_id,
        vm.registration_no_clean AS matched_registration_no,
        vm.standardized_fuel_type AS vehicle_master_fuel_type,

        CASE
            WHEN cs.vehicle_id_clean_raw IS NOT NULL AND cs.vehicle_id_clean_raw = vm.vehicle_id_clean THEN 'MATCHED_BY_VEHICLE_ID'
            WHEN cs.registration_no_clean IS NOT NULL AND cs.registration_no_clean = vm.registration_no_clean THEN 'MATCHED_BY_REGISTRATION'
            WHEN cs.vehicle_id_clean_raw IS NULL THEN 'MISSING_VEHICLE_ID'
            ELSE 'ORPHAN_VEHICLE_ID'
        END AS vehicle_match_status
    FROM condition_standardized cs

    OUTER APPLY (
        SELECT TOP 1
            v.clean_vehicle_key,
            v.vehicle_id_clean,
            v.registration_no_clean,
            v.standardized_fuel_type,
            v.clean_record_status
        FROM clean.vw_vehicle_master v
        WHERE
            (
                cs.vehicle_id_clean_raw IS NOT NULL
                AND cs.vehicle_id_clean_raw = v.vehicle_id_clean
            )
            OR (
                cs.registration_no_clean IS NOT NULL
                AND cs.registration_no_clean = v.registration_no_clean
            )
        ORDER BY
            CASE WHEN cs.vehicle_id_clean_raw = v.vehicle_id_clean THEN 1 ELSE 2 END,
            CASE v.clean_record_status
                WHEN 'OK' THEN 1
                WHEN 'USABLE_WITH_WARNING' THEN 2
                ELSE 3
            END
    ) vm
)

SELECT
    assessment_id_clean,
    assessment_date_clean,

    vehicle_id_clean_raw AS source_vehicle_id,
    registration_no_clean AS source_registration_no,
    clean_vehicle_key,
    vehicle_match_status,

    Vehicle_Model AS source_vehicle_model,
    vehicle_age_num,

    Mileage AS source_mileage,
    Odometer_Reading AS source_odometer_reading,
    mileage_num,
    odometer_reading_num,

    CASE
        WHEN mileage_num IS NOT NULL
        AND odometer_reading_num IS NOT NULL
        THEN ABS(mileage_num - odometer_reading_num)
        ELSE NULL
    END AS mileage_odometer_difference,

    CASE
        WHEN mileage_num IS NOT NULL
        AND odometer_reading_num IS NOT NULL
        AND ABS(mileage_num - odometer_reading_num) > 5000
        THEN 1 ELSE 0
    END AS mileage_odometer_disagreement_flag,

    Fuel_Type AS source_fuel_type,
    standardized_condition_fuel_type,
    vehicle_master_fuel_type,

    CASE
        WHEN vehicle_master_fuel_type IS NOT NULL
        AND standardized_condition_fuel_type <> 'UNKNOWN'
        AND vehicle_master_fuel_type <> standardized_condition_fuel_type
        THEN 1 ELSE 0
    END AS fuel_type_conflict_flag,

    Transmission_Type AS source_transmission_type,
    standardized_transmission_type,

    Engine_Size AS source_engine_size,

    last_service_date_clean,
    warranty_expiry_date_clean,

    CASE
        WHEN last_service_date_clean IS NOT NULL
        AND assessment_date_clean IS NOT NULL
        AND last_service_date_clean > assessment_date_clean
        THEN 1 ELSE 0
    END AS last_service_after_assessment_flag,

    Maintenance_History,
    reported_issues_num,
    Owner_Type,
    Insurance_Premium,
    Service_History,
    Accident_History,
    fuel_efficiency_num,

    Tire_Condition AS source_tire_condition,
    standardized_tire_condition,

    Brake_Condition AS source_brake_condition,
    standardized_brake_condition,

    Battery_Status AS source_battery_status,
    standardized_battery_status,

    need_maintenance_flag,

    CASE
        WHEN vehicle_id_clean_raw IS NULL THEN 'REVIEW_REQUIRED'
        WHEN clean_vehicle_key IS NULL THEN 'REVIEW_REQUIRED'
        WHEN last_service_date_clean > assessment_date_clean THEN 'REVIEW_REQUIRED'
        WHEN mileage_num IS NOT NULL
        AND odometer_reading_num IS NOT NULL
        AND ABS(mileage_num - odometer_reading_num) > 5000 THEN 'USABLE_WITH_WARNING'
        WHEN vehicle_master_fuel_type IS NOT NULL
        AND standardized_condition_fuel_type <> 'UNKNOWN'
        AND vehicle_master_fuel_type <> standardized_condition_fuel_type THEN 'USABLE_WITH_WARNING'
        ELSE 'OK'
    END AS clean_record_status,

    CASE
        WHEN clean_vehicle_key IS NOT NULL THEN 1 ELSE 0
    END AS include_in_vehicle_level_reporting_flag,

    source_system

FROM condition_with_vehicle;
GO

-- Validation Queries
SELECT
    'clean.vw_maintenance_work_orders' AS view_name,
    COUNT(*) AS row_count
FROM clean.vw_maintenance_work_orders

UNION ALL

SELECT
    'clean.vw_fuel_transactions',
    COUNT(*)
FROM clean.vw_fuel_transactions

UNION ALL

SELECT
    'clean.vw_fleet_condition_assessments',
    COUNT(*)
FROM clean.vw_fleet_condition_assessments;
GO

SELECT
    clean_record_status,
    COUNT(*) AS record_count
FROM clean.vw_maintenance_work_orders
GROUP BY clean_record_status
ORDER BY record_count DESC;
GO

SELECT
    clean_record_status,
    COUNT(*) AS record_count
FROM clean.vw_fuel_transactions
GROUP BY clean_record_status
ORDER BY record_count DESC;
GO

SELECT
    vehicle_match_status,
    COUNT(*) AS record_count
FROM clean.vw_maintenance_work_orders
GROUP BY vehicle_match_status
ORDER BY record_count DESC;
GO

SELECT
    vehicle_match_status,
    COUNT(*) AS record_count
FROM clean.vw_fuel_transactions
GROUP BY vehicle_match_status
ORDER BY record_count DESC;
GO

SELECT
    vehicle_match_status,
    COUNT(*) AS record_count
FROM clean.vw_fleet_condition_assessments
GROUP BY vehicle_match_status
ORDER BY record_count DESC;
GO
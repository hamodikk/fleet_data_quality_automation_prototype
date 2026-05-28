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

-- Clean vehicle master view
CREATE OR ALTER VIEW clean.vw_vehicle_master AS

WITH vehicle_base AS (
    SELECT
        asset_no,
        vehicle_id,
        vin,
        registration_no,
        license_plate_state,
        make,
        model,
        model_year,
        vehicle_type,
        department_code,
        department_name,
        fleet_group,
        fuel_type,
        engine_size,
        transmission_type,
        acquisition_date,
        in_service_date,
        warranty_expiry_date,
        current_status,
        current_odometer,
        parent_asset_no,
        assigned_location_code,
        assigned_location_name,
        source_system,
        last_updated_date,

        NULLIF(TRIM(asset_no), '') AS asset_no_clean,
        NULLIF(TRIM(vehicle_id), '') AS vehicle_id_clean_raw,
        NULLIF(TRIM(vin), '') AS vin_clean_raw,
        UPPER(NULLIF(TRIM(registration_no), '')) AS registration_no_clean,

        TRY_CONVERT(INT, NULLIF(TRIM(model_year), '')) AS model_year_num,
        TRY_CONVERT(INT, NULLIF(TRIM(current_odometer), '')) AS current_odometer_num,

        COALESCE(
            TRY_CONVERT(DATE, NULLIF(TRIM(acquisition_date), ''), 23),
            TRY_CONVERT(DATE, NULLIF(TRIM(acquisition_date), ''), 101),
            TRY_CONVERT(DATE, NULLIF(TRIM(acquisition_date), ''))
        ) AS acquisition_date_clean,

        COALESCE(
            TRY_CONVERT(DATE, NULLIF(TRIM(in_service_date), ''), 23),
            TRY_CONVERT(DATE, NULLIF(TRIM(in_service_date), ''), 101),
            TRY_CONVERT(DATE, NULLIF(TRIM(in_service_date), ''))
        ) AS in_service_date_clean,

        COALESCE(
            TRY_CONVERT(DATE, NULLIF(TRIM(warranty_expiry_date), ''), 23),
            TRY_CONVERT(DATE, NULLIF(TRIM(warranty_expiry_date), ''), 101),
            TRY_CONVERT(DATE, NULLIF(TRIM(warranty_expiry_date), ''))
        ) AS warranty_expiry_date_clean,

        COALESCE(
            TRY_CONVERT(DATE, NULLIF(TRIM(last_updated_date), ''), 23),
            TRY_CONVERT(DATE, NULLIF(TRIM(last_updated_date), ''), 101),
            TRY_CONVERT(DATE, NULLIF(TRIM(last_updated_date), ''))
        ) AS last_updated_date_clean
    FROM raw.vehicle_master_raw
),

vehicle_standardized AS (
    SELECT
        *,

        -- Main clean key: asset_no is complete and unique in the raw profile.
        asset_no_clean AS clean_vehicle_key,

        -- Preserve the raw missing vehicle_id issue, but create a usable reporting ID.
        COALESCE(vehicle_id_clean_raw, CONCAT('DERIVED_FROM_ASSET_', asset_no_clean)) AS vehicle_id_clean,

        UPPER(vin_clean_raw) AS vin_clean,

        CASE
            WHEN UPPER(TRIM(fuel_type)) IN ('DIESEL', 'DSL') THEN 'DIESEL'
            WHEN UPPER(TRIM(fuel_type)) IN ('GASOLINE', 'GAS', 'UNLEADED', 'PETROL') THEN 'GASOLINE'
            WHEN UPPER(TRIM(fuel_type)) IN ('ELECTRIC', 'EV') THEN 'ELECTRIC'
            WHEN UPPER(TRIM(fuel_type)) LIKE '%HYBRID%' THEN 'HYBRID'
            WHEN TRIM(ISNULL(fuel_type, '')) = '' THEN 'UNKNOWN'
            ELSE 'UNKNOWN'
        END AS standardized_fuel_type,

        CASE
            WHEN UPPER(TRIM(current_status)) IN ('ACTIVE', 'IN SERVICE', 'AVAILABLE') THEN 'ACTIVE'
            WHEN UPPER(TRIM(current_status)) = 'OUT OF SERVICE' THEN 'OUT_OF_SERVICE'
            WHEN UPPER(TRIM(current_status)) = 'INACTIVE' THEN 'INACTIVE'
            WHEN UPPER(TRIM(current_status)) = 'RETIRED' THEN 'RETIRED'
            WHEN TRIM(ISNULL(current_status, '')) = '' THEN 'UNKNOWN'
            ELSE 'UNKNOWN'
        END AS standardized_vehicle_status,

        CASE
            WHEN UPPER(TRIM(transmission_type)) IN ('AUTO', 'AUTOMATIC') THEN 'AUTOMATIC'
            WHEN UPPER(TRIM(transmission_type)) = 'MANUAL' THEN 'MANUAL'
            WHEN UPPER(TRIM(transmission_type)) = 'CVT' THEN 'CVT'
            WHEN TRIM(ISNULL(transmission_type, '')) = '' THEN 'UNKNOWN'
            ELSE 'UNKNOWN'
        END AS standardized_transmission_type
    FROM vehicle_base
),

duplicate_vin AS (
    SELECT
        vin_clean,
        COUNT(*) AS vin_record_count
    FROM vehicle_standardized
    WHERE vin_clean IS NOT NULL
    GROUP BY vin_clean
    HAVING COUNT(*) > 1
),

duplicate_registration AS (
    SELECT
        registration_no_clean,
        COUNT(*) AS registration_record_count
    FROM vehicle_standardized
    WHERE registration_no_clean IS NOT NULL
    GROUP BY registration_no_clean
    HAVING COUNT(*) > 1
)

SELECT
    vs.clean_vehicle_key,
    vs.asset_no_clean,
    vs.vehicle_id_clean,
    vs.vehicle_id_clean_raw AS source_vehicle_id,
    vs.vin_clean,
    vs.registration_no_clean,
    UPPER(NULLIF(TRIM(license_plate_state), '')) AS license_plate_state_clean,

    vs.make,
    vs.model,
    vs.model_year_num AS model_year,
    vs.vehicle_type,
    vs.department_code,
    vs.department_name,
    vs.fleet_group,

    vs.fuel_type AS source_fuel_type,
    vs.standardized_fuel_type,

    vs.engine_size,
    vs.transmission_type AS source_transmission_type,
    vs.standardized_transmission_type,

    vs.acquisition_date_clean,
    vs.in_service_date_clean,
    vs.warranty_expiry_date_clean,

    vs.current_status AS source_current_status,
    vs.standardized_vehicle_status,

    vs.current_odometer_num AS current_odometer,
    vs.parent_asset_no,
    vs.assigned_location_code,
    vs.assigned_location_name,
    vs.source_system,
    vs.last_updated_date_clean,

    CASE WHEN vs.vehicle_id_clean_raw IS NULL THEN 1 ELSE 0 END AS missing_vehicle_id_flag,
    CASE WHEN vs.vin_clean IS NULL THEN 1 ELSE 0 END AS missing_vin_flag,
    CASE WHEN dv.vin_clean IS NOT NULL THEN 1 ELSE 0 END AS duplicate_vin_flag,
    CASE WHEN dr.registration_no_clean IS NOT NULL THEN 1 ELSE 0 END AS duplicate_registration_flag,

    CASE
        WHEN vs.vehicle_id_clean_raw IS NULL THEN 'REVIEW_REQUIRED'
        WHEN dv.vin_clean IS NOT NULL THEN 'REVIEW_REQUIRED'
        WHEN dr.registration_no_clean IS NOT NULL THEN 'REVIEW_REQUIRED'
        WHEN vs.vin_clean IS NULL THEN 'USABLE_WITH_WARNING'
        ELSE 'OK'
    END AS clean_record_status

FROM vehicle_standardized vs
LEFT JOIN duplicate_vin dv
    ON vs.vin_clean = dv.vin_clean
LEFT JOIN duplicate_registration dr
    ON vs.registration_no_clean = dr.registration_no_clean;
GO


-- Clean vendor master view
CREATE OR ALTER VIEW clean.vw_vendor_master AS

WITH vendor_base AS (
    SELECT
        vendor_id,
        vendor_name,
        vendor_legal_name,
        partner_type,
        service_category,
        preferred_vendor_flag,
        active_flag,
        address_line_1,
        city,
        state,
        zip_code,
        phone_number,
        contact_email,
        payment_terms,
        source_system,
        last_updated_date,

        NULLIF(TRIM(vendor_id), '') AS vendor_id_clean_raw,
        NULLIF(TRIM(vendor_name), '') AS vendor_name_clean_raw,

        UPPER(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(TRIM(ISNULL(vendor_name, '')), '''', ''),
                    '.', ''),
                '&', 'AND'),
            '  ', ' ')
        ) AS normalized_vendor_name,

        COALESCE(
            TRY_CONVERT(DATE, NULLIF(TRIM(last_updated_date), ''), 23),
            TRY_CONVERT(DATE, NULLIF(TRIM(last_updated_date), ''), 101),
            TRY_CONVERT(DATE, NULLIF(TRIM(last_updated_date), ''))
        ) AS last_updated_date_clean
    FROM raw.vendor_master_raw
),

vendor_standardized AS (
    SELECT
        *,

        -- If vendor_id missing, create temporary clean key from normalize vendor name.
        COALESCE(
            vendor_id_clean_raw,
            CONCAT('DERIVED_VENDOR_', ABS(CHECKSUM(normalized_vendor_name)))
        ) AS clean_vendor_key,

        CASE
            WHEN UPPER(TRIM(partner_type)) IN ('REPAIR SHOP', 'REPAIR', 'MAINTENANCE VENDOR') THEN 'MAINTENANCE'
            WHEN UPPER(TRIM(partner_type)) IN ('FUEL SUPPLIER', 'FUEL') THEN 'FUEL_SUPPLIER'
            WHEN UPPER(TRIM(partner_type)) = 'PARTS SUPPLIER' THEN 'PARTS_SUPPLIER'
            WHEN UPPER(TRIM(partner_type)) = 'TOWING' THEN 'TOWING'
            WHEN TRIM(ISNULL(partner_type, '')) = '' THEN 'UNKNOWN'
            ELSE 'OTHER'
        END AS standardized_partner_type,

        CASE
            WHEN UPPER(TRIM(preferred_vendor_flag)) IN ('Y', 'YES', 'TRUE') THEN 1
            WHEN UPPER(TRIM(preferred_vendor_flag)) IN ('N', 'NO', 'FALSE') THEN 0
            ELSE NULL
        END AS preferred_vendor_flag_clean,

        CASE
            WHEN UPPER(TRIM(active_flag)) IN ('Y', 'YES', 'TRUE', 'ACTIVE') THEN 1
            WHEN UPPER(TRIM(active_flag)) IN ('N', 'NO', 'FALSE', 'INACTIVE') THEN 0
            ELSE NULL
        END AS active_flag_clean,

        CASE
            WHEN contact_email IS NULL OR TRIM(contact_email) = '' THEN NULL
            WHEN contact_email LIKE '%_@_%._%' THEN LOWER(TRIM(contact_email))
            ELSE NULL
        END AS contact_email_clean
    FROM vendor_base
),

duplicate_vendor_id AS (
    SELECT
        vendor_id_clean_raw,
        COUNT(*) AS vendor_id_record_count
    FROM vendor_standardized
    WHERE vendor_id_clean_raw IS NOT NULL
    GROUP BY vendor_id_clean_raw
    HAVING COUNT(*) > 1
),

repeated_normalized_vendor_name AS (
    SELECT
        normalized_vendor_name,
        COUNT(*) AS normalized_name_record_count
    FROM vendor_standardized
    WHERE normalized_vendor_name IS NOT NULL
    AND normalized_vendor_name <> ''
    GROUP BY normalized_vendor_name
    HAVING COUNT(*) > 1
)

SELECT
    vs.clean_vendor_key,
    vs.vendor_id_clean_raw AS source_vendor_id,
    vs.vendor_name_clean_raw AS vendor_name_clean,
    vs.vendor_legal_name,
    vs.normalized_vendor_name,

    vs.partner_type AS source_partner_type,
    vs.standardized_partner_type,

    vs.service_category,

    vs.preferred_vendor_flag AS source_preferred_vendor_flag,
    vs.preferred_vendor_flag_clean,

    vs.active_flag AS source_active_flag,
    vs.active_flag_clean,

    vs.address_line_1,
    vs.city,
    UPPER(NULLIF(TRIM(vs.state), '')) AS state_clean,
    vs.zip_code,
    vs.phone_number,

    vs.contact_email AS source_contact_email,
    vs.contact_email_clean,

    vs.payment_terms,
    vs.source_system,
    vs.last_updated_date_clean,

    CASE WHEN vs.vendor_id_clean_raw IS NULL THEN 1 ELSE 0 END AS missing_vendor_id_flag,
    CASE WHEN vs.contact_email_clean IS NULL THEN 1 ELSE 0 END AS missing_or_invalid_contact_email_flag,
    CASE WHEN dvi.vendor_id_clean_raw IS NOT NULL THEN 1 ELSE 0 END AS duplicate_vendor_id_flag,
    CASE WHEN rnv.normalized_vendor_name IS NOT NULL THEN 1 ELSE 0 END AS repeated_normalized_vendor_name_flag,
    CASE WHEN vs.preferred_vendor_flag_clean IS NULL THEN 1 ELSE 0 END AS unmapped_preferred_vendor_flag_flag,
    CASE WHEN vs.active_flag_clean IS NULL THEN 1 ELSE 0 END AS unmapped_active_flag_flag,

    CASE
        WHEN vs.vendor_id_clean_raw IS NULL THEN 'REVIEW_REQUIRED'
        WHEN dvi.vendor_id_clean_raw IS NOT NULL THEN 'REVIEW_REQUIRED'
        WHEN rnv.normalized_vendor_name IS NOT NULL THEN 'USABLE_WITH_WARNING'
        WHEN vs.contact_email_clean IS NULL THEN 'USABLE_WITH_WARNING'
        ELSE 'OK'
    END AS clean_record_status

FROM vendor_standardized vs
LEFT JOIN duplicate_vendor_id dvi
    ON vs.vendor_id_clean_raw = dvi.vendor_id_clean_raw
LEFT JOIN repeated_normalized_vendor_name rnv
    ON vs.normalized_vendor_name = rnv.normalized_vendor_name;
GO

-- Validate clean vehicle view row count
SELECT
    'clean.vw_vehicle_master' AS view_name,
    COUNT(*) AS row_count
FROM clean.vw_vehicle_master;

-- Validate clean vendor view row count
SELECT
    'clean.vw_vendor_master' AS view_name,
    COUNT(*) AS row_count
FROM clean.vw_vendor_master;

-- Vehicle clean status check
SELECT
    clean_record_status,
    COUNT(*) AS record_count
FROM clean.vw_vehicle_master
GROUP BY clean_record_status
ORDER BY record_count DESC;

-- Vehicle fuel type standardization check
SELECT
    source_fuel_type,
    standardized_fuel_type,
    COUNT(*) AS record_count
FROM clean.vw_vehicle_master
GROUP BY source_fuel_type, standardized_fuel_type
ORDER BY standardized_fuel_type, record_count DESC;

-- Vendor flag standardization check
SELECT
    source_preferred_vendor_flag,
    preferred_vendor_flag_clean,
    COUNT(*) AS record_count
FROM clean.vw_vendor_master
GROUP BY source_preferred_vendor_flag, preferred_vendor_flag_clean
ORDER BY preferred_vendor_flag_clean, record_count DESC;
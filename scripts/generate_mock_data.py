
import csv
import os
import random
import string
import zipfile
from datetime import datetime, timedelta
from pathlib import Path
from collections import Counter, defaultdict

random.seed(20260524)

base_dir = Path(__file__).resolve().parents[1]
mock_dir = base_dir / "data" / "raw" / "mock_messy_sources"
docs_dir = base_dir / "docs"
scripts_dir = base_dir / "scripts"
outputs_dir = base_dir / "outputs"

for d in [mock_dir, docs_dir, scripts_dir, outputs_dir]:
    d.mkdir(parents=True, exist_ok=True)

# Helper functions for data generation
def rand_date(start, end):
    delta = end - start
    return start + timedelta(days=random.randint(0, delta.days), hours=random.randint(0, 23), minutes=random.choice([0, 5, 10, 15, 20, 30, 45]))

# Intentionally inconsistent date formatting
def fmt_dt(dt):
    if dt is None:
        return ""
    # intentionally mix date formatting slightly
    if random.random() < 0.08:
        return dt.strftime("%m/%d/%Y %H:%M")
    return dt.strftime("%Y-%m-%d %H:%M:%S")

# Intentionally inconsistent date formatting for date-only fields
def fmt_date(dt):
    if dt is None:
        return ""
    if random.random() < 0.08:
        return dt.strftime("%m/%d/%Y")
    return dt.strftime("%Y-%m-%d")

# Intentionally inconsistent money formatting, with some blank and some negative values
def money(x):
    if x == "":
        return ""
    if random.random() < 0.08:
        return f"${x:,.2f}"
    return f"{x:.2f}"

#  Randomly blank out a value with probability p
def maybe_blank(value, p=0.02):
    return "" if random.random() < p else value

# Generate a random VIN-like string
def make_vin():
    chars = "ABCDEFGHJKLMNPRSTUVWXYZ0123456789"
    return "".join(random.choice(chars) for _ in range(17))

# Generate a random license plate-like string
def make_reg():
    letters = "".join(random.choice(string.ascii_uppercase) for _ in range(3))
    nums = "".join(random.choice(string.digits) for _ in range(4))
    return f"{letters}{nums}"

# Define some base data for vehicles, vendors, locations, etc.
makes_models = [
    ("Ford", "F-150", "Truck"), ("Ford", "Transit", "Van"), ("Ford", "Explorer", "SUV"),
    ("Chevrolet", "Silverado", "Truck"), ("Chevrolet", "Express", "Van"),
    ("Toyota", "Camry", "Sedan"), ("Toyota", "Prius", "Sedan"), ("Toyota", "Tacoma", "Truck"),
    ("Dodge", "Ram 1500", "Truck"), ("Freightliner", "M2", "Heavy Truck"),
    ("International", "MV607", "Heavy Truck"), ("Nissan", "NV200", "Van"),
    ("GMC", "Sierra", "Truck"), ("Honda", "Civic", "Sedan"),
]
departments = [
    ("1001", "Operations"), ("1002", "Field Services"), ("1003", "Sales"),
    ("1004", "Maintenance"), ("1005", "Customer Support"), ("1006", "Logistics"),
    ("1007", "Facilities"), ("1008", "Executive Fleet")
]
locations = [
    ("CHI01", "Chicago Central Garage"), ("CHI02", "Northside Service Hub"),
    ("MIL01", "Milwaukee Repair Yard"), ("IND01", "Indianapolis Depot"),
    ("STL01", "St. Louis Fleet Center"), ("DET01", "Detroit Partner Shop")
]
fuel_types_clean = ["Gasoline", "Diesel", "Hybrid", "Electric"]
fuel_type_messy = {
    "Gasoline": ["Gasoline", "Gas", "Unleaded", "petrol", "GAS"],
    "Diesel": ["Diesel", "DIESEL", "Dsl", "diesel"],
    "Hybrid": ["Hybrid", "HYBRID", "Gas Hybrid"],
    "Electric": ["Electric", "EV", "ELECTRIC"]
}
statuses = ["Active", "ACTIVE", "In Service", "Available", "Out of Service", "Inactive", "Retired"]

# Generate mock data for each dataset with intentional inconsistencies and issues
# 1. Vehicle master
vehicles = []
asset_nums = []
registrations = []
for i in range(1, 421):
    asset_no = f"{10000+i}"
    asset_nums.append(asset_no)
    make, model, vtype = random.choice(makes_models)
    year = random.randint(2012, 2025)
    clean_fuel = "Electric" if model in ["Prius"] and random.random() < 0.25 else random.choice(fuel_types_clean)
    reg = make_reg()
    registrations.append(reg)
    dept_code, dept_name = random.choice(departments)
    loc_code, loc_name = random.choice(locations)
    acquired = datetime(year, random.randint(1, 12), random.randint(1, 28))
    in_service = acquired + timedelta(days=random.randint(5, 90))
    warranty = acquired + timedelta(days=random.randint(900, 2200))
    age = max(1, 2026 - year)
    odom = random.randint(8000 * age, 22000 * age)
    if year < 2016 and random.random() < 0.05:
        odom = random.randint(2000, 9000)  # suspiciously low odometer
    vehicles.append({
        "asset_no": asset_no,
        "vehicle_id": maybe_blank(f"VH-{asset_no}", 0.015),
        "vin": maybe_blank(make_vin(), 0.04),
        "registration_no": reg,
        "license_plate_state": random.choice(["IL", "IN", "WI", "MO", "MI", ""]),
        "make": make,
        "model": model,
        "model_year": year,
        "vehicle_type": vtype,
        "department_code": dept_code,
        "department_name": dept_name,
        "fleet_group": random.choice(["Light Duty", "Heavy Duty", "Service", "Executive", "Pool"]),
        "fuel_type": random.choice(fuel_type_messy[clean_fuel]),
        "engine_size": random.choice(["1.8L", "2.0L", "2.5L", "3.5L", "5.3L", "6.7L", "Electric", ""]),
        "transmission_type": random.choice(["Automatic", "AUTO", "Manual", "CVT", ""]),
        "acquisition_date": fmt_date(acquired),
        "in_service_date": fmt_date(in_service),
        "warranty_expiry_date": fmt_date(warranty),
        "current_status": random.choice(statuses),
        "current_odometer": str(odom),
        "parent_asset_no": random.choice(asset_nums[:max(1, len(asset_nums)//4)]) if random.random() < 0.08 and len(asset_nums) > 5 else "",
        "assigned_location_code": loc_code,
        "assigned_location_name": loc_name,
        "source_system": random.choice(["FleetMaster", "Fleet_Master", "AssetHub"]),
        "last_updated_date": fmt_date(rand_date(datetime(2025, 1, 1), datetime(2026, 5, 1)))
    })

# intentional duplicate registrations and VINs
for idx in random.sample(range(len(vehicles)), 8):
    vehicles[idx]["registration_no"] = random.choice(registrations[:80])
for idx in random.sample(range(len(vehicles)), 5):
    vehicles[idx]["vin"] = random.choice([v["vin"] for v in vehicles[:100] if v["vin"]])

vehicle_headers = list(vehicles[0].keys())
with open(mock_dir / "vehicle_master_raw.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=vehicle_headers)
    writer.writeheader()
    writer.writerows(vehicles)

# 2. Vendor master
base_vendor_names = [
    "Joe's Auto Shop", "Northside Fleet Repair", "Midwest Diesel Service",
    "Quick Fuel Partners", "Citywide Tire & Brake", "Premier Collision Center",
    "Apex Maintenance Group", "Reliable Truck Service", "GreenCharge EV Supply",
    "Metro Fuel Services", "Central Parts Warehouse", "Lakeshore Automotive",
    "Express Oil & Lube", "Universal Fleet Solutions", "Allied Mechanics",
    "Interstate Repair Depot", "FleetPro Service Center", "RoadReady Repairs",
    "BlueLine Fuel", "Superior Body Shop", "Budget Auto Care", "Precision Hydraulics",
    "Capital Towing", "FastLane PM Services", "Industrial Equipment Repair",
    "Evergreen Battery Supply", "North Star Garage", "Partner Mobile Mechanics",
    "Atlas Heavy Truck", "Urban Fleet Maintenance"
]
vendor_variants = {
    "Joe's Auto Shop": ["Joe's Auto Shop", "JOES AUTO", "Joe Auto Service", "Joe's Automotive LLC"],
    "Northside Fleet Repair": ["Northside Fleet Repair", "NORTH SIDE FLEET", "Northside Fleet Repairs"],
    "Quick Fuel Partners": ["Quick Fuel Partners", "QuickFuel", "Quick Fuel Prtnrs"],
    "Metro Fuel Services": ["Metro Fuel Services", "METRO FUEL", "Metro Fuel Svc"],
    "Citywide Tire & Brake": ["Citywide Tire & Brake", "City Wide Tire and Brake", "CITYWIDE TIRE"],
    "GreenCharge EV Supply": ["GreenCharge EV Supply", "Green Charge", "GreenCharge"],
}
vendors = []
vendor_id_pool = []
for i in range(1, 71):
    base = random.choice(base_vendor_names)
    name = random.choice(vendor_variants.get(base, [base]))
    partner_type = random.choice(["Repair Shop", "repair", "Maintenance Vendor", "Fuel Supplier", "Fuel", "Parts Supplier", "Towing", ""])
    service_category = random.choice(["Maintenance", "Fuel", "Parts", "Tires", "Body Work", "EV Charging", "Towing"])
    vendor_id = f"V{2000+i}"
    vendor_id_pool.append(vendor_id)
    vendors.append({
        "vendor_id": maybe_blank(vendor_id, 0.04),
        "vendor_name": name,
        "vendor_legal_name": base + random.choice([" LLC", " Inc.", " Company", ""]),
        "partner_type": partner_type,
        "service_category": service_category,
        "preferred_vendor_flag": random.choice(["Y", "N", "Yes", "No", "TRUE", "FALSE", ""]),
        "active_flag": random.choice(["Y", "N", "Active", "Inactive", "TRUE", "FALSE"]),
        "address_line_1": f"{random.randint(100,9999)} {random.choice(['Main', 'Oak', 'Lake', 'Industrial', 'Commerce'])} {random.choice(['St', 'Ave', 'Rd', 'Blvd'])}",
        "city": random.choice(["Chicago", "Milwaukee", "Indianapolis", "St. Louis", "Detroit", "Gary"]),
        "state": random.choice(["IL", "WI", "IN", "MO", "MI"]),
        "zip_code": str(random.randint(46000, 60999)),
        "phone_number": random.choice([f"({random.randint(200,999)}) {random.randint(200,999)}-{random.randint(1000,9999)}", "", "555-INVALID"]),
        "contact_email": random.choice([f"contact{i}@vendor-example.com", "", f"service{i}vendor-example.com"]),
        "payment_terms": random.choice(["Net 30", "NET30", "Net 45", "Due on Receipt", ""]),
        "source_system": random.choice(["VendorHub", "AP_System", "FuelCardPortal"]),
        "last_updated_date": fmt_date(rand_date(datetime(2024, 1, 1), datetime(2026, 5, 1)))
    })
# duplicate IDs on purpose
for idx in random.sample(range(len(vendors)), 5):
    vendors[idx]["vendor_id"] = random.choice(vendor_id_pool[:20])

vendor_headers = list(vendors[0].keys())
with open(mock_dir / "vendor_master_raw.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=vendor_headers)
    writer.writeheader()
    writer.writerows(vendors)

# 3. Maintenance work orders
job_types = ["REPAIR", "Repair", "PM", "Preventative Maintenance", "preventive maint", "Corrective"]
wo_statuses = ["Closed", "CLOSED", "Open", "In Progress", "Finished", "Cancelled"]
repair_reasons = [
    ("BRK", "Brake repair"), ("TIR", "Tire replacement"), ("OIL", "Oil change"),
    ("ENG", "Engine issue"), ("TRN", "Transmission service"), ("ELEC", "Electrical issue"),
    ("PM", "Preventative maintenance"), ("BODY", "Body repair"), ("BAT", "Battery replacement")
]
maintenance = []
start_date = datetime(2024, 1, 1)
end_date = datetime(2026, 5, 1)
for i in range(1, 4001):
    create_dt = rand_date(start_date, end_date)
    open_dt = create_dt + timedelta(hours=random.randint(0, 48))
    first_labor = open_dt + timedelta(hours=random.randint(0, 96))
    duration_hours = max(1, int(random.expovariate(1/36)))
    finished_dt = first_labor + timedelta(hours=duration_hours)
    closed_dt = finished_dt + timedelta(hours=random.randint(0, 72))
    out_service = open_dt - timedelta(hours=random.randint(0, 12))
    in_service = finished_dt + timedelta(hours=random.randint(0, 12))
    due_dt = create_dt + timedelta(days=random.randint(-5, 30))
    pm_sched = create_dt + timedelta(days=random.randint(-10, 20))
    asset = random.choice(asset_nums)
    if random.random() < 0.025:
        asset = f"99{random.randint(100,999)}"  # orphan
    if random.random() < 0.018:
        asset = ""
    loc_code, loc_name = random.choice(locations)
    dept_code, dept_name = random.choice(departments)
    reason_code, reason_desc = random.choice(repair_reasons)
    vendor = random.choice(vendors)
    labor_hours = round(random.uniform(0.25, 28), 2)
    labor_cost = round(labor_hours * random.uniform(70, 145), 2)
    parts_cost = round(random.uniform(0, 2500), 2)
    comml_cost = round(random.choice([0, random.uniform(20, 1200)]), 2)
    total_cost = labor_cost + parts_cost + comml_cost
    # inject cost inconsistencies
    if random.random() < 0.04:
        total_cost = total_cost + random.uniform(25, 900)
    if random.random() < 0.012:
        labor_cost = -abs(labor_cost)
    if random.random() < 0.015:
        parts_cost = ""
    if random.random() < 0.01:
        closed_dt = open_dt - timedelta(hours=random.randint(1, 72))  # invalid date logic
    maintenance.append({
        "UNIQUE_WORK_ORDER_NO": f"WO-{2024 + (i % 3)}-{i:06d}",
        "CREATE_DATE": fmt_dt(create_dt),
        "LOC_WORK_ORDER_LOC": loc_code,
        "LOC_WORK_ORDER_LOC_NAME": loc_name,
        "WORK_ORDER_YR": str(create_dt.year),
        "WORK_ORDER_NO": str(100000 + (i % 15000)),
        "JOB_TYPE": random.choice(job_types),
        "EQ_EQUIP_NO": asset,
        "WORK_ORDER_STATUS": random.choice(wo_statuses),
        "METER_1_READING": str(random.randint(5000, 225000)),
        "DATETIME_OUT_SERVICE": fmt_dt(out_service),
        "DATETIME_IN_SERVICE": fmt_dt(in_service),
        "DATETIME_OPEN": fmt_dt(open_dt),
        "DATETIME_FIRST_LABOR": fmt_dt(first_labor),
        "DATETIME_FINISHED": fmt_dt(finished_dt),
        "DATETIME_CLOSED": fmt_dt(closed_dt),
        "DATETIME_UNIT_IN": fmt_dt(open_dt - timedelta(hours=random.randint(0, 24))),
        "DATETIME_DUE": fmt_dt(due_dt),
        "DATETIME_PM_SCHED": fmt_dt(pm_sched),
        "QTY_EST_HOURS": str(round(random.uniform(1, 16), 2)),
        "DOWNTIME_HRS_USER": str(round(random.uniform(0, 120), 2)),
        "DOWNTIME_HRS_SHOP": str(round(random.uniform(0, 100), 2)),
        "WARRANTY": random.choice(["Y", "N", "Yes", "No", ""]),
        "REAS_REAS_FOR_REPAIR": reason_code,
        "REAS_FOR_REPAIR_DESC": reason_desc,
        "PRI_PRIORITY_CODE": str(random.choice([1, 2, 3, 4, "", "High"])),
        "REF_WORK_ORDER_NO": random.choice(["", f"WO-REF-{random.randint(1000,9999)}"]),
        "DEPT_EQUIP_DEPT": dept_code,
        "DEPT_EQUIP_DEPT_NAME": dept_name,
        "METER_1_LIFE_TOTAL": str(random.randint(5000, 260000)),
        "EQ_PARENT_EQUIP_NO": random.choice(["", random.choice(asset_nums)]),
        "DELAY_HOURS": str(round(random.uniform(0, 80), 2)),
        "LABOR_HOURS": str(labor_hours),
        "LABOR_COST": money(labor_cost) if labor_cost != "" else "",
        "PARTS_COST": money(parts_cost) if parts_cost != "" else "",
        "COMML_COST": money(comml_cost),
        "TOTAL_COST": money(round(total_cost, 2)),
        "vendor_id": random.choice([vendor["vendor_id"], "", f"V9{random.randint(100,999)}"]) if random.random() < 0.08 else vendor["vendor_id"],
        "vendor_name": random.choice([vendor["vendor_name"], vendor["vendor_legal_name"], "Unknown Vendor", ""]) if random.random() < 0.08 else vendor["vendor_name"],
        "work_description": random.choice(["Routine service", "Customer reported issue", "Inspection follow-up", "Emergency repair", "PM schedule", ""]),
        "source_system": random.choice(["FleetAnywhere", "Fleet Anywhere", "MaintenancePortal"])
    })
# duplicate several work orders
for row in random.sample(maintenance, 22):
    duplicate = row.copy()
    duplicate["source_system"] = "MaintenancePortal"
    maintenance.append(duplicate)

maintenance_headers = list(maintenance[0].keys())
with open(mock_dir / "maintenance_work_orders_raw.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=maintenance_headers)
    writer.writeheader()
    writer.writerows(maintenance)

# 4. Fuel transactions
fuel_transactions = []
supplier_names = [v["vendor_name"] for v in vendors if "Fuel" in v["service_category"] or "Fuel" in v["partner_type"] or "Fuel" in v["vendor_name"]]
supplier_names += ["QuickFuel", "METRO FUEL", "Blue Line Fuel", "Green Charge", "Unknown Supplier"]
last_odom = defaultdict(lambda: random.randint(5000, 40000))
for i in range(1, 8001):
    veh = random.choice(vehicles)
    txn_date = rand_date(datetime(2024, 1, 1), datetime(2026, 5, 1))
    asset = veh["asset_no"]
    reg = veh["registration_no"]
    if random.random() < 0.025:
        asset = f"X{random.randint(90000,99999)}"
    if random.random() < 0.025:
        reg = make_reg()
    if random.random() < 0.015:
        asset = ""
    unit = random.choice(["Miles", "MILES", "KM", "Kilometers"])
    qty_uom = random.choice(["Gallons", "GAL", "Liters", "L"])
    product = random.choice(["Diesel", "DIESEL", "Dsl", "Gasoline", "Gas", "Unleaded", "Petrol", "Electric"])
    distance = random.randint(30, 900)
    if unit.lower().startswith("k"):
        distance_val = distance * 1.609
    else:
        distance_val = distance
    odom = last_odom[asset] + max(1, int(distance_val))
    # backwards odometer
    if random.random() < 0.018:
        odom = max(0, last_odom[asset] - random.randint(100, 3000))
    last_odom[asset] = odom
    fuel_qty = round(random.uniform(4, 38), 2)
    if qty_uom.lower().startswith("l"):
        # liters quantity, intentionally not always converted for MPG
        fuel_qty = round(fuel_qty * 3.785, 2)
    mpg = round(distance / max(1, fuel_qty), 2)
    if random.random() < 0.025:
        mpg = round(random.choice([0, random.uniform(90, 250), random.uniform(0.1, 2.5)]), 2)
    cost = round(fuel_qty * random.uniform(3.0, 5.4), 2)
    if random.random() < 0.012:
        cost = random.choice([0, random.uniform(500, 2000)])
    fuel_transactions.append({
        "fuel_txn_id": f"FT-{i:07d}",
        "transaction_date": fmt_dt(txn_date),
        "Number": maybe_blank(veh["vehicle_id"], 0.04),
        "Registration": reg,
        "Asset No": asset,
        "Details": f"{veh['make']} {veh['model']} {veh['vehicle_type']}",
        "Product": product,
        "supplier_name": random.choice(supplier_names),
        "fuel_card_id": random.choice([f"FC-{random.randint(100000,999999)}", "", "TEMP-CARD"]),
        "Odometer": "" if random.random() < 0.025 else str(odom),
        "Distance": str(round(distance_val, 1)),
        "Unit": unit,
        "Fuel_Qty": str(fuel_qty),
        "Qty_UOM": qty_uom,
        "Fuel_Cost": money(cost),
        "MPG": str(mpg),
        "driver_department": random.choice([d[1] for d in departments] + ["Ops", ""]),
        "source_file_name": random.choice(["fuelcard_export_jan.csv", "Fuel Usage 18-19.csv", "supplier_fuel_extract.csv"])
    })
# add blank/nearly blank rows
for _ in range(12):
    fuel_transactions.insert(random.randint(0, len(fuel_transactions)-1), {h: "" for h in [
        "fuel_txn_id","transaction_date","Number","Registration","Asset No","Details","Product","supplier_name",
        "fuel_card_id","Odometer","Distance","Unit","Fuel_Qty","Qty_UOM","Fuel_Cost","MPG","driver_department","source_file_name"
    ]})

fuel_headers = list(fuel_transactions[0].keys())
with open(mock_dir / "fuel_transactions_raw.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=fuel_headers)
    writer.writeheader()
    writer.writerows(fuel_transactions)

# 5. Fleet condition assessment
condition_rows = []
for i in range(1, 1501):
    veh = random.choice(vehicles)
    assess_date = rand_date(datetime(2024, 1, 1), datetime(2026, 5, 1))
    last_service = assess_date - timedelta(days=random.randint(0, 420))
    if random.random() < 0.018:
        last_service = assess_date + timedelta(days=random.randint(1, 90))
    warranty = datetime.strptime(veh["warranty_expiry_date"][:10], "%Y-%m-%d") if veh["warranty_expiry_date"] and "-" in veh["warranty_expiry_date"] else assess_date + timedelta(days=random.randint(1, 600))
    vehicle_id = veh["vehicle_id"]
    if random.random() < 0.03:
        vehicle_id = f"VH-X{random.randint(1000,9999)}"
    if random.random() < 0.04:
        vehicle_id = ""
    odom_master = int(veh["current_odometer"]) if str(veh["current_odometer"]).isdigit() else random.randint(5000, 200000)
    mileage = odom_master + random.randint(-5000, 5000)
    odom_read = mileage + random.choice([random.randint(-300, 300), random.randint(5000, 25000)])
    condition_rows.append({
        "assessment_id": f"CA-{i:06d}",
        "assessment_date": fmt_date(assess_date),
        "vehicle_id": vehicle_id,
        "registration_no": veh["registration_no"] if random.random() > 0.03 else make_reg(),
        "Vehicle_Model": random.choice([veh["model"], veh["vehicle_type"], f"{veh['make']} {veh['model']}"]),
        "Mileage": str(max(0, mileage)),
        "Maintenance_History": random.choice(["Good", "Average", "Poor", "GOOD", "Unknown"]),
        "Reported_Issues": str(random.choice([0, 0, 1, 1, 2, 3, ""])),
        "Vehicle_Age": str(max(0, 2026 - int(veh["model_year"]))),
        "Fuel_Type": random.choice([veh["fuel_type"], "Diesel", "DIESEL", "Gas", "Electric", "EV", "Hybrid"]),
        "Transmission_Type": random.choice([veh["transmission_type"], "Automatic", "AUTO", "Manual", ""]),
        "Engine_Size": random.choice([veh["engine_size"], "2000", "2500", "3.5L", "Electric", ""]),
        "Odometer_Reading": str(max(0, odom_read)),
        "Last_Service_Date": fmt_date(last_service),
        "Warranty_Expiry_Date": fmt_date(warranty),
        "Owner_Type": random.choice(["Company", "Leased", "Second", "Pool", ""]),
        "Insurance_Premium": str(random.randint(800, 4500)),
        "Service_History": str(random.randint(0, 20)),
        "Accident_History": str(random.choice([0, 0, 0, 1, 2, 3])),
        "Fuel_Efficiency": str(round(random.uniform(8, 55), 2)),
        "Tire_Condition": random.choice(["New", "Good", "GOOD", "Worn", "Worn Out", "Poor"]),
        "Brake_Condition": random.choice(["New", "Good", "GOOD", "Worn", "Needs Service", "Poor"]),
        "Battery_Status": random.choice(["New", "Good", "Weak", "WEAK", "Replace", "Unknown"]),
        "Need_Maintenance": str(random.choice([0, 0, 0, 1, 1])),
        "source_system": random.choice(["ConditionPortal", "InspectionApp", "MaintenanceRiskModel"])
    })

condition_headers = list(condition_rows[0].keys())
with open(mock_dir / "fleet_condition_assessment_raw.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=condition_headers)
    writer.writeheader()
    writer.writerows(condition_rows)

# Technical design markdown
design_md = """# Mock Dataset Design

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
"""

(docs_dir / "mock_dataset_design.md").write_text(design_md, encoding="utf-8")

# Write generation summary
summary_rows = []
for file_name in [
    "vehicle_master_raw.csv",
    "vendor_master_raw.csv",
    "maintenance_work_orders_raw.csv",
    "fuel_transactions_raw.csv",
    "fleet_condition_assessment_raw.csv",
]:
    path = mock_dir / file_name
    with open(path, newline="", encoding="utf-8") as f:
        reader = csv.reader(f)
        headers = next(reader)
        row_count = sum(1 for _ in reader)
    summary_rows.append({"file_name": file_name, "row_count": row_count, "column_count": len(headers)})

with open(outputs_dir / "mock_data_generation_summary.csv", "w", newline="", encoding="utf-8") as f:
    writer = csv.DictWriter(f, fieldnames=["file_name", "row_count", "column_count"])
    writer.writeheader()
    writer.writerows(summary_rows)

# Save the generator script itself
script_text = """# This project package was generated in ChatGPT.
# For reproducibility, the mock data used random seed 20260524.
# The full generation logic is available in the conversation-generated artifact package.
# Recommended use: keep this script in /scripts and keep generated raw CSVs in /data/mock_messy_sources.
"""
(scripts_dir / "README_generate_mock_data.txt").write_text(script_text, encoding="utf-8")

# zip package
zip_path = Path("/mnt/data/data_integrity_automation_prototype_mock_data_package.zip")
with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
    for p in base_dir.rglob("*"):
        z.write(p, p.relative_to(base_dir.parent))

summary_rows, str(zip_path)

# Daily Research Log

## Day 1: Project Setup, Problem Framing, and Raw Data Ingestion

### Date

05/24/2026

### Goals for Today

- Set up the project folder
- Create initial documentation files
- Define the business problem
- Understand the purpose of the prototype
- Identify public datasets for mock dataset generation inspiration
- Create mock csv files as sources referenced from the public datasets
- Ingest the CSV files into SQL

### Work Completed

- Created the main project folder: 'data_integrity_automation_prototype'
- Created initial documentation files:
    - 'README.md'
    - 'project_charter.md'
    - 'daily_research_log.md'
    - 'assumptions_decisions_log.md'
- Created full folder structure
- Defined the project as a fleet data integrity and automation prototype
- Identified candidate datasets to use as inspiration for mock dataset generation
- Identified and created mock csv files for mock datasets
- Defined the contents of mock csv files
- Identified intentional errors to introduce in our mock files
- Generated mock datasets using ChatGPT and prompt engineering
- Inspected the mock CSV before loading into SQL
- Identified and reported limitations of simulating fleet data
- CSV files have been ingested into the SQL server and database

### What I Learned

- A good analytics project should start with a clear business problem before jumping into tools.
- Documentation is part of the project, not something added at the end.
- Messy data requires assumptions, and those assumptions should be tracked.
- Different datasets can have different grains, meaning the representation of each row can be different between datasets. One maintenance work order row could show an individual work order, whereas a row in fuel consumption file can represent one months fuel total by fuel type.
- If the prompts, parameters and purpose is set accurately, AI agents can become a valuable asset in generating simulated data, in this case for fleet related datasets. It is always important to perform QC when working with AI generated content, such as a walkthrough of the code, the outputs, and a review of the alignment of generated output with goals of the project.
- Generating mock data comes with it's own limitations, and would require more manual work to simulate real-world more accurately, but adjusting expectations based on project scope is essential in avoiding wasted time.
- There are particulars to each software being used, and understanding what is happening in each step even in an unfamiliar software is essential to navigating challenges and figuring out requirements of each software.
- It is important to perform quality control checks to confirm successful ingestion.

### Questions / Uncertainties

- Which fields should be treated as trusted identifiers?
- What kinds of data quality issues are most realistic in fleet operations?
- Which tool should handle each part of the workflow?
- The initial datasets found were vastly different in size. While the maintenance work order dataset has 300,000+ rows, the fleet service report only has 39 rows and the fuel consumption has 19 rows, reporting in a much shorter window. While These datasets could serve as inspiration for mock datasets, they would not be useful as a baseline besides extracting only the column names.
- Use all acquired public datasets for inspiration to generate mock datasets.
- Identify what columns could be used to simulate vehicle information, fuel transactions, fleet condition assessment, maintenance work orders, etc.

### Next Steps

- Perform raw data profiling in SQL

### Notes

- The normal approach to Ingesting the CSV files into SQL server was not successful (Tasks -> Import Flat File). After some research, I found out that Import Data is an alternative approach (without using SQL commands), but required installation of SQL Server Integration Services Projects 2022+ (SSIS). After installation, "Tasks -> Insert Data" worked successfully.
- During Ingestion, the "Insert Data" was working for the most part, but the "maintenance_work_orders_raw.csv" has additional commas for certain values containing dollar values. I noticed errors returning for unsuccessful ingestion, and after looking around, I realized that I had to set "Text qualifier" as a quotation mark (") in order to avoid structural errors that can be caused by commas introduced in CSV values.

## Day 2: Data Profiling

### Date

05/26/2026

### Goals for Today

- Create profiling queries for the raw data
- Identify data quality issues
- Generate profiling reports for each table

### Work Completed

- Created SQL queries for profiling
- Identified and reported data quality issues
- Created formal data quality rules
- Created an exception table in SQL

### What I Learned

- Data quality can contribute drastically to the operations and downstream analytics in any organization. It is important to assess the fitness of data sources to ensure proper operations, establish standardization, and clear any potential issues with the data.
- Similar fields across datasets do not always mean the same thing, like `Odometer`, `Mileage`, and `METER_1_READING`.
- Missing keys and orphan records are important because they show whether datasets can be joined reliably.
- Some records can be automatically cleaned, but others should be flagged for business review instead of being changed blindly.
- Profiling results can be used to create formal data quality rules to be used later in the project.

### Questions / Uncertainties

- Which vehicle identifier should be treated as the most reliable key: asset_no, vehicle_id, registration_no, or another field?
- Should duplicate vendors be merged based on exact matching, normalized names, or fuzzy matching?
- Should orphan records be excluded from analysis, corrected through lookup rules, or sent to an exception review process?
- What should happen when two systems disagree like vehicle master fuel type vs. assessment fuel type?

### Next Steps

- Create clean SQL views/tables
- Clean up the raw tables

### Notes

- Some counts are slightly different between profiling report and the exception table
    - Fuel report had 215 missing odometer values, but the exception table has 203 missing odometer exceptions, because the 12 blank rows are handled separately as `Likely blank row`.
    - Fuel report had 134 missing `Asset No` values, but the exception table has 122 missing vehicle reference exceptions, because the 12 blank rows are separately handled.
    - Maintenance cost validation appears as both high and medium severity, which is reasonable because negative labor costs are treated as high severity, while other cost issues are medium severity.

## Day 3: Clean SQL Views

### Date

05/27/2026

### Goals for Today

- Create clean SQL views/tables
- Clean up the raw tables, starting from the master tables.
- Create clean views for the vehicle and vendor master tables.
- Preserve raw values while also creating standardized fields.
- Add flags that show which records are usable, usable with warning, or require review.
- Validate row counts and clean record status distribution.
- Create clean views for maintenance work orders, fuel transactions, and fleet condition assessments.

### Work Completed

- Created `clean.vw_vehicle_master`.
- Created `clean.vw_vendor_master`.
- Standardized vehicle fields such as fuel type,status, transmission type, dates, and odometer values.
- Standardized vendor fields such as partner type, preferred vendor flag, active flag, normalized vendor name, and contact email.
- Created clean keys while preserving source identifiers.
- Added flags for missing IDs, duplicate IDs, repeated vendor names, and missing/invalid contact fields.
- Ran validation queries to compare clean view row counts against raw table row counts.
- Validated clean vehicle and vendor views.
- Created clean views for:
    - `clean.vw_maintenance_work_orders`
    - `clean.vw_fuel_transactions`
    - `clean.vw_fleet_condition_assessments`
- Created a github repository for the project.

### What I Learned

- Clean views are useful before creating clean tables because they keep logic transparent and easy to revise.
- A clean layer is there to preserve the source values while adding standardized fields.
- On a technical lesson, even though I was familiar previously, I've practiced utilizing more advanced SQL queries using `COALESCE`, `TRY_CONVERT` and `CASE WHEN`. These are very useful commands that allow us to apply conditionals or trial and errors to our normalization and standardization efforts.
- Some issues can be standardized safely, while others should remain flagged for business review.
- Reference/master data should be cleaned before transaction data because maintenance, fuel and condition records depend on vehicle and vendor matching.
- Ran into about 70 errors when creating `07_create_clean_transaction_views.sql`. After running the queries without any issues (while errors were still showing), I realized that these errors were different than SQL execution errors. My assumption is that these errors stemmed from utilizing a SQL extension and using VS Code for scripting.
- Validation queries are important because they confirm whether the actual database output is correct, even if the editor shows warnings.

### Questions / Uncertainties

- Should `asset_no` be treated as the clean vehicle key when `vehicle_id` is missing?
- When is it acceptable to create derived keys for missing vendor or vehicle identifiers?
- Should duplicate VINs, duplicate registration numbers, and duplicate vendor IDs block these records from the clean layer or only flag them?
- How should repeated normalized vendor names be handled? When might they require manual review to avoid different vendors with similar names getting merged?
- Should missing vendor contact emails affect operational workflows later in Power Apps or Power Automate? How can we remediate missing contact email efficiently?
- Should `USABLE_WITH_WARNING` records be included in dashboards by default, or only included with filters?
- Should records marked `REVIEW_REQUIRED` be excluded from all business metrics, or only from specific metrics?
- When is a good time to convert clean views into clean tables?

### Next Steps

- Review records marked `REVIEW_REQUIRED` and `USABLE_WITH_WARNING`.
- Begin designing how exceptions will connect to Power Apps review workflow later.

### Notes

- As mentioned previously, I ran into an issue where `07_create_clean_transaction_views.sql` produced multiple (around 70) VS Code warnings. These warnings did not seem to contribute to any issues in execution of the commands.
- Got carried away with the work, but decided that it is better now than later to create a github repository for the project, both in order to version control, and also to keep track of daily updates of the project. It is also important so I can easily share the project with interested parties once it is completed.
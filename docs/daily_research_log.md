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
- Also, this is a good place to wrap up the baseline work with SQL, and start working on the Alteryx -> Power Automate -> Power Apps pipeline. For this, I will first take a similar
    1. Data Profiling
    2. Exception Generation
    3. Data Cleaning
    approach using Alteryx, before moving on to creating trigger alerts or automate handoffs using Power Automate, and finally use Power Apps to create an exception review UI for business operations.

## Day 4: Alteryx Integration

### Date

05/28/2026

### Goals for Today

- Install Alteryx
- Figure out how to use Alteryx
    1. Connect Alteryx to SQL Server.
    2. Read raw.vehicle_master_raw.
    3. Add Browse and confirm rows load.
    4. Add Select to rename/standardize fields.
    5. Add Formula to create one flag.
    6. Add Filter to isolate exceptions.
    7. Output one exception file.
    8. Repeat for raw.vendor_master_raw.
    9. Add duplicate checks.
    10. Add maintenance/fuel/condition tables.
    11. Add Join tools to find orphan records.
    12. Output final data_quality_exceptions_alteryx.csv.

### Work Completed

- Alteryx installed
- Connected Alteryx to SQL Server.
- Replicated the SQL commands from `05_create_data_quality_exceptions.sql` in Alteryx
- Saved the .yxmd for data quality exceptions under `/alteryx/workflows/fleet_data_quality_workflow.yxmd`
- Implemented data quality exception validations in Alteryx.

### What I Learned

- The drag-and-drop style of Alteryx is very intuitive, and testing individual sections of a workflow gives so much control on troubleshooting and refining workflows.
- Some SQL commands do not have direct translations to Alteryx:
    - Datetime normalizations can be done under a COALESCE approach, but there is no TRY_CONVERT function in Alteryx. Instead, I used a chain of IF/THEN statements
    - Instead of PARTITION BY, I used a Sort tool to order by columns
    - Instead of ROW_NUMBER () I used a Multi-Row Formula in order to count the occurences based on specific sorting parameters.
- SQL server handles implicit data type conversion behind the scenes, whereas this needs to be done manually in Alteryx (see `fleet_data_quality_workflow.yxmd` "Maintenance Work Orders Cost Vlidation Exceptions" initial filter tool)
- The Output Data tool is a little tricky. While it allows user to choose which server to save in, the particular schema and table selection is done through "naming" the output table. This naming has to be in `DatabaseName.SchemaName.TableName` format to direct to the specific table, especially if the table has already been created.

### Questions / Uncertainties

- Similar approaches to SQL servers `COALESCE` failed in normalizing datetime. While `DateTimeParse` works and converts datetimes, for some reason `COALESCE` tries all options even after succeeding with the first conversion. This generates lots of errors, and reaches the error limits. Functionally, on it's own, this wouldn't create any issues, but it could potentially mask other errors in the process. I have switched to a chain of IF/THEN statements and REGEX matching to perform the same normalizations.

### Next Steps

- Implement clean up SQL scripts in Alteryx.

## Day 5: Alteryx Cleanup Outputs and Power Apps Review Queue

### Date

05/29/2026

### Goals for Today

- Proceed with clean output creation with the exceptions generated in Alteryx.
- Separate records that can be used for clean reporting from records that require business review.
- Create clean outputs for all 5 tables the exceptions were created for:
    - vehicle_master
    - vendor_master
    - maintenance_work_orders
    - fuel_transactions
    - fleet_condition_assessment
- Prepare the files for Power Apps and Power Automate exception review workflow.

### Work Completed

- Created `all_data_quality_exceptions_alteryx.csv`.
- Created `review_required_exceptions_alteryx.csv`.
- Added `resolution_path` logic to separate review-required issues from non-review issues
- Created clean Alteryx outputs for:
    - `vehicle_master_clean_alteryx.csv`
    - `vendor_master_clean_alteryx.csv`
    - `maintenance_work_orders_clean_alteryx.csv`
    - `fuel_transactions_clean_alteryx.csv`
    - `fleet_condition_assessment_clean_alteryx.csv`
- Created excluded review-required outputs for master and transaction tables.
- Used clean vehicle and vendor master outputs as reference layers for transaction table joins.
- Joined maintenance work orders, fuel transactions, and fleet condition assessments back to clean master data before outputting clean records.
- Performed a final quality check on Alteryx output row counts and saved under `alteryx/outputs/cleanup_validation.md`
- Converted `review_required_exceptions_alteryx.csv` into Microsoft List as "Fleet Data Quality Review Queue".
- Used "Fleet Data Quality Review Queue" to create and publish a `REVIEW_REQUIRED` exception review app using Power Apps.
    - Implemented a scrollable list of issues that require review, showing `issue_type`, `source_record_id`, `severity`, and `review_status`.
    - The app gives user the ability to search, click on an issue, and edit fields like
        - `review_status`
        - `resolution_path`
        - `resolved_at`
        - `review_notes`
        - Add attachments
    - Issues marked as "Resolved" gets pushed to the bottom of the list to avoid accidental changes filtering out the issue and to allow review of resolved issues.
    - Edits made in the app are written back to the SharePoint "Fleet Data Quality Review Queue" list.

### What I Learned

- Exception generation and data cleanup are related but not the same step. Some records get cleaned automatically, while others are held out for business review.
- Clean master/reference data should be created before transaction data because transaction records depend on reliable vehicle and vendor matching.
- In Alteryx, the `Join` tool is useful not only for combining data, but also for separating clean records from records that require review.
- The `Summarize` tool may rename fields based on the aggregation method, such as creating `First_severity`, so final field names should be reviewed carefully before output.
- Creating separate clean and excluded outputs makes the workflow more transparent and separates business review records from data that is ready to be analyzed.
- Choice columns in SharePoint behave differently in Power Apps and often require `.Value` in formulas.

### Questions / Uncertainties

- Should records with medium-severity issues be included in dashboards by default or only included with filters?
- Should excluded review-required records be shown in Tableau, Power Apps, or both?

### Next Steps

- Create a Power Automate flow to notify users when high severity exceptions require review.
- Create a Tableau dashboard that shows exception counts, high severity issues, clean vs. excluded records, and fleet operations metrics from clean tables.

## Day 6: Power Automate Flows and Tableau Dashboards

### Date

05/30/2026

### Goals for Today

- Create a Power Automate flow that notifies the user of high severity exceptions.
- Create a Tableau dashboard that shows exception counts, high severity issues, clean vs. excluded records, and fleet operations metrics from clean tables.
- Clean up the documentation for github upload and final presentation.
- Test the review workflow using positive and negative test cases.
- Create a `power_platform_implementation.md` documentation file

### Work Completed

- Created a Power Automate cloud flow called `Notify High Severity Data Quality Exceptions`.
- Created a second Power Automate cloud flow called `Stamp Resolved Exceptions`.
- Configured the flow to send an email when a new exception has `severity = High` and `review_status = New`.
- Tested the flow with positive and negative test cases.
- Added a safeguard to `Stamp Resolved Exceptions` flow so `resolved_at` is only populated when the field is blank, preventing the flow from overwriting existing resolution timestamps.
- Created a `power_platform_implementation.md` documentation file.
- Exported the files and captured screenshots of the workflows for the Power Apps and Power Automate for documentation.
- Uploaded `all_data_quality_exceptions_alteryx.csv` into Tableau.
- Created the `Data Quality Command Center` and `Fleet Operations Snapshot` dashboard.
- Captured screenshots/export evidence for documentation.

### What I Learned

- For this specific project, Power Automate works as a notification and routing layer rather than a data cleaning tool.
- Not all project artifacts are easy to share directly, so screenshots, exported packages, and clear documentation are important for communicating the work.
- Tableau works well as the final communication layer for a data quality project.
- It is important to keep the data quality dashboard and operational dashboards separated since they answer different questions.
- The data quality dashboard explains whether the data can be trusted.
- The operations dashboard shows what reporting becomes possible after the data is cleaned.
- The `resolved_at` timestamp creates a simple audit trail for exception closure and makes the review workflow more complete.

### Questions / Uncertainties

- Should the notification flow eventually trigger only once per exception, or should it also remind users about unresolved high-severity exceptions?
- Should assignment eventually use a person/group column instead of a plain text field?
- Should the review queue be refreshed manually from Alteryx outputs or automated later?
- Would a real implementation connect Tableau directly to SQL Server, SharePoint, or a governed data warehouse instead of CSV outputs?
- Should the resolved timestamp eventually be pushed back into SQL Server or only maintained in the SharePoint review queue?

### Notes

- The new high severity data quality exception notification is triggered per each new exception. It would be a good improvement in the future to include an email that goes out daily, listing all new high severity exceptions for that day to avoid spamming.

## Next Steps

- Prepare the final deliverable package for sharing, including the project overview, tool-specific documentation, screenshots, exported artifacts, and a short demo script.
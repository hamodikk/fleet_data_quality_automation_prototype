# Demo Script: Fleet Data Quality Automation Prototype

## 1. Opening Summary

This project is a mock fleet data quality automation prototype. It demonstrates how messy operational data can be profiled, validated, cleaned, routed for review, automated, and reported using SQL Server, Alteryx, SharePoint, Power Apps, Power Automate, and Tableau.

The goal of the project was not to build a production system, but to show initiative, fast learning, and a structured approach to solving messy business data problems with tools commonly used in analytics, automation, and business excellence workflows.

## 2. Business Problem

Fleet related data often comes from multiple sources, including vehicle master records, vendor records, maintenance work orders, fuel transactions, and condition assessments.

In this kind of environment, data quality issues can make reporting unreliable. Examples include missing vehicle IDs, duplicate vendor records, orphan transactions, inconsistent fuel type labels, invalid dates, suspicious MPG values, and cost fields that do not reconcile.

If these issues are not identified and handled clearly, dashboards and business decisions based on the data may be misleading.

## 3. End-to-End Workflow

The project follows this workflow:

1. Mock fleet datasets were generated using public fleet related datasets as structural inspiration.
2. Raw CSV files were loaded into SQL Server to simulate a business data storage layer.
3. SQL was used for raw data profiling, validation, and initial data quality rule discovery.
4. Alteryx connected to SQL Server and recreated the exception generation logic as a repeatable workflow.
5. Alteryx separated "review required" exceptions from records that could be cleaned or used for reporting.
6. Review required exceptions were imported into a SharePoint List called `Fleet Data Quality Review Queue`.
7. Power Apps was used to create a simple exception review app where users can update review status, notes, assignment, and resolution information.
8. Power Automate was used to send notifications for new high severity exceptions and to stamp resolved records with a resolution timestamp.
9. Tableau was used to create dashboards for both data quality health and clean fleet operations reporting.

## 4. Tool Responsibilities

| Tool | Role |
|---|---|
| SQL Server | Raw data storage, profiling, validation, and initial rule discovery |
| Alteryx | Repeatable exception generation, validation, cleanup, and clean outputs |
| SharePoint | Review queue storage |
| Power Apps | Exception review interface |
| Power Automate | Notifications and review lifecycle automation |
| Tableau | Data quality and operations dashboards |

## 5. Key Deliverables to Show

During a walkthrough, the main deliverables to show are:

1. `PROJECT_OVERVIEW_AND_DELIVERABLES.md`
2. `project_charter.md`
3. SQL profiling, exception, and clean view scripts
4. Alteryx workflow screenshots and clean output files
5. SharePoint review queue screenshots
6. Power Apps review app screenshot/export
7. Power Automate flow screenshots/exports
8. Tableau dashboard screenshots/exports

## 6. Demo Walkthrough Order

A good review order is:

1. Start with `PROJECT_OVERVIEW_AND_DELIVERABLES.md` to explain the full workflow and deliverables.
2. Show the SQL scripts to explain profiling, exception creation, and clean view logic.
3. Show the Alteryx workflow or screenshots to explain how the SQL exception logic was translated into a repeatable workflow.
4. Show the clean and excluded Alteryx outputs to explain how records were separated for reporting or review.
5. Show the SharePoint review queue to explain where review required exceptions are stored.
6. Show the Power Apps app to explain how a reviewer can inspect issues and update status or notes.
7. Show the Power Automate flows to explain notification and resolution timestamp automation.
8. Show the Tableau dashboards to explain how the final outputs support data quality monitoring and fleet operations reporting.

## 7. Main Takeaway

This prototype shows how a business team could move from messy source data to a more trustworthy reporting and review workflow.

The project demonstrates that data quality is not just a cleaning step. It requires profiling, documented rules, exception handling, business review, automation, and reporting. SQL, Alteryx, Power Apps, Power Automate, and Tableau each play a different role in that process.

## 8. Closing Statement

The project is intentionally scoped as a learning prototype, not a production deployment. However, it demonstrates a practical foundation for building a more mature data quality workflow, including raw data preservation, repeatable exception generation, business review routing, automation, and dashboard reporting.
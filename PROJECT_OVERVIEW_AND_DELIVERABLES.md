# Fleet Data Quality Automation Prototype

## Purpose of This Document

This file serves as the final navigation guide for the Fleet Data Integrity & Automation Prototype. The full project purpose, business problem, scope, and success criteria are documented separately in `project_charter.md`.

This document focuses on what was built, where the deliverables are located, and how to review the project.


## 1. Project Purpose

The purpose of this project is to demonstrate how messy, fleet related operational data can be turned into a structured, reviewable, and reportable data workflow.

This prototype was built as a mock business excellence automation project. It simulates a common business problem where data from vehicles, vendors, maintenance work orders, fuel transactions, and fleet condition assessments is inconsistent, incomplete, or difficult to trust. Instead of only cleaning the data manually, the project shows how a repeatable workflow can be created to profile the data, identify quality issues, generate exceptions, clean usable records, route unresolved issues for review, and present results through dashboards. The goal of this project is not to claim production level expertise in every tool used. The goal is to show initiative, fast learning, structured problem solving, and an understanding of how data quality, automation, and analytics can work together in a business setting.

## 2. Business Context

Fleet operations often depend on data from multiple internal and external partners, including mechanics, fuel suppliers, vendors, and internal departments. In a real business environment, these sources may not follow the same standards. Important core features like vehicle identifiers may be inconsistent, vendor names may be duplicated or formatted differently, date fields may be unreliable, and similar column names may refer to different types of information across datasets.

These issues can make it difficult for business teams to answer basic operational questions with confidence. For example, a team may want to know which vehicles have the highest maintenance cost, which vendors are associated with the most repair activity, or whether fuel and odometer records are reliable enough for performance reporting. If the underlying data cannot be trusted, the dashboard or analysis built from that data may also be misleading.

This project models that challenge using mock fleet data generated with support from ChatGPT and reviewed for alignment with the project goals. The workflow uses SQL Server for raw data storage and initial profiling, Alteryx for repeatable exception generation and cleanup, SharePoint and Power Apps for exception review, Power Automate for notification and review lifecycle automation, and Tableau for dashboard reporting.

The final result is an end-to-end prototype that shows how a business excellence team could move from messy source data to cleaner reporting outputs while still preserving transparency around unresolved data quality issues.

## 3. End-to-End Workflow

SQL Server -> Alteryx -> SharePoint -> Power Apps -> Power Automate -> Tableau

## 4. Tool Responsibilities

|      Tool      | Role                                                     |
|:---------------|:---------------------------------------------------------|
| SQL Server     | Raw data storage, profiling, initial rule design         |
| Alteryx        | Exception generation, validation, cleanup, clean outputs |
| SharePoint     | Review queue storage                                     |
| Power Apps     | Exception review interface                               |
| Power Automate | Notification and review lifecycle automation             |
| Tableau        | Data quality and operations dashboards                   |

## 5. Final Workflow Summary

The final prototype follows this workflow:

1. Mock fleet data is generated and loaded into SQL Server.
2. SQL is used for initial profiling, validation, and rule discovery.
3. Alteryx connects to SQL Server and recreates the exception generation logic as a repeatable workflow.
4. Alteryx separates review required exceptions from records that can be cleaned or used for reporting.
5. Review required exceptions are loaded into a SharePoint List.
6. Power Apps provides a review interface for updating status, notes, and assignment.
7. Power Automate sends notifications for new high severity exceptions and stamps resolved records with a resolution timestamp.
8. Tableau presents both data quality health and clean fleet operations reporting.

## 6. Main Deliverables

* Python mock data generation:
    1. `generate_mock_data.py`
    2. `README_generate_mock_data.txt`
* SQL scripts:
    1. `01_create_database.sql`
    2. `02_create_raw_tables.sql`
    3. `03_raw_data_validation.sql`
    4. `04_raw_data_profiling.sql`
    5. `05_create_data_quality_exceptions.sql`
    6. `06_create_clean_vehicle_vendor_views.sql`
    7. `07_create_clean_transaction_views.sql`
* Alteryx workflows:
    1. `fleet_data_quality_exceptions.yxmd`
    2. `data_review_workflow.yxmd`
* Clean CSV outputs:
    1. `vendor_master_clean_alteryx.csv`
    2. `vendor_master_excluded_review_required.csv`
    3. `fleet_condition_assessment_clean_alteryx.csv`
    4. `fleet_condition_assessment_excluded_review_required.csv`
    5. `fuel_transactions_clean_alteryx.csv`
    6. `fuel_transactions_excluded_review_required.csv`
    7. `maintenance_work_orders_clean_alteryx.csv`
    8. `maintenance_work_orders_excluded_review_required.csv`
    9. `vehicle_master_clean_alteryx.csv`
    10. `vehicle_master_excluded_review_required.csv`
* Exception CSV outputs:
    1. `review_required_exceptions_alteryx.csv`
    2. `all_data_quality_exceptions_alteryx.csv`
* SharePoint review queue screenshots:
    1. `01_preview_queue_list.png`
    2. `02_open_review_queue_view.png`
    3. `03_high_severity_queue_view.png`
* Power Apps export & screenshot:
    1. `Fleet Data Quality Review App.msapp`
    2. `01_app_home_review_queue.png`
* Power Automate export & screenshots:
    1. `notify_high_severity_data_quality_exceptions.zip`
    2. `power_platform/power_automate/high_severity_exception_notification/screenshots/`
    3. `notify_high_severity_exceptions.md`
    4. `stamp_resolved_exceptions.zip`
    5. `power_platform/power_automate/stamp_resolved_exceptions/screenshots/`
    6. `stamp_resolved_exceptions.md`
* Tableau dashboard export & screenshots:
    1. `Fleet Operations Snapshot.twbx`
    2. `Fleet_Data_Quality_Command_Center.twbx`
    3. `Fleet Operations Snapshot.pdf`
    4. `Fleet Data Quality Command Center.pdf`

## 7. How to Review the Project

1. Read the project overview and deliverables
2. Review the workflow diagram
3. Inspect SQL/Alteryx logic
4. Review Power Platform screenshots, and if possible, the app/flows.
5. Review Tableau dashboards
6. Read the final lessons learned.

## 8. Key Project Takeaways

Although the project dataset is synthetic, it was able to capture a lot of the potential issues a big organization might have in terms of data maturity and data health. Before starting this project, I was confident in my ability to brush up on SQL, but as I worked through different parts of this project, I came to appreciate the utility of programs like Alteryx, Power Apps, Power Automate and Tableau.

Alteryx made data exploration, profiling, exception generation and cleanup so much easier. The drag and drop ability creates a different kind of modularity that simple SQL queries lack, where you can investigate parts of your workflow, inspect what goes into and out of each block, and branch out from one function to multiple.

Power Apps was more intuitive than I expected. Starting from a SharePoint List created a useful app template that I could then customize for the exception review process. With quick searches, it is possible to implement very specific features and the ability to input a dataset to get back an app template, which is extremely easy to modify, is so interesting.

Power Automate has broad connectivity across Microsoft services. While I generated simple workflow automations, I think in the long run Power Automate would take the center stage in making sure simple code or functions are automated properly and all stakeholders are informed in a timely manner.

Tableau has the ability to present data in a clean way and has convenient functions like feature engineering and is such an intuitive interface to create plots and deliver information by simply dragging fields onto the canvas. I understand that it has the potential to integrate with SQL servers and therefore create a reporting branch in a potential automated system that profiles the data, creates exceptions, cleans up the data, requests reviews for exceptions from business excellence team, and finally reports the results of both the data health and fleet information to the stakeholders.

## 9. Future Improvements

- Connect Alteryx exception outputs directly to SharePoint Lists instead of manually importing CSV files. This would automate the Fleet Data Quality Review Queue list.
- Create a recurring exception generation pipeline, where the Alteryx workflow runs daily or weekly to generate exceptions for cleanup and review.
- Use Power Automate also to notify the person listed in the `assigned_to` field when they are assigned a new issue.
- Use Power Automate to set up an update system that updates the exception tables on the SQL server when an issue is resolved.
- Connect Tableau directly to SQL Server, SharePoint, or a governed data source instead of using uploaded CSV files, which can enable live dashboarding.
- Evolve the project into a closed loop that ingests and profiles the data, creates exceptions on a recurring basis and cleans up the non-exception data for future analysis, and have an outward facing reporting and review interfaces that are all connected seamlessly to each other.
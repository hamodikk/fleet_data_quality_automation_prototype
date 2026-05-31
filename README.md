# Fleet Data Quality Automation Prototype

## Overview

This project is a mock fleet management business excellence prototype. It demonstrates how messy operational data can be profiled, validated, cleaned, routed for review, automated, and visualized using SQL Server, Alteryx, SharePoint, Power Apps, Power Automate, and Tableau.

The project focuses on data integrity, reproducibility, workflow design, and practical business insight.

## Business Problem

The prototype simulates a situation where fleet-related operational data is spread across multiple sources and contains inconsistencies. These issues make it difficult to trust dashboards, reports, and business decisions.

Example data quality issues include:

- Missing vehicle or vendor identifiers
- Duplicate vehicle, vendor, or work order records
- Orphan records that do not match master data
- Inconsistent fuel type, unit, and status labels
- Invalid date logic
- Suspicious MPG and odometer values
- Cost fields that do not reconcile
- Records that require business review instead of automatic correction

## Project Purpose

This project was built to demonstrate initiative, fast learning, analytical thinking, and a structured approach to messy business data. It is not intended to claim production-level expertise in every tool used. Instead, it shows how multiple business tools can work together in an end-to-end data quality workflow.

## Tools Used

- SQL Server / SQL Server Management Studio
- Alteryx
- SharePoint / Microsoft Lists
- Power Apps
- Power Automate
- Tableau
- Python
- Markdown documentation
- Git / GitHub

## End-to-End Workflow

```text
Mock Data Generation
        ↓
SQL Server Raw Data Storage and Profiling
        ↓
SQL Data Quality Rule Discovery
        ↓
Alteryx Exception Generation and Cleanup
        ↓
SharePoint Review Queue
        ↓
Power Apps Exception Review Interface
        ↓
Power Automate Notification and Resolution Flows
        ↓
Tableau Data Quality and Fleet Operations Dashboards
```

## Main Deliverables

**SQL**
* Database setup scripts
* Raw table creation scripts
* Raw data validation and profiling scripts
* Data quality exception creation script
* Clean SQL views for master and transaction table

**Alteryx**
* Exception generation workflow
* Clean output workflow
* Validation outputs comparing Alteryx results against SQL logic
* Clean CSV outputs
* Review-required exception outputs

**Power Platform**
* SharePoint List: Fleet Data Quality Review Queue
* Power Apps review app for exception review and status updates
* Power Automate flow for high-severity exception notifications
* Power Automate flow for stamping resolved exceptions with resolved_at

**Tableau**
* Data Quality Command Center
* Fleet Operations Snapshot

**Documentation**
* Project charter
* Data sources
* Mock dataset design
* Data quality rules
* Assumptions and decisions log
* Daily research log
* Power Platform implementation summary
* Tableau dashboard summary
* Final project overview and deliverables guide

## How to Review This Project

Start with:

1. PROJECT_OVERVIEW_AND_DELIVERABLES.md
2. project_charter.md
3. docs/daily_research_log.md
4. docs/data_quality_rules.md

Then review the tool-specific folders:

1. sql/
2. alteryx/
3. power_platform/
4. tableau/

The exported screenshots and documentation files are included so the project can be reviewed even if the reviewer does not have access to the original SQL Server, Alteryx, Power Apps, Power Automate, SharePoint, or Tableau environments.

## Current Status

The core prototype is complete.

**Completed components include:**

* Mock fleet data generation
* SQL Server ingestion and profiling
* SQL exception logic and clean views
* Alteryx exception generation and clean outputs
* SharePoint review queue
* Power Apps exception review app
* Power Automate notification and resolution timestamp flows
* Tableau dashboards for data quality and fleet operations
* Final project documentation and exported evidence

## Future Improvements

Potential future improvements include:

* Automating the transfer of Alteryx exception outputs directly into SharePoint Lists
* Scheduling Alteryx workflows to run daily or weekly
* Creating Power Automate reminder flows for unresolved high-severity exceptions
* Pushing resolved exception statuses back into SQL Server
* Connecting Tableau directly to SQL Server, SharePoint, or a governed data source
* Creating a fully closed-loop exception management and reporting workflow
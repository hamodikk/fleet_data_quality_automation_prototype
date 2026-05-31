# Project Charter: Fleet Data Quality Automation Prototype

## Project Name

Fleet Data Integrity & Automation Prototype

## Background

This project was created as a mock business excellence analytics prototype for a fleet management environment. The purpose is to simulate a realistic business problem where operational data from vehicles, maintenance work orders, fuel transactions, and vendors is messy, inconsistent, and difficult to trust.

## Business Problem

Fleet operations teams often rely on data from multiple internal and external partners, including mechanics, repair shops, fuel suppliers, and internal departments. When this data is inconsistent or poorly documented, it becomes difficult to answer basic business questions reliably.

Examples of possible issues include inconsistent vehicle IDs, duplicate vendor names, missing values, unclear column definitions, incorrect dates, and conflicting cost fields.

## Project Goal

The goal of this prototype is to build a small, reproducible workflow that profiles, cleans, validates, and analyzes messy fleet-related data. The project will also demonstrate how automation and dashboards can support data quality review and business decision-making.

## Scope

This prototype will include:

- Mock fleet management data
- SQL database storage
- SQL data profiling
- SQL validation and rule discovery
- Alteryx exception generation workflows
- Alteryx validation against SQL results
- Alteryx cleanup for safe standardization
- Data quality exception tracking
- Exception review queue creation
- Review workflow automation using Power Automate
- Exception review interface using Power Apps
- Data quality and operations dashboards using Tableau
- Reproducible documentation

## Out of Scope

This project will not use real company data. It will not claim production-level expertise in the tools. It is intended as a learning prototype and proof of initiative.

## Success Criteria

The project will be considered successful if it can:

- Identify common data quality issues in mock fleet-related data
- Preserve raw source data while creating standardized clean outputs
- Document assumptions, business rules, and data quality decisions
- Use SQL Server for raw data storage, profiling, and rule discovery
- Use Alteryx to recreate exception logic, validate results, and generate clean outputs
- Create a basic exception-review process using SharePoint, Power Apps, and Power Automate
- Present data quality health and clean fleet operations metrics in Tableau
- Be reproduced or reviewed using clear documentation, screenshots, scripts, and exported artifacts
# Power Platform Implementation

## Purpose

The Power Platform portion of this project turns Alteryx generated data quality exceptions into an operational review workflow.

## SharePoint Review Queue

The `review_required_exceptions_alteryx.csv` output from Alteryx was imported into a SharePoint List called `Fleet Data Quality Review Queue`.

This list stores exceptions that require manual review, including issue type, severity, source table, source record ID, suggested action, review status, reviewer notes, and assignment fields.

## Power Apps Review App

A Power Apps canvas app was created from the SharePoint review queue.

The app allows a reviewer to:
- Browse open and resolved exceptions
- Search by issue type or source record ID
- View exception details
- Update review status
- Add reviewer notes
- Assign ownership

Resolved exceptions are pushed to the bottom of the gallery instead of hidden, so reviewers can recover records that may have been marked resolved by mistake.

## Power Automate Notification Flow

A Power Automate cloud flow was created to monitor the SharePoint review queue.

Flow logic:
1. Trigger when a new item is created in the SharePoint list
2. Check whether severity is High and review status is New
3. If yes, send an email notification
4. If no, take no action

The flow was tested with both positive and negative test cases.
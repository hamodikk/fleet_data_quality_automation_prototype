# Power Automate Flow: Notify High Severity Data Quality Exceptions

## Purpose

This flow supports the data quality review process by notifying the reviewer when a new high severity exception is added to the SharePoint review queue.

## Flow Name

`Notify High Severity Data Quality Exceptions`

## Trigger

The flow starts when a new item is created in the SharePoint List:

`Fleet Data Quality Review Queue`

## Logic

The flow checks whether the new exception meets both conditions:

- `severity = High`
- `review_status = New`

If both conditions are true, the flow sends an email notification to the reviewer. If either condition is false, the flow does nothing.

## Inputs

The flow uses fields from the SharePoint review queue, including:

- `issue_type`
- `source_table`
- `source_record_id`
- `severity`
- `review_status`
- `issue_description`
- `suggested_action`

## Output

The flow sends an email notification summarizing the exception and prompting review.

## Business Value

This flow shows how high-priority data quality issues can be routed automatically instead of relying on manual monitoring. It supports a faster response process for exceptions that could affect reporting, downstream automation, or business decision-making.

## Testing Completed

The flow was tested with:

- A positive test where `severity = High` and `review_status = New`, which successfully sent an email.
- A negative test where the exception did not meet the condition, which correctly resulted in no email being sent.

## Notes

This first flow was intentionally kept simple to reduce the risk of duplicate alerts. It triggers only when a new item is created, rather than every time an item is modified.

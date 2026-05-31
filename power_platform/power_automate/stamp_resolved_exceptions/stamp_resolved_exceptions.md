# Power Automate Flow: Stamp Resolved Exceptions

## Purpose

This flow supports the exception review lifecycle by automatically recording when an exception is marked as resolved.

## Flow Name

`Stamp Resolved Exceptions`

## Trigger

The flow starts when an item in the SharePoint List is modified:

`Fleet Data Quality Review Queue`

## Logic

The flow checks whether:

- `review_status = Resolved`
- `resolved_at` is empty

If both conditions are true, the flow updates the item and stamps the `resolved_at` field with the current timestamp.

If the item is not resolved, or if `resolved_at` is already populated, the flow does nothing.

## Inputs

The flow uses fields from the SharePoint review queue, including:

- `review_status`
- `resolved_at`
- `issue_type`
- `source_table`
- `source_record_id`
- `review_notes`

## Output

The flow updates the same SharePoint item by filling in:

- `resolved_at`

## Business Value

This flow creates a lightweight audit trail for exception closure. Reviewers do not need to manually enter the resolution timestamp, and resolved records can be tracked more reliably in the review queue and future dashboard reporting.

## Loop Prevention

Because the flow updates the same item that triggered it, a loop prevention condition is included. The flow only updates `resolved_at` when that field is blank. Once the timestamp has been added, future edits to the same item will not overwrite the original resolved timestamp.

## Testing Completed

The flow was tested with:

- A positive test where an item was changed to `Resolved` and `resolved_at` was automatically populated.
- A negative test where non-resolved status changes did not populate `resolved_at`.
- A safeguard test confirming that an already populated `resolved_at` value was not overwritten.

## Notes

This flow demonstrates how Power Automate can support workflow metadata and auditability, not just notifications.

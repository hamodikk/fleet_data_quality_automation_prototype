# Cleanup Validation

This is a quick, manual quality assurance step to make sure no data was lost in the process of cleanup.

This is useful for checking whether the clean and excluded outputs match/compliment with each other, but it is not an independent validation against the original SQL raw tables.

## Row Count Summary

| Dataset | Raw row count* | Clean row count | Excluded row count | Clean + excluded count | Notes |
|---|---:|---:|---:|---:|---|
| Vehicle Master | 420 | 390 | 30 | 420 | Raw count inferred from attached clean + excluded outputs. |
| Vendor Master | 70 | 61 | 9 | 70 | Raw count inferred from attached clean + excluded outputs. |
| Maintenance Work Orders | 3,783 | 3,473 | 310 | 3,783 | Raw count inferred from attached clean + excluded outputs. |
| Fuel Transactions | 7,460 | 7,116 | 344 | 7,460 | Raw count inferred from attached clean + excluded outputs. |
| Fleet Condition Assessment | 1,424 | 1,271 | 153 | 1,424 | Raw count inferred from attached clean + excluded outputs. |

## Notes

- `First_severity` from Alteryx Summarize is renamed to `severity` in excluded/review-required outputs.
- Vehicle Master: 30 records were separated into the excluded review-required output.
- Vendor Master: 9 records were separated into the excluded review-required output.
- Maintenance Work Orders: 310 records were separated into the excluded review-required output.
- Fuel Transactions: 344 records were separated into the excluded review-required output.
- Fleet Condition Assessment: 153 records were separated into the excluded review-required output.

## Recommended Follow-Up

- Compare the inferred raw counts against the original SQL raw table row counts for final validation.
- Confirm that excluded review-required records are represented in the Power Apps review queue.
- Keep clean outputs and excluded outputs separate so records are not silently dropped from the workflow.
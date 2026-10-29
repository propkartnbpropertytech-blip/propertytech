# 05 — Migration 81 and 82 verification

## What was proven

On the local database, both `trg_a_snapshot_requirement_status` and `trg_z_preserve_requirement_pipeline_status` exist.

A linked requirement and lead were updated inside a transaction:

- Requirement status set to Follow-up, then the lead was set to stage `SALES`, allocation `HANDED_TO_SALES`, and direct-sales allocation.
- The requirement status was still Follow-up.
- The same sequence with Interested still returned Interested.

The transaction was rolled back. No row was left changed.

Migration 82 replaces `fn_sync_leads_to_requirements` and does not drop the preserve trigger. Its update keeps an existing non-reject status. A rejected requirement that is newly moved to stage `SALES` under direct sales is still rewritten to Assigned to Sales. That is the behavior written in migration 82, not a bypass of the preserve trigger for Follow-up or Interested.

## Test

`test/migration.status.preserve.test.js` passed.

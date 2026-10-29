# 04 — Allocation concurrency remediation

## Cause

`allocate_waiting_leads` and `allocate_old_untouched_leads` locked the lead (`FOR UPDATE SKIP LOCKED`) and used a workload count from the start of the scan. Two transactions could both see free capacity for the same telecaller.

## Fix

In both telecaller loops, after the capacity snapshot, the function locks that telecaller's `telecaller_availability` row and recounts active leads before assigning. If the live count is at `max_capacity`, the loop moves to the next telecaller. The second transaction blocks on the row lock until the first commits, then sees the new count.

Enqueue failures now throw `ALLOCATION_ENQUEUE_FAILED` instead of returning `{ allocated: [] }`. The ingest callers already catch that error and log it. The lead row is still saved before allocation is attempted.

## Tests

The migration source contains the lock and the recount in both loops.
Two database sessions: the second `FOR UPDATE` on the same availability row timed out with SQLSTATE 57014 while the first transaction held the lock. The transactions were rolled back. No lead was assigned by this test.

A capacity of N with N+X concurrent `allocate_waiting_leads` calls was not executed against live leads, because that would assign real rows.

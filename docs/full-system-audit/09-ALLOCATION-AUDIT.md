# 09 — Allocation Audit

## What the code does

Enqueue then `allocate_waiting_leads` inside one database transaction. Waiting leads are taken with `SKIP LOCKED`. Active telecallers exclude `INACTIVE` and `LOGGED_OUT`. Choice is round-robin by `last_allocated_at`. Direct sales uses least current workload. History rows are written for the allocation type allowed by migration 80.

## Concurrency

The lead row is locked. The telecaller row is not. Two sessions can both count the telecaller under capacity and both assign. The JavaScript capacity set is wider than the SQL count, so the two checks can disagree.

## Idempotency and failure

A duplicate enqueue is meant to no-op. Errors from enqueue have been seen returned as an empty allocated list, which looks like success with no work. That path was not re-run.

## Scenarios not executed

1 lead / 1 telecaller, many-to-many, simultaneous ingest, telecaller offline mid-flight, reject, retry, duplicate request, and network drop. Status: `NOT TESTABLE`.

## Authorization

Allocation endpoints sit behind authenticate and role checks. A cross-tenant call was not attempted.

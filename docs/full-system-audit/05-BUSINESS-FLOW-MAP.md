# 05 — Business Flow Map

These are the chains the code implements. Only the requirement-status chain has a local database proof.

## Property to match to lead

Property create writes PostgreSQL, then invalidates the KPI cache for that organization. Match evaluation is a server service on `GET/POST /requirements/:id/matches`. The Flutter matcher can also score locally with different budget bands. A match does not by itself create and allocate a lead in one transaction.

## Lead ingestion

Source to validation to dedup to insert to allocation queue to telecaller. Phone is not a unique constraint. External id is. Dedup is check-then-insert.

## Allocation

`enqueue_lead_for_allocation` then `allocate_waiting_leads` in one SQL transaction. Telecaller choice is round-robin by `last_allocated_at` among active telecallers. Sales choice is least direct-sales workload. Waiting rows use `SKIP LOCKED`. The telecaller row itself is not locked, so two concurrent allocations can pass a capacity check together.

## Requirement status

A lead update runs `fn_sync_leads_to_requirements`. Migration 81 snapshots the requirement status and an AFTER trigger restores a pipeline status that the sync would otherwise replace with Assigned. Migration 82 replaces the forward function and sets Assigned to Sales for direct sales. It does not drop the preserve trigger. The local database proof was run with 81 applied and 82 not loaded into that container.

## Won, lost, site visit, follow-up

Requirement status changes map to lead stage and allocation status in the requirements repository, then the service reasserts the requirement status after site-visit sync. KPI cache is invalidated from the returned row's organization.

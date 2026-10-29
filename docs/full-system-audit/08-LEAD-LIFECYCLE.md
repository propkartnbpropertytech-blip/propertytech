# 08 — Lead Lifecycle

States below are the ones constrained or written by the code. They are not one single state machine.

## Lead stage (`chk_leads_stage`)

`NEW`, `QUALIFICATION`, `INTERESTED`, `SALES`, `SITE_VISIT`, `NEGOTIATION`, `WON`, `LOST`, `CLOSED`, `LISTED`, `ARCHIVED`.

## Allocation status

`UNASSIGNED_WAITING`, `ASSIGNED_TO_TELECALLER`, `ASSIGNED_TO_SALES`, `DIRECT_SALES`, `HANDED_TO_SALES`, `IN_CALL`, `CNR`, `CALLBACK`, `FOLLOWUP`, `PICKED_UP`, `LEGACY_UNALLOCATED`, `ARCHIVED`, `LISTED`, `RELEASED`.

## Requirement status used by the salesperson dropdown

`New`, `Assigned`, `Not Started`, `Follow-up`, `Re-Followup`, `Interested`, `Site Visit`, `Site Visit Done`, `Negotiation`, `Won`. The column has no check constraint. The UI also displays Assigned and Assigned to Sales as "Assigned to Sales".

## Mapping that the repository writes

| Requirement status | Lead stage | Allocation status |
| :--- | :--- | :--- |
| Visit | `SITE_VISIT` | `HANDED_TO_SALES` |
| Follow-up | `INTERESTED` | `FOLLOWUP` |
| Negotiation | `NEGOTIATION` | `HANDED_TO_SALES` |
| Interested | `INTERESTED` | `HANDED_TO_SALES` |
| Assigned / Not Started | `SALES` | `HANDED_TO_SALES` |
| New | `NEW` | unchanged by that branch |

Follow-up therefore stores stage `INTERESTED` while the requirement row says Follow-up. That is a real vocabulary split.

## Proven transition

On the local database after migration 81, Interested survived a lead update to stage `INTERESTED`, and Follow-up survived a lead update to stage `SALES` with direct-sales allocation. The transaction was rolled back. Invalid transitions were not rejected: `_isValidStatusTransition` returns true.

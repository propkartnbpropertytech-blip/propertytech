# 18 — Data Consistency Audit

| Flow | UI | API | Database | Cache | Audit | Verdict |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| Requirement status after lead sync | Flutter keeps a non-assigned choice over Assigned | Repository reasserts status | Migration 81 preserve trigger. Proven locally, then rolled back | KPI cache invalidated after reassert | Not read | PARTIAL |
| Direct-sales status if migration 82 is applied | Same UI rule | Same reassert | 82 rewrites the forward function and does not drop the preserve trigger. Not re-proven together | Same | Not read | PARTIAL |
| Match score | Client formula | Server formula | Server reads PostgreSQL | Threshold also in SharedPreferences | None | FAIL for a single definition |
| KPI numbers | Not compared | Not compared | Not compared | Not compared | Not compared | NOT TESTABLE |
| Live Excel vs database | Not downloaded | Scoped after this fix | Not compared | n/a | n/a | NOT TESTABLE |
| Allocation ownership | Not clicked | Code writes history | Not queried | n/a | Not queried | NOT TESTABLE |

The local status proof is the only row with a database observation in this audit cycle.

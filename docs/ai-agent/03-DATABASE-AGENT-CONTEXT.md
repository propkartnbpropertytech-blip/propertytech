# 03 — DATABASE AGENT CONTEXT & RELATIONAL GOVERNANCE

## 1. Single Authoritative Source of Truth
PostgreSQL 16 (`public` schema) is the sole authoritative store of truth for all business entities in the PropKart platform:
- Primary entities: `properties`, `leads`, `requirements`, `users`, `organizations`, `site_visits`, `audit_logs`.
- Multi-tenancy: Every business table enforces an `organization_id` column, indexed foreign key, and Row-Level Security (RLS) policies.

## 2. Core Entities & Relational Schema Map

| Table Name | Primary Key | Key Relationships | Multi-Tenant Key | Role & Invariants |
| :--- | :--- | :--- | :--- | :--- |
| `public.organizations` | `id` (UUID) | Root tenant entity | `id` | Tenant boundary; isolating tenant workspaces. |
| `public.users` | `id` (UUID) | Belongs to `organizations` | `organization_id` | RBAC: Super Admin, Admin, Sales, Telecaller. |
| `public.properties` | `id` (UUID) | Created by `users`, belongs to `organizations` | `organization_id` | Property inventory; supports status transitions and soft-deletion (`deleted_at`). |
| `public.leads` | `id` (UUID) | Assigned to `users`, belongs to `organizations` | `organization_id` | Core lead entity (Meta, Housing, Webhook, Manual). |
| `public.requirements` | `id` (UUID) | Linked to `leads`, belongs to `organizations` | `organization_id` | Client requirements, budget, location preferences. |
| `public.site_visits` | `id` (UUID) | References `leads`, `properties`, `users` | `organization_id` | **Immutable operational ledger** of site visits conducted. |
| `public.lead_call_attempts`| `id` (UUID) | References `leads`, `users` | `organization_id` | **Immutable historical log** of telecaller call attempts. |
| `public.audit_logs` | `id` (UUID) | References `users`, `organizations` | `organization_id` | Append-only compliance trail recording state mutations. |

## 3. Historical Event Immutability (`INV-002`)
A completed business event (such as a conducted Site Visit or executed Call Attempt) is an immutable historical fact:
- **`site_visits` table:** Never delete or decrement rows when a lead is subsequently archived, reassigned, or lost. The count of site visits done must always query `public.site_visits WHERE status = 'Completed'` (or canonical equivalent), NOT mutable columns on `leads`.
- **`audit_logs` table:** Append-only ledger. Truncation or deletion of audit logs is strictly forbidden.

## 4. Migration Rules & Database Discipline
- All migrations reside in `sql/migrations/` and must be strictly additive (`CREATE TABLE IF NOT EXISTS`, `ADD COLUMN IF NOT EXISTS`, `CREATE INDEX IF NOT EXISTS`).
- Every new migration must be registered in `ADDITIVE_MIGRATIONS` in `src/config/ensureAdditiveSchema.js`.
- Destructive statements (`DROP TABLE`, `DROP COLUMN`) are strictly prohibited in production.

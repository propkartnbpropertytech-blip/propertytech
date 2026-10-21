# 05 — AUTHORIZATION & ROLE-BASED ACCESS CONTROL (RBAC)

## 1. Role Hierarchy & Principles

PropKart enforces a 4-tier Role-Based Access Control hierarchy:

```text
       ┌────────────────────────┐
       │      Super Admin       │  (Global multi-tenant platform owner)
       └───────────┬────────────┘
                   │
       ┌───────────▼────────────┐
       │         Admin          │  (Organization tenant administrator)
       └───────────┬────────────┘
                   │
         ┌─────────┴─────────┐
         ▼                   ▼
┌─────────────────┐ ┌─────────────────┐
│      Sales      │ │   Telecaller    │  (Operational team roles)
└─────────────────┘ └─────────────────┘
```

---

## 2. Definitive Role Permission Matrix

| Feature / Action | Super Admin | Admin | Sales | Telecaller | Enforcement Location |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Manage Multi-Tenant Organizations** | **YES** | NO | NO | NO | `assertRoleBoundary` (Backend) |
| **View System Audit Logs** | **YES** | NO | NO | NO | `RoleGuard.canViewAuditLogs` + Backend |
| **Assign/Create Admin Accounts** | **YES** | NO | NO | NO | `RoleGuard.canAssignAdminRole` + Backend |
| **Manage Organization Roster (Users)** | **YES** | **YES** | NO | NO | `RoleGuard.canManageEmployees` + Backend |
| **Reassign Leads Across Agents** | **YES** | **YES** | NO | NO | `assertLeadTeamBoundary` (Backend) |
| **Manage Cities / Areas Lookups** | **YES** | **YES** | **YES** | NO | `RoleGuard.canManageLookups` + Backend |
| **Access Telecaller Qualified Leads** | **YES** | **YES** | NO | **YES** | `TeamUserVisibility` + Backend |
| **Update Own Assigned Leads/Requirements** | **YES** | **YES** | **YES** | **YES** | `assertLeadTeamBoundary` (Backend) |
| **View Organization Authoritative KPIs** | **YES** | **YES** | Scoped | Scoped | `KpiService` + Tenant Middleware |
| **View All Tenant Properties** | **YES** | **YES** | **YES** (Global) | **YES** (Global) | UI Hides Creator details |

---

## 3. Super Admin Invariant Safeguards

1. **Immutable Maximum Permissions**:
   - Super Admin holds 100% active permissions across all modules at all times.
   - Calling dynamic revocation APIs (`PATCH /super-admin/feature-permissions/role`) targeting Super Admin fails closed.
2. **Account Protection**:
   - Super Admin accounts cannot be edited, downgraded, or deleted by standard Admins.
   - Attempts to pass `is_super_admin: true` during self-update or standard admin creation are stripped via allowlists.

---

## 4. Sales & Telecaller Boundary Isolation

1. **Lead Reassignment Restrictions**:
   - Sales agents cannot reassign a lead to another sales agent.
   - Telecallers cannot reassign a lead to another telecaller.
   - Both violations throw `ArchitecturalViolationError` (`REASSIGNMENT_RESTRICTED`).
2. **User Enumeration & Roster Protection**:
   - Sales users cannot access team roster filter endpoints (`TeamUserVisibility.canUseFilter('Sales') == false`).
   - Telecallers can only see Sales agents to whom leads can be transferred; they cannot enumerate or view other telecallers.
3. **Property Visibility vs. Ownership**:
   - Properties are globally visible across an organization to allow brokerage agents to sell inventory.
   - However, internal creator names and phone numbers are hidden from peer sales reps in the UI to prevent customer poaching.

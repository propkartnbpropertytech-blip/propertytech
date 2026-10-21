# 07 — INSECURE DIRECT OBJECT REFERENCE (IDOR / BOLA) PREVENTION

## 1. Overview & Risk Profile

Broken Object Level Authorization (BOLA / IDOR) occurs when an application exposes internal object identifiers (such as `/properties/:id` or `/leads/:id`) and fails to verify that the requesting user has legitimate ownership and tenant authority to access or mutate that specific object.

---

## 2. Multi-Tiered IDOR Protection Model

Every resource access request in PropKart must pass three sequential authorization layers:

```text
Request: GET/PUT/DELETE /resource/:id
                   │
                   ▼
       [Layer 1: Authentication]
   Valid JWT, unexpired, trusted issuer
                   │
                   ▼
     [Layer 2: Tenant Authorization]
   Resource organization_id == User organization_id
                   │
                   ▼
 [Layer 3: Resource Ownership / Role RBAC]
   User has assigned ownership OR holds Admin/Super Admin role
                   │
                   ▼
               PERMIT
```

---

## 3. Resource IDOR Audit Matrix

| Resource | Identifier Type | Tenant Verification | Ownership / Role Check | IDOR Prevention Status |
| :--- | :---: | :---: | :---: | :---: |
| **Properties** | UUID (`id`) | Mandatory `organization_id` filter | Global tenant visibility; edit/delete limited to creator or Admin | **SECURED** |
| **Leads & Requirements** | UUID (`id`) | Mandatory `organization_id` filter | Sales scoped to `assigned_to`; Telecaller scoped to `assigned_telecaller_id` | **SECURED** |
| **Followups** | UUID (`id`) | Mandatory `organization_id` filter | Limited to lead owner or Admin | **SECURED** |
| **Site Visits** | UUID (`id`) | Mandatory `organization_id` filter | Limited to assigned agent or Admin | **SECURED** |
| **User Profiles** | UUID (`id`) | Mandatory `organization_id` filter | Self-update allowlist; Admin can only manage subordinate roles | **SECURED** |
| **Sessions** | UUID / SHA-256 | Bound to user ID | User can only revoke own session; Admins can revoke organization sessions | **SECURED** |
| **Audit Logs** | UUID (`id`) | Super Admin boundary | Only Super Admin can access audit log entries | **SECURED** |

---

## 4. Specific Attack Test Scenarios

### Scenario 1: Tenant A User requests Tenant B Property ID
- **Input**: User in Org A sends `GET /api/v1/properties/3fa85f64-5717-4562-b3fc-2c963f66afa6` (belonging to Org B).
- **Result**: PostgreSQL query includes `AND organization_id = 'org-a'`. No row returned. Endpoint returns HTTP 404 NOT FOUND. Zero information leaked.

### Scenario 2: Sales Agent A attempts to reassign Lead of Sales Agent B
- **Input**: Sales User A sends `PUT /api/v1/leads/:id` with `assigned_to = sales_user_c`.
- **Result**: `assertLeadTeamBoundary` intercepts mutation before SQL execution, identifying that `caller.id !== lead.assigned_to` and throwing `REASSIGNMENT_RESTRICTED`. HTTP 403 Forbidden.

### Scenario 3: Telecaller attempts to enumerate peer Telecallers
- **Input**: Telecaller requests user roster.
- **Result**: `TeamUserVisibility.visibleTelecallerUsers` returns empty array. User enumeration blocked.

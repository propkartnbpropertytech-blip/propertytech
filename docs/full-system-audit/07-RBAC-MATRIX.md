# 07 — RBAC Matrix

Generated from `rolePermissions` and route middleware. Broker is not a key in `rolePermissions`. The control matrix seeds Broker like Admin, so Broker API rights depend on feature overrides. An empty override list means no API permission.

UI hiding is listed separately from the API. A hidden button is not the security boundary.

| Capability | Super Admin | Admin | Broker | Telecaller | Sales | Backend evidence |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| View property | Yes | Yes | Override only | Limited | Limited | Controller checks organization after load |
| Create property | Yes | Yes | Override only | No | No | Permission middleware |
| Edit property | Yes | Yes | Override only | No | Own or team | `checkTeamAccess` |
| Delete property | Yes | Yes | Override only | No | No | Permission middleware |
| View lead / requirement | Yes | Yes | Override only | Own queue | Own pipeline | Service filters |
| Change requirement status | Yes | Yes | Treated like sales in parts of the UI | Blocked in the requirements screen | Yes | API must still enforce. Not re-tested live |
| Assign / reassign lead | Yes | Yes | Override only | No | No | Allocation service |
| View KPI | Yes | Yes | UI sometimes follows sales | Own | Own | Canonical queries are role-scoped in code |
| View reports | Yes | Yes | UI guard | UI guard | UI guard | Several report routes are authenticate-only |
| Export live Excel | Token or JWT, one organization required | Same | Same | Same | Same | Fixed in this audit. Not a role check |
| Manage users | Yes | Yes | No | No | No | Permission middleware |
| Change match threshold | Yes | Config permission | No | No | No | Config route |
| View audit logs | Yes | Limited | No | No | No | Audit routes |

This matrix was not executed as five logged-in sessions. Status of the live matrix: `NOT TESTABLE`.

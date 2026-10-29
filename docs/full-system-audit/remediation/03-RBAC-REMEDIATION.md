# 03 — RBAC remediation

## Cause

`rolePermissions` had Super Admin, Admin, Telecaller, and Sales. Broker fell through to an empty list, so API checks denied the workspace owner. The control service already treated Broker like a tenant admin rather than staff.

## Fix

Broker receives the same permission set as Admin. That includes property, requirement, user, and report operations inside the caller's organization. Broker does not receive `permissions.manage`, `config.manage`, `users.manage_admins`, `users.manage_access`, `ops.backup`, or `health.detailed`.

Broker may update the match threshold for their team. Report and export routes still require the specific permission, not merely a session.

## Tests

`test/permissions.telecaller.test.js`: Broker has the workspace keys and does not have the platform keys. Sales does not have `reports.read`.

No logged-in Broker session was executed against the HTTP server.

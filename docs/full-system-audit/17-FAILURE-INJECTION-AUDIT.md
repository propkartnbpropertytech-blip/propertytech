# 17 — Failure Injection Audit

| Failure | Result |
| :--- | :--- |
| Missing sheet token configuration | Rejected by `resolveSyncAccess` when the request does not carry a valid JWT. Covered by the unit test for the old published token |
| Forged JWT with the old fallback secret | Rejected. Unit test passed |
| Missing `organization_id` on the feed | `scopeSyncOrganization` returns 400. Unit test passed |
| Conflicting JWT and query organization | Returns 403. Unit test passed |
| Database unavailable | Not injected |
| Redis unavailable | Not injected |
| Offline client | Not injected |
| Duplicate allocation | Not injected |
| Constraint violation | Not injected |

Status of the uninjected rows: `NOT TESTABLE`.

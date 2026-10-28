# 10 — Security Regression Testing & Boundary Verification

## 1. Scope & Security Objectives

PropKart processes proprietary commercial real estate data, high-value client budgets, and agent performance statistics. All security controls established in **Step 10 (Security Hardening)** must be guarded against regressions through continuous automated test suites.

---

## 2. Multi-Tenant Isolation & IDOR Defense

Cross-tenant data exposure and Insecure Direct Object References (IDOR) represent severe security risks. Automated security suites continuously verify tenant containment:

### 2.1 IDOR Prevention Matrix
- Given Tenant A with Lead $L_A$, and Tenant B with Lead $L_B$:
  - When Tenant A issues `GET /api/v1/leads/{L_B.id}`, the backend must respond with `404 Not Found` (preferred to avoid revealing entity existence) or `403 Forbidden`.
  - When Tenant A issues `PUT /api/v1/leads/{L_B.id}` with a payload attempting to reassign or delete $L_B$, the database update must affect 0 rows and return `404 Not Found`.

```javascript
describe('Security Regression - IDOR & Cross-Tenant Boundary', () => {
  it('prevents Tenant A from fetching lead belonging to Tenant B', async () => {
    const res = await request(app)
      .get(`/api/v1/leads/${tenantBLeadId}`)
      .set('Authorization', `Bearer ${tenantAUserToken}`);

    assert.strictEqual(res.status, 404);
    assert.strictEqual(res.body.success, false);
  });
});
```

---

## 3. RBAC Privilege Boundary Testing

Role-Based Access Control (RBAC) boundaries are validated for every role in the PropKart hierarchy:

| Role | Permitted Actions | Strictly Prohibited Actions (Tested with 403) |
|:---|:---|:---|
| **SuperAdmin** | Global platform config, tenant provisioning, system health | Viewing unmasked tenant PII without audit log flag. |
| **TenantAdmin**| Tenant user management, team configuration, billing | Cross-tenant access, system-level infrastructure controls. |
| **SalesManager**| Team pipeline management, lead assignments, KPI reports | Deleting users, changing billing tiers, system settings. |
| **FieldAgent** | Assigned leads, site visits, client requirements, property catalog | Reassigning others' leads, exporting lead database. |
| **Telecaller** | Assigned call queue, logging call outcomes, basic lead notes | Direct property ownership lookup, bulk data export, team KPIs. |

### 3.1 Telecaller Boundary Verification Suite
The dedicated test file `test/telecaller_boundary_verification.test.js` strictly asserts that telecaller accounts:
1. Cannot access raw owner phone numbers (only masked or click-to-call proxy endpoints).
2. Cannot view leads outside their assigned campaign batch.
3. Cannot perform bulk CSV/Excel exports (`POST /api/v1/reports/export` returns 403).

---

## 4. Authentication & Token Security Tests

### 4.1 JWT Signature & Algorithm Forgery
- Tests craft tampered tokens with `alg: "none"` or symmetric key HMAC substitutions and assert that authentication middleware rejects the token with `401 Unauthorized`.
- Expired tokens (`exp` in the past) are rejected with a standardized `TOKEN_EXPIRED` error code.

### 4.2 Refresh Token Rotation (RTR)
- Every refresh token exchange yields a new access token and a new refresh token.
- Reusing an already-consumed refresh token triggers immediate invalidation of the entire token family (compromise detection) and revokes all active sessions for that user.

---

## 5. Input Sanitization & Injection Defense

### 5.1 SQL Injection Resistance
- Automated test suites fuzz query parameters with SQL injection payloads (`' OR 1=1 --`, `'; DROP TABLE leads; --`, `UNION SELECT`).
- All queries must be strictly parameterized via query builders or prepared statements. Fuzzing results must yield either valid filtered results or 422 validation errors, never raw database syntax exceptions.

### 5.2 File Upload & Path Traversal Prevention
- The bulk user upload endpoint (`test/users.upload.test.js`) is tested with:
  - Filenames containing path traversal characters (`../../etc/passwd`).
  - Corrupt or oversized CSV payloads (> 10MB).
  - Malicious CSV formulas (`=CMD('calc.exe')`).
  - All files are parsed in memory or strictly written to isolated temporary storage with generated UUID filenames.

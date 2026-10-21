# 02 — THREAT MODEL

## 1. Methodology & Scope

The PropKart threat model applies the **STRIDE** methodology (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) across all primary assets, threat actors, and communication channels.

---

## 2. Protected Assets

| Asset Category | Specific Entities | Impact of Breach | Confidentiality | Integrity | Availability |
| :--- | :--- | :--- | :---: | :---: | :---: |
| **Authentication Secrets** | Password hashes, JWT secrets, session keys | Account takeover, impersonation | **CRITICAL** | **CRITICAL** | HIGH |
| **Tenant Data** | Organization records, billing, settings | Cross-tenant contamination | **CRITICAL** | **CRITICAL** | HIGH |
| **Customer PII** | Leads, client names, phone numbers, budgets | Privacy regulatory breach | **CRITICAL** | HIGH | MEDIUM |
| **Property Inventory** | Real estate listings, owner mobile numbers | Commercial data leakage | HIGH | HIGH | HIGH |
| **Operational Transactions** | Requirements, followups, site visits, deals | Disrupted sales pipelines | HIGH | **CRITICAL** | HIGH |
| **Authoritative KPIs** | Executive reports, revenue conversions | Fraudulent metrics, false reporting | HIGH | **CRITICAL** | HIGH |
| **Audit Records** | Security logs, mutation history, login logs | Loss of non-repudiation | HIGH | **CRITICAL** | MEDIUM |

---

## 3. Threat Actors

1. **External Unauthenticated Attacker**: Remote adversary attempting credential stuffing, brute-forcing auth endpoints, probing for open redirects, or executing SSRF.
2. **Malicious Authenticated Low-Privilege User (Sales/Telecaller)**: Legitimate tenant user attempting IDOR attacks, horizontal privilege escalation into peer records, or vertical privilege escalation into administrative functions.
3. **Cross-Tenant Adversary**: Competitor or malicious tenant user attempting to view or manipulate data belonging to another brokerage/organization on the shared platform.
4. **Compromised Account / Stolen Token**: Attacker possessing a leaked access or refresh token attempting session reuse or unauthorized replay of outbox operations.
5. **Automated Abuse Bot**: Automated scrapers or bots attempting to exhaust API rate limits, flood SMS/OTP/Captcha gateways, or trigger cache stampedes.

---

## 4. STRIDE Threat Matrix & Mitigations

### 4.1 Spoofing (Identity Impersonation)
- **Threat**: Forging JWT tokens with arbitrary `role` or `organization_id` claims, or using algorithm `none`.
- **Mitigation**: Backend uses strict HMAC-SHA256 signature verification with dedicated secrets, rejects algorithm confusion, and independently validates user identity and organization context against PostgreSQL.
- **Verification**: Verified in `test/security/backend_security_matrix.test.js` and `test/api/security.contract.test.js`.

### 4.2 Tampering (Data Manipulation)
- **Threat**: Mass assignment attacks injecting `organization_id`, `created_by`, `admin_id`, or `is_verified` during property or requirement mutations.
- **Mitigation**: Strict allowlisting via `pickPropertyFields`, `pickRequirementFields`, `pickAllowedFields`, and Zod schemas. Any unwhitelisted parameters are stripped before persistence.
- **Verification**: Verified in `test/payload.validation.hardening.test.js` and `test/security/mass_assignment_test.dart`.

### 4.3 Repudiation (Disavowal of Actions)
- **Threat**: Users denying having modified customer contacts, assigned leads, or deleted properties.
- **Mitigation**: Dedicated immutable audit logging via `logSecurityEvent`, recording timestamp, actor ID, action type, IP address, and correlation `X-Request-Id`.
- **Verification**: Verified in `test/audit.telemetry.test.js`.

### 4.4 Information Disclosure (Data Leakage)
- **Threat**: SQL syntax errors or database relation errors leaking internal table names and stack traces to API clients; or Sales users viewing properties exposing private creator phone numbers.
- **Mitigation**: Standardized Step 8.4 API envelope masking all raw exceptions; client-side `TeamUserVisibility` hiding creator identities from unauthorized roles.
- **Verification**: Verified in `test/security/error_sanitization_test.dart` and `test/security/property_visibility_demo_test.dart`.

### 4.5 Denial of Service (Resource Exhaustion)
- **Threat**: Excessive unauthenticated login attempts, large pagination requests (`limit=50000`), or oversized file uploads.
- **Mitigation**: `paginationGuard` capping queries to 100 records; file upload size ceilings (10MB); account lockout service blocking IPs/accounts after repeated failures.
- **Verification**: Verified in `test/api/security.contract.test.js` and `test/security/file_security_test.dart`.

### 4.6 Elevation of Privilege (Unauthorized Authority)
- **Threat**: Sales or Telecaller user creating Admin accounts or viewing Super Admin audit logs.
- **Mitigation**: Strict dual-layer checks (`RoleGuard` on frontend and `assertRoleBoundary` / `effectivePermissions` on backend). Super Admin privileges are hard-locked and cannot be delegated or revoked.
- **Verification**: Verified in `test/security/telecaller_role_test.dart`, `test/security/rbac_test.dart`, and `test/rbac.team.isolation.test.js`.

# 17 — SECURITY LOGGING, TELEMETRY & AUDIT MONITORING

## 1. Security Event Taxonomy

All security-sensitive operations trigger structured telemetry through `logSecurityEvent()` (`src/security/events.js`):

| Event Type | Severity | Trigger Condition | Logged Payload Details |
| :--- | :---: | :--- | :--- |
| `auth_login_success` | INFO | User successfully logs in | `userId`, `organizationId`, `ip`, `userAgent`, `timestamp` |
| `auth_login_failure` | WARN | Password mismatch or invalid email | Attempted email (sanitized), `ip`, `userAgent`, `failureCount` |
| `refresh_reuse_or_invalid` | **HIGH** | Reuse of rotated refresh token | Stolen token hash, `userId`, `ip`, `familyId` |
| `tenant_isolation_violation` | **CRITICAL** | User attempted cross-tenant access | `userId`, `userOrgId`, `targetResourceOrgId`, `endpoint` |
| `team_boundary_violation` | **HIGH** | Unauthorized lead reassignment attempt | `callerId`, `callerRole`, `leadId`, `targetAssigneeId` |
| `banned_table_query` | **CRITICAL** | Query attempted on dropped/shadow table | `tableName`, `callerFile`, `stackTrace` |
| `rate_limit_exceeded` | WARN | Endpoint rate limit breached | `ip`, `endpoint`, `attemptCount` |

---

## 2. Redaction & Privacy Invariants

To comply with enterprise privacy requirements:
1. **Zero Secret Logging**:
   - `SecureLog.redact()` on Flutter and logger formatting middleware strip Bearer tokens, JWT strings, and passwords.
2. **Correlation ID (`X-Request-Id`)**:
   - Every incoming HTTP request is assigned or validated against an RFC 4122 UUID v4.
   - All logs, errors, and database telemetry attach the `requestId` for end-to-end tracing without disclosing internal database row states.

---

## 3. Monitoring & Alerting Integrations

- Server errors are monitored via Sentry / GlitchTip.
- Security-critical events (`CRITICAL` severity) trigger alerts in operational dashboards.
- Audit logs are accessible strictly to Super Admin via `/api/v1/audit/logs`.

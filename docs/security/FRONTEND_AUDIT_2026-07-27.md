# PropKart Frontend Security Audit & Hardening

**Date:** 2026-07-27  
**Scope:** Flutter client (`C:\NB\propkart`)  
**Companion:** Backend hardened separately (`PropKart-Backend`)

---

## Executive summary

Prior client patches (session cleanup, 401 logout, `/users` route guard) were extended with refresh-token support, Realtime lockdown, audit RBAC, redirect allowlisting, PII cache redaction on web, and secure logging.

**Client risk after this pass:** Medium — true enforcement remains on the API; Supabase RLS must still deny cross-tenant Realtime.

---

## Findings fixed this pass

| ID | Severity | Finding | Fix |
|----|----------|---------|-----|
| F1 | Critical | Realtime joined entire `public` schema before login | Connect only after auth; table allowlist |
| F2 | High | Refresh token ignored; logout local-only | Persist refresh; `/auth/refresh` + `/auth/logout` |
| F3 | High | Sales could deep-link `/settings/audit-logs` | Router + UI RoleGuard |
| F4 | High | `?from=` open privilege redirect | Allowlist via `RoleGuard.sanitizeRedirectPath` |
| F5 | High | JWT sent on public share endpoints | Interceptor skips Authorization |
| F6 | Medium | Web prefs cached owner/client phones | Redacted on web write |
| F7 | Medium | Placeholder `broker@nbrealty.com` in shell | Empty / shrink when unauthenticated |
| F8 | Medium | UsersBloc lacked RoleGuard | Wired AuthBloc + RoleGuard on mutations |
| F9 | Medium | Password in LoginSubmitted.props | Removed from props |
| F10 | Low | Unredacted debug logs | `SecureLog` + kDebugMode gates |

---

## Remaining risks (server / ops)

1. Supabase **RLS** must deny anon Realtime for other orgs’ rows (client filters are not enough).
2. Rotate Supabase anon key if RLS was ever weak; prefer `--dart-define` in CI.
3. Web remember-me still uses browser storage (not OS keychain) — XSS risk residual.
4. Backend must reject Sales on audit endpoints even if UI is bypassed.

---

## Verification

```bash
flutter test test/security/
```

Manual:
1. Login Sales → `/settings/audit-logs` redirects to dashboard.
2. Login A → logout → login B: no A email/data.
3. Expire access token with valid refresh → silent refresh (no forced logout).
4. Public `/share/...` network tab: no `Authorization` header.

# PropKart Security Audit Report

**Date:** 2026-07-25  
**Scope:** Flutter client (`C:\NB\propkart`). Backend is external (`prop-kart-backend.vercel.app`) — server RBAC must be verified separately.  
**Algorithm note:** Migrating HS256→RS256 is **not** required for this client. User JWTs are opaque Bearer tokens; algorithm choice is a **server** concern. Prefer RS256 only if multiple services must verify tokens without sharing a secret.

---

## 1. Vulnerability Summary

| ID | Severity | Finding | Status |
|----|----------|---------|--------|
| C1 | **Critical** | Logout did not clear Isar / web memory / outbox / prefs — cross-user data leak | **Patched** |
| C2 | **Critical** | `rememberMe: false` left previous JWT on disk | **Patched** |
| H1 | **High** | Shell showed `broker@nbrealty.com` during AuthLoading/Initial | **Patched** |
| H2 | **High** | Router allowed protected routes during AuthLoading/Initial | **Patched** |
| H3 | **High** | No Dio 401 → session kill | **Patched** |
| H4 | **High** | Requirements `_hasEditAccess` always returned `true` | **Patched** |
| H5 | **High** | `/users` routable by any authenticated role (UI hide only) | **Patched** (client route guard) |
| M1 | **Medium** | Dashboard placeholder `admin@nbdeveloper.com` | **Patched** |
| M2 | **Medium** | SyncManager not disconnected on logout | **Patched** |
| M3 | **Medium** | Embedded Supabase anon key + broad Realtime `public` join | Remaining (RLS must be server-side) |
| S1 | **Server** | Admin create/update/delete RBAC | **Must verify on backend** — client RoleGuard is defense-in-depth only |
| S2 | **Server** | IDOR / org isolation on properties & requirements | **Must verify on backend** |

---

## 2. Root Causes

### Stale email (`broker@nbrealty.com`)
Not Isar user cache. Hardcoded placeholder in `app_shell.dart` when `AuthBloc` was not `Authenticated`, combined with router allowing the shell during `AuthLoading` / `AuthInitial`.

### Cross-user data after login switch
`AuthRepository.logout()` only deleted the token. Isar collections, web `inMemory` maps, SharedPreferences caches, outbox, and `SyncManager.isSyncCompleted` survived — next user could briefly see prior CRM data / replay outbox.

### Privilege escalation risk (client)
UI filtered roles for Admin vs Super Admin, but `_hasEditAccess` always allowed edits, and `/users` had no router guard. **True enforcement must be on the API.**

---

## 3. Patches Applied (client)

| Area | Change |
|------|--------|
| `SessionCleanup` | New: clears token, Isar, web maps, user prefs, disconnects sync |
| `SecureStorage.saveToken` | Always deletes disk token before optional rewrite |
| `AuthRepository` | Clears session before login + full teardown on logout |
| `AuthBloc` | Listens for forced logout from 401 |
| `JwtInterceptor` | On 401 (non-auth paths): clear session + notify AuthBloc |
| `app_router` | AuthInitial/Loading → splash; `/users` Admin/Super Admin only |
| `app_shell` / dashboard | Remove fake identity emails |
| `RoleGuard` + users UI | Block Admin mutations unless Super Admin |
| Requirements | `_hasEditAccess` deny-by-default |

---

## 4. Remaining Risks (backend required)

1. Confirm only Super Admin can `POST/PUT/DELETE /users` for Admin role — integration test with Sales/Broker/Admin tokens.
2. Confirm JWT: strong secret or RS256 keypair, short expiry, issuer/audience checks, no `alg: none`.
3. Confirm org/tenant isolation and IDOR checks on every resource ID.
4. Rate-limit login; revoke/blacklist on logout if stateful sessions exist.
5. Supabase RLS must deny cross-tenant Realtime payloads.
6. Never return password hashes / internal errors to clients.

---

## 5. Hardening Checklist

- [x] Client logout clears Isar + prefs + memory + sync
- [x] Token persist bug fixed
- [x] No placeholder user identity in shell
- [x] Router auth gate for non-terminal states
- [x] 401 forces local logout
- [x] Client RoleGuard + `/users` route guard
- [ ] Backend RBAC integration tests (Sales/Broker/Employee → all admin endpoints)
- [ ] Backend JWT expiry + refresh strategy review
- [ ] Dependency CVE scan in CI
- [ ] Helmet/HSTS/CSP on API gateway
- [ ] Log redaction (no Authorization headers)

---

## 6. Verification Tests

```bash
flutter test test/security/
```

- `role_guard_test.dart` — Sales cannot become/manage Admin; Super Admin rules
- `session_token_test.dart` — token memory boundary after non-persist save

Manual QA:
1. Login User A → logout → login User B: sidebar never shows A’s email; lists are B’s data only.
2. Login as Sales → navigate `/users` → redirected to dashboard.
3. Expire/revoke token server-side → next API call returns to get-started.

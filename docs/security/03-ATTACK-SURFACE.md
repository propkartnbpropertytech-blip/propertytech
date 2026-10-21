# 03 — ATTACK SURFACE ANALYSIS

## 1. Attack Surface Overview

PropKart's attack surface consists of 5 primary vectors:
1. External HTTP/REST Endpoints
2. Realtime WebSocket Subscriptions (Phoenix Channels)
3. Offline Synchronization & Outbox Queues
4. File/Media Upload & Signature Endpoints
5. Client-Side Local Storage & Session State

---

## 2. External HTTP/REST Endpoints

| Endpoint Pattern | Method | Auth Required | Tenant Scoped | Risk Profile | Mitigations |
| :--- | :---: | :---: | :---: | :---: | :--- |
| `/api/v1/auth/login` | POST | No | No | Brute force, credential stuffing | Rate limited, captcha challenge, lockout tracking |
| `/api/v1/auth/refresh` | POST | Refresh | Yes | Token replay, token leakage | Token rotation, family reuse revocation |
| `/api/v1/auth/logout` | POST | Yes | Yes | Incomplete invalidation | JTI blacklisting, memory wipe |
| `/api/v1/dashboard/kpis` | GET | Yes | Yes | Tenant leakage, heavy query DoS | Server-stamped org filter, Redis caching, ceiling limits |
| `/api/v1/properties/*` | GET/POST/PUT | Yes | Yes | IDOR, mass assignment | Field allowlists, tenant context assertion |
| `/api/v1/requirements/*` | GET/POST/PUT | Yes | Yes | Cross-agent data theft | Team boundary scoping, assigned_to checks |
| `/api/v1/audit/logs` | GET | Yes (Super Admin) | Global | Information disclosure | Super Admin only boundary guard |
| `/api/v1/sync/*` | POST | Yes | Yes | Outbox spoofing, batch injection | Operation ID verification, tenant stamp assertion |

---

## 3. Realtime WebSocket Subscriptions

- **Protocol**: Phoenix Channels over Secure WebSocket (`wss://`).
- **Surface**: Clients subscribing to topics such as `realtime:propkart`.
- **Risks**:
  - Unauthenticated client tapping into CRM database changes.
  - Subscribing to sensitive database tables (e.g. `users`, `sessions`, `passwords`).
  - Cross-tenant message delivery.
- **Defenses**:
  - WebSocket connection requires verified JWT bearer handshake.
  - Channel subscriptions explicitly allowlist public CRM tables (`properties`, `requirements`, `followups`, `site_visits`, `leads`), strictly excluding credentials or security tables.
  - Incoming database replication events are filtered by tenant identity before dispatch.

---

## 4. Offline Synchronization & Outbox Queue

- **Surface**: Local Isar database storage and pending Outbox mutation queues.
- **Risks**:
  - Shared device leakage: User A logs out, User B logs in, previous tenant records remain readable.
  - Outbox mutation replay: Unsynced mutations drafted by User A dispatched under User B's token.
- **Defenses**:
  - `SessionCleanup.clearLocalSession()` executes a comprehensive wipe of all local repositories, in-memory caches, and outbox entries upon logout or token revocation.
  - Outbox items record immutable tenant bindings, preventing cross-tenant submission.

---

## 5. File & Media Uploads

- **Surface**: Cloudinary signature generation endpoints and multipart media uploads.
- **Risks**:
  - Direct shell script / SVG XSS upload spoofed as images.
  - Path traversal in filenames (`../../etc/passwd`).
  - Unbounded file sizes exhausting storage or network bandwidth.
- **Defenses**:
  - File magic-byte detection via `fileMagic.js` verifying actual file headers rather than trustable MIME headers.
  - Strict allowlist: `image/jpeg`, `image/png`, `image/webp`, `application/pdf`.
  - Filename sanitization stripping relative path specifiers (`..`, `/`, `\`).
  - Strict 10MB file size ceiling.

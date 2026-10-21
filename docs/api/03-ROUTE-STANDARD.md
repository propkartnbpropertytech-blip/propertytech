# 03 — ROUTE ARCHITECTURE & URL NAMING STANDARDS

## 1. Principles of Route Architecture

The PropKart REST API enforces standard REST resource-oriented URL conventions to provide an intuitive, discoverable, and predictable contract for mobile and web clients.

```
Base Pattern:
https://api.propkart.com/api/v1/{resource}[/{id}[/{sub-resource}]]
```

### 1.1 Core Route Rules
1. **Resource Nouns in Plural Kebab-Case**: Resource paths must be plural lowercase nouns with hyphens for multi-word entities (e.g. `/api/v1/site-visits`, `/api/v1/team-messages`, `/api/v1/campaign-connections`).
2. **Sub-Resource Hierarchy**: Nested resources must represent natural domain ownership (e.g. `/api/v1/properties/:id/images`, `/api/v1/requirements/:id/notes`).
3. **Actions as Verbs on Resources**: RPC-style actions are modeled as sub-resource verbs on nouns (e.g. `POST /api/v1/telecaller/leads/:id/start-call`, `POST /api/v1/auth/logout-all`).
4. **No Verbs in Primary Paths**: Forbidden: `/api/v1/getProperties`, `/api/v1/updateLead`. Use standard HTTP verbs (`GET /api/v1/properties`, `PATCH /api/v1/requirements/:id`).

---

## 2. API Versioning Strategy

### 2.1 URL Path Versioning
The PropKart API uses URL path versioning prefixed with `/api/v1`.

- **Current Stable Version**: `/api/v1`
- **Minimum Client Compatibility**: Controlled dynamically via `GET /api/v1/sync/status`:
  ```json
  {
    "serverTime": "2026-10-20T12:00:00.000Z",
    "schemaVersion": 4,
    "minimumClientVersion": 18,
    "maintenance": false
  }
  ```
- **Breaking Change Policy**: Adding optional query params or response fields is non-breaking and allowed in `v1`. Renaming fields, removing endpoints, or altering authentication contracts requires deploying `/api/v2` with a 90-day transition window for mobile clients.

---

## 3. Backward-Compatible Route Aliases

Due to historical Flutter client releases, several resources were originally requested with snake_case paths. PropKart maintains **permanent non-breaking route aliases** in `src/app.js`:

| Canonical Route | Legacy Alias Route | Router Module | Status |
| :--- | :--- | :--- | :--- |
| `/api/v1/site-visits` | `/api/v1/site_visits` | `site_visits.routes.js` | Maintained & Active |
| `/api/v1/page-controls` | `/api/v1/page_controls` | `page_controls.routes.js` | Maintained & Active |
| `/api/v1/health` | `/health` | `health.routes.js` | Maintained (Cloud load balancers) |
| `/api/v1/support` | `/support` | `support.routes.js` | Maintained (Web help redirect) |

> [!IMPORTANT]
> Route aliases MUST NEVER be removed until the mobile client version floor (`minimumClientVersion`) guarantees zero installations remain on obsolete versions.

---

## 4. Router Mounting Architecture

All router modules are mounted centrally in `src/app.js`.

```
src/app.js
├── Global Middlewares (CorrelationId, Helmet, CORS, Compression, BodyParser, RateLimit, Idempotency)
├── Public Health & Sync Status Routes
├── Module Routers
│   ├── /api/v1/auth                 → auth.routes.js
│   ├── /api/v1/dashboard            → dashboard.routes.js
│   ├── /api/v1/properties           → properties.routes.js
│   ├── /api/v1/requirements         → requirements.routes.js
│   ├── /api/v1/followups            → followups.routes.js
│   ├── /api/v1/site-visits          → site_visits.routes.js
│   ├── /api/v1/users                → users.routes.js
│   ├── /api/v1/notifications        → notifications.routes.js
│   ├── /api/v1/lookup               → lookup.routes.js
│   ├── /api/v1/config               → config.routes.js
│   ├── /api/v1/locations            → location.routes.js
│   ├── /api/v1/reports              → reports.routes.js
│   ├── /api/v1/export               → export.routes.js
│   ├── /api/v1 (telecaller/admin)   → allocation.routes.js
│   └── /api/external                → external.routes.js
├── Canonical 404 Catch-All Handler
└── Error Handling Middleware (error.middleware.js)
```

### 4.1 Route Isolation Rule
Routers mounted at base paths (such as `allocationRouter` mounted at `/api/v1`) must **never execute broad wildcard middleware** like `router.use(authenticate)` that would intercept unrelated sibling paths. Scoped route prefixes (`router.use(["/telecaller", "/admin", "/leads"], authenticate)`) must be used exclusively.

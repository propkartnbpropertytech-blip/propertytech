# 02 — API ARCHITECTURE VIOLATIONS & DEBT REGISTER

## 1. Executive Summary

In Step 1 (`docs/architecture/02-TARGET-ARCHITECTURE.md` and `docs/architecture/ARCHITECTURE-RULES.md`), PropKart established the strict **layered architecture rule**:

```
Routes  →  Middleware  →  Controllers  →  Services  →  Repositories  →  PostgreSQL / Redis
```

A comprehensive code audit in Step 4 revealed that **16 controllers** directly bypass the Service and Repository layers to execute queries directly against `supabase` or `dbPool`, or interact with cache without using `cacheService`.

This document catalogs every violation, evaluates its impact on system scalability and maintainability, and defines the remediation blueprint for Step 5.

---

## 2. Catalog of Direct Database Queries Inside Controllers

| Controller File | Violating Query Calls | Root Problem | Target Layer in Step 5 |
| :--- | :--- | :--- | :--- |
| `src/modules/auth/auth.controller.js` | Direct `supabase.from("users")`, `supabase.from("auth_tokens")`, `dbPool.query(...)` | Controller performs SQL queries, password hashing, token revocation directly. Monolithic file (1,363 lines). | Extract to `AuthRepository` and `AuthService`. Split into auth, token, and MFA sub-modules. |
| `src/modules/properties/properties.controller.js` | Direct `supabase.from("properties")`, `supabase.from("property_images")`, `supabase.from("property_status")` | Direct queries for status updates, media management, duplicate checks. 1,162 lines. | Route all persistence through `PropertiesRepository`. Extract media management to `PropertyMediaService`. |
| `src/modules/users/users.controller.js` | Direct `supabase.from("users")`, `supabase.from("roles")`, `supabase.from("organizations")` | User creation, role reassignment, and status changes query database directly. 775 lines. | Route through `UsersRepository` and `UsersService`. |
| `src/modules/followups/followups.controller.js` | Direct `supabase.from("followups")`, `supabase.from("leads")` | Direct queries for overdue follow-ups and status changes. | Migrate to `FollowupsRepository`. |
| `src/modules/site_visits/site_visits.controller.js` | Direct `supabase.from("site_visits")` | Site visit scheduling, cancellation, feedback updates query Supabase directly. | Migrate to `SiteVisitsRepository`. |
| `src/modules/owners/owners.controller.js` | Direct `supabase.from("owners")` | Property owner CRUD queries execute directly in controller. | Migrate to `OwnersRepository`. |
| `src/modules/builders/builders.controller.js` | Direct `supabase.from("builders")`, `supabase.from("projects")` | Builder profiles and project catalog querying DB directly. | Migrate to `BuildersRepository`. |
| `src/modules/notifications/notifications.controller.js` | Direct `supabase.from("notifications")` | Marking read, listing unread notifications querying DB directly. | Migrate to `NotificationsRepository`. |
| `src/modules/checklist/checklist.controller.js` | Direct `supabase.from("checklist")` | Daily checklist item toggling and creation in controller. | Migrate to `ChecklistRepository`. |
| `src/modules/places/places.controller.js` | Direct `supabase.from("cities")`, `supabase.from("areas")` | Location lookups and geocoding querying DB directly. | Migrate to `LocationsRepository`. |
| `src/modules/clients/clients.controller.js` | Direct `supabase.from("clients")` | Client contact creation and search in controller. | Migrate to `ClientsRepository`. |
| `src/modules/legal/legal.controller.js` | Direct `supabase.from("legal_documents")` | Legal document retrieval querying DB directly. | Migrate to `LegalRepository`. |
| `src/modules/support/support.controller.js` | Direct `supabase.from("support_tickets")` | Support ticket submission and listing in controller. | Migrate to `SupportRepository`. |
| `src/modules/team_messages/team_messages.controller.js` | Direct `supabase.from("team_messages")` | Message post and retrieval querying DB directly. | Migrate to `TeamMessagesRepository`. |
| `src/modules/usage/usage.controller.js` | Direct `dbPool.query(...)` | Storage calculation querying PostgreSQL directly. | Migrate to `UsageRepository`. |
| `src/modules/page_controls/page_controls.controller.js` | Direct `supabase.from("page_controls")` | UI visibility rules querying DB directly. | Migrate to `PageControlsRepository`. |

---

## 3. Monolithic Controller Anti-Patterns

Three controllers and one integration service have grown to extreme lengths, posing severe maintainability, code comprehension, and AI-agent context risks:

1. **`src/modules/integrations/integrations.service.js` (4,688 lines):**
   - Contains raw webhook ingestion logic for Meta, Housing, MagicBricks, and 99acres combined into a single gigantic file.
   - Mixes HTTP header verification, payload mapping, lead deduplication, telecaller assignment, and database writes.
   - **Remediation**: Split into dedicated adapters (`MetaIntegrationService`, `HousingIntegrationService`, `PortalSyncService`) in Step 5.

2. **`src/modules/auth/auth.controller.js` (1,363 lines):**
   - Handles password login, token refreshes, cookie extraction, CAPTCHA verification, TOTP MFA setup, email verification, password reset tokens, and logout all in one file.
   - **Remediation**: Split into `AuthController`, `MfaController`, and `SessionController` with shared `AuthService`.

3. **`src/modules/properties/properties.controller.js` (1,162 lines):**
   - Combines property querying, Excel export, Cloudinary image uploading, video processing, bulk updates, and duplicate address detection in a single file.
   - **Remediation**: Split into `PropertiesController`, `PropertyMediaController`, and `PropertyExportController`.

---

## 4. Application-Level Joins & Inefficient Query Patterns

### 4.1 Dashboard Service N+1 Multi-Hop Pattern
In `src/modules/dashboard/dashboard.service.js`, the dashboard summary aggregates requirements, follow-ups, and site visits:
- It first queries all `requirements` for the user/organization.
- It extracts the array of IDs and maps them into an in-memory comma-separated PostgREST filter string:
  ```javascript
  query.or(`requirement_id.in.(${idList.join(",")})`);
  ```
- **Architectural Risk**: When a sales agent or organization has 2,000+ requirements, the URL filter exceeds HTTP header size limits (414 URI Too Long) and PostgreSQL executes an unbounded list scan.
- **Solution Established in Step 2 / Step 3**: Use the canonical SQL aggregation view / stored function (`get_dashboard_summary(org_id, user_id)`) and cache the result in Redis with a 3-minute TTL.

### 4.2 Property Universal Search RAM Buffering
Before Step 4, `PropertiesRepository.getProperties` fetched all 632+ properties and joined all 13 lookup tables, images, and amenities into Node.js heap memory, filtering in JS via `propertyMatchesUniversalSearch`:
- Payload size: **1,071,296 bytes (1.07 MB)**.
- Latency: **240.58 ms P50**.
- **Step 4 Remediation**: When universal search is not requested, SQL-level `.range(offset, offset + limit - 1)` is strictly enforced. Payload dropped to **158 KB (85% reduction)** and latency dropped to **96 ms (60% reduction)**.

---

## 5. Architectural Boundaries Checklist for Step 5

To eliminate all violations without breaking existing mobile API contracts:
- [ ] No controller may import `supabase` or `dbPool`.
- [ ] No controller may import `redisClient` directly; must use `cacheService`.
- [ ] Every mutation must validate input via Zod schema middleware before hitting controller.
- [ ] Controllers must only parse request parameters, call the domain Service, and format the response using standard DTOs.

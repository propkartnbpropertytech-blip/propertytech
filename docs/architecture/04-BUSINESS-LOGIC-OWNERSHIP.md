# PROPKART — BUSINESS LOGIC OWNERSHIP MAP
**Version:** 1.0.0  
**Status:** CANONICAL GOVERNANCE CONTRACT (STEP 1 FOUNDATION)  
**Date:** October 19, 2026  
**Scope:** Rule Ownership & Deduplication across Flutter, Backend, and Database  

---

## 1. Architectural Mandate on Logic Ownership

In a complex multi-platform ERP/CRM platform, business rule duplication is the primary cause of bugs, data drift, and security vulnerabilities. When the same rule (e.g. lead qualification, KPI counting, or permission checks) is implemented independently in Flutter and in Node.js, the implementations inevitably diverge.

**The Golden Law of Logic Ownership:**
> Every business invariant, calculation formula, and state transition rule must have **ONE CANONICAL OWNER**.
> - The Canonical Owner is the authoritative execution engine for that rule.
> - Client platforms (Flutter Web/Mobile/Desktop) may execute **optimistic validation** or **preview rendering**, but must never become an independent business authority.

---

## 2. Canonical Business Logic Ownership Registry

| # | Business Domain / Rule | Canonical Owner | Location | Non-Canonical Role of Client / Other Layers |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Property Matching Algorithm** | **Backend Domain Service** | `src/modules/matching/matching.service.js` | Flutter UI receives match scores and displays explanation badges. Client must NOT calculate matching scores. |
| **2** | **Lead Allocation Engine** | **Database PL/pgSQL Function** with Backend Coordinator | `allocate_waiting_leads` / `src/modules/allocation/` | Database handles concurrency locks (`FOR UPDATE SKIP LOCKED`). Backend coordinates events. Flutter displays queue stats. |
| **3** | **Telecaller Workload & Capacity** | **Database PL/pgSQL & Allocation Service** | `telecaller_active_workload` / `allocation.constants.js` | Canonical rules enforce `max_capacity` (e.g. 25). Telecaller client only displays assigned count. |
| **4** | **Rental Pipeline Lifecycle** | **Backend Properties & Requirements Service** | `src/modules/properties/`, `src/modules/requirements/` | State machine transitions (`Available` -> `Under Negotiation` -> `Rented` -> `Off Market`). Client binds to enums. |
| **5** | **Resale Pipeline Lifecycle** | **Backend Properties & Requirements Service** | `src/modules/properties/`, `src/modules/requirements/` | State machine transitions (`Available` -> `Token Paid` -> `Registered` -> `Sold`). Client binds to enums. |
| **6** | **Lead Ownership & Team Scoping** | **Backend Architectural Guard** | `src/security/architecturalGuard.js` | Enforces `assigned_telecaller_id` and `assigned_to`. Non-admins cannot steal/reassign leads. Client disables reassign UI. |
| **7** | **Role-Based Access Control (RBAC)**| **Backend Security Middleware** | `src/middleware/auth.middleware.js` & `tenant.js` | Server validates every request. Flutter `RoleGuard` provides client-side route protection for UX only. |
| **8** | **Master KPI Calculations** | **Backend KPI Service** | `src/modules/dashboard/kpi.service.js` | Formula definition, cohort filtering, deduplication. Flutter displays server-returned KPI figures. |
| **9** | **Dashboard Metric Aggregations** | **Backend Dashboard Service** | `src/modules/dashboard/dashboard.service.js` | Computes summary cards, trend vectors, and conversion rates. Client renders charts. |
| **10**| **Followup Scheduling & Overdue Detection** | **Backend Followups Service** | `src/modules/followups/followups.service.js` | Evaluates overdue statuses and notifications. Client provides calendar picker and optimistic list sorting. |
| **11**| **Site Visit Outcome Tracking** | **Backend Site Visits Service** | `src/modules/site_visits/site_visits.service.js` | Immutable ledger updates. Enforces unique booking constraints. Client records agent notes and outcome selection. |
| **12**| **Lead Qualification & Conversion**| **Backend Requirements Service** | `src/modules/requirements/` | Moves lead to converted client and links active requirements. Client triggers action modal. |
| **13**| **Lost / Disqualified Leads (CNR, NI, Junk)** | **Backend Allocation Service** | `src/modules/allocation/allocation.service.js` | Moves to cooling period, releases telecaller slot, archives lead with required remark. Client shows outcome dialog. |
| **14**| **Auto-Provisioning Requirements**| **Database Trigger / Backend Ingestion** | `trg_sync_leads_to_requirements` / `integrations.service.js` | When an inbound lead contains property parameters, requirement record is auto-generated. |
| **15**| **Offline Mutation Synchronization**| **Flutter Sync Engine** | `lib/core/network/sync_engine.dart` | Buffers local actions into `OutboxLocal`, computes diffs, batches uploads. Backend validates each mutation atomically. |
| **16**| **Sync Conflict Resolution** | **Backend Service (Server-Wins Policy)** | `src/modules/sync/sync.service.js` | Timestamps evaluated. Server authoritative state overwrites stale client updates. Client updates local cache. |
| **17**| **System Notifications & Alerts** | **Backend Notification Service** | `src/services/notification.service.js` | Generates notification payloads and triggers FCM push. Flutter displays local snackbars / notification tray. |
| **18**| **Security & Transaction Audit Logs**| **Backend Audit Service** | `src/modules/audit/audit.service.js` | Appends audit rows on critical mutations. Client cannot directly write to audit table. |
| **19**| **Media Transformation & CDN Delivery**| **Cloudinary Edge Engine** | Cloudinary URL transform rules | Backend generates signed upload tokens. Flutter requests optimized WebP/AVIF dimensions. |
| **20**| **UI Dwell Telemetry** | **Flutter Audit Telemetry Service** | `lib/core/telemetry/audit_dwell_tracker.dart` | Measures route dwell time and clicks. Periodically flushes to backend telemetry sink. |

---

## 3. Forensic Analysis: Cataloged Logic Duplication Violations

The forensic inspection revealed critical areas where business rules are duplicated between Flutter and the backend:

### Violation 1: Client-Side KPI & Count Recalculation
- **Location:** `lib/features/requirements/screens/requirements_screen.dart` (lines 4200–4800) and `lib/features/campaign/screens/campaign_leads_screen.dart` (lines 2800–3200).
- **The Defect:** When filtering requirements or campaign leads, the UI recalculates total counts, active lead counts, CNR percentages, and stage breakdowns inside `StatefulWidget` loops instead of consuming backend aggregated metrics.
- **The Risk:** When server-side status enums change or filters include timezone offsets, the figures displayed in the table header differ from the Dashboard summary bar.
- **Remediation Target:** Frontend must display the exact KPI counters returned in the API response envelope (`meta.counts` / `meta.kpis`).

### Violation 2: Duplicated Property Matching Logic
- **Location:** `lib/features/requirements/services/match_criteria_manager.dart` vs `src/modules/matching/matching.service.js`.
- **The Defect:** Both the Flutter client and the backend maintain independent algorithms to calculate if a property matches a client requirement (checking budget tolerance $\pm 10\%$, bedroom count, area distance).
- **The Risk:** A property might appear as a "95% Match" in the Flutter mobile card preview, but fail to appear on the web sharing portal or in automated WhatsApp alerts generated by the backend.
- **Remediation Target:** Deprecate client-side matching algorithm. All matches must be fetched from `GET /api/v1/requirements/:id/matches` or calculated via a shared deterministic specification.

### Violation 3: Duplicated Telephone Formatting & Sanitization
- **Location:** `lib/core/utils/phone.dart` vs `src/services/leadIngestEngine.service.js` vs `src/modules/integrations/integrations.service.js`.
- **The Defect:** Both frontend and backend implement custom regexes to strip `+91`, remove leading zeros, and format Indian 10-digit mobile numbers.
- **The Risk:** Edge cases (e.g. landlines, international numbers) are sanitized differently, causing unique phone lookups to miss existing leads and create duplicates.
- **Remediation Target:** The backend `leadIngestEngine` is the single canonical normalizer. Flutter uses client-side formatting for display only (`+91 XXXXX-XXXXX`).

### Violation 4: Dual Lead-to-Requirement Sync (Database Triggers vs Application Code)
- **Location:** Database triggers (`fn_sync_leads_to_requirements`) vs Backend `integrations.service.js` (lines 800–1200) vs Flutter `FollowupSyncEngine`.
- **The Defect:** When a lead is updated or a followup is added, the database trigger attempts to update the requirement record, while the Node.js service ALSO executes manual update queries, and Flutter triggers its own local sync engine.
- **The Risk:** Race conditions, duplicate followup rows, and database deadlocks (`40P01`) under high concurrent webhook traffic.
- **Remediation Target:** Elevate lead-to-requirement lifecycle coordination to the backend application service layer; phase out recursive database triggers.

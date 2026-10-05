# PROPKART — MASTER ENGINEERING RULEBOOK
## System Architecture, Data Governance, Lifecycle State Machines, KPI Definitions & Operational Protocols
**Version:** 1.1.0  
**Status:** ACTIVE GOVERNANCE DOCUMENT  
**Release Date:** October 2, 2026  
**Target Platform:** PropKart CRM & PropTech ERP (Web, Mobile, Desktop)  
**Authoritative Repositories:**  
- Backend: `C:\NB\PropKart-Backend` (Node.js 20+, Express, PostgreSQL 16)  
- Frontend: `c:\NB\propkart` (Flutter 3.x, Dart 3.x, BLoC Architecture)  
- Authoritative Database: PostgreSQL 16 (`public` schema, Port 54350 / 54329)  

---

## 1. Document Authority, Mandate & Scope

### 1.1 Constitutional Authority
This document constitutes the **Master Engineering Governance Authority** for the PropKart platform. It supercedes all informal architectural discussions, ad-hoc tickets, legacy comments, and unverified implementation conventions.

Every engineering activity undertaken on PropKart—including feature development, bug fixing, schema evolution, KPI calculation, performance optimization, refactoring, and AI agent prompt execution—is subject to the rules, invariants, and change protocols defined herein.

### 1.2 Core Mandate: "No Isolated Change"
In PropKart, **NO ISOLATED CHANGE EXISTS**. Every change must be evaluated as a holistic system modification. A modification is never complete merely because its immediate screen renders without error or an endpoint returns HTTP 200. A change is considered architecturally compliant **ONLY** when:
$$\text{Business Invariant} + \text{Authoritative Data Model} + \text{Database Integrity} + \text{Lifecycle Progression} + \text{RBAC} + \text{KPI Semantics} + \text{Audit} + \text{Performance} + \text{Offline Sync}$$
have all been evaluated and verified against this Rulebook.

### 1.3 Scope of Governance
This Rulebook governs:
1. **Database Schema & Evolution:** Tables, constraints, foreign keys, indexes, types, sequences, and migrations.
2. **Backend Engineering:** API contracts, service boundaries, repositories, transactions, allocation engines, and background jobs.
3. **Frontend Application:** Flutter UI layouts, BLoC state management, navigation, responsive breakpoints, offline storage, and caching.
4. **Data Analytics & KPIs:** Formulations, source tables, time boundaries, deduplication, and cross-screen reconciliation.
5. **Security & RBAC:** Multi-tenancy, authentication, role scopes, data isolation, and field-level masking.
6. **Operations & Lifecycle:** Lead qualification, telecaller workload, property inventory, site visits, and audit logging.

---

## 2. Core Engineering Axioms & Fundamental Invariants

The PropKart system is anchored on **Ten Fundamental Engineering Axioms**. These axioms are eternal architectural foundations that cannot be altered without platform-wide redesign:

### Axiom 1: Single Authoritative Source of Truth (`INV-001`)
PostgreSQL is the single authoritative store of business truth. Client-side storage (Isar, SharedPreferences), in-memory caches, and UI state engines are non-authoritative read projections or temporary staging queues.

### Axiom 2: Historical Event Immutability (`INV-002`)
A completed business event (such as a conducted Site Visit, an executed Call Attempt, or an Audit Log entry) is an immutable historical fact. Subsequent changes to an entity's mutable lifecycle status must **NEVER** delete, overwrite, or decrement historical event ledgers.

### Axiom 3: Strict Set-Theoretic Cohort Invariant (`INV-006`)
Under any temporal cohort filter, child progression counts must be mathematical subsets of parent intake counts:
$$\text{Cohort Allocated Leads} \subseteq \text{Total Intake Leads} \implies \left|\text{Allocated}\right| \le \left|\text{Total}\right|$$

### Axiom 4: Direct Relational Ownership (`RBAC-INV-04`)
Ownership and data access scopes must be established exclusively through direct foreign keys (`assigned_telecaller_id`, `assigned_to`, `organization_id`). Access evaluation via runtime string searches, heuristic loops, or unindexed phone matching is strictly prohibited.

### Axiom 5: Canonical Metric Definition & Semantic Equivalence (`KPI-001`)
Every KPI across the platform must share an identical canonical definition, mathematical formula, authoritative source table, date semantics, and deduplication rules. Query shapes may differ for performance or aggregation, but must produce semantically equivalent results.

### Axiom 6: Multi-Tenant Data Isolation at the Core (`INV-004`)
PropKart is a multi-tenant platform. Every business table, search query, dashboard aggregation, and mutation must enforce strict organization isolation (`organization_id`) at the database layer.

### Axiom 7: Concurrency & Lock Integrity (`INV-003`)
Resource allocation, queue dequeuing, and state handoffs under concurrent traffic must utilize deterministic database-level concurrency controls (`FOR UPDATE SKIP LOCKED`) to guarantee zero duplicate assignments.

### Axiom 8: Additive Schema Evolution (`DB-003`)
Database schemas evolve additively. Production deployments must maintain backward compatibility with running code. Destructive modifications (dropping columns/tables) require multi-release deprecation protocols.

### Axiom 9: Explainable & Deterministic Matching (`INV-007`)
The property matching engine must strictly evaluate hard disqualification filters before computing weighted scoring. Scoring must be deterministic, mathematically transparent, and explainable to users.

### Axiom 10: Telemetry & Transactional Audit Isolation (`AUD-003`)
Transactional audit logging (`public.audit_logs`) records security and business state transitions. High-frequency UI telemetry (mouse hovers, screen dwell time) must never pollute transactional audit logs.

---

## 3. Mandatory Rule Classification & Governance Taxonomy

Every rule within this Rulebook is categorized under the **Eight-Category Taxonomy** to strictly distinguish permanent engineering laws from operational business policies, current implementations, and technical debt:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PROPKART GOVERNANCE TAXONOMY                    │
├────────────────────────────────┬───────────────────────────────────────┤
│ 1. PERMANENT INVARIANT         │ Architectural axiom that must NEVER   │
│                                │ change across the system's lifetime.  │
├────────────────────────────────┼───────────────────────────────────────┤
│ 2. BUSINESS POLICY             │ Configurable business rule, threshold,│
│                                │ or operational allowance.             │
├────────────────────────────────┼───────────────────────────────────────┤
│ 3. ENGINEERING STANDARD        │ Technical specification, protocol, or │
│                                │ architectural pattern.                │
├────────────────────────────────┼───────────────────────────────────────┤
│ 4. CURRENT APPROVED            │ Current production implementation     │
│    IMPLEMENTATION              │ mechanism chosen to fulfill a rule.   │
├────────────────────────────────┼───────────────────────────────────────┤
│ 5. PROPOSED GOVERNANCE RULE    │ Validated governance rule pending     │
│                                │ production deployment.                │
├────────────────────────────────┼───────────────────────────────────────┤
│ 6. TECHNICAL DEBT / VIOLATION  │ Cataloged deviation from rules        │
│                                │ documented for future remediation.    │
├────────────────────────────────┼───────────────────────────────────────┤
│ 7. CONDITIONAL RULE            │ Rule active only under specific       │
│                                │ operational conditions or flags.      │
├────────────────────────────────┼───────────────────────────────────────┤
│ 8. TEMPORARY MIGRATION RULE    │ Interim rule active only during data  │
│                                │ or schema migration transitions.      │
└────────────────────────────────┴───────────────────────────────────────┘
```

### Rule Specification Schema
Every governance rule in this Rulebook adheres to the following mandatory specification schema:
- **Rule ID:** Globally unique identifier formatted as `[DOMAIN]-[NUMBER]`.
- **Category:** Exactly one of the eight taxonomy categories above.
- **Severity:** `CRITICAL` (P0), `HIGH` (P1), `MEDIUM` (P2), or `LOW` (P3).
- **Status:** `ACTIVE`, `PROPOSED`, `RETIRED`, `SUPERSEDED BY [ID]`, or `VIOLATION`.
- **Rule:** High-level declarative statement of the mandate.
- **MUST:** Mandatory technical behaviors and requirements.
- **MUST NOT:** Prohibited technical behaviors and anti-patterns.
- **Rationale:** Deep architectural and operational justification.
- **Validation:** Concrete automated verification query, test, or inspection step.
- **Affected Systems:** Specific backend services, frontend widgets, and database tables impacted.

---

## 4. Permanent Engineering Invariants (`INV`)

### INV-001 — PostgreSQL Server-Side Authoritative Truth
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
PostgreSQL is the sole, authoritative source of server-side business truth for the PropKart platform. No client device, local database, browser cache, or mobile storage engine can independently establish or override final server-side state.

**MUST:**
- Treat PostgreSQL database tables as the primary definitive record for all entities, lifecycle states, assignments, and transactions.
- Synchronize all client mutations to PostgreSQL prior to declaring business state committed.
- Reconcile client-side caches against PostgreSQL records upon network reconnection or application launch.

**MUST NOT:**
- Never permit client-side state engines (e.g., Isar, SharedPreferences, Flutter BLoC) to unilaterally declare an entity created, modified, or deleted without PostgreSQL acknowledgment.
- Never bypass PostgreSQL constraint validation in favor of client-only validation logic.

**Rationale:**  
Multi-device environments create inherent concurrency conflicts. If client caches are treated as authoritative, network partitions lead to permanent data divergence, phantom assignments, and irreversible data loss.

**Validation:**  
Inspect frontend API repositories. Ensure every mutation awaits successful backend HTTP/RPC response before finalizing client models.

**Affected Systems:**  
All Client Repositories, Backend APIs, PostgreSQL Database.

---

### INV-002 — Completed Historical Events are Immutable
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Any completed real-world business event—specifically Site Visits conducted, Call Attempts executed, Follow-ups logged, and Audit Entries recorded—is permanently immutable. Subsequent lifecycle transitions of the parent lead or requirement must NEVER delete, reverse, decrement, or overwrite the completed historical record.

**MUST:**
- Preserve historical event rows in their dedicated event tables (`public.site_visits`, `public.followups`, `public.audit_logs`) indefinitely or until formal cold-storage archival.
- Retain `site_visits.status = 'COMPLETED'` and populated `completed_at` when a requirement or lead subsequently transitions to `Rejected`, `Lost`, `Not Interested`, or `Won`.
- Record subsequent progress as downstream outcomes (e.g., `outcome = 'REJECTED_AFTER_VISIT'`) rather than deleting or modifying the visit event.

**MUST NOT:**
- Never execute `DELETE` or status reversal on a completed site visit upon deal loss or rejection.
- Never decrement historical counters (such as "Site Visits Done") when a downstream rejection occurs.

**Rationale:**  
Business events reflect physical actions executed by staff. Erasing historical events upon subsequent deal loss destroys operational performance metrics, falsifies salesperson KPI achievements, and distorts conversion funnel analytics.

**Validation:**  
Execute transition test: `Site Visit Done` $\rightarrow$ `Rejected`. Assert that `site_visits` row retains `status = 'COMPLETED'`, `completed_at IS NOT NULL`, and `outcome = 'REJECTED_AFTER_VISIT'`.

**Affected Systems:**  
Requirements Service, Site Visits Module, KPI Service, Admin Dashboard, Sales Performance Reports.

---

### INV-003 — Single Active Telecaller Ownership per Lead Allocation
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
A single lead allocation in `public.leads` must never have more than one simultaneous active telecaller owner. Lead allocation must be concurrency-safe, deterministic, and auditable.

**MUST:**
- Ensure that at any given moment, `leads.assigned_telecaller_id` contains exactly one user UUID or is `NULL`.
- Enforce atomic ownership transitions such that transferring a lead to a new telecaller automatically updates `telecaller_assigned_at` and logs a status history record.
- Execute allocation updates within concurrency-safe database locks to prevent race conditions during bulk or simultaneous inbound lead ingestion.

**MUST NOT:**
- Never assign a lead to multiple telecallers simultaneously.
- Never execute non-atomic allocation routines that leave ownership undefined or duplicated.

**Rationale:**  
Dual ownership results in duplicate calling, customer harassment, telecaller commission conflicts, and corrupted call performance tracking.

**Validation:**  
Run database constraint check: verify zero leads exist with conflicting multi-assignment records. Execute concurrent ingestion load tests to prove zero double-allocation.

**Affected Systems:**  
Lead Allocation Engine, Ingestion Service, Telecaller Workspace.

---

### INV-004 — Tenant Isolation at Database Boundary
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
PropKart enforces strict multi-tenant isolation. All queries, mutations, reports, and background jobs must enforce tenant scoping (`organization_id`) at the PostgreSQL database layer.

**MUST:**
- Include `organization_id = :current_user_org_id` in every SQL `WHERE` clause across all controllers, services, and repositories (unless requester is explicitly verified as `Super Admin`).
- Reject any API request where the route or payload attempts to query or mutate a record belonging to another organization.

**MUST NOT:**
- Never execute naked cross-tenant queries that rely on frontend filtering to hide foreign tenant records.
- Never permit cross-tenant data leakage in aggregate reports, search lookups, or exports.

**Rationale:**  
PropKart hosts independent real estate brokerages. Cross-tenant leakage constitutes an existential data privacy breach, violating commercial agreements and data protection laws.

**Validation:**  
Audit all SQL queries and Supabase RPC calls. Confirm that `WHERE organization_id = ...` is enforced uniformly across all data-access paths.

**Affected Systems:**  
Entire Backend API, Database Row-Level Security, Reporting Engine, Export Service.

---

### INV-005 — Indian Standard Time (IST) for All Business Day Boundaries
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
All business day boundaries, calendar date filters (*Today*, *Yesterday*, *This Week*, *This Month*, *Custom Range*), shift schedules, and operational deadlines must evaluate strictly in **Indian Standard Time (IST / Asia/Kolkata, UTC+5:30)**.

**MUST:**
- Calculate calendar day start and end in SQL using explicit timezone conversions:
  $$\text{Day Start} = \text{00:00:00.000 IST} \quad (\text{18:30:00.000 UTC Previous Day})$$
  $$\text{Day End} = \text{23:59:59.999 IST} \quad (\text{18:29:59.999 UTC Current Day})$$
- Formulate SQL date checks explicitly:
  ```sql
  (created_at AT TIME ZONE 'Asia/Kolkata')::date = (NOW() AT TIME ZONE 'Asia/Kolkata')::date
  ```

**MUST NOT:**
- Never evaluate business day boundaries in raw UTC (`CURRENT_DATE` in UTC).
- Never allow client devices in different timezones to skew server-side reporting dates.

**Rationale:**  
Evaluating day boundaries in UTC creates a 5.5-hour operational skew in India. Leads ingested between midnight and 5:30 AM IST appear under the previous day, causing morning executive dashboards to display zero leads received.

**Validation:**  
Verify `src/modules/dashboard/kpi.service.js` line 14 (`getIstDateRange`). Test boundary timestamps at 00:01 IST and 23:59 IST.

**Affected Systems:**  
KPI Service, Reports Service, Daily Telecaller Counts, Dashboard Controllers.

---

### INV-006 — Mathematical Cohort Subset Guarantee
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Under any temporal cohort filter, downstream milestone counts must be strict mathematical subsets of the upstream intake set. Specifically:
$$\text{Leads Allocated (Cohort)} \le \text{Total Ingested Leads}$$

**MUST:**
- Filter cohort metrics strictly by the entity's creation timestamp (`leads.created_at`).
- Explicitly distinguish **Cohort Progression Metrics** (filtered by `created_at`) from **Operational Action Volume** (filtered by action timestamp such as `telecaller_assigned_at`).

**MUST NOT:**
- Never display an action-volume metric under a cohort progression label.
- Never produce a cohort dashboard where child stage counts exceed 100% of the intake denominator.

**Rationale:**  
Displaying 1,095 allocated leads against 163 total leads destroys stakeholder trust in analytics and creates fundamental confusion between intake cohort conversion and telecaller daily activity.

**Validation:**  
Execute cross-screen reconciliation test across Today, Weekly, Monthly, and Yearly filters. Assert $\text{Allocated} \le \text{Total}$ across all windows.

**Affected Systems:**  
Admin Dashboard, Business Insights, Campaign Reports.

---

### INV-007 — Hard Filters Must Precede Soft Scoring in Matching
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
The property matching engine must strictly evaluate Stage 1 Hard Disqualification Filters before evaluating Stage 2 Weighted Soft Scoring. Any property failing a hard filter must be immediately disqualified with a match score of 0.

**MUST:**
- Disqualify properties immediately if:
  1. Status is `Sold Out`, `Rented Out`, `Inactive`, or `Do Not Disturb`.
  2. Listing type conflicts (e.g., Requirement is Rent and Property is Resale).
  3. City conflicts when cities are specified and mismatched.
- Execute weighted scoring only on properties that pass all Stage 1 hard filters.

**MUST NOT:**
- Never calculate soft scoring points for a disqualified property.
- Never show a property with match score $>0$ if it is unavailable or incompatible in listing type.

**Rationale:**  
Presenting unavailable or listing-type-incompatible properties to sales agents wastes client consultation time, frustrates prospective buyers, and damages brokerage credibility.

**Validation:**  
Inspect `src/modules/matching/matching.service.js` lines 261–445. Unit test disqualified property inputs to assert 0 match score.

**Affected Systems:**  
Matching Engine, Sales Consultation Screen, Client Presentation View.

---

### INV-008 — Client Local State Cannot Establish Final Authoritative Server Truth
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Client-side persistence engines (Isar on mobile/desktop; SharedPreferences / in-memory maps on web) function strictly as read-through cache accelerators and offline draft/intent stores. Local client state cannot independently establish final authoritative server truth.

**MUST:**
- Treat local database records as projections that are subject to backend reconciliation.
- Queue offline client mutations in a dedicated Outbox awaiting server synchronization and server-side validation.
- Overwrite or reconcile local client state with the authoritative server payload upon receiving API confirmation.

**MUST NOT:**
- Never treat local database state as final business truth prior to successful server synchronization.
- Never allow a disconnected client to establish final allocation ownership or terminal deal states without server confirmation.

**Rationale:**  
If offline devices are permitted to establish final business truth, concurrent conflicting mutations across devices cannot be reconciled without arbitrary data corruption.

**Validation:**  
Inspect `lib/core/storage/local_repositories.dart` and offline sync outbox handlers. Verify that all outbox sync operations handle server conflict responses gracefully.

**Affected Systems:**  
Flutter Isar Storage, Outbox Sync Engine, Offline Mutation Handlers.

---

## 5. Business Governance Policies (`BUS`)

### BUS-001 — Lead Qualification Funnel Separation
**Category:** BUSINESS POLICY  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
The telecaller qualification queue (`public.leads` / `public.integration_leads`) and the sales deal closing pipeline (`public.requirements`) are distinct business stages. Telecallers qualify cold leads; sales closers negotiate deals and execute site visits.

**MUST:**
- Direct telecallers to work from their dedicated calling queue (`/telecaller/leads` or `/campaign/leads`).
- Direct sales closers to manage property matching, consultation, site visits, and negotiations within the requirements workflow (`/requirements`).
- Execute formal qualification transactions when handing off a lead from outreach to sales, setting `leads.allocation_status = 'HANDED_TO_SALES'` and linking to an active record in `public.requirements`.

**MUST NOT:**
- Never force telecallers to execute property showings or manage closing contracts.
- Never allow a lead to bypass outreach qualification unless created as an explicit direct manual requirement by an authorized sales agent or administrator.

**Rationale:**  
Telecallers handle high-volume, rapid-turnaround outreach across cold inquiries. Sales closers manage low-volume, high-touch consultation over weeks or months. Conflating the two creates catastrophic reporting ambiguity regarding ownership and pipeline conversion.

**Validation:**  
Verify `src/modules/integrations/integrations.service.js` line 3480 (`transferLeadToSales`).

**Affected Systems:**  
Backend Ingestion Engine, Campaign Screen, Requirements Screen, Sales Reports.

---

### BUS-002 — Telecaller 6-Hour Manual OFF Allowance Policy
**Category:** BUSINESS POLICY  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Telecallers are granted a configurable operational allowance of maximum **6 hours of manual OFF time** within each 24-hour cycle. When this allowance expires, new inbound lead allocations are paused until the telecaller explicitly toggles Active ON.

**MUST:**
- Decrement the 6-hour countdown timer whenever a telecaller manually toggles availability to OFF.
- Pause the 6-hour manual OFF countdown when an automatic inactivity break (5 minutes of idle) triggers and transitions the user to `'BREAK'` status.
- Display a prominent, non-blocking warning banner when the 6-hour allowance is exhausted: *"6-Hour OFF limit reached! New lead assignments are paused until you turn the Active toggle ON."*
- Exclude the telecaller from automated round-robin lead allocation while OFF allowance is exhausted and toggle is OFF.

**MUST NOT:**
- Never classify this operational threshold as a frozen architectural invariant; thresholds must remain configurable in business constants (`src/modules/allocation/allocation.constants.js`).
- Never lock out a telecaller from viewing existing assigned leads when the OFF allowance is reached.

**Rationale:**  
Telecallers require operational flexibility for administrative tasks, but brokerages must prevent telecallers from remaining permanently inactive while blocking lead flow.

**Validation:**  
Inspect `src/modules/allocation/allocation.constants.js` (`OFF_TIME_ALLOWANCE_HOURS = 6`) and Flutter `TelecallerShiftManager`.

**Affected Systems:**  
Telecaller Workspace, Shift Manager, Allocation Stored Procedure.

---

### BUS-003 — Telecaller 9-Hour Daily Active Shift Ceiling
**Category:** BUSINESS POLICY  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Telecallers are subject to a configurable operational ceiling of maximum **9 hours of total active shift time** per calendar day. Upon reaching this ceiling, an un-bypassable shift completion modal is presented, and lead allocation ceases until the next calendar day.

**MUST:**
- Track accumulated active time in `public.telecaller_availability`.
- Trigger the shift completion lockout overlay upon reaching 9 active hours (540 minutes).
- Automatically reset daily active time accumulation at 00:00 IST.

**MUST NOT:**
- Never allocate new inbound leads to a telecaller who has exceeded the daily active shift ceiling.
- Never hardcode the 9-hour ceiling directly into database DDL constraints; maintain it as a configurable application business constant.

**Rationale:**  
Compliance with labor regulations and operational fatigue prevention. Protects call quality and lead conversion performance.

**Validation:**  
Review `telecaller_shift_gate_overlay.dart` and allocation eligibility checks.

**Affected Systems:**  
Shift Manager, Allocation Service, Telecaller UI.

---

### BUS-004 — Telecaller Inactivity Timeout & Auto-Break Policy
**Category:** BUSINESS POLICY  
**Severity:** MEDIUM  
**Status:** ACTIVE  

**Rule:**  
When a telecaller exhibits no mouse movement, keystrokes, or screen interactions for **5 consecutive minutes**, the system must automatically pause their shift, transition their status to `'BREAK'`, and pause the manual OFF timer.

**MUST:**
- Reset the idle timer upon any user interaction.
- Transition availability status from `'ACTIVE'` to `'BREAK'` at 300 seconds of detected inactivity.
- Resume active status seamlessly when the user interacts with the resume prompt.

**MUST NOT:**
- Never count inactivity break duration against the telecaller's 6-hour manual OFF allowance.

**Rationale:**  
Prevents idle telecallers who have walked away from their desk from continuing to receive urgent inbound leads that require immediate response.

**Validation:**  
Inspect `TelecallerShiftManager.onInactivityDetected()`.

**Affected Systems:**  
Telecaller Frontend Application, Allocation Engine.

---

### BUS-005 — Property Status Exclusivity
**Category:** BUSINESS POLICY  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
A property must possess exactly one active status at any given time, managed via `property_status_id`:
- `Available`: Property is actively marketed and ready for occupancy.
- `To Be Available`: Property is currently occupied or under development, becoming available on a specified future date.
- `Rented Out`: Property has executed an active rental agreement (Terminal / Inactive).
- `Sold Out`: Property has executed a sale deed (Terminal / Inactive).

**MUST:**
- Automatically transition `To Be Available` properties to `Available` on their scheduled availability date via nightly background cron.
- Disqualify `Rented Out` and `Sold Out` properties from all automated matching engine runs.

**MUST NOT:**
- Never permit a property to have null or multiple conflicting status flags.

**Rationale:**  
Guarantees clean inventory accounting and prevents marketing unavailable properties.

**Validation:**  
Verify `src/services/cron.service.js` nightly property availability update job.

**Affected Systems:**  
Properties Module, Matching Engine, Inventory Overview Dashboard.

---

### BUS-006 — Terminal Lead Status Mandatory Reason Capture
**Category:** BUSINESS POLICY  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Transitioning a lead or requirement to a terminal negative status (`NOT_INTERESTED`, `LOST`, `REJECTED_*`) requires a non-empty, categorized rejection reason and optional notes.

**MUST:**
- Require selection of a standardized canonical rejection reason code (e.g., `BUDGET_MISMATCH`, `LOCALITY_MISMATCH`, `NO_REQUIREMENT`, `ALREADY_RENTED`, `BROKER`, `OTHERS`).
- Persist the reason in `lead_status_history` and the entity's `rejection_reason` column.

**MUST NOT:**
- Never permit terminal transitions with null, empty, or whitespace-only reasons.

**Rationale:**  
Capturing rejection reasons is vital for marketing attribution analysis, property pricing feedback, and telecaller training.

**Validation:**  
Inspect backend status transition validation middleware in `requirements.controller.js` and `integrations.controller.js`.

**Affected Systems:**  
Lead Status Controller, Requirements Controller, Lost Lead Analysis Reports.

---

## 6. Source-of-Truth & Data Integrity Registry (`DATA`)

### DATA-001 — Master Entity Source-of-Truth Mapping
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Every core PropKart business entity has an authoritative PostgreSQL table, primary key, lifecycle status column, timestamp, and owner column. The Rulebook strictly prohibits **DIVERGENT DUPLICATE SOURCES OF TRUTH**, while explicitly recognizing legitimate relational children, event ledgers, staging representations, and external integration mirrors.

| Entity Type | Business Concept | Authoritative Table | Primary Key | Authoritative Status Column | Authoritative Timestamp | Authoritative Owner Column | Legitimate Relational Children / Projections |
|---|---|---|---|---|---|---|---|
| **Master Entity** | Individual Client Lead | `public.leads` | `id` (UUID) | `stage` & `allocation_status` | `created_at` | `assigned_telecaller_id` | `lead_status_history`, `lead_call_attempts` |
| **Integration Staging** | Campaign Sync Mirror | `public.integration_leads` | `id` (UUID = `leads.id`) | `campaign_status` | `received_at` | `assigned_telecaller_id` | Raw webhook payload mirror (1:1 with `leads`) |
| **Sales Entity** | Search Specification & Deal | `public.requirements` | `id` (UUID) | `status` | `created_at` | `assigned_to` | `requirement_configurations` |
| **Inventory Entity** | Real Estate Property | `public.properties` | `id` (UUID) | `property_status_id` (FK) | `created_at` | `created_by` / `admin_id` | `property_images`, `property_amenities` |
| **Historical Event** | Property Showing Event | `public.site_visits` | `id` (UUID) | `status` (`'COMPLETED'`) | `completed_at` | `sales_user_id` | Relational child of `requirements` & `properties` |
| **Historical Event** | Customer Activity Ledger | `public.followups` | `id` (UUID) | `status` | `followup_date` | `created_by` | Relational child of `leads` |
| **Identity Entity** | User Account | `public.users` | `id` (UUID) | `is_active` (boolean) | `created_at` | `organization_id` | `user_roles`, `telecaller_availability` |
| **Tenant Entity** | Brokerage Organization | `public.organizations` | `id` (UUID) | `is_active` (boolean) | `created_at` | `id` | Multi-tenant root container |
| **Operational State** | Telecaller Shift State | `public.telecaller_availability`| `user_id` (UUID) | `availability_status` | `last_heartbeat_at` | `user_id` | Realtime workload state projection |

**MUST:**
- Query authoritative tables for all canonical business reporting, dashboard metrics, and state machines.
- Treat `integration_leads` as a campaign-specific metadata extension sharing the primary key with `leads` (`leads.id = integration_leads.id`).
- Treat `site_visits` as the sole authoritative historical event ledger for completed property showings.

**MUST NOT:**
- Never create shadow tables or redundant tables representing the same core business entity (e.g., prohibited: `deleted_properties`, `archived_leads_copy`).
- Never query local cache (Isar), activity logs, or client-side storage as the authoritative source of an entity's current status.

**Rationale:**  
Divergent duplicate tables create synchronization drift, dual-source reporting conflicts, orphaned records, and permanent data corruption.

**Validation:**  
Review PostgreSQL schema. Verify zero unauthorized duplicate entity tables exist.

**Affected Systems:**  
All Backend Modules, Database Schema, Reports Service.

---

### DATA-002 — Phone Number Canonical Normalization
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
All telephone numbers ingested into or queried within PropKart must be normalized into a standard 10-digit numeric string stripped of international prefixes (`+91`, `91`), leading zeros, spaces, hyphens, and punctuation:
$$\text{sanitized\_phone} = \text{RegExpReplace}(\text{raw\_phone}, \text{'\\D'}, \text{''}) \rightarrow \text{Last 10 Digits}$$

**MUST:**
- Persist both raw user input (`phone`) and canonical normalized output (`sanitized_phone`).
- Execute all duplicate detection, search lookups, authentication matches, and campaign joins strictly against `sanitized_phone`.
- Ensure that `sanitized_phone` is populated via an automated pre-insert trigger or service normalization routine.

**MUST NOT:**
- Never execute equality comparisons (`phone = :input`) against unnormalized raw user strings.
- Never store invalid phone numbers with fewer than 10 digits in `sanitized_phone`.

**Rationale:**  
In India, customer phone numbers are entered with diverse formatting variations (`+91 98765 43210`, `09876543210`, `98765-43210`, `9876543210`). Failing to normalize creates duplicate lead records for the same individual.

**Validation:**  
Verify `src/services/leadIngestEngine.service.js` lines 12–28 (`sanitizePhone`). Assert all database rows have length 10 or are null.

**Affected Systems:**  
Lead Ingestion, Housing Integration, Meta Webhooks, Global Search.

---

### DATA-003 — Duplicate Prevention & Idempotency Governance
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Every entity creation and status mutation must explicitly define its duplicate identity contract and application-level idempotency protection across concurrent requests, retries, webhook replays, and offline sync replays.

**MUST:**
- Establish canonical uniqueness definitions:
  - Master Lead: Unique on `(sanitized_phone, organization_id)` where `deleted_at IS NULL`.
  - Property: Unique on `property_code` where `deleted_at IS NULL`.
  - Site Visit Event: Unique on `(requirement_id, completed_at)` where `completed_at IS NOT NULL`.
- Implement idempotent webhook handling using external transaction identifiers (`lead_id` / `form_id` / `event_id`). Replayed webhooks must update existing records and append campaign history without creating duplicate leads.
- Handle offline sync retry gracefully: repeated client outbox pushes of the same transaction must return the existing record (`HTTP 200`) without executing duplicate business side effects.

**MUST NOT:**
- Never rely solely on client-side duplicate checks.
- Never execute non-idempotent inserts in background workers or webhook listeners.

**Rationale:**  
Network retries, duplicate webhook deliveries from Meta/Housing, and offline client reconnects regularly resend identical payloads. Without strict idempotency, duplicate records and phantom notifications explode.

**Validation:**  
Send identical webhook payload twice within 100ms. Assert exactly 1 row created in `leads` and `enquiry_count = 2` in `integration_leads`.

**Affected Systems:**  
Lead Ingestion Engine, Meta/Housing Webhook Receivers, Outbox Sync Service.

---

## 7. Data Integrity & Deduplication Standards (`INTEG`)

### INTEG-001 — Cross-Vendor Global Ingestion Deduplication
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Inbound lead deduplication must evaluate globally across all marketing sources and vendors within the organization based on `sanitized_phone`. Deduplication must never be siloed by individual vendor source.

**MUST:**
- Upon receiving a lead from Meta, Housing, Website, or Manual entry, search for existing active records in `public.leads` where `sanitized_phone = :sanitized_phone AND organization_id = :org_id AND deleted_at IS NULL`.
- If an active lead exists:
  - Do NOT create a duplicate row in `public.leads`.
  - Increment `integration_leads.enquiry_count`.
  - Append the new campaign metadata to `integration_leads.campaign_history`.
  - Update `leads.updated_at = NOW()`.
  - Notify the assigned telecaller of the re-inquiry event.

**MUST NOT:**
- Never allow a lead from Meta and a lead from Housing with the same phone number to exist as two separate active unassigned leads in the calling queue.

**Rationale:**  
Customers frequently submit inquiries on both Housing.com and Facebook Ads for the same property. Siloed deduplication assigns the customer to two different telecallers, resulting in competing calls and unprofessional service.

**Validation:**  
Inspect `src/services/leadIngestEngine.service.js` lines 259–262. Verify global deduplication logic.

**Affected Systems:**  
Lead Ingestion Engine, Webhook Handlers, Telecaller Queue.

---

### INTEG-002 — Foreign Key Integrity & Prohibition of Naked UUIDs
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Every column referencing another table's primary key must be backed by a formal PostgreSQL `FOREIGN KEY` constraint. Storing naked, unconstrained UUIDs representing relational entities is strictly prohibited.

**MUST:**
- Back relational columns with explicit constraints:
  - `leads.assigned_telecaller_id` $\rightarrow$ `users(id) ON DELETE SET NULL`
  - `leads.assigned_to` $\rightarrow$ `users(id) ON DELETE SET NULL`
  - `leads.created_by` $\rightarrow$ `users(id) ON DELETE SET NULL`
  - `leads.organization_id` $\rightarrow$ `organizations(id) ON DELETE RESTRICT`
  - `requirements.telecaller_id` $\rightarrow$ `users(id) ON DELETE SET NULL`
  - `requirements.assigned_to` $\rightarrow$ `users(id) ON DELETE SET NULL`
  - `site_visits.sales_user_id` $\rightarrow$ `users(id) ON DELETE SET NULL`
  - `site_visits.requirement_id` $\rightarrow$ `requirements(id) ON DELETE CASCADE`
  - `site_visits.property_id` $\rightarrow$ `properties(id) ON DELETE SET NULL`

**MUST NOT:**
- Never create a table column containing a foreign UUID without a database-level `FOREIGN KEY` constraint.

**Rationale:**  
Lacking foreign key constraints permits orphaned records when parent users or organizations are modified or removed, causing relational joins in API queries to fail silently or return corrupted data.

**Validation:**  
Query `information_schema.table_constraints` for `leads` and `requirements`. Assert all relationship columns have `FOREIGN KEY` constraints.

**Affected Systems:**  
PostgreSQL Schema, All Repositories.

---

### INTEG-003 — Soft Deletion Uniformity & Deprecation of Shadow Tables
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Soft deletion must be implemented uniformly using a `deleted_at TIMESTAMPTZ` column on the core entity table. The practice of physically copying deleted rows into shadow tables (e.g., `deleted_properties`, `deleted_property_images`) is deprecated and prohibited for all entities.

**MUST:**
- Filter active records using `WHERE deleted_at IS NULL`.
- Filter recycled records using `WHERE deleted_at IS NOT NULL`.
- Soft-delete a record via `UPDATE ... SET deleted_at = NOW()`.
- Restore a record via `UPDATE ... SET deleted_at = NULL`.

**MUST NOT:**
- Never execute `INSERT INTO deleted_x SELECT * FROM x; DELETE FROM x;`.
- Never permanently hard-delete records from the active table without prior soft deletion and compliance retention clearance.

**Rationale:**  
Dual-table deletion schemes duplicate schema maintenance overhead, break foreign key relationships, corrupt activity history, and complicate restoration workflows.

**Validation:**  
Confirm that `public.properties` queries enforce `deleted_at IS NULL` and that `/recycle-bin` queries `properties WHERE deleted_at IS NOT NULL`.

**Affected Systems:**  
Properties Module, Recycle Bin, Admin Reports.

---

### INTEG-004 — Atomicity Classification for Multi-Table Operations
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Operations touching multiple tables must adhere to the PropKart **Atomicity Classification Framework**. Database mutations requiring atomic business consistency must execute transactionally, while external side effects must NEVER execute inside a database transaction block.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   PROPKART ATOMICITY CLASSIFICATION                    │
├─────────┬──────────────────────────┬───────────────────────────────────┤
│ Class A │ Strictly Atomic DB       │ Multiple database mutations that  │
│         │ Transaction              │ must succeed or fail together.    │
├─────────┼──────────────────────────┼───────────────────────────────────┤
│ Class B │ Eventually Consistent    │ Asynchronous background actions,  │
│         │ Event                    │ denormalized projections, caches. │
├─────────┼──────────────────────────┼───────────────────────────────────┤
│ Class C │ Independent Operations   │ Read telemetry, non-critical logs,│
│         │                          │ independent metric counters.      │
├─────────┼──────────────────────────┼───────────────────────────────────┤
│ Class D │ Transactional Outbox     │ External API calls, Webhooks, SMS,│
│         │ Required                 │ Push notifications, Email alerts. │
└─────────┴──────────────────────────┴───────────────────────────────────┘
```

**MUST:**
- Class A Operations (e.g., Lead Qualification + Requirement Creation; Site Visit Completion + Status Sync; Bulk Reallocation) must wrap in `BEGIN ... COMMIT` with immediate `ROLLBACK` on failure.
- Class D Operations must record intent in an outbox table within the DB transaction; the actual external HTTP/network call must execute **OUTSIDE** the database transaction block.

**MUST NOT:**
- Never place external network calls (WhatsApp API, SMS gateway, Housing webhook, Push notification) inside a PostgreSQL `BEGIN ... COMMIT` block.
- Never execute sequential, disconnected DB updates for Class A operations without transaction boundaries.

**Rationale:**  
Placing external network calls inside a DB transaction holds database connection locks open across high-latency external HTTP requests, rapidly exhausting connection pools and causing cascading database lock starvation.

**Validation:**  
Review `src/modules/requirements/requirements.service.js` and `src/services/notification.service.js`. Ensure zero `fetch()` or `axios` calls occur within active SQL transaction clients.

**Affected Systems:**  
All Backend Services, Database Connection Pool, Notification Engine.


---

## 8. Database Schema Governance (`DB`)

### DB-001 — Controlled Database Migration Standards
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Database schema evolution must follow controlled, versioned migration procedures. Changes must maintain backward compatibility, support concurrency-safe execution, and provide explicit forward-fix and rollback strategies.

**MUST:**
- Number migrations sequentially in `sql/migrations/` with clear semantic descriptors (e.g., `36_site_visit_historical_tracking.sql`).
- Ensure migrations execute under a single-writer migration lock (such as PostgreSQL advisory locks) to prevent concurrent execution during cluster deployments.
- Provide explicit operational recovery strategies:
  - **Application Rollback:** Revert backend application deployment while maintaining forward-compatible schema.
  - **Schema Rollback:** Reverse additive DDL using a pre-tested rollback script.
  - **Data Rollback:** Restore modified rows from pre-migration snapshot tables.
  - **Forward Fix:** Deploy a new additive patch migration to correct an incomplete migration state.
- Test migrations in staging against production-scale data before applying to production.

**MUST NOT:**
- Never execute ad-hoc, unversioned DDL statements directly against production databases via manual database clients without versioned migration files.
- Never drop production columns or tables in the same deployment release in which application code ceases referencing them.

**Rationale:**  
Uncontrolled database migrations cause cluster deployment race conditions, lock contention, schema drift across staging and production, and unrecoverable downtime.

**Validation:**  
Review migration files in `sql/migrations/`. Ensure all migrations are numbered, documented, and tested with forward-fix plans.

**Affected Systems:**  
PostgreSQL Engine, Deployment Pipelines, Migration Runners.

---

### DB-002 — Startup Additive Schema Runner
**Category:** CURRENT APPROVED IMPLEMENTATION  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
The PropKart backend currently executes additive schema synchronization during application initialization via `src/config/ensureAdditiveSchema.js`. This implementation is recognized as the current approved migration mechanism.

**MUST:**
- Maintain idempotent execution semantics within `ensureAdditiveSchema.js` using conditional DDL statements (`IF NOT EXISTS`, `OR REPLACE`, column existence queries).
- Log all executed schema assertions clearly to console output during startup.
- Wrap schema assertion blocks in try/catch handlers to log informative errors and prevent silent half-executed migrations.

**MUST NOT:**
- Never classify startup migration execution as an immutable permanent invariant; the platform may transition to an external CI/CD single-writer migration runner in future releases without violating core architectural principles.
- Never introduce destructive DDL commands (`DROP TABLE`, `DROP COLUMN`) into `ensureAdditiveSchema.js`.

**Rationale:**  
Startup schema synchronization simplifies development and single-instance deployments but must remain safely contained as an implementation pattern rather than a permanent architectural law.

**Validation:**  
Inspect `src/config/ensureAdditiveSchema.js`. Verify all DDL statements execute conditionally and log success metrics.

**Affected Systems:**  
Backend Server Initialization, Express Bootstrap.

---

### DB-003 — Non-Destructive Additive Schema Evolution
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
All database schema evolution must be strictly additive. Newly added columns must be nullable (`NULL`) or provide safe default values. Column renaming and table restructuring must follow the multi-release Expand/Contract deprecation lifecycle.

**MUST:**
- Follow the Three-Release Deprecation Lifecycle for schema changes:
  1. **Phase 1 (Expand):** Add new column/table additively; write to both old and new columns via backend dual-writing.
  2. **Phase 2 (Migrate):** Backfill historical data from old column to new column; switch reads to new column.
  3. **Phase 3 (Contract):** Deprecate and safely decommission old column after formal verification.

**MUST NOT:**
- Never add a column with `NOT NULL` without an immediate, safe default value on existing populated tables.
- Never execute destructive column drops without completing the three-phase deprecation cycle.

**Rationale:**  
Zero-downtime rolling deployments require running old application pods concurrently with new application pods. Non-additive schema changes instantly crash old pods that encounter missing columns.

**Validation:**  
Audit migration scripts for `NOT NULL` without `DEFAULT` clauses on non-empty tables.

**Affected Systems:**  
Database Schema, Rolling Deployments.

---

### DB-004 — Array vs Scalar Field Standards
**Category:** ENGINEERING STANDARD  
**Severity:** MEDIUM  
**Status:** ACTIVE  

**Rule:**  
Where business entities support multiple selections (e.g., requirement BHK configurations, property amenities), the schema must standardize on PostgreSQL array columns (`TEXT[]` / `UUID[]`) with appropriate GIN indexing, eliminating search bifurcations between legacy scalar fields and modern arrays.

**MUST:**
- Support multi-configuration search queries using PostgreSQL array containment operators (`@>`, `&&`).
- Maintain GIN indexes on multi-value array columns:
  ```sql
  CREATE INDEX IF NOT EXISTS idx_requirements_configuration_ids 
  ON public.requirements USING GIN (configuration_ids);
  ```

**MUST NOT:**
- Never maintain uncoordinated duplicate scalar and array columns (e.g., maintaining both `configuration_id` and `configuration_ids`) where queries arbitrarily check one and ignore the other.

**Rationale:**  
Maintaining competing scalar and array representations creates query bifurcations, inconsistent search results, and complex repository logic.

**Validation:**  
Review `public.requirements` schema. Verify array queries utilize indexed GIN containment operators.

**Affected Systems:**  
Requirements Module, Property Matching Engine, Search Controller.

---

## 9. Database Performance, Indexing & Query Architecture (`IDX` & `PERF`)

### IDX-001 — Evidence-Based Foreign Key & Relationship Indexing
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Foreign keys and frequently joined or filterable relationship columns must be indexed when workload patterns and query execution plans demonstrate the need. Indexes may be standalone, composite, partial, or covering, based on empirical performance validation.

**MUST:**
- Ensure high-frequency relationship columns are covered by appropriate B-tree or partial indexes:
  ```sql
  CREATE INDEX IF NOT EXISTS idx_leads_sanitized_phone 
  ON public.leads(sanitized_phone);

  CREATE INDEX IF NOT EXISTS idx_leads_org_created_at 
  ON public.leads(organization_id, created_at DESC);

  CREATE INDEX IF NOT EXISTS idx_leads_assigned_telecaller 
  ON public.leads(assigned_telecaller_id) 
  WHERE deleted_at IS NULL;

  CREATE INDEX IF NOT EXISTS idx_requirements_telecaller 
  ON public.requirements(telecaller_id) 
  WHERE deleted_at IS NULL;
  ```
- Use partial indexes (`WHERE deleted_at IS NULL`) where queries predominantly target active records, minimizing index footprint and write amplification.

**MUST NOT:**
- Never establish a dogmatic rule requiring every single foreign key to possess a dedicated standalone index regardless of table size or query patterns.
- Never deploy unindexed foreign keys on high-volume tables that participate in frequent joins or cascades.

**Rationale:**  
Unindexed foreign keys on active tables cause full table sequential scans during cascading updates or relational joins, degrading API response times from under 20ms to over 2,000ms. Conversely, redundant standalone indexes on rarely queried keys increase write overhead needlessly.

**Validation:**  
Run `EXPLAIN (ANALYZE, BUFFERS)` on relational join queries. Confirm index scans are utilized on high-traffic paths.

**Affected Systems:**  
PostgreSQL Query Planner, Ingestion Engine, Search Controller.

---

### IDX-002 — Workload-Driven Composite Index Design
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Composite indexes must be designed based on actual query patterns, filter predicates, sorting requirements, cardinality, and selectivity, and validated against PostgreSQL execution plans.

**MUST:**
- Design composite index column ordering to maximize index efficiency:
  1. **Leading Columns:** Equality filters and tenant scoping (`organization_id`).
  2. **Intermediate Columns:** Low/medium cardinality status flags (`allocation_status`, `stage`).
  3. **Trailing Columns:** Range predicates and sorting columns (`created_at DESC`, `waiting_since ASC`).
- Validate composite indexes using `EXPLAIN ANALYZE` to verify that the planner executes Index Scans or Index Only Scans rather than Bitmap Heap Scans with re-checks.

**MUST NOT:**
- Never adhere blindly to a rigid formula without query plan validation.
- Never place range columns or timestamps ahead of equality columns in composite indexes (e.g., `(created_at, organization_id)` is an anti-pattern when queries filter by `organization_id`).

**Rationale:**  
PostgreSQL B-tree index traversal can only perform index range checks on columns following the first range inequality. Placing range columns first neutralizes subsequent equality indexing benefits.

**Validation:**  
Inspect `pg_indexes` on `leads` and `requirements`. Run query plan validations on dashboard queue queries.

**Affected Systems:**  
PostgreSQL Query Planner, Admin Dashboard, Telecaller Workspace.

---

### PERF-001 — Performance-Based Query Plan Validation
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Production query performance must be validated using empirical execution plans. Unexpected or expensive sequential scans on production-critical queries must be investigated using `EXPLAIN (ANALYZE, BUFFERS)`, and indexes or query redesign introduced when evidence demonstrates meaningful performance improvement.

**MUST:**
- Benchmark production-critical queries (KPI aggregations, lead allocation queries, property matching, global search).
- Investigate queries where execution time exceeds 100ms or buffer read counts indicate excessive heap fetching.
- Recognize that PostgreSQL legitimately selects sequential scans on small tables ($<1,000$ rows) or cold paths where sequential I/O is faster than random index lookups.

**MUST NOT:**
- Never enforce an absolute, technically invalid rule requiring "zero sequential scans on tables over 1,000 rows".
- Never deploy new high-volume queries to production without `EXPLAIN ANALYZE` review.

**Rationale:**  
Query planner cost models choose sequential scans when tables fit within memory pages. Forcing index scans on small tables actually degrades performance. Optimization must be evidence-based, focusing on real execution time and buffer usage.

**Validation:**  
Run `EXPLAIN (ANALYZE, BUFFERS)` on top 10 backend API queries. Verify all queries execute in $<50$ms under normal load.

**Affected Systems:**  
All Backend Repositories, Database Performance Profiler.

---

### PERF-002 — Database Connection & Query Hygiene
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Backend services must maintain strict database connection and query hygiene, preventing connection leaks, N+1 query cascades, PostgREST URL length exhaustion, and unbounded memory buffering.

**MUST:**
- Utilize connection pooling with release guarantees: always release pool clients in a `finally` block (`client.release()`).
- Eliminate N+1 query patterns by using SQL batching, `IN` clauses, or `JOIN` operations.
- Bound dynamic query parameter lists: chunk batch operations to a maximum of 500 parameters to prevent PostgREST URL length limits and PostgreSQL parameter stack overflows.

**MUST NOT:**
- Never execute database queries in un-batched loops across list collections.
- Never leave connection pool clients unreleased in error catch blocks.

**Rationale:**  
Leaked connections exhaust pool capacity in minutes, crashing all backend API instances. N+1 queries multiply database roundtrips exponentially, destroying server response times.

**Validation:**  
Audit repository code for `try { ... } finally { client.release(); }` compliance.

**Affected Systems:**  
Database Connection Pool (`db.js`), All Services and Repositories.

---

## 10. Master Lead Lifecycle State Machine (`LEAD`)

### LEAD-001 — Canonical Lead State Machine & Status History Tracking
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Master leads in `public.leads` transition through strictly defined lifecycle milestones (`stage` and `allocation_status`). Every status transition must record an immutable audit entry in `public.lead_status_history`.

```text
[ INGESTION ]
     │
     ▼
[ NEW / UNASSIGNED_WAITING ]
     │
     ├─────────────────────────────────────────────────┐
     ▼ (Auto-Allocation via Engine)                   ▼ (No Active Telecallers)
[ ASSIGNED_TO_TELECALLER ]                       [ UNASSIGNED_WAITING (Queue) ]
     │
     ├───────────────────┬───────────────────┬───────────────────┐
     ▼                   ▼                   ▼                   ▼
  [ IN_CALL ]          [ CNR ]          [ CALLBACK ]      [ NOT_INTERESTED ]
     │                   │                   │                   │
     │ (Dial ended)      │ (Retry scheduled) │ (Schedule booked) │ (Lost reason captured)
     ▼                   ▼                   ▼                   ▼
  [ CONTACTED ]   [ Max Retries ]      [ Followup Table ]     [ LOST ]
     │                   │
     ▼                   ▼
[ QUALIFIED ]       [ LOST ]
     │
     ▼ (Handoff to Sales Closer)
[ HANDED_TO_SALES ] (stage = SALES, requirement created)
```

**MUST:**
- Record in `public.lead_status_history`: `lead_id`, `from_status`, `to_status`, `changed_by`, `changed_at`, and `reason`.
- Enforce mandatory rejection reason upon transitioning to `NOT_INTERESTED` or `LOST`.

**MUST NOT:**
- Never transition a lead backward from `HANDED_TO_SALES` to `UNASSIGNED_WAITING`.
- Never execute lead status updates without recording status history.

**Rationale:**  
Preserving complete status history is essential for conversion funnel auditing, telecaller accountability, and tracking customer journey milestones.

**Validation:**  
Inspect `src/modules/integrations/integrations.service.js` status transition methods. Assert history insertion.

**Affected Systems:**  
Lead Lifecycle Controller, Ingestion Service, Telecaller Queue.

---

### LEAD-002 — Lead Ingestion, Normalization & Campaign Staging
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Inbound marketing leads ingested from ad platforms (Meta Ads, Housing.com, Webhooks) must be normalized, staged in `public.integration_leads`, and mapped 1-to-1 to `public.leads` with global deduplication.

**MUST:**
- Assign the exact identical UUID to both records: `leads.id = integration_leads.id`.
- Normalize telephone numbers to 10 digits in `sanitized_phone`.
- Normalize vendor source strings to uppercase canonical codes (`'META'`, `'HOUSING'`, `'WEBHOOK'`, `'MANUAL'`).
- Record raw payload JSON in `integration_leads.raw_json` for auditability.

**MUST NOT:**
- Never create an `integration_leads` record without a corresponding parent `leads` record.
- Never store fragmented vendor source strings (`'Meta Ads'`, `'Housing Inbound'`).

**Rationale:**  
Uniform source codes and shared primary keys ensure zero orphaned records and simplify cross-system joins and campaign analytics.

**Validation:**  
Verify `src/services/leadIngestEngine.service.js`. Run SQL assertion: `SELECT COUNT(*) FROM integration_leads WHERE id NOT IN (SELECT id FROM leads)` equals 0.

**Affected Systems:**  
Ingestion Engine, Campaign Queue, Reports Module.

---

### LEAD-003 — Lead Qualification & Sales Handoff Transaction
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
The qualification of an outreach lead and its handoff to a sales closer must execute as an atomic Class A database transaction.

**MUST:**
- Wrap in a single transaction:
  1. Update `leads.allocation_status = 'HANDED_TO_SALES'` and `leads.stage = 'SALES'`.
  2. Update `leads.assigned_to = :sales_user_id` and `leads.sales_assigned_at = NOW()`.
  3. Create an active record in `public.requirements` with `assigned_to = :sales_user_id` and `telecaller_id = :telecaller_user_id`.
  4. Record entry in `public.lead_status_history`.
  5. Queue transactional outbox notification for the assigned sales representative.
- Roll back all changes if any constituent statement fails.

**MUST NOT:**
- Never mark a lead `HANDED_TO_SALES` without creating a corresponding requirement record.
- Never perform handoff across disconnected API calls.

**Rationale:**  
Partial failures during handoff create orphaned leads that disappear from the telecaller's queue without appearing in any salesperson's active pipeline.

**Validation:**  
Verify `src/modules/integrations/integrations.service.js` line 3480 (`transferLeadToSales`).

**Affected Systems:**  
Integrations Service, Requirements Service, Sales Pipeline.

---

## 11. Lead Allocation Engine & Concurrency Control (`ALLOC`)

### ALLOC-001 — Concurrency-Safe Round-Robin Allocation Invariant
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Lead allocation must be concurrency-safe, atomic, deterministic, auditable, and enforce fairness. A lead waiting in the intake queue must be allocated to exactly one eligible telecaller without race conditions.

**MUST:**
- Ensure eligibility checks evaluate:
  1. User account is active (`is_active = true` and `deleted_at IS NULL`).
  2. Role is strictly `'Telecaller'`.
  3. Availability status is explicitly `'ACTIVE'`.
  4. Heartbeat is fresh: `last_heartbeat_at > NOW() - INTERVAL '60 seconds'`.
  5. Current workload $< \text{max\_active\_workload}$.
  6. Shift limit is active: total active shift time $< 9$ hours in current day.
  7. Manual OFF allowance is valid: manual OFF time $< 6$ hours in 24-hour cycle.
- Order queue deterministically: Priority (`HOT` before `NORMAL`), then FIFO (`waiting_since ASC`).
- Distribute fairly: Allocate to the eligible telecaller with the oldest `last_allocated_at` timestamp.

**MUST NOT:**
- Never allocate leads to telecallers with status `'BREAK'`, `'INACTIVE'`, or `'LOGGED_OUT'`.
- Never execute allocation loops outside database row locks.

**Rationale:**  
Under high-volume concurrent webhook ingestion, parallel workers without row locks read identical state and allocate the same lead to multiple telecallers simultaneously.

**Validation:**  
Inspect PostgreSQL stored procedure `allocate_waiting_leads`.

**Affected Systems:**  
Allocation Service, Cron Scheduler, Telecaller Shift Manager.

---

### ALLOC-002 — Stored Procedure Implementation
**Category:** CURRENT APPROVED IMPLEMENTATION  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
The PropKart backend currently executes automated round-robin lead allocation via the PostgreSQL stored procedure `allocate_waiting_leads` utilizing `FOR UPDATE SKIP LOCKED`. This implementation is recognized as the current approved allocation mechanism.

**MUST:**
- Use `FOR UPDATE SKIP LOCKED` when locking candidate lead rows and candidate telecaller availability rows.
- Update `telecaller_assigned_at`, `last_allocated_at`, and `current_workload` within the same procedure execution.

**MUST NOT:**
- Never freeze this specific stored procedure as an immutable invariant; future implementations may transition to alternative distributed queue engines (e.g., Redis Streams / BullMQ) provided the core invariant (`ALLOC-001`) is preserved.

**Rationale:**  
`FOR UPDATE SKIP LOCKED` in PostgreSQL allows parallel workers to skip rows currently locked by concurrent transactions, preventing deadlocks and race conditions.

**Validation:**  
Review migration `allocate_waiting_leads` in PostgreSQL.

**Affected Systems:**  
PostgreSQL Stored Procedures, Lead Ingest Engine.

---

### ALLOC-003 — Telecaller Heartbeat & Availability State Management
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Active telecallers must maintain a fresh heartbeat timestamp in `public.telecaller_availability`. Failure to pulse a heartbeat within 60 seconds marks the telecaller stale, pausing inbound lead allocation.

**MUST:**
- Emit client heartbeat ping every 30 seconds while the telecaller app is foregrounded and active.
- Automatically exclude telecallers whose `last_heartbeat_at` is older than 60 seconds from candidate allocation sets.

**MUST NOT:**
- Never allocate leads to a client device that has lost network connectivity or terminated its session.

**Rationale:**  
Prevents allocating leads to telecallers whose browser or app crashed without a clean logout, stranding urgent leads in unmonitored queues.

**Validation:**  
Review `TelecallerAvailabilityBloc` in Flutter and `AllocationService.pulseHeartbeat()` in backend.

**Affected Systems:**  
Telecaller Frontend, Realtime Availability Monitor.

---

## 12. User Lifecycle & Organizational Governance (`USR`)

### USR-001 — User Creation, Role Transition & Deactivation Impact Governance
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Whenever a user account is created, activated, deactivated, role-changed, transferred between teams, or removed, the engineering modification must evaluate and address the 360-degree impact across RBAC, ownership, workload, allocation, reporting, and historical attribution.

```text
USER LIFECYCLE EVENT
  ├── RBAC: Route permissions & token invalidation
  ├── Ownership: Active assigned leads, active requirements, managed properties
  ├── Workload: Allocation capacity & round-robin queue eligibility
  ├── Availability: Shift tracking, heartbeats, and timer cleanups
  ├── Reporting: Historical KPI attribution (closed deals remain attributed)
  └── Audit: User lifecycle audit log entry emitted
```

**MUST:**
- Evaluate the 8 core dimensions upon any user state transition:
  1. **RBAC:** Invalidate active JWT sessions upon deactivation or role modification.
  2. **Active Lead Reassignment:** Reassign active uncompleted leads to an active colleague or return to the unassigned queue.
  3. **Historical Attribution:** Retain historical `created_by`, `sales_user_id`, and `telecaller_id` foreign keys on closed deals and completed site visits (`ON DELETE SET NULL` or soft-deactivation).
  4. **Allocation Eligibility:** Remove deactivated telecallers immediately from round-robin eligibility.
  5. **Team Visibility:** Update property attribution masking scopes upon team transfers.
  6. **KPI Continuity:** Ensure historical reports continue to attribute past performance to the user account.
  7. **Audit Trail:** Record the user transition in `public.audit_logs`.
  8. **Notification Cleanup:** Dismiss or reassign unread action notifications.

**MUST NOT:**
- Never hard-delete a user account that has participated in historical business transactions.
- Never simply insert a user into `public.users` without initializing their role, organization, and availability records.

**Rationale:**  
Treating user provisioning or deactivation as an isolated table row edit creates dangling leads, broken foreign keys, orphaned notifications, and distorted historical sales reports.

**Validation:**  
Inspect `src/modules/users/users.service.js` deactivation workflow. Confirm lead reassignment and session invalidation.

**Affected Systems:**  
User Management Service, RBAC Middleware, Lead Allocation Engine, Sales Reports.

---

### USR-002 — User Account Deactivation vs Lead Reassignment Protocol
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Deactivating a user account requires an explicit lead reassignment decision. Active leads cannot be left assigned to an inactive user.

**MUST:**
- Prompt the administrator during deactivation to select:
  - Option A: Bulk reassign active leads and requirements to another specified active user.
  - Option B: Return active leads to the unassigned queue (`UNASSIGNED_WAITING`).
- Execute the deactivation and reassignment within an atomic Class A database transaction.

**MUST NOT:**
- Never permit an account with active unfinished leads to be marked `is_active = false` without handling active assignments.

**Rationale:**  
Leaves assigned to inactive users become invisible "dead leads" that receive zero follow-up, causing severe customer churn.

**Validation:**  
Test user deactivation API endpoint with active assigned leads. Confirm rejection if reassignment payload is missing.

**Affected Systems:**  
User Administration Controller, Allocation Engine.

---

## 13. Property Inventory Lifecycle & Availability (`PROP`)

### PROP-001 — Property Serial Code Generation & Atomic Uniqueness
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Every property inventory unit must possess a globally unique serial code (e.g., `PR-0001`, `PR-0144`) generated via an atomic database sequence.

**MUST:**
- Enforce database uniqueness:
  ```sql
  CREATE UNIQUE INDEX idx_properties_code 
  ON public.properties(property_code) 
  WHERE deleted_at IS NULL;
  ```
- Generate code atomically during insertion using a PostgreSQL sequence:
  ```sql
  'PR-' || LPAD(nextval('properties_code_seq')::text, 4, '0')
  ```

**MUST NOT:**
- Never allow manual editing of `property_code` after creation.
- Never generate property codes using non-atomic client-side counters.

**Rationale:**  
Property codes are referenced by sales agents, clients, and marketing signage. Atomic sequences prevent duplicate code collisions during concurrent property creation.

**Validation:**  
Review migration `properties_code_seq`. Verify unique index on `property_code`.

**Affected Systems:**  
Properties Service, Property Serializer, Search Engine.

---

### PROP-002 — Property Lifecycle Status Transitions & Automated Nightly Availability Cron
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Properties transition through exclusive lifecycle statuses. Properties scheduled as `To Be Available` must be automatically promoted to `Available` on their effective date via a nightly background cron job.

**MUST:**
- Execute nightly cron job at 00:05 IST:
  ```sql
  UPDATE public.properties
  SET property_status_id = (SELECT id FROM property_status WHERE name = 'Available')
  WHERE property_status_id = (SELECT id FROM property_status WHERE name = 'To Be Available')
    AND available_from <= CURRENT_DATE
    AND deleted_at IS NULL;
  ```
- Disqualify `Rented Out` and `Sold Out` properties from the matching engine.

**MUST NOT:**
- Never require manual administrator intervention to activate scheduled `To Be Available` properties.

**Rationale:**  
Automating scheduled inventory activation ensures that properties ready for viewing enter the matching engine immediately without administrative delay.

**Validation:**  
Review `src/services/cron.service.js` lines 9–74.

**Affected Systems:**  
Cron Scheduler, Properties Repository, Matching Engine.

---

### PROP-003 — Property Inventory Governance Checklist
**Category:** ENGINEERING STANDARD  
**Severity:** MEDIUM  
**Status:** ACTIVE  

**Rule:**  
Every property management feature must adhere to the PropKart Property Inventory Checklist, covering data source, ownership, media, pricing, deduplication, search indexing, and recycle bin management.

**MUST:**
- Verify during feature design:
  1. **Source of Truth:** Authoritative table is `public.properties`.
  2. **Ownership:** Creator attribution recorded in `created_by`.
  3. **Media:** Property images stored in `property_images` with ordering index.
  4. **Pricing:** Separate monthly rent from security deposit.
  5. **Deduplication:** Check for duplicate unit/floor/building in same locality.
  6. **Matching Impact:** Verify updates trigger match recalculation.
  7. **Recycle Bin:** Deletion sets `deleted_at = NOW()`; restoration clears it.

**MUST NOT:**
- Never implement property deletion via physical row copying to shadow tables.

**Rationale:**  
Ensures end-to-end data integrity across property inventory workflows.

**Validation:**  
Verify against Property Checklist prior to merging property feature changes.

**Affected Systems:**  
Properties Module, Recycle Bin, Matching Service.

---

## 14. Requirement Lifecycle & Consultation Pipeline (`REQ`)

### REQ-001 — Requirement Sales Pipeline State Machine
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
A sales requirement in `public.requirements` represents a buyer or tenant search profile and progresses through the canonical sales pipeline state machine.

```text
[ NOT_STARTED ]
      │
      ▼
  [ ASSIGNED ]
      │
      ├───────────────────┬───────────────────┐
      ▼                   ▼                   ▼
[ CALL_ATTEMPTED ]   [ FOLLOW_UP ]     [ NOT_INTERESTED ]
      │                   │
      ▼                   ▼
 [ INTERESTED ] ◄─────────┘
      │
      ▼
[ SITE_VISIT_SCHEDULED ]
      │
      ▼
[ SITE_VISIT_DONE ] (Immutable historical event synced)
      │
      ├───────────────────┬───────────────────┐
      ▼                   ▼                   ▼
[ NEGOTIATION ]     [ FOLLOW_UP ]       [ REJECTED_* ]
      │                                       │
      ▼                                       ▼
    [ WON ]                                [ LOST ]
```

**MUST:**
- Enforce that transitioning to `Site Visit Done` invokes the authoritative site visit synchronization handler (`SITE-001`).
- Ensure that transitioning to `Won` records the final deal value and closes the requirement.
- Require selection of specific rejection reason codes when transitioning to `REJECTED_*`.

**MUST NOT:**
- Never permit repository-level silent rewrites of canonical statuses (e.g., prohibited: rewriting legacy `Live` to `Interested` silently without audit).
- Never allow a requirement to transition from `Won` back to active pipeline without Super Admin authorization.

**Rationale:**  
Preserving consistent pipeline states ensures accurate sales forecasting, conversion tracking, and deal attribution.

**Validation:**  
Inspect `src/modules/requirements/requirements.repository.js`. Verify state transitions validate against canonical enum registry.

**Affected Systems:**  
Requirements Service, Sales Dashboard, Sales Reports.

---

### REQ-002 — Requirement Multi-Configuration Array & Area Range Modeling
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Requirements must capture buyer/tenant configuration preferences as an array of accepted configurations (`configuration_ids`) and physical area boundaries as a range (`min_area`, `max_area`).

**MUST:**
- Model accepted configurations using `configuration_ids UUID[]` or standardized textual tags.
- Model area preferences using `min_area NUMERIC` and `max_area NUMERIC` representing carpet area in square feet.
- Provide the property matching engine with full access to both configuration arrays and area ranges.

**MUST NOT:**
- Never restrict requirements to a single scalar configuration when buyers frequently accept multiple options (e.g., both 2BHK and 3BHK).

**Rationale:**  
Buyers rarely search for exactly one configuration. Modeling preferences as arrays and ranges reflects real-world search behavior and prevents artificially depressed matching scores.

**Validation:**  
Review `public.requirements` schema. Verify `configuration_ids`, `min_area`, and `max_area` columns exist and are queried.

**Affected Systems:**  
Requirements Form, Matching Engine, Search Controller.

---

## 15. Site Visit Historical Tracking & Outcome Lifecycle (`SITE`)

### SITE-001 — Completed Site Visit Immutability & Outcome Evolution
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
A completed site visit is an **immutable historical business event**. Once a site visit is marked completed (`status = 'COMPLETED'`, `completed_at IS NOT NULL`), changing the parent requirement's or lead's status afterward (e.g., to *Rejected*, *Not Interested*, or *Won*) must **NEVER** delete, overwrite, or decrement the completed site visit record in `public.site_visits`.

**MUST:**
- Store historical visit completions in `public.site_visits` with:
  - `status = 'COMPLETED'`
  - `completed_at` populated with the exact completion timestamp.
  - `sales_user_id` identifying the attending salesperson.
  - `outcome` recording downstream progress (`'INTERESTED'`, `'DEAL_WON'`, `'REJECTED_AFTER_VISIT'`, `'FOLLOW_UP'`).
- When a requirement or lead transitions to `Rejected` after a visit, update:
  - `site_visits.outcome = 'REJECTED_AFTER_VISIT'`
  - `site_visits.outcome_at = NOW()`
  - Retain `site_visits.status = 'COMPLETED'`.
- When a requirement or lead transitions to `Won` after a visit, update:
  - `site_visits.outcome = 'DEAL_WON'`
  - `site_visits.outcome_at = NOW()`
  - Retain `site_visits.status = 'COMPLETED'`.
- Enforce the KPI invariant:
  $$\Delta(\text{Site Visits Done}) = 0 \quad \text{when lead transitions from Site Visit Done to Rejected}$$
  $$\Delta(\text{Rejected After Site Visit}) = +1$$

**MUST NOT:**
- Never delete or modify `status = 'COMPLETED'` or clear `completed_at` in `public.site_visits`.
- Never decrement the "Site Visits Done" KPI when a deal is subsequently lost or won.

**Rationale:**  
Sales representatives conduct property showings regardless of whether the customer ultimately closes the deal. Erasing completed site visits upon rejection destroys employee achievement records and distorts brokerage performance analytics.

**Validation:**  
Inspect `src/modules/requirements/requirements.service.js` line 35 (`syncHistoricalSiteVisitOnRequirementStatus`). Run verification test asserting Site Visits Done remains invariant after rejection.

**Affected Systems:**  
Site Visits Module, Requirements Service, KPI Service, Admin Dashboard, Sales Performance Report.

---

### SITE-002 — Idempotent Site Visit Synchronization & Unique Constraint
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Status transition handlers that synchronize site visit records must execute idempotently. Multiple saves, edits, or API retries on the same requirement must never create duplicate completed site visit records.

**MUST:**
- Check for existing completed site visits for the `requirement_id` prior to inserting a new row.
- Enforce the database unique constraint:
  ```sql
  CREATE UNIQUE INDEX IF NOT EXISTS uq_site_visits_req_completed 
  ON public.site_visits(requirement_id, completed_at) 
  WHERE requirement_id IS NOT NULL AND completed_at IS NOT NULL;
  ```

**MUST NOT:**
- Never execute blind `INSERT INTO site_visits` on requirement updates without conflict checks.

**Rationale:**  
Network retries and multiple edits on a requirement screen would otherwise insert duplicate visit events, artificially inflating site visit counts.

**Validation:**  
Review migration `39_deduplicate_site_visits_and_unique_constraint.sql`.

**Affected Systems:**  
Requirements Service, Integrations Service.

---

### SITE-003 — Verification of All Status-Update Paths Reaching Site Visit Synchronization
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
EVERY code path across the entire backend that transitions a lead, requirement, or campaign lead to `Site Visit Done` MUST route through the authoritative historical synchronization mechanism:
$$\text{Status = Site Visit Done} \implies \text{Authoritative site\_visits sync} \implies \text{site\_visits.status = 'COMPLETED'} \land \text{completed\_at populated}$$

**MUST:**
- Route all requirement status updates through `RequirementsService.updateRequirement` or direct invocation of `syncHistoricalSiteVisitOnRequirementStatus`.
- Enforce that if a lead or campaign status transition triggers a site visit completion, it synchronizes the associated requirement and persists the completed visit in `public.site_visits`.

**MUST NOT:**
- Never introduce a legacy, mobile, bulk, or webhook endpoint that updates status to `Site Visit Done` without executing historical site visit synchronization.

**Rationale:**  
Bypassing the synchronization helper on alternative API endpoints causes site visits to be recorded in mutable status columns but omitted from historical event ledgers, producing cross-screen reporting divergence.

**Validation:**  
Run end-to-end audit searching all controllers for `SITE_VISIT_DONE` / `Site Visit Done`. Assert every transition path invokes the authoritative sync service.

**Affected Systems:**  
Requirements Controller, Integrations Controller, Mobile Sync Endpoints.


---

## 16. Property Matching Engine Architecture & Policies (`MATCH`)

### MATCH-001 — Two-Stage Matching Architecture
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
The property matching engine must strictly evaluate **Stage 1: Hard Disqualification Filters** before computing **Stage 2: Weighted Soft Scoring**. Stage 1 failure produces an immediate, unconditional disqualification with a score of 0. Soft scoring must be deterministic, mathematically transparent, and explainable.

```text
[ INCOMING REQUIREMENT ]
          │
          ▼
┌────────────────────────────────────────────────────────┐
│ STAGE 1: HARD DISQUALIFICATION FILTERS                 │
│  - Property Status: Active & Marketable?               │
│  - Listing Type: Rent vs Resale compatible?            │
│  - Location: Cities compatible?                        │
└────────────────────────────────────────────────────────┘
          │
          ├── [ FAIL ANY FILTER ] ──► DISQUALIFIED (Score = 0)
          │
          ▼ [ PASS ALL FILTERS ]
┌────────────────────────────────────────────────────────┐
│ STAGE 2: WEIGHTED SOFT SCORING (Max 100 Points)        │
│  - Location & Area Proximity Score                     │
│  - Configuration / BHK Compatibility Score             │
│  - Budget & Financial Alignment Score                  │
│  - Carpet Area Tolerance Score                         │
│  - Property Type & Category Score                      │
└────────────────────────────────────────────────────────┘
          │
          ▼
[ NORMALIZED MATCH SCORE (0 - 100) + DETAILED EXPLANATION BREAKDOWN ]
```

**MUST:**
- Disqualify properties immediately with score 0 if:
  1. Property status is `Sold Out`, `Rented Out`, `Inactive`, or `Do Not Disturb`.
  2. Listing type conflicts (Rent vs Resale).
  3. City conflicts when cities are specified and mismatched.
- Return both a normalized aggregate score (0 to 100) and an explainable breakdown object documenting points awarded per dimension.

**MUST NOT:**
- Never award soft scoring points to a property that failed any Stage 1 hard filter.
- Never execute matching using opaque, non-deterministic heuristics.

**Rationale:**  
Evaluating soft points for unavailable or listing-type-incompatible properties creates false positives, wasting agent and client time on invalid showings.

**Validation:**  
Review `src/modules/matching/matching.service.js` lines 261–445. Test disqualified properties to verify 0 score and empty score breakdown.

**Affected Systems:**  
Matching Engine, Sales Consultation Workspace, Client Recommendation Portal.

---

### MATCH-002 — Configurable Matching Scoring Weights & Business Policies
**Category:** BUSINESS POLICY  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Specific scoring weights, area tolerances, and presentation thresholds in the matching engine are **Configurable Business Policies**, not permanent engineering invariants. They must be centrally defined, versioned, and auditable.

**Current Approved Business Configuration:**
- Total Score Ceiling: **100 points**
- Minimum Display Threshold: **60 points** (Properties scoring $<60$ hidden from default recommendations)
- Location & Proximity Weight: **25 points**
- Configuration / BHK Weight: **25 points**
- Budget & Price Alignment Weight: **30 points**
- Carpet Area Alignment Weight: **10 points** (with default $\pm 20\%$ tolerance)
- Property Category Compatibility: **10 points**

**MUST:**
- Maintain scoring weights and tolerances in central configuration objects (`src/modules/matching/matching.config.js`).
- Support future modifications to weights or tolerances without requiring Rulebook constitutional amendments.

**MUST NOT:**
- Never hardcode scoring weights across scattered SQL queries or frontend widgets.

**Rationale:**  
Business priorities between location, price, and unit size evolve with market dynamics and seasonal campaigns. Decoupling configuration from core engine architecture enables business agility while preserving algorithmic integrity.

**Validation:**  
Inspect `src/modules/matching/matching.config.js` for central weight definitions.

**Affected Systems:**  
Matching Service, Configuration Manager.

---

### MATCH-003 — Rental Budget & Security Deposit Evaluation Separation
**Category:** ENGINEERING STANDARD  
**Severity:** MEDIUM  
**Status:** ACTIVE  

**Rule:**  
When evaluating rental requirements against properties, the matching engine must evaluate monthly rent against the tenant's monthly budget, and security deposit against the tenant's deposit capacity separately.

**MUST:**
- Compare monthly rent against `budget_from` and `budget_to`.
- Compare security deposit against dedicated deposit fields when specified.

**MUST NOT:**
- Never lump monthly rent and security deposit together into a single gross figure that skews monthly budget scoring.

**Rationale:**  
Tenants have distinct constraints for ongoing monthly rent versus upfront capital deposits. Conflating the two produces distorted financial alignment scores.

**Validation:**  
Inspect `MatchingService.evaluateProperty` financial calculation subroutine.

**Affected Systems:**  
Matching Service, Rental Matching Filter.

---

## 17. KPI Governance & Semantic Equivalence Architecture (`KPI`)

### KPI-001 — KPI Semantic Equivalence Rule
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Every occurrence of a KPI across the platform must share an identical **Canonical Semantic Contract**. A KPI implementation is compliant when different query shapes (e.g., org-wide aggregation, user-specific aggregation, grouped reports, paginated drilldowns, streaming exports) produce the same canonical numerical result for the same scope and filter parameters.

**Mandatory Canonical Semantic Contract:**
Every KPI must share identical:
1. **Canonical KPI System Key** (e.g., `site_visits_done`)
2. **Canonical Business Definition**
3. **Mathematical Formula**
4. **Authoritative Source Table**
5. **Inclusion and Exclusion Predicates**
6. **Date Semantics** (Cohort creation date vs Action execution date)
7. **Timezone Boundary Semantics** (IST Asia/Kolkata)
8. **Tenant Scope** (`organization_id`)
9. **Deduplication Rule** (e.g., `COUNT(DISTINCT site_visits.id)`)

**Permitted Query Variations:**
Different SQL implementations are explicitly permitted across:
- Organization-wide aggregate summaries
- Individual user performance cards
- Grouped cohort reports by source or telecaller
- Detailed drilldown list views
- Streaming CSV / Excel exports
provided they evaluate to the exact same canonical business contract.

**MUST NOT:**
- Never require the exact same identical SQL string across all surfaces when query shapes naturally require different groupings, projections, or pagination envelopes.
- Never implement ad-hoc filter criteria in a screen controller that alters the canonical business definition of a metric.

**Rationale:**  
A single rigid SQL query cannot serve an executive high-level summary card, an unpaginated streaming CSV export, and a paginated Flutter infinite scroll list simultaneously. Enforcing semantic equivalence guarantees consistent numbers while allowing performant, specialized query implementations.

**Validation:**  
Run cross-surface reconciliation test. Compare executive dashboard value against aggregated drilldown count for the same date window. Assert $\text{Difference} = 0$.

**Affected Systems:**  
Dashboard Controller, Reports Service, Export Service, Flutter BLoCs.

---

### KPI-002 — Strict Indian Standard Time (IST) Boundary Rule
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
All temporal date-filter aggregations (*Today*, *Yesterday*, *Weekly*, *Monthly*, *Yearly*, *Custom Range*) must evaluate day boundaries strictly in **Indian Standard Time (IST / Asia/Kolkata, UTC+5:30)**:
$$\text{Day Start} = \text{00:00:00.000 IST} \quad (\text{18:30:00.000 UTC Previous Day})$$
$$\text{Day End} = \text{23:59:59.999 IST} \quad (\text{18:29:59.999 UTC Current Day})$$

**MUST:**
- Apply explicit timezone conversions in SQL:
  ```sql
  (created_at AT TIME ZONE 'Asia/Kolkata')::date = (NOW() AT TIME ZONE 'Asia/Kolkata')::date
  ```
- Apply IST conversions uniformly across inventory overview queries, lead counts, and sales metrics.

**MUST NOT:**
- Never use UTC day boundaries (`CURRENT_DATE` in raw UTC) for business reporting.

**Rationale:**  
Evaluating day boundaries in UTC creates a 5.5-hour operational reporting skew, distorting daily counts and causing morning dashboards to under-report activity.

**Validation:**  
Review `src/modules/dashboard/kpi.service.js` line 14 (`getIstDateRange`).

**Affected Systems:**  
Dashboard KPIs, Reports Service, Daily Telecaller Counts.

---

### KPI-003 — Cohort vs Action Date Metric Separation
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Metrics evaluating cohort progression (e.g., *"Leads Allocated from This Week's Intake"*) must filter strictly by `leads.created_at`. Metrics evaluating operational activity volume (e.g., *"Total Allocation Events Executed This Week"*) must filter by `telecaller_assigned_at` and be labeled distinctly as **Activity Volume**.

**MUST:**
- Enforce the mathematical guarantee for cohort metrics:
  $$\text{Leads Allocated} \le \text{Total Ingested Leads}$$
- Label activity metrics explicitly (e.g., `activity_allocated`, `calls_dialed_today`).

**MUST NOT:**
- Never label an action-volume metric with a cohort name.

**Rationale:**  
Conflating cohort conversion with daily operational activity produces impossible figures (e.g., 1,095 allocated out of 163 intake leads), destroying executive trust in analytics.

**Validation:**  
Verify `src/modules/dashboard/kpi.service.js` line 42 (`leads_allocated` cohort query).

**Affected Systems:**  
Admin Dashboard KPI Card 7, Business Insights Reports.

---

### KPI-004 — Authoritative Data Model Precondition
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
If the existing PostgreSQL database schema cannot represent a proposed KPI's historical truth, **THE IMPLEMENTATION MUST STOP IMMEDIATELY**. Under no circumstances may an engineer fake a KPI from mutable current status, compute it from incomplete client-side cache, or introduce a Flutter-only in-memory counter.

**MUST:**
- Halt frontend and API implementation if database columns or event tables required for historical tracking are missing.
- Extend the authoritative schema via an additive migration first, establishing the necessary event ledger and timestamps before building the KPI.

**MUST NOT:**
- Never calculate historical metrics by counting current mutable statuses (e.g., counting Site Visits Done by filtering `lead.status = 'SITE_VISIT_DONE'`).
- Never compute system metrics via in-memory Dart loops over partial paginated client lists.

**Rationale:**  
Faking metrics from current status causes numbers to decay and distort as entities progress through subsequent lifecycle stages (e.g., completed visits disappearing upon deal rejection).

**Validation:**  
Review KPI Addition Protocol (`KPI-PROTO-02`). Verify data model existence before approving new KPI PRs.

**Affected Systems:**  
Database Schema, Backend KPI Service, Flutter Dashboard BLoCs.

---

## 18. Cross-Screen Consistency Standards (`CONSISTENCY`)

### CONSISTENCY-001 — Same Fact, Same Answer Rule
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Whenever the same business fact appears across multiple platform surfaces:
- Telecaller Dashboard
- Sales Dashboard
- Admin Master Dashboard
- Business Reports & Insights
- Executive KPI Cards
- Detailed Drilldown Lists
- Streaming Spreadsheet Exports
- Push Notifications & SMS
- Mobile, Web & Desktop interfaces

the displayed numeric value must reconcile to the **same canonical business definition for the same scope and filter parameters**. Any difference must be explainable through documented scope parameters (e.g., organization scope vs individual user scope).

```text
┌────────────────────────────────────────────────────────┐
│               CANONICAL SOURCE OF TRUTH                │
│         PostgreSQL Database (Port 54350/54329)         │
└──────────────────────────┬─────────────────────────────┘
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
       [ DASHBOARD ]  [ REPORTS ]  [ EXPORTS ]
             │             │             │
             └─────────────┼─────────────┘
                           │
                           ▼
          RECONCILIATION RESULT: DELTA = 0
```

**MUST:**
- Ensure that if Admin Dashboard displays 11 Completed Site Visits for a date range, the drilldown list displays exactly 11 rows, the exported Excel file contains exactly 11 rows, and the Sales Reports aggregate to 11.
- Document scope parameters explicitly:
  - **Aggregation Scope:** Organization Total vs Team Total vs User Total.
  - **Temporal Scope:** Today vs Week vs Month vs Custom IST Range.
  - **Lifecycle Scope:** Active records (`deleted_at IS NULL`) vs Recycled records.

**MUST NOT:**
- Never allow cross-screen numerical discrepancies to arise from accidental differences in SQL filter clauses or timezone parsing.

**Rationale:**  
Inconsistent numbers across screens erode managerial trust in the CRM, spark disputes over sales commissions, and lead to poor operational decisions.

**Validation:**  
Execute cross-screen reconciliation script. Assert $\text{Delta} = 0$ across all 6 surfaces.

**Affected Systems:**  
All Dashboards, Reports Modules, Drilldowns, and Export Controllers.

---

### CONSISTENCY-002 — Cross-Screen Metric Scope & Aggregation Rules
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
When decomposing an organization-level metric across individual user cards or regional teams, the sum of individual subsets must mathematically equal the total, minus explicitly accounted-for unassigned or cross-team records:
$$\text{Total Org Leads} = \sum_{i} \text{User Leads}_i + \text{Unassigned Leads}$$

**MUST:**
- Explicitly display unassigned records on executive screens to bridge the reconciliation gap between individual user sums and organizational totals.
- Reconcile ownership transfers in realtime across both source and destination user dashboards.

**MUST NOT:**
- Never hide unassigned records from organizational totals, which would create unexplained gaps between system totals and user aggregations.

**Rationale:**  
Managers reconciling team workloads require total transparency into where every lead resides.

**Validation:**  
Run organizational rollup query: assert $\sum \text{User Workloads} + \text{Unassigned Queue} = \text{Total System Leads}$.

**Affected Systems:**  
Admin Dashboard, Allocation Monitor, Team Performance Reports.

---

## 19. Reports, Analytics & Streaming Exports (`REP`)

### REP-001 — Server-Side Streaming Data Exports
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Spreadsheet exports (CSV / Excel) of collections (`leads`, `requirements`, `properties`, `audit_logs`) must be processed and streamed directly from the backend server. Client-side export generators in Flutter that truncate data to currently loaded UI page rows are strictly prohibited.

**MUST:**
- Provide dedicated streaming export endpoints:
  - `/api/v1/export/leads`
  - `/api/v1/export/requirements`
  - `/api/v1/export/properties`
- Stream data directly from PostgreSQL using cursor-based query streams or chunked batching.
- Enforce tenant isolation and role permission filtering during streaming export generation.

**MUST NOT:**
- Never implement Flutter client-side exports that only dump records currently loaded in memory or on the current UI pagination page.
- Never buffer entire multi-gigabyte export files in Node.js server RAM prior to sending.

**Rationale:**  
Client-side page exports truncate large datasets silently, exporting only 20–50 rows instead of thousands, which creates incomplete and misleading business reports.

**Validation:**  
Review `lib/features/properties/screens/properties_screen.dart`. Ensure export buttons trigger backend streaming URLs.

**Affected Systems:**  
Backend Export Controller, Flutter Export Handlers.

---

### REP-002 — Business Reports Aggregation Consistency
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Analytical charts and reports in the Business Insights module must utilize identical semantic contracts and boundary parameters as executive dashboards.

**MUST:**
- Bind charting aggregation buckets (daily, weekly, monthly) to IST timezone intervals.
- Use the canonical 64-KPI formulations documented in `KPI_SOURCE_OF_TRUTH.md`.

**MUST NOT:**
- Never introduce divergent date truncation functions (`DATE_TRUNC('day', ...)` in UTC) in reports services that diverge from dashboard IST queries.

**Rationale:**  
Prevents discrepancies where the executive dashboard card reports one number for the week while the analytical bar chart displays a different total for the same week.

**Validation:**  
Compare `ReportsService.getBusinessInsights()` output against `KpiService.getDashboardKpis()` for identical date filters.

**Affected Systems:**  
Reports Service, Business Insights UI.

---

## 20. Role-Based Access Control & Multi-Tenant Isolation (`RBAC` & `TENANT`)

### RBAC-001 — Four-Tier Role Hierarchy & Multi-Tenant Isolation
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
PropKart enforces a strict four-tier hierarchical role structure and multi-tenant organization boundary.

| Role Name | Access Scope | Operational Authority |
|---|---|---|
| **Super Admin** | Global Cross-Tenant | Platform infrastructure, billing, tenant provisioning, system overrides. |
| **Admin** | Organization Scope | Full read/write authority across their specific brokerage (`organization_id`). |
| **Sales** | Assigned Deals Scope | Deals assigned to them (`assigned_to = user.id`) or self-created requirements. |
| **Telecaller** | Calling Queue Scope | Inbound calling queue assigned to them (`assigned_telecaller_id = user.id`). |

**MUST:**
- Verify JWT claims on every backend request: extract `user.id`, `user.role`, and `user.organization_id`.
- Enforce `WHERE organization_id = :user_org_id` on all data access queries unless requester has verified `Super Admin` role.
- Restrict sales and telecaller queries to their explicitly assigned records.

**MUST NOT:**
- Never allow a user to view, mutate, or export records belonging to another organization.
- Never allow sales agents or telecallers to view unassigned leads or deals belonging to colleagues without manager authorization.

**Rationale:**  
Multi-tenant confidentiality and intra-brokerage lead ownership security. Prevents lead theft and unauthorized visibility.

**Validation:**  
Inspect `src/middleware/auth.middleware.js` and `src/security/tenant.js`.

**Affected Systems:**  
Authentication Middleware, Tenant Filter, All API Routes.

---

### RBAC-002 — Inventory Shared Attribution Masking
**Category:** BUSINESS POLICY  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Property inventory is shared across teams within an organization to maximize matching opportunities, but creator attribution (`created_by`, `creator_name`) is visible only to members of the creator's immediate team:
```javascript
if (!canSeeInventoryAttribution(user, property)) {
    property.created_by = null;
    property.creator = null;
}
```

**MUST:**
- Mask `created_by` and agent identity fields in API serialization when the requesting user is outside the creator's team.
- Maintain full property details (pricing, location, configuration) accessible to all organization agents for matching.

**MUST NOT:**
- Never hide active inventory properties from agents of different teams within the same brokerage.

**Rationale:**  
Encourages brokerage-wide co-broking and property matching while preventing intra-agency poaching of property listing owners.

**Validation:**  
Review `src/security/tenant.js` lines 75–92.

**Affected Systems:**  
Properties Controller, Properties Serializer.

---

### RBAC-003 — Direct Relational Foreign Key Scoping
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
RBAC permissions and record ownership must be evaluated exclusively via indexed relational foreign keys. Heuristic search loops, phone number lookup chains, and string-matching routines are strictly prohibited for access control.

**MUST:**
- Query access via direct keys: `requirements.assigned_to`, `requirements.telecaller_id`, `leads.assigned_telecaller_id`.

**MUST NOT:**
- Never execute sequential lookup loops (e.g., querying across 5 tables searching for phone numbers) to deduce whether a user has permission to access a record.

**Rationale:**  
Heuristic lookup loops create severe latency spikes (executing 6+ sequential queries per record), introduce race conditions, and bypass database index protections.

**Validation:**  
Review `src/modules/requirements/requirements.repository.js`. Verify zero heuristic phone-search loops exist in permission queries.

**Affected Systems:**  
Requirements Repository, Telecaller Access Controller.

---

## 21. API Contract & Backend Implementation Standards (`API`)

### API-001 — Mandatory Cursor or Limit/Offset Pagination
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
All list endpoints returning collections (`/leads`, `/requirements`, `/properties`, `/site-visits`, `/notifications`, `/audit-logs`) must enforce pagination with hard upper bounds:
$$\text{Default Limit} = 20 \text{ to } 50, \quad \text{Maximum Allowable Limit} = 200$$

**MUST:**
- Return pagination metadata in the standard envelope:
  ```json
  {
    "success": true,
    "data": {
      "items": [...],
      "pagination": { "page": 1, "limit": 50, "total": 1119, "totalPages": 23 }
    }
  }
  ```

**MUST NOT:**
- Never implement an unpaginated `SELECT *` endpoint that returns an unbounded array.

**Rationale:**  
Unbounded queries exhaust Node.js heap buffers, saturate network bandwidth, and crash mobile clients with out-of-memory exceptions as dataset size increases.

**Validation:**  
Inspect `src/modules/requirements/requirements.controller.js`. Verify limit clamping on all list routes.

**Affected Systems:**  
All List Endpoints, API Gateway, Mobile Client BLoCs.

---

### API-002 — Consistent HTTP Status Codes & Error Envelopes
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
All API responses must follow the standard JSON envelope structure:
```json
{
  "success": true | false,
  "data": { ... } | null,
  "message": "Human-readable description",
  "errorCode": "MACHINE_READABLE_ENUM" | null
}
```

**MUST:**
- Use accurate HTTP status codes:
  - `200 OK`: Successful read or update.
  - `201 Created`: Successful creation.
  - `400 Bad Request`: Validation failure.
  - `401 Unauthorized`: Missing or invalid authentication token.
  - `403 Forbidden`: Insufficient role or tenant permissions.
  - `404 Not Found`: Record does not exist.
  - `409 Conflict`: Unique constraint violation or duplicate detected.
  - `500 Internal Server Error`: Unhandled server exception.

**MUST NOT:**
- Never return `200 OK` with an envelope containing `{ "success": false, "error": ... }`.

**Rationale:**  
Predictable HTTP status codes enable standard network client error handling, HTTP caching, and circuit breaker resilience.

**Validation:**  
Review global error handling middleware in `src/middleware/error.middleware.js`.

**Affected Systems:**  
All Controllers, Global Error Handler, Flutter API Client.

---

### API-003 — Backend-Authoritative Business Calculations
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
All business calculations, state transitions, eligibility checks, permission evaluations, and aggregate metrics must be authored and executed authoritatively by the backend Node.js API and PostgreSQL database engine.

**MUST:**
- Restrict frontend Flutter code to presentation, client-side input validation, responsive rendering, and event dispatching.
- Compute KPI aggregations, qualification rates, workload capacities, match scores, and date-range filtering via SQL or backend services.

**MUST NOT:**
- Never compute global system KPIs by downloading entire database tables to the Flutter client and running in-memory Dart loops.
- Never perform role authorization on the client without authoritative backend route middleware enforcement.

**Rationale:**  
Client-side business calculations diverge across devices, degrade mobile battery and memory performance, fail on paginated data, and introduce severe security vulnerabilities.

**Validation:**  
Review Flutter BLoC classes. Confirm zero in-memory reduction routines computing system metrics over partial datasets.

**Affected Systems:**  
Flutter BLoCs, Admin Dashboard, Reports Module, Export Engine.

---

## 22. Offline Storage, Synchronization & Realtime Architecture (`SYNC` & `RT`)

### SYNC-001 — Non-Authoritative Client Storage & Read-Through Cache Standards
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Client-side persistence engines (Isar database on mobile/desktop; SharedPreferences / in-memory maps on web) function strictly as read-through cache accelerators and offline draft/intent stores. They are never authoritative.

**MUST:**
- Reconstruct the authenticated user's workspace from backend API endpoints upon app launch, refresh, or network reconnection.
- Invalidate local cache entries when backend notifications indicate data mutations.

**MUST NOT:**
- Never write lead allocation states, telecaller availability, call attempts, or KPI summaries to local storage as authoritative business state.

**Rationale:**  
Treating client databases as authoritative sources leads to permanent data divergence across multiple devices and silent loss of server-side assignments.

**Validation:**  
Review `lib/core/storage/local_repositories.dart` and `crm_draft_repository.dart`.

**Affected Systems:**  
Isar Database, SharedPreferences, Offline Sync Engine.

---

### SYNC-002 — Offline Mutation, Outbox Pattern & Conflict Resolution Protocol
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Client-side mutations executed while offline must be recorded in a persistent local Outbox queue. Upon network reconnection, outbox items must be synchronized to the backend sequentially, with deterministic conflict resolution.

**MUST:**
- Store offline mutations with: `mutation_id`, `entity_type`, `entity_id`, `action`, `payload`, `timestamp`, and `retry_count`.
- Apply **Server-Wins Conflict Resolution**: If a record was modified on the server while the client was offline, the server rejects the stale client mutation with `409 Conflict`, and the client fetches the authoritative server record.
- Handle idempotency: Include `mutation_id` in API headers to prevent duplicate execution during network retries.

**MUST NOT:**
- Never silently overwrite newer server-side data with stale offline client payloads.

**Rationale:**  
Field agents frequently lose connectivity in basements or remote sites. The outbox pattern ensures no field notes or follow-up logs are lost, while server-wins conflict resolution prevents corrupting subsequent updates.

**Validation:**  
Simulate offline mutation: update requirement notes while offline, update status on server, reconnect client. Assert server returns conflict and local outbox reconciles cleanly.

**Affected Systems:**  
Flutter Outbox Sync Service, Backend Sync Controller.

---

### SYNC-003 — Supabase Realtime Subscription Management & Reconnection
**Category:** ENGINEERING STANDARD  
**Severity:** MEDIUM  
**Status:** ACTIVE  

**Rule:**  
Realtime updates (lead allocations, availability changes, status updates) delivered via Supabase Realtime / WebSockets must be managed safely with auto-reconnection and full workspace refresh upon reconnect.

**MUST:**
- Throttle realtime subscriptions per user session to prevent connection quota exhaustion.
- Execute a full delta-sync refresh upon WebSocket reconnection to recover any events dropped during network disconnection.
- Unsubscribe from realtime channels when screens or dialogs are disposed.

**MUST NOT:**
- Never rely solely on WebSocket messages for data consistency; WebSockets provide notification hints, while REST APIs deliver authoritative data.

**Rationale:**  
Mobile devices frequently drop WebSocket connections during backgrounding or cellular handoffs. Treating WebSockets as infallible leads to stale client views.

**Validation:**  
Inspect Flutter WebSocket lifecycle handlers and channel disposal logic.

**Affected Systems:**  
Realtime Service, Flutter BLoC Listeners.

---

## 23. Audit Logging, Archival & Compliance (`AUD`)

### AUD-001 — Immutable Transactional Audit Log Mandate
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
The `public.audit_logs` table is an immutable, append-only ledger of security-relevant and business-critical operations. An audit event must never be modified after creation.

**MUST:**
- Create structured audit records for:
  1. User provisioning, role edits, and account activations/deactivations.
  2. Lead allocations, manual reassignments, and bulk transfers.
  3. Lead and requirement status transitions to terminal states (*Won*, *Lost*, *Rejected*).
  4. Property price, deposit, or ownership modifications.
  5. Soft-deletion, permanent deletion, and recycle-bin empty actions.
  6. Data export operations.
- Record: `user_id`, `organization_id`, `module`, `action`, `record_type`, `record_id`, `old_data`, `new_data`, `ip_address`, and `created_at`.

**MUST NOT:**
- Never permit `UPDATE` or `DELETE` statements on `public.audit_logs` during normal operational transactions.

**Rationale:**  
Audit logs represent the legal and operational record of brokerage transactions. Mutating or deleting audit records destroys compliance audit trails and conceals malicious actions.

**Validation:**  
Inspect `src/services/audit.service.js`. Run SQL assertion confirming zero `UPDATE` permissions exist on `audit_logs`.

**Affected Systems:**  
Audit Service, Security Logger, Administrative Screens.

---

### AUD-002 — Archival Storage vs Deletion Policy
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
Audit log retention and archival must preserve data integrity, traceability, and regulatory retrieval capabilities. Deleting historical audit records without verified cold-storage export is strictly prohibited.

**MUST:**
- Implement a formal two-phase archival workflow:
  1. **Phase 1 (Export):** Stream records older than 180 days to compressed, immutable cold storage (e.g., S3 Glacier / GCS Coldline).
  2. **Phase 2 (Purge):** Truncate purged partitions only after cold-storage export verification and checksum validation.
- Retain audit records for a minimum of 7 years in cold storage for compliance.

**MUST NOT:**
- Never run nightly cron jobs that execute blind `DELETE FROM audit_logs WHERE created_at < NOW() - INTERVAL '180 days'` without prior cold-storage dump.

**Rationale:**  
Real estate regulatory frameworks require multi-year transaction audit trails. Blind deletion exposes the brokerage to severe regulatory penalties.

**Validation:**  
Audit `src/services/cron.service.js` lines 9–74. Verify export verification gate before purge execution.

**Affected Systems:**  
Cron Scheduler, Archival Service, Database Storage.

---

### AUD-003 — Isolation of UI Telemetry from Transactional Audit Trail
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
High-frequency client-side telemetry (mouse hovers, screen dwell time, UI scroll events) must be directed to a dedicated telemetry store and must NEVER pollute `public.audit_logs`.

**MUST:**
- Ingest UI telemetry events into dedicated tables (`public.ui_telemetry`) or an external analytics pipeline (PostHog, Mixpanel).
- Reserve `public.audit_logs` strictly for business and security transactions.

**MUST NOT:**
- Never insert `HOVER_DWELL` or UI interaction records into `public.audit_logs`.

**Rationale:**  
Inserting thousands of UI hover events into `audit_logs` inflates table storage by gigabytes, exhausts index buffers, slows down compliance queries, and buries critical security events under UI noise.

**Validation:**  
Run query: `SELECT COUNT(*) FROM public.audit_logs WHERE action IN ('HOVER_DWELL', 'MOUSE_MOVE')`. Assert count is 0.

**Affected Systems:**  
Audit Service, Frontend Telemetry Service.


---

## 24. Flutter Frontend Architecture & UI/UX Standards (`UI`)

### UI-001 — Strict BLoC Architecture for Business State
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
All business workflows, remote data fetching, mutation lifecycles, and queue interactions in the Flutter application must be managed via `flutter_bloc`. Ad-hoc global singletons, static variables, and nested `setState` chains for business state are strictly prohibited.

**MUST:**
- Structure every feature with explicit `Bloc`, `Event`, `State`, and `Repository` contracts.
- Consume states in widgets using `BlocBuilder`, `BlocListener`, and `BlocConsumer`.
- Restrict `StatefulWidget` `setState` strictly to transient local UI state (e.g., hover states, text editing controllers, accordion expansion toggles).

**MUST NOT:**
- Never manage business state, lead assignments, or API caching in global static maps or service singletons.
- Never dispatch business mutations directly from UI event handlers without routing through a BLoC event.

**Rationale:**  
BLoC guarantees deterministic, unidirectional data flow, decouples business logic from the widget tree, facilitates automated widget testing, and prevents memory leaks.

**Validation:**  
Audit `lib/features/admin/bloc/`, `lib/features/campaign/`, and `lib/features/telecaller/`. Confirm zero global business singletons.

**Affected Systems:**  
Entire Flutter Codebase, All UI Screens.

---

### UI-002 — Adaptive Screen Layouts & WebGL Shader Safety
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
All UI screens and dialogs must support responsive breakpoint scaling using `CRMBreakpoints` and design tokens (`AppDesignTokens`), and must safeguard WebGL / CanvasKit performance on Flutter Web.

**MUST:**
- Clamp modal dialogs and overlays using responsive width helpers:
  ```dart
  width: CRMBreakpoints.adaptiveWidth(context, 440)
  ```
- On Flutter Web (`kIsWeb`), avoid heavy real-time shader blurs:
  ```dart
  kIsWeb ? containerFallback : BackdropFilter(...)
  ```

**MUST NOT:**
- Never render fixed-width dialogs ($>360\text{px}$) that overflow small mobile screens.
- Never apply unbounded `BackdropFilter` blur filters on Flutter Web platforms.

**Rationale:**  
Complex Gaussian blurs trigger high GPU fill rates on WebGL CanvasKit, causing frame drops and browser crashes on mobile web and entry-level laptops.

**Validation:**  
Review `lib/features/telecaller/widgets/telecaller_shift_gate_overlay.dart`. Verify `kIsWeb` conditional fallback.

**Affected Systems:**  
Flutter Web & Mobile UI, Dialog Overlays.

---

### UI-003 — Flutter Analyzer Baseline Rule
**Category:** ENGINEERING STANDARD  
**Severity:** HIGH  
**Status:** ACTIVE  

**Rule:**  
The Flutter codebase must satisfy the **Analyzer Baseline Standard**. Deployments and PRs must produce zero analyzer errors, zero new analyzer errors, zero new critical warnings, and zero regressions in modified files.

**MUST:**
- Run `flutter analyze` on every PR and release build.
- Maintain **Zero Analyzer Errors** across the entire codebase.
- Enforce that modified files introduce zero new warnings or lint regressions.
- Track known legacy warnings in a documented backlog rather than blocking releases on legacy non-critical hints.

**MUST NOT:**
- Never enforce an unrealistic, dogmatic rule requiring "zero warnings everywhere forever" if legacy packages produce non-breaking hints.
- Never merge code containing analyzer compilation errors.

**Rationale:**  
Compilation errors break builds and crash runtimes. Distinguishing fatal errors and new regressions from legacy lint hints ensures velocity while steadily improving code quality.

**Validation:**  
Execute `flutter analyze`. Assert 0 fatal errors and verify modified files introduce no new warnings.

**Affected Systems:**  
Flutter CI/CD Pipeline, Frontend Repository.

---

## 25. Security, Authentication & Data Protection (`SEC`)

### SEC-001 — JWT Authentication & Tenant Claims Enforcement
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Every backend API endpoint (except public authentication routes) must validate a signed JSON Web Token (JWT) and extract authoritative claims: `user_id`, `role`, and `organization_id`.

**MUST:**
- Validate token signatures and expiration timestamps via `auth.middleware.js`.
- Bind request context strictly to verified token claims.
- Invalidate user tokens immediately upon account deactivation or role changes.

**MUST NOT:**
- Never trust user identity or tenant identity passed in unauthenticated request headers or query parameters.

**Rationale:**  
Prevents impersonation, horizontal privilege escalation, and cross-tenant data access.

**Validation:**  
Send unauthenticated request to protected endpoint. Assert `401 Unauthorized`. Send request with tampered org header. Assert tenant claim from JWT is enforced.

**Affected Systems:**  
Authentication Middleware, Token Service.

---

### SEC-002 — PII Data Protection, Sanitization & Masking
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Personally Identifiable Information (PII)—specifically customer phone numbers and email addresses—must be protected, sanitized in logs, and masked in unprivileged API responses and executive exports.

**MUST:**
- Sanitize PII in server application logs: mask middle digits (e.g., `+91 98****3210`).
- Mask customer contact details in UI views for sales agents until formal lead claim or qualification occurs.
- Restrict unmasked bulk exports to verified tenant administrators.

**MUST NOT:**
- Never log raw, unmasked customer phone numbers or credit information in plain text logs.

**Rationale:**  
Compliance with data privacy regulations (Digital Personal Data Protection Act) and prevention of lead contact theft by rogue agents.

**Validation:**  
Inspect application log output during lead ingestion. Verify phone numbers appear masked.

**Affected Systems:**  
Logger Service, Export Controller, Lead Serializer.

---

## 26. Testing, Baseline Verification & Reconciliation (`TEST`)

### TEST-001 — Test Baseline Rule
**Category:** ENGINEERING STANDARD  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Software releases must satisfy the **Test Baseline Standard**. Every release must compare current test results against the established test baseline. All relevant and critical-path tests must pass, and zero unexplained regressions are permitted.

```text
TEST EXECUTION
      │
      ▼
┌────────────────────────────────────────────────────────┐
│ COMPARE BASELINE FAILURES vs CURRENT FAILURES          │
│  - Critical-path tests passing? (Must be 100%)         │
│  - Any new, unexplained failures? (Must be 0)          │
│  - Environment/Network timeouts distinguished?         │
│  - Known pre-existing failures documented?             │
└────────────────────────────────────────────────────────┘
      │
      ├── [ ANY NEW REGRESSION ] ──► MERGE BLOCKED
      │
      ▼ [ ZERO NEW REGRESSIONS & CRITICAL PATH GREEN ]
[ RELEASE APPROVED ]
```

**MUST:**
- Execute `npm test` across backend services and `flutter test` across frontend modules.
- Ensure 100% of critical-path tests (Lead Ingestion, Allocation Stored Procedure, Site Visit Sync, KPI Calculation, RBAC Middleware) pass.
- Document known pre-existing test failures with linked tickets.
- Distinguish environment/network timeouts from actual product code defects.

**MUST NOT:**
- Never enforce a simplistic "100% of all tests must pass" rule that blocks critical hotfixes due to an unrelated, pre-existing legacy unit test.
- Never silently accept a newly introduced test failure without formal investigation.

**Rationale:**  
Complex production codebases accumulate edge-case legacy tests. The baseline rule ensures that new work never introduces regressions while preventing non-critical legacy debt from paralyzing releases.

**Validation:**  
Run test suite. Assert:
$$\text{New Unexplained Failures} = 0$$

**Affected Systems:**  
CI/CD Pipeline, Backend Test Suite, Frontend Test Suite.

---

### TEST-002 — Zero-Delta KPI Reconciliation Testing
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Before deploying any modification impacting KPIs, dashboards, or reports, an automated reconciliation test must be executed comparing PostgreSQL database counts directly against backend API responses. The reconciliation must prove **Delta = 0**.

**MUST:**
- Execute reconciliation queries comparing database counts against API responses for all 64 master KPIs.
- Verify:
  $$\text{Delta} = \left| \text{Database Count} - \text{API Count} \right| = 0$$

**MUST NOT:**
- Never approve a release where an existing KPI exhibits unexplained numerical variance between database queries and API outputs.

**Rationale:**  
Guarantees mathematical integrity across executive reporting surfaces prior to production deployment.

**Validation:**  
Execute `src/scripts/verify_kpi_reconciliation.js`. Assert all 64 KPIs report `PASS` with `Delta = 0`.

**Affected Systems:**  
KPI Service, Reports Service, Admin Dashboard.

---

## 27. Feature Impact & Addition Protocol (`FEAT-PROTO-01`)

### FEAT-001 — No Isolated Feature Implementation Rule
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Before commencing implementation of ANY new feature or modification, the engineering team or agent MUST perform an exhaustive **30-Area Impact Assessment**. Every area must be explicitly evaluated and categorized as `AFFECTED`, `NOT AFFECTED`, or `UNKNOWN — REQUIRES INVESTIGATION`. No "UNKNOWN" item may be silently ignored before coding begins.

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   MANDATORY 30-AREA IMPACT ASSESSMENT                  │
├───────────────────────────────────┬────────────────────────────────────┤
│ 1. Business Rules                 │ 16. Business Reports               │
│ 2. Source of Truth Table          │ 17. Executive Dashboards           │
│ 3. Database Schema / DDL          │ 18. KPI Drilldowns                 │
│ 4. Foreign Key Constraints        │ 19. Streaming Exports              │
│ 5. Database Indexes               │ 20. Notification Engine            │
│ 6. Historical Data Immutability   │ 21. Audit Logging                  │
│ 7. Lifecycle State Machine        │ 22. Realtime WebSockets            │
│ 8. Backend Services               │ 23. Offline Outbox Sync            │
│ 9. REST / RPC APIs                │ 24. Local Cache (Isar)             │
│ 10. Role-Based Access Control     │ 25. Flutter UI/UX & Responsive     │
│ 11. Multi-Tenant Isolation        │ 26. Deduplication & Idempotency    │
│ 12. Lead Lifecycle Stage          │ 27. Query Performance & Buffers    │
│ 13. Lead Allocation Engine        │ 28. Security & PII Protection      │
│ 14. Property Matching Engine      │ 29. Automated Testing              │
│ 15. KPI Semantics & Formulas      │ 30. Deployment & Migration Order   │
└───────────────────────────────────┴────────────────────────────────────┘
```

**MUST:**
- Complete the 30-area evaluation in design documentation before writing production code.
- Investigate and resolve all "UNKNOWN" assessments prior to implementation.
- Execute the 20-step sign-off pipeline:
  ```text
  1. Business Requirement Defined
  2. Source of Truth Table Identified
  3. Relational Schema & Foreign Keys Modeled
  4. Historical Event Preservation Verified
  5. RBAC Scopes Defined for All 4 Roles
  6. Lifecycle State Machine Validated
  7. Affected KPIs & Mathematical Formulas Documented
  8. Allocation & Workload Engine Impact Assessed
  9. Matching Engine Scoring Assessed
  10. API Route, Controller & Pagination Designed
  11. Multi-Tenant Scoping Enforced in SQL
  12. Responsive UI Wireframed
  13. Audit Log Emission Wired
  14. Database Indexes Evaluated via EXPLAIN ANALYZE
  15. Concurrency Race Conditions Protected
  16. BLoC State Management Implemented
  17. Automated Unit & Integration Tests Written
  18. KPI Reconciliation Executed (Delta = 0)
  19. Regression Test Suite Executed (Baseline Standard)
  20. Rulebook Compliance Sign-Off Executed
  ```

**MUST NOT:**
- Never begin coding an isolated feature that touches a UI screen without assessing its impact across the 30 areas.

**Rationale:**  
PropKart is a deeply interconnected CRM/ERP. Isolated changes inevitably break downstream analytics, corrupt historical ledgers, or cause tenant data leaks.

**Validation:**  
Review feature PR for attached 30-area impact assessment.

**Affected Systems:**  
Platform Engineering Lifecycle, All Pull Requests.

---

## 28. KPI Addition & Governance Protocol (`KPI-PROTO-02`)

When an engineering or business request is submitted to *"Add KPI X"*, engineers **MUST STOP CODING** and establish the complete **26-Point Mandatory KPI Specification** before implementing backend queries or frontend cards:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                   26-POINT MANDATORY KPI SPECIFICATION                 │
├───────────────────────────────────┬────────────────────────────────────┤
│ 1. Canonical KPI System Key       │ 14. Deduplication Rule             │
│ 2. Official Display Label         │ 15. Cohort vs Action Semantic      │
│ 3. Core Business Question         │ 16. Multi-Tenant Organization Scope│
│ 4. Exact Mathematical Formula     │ 17. Role Visibility Scope          │
│ 5. Numerator Formulation          │ 18. Dashboard Display Surfaces     │
│ 6. Denominator Formulation        │ 19. Analytical Reports Mapping     │
│ 7. Authoritative Source Table     │ 20. Detailed Drilldown Endpoint    │
│ 8. Authoritative Source Event     │ 21. Streaming Export Mapping       │
│ 9. Historical Immutability Check  │ 22. Backend Controller & API Route │
│ 10. Canonical Date Field          │ 23. Required Performance Indexes   │
│ 11. Timezone Boundary (IST)       │ 24. Historical Backfill Strategy   │
│ 12. Mandatory Status Inclusions   │ 25. Reconciliation Verification SQL│
│ 13. Mandatory Status Exclusions   │ 26. Automated Test Scenarios       │
└───────────────────────────────────┴────────────────────────────────────┘
```

> [!CAUTION]
> **STOP-THE-LINE PRECONDITION:** If the database schema cannot currently represent the KPI's historical truth, **THE IMPLEMENTATION MUST STOP**. The database model must be extended via an additive migration before the KPI can be created. Never fake a metric from current mutable status!

---

## 29. Database Change & Evolution Protocol (`DB-PROTO-03`)

Every database modification must satisfy:
1. **Additive-Only Rule:** All newly added columns must be `NULL` or supply a safe `DEFAULT`. No dropping of columns or tables without prior multi-release deprecation.
2. **Idempotency Where Applicable:** DDL statements should execute safely without throwing duplicate-object errors upon re-run.
3. **Controlled Migration Mechanism:** Migrations must execute under single-writer locking (via `ensureAdditiveSchema.js` or external migration runner).
4. **Performance & Index Verification:** Every newly added relationship column or high-frequency filter must be paired with an evidence-based index validated via `EXPLAIN ANALYZE`.
5. **Operational Recovery Plan:** Every migration must provide an explicit operational strategy:
   - Application Rollback
   - Schema Rollback
   - Data Rollback
   - Forward Fix

---

## 30. Production Release Gate & Verification Protocol (`REL-GATE`)

Before any release branch is merged into `local_setup`, `main`, or `production`, the verification gate must execute and record:

```text
┌────────────────────────────────────────────────────────────────────────┐
│                    PROPKART PRODUCTION RELEASE GATE                    │
├────────────────────────────┬───────────────────────────────────────────┤
│ 1. Analyzer Gate           │ Zero fatal analyzer errors; zero new      │
│                            │ warnings in modified files.               │
├────────────────────────────┼───────────────────────────────────────────┤
│ 2. Test Baseline Gate      │ Zero new unexplained test regressions;    │
│                            │ 100% critical-path tests passing.         │
├────────────────────────────┼───────────────────────────────────────────┤
│ 3. Database Integrity Gate │ Zero unindexed critical foreign keys;     │
│                            │ zero orphaned records.                    │
├────────────────────────────┼───────────────────────────────────────────┤
│ 4. KPI Reconciliation Gate │ Database count vs API count Difference = 0│
│                            │ across all affected metrics.              │
├────────────────────────────┼───────────────────────────────────────────┤
│ 5. Historical Event Gate   │ Completed events immutable; verified      │
│                            │ downstream transitions retain event rows. │
├────────────────────────────┼───────────────────────────────────────────┤
│ 6. Multi-Tenant Gate       │ SQL queries verified with strict org      │
│                            │ isolation clauses.                        │
├────────────────────────────┼───────────────────────────────────────────┤
│ 7. Migration Recovery Gate │ Additive migration verified; forward fix  │
│                            │ and rollback documented.                  │
└────────────────────────────┴───────────────────────────────────────────┘
```

---

## 31. Current Known Governance Violations Register

The audit identified the following **18 active governance violations** in the codebase. In accordance with strict governance principles, these are **documented without modification** and remain active technical debt until dedicated, verified remediation:

| Violation ID | Rule ID | Subsystem | Current Defect Behavior | Required Canonical Behavior | Severity | Evidence in Codebase |
|---|---|---|---|---|---|---|
| **VIOL-01** | `DB-001` | Database Schema | `leads.assigned_telecaller_id` and `leads.assigned_to` lack SQL `FOREIGN KEY` constraints to `users(id)`. | Enforce `FOREIGN KEY (assigned_telecaller_id) REFERENCES users(id) ON DELETE SET NULL`. | **CRITICAL** | `information_schema.table_constraints` on `leads` table shows missing constraints. |
| **VIOL-02** | `IDX-001` | Database Indexing | `public.leads` lacks a B-tree index on `sanitized_phone`. | Create `CREATE INDEX idx_leads_sanitized_phone ON public.leads(sanitized_phone);`. | **CRITICAL** | `pg_indexes` on `leads` table shows no index on `sanitized_phone`. |
| **VIOL-03** | `DB-002` | Properties | Physical shadow table `deleted_properties` exists alongside `properties.deleted_at`. | Decommission shadow table; unify all soft deletion under `properties.deleted_at`. | **HIGH** | `src/modules/properties/properties.repository.js` lines 718–742. |
| **VIOL-04** | `AUD-001` | Audit System | Over 6,000 UI hover/dwell telemetry rows pollute `public.audit_logs`. | Isolate UI telemetry to a dedicated log store; preserve `audit_logs` for business transactions. | **HIGH** | `public.audit_logs` row count analysis (`HOVER_DWELL` = 2,342 rows). |
| **VIOL-05** | `MATCH-002`| Matching Engine | Matching engine ignores requirement square footage constraints (`min_area`, `max_area`). | Add carpet area evaluation dimension with $\pm 20\%$ tolerance score. | **HIGH** | `src/modules/matching/matching.service.js` lines 253–259 (area missing from breakdown). |
| **VIOL-06** | `DATA-002` | Database Constraints | Neither `leads` nor `integration_leads` has a SQL unique constraint on `(sanitized_phone, organization_id)`. | Add partial unique index on `(sanitized_phone, organization_id)` where `deleted_at IS NULL`. | **CRITICAL** | `pg_indexes` on `leads` table shows no phone uniqueness constraint. |
| **VIOL-07** | `API-001` | Export Engine | Client-side spreadsheet export in Flutter truncates data to loaded page rows. | Delegate all exports to backend streaming endpoints `/api/v1/export/*`. | **HIGH** | `lib/features/properties/screens/properties_screen.dart` lines 5071–5140. |
| **VIOL-08** | `DATA-001` | Ingestion Pipeline | Meta and Housing lead deduplication is siloed by source family, creating cross-vendor duplicates. | Deduplicate across all sources globally on `sanitized_phone`. | **CRITICAL** | `src/services/leadIngestEngine.service.js` lines 259–262. |
| **VIOL-09** | `SEC-001` | Notification Service | `NotificationService.sendNotification` omits `route` and `data` fields on database insertion. | Insert full payload including navigation routes. | **HIGH** | `src/services/notification.service.js` lines 8–24. |
| **VIOL-10** | `ARCH-003` | Requirements | Updating requirement status silently rewrites legacy values (`Live` $\rightarrow$ `Interested`, `Closed` $\rightarrow$ `Won`). | Remove repository-level rewrites; enforce canonical status codes via database enum/check. | **HIGH** | `src/modules/requirements/requirements.repository.js` lines 5–14. |
| **VIOL-11** | `UI-002` | Requirements Screen | Dropdown lacks `Re-Followup` and `Call Attempted (Open)`, hiding 34 active leads. | Expose canonical status registry options in dropdown. | **HIGH** | `lib/features/requirements/screens/requirements_screen.dart` lines 2763–2790. |
| **VIOL-12** | `RBAC-001` | Telecaller Access | Heuristic phone lookup loop executes 6 sequential queries across 5 tables to resolve telecaller requirements. | Query directly via indexed `requirements.telecaller_id` foreign key. | **CRITICAL** | `src/modules/requirements/requirements.repository.js` lines 210–275. |
| **VIOL-13** | `DATA-001` | Lead Ingestion | Vendor source names in `leads.source` are fragmented (`META` vs `Meta Ads`; `WEBHOOK API` vs `Webhook API`). | Enforce uppercase canonical source codes (`META`, `HOUSING`, `WEBHOOK`, `MANUAL`). | **HIGH** | `public.leads` source column distribution. |
| **VIOL-14** | `MATCH-001`| Matching Engine | Rental matching compares gross tenant budget against monthly rent without accounting for security deposit. | Compare against monthly rent and security deposit separately. | **MEDIUM** | `src/modules/matching/matching.service.js` lines 377–403. |
| **VIOL-15** | `DB-001` | Database Schema | Requirements maintains both `configuration_id` (single) and `configuration_ids` (array), creating search bifurcations. | Standardize on array column `configuration_ids` with GIN indexing. | **MEDIUM** | `public.requirements` column schema. |
| **VIOL-16** | `SYNC-001` | Frontend Storage | Web platform falls back to `SharedPreferences` string serialization for offline property caching. | Standardize web caching via indexed IndexedDB or memory-bounded LRU cache. | **MEDIUM** | `lib/core/storage/local_repositories.dart` lines 77–100. |
| **VIOL-17** | `AUD-001` | Background Jobs | Nightly cron deletes audit logs older than 180 days and soft-deleted records older than 30 days without archival dump. | Implement cold-storage export prior to hard deletion. | **MEDIUM** | `src/services/cron.service.js` lines 9–74. |
| **VIOL-18** | `KPI-002` | Dashboard Controller| `getInventoryOverview` ignores temporal date filters unless Custom Range is explicitly chosen. | Honor `dateFilter` parameter across all inventory overview queries. | **HIGH** | `src/modules/dashboard/kpi.service.js` lines 270–278. |

---

## 32. Rulebook Governance, Amendment Process & Change Log (`AMEND`)

### RULE-GOV-001 — Rule ID Permanence & Retirement Protocol
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Rule IDs are globally unique, permanent identifiers. A Rule ID must NEVER be silently reused or redefined. If a rule is retired or replaced, its historical identity must be explicitly marked.

**MUST:**
- If a rule is retired: mark `Status: RETIRED`.
- If a rule is replaced: mark `Status: SUPERSEDED BY [NEW_RULE_ID]`.
- Maintain historical Rule ID entries in the rule index so past commit references remain clear and unambiguous.

**MUST NOT:**
- Never assign an existing Rule ID to a different concept or requirement.
- Never delete a Rule ID from history.

**Rationale:**  
Software development spans years of git commit logs, code comments, test suites, and compliance reports. Reusing Rule IDs destroys historical traceability and confuses engineering teams.

**Validation:**  
Run automated uniqueness check across all Rule IDs in the Rulebook. Assert zero duplicate Rule IDs.

**Affected Systems:**  
Engineering Governance, Code Review Standards.

---

### AMEND-001 — Rulebook Amendment Versioning Protocol
**Category:** PERMANENT INVARIANT  
**Severity:** CRITICAL  
**Status:** ACTIVE  

**Rule:**  
Modifications to this Rulebook must follow the formal versioned amendment procedure. Every modification must be logged in `PROPKART_RULEBOOK_V1_1_CHANGELOG.md` with:
- Amendment ID
- Date
- Reason
- Affected Rule IDs
- Old Rule Text
- New Rule Text
- Category Shift
- Impact Analysis
- Author & Reviewer
- Implementation Status

**MUST:**
- Increment document version according to Semantic Versioning:
  - Major (v2.0.0): Core architectural axiom or paradigm changes.
  - Minor (v1.1.0): New governance rules, taxonomy realignments, or policy adjustments.
  - Patch (v1.0.1): Typographical fixes, clarifying notes, or formatting improvements.

**MUST NOT:**
- Never modify rule text silently without an accompanying changelog entry.

**Rationale:**  
Preserves governance integrity, accountability, and clarity across distributed engineering teams.

**Validation:**  
Verify corresponding entries in `PROPKART_RULEBOOK_V1_1_CHANGELOG.md`.

**Affected Systems:**  
Master Rulebook, Governance Change Control.

---

### Master Rulebook V1.1 Change Record
For detailed itemized amendments and historical rationale regarding the transition from v1.0.0 to v1.1.0, refer to the companion document:  
**[PROPKART_RULEBOOK_V1_1_CHANGELOG.md](file:///c:/NB/propkart/PROPKART_RULEBOOK_V1_1_CHANGELOG.md)**.

# PROPKART MASTER ENGINEERING RULEBOOK — GOVERNANCE CHECKLIST
## Master Feature Change Gate, 30-Area Impact Assessment & Pre-Merge Verification Protocol
**Document Version:** 1.1.0  
**Release Date:** October 2, 2026  
**Status:** MANDATORY RELEASE GATE  
**Target Platform:** PropKart CRM & PropTech ERP (Web, Mobile, Desktop)  

---

## 1. Constitutional Mandate: "No Isolated Change"

In PropKart, **NO ISOLATED CHANGE EXISTS**. Every engineering modification—whether a bug fix, new screen, API endpoint, database column, or KPI card—must be evaluated as a system-wide change. 

Before any code is committed, tested, or merged into `local_setup`, `main`, or `production`, engineers and AI agents **MUST** execute and sign off on this checklist.

---

## 2. Stage 1: Master Pre-Coding Gate (MANDATORY BEFORE CODING)

Before writing a single line of backend, frontend, or database code, complete the following pre-coding verification:

- [ ] **1. Business Requirement Formally Defined:** Is the user story, bug report, or business requirement clearly stated in writing?
- [ ] **2. Existing Rulebook Search Completed:** Did you search `PROPKART_MASTER_ENGINEERING_RULEBOOK.md` for existing rules governing this domain?
- [ ] **3. New Rule Required?** Does this feature introduce a new business pattern or technical standard requiring a new Rule ID?
- [ ] **4. Authoritative Source of Truth Identified:** Which PostgreSQL table, primary key, and status column own the data?
- [ ] **5. Historical Semantics Identified:** Does this action involve completed historical events (Site Visits, Call Attempts, Audits)? Are they guaranteed immutable?
- [ ] **6. Database Schema Impact Assessed:** Is an additive migration required? Does it avoid non-additive destructive modifications?
- [ ] **7. Foreign Key & Index Impact Assessed:** Are all relationship columns backed by SQL foreign keys and evidence-based indexes?
- [ ] **8. Duplicate & Idempotency Behavior Defined:** What constitutes a duplicate? What unique constraint and application-level idempotency protect it?
- [ ] **9. Lifecycle State Machine Impact Assessed:** Does this transition follow the canonical state machine? Are terminal reason codes enforced?
- [ ] **10. RBAC & Multi-Tenancy Scopes Defined:** How is access scoped across Super Admin, Admin, Sales, and Telecaller? Is `organization_id` enforced?
- [ ] **11. Lead Allocation Impact Assessed:** Does this change affect telecaller workload, availability, shift limits, or round-robin queue ordering?
- [ ] **12. Property Matching Impact Assessed:** Does this change affect Stage 1 hard filters or Stage 2 soft scoring weights?
- [ ] **13. KPI & Analytics Impact Assessed:** Are any of the 64 master KPIs affected? Is the canonical formula and IST timezone preserved?
- [ ] **14. Business Reports & Insights Impact Assessed:** Do reports aggregate to the same numbers as dashboard cards?
- [ ] **15. Backend API & Pagination Envelope Designed:** Is cursor or limit/offset pagination enforced (limit $\le 200$)? Is the JSON response envelope standard?
- [ ] **16. Audit Logging Wired:** Is an audit record emitted in `public.audit_logs` for security-relevant or business state changes?
- [ ] **17. Notification & External Side Effects Assessed:** Are external network calls (SMS, WhatsApp, Webhooks) isolated outside the DB transaction block?
- [ ] **18. Realtime & WebSocket Impact Assessed:** Are channel subscriptions managed with cleanup on widget disposal and reconnect sync?
- [ ] **19. Offline Sync & Local Cache Assessed:** Is local storage (Isar) treated as non-authoritative read cache? Are offline mutations queued in an Outbox?
- [ ] **20. Flutter UI/UX & Responsive Breakpoints Designed:** Is business state in BLoC? Are modal widths clamped with `CRMBreakpoints`? Are WebGL shader blurs avoided on web?
- [ ] **21. Security & PII Protection Assessed:** Are phone numbers and emails sanitized in logs and masked in unprivileged API responses?
- [ ] **22. Performance & Buffer Overhead Assessed:** Has `EXPLAIN (ANALYZE, BUFFERS)` been run on critical queries? Are N+1 loops eliminated?
- [ ] **23. Automated Testing Strategy Defined:** Are unit tests, integration tests, and zero-delta reconciliation scripts planned?

**ONLY AFTER ALL 23 PRE-CODING ITEMS ARE VERIFIED MAY IMPLEMENTATION BEGIN.**

---

## 3. Stage 2: Mandatory 30-Area Impact Assessment Template

Copy and complete this assessment matrix into every feature design document or pull request description. Every item must be marked as `AFFECTED`, `NOT AFFECTED`, or `UNKNOWN — REQUIRES INVESTIGATION`. 

> [!CAUTION]
> **No item marked `UNKNOWN` may be silently ignored before writing code.**

| # | System Area | Status (`AFFECTED` / `NOT AFFECTED` / `UNKNOWN`) | Detailed Impact & Mitigation Notes |
|---|---|---|---|
| **1** | Business Rules | | |
| **2** | Source of Truth Table | | |
| **3** | Database Schema / DDL | | |
| **4** | Foreign Key Constraints | | |
| **5** | Database Indexes | | |
| **6** | Historical Data Immutability | | |
| **7** | Lifecycle State Machine | | |
| **8** | Backend Services | | |
| **9** | REST / RPC APIs | | |
| **10** | Role-Based Access Control | | |
| **11** | Multi-Tenant Isolation | | |
| **12** | Lead Lifecycle Stage | | |
| **13** | Lead Allocation Engine | | |
| **14** | Property Matching Engine | | |
| **15** | KPI Semantics & Formulas | | |
| **16** | Business Reports | | |
| **17** | Executive Dashboards | | |
| **18** | KPI Drilldowns | | |
| **19** | Streaming Exports | | |
| **20** | Notification Engine | | |
| **21** | Audit Logging | | |
| **22** | Realtime WebSockets | | |
| **23** | Offline Outbox Sync | | |
| **24** | Local Cache (Isar) | | |
| **25** | Flutter UI/UX & Responsive | | |
| **26** | Deduplication & Idempotency | | |
| **27** | Query Performance & Buffers | | |
| **28** | Security & PII Protection | | |
| **29** | Automated Testing | | |
| **30** | Deployment & Migration Order | | |

---

## 4. Stage 3: Mandatory 26-Point KPI Addition Specification Template

Whenever an engineering or business request is made to *"Add KPI X"*, engineers **MUST STOP CODING** and complete this 26-point specification:

```text
1. CANONICAL KPI SYSTEM KEY:
   (e.g., 'rejected_after_site_visit')

2. OFFICIAL DISPLAY LABEL:
   (e.g., 'Rejected After Site Visit')

3. CORE BUSINESS QUESTION ANSWERED:
   (e.g., 'How many customer property visits resulted in a deal rejection?')

4. EXACT MATHEMATICAL FORMULA:
   (e.g., COUNT(DISTINCT sv.id) WHERE sv.status = 'COMPLETED' AND sv.outcome = 'REJECTED_AFTER_VISIT')

5. NUMERATOR FORMULATION:
   (Explicit SQL count expression)

6. DENOMINATOR FORMULATION:
   (If ratio or percentage, otherwise 'N/A')

7. AUTHORITATIVE SOURCE TABLE:
   (e.g., 'public.site_visits')

8. AUTHORITATIVE SOURCE EVENT:
   (e.g., 'Site visit completion event with recorded outcome')

9. HISTORICAL IMMUTABILITY CHECK:
   (Verified: downstream lifecycle status changes do not decrement count)

10. CANONICAL DATE FIELD:
    (e.g., 'completed_at' or 'outcome_at')

11. TIMEZONE BOUNDARY CLAUSE:
    (Strict IST: (completed_at AT TIME ZONE 'Asia/Kolkata')::date)

12. MANDATORY STATUS INCLUSIONS:
    (e.g., status = 'COMPLETED', outcome = 'REJECTED_AFTER_VISIT')

13. MANDATORY STATUS EXCLUSIONS:
    (e.g., status = 'CANCELLED', status = 'SCHEDULED')

14. DEDUPLICATION RULE:
    (e.g., DISTINCT site_visits.id)

15. COHORT VS ACTION CLASSIFICATION:
    (Cohort metric vs Action volume metric)

16. MULTI-TENANT ORGANIZATION SCOPE:
    (WHERE organization_id = :org_id)

17. ROLE VISIBILITY SCOPE:
    (Super Admin, Admin, Sales Representative, Telecaller)

18. DASHBOARD DISPLAY SURFACES:
    (Admin Master Dashboard Card #14, Sales Dashboard)

19. ANALYTICAL REPORTS MAPPING:
    (Sales Conversion Funnel Report, Site Visit Outcome Report)

20. DETAILED DRILLDOWN ENDPOINT:
    (GET /api/v1/site-visits?outcome=REJECTED_AFTER_VISIT&page=1&limit=50)

21. STREAMING EXPORT MAPPING:
    (GET /api/v1/export/site-visits?outcome=REJECTED_AFTER_VISIT)

22. BACKEND CONTROLLER & API ROUTE:
    (KpiService.getDashboardKpis -> /api/v1/dashboard/kpis)

23. REQUIRED PERFORMANCE INDEXES:
    (CREATE INDEX idx_site_visits_outcome ON site_visits(organization_id, outcome, completed_at))

24. HISTORICAL BACKFILL STRATEGY:
    (Backfill script to populate historical events from legacy logs if required)

25. RECONCILIATION VERIFICATION SQL:
    (Standalone SQL query verifying database count matches API count)

26. AUTOMATED TEST SCENARIOS:
    (Unit test asserting Delta = 0 across Today, Weekly, Monthly filters)
```

> [!CAUTION]
> **STOP-THE-LINE RULE:** If the database does not currently have the columns or tables to represent the historical truth of this KPI, **STOP IMPLEMENTATION**. Extend the database model via an additive migration first. Never compute historical metrics by checking current mutable lead status!

---

## 5. Stage 4: Production Release Gate Checklist (BEFORE MERGING)

Execute and sign off on all items before merging to `local_setup`, `main`, or deploying to production:

### A. Static Analysis & Lint Gate
- [ ] `flutter analyze` reports **ZERO compilation errors**.
- [ ] Modified Flutter files introduce **ZERO new warnings or critical lints**.
- [ ] Node.js code passes ESLint with zero fatal syntax or unhandled promise errors.

### B. Automated Testing & Baseline Gate
- [ ] Backend regression suite (`npm test`) executed.
- [ ] 100% of critical-path tests passing (Ingestion, Allocation, Site Visit Sync, RBAC).
- [ ] **ZERO new unexplained test failures** compared to baseline.

### C. Database Integrity & Index Gate
- [ ] Schema changes are strictly additive (no dropped columns or non-default `NOT NULL` fields).
- [ ] Registered in migration catalog (`sql/migrations/` and `ensureAdditiveSchema.js`).
- [ ] Foreign keys backed by SQL `FOREIGN KEY` constraints (`DB-001`).
- [ ] Evidence-based indexes created for relationship columns and validated via `EXPLAIN ANALYZE`.
- [ ] Zero shadow tables or redundant copy mechanisms introduced (`DB-002`).

### D. KPI & Data Reconciliation Gate
- [ ] Automated reconciliation test executed against PostgreSQL database.
- [ ] **Delta = 0 verified** across all affected KPI cards, drilldown lists, and streaming exports.
- [ ] Temporal boundaries evaluated strictly in IST (UTC+5:30).
- [ ] Cohort metrics respect mathematical subset invariant ($\text{Allocated} \le \text{Total}$).

### E. Security & Multi-Tenancy Gate
- [ ] Multi-tenant isolation verified in SQL queries (`WHERE organization_id = ...`).
- [ ] RBAC permissions enforced via direct relational foreign keys (no phone-search loops).
- [ ] Customer phone numbers and PII masked in application logs and unprivileged API views.

### F. Frontend & UI/UX Gate
- [ ] Business state managed exclusively via `flutter_bloc` (zero global business singletons).
- [ ] Dialog widths clamped using `CRMBreakpoints.adaptiveWidth`.
- [ ] Flutter Web performance protected: expensive shader blurs bypassed on `kIsWeb`.
- [ ] Local storage (Isar) treated strictly as read cache and offline draft store.

### G. Sign-Off Certification
```text
FEATURE / PR TITLE: ____________________________________________________
AUTHOR: ____________________________________ DATE: _____________________
CHECKLIST STATUS: COMPLETE & RATIFIED
PRODUCTION CODE MODIFIED: [ ] YES   [ ] NO
DATABASE MODIFIED:        [ ] YES   [ ] NO
RECONCILIATION RESULT:    DELTA = 0 VERIFIED
```

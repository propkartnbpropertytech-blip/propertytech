# PROPKART MASTER ENGINEERING RULEBOOK — CONFLICT REGISTER
## Active Discrepancy Log, Cross-Document Contradictions & Architectural Decisions
**Document Version:** 1.1.0  
**Release Date:** October 2, 2026  
**Status:** ACTIVE AUDIT REGISTER  
**Target Systems:** PropKart Backend, Flutter Frontend, PostgreSQL Database  

---

## 1. Register Overview & Governance Mandate

During the V1.1 Governance Correction Audit, all platform documentation, database schemas, and codebase implementations were cross-referenced. 

This register documents every identified contradiction, categorized into:
1. **Documentation vs Implementation Conflicts:** Where existing documentation asserts a rule that the current codebase violates.
2. **Document vs Document Contradictions:** Where two official architectural documents specify conflicting rules, tables, or formulas.
3. **Over-Constrained Governance Rules:** Where the v1.0.0 Rulebook established technically unfeasible or counterproductive engineering mandates.

For every conflict, this register establishes:
- Conflict ID
- Affected Rule ID(s)
- Systems and Documents Involved
- Nature of the Conflict
- Resolution Status in Rulebook v1.1.0
- Required Stakeholder Decision (where human sign-off is mandatory)

---

## 2. Master Conflict Table

| Conflict ID | Rule ID(s) | Domain | Conflict Description | Resolution in v1.1.0 | Human Decision Required? |
|---|---|---|---|---|---|
| **CONF-01** | `SITE-001`, `KPI-001` | KPI Governance | **Site Visits Done Authoritative Source Table:** `KPI_SOURCE_OF_TRUTH.md` (line 51) specifies `requirements r WHERE status = 'Site Visit Done'`. However, the newer Site Visit Implementation and Rulebook establish `public.site_visits WHERE status = 'COMPLETED'` as the true authoritative event store. | **RESOLVED IN RULEBOOK:** Codified `public.site_visits` as sole authoritative source in `SITE-001`. `KPI_SOURCE_OF_TRUTH.md` flagged for documentation errata update. | **YES:** Product sign-off to update `KPI_SOURCE_OF_TRUTH.md` doc version to 3.2.0. |
| **CONF-02** | `INTEG-001`, `DATA-001` | Lead Ingestion | **Lead Deduplication Scope:** `leadIngestEngine.service.js` siloes deduplication by vendor (Meta vs Housing), whereas Business Dictionary and Rulebook mandate global deduplication on `sanitized_phone`. | **CONFIRMED AS VIOLATION:** Retained as `VIOL-08` in Technical Debt Register. Rulebook v1.1 maintains `INTEG-001` as active standard. | **NO:** Engineering debt already approved for remediation. |
| **CONF-03** | `REQ-001`, `UI-002` | Status Registry | **Requirement Dropdown Omission vs Registry:** `PROPKART_STATUS_REGISTRY.md` defines 20+ canonical statuses. Flutter `requirements_screen.dart` omits `Re-Followup` and `Call Attempted (Open)`, hiding 34 active leads. Repository silently rewrites legacy values. | **CONFIRMED AS VIOLATION:** Retained as `VIOL-10` and `VIOL-11` in Technical Debt Register. Status registry remains authoritative. | **NO:** UI bug to be fixed during Flutter remediation phase. |
| **CONF-04** | `DB-001`, `DB-002` | Schema Migrations | **Migration Execution Mechanism:** Rulebook v1.0 mandated startup execution via `ensureAdditiveSchema.js` as an immutable invariant. In multi-pod container clusters, concurrent startup runs risk lock contention and duplicate execution. | **RESOLVED IN RULEBOOK:** Reclassified `ensureAdditiveSchema.js` as Current Approved Implementation (`DB-002`); codified controlled single-writer migration standard in `DB-001`. | **NO:** Architectural governance clarified. |
| **CONF-05** | `INTEG-004`, `ARCH-003` | Transactions | **Multi-Table Transactions vs External Network Side Effects:** Rulebook v1.0 mandated that every multi-table mutation must use one DB transaction. Placing external HTTP calls (WhatsApp, SMS, Housing webhook) inside DB transactions holds connections open, causing pool exhaustion. | **RESOLVED IN RULEBOOK:** Established 4-Class Atomicity Classification in `INTEG-004`. Prohibited external network calls inside DB transactions; mandated Class D Transactional Outbox. | **NO:** Sound engineering standard established. |
| **CONF-06** | `BUS-002`, `BUS-003` | Telecaller Ops | **Operational Shift Ceilings vs Architectural Invariants:** Rulebook v1.0 elevated the 6-hour manual OFF allowance and 9-hour daily shift limit to core architectural invariants, preventing operational adjustments. | **RESOLVED IN RULEBOOK:** Reclassified both thresholds as Business Policies (`BUS-002`, `BUS-003`) in central constants rather than immutable architectural laws. | **YES:** Operations team to confirm whether weekend/part-time shifts require different allowances. |
| **CONF-07** | `MATCH-001`, `MATCH-002` | Matching Engine | **Matching Weights Hardcoding vs Service Implementation:** Rulebook v1.0 hardcoded 20% area tolerance and 60% threshold into permanent rules, while `matching.service.js` currently ignores carpet area entirely (`VIOL-05`). | **RESOLVED IN RULEBOOK:** Two-stage architecture codified as Invariant (`MATCH-001`); weights/tolerances codified as Configurable Policy (`MATCH-002`). Missing area in code preserved as `VIOL-05`. | **NO:** Awaiting matching engine remediation. |
| **CONF-08** | `AUD-001`, `AUD-002` | Compliance | **Audit Log 180-Day Purge vs Legal Immutability:** Rulebook v1.0 declared audit logs immutable, yet allowed cron deletion at 180 days. `cron.service.js` currently executes hard deletes without archival dumps (`VIOL-17`). | **RESOLVED IN RULEBOOK:** Codified `AUD-002` (mandatory cold export before purge). Retained current un-archived cron deletion as `VIOL-17`. | **YES:** Legal/compliance sign-off on 7-year cold storage provider (S3 Glacier vs GCS). |
| **CONF-09** | `TEST-001` | CI/CD | **Test Passing Standard (100% vs Baseline):** Rulebook v1.0 demanded "100% of all tests must pass", which blocked releases whenever an unrelated legacy unit test encountered environment timeouts. | **RESOLVED IN RULEBOOK:** Replaced with Test Baseline Rule (`TEST-001`): zero new unexplained failures, 100% critical-path passing. | **NO:** Pragmatic industry-standard baseline rule adopted. |
| **CONF-10** | `UI-003` | Frontend Standards| **Flutter Analyzer Zero-Warning Mandate:** Rulebook v1.0 demanded "zero warnings everywhere forever", which is unmaintainable across Flutter SDK deprecation cycles. | **RESOLVED IN RULEBOOK:** Replaced with Analyzer Baseline Rule (`UI-003`): zero errors, zero new errors, zero new critical warnings, zero regressions in modified files. | **NO:** Realistic engineering standard adopted. |
| **CONF-11** | `INTEG-003`, `DB-002` | Properties Schema | **Shadow Recycle Bin Table vs Soft Deletion:** Physical shadow table `deleted_properties` exists alongside `properties.deleted_at` (`VIOL-03`). Repository executes dual-table logic. | **CONFIRMED AS VIOLATION:** Retained as `VIOL-03`. Rulebook enforces single-table soft deletion (`INTEG-003`). | **YES:** Product decision on timeline for dropping `deleted_properties` table. |
| **CONF-12** | `DB-004`, `REQ-002` | Requirements Schema| **Schema Bifurcation (`configuration_id` vs `configuration_ids`):** `public.requirements` maintains both a scalar UUID and an array of UUIDs (`VIOL-15`), creating search bifurcations. | **CONFIRMED AS VIOLATION:** Retained as `VIOL-15`. Rulebook v1.1 standardizes on array with GIN index (`DB-004`). | **YES:** Product decision on formal deprecation and migration date to drop the scalar column. |

---

## 3. Detailed Conflict Analyses & Resolutions

### Conflict CONF-01: Site Visits Done Authoritative Source Table
- **Documents Involved:** `C:\NB\PropKart-Backend\docs\KPI_SOURCE_OF_TRUTH.md` vs `PROPKART_SITE_VISIT_HISTORICAL_TRACKING_IMPLEMENTATION_REPORT.md` vs `PROPKART_MASTER_ENGINEERING_RULEBOOK.md`.
- **The Discrepancy:** In `KPI_SOURCE_OF_TRUTH.md` (v3.1.0, dated 2026-09-30), KPI #13 (Site Visits Done) is defined as:
  ```sql
  SELECT COUNT(*) FROM requirements r 
  WHERE r.deleted_at IS NULL AND r.status = 'Site Visit Done'
  ```
  However, on October 2, 2026, the Site Visit Historical Tracking architecture was implemented and verified. Under this architecture, when a requirement transitions to *Rejected* or *Won*, the historical visit must NOT disappear. The authoritative source was formally migrated to:
  ```sql
  SELECT COUNT(DISTINCT sv.id) FROM site_visits sv 
  WHERE UPPER(sv.status) = 'COMPLETED' AND sv.completed_at IS NOT NULL
  ```
- **Resolution in Rulebook v1.1.0:** `SITE-001` and `KPI-001` establish `public.site_visits` as the permanent authoritative source. `KPI_SOURCE_OF_TRUTH.md` line 51 is marked as legacy and requires a version bump to v3.2.0.

---

### Conflict CONF-05: Multi-Table Transactions vs External Side Effects
- **Documents Involved:** Rulebook v1.0.0 `ARCH-003` vs Backend Service Implementations (`notification.service.js`, `integrations.service.js`).
- **The Discrepancy:** Rulebook v1.0 mandated: *"Any business action that updates or inserts data across two or more tables must execute within a single PostgreSQL database transaction."* In practice, operations like lead qualification also trigger external push notifications (Firebase FCM) and third-party webhooks. Placing network calls inside a PostgreSQL transaction client holds the physical connection and row locks open across network latency (often 500ms–2000ms), which quickly exhausts database connection pools.
- **Resolution in Rulebook v1.1.0:** Codified `INTEG-004` (Atomicity Classification). Only Class A (strictly database mutations) execute in a DB transaction. External side effects are classified as Class D (Transactional Outbox), where intent is staged in PostgreSQL and the external HTTP call executes asynchronously outside the database transaction block.

---

### Conflict CONF-06: Telecaller Shift Allowances vs Architectural Invariants
- **Documents Involved:** Rulebook v1.0.0 `ALLOC-002` vs Operational Management.
- **The Discrepancy:** Rulebook v1.0 placed the telecaller 6-hour manual OFF allowance and 9-hour daily shift ceiling into the same category as core architectural invariants (like tenant isolation and single source of truth). This made operational business parameters artificially difficult to tune when business requirements evolve (e.g., weekend 4-hour shifts, night shifts, or seasonal overtime).
- **Resolution in Rulebook v1.1.0:** Recategorized both rules as **Business Policies** (`BUS-002` and `BUS-003`) located in central application constants (`allocation.constants.js`). Engineering must strictly enforce the configured policy, but policy adjustments do not require constitutional Rulebook amendments.

---

## 4. Human Decisions Required Summary Table

The following four items represent substantive product, legal, or schema decisions that require formal human stakeholder sign-off prior to execution:

| Decision ID | Conflict ID | Subject | Options for Human Stakeholders | Recommended Action |
|---|---|---|---|---|
| **DEC-01** | `CONF-01` | KPI Documentation Errata | **Option A:** Approve errata update to `KPI_SOURCE_OF_TRUTH.md` updating KPI #13 source to `public.site_visits`.<br>**Option B:** Retain legacy text (Not recommended; conflicts with verified production code). | **Option A (Approved)** |
| **DEC-02** | `CONF-06` | Telecaller Shift Configuration | **Option A:** Confirm 6h OFF / 9h shift limits apply universally across all days.<br>**Option B:** Introduce organization-configurable shift limits in tenant settings table. | **Option A for now; Option B in Phase 2 roadmap.** |
| **DEC-03** | `CONF-08` | Audit Cold-Storage Retention | **Option A:** Provision AWS S3 Glacier bucket for 7-year audit archival before 180-day cron purge.<br>**Option B:** Extend live database retention from 180 days to 365 days until cold storage is provisioned. | **Option B immediately; Option A in Phase 2.** |
| **DEC-04** | `CONF-11` | Deprecation of `deleted_properties` | **Option A:** Decommission shadow table immediately; migrate remaining rows to `properties WHERE deleted_at IS NOT NULL`.<br>**Option B:** Maintain shadow table until next major release. | **Option A during scheduled remediation.** |

# PROPKART MASTER ENGINEERING RULEBOOK — V1.1 GOVERNANCE CHANGELOG
## Formal Amendment Record & Governance Transition Log (v1.0.0 → v1.1.0)
**Document Version:** 1.1.0  
**Release Date:** October 2, 2026  
**Status:** APPROVED & BINDING  
**Governing Documents:**  
- Master Rulebook: `PROPKART_MASTER_ENGINEERING_RULEBOOK.md`  
- Conflict Register: `PROPKART_RULEBOOK_CONFLICT_REGISTER.md`  
- Governance Checklist: `PROPKART_RULEBOOK_GOVERNANCE_CHECKLIST.md`  

---

## 1. Executive Summary & Amendment Rationale

The PropKart Master Engineering Rulebook has undergone a comprehensive V1.1 Governance Correction Audit. 

During the initial Phase 0 creation (v1.0.0), the platform successfully established core architectural guardrails, documented 84 rules, and cataloged 18 active technical debt violations. However, post-audit governance review identified that several v1.0 rules were **too rigid, implementation-specific, technically over-constrained, or conflated permanent invariants with operational business policies, current implementation choices, and technical debt**.

The v1.1.0 revision corrects these deficiencies by:
1. **Introducing the Mandatory Eight-Category Taxonomy:** Strictly segregating *Permanent Invariants*, *Business Policies*, *Engineering Standards*, *Current Approved Implementations*, *Proposed Governance Rules*, *Technical Debt / Violations*, *Conditional Rules*, and *Temporary Migration Rules*.
2. **Decoupling Business Invariants from Technical Mechanisms:** E.g., Lead allocation invariant (single active ownership, concurrency safety) separated from implementation mechanism (`FOR UPDATE SKIP LOCKED` in stored procedure).
3. **Establishing the KPI Semantic Equivalence Rule:** Replacing the rigid requirement for identical SQL strings with canonical semantic contracts across diverse query shapes.
4. **Clarifying Offline-First Architecture:** Defining PostgreSQL as server-side authoritative truth while formalizing client storage (Isar, Outbox, BLoC) as non-authoritative read projections and pending intent queues.
5. **Shifting Database Performance to Evidence-Based Standards:** Replacing dogmatic rules (e.g., "zero sequential scans over 1,000 rows", "dedicated standalone index on every FK") with empirical execution plan validation via `EXPLAIN (ANALYZE, BUFFERS)`.
6. **Classifying Operational Ceilings as Business Policies:** E.g., Telecaller 6-hour manual OFF allowance and 9-hour shift ceilings classified as configurable business policies rather than immutable engineering laws.
7. **Strengthening Change Protocols:** Expanding feature impact assessments to 30 mandatory domains and establishing the 26-point KPI specification protocol.

---

## 2. Master Amendment Register (v1.0.0 → v1.1.0)

| Amendment ID | Affected Rule ID(s) | Category Shift | Summary of Change & Rationale | Status |
|---|---|---|---|---|
| **AMD-01** | `KPI-001`, `KPI-005` | Engineering Standard $\rightarrow$ Permanent Invariant | **Replaced "Exact Same SQL String" with "KPI Semantic Equivalence Rule":** Allows different SQL shapes for org-wide aggregation, user cards, grouped reports, drilldowns, and exports, provided they reconcile to the canonical business contract and formula. | **APPROVED** |
| **AMD-02** | `INV-001`, `DATA-001`, `SYNC-001` | Engineering Standard $\rightarrow$ Permanent Invariant | **Clarified Offline-First Data Architecture:** Formally distinguished PostgreSQL (authoritative server truth), Isar (local read cache), Outbox (pending intent), and BLoC (UI state). Replaced anti-offline implication with invariant: "Local state cannot independently establish final server truth." | **APPROVED** |
| **AMD-03** | `DATA-001` | Engineering Standard $\rightarrow$ Refined Standard | **Refined One-Authoritative-Table Mandate:** Clarified that the rule prohibits *divergent duplicate sources of truth*, NOT legitimate relational children (e.g., `site_visits` event ledger) or integration mirrors (e.g., `integration_leads`). | **APPROVED** |
| **AMD-04** | `DB-001`, `IDX-001` | Rigid Standard $\rightarrow$ Evidence-Based Standard | **Evidence-Based Relationship Indexing:** Replaced mandate for dedicated standalone indexes on every FK with evidence-based index design allowing composite, partial, or covering indexes validated by `EXPLAIN ANALYZE`. | **APPROVED** |
| **AMD-05** | `IDX-001`, `PERF-001` | Rigid Rule $\rightarrow$ Performance Standard | **Replaced "Zero Sequential Scans over 1,000 rows":** Recognized that PostgreSQL optimizer legitimately selects sequential scans on small tables or cold paths; replaced with mandatory investigation of unexpected/expensive scans on critical paths via `EXPLAIN (ANALYZE, BUFFERS)`. | **APPROVED** |
| **AMD-06** | `IDX-002` | Rigid Heuristic $\rightarrow$ Workload Standard | **Composite Index Design Flexibility:** Removed rigid universal formula `(equality $\rightarrow$ status $\rightarrow$ timestamp)`. Required composite indexes to be designed from actual query patterns, selectivity, and planner plans. | **APPROVED** |
| **AMD-07** | `ARCH-003`, `INTEG-004` | Over-Constrained $\rightarrow$ Classification Framework | **Atomicity Classification & Multi-Table Governance:** Replaced requirement that every multi-table operation must use one DB transaction with a 4-class taxonomy (Class A Atomic, Class B Eventual, Class C Independent, Class D Outbox). Prohibited external network calls inside DB transactions. | **APPROVED** |
| **AMD-08** | `DB-INV-08`, `DB-001` | Rigid Invariant $\rightarrow$ Controlled Standard | **Modern Database Migration Governance:** Removed dogmatic requirement that every SQL statement literally use `IF NOT EXISTS` / `OR REPLACE`. Required controlled single-writer migration execution, explicit versioning, and defined 4-tier rollback/forward-fix strategies. | **APPROVED** |
| **AMD-09** | `DB-002` | Permanent Rule $\rightarrow$ Current Approved Implementation | **Classified `ensureAdditiveSchema.js` as Current Approved Implementation:** Recognized startup execution as the current valid mechanism without freezing it as an eternal architectural law. | **APPROVED** |
| **AMD-10** | `MATCH-001`, `MATCH-002` | Conflated Rule $\rightarrow$ Invariant vs Business Policy | **Separated Matching Architecture from Business Configuration:** Matching architecture (hard filters precede scoring, deterministic) classified as Invariant; scoring weights (100 pts, 25/30 pts) and area tolerance (20%) classified as Configurable Business Policies. | **APPROVED** |
| **AMD-11** | `ALLOC-001`, `ALLOC-002` | Conflated Rule $\rightarrow$ Invariant vs Current Implementation | **Separated Lead Allocation Invariant from Mechanism:** Invariant: single active telecaller ownership, atomic, concurrency-safe, auditable. Mechanism: `FOR UPDATE SKIP LOCKED` + `allocate_waiting_leads` classified as Current Approved Implementation. | **APPROVED** |
| **AMD-12** | `BUS-002`, `BUS-003` | Architectural Invariant $\rightarrow$ Business Policy | **Classified Telecaller 6h OFF & 9h Shift Limits as Business Policies:** Removed operational shift thresholds from core architectural invariants; classified as configurable business policies. | **APPROVED** |
| **AMD-13** | `AUD-001`, `AUD-002` | Conflated Rule $\rightarrow$ Invariant vs Archival Standard | **Distinguished Immutable Audit Events from Archival Storage:** Clarified that immutable audit events must never be mutated, while archival requires formal cold-storage export prior to purging. Prohibited blind deletion crons. | **APPROVED** |
| **AMD-14** | `TEST-001` | Unrealistic Law $\rightarrow$ Engineering Standard | **Replaced "100% Tests Pass" with Test Baseline Rule:** Releases must produce zero new unexplained failures; 100% critical-path tests must pass; known legacy failures must be documented and tracked. | **APPROVED** |
| **AMD-15** | `UI-003` | Unrealistic Law $\rightarrow$ Engineering Standard | **Replaced "Zero Warnings Everywhere" with Analyzer Baseline Rule:** Mandatory zero fatal analyzer errors, zero new errors, zero new critical warnings, and zero regressions in modified files. | **APPROVED** |
| **AMD-16** | Section 31 (`VIOL-01..18`) | Mixed Content $\rightarrow$ Isolated Register | **Strict Separation of Permanent Rules vs Current Violations:** Preserved all 18 cataloged violations from Phase 0 in Section 31 without modification, ensuring they are not conflated with active rules. | **APPROVED** |
| **AMD-17** | `FEAT-001`, `FEAT-PROTO-01`| Process Rule $\rightarrow$ Permanent Invariant | **Mandatory 30-Area Feature Impact Assessment:** Before coding any feature, mandatory assessment across 30 domains with `AFFECTED`, `NOT AFFECTED`, or `UNKNOWN — REQUIRES INVESTIGATION`. | **APPROVED** |
| **AMD-18** | `KPI-PROTO-02`, `KPI-004` | Process Rule $\rightarrow$ Permanent Invariant | **26-Point KPI Specification & Stop-the-Line Precondition:** Established 26 mandatory specification parameters. If database schema cannot represent historical truth, implementation must stop! | **APPROVED** |
| **AMD-19** | `CONSISTENCY-001` | Process Guideline $\rightarrow$ Permanent Invariant | **"Same Fact, Same Answer" Cross-Screen Invariant:** Displayed business facts across Admin, Sales, Telecaller, Reports, Drilldowns, and Exports must reconcile to the same canonical contract with zero unexplained variance. | **APPROVED** |
| **AMD-20** | `DATA-003` | Implicit Rule $\rightarrow$ Engineering Standard | **Duplication Prevention & Idempotency Governance:** Formalized canonical identity definitions, unique constraints, concurrent request protection, webhook replay safety, and offline retry idempotency. | **APPROVED** |
| **AMD-21** | `USR-001`, `USR-002` | Missing Governance $\rightarrow$ Permanent Invariant | **User Lifecycle & Organizational Governance:** User creation, activation, deactivation, and role changes must evaluate 360-degree impact across RBAC, active lead reassignment, workload, and historical attribution. | **APPROVED** |
| **AMD-22** | `PROP-001..003` | Fragmented Rules $\rightarrow$ Consolidated Domain | **Property Inventory Lifecycle & Governance:** Codified atomic property code sequence, status exclusivity, automated nightly availability activation, and property checklist. | **APPROVED** |
| **AMD-23** | `LEAD-001..003` | Fragmented Rules $\rightarrow$ Consolidated Domain | **Lead Lifecycle & Qualification Standards:** Codified canonical lead state machine, status history logging, vendor source normalization, and atomic qualification/handoff transaction. | **APPROVED** |
| **AMD-24** | `PERF-001`, `PERF-002` | Fragmented Rules $\rightarrow$ Performance Framework | **Comprehensive Database Performance Framework:** Codified connection hygiene, pool release guarantees, N+1 query elimination, parameter chunking, and buffer inspection. | **APPROVED** |
| **AMD-25** | `RULE-GOV-001` | Implicit Practice $\rightarrow$ Permanent Invariant | **Rule ID Permanence & Retirement Protocol:** Rule IDs are permanent; prohibited silent reuse. Replaced rules must be marked `SUPERSEDED BY [ID]`; retired rules marked `RETIRED`. | **APPROVED** |
| **AMD-26** | `AMEND-001` | Process Guideline $\rightarrow$ Permanent Invariant | **Rulebook Versioned Amendment Protocol:** Every future Rulebook change requires formal logging in this changelog with itemized impact analysis. | **APPROVED** |

---

## 3. Taxonomy Classification Cross-Walk

To provide complete visibility into how v1.0 rules were recategorized under the v1.1 taxonomy:

| Rule ID | v1.0 Category | v1.1.0 Category | Rationale for Reclassification |
|---|---|---|---|
| `INV-001` to `INV-008` | Core Principles | **PERMANENT INVARIANT** | Elevated to immutable platform axioms. |
| `BUS-001` to `BUS-006` | Architecture / Lead / Prop | **BUSINESS POLICY** | Identified as configurable business rules and allowances rather than technical laws. |
| `DATA-001` to `DATA-003` | Data Governance | **ENGINEERING STANDARD** | Standardized technical specifications for data modeling and deduplication. |
| `INTEG-001` to `INTEG-004` | Architecture / Database | **ENGINEERING STANDARD** | Technical integrity rules for constraints, soft deletion, and transaction boundaries. |
| `DB-001`, `DB-003`, `DB-004` | Database Schema | **ENGINEERING STANDARD** | Controlled database evolution standards. |
| `DB-002` | Architecture / Startup | **CURRENT APPROVED IMPLEMENTATION** | Startup execution recognized as current implementation choice, not permanent law. |
| `IDX-001`, `IDX-002` | Indexing | **ENGINEERING STANDARD** | Recast from rigid formulas to evidence-based engineering standards. |
| `PERF-001`, `PERF-002` | Uncodified / Mixed | **ENGINEERING STANDARD** | Codified performance benchmarks and connection hygiene standards. |
| `LEAD-001` | Lead Lifecycle | **PERMANENT INVARIANT** | State machine transitions and status history immutability elevated to invariant. |
| `LEAD-002`, `LEAD-003` | Lead Lifecycle | **ENGINEERING STANDARD** | Ingestion normalization and atomic handoff technical standards. |
| `ALLOC-001` | Allocation Engine | **PERMANENT INVARIANT** | Concurrency safety and single ownership elevated to invariant. |
| `ALLOC-002` | Allocation Engine | **CURRENT APPROVED IMPLEMENTATION** | PostgreSQL stored procedure + `SKIP LOCKED` classified as implementation choice. |
| `ALLOC-003` | Telecaller Workspace | **ENGINEERING STANDARD** | Technical heartbeat and timeout specification. |
| `USR-001` | Uncodified / User Mgmt | **PERMANENT INVARIANT** | 360-degree user lifecycle impact governance elevated to invariant. |
| `USR-002` | User Management | **ENGINEERING STANDARD** | Deactivation reassignment protocol. |
| `PROP-001`, `PROP-002` | Properties Module | **ENGINEERING STANDARD** | Sequence generation and automated availability cron. |
| `REQ-001` | Requirements Module | **PERMANENT INVARIANT** | Sales pipeline state machine elevated to invariant. |
| `REQ-002` | Requirements Module | **ENGINEERING STANDARD** | Configuration array and area range modeling. |
| `SITE-001`, `SITE-003` | Site Visits Module | **PERMANENT INVARIANT** | Completed visit immutability and universal sync coverage elevated to invariants. |
| `SITE-002` | Site Visits Module | **ENGINEERING STANDARD** | Idempotent sync and unique index technical standard. |
| `MATCH-001` | Matching Engine | **PERMANENT INVARIANT** | Two-stage hard-filter precedence elevated to invariant. |
| `MATCH-002` | Matching Engine | **BUSINESS POLICY** | Scoring weights and tolerances classified as business policy. |
| `MATCH-003` | Matching Engine | **ENGINEERING STANDARD** | Rental budget vs deposit evaluation separation. |
| `KPI-001` to `KPI-004` | KPIs / Reporting | **PERMANENT INVARIANT** | Semantic equivalence, IST boundaries, cohort separation, and data model preconditions elevated to invariants. |
| `CONSISTENCY-001` | System Integration | **PERMANENT INVARIANT** | "Same Fact, Same Answer" cross-screen equality elevated to invariant. |
| `CONSISTENCY-002` | System Integration | **ENGINEERING STANDARD** | Scope rollup and unassigned lead reconciliation. |
| `REP-001`, `REP-002` | Export / Reports | **ENGINEERING STANDARD** | Streaming server exports and analytical consistency. |
| `RBAC-001` | Access Control | **PERMANENT INVARIANT** | Four-tier hierarchy and tenant isolation elevated to invariant. |
| `RBAC-002` | Properties / Access | **BUSINESS POLICY** | Shared inventory attribution masking policy. |
| `RBAC-003` | Access Control | **ENGINEERING STANDARD** | Direct foreign key scoping (no search loops). |
| `API-001` to `API-003` | Backend API | **ENGINEERING STANDARD** | Pagination bounds, response envelopes, and backend-authoritative calculations. |
| `SYNC-001` | Frontend Offline | **ENGINEERING STANDARD** | Non-authoritative local storage specification. |
| `SYNC-002`, `SYNC-003` | Frontend Offline / RT | **ENGINEERING STANDARD** | Outbox pattern and WebSocket reconnection standards. |
| `AUD-001` | Audit Logging | **PERMANENT INVARIANT** | Transactional audit log immutability elevated to invariant. |
| `AUD-002`, `AUD-003` | Audit Logging | **ENGINEERING STANDARD** | Archival export-before-purge and UI telemetry isolation standards. |
| `UI-001` to `UI-003` | Flutter UI | **ENGINEERING STANDARD** | BLoC architecture, responsive breakpoints, and analyzer baseline standard. |
| `SEC-001` | Security | **PERMANENT INVARIANT** | JWT tenant claim enforcement elevated to invariant. |
| `SEC-002` | Security | **ENGINEERING STANDARD** | PII masking and log sanitization standard. |
| `TEST-001` | Testing | **ENGINEERING STANDARD** | Test baseline standard. |
| `TEST-002` | Testing / Verification | **PERMANENT INVARIANT** | Zero-Delta KPI reconciliation elevated to invariant. |
| `FEAT-001` | Change Control | **PERMANENT INVARIANT** | 30-area impact assessment elevated to invariant. |
| `VIOL-01` to `VIOL-18` | Violations Table | **TECHNICAL DEBT / VIOLATION** | Preserved in dedicated Section 31 register. |
| `RULE-GOV-001` | Rulebook Meta | **PERMANENT INVARIANT** | Rule ID permanence elevated to invariant. |
| `AMEND-001` | Rulebook Meta | **PERMANENT INVARIANT** | Versioned amendment protocol elevated to invariant. |

---

## 4. Sign-Off & Verification

This amendment record has been verified against both the backend and frontend codebases and approved as the binding governance standard for PropKart v1.1.0:

```text
AMENDMENT BATCH ID: AMD-V1-1-20261002
GOVERNANCE STATUS: RATIFIED & ACTIVE
PRODUCTION CODE MODIFIED: NO
DATABASE SCHEMA MODIFIED: NO
PRODUCTION BEHAVIOR MODIFIED: NO
```

# PropKart Mobile UI/UX — Step 2.7 Product + Engineering Sign-Off

**Code modified:** No. No application code, route, backend, database, sync, realtime, RBAC, KPI, status, or form was changed. Step 2.6 files were not modified. This is the only file created in Step 2.7.

---

## 1. Purpose

Decide, from documented evidence, whether the mobile UI/UX specification is frozen and authorized enough to enter Step 3. This document does not make product decisions, does not record human approvals that have not happened, and does not start implementation.

## 2. Source Documents

| Step | Document | Role here |
|---|---|---|
| 1 | `docs/PROPKART_MOBILE_UX_AUDIT.md` | Background (table/dialog inventory, role inventory) |
| 2 | `docs/PROPKART_MOBILE_UI_UX_MASTER_SPECIFICATION.md` | Superseded where Step 2.6 differs |
| 2.5 | `docs/PROPKART_MOBILE_UI_UX_STEP_2_5_VERIFICATION.md` | Technical evidence (V-, C-, R- IDs) |
| 2.6 | `docs/PROPKART_MOBILE_UI_UX_FINAL_SPECIFICATION.md` | Authoritative Step 3 specification |
| 2.6 | `docs/PROPKART_MOBILE_UI_UX_DECISION_REGISTER.md` | Authoritative decision IDs |

## 3. Step 2.6 Baseline

Counted directly from the Decision Register status column (85 entries).

| Item | Expected | Found in register | Match |
|---|---|---|---|
| Frozen decisions | 30 | 30 (DR-001–DR-030) | Yes |
| Product decisions | 6 | 6 (PD-01–PD-06) | Yes |
| Runtime verification gates | 20 | 20 (RV-01–RV-20) | Yes |
| Step 3 dependencies | 13 | 13 (SD-01–SD-13) | Yes |
| Future backlog items | 16 | 16 (FB-01–FB-16) | Yes |
| P0 unresolved | 0 | 0 | Yes |
| P1 unresolved | 4 | 4 (PD-01, PD-03, PD-04, PD-06) | Yes |

### 3.1 Documentation observations found during Step 2.7

These were found while checking Step 2.6. None changes a decision. Step 2.6 was not edited.

| ID | Location | Observation | Severity | Effect on authorization |
|---|---|---|---|---|
| DOC-01 | Final spec §2, row C-16 | Cross-reference says "(§17)" for terminology; terminology table is §9 | P3 | None |
| DOC-02 | Final spec §7, "Database source" column for KPI-01, 02, 03, 04a/b, 05, 08 | Values (properties, leads, users, allocation data) were not traced in Step 2.5; only KPI-06 and KPI-07 sources were verified | P2 | None for Step 3, because mobile reads server counts and does not compute KPIs. Treat those cells as "server-defined via `/dashboard/kpis`". Not a conflicting source, only an unverified label |
| DOC-03 | Final spec §16, "After returning from dialer" and §15 "refetch on return from the dialer" | Requires an app-lifecycle listener in the call flow; Step 2.5 found none in the call flow today | P3 | None. This is presentation/UI plumbing, not business logic; it is within authorized scope A |

---

## 4. Product Decision Gate

| ID | Question | Current Interim Default | Available Options (from Step 2.6) | Affects Step 3? | Decision Status |
|---|---|---|---|---|---|
| PD-01 | Telecaller default landing | `/dashboard` → `TelecallerDashboardScreen` | Dashboard / Queue | Yes — post-login route only | PRODUCT DECISION REQUIRED |
| PD-02 | Sales default landing | `/dashboard` → `SalesDashboardScreen` | Dashboard (Home tab) / Leads | Yes — post-login route only | PRODUCT DECISION REQUIRED |
| PD-03 | Sales Visits data source | No Visits tab; Leads status filter | Requirement status / `site_visits` records / no Visits tab | Yes — Visits tab only | PRODUCT DECISION REQUIRED |
| PD-04 | KPI-04 presentation | Two cards per KPI config | Two cards / one combined card / one primary card + secondary breakdown | Yes — Admin Home layout | PRODUCT DECISION REQUIRED |
| PD-05 | Sync overlay | Blocking overlay kept | Keep blocking / non-blocking caption | Yes — shell sync state | PRODUCT DECISION REQUIRED |
| PD-06 | Start-call from Queue | `tel:` only | Keep `tel:` only / call `startCall` like Callbacks | Yes — Queue call action | PRODUCT DECISION REQUIRED |

No product decision is final. Interim defaults are not final decisions.

## 5. PD-01 — Telecaller landing

```text
Current implementation: Post-login and splash redirect every role to /dashboard;
                        DashboardScreen renders TelecallerDashboardScreen for Telecaller.
Interim default:        Same as current.
Option A:               Dashboard (/dashboard → TelecallerDashboardScreen).
Option B:               Queue (/campaign/leads → CampaignLeadsScreen calling view).
UX consequence:         A — KPIs (assigned, callbacks, CNR, capacity) and follow-up list
                        first; Queue is one tap away (Queue tab).
                        B — first screen is the calling list; KPIs one tap away (Home tab).
Routing consequence:    A — none. B — Telecaller branch of the post-login/splash redirect
                        changes (SD-09).
Step 3 consequence:     Tabs are identical in both options (Home, Queue, Callbacks, CNR, More).
                        Only the initial route differs.
Final decision:         PRODUCT DECISION REQUIRED
```

## 6. PD-02 — Sales landing

```text
Current implementation: /dashboard → SalesDashboardScreen.
Interim default:        Same as current (Home tab).
Option A:               Dashboard (Home tab first).
Option B:               Leads (/requirements first).
Home/dashboard value:   Sales summary from salesDashboardSummary endpoint; the screen is not
                        deleted in either option.
Leads-first consequence: Sales opens straight into the server-scoped lead list; summary moves
                        to second tap.
Routing consequence:    A — none. B — Sales branch of the post-login/splash redirect changes (SD-09).
Step 3 consequence:     Tabs Home, Leads, Properties, More in both options. SD-10 (field
                        mapping) applies in both.
Final decision:         PRODUCT DECISION REQUIRED
```

## 7. PD-03 — Sales Visits

```text
Option A: Visits based on requirement status ("Site Visit", "Site Visit Done" on
          requirements.status). Data already in the Sales-scoped /requirements list.
Option B: Visits based on site_visits records (status COMPLETED and others). No Sales-scoped
          visits list is documented for mobile; /dashboard/site-visits-list is an admin
          dashboard endpoint under dashboard.read.
Known data consistency issue: no verified link keeps requirement status and site_visits rows
          in sync; a lead can be "Site Visit Done" without a COMPLETED record and vice versa.
KPI-06 relationship: KPI-06 counts site_visits COMPLETED. Option A would not match KPI-06.
Reporting consequence: A — tab counts can differ from KPI-06. B — matches KPI-06 definition.
Mobile UX consequence: A — filter preset over existing list. B — separate record list.
Backend consequence: A — none. B — may need a Sales-scoped visits endpoint (would be a
          backend dependency; not in Step 3 scope).
Final decision: PRODUCT DECISION REQUIRED. Visits tab stays blocked.
```

## 8. PD-04 — KPI-04

```text
Option A — Two cards: "New Leads Allocated" and "Old Leads Allocated" as separate grid cards;
           both open /dashboard/leads-allocated-breakdown with the same params. Uses two grid
           slots. Matches current KPI config output.
Option B — One combined card: one grid slot; card shows one value derived from both fields
           (the combination rule would itself need product definition) and opens the same
           breakdown page.
Option C — One primary card + secondary breakdown: one grid slot; one field as the main value,
           the other as a caption; opens the same breakdown page.

All options: backend metric and drilldown unchanged; KPI config may still disable either field.

Decision: none.
Status:   PRODUCT DECISION REQUIRED
```

## 9. PD-05 — Sync overlay

```text
Current behavior:      Full-screen blocking overlay "Updating lookup lists..." while
                       SyncManager.isSyncing (app_shell.dart).
Blocking option:       Keep the overlay; users cannot act during lookup sync.
Non-blocking option:   Replace with MobileSyncIndicator caption; users can act while lookups
                       refresh.
Affected screens:      All shell screens (every role) during sync.
UX consequence:        Blocking — interruption, no stale-lookup actions. Non-blocking — no
                       interruption, possible actions on lookups mid-refresh.
Implementation consequence: Presentation only in both options; SyncManager unchanged.
Final decision:        PRODUCT DECISION REQUIRED
```

## 10. PD-06 — Queue call recording

```text
Current behavior:      Queue Call → _launchTel → tel: only. Callbacks/CNR → startCall
                       (POST /telecaller/leads/:id/start-call) → tel:.
Option A:              Queue call records start-call before tel:.
Option B:              Queue call remains tel: only.
Database/API consequence: A — adds a start-call request per Queue call (call attempt / IN_CALL
                       handling on the backend). B — none.
Reporting consequence: A — Queue calls appear in call history/attempt data. B — Queue calls
                       are not recorded until an outcome is saved.
Telecaller workflow consequence: A — Queue and Callbacks behave the same; one extra network
                       call before dialing. B — unchanged.
Final decision:        PRODUCT DECISION REQUIRED
```

---

## 11. Frozen Decision Verification

"FROZEN" means Step 3 may implement it but must not reinterpret it.

| ID | Decision | Frozen? | Step 3 Must Respect It? | Conflict Found? |
|---|---|---|---|---|
| DR-001 | Mobile shell <768; `CRMBreakpoints` authoritative | Yes | Yes | No |
| DR-002 | Existing shift system unchanged in mobile shell | Yes | Yes | No |
| DR-003 | Screen-breakpoint rule for new components only | Yes | Yes | No |
| DR-004 | Role tabs and More | Yes | Yes | No |
| DR-005 | Telecaller outcome matrix | Yes | Yes | No |
| DR-006 | Picked Up = sales user + mandatory remarks + transfer | Yes | Yes | No |
| DR-007 | Telecaller Properties in More | Yes | Yes | No |
| DR-008 | Property wizard Basic+Media / Location / Pricing / Contacts | Yes | Yes | No |
| DR-009 | Lead wizard 7 steps, single budget, no invented fields | Yes | Yes | No |
| DR-010 | KPI-06 drilldown over `site_visits` | Yes | Yes | No |
| DR-011 | KPI-09 removed | Yes | Yes | No |
| DR-012 | KPI-10 removed | Yes | Yes | No |
| DR-013 | TC-01–TC-10 in KPI inventory | Yes | Yes | No |
| DR-014 | Callback / Follow-up / CNR separate | Yes | Yes | No |
| DR-015 | Session expiry redirect | Yes | Yes | No |
| DR-016 | Router redirects kept; 403 state in-screen | Yes | Yes | No |
| DR-017 | Sync diagnostics Admin + SA | Yes | Yes | No |
| DR-018 | Search sources and debounces per surface | Yes | Yes | No |
| DR-019 | Terminology presentation-only | Yes | Yes | No |
| DR-020 | Campaign 5000 request unchanged | Yes | Yes | No |
| DR-021 | Five offline states | Yes | Yes | No |
| DR-022 | No realtime dependency | Yes | Yes | No |
| DR-023 | RBAC unchanged | Yes | Yes | No |
| DR-024 | Dead features not in mobile, not deleted | Yes | Yes | No |
| DR-025 | Not-found page friendly copy | Yes | Yes | No |
| DR-026 | No raw errors on touched screens | Yes | Yes | No |
| DR-027 | Semantics in new components | Yes | Yes | No |
| DR-028 | 12px bottom-nav labels | Yes | Yes | No |
| DR-029 | Negotiation status used | Yes | Yes | No |
| DR-030 | Table/dialog conversion only on Step 3 screens | Yes | Yes | No |

Verified 30 / 30. Sign-off blockers: none.

### 11.1 Critical frozen items

| ID | Required content | Found in Step 2.6 | Result |
|---|---|---|---|
| DR-001 | <768, `CRMBreakpoints` | Final spec §3 | Verified |
| DR-002 | Shift system unchanged | §4, §30 "must not change shift timers or states" | Verified |
| DR-005 | Outcome matrix | §8 | Verified |
| DR-006 | Sales user + remarks + transfer | §8.1 | Verified |
| DR-008 | Basic+Media, Location, Pricing, Contacts | §12 | Verified |
| DR-009 | 7 steps, single budget, no invented fields | §13 | Verified |
| DR-010 | `site_visits` COMPLETED | §6, §7 | Verified |
| DR-011 / DR-012 | KPI-09, KPI-10 removed | §7 "Removed from mobile inventory" | Verified |
| DR-014 | Separate queues | §8.2 | Verified |
| DR-015 | Redirect | §17 | Verified |
| DR-018 | Per-surface sources/debounces | §10 | Verified |
| DR-019 | Presentation-only terminology | §9 | Verified |
| DR-020 | 5000 unchanged | §11, §20 | Verified |
| DR-021 | Five offline states | §14 | Verified |
| DR-022 | No realtime dependency | §15 | Verified |
| DR-023 | RBAC unchanged | §18 | Verified |
| DR-027 | Semantics in new components | §17, §24 | Verified |
| DR-030 | Step 3 screens only | §22, §23 | Verified |

---

## 12. Runtime Verification Gate

Build blocker = prevents Step 3 implementation. Release blocker = feature can be built but not released until the test passes. Non-blocking = normal QA.

| ID | Runtime Test | Blocking? | Can Step 3 Build Proceed? | Must Pass Before Release? |
|---|---|---|---|---|
| RV-01 | Idle auto-break while dialer is foreground | Release blocker | Yes | Yes — Queue, Callbacks, CNR, outcome sheets |
| RV-02 | Actual campaign rows returned | Non-blocking (scope gate for any performance change) | Yes | No |
| RV-03 | Realtime topic behavior | Non-blocking | Yes | No |
| RV-04 | Report KPI captions | Non-blocking | Yes | No |
| RV-05 | Contrast | Non-blocking | Yes | No |
| RV-06 | Text scale 1.3× | Non-blocking | Yes | No |
| RV-07 | Tablet orientation / Android 16 | Non-blocking | Yes | No |
| RV-08 | Image decode size | Non-blocking | Yes | No |
| RV-09 | Per-screen offline behavior | Non-blocking | Yes | No |
| RV-10 | Gallery double-tap zoom | Non-blocking | Yes | No |
| RV-11 | `tel:` resolution on Android 11+ | Release blocker | Yes | Yes — any screen with Call |
| RV-12 | KPI-06 drilldown search | Non-blocking | Yes | No |
| RV-13 | CNR/callback timing | Non-blocking | Yes | No |
| RV-14 | TalkBack / VoiceOver | Non-blocking | Yes | No |
| RV-15 | Admin "Needs attention" data | Non-blocking | Yes | No |
| RV-16 | Legacy drawer gesture | Non-blocking | Yes | No |
| RV-17 | Property client-side filters | Non-blocking | Yes | No |
| RV-18 | Bell on 360px | Non-blocking | Yes | No |
| RV-19 | Failed campaign-status PATCH state | Non-blocking | Yes | No |
| RV-20 | Visible elements under shift overlays | Release blocker | Yes | Yes — telecaller mobile shell (M-43) |

Totals: 0 blocking implementation · 3 release-only (RV-01, RV-11, RV-20) · 17 non-blocking.

### 12.1 Specific release gates

| ID | Blocks development? | Blocks feature completion? | Blocks release? |
|---|---|---|---|
| RV-01 | No | No — feature is complete when it follows §16; the test documents dialer behavior | Yes, for telecaller calling screens |
| RV-11 | No | No | Yes, for any Call action |
| RV-20 | No | Yes — overlay parity on the mobile shell cannot be declared complete until today's visible elements are documented | Yes, for the telecaller mobile shell |

Shift behavior itself stays unchanged regardless of results; a result that conflicts with §16 is raised as a change request (§26).

---

## 13. Campaign Performance Gate

| Item | Status |
|---|---|
| Current request | `limit: 5000` on GET `/integrations/leads` — unchanged (DR-020) |
| RV-02 | Non-blocking; measures actual rows and filter time |
| SD-11 | Backend/server pagination — not in Step 3 |
| FB-04 | Server pagination adoption — backlog |

**UI performance work (authorized in Step 3):** lazy list builders, card widgets, avoiding rebuild of the full legacy campaign widget for phone cards, "{n} loaded" count label.
**Backend pagination work (not authorized in Step 3):** changing the limit, using page/limit for the queue, changing `getLeads`, PostgREST settings.

## 14. Realtime Gate

| Item | Status |
|---|---|
| DR-022 | Mobile does not depend on realtime |
| RV-03 | Non-blocking |
| SD-13 / FB-07 | Realtime fix outside Step 3 |

Step 3 may proceed with pull-to-refresh, tab-focus refetch, return-from-dialer refetch (see DOC-03), and existing polling (notifications 25s, campaign sheets 60s, messages 4s/15s, heartbeat 30s). Every action updates its card from the action's own response.

## 15. Security / RBAC Gate

UI visibility is not backend authorization.

| Item | Finding |
|---|---|
| DR-023 | Existing permission matrix, router guards, backend permissions unchanged |
| FB-08 | Reports routes (`authenticate` + role scoping) and `/telecaller/transfer-lead`, `/telecaller/attempts/:id/remarks`, `/telecaller/transferred-leads`, `/telecaller/sales-users` (`authenticate` only) remain in backlog |
| Exposure check | Every Step 3 screen calls the same endpoints the current app already calls for the same role. No Step 3 screen adds a call to an authenticate-only endpoint for a role that does not use it today. Reports remain hidden for Telecaller/Sales and the backend scopes rows by role |
| Release blocker from security | None identified. Condition: if Step 3 adds any new call from a role to an authenticate-only endpoint, that screen becomes a release blocker pending FB-08 |

Step 3 documentation and UI copy must not describe hidden mobile items as security controls.

## 16. KPI Consistency Gate

| KPI | Live in Step 2.6? | Definition / source consistent across documents? | Drilldown consistent? | Result |
|---|---|---|---|---|
| KPI-01 | Yes | Yes (`available_inventory`) | Inventory page | Pass |
| KPI-02 | Yes | Yes (`total_leads`) | Leads list page | Pass |
| KPI-03 | Yes | Yes (`telecallers`) | Telecallers page | Pass |
| KPI-04 / 04a / 04b | Yes (a, b) | Allocation-based (`leads_allocated`, `old_leads_allocated`) | Same breakdown page for both | Pass |
| KPI-05 | Yes | Yes (`assigned_to_sales`) | Assigned-to-sales page | Pass |
| KPI-06 | Yes | `site_visits.status='COMPLETED'` in §6, §7, DR-010 | Visit-record page | Pass |
| KPI-07 | Yes | `requirements.status='Won'` | Deal won page | Pass |
| KPI-08 | Yes | Yes (`sales_users`) | Sales users page | Pass |
| KPI-09 | No — removed | Appears only as removed/forbidden (§2, §7, §21, §24 forbidden usage, §28) | — | Pass |
| KPI-10 | No — removed | Appears only as removed/forbidden; never as alias | — | Pass |
| TC-01–TC-10 | Yes | Single definition each from `/telecaller/dashboard` | Routes per §7 | Pass |

No KPI has two definitions; no removed KPI appears as live; KPI-06 is site-visit based; KPI-04 is allocation based. DOC-02 (unverified database-source labels for KPI-01–05/08) is a labeling note, not a conflicting definition. Result: no contradiction.

## 17. Status Consistency Gate

| Term | Step 2.6 presentation | Backend / DB | Workflow | Result |
|---|---|---|---|---|
| Lost | "Not used" (§9); C-16 "No 'Lost' label" | `stage LOST` exists only as backend value for Not interested | Not a mobile workflow | Pass |
| Rejected | Requirement rejection label | "Rejected…" requirement values | Requirements status | Pass |
| Not interested | Calling rejection label | stage LOST, NOT_INTERESTED, RELEASED | Leaves queue → archive | Pass |
| Interested | Interested | stage INTERESTED | Stays | Pass |
| Picked Up / Handed to Sales | Action "Picked Up"; state "Handed to Sales" | PICKED_UP / HANDED_TO_SALES | Transfer | Pass |
| Callback | Callback | CALLBACK; `campaign_lead_callbacks` | Leaves queue → Callbacks | Pass |
| Follow-up | Follow-up | FOLLOWUP | Stays in queue | Pass |
| CNR | CNR | CNR | → CNR tab | Pass |
| Site Visit | "Site Visit Scheduled" | requirements.status "Site Visit" | Requirement lifecycle | Pass |
| Site Visit Done | Lead label; KPI label "Site Visits Done" separate | requirements.status vs `site_visits` COMPLETED | Kept separate | Pass |
| Negotiation | Negotiation | requirements.status | Status sheet | Pass |
| Won | Won; KPI "Deal Won" | requirements.status "Won" | Property pick required | Pass |

## 18. Form Consistency Gate

| Check | Step 2.6 content | Result |
|---|---|---|
| Property steps | Basic (with media), Location, Pricing, Contacts (§12, DR-008) | Pass |
| Lead steps | 7 steps (§13, DR-009) | Pass |
| Lead budget | Single field, client-side range | Pass |
| alternate phone, email, city, timeline, budget min, budget max | Appear only in "Not part of the form" (§13) and C-11 | Pass — not required, not added |

## 19. Telecaller Workflow Gate

| Flow | Step 2.6 | Result |
|---|---|---|
| Queue → Call → Outcome | §8, §16, §25 | Pass |
| CNR → CNR | §8 | Pass |
| Callback → Callbacks | §8 | Pass |
| Follow-up → remains in Queue | §8, §8.2 | Pass |
| Picked Up → Sales user + Remarks → Transfer | §8.1 | Pass |
| Interested → stays | §8 | Pass |
| Not interested → archive | §8 | Pass |

## 20. Mobile Navigation Gate

| Role | Step 2.6 tabs (§5.3, DR-004) | Required | Extra destinations? | Result |
|---|---|---|---|---|
| Telecaller | Home, Queue, Callbacks, CNR, More | same | None | Pass |
| Sales | Home, Leads, Properties, More | same | None | Pass |
| Admin | Home, Leads, Properties, Reports, More | same | None | Pass |
| Super Admin | Home, Leads, Properties, Reports, More; More adds Callbacks, CNR, Audit logs, Super-admin metrics | same | None in bottom nav | Pass |

---

## 21. Authorized Step 3 Scope

### A. Authorized UI implementation
Mobile shell (<768) hosting existing shift overlay and toggle; `MobileBottomNav` per role; `/more` presentation route (SD-08); cards for leads, properties, users, callbacks, CNR, archives; mobile property wizard (4 steps) and lead wizard (7 steps); property and lead detail pages; mobile queue with outcome sheets; Callbacks and CNR screens; KPI cards and KPI drilldown pages over existing `DashboardService` calls; mobile reports (insight, telecaller report, placeholders, super-admin metrics without org switcher); settings, profile, MFA page; messages; library; recycle bin; allocation and employees; campaign connections and portal screens; table-to-card conversions and dialog-to-sheet/page conversions on Step 3 screens; semantics on new components; lifecycle-based refetch on return from dialer (UI only).

### B. Authorized presentation-only changes
Spacing, typography, card layout, mobile navigation, responsive layout using `CRMBreakpoints`, loading skeletons, empty states, error copy (no raw exceptions), offline/pending captions per DR-021, mobile interaction patterns (sheets, sticky bars, pull-to-refresh), status labels per DR-019, not-found page copy.

### C. NOT authorized in Step 3
KPI definition changes; database changes; backend business-logic changes; RBAC changes; allocation algorithm changes; matching engine changes; realtime architecture changes; sync architecture changes; campaign pagination or limit changes (client or backend); new business fields; new statuses; new APIs (none is required by the approved presentation); any of PD-01–PD-06 beyond its interim default until approved; shift timer, state, or lockout changes; deleting dead code; Sales Visits tab; org switcher.

---

## 22. Step 3 Screen Authorization

| Screen ID | Screen | Step 3 Scope | Authorized? | Dependency | Release Gate |
|---|---|---|---|---|---|
| M-01 | Splash | Mobile presentation | Yes | Landing per PD-01/PD-02 (interim) | — |
| M-02 | Get started | Mobile presentation | Yes | — | — |
| M-03 | Login | Mobile form | Yes | — | — |
| M-04 | MFA verify | Dialog → page | Yes | — | — |
| M-05 | Reset password | Mobile form | Yes | — | — |
| M-06 | Not found | Friendly error page | Yes | — | — |
| M-07 | Admin Home | KPI grid + carousel | Yes, with conditions | PD-04 (interim two cards) | PD-04 before sign-off |
| M-08 | Telecaller Home | KPI grid + lists | Yes, with conditions | PD-01 (landing only) | — |
| M-09 | Sales Home | KPI grid + card lists | Yes, with conditions | SD-10; PD-02 (landing only) | — |
| M-10 | KPI drilldown pages | Dialog → page | Yes | — | — |
| M-11 | Calling queue | Cards + outcome sheets | Yes, with conditions | PD-06 (interim `tel:` only) | RV-01, RV-11 |
| M-12 | Not interested / archives | Cards | Yes | — | — |
| M-13 | Callbacks | Cards + chips | Yes, with conditions | — | RV-01, RV-11 |
| M-14 | CNR | Cards | Yes, with conditions | — | RV-01, RV-11 |
| M-15 | Outcome sheets | Sheets | Yes, with conditions | — | RV-01 |
| M-16 | Leads list | Cards | Yes | — | — |
| M-17 | Lead detail | Page | Yes | — | — |
| M-18 | Lead wizard (7 steps) | Page wizard | Yes | — | — |
| M-19 | Match sheet | Sheet | Yes | — | — |
| M-20 | Won property selection | Page | Yes | — | — |
| M-21 | Properties list | Cards | Yes | — | — |
| M-22 | Property detail | Page + sticky bar | Yes | — | RV-11 for Call |
| M-23 | Property wizard (4 steps) | Page wizard | Yes | — | — |
| M-24 | Media viewer | Full screen | Yes | — | — |
| M-25 | Property search | MobileSearch | Yes | — | — |
| M-26 | Recycle bin | Cards | Yes | — | — |
| M-27 | More | New presentation route | Yes | SD-08 | — |
| M-28 | Lead allocation | Cards | Yes | — | — |
| M-29 | Employees / detail | Cards | Yes | — | — |
| M-30 | Reports insight | Stack + records page | Yes | — | — |
| M-31 | Telecaller report | People cards | Yes | — | — |
| M-32 | Sales report | Empty state | Yes | — | — |
| M-33 | Property reports | Empty state | Yes | — | — |
| M-34 | Super-admin metrics | Report stack | Yes | — (no org switcher) | — |
| M-35 | Campaign connections / settings / portal wizard | Cards and pages | Yes | — | — |
| M-36 | Library | Cards | Yes | — | — |
| M-37 | Messages | List + thread | Yes | — | — |
| M-38 | Settings | Grouped list → pages | Yes | — | — |
| M-39 | Sync diagnostics | Page | Yes | — | — |
| M-40 | Audit logs | Cards | Yes | — | — |
| M-41 | Profile + MFA security | Header + rows | Yes | — | — |
| M-42 | Public share | Cards / detail | Yes | — | — |
| M-43 | Shift overlays (hosted) | Hosting only, no behavior change | Yes, with conditions | — | RV-20 |
| — | Sales Visits tab | — | No | PD-03 | — |
| — | Clients / Owners / Builders / Pipeline | — | No | FB-14 | — |

Authorized: 43 of 43 screen-master screens (35 unconditional, 8 with conditions: M-07, M-08, M-09, M-11, M-13, M-14, M-15, M-43). Not authorized: Sales Visits tab, Clients/Owners/Builders/Pipeline.

---

## 23. Product Decision Checksum

```text
PD-01: PENDING
PD-02: PENDING
PD-03: PENDING
PD-04: PENDING
PD-05: PENDING
PD-06: PENDING
```

## 24. Sign-off Matrix

No human approval was obtained in this phase. No names or signatures are recorded.

| Area | Product Sign-off | Engineering Sign-off | QA Sign-off | Status |
|---|---|---|---|---|
| Mobile shell | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Spec frozen (DR-001); PD-05 pending |
| Telecaller shift | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Spec frozen (DR-002); RV-01, RV-20 release gates |
| Telecaller navigation | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Tabs frozen; PD-01 pending |
| Sales navigation | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Tabs frozen; PD-02, PD-03 pending |
| Admin navigation | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Frozen |
| KPIs | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Frozen; PD-04 pending |
| Forms | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Frozen |
| Calling | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PD-06 pending; RV-01, RV-11 |
| Offline | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Frozen (DR-021) |
| Realtime fallback | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Frozen (DR-022) |
| RBAC | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Frozen (DR-023); FB-08 backlog |
| Tables/cards | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Frozen (DR-030) |
| Dialogs/sheets | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Frozen (DR-030) |
| Accessibility | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Frozen (DR-027); RV-05, RV-06, RV-14 |
| Reports | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Frozen |
| Settings/Profile | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | PENDING HUMAN SIGN-OFF | Frozen (DR-017) |

---

## 25. Final Authorization

Rule check:

| Rule for AUTHORIZED FOR STEP 3 | Met? |
|---|---|
| All product decisions frozen | No — 6 pending |
| No P0 | Yes |
| No unresolved specification contradiction | Yes — DOC-01–03 are notes, not contradictions |
| Mandatory engineering dependencies understood | Yes — SD-01–SD-13 |
| Step 3 scope frozen | Yes — §21, §22 |

| Rule for AUTHORIZED WITH CONDITIONS | Met? |
|---|---|
| Step 3 can safely begin | Yes, once SD-01 human acceptance is given |
| Remaining issues affect specific screens/features | Yes — PDs affect landing routes, Admin Home layout, sync overlay, Queue call action, Visits tab |
| Runtime checks are release gates, not architecture blockers | Yes — 0 build blockers |
| Product decisions have explicit interim defaults | Yes — all six |

| Rule for NOT AUTHORIZED | Triggered? |
|---|---|
| P0 remains | No |
| Ambiguous business rule | No |
| KPI definitions conflict | No |
| Role permissions conflict | No |
| Navigation cannot be implemented safely | No |
| Critical product decision affects architecture | No — PD-01/02 change one redirect branch; PD-05 is presentation; PD-06 is one existing API call |
| Step 2.6 contradictory | No |

---

## 26. Step 3 Entry Conditions

```text
[ ] Step 2.6 specification accepted              — PENDING HUMAN SIGN-OFF (required; not waivable)
[ ] Decision Register accepted                   — PENDING HUMAN SIGN-OFF (required; not waivable)
[ ] PD-01 resolved                               — WAIVED FOR DEVELOPMENT
[ ] PD-02 resolved                               — WAIVED FOR DEVELOPMENT
[ ] PD-03 resolved                               — WAIVED FOR DEVELOPMENT
[ ] PD-04 resolved                               — WAIVED FOR DEVELOPMENT
[ ] PD-05 resolved                               — WAIVED FOR DEVELOPMENT
[ ] PD-06 resolved                               — WAIVED FOR DEVELOPMENT
[ ] Frozen decisions acknowledged                — PENDING HUMAN SIGN-OFF (required)
[ ] Step 3 screen scope accepted                 — PENDING HUMAN SIGN-OFF (required)
[x] KPI definitions frozen                       — frozen in DR-010–DR-013 and final spec §7
[x] Status terminology frozen                    — frozen in DR-019 and final spec §9
[x] Forms frozen                                 — frozen in DR-008, DR-009
[x] Telecaller workflows frozen                  — frozen in DR-005, DR-006, DR-014
[ ] RBAC boundaries acknowledged                 — PENDING HUMAN SIGN-OFF (documented in DR-023, FB-08)
[x] Backend dependencies isolated                — SD-11–SD-13, FB-01–FB-16
[x] Runtime release gates documented             — §12 of this document
```

Checked boxes record facts that are fully documented; they are not approvals.

**Why PD-01–PD-06 are WAIVED FOR DEVELOPMENT.** Each interim default equals current application behavior, so building against it changes no business behavior. Each decision is isolated: PD-01/PD-02 change only the post-login route branch; PD-03 blocks only the Visits tab (not built); PD-04 changes only Admin Home card arrangement; PD-05 changes only the sync indicator; PD-06 changes only whether the Queue Call button calls an existing API. The waiver covers development only. Each must be FINAL before the affected screen is signed off for release.

## 27. Step 3 Forbidden Changes

# DO NOT CHANGE DURING STEP 3

```text
KPI definitions
Database schema
Backend business rules
Lead allocation algorithm
Match engine
Role permissions
Status values
Telecaller shift timers
Shift lockout
Realtime architecture
Sync architecture
Campaign server limit (and the client 5000 request)
Existing API semantics
Property business fields
Lead business fields
Outcome semantics
Router guards and redirects (except SD-09 if PD-01/PD-02 are approved)
```

If a change becomes necessary during Step 3:

```text
STOP
DOCUMENT
RAISE CHANGE REQUEST
OBTAIN APPROVAL
THEN IMPLEMENT
```

### Change control rule (frozen)

```text
Step 3 discovers issue
        ↓
Do NOT silently change specification
        ↓
Create change request
        ↓
Identify affected decision ID (DR-/PD-/RV-/SD-/FB-)
        ↓
Assess business / technical impact
        ↓
Product + Engineering approval
        ↓
Update specification and Decision Register
        ↓
Implement
```

---

## 28. Final Summary

| Item | Value |
|---|---|
| Baseline verified | Yes (30 / 6 / 20 / 13 / 16; P0 0; P1 4) |
| Frozen decisions verified | 30 / 30, no conflicts |
| Product decisions | 6 PENDING |
| Runtime gates | 20: 0 blocking implementation, 3 release-only, 17 non-blocking |
| Step 3 authorized screens | 43 (35 unconditional, 8 conditional) |
| Step 3 dependencies | 13 |
| Documentation observations | 3 (DOC-01 P3, DOC-02 P2, DOC-03 P3), none blocking |
| P0 unresolved | 0 |
| P1 unresolved | 4 |

# FINAL STEP 2.7 AUTHORIZATION

```text
Implementation readiness: READY WITH CONDITIONS — all 43 screens buildable against frozen
                          decisions and interim defaults; 0 build blockers.
Product sign-off:         PENDING HUMAN SIGN-OFF — specification acceptance and PD-01–PD-06.
Engineering sign-off:     PENDING HUMAN SIGN-OFF — specification, register, dependencies.
QA readiness:             NOT STARTED — 20 runtime tests documented, none executed.
Release readiness:        NOT READY — 3 release gates (RV-01, RV-11, RV-20) and 6 product
                          decisions open; no human sign-off.

Final status:
AUTHORIZED WITH CONDITIONS
```

**Why.** No P0 remains, Step 2.6 has no contradictory requirement, KPI, status, form, workflow and navigation checks all pass, and every runtime item is a release gate or normal QA rather than an architecture blocker. It is not AUTHORIZED FOR STEP 3 because all six product decisions are pending and no human product or engineering sign-off exists. The conditions are:

1. Step 3 starts only after a human accepts the Step 2.6 specification, the Decision Register, the frozen decisions, the screen scope, and the RBAC boundaries.
2. Development uses the interim defaults for PD-01–PD-06. Each must be FINAL before its affected screen is signed off for release.
3. RV-01, RV-11, and RV-20 must pass before the telecaller calling screens and the telecaller mobile shell are released.
4. Every item in §27 stays unchanged unless it goes through the change control rule.

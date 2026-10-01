# PropKart Mobile UI/UX — Decision Register (Step 2.6)

Companion to `docs/PROPKART_MOBILE_UI_UX_FINAL_SPECIFICATION.md`. Evidence references point to `docs/PROPKART_MOBILE_UI_UX_STEP_2_5_VERIFICATION.md` (V-, C-, R- IDs) and code paths.

**Statuses.** FROZEN · PRODUCT DECISION REQUIRED · RUNTIME VERIFICATION REQUIRED · STEP 3 DEPENDENCY · FUTURE BACKLOG. Unresolved questions are never FROZEN.

**Code modified:** No.

---

## 1. Frozen and design decisions

| ID | Decision | Evidence | Final Decision | Owner Needed | Status | Step 3 Impact |
|---|---|---|---|---|---|---|
| DR-001 | Mobile shell breakpoint | C-01, V-01; `app_shell.dart` `isMobile < 768`; `CRMBreakpoints.tablet = 768` | Phone shell <768; tablet 768–1023 and desktop ≥1024 keep existing shell; token source `CRMBreakpoints`; 600 and screen literals are legacy | Engineering sign-off | FROZEN | New shell uses `CRMBreakpoints.tablet` |
| DR-002 | Telecaller shift system in mobile shell | C-02, V-58; `TelecallerShiftManager`, `TelecallerShiftGateOverlay`, `TelecallerAvailabilityToggle`, `/telecaller/availability` | Existing system hosted unchanged; toggle in top bar; overlays wrap shell; More shows read-only Shift row | Engineering sign-off | FROZEN | Wrap mobile shell with existing overlay |
| DR-003 | Screen-level breakpoint rule | C-03, V-02 | Applies to new mobile components; legacy screens migrate when touched | — | FROZEN | No global refactor |
| DR-004 | Role navigation (tabs and More) | §5.3 final spec; `ModernSidebar`, `PermissionMatrixService` defaults | TC: Home, Queue, Callbacks, CNR, More. SL: Home, Leads, Properties, More. AD/SA: Home, Leads, Properties, Reports, More | — | FROZEN | Build `MobileBottomNav` configs |
| DR-005 | Telecaller outcome matrix | §6 Step 2.5; `IntegrationService.transferLead`, `scheduleFollowup`, `updateLeadCampaignStatus` | CNR, Callback, Follow-up, Picked Up, Interested, Not interested with existing statuses and inputs | — | FROZEN | Outcome sheets |
| DR-006 | Picked Up is a hand-off | C-12, V-49; `campaign_leads_screen.dart:4945` | Sales user + mandatory remarks → transfer → leaves queue | — | FROZEN | Picked Up sheet |
| DR-007 | Telecaller Properties access | V-13; default `properties` true for Telecaller; sidebar shows it | Properties in Telecaller More | — | FROZEN | More row |
| DR-008 | Property wizard | C-09, V-38, V-39 | Basic (media), Location, Pricing, Contacts; existing fields only | — | FROZEN | 4-step mobile wizard |
| DR-009 | Lead wizard | C-10, C-11, V-43, V-44 | 7 steps; single budget; no alt phone/email/city/timeline/min/max | — | FROZEN | 7-step mobile wizard |
| DR-010 | KPI-06 drilldown | C-08, V-31; `/dashboard/site-visits-list` | Visit-record list over `site_visits` | — | FROZEN | Drilldown page |
| DR-011 | KPI-09 Active Requirements | C-07, V-29 | Removed from mobile; future KPI needs backend source | — | FROZEN | Do not render |
| DR-012 | KPI-10 Deals Won | C-06, V-28 | Removed; not an alias of Deal Won | — | FROZEN | Do not render |
| DR-013 | Telecaller KPIs in inventory | V-33; `telecaller_dashboard_screen.dart:347–357` | TC-01–TC-10 added to KPI master | — | FROZEN | TC Home grid + stats list |
| DR-014 | Callback / Follow-up / CNR separation | §7 Step 2.5; `_leftCallingQueue` | Callback leaves queue; Follow-up stays; CNR to CNR tab | — | FROZEN | Separate tabs/cards |
| DR-015 | Session expiry | C-14, V-23 | Keep redirect to `/get-started?from=` | — | FROZEN | No dialog |
| DR-016 | Forbidden route behavior | C-21, V-92 | Keep router redirects; `MobilePermissionState` only on API 403 | — | FROZEN | No guard changes |
| DR-017 | Sync diagnostics visibility | C-23, V-21; `settings_screen.dart:246` | Admin and Super Admin | — | FROZEN | More row for AD/SA |
| DR-018 | Search and debounce | C-17, V-70–V-73 | One search chrome; existing per-surface sources and debounces; no recent searches | — | FROZEN | `MobileSearch` |
| DR-019 | Status terminology | §8 Step 2.5 | Presentation labels per final spec §9; "Rejected", not "Lost"; backend values unchanged | — | FROZEN | Labels in chips/sheets |
| DR-020 | Campaign pagination strategy | C-13, V-82, V-83 | Preserve existing 5000 request in Step 3; lazy rendering; server paging is a dependency | Engineering | FROZEN | No limit change |
| DR-021 | Offline state model | V-75, V-93 | Cached read / syncing / pending write (outbox only) / direct server operation / failed write | — | FROZEN | No "Waiting to sync" for outcomes |
| DR-022 | Realtime dependency | V-94 | Mobile does not depend on realtime; refresh fallback | — | FROZEN | Pull-to-refresh, refetch on focus |
| DR-023 | RBAC preservation | §15 Step 2.5, V-91 | Existing permission matrix, guards, backend permissions unchanged | — | FROZEN | Visibility via `canViewRoute` |
| DR-024 | Dead / unreachable features | §16 Step 2.5 | Not in mobile; not deleted; cleanup in backlog | — | FROZEN | None |
| DR-025 | Not-found page copy | C-15 | Friendly copy + role-home button | — | FROZEN | Step 3 implementation |
| DR-026 | Raw error exposure | C-19, V-76 | No raw exceptions on touched screens | — | FROZEN | Error mapping on touched screens |
| DR-027 | Semantics | C-20, V-78 | Semantics in all new mobile components | — | FROZEN | Component requirement |
| DR-028 | Bottom nav label size | C-22 | 12px labels in new bar | — | FROZEN | Component requirement |
| DR-029 | Negotiation status | C-24 | Existing status used | — | FROZEN | Status sheet |
| DR-030 | Table and dialog conversion scope | V-95, V-69; final spec §22–§23 | Convert tables/dialogs on Step 3 screens; desktop-only and backlog items listed | — | FROZEN | Per-screen conversions |

## 2. Product decisions

| ID | Decision | Evidence | Final Decision | Owner Needed | Status | Step 3 Impact |
|---|---|---|---|---|---|---|
| PD-01 | Telecaller default landing | C-04, V-07, R31 | Pending. Interim: `/dashboard` → `TelecallerDashboardScreen` | Product | PRODUCT DECISION REQUIRED | Router change only if Queue chosen |
| PD-02 | Sales default landing | V-16 | Pending. Interim: `/dashboard` → `SalesDashboardScreen` (Home tab) | Product | PRODUCT DECISION REQUIRED | Router change only if Leads chosen |
| PD-03 | Sales Visits source | V-15, V-31, R22 | Pending. Interim: no Visits tab; Leads status filter | Product | PRODUCT DECISION REQUIRED | Blocks Visits tab only |
| PD-04 | KPI-04 presentation | C-05, V-26, V-30 | Pending. Interim: two cards per KPI config | Product | PRODUCT DECISION REQUIRED | Admin Home sign-off |
| PD-05 | Sync overlay blocking vs non-blocking | C-18, V-74 | Pending. Interim: keep blocking overlay | Product | PRODUCT DECISION REQUIRED | Shell keeps overlay |
| PD-06 | Record start-call from Queue | V-55 | Pending. Interim: `tel:` only, as today | Product | PRODUCT DECISION REQUIRED | No server write added |

## 3. Runtime verification

| ID | Decision | Evidence | Final Decision | Owner Needed | Status | Step 3 Impact |
|---|---|---|---|---|---|---|
| RV-01 | Idle auto-break during external dialer | V-58, §14 Step 2.5 | Test on device | QA | RUNTIME VERIFICATION REQUIRED | Blocks queue/outcome release |
| RV-02 | Actual campaign rows returned | C-13, V-82 | Log per role | Engineering | RUNTIME VERIFICATION REQUIRED | Blocks campaign performance change |
| RV-03 | Realtime topic behavior | V-94 | Two-device test | Engineering | RUNTIME VERIFICATION REQUIRED | None (fallback) |
| RV-04 | Report KPI captions | R06, V-65 | Capture | QA | RUNTIME VERIFICATION REQUIRED | Copy only |
| RV-05 | Contrast | R11 | Measure | Design/QA | RUNTIME VERIFICATION REQUIRED | Token tweaks if needed |
| RV-06 | Text scale 1.3× | V-80 | Device check | QA | RUNTIME VERIFICATION REQUIRED | Layout fixes in new components |
| RV-07 | Tablet orientation / Android 16 | R13, V-81 | Rotate tablet | QA | RUNTIME VERIFICATION REQUIRED | None expected |
| RV-08 | Image decode size | R14, V-85 | Profile | Engineering | RUNTIME VERIFICATION REQUIRED | None expected |
| RV-09 | Per-screen offline behavior | R15, V-77 | Airplane mode | QA | RUNTIME VERIFICATION REQUIRED | Offline copy per screen |
| RV-10 | Gallery double-tap zoom | R28, V-42 | Device | QA | RUNTIME VERIFICATION REQUIRED | Gesture copy |
| RV-11 | `tel:` resolution on Android 11+ | §14 Step 2.5 | Device | QA | RUNTIME VERIFICATION REQUIRED | Blocks queue calling release |
| RV-12 | KPI-06 drilldown search bug | V-31; `kpi.service.js:1444` | Test search | QA | RUNTIME VERIFICATION REQUIRED | Hide search on that page if failing |
| RV-13 | CNR/callback timing targets | V-59, R07 | Timed session | QA | RUNTIME VERIFICATION REQUIRED | None |
| RV-14 | TalkBack / VoiceOver | R12 | Device | QA | RUNTIME VERIFICATION REQUIRED | Label fixes |
| RV-15 | Admin "Needs attention" data | V-34 | Inspect | QA | RUNTIME VERIFICATION REQUIRED | Section shown or omitted |
| RV-16 | Legacy drawer gesture | R05 | Device | QA | RUNTIME VERIFICATION REQUIRED | None |
| RV-17 | Property client-side filters | V-40 | Inspect | QA | RUNTIME VERIFICATION REQUIRED | Filter sheet scope |
| RV-18 | Bell on 360px | V-06 | Device | QA | RUNTIME VERIFICATION REQUIRED | Top bar layout |
| RV-19 | Failed campaign-status PATCH state | §14 Step 2.5 | Force failure | QA | RUNTIME VERIFICATION REQUIRED | Reload-on-failure behavior |
| RV-20 | What stays visible under shift overlays | V-58 | Device | QA | RUNTIME VERIFICATION REQUIRED | Blocks M-43 sign-off |

## 4. Step 3 dependencies

| ID | Decision | Evidence | Final Decision | Owner Needed | Status | Step 3 Impact |
|---|---|---|---|---|---|---|
| SD-01 | Sign-off of FROZEN decisions | this register | Required before Step 3 | Product + Engineering | STEP 3 DEPENDENCY | Gate to start |
| SD-02 | PD-01 resolved | PD-01 | Before final TC landing | Product | STEP 3 DEPENDENCY | Interim allows work |
| SD-03 | PD-03 resolved | PD-03 | Before Visits tab | Product | STEP 3 DEPENDENCY | Visits tab only |
| SD-04 | PD-04 resolved | PD-04 | Before Admin Home sign-off | Product | STEP 3 DEPENDENCY | Interim allows build |
| SD-05 | RV-01 passed | RV-01 | Before queue/outcome release | QA | STEP 3 DEPENDENCY | Release gate |
| SD-06 | RV-11 passed | RV-11 | Before queue calling release | QA | STEP 3 DEPENDENCY | Release gate |
| SD-07 | RV-02 measured | RV-02 | Before campaign performance work | Engineering | STEP 3 DEPENDENCY | Scope gate |
| SD-08 | `/more` presentation route | V-12 | Implement in Step 3 | Engineering | STEP 3 DEPENDENCY | New route, no backend |
| SD-09 | Router landing change | PD-01, PD-02 | Only if approved | Engineering | STEP 3 DEPENDENCY | Router-only change |
| SD-10 | Sales Home field mapping | V-35 | Map `salesDashboardSummary` fields | Engineering | STEP 3 DEPENDENCY | Sales Home cards |
| SD-11 | Server pagination for lists | V-83 | Not in Step 3 | Backend/Engineering | STEP 3 DEPENDENCY | Lists stay local-first |
| SD-12 | Offline outbox for campaign outcomes | V-93 | Not in Step 3 | Engineering | STEP 3 DEPENDENCY | No "Waiting to sync" for outcomes |
| SD-13 | Realtime fix | V-94 | Not in Step 3 | Engineering | STEP 3 DEPENDENCY | Fallback refresh |

## 5. Future backlog

| ID | Decision | Evidence | Final Decision | Owner Needed | Status | Step 3 Impact |
|---|---|---|---|---|---|---|
| FB-01 | Active Requirements KPI with a backend source | DR-011 | Later | Product + Backend | FUTURE BACKLOG | None |
| FB-02 | Super-admin org switcher UI | V-64 | Later | Product | FUTURE BACKLOG | None |
| FB-03 | Unified server search (`/api/v1/search`) | V-73 | Later | Backend | FUTURE BACKLOG | None |
| FB-04 | Server pagination adoption | SD-11 | Later | Backend | FUTURE BACKLOG | None |
| FB-05 | Offline outcome capture | SD-12 | Later | Engineering | FUTURE BACKLOG | None |
| FB-06 | Rollback on failed campaign-status PATCH | V-93 | Later | Engineering | FUTURE BACKLOG | None |
| FB-07 | Realtime topic/handler and callbacks subscription | SD-13 | Later | Engineering | FUTURE BACKLOG | None |
| FB-08 | Permission middleware on reports and telecaller transfer/remarks routes | V-66, V-91 | Later | Backend/Security | FUTURE BACKLOG | None |
| FB-09 | Site-visits search placeholder fix | `kpi.service.js:1444` | Later | Backend | FUTURE BACKLOG | None |
| FB-10 | Legacy breakpoint migration on untouched screens | DR-003 | Later | Engineering | FUTURE BACKLOG | None |
| FB-11 | Raw error cleanup on untouched screens | DR-026 | Later | Engineering | FUTURE BACKLOG | None |
| FB-12 | Semantics on untouched screens | DR-027 | Later | Engineering | FUTURE BACKLOG | None |
| FB-13 | Dead code removal | DR-024 | Later | Engineering | FUTURE BACKLOG | None |
| FB-14 | Clients / Owners / Builders / Pipeline restoration | DR-024 | Later | Product | FUTURE BACKLOG | None |
| FB-15 | Replace raw `Image.network` in library | V-85 | Later | Engineering | FUTURE BACKLOG | None |
| FB-16 | Remove legacy `recordOutcome` path | §6 Step 2.5 | Later | Engineering | FUTURE BACKLOG | None |

---

## 6. Totals

| Status | Count |
|---|---|
| FROZEN | 30 |
| PRODUCT DECISION REQUIRED | 6 |
| RUNTIME VERIFICATION REQUIRED | 20 |
| STEP 3 DEPENDENCY | 13 |
| FUTURE BACKLOG | 16 |
| **Total** | **85** |

P0 unresolved: 0. P1 unresolved: 4 (PD-01, PD-03, PD-04, PD-06).

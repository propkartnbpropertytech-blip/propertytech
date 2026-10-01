# PropKart Mobile UI/UX — Step 2.5 Technical and Runtime Verification

**Scope.** Read, trace, verify only. This document checks `docs/PROPKART_MOBILE_UI_UX_MASTER_SPECIFICATION.md` (Step 2) against the code in `C:\NB\propkart` (Flutter, branch `local_setup`) and `C:\NB\PropKart-Backend` (Node/Express, Supabase).

**Code modified:** No. No source, route, BLoC, API, database, KPI, RBAC, status, sync, or existing document was changed. Nothing was committed. This file is the only file created.

**Method.** Static reading of routes, widgets, services, repositories, backend routes and services, and constants. No device build was run. Anything that depends on a device, network, or live data is marked **RUNTIME VERIFICATION REQUIRED**. Uncertainty was not upgraded to CONFIRMED.

**Status vocabulary.** CONFIRMED · PARTIALLY CONFIRMED · CONTRADICTED · NOT FOUND · RUNTIME VERIFICATION REQUIRED · PRODUCT DECISION REQUIRED · IMPLEMENTATION DEPENDENCY.
**Labels.** IMPLEMENTED BUT UNREACHABLE · ROUTE EXISTS — REDIRECTED · PRESENTATION EXISTS — BACKEND DEPENDENCY.

**Severity.** P0 blocks Step 3 shell work. P1 must be resolved or explicitly accepted before the affected screen is built. P2 fix during the affected screen. P3 polish or documentation.

---

## 1. Master verification table

| ID | Step 2 Section | Requirement | Source Evidence | Actual Behavior | Status | Risk | Step 3 Action |
|---|---|---|---|---|---|---|---|
| V-01 | §5, §39 | Phone shell below 700px; desktop at 700+ | `app_shell.dart` `isMobile = width < 768`, tablet 768–1024 shows sidebar; `CRMBreakpoints.tablet = 768`; `app_breakpoints.dart` tablet 768; `app_constants.dart` mobileMax 600 | Shell switches at 768, not 700. Three competing token sets exist | CONTRADICTED | P0 | Freeze one shell breakpoint before M0 |
| V-02 | §39 | No screen may add its own breakpoint | 700 used 31×, 600 48×, 768 11×, 900 13×, 1024 8×; plus 360–1200 values | Screens branch on many local widths | CONTRADICTED | P1 | Inventory per screen; migrate only screens touched |
| V-03 | §10 | Bottom nav ≤5 slots, height 64 | `CustomBottomNavBar` (`app_shell.dart:3970`), height 64, 4 tabs + center plus | Exists; height matches | PARTIALLY CONFIRMED | P2 | Reuse or replace; keep 64 |
| V-04 | §10 | Labels always visible, `captionBold` 12 | Bottom bar label fontSize 9, icon 22 | Label 9px | CONTRADICTED | P3 | Adopt Step 2 size when bar is rebuilt |
| V-05 | §10 | Plus is an app-bar action, not center | Center circular plus index 2 → `_showQuickActionsBottomSheet` | Current is center plus | IMPLEMENTATION DEPENDENCY | P2 | Move only when new bar ships |
| V-06 | §10 | Bell keeps existing count | Notifications polled every 25s in `app_shell.dart` | Badge source exists; phone render not seen | PARTIALLY CONFIRMED | P3 | Runtime check on 360px |
| V-07 | §11, §43 | Telecaller lands on Queue, not `/dashboard` | `app_router.dart` post-login and splash redirect every role to `/dashboard`; `DashboardScreen.build` renders `TelecallerDashboardScreen` | Telecaller lands on telecaller dashboard | CONTRADICTED | P1 | Requires router redirect change (dependency) |
| V-08 | §11 | Queue = `/campaign/leads` | `ModernSidebar` "My Calling Leads" → `/campaign/leads`; `/telecaller/leads` also mounts `CampaignLeadsScreen` | Same widget on two routes | CONFIRMED | — | Pick one route for the tab |
| V-09 | §11 | Callbacks = `/telecaller/callbacks` | Route mounts `TelecallerCallbacksScreen` | Exists | CONFIRMED | — | — |
| V-10 | §11 | CNR = `/telecaller/cnr` | Route mounts `TelecallerCnrScreen` (`telecaller_callbacks_screen.dart:719`) | Exists | CONFIRMED | — | — |
| V-11 | §11 | Telecaller Leads = `/requirements` | Sidebar "All Leads (Track)" for telecaller | Exists | CONFIRMED | — | — |
| V-12 | §11, §12 | `/more` route | No route in `app_router.dart` | Absent | IMPLEMENTATION DEPENDENCY | P1 | New presentation route |
| V-13 | §11 | Telecaller tabs omit Properties | `PermissionMatrixService` default `properties` = true for Telecaller; sidebar shows Properties | Telecaller can open Properties today | PRODUCT DECISION REQUIRED | P1 | Decide: More row or hidden |
| V-14 | §11, §19 | Sales leads scoped to user | Backend GET `/requirements` forces `salesUserId` for Sales | Server-side scope | CONFIRMED | — | — |
| V-15 | §11 | Sales Visits tab by site-visit status | Requirement status `Site Visit` ("Site Visit Sche.") and `Site Visit Done` in `requirements_screen.dart:2787`; KPI-06 counts `site_visits.status='COMPLETED'` | Two sources of "site visit done" | PARTIALLY CONFIRMED | P1 | Product picks the source for the tab |
| V-16 | §11, §15 | Sales dashboard only inside More | Sales lands on `/dashboard` → `SalesDashboardScreen` (`sales_dashboard_bloc.dart`) | Sales home is the dashboard | PRODUCT DECISION REQUIRED | P2 | Confirm Sales home |
| V-17 | §11 | Admin/SA tab routes | `/dashboard`, `/requirements`, `/properties`, `/reports/leads/overall-business-insight` exist | Exist | CONFIRMED | — | — |
| V-18 | §11, §45 | Campaign absent for Telecaller | Sidebar hides Campaign tree for telecaller; default `campaign` = true for Telecaller; no router guard on `/campaign/*` | UI hidden, route open | PARTIALLY CONFIRMED | P1 | Keep queue reachable; do not hide by permission key |
| V-19 | §12, §20 | Lead allocation SA/AD only | Router redirects non-Admin/SA from `/admin/lead-allocation` to `/telecaller/leads` | ROUTE EXISTS — REDIRECTED for others | CONFIRMED | — | — |
| V-20 | §12 | Audit logs SA only | `RoleGuard.canViewAuditLogs` SA only; default `audit_logs` false for all roles | SA only | CONFIRMED | — | — |
| V-21 | §12, §24 | Sync debug SA only | `settings_screen.dart:246` `if (isAdminOrSuperAdmin)` wraps "Sync Diagnostics" → `SyncDebugScreen` (line 307) | Admin also sees it | CONTRADICTED | P3 | Product decides Admin visibility |
| V-22 | §12 | Messages row if `/messages` allowed | `page.messages` true by default for all roles; `top_bar.dart:935` `context.go('/messages')` | Route exists | CONFIRMED | — | — |
| V-23 | §34 | Session expired = blocking dialog | Router global redirect to `/get-started?from=` | Redirect, no dialog | CONTRADICTED | P2 | Decide dialog vs redirect |
| V-24 | §14, §30 | MFA page, 6 digits | `mfa_verify_dialog.dart`: `showDialog(barrierDismissible:false)`, pinput 6-digit TOTP SHA1/30s | 6 digits confirmed; it is a dialog | PARTIALLY CONFIRMED | P2 | Page conversion is presentation only |
| V-25 | §41 MOB-007 | Not-found page without raw error | Router `errorBuilder` shows `state.error.toString()` | Raw error text | CONTRADICTED | P2 | Replace copy |
| V-26 | §15 | One "Leads Allocated" KPI-04 card | `_buildModernKpiCards` (`dashboard_screen.dart:803`): "New Leads Allocated" (`leads_allocated`) and "Old Leads Allocated" (`old_leads_allocated`); `kpi.service.js` default config has both | Two cards | CONTRADICTED | P1 | Product picks one or both |
| V-27 | §15, §28 | Show only Deal Won | Live card "Deal Won" from `counts.dealWon`; "Deals Won" only in `_buildInventoryOverview` (no callers) | Only Deal Won is live | CONFIRMED | — | — |
| V-28 | §28 | KPI-10 is the same metric as KPI-07 | "Deals Won" read `summary.rentalWonRequirements`; backend GET `/dashboard` (`dashboard.service.js` ~331–345) never returns it; Deal Won = `requirements.status='Won'` | Different sources; KPI-10 is dead and unbacked | CONTRADICTED | P1 | Drop KPI-10 from spec language |
| V-29 | §28 | KPI-09 Active Requirements row | Only in `_buildInventoryOverview` (no callers); not in `/dashboard/kpis` config | Not live | CONTRADICTED | P1 | Remove or source from an existing API |
| V-30 | §28 | KPI-04 tap → allocation or lead list | Both cards → `showLeadsAllocatedDrilldown` → `getLeadsAllocatedBreakdown` (per-telecaller new/old counts) | Aggregate dialog, not a lead list | PARTIALLY CONFIRMED | P1 | Phone list = telecaller rows |
| V-31 | §28 | KPI-06 tap → lead list with visit filter | `showSiteVisitsDrilldown` → `/dashboard/site-visits-list` over `site_visits`; search bug in `kpi.service.js:1444` (`ILIKE ${params.length}` without `$`) | Visit records, not leads | CONTRADICTED | P1 | Do not map KPI-06 to requirement status |
| V-32 | §28 | KPI-01/03/05/08 taps | Inventory, telecallers, assigned-to-sales, sales-users drilldowns exist as dialogs | Targets exist as dialogs | PARTIALLY CONFIRMED | P2 | Convert to pages |
| V-33 | §28 | KPI-11–21 strips cover the rest | `telecaller_dashboard_screen.dart:347–357` has 10 KPIs from `/telecaller/dashboard` | Telecaller KPIs not named in Step 2 | PARTIALLY CONFIRMED | P2 | Add to KPI inventory |
| V-34 | §15 | "Needs attention" from existing data | Admin dashboard notes/checklist calls exist; exact rows not traced | Unproven | RUNTIME VERIFICATION REQUIRED | P3 | Check on device |
| V-35 | §15 | Sales summary shows KPI-02/06/07 | `SalesDashboardScreen` uses `ApiConstants.salesDashboardSummary`, not `/dashboard/kpis` | Different endpoint | IMPLEMENTATION DEPENDENCY | P2 | Map fields before building |
| V-36 | §15 | Telecaller does not get admin home | `DashboardScreen.build` branches by role | Confirmed | CONFIRMED | — | — |
| V-37 | §16 | Use existing sort keys | `properties_screen.dart` client-side `l2h` / `h2l`; GET `/properties` sends no sort | Price asc/desc, client-side | CONFIRMED | — | — |
| V-38 | §16 | Wizard: Basics, Location, Media, Details | `add_edit_property_screen.dart`: Basic (incl. images/videos), Location, Pricing, Contacts | Different order and grouping | CONTRADICTED | P1 | Keep current 4 steps |
| V-39 | §16 | Field list matches form | Payload ~lines 1156–1210 (see §11) | Step 2 omits many fields | PARTIALLY CONFIRMED | P1 | Use §11 table |
| V-40 | §16 | Filters: listing type, BHK, price, locality, status | Server params: search, categoryId, areaId, listingTypeId, createdBy, isVerified, includeDeleted | BHK/price/status not server params | PARTIALLY CONFIRMED | P2 | Runtime check client filters |
| V-41 | §16 | Existing pickers and limits | `UploadLimitsManager` 30 images / 5 videos default, clamp 100/20; backend 10 MB / 100 MB | Confirmed | CONFIRMED | — | — |
| V-42 | §36 | Double-tap zoom if supported | Zoom viewer exists; double-tap not traced | Unproven | RUNTIME VERIFICATION REQUIRED | P3 | Device test |
| V-43 | §17 | Lead wizard 3 steps | `add_edit_requirement_screen.dart` 7 steps (`_activeStep < 6`) | 7 steps | CONTRADICTED | P1 | Keep 7 or product-approved regroup |
| V-44 | §17 | Fields: alternate phone, email, city, budget min/max | Not in form; budget is one text field parsed to a range (single value → ×0.8 / ×1.2) | Invented fields | CONTRADICTED | P1 | Use §12 table |
| V-45 | §17 | Telecaller add has no assignment | Admin/SA/Telecaller create unassigned; Sales self-assigns | Confirmed | CONFIRMED | — | — |
| V-46 | §17 | Negotiation needs product decision | `requirements_screen.dart` status list includes Negotiation | Status exists | CONTRADICTED | P3 | Use existing status |
| V-47 | §17 | "Lost" transition | No "Lost"; "Rejected…" prefixed statuses, tab "Rejected" | Named Rejected | CONTRADICTED | P2 | Use Rejected labels |
| V-48 | §17, §44 | Won requires property pick | `RequirementWinPropertySelectionDialog` (`requirements_screen.dart:1572`, class 12540) | Confirmed | CONFIRMED | — | — |
| V-49 | §17, §18 | Picked up = confirm, nothing required | `_showTransferDialog` (`campaign_leads_screen.dart:4245`): "Picked Up" requires sales user and mandatory remarks (line 4945), then transfer to sales | Picked Up is a hand-off to Sales | CONTRADICTED | P1 | Picked Up sheet must include user + remarks |
| V-50 | §17 | Callback leaves queue → Callbacks | `_leftCallingQueue` true for callback / pending `callbackScheduledAt`; `/telecaller/callbacks` reads `campaign_lead_callbacks` | Confirmed | CONFIRMED | — | — |
| V-51 | §17 | CNR → CNR queue | `transferLead(status:'CNR')`; `/telecaller/cnr` filters CNR | Confirmed | CONFIRMED | — | — |
| V-52 | §17 | Not interested needs reason | `updateLeadCampaignStatus(id,'Not interested', reason)` → leads stage LOST, NOT_INTERESTED | Confirmed | CONFIRMED | — | — |
| V-53 | §18 | Follow-ups stay in queue | `_leftCallingQueue` false for Follow up / FOLLOWUP | Confirmed | CONFIRMED | — | — |
| V-54 | §18 | Outcome bar after Call | Outcomes live in `_showTransferDialog` (CNR / Callback / Picked Up) and separate Not interested flow | Dialog, no post-call bar | IMPLEMENTATION DEPENDENCY | P1 | Presentation change over same service calls |
| V-55 | §18 | Call via `tel:` | Queue `_launchTel` only `launchUrl('tel:')`; callbacks `_handleStartCall` calls `startCall` then `tel:` | Queue calls are not recorded | PARTIALLY CONFIRMED | P1 | Product decides whether queue records start-call |
| V-56 | §18 | No call timer unless it exists | No timer in queue, callbacks, or repository | Absent | NOT FOUND | — | Do not design one |
| V-57 | §18 | "{n} in queue" from loaded list | Queue = client filter over up to 5000 fetched rows | Count limited by fetch | PARTIALLY CONFIRMED | P2 | Label count as loaded |
| V-58 | §18 | No break/availability system; do not invent | `TelecallerShiftManager` (ACTIVE/INACTIVE/BREAK, 5-min idle auto-break, 9-hour lockout, 30s heartbeat); `TelecallerShiftGateOverlay` (3 blocking overlays); `TelecallerAvailabilityToggle` (`top_bar.dart:843`); backend POST `/telecaller/availability` | Fully implemented and blocking | CONTRADICTED | P0 | Phone shell must host gate and toggle |
| V-59 | §18, §44 | CNR <20s, callback <40s | Design targets | Not measured | RUNTIME VERIFICATION REQUIRED | P3 | Time on device |
| V-60 | §19 | Pipeline behind clients redirect | `/clients` → `/dashboard`; `PipelineScreen` no callers | Confirmed | CONFIRMED | — | — |
| V-61 | §21 | Sales report empty state | `/reports/leads/sales` → `SalesReportPlaceholderScreen` | Confirmed | CONFIRMED | — | — |
| V-62 | §21 | Property reports empty state | `/reports/properties` → `PropertiesComingSoonScreen` | Confirmed | CONFIRMED | — | — |
| V-63 | §21, §46 | Ignore lead metrics placeholder | `LeadMetricsPlaceholderScreen` no references | Confirmed | CONFIRMED | — | — |
| V-64 | §21 | Org switcher sheet if control exists | `super_admin_metrics_screen.dart` has no org control; backend reports accept `filters.organization_id` for SA | Backend supports, UI absent | NOT FOUND | P2 | Product decides whether to add |
| V-65 | §21 | Report captions from payload | Captions are payload-driven | Not listed | RUNTIME VERIFICATION REQUIRED | P3 | Capture on device |
| V-66 | §21, §45 | Reports hidden for Telecaller | `RoleGuard.canViewReports` + default `reports` true only for Admin; backend `reports.routes.js` uses `authenticate` only, scopes rows by role | UI hidden; API not permission-gated | PARTIALLY CONFIRMED | P1 | Note for security backlog, no change in Step 3 |
| V-67 | §24 | Notifications settings row | No notifications section in settings | Absent | NOT FOUND | — | Omit row |
| V-68 | §26 | `/messages` is the inbox | `top_bar.dart:935`; `TeamMessengerDialog.show` also routes to `/messages`; dialog widget never built | Route authoritative | CONFIRMED | — | — |
| V-69 | §30 | KPI drilldown dialogs → full-screen lists | `kpi_drilldown_dialogs.dart` ~13 `showDialog` entry points | Dialogs today | IMPLEMENTATION DEPENDENCY | P2 | Page wrappers over same services |
| V-70 | §32 | Debounce 300ms | Shell 500ms; campaign 250/150/250ms; requirements 200ms | No 300ms | CONTRADICTED | P2 | Keep per-screen values or product sets one |
| V-71 | §32 | No recent-search store | No store found | Absent | NOT FOUND | — | Do not add |
| V-72 | §32 | `/search` mounts which UI | `/search` → `PropertySearchScreen` (outside shell); also `drawers.dart:276` | Confirmed | CONFIRMED | — | — |
| V-73 | §32 | One search UI, contextual API | Global search = client fuzzy over Isar (`_performSearch`); backend `/api/v1/search` unused | Multiple local searches | PARTIALLY CONFIRMED | P2 | Merge chrome only |
| V-74 | §34 | Syncing = non-blocking caption | `app_shell.dart` full-screen overlay "Updating lookup lists..." while `SyncManager.isSyncing` | Blocking | CONTRADICTED | P2 | Product approves non-blocking |
| V-75 | §34 | Pending writes caption if a queue exists | `OutboxLocal` + `SyncManager` replay for properties/requirements; campaign outcomes call API directly | Partial queue | PARTIALLY CONFIRMED | P1 | Caption only where outbox applies |
| V-76 | §34 | Never show exceptions | ~45 SnackBars with raw `$e`; 198 `e.toString()`; telecaller dashboard shows `state.error` | Raw errors shown | CONTRADICTED | P2 | Copy mapping on touched screens |
| V-77 | §34 | Offline per screen | Isar caches vary by feature | Unproven per screen | RUNTIME VERIFICATION REQUIRED | P2 | Airplane-mode pass |
| V-78 | §35 | Icon buttons have semantics | 0 `Semantics`/`semanticLabel`; 330 `IconButton`, 188 `tooltip:` | Tooltips only | CONTRADICTED | P2 | Add labels in new widgets |
| V-79 | §35 | Contrast | Not measurable statically | — | RUNTIME VERIFICATION REQUIRED | P3 | WCAG check |
| V-80 | §35 | Text scale 1.3× | Not measurable statically | — | RUNTIME VERIFICATION REQUIRED | P3 | Device check |
| V-81 | §5 | Orientation / Android 16 | No `screenOrientation` in manifest; 0 orientation APIs | Unlocked | RUNTIME VERIFICATION REQUIRED | P3 | Rotate tablet |
| V-82 | §38 | Campaign fetch limit 1000 | `integration_service.dart` `_executeFetchServerLeads` GET `/integrations/leads` `limit: 5000`; backend default 200, range + `count:'exact'`; PostgREST max-rows may cap | 5000 requested | CONTRADICTED | P1 | Runtime log actual rows |
| V-83 | §38 | Phone lists 30 rows via existing limit | APIs accept page/limit (integration leads; requirements ≤200; properties ≤200; drilldowns 25); clients full-sync to Isar and filter locally | Server paging unused by lists | IMPLEMENTATION DEPENDENCY | P1 | Paging changes data flow, not only UI |
| V-84 | §38 | Lazy list children | 80 lazy builders; 175 `SingleChildScrollView`; 20 `ListView(` | Mixed | PARTIALLY CONFIRMED | P2 | Builders in new widgets |
| V-85 | §38 | Gallery decodes to display size | `CrmNetworkImage` sets cacheWidth/memCacheWidth (22 uses); 7 raw `Image.network` in library | Mostly | PARTIALLY CONFIRMED | P2 | Network trace |
| V-86 | §38 | Campaign widget ~12,000 lines | `campaign_leads_screen.dart` 12,795 lines | Confirmed | CONFIRMED | — | — |
| V-87 | §42, §46 | `_buildSidebarContent` unused | `app_shell.dart:3085`, no callers | IMPLEMENTED BUT UNREACHABLE | CONFIRMED | — | — |
| V-88 | §46 | IntegrationScreen deprecated, route redirects | `/integration` → `/campaign/leads`; no constructor callers | IMPLEMENTED BUT UNREACHABLE | CONFIRMED | — | — |
| V-89 | §46 | HomeScreen, CRMPlaceholderScreen unreferenced | No constructor callers | IMPLEMENTED BUT UNREACHABLE | CONFIRMED | — | — |
| V-90 | §41 MOB-031 | TelecallerLeadsScreen vs queue | Not routed; `/telecaller/leads` mounts `CampaignLeadsScreen` | IMPLEMENTED BUT UNREACHABLE | CONFIRMED | — | — |
| V-91 | §45 | API still enforces | Most routes use `requirePermission`; `/telecaller/transfer-lead`, `/telecaller/attempts/:id/remarks`, `/telecaller/transferred-leads`, `/telecaller/sales-users`, reports use `authenticate` only | Partial | PARTIALLY CONFIRMED | P1 | Security backlog; no change in Step 3 |
| V-92 | §45, §13 | Forbidden deep link → permission state | Router redirects (e.g. allocation → `/telecaller/leads`); most shell routes unguarded | Redirect or open, never a permission page | CONTRADICTED | P2 | Product picks behavior |
| V-93 | §43 | Telecaller offline "Waiting to sync" | Outcomes go to API directly; optimistic Isar write without rollback in `updateLeadCampaignStatus` | No outcome queue | IMPLEMENTATION DEPENDENCY | P1 | Do not show "Waiting to sync" for outcomes |
| V-94 | §34, §43 | Cards update after changes | `SyncManager` joins `realtime:propkart`; `_handleIncomingMessage` accepts only `realtime:public`; `campaign_lead_callbacks` not watched | Realtime may be inert | RUNTIME VERIFICATION REQUIRED | P1 | Verify before relying on push updates |
| V-95 | §29 | Tables → cards | 32 `DataTable(`, 12 `CRMDataTable(`, 0 `PaginatedDataTable` | Tables exist | IMPLEMENTATION DEPENDENCY | P2 | Card builders per screen |

---

## 2. Runtime verification register (Step 2 §50), verified individually

Step 2 §50 contains 30 rows. The Step 2.5 prompt referred to 31 items, so R31 adds screen-master item MOB-009, which Step 2 also left open.

| # | Step 2 item | Evidence | Finding | Status |
|---|---|---|---|---|
| R01 | Telecaller branch inside DashboardScreen | `dashboard_screen.dart` `build` | Telecaller → `TelecallerDashboardScreen`; Sales → `SalesDashboardScreen` | CONFIRMED |
| R02 | Which search `/search` mounts | `app_router.dart` | `PropertySearchScreen` wrapped in `MobileSystemBackHandler(homeLocation:'/get-started')` | CONFIRMED |
| R03 | TelecallerLeadsScreen vs campaign queue | `app_router.dart` `/telecaller/leads` | Mounts `CampaignLeadsScreen`; `TelecallerLeadsScreen` IMPLEMENTED BUT UNREACHABLE | CONFIRMED |
| R04 | LeadMetricsPlaceholderScreen references | repo-wide search | No references | CONFIRMED |
| R05 | Drawer open gesture on phone | `app_shell.dart` mobile `Drawer` with `ModernSidebar` | Drawer exists; gesture behavior not exercised | PARTIALLY CONFIRMED |
| R06 | Report KPI captions from API | `business_insight_summary.dart`, report widgets | Payload-driven; values not captured | RUNTIME VERIFICATION REQUIRED |
| R07 | CNR and callback elapsed time | — | Needs timed device test | RUNTIME VERIFICATION REQUIRED |
| R08 | Telecaller break/offline control | `telecaller_shift_manager.dart`, `telecaller_shift_gate_overlay.dart`, `top_bar.dart:843` | Full shift system with blocking overlays | CONTRADICTED |
| R09 | Notifications settings section | `settings_screen.dart` | No section | NOT FOUND |
| R10 | Recent searches | shell, search screens | No store | NOT FOUND |
| R11 | Contrast | — | Device check | RUNTIME VERIFICATION REQUIRED |
| R12 | Semantics of icon buttons | 0 Semantics in `lib` | No semantics labels; TalkBack pass still needed | CONTRADICTED |
| R13 | Tablet orientation / Android 16 | `AndroidManifest.xml` | No lock; behavior unknown | RUNTIME VERIFICATION REQUIRED |
| R14 | Image decode size | `CrmNetworkImage`; library `Image.network` ×7 | Decode sizing on main widget, not library | PARTIALLY CONFIRMED |
| R15 | Per-screen offline copy | Isar collections vary | Device pass needed | RUNTIME VERIFICATION REQUIRED |
| R16 | Pending write queue | `OutboxLocal`, `SyncManager` | Properties/requirements queued; campaign outcomes not | PARTIALLY CONFIRMED |
| R17 | Messages dialog vs route | `top_bar.dart:935`, `TeamMessengerDialog.show` line 16 | Both go to `/messages` | CONFIRMED |
| R18 | IntegrationScreen push sites | repo-wide search | None | CONFIRMED |
| R19 | List views not named ListView | counts in §21 | 80 lazy builders, 175 `SingleChildScrollView`; per-screen review not done | PARTIALLY CONFIRMED |
| R20 | Empty-state copy inventory | 13 EmptyState widgets, 29 "No data/leads" strings | Counted, not read per branch | PARTIALLY CONFIRMED |
| R21 | Property sort keys | `properties_screen.dart` | Client-side `l2h`, `h2l` | CONFIRMED |
| R22 | Site visit status string | `requirements_screen.dart:1556, 2787`; `kpi.service.js` | `Site Visit` / `Site Visit Done` on requirements; `COMPLETED` on `site_visits` | PARTIALLY CONFIRMED |
| R23 | Sales "my leads" filter | backend requirements service | Server forces `salesUserId` | CONFIRMED |
| R24 | KPI-04 and KPI-06 tap targets | `kpi_drilldown_dialogs.dart` | KPI-04 → per-telecaller aggregate; KPI-06 → `site_visits` list | PARTIALLY CONFIRMED |
| R25 | Super-admin org switcher | `super_admin_metrics_screen.dart` | No UI; backend accepts `organization_id` | NOT FOUND |
| R26 | MFA code length | `mfa_verify_dialog.dart` | 6 digits, TOTP | CONFIRMED |
| R27 | In-app call timer | queue, callbacks, repository | None | NOT FOUND |
| R28 | Gallery double-tap zoom | viewer | Not traced | RUNTIME VERIFICATION REQUIRED |
| R29 | Debounce duration | shell, campaign, requirements | 500 / 250 / 200 / 150ms | CONTRADICTED |
| R30 | Campaign 1000 limit on phone | `integration_service.dart` | Client requests 5000 | CONTRADICTED |
| R31 | MOB-009 telecaller on `/dashboard` | router + `DashboardScreen` | Renders telecaller dashboard; no redirect to queue | CONFIRMED |

Register totals: CONFIRMED 10 · PARTIALLY CONFIRMED 7 · CONTRADICTED 4 · NOT FOUND 4 · RUNTIME VERIFICATION REQUIRED 6 · total 31.

---

## 3. Role navigation verification

| Role | Step 2 tabs | Current entry points | Current home | Gap |
|---|---|---|---|---|
| Telecaller | Queue, Callbacks, CNR, Leads, More | Sidebar: Dashboard, Properties, My Calling Leads (`/campaign/leads`), Callbacks, CNR / Retry, All Leads (Track), Library, Settings, Recycle Bin; bottom bar Dashboard/Properties/Leads/Profile | `/dashboard` → `TelecallerDashboardScreen` | Home differs (V-07); Properties present (V-13); shift gate absent from spec (V-58) |
| Sales | Leads, Properties, Visits, More | Sidebar: Dashboard, Properties, Leads, Library, Settings, Recycle Bin | `/dashboard` → `SalesDashboardScreen` | Visits source undecided (V-15); home undecided (V-16) |
| Admin | Home, Leads, Properties, Reports, More | Sidebar adds Employees, Reports, Campaign tree, Lead Allocation | `/dashboard` | Matches |
| Super Admin | Same as Admin | Adds Audit Logs | `/dashboard` | Matches |

Messages is not in `ModernSidebar`; it is reached from the top bar. Clients/Owners/Builders are not in navigation and their routes redirect to `/dashboard`.

---

## 4. 700px breakpoint and competing breakpoints

| Source | Value | Meaning today |
|---|---|---|
| Step 2 §5 | 700 | Phone shell below, desktop at and above |
| `app_shell.dart` | <768 mobile, 768–1024 tablet (sidebar shown), ≥1024 desktop | Actual shell switch |
| `CRMBreakpoints` / `app_breakpoints.dart` | phone 360, phablet 480, tablet 768, desktop 1024, wide 1280, ultrawide 1536 | Token set |
| `app_constants.dart` | mobileMax 600, tabletMax 1024 | Second token set |
| Screen code | 700 ×31, 600 ×48, 900 ×13, 768 ×11, 1024 ×8, plus 360, 420, 480, 500, 520, 560, 640, 650, 680, 720, 800, 950, 1000, 1050, 1100, 1200 | Local layout switches |
| `dashboard_screen.dart` | KPI grid 4 cols ≥1050, 3 ≥700, 2 ≥360; also 1100, 680, 640, 600 | Dashboard only |
| `telecaller_dashboard_screen.dart` | `isPhone < 700`, `isWide ≥ 1050`; KPI cols 1 (<340), 2 (<900) | Telecaller home |

Between 700 and 767px the current shell is "mobile" (drawer + bottom bar) while Step 2 says desktop. This band is the P0 conflict.

---

## 5. Route reconciliation

| Route | Mounted widget | Guard / redirect | Step 2 use | Label |
|---|---|---|---|---|
| `/dashboard` | `DashboardScreen` (role branch) | none | Admin Home | — |
| `/properties`, `/properties/:id` | `PropertiesScreen`, detail outside shell | none | Properties tab, detail | — |
| `/requirements` | `RequirementsScreen` | none | Leads tab | — |
| `/campaign` | — | → `/campaign/connections` | More → Campaign | ROUTE EXISTS — REDIRECTED |
| `/campaign/leads` | `CampaignLeadsScreen` | none | Telecaller Queue | — |
| `/integration`, `/campaign-leads` | — | → `/campaign/leads` | deprecated | ROUTE EXISTS — REDIRECTED |
| `/telecaller/leads` | `CampaignLeadsScreen(initialView, initialSearch)` | none | not used | — |
| `/telecaller/callbacks` | `TelecallerCallbacksScreen` | none | Callbacks tab | — |
| `/telecaller/cnr` | `TelecallerCnrScreen` | none | CNR tab | — |
| `/admin/lead-allocation` | allocation screen | non-Admin/SA → `/telecaller/leads` | More → Allocation | ROUTE EXISTS — REDIRECTED (for others) |
| `/users` | employees | RoleGuard | More → Employees | — |
| `/reports`, `/reports/leads` | — | → `/reports/leads/overall-business-insight` | Reports tab | ROUTE EXISTS — REDIRECTED |
| `/reports/leads/sales` | `SalesReportPlaceholderScreen` | RoleGuard | empty state | — |
| `/reports/properties` | `PropertiesComingSoonScreen` | RoleGuard | empty state | — |
| `/settings/audit-logs` | audit logs | RoleGuard (SA) | More → Audit | — |
| `/messages` | team messages screen | none | More → Messages | — |
| `/search` | `PropertySearchScreen` (outside shell) | none | MobileSearch | — |
| `/clients`, `/owners`, `/builders` | — | → `/dashboard` | product decision | ROUTE EXISTS — REDIRECTED |
| `/share/...` | public share | outside shell | Public share | — |
| `/more` | — | — | More | NOT FOUND |
| unknown | error page | shows `state.error.toString()` | MOB-007 | — |

---

## 6. Telecaller flow

| Action | UI Label | Backend Status | DB Field | API | Resulting Queue | Confirmed? |
|---|---|---|---|---|---|---|
| Dial from queue | Call | none recorded | — | none (`_launchTel` → `tel:`) | stays in queue | Yes |
| Dial from callbacks | Call | STARTED / IN_CALL | `lead_call_attempts` | POST `/telecaller/leads/:id/start-call` | stays on Callbacks | Yes (static) |
| CNR | CNR | allocation CNR, call_disposition CNR, attempts +1 | `leads.allocation_status`, `leads.call_disposition`, `lead_call_attempts`; pending `campaign_lead_callbacks` completed | POST `/integrations/leads/:id/transfer` (status CNR) | leaves queue → CNR | Yes |
| Callback | Callback | CALLBACK (optimistic) | `campaign_lead_callbacks.scheduled_at` / `raw_json._callback` | POST `/integrations/leads/:id/followups` (status Callback, outcome CALLBACK) | leaves queue → Callbacks | Yes |
| Follow up | Follow up | FOLLOWUP | `campaign_lead_followups`, `followups`; `leads.allocation_status` FOLLOWUP | POST `/integrations/leads/:id/followups` (status Follow up, outcome FOLLOWUP) | stays in queue | Yes |
| Picked Up | Picked Up | HANDED_TO_SALES / Assigned | `integration_leads` assignment; `raw_json._transfer` | POST `/integrations/leads/:id/transfer` (sales user + mandatory remarks) | leaves queue (assigned) | Yes |
| Interested | Interested | stage INTERESTED, call_disposition CONTACTED | `leads.stage` | PATCH `/integrations/leads/:id/campaign-status` | stays unless imported | Yes |
| Not interested | Not interested | stage LOST, NOT_INTERESTED, allocation RELEASED | `leads.rejection_reason` | PATCH `/integrations/leads/:id/campaign-status` (reason) | leaves → Not interested archive | Yes |
| Reset to New | New | NEW, NOT_ATTEMPTED, UNASSIGNED_WAITING | `leads.stage` | PATCH campaign-status | back in queue | Yes |
| Edit attempt remark | Remarks | — | `lead_call_attempts` | PATCH `/telecaller/attempts/:id/remarks` | — | Yes |
| Record outcome (legacy) | — | — | — | POST `/leads/:id/outcome` via `TelecallerRepository.recordOutcome` | — | Known broken path; must not be used |

---

## 7. Callback vs follow-up vs CNR

| Aspect | Callback | Follow-up | CNR |
|---|---|---|---|
| Storage | `campaign_lead_callbacks` (fallback: `integration_leads` allocation CALLBACK / campaign_status Callback, `next_retry_at`, `raw_json._callback.scheduled_at`) | `campaign_lead_followups` + `followups` | status filter on `allocation_status` / `call_disposition` / `campaign_status` |
| In calling queue | No (`_leftCallingQueue` true) | Yes | No |
| Own screen | `/telecaller/callbacks` | Telecaller dashboard "My Scheduled Follow-ups"; requirements Follow-ups tab | `/telecaller/cnr` |
| Due rule | scheduled day before today, device local time (`_isOverdue`) | — | — |
| Server list merge | merged with local `local_` items in `TelecallerListBloc` | — | merged with local items |
| Realtime | not watched | `campaign_lead_followups` watched | via `integration_leads` / `leads` |

Step 2's separation of the three queues is CONFIRMED.

---

## 8. Status enums

| UI Status | Flutter Enum / String | Backend Value | DB Value | Existing? |
|---|---|---|---|---|
| New | `'New'` campaign status | UNASSIGNED_WAITING | `leads.stage` NEW | Yes |
| CNR | `'CNR'` | CNR | allocation_status / call_disposition CNR | Yes |
| Callback | `'Callback'` | CALLBACK | allocation_status CALLBACK | Yes |
| Follow up | `'Follow up'` / `'Follow-up'` | FOLLOWUP | allocation_status FOLLOWUP | Yes |
| Picked Up | `'Picked Up'` | PICKED_UP / HANDED_TO_SALES | allocation_status | Yes |
| In call | — | IN_CALL | allocation_status | Backend only |
| Interested | `'Interested'` | — | stage INTERESTED | Yes |
| Not interested | `'Not interested'` | RELEASED | stage LOST, rejection_reason NOT_INTERESTED | Yes |
| Availability | ACTIVE / INACTIVE / BREAK | same | telecaller availability | Yes |
| Requirement: New, Assigned, Not Started, Call Attempted, Follow-up, Re-Followup, Interested | `requirements_screen.dart` dropdown | same strings | `requirements.status` | Yes |
| Site Visit (label "Site Visit Sche.") | `'Site Visit'` | — | `requirements.status` | Yes |
| Site Visit Done | `'Site Visit Done'` | also `SITE_VISIT_DONE` in sales lifecycle | `requirements.status`; separately `site_visits.status='COMPLETED'` | Yes (two meanings) |
| Negotiation | `'Negotiation'` | — | `requirements.status` | Yes |
| Won | `'Won'` | also `WON`, `Deal Won` in lifecycle | `requirements.status='Won'` | Yes |
| Lost | — | — | — | No — "Rejected…" prefix instead |

---

## 9. Property form fields (`add_edit_property_screen.dart`)

| Step | Field | Required |
|---|---|---|
| 1 Basic | title ("Location / Property Name") | Yes |
| 1 Basic | description, category_id, property_type_id, configuration_id, listing_type_id, property_status_id | per form |
| 1 Basic | images, videos (30 / 5 default) | No |
| 2 Location | city_id, area_id (new area needs 6-digit pincode), address, landmark, block_wing, flat_no, google_place_id, formatted_address, locality, city, state, country, postal_code, lat/lng | area per form |
| 3 Pricing | brokerage_type_id, super_builtup_area, carpet_area, plot_area (conditional), price, deposit, maintenance, furnishing, facing, ownership, bedrooms, bathrooms, balconies, parking, floor_no / total_floor (null for bungalow), age_of_property, possession_date (required when "To Be Available") | conditional |
| 4 Contacts | owner_name, owner_mobile, broker_name, remarks | per form |
| other | amenities, additional_details, is_verified | No |

Edit mode shows Back, Next, "Save Changes". Writes go through `PropertiesRepository` with `OutboxLocal`.

## 10. Lead (requirement) form fields (`add_edit_requirement_screen.dart`)

| Field | Required | Note |
|---|---|---|
| client name | Yes | — |
| mobile | Yes | duplicate check on local Isar, AlertDialog |
| listing type | Yes | — |
| category, property type(s) | Yes | multi `property_type_ids` |
| configuration_ids | No | — |
| target area_ids | Yes | "All Areas" option |
| budget | Yes | single text field; single value → min ×0.8, max ×1.2 client-side |
| min/max area, furnishings, facings, remarks | No | — |
| leadSource, referralName | referralName if Referral | — |
| status | — | — |
| alternate phone, email, city, timeline | — | NOT FOUND |

7 steps; validation via SnackBar and jump to step; drafts via `CRMDraftRepository`.

---

## 11. KPI table

| KPI | Live label | Count field / source | Tap target | Live? |
|---|---|---|---|---|
| KPI-01 | Available Inventory | `available_inventory` | `showInventoryDrilldown` (Available, To Be Available, Rented Out, Sold Out) | Yes |
| KPI-02 | Total Leads | `total_leads` | `showLeadsDrilldown` → `/dashboard/leads-list` | Yes |
| KPI-03 | Telecallers | `telecallers` | `showTelecallersDrilldown` | Yes |
| KPI-04a | New Leads Allocated | `leads_allocated` (fallback `new_leads_allocated`) | `showLeadsAllocatedDrilldown` | Yes |
| KPI-04b | Old Leads Allocated | `old_leads_allocated` | same dialog, same params | Yes |
| KPI-05 | Assigned to Sales | `assigned_to_sales` | `showAssignedToSalesDrilldown` | Yes |
| KPI-06 | Site Visits Done | `site_visits_done` | `showSiteVisitsDrilldown` | Yes |
| KPI-07 | Deal Won | `deal_won` | `showDealWonDrilldown` | Yes |
| KPI-08 | Sales Users | `sales_users` | `showSalesUsersDrilldown` | Yes |
| KPI-09 | Active Requirements | `_buildInventoryOverview` | — | No (dead) |
| KPI-10 | Deals Won | `summary.rentalWonRequirements` (never returned) | — | No (dead) |
| Telecaller | My assigned leads, Uncontacted, Callbacks, Today's callbacks, CNR / Retries, Picked up, Handed to Sales, Not Interested, Workload, Remaining Capacity | `/telecaller/dashboard` | routes to `/telecaller/leads`, `/telecaller/callbacks`, `/telecaller/cnr`, `/campaign/leads?view=not_interested` | Yes |

All admin dashboard routes require `dashboard.read` (PUT `/kpi-config` also uses `dashboard.read`). Filters: businessType, dateFilter, startDate, endDate, leadType. Drilldown lists default limit 25.

### KPI-04 trace
`DashboardScreen._buildModernKpiCards` → `StatCard` "New Leads Allocated" / "Old Leads Allocated" → `showLeadsAllocatedDrilldown(KpiFilterParams)` → `DashboardService.getLeadsAllocatedBreakdown` → GET `/dashboard/leads-allocated-breakdown` → per-telecaller rows with new and old counts. Both cards open the identical dialog; the dialog is an aggregate, not a lead list.

### KPI-06 trace
Count: `kpi.service.js` `site_visits sv WHERE sv.status='COMPLETED'`, date via `COALESCE(completed_at, visit_date, updated_at)`, org filter `org = X OR NULL`. Tap: `showSiteVisitsDrilldown` → `getSiteVisitsList` → GET `/dashboard/site-visits-list` over the same table (count and list agree). Search builds `ILIKE ${params.length}` without `$` at `kpi.service.js:1444`, so search in this drilldown is expected to fail (RUNTIME VERIFICATION REQUIRED; do not fix in Step 3 UI work). `SiteVisitItem` default status "Site Visit Done". A Sales tab built on requirement status `Site Visit Done` would not match KPI-06.

---

## 12. Reports

| Screen | Route | Backend | Permission | Phone note |
|---|---|---|---|---|
| Overall business insight | `/reports/leads/overall-business-insight` | `/reports/business-insight`, `/business-insight/leads` (limit 500 + offset) | UI `canViewReports`; API `authenticate` + role scoping | Fallback status counts in `report_data_engine.dart` when `lpk` missing |
| Telecaller report | under reports shell | `/reports/telecallers` | same | — |
| Sales report | `/reports/leads/sales` | `/reports/sales` exists | same | placeholder screen |
| Campaign report | — | `/reports/campaigns` | same | — |
| Property reports | `/reports/properties` | — | same | coming-soon screen |
| Super-admin metrics | — | `filters.organization_id` | SA | no org UI |

`ReportsBloc` is provided by a nested ShellRoute.

## 13. Search, filters, sort, pagination

| Surface | Implementation | Debounce | Server or client | Pagination |
|---|---|---|---|---|
| Shell global search | `_performSearch` fuzzy over Isar properties, requirements, owners, builders, clients, calling leads | 500ms | client | none |
| `/search` | `PropertySearchScreen` | per screen | client | — |
| Campaign queue | `campaign_leads_screen.dart` | 250ms main, 150ms follow-ups, 250ms not-interested | client over ≤5000 fetched | none in UI |
| Requirements tabs | `requirements_screen.dart` | 200ms | client (Isar local-first) | API supports page/limit ≤200, unused by list |
| Properties | `properties_service` GET `/properties` | — | server params + client sort `l2h`/`h2l` | API supports page/limit ≤200 |
| Callbacks / CNR | `TelecallerRepository.callbacks/cnr` (search, from, to, source, telecallerId) | — | server | — |
| Dashboard drilldowns | `DashboardService` | — | server | page/limit 25 |
| Backend `/api/v1/search` | `search.read` | — | — | Unused by Flutter |

---

## 14. Offline, realtime, media, messages, MFA, calling

| Area | Evidence | Finding | Status |
|---|---|---|---|
| Offline cache | `isar_collections.dart`: LookupItemLocal, PropertyLocal, RequirementLocal, FollowupLocal, BuilderLocal, OwnerLocal, ClientLocal, OutboxLocal, DashboardLocal, CampaignLeadLocal | Broad read cache | PARTIALLY CONFIRMED |
| Outbox | `OutboxLocal` (endpoint, method, payloadJson, createdAt, deviceId); `SyncManager` replays, server-wins on conflict | Properties/requirements | PARTIALLY CONFIRMED |
| Campaign outcomes offline | direct API; optimistic write, no rollback on PATCH failure | No queue | CONFIRMED (gap) |
| Realtime | Phoenix WS topic `realtime:propkart`; handler accepts `realtime:public`; tables: properties, requirements, notifications, followups, site_visits, integration_leads, leads, campaign_connections, campaign_lead_followups | Possibly inert; callbacks not watched | RUNTIME VERIFICATION REQUIRED |
| Sheet polling | `watchCampaignUi` 60s | Exists | CONFIRMED |
| Media | `CrmNetworkImage` decode sizing; limits 30/5; backend 10 MB / 100 MB | — | PARTIALLY CONFIRMED |
| Messages | `/messages`; screen polls 4s and 15s; dialog (3.5s) never built | Route authoritative | CONFIRMED |
| MFA | dialog, 6-digit TOTP, QR + manual key on setup, `MfaSubmitted`, no resend | — | CONFIRMED |
| Calling | Manifest `<queries>` DIAL+tel, VIEW http/https, smsto, mailto; `tel:` via url_launcher; WhatsApp `wa.me` with `91` prefix; no `AppLifecycleState` in call flow | VIEW+tel resolution unproven | RUNTIME VERIFICATION REQUIRED |
| Idle auto-break during external call | 5-min Dart Timer in `TelecallerShiftManager`; pointer activity only | May fire while dialer is foreground | RUNTIME VERIFICATION REQUIRED |

---

## 15. RBAC

Permission source: `PermissionMatrixService` defaults (Super Admin always true), synced from backend; route guards in `app_router.dart` via `RoleGuard`.

| Feature | Telecaller | Sales | Admin | Super Admin | Permission Source |
|---|---|---|---|---|---|
| Dashboard | Y (telecaller view) | Y (sales view) | Y | Y | `dashboard`; API `dashboard.read` |
| Properties | Y | Y | Y | Y | `properties` |
| Leads (requirements) | Y | Y | Y | Y | `leads`; API `requirements.read` |
| Calling queue | Y | N | Y | Y | `telecaller_leads` / `campaign`; API `campaign.manage` or `telecaller.leads/calls` |
| Callbacks | Y | N | N (page) | Y | `callbacks`; API `telecaller.callbacks` or `allocation.monitor` or `campaign.manage` |
| CNR | Y | N | N (page) | Y | `cnr`; API `telecaller.cnr` or monitor/manage |
| Campaign tree | hidden (page true) | N | Y | Y | `campaign`; sidebar `!isTelecaller` |
| Lead allocation | N (redirect) | N (redirect) | Y | Y | `lead_allocation`; router role check |
| Employees | N | N | Y | Y | `employees`; `canManageEmployees` |
| Reports | N | N | Y | Y | `reports`; `canViewReports`; API authenticate only |
| Library | Y | Y | Y | Y | `library` |
| Recycle bin | Y | Y | Y | Y | `recycle_bin` |
| Messages | Y | Y | Y | Y | `messages` |
| Settings | Y | Y | Y | Y | `settings` |
| Sync diagnostics | N | N | Y | Y | `isAdminOrSuperAdmin` in settings |
| Audit logs | N | N | N | Y | `audit_logs`; `canViewAuditLogs` |
| Availability / shift | Y | N | N | N | telecaller role; API `telecaller.availability` |

---

## 16. Dead and duplicate screens

| Item | Evidence | Label |
|---|---|---|
| IntegrationScreen | no constructor callers; route redirects | IMPLEMENTED BUT UNREACHABLE |
| LeadMetricsPlaceholderScreen | no references | IMPLEMENTED BUT UNREACHABLE |
| HomeScreen | no callers | IMPLEMENTED BUT UNREACHABLE |
| CRMPlaceholderScreen | no callers | IMPLEMENTED BUT UNREACHABLE |
| ClientsScreen, OwnersScreen, BuildersScreen (+ AddEdit screens) | routes redirect; add/edit only from dead lists | ROUTE EXISTS — REDIRECTED |
| PipelineScreen | no callers | IMPLEMENTED BUT UNREACHABLE |
| TeamMessengerDialog | `.show` routes to `/messages`; widget never built | IMPLEMENTED BUT UNREACHABLE |
| TelecallerLeadsScreen | not routed | IMPLEMENTED BUT UNREACHABLE |
| `_buildSidebarContent` | no callers | IMPLEMENTED BUT UNREACHABLE |
| `_buildDeskMetrics`, `_buildInventoryOverview` | no callers; mislabeled property counts as "Site visits done" | IMPLEMENTED BUT UNREACHABLE |
| `CampaignLeadsScreen` on two routes | `/campaign/leads`, `/telecaller/leads` | duplicate route |
| SyncDebugScreen | pushed from `settings_screen.dart:307` | reachable |

---

## 17. Tables, dialogs, SnackBars, accessibility

| Pattern | Count in `lib` | Note |
|---|---|---|
| `DataTable(` / `CRMDataTable(` / `PaginatedDataTable` | 32 / 12 / 0 | Telecaller and sales dashboards use DataTable for transferred/added leads |
| `showDialog` / `AlertDialog` | 181 / 118 | — |
| `showModalBottomSheet` | 16 | — |
| `PopupMenuButton` | 30 | — |
| `SnackBar(` / `showSnackBar(` / `AppStatusSnackBar.show` | 680 / 353 / 14 | No single SnackBar helper in use |
| SnackBars with raw `$e` | ~45 | e.g. `mfa_security_card.dart:184`, `integration_screen.dart:999/1621/1856`, `backup_management_card.dart:107/141`, `settings_screen.dart:788/1888`, `campaign_leads_screen.dart:4936` |
| `e.toString()` | 198 | — |
| `IconButton` / `tooltip:` / Semantics | 330 / 188 / 0 | — |
| `CRMKPICard(` / `StatCard(` | 42 / 16 | — |
| EmptyState widgets / "No data" strings | 13 / 29 | — |

## 18. Responsive conflicts

| Conflict | Where | Effect | Severity |
|---|---|---|---|
| Shell 768 vs spec 700 | `app_shell.dart` | 700–767 band disagrees | P0 |
| Two token sets (768 vs 600) | `app_breakpoints.dart`, `app_constants.dart` | Screens pick either | P1 |
| Screen-level 700 checks | 31 sites incl. telecaller dashboard | Different from shell switch | P1 |
| Dashboard grid 1050/700/360 | `dashboard_screen.dart` | 3 columns at 700–1049 inside "mobile" shell up to 767 | P2 |
| Width checks 1100/420/360 in shell | `app_shell.dart` | Local tweaks | P3 |
| `mobileNavClearance` 76 + safe area | `CRMBreakpoints` | Must match new bar height | P2 |

## 19. Performance risks

| Risk | Evidence | Severity |
|---|---|---|
| 5000-row campaign fetch on phone | `integration_service.dart` | P1 |
| Very large single widgets | campaign 12,795; requirements 13,764; properties 6,876; app_shell 4,173; dashboard 4,016 lines | P1 |
| Full Isar sync then client filter | requirements, properties repositories | P2 |
| Blocking sync overlay | `app_shell.dart` | P2 |
| Polling: notifications 25s, messages 4s/15s, sheets 60s, heartbeat 30s | shell, messages, integration service, shift manager | P2 |
| Non-lazy scroll views | 175 `SingleChildScrollView` | P2 |
| Raw `Image.network` | 7 in library screens | P3 |

---

## 20. Database / API truth

| Concept | Table / field | API | Note |
|---|---|---|---|
| Calling lead | `integration_leads` (+ `raw_json`), mirrored to `leads` (allocation_status, call_disposition, stage) | GET `/integrations/leads` (default 200, `count:'exact'`) | Telecaller scoped by `integrationLeadIdsForTelecaller` |
| Campaign status | `integration_leads.campaign_status` → `leads` sync | PATCH `/integrations/leads/:id/campaign-status` | see §6 |
| Callback | `campaign_lead_callbacks.scheduled_at` | GET `/telecaller/callbacks` | fallback to `integration_leads` |
| Follow-up | `campaign_lead_followups`, `followups` | POST `/integrations/leads/:id/followups`, GET `/followups` | — |
| Call attempt | `lead_call_attempts` | start-call, remarks PATCH | — |
| Site visit | `site_visits.status` COMPLETED | `/dashboard/site-visits-list` | differs from requirement status |
| Deal won | `requirements.status='Won'`, `deleted_at IS NULL` | `/dashboard/deal-won-list` | — |
| Availability | ACTIVE / BREAK / INACTIVE, heartbeat TTL 60s, DEFAULT_CAPACITY 10 | POST `/telecaller/availability`, `/telecaller/heartbeat` | — |
| Allocation statuses | UNASSIGNED_WAITING, ASSIGNED_TO_TELECALLER, IN_CALL, CNR, CALLBACK, FOLLOWUP, PICKED_UP, HANDED_TO_SALES, LEGACY_UNALLOCATED | `allocation.constants.js` | — |
| Requirements | `requirements` | GET `/requirements` (≤200 when paged; unbounded without page) | Sales forced `salesUserId` |
| Properties | `properties` | GET `/properties` (≤200) | — |

---

## 21. Step 2 contradictions

**C-01 (P0) — Shell breakpoint.**
STEP 2: Phone shell below 700px; desktop at 700+ (§5, §39).
CODE: `app_shell.dart` `isMobile = width < 768`; `CRMBreakpoints.tablet = 768`; `app_constants.dart` mobileMax 600.
CONFLICT: 700–767px is "desktop" in Step 2 and "mobile" in code.
RECOMMENDATION: Choose one shell breakpoint (700, 768, or another) and record it before M0.

**C-02 (P0) — Telecaller shift system.**
STEP 2: Availability/break is not a screen; do not invent a shift system (§18).
CODE: `TelecallerShiftManager`, `TelecallerShiftGateOverlay` (break, 9-hour lockout, inactive gate), `TelecallerAvailabilityToggle` (`top_bar.dart:843`), POST `/telecaller/availability`.
CONFLICT: A blocking shift system exists and wraps the telecaller shell.
RECOMMENDATION: Treat the gate and toggle as existing behavior the phone shell must host; confirm idle auto-break behavior during external calls at runtime.

**C-03 (P1) — Screen-level breakpoints.**
STEP 2: No screen may add its own breakpoint (§39).
CODE: 700 ×31, 600 ×48, 900 ×13 and others.
CONFLICT: Local breakpoints are pervasive.
RECOMMENDATION: Apply the rule to new phone widgets only; migrate existing screens when touched.

**C-04 (P1) — Telecaller home.**
STEP 2: Home after login is Queue (§11).
CODE: Router redirects every role to `/dashboard`; telecaller sees `TelecallerDashboardScreen`.
CONFLICT: Different home.
RECOMMENDATION: Product confirms Queue vs telecaller dashboard; if Queue, the redirect is an implementation dependency.

**C-05 (P1) — KPI-04 card count.**
STEP 2: One "Leads Allocated" card (§15).
CODE: "New Leads Allocated" and "Old Leads Allocated" from `/dashboard/kpis` config.
CONFLICT: Two cards, same drilldown.
RECOMMENDATION: Product chooses one combined card or two cards.

**C-06 (P1) — KPI-10 equivalence.**
STEP 2: KPI-10 is the same metric as Deal Won (§28).
CODE: "Deals Won" reads `rentalWonRequirements`, which the backend never returns; only in dead code.
CONFLICT: Not the same metric; not live.
RECOMMENDATION: Describe KPI-10 as dead code, not as an alias.

**C-07 (P1) — KPI-09.**
STEP 2: Active Requirements row under the admin grid (§28).
CODE: Only in `_buildInventoryOverview` (no callers); not in KPI config.
CONFLICT: No live source.
RECOMMENDATION: Remove from phone home or identify an existing API field first.

**C-08 (P1) — KPI-06 tap target.**
STEP 2: Lead list with visit filter (§28).
CODE: Drilldown lists `site_visits` COMPLETED; search placeholder bug at `kpi.service.js:1444`.
CONFLICT: Visit records, not leads.
RECOMMENDATION: Phone drilldown lists visit records from the same endpoint.

**C-09 (P1) — Property wizard order.**
STEP 2: Basics, Location, Media, Details (§16).
CODE: Basic (with media), Location, Pricing, Contacts.
CONFLICT: Different steps.
RECOMMENDATION: Keep the current four steps unless product approves a regroup.

**C-10 (P1) — Lead wizard.**
STEP 2: 3 steps (§17).
CODE: 7 steps.
CONFLICT: Step count.
RECOMMENDATION: Keep 7 steps or get product approval for regrouping without changing fields.

**C-11 (P1) — Lead fields.**
STEP 2: alternate phone, email, city, budget min/max (§17).
CODE: none of these; single budget field parsed to a range.
CONFLICT: Invented fields.
RECOMMENDATION: Use the field table in §10 of this document.

**C-12 (P1) — Picked Up.**
STEP 2: Confirm, nothing required (§17).
CODE: `_showTransferDialog` requires a sales user and mandatory remarks; transfers lead.
CONFLICT: Picked Up is a hand-off.
RECOMMENDATION: Picked Up sheet carries sales user and remarks.

**C-13 (P1) — Campaign limit.**
STEP 2: 1000 rows (§38, R30).
CODE: `limit: 5000`; backend default 200; PostgREST cap possible.
CONFLICT: Value.
RECOMMENDATION: Log actual returned rows on device before planning phone paging.

**C-14 (P2) — Session expiry.**
STEP 2: Blocking dialog (§30, §34).
CODE: Redirect to `/get-started?from=`.
CONFLICT: Pattern.
RECOMMENDATION: Product chooses dialog or redirect.

**C-15 (P2) — Not-found page.**
STEP 2: No raw error (MOB-007).
CODE: `state.error.toString()`.
CONFLICT: Raw text.
RECOMMENDATION: Replace copy only.

**C-16 (P2) — Lost.**
STEP 2: "Lost" transition (§17).
CODE: "Rejected…" statuses.
CONFLICT: Name.
RECOMMENDATION: Use existing Rejected labels.

**C-17 (P2) — Debounce.**
STEP 2: 300ms (§32).
CODE: 500 / 250 / 200 / 150ms.
CONFLICT: Value.
RECOMMENDATION: Keep existing values per Step 2's own fallback, or product sets one.

**C-18 (P2) — Sync overlay.**
STEP 2: Non-blocking caption (§34).
CODE: Full-screen "Updating lookup lists...".
CONFLICT: Blocking.
RECOMMENDATION: Product approves non-blocking before change.

**C-19 (P2) — Error copy.**
STEP 2: Never show exceptions (§34).
CODE: ~45 SnackBars with `$e`; 198 `e.toString()`.
CONFLICT: Raw errors.
RECOMMENDATION: Map messages on screens touched in Step 3.

**C-20 (P2) — Semantics.**
STEP 2: Icon buttons have semantics labels (§35).
CODE: 0 Semantics.
CONFLICT: Absent.
RECOMMENDATION: Build labels into new phone components.

**C-21 (P2) — Forbidden deep links.**
STEP 2: Permission state page (§13, §45).
CODE: Redirects or no guard.
CONFLICT: Pattern.
RECOMMENDATION: Product chooses permission page vs redirect.

**C-22 (P3) — Bottom nav label size.**
STEP 2: 12px labels. CODE: 9px. CONFLICT: Size. RECOMMENDATION: Apply when the bar is rebuilt.

**C-23 (P3) — Sync debug visibility.**
STEP 2: SA only. CODE: Admin and SA (`settings_screen.dart:246`). CONFLICT: Audience. RECOMMENDATION: Product confirms.

**C-24 (P3) — Negotiation.**
STEP 2: Product decision if no status. CODE: Status exists. CONFLICT: Already resolved. RECOMMENDATION: Use existing status.

| ID | Topic | Severity |
|---|---|---|
| C-01 | Shell breakpoint | P0 |
| C-02 | Telecaller shift system | P0 |
| C-03 | Screen-level breakpoints | P1 |
| C-04 | Telecaller home | P1 |
| C-05 | KPI-04 card count | P1 |
| C-06 | KPI-10 equivalence | P1 |
| C-07 | KPI-09 | P1 |
| C-08 | KPI-06 tap | P1 |
| C-09 | Property wizard order | P1 |
| C-10 | Lead wizard steps | P1 |
| C-11 | Lead fields | P1 |
| C-12 | Picked Up | P1 |
| C-13 | Campaign limit | P1 |
| C-14 | Session expiry | P2 |
| C-15 | Not-found page | P2 |
| C-16 | Lost | P2 |
| C-17 | Debounce | P2 |
| C-18 | Sync overlay | P2 |
| C-19 | Error copy | P2 |
| C-20 | Semantics | P2 |
| C-21 | Forbidden deep links | P2 |
| C-22 | Bottom nav label size | P3 |
| C-23 | Sync debug visibility | P3 |
| C-24 | Negotiation | P3 |

---

## 22. Confirmed Step 2 decisions

- Telecaller tab routes `/campaign/leads`, `/telecaller/callbacks`, `/telecaller/cnr`, `/requirements` exist.
- Callbacks, follow-ups, and CNR are separate queues; follow-ups stay in the calling queue.
- Callback and CNR outcomes remove the lead from the calling queue; Not interested requires a reason.
- Won requires the existing property-selection dialog.
- Only "Deal Won" is live on the dashboard.
- Sales lead list is scoped server-side.
- `/messages` is the messaging destination; the messenger dialog is not used.
- `/search` mounts `PropertySearchScreen`.
- MFA uses a 6-digit TOTP code.
- No call timer and no recent-search store exist.
- Sales and property reports are placeholders.
- IntegrationScreen, LeadMetricsPlaceholderScreen, HomeScreen, CRMPlaceholderScreen, TelecallerLeadsScreen, PipelineScreen, `_buildSidebarContent` are unreachable.
- Audit logs are SA only; lead allocation is Admin/SA only.
- Property sort is client-side price ascending/descending.
- Upload limits and media pickers already exist.

## 23. Step 3 blockers

1. Shell breakpoint not agreed (C-01).
2. Shift gate, availability toggle, and idle auto-break must be part of the phone shell (C-02); idle timer during external calls needs runtime proof.
3. Telecaller and Sales home routes need a product decision and a router change (C-04, V-16).
4. Admin KPI set (KPI-04 two cards, KPI-09 and KPI-10 dead, KPI-06 source) needs a product decision (C-05 to C-08).
5. Picked Up, property wizard, and lead wizard must follow the real flows (C-09 to C-12).
6. Realtime delivery and campaign row limit need runtime verification before relying on push updates or planning phone paging (V-82, V-94).

## 24. Safe to implement in Step 3

- Phone component library (app bar, cards, sheets, empty/error states, skeletons) with semantics labels, as new widgets.
- More page as a new presentation route listing only existing routes the role can open.
- Card layouts over existing data for properties, requirements, callbacks, CNR, and campaign lists.
- Converting KPI drilldown dialogs to full-screen pages that call the same `DashboardService` methods.
- MFA as a page using the existing `MfaSubmitted` event.
- Replacing raw error text on screens touched in Step 3.
- Outcome sheets that call the same `IntegrationService` methods (`transferLead`, `scheduleFollowup`, `updateLeadCampaignStatus`) with the same required inputs.

## 25. Do not implement yet

- Any change to login/splash redirects until product confirms role homes.
- Removing or hiding the shift gate or availability toggle.
- Server-side pagination of campaign, requirements, or properties lists (changes data flow).
- "Waiting to sync" for campaign outcomes (no outbox).
- New fields in property or lead forms; regrouping wizard steps without approval.
- KPI-09, KPI-10, or a merged KPI-04 card without a product decision.
- Org switcher UI.
- A single global debounce value.
- Non-blocking sync overlay without approval.
- Any backend permission change (reports, telecaller transfer routes) or the `kpi.service.js:1444` search fix.
- Calling `POST /leads/:id/outcome` (`recordOutcome`).

---

## 26. Final reconciliation matrix

| # | Domain | Overall status | Key reference |
|---|---|---|---|
| 1 | Breakpoints | CONTRADICTED | V-01, V-02 |
| 2 | Shell and bottom nav | PARTIALLY CONFIRMED | V-03 to V-06 |
| 3 | Role navigation | PARTIALLY CONFIRMED | §3 |
| 4 | Login and role home | CONTRADICTED | V-07, V-16 |
| 5 | Routes and redirects | CONFIRMED | §5 |
| 6 | More menu | IMPLEMENTATION DEPENDENCY | V-12 |
| 7 | Telecaller queue | PARTIALLY CONFIRMED | V-53 to V-57 |
| 8 | Telecaller outcomes | PARTIALLY CONFIRMED | §6, V-49 |
| 9 | Callbacks / follow-ups / CNR | CONFIRMED | §7 |
| 10 | Shift / availability | CONTRADICTED | V-58 |
| 11 | Calling and dialer | RUNTIME VERIFICATION REQUIRED | V-55, §14 |
| 12 | Status enums | PARTIALLY CONFIRMED | §8 |
| 13 | Property form | CONTRADICTED | V-38, V-39 |
| 14 | Lead form | CONTRADICTED | V-43, V-44 |
| 15 | KPIs | CONTRADICTED | V-26 to V-33 |
| 16 | Reports | PARTIALLY CONFIRMED | §12 |
| 17 | Search | PARTIALLY CONFIRMED | V-70 to V-73 |
| 18 | Filters, sort, pagination | IMPLEMENTATION DEPENDENCY | V-40, V-83 |
| 19 | Offline and outbox | PARTIALLY CONFIRMED | V-75, V-93 |
| 20 | Realtime | RUNTIME VERIFICATION REQUIRED | V-94 |
| 21 | Media | PARTIALLY CONFIRMED | V-41, V-85 |
| 22 | Messages | CONFIRMED | V-68 |
| 23 | MFA / auth | PARTIALLY CONFIRMED | V-23 to V-25 |
| 24 | RBAC | PARTIALLY CONFIRMED | §15, V-91 |
| 25 | Dead / duplicate screens | CONFIRMED | §16 |
| 26 | Accessibility, errors, performance | CONTRADICTED | V-76, V-78, §19 |

---

## 27. Final numbers

Master table (§1), 95 rows:

| Status | Count |
|---|---|
| CONFIRMED | 30 |
| PARTIALLY CONFIRMED | 18 |
| CONTRADICTED | 24 |
| NOT FOUND | 4 |
| RUNTIME VERIFICATION REQUIRED | 9 |
| PRODUCT DECISION REQUIRED | 2 |
| IMPLEMENTATION DEPENDENCY | 8 |
| **Total** | **95** |

Risk on non-confirmed master rows: P0 2 · P1 25 · P2 24 · P3 11 (3 NOT FOUND rows carry no risk).

Step 2 contradictions (§21): 24 — P0 2 · P1 11 · P2 8 · P3 3.

Runtime register (§2): 31 — CONFIRMED 10 · PARTIALLY CONFIRMED 7 · CONTRADICTED 4 · NOT FOUND 4 · RUNTIME VERIFICATION REQUIRED 6.

**Code modified:** No.

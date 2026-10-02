# PropKart Mobile UI/UX — Final Specification (Step 2.6 Reconciliation and Decision Freeze)

**Status.** Implementation-ready specification for Step 3, subject to the gates in §29–§31.
**Inputs.** Step 1 `docs/PROPKART_MOBILE_UX_AUDIT.md`, Step 2 `docs/PROPKART_MOBILE_UI_UX_MASTER_SPECIFICATION.md`, Step 2.5 `docs/PROPKART_MOBILE_UI_UX_STEP_2_5_VERIFICATION.md` (authoritative technical verification).
**Companion.** `docs/PROPKART_MOBILE_UI_UX_DECISION_REGISTER.md` holds every decision ID used here.
**Code modified:** No. This phase changed no application code, route, backend, database, KPI, RBAC, status, sync, or existing document.

**Precedence.** Where this document and Step 2 disagree, this document wins. Where Step 2 is silent and Step 2.5 is silent, Step 2 visual rules (tokens, sizes, motion) still apply.

**Classification vocabulary.** SPECIFICATION CORRECTION · PRODUCT DECISION · RUNTIME VERIFICATION · STEP 3 IMPLEMENTATION · IMPLEMENTATION DEPENDENCY · FUTURE BACKLOG · NO ACTION.

---

## 1. Mobile implementation principle (frozen)

> PropKart mobile is a purpose-built mobile operating experience using the same verified business truth, APIs, permissions, database architecture, and lifecycle rules as the existing product.

Mobile presentation may change. Business truth may not change without explicit product/engineering approval.

---

## 2. Master contradiction reconciliation (C-01 to C-24)

| ID | Step 2 Position | Step 2.5 Finding | Final Decision | Classification | Step 3 Impact |
|---|---|---|---|---|---|
| C-01 | Phone shell <700px | Shell switches at 768 (`app_shell.dart`, `CRMBreakpoints.tablet`); second token set at 600 | Mobile shell <768. `CRMBreakpoints` is authoritative (§3, DR-001) | SPECIFICATION CORRECTION | New shell uses existing 768 boundary; no shell-switch change |
| C-02 | No availability/break system | Full shift system with blocking overlays exists | Existing shift system is part of the telecaller mobile shell (§4, DR-002) | SPECIFICATION CORRECTION | Mobile shell must host the existing overlay and toggle |
| C-03 | No screen-level breakpoints | 700 ×31, 600 ×48, 900 ×13, others | Rule applies to new mobile components only; legacy screens migrate when touched (§3) | SPECIFICATION CORRECTION | No codebase-wide refactor required |
| C-04 | Telecaller lands on Queue | All roles redirect to `/dashboard`; telecaller sees `TelecallerDashboardScreen` | Interim: keep existing landing. Queue vs dashboard needs product sign-off (PD-01) | PRODUCT DECISION | Router unchanged unless PD-01 chooses Queue |
| C-05 | One "Leads Allocated" card | Two live cards, New and Old, same drilldown | Interim: show both cards as configured by `/dashboard/kpis`; presentation choice is PD-04 | PRODUCT DECISION | Admin home renders whatever the KPI config enables |
| C-06 | KPI-10 Deals Won = Deal Won | Deals Won is dead code, reads a field the backend never returns | KPI-10 removed from mobile inventory; not an alias (DR-012) | SPECIFICATION CORRECTION | Do not render KPI-10 |
| C-07 | KPI-09 Active Requirements row | Dead code, no live source | KPI-09 removed from mobile inventory; future KPI needs a backend source (DR-011, FB-01) | SPECIFICATION CORRECTION | Do not render KPI-09 |
| C-08 | KPI-06 tap → lead list | Drilldown lists `site_visits` COMPLETED records | KPI-06 tap opens a visit-record list from `/dashboard/site-visits-list` (DR-010) | SPECIFICATION CORRECTION | Drilldown page over existing endpoint |
| C-09 | Property wizard Basics/Location/Media/Details | Basic (with media), Location, Pricing, Contacts | Keep actual four steps and fields (§12) | SPECIFICATION CORRECTION | Mobile wizard mirrors existing steps |
| C-10 | Lead wizard 3 steps | 7 steps | Keep 7 steps; visual compaction allowed, no field moves across business meaning (§13) | SPECIFICATION CORRECTION | Mobile wizard has 7 steps |
| C-11 | Alt phone, email, city, budget min/max | Not in form; single budget field | Those fields are not part of the mobile form (§13) | SPECIFICATION CORRECTION | No new fields |
| C-12 | Picked Up = confirm only | Requires sales user + mandatory remarks; transfers lead | Picked Up is a hand-off flow (§15) | SPECIFICATION CORRECTION | Picked Up sheet with user picker + remarks |
| C-13 | Campaign fetch 1000 | Client requests 5000; backend default 200; possible PostgREST cap | Preserve existing fetch in Step 3; measure actual rows (RV-02) before any change (§20) | RUNTIME VERIFICATION | No limit change in Step 3 |
| C-14 | Session expiry = blocking dialog | Redirect to `/get-started?from=` | Keep existing redirect (DR-015) | SPECIFICATION CORRECTION | No session dialog |
| C-15 | Not-found page without raw error | Shows `state.error.toString()` | Mobile not-found page shows friendly copy + role-home button | STEP 3 IMPLEMENTATION | Replace copy in the error page |
| C-16 | "Lost" transition | System uses "Rejected…" and "Not interested" | Mobile label is "Rejected" (requirements) / "Not interested" (calling) (§17) | SPECIFICATION CORRECTION | No "Lost" label |
| C-17 | Debounce 300ms | 500 / 250 / 200 / 150ms per surface | Keep each surface's existing debounce (DR-018) | SPECIFICATION CORRECTION | No debounce change |
| C-18 | Sync = non-blocking caption | Full-screen blocking "Updating lookup lists..." | Interim: keep blocking overlay; non-blocking needs product approval (PD-05) | PRODUCT DECISION | Mobile shell keeps overlay |
| C-19 | Never show exceptions | ~45 raw `$e` SnackBars, 198 `e.toString()` | Requirement retained; applied to screens touched in Step 3 | STEP 3 IMPLEMENTATION | Error mapping on touched screens |
| C-20 | Icon buttons have semantics | 0 Semantics | Requirement retained; built into new mobile components | STEP 3 IMPLEMENTATION | Semantics in new components |
| C-21 | Forbidden deep link → permission page | Router redirects; many routes unguarded | Keep existing redirects; `MobilePermissionState` only for API 403 inside a screen (DR-016) | SPECIFICATION CORRECTION | No router guard changes |
| C-22 | Bottom nav labels 12px | Current 9px | New `MobileBottomNav` uses 12px labels | STEP 3 IMPLEMENTATION | New component |
| C-23 | Sync debug SA only | Admin and SA (`settings_screen.dart:246`) | Admin and SA, matching code (DR-017) | SPECIFICATION CORRECTION | More row for Admin and SA |
| C-24 | Negotiation needs product decision | Negotiation status exists | Use existing Negotiation status | SPECIFICATION CORRECTION | Status sheet lists it |

Totals: SPECIFICATION CORRECTION 16 · PRODUCT DECISION 3 · RUNTIME VERIFICATION 1 · STEP 3 IMPLEMENTATION 4 · total 24.

---

## 3. Breakpoint architecture (P0, frozen — DR-001)

**Evaluation.** The existing shell already switches at 768 using `CRMBreakpoints` (`app_breakpoints.dart`: phone 360, phablet 480, tablet 768, desktop 1024, wide 1280, ultrawide 1536). `CRMBreakpoints.mobileNavClearance` and the bottom bar already live in this system. Adopting 700 would require changing the shell switch and would leave 700–767 inconsistent with the existing bottom bar. Adopting 600 (`app_constants.dart`) would push the sidebar onto many phones in landscape and phablets. 768 is the only value that matches the running shell without changing it.

```text
Phone/mobile shell:  width < 768 (CRMBreakpoints.tablet). New mobile shell, bottom nav, More page.
Tablet behavior:     768 ≤ width < 1024. Existing CRMAppShell with ModernSidebar, unchanged.
Desktop shell:       width ≥ 1024 (CRMBreakpoints.desktop). Existing shell, unchanged.
Wide desktop:        width ≥ 1280 (CRMBreakpoints.wide). Existing shell, unchanged.
Primary breakpoint:  768.
Token source:        CRMBreakpoints in lib/core/design_system (app_breakpoints.dart).
Legacy breakpoint handling: app_constants.dart mobileMax 600 / tabletMax 1024 and screen-level
                     literals (700, 600, 900, 1050, 1100, …) stay as-is in legacy screens.
```

**Authoritative constants for the new mobile shell:** `CRMBreakpoints.tablet` (768) as the shell boundary; `CRMBreakpoints.phone` (360) as the minimum design width; `CRMBreakpoints.phablet` (480) as the only allowed density step inside the phone shell; `CRMBreakpoints.mobileNavClearance` for bottom padding (must be updated in Step 3 to match the new bar height if it differs from 64 + safe area).

**Screen-specific exceptions (allowed in new mobile code):** gallery height 200 below 360 and 220 from 360; horizontal padding 12 below 360, 16 from 360.

**Legacy exceptions:** existing screens keep their literals until migrated. A legacy screen rendered inside the mobile shell at 700–767 may still show its own "wide" layout; this is accepted and logged as a migration item when the screen is touched.

**Migration rule:** any screen converted in Step 3 replaces local width literals with `CRMBreakpoints`. Untouched screens are FUTURE BACKLOG (FB-10).

**Step 2 band table correction:** Step 2 §5 bands "430–699 phone" and "700+ desktop" become "430–767 phone (content max width 560, centered)" and "768+ existing shell".

---

## 4. Telecaller shift system in the mobile shell (P0, frozen — DR-002)

Uses only existing behavior: `TelecallerShiftManager` (ACTIVE / INACTIVE / BREAK, 5-minute idle auto-break, 9-hour daily lockout by device-local date, 30s heartbeat), `TelecallerShiftGateOverlay`, `TelecallerAvailabilityToggle`, `TelecallerHeartbeatService`, POST `/telecaller/availability`, POST `/telecaller/heartbeat`.

| Aspect | Mobile specification |
|---|---|
| Availability toggle | `TelecallerAvailabilityToggle(compact: true)` in `MobileTopBar` trailing area for Telecaller only, as `top_bar.dart:843` does today. Not in the bottom nav. |
| ACTIVE | Normal workspace. Heartbeat runs. Pointer activity resets the idle timer. Queue, Callbacks, CNR usable. |
| BREAK (manual or 5-min idle) | Existing blur overlay with "Resume Active". Workspace is not interactive behind it. Resume sets ACTIVE via existing manager. |
| INACTIVE | Existing gate overlay with "Start Shift (Turn Active)". Workspace blocked until ACTIVE. |
| 9-hour lockout | Existing lockout overlay; no resume action. Ends at device-local date change as today. |
| Overlay behavior | The mobile shell is wrapped by `TelecallerShiftGateOverlay` in the same position it wraps `CRMAppShell` today, so overlays cover content and bottom nav. What else stays visible (e.g. top bar, logout) must match current behavior — RV-20. |
| More menu | A read-only "Shift" row at the top of More shows current availability label (Active / On break / Inactive) from `TelecallerShiftManager`. Tapping it opens no new screen; it uses the same toggle action. No new hours or history data. |
| Visible while gated | Only the overlay and its action. Do not add new controls to overlays. |
| Calling interaction | §16. Idle auto-break while the external dialer is foreground is RV-01. |

Step 3 must not change timers, states, endpoints, or lockout rules.

---

## 5. Role homes and final information architecture

### 5.1 Telecaller home (PD-01 — PRODUCT DECISION REQUIRED)

```text
Telecaller default landing: /dashboard → TelecallerDashboardScreen (existing, interim default)
Reason:                     Existing router behavior; the telecaller dashboard already exposes
                            queue, callbacks, CNR and capacity KPIs that route to the queues.
                            Queue-as-home is a product choice, not derivable from code.
Existing screen retained:   Yes, TelecallerDashboardScreen.
Queue access:               Bottom tab "Queue" → /campaign/leads (1 tap from landing).
Dashboard access:           Bottom tab "Home" → /dashboard.
Router change required:     None for the interim default. If PD-01 = Queue, the post-login
                            and splash redirect for Telecaller changes (SD-09).
```

### 5.2 Sales home (PD-02 — PRODUCT DECISION REQUIRED)

```text
Sales default landing: /dashboard → SalesDashboardScreen (existing, interim default)
Primary mobile tabs:   Home, Leads, Properties, More
Dashboard location:    Home tab (/dashboard). Not deleted. Team tables render as cards on phone.
Leads location:        Leads tab (/requirements), server-scoped to the user.
Properties location:   Properties tab (/properties).
Visits location:       No separate tab until PD-03. Interim: Leads tab status filter
                       "Site Visit" / "Site Visit Done" (existing requirement statuses).
More contents:         Profile, Library, Messages, Settings, Recycle bin.
```

### 5.3 Final role navigation (frozen except where a PD is noted)

**Telecaller** — tabs: Home (`/dashboard`), Queue (`/campaign/leads`), Callbacks (`/telecaller/callbacks`), CNR (`/telecaller/cnr`), More (`/more`).
More: Shift status row · Leads — "All Leads" (`/requirements`) · Properties (`/properties`, page key true by default, DR-007) · Library (`/library`) · Messages (`/messages`) · Settings (`/settings`) · Recycle bin (`/bin`) · Profile (`/profile`).
Shift control: top bar toggle (§4). No Campaign tree, no Allocation, no Reports, no Employees, no Audit.

**Sales** — tabs: Home, Leads, Properties, More (§5.2). More: Profile, Library, Messages, Settings, Recycle bin. No Callbacks, CNR, Queue, Campaign, Allocation, Reports, Employees, Audit.

**Admin** — tabs: Home (`/dashboard`), Leads (`/requirements`), Properties (`/properties`), Reports (`/reports/leads/overall-business-insight`), More.
More: Profile · Calling queue (`/campaign/leads`) · Campaign connections (`/campaign/connections`) · Lead allocation (`/admin/lead-allocation`) · Employees (`/users`) · Library · Messages · Settings · Sync diagnostics (settings push, DR-017) · Recycle bin.
Callbacks and CNR pages are hidden for Admin (page keys `callbacks`, `cnr` false by default).

**Super Admin** — same tabs as Admin. More adds: Callbacks, CNR (Super Admin always true), Audit logs (`/settings/audit-logs`), Super-admin metrics (existing screen; no org switcher, FB-02).

All More rows are shown only when `PermissionMatrixService.canViewRoute` allows the route for the signed-in user; the lists above are the default matrix.

---

## 6. Sales Visits data source (PD-03 — PRODUCT DECISION REQUIRED)

```text
Sales Visits tab source:     Not frozen. Interim: requirement status filter on /requirements.
KPI-06 source:               site_visits WHERE status='COMPLETED' (kpi.service.js), date
                             COALESCE(completed_at, visit_date, updated_at).
Requirement Site Visit status purpose: lead lifecycle stage on requirements.status
                             ("Site Visit" shown as "Site Visit Sche.", and "Site Visit Done").
site_visits purpose:         visit records with their own status and timestamps.
Relationship between them:   No verified link that keeps them in sync.
Known mismatch:              A requirement can be "Site Visit Done" without a COMPLETED
                             site_visits row and vice versa; counts may differ.
Step 3 behavior:             Do not label the requirement filter as KPI-06. Do not build a
                             Visits tab until PD-03 picks a source.
```

---

## 7. Final KPI master

Definitions stay server-side. Admin KPIs come from GET `/dashboard/kpis` (`dashboard.read`), filtered by the `/dashboard/kpi-config` enable list. Telecaller KPIs come from GET `/telecaller/dashboard` (`telecaller.leads`). Empty state: "—" only when the field is absent; show 0 when the API returns 0. Error state: card shows "Couldn't load" + Retry. Drilldowns are full-screen pages (§23) over the existing dialogs' service calls.

| ID | Name | Definition | Backend source | Database source | Role | Screen | Priority | Card type | Mobile visibility | Tap target | Drilldown |
|---|---|---|---|---|---|---|---|---|---|---|---|
| KPI-01 | Available Inventory | Properties available | `/dashboard/kpis` `available_inventory` | `properties` | AD SA | Admin Home | P2 | carousel | yes | Inventory page | `/dashboard/inventory-breakdown`, `/inventory-properties` (Available, To Be Available, Rented Out, Sold Out) |
| KPI-02 | Total Leads | Leads in range | `total_leads` | leads | AD SA | Admin Home | P0 | grid | above fold | Leads list page | `/dashboard/leads-list` (25/page) |
| KPI-03 | Telecallers | Telecaller users | `telecallers` | users | AD SA | Admin Home | P2 | carousel | yes | Telecallers page | `/dashboard/telecallers-summary`, `/telecaller-drilldown/:id`, `/telecaller-leads/:id` |
| KPI-04a | New Leads Allocated | New allocations | `leads_allocated` (fallback `new_leads_allocated`) | allocation data | AD SA | Admin Home | P0 | grid | above fold if enabled | Allocation breakdown page | `/dashboard/leads-allocated-breakdown` (per telecaller, new/old) |
| KPI-04b | Old Leads Allocated | Old allocations | `old_leads_allocated` | allocation data | AD SA | Admin Home | P0 | grid | above fold if enabled | Same page, same params | same |
| KPI-05 | Assigned to Sales | Leads handed to sales | `assigned_to_sales` | leads | AD SA | Admin Home | P2 | carousel | yes | Assigned-to-sales page | `/dashboard/assigned-to-sales-breakdown` |
| KPI-06 | Site Visits Done | Completed visit records | `site_visits_done` | `site_visits.status='COMPLETED'` | AD SA | Admin Home | P0 | grid | above fold | Visit records page | `/dashboard/site-visits-list` (search has known backend bug, RV-12) |
| KPI-07 | Deal Won | Won requirements | `deal_won` | `requirements.status='Won'`, not deleted | AD SA | Admin Home | P0 | grid | above fold | Deal won page | `/dashboard/deal-won-list` |
| KPI-08 | Sales Users | Sales users | `sales_users` | users | AD SA | Admin Home | P2 | carousel | yes | Sales users page | `/dashboard/sales-users-summary`, `/sales-user-drilldown/:id`, `/sales-user-requirements/:id` |
| TC-01 | My assigned leads | `assignedLeads` | `/telecaller/dashboard` | allocation | TC | TC Home | P0 | grid | yes | `/telecaller/leads` (same widget as Queue) | — |
| TC-02 | Uncontacted | `uncontacted` | same | allocation | TC | TC Home | P1 | grid | yes | `/telecaller/leads` | — |
| TC-03 | Callbacks | `callbackCount` | same | `campaign_lead_callbacks` | TC | TC Home | P0 | grid | yes | `/telecaller/callbacks` | — |
| TC-04 | Today's callbacks | `todaysCallbacks` | same | same | TC | TC Home | P0 | grid | yes | `/telecaller/callbacks` | — |
| TC-05 | CNR / Retries | `cnrCount` | same | allocation CNR | TC | TC Home | P0 | grid | yes | `/telecaller/cnr` | — |
| TC-06 | Picked up | `pickedUp` | same | allocation | TC | TC Home | P2 | list row | "More stats" | `/telecaller/leads` | — |
| TC-07 | Handed to Sales | `handedToSales` | same | allocation | TC | TC Home | P2 | list row | "More stats" | `/telecaller/leads` | — |
| TC-08 | Not Interested | `notInterestedCount` | same | campaign status | TC | TC Home | P2 | list row | "More stats" | `/campaign/leads?view=not_interested` | — |
| TC-09 | Workload | `currentWorkload`/`maxCapacity` | same | allocation, capacity | TC | TC Home | P1 | list row | "More stats" | `/telecaller/leads` | — |
| TC-10 | Remaining Capacity | `remainingCapacity` | same | allocation | TC | TC Home | P2 | list row | "More stats" | `/telecaller/leads` | — |
| SL-* | Sales summary | fields of `ApiConstants.salesDashboardSummary` | sales summary endpoint | requirements | SL | Sales Home | P1 | grid (max 4) | yes | existing routes (`/requirements`, `/properties`) | field mapping SD-10 |

**KPI-04 presentation (PD-04).** Interim frozen behavior: render KPI-04a and KPI-04b as two cards if both are enabled in KPI config; both open the same breakdown page. Options for PD-04: two cards (current), one combined card with new/old breakdown inside, or one primary card plus secondary caption. The backend metric does not change in any option.

**Removed from mobile inventory.** KPI-09 Active Requirements (dead `_buildInventoryOverview`, no source; FB-01). KPI-10 Deals Won (dead, reads `rentalWonRequirements` which the backend never returns; not an alias of KPI-07). Dead `_buildDeskMetrics` labels ("Site visits done" over property counts) are not reused.

**Admin Home layout.** 2-column grid: KPI-02, KPI-04 (a/b per PD-04), KPI-06, KPI-07. Carousel: KPI-01, KPI-03, KPI-05, KPI-08. "Needs attention" list only if RV-15 confirms existing data; otherwise omitted.

**Telecaller Home layout.** Grid of TC-01, TC-03, TC-04, TC-05 (max 4). TC-02, TC-06–TC-10 in a "More stats" row list. "My Scheduled Follow-ups" and "Recent Leads Transferred to Sales" become card lists (existing pagination kept).

---

## 8. Telecaller outcome system (frozen — DR-005, DR-006)

| Outcome | Backend Status | Required Input | Leaves Queue? | Destination |
|---|---|---|---|---|
| CNR | allocation CNR, call_disposition CNR, attempt +1, pending callbacks completed | optional remark (default "Marked as CNR") | Yes | CNR (`/telecaller/cnr`) |
| Callback | allocation CALLBACK; row in `campaign_lead_callbacks` | date, time; optional remark | Yes | Callbacks (`/telecaller/callbacks`) |
| Follow Up | allocation FOLLOWUP; rows in `campaign_lead_followups`, `followups` | date, time; optional remark | No | Stays in Queue; also TC Home "My Scheduled Follow-ups" |
| Picked Up | HANDED_TO_SALES / Assigned | sales user (required), remarks / property key points (required) | Yes | Assigned to the chosen sales user |
| Interested | stage INTERESTED, call_disposition CONTACTED | none | No (unless imported) | Stays; Requirement section |
| Not Interested | stage LOST, rejection_reason NOT_INTERESTED, allocation RELEASED | reason | Yes | Not interested archive (`/campaign/leads?view=not_interested`) |

APIs: CNR and Picked Up → POST `/integrations/leads/:id/transfer`; Callback and Follow Up → POST `/integrations/leads/:id/followups`; Interested, Not interested, New → PATCH `/integrations/leads/:id/campaign-status`. POST `/leads/:id/outcome` (`recordOutcome`) must not be used.

### 8.1 Picked Up workflow (frozen)

```text
Picked Up
↓
Select Sales User (required)
↓
Enter mandatory remark (property key points)
↓
Transfer / Assign  (POST /integrations/leads/:id/transfer)
↓
Lead leaves telecaller queue
```

Validation copy (existing): "Please select a sales user to assign the lead to." and "Property key points (remarks) are mandatory when assigning a lead."

### 8.2 Callback / Follow-up / CNR separation (frozen)

| | Callback | Follow-up | CNR |
|---|---|---|---|
| In calling queue | No | Yes | No |
| Mobile destination | Callbacks tab | Queue card with follow-up chip; TC Home list | CNR tab |
| Storage | `campaign_lead_callbacks` (+ fallback) | `campaign_lead_followups`, `followups` | status on lead |
| Due rule | scheduled day before today, device local time | — | — |

They are never merged into one "Follow-ups" feature on mobile.

---

## 9. Status terminology freeze (presentation only — DR-019)

| Concept | Existing UI Label | Backend | DB | Final Mobile Label |
|---|---|---|---|---|
| Not reached | CNR / "CNR / Retry" | CNR | allocation_status, call_disposition CNR | CNR |
| Scheduled call back | Callback | CALLBACK | allocation_status CALLBACK; `campaign_lead_callbacks` | Callback |
| Follow-up in queue | "Follow up" (campaign), "Follow-up" (requirements) | FOLLOWUP | allocation_status FOLLOWUP | Follow-up |
| Handed to sales | Picked Up; dashboard "Handed to Sales" | PICKED_UP / HANDED_TO_SALES | allocation_status | Action label "Picked Up"; resulting state label "Handed to Sales" |
| Interested | Interested | — | stage INTERESTED | Interested |
| Calling rejection | Not interested | RELEASED | stage LOST, NOT_INTERESTED | Not interested |
| Requirement rejection | "Rejected…" values, tab "Rejected" | — | requirements.status "Rejected…" | Rejected (keep full value in detail) |
| Lost | — | — | — | Not used |
| Visit scheduled | "Site Visit Sche." | — | requirements.status "Site Visit" | Site Visit Scheduled |
| Visit done (lead) | Site Visit Done | SITE_VISIT_DONE in lifecycle | requirements.status | Site Visit Done |
| Visit done (record) | Site Visits Done (KPI) | COMPLETED | site_visits.status | Site Visits Done (KPI only) |
| Won | Won / My Won | WON, Deal Won | requirements.status "Won" | Won; KPI label "Deal Won" |
| Negotiation | Negotiation | — | requirements.status | Negotiation |
| Availability | Active / Break / Inactive | ACTIVE / BREAK / INACTIVE | availability | Active / On break / Inactive |

Backend and stored values are not renamed.

---

## 10. Search (frozen — DR-018)

```text
Mobile search chrome:   One MobileSearch component (full screen, field 48, clear 48).
Search scope:           Context of the current tab (Properties, Leads, Queue, Callbacks/CNR,
                        Library, Employees). Global shell search remains a separate entry.
Data source:            Existing per-surface source:
                        Properties/requirements/global → local Isar (client fuzzy);
                        Queue → loaded campaign leads (client);
                        Callbacks/CNR → server (search param);
                        /search → PropertySearchScreen.
Offline behavior:       Isar-backed searches work offline over cached data; server-backed
                        searches show the offline state.
Context-specific search: Uses that surface's existing debounce (500/250/200/150ms).
Global search:          Existing _performSearch over Isar; results grouped by type.
Backend dependency:     /api/v1/search is unused; a unified server search is FB-03
                        (IMPLEMENTATION DEPENDENCY if ever required). No recent-search store.
```

---

## 11. Filters, sort, pagination per surface (frozen — DR-020)

| Surface | Current Source | Current Pagination | Mobile Strategy | Step 3 Dependency |
|---|---|---|---|---|
| Campaign queue | GET `/integrations/leads` limit 5000 → memory/Isar, client filter | none in UI | Keep fetch; render with lazy builder; client filters as today | Server paging = IMPLEMENTATION DEPENDENCY (SD-11) |
| Requirements | Isar local-first, background refresh; API page/limit ≤200 unused | none in UI | Keep local-first; lazy list | Server paging = IMPLEMENTATION DEPENDENCY |
| Properties | GET `/properties` + Isar; client sort l2h/h2l | API ≤200 | Keep; sort sheet with the two existing keys; filter sheet with existing server params, other filters only where client logic exists (RV-17) | Server paging = IMPLEMENTATION DEPENDENCY |
| Callbacks | GET `/telecaller/callbacks` (search, from, to, source, telecallerId) + local merge | server list | Keep; tabs all/today/due/future as chips | none |
| CNR | GET `/telecaller/cnr` + local merge | server list | Keep | none |
| Reports | `/reports/*`; business-insight drilldown limit 500 + offset | offset | "View records" page with existing offset paging | none |
| KPI drilldowns | `/dashboard/*-list` | page/limit 25 | Infinite scroll using existing page param | none |

"30 rows everywhere" from Step 2 §38 is withdrawn.

---

## 12. Property wizard (frozen — DR-008)

Steps stay: 1 Basic (with media), 2 Location, 3 Pricing, 4 Contacts. Edit mode keeps Back / Next / "Save Changes". Presentation may change; fields may not.

| Step | Field | Class | DB-backed |
|---|---|---|---|
| 1 | title ("Location / Property Name") | required | yes |
| 1 | category_id, property_type_id, listing_type_id, property_status_id | as validated today | yes |
| 1 | configuration_id, description | optional | yes |
| 1 | images (default max 30, clamp 100; 10 MB each), videos (default 5, clamp 20; 100 MB each) | media | yes (URLs) |
| 2 | city_id, area_id | as validated today | yes |
| 2 | new area pincode (6 digits) | conditional (only when adding an area) | via lookup |
| 2 | address, landmark, block_wing, flat_no | optional | yes |
| 2 | google_place_id, formatted_address, locality, city, state, country, postal_code, lat/lng | optional (place picker) | yes |
| 3 | price, deposit, maintenance, brokerage_type_id | as validated today | yes |
| 3 | super_builtup_area, carpet_area | optional | yes |
| 3 | plot_area | conditional (property type) | yes |
| 3 | furnishing, facing, ownership, bedrooms, bathrooms, balconies, parking, age_of_property | optional | yes |
| 3 | floor_no, total_floor | conditional (null for bungalow) | yes |
| 3 | possession_date | conditional (required when status "To Be Available") | yes |
| 4 | owner_name, owner_mobile, broker_name, remarks | as validated today | yes |
| any | amenities, additional_details, is_verified | optional | yes |
| UI-only | step index, draft state, upload progress | UI-only | no |

Writes go through `PropertiesRepository` and `OutboxLocal` (pending-write state applies, §14).

---

## 13. Lead (requirement) wizard (frozen — DR-009)

Seven steps as today (`_activeStep < 6`). Mobile may compact the visual (one step per page, sticky Next/Save, progress "n of 7").

| Field | Class |
|---|---|
| client name | required |
| mobile | required; duplicate check on local Isar (existing dialog → confirmation sheet allowed) |
| listing type | required |
| category, property types (`property_type_ids`, multi) | required |
| configuration_ids | optional |
| target area_ids ("All Areas" option) | required |
| budget (single field; single value → ×0.8 / ×1.2 range client-side) | required |
| min/max area, furnishings, facings, remarks | optional |
| leadSource | as validated today |
| referralName | conditional (Referral) |
| status | existing values |
| draft | `CRMDraftRepository` |

Not part of the form: alternate phone, email, city, timeline, budget min, budget max. Assignment: Admin, SA, Telecaller create unassigned; Sales self-assigns (unchanged). Writes go through `RequirementsRepository` / outbox.

---

## 14. Offline and outbox states (frozen — DR-021)

| State | Where it applies | UI |
|---|---|---|
| Cached read | Isar collections: properties, requirements, follow-ups, lookups, dashboard, campaign leads | Show cache + caption "Offline · last updated {time}" when offline |
| Syncing | `SyncManager.isSyncing` | Existing blocking overlay (PD-05 pending); per-list caption allowed in addition |
| Pending write | Property and requirement writes via `OutboxLocal` | Caption "Waiting to sync" on the affected card |
| Direct server operation | Campaign outcomes (transfer, followups, campaign-status), allocation, start-call | Spinner on the action; on success update card; no "Waiting to sync" |
| Failed write | Outbox conflict (server wins, item removed) or direct call failure | Banner "Couldn't save. Try again." + Retry; for campaign-status failure, reload the lead from server because the optimistic write is not rolled back (RV-19) |

Offline outcome capture for calling is FUTURE BACKLOG (FB-05).

---

## 15. Realtime (frozen strategy — DR-022)

```text
Realtime is required for:  nothing in the mobile UX. It is an enhancement only.
Realtime currently verified: no. SyncManager joins "realtime:propkart"; the handler accepts
                            only "realtime:public"; campaign_lead_callbacks is not watched.
Runtime verification required: RV-03.
Fallback behavior:          pull-to-refresh on every list; refetch on tab focus and on return
                            from the dialer; existing polling stays (notifications 25s,
                            campaign sheets 60s, messages 4s/15s, heartbeat 30s).
```

No mobile screen may depend on push updates to show correct state after the user's own action; the action's response updates the card.

---

## 16. Shift and calling interaction

| Moment | Specification |
|---|---|
| Before call | Telecaller must be ACTIVE (gate otherwise blocks). Card shows Call (48) and WhatsApp (`wa.me`, `91` prefix). |
| Call from Queue | `tel:` via url_launcher only (existing). No start-call record unless PD-06 approves. |
| Call from Callbacks / CNR | Existing `startCall` (POST `/telecaller/leads/:id/start-call`) then `tel:`. |
| During call | App is backgrounded. No in-app timer (none exists). |
| After returning from dialer | Outcome sheet is offered for the called lead; list refetches. |
| Idle timer | Existing 5-minute pointer-idle timer. Behavior while dialer is foreground is RV-01. |
| Break behavior | If BREAK is set on return, the break overlay shows first; outcome is recorded after Resume. |
| Call outcome | §8 matrix. |
| Failed call (dialer did not open) | SnackBar "Couldn't open the dialer." (copy only; RV-11 for Android resolution). |
| No answer | Telecaller chooses CNR. |
| CNR | §8. |
| Callback | §8. |

---

## 17. Session, errors, accessibility

**Session expiry (DR-015, SPECIFICATION CORRECTION).** Final mobile behavior: existing redirect to `/get-started?from=<path>`; after sign-in, `RoleGuard.sanitizeRedirectPath` returns to the allowed path. No blocking dialog.

**Errors.** Requirement retained: user-facing mobile UI must not expose raw technical exceptions. Current app does not satisfy this (~45 raw `$e` SnackBars, 198 `e.toString()`). STEP 3 IMPLEMENTATION for every screen touched; untouched screens FB-11.

**Accessibility.** Semantics requirement retained. Current app has 0 explicit Semantics. Every new mobile component carries semantics labels (icon buttons label = tooltip). TalkBack/VoiceOver pass is RV-14. Contrast RV-05; text scale 1.3× RV-06.

**Forbidden routes (DR-016).** Existing router redirects stay (e.g. non-Admin `/admin/lead-allocation` → `/telecaller/leads`). `MobilePermissionState` is shown only when a screen receives HTTP 403 from the API.

---

## 18. RBAC per mobile destination (preserved — DR-023)

Hidden UI is not security. Backend permissions below are the existing ones.

| Destination | Telecaller | Sales | Admin | Super Admin | Route guard | Backend permission |
|---|---|---|---|---|---|---|
| Home `/dashboard` | TC dashboard | Sales dashboard | Admin | Admin | none | `dashboard.read` (admin KPIs); `/telecaller/dashboard` `telecaller.leads` |
| Queue `/campaign/leads` | tab | hidden | More | More | none | `/integrations/leads` any of `campaign.manage`, `telecaller.leads`, `telecaller.calls` |
| Callbacks | tab | hidden | hidden | More | none | `telecaller.callbacks` or `allocation.monitor` or `campaign.manage` |
| CNR | tab | hidden | hidden | More | none | `telecaller.cnr` or monitor/manage |
| Leads `/requirements` | More | tab | tab | tab | none | `requirements.read` (Sales scoped to self, TC to telecaller) |
| Properties | More | tab | tab | tab | none | properties API |
| Reports | hidden | hidden | tab | tab | RoleGuard | `authenticate` only + role scoping (FB-08) |
| Employees `/users` | hidden | hidden | More | More | RoleGuard | users API |
| Lead allocation | hidden | hidden | More | More | role redirect | allocation permissions |
| Campaign connections | hidden | hidden | More | More | none (sidebar hides for TC) | `campaign.manage` |
| Library, Recycle bin, Messages, Settings, Profile | More | More | More | More | none | existing |
| Sync diagnostics | hidden | hidden | More (via Settings) | More | `isAdminOrSuperAdmin` | — |
| Audit logs | hidden | hidden | hidden | More | RoleGuard SA | audit API |
| Shift toggle | top bar | — | — | — | role | `telecaller.availability` |

Visibility always defers to `PermissionMatrixService` as synced from the backend.

---

## 19. Final screen master

| ID | Screen | Role | Route | Primary Navigation | Data Source | Mobile Pattern | Status |
|---|---|---|---|---|---|---|---|
| M-01 | Splash | all | `/` | auto | session | loader | STEP 3 IMPLEMENTATION |
| M-02 | Get started | public | `/get-started` | entry | — | page | STEP 3 IMPLEMENTATION |
| M-03 | Login | public | `/login` | push | auth API | form page | STEP 3 IMPLEMENTATION |
| M-04 | MFA verify | all | dialog today | after login | `MfaSubmitted` | full page (keyboard) | STEP 3 IMPLEMENTATION |
| M-05 | Reset password | public | existing | push | auth API | form page | STEP 3 IMPLEMENTATION |
| M-06 | Not found | all | errorBuilder | — | — | error state | STEP 3 IMPLEMENTATION |
| M-07 | Admin Home | AD SA | `/dashboard` | tab | `/dashboard/kpis` | KPI grid + carousel | STEP 3 IMPLEMENTATION (KPI-04 per PD-04) |
| M-08 | Telecaller Home | TC | `/dashboard` | tab | `/telecaller/dashboard`, follow-ups, transferred leads | KPI grid + card lists | STEP 3 IMPLEMENTATION |
| M-09 | Sales Home | SL | `/dashboard` | tab | sales summary endpoint | KPI grid + card lists | IMPLEMENTATION DEPENDENCY (SD-10) |
| M-10 | KPI drilldown pages (KPI-01…08) | AD SA | push from Home | push | `/dashboard/*` | full-screen list | STEP 3 IMPLEMENTATION |
| M-11 | Calling queue | TC (AD SA via More) | `/campaign/leads` | tab | `IntegrationService` | lead cards + outcome sheet | STEP 3 IMPLEMENTATION (gated by RV-01, RV-11) |
| M-12 | Not interested / archives | TC AD SA | `/campaign/leads?view=…` | push from queue overflow | same | cards | STEP 3 IMPLEMENTATION |
| M-13 | Callbacks | TC SA | `/telecaller/callbacks` | tab / More | `/telecaller/callbacks` | cards + chips | STEP 3 IMPLEMENTATION |
| M-14 | CNR | TC SA | `/telecaller/cnr` | tab / More | `/telecaller/cnr` | cards | STEP 3 IMPLEMENTATION |
| M-15 | Outcome sheets (CNR, Callback, Follow-up, Picked Up, Interested, Not interested) | TC AD SA | sheet | from card | `IntegrationService` | selection/short-form sheets | STEP 3 IMPLEMENTATION |
| M-16 | Leads list | all | `/requirements` | tab / More | `RequirementsRepository` | lead cards, tabs as chips | STEP 3 IMPLEMENTATION |
| M-17 | Lead detail | permitted | from list | push | requirement | detail page | STEP 3 IMPLEMENTATION |
| M-18 | Lead wizard (7 steps) | permitted | add/edit | push | repository + outbox | wizard page | STEP 3 IMPLEMENTATION |
| M-19 | Match sheet | permitted | from detail | sheet | `/requirements/:id/matches` | property cards | STEP 3 IMPLEMENTATION |
| M-20 | Won property selection | permitted | from status | page | existing dialog logic | selection page | STEP 3 IMPLEMENTATION |
| M-21 | Properties list | all | `/properties` | tab / More | `PropertiesRepository` | property cards | STEP 3 IMPLEMENTATION |
| M-22 | Property detail | permitted | `/properties/:id` | push | property | detail + sticky bar | STEP 3 IMPLEMENTATION |
| M-23 | Property wizard (4 steps) | permitted | add/edit | push | repository + outbox | wizard page | STEP 3 IMPLEMENTATION |
| M-24 | Media viewer | permitted | push | push | URLs | full screen | STEP 3 IMPLEMENTATION |
| M-25 | Property search | permitted | `/search` | push | Isar | MobileSearch | STEP 3 IMPLEMENTATION |
| M-26 | Recycle bin | permitted | `/bin` | More | properties (deleted) | cards | STEP 3 IMPLEMENTATION |
| M-27 | More | all | `/more` (new) | tab | permission matrix | grouped list | IMPLEMENTATION DEPENDENCY (SD-08) |
| M-28 | Lead allocation | AD SA | `/admin/lead-allocation` | More | allocation API | telecaller cards | STEP 3 IMPLEMENTATION |
| M-29 | Employees / detail | AD SA | `/users` | More | users API | user cards | STEP 3 IMPLEMENTATION |
| M-30 | Reports insight | AD SA | `/reports/leads/overall-business-insight` | tab | `/reports/business-insight` | KPI stack + chart + records page | STEP 3 IMPLEMENTATION |
| M-31 | Telecaller report | AD SA | reports shell | push | `/reports/telecallers` | people cards | STEP 3 IMPLEMENTATION |
| M-32 | Sales report | AD SA | `/reports/leads/sales` | push | placeholder | empty state | STEP 3 IMPLEMENTATION |
| M-33 | Property reports | AD SA | `/reports/properties` | push | placeholder | empty state | STEP 3 IMPLEMENTATION |
| M-34 | Super-admin metrics | SA | existing | More | reports API | report stack (no org switcher) | STEP 3 IMPLEMENTATION |
| M-35 | Campaign connections + Meta/Housing settings + portal wizard | AD SA | `/campaign/connections` etc. | More | integrations API | cards / pages | STEP 3 IMPLEMENTATION |
| M-36 | Library (rental, resale, agents) | permitted | `/library` | More | library data | cards | STEP 3 IMPLEMENTATION |
| M-37 | Messages | permitted | `/messages` | More | messages API (polling) | list + thread page | STEP 3 IMPLEMENTATION |
| M-38 | Settings home + sections | permitted | `/settings` | More | settings | grouped list → pages | STEP 3 IMPLEMENTATION |
| M-39 | Sync diagnostics | AD SA | settings push | More | `SyncDebugScreen` | page | STEP 3 IMPLEMENTATION |
| M-40 | Audit logs | SA | `/settings/audit-logs` | More | audit API | cards | STEP 3 IMPLEMENTATION |
| M-41 | Profile + MFA security | all | `/profile` | More | profile | header + rows | STEP 3 IMPLEMENTATION |
| M-42 | Public share pack / property | public | `/share/...` | link | share API | cards / detail | STEP 3 IMPLEMENTATION |
| M-43 | Shift overlays | TC | wrapper | shell | `TelecallerShiftManager` | existing overlays hosted | STEP 3 IMPLEMENTATION (no behavior change) |

Not in Step 3: Sales Visits tab (PD-03), Clients/Owners/Builders/Pipeline (FB-14), IntegrationScreen, TelecallerLeadsScreen, LeadMetricsPlaceholderScreen, HomeScreen, CRMPlaceholderScreen.

---

## 20. Campaign 5000-row issue

```text
Current request:      GET /integrations/leads limit 5000 (_executeFetchServerLeads).
Actual backend behavior: getLeads defaults page 1 / limit 200, uses range + count:'exact';
                      telecallers scoped by integrationLeadIdsForTelecaller. A PostgREST
                      max-rows setting may cap the response.
Actual returned row count: unknown (RV-02).
Mobile requirement:   queue must render smoothly at 360×800 with lazy cards; count shown as
                      "{n} loaded".
Performance risk:     P1 — memory and filter cost of a large list on low-end phones.
Step 3 dependency:    none for rendering; server paging is SD-11 (IMPLEMENTATION DEPENDENCY).
Runtime verification: RV-02 — log returned row count and filter time per role.
```

No limit value is prescribed by this specification.

---

## 21. Dead and unreachable features (DR-024)

| Item | Final state |
|---|---|
| IntegrationScreen | Deprecated; unreachable (route redirects). Future cleanup FB-13 |
| LeadMetricsPlaceholderScreen | Unreachable; future cleanup |
| HomeScreen | Unreachable; future cleanup |
| CRMPlaceholderScreen | Unreachable; future cleanup |
| PipelineScreen | Product decision (FB-14); not in mobile |
| TelecallerLeadsScreen | Unreachable; `/telecaller/leads` uses `CampaignLeadsScreen`; future cleanup |
| `_buildSidebarContent` | Unreachable; future cleanup |
| `_buildDeskMetrics`, `_buildInventoryOverview` | Unreachable; source of KPI-09/10; future cleanup |
| Clients, Owners, Builders (+ add/edit) | Routes redirect to `/dashboard`; product decision (FB-14); not in mobile nav |
| TeamMessengerDialog | Unreachable (show routes to `/messages`); future cleanup |
| `recordOutcome` → POST `/leads/:id/outcome` | Do not use; future cleanup FB-16 |

Nothing is deleted in Step 3 unless separately approved.

---

## 22. Table → card classification

Principle kept: no primary phone workflow depends on a horizontally scrolling data table. Inventory: 32 `DataTable`, 12 `CRMDataTable`, 0 `PaginatedDataTable`.

| Table | Classification |
|---|---|
| Campaign leads | Step 3 mobile conversion (cards) |
| Requirements (4) | Step 3 mobile conversion |
| Properties | Step 3 mobile conversion |
| Recycle bin (2) | Step 3 mobile conversion |
| Telecaller dashboard "Recent Leads Transferred to Sales" | Step 3 mobile conversion |
| Sales dashboard tables (2) | Step 3 mobile conversion |
| KPI and report drilldown tables | Step 3 mobile conversion (priority fields on card, rest on detail) |
| Telecaller report (`telecaller_leads_table`), team ranking | Step 3 mobile conversion |
| Users | Step 3 mobile conversion |
| Audit logs | Step 3 mobile conversion |
| Permission matrix | Step 3 mobile conversion (switch list) |
| Service-agent library | Step 3 mobile conversion |
| Portal "advanced JSON" preview | Desktop-only retained (horizontal scroll acceptable) |
| Clients, owners, builders | Requires product decision (FB-14) |
| Any remaining table not on a Step 3 screen | Future backlog |

Tables remain as-is at ≥768.

---

## 23. Dialog reconciliation

| Current | Mobile type | Classification |
|---|---|---|
| Campaign disposition / transfer dialog (`_showTransferDialog`) | Outcome sheets (§8) | Step 3 conversion |
| Property form dialogs, requirement stepper | Full-page wizard | Step 3 conversion |
| KPI drilldown dialogs (~13), lead drilldown, report expand | Full-screen list page | Step 3 conversion |
| MFA verify | Full page | Step 3 conversion |
| Delete / logout confirm | `MobileConfirmDialog` (blocking, names the object) | Step 3 conversion |
| Duplicate-mobile check on lead | Confirmation sheet | Step 3 conversion |
| Filters, sort | `MobileFilterSheet`, `MobileSortSheet` | Step 3 conversion |
| PDF/export, popup menus >3 items | `MobileSelectionSheet` | Step 3 conversion |
| Dashboard notes / schedule | Sheet | Step 3 conversion |
| Date / time pickers | Platform pickers | Keep |
| Existing bottom sheets (16) | Keep as sheets | No action |
| Forced app update | Blocking dialog | Keep |
| Session expiry | Redirect (no dialog) | Keep (DR-015) |
| Shift overlays | Existing overlays | Keep (DR-002) |
| Messenger dialog | Not used (route) | No action |

---

## 24. Final component master

| Component | Purpose | Inputs | States | Role behavior | Accessibility | Responsive | Allowed | Forbidden |
|---|---|---|---|---|---|---|---|---|
| MobileAppShell | Phone frame below 768 | role, child route, nav config | normal, syncing overlay, shift-gated (TC) | TC wrapped by `TelecallerShiftGateOverlay` | focus order top→content→nav | <768 only | all signed-in shell routes | rendering at ≥768 |
| MobileBottomNav | Role tabs | items (≤5), current route | selected, unselected, hidden (keyboard) | per §5.3 | label 12, semantics per tab, 48 hit | labels visible ≥360 | primary destinations | >5 items, actions as tabs |
| MobileMoreSheet (More page) | Secondary destinations | permission matrix, role | loading, list | rows per §5.3; TC Shift row | row semantics, 64 rows | full screen page | grouped list | drawer, invented badges |
| MobileTopBar | Title, back, search, overflow | title, back flag, actions | root, pushed | TC: availability toggle | 48 targets, labels | 56 high | ≤3 trailing icons | tabs inside |
| MobileSearch | Full-screen search | context, data source, debounce | empty, loading, results, no matches, offline, error | context per role | autofocus, clear label | full screen | per §10 | recent-search store, new API |
| MobileFilterSheet | Filters | sections, current values | open, applied, cleared | role-specific filters | grabber + close 48 | max 85% | existing filters only | new filter logic |
| MobileSortSheet | Sort | existing sort keys | selected | — | radio rows 48 | max 50% | existing keys | new sort keys |
| MobileCard | Record card (lead, property, user) | record, actions | normal, pending write, disabled | actions by permission | card label = primary text | full width | lists | horizontal tables |
| MobileListTile | Rows in More/settings/stats | icon, title, subtitle, trailing | normal, disabled | permission-gated | 56–64 rows | full width | lists | dense 40 rows |
| MobileKpiCard | KPI | label, value, delta?, onTap | loading, value, "—", 0, error | per §7 | value + label read together | 104 grid / carousel | §7 KPIs | KPI-09, KPI-10, sparkline |
| MobileSectionHeader | Section titles | text, action? | — | — | header semantics | — | lists | — |
| MobileEmptyState | Empty list | icon, title, body, action? | — | action only if permitted | readable copy | center | all lists | blank screens |
| MobileErrorState | Load failure | message key, retry | — | — | no raw exceptions | center/banner | all loads | `$e`, stack, JSON |
| MobileOfflineBanner | Offline | lastUpdated?, hasCache | cache, no cache | — | live region | top of content | Isar-backed screens | claiming "no data" with cache |
| MobileSyncIndicator | Sync status | sync state | syncing, failed | — | live region | caption 16 | in addition to existing overlay (PD-05) | replacing overlay before PD-05 |
| MobileFormStep | Wizard step | step n/total, fields, validators | valid, invalid, saving | role-driven fields as today | error text under field, focus first error | one column | property (4), lead (7) wizards | new fields |
| MobileStickyActionBar | Primary actions | 1 primary or 3 equal contact actions | enabled, loading, disabled | permission-gated | 48 targets | 64 + safe area | detail, wizard | 4 equal primaries |
| MobileConfirmDialog | Destructive / critical confirm | title naming object, actions | — | — | focus on cancel | max 40% | delete, logout | long forms |
| MobileSelectionSheet | Short choices, outcomes | options, required inputs | selecting, submitting, error | outcomes per §8 | radio rows 48 | max 70% | outcomes, menus >3 | multi-step workflows |
| MobileMediaViewer | Images/videos | media list, index | image, video, zoom | — | close 48, labels | full screen | galleries | CRM chrome |
| MobilePermissionState | API 403 | role home route | — | — | clear copy | center | 403 responses | replacing router redirects |
| MobileLoadingSkeleton | Loading | shape (card/kpi) | pulse | — | busy semantics | matches card | lists, KPIs | spinners for lists |

---

## 25. Final workflow master

**Telecaller.**

| Step | Route | Source | Backend operation | State | Offline | Failure |
|---|---|---|---|---|---|---|
| Login | `/login` | auth | login + MFA | — | not available | field/banner error |
| Home | `/dashboard` (PD-01) | `/telecaller/dashboard` | GET | shift gate applies | cached dashboard if present | error state + Retry |
| Queue | `/campaign/leads` | `IntegrationService` | GET `/integrations/leads` | ACTIVE required | cached `CampaignLeadLocal` | error state |
| Call | `tel:` | — | none (queue) / start-call (callbacks, CNR) | app backgrounded | dialer works offline | "Couldn't open the dialer." |
| Outcome | sheet | — | transfer / followups / campaign-status | direct server operation | not available offline (FB-05) | banner + reload lead |
| Destination | Callbacks / CNR / assigned / archive / stays | §8 | — | — | — | — |

**Sales.**

| Step | Route | Source | Backend operation | State | Offline | Failure |
|---|---|---|---|---|---|---|
| Login → Home | `/dashboard` (PD-02) | sales summary | GET | — | cache if present | error state |
| Leads | `/requirements` | `RequirementsRepository` | GET (server-scoped) | local-first | Isar | error state |
| Match | sheet | `/requirements/:id/matches` | GET | — | not available | error in sheet |
| Visit | status sheet | requirement status "Site Visit" / "Site Visit Done" | requirement update via outbox | pending write | queued | failed write banner |
| Pipeline | status on detail | requirement statuses through Negotiation → Won (property pick) / Rejected | update | pending write | queued | failed write banner |

**Admin.**

| Step | Route | Source | Backend operation | State | Offline | Failure |
|---|---|---|---|---|---|---|
| Login → Home | `/dashboard` | `/dashboard/kpis` + config | GET | filters (business type, date) | `DashboardLocal` cache | card error + Retry |
| KPI | tap card | §7 | — | — | — | — |
| Drilldown | page | `/dashboard/*-list` | GET page/limit 25 | paging | not available | error state |
| Reports | `/reports/leads/overall-business-insight` | `/reports/*` | GET | filters sheet | not available | error state |

**Property.**

| Step | Route | Source | Backend operation | State | Offline | Failure |
|---|---|---|---|---|---|---|
| List | `/properties` | `PropertiesRepository` | GET `/properties` | local-first | Isar | error state |
| Detail | `/properties/:id` | property | GET | — | cache | error state |
| Add/Edit | wizard | form | POST/PATCH via outbox | 4 steps | queued | field errors / banner |
| Save | — | — | outbox enqueue | pending write | "Waiting to sync" | — |
| Sync | — | `SyncManager` | replay | syncing | on reconnect | server-wins conflict → failed write banner |

**Lead.**

| Step | Route | Source | Backend operation | State | Offline | Failure |
|---|---|---|---|---|---|---|
| List | `/requirements` | `RequirementsRepository` | GET | local-first | Isar | error state |
| Detail | push | requirement | — | — | cache | error state |
| Add/Edit | wizard | form | POST/PATCH via outbox | 7 steps, draft | queued | field errors / banner |
| Save | — | — | outbox | pending write | "Waiting to sync" | — |
| Sync | — | `SyncManager` | replay | syncing | on reconnect | failed write banner |

---

## 26. Responsive and performance rules (reconciled)

- Lists use lazy builders in new components.
- Images use `CrmNetworkImage` (decode to width × DPR); library raw `Image.network` is FB-15.
- Large legacy widgets (campaign 12,795 lines, requirements 13,764) are wrapped or split for phone presentation reading the same services/BLoCs; no business logic moves.
- Polling intervals stay as they are.
- No mobile screen adds a breakpoint outside §3.

---

## 27. Runtime Verification Gate

| ID | Test | Why Required | Blocks Step 3? | Test Environment | Expected Result |
|---|---|---|---|---|---|
| RV-01 | Idle auto-break during an external dialer call >5 min | Telecaller may return to a break overlay mid-workflow | Yes — before releasing M-11/M-15 | Android phone, TC account, real call | Documented behavior (break or not); spec §16 adjusted if needed |
| RV-02 | Actual rows returned by `/integrations/leads?limit=5000` per role | Performance and paging decision | Partial — blocks any campaign performance change, not rendering | Staging/prod data, phone | Row count + filter time logged |
| RV-03 | Realtime events reach handlers (topic propkart vs public) | Avoid relying on push | No (fallback defined) | Two devices, edit a lead | Documented whether cards update |
| RV-04 | Report KPI captions from payload | Copy and layout | No | Admin, insight screen | Caption list captured |
| RV-05 | Contrast (terracotta on white, captions) | WCAG | No | Device, contrast tool | Ratios recorded |
| RV-06 | Text scale 1.3× | Clipping of sticky CTAs | No | Android font scale | No clipped CTA |
| RV-07 | Tablet orientation / Android 16 large-screen | Shell switch on rotation | No | Tablet | Shell changes at 768 cleanly |
| RV-08 | Image decode size | Memory | No | Network/memory profile | Decode ≈ display width × DPR |
| RV-09 | Per-screen offline behavior | Offline copy | No | Airplane mode | Matches §14 table per screen |
| RV-10 | Gallery double-tap zoom | Gesture spec | No | Device | Supported or not documented |
| RV-11 | `tel:` resolves via url_launcher on Android 11+ with current `<queries>` | Core calling | Yes — before releasing M-11 | Android 11+ device | Dialer opens |
| RV-12 | KPI-06 drilldown search (placeholder bug) | Search may error | No (hide search on that page if it fails) | Admin, site-visit drilldown | Documented error/no-error |
| RV-13 | CNR <20s, callback <40s | Design targets | No | Timed TC session | Times recorded |
| RV-14 | TalkBack / VoiceOver pass on new components | Accessibility | No | Device | Labels announced |
| RV-15 | "Needs attention" data on Admin Home | Avoid inventing rows | No | Admin dashboard | Existing data identified or section omitted |
| RV-16 | Drawer gesture on phone (legacy) | Legacy nav only | No | Device | Not needed once bottom nav ships |
| RV-17 | Property client-side filters for BHK/price/status | Filter sheet scope | No | Properties screen | Supported filters listed |
| RV-18 | Notification bell on 360px | Top bar layout | No | Device | Bell + count fit |
| RV-19 | Campaign-status PATCH failure leaves optimistic state | Failed-write UX | No | Force network error | Card reload restores server state |
| RV-20 | What stays visible/usable under shift overlays today | Mobile overlay parity | Yes — before M-43 sign-off | TC on device | Visible elements documented |

---

## 28. Product Decisions Required Before Step 3

Only PD-01 to PD-06 are genuine product decisions. The other evaluated items are frozen from code evidence.

| Decision ID | Question | Options | Current behavior | Technical consequence | Recommended specification state | Final decision |
|---|---|---|---|---|---|---|
| (DR-001) Shell breakpoint | Where does phone shell start? | 600 / 700 / 768 | 768 | 768 needs no shell switch change | FROZEN | 768 |
| PD-01 | Telecaller landing | Dashboard / Queue | Dashboard | Queue needs router change (SD-09) | PRODUCT DECISION REQUIRED, interim = Dashboard | Pending |
| PD-02 | Sales landing | Dashboard (Home tab) / Leads | Dashboard | Leads needs router change | PRODUCT DECISION REQUIRED, interim = Dashboard | Pending |
| PD-03 | Sales Visits source | requirement status / `site_visits` records / no Visits tab | No tab | `site_visits` list for Sales needs an API scoped to the user | PRODUCT DECISION REQUIRED, interim = no tab | Pending |
| PD-04 | KPI-04 presentation | two cards / combined / primary + caption | two cards | presentation only | PRODUCT DECISION REQUIRED, interim = two cards | Pending |
| (DR-011) KPI-09 | Keep Active Requirements? | remove / future KPI | dead | needs backend source | FROZEN | Removed; FB-01 |
| (DR-012) KPI-10 | Keep Deals Won? | remove / future | dead | — | FROZEN | Removed |
| (DR-015) Session expiry | Dialog or redirect | dialog / redirect | redirect | dialog changes auth flow | FROZEN | Redirect |
| (DR-016) Forbidden route | Permission page or redirect | page / redirect | redirect | page needs router guard changes | FROZEN | Redirect; 403 state in-screen |
| (DR-017) Sync-debug visibility | SA only / Admin + SA | — | Admin + SA | — | FROZEN | Admin + SA |
| (DR-020) Campaign pagination | Preserve / server paging now / defer | preserve | 5000 request | paging changes data flow | FROZEN | Preserve; RV-02; SD-11 |
| (DR-022) Realtime dependency | Depend / don't depend | — | unverified | — | FROZEN | Don't depend; fallback refresh |
| PD-05 | Sync overlay blocking? | keep blocking / non-blocking caption | blocking | non-blocking lets users act on stale lookups | PRODUCT DECISION REQUIRED, interim = blocking | Pending |
| PD-06 | Record start-call from Queue? | keep tel-only / call `startCall` like Callbacks | tel-only | adds a server write per queue call | PRODUCT DECISION REQUIRED, interim = tel-only | Pending |

---

## 29. Step 3 Dependencies

**Must be resolved before Step 3**
- SD-01 Sign-off of FROZEN decisions in the register (breakpoint 768, shift system, KPI inventory, outcome matrix).

**Must be resolved before the affected Step 3 screen**
- SD-02 PD-01 before final Telecaller landing (interim default allows shell work).
- SD-03 PD-03 before any Sales Visits tab.
- SD-04 PD-04 before Admin Home sign-off (interim default allows build).
- SD-05 RV-01 before releasing queue/outcome screens.
- SD-06 RV-11 before releasing queue calling.
- SD-07 RV-02 before any campaign performance change.

**Can be implemented during Step 3**
- SD-08 `/more` presentation route.
- SD-09 Router redirect change for Telecaller/Sales landing, only if PD-01/PD-02 approve.
- SD-10 Sales Home field mapping from `salesDashboardSummary`.

**Backend dependency (not in Step 3)**
- SD-11 Server pagination for campaign, requirements, properties lists.
- SD-12 Outbox / offline capture for campaign outcomes.

**Runtime/sync dependency (not in Step 3)**
- SD-13 Realtime topic/handler fix and `campaign_lead_callbacks` subscription.

**Future backlog** — FB-01 to FB-16 in the decision register.

---

## 30. Step 3 implementation rules

**Step 3 MAY:** create mobile UI components; create the mobile shell; create role navigation; convert screens to mobile patterns; create cards; create mobile forms; create sheets; create mobile detail pages; implement approved UX states; add accessibility to touched components; preserve existing APIs and business logic.

**Step 3 MUST NOT, unless explicitly approved:** change KPI definitions; change database truth; invent fields; change statuses; change allocation logic; change matching logic; change RBAC rules; rewrite backend; change sync architecture; change realtime architecture; change shift timers or states; silently change business behavior.

---

## 31. Quality check

| Check | Result |
|---|---|
| Every Step 2 contradiction handled | Yes, C-01–C-24 (§2) |
| Every P0 handled | Yes, C-01 (DR-001), C-02 (DR-002) frozen |
| Every P1 handled | Yes: frozen corrections, PD-01/03/04/06, RV-02, SD-11/12/13 |
| Runtime items preserved | Yes, RV-01–RV-20 |
| Product decisions isolated | Yes, PD-01–PD-06 |
| Backend dependencies isolated | Yes, SD-11–SD-13, FB items |
| Dead features classified | Yes, §21 |
| KPI inventory reconciled | Yes, §7; KPI-09/10 removed, telecaller KPIs added |
| Role navigation frozen | Yes, §5.3 (landings interim per PD-01/02) |
| Property and lead forms reconciled | Yes, §12, §13 |
| Telecaller workflow reconciled | Yes, §8, §16 |
| Offline and realtime | Yes, §14, §15 |
| RBAC preserved | Yes, §18 |
| Breakpoints frozen | Yes, §3 |
| Tables/dialogs classified | Yes, §22, §23 |
| Duplicate KPI names | None (Deal Won only; KPI-04a/b distinct labels) |
| Duplicate routes | `/campaign/leads` and `/telecaller/leads` both mount the queue widget; mobile tab uses `/campaign/leads`; TC KPI links to `/telecaller/leads` remain valid |
| Conflicting site-visit definitions | Separated (§6, §9) |
| Invented fields / APIs / statuses / rules | None; `/more` is a presentation route only |

---

## 32. Final reconciliation scorecard

```text
Step 2 requirements:          95 (verified in Step 2.5 master table)
Step 2.5 requirements:        95 master rows + 31 register rows + 24 contradictions
Reconciled:                   95 / 95 master rows; 24 / 24 contradictions; 31 / 31 register rows
Specification corrections:    16
Product decisions:            6 (PD-01 to PD-06)
Runtime gates:                20 (RV-01 to RV-20)
Step 3 dependencies:          13 (SD-01 to SD-13)
Future backlog:               16 (FB-01 to FB-16)
P0 unresolved:                0
P1 unresolved:                4 (PD-01, PD-03, PD-04, PD-06)
```

### STEP 3 READINESS

```text
READY WITH CONDITIONS
```

Conditions: SD-01 sign-off before Step 3 starts; PD-01–PD-06 resolved before the screens they affect (interim defaults preserve current behavior); RV-01, RV-11, RV-20 passed before telecaller calling and shift screens are released.

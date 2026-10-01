# PropKart Mobile UX/UI Audit and Redesign Specification

Audit date: 1 October 2026  
Method: static inspection of the Flutter client in `lib/` (306 Dart files). No application code was changed.  
Scores are **static estimates** from structure (navigation, tables, dialogs, width checks). Pixel overflow, contrast, and tap timing that cannot be proven from source are marked **Requires runtime verification**.

Counting rules used below:

- A **full screen** is a public widget whose class name ends in `Screen`.
- A **page** is a public widget whose class name ends in `Page`.
- A **dialog call site** is one `showDialog(` (152). An **AlertDialog constructor** is one `AlertDialog(` (118). These overlap: most call sites build an `AlertDialog`. They are not 152 + 118 separate products.
- A **bottom sheet call site** is one `showModalBottomSheet(` (14).
- A **popup** is one `PopupMenuButton` (30).
- A **table widget** is one `DataTable(` (32) or `CRMDataTable(` (12).
- A **KPI card construction** is one `CRMKPICard(` outside its definition (43). Dashboard tiles that do not use that widget are listed separately.
- `Dialog(` regex hits (551) are **not** used as a product count. The pattern also matches `showDialog(`.

---

## 1. Executive Summary

PropKart is a desktop-first CRM that already contains mobile breakpoints (`MediaQuery` width checks: 107) and a phone bottom bar. It is not a mobile product.

The shell that users actually see is `ModernSidebar` (`lib/features/shell/widgets/sidebar.dart`), rendered from `CRMAppShell`. A second sidebar, `_buildSidebarContent` in `app_shell.dart`, is never called. The phone bar offers Dashboard, Properties, Leads, Profile, and a center `+`. Telecaller work (calling queue, callbacks, CNR) is extra sidebar items, not the bottom bar. Campaign lead disposition lives in `campaign_leads_screen.dart` (about 12,000 lines) with 21 `showDialog` call sites and a `DataTable`.

Clients, Owners, and Builders still have full list and form screens, but `/clients`, `/owners`, and `/builders` redirect to `/dashboard`. Those screens are unreachable from the router.

Reports, lead allocation, audit logs, and portal configuration are real routes. On a phone they compete with a four-item bar that does not include them.

**Current overall mobile UX score: 4/10.**

The redesign should not shrink the sidebar. It should give each role a small set of bottom destinations and turn tables, multi-column forms, and desktop dialogs into cards, full-screen flows, and bottom sheets.

---

## 2. Exact inventory

```text
Total Full Screens                 53
Total Pages                        5
Total Detail Views                 4
Total Dashboards                   3
Total Tabs (TabBar widgets)        8
Total Sub-tabs (TabBarView)        2
Total Dialogs (showDialog sites)   152
Total AlertDialogs                 118
Total Bottom Sheets                14
Total Popup Menus                  30
Total Drawers (Drawer widget)      1
Total Forms (Form widget)          18
Total Form Steps (portal wizard)   8
Total KPI Cards (CRMKPICard uses)  43
Total Charts (distinct surfaces)   11
Total Tables (DataTable+CRM)       44
Total List Views                   Requires runtime verification (most lists are custom, not ListView-named screens)
Total Card Views                   widespread; CRMKPICard 43 plus property/lead cards inside large screens
Total Filter Panels                4 named (report date bar, report global bar, CRM filter drawer, dashboard filter dialogs)
Total Search Interfaces            6 routed or dedicated (shell search, /search, property search, campaign search, requirements search, library search)
Total Sort Interfaces              embedded in campaign and property lists; no standalone sort screen
Total Pickers                      date/time pickers 34 call sites; image picker and video picker sheets present
Total Image/Media Viewers          2 (CRMImageSlider, CRMImageZoomViewer) plus CRMVideoSlider
Total Empty States                 present on major lists; exact copy count Requires runtime verification (string heuristic 266 is not a product count)
Total Loading States               CircularProgressIndicator 147; LinearProgressIndicator 9; skeleton/shimmer string hits 77
Total Error States                 route error page, dashboard retry, Dio snackbars; SnackBar constructions 695
Total Permission States            1 shared CRMPermissionDenied pattern, used on campaign and other guarded pages
Total Confirmation Flows           majority of the 118 AlertDialogs
Total Quick Actions                1 center + on the phone bar (index 2)
Total Navigation Destinations      16 fixed sidebar destinations plus dynamic portal items
```

Dart files inspected: **306**.

---

## 3. Screen and view inventory

Roles: SA = Super Admin, AD = Admin, TC = Telecaller, SL = Sales, PUB = signed-out or public link.  
“Hidden” means the widget exists but its route redirects or the widget is not referenced.

| ID | Type | Name | Route / file | Parent | Role | Current purpose |
|---|---|---|---|---|---|---|
| MOB-001 | Full Screen | Splash | `/splash` `lib/splash.dart` | root | PUB | Session bootstrap |
| MOB-002 | Full Screen | Get started | `/get-started` | root | PUB | Entry before login |
| MOB-003 | Full Screen | Login | `/login` | root | PUB | Email/password and MFA entry |
| MOB-004 | Full Screen | Reset password | `/reset-password` | root | PUB | Recovery link |
| MOB-005 | Page | Terms | `/terms-and-conditions` and `/terms_and_conditions` | root | PUB | Legal |
| MOB-006 | Page | Privacy | `/privacy-policy` and `/privacy_policy` | root | PUB | Legal |
| MOB-007 | Error | Page not found | router `errorBuilder` | root | all | Unknown path |
| MOB-008 | Dashboard | Admin/sales dashboard | `/dashboard` | shell | SA AD SL | Org KPIs, schedule, recent properties |
| MOB-009 | Dashboard | Telecaller dashboard | same route, role branch inside `DashboardScreen` | shell | TC | Follow-ups and calling summary. **Requires runtime verification** of the exact branch |
| MOB-010 | Dashboard | Sales dashboard widget | `SalesDashboardScreen` inside sales bloc file | dashboard | SL | Sales-specific metrics |
| MOB-011 | Full Screen | Properties | `/properties` | shell | SA AD SL TC if permitted | Inventory list, filters, charts |
| MOB-012 | Detail | Property detail | `/properties/:id` | outside shell back-handler | all permitted | Listing detail |
| MOB-013 | Full Screen | Add/edit property | opened from properties, not its own route | properties | SA AD SL | Long listing form |
| MOB-014 | Full Screen | Property search | `PropertySearchScreen` | properties | SA AD SL | Dedicated search. Route wiring **Requires runtime verification** (`/search` exists) |
| MOB-015 | Full Screen | Recycle bin | `/bin` | shell | permitted | Deleted listings |
| MOB-016 | Full Screen | Requirements / Leads | `/requirements` | shell | SA AD SL TC | Buyer/tenant track list |
| MOB-017 | Form | Add/edit requirement | `AddEditRequirementScreen` | requirements | permitted | Lead form |
| MOB-018 | Page | Share pack | `/share/:sessionId` | public | PUB | Agent share link |
| MOB-019 | Detail | Public property | `/share/:sessionId/property/:propertyId` | public | PUB | Shared listing |
| MOB-020 | Full Screen | Campaign leads | `/campaign/leads`, `/campaign/meta`, `/campaign/housing`, `/campaign/portal-leads/:id`, `/telecaller/leads` | shell | SA AD TC | Calling queue, follow-ups, NI, archives |
| MOB-021 | Page | Source total leads | `SourceTotalLeadsPage` | campaign | SA AD | Source drilldown |
| MOB-022 | Page | Telecaller assigned leads | `TelecallerAssignedLeadsPage` | campaign | SA AD | Assignment drilldown |
| MOB-023 | Full Screen | Connections | `/campaign/connections` | shell | SA AD | Meta, Housing, portal cards |
| MOB-024 | Full Screen | Meta connection | `/campaign/connections/meta` | connections | SA AD | Meta settings |
| MOB-025 | Full Screen | Housing connection | `/campaign/connections/housing` | connections | SA AD | Housing settings |
| MOB-026 | Wizard | Portal integration | `/campaign/connections/portal/new` and `/:id` | connections | SA AD | 8-step API builder |
| MOB-027 | Full Screen | Portal leads loader | `/campaign/portal-leads/:id` | shell | SA AD | Loads name, then MOB-020 locked to that source |
| MOB-028 | Full Screen | Callbacks | `/telecaller/callbacks` | shell | TC AD | Callback queue |
| MOB-029 | Full Screen | CNR | `/telecaller/cnr` | shell | TC AD | Could-not-reach queue |
| MOB-030 | Dashboard | Telecaller dashboard widget | `TelecallerDashboardScreen` | telecaller | TC | Scheduled follow-ups card |
| MOB-031 | Full Screen | Telecaller leads wrapper | `TelecallerLeadsScreen` | telecaller | TC | Thin wrapper. **Requires runtime verification** whether shell uses it or MOB-020 |
| MOB-032 | Full Screen | Lead allocation | `/admin/lead-allocation` | shell | SA AD | Capacity and allocate |
| MOB-033 | Dialog | Telecaller detail | `TelecallerDetailDialog` | allocation | SA AD | Telecaller drill-in |
| MOB-034 | Full Screen | Employees | `/users` | shell | SA AD | Staff list |
| MOB-035 | Detail | Employee detail | `/users/:id` | shell | SA AD | Staff profile and KPIs |
| MOB-036 | Full Screen | Library home | `/library` | shell | permitted | Library chooser |
| MOB-037 | Full Screen | Rental library | `/rental-library` | shell | permitted | Shared rentals |
| MOB-038 | Full Screen | Resale library | `/resale-library` | shell | permitted | Shared resale |
| MOB-039 | Full Screen | Service-agent library | `/service-agent-library` | shell | permitted | Service agents |
| MOB-040 | Full Screen | Reports insight | `/reports` and `/reports/leads` redirect here: `/reports/leads/overall-business-insight` | shell | SA AD | Business insight |
| MOB-041 | Full Screen | Telecaller report | `/reports/leads/telecaller` | reports | SA AD | Telecaller performance |
| MOB-042 | Full Screen | Super-admin metrics | `/reports/leads/super-admin-metrics` | reports | SA | Cross-org metrics |
| MOB-043 | Full Screen | Sales report | `/reports/leads/sales` | reports | SA AD | Placeholder screen |
| MOB-044 | Full Screen | Lead metrics | `/reports/leads/metrics` | reports | SA AD | Lead metrics |
| MOB-045 | Full Screen | Property reports | `/reports/properties` | reports | SA AD | Coming-soon placeholder |
| MOB-046 | Full Screen | Lead metrics placeholder | `LeadMetricsPlaceholderScreen` | reports | — | Unused twin of MOB-044. **Requires runtime verification** of references |
| MOB-047 | Full Screen | Settings | `/settings` | shell | permitted | Sectioned settings |
| MOB-048 | Full Screen | Audit logs | `/settings/audit-logs` | shell | SA | Audit table |
| MOB-049 | Full Screen | Location config | `/settings/location-config` | settings | SA AD | Cities and areas |
| MOB-050 | Full Screen | KPI config | `/settings/kpi-config` | settings | SA AD | KPI toggles |
| MOB-051 | Full Screen | Sync debug | `SyncDebugScreen` | settings | SA | Sync diagnostics |
| MOB-052 | Full Screen | Profile | `/profile` | shell | all signed-in | Account |
| MOB-053 | Full Screen | Team messages | `/messages` | shell | permitted | Inbox |
| MOB-054 | Dialog | Team messenger | `TeamMessengerDialog` | shell | permitted | Chat overlay |
| MOB-055 | Full Screen | Integration inbox | `/integration` redirects to `/campaign/leads` | — | — | `IntegrationScreen` still exists |
| MOB-056 | Full Screen | Clients | `/clients` **redirects to `/dashboard`** | hidden | — | Unreachable list |
| MOB-057 | Form | Add/edit client | `AddEditClientScreen` | hidden | — | Unreachable with MOB-056 |
| MOB-058 | Full Screen | Pipeline | `PipelineScreen` | clients | — | Unreachable with clients redirect |
| MOB-059 | Full Screen | Owners | `/owners` **redirects to `/dashboard`** | hidden | — | Unreachable list |
| MOB-060 | Form | Add/edit owner | `AddEditOwnerScreen` | hidden | — | Unreachable |
| MOB-061 | Full Screen | Builders | `/builders` **redirects to `/dashboard`** | hidden | — | Unreachable list |
| MOB-062 | Form | Add/edit builder | `AddEditBuilderScreen` | hidden | — | Unreachable |
| MOB-063 | Full Screen | Home | `HomeScreen` | none | — | Not mounted by the router found in `app_router.dart` |
| MOB-064 | Full Screen | Placeholder | `CRMPlaceholderScreen` | design system | — | Generic empty module |
| MOB-065 | Overlay | Image zoom | `CRMImageZoomViewer` in `drawers.dart` | property detail | all | Gallery zoom |
| MOB-066 | Overlay | Image slider | `CRMImageSlider` | property | all | Gallery |
| MOB-067 | Overlay | Video slider | `CRMVideoSlider` | property | all | Video |
| MOB-068 | Dialog | MFA verify | `MfaVerifyDialog` | login | PUB | Second factor |
| MOB-069 | Dialog | MFA manage | `mfa_security_card.dart` | profile | all | Enroll / disable |
| MOB-070 | Dialog | App update | `UpdateDialog` | version module | all | Store update prompt |
| MOB-071 | Dialog | KPI expand | `KpiExpandDialog` | reports | SA AD | Larger KPI |
| MOB-072 | Dialog | KPI configuration | `KpiConfigurationDialog` | reports | SA AD | Which KPIs show |
| MOB-073 | Dialog | Lead drilldown | `LeadDrilldownDialog` | reports | SA AD | Lead rows behind a KPI |
| MOB-074 | Dialog | User performance | `UserPerformanceSummaryDialog` | reports | SA AD | Person summary |
| MOB-075 | Dialog | Requirement stepper | `RequirementStepperDialog` | requirements | permitted | Multi-step lead dialog |
| MOB-076 | Dialog | Win property pick | `RequirementWinPropertySelectionDialog` | requirements | SL SA AD | Choose property on win |
| MOB-077 | Dialog | PDF options | `PdfOptionSelectionDialog` | requirements | permitted | Share/PDF choices |
| MOB-078 | Menu | Phone bottom bar | `CustomBottomNavBar` | shell | all signed-in | Dashboard, Properties, Leads, Profile, + |
| MOB-079 | Menu | Report subshell | `reports_subshell_nav.dart` | reports | SA AD | Insight vs properties |
| MOB-080 | Menu | Campaign header tabs | `campaign_subshell_header.dart` | campaign | SA AD TC | Connections, Meta, Housing, saved portals |
| MOB-081 | Filter | Report date filter | `report_date_filter_bar.dart` | reports | SA AD | Range |
| MOB-082 | Filter | Report global filters | `report_global_filters_bar.dart` | reports | SA AD | Source, user, property |
| MOB-083 | Menu | Report export | `report_export_menu.dart` | reports | SA AD | Export |
| MOB-084 | Picker | Image picker sheet | `crm_image_picker.dart` | forms | permitted | Camera/gallery |
| MOB-085 | Picker | Video picker sheet | `crm_video_picker.dart` | forms | permitted | Video |
| MOB-086 | Picker | Searchable dropdown | `crm_searchable_dropdown.dart` | forms | all | Long option lists |
| MOB-087 | Wizard steps | Portal steps 1–8 | inside MOB-026 | portal | SA AD | Basic, Auth, Request, Parameters, Response, Mapping, Sync, Test |

`showDialog` is also called from these files (count in parentheses). Each call site is a separate overlay even when it has no named class:

`campaign_leads_screen.dart` (21), `requirements_screen.dart` (13), `kpi_drilldown_dialogs.dart` (12), `add_edit_property_screen.dart` (10), `properties_screen.dart` (9), `integration_screen.dart` (9), `dashboard_screen.dart` (7), `service_agent_library_screen.dart` (7), `connections_screen.dart` (6), `splash.dart` (4), `resale_library_screen.dart` (4), `rental_library_screen.dart` (4), `location_config_screen.dart` (3), `drawers.dart` (3), `login_screen.dart` (3), `telecaller_detail_dialog.dart` (3), `users_screen.dart` (2), `permission_matrix_card.dart` (2), `mfa_security_card.dart` (2), `add_edit_requirement_screen.dart` (2), plus 1 each in reset password, team messages, telecaller leads, telecaller dashboard, telecaller callbacks, settings, builders, clients, owners, audit logs, source totals, assigned leads, several report sections, searchable dropdown, sales bloc, allocation bloc, todays schedule.

Bottom sheet call sites (14): requirements (1), connections (3), integration (1), dashboard (1), top bar (1), location config (2), report global filters (1), owners (1), image picker (1), video picker (1), app shell (1).

---

## 4. Navigation map

Live primary navigation is `ModernSidebar`, not `_buildSidebarContent` (that method has no callers).

```text
PropKart
├── Signed out
│   ├── Splash                         /splash
│   ├── Get started                    /get-started
│   ├── Login                          /login
│   ├── Reset password                 /reset-password
│   ├── Terms                          /terms-and-conditions
│   └── Privacy                        /privacy-policy
├── Public share (no shell)
│   ├── Share pack                     /share/:sessionId
│   └── Shared property                /share/:sessionId/property/:propertyId
└── Signed in (CRMAppShell)
    ├── Phone bar: Dashboard | Properties | + | Leads | Profile
    ├── Sidebar (permission-gated)
    │   ├── Dashboard                  /dashboard
    │   ├── Properties                 /properties
    │   │   └── Detail                 /properties/:id   (leaves the shell)
    │   ├── Telecaller only
    │   │   ├── My Calling Leads       /campaign/leads
    │   │   ├── Callbacks              /telecaller/callbacks
    │   │   ├── CNR / Retry            /telecaller/cnr
    │   │   └── All Leads (Track)      /requirements
    │   ├── Everyone else: Leads       /requirements
    │   ├── Employees                  /users  → /users/:id
    │   ├── Reports                    /reports/leads/overall-business-insight
    │   │   ├── Telecaller report
    │   │   ├── Sales report (placeholder)
    │   │   ├── Lead metrics
    │   │   ├── Super-admin metrics
    │   │   └── Property reports (coming soon)
    │   ├── Campaign (hidden for telecaller)
    │   │   ├── Connections, Meta, Housing
    │   │   └── Dynamic portal names
    │   ├── Lead Allocation            /admin/lead-allocation
    │   ├── Library
    │   │   ├── Rental, Resale, Service agents
    │   ├── Settings                   /settings
    │   ├── Audit Logs                 Super Admin only
    │   └── Recycle Bin                /bin
    └── Profile card at the bottom of the sidebar
```

Redirects that hide screens:

- `/clients`, `/owners`, `/builders` → `/dashboard`
- `/campaign` → `/campaign/connections`
- `/integration` and `/campaign-leads` → `/campaign/leads`
- `/reports` and `/reports/leads` → overall business insight

Deep links: password reset, share links, `?from=` after login (allow-listed in `RoleGuard.allowedPostLoginPaths`).

Duplicate navigation: `_buildSidebarContent` repeats Dashboard, Properties, Leads, Employees, Campaign, Library, Settings, Bin, and a different phone bar, but nothing calls it. **Deprecate** after confirming no reflection/test reference. **Requires runtime verification** only if a flavor imports it dynamically. Static search found the definition only.

---

## 5. Role inventory

### Super Admin

Available: everything in the sidebar, including Audit Logs, KPI config, super-admin metrics, portal builder, allocation, employees.  
Hidden by redirect: Clients, Owners, Builders screens.  
Primary actions: watch KPIs, allocate leads, manage staff and permissions, open reports.  
Frequent workflow: Dashboard → KPI → drilldown dialog → lead table.  
Mobile priority: a short KPI stack and one drilldown list. Portal builder and permission matrix are desktop tasks; keep them behind More, full-screen, not in the first tab.

### Admin

Same as Super Admin except Audit Logs and super-admin-only metrics. Can manage employees if `page.employees` or `team.view` is on. Reports if `page.reports` or `reports.overall_insight` is on.  
Mobile priority: allocation and team performance before settings.

### Telecaller

Sidebar adds My Calling Leads, Callbacks, CNR, and renames Leads to All Leads (Track). Campaign tree is hidden (`!isTelecaller`).  
Phone bar does **not** include Callbacks or CNR. Those require the sidebar, which on a phone is a drawer. **Requires runtime verification** of how the drawer is opened.  
Primary actions: open the next lead, call, set CNR / callback / not interested / picked up, write a remark.  
This is the highest-frequency mobile role. Current UI is the campaign desktop screen.

### Sales

Sidebar matches Admin without employee, allocation, and campaign management unless a permission flag grants them. Default sales work is properties, leads, and the sales dashboard branch.  
Primary actions: open a lead, match a property, update pipeline, add a listing.  
Site visit and won/lost live inside lead and requirement dialogs, not as their own routes.

No fifth role name exists in `RoleGuard` beyond Super Admin, Admin, Telecaller, and Sales.

---

## 6. Screen-by-screen audit

Scores are 1–10 static estimates. Columns: hierarchy, readability, touch, navigation, spacing, type, density, efficiency, accessibility, clarity, actions, errors, loading, empty, **overall**.

### MOB-001 Splash

Purpose: hold the user while auth and sync settle. Frequency: once per launch.  
Layout: full-screen animation plus dialogs (4 `showDialog` sites, 1 `AlertDialog`).  
Mobile problem: blocking dialogs during start.  
Scores: 6, 6, 5, 7, 6, 6, 6, 5, 4, 6, 4, 5, 6, 5. **Overall 5.**  
Priority: Low. Keep a single full-screen loader. One dialog only for a hard failure, with Retry.

### MOB-002 Get started / MOB-003 Login / MOB-004 Reset / MOB-068 MFA

Purpose: enter the product.  
Layout: centered card. Login has 3 dialogs. MFA is a dialog, not a step.  
Mobile problem: a desktop card on a phone; MFA as a dialog fights the keyboard.  
Scores: 6, 6, 5, 6, 5, 6, 6, 5, 4, 6, 5, 5, 5, 5. **Overall 5.**  
Priority: High. One column, 48px fields, MFA as the next full screen, sticky Sign in. Password reset stays its own screen.

### MOB-005 Terms / MOB-006 Privacy

Purpose: legal text.  
Mobile: long scroll is acceptable. **Overall 7.** Priority: Low. Keep. Sticky close.

### MOB-007 Not found

Shows `state.error` text. That can be a technical router message.  
**Overall 3.** Priority: Medium. Human sentence and a Home button. Do not print the exception.

### MOB-008 / MOB-009 Dashboard

Purpose: the home for every signed-in role.  
Layout: KPI row (Available Inventory, Total Leads, Telecallers, Leads Allocated, Assigned to Sales, Site Visits Done, Deal Won, Sales Users), filter dialogs, recent properties, schedule, notes dialog, status pie painter. Width is checked; cards can sit in a row.  
Mobile problem: eight KPIs in a wrapping grid become a tall, low-priority stack. Filters are dialogs. The phone bar still says Dashboard, so this screen is the first thing every telecaller may see instead of the call queue.  
Scores: 4, 5, 4, 3, 4, 5, 3, 3, 4, 4, 4, 5, 5, 4. **Overall 4.**  
Priority: **Critical** for telecaller (wrong home), **High** for admin.  
Mobile layout: role-specific home. Telecaller home is the queue (MOB-020), not this grid. Admin home: four KPIs in a 2-column grid, the rest in a horizontal snap row. Recent items as cards. Filters in a bottom sheet.

### MOB-010 Sales dashboard

Embedded sales metrics and tables (`DataTable` hits inside the sales bloc file: 2).  
**Overall 4.** Priority: High. Replace tables with person cards. Keep three numbers above the fold: my leads, visits, won.

### MOB-011 Properties

Purpose: find and act on inventory.  
Layout: header KPIs (4 `CRMKPICard`), donut charts (`DonutChart3DPainter`), `DataTable` (1), 9 dialogs, 4 popup menus, search and filters. `chartCardWidth` changes when `isMobile` is true, so charts shrink rather than change pattern.  
Mobile problem: chart row plus table is a desktop inventory console.  
Scores: 4, 4, 4, 4, 4, 4, 3, 3, 3, 4, 4, 4, 4, 4. **Overall 4.**  
Priority: **Critical.**  
Header: search field that expands full screen. Content: one property card (photo, price, BHK, area, locality). Actions: call and share on the card; edit and delete inside the detail. Filters: bottom sheet with sticky Apply. Charts: one compact donut behind a “Mix” chip, not beside the list.

### MOB-012 Property detail

Purpose: read one listing and contact.  
Layout: `BuildPropertyDetailWidget` in `drawers.dart` (large), image slider, zoom viewer, video slider, horizontal arrow scroller. Opened outside the shell via `MobileSystemBackHandler`.  
Mobile problem: detail is built as a wide panel. Horizontal amenity/investment strips (`_ArrowedHScroll`) assume a mouse.  
Scores: 5, 5, 4, 5, 4, 5, 4, 4, 4, 5, 4, 4, 5, 4. **Overall 4.**  
Priority: **Critical.**  
Header: gallery, price, locality. Content: facts in a two-column definition list, amenities as chips, remarks collapsed. Sticky bar: Call, WhatsApp, Share. Edit in the app bar. Pinch-zoom only inside the gallery.

### MOB-013 Add/edit property

10 `showDialog`, 9 `AlertDialog`, many `TextField`s. Sections for media, price, configuration, location.  
Mobile problem: multi-section desktop form with confirm dialogs stacked on the keyboard.  
**Overall 3.** Priority: **Critical.**  
Wizard of 4 steps: Basics (type, BHK, price), Location, Media, Details. Sticky Next. One error under the field. Unsaved back asks in a bottom sheet, not an alert.

### MOB-014 Property search / shell search

`/search` is a route. Property search screen exists. Shell also has a search field.  
**Requires runtime verification** which search is wired to `/search`.  
**Overall 4.** Priority: High. One full-screen search: recent queries, results as the same property card, clear in the field, debounce already expected. No separate search button.

### MOB-015 Recycle bin

2 `DataTable`, 4 `AlertDialog`.  
**Overall 4.** Priority: Medium. Cards with Restore and Delete permanently. Delete stays a bottom sheet with the property name in the title.

### MOB-016 Requirements (Leads track)

13 dialogs, 9 alerts, 4 popup menus, 4 data tables, 1 bottom sheet. Tabs via `initialTab` / `initialSubTab` / `initialGroup` (rent vs resale and more).  
Purpose: the CRM lead book, not the calling queue.  
Mobile problem: table plus nested tabs. Add-lead and match flows are dialogs (`RequirementStepperDialog`, win-property dialog, PDF dialog).  
**Overall 3.** Priority: **Critical.**  
Header: search and a filter chip row. Content: lead card (name, phone, budget, locality, status). Primary: call. Secondary: open. Match and status change on the detail, not in a table row menu.

### MOB-017 Add/edit requirement

2 dialogs, 3 alerts.  
**Overall 4.** Priority: High. Same wizard pattern as property, fewer steps: Contact, Need, Budget and area. Telecaller “add lead” should be this short form, not the full admin form.

### MOB-018 / MOB-019 Public share

No shell. Must work on a customer’s phone.  
**Overall 5** static. Priority: High. Same property card and detail as MOB-012, without CRM chrome. Call and WhatsApp only.

### MOB-020 Campaign / calling leads

The largest screen. View modes in code: `active`, `followups`, `not_interested`, `archive_listed`, `archive_requirements`, `listed`. Locked source for Meta (`Meta Ads`), Housing (`Housing.com`), and each portal name. 21 dialogs, 28 `AlertDialog` constructors, 5 popup menus, 1 `DataTable`.  
Purpose: telecaller disposition and admin campaign review.  
Mobile problem: one screen owns queue, archives, filters, column layout, and dialogs. Horizontal density is the core defect.  
Scores: 3, 3, 3, 3, 3, 4, 2, 2, 3, 3, 3, 4, 4, 3. **Overall 3.**  
Priority: **Critical.**  
Split by route that already exists: Calling (active), Follow-ups, CNR (already `/telecaller/cnr`), Callbacks (already `/telecaller/callbacks`). Do not keep archives in the same scroll. Card: name, phone, source, status. Sticky outcome bar after the call: CNR, Callback, Not interested, Picked up. Remark is one field, not a dialog chain.

### MOB-021 / MOB-022 Campaign drilldown pages

Opened from campaign totals.  
**Overall 4.** Priority: Medium. They should be the same lead card list with a title, not a second table.

### MOB-023 to MOB-027 Connections and portal builder

Connections: 3 bottom sheets, 6 dialogs, 6 alerts. Portal wizard: 8 steps, credential dialog, dynamic rows.  
Admin-only. Low frequency, high complexity.  
**Overall 4** on phone. Priority: Medium.  
Keep the wizard full screen. One column. Secret fields stay masked. Test result is a summary card, not a wide table. Do not put this in bottom navigation.

### MOB-028 Callbacks / MOB-029 CNR

Separate routes and sidebar items. Implemented in `telecaller_callbacks_screen.dart` (`TelecallerCallbacksScreen`, `TelecallerCnrScreen`) with dialogs.  
**Overall 4.** Priority: **Critical** because they are off the phone bar.  
They should be bottom-nav or a segmented control on the telecaller home: Queue | Callbacks | CNR. Card shows due time and phone. One tap calls. One tap completes.

### MOB-030 Telecaller dashboard widget

Follow-up card. Data path was fixed earlier to read `scheduledFollowups`.  
**Overall 5.** Priority: High. This card belongs at the top of the telecaller home, not buried under admin KPIs.

### MOB-032 Lead allocation

Screen class lives in a bloc file. Dialogs for batch size and telecaller detail (3 alerts in the dialog, 4 in the bloc).  
**Overall 4.** Priority: High for admin, hidden for others.  
Mobile: two capacity cards (name, workload, status), one Allocate button, a full-screen confirm with the count. No wide monitor table.

### MOB-034 / MOB-035 Employees

Users list: 3 KPI cards, 2 dialogs. Detail: **13** `CRMKPICard` uses.  
**Overall 3** on the detail. Priority: Medium.  
List is people cards. Detail: identity header, then four KPIs, then a “Performance” list. Thirteen cards on a phone is a report, not a profile.

### MOB-036 to MOB-039 Libraries

Rental and resale: 4 KPI cards, 4 popup menus, 4 dialogs each. Service agents: 7 dialogs, 1 table, 3 menus.  
**Overall 4.** Priority: Medium. Same card pattern as properties. Libraries are reference data; they sit under More.

### MOB-040 to MOB-046 Reports

Sections on disk: business insight, trend, growth, conversion, funnel, call performance, follow-up, lead source, lead status pipeline, team ranking, telecaller leads table, campaign and leads KPI drilldowns.  
Sales report and property reports are placeholders. Lead metrics has both a real screen and a placeholder class.  
Charts are custom painters and section widgets, not a chart package (no `fl_chart` import).  
Mobile problem: filter bars (`report_date_filter_bar`, `report_global_filters_bar` with a bottom sheet) sit above wide sections and a telecaller table. KPI expand and lead drilldown are dialogs with `DataTable`.  
Scores: 4, 4, 3, 4, 3, 4, 2, 3, 3, 4, 3, 4, 4, 3. **Overall 3.**  
Priority: High.  
Phone: date chip, one KPI stack, tap opens a **full-screen list** (not a dialog table). Charts become a single full-width card, 200px tall, no legend beside the plot. Export moves to the app bar menu. Placeholders get a plain empty state, not a fake report.

Chart surfaces counted as 11:

1. Dashboard status pie  
2. Properties donut row  
3. CRM donut widget  
4. KPI sparkline on `CRMKPICard`  
5. Trend section  
6. Growth comparison  
7. Conversion funnel  
8. Lead source  
9. Call performance  
10. Lead status pipeline  
11. Follow-up analysis  

Team ranking is a table, not a chart.

### MOB-047 to MOB-051 Settings

Settings uses `_activeSection` and a selector (profile, upload limits, and further ids in the same file). Sub-routes: audit logs (table), location config (tabs via `SingleTickerProviderStateMixin`, 3 dialogs, 2 sheets), KPI config, sync debug. Permission matrix is a card with its own table and dialogs.  
**Overall 4.** Priority: Medium.  
Mobile settings is a list of rows (Profile, Security, Notifications, Matching, Uploads, Locations, KPIs, Permissions). Each row is a full screen. Audit logs: card per event, filter sheet. Do not show the matrix as a grid.

### MOB-052 Profile

Popup menu, MFA card. Sidebar also shows name, role, avatar.  
**Overall 5.** Priority: Medium.  
One profile screen: avatar, name, role, phone, email. Rows: Security, MFA, Notifications, Theme, Logout. Logout is destructive and last. MFA enrollment is a full screen, not a dialog, when the keyboard is needed.

### MOB-053 / MOB-054 Messages

Route `/messages` plus a messenger dialog. **Requires runtime verification** whether the shell opens the dialog or the route first.  
**Overall 4.** Priority: Medium. Messages are a full screen under More. The dialog should not be the only inbox.

### MOB-055 Integration screen

Route redirects to campaign leads. The screen file still has 9 dialogs and a table. **Deprecate** the screen if no other navigator pushes it. **Requires runtime verification** of `Navigator.push` to `IntegrationScreen`.

### MOB-056 to MOB-062 Clients, pipeline, owners, builders

Reachable widgets, unreachable routes. Lists use KPI strips and at least one table each (clients, owners, builders).  
**Overall n/a for mobile navigation.** Recommendation: **Deprecate** the routes’ targets or restore a real route. Do not redesign three hidden modules before that decision.

### MOB-063 Home / MOB-064 Placeholder

Not on the live router. **Deprecate** after a reference check.

### MOB-078 Phone bar

Four labels plus a center action at index 2. Height 64. Labels will collide below 360px (`isNarrow`).  
**Overall 4.** The bar is the right pattern and the wrong contents. See section 34.

---

## 7. Desktop-only components

| Component | Where | Decision |
|---|---|---|
| `ModernSidebar` full label list | shell | **Replace** on width &lt; 700 with bottom nav + More |
| `_buildSidebarContent` | app_shell | **Deprecate** (no callers) |
| Campaign `DataTable` and column customizer | MOB-020 | **Replace** with cards |
| Report drilldown tables | MOB-073 and campaign KPI drilldowns (6 `DataTable` hits) | **Replace** with full-screen lists |
| Telecaller leads table | reports | **Replace** with cards |
| Permission matrix table | settings | **Redesign** as a list of toggles |
| Eight-up KPI row | dashboard | **Adapt** to 2-column plus carousel |
| Properties donut row | MOB-011 | **Adapt** to one optional chart |
| Portal field-mapping rows | MOB-026 | **Adapt** to stacked cards, not a 3-column wrap |
| Employee 13-KPI grid | MOB-035 | **Redesign** to 4 plus a list |
| `AlertDialog` forms | property, campaign, requirements | **Replace** with full pages or sheets |
| Horizontal `_ArrowedHScroll` | property detail | **Replace** with wrapping chips |

---

## 8. KPI inventory

Dashboard tiles (custom, not all `CRMKPICard`):

| KPI ID | KPI | Screen | Role | Layout now | Mobile problem | Pattern |
|---|---|---|---|---|---|---|
| KPI-01 | Available Inventory | Dashboard | SA AD SL | header tile | competes with 7 siblings | 2-column card |
| KPI-02 | Total Leads | Dashboard | SA AD SL | header tile | same | 2-column card |
| KPI-03 | Telecallers | Dashboard | SA AD | header tile | low value on a phone | carousel |
| KPI-04 | Leads Allocated | Dashboard | SA AD | header tile | same | 2-column card |
| KPI-05 | Assigned to Sales | Dashboard | SA AD SL | header tile | same | carousel |
| KPI-06 | Site Visits Done | Dashboard | SA AD SL | header tile | good sales KPI | 2-column card |
| KPI-07 | Deal Won | Dashboard | SA AD SL | header tile | good | 2-column card |
| KPI-08 | Sales Users | Dashboard | SA AD | header tile | org meta, not daily | carousel |
| KPI-09 | Active Requirements | Dashboard secondary | SA AD SL | compact label | easy to miss | metric row |
| KPI-10 | Deals Won (secondary label) | Dashboard | SA AD SL | duplicate of KPI-07 | two won numbers | merge with KPI-07 |

`CRMKPICard` construction sites (43), typically a 3–4 card strip:

| KPI ID | Screen | Count on that file | Pattern |
|---|---|---|---|
| KPI-11 | Properties | 4 | one row of 2, rest optional |
| KPI-12 | Clients (hidden route) | 3 | do not surface until route returns |
| KPI-13 | Owners (hidden) | 3 | same |
| KPI-14 | Builders (hidden) | 3 | same |
| KPI-15 | Pipeline (hidden) | 3 | same |
| KPI-16 | Rental library | 4 | 2-column |
| KPI-17 | Resale library | 4 | 2-column |
| KPI-18 | Service-agent library | 1 | single card |
| KPI-19 | Users list | 3 | 2-column |
| KPI-20 | Employee detail | 13 | 4 visible, rest in a list |
| KPI-21 | Overall business insight | 2 | stack; tap opens drilldown list |

Report sections add further metrics inside trend, funnel, call, source, and pipeline widgets. Their individual labels are data-driven. **Requires runtime verification** to freeze the exact caption list from the API payload.

Each KPI should show: one number (at least 28px), one label (13px), an optional delta, no sparkline on the phone home. Tap goes to a list. Loading is a skeleton block, not a spinner in the number. Error is “Couldn’t load” plus retry on the card.

---

## 9. Property UX

| View | Optimal mobile structure |
|---|---|
| List MOB-011 | Photo 96px, price, BHK, area, locality, status chip. No table. |
| Card | One tap opens detail. Call is a separate icon button, 48px. |
| Grid | Do not use a multi-column grid below 700px. One column. |
| Detail MOB-012 | Gallery, price, facts, map/locality, amenities, remarks. |
| Gallery | Full-bleed, page dots, pinch zoom. |
| Add / edit | 4-step wizard. |
| Filters | Bottom sheet, chips for active filters, Clear and Apply sticky. |
| Search | Full-screen. |
| Matching | From a lead, a sheet of matching cards, not a new table. |
| Contact | Sticky Call / WhatsApp. |
| Share | System share sheet. |
| Delete | Bottom sheet, destructive button, named property. |
| Bin | Cards, Restore primary, Delete secondary. |

Above the fold on a listing: photo, price, locality, BHK. Below: area, furnishing, amenities, remarks. One tap: call and open. Never bury the phone number behind More.

---

## 10. Lead and requirement UX

| Workflow | Where it lives now | Mobile flow |
|---|---|---|
| List | MOB-016 tables and tabs | cards |
| Detail | dialogs inside the list | full page |
| Add | stepper dialog MOB-075 | 3-step page |
| Edit | same form | same page |
| Status | menus and dialogs | sticky outcome bar |
| Assignment | allocation screen and campaign dialogs | admin-only sheet |
| Follow-up | campaign `followups` mode and telecaller card | its own segment |
| Callback | MOB-028 | segment |
| CNR | MOB-029 | segment |
| Not interested | campaign mode plus reason dialog | outcome + one reason sheet |
| Site visit / negotiation / won / lost | requirement dialogs including MOB-076 | status sheet, then property pick if won |
| Call history, remarks, timeline | inside campaign and requirement UI | a timeline section on the lead page |

Minimum taps today cannot be measured on a device in this pass. From the code path, a disposition is: open campaign list → open row → dialog → confirm. That is at least 4 taps before the outcome is saved, plus typing. Target: open card (1), tap outcome (2), optional remark, save (3).

---

## 11. Telecaller

| Step | Current surface | Current taps (static) | Target taps |
|---|---|---|---|
| See queue | Sidebar “My Calling Leads”, not the phone bar | 2 (open drawer, tap) | 0 (it is the home tab) |
| Open lead | row or dialog | 1 | 1 |
| Call | button inside the screen | 1 | 1 on the card |
| Outcome | dialog | 2 | 1 |
| Callback time | another picker dialog | 2 | 1 sheet |
| Not interested reason | dialog | 2 | 1 sheet |
| Remark | dialog field | 2 | same screen |
| Back to queue | close dialogs | 1–2 | 0 after save |

Current time and target time: **Requires runtime verification**. Design target is under 20 seconds for CNR with no remark, under 40 seconds for a callback with a note.

Availability, break, and offline exist in allocation data (`telecaller_availability`) and the admin monitor. A telecaller control for break/offline was **not** found as its own screen in this pass. **Requires runtime verification** on the telecaller dashboard. If it is missing, add one status control on the telecaller home, not a settings page.

---

## 12. Sales

Priority order on a phone:

1. My leads (MOB-016 filtered to the user)  
2. Lead detail and property match  
3. Add/edit property (wizard)  
4. Site visit and won, from the lead  
5. Profile  

Dashboard KPIs are secondary. Recycle bin and settings sit under More. Pipeline screen is currently stranded behind the clients redirect. **Investigate** before building a sales pipeline mobile view; the live pipeline may only be requirement status.

---

## 13. Admin

Keep on the first screen: four KPIs (leads, allocated, visits, won) and anything that needs a decision today.  
Move one level down: telecaller and sales performance, source mix, portal health.  
Move under More: user management, KPI configuration, permission matrix, audit logs, location config, portal builder.

Lead allocation stays one tap from More for admins, not from the telecaller bar.

---

## 14. Reports

| Report | Desktop now | Mobile |
|---|---|---|
| Overall insight | sections stacked, some tables | KPI stack, one chart card, drilldown list |
| Telecaller | table of leads | cards grouped by person |
| Sales | placeholder | empty state until the report exists |
| Lead metrics | charts and filters | same as insight, fewer charts |
| Super-admin metrics | extra route | same pattern, org switcher in a sheet |
| Property reports | coming soon | empty state |
| Drilldowns | dialog + `DataTable` | full-screen cards |
| Filters | bars and one sheet | one filter sheet |
| Export | popup menu | app bar menu |
| Print | not a first-class mobile action | omit on phone |

Do not scale the donut down until the legend wraps into unreadably small type. One chart, full width, legend underneath.

---

## 15. Tables

| Table | File evidence | Choice | Why |
|---|---|---|---|
| Campaign leads | `campaign_leads_screen.dart` 1 `DataTable` plus a custom column system | **A cards** | This is the calling queue. A table hides the phone number. |
| Properties | 1 `DataTable` | **A cards** | Photo and price matter more than columns. |
| Requirements | 4 | **A cards** | Same as leads. |
| Recycle bin | 2 | **A cards** | Few columns, destructive actions. |
| Report drilldowns | lead drilldown, campaign KPI drilldowns (6), business insight, leads page KPI | **C priority columns + list page** | Admins sometimes need many fields; show name, phone, status, then a detail page. |
| Telecaller report table | `telecaller_leads_table.dart` | **A cards** | Rank and outcome, not a grid. |
| Team ranking | 1 | **A cards** | A ranked list is enough. |
| Clients, owners, builders | 1 each | **A cards** if the module returns; otherwise leave | Routes are dead. |
| Users | list KPIs; detail is cards already | **A cards** | People are not rows. |
| Audit logs | audit screen dialogs; table-like density | **C** | Time, actor, action on the card; raw payload on detail. |
| Permission matrix | 1 `DataTable` | **D compact list of switches** | A matrix does not scroll well in either axis. |
| Service-agent library | 1 | **A cards** | Directory. |
| Sales dashboard | 2 | **A cards** | Same as ranking. |
| Libraries rental/resale | menus more than tables | **A cards** | Match properties. |

No table should use horizontal scroll as the primary layout (option B). Option B is only acceptable inside the portal “advanced JSON” preview, which is admin-only and rare.

---

## 16. Dialogs and bottom sheets

Pattern for the 152 dialog sites:

| Kind | Count signal | Mobile type | Sticky action | Dismiss |
|---|---|---|---|---|
| Confirm delete / logout | many of the 118 alerts | bottom sheet, max 40% height | destructive + cancel | tap scrim cancels |
| Form inside a dialog (property, lead, campaign) | campaign 21, property 10, requirements 13 | **full page** | save | back confirms if dirty |
| KPI drilldown | `kpi_drilldown_dialogs.dart` 12 | **full-screen list** | close | system back |
| MFA | 1 verify + profile card | full screen when typing | verify | back |
| PDF / share options | 1 named dialog | bottom sheet, 50% | primary share | scrim |
| Date/time | 34 picker call sites | platform picker | done | platform |
| Filter | report global sheet, dashboard filter dialogs | bottom sheet, 85%, scroll body | Apply | scrim does not apply |
| Portal credential | 1 alert | bottom sheet | save | scrim |
| Notes / schedule on dashboard | dashboard dialogs | bottom sheet | save | dirty confirm |
| Messenger | 1 dialog | full screen | send in the composer | back |
| Update app | 1 | dialog is acceptable | update | cannot dismiss if forced |

Sheets that already exist (14) should stay sheets. Do not also show an `AlertDialog` for the same task.

Popup menus (30): on phone, a popup anchored to a 24px icon is a miss target. Use a bottom sheet titled with the record name when the menu has more than three items. Keep a popup only for the report export menu and the profile overflow.

---

## 17. Forms

| Form | Fields (static) | Columns now | Mobile pattern |
|---|---|---|---|
| Login | email, password, MFA | 1 | single page |
| Reset password | new password | 1 | single page |
| Property add/edit | large; media, price, location, facts | multi-section page | 4-step wizard |
| Requirement add/edit | contact, budget, area, type | page plus dialogs | 3-step wizard |
| Portal wizard | 8 steps already | mixed wrap | keep wizard, one column |
| Location config | cities/areas | tabs | list + sheet to add |
| Settings upload limits and match threshold | sliders | settings page | one section screen |
| Profile / MFA | identity and secrets | cards | one security screen |
| Campaign remark / NI reason | short | dialog | sheet |
| Employee edit | inside users dialogs | dialog | full page |
| Client / owner / builder forms | full screens | hidden routes | do not ship until routes exist |
| Credential row | name, key, type, value | dialog | sheet |

Validation must sit under the field. Keyboard type: phone for phone, number for budget and area, email for email. Focus order follows visual order. Save is sticky. Cancel is text. Dirty back is a sheet.

---

## 18. Settings and profile

Settings information architecture on mobile:

1. Account and profile  
2. Security and MFA  
3. Appearance  
4. Notifications (**Requires runtime verification** of a dedicated notifications section; a full notifications settings screen was not found)  
5. Matching threshold  
6. Upload limits  
7. Locations  
8. KPI configuration  
9. Permissions (admin)  
10. Audit logs (super admin)  
11. Sync debug (super admin, bottom of the list)

Profile shows avatar, name, role, contact. Logout is the last row, destructive color, confirm sheet.

---

## 19. Search and filters

| Search | Recommendation |
|---|---|
| Shell header search | On phone, the field is not in the header. A search icon opens full-screen search. |
| `/search` and `PropertySearchScreen` | Merge with shell search. One implementation. |
| Campaign lead search | Inside the queue, persistent under the app bar. |
| Requirements search | Same. |
| Library search | Same card search. |
| Employee search | Inline on the people list. |

No recent-search store was confirmed. **Requires runtime verification.** If absent, do not invent history in the first release; show an empty hint instead.

Filters:

| System | Mobile |
|---|---|
| Dashboard filter dialogs | bottom sheet |
| Property filters | bottom sheet, chips above the list |
| Campaign column filters | bottom sheet; columns themselves go away |
| Report date bar | one chip that opens the sheet |
| Report global bar | same sheet, not a second bar |
| Audit log filters | sheet |

Active filters are chips with a remove icon. Clear all is text in the sheet. Apply is sticky. Changing a chip applies immediately when there are three or fewer filters; otherwise Apply.

---

## 20. Loading, empty, error, success

| State | Use |
|---|---|
| First load of a list | skeleton cards (shimmer hits already exist; standardize on them) |
| Refresh | the existing `RefreshIndicator` (10 sites) plus the skeleton only if the list is empty |
| Button action | button spinner, not a page spinner |
| Empty queue | “No leads in this queue” and the next queue to check |
| Empty properties | “No properties yet” and Add property |
| Empty search | “No matches” and Clear |
| Error | one sentence and Retry. Do not show Dio or exception text (the not-found page currently can) |
| Success | snackbar only for background saves; navigate back with the new card visible for creates |

---

## 21. Touch, accessibility, gesture, orientation

Touch: phone bar items at height 64 are acceptable. Icon-only popup triggers in campaign, properties, and libraries are not. Target 48×48 with 8px gap.  
Type: body at least 16px in forms, 14px in cards. KPI numbers at least 28px.  
Contrast and semantics: **Requires runtime verification.** Many icon buttons need tooltips that are already present on the collapsed sidebar; phone icons need the same labels for screen readers.  
Destructive: filled error color, never next to the primary as an equal button.  
Gestures to keep: pull to refresh on queues and property list; horizontal swipe only inside the gallery; bottom sheet drag. Do not add swipe-to-delete on leads.  
Orientation: portrait for queues, forms, and detail. Landscape may keep reports as a single column still; do not build a landscape dashboard. The manifest does not lock orientation (`configChanges` includes orientation). Large-screen orientation lock is an Android 16 issue for the Play build and **Requires runtime verification** on a tablet.

---

## 22. Performance UX risks

- `campaign_leads_screen.dart` and `requirements_screen.dart` and `properties_screen.dart` are very large widgets. A phone rebuilds a lot of off-screen desktop layout. Risk: jank when opening the queue.  
- Lists request `limit: 1000` in campaign lead fetch (`integration_service.dart`). Risk: memory and a long first paint. Paginate on mobile.  
- Property images use `cached_network_image` in the project; galleries still need a bounded decode. **Requires runtime verification** of full-size downloads.  
- Charts are custom painters. They are cheap if the data set is small and expensive if they repaint with the parent. Isolate them.  
- Offline: local Isar exists. The mobile empty/error copy must not claim the network is required when a cache exists. **Requires runtime verification** per screen.  
- SnackBar volume (695 constructions) means errors can stack. One error surface.

---

## 23. Recommended navigation

Phone bottom navigation by role:

| Role | Tabs |
|---|---|
| Telecaller | Queue, Callbacks, CNR, Leads, More |
| Sales | Leads, Properties, Visits, More |
| Admin / Super Admin | Home, Leads, Properties, Reports, More |

More holds: profile, settings, library, bin, messages, employees, allocation, campaign connections, audit logs.

Center `+`:

- Telecaller: Add lead (short form) only.  
- Sales: Add property, Add lead.  
- Admin: Add property, Add lead. Not “add integration”.

Do not use the current five-slot bar (Dashboard, Properties, +, Leads, Profile) for telecallers. It optimizes browsing, and their job is calling.

---

## 24. Design system (recommendation only)

Use existing tokens in `lib/core/design_system/tokens/` (`CRMColors`, `CRMTypography`, `CRMSpacing`, `CRMBorderRadius`). Do not invent a second palette.

| Token | Mobile rule |
|---|---|
| Color | Primary for the one main action. Error for destructive. Success for won/connected. Surface from `cardBgOf`. |
| Type | Display 28 for KPI numbers. Title 20 for screen titles. Body 16 for forms. Caption 13 for meta. |
| Space | 4, 8, 12, 16, 24, 32. Screen padding 16. Card padding 16. |
| Radius | Cards 16 (already used). Buttons 12. Sheets 16 top corners. Inputs 12. |
| Elevation | Cards: border, not a heavy shadow. Sheets: scrim 40%. |
| Buttons | Primary filled, secondary outline, destructive filled error, text for cancel, icon 48. |
| Inputs | Filled surface, 56 tall, error text below, disabled 40% opacity. |
| Cards | Property, lead, KPI, report, user, activity. One radius, one padding. |
| Status chips | One height 28, semantic color, no rainbow per screen. |

---

## 25. Pattern library

| Pattern | Use | Do not use | Size |
|---|---|---|---|
| Mobile app bar | Title, one search icon, one overflow | Tab rows inside the bar | 56 plus status |
| Bottom navigation | 4 or 5 role tabs | More than 5, or admin tools | 64 plus safe area |
| Search bar | Persistent on queues | On wizards | 48 |
| Filter bar | Chips of active filters | A full desktop filter row | 40 |
| Filter sheet | 3 or more filters | A single toggle | max 85% height, scroll, sticky Apply |
| KPI card | One number | Charts inside the card on a phone | min 120 wide in a 2-column grid |
| Lead card | Queue and track | Tables | full width, min 88 tall |
| Property card | Inventory and match | Grids of tiny tiles | image 96, text beside |
| User card | Employees and ranking | KPI soup | 72 tall |
| Timeline | Remarks and calls | A second table | full width |
| Status chip | State | Long sentences | 28 tall |
| Sticky CTA | One primary | Two primaries | 56, above the gesture inset |
| Bottom sheet | Confirm, short form, filters | 15-field forms | 40–90% |
| Full-screen form | Property, lead, MFA | A yes/no question | whole route |
| Confirm dialog | Only blocking legal or session expiry | Routine delete | prefer sheet |
| Empty state | Title, reason, one action | A blank scaffold | centered |
| Error state | Sentence and Retry | Exception strings | replaces the list |
| Skeleton | List and KPI first load | Buttons | match the card |
| Chart card | One plot | Side-by-side donuts | width 100%, height 200 |
| Section header | 13px label | Giant dividers | 16 inset |
| Expandable section | Amenities, raw portal JSON | The phone number | collapsed by default |
| Gallery | Listing photos | Avatars | 16:10, paging |

---

## 26. Information hierarchy (global)

Seen immediately: the next person or property, their phone or price, and the status.  
Below the fold: remarks, history, amenities, secondary KPIs.  
Collapsed: raw JSON, portal config, audit payload, chart legends.  
Behind More: settings, libraries, bin, messages, employees, reports for telecallers.  
One tap: call, the role’s home queue, the primary create.  
Two taps: filters, a specific report, edit.  
Never multi-step: calling the lead that is already on screen, and confirming a destructive delete without showing the name.

---

## 27. Action priority (global)

| Level | Examples |
|---|---|
| Primary | Call, Save, Apply filters, Allocate, Next wizard step |
| Secondary | Share, Edit, Follow-up, Open report |
| Tertiary | Export, column layout, sync debug, portal JSON |
| Destructive | Delete property, delete lead, logout, disable MFA, force activate without a test |

---

## 28. Workflow efficiency

| Workflow | Now (static) | Target |
|---|---|---|
| Telecaller: lead → call → outcome | drawer + campaign screen + dialog | home card, call, one outcome |
| Sales: lead → match → property → visit | requirements dialogs | lead page, match sheet, property page, status sheet |
| Admin: dashboard → KPI → lead | KPI then dialog table | KPI then full-screen list |
| Property: list → detail → contact | list (table or card) then detail | card → detail with sticky call |
| Report: filter → drilldown → export | filter bar + dialog table + menu | sheet, list page, app bar export |

Exact tap counts on a device: **Requires runtime verification**.

---

## 29. Duplicates

| Item | Recommendation | Why |
|---|---|---|
| `_buildSidebarContent` vs `ModernSidebar` | **Deprecate** the unused builder | Two information architectures |
| `IntegrationScreen` vs campaign leads | **Deprecate** integration route (already redirects) | Second inbox |
| `LeadMetricsPlaceholderScreen` vs `LeadMetricsScreen` | **Deprecate** placeholder if unreferenced | Two endings for one report |
| Sales report and property report placeholders | **Keep** as empty states until data exists | Honest |
| Clients, owners, builders screens | **Investigate** then merge into leads/properties or delete later | Routes already redirect |
| `HomeScreen` | **Deprecate** if unreferenced | Not in the router |
| Dashboard “Deal Won” and “Deals Won” | **Merge** | Two labels, one idea |
| Campaign leads used for Meta, Housing, portals, and telecaller queue | **Keep** one list component, **replace** the chrome per mode | Same data, different jobs |
| Phone bar vs sidebar | **Replace** phone contents per role | They disagree today |

---

## 30. Priority matrix

| ID | Screen | Issue | Severity | Impact | Recommendation |
|---|---|---|---|---|---|
| P0-1 | MOB-020 | Calling queue is a desktop campaign page | P0 | Telecaller cannot work quickly on a phone | Card queue and sticky outcomes |
| P0-2 | MOB-078 | Phone bar omits Callbacks and CNR | P0 | Those queues are hidden | Role-based tabs |
| P0-3 | MOB-011 / MOB-016 | Inventory and leads still center on tables | P0 | Horizontal overflow and tiny hit targets | Cards |
| P0-4 | MOB-013 / MOB-017 | Long forms open through dialogs | P0 | Keyboard covers actions | Full-screen wizards |
| P0-5 | MOB-008 | Telecaller can land on admin KPI dashboard | P0 | Wrong home | Role home |
| P1-1 | MOB-040 | Report drilldowns are dialog tables | P1 | Unreadable numbers | Full-screen lists |
| P1-2 | MOB-012 | Property detail is a wide drawer layout | P1 | Gallery and call are not obvious | Sticky contact, stacked facts |
| P1-3 | MOB-035 | 13 KPI cards on one employee | P1 | Endless scroll | Four, then a list |
| P1-4 | MOB-032 | Allocation is a monitor layout | P1 | Admin cannot allocate comfortably | Two cards and one action |
| P1-5 | Shell | Dead sidebar still in the codebase | P1 | Future edits will change the wrong nav | Remove from the design source of truth |
| P1-6 | Errors | Not-found page can show exception text | P1 | Confusing and noisy | Human copy |
| P2-1 | MOB-026 | Portal wizard wraps many columns | P2 | Admin setup is fiddly | One column |
| P2-2 | MOB-047 | Settings is a desktop section switcher | P2 | Hard to scan | Settings list |
| P2-3 | Libraries | Same density as properties | P2 | Secondary task feels primary | Under More, same cards |
| P2-4 | Search | Several search entry points | P2 | Inconsistent | One full-screen search |
| P2-5 | MOB-056–062 | Hidden modules still compiled | P2 | Design drift | Decide before mobile work |
| P3-1 | Placeholders | Sales and property reports say coming soon | P3 | Dead ends | Plain empty states |
| P3-2 | Charts | Donuts shrink beside lists | P3 | Decoration over task | Optional single chart |
| P3-3 | Phone bar below 360px | Labels compress | P3 | Clipped words | Icon plus short label |
| P3-4 | Snackbars | Hundreds of call sites | P3 | Stacked toasts | One helper |

P0 issues: **5**. P1: **6**. P2: **5**. P3: **4**.

---

## 31. Implementation order (next phase, not this one)

1. Role homes and bottom navigation (P0-2, P0-5).  
2. Calling queue cards and outcome bar (P0-1).  
3. Property and lead cards (P0-3).  
4. Property and lead wizards (P0-4).  
5. Property detail sticky actions (P1-2).  
6. Report drilldown as a page (P1-1).  
7. Allocation and employee detail (P1-3, P1-4).  
8. Settings list, search, portal one-column (P2).  
9. Empty states and chart simplification (P3).

Do not start with colors. The structure is the defect.

---

## 32. Final scores

| Area | Score |
|---|---|
| Information hierarchy | 4 |
| Readability | 4 |
| Touch | 4 |
| Navigation | 3 |
| Spacing | 4 |
| Typography | 5 |
| Density | 3 |
| Interaction efficiency | 3 |
| Accessibility | 4 (static; contrast **Requires runtime verification**) |
| Visual clarity | 4 |
| Action discoverability | 3 |
| Error handling | 4 |
| Loading | 5 |
| Empty states | 4 |
| **Overall mobile UX** | **4/10** |

---

## 33. Final recommendations

1. Give telecallers a queue home and put Callbacks and CNR on the phone bar.  
2. Stop using tables for leads and properties on widths under 700.  
3. Move create/edit flows out of dialogs into short wizards.  
4. Make property detail a phone page with a sticky call action.  
5. Turn report drilldowns into pages.  
6. Keep one sidebar implementation (`ModernSidebar`) and delete the unused builder from the design.  
7. Leave portal configuration, permissions, and audit logs under More.  
8. Decide the fate of Clients, Owners, and Builders before drawing mobile screens for them.  
9. Standardize skeleton, empty, and error components so Dio messages never reach the UI.  
10. Verify tap counts and contrast on a device before build work; this document is static.

---

## 34. Verification checklist

| Check | Result |
|---|---|
| Router file read | Yes, `app_router.dart` including redirects and public share routes |
| Public `Screen` widgets counted | 53 |
| Public `Page` widgets counted | 5 |
| `TabBar` / `TabBarView` counted | 8 / 2 |
| `showDialog` / `AlertDialog` / `showModalBottomSheet` / `PopupMenuButton` counted | 152 / 118 / 14 / 30 |
| KPI `CRMKPICard` uses counted | 43, plus 10 named dashboard metrics |
| `Form` / portal steps counted | 18 forms, 8 portal steps |
| `DataTable` + `CRMDataTable` counted | 32 + 12 |
| Chart surfaces listed | 11, from painters and report sections |
| Roles | Super Admin, Admin, Telecaller, Sales |
| Major workflows traced in code | Yes, to the widget that owns them |
| Loading / empty / error / permission | Patterns found; per-screen copy **Requires runtime verification** |
| Dead navigation noted | `_buildSidebarContent` has no callers; clients/owners/builders redirect |
| Code modified | No application code. This file is the only deliverable. |

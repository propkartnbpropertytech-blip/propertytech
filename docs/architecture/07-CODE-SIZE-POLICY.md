# PROPKART — CODE SIZE, COMPLEXITY & DECOMPOSITION POLICY
**Version:** 1.0.0  
**Status:** CANONICAL REFACTORING POLICY (STEP 1 FOUNDATION)  
**Date:** October 19, 2026  
**Scope:** Engineering Thresholds & Monolithic File Decomposition Registry  

---

## 1. Architectural Philosophy on Code Size

In a large ERP and CRM system, files exceeding 1,000 lines become anti-patterns:
1. **Context Window Exhaustion:** An AI coding agent or human engineer cannot comprehend or modify the file without loading 10,000–15,000 lines of disparate concerns, increasing hallucination rates and code regressions.
2. **Merge Conflict Magnet:** When five developers edit different parts of `requirements_screen.dart`, git merges become hazardous.
3. **Hidden Coupled Logic:** Mixed concerns (e.g. UI widgets, network retries, and CSV export loops in the same file) prevent unit testability.

### 1.1 Engineering Thresholds

| Metric | Target / Healthy | Warning Level | Strict Architectural Violation |
| :--- | :--- | :--- | :--- |
| **Dart File Length (Flutter)** | $< 350$ lines | $350 - 600$ lines | $> 800$ lines |
| **Node.js File Length (Backend)** | $< 300$ lines | $300 - 500$ lines | $> 600$ lines |
| **Method / Function Length** | $< 30$ lines | $30 - 60$ lines | $> 80$ lines |
| **Cyclomatic Complexity per Function**| $< 8$ | $8 - 15$ | $> 15$ |
| **Number of Dependencies (Imports)** | $< 15$ imports | $15 - 25$ imports | $> 30$ imports |
| **Class Responsibilities** | Single SRP | 2 related concerns | $\ge 3$ mixed concerns |

### 1.2 Decomposition Rule: Responsibility Boundaries, Not Blind Slicing
> **DO NOT blindly chop files into 300-line arbitrary chunks.**  
> Slicing must strictly follow **domain and architectural responsibility boundaries**:
> - Presentation Widgets $\rightarrow$ `presentation/widgets/`
> - Dialogs & Bottom Sheets $\rightarrow$ `presentation/dialogs/`
> - State & Event Handling $\rightarrow$ `presentation/bloc/`
> - Domain Business Calculations $\rightarrow$ `application/usecases/` or `domain/`
> - Network & Storage Operations $\rightarrow$ `data/datasources/`

---

## 2. Forensic Catalog of Oversized Files & Decomposition Plans

### 2.1 Top 12 Monolithic Files in Flutter (`lib/`)

#### 1. `lib/features/requirements/screens/requirements_screen.dart` (15,925 lines)
```text
Current Responsibility: Monolithic screen containing the entirety of buyer/tenant requirements UI, filtering, matching, sharing, data-table pagination, WhatsApp messaging, and PDF exports.
Responsibilities Found:
  1. Main layout, filter bars, view mode toggle (Table vs Card).
  2. Requirement matching algorithm execution and score presentation.
  3. Direct Isar and Dio data fetching and cache syncing.
  4. WhatsApp message template generation and direct url_launcher launching.
  5. Multi-property PDF catalog generation and download handling.
  6. Detail drawer and edit modal widgets.
  7. Client-side KPI counter calculations.
Recommended Modules:
  - `presentation/screens/requirements_screen.dart` (Thin shell, <400 lines)
  - `presentation/widgets/requirements_table_view.dart` & `requirements_card_view.dart`
  - `presentation/widgets/requirements_filter_bar.dart`
  - `presentation/dialogs/requirement_detail_dialog.dart`
  - `application/usecases/export_requirement_pdf_usecase.dart`
  - `application/usecases/generate_whatsapp_pitch_usecase.dart`
Migration Priority: P0 (Extreme maintainability risk)
Dependencies: `RequirementsBloc`, `PropertiesRepository`, `DioClient`, `LocalRepositories`
Risk: High (Critical core business workflow)
```

#### 2. `lib/features/campaign/screens/campaign_leads_screen.dart` (13,121 lines)
```text
Current Responsibility: Monolithic screen handling the entire Meta Ads & Housing.com lead inbox, telecaller reassignments, status transitions, followups, and Excel exports.
Responsibilities Found:
  1. Tab navigation across Campaign sources (Meta, Housing, Webhook, Portal).
  2. Realtime lead table with inline disposition editing.
  3. Telecaller reassignment modals and workload verification.
  4. Excel workbook generation using `excel` package on the main isolate.
  5. Direct Dio network mutations and service calls.
  6. Client-side date boundary filtering.
Recommended Modules:
  - `presentation/screens/campaign_leads_screen.dart` (Scaffold & tab controller, <350 lines)
  - `presentation/widgets/campaign_leads_data_table.dart`
  - `presentation/widgets/campaign_source_tabs.dart`
  - `presentation/dialogs/reassign_lead_dialog.dart`
  - `presentation/dialogs/campaign_disposition_sheet.dart`
  - `application/usecases/export_campaign_leads_excel_usecase.dart`
Migration Priority: P0 (Extreme maintainability risk)
Dependencies: `CampaignLeadsBloc`, `IntegrationService`, `UsersRepository`, `DioClient`
Risk: High (Primary lead generation interface)
```

#### 3. `lib/features/dashboard/widgets/kpi_drilldown_dialogs.dart` (7,269 lines)
```text
Current Responsibility: Contains all KPI drill-down popup modal dialogs, data tables, and client-side aggregation filters for dashboard cards.
Responsibilities Found:
  1. Drilldown modal for 20+ distinct KPI cards (Total Intake, Allocated, Lost, Visits, Converted).
  2. Custom data table rendering for each drilldown type.
  3. Client-side search and sorting routines.
Recommended Modules:
  - `features/dashboard/presentation/dialogs/kpi_drilldown_shell.dart` (Generic container, <250 lines)
  - Individual drilldown content builders in `features/dashboard/presentation/dialogs/drilldowns/` (e.g. `lead_intake_drilldown.dart`, `site_visit_drilldown.dart`, `lost_leads_drilldown.dart`).
Migration Priority: P1
Dependencies: `DashboardBloc`, `DashboardSummary`, `CRMDataTable`
Risk: Low (Read-only presentation modals)
```

#### 4. `lib/features/properties/screens/properties_screen.dart` (6,860 lines)
```text
Current Responsibility: Property inventory screen containing list/grid views, complex search/filter dialogs, map interactions, and brochure downloads.
Responsibilities Found:
  1. Main inventory scaffold, app bar actions, view mode toggle.
  2. Filter drawer containing 15+ filter criteria (BHK, price slider, locality, furnishing).
  3. Card/Table item rendering and quick status toggling.
  4. Direct storage queries to `PropertyLocalRepository`.
Recommended Modules:
  - `presentation/screens/properties_screen.dart` (Thin coordinator, <350 lines)
  - `presentation/widgets/property_card_item.dart` & `property_table_item.dart`
  - `presentation/widgets/property_filter_drawer.dart`
  - `presentation/widgets/property_quick_actions.dart`
Migration Priority: P1
Dependencies: `PropertiesBloc`, `PropertiesRepository`, `CRMMapPicker`
Risk: Medium (Central operational inventory screen)
```

#### 5. `lib/features/dashboard/widgets/inventory_demand_analytics_section.dart` (4,370 lines)
```text
Current Responsibility: Renders demand vs inventory analytics charts, supply deficit gauges, and locality breakdown matrices.
Responsibilities Found:
  1. Chart drawing routines, canvas sizing, legend layout.
  2. Custom mathematical transformations for supply/demand ratios.
  3. Data table displaying unmatched requirements per locality.
Recommended Modules:
  - `presentation/widgets/analytics/demand_analytics_container.dart` (<300 lines)
  - `presentation/widgets/analytics/supply_demand_chart.dart`
  - `presentation/widgets/analytics/locality_deficit_table.dart`
Migration Priority: P2
Dependencies: `DashboardSummary`, `AppColors`, `AppTypography`
Risk: Low (Reporting visualization)
```

#### 6. `lib/features/integration/services/integration_service.dart` (4,185 lines)
```text
Current Responsibility: Massive frontend service handling Meta integration, lead parsing, CSV/Excel parsing, peer transfer history, webhook configuration, and local sync staging.
Responsibilities Found:
  1. HTTP client calls to `/api/v1/integrations/*`.
  2. Client-side CSV/Excel parsing algorithms.
  3. Lead understanding and raw JSON text extraction.
  4. Local transfer history merging.
Recommended Modules:
  - `data/datasources/remote/integration_api_service.dart` (Pure HTTP, <400 lines)
  - `domain/services/lead_text_parser.dart` (Pure Dart parser, <300 lines)
  - `application/usecases/import_leads_file_usecase.dart`
Migration Priority: P1
Dependencies: `DioClient`, `ApiClient`, `IsarService`
Risk: Medium (Data ingestion stability)
```

#### 7. `lib/core/design_system/widgets/app_shell.dart` (3,846 lines)
```text
Current Responsibility: Master responsive application layout wrapper for Desktop, Tablet, and Mobile.
Responsibilities Found:
  1. Desktop side navigation rail.
  2. Mobile bottom navigation bar and drawer integration.
  3. Responsive breakpoint listener and layout switching.
  4. Global header, notifications popover, user profile menu.
  5. Unread team message badge polling and sync indicators.
Recommended Modules:
  - `lib/app/shell/app_shell.dart` (Thin breakpoint switcher, <250 lines)
  - `lib/app/shell/desktop/desktop_navigation_rail.dart`
  - `lib/app/shell/mobile/mobile_bottom_nav.dart`
  - `lib/app/shell/header/app_header_bar.dart`
  - `lib/app/shell/header/notifications_menu.dart`
Migration Priority: P1
Dependencies: `AppRouter`, `RoleGuard`, `ThemeManager`, `AuthBloc`
Risk: Medium (Affects every screen layout in the app)
```

#### 8. `lib/features/dashboard/widgets/analytics_section.dart` (3,794 lines)
```text
Current Responsibility: Renders KPI trend graphs, lead conversion funnels, and agent performance leaderboards.
Responsibilities Found:
  1. SVG / Canvas chart drawing code.
  2. Funnel dropoff calculations.
  3. Leaderboard list sorting and rendering.
Recommended Modules:
  - `presentation/widgets/analytics/lead_conversion_funnel.dart`
  - `presentation/widgets/analytics/agent_performance_leaderboard.dart`
  - `presentation/widgets/analytics/trend_chart_widget.dart`
Migration Priority: P2
Dependencies: `DashboardSummary`, `AppTheme`
Risk: Low
```

#### 9. `lib/features/telecaller/screens/telecaller_callbacks_screen.dart` (3,730 lines)
```text
Current Responsibility: Telecaller operational workflow screen for pending callbacks, scheduled calls, and overdue followups.
Responsibilities Found:
  1. Calendar and time-slot filter bar.
  2. Callback card list with direct dialer launch.
  3. Disposition modal with outcome selection (CNR, Busy, Not Interested, Converted).
  4. Local reschedule date/time calculation.
Recommended Modules:
  - `presentation/screens/telecaller_callbacks_screen.dart` (Shell, <300 lines)
  - `presentation/widgets/callback_card_item.dart`
  - `presentation/widgets/callback_time_filter_bar.dart`
  - `presentation/dialogs/telecaller_call_disposition_sheet.dart`
Migration Priority: P1
Dependencies: `TelecallerLeadsBloc`, `FollowupsRepository`
Risk: Medium (Telecaller daily workflow)
```

#### 10. `lib/features/properties/screens/add_edit_property_screen.dart` (3,611 lines)
```text
Current Responsibility: Enormous property creation and editing form.
Responsibilities Found:
  1. Multi-step stepper wizard.
  2. Basic details, location pickers (lat/long map), pricing, and brokerage.
  3. Amenities multi-select checkboxes.
  4. Image & video multi-file picking, compression, and Cloudinary upload.
  5. Form validation and draft persistence (`CRMDraftRepository`).
Recommended Modules:
  - `presentation/screens/add_edit_property_screen.dart` (Form wizard coordinator, <350 lines)
  - `presentation/forms/property_basic_info_step.dart`
  - `presentation/forms/property_location_step.dart`
  - `presentation/forms/property_pricing_step.dart`
  - `presentation/forms/property_media_upload_step.dart`
Migration Priority: P1
Dependencies: `PropertiesBloc`, `PropertiesRepository`, `CloudinaryUploader`
Risk: Medium (Critical inventory intake form)
```

#### 11. `lib/features/admin/bloc/lead_allocation_monitor_bloc.dart` (2,303 lines)
```text
Current Responsibility: BLoC file that illegally embeds the entire 2,050-line `LeadAllocationMonitorScreen` UI widget tree, data tables, and dialogs!
Responsibilities Found:
  1. Lead allocation state management (`LeadAllocationMonitorBloc`, Events, State).
  2. Complete `LeadAllocationMonitorScreen` widget implementation.
  3. Admin telecaller capacity table and toggle buttons.
  4. Direct Dio network calls (`DioClient.dio.get(...)`).
Recommended Modules:
  - `features/admin/presentation/bloc/lead_allocation_monitor_bloc.dart` (Pure BLoC, <200 lines)
  - `features/admin/presentation/bloc/lead_allocation_monitor_event.dart` (<80 lines)
  - `features/admin/presentation/bloc/lead_allocation_monitor_state.dart` (<80 lines)
  - `features/admin/presentation/screens/lead_allocation_monitor_screen.dart` (Pure UI screen, <400 lines)
  - `features/admin/presentation/widgets/telecaller_capacity_table.dart`
Migration Priority: P0 (Gross architectural violation: UI inside BLoC file)
Dependencies: `DioClient`, `SecureStorage`, `IntegrationService`
Risk: Medium (Admin allocation control)
```

#### 12. `lib/features/telecaller/widgets/telecaller_kpi_dialogs.dart` (2,690 lines)
```text
Current Responsibility: All KPI popup modals and drilldowns for telecaller dashboards.
Responsibilities Found:
  1. Five distinct modal dialog implementations for telecaller metrics.
  2. Tabular lead history inside popups.
Recommended Modules:
  - Decompose into separate files under `lib/features/telecaller/presentation/dialogs/`
Migration Priority: P2
Dependencies: `TelecallerDashboardBloc`
Risk: Low
```

---

### 2.2 Top 6 Monolithic Files in Backend (`src/`)

#### 1. `src/modules/dashboard/kpi.service.js` (5,541 lines)
```text
Current Responsibility: Monolithic master KPI service containing all raw SQL compositions, metric formulas, and drilldown query generators for the entire platform.
Responsibilities Found:
  1. Executive KPI calculations (Total Ingested, Net Leads, Conversion Rate).
  2. Telecaller individual and team performance metrics.
  3. Sales pipeline, site visit progress, and revenue metrics.
  4. Complex raw SQL query strings, case statements, date filters, and string normalizers.
  5. In-memory KPI caching logic.
Recommended Modules:
  - `services/kpi_executive.service.js` (<400 lines)
  - `services/kpi_telecaller.service.js` (<400 lines)
  - `services/kpi_sales.service.js` (<400 lines)
  - `repositories/kpi_query.repository.js` (Encapsulates all SQL compositions)
  - `utils/kpi_date_parser.js`
Migration Priority: P0 (High bug risk; KPI reconciliation source)
Dependencies: `dbPool.js`, `kpiRulebook.master.js`, `AllocationService`
Risk: High (Must maintain exact semantic equivalence across dashboards)
```

#### 2. `src/modules/integrations/integrations.service.js` (4,624 lines)
```text
Current Responsibility: Monolithic service handling Meta Webhooks, Graph API communication, Housing.com payloads, CSV lead parsing, and lead auto-provisioning.
Responsibilities Found:
  1. Meta webhook signature verification and challenge response.
  2. Meta Graph API lead fetching and field mapping.
  3. Housing.com lead payload digestion.
  4. Phone sanitization and Indian mobile number validation.
  5. Auto-creation of requirement records from lead metadata.
  6. CSV/Excel file import parsing.
Recommended Modules:
  - `integrations/meta/meta_webhook.service.js` (<300 lines)
  - `integrations/housing/housing_webhook.service.js` (<300 lines)
  - `services/lead_sanitizer.service.js` (<200 lines)
  - `services/lead_auto_provision.service.js` (<350 lines)
  - `services/file_import.service.js` (<300 lines)
Migration Priority: P0 (Critical webhook ingestion path)
Dependencies: `supabase.js`, `dbPool.js`, `leadIngestEngine.service.js`
Risk: High (External third-party data stream)
```

#### 3. `src/modules/health/health.html.js` (2,945 lines)
```text
Current Responsibility: Massive raw HTML, CSS, and client-side JavaScript template string hardcoded into a Node.js export file for rendering the `/health` diagnostic portal.
Responsibilities Found:
  1. Embedded HTML structure.
  2. Embedded CSS stylesheets (over 1,200 lines).
  3. Embedded client-side JavaScript for charts and polling (over 1,000 lines).
Recommended Modules:
  - Extract static HTML/CSS/JS assets to `assets/health_portal/index.html`, `portal.css`, `portal.js`.
  - Node.js health module simply reads and serves the static files or renders via a minimal template.
Migration Priority: P2 (Cleanliness & file size hygiene)
Dependencies: None
Risk: Zero (Internal diagnostic view only)
```

#### 4. `src/modules/allocation/allocation.service.js` (2,464 lines)
```text
Current Responsibility: Lead allocation engine, telecaller workload balance, capacity management, round-robin cursor, stale lead recovery, and manual off scheduling.
Responsibilities Found:
  1. Waiting lead allocation coordination.
  2. Telecaller availability state machine (ONLINE, ON_CALL, BUSY, MANUAL_OFF, LOGGED_OUT).
  3. Stale lead recovery timer logic.
  4. Direct database queries via both Supabase client and pg.Pool.
Recommended Modules:
  - `allocation/services/allocation_dispatcher.service.js` (<400 lines)
  - `allocation/services/telecaller_capacity.service.js` (<350 lines)
  - `allocation/services/stale_recovery.service.js` (<300 lines)
  - `allocation/repositories/allocation.repository.js` (All SQL queries)
Migration Priority: P1
Dependencies: `dbPool.js`, `supabase.js`, `NotificationService`
Risk: High (Core lead distribution mechanism)
```

#### 5. `src/modules/reports/reports.service.js` (1,521 lines)
```text
Current Responsibility: Analytics reporting queries, business insight summaries, telecaller aggregate reports, and streaming file exports.
Responsibilities Found:
  1. Multi-table reporting aggregations.
  2. Excel workbook building via `exceljs`.
  3. Streaming CSV data pipes.
Recommended Modules:
  - `reports/services/business_insight.service.js`
  - `reports/services/telecaller_report.service.js`
  - `reports/services/export_streamer.service.js`
  - `reports/repositories/reports.repository.js`
Migration Priority: P2
Dependencies: `dbPool.js`, `exceljs`
Risk: Low
```

#### 6. `src/modules/auth/auth.controller.js` (1,247 lines)
```text
Current Responsibility: Authentication controller containing business logic for login, registration, MFA setup/verification, captcha generation, and password policies.
Responsibilities Found:
  1. HTTP request parsing.
  2. Password hashing & salt comparison.
  3. MFA TOTP secret generation & QR code formatting.
  4. Captcha rendering and validation.
  5. Session insertion into PostgreSQL.
Recommended Modules:
  - `auth/controllers/auth.controller.js` (HTTP translation only, <300 lines)
  - `auth/services/auth.service.js` (Core authentication logic)
  - `auth/services/mfa.service.js` (MFA TOTP logic)
  - `auth/services/captcha.service.js` (Captcha generation)
Migration Priority: P1
Dependencies: `bcryptjs`, `jsonwebtoken`, `redis.js`, `dbPool.js`
Risk: Medium (Security critical)
```

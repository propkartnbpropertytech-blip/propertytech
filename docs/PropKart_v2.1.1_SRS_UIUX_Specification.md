# SOFTWARE REQUIREMENTS SPECIFICATION (SRS) & UI/UX DESIGN SYSTEM SPECIFICATION
## Product: PropKart Real Estate Operating System & CRM
### Release Version: v2.1.1 (Production Build 10+)
* **Document Identifier:** `SRS-PK-V2.1.1-DES-UIUX-001`
* **Parent Organization:** NB Property Tech
* **Product Codebase:** Flutter Material 3 / Custom CRM Design System (`c:\NB\propkart`)
* **Document Status:** Official Production Baseline / UI/UX Design & Engineering Handoff
* **Target Roles:** Lead Graphics Designer, Principal UI/UX Designer, Design System Engineers, Frontend / Mobile Developers, Product Management
* **Date of Issue:** September 12, 2026

---

## 1. EXECUTIVE SUMMARY & SYSTEM ARCHITECTURE

### 1.1 Product Philosophy & Market Positioning
PropKart is **not a public classifieds listing portal** (such as 99acres or MagicBricks). It is an enterprise-grade, high-performance **Real Estate Operating System & Desk CRM** engineered for property brokers, sales teams, telecallers, and real estate agency owners.

The platform provides a consolidated operating workspace for managing both **Rental** and **Re-Sale** real estate businesses. It manages the complete lifecycle of property transactions: from inbound multi-channel ad lead ingestion (Meta Lead Ads, Google Sheets) to AI-assisted inventory matchmaking, automated client dossier sharing via WhatsApp, site visit coordination, commercial negotiation tracking, and closing legal paperwork.

### 1.2 Core Product Pillars of v2.1.1
1. **Unified Dual Inventory (Rent & Re-Sale):** Complete property lifecycle management across residential and commercial sectors with a dynamic visual atmosphere switch between Rental and Re-Sale operations.
2. **Automated Demand Matchmaking:** Real-time pairing of buyer/tenant inquiries with active listings based on budget tolerance (10%), configurations (BHK), localities, furnishing, and facing.
3. **One-Tap Client Sharing:** Instant generation of branded multi-property PDF dossiers, WhatsApp broadcast messages, and trackable public web shortlists (`/share/:sessionId`).
4. **Direct Inbound Marketing Ingestion:** Real-time webhook inbox for Meta Lead Ads (Facebook & Instagram) and Google Sheets with lead intelligence, duplicate phone detection, and 1-click promotion to CRM.
5. **Role-Aware Security & Permission Matrix:** 4 operational roles (*Super Admin*, *Admin*, *Sales*, *Telecaller*) governed by a dynamic 40-metric permission control center.
6. **Internal Team Messenger:** Dedicated real-time communication desk (`/messages`) with team grouping, role filtering, and administrative oversight.
7. **Document Vaults:** Organized digital libraries for rental lease contracts, resale title deeds, society NOCs, and service contractor agreements.

### 1.3 Technical Ecosystem
* **Front-End Framework:** Flutter (Dart `^3.11.1`) targeting Material 3 with an Apple HIG-inspired custom CRM design system.
* **State Management:** BLoC (`flutter_bloc` 9.1.1) for domain event handling and asynchronous streams + Riverpod (`flutter_riverpod` 2.6.1) for reactive caches.
* **Local Persistence & Offline Cache:** `Isar` NoSQL embedded database for high-performance offline record indexing.
* **Secure Storage:** `flutter_secure_storage` for encrypted JWT tokens + `shared_preferences` for theme and view preferences.
* **Network & API Client:** `Dio` (5.10.0) with interceptors, 9-hour inactivity session timeout, and background sync manager (`SyncManager`).
* **Media Processing:** Client-side image compression (`flutter_image_compress`), Cloudinary CDN uploading, and video playback.
* **Target Platforms:** Web (PWA at `propkart.nbpropertytech.com`), Android, iOS, Windows Desktop, macOS Desktop.

---

## 2. DESIGN SYSTEM & UI TOKEN ARCHITECTURE

The PropKart design system follows modern Apple Human Interface Guidelines (HIG) combined with enterprise SaaS ergonomics. Long CRM working sessions require low visual fatigue, high contrast ratios (WCAG AAA compliant), crisp information density, and instant context recognition.

### 2.1 Dual-Theme Architecture & Color Roles
PropKart implements dynamic runtime theming via `ThemeManager`. The app supports **Light** and **Dark** modes across two master presets, with a distinct visual **Atmosphere Shift** when switching between **Rental** and **Re-Sale** desks.

| Token Role | Modern Teal Preset (Default SaaS) | PropKart Classic Preset (Warm Terracotta) | Dark Mode Override |
| :--- | :--- | :--- | :--- |
| `primary` | #159B73 (Emerald Teal) | #C15D4A (Terracotta Clay) | #10B981 / #D47A66 |
| `primaryHover` | #128764 | #A64C3C | #34D399 / #E08B78 |
| `accent` | #E8F5F1 (Light Mint Wash) | #F6D8D0 (Warm Sand Tint) | #0D3D31 / #3A2824 |
| `rentalAtmosphere` | #159B73 (Fresh Teal) | #5F8064 (Sage Green) | #10B981 / #5F8064 |
| `resaleAtmosphere` | #C15D4A (Warm Terracotta) | #8B4513 (Saddle Wood) | #D47A66 / #8B4513 |
| `canvas` | #F8FAFC (Slate Canvas) | #F4F4F3 (Warm Alabaster) | #0F172A (Deep Slate) |
| `surface` (Cards) | #FFFFFF (Pure White) | #FFFFFF (Neutral Card) | #1E293B (Midnight Surface) |
| `border` / `divider`| #E8ECF2 (Light Gray Border)| #E3DDD7 (Muted Sand Border) | #334155 (Slate Border) |
| `textPrimary` | #14213D (Deep Navy Ink) | #1A1A1A (Carbon Charcoal) | #F8FAFC (Off-White) |
| `textSecondary` | #64748B (Slate Muted) | #68738A (Clay Charcoal) | #94A3B8 (Cool Slate) |
| `whatsappGreen` | #25D366 (WhatsApp Official)| #25D366 (WhatsApp Official) | #25D366 |
| `success` | #10B981 (Mint Emerald) | #5F8064 (Sage Success) | #10B981 |
| `danger` | #E11D48 (Crimson Red) | #DC2626 (Vibrant Ruby) | #E11D48 |
| `warning` | #F59E0B (Amber Gold) | #C4924A (Sand Warning) | #F59E0B |
| `info` / `messages`| #3B82F6 (Electric Blue) | #3B82F6 (Cobalt Blue) | #3B82F6 |

> **UX Rule — Atmosphere Shift:** When the desk operates in **Rental Mode**, primary buttons, status pills, and active filter tabs accent in **Teal / Sage**. When toggled to **Re-Sale Mode**, the accent shifts to **Terracotta / Clay**. This ensures agents immediately recognize which book they are editing or pitching.

### 2.2 Typography Scale (SF Pro / Inter)
* **Apple Platforms:** System Font `SF Pro Display` & `SF Pro Text`.
* **Other Platforms:** `Inter` via Google Fonts.

| Token | Size | Weight | Line Height | Tracking | Usage |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `largeDisplay` | 32 pt | Bold (700) | 40 pt | -0.02 em | Splash, Hero KPIs, Auth welcome headers |
| `pageTitle` | 24 pt | Bold (700) | 32 pt | -0.015 em | Screen headers (Properties, Leads, Dashboard) |
| `sectionTitle`| 18 pt | SemiBold (600) | 24 pt | -0.01 em | Card headers, drawer titles, modal headings |
| `cardTitle` | 15 pt | SemiBold (600) | 20 pt | -0.01 em | Property card titles, requirement headers |
| `bodyMedium` | 14 pt | Medium (500) | 20 pt | 0.0 em | Form inputs, data table cell content |
| `body` | 13.5 pt| Regular (400) | 18 pt | 0.0 em | Property descriptions, client remarks |
| `captionBold` | 12 pt | SemiBold (600) | 16 pt | +0.01 em | Status badges, table headers, column labels |
| `caption` | 11 pt | Regular (400) | 14 pt | +0.01 em | Timestamps, secondary subtitles, footnotes |
| `footnote` | 10 pt | Medium (500) | 12 pt | +0.02 em | Unread badge counts, helper validation tags |

### 2.3 Spacing, Radii, and Elevation
* **Spacing Scale (`CRMSpacing`):**
  * `xs`: 4px | `s`: 8px | `m`: 12px | `l`: 16px | `xl`: 20px | `xxl`: 24px | `xxxl`: 32px | `huge`: 48px | `mega`: 64px.
* **Corner Radius Scale (`CRMBorderRadius`):**
  * `xs`: 4px (Tags/Dots) | `s`: 8px (Inputs, dropdowns) | `m`: 12px (Cards, dialogs) | `l`: 16px (Floating panels) | `xl`: 20px (Modals, sheets) | `pill`: 999px (Action pills, chips, search bars).
* **Elevation & Shadows (`CRMShadows`):**
  * `soft`: `0px 2px 8px rgba(0, 0, 0, 0.04)` — Card rest state.
  * `medium`: `0px 6px 16px rgba(0, 0, 0, 0.08)` — Card hover state, dropdown menus.
  * `floating`: `0px 12px 32px rgba(0, 0, 0, 0.12)` — Top bar sticky shadow, quick add bottom sheet.
  * `primaryGlow`: `0px 4px 14px rgba(21, 155, 115, 0.35)` — Primary CTA buttons.
* **Glassmorphism Spec (`CRMBlur`):**
  * Top navigation bar, filter overlays, and modal backdrops utilize `BackdropFilter` with `sigmaX: 20`, `sigmaY: 20`, overlaying a translucent surface fill (82% opacity in light mode, 85% in dark mode).

### 2.4 Responsive Viewport Breakpoints
* **Mobile (Phone):** `< 768px` (Single column stacked layout, bottom tab bar, full-screen dialogs, collapsed search).
* **Tablet (iPad / Surface):** `768px – 1023px` (Dual-column KPI grid, floating drawer filters, iconified collapsed sidebar).
* **Desktop (Laptop / Monitor):** `1024px – 1439px` (Full expanded sidebar, side-by-side split inspectors, multi-column high-density data tables).
* **Ultrawide Monitors:** `≥ 1440px` (Content bounded to max width `1440px` centered with auto-margins to prevent visual eye fatigue).

---

## 3. GLOBAL APPLICATION SHELL (CRMAppShell)

### 3.1 Resizable Modern Sidebar (`ModernSidebar`)
* **Width Range:** Default expanded width `245px` (resizable up to `320px` via a 3px vertical drag handle). Collapsed icon-only width `70px`.
* **Header:** `CRMBrandLockup` rendering the official PropKart home emblem (38px) and bold typographic wordmark.
* **Navigation Hierarchy & Badges:**
  1. **Dashboard** (`/dashboard`) — Icon: `grid_view_rounded`
  2. **Properties** (`/properties`) — Icon: `home_work_outlined`
  3. **Leads** (`/requirements`) — Icon: `assignment_outlined` + **Dynamic Unread Count Pill** (Red `#E11D48`)
  4. **Employees** (`/users`) — Icon: `people_outline_rounded` *(Admin / Super Admin only)*
  5. **Reports** (`/reports`) — Icon: `bar_chart_rounded` *(Admin / Super Admin only)*
  6. **Campaign & Ingestion** (`/campaign`) — Expandable accordion tree:
     * *Connections* (`/campaign/connections`)
     * *Lead Ingestion* (`/campaign/leads`)
  7. **Library** (`/library`) — Icon: `folder_outlined`
  8. **Settings** (`/settings`) — Icon: `settings_outlined`
  9. **Recycle Bin** (`/bin`) — Icon: `delete_outline_rounded`
* **Footer User Card (`UserProfileCard`):** Displays user initials avatar, full name, role pill, and quick session sign-out button.

### 3.2 Glass Modern Top Bar (`ModernTopBar`)
* **Height:** Desktop `74px` | Mobile `62px`.
* **Sidebar Toggle:** Hamburger menu button with smooth hover feedback.
* **Global Omni-Search Field:**
  * Width: Max `420px`. Border radius: `24px` pill.
  * Real-time debounced search (`300ms`) querying:
    * Property Listings (title, property code, locality).
    * Leads / Requirements (client name, mobile, budget).
    * Owners and Builders.
  * Overlay: Translucent glass dropdown layer positioned directly underneath the search field with category grouping.
  * Mobile view: Collapses to a search icon button; tapping opens a full-width header search bar with autofocus.
* **Top Bar Action Cluster (Right Aligned):**
  1. **Quick Add Action Button (`+`):** Primary color filled circular button (`38px` diameter) with drop shadow glow. Tapping opens the *Quick Actions Bottom Sheet* (`Add Property`, `Add Lead`, `Schedule Site Visit`).
  2. **Notifications Center (`🔔`):** Outlined bell with red unread notification dot badge. Tapping toggles the right-sliding notification drawer.
  3. **Team Messages Shortcut (`💬`):** Outlined chat bubble with blue unread message dot badge. Directly navigates to `/messages`.
  4. **Super Admin Profile & Theme Menu (`👤`):** Displays avatar circle with initials, user name, and role badge. Clicking opens a dropdown menu containing:
     * *Profile & Account Details*
     * *Set System Default Theme Modal* (Allows Super Admin to lock the default global preset for all agency devices)
     * *Session Sign-out* (Destroys secure tokens and resets local cache)

### 3.3 Mobile Persistent Bottom Navigation Bar
* On viewports `< 768px`, the sidebar is hidden and replaced by a 5-tab bottom navigation bar (`persistent_bottom_nav_bar_v2`):
  * **Tab 0:** Dashboard (`/dashboard`)
  * **Tab 1:** Properties (`/properties`)
  * **Tab 2 (Center Action):** Quick Add `+` (Elevated center button, opens Quick Actions modal)
  * **Tab 3:** Leads (`/requirements`) with numeric notification counter
  * **Tab 4:** Profile & Settings (`/profile`)

---

## 4. ROLE-BASED ACCESS CONTROL (RBAC) & PERMISSION MATRIX

PropKart enforces strict, multi-tiered role visibility. The server remains the source of truth, but the UI adapts dynamically using `RoleGuard` and the **v2.1.1 Super Admin Permission Matrix Service**.

### 4.1 The 4 User Roles
1. **Super Admin:** Master organizational controller. Exclusively manages Admin accounts, configures the 40-metric Permission Matrix, inspects security audit logs, runs server diagnostics, and locks system default themes.
2. **Admin:** Branch / desk manager. Manages Sales and Telecaller accounts, manages Meta Ads and Google Sheets webhook connectors, reviews executive reports, exports data, and handles location configurations.
3. **Sales:** Field and closing executives. Manages inventory, registers requirements, executes property matching, conducts site visits, generates WhatsApp shortlists, and negotiates transactions.
4. **Telecaller:** Inbound call desk. Monitors inbound campaign leads from Meta Ads, conducts initial qualification calls, updates lead statuses, schedules callbacks, and registers buyer/tenant inquiries.

### 4.2 Granular Permission Matrix Categories
1. **App Shell & Pages:** Access control for Dashboard, Properties, Leads, Employees, Reports, Campaign, Library, Recycle Bin, Settings, Audit Logs, Clients, Owners, Builders, Messages.
2. **Properties Inventory:** Create, Edit, Soft Delete, Restore, Permanent Delete, Verify (Blue Checkmark), Export to Excel, View Direct Landlord Contact, Share Dossiers.
3. **Leads & Pipeline:** Create Inquiries, Edit Matchmaking, Delete Leads, Reassign Leads across Agents, Bulk Export to Excel, View Unmasked Client Phone, Schedule Follow-up Alarms.
4. **Campaign & Ingestion:** View Inbound Inbox, Manage Webhook Secrets, Update Lead Status (Interested / Follow-up / Not Interested), 1-Click Move to CRM, Run Deduplication Engine, Bulk Purge Leads, Simulate Payloads.
5. **Team & Staff:** View Directory, Invite/Register Users, Edit Role & Profile, Deactivate Accounts, Manage Admin Users (Super Admin exclusive), Trigger Password Reset Links.
6. **Reports & Analytics:** Overall Business Insights, Telecaller Productivity Analytics, Sales Performance & Closures, Export Analytical Dossiers.
7. **Security & System:** View Audit Trail, Manage Cities & Localities, Configure Global Branding Presets, System Health Diagnostics, Manage Permission Matrix.

---

## 5. COMPLETE SCREEN-BY-SCREEN FUNCTIONAL & UI SPECIFICATIONS

### 5.1 Authentication & Gatekeeper Screens
* **Splash Screen (`/splash`):**
  * Displays centered high-resolution brand mark with smooth pulsating shimmer animation (`CRMMotion.nameShimmer`).
  * Concurrently executes `SyncManager.performStartupSync()` to warm up local `Isar` cache.
  * Validates session freshness and 9-hour inactivity limit. Redirects to `/dashboard` or `/get-started`.
* **Get Started Screen (`/get-started`):**
  * Apple-style clean presentation with tagline *\"Treasure of listed properties in your area\"*.
  * Primary CTA button: `Sign In to Desk`. Footer links to Terms and Privacy Policy.
* **Login Screen (`/login`):**
  * Form fields: Email Address (regex validation), Password (with eye toggle icon for obscure text).
  * Rate-limiting error banners, invalid credentials notifications.
  * Actions: `Sign In` (shows spinner), `Forgot Password?` action link.
* **Password Reset Screen (`/reset-password`):**
  * Consumes URL query parameters: `error_code`, `token_hash`, `code`, `token`.
  * Form inputs: New Password, Confirm Password with visual password strength indicator.
* **Legal Pages (`/terms-and-conditions`, `/privacy-policy`):**
  * Clean typographic document viewers rendering embedded markdown legal documents.

### 5.2 Executive Dashboard (`/dashboard`)
* **Header Bar (`WelcomeHeader`):** Time-of-day greeting (*Good Morning / Afternoon / Evening*) + User Name + Date.
* **Desk Mode Switcher:** Toggle between **Rental** and **Re-Sale** modes, dynamically recalculating KPI values.
* **KPI Metrics Grid (`CRMKPICard`):** 2 columns on mobile, 4 columns on desktop:
  1. *Total Listed Inventory* (+% growth indicator)
  2. *Available Units* (% of total inventory)
  3. *Deals Closed* (Rented / Sold count)
  4. *Active Requirements* (Client demand volume)
  5. *Team Roster Count* (Active agents on duty)
* **Today's Schedule & Site Visits Card (`TodaysScheduleCard`):**
  * Agenda list of client appointments scheduled for the current date.
  * Shows visit time, property code link, client name, assigned executive, status pill (*Scheduled*, *Completed*, *Cancelled*), and WhatsApp shortcut button.
* **Priority Follow-ups Card (`FollowupsCard`):**
  * Sub-tabs: **Today**, **Due / Overdue**, **Future**.
  * Shows client name, preferred BHK, budget range, and scheduled callback time.
  * Direct phone call (`tel:`) and pre-templated WhatsApp greeting buttons.
* **Analytics Section (`AnalyticsSection`):**
  * *Inventory Mix Pie Chart:* Breakdown of Residential vs Commercial units.
  * *Top Localities Bar Chart:* Ranked bar chart of properties across top localities (Bopal, Prahlad Nagar, SG Highway, etc.).
* **Desk Quick Notes & Checklist:**
  * Interactive scratchpad with optimistic check/uncheck updates for agent reminders.

### 5.3 Properties Inventory Hub (`/properties`)
* **Atmosphere & Category Filter Bar:**
  * Desk Mode: **Rent** vs **Re-Sale**.
  * Category: **Residential** vs **Commercial**.
  * Configuration Chips: `1 BHK`, `2 BHK`, `3 BHK`, `4+ BHK`, `RK`, `Plot / Land`, `Office`, `Shop`.
* **Desk Filter & Toolstrip:**
  * Search field (matches code, title, address, landmark).
  * Locality Multi-select dropdown.
  * Price range slider / min-max inputs in Indian currency format (₹ Lacs / ₹ Crores).
  * Image status filter: *All*, *With Images*, *No Images*.
  * *My Added Only* toggle switch.
  * Layout Switcher: **Card Grid View** vs **Data Table View**.
  * Compare checkboxes: Select up to 4 properties for side-by-side comparison.
* **Property Card UI Anatomy:**
  * Image carousel with cached network images and counter badge (`1/8`).
  * Price header (e.g., `₹45,000/mo` or `₹1.85 Cr`).
  * Spec badge: `3 BHK` • `1,850 sq.ft Super Built-up` • `Carpet: 1,320 sq.ft`.
  * Verified Blue Badge (`✔ Verified`).
  * Property Code chip (e.g., `PROP-R-10294`).
  * Landlord contact row with direct WhatsApp trigger.
  * Action row: `View Details`, `Edit Listing`, `Share Dossier`, `Move to Bin`.
* **Side-by-Side Property Comparison Modal:**
  * Evaluates up to 4 properties across 15 structured dimensions (Price, Deposit, Carpet Area, Super Built-up, Configuration, Floor, Total Floors, Age, Facing, Furnishing, Parking, Bathrooms, Balconies, Maintenance, Locality).
* **Add / Edit Property Multi-Step Wizard (`AddEditPropertyScreen`):**
  * Section 1: Basic Identity (Listing Type, Category, Type, Configuration, Title).
  * Section 2: Location & Map (City, Area, Pincode, Address, Landmark, Google Places autocomplete, Interactive Map Pin Picker with reverse geocoding).
  * Section 3: Dimensions & Spaces (Super Built-up, Carpet, Plot area, Floor No, Total Floors, Age).
  * Section 4: Commercials (Asking Price / Rent, Deposit with 1-6 months quick calculator, Maintenance, Brokerage).
  * Section 5: Specifications & Amenities (Furnishing, Facing, Bathrooms, Balconies, Parking, Amenities checklist).
  * Section 6: Media Uploader (Multi-photo picker, automated compression, video walkthrough, Cloudinary upload).
  * Section 7: Ownership & Remarks (Landlord Name, Mobile with country picker, Broker Name, Internal Desk Remarks).
  * *Draft Autosave Protection (`CRMDraftRepository`):* Restores form state if accidentally closed.
* **Property Detail Screen (`/properties/:id`):**
  * Full-bleed photo gallery, comprehensive specification matrix, map preview, owner card with call/WhatsApp actions, and client share drawer.

### 5.4 Recycle Bin (`/bin`)
* Holding area for soft-deleted properties and requirements.
* Displays deleted item code, title, deleted by, deletion timestamp, and retention window.
* Actions: **Restore to Active Inventory** (1-click optimistic update) or **Permanently Drop Record** (Super Admin exclusive).

### 5.5 Leads & Requirements Hub (`/requirements`)
* **Main Tabs:** **Active Leads**, **Requirements**, **Scheduled Follow-ups**.
* **14-Stage Client Deal Progression Funnel:**
  Tracks leads across: `Lead Created` → `Requirement Added` → `Requirement Verified` → `Matching Started` → `Properties Matched` → `Properties Shared` → `Client Viewed` → `Client Interested` → `Site Visit Scheduled` → `Site Visit Completed` → `Negotiation` → `Booking / Token` → `Documentation` → `Closed / Won`.
* **Automated Matchmaking Intelligence:**
  * Matches client criteria against live inventory with 10% budget tolerance.
  * Outputs **Match Readiness Score**: *Ready*, *Needs Information*, *Cannot Match*.
  * Outputs **Requirement Quality Metric**: *High*, *Medium*, *Low*, *Poor*.
* **Client Sharing Suite:**
  * *Branded PDF Dossier Generator (`PropertySharePdf`):* Creates agency-branded client PDF dossiers.
  * *Public Shortlist Web Link (`/share/:sessionId`):* Generates responsive client web portal; tracks when client opens the link.
  * *WhatsApp Broadcast:* Formatted message with specs, pricing, and view link.
* **Internal CRM Remarks vs Follow-up Reminders:**
  * Strictly separated database tables: `followups` (alarms) and `internal_crm_remarks` (immutable audit trail of agent discussion notes).

### 5.6 Campaign & Marketing Ingestion Inbox (`/campaign`)
* **Dual-Section Header Isolation:** Segregates inbound leads into two isolated pipelines: **Property Listing Leads** (owners) vs **Requirement Leads** (buyers/tenants).
* **Lead Intelligence Engine (`LeadUnderstandingEngine`):**
  * Auto-extracts budget numbers, BHK configurations, and localities from Meta custom questions and Google Forms.
  * Detects duplicate phone numbers across the database, flagging repeat inquiries with a warning badge.
* **Interactive Status Dropdown:**
  * `Follow-up`: Prompts the Follow-up Calendar & Clock Picker Modal to schedule a callback alarm.
  * `Interested`: Highlights row in soft green and unlocks the 1-click **Move to CRM** button.
  * `Not Interested`: Automatically moves entry to the archived Not Interested tab.
* **1-Click \"Move to CRM\" Workflow:** Promotes campaign entry into a formal `PropertyModel` or `RequirementModel`, preserving campaign attribution metadata.
* **Connections Screen (`/campaign/connections`):**
  * Meta Lead Ads Webhook settings: Callback URL, Verify Token, Page Subscriptions, App Secret verification.
  * Google Sheets Ingestion: Live sheet URL sync, column mapping wizard, periodic poll interval config.
  * Payload Inspector & Ingestion Simulator: Allows admins to paste test JSON payloads to verify field mapping.

### 5.7 Internal Team Messenger (`/messages`)
* **Layout Architecture:** Responsive master-detail layout (Left roster list `320px`, right chat canvas; on mobile, standard drill-down navigation stack).
* **Super Admin Team Grouping:** Categorizes roster by teams, pinning **Propkart Admin** at the top. Super Admins can inspect cross-team threads to monitor deal handoffs.
* **Roster Filtering & Status:** Filter chips (`All`, `Admins`, `Telecallers`, `Sales`), online green dot, unread message count badges, roster sorting.
* **Chat Thread Features:** Sent messages align right with primary theme tint; received messages align left with crisp card background. Keyboard ergonomics: `Enter` sends, `Shift + Enter` inserts a newline.

### 5.8 Reports & Business Intelligence Hub (`/reports`)
* **Global Filter Header (`ReportGlobalFiltersBar`):** Date presets (*Today*, *Yesterday*, *Last 7 Days*, *This Month*, *Custom Date Range*, *All Time*) + Team/Agent dimension filter.
* **Overall Business Insight (`/reports/leads/overall-business-insight`):**
  * Executive revenue & turnover metrics.
  * 14-Stage Lead Conversion Funnel.
  * Callback Fulfillment Velocity metrics.
  * Team Leaderboard & Ranking (site visits, requirements closed, revenue).
  * Source Attribution Donut Chart (Meta Ads, Google Search, Walk-in, Referral, WhatsApp).
* **Export Suite:** 1-click export of analytical dossiers to `.xlsx` and formatted `.pdf`.

### 5.9 Shared Document Libraries (`/library`)
* **Rental Library (`/rental-library`):** Lease agreements, tenant/owner KYC proofs (Aadhaar, Passport), security deposit receipts, utility clearances, inspection media.
* **Re-Sale Library (`/resale-library`):** Title clearance certificates, registered sale deeds, society NOCs, approved floor plans, tax assessment receipts, bank loan sanction letters.
* **Service Agent Library (`/service-agent-library`):** Vendor contracts, GST certificates, SLAs, rate cards, and completed work inspection proofs for electricians, plumbers, cleaning crews, and legal drafters.

### 5.10 Directories & Team Administration
* **Client Index (`/clients`):** Buyer/tenant contact list with Pipeline Kanban Board vs Data Table toggle.
* **Property Owners Directory (`/owners`):** Landlord/seller registry linked to all properties owned with rental yield summaries.
* **Builders & Developers Directory (`/builders`):** Developer registry with tier ratings, ongoing projects, direct sales POCs, and commission structures.
* **Employees & Team Roster (`/users`):** Staff list with role badges, status chips, avatar photos, user creation modal, password reset queue, and agent activity drawer.
* **System Settings & Governance (`/settings`):**
  * Profile Editor (`/profile`).
  * Theme Presets Selector with Super Admin *\"Make as System Default\"* option.
  * Location Configuration (`/settings/location-config`) for cities, localities, and pincodes.
  * Super Admin Permission Matrix Control Center (`PermissionMatrixCard`) governing 40+ permissions.
  * Security Audit Logs (`/settings/audit-logs`) with filterable chronological trail.
  * System Diagnostics (`/settings/sync-debug`) for Isar cache and sync queues.

---

## 6. USER WORKFLOWS & STATE TRANSITION DIAGRAMS

### 6.1 Inbound Lead-to-Close Pipeline
```
[Meta Lead Ads / Google Sheets Ingestion]
                   │
                   ▼
       [Campaign Ingestion Inbox]
                   │
          (Telecaller Qualifies)
                   │
    ┌──────────────┴──────────────┐
    ▼                             ▼
[Follow-up Callback Scheduled]   [Marked Interested]
                                  │
                                  ▼
                         [1-Click Move to CRM]
                                  │
                                  ▼
                       [New Requirement Created]
                                  │
                                  ▼
                     [Auto-Match Against Stock]
                                  │
                                  ▼
                   [Branded PDF / WhatsApp Share]
                                  │
                                  ▼
                    [Client Views Public Portal]
                                  │
                                  ▼
                     [Site Visit Scheduled & Done]
                                  │
                                  ▼
                       [Commercial Negotiation]
                                  │
                                  ▼
                         [Booking Token Paid]
                                  │
                                  ▼
                     [Upload Lease / Sale Papers]
                                  │
                                  ▼
                            [Deal Closed]
```

### 6.2 Property Listing Lifecycle & Atmosphere Shift
```
[Agent Initiates Add Listing] ──> [Autosaved Draft in Local Storage]
                                            │
                                            ▼
                               [Validation & Media Upload]
                                            │
                                            ▼
                                   [Active Inventory]
                                            │
                  ┌─────────────────────────┴─────────────────────────┐
                  ▼                                                   ▼
         [Rental Atmosphere]                                 [Re-Sale Atmosphere]
            (Teal / Sage)                                     (Terracotta / Clay)
                  │                                                   │
                  └─────────────────────────┬─────────────────────────┘
                                            ▼
                                 [Available for Matching]
                                            │
                          ┌─────────────────┴─────────────────┐
                          ▼                                   ▼
                 [Move to Recycle Bin]                 [Deal Closed: Sold/Rented]
                          │
                 ┌────────┴────────┐
                 ▼                 ▼
          [Restore Listing]  [Permanent Drop]
```

---

## 7. UI/UX DESIGNER IMPLEMENTATION DIRECTIVES

### 7.1 Layout & Spatial Guidelines
1. **Never Design Fixed-Width Canvases:** Design responsive auto-layout frames across:
   * **Mobile Reference:** `390px` (iPhone 15/16).
   * **Tablet Reference:** `834px` (iPad Air / 11\" Pro).
   * **Desktop Reference:** `1440px` (MacBook Pro / 1080p Desktop).
2. **Information Density Balance:** PropKart is an enterprise productivity tool. Prioritize high-density data tables, clear typography contrast, and compact padding (`CRMSpacing.s` to `CRMSpacing.m`). Avoid excessive empty whitespace.
3. **Atmosphere Recognition:** Design distinct visual atmosphere cues for **Rental** (cool teal tones) versus **Re-Sale** (warm terracotta tones).

### 7.2 Core Component Specifications
* **Buttons:**
  * `PrimaryButton`: Primary brand fill with soft primary glow shadow (`CRMShadows.primaryGlow`). Press scale animation (`0.98`).
  * `SecondaryButton`: Soft neutral surface with 1px border.
  * `WhatsAppButton`: Official WhatsApp brand green `#25D366` with icon and white label.
  * `DestructiveButton`: Subtle crimson outline `#E11D48`, transitioning to solid crimson on confirm modals.
* **Form Inputs (`CRMTextField`):**
  * Height: `44px`. Corner radius: `8px`.
  * Normal state: 1px border `#E8ECF2` (Light) / `#334155` (Dark).
  * Focused state: 1.5px primary brand border with subtle outer glow ring.
  * Numeric Inputs: Incorporates currency prefix (`₹`) and right-aligned format badges (e.g., `Lacs`, `Cr`, `/month`).
* **Status Badges & Semantic Chips:**
  * Height: `24px`. Corner radius: `12px` (pill).
  * Translucent background washes (12% opacity) paired with high-contrast text labels:
    * *Active / Available / Verified:* Soft Emerald `#10B981`.
    * *Follow-up / Pending:* Soft Amber `#F59E0B`.
    * *Closed / Sold / Dropped:* Soft Slate `#64748B`.
    * *Critical / Expired:* Soft Crimson `#E11D48`.
* **Modals & Drawers:**
  * Modals must feature rounded corners (`20px`), centered layout, max-width `540px`, and frosted glass backdrop overlay (`sigma: 24`).
  * Filter drawers must slide in from the right edge on desktop/tablet, and slide up from the bottom on mobile devices.

### 7.3 Mandatory 5 States per Screen
For every screen, the UI designer must specify 5 distinct states:
1. **Default Loaded State:** Complete data populated with interactive controls.
2. **Skeleton Loading State:** Shimmering placeholder cards matching exact dimensions of text blocks and images (no generic circular spinners in data tables).
3. **Empty State:** Friendly graphic illustration with explanatory title and a single clear primary CTA (e.g., *\"No properties found matching this budget. Add New Property or Adjust Filters\"*).
4. **Error State:** Clear error icon with non-technical explanation and a `Retry` action button.
5. **Permission Denied State (`CRMPermissionDenied`):** Shield lock icon with message: *\"Access Restricted. Contact your Super Administrator to request permission for this module.\"*

---

## 8. MASTER ROUTE & PERMISSION INDEX TABLE

| Screen Name | Route URL | Allowed User Roles | Primary Viewport Layout |
| :--- | :--- | :--- | :--- |
| Splash & Token Sync | `/splash` | Public / System | Responsive Fullscreen |
| Get Started Onboarding | `/get-started` | Unauthenticated | Centered Presentation Card |
| Login Screen | `/login` | Unauthenticated | Centered Auth Card |
| Password Reset & Recovery | `/reset-password` | Recovery Link Holder | Centered Form Card |
| Terms & Conditions | `/terms-and-conditions` | Public | Document Reader |
| Privacy Policy | `/privacy-policy` | Public | Document Reader |
| Executive Dashboard | `/dashboard` | All 4 Roles | 4-Col Grid / Mobile Stack |
| Properties Inventory CRM | `/properties` | All 4 Roles | Data Table & 3-Col Cards |
| Property Detailed Dossier | `/properties/:id` | All 4 Roles | Hero Gallery & Split Specs |
| Add / Edit Property Wizard | Modal / Sheet | All 4 Roles | 7-Step Multi-Step Dialog |
| Leads & Requirements Hub | `/requirements` | All 4 Roles | Pipeline Cards & Table |
| Add / Edit Requirement Modal| Modal / Sheet | All 4 Roles | Centered Form Dialog |
| Public Property Share Landing | `/share/:sessionId` | Public Client Link | Responsive Web Portal |
| Public Individual Property View| `/share/:sessionId/prop..`| Public Client Link | Responsive Web Portal |
| Campaign Ingestion Queue | `/campaign/leads` | SuperAdmin, Admin, TC | High-Density Table |
| Campaign Webhook Connectors | `/campaign/connections` | SuperAdmin, Admin | Form & Payload Inspector |
| Dedicated Team Messenger | `/messages` | All 4 Roles | Master-Detail Split Canvas |
| Overall Business Insights Report| `/reports/leads/overall..`| SuperAdmin, Admin | Charts & KPI Dossier |
| Telecaller Productivity Report| `/reports/leads/telec..` | SuperAdmin, Admin, TC | Metrics & Call Logs |
| Sales Closures Performance Report| `/reports/leads/sales` | SuperAdmin, Admin | Leaderboard & Funnels |
| Shared Document Library Main | `/library` | All 4 Roles | Category 3-Card Grid |
| Rental Document Library | `/rental-library` | All 4 Roles | Folder & File List |
| Re-Sale Document Library | `/resale-library` | All 4 Roles | Folder & File List |
| Service Agent Vendor Library | `/service-agent-library` | All 4 Roles | Vendor Profile Cards |
| Client Directory & Pipeline | `/clients` | All 4 Roles | Kanban Board & Table |
| Property Owners Directory | `/owners` | All 4 Roles | Master-Detail Table |
| Builders & Developers Registry| `/builders` | All 4 Roles | Directory Cards |
| Employee & Staff Administration| `/users` | SuperAdmin, Admin | User Cards & Roster |
| Recycle Bin (Archive & Restore)| `/bin` | SuperAdmin, Admin | High-Density Table |
| Personal User Profile | `/profile` | All 4 Roles | Account Form |
| System Settings & Themes | `/settings` | All 4 Roles | Multi-Tab Master Panel |
| Location Config & Localities | `/settings/location-co..` | SuperAdmin, Admin, SA | Hierarchy Editor |
| Super Admin Permission Matrix | `/settings` (Tab) | Super Admin Only | 40-Metric Matrix Grid |
| Security Audit Logs | `/settings/audit-logs` | Super Admin Only | Chronological Feed |
| Sync & Diagnostic Debugger | `/settings/sync-debug` | Super Admin Only | Technical Status Feed |

---

## 9. DOCUMENT SIGN-OFF & REVISION APPROVAL

* **Product Architecture Approval:** Lead Systems Architect, NB Property Tech
* **UI/UX Design Lead Approval:** Principal UX Designer, NB Property Tech
* **Engineering Review:** Lead Flutter Engineer & Core API Team

*End of Software Requirements Specification (SRS-PK-V2.1.1-DES-UIUX-001)*

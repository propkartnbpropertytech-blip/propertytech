# PropKart Mobile UI/UX Master Specification

Status: design specification only. No application code, routes, tokens, assets, or APIs were changed.  
Baseline: `docs/PROPKART_MOBILE_UX_AUDIT.md` (Step 1).  
This document specifies the phone presentation layer. Business rules, RBAC, KPI definitions, lead and property lifecycles, allocation, matching, and database truth stay as they are.

Shared state, form, and error rules are defined once in sections 26–30. Each screen cites that contract and adds only what is different. That is the implementation contract, not a shortened audit.

---

## 1. Executive summary

Below 700px PropKart stops being a sidebar CRM. Each role gets its own bottom navigation and a home that matches the job.

- Telecaller home is the calling queue, not the admin dashboard.
- Leads and properties are cards. Tables are not the phone layout.
- Property and lead create/edit are full-screen wizards, not `AlertDialog`s.
- Short choices, filters, and confirms are bottom sheets.
- Reports drill into full-screen lists.
- One shell, one search, one filter sheet, one empty/error/offline set.
- `ModernSidebar` remains the navigation source at 700px and above. `_buildSidebarContent` is not part of the mobile design.

Future-state overall mobile UX score, if this spec is implemented as written and not yet device-tested: **8/10**. Contrast, real tap timing, and offline cache behavior stay **REQUIRES RUNTIME VERIFICATION**.

---

## 2. Design objective

A Flutter developer must be able to build a screen from this file without choosing layout, navigation, or component style.

Desktop and mobile share repositories, BLoCs, models, and APIs. They do not share tables, multi-column forms, or the admin sidebar as the phone interface.

---

## 3. Source audit baseline

Step 1 counts used here: 53 screen classes, 5 page classes, 4 detail views, 3 dashboards, 8 `TabBar`s, 152 `showDialog` sites, 118 `AlertDialog`s, 14 bottom sheets, 30 popup menus, 18 `Form` widgets, 8 portal steps, 43 `CRMKPICard` uses plus 10 named dashboard metrics, 44 table widgets, 11 chart surfaces, 16 fixed nav destinations plus dynamic portals.

Step 1 overall current score: 4/10. This spec does not repeat that audit.

Items marked **Requires runtime verification** in Step 1 stay open. See section 50.

---

## 4. Mobile design principles

1. **Above the fold is the next action.** Queue card, price, or four decision KPIs. Not a chart row.
2. **One primary action per screen.** One filled button or one sticky bar slot. A second filled primary is not allowed.
3. **Thumb reach.** Primary actions sit in the bottom 96px above the gesture inset, or on the card itself. Not in a top-right 24px icon.
4. **One column below 700px.** Two columns only for the KPI grid.
5. **Cards, not tables,** for every primary workflow.
6. **Pages for long work.** Property, lead, MFA, reports, portal builder.
7. **Sheets for short work.** Filters, reasons, confirms, 1–4 fields.
8. **Sticky actions** when the user must finish the screen: Call, Save, Apply, Next.
9. **Progressive disclosure.** Remarks, amenities, raw JSON, and secondary KPIs start collapsed.
10. **Same business truth.** Status names, permissions, and KPI math do not change.

---

## 5. Device and breakpoint strategy

Design targets:

| Name | Logical px |
|---|---|
| Small | 360×800 |
| Standard | 390×844 |
| Large | 412×915 |
| XL | 430×932 |

One layout system. Width changes density, not the product.

| Band | Rule |
|---|---|
| 320–359 | Same as 360. Horizontal padding 12. Bottom-nav label hidden if it would clip; icon remains with semantics label. KPI grid stays 2 columns. Card image 80×80. |
| 360–389 | Base phone. Padding 16. Image 96×96. |
| 390–411 | Base phone. No extra columns. |
| 412–429 | Base phone. Section gap may use 24. |
| 430–699 | Still the phone IA. Content max width 560, centered. Do not restore the sidebar. |
| 700+ | Existing desktop shell (`ModernSidebar`) and current desktop screens. This spec does not redesign desktop. |

Portrait is the designed orientation. At 700+ landscape, desktop layout applies. Below 700, landscape keeps the same one-column stack. **REQUIRES RUNTIME VERIFICATION** for Android 16 large-screen orientation rules.

---

## 6. Design tokens

Use `CRMColors`, `CRMTypography`, `CRMSpacing`, `CRMBorderRadius`. Do not add a second palette.

Primary is **not** a new hex. It is `ThemeManager.currentTheme`:

| Preset already in `theme_presets.dart` | Light | Dark |
|---|---|---|
| Terracotta | `#C15D4A` | `#D47A66` |
| Green | `#159B73` | `#10B981` |

| Token | Light | Dark | Use |
|---|---|---|---|
| primary | theme `primaryLight` | theme `primaryDark` | One filled action, selected tab, links |
| primary container | `terracottaSoft` `#F6D8D0` when terracotta; otherwise 12% primary | 16% primary | Selected chip background |
| secondary | theme secondary | theme secondary | Secondary emphasis only. Not a second primary button |
| background | `#F7F9FC` | `#0F172A` | Screen |
| surface / card | `#FFFFFF` | `#1E293B` | Cards, sheets, inputs |
| surface elevated | `#FFFFFF` | `#243044` | Sticky bars |
| border | `#E8ECF2` | `#334155` | Card and input hairline, 1px |
| text primary | `#14213D` | `#F8FAFC` | Titles, numbers, body |
| text secondary | `#68738A` | `#94A3B8` | Meta, captions |
| text muted | `#94A3B8` | `#64748B` | Placeholders |
| disabled | `#E5E5E4` | `#423C37` | Disabled fill. Text at 40% opacity |
| success | `#5F8064` / bg `#D7E8D8` | same fg | Won, connected, synced |
| warning | `#C4924A` / bg `#F6E4C8` | same fg | Callback due, paused |
| error | `#C15D4A` / bg `#F6D8D0` | same fg | Destructive, failed, CNR overdue if product already uses danger |
| info | `#647B7A` / bg `#E9EFEE` | same fg | Neutral status, syncing |
| overlay | `#66000000` | `#99000000` | Sheet scrim |
| on primary | `#FFFFFF` | `#FFFFFF` | Label on filled primary |

Rent vs resale accent already exists (`rentAccent` charcoal, `resaleAccent` theme primary). Use it only as a listing-type chip, not as a second button color.

Status chips map existing campaign/lead statuses to these semantics. Do not invent new status names.

| Status family already in the product | Chip |
|---|---|
| New, Pending | info |
| Follow up, Callback, Call Back | warning |
| CNR | warning |
| Not interested | error, outline not fill |
| Won, Listed, Connected, Active | success |
| Paused, Draft | info |
| Error | error |

---

## 7. Typography

Family: `CRMTypography` (DM Sans; system font on iOS). Do not introduce another family.

Mobile overrides existing sizes only where Step 1 required 16px in forms. Map them to tokens:

| Role | Token | Size | Weight | Height | Tracking | Max lines | Overflow |
|---|---|---|---|---|---|---|---|
| KPI number | `statistics` | 28 | 700 | 1.15 | -0.6 | 1 | ellipsis, tabular figures |
| Hero (property price) | `largeTitle` | 28 | 700 | 1.2 | -0.5 | 1 | ellipsis |
| Screen title | `title` | 20 | 600 | 1.3 | -0.3 | 1 | ellipsis |
| Section title | `headline` | 18 | 600 | 1.3 | -0.3 | 1 | ellipsis |
| Card title | `cardTitle` | 15 | 600 | 1.35 | 0 | 1 | ellipsis |
| Body | mobile body | 16 | 400 | 1.45 | 0 | 3 on cards, unlimited in detail | ellipsis on cards |
| Body emphasis | mobile body medium | 16 | 500 | 1.45 | 0 | 2 | ellipsis |
| Meta | `subheadline` | 13 | 400 | 1.4 | 0 | 1 | ellipsis |
| Caption / time | `caption` | 12 | 400 | 1.4 | 0 | 1 | ellipsis |
| Caption strong | `captionBold` | 12 | 600 | 1.4 | 0 | 1 | ellipsis |
| Input text | mobile body | 16 | 400 | 1.45 | 0 | 1 (4 if notes) | scroll inside field |
| Placeholder | mobile body | 16 | 400 | 1.45 | 0 | 1 | ellipsis, `textMuted` |
| Validation | `caption` | 12 | 400 | 1.4 | 0 | 2 | wrap, `danger` |
| Chart label | `chartLabel` | 11 | 500 | 1.3 | 0 | 1 | ellipsis |
| Button | `button` at 16 on mobile | 16 | 600 | 1.2 | 0 | 1 | ellipsis |

Do not use `pageTitle` 28 or `heroStatistic` 40 on phone screens. Those stay desktop.

Text scale: layouts must not clip at 1.3×. At 1.3×, card meta may drop to 1 line. **REQUIRES RUNTIME VERIFICATION** above 1.3×.

---

## 8. Spacing

Scale already in `CRMSpacing`: 4, 8, 12, 16, 24, 32. Do not use 20 on phone.

| Use | Token | px |
|---|---|---|
| Icon to label | xs | 8 |
| Chip gap, inline meta gap | xs | 8 |
| List card gap | s | 12 |
| Form field gap | s | 12 |
| Screen horizontal padding | m | 16 (12 only in 320–359) |
| Card padding | m | 16 |
| Section gap | l | 24 |
| Sticky bar top padding | s | 12 |
| Bottom clearance above nav | 16 + nav 64 + safe bottom | — |
| Sheet top radius padding | m | 16 |

---

## 9. Touch targets

| Control | Min size |
|---|---|
| Icon button | 48×48 |
| Primary / secondary / destructive button | height 48, full width when sticky, min width 120 when inline |
| Bottom nav item | height 64, width equal share |
| List card | min height 88, full width |
| Checkbox, radio, switch | 48×48 hit area; control visual may be 24 |
| Chip | height 32, horizontal padding 12, hit area height 40 |
| Dropdown | height 56, full width |
| Date/time trigger | height 56, full width |
| Search field | height 48 |

---

## 10. Mobile shell

Used under 700px for every signed-in route that today sits in `CRMAppShell`.

**App bar.** Height 56. Background `surface`. Bottom border 1px `border`. Padding horizontal 4.

- Back: 48×48, icon `arrow_back_rounded`, only when the route is not a tab root.
- Title: `title` 20, start-aligned, 8px after the back slot. One line.
- Search icon: 48×48, opens full-screen search (section 27). Hidden on wizards and detail.
- Overflow: 48×48, only when the screen has tertiary actions. Opens a selection sheet, not a tiny popup, when there are more than three items.
- Notifications: the existing notification entry may stay as a 48×48 icon if the shell already shows a count. Badge is an 8px dot, not a second nav item. **REQUIRES RUNTIME VERIFICATION** of the exact bell behavior on phone.

**Bottom navigation.** Height 64 plus safe bottom. Surface, top border 1px. Five slots maximum. Selected item uses primary icon and `captionBold`. Unselected uses `textSecondary`. Labels always visible from 360px up.

**Center plus.** Not a sixth tab. It is the last concept from Step 1, implemented as the trailing action of the Queue/Leads tab app bar (48×48 primary filled circle, 40px visual inside a 48 hit target), not a floating button over content. Actions:

- Telecaller: Add lead (short wizard).
- Sales and Admin: sheet with Add lead, Add property.
- Super Admin: same as Admin. Add integration is not in this sheet.

**Safe area.** Top and bottom insets respected. Sticky bars add `MediaQuery.padding.bottom`.

**Keyboard.** `resizeToAvoidBottomInset` true. Sticky CTA scrolls above the keyboard. Sheets use `isScrollControlled` and padding `viewInsets.bottom`.

**Status bar.** Light icons on dark theme, dark icons on light theme. No brand-colored status bar.

**Transitions.** Forward: horizontal slide 250ms, ease-out. Back: reverse. Sheet: vertical 220ms. No other page animation.

Tab roots have no back button. System back from a tab root goes to the role home, then exits the app. System back from a pushed page pops one route.

---

## 11. Role navigation

Tabs are routes, not indexed views that forget state.

### Telecaller

| Slot | Label | Route |
|---|---|---|
| 1 | Queue | `/campaign/leads` locked to the calling queue (active, not archives) |
| 2 | Callbacks | `/telecaller/callbacks` |
| 3 | CNR | `/telecaller/cnr` |
| 4 | Leads | `/requirements` |
| 5 | More | `/more` (new presentation route in Step 3; not a backend change) |

Home after login: Queue. Do not land on `/dashboard`.

### Sales

| Slot | Label | Route |
|---|---|---|
| 1 | Leads | `/requirements` filtered to that user where the API already supports `assignedTo` |
| 2 | Properties | `/properties` |
| 3 | Visits | `/requirements` with the existing site-visit status filter. **REQUIRES RUNTIME VERIFICATION** of the exact status string used for site visit |
| 4 | More | `/more` |

Dashboard KPIs are inside More → Home summary, not the first tab.

### Admin

| Slot | Label | Route |
|---|---|---|
| 1 | Home | `/dashboard` |
| 2 | Leads | `/requirements` |
| 3 | Properties | `/properties` |
| 4 | Reports | `/reports/leads/overall-business-insight` |
| 5 | More | `/more` |

### Super Admin

Same five tabs as Admin. Audit logs, sync debug, and super-admin metrics appear only inside More.

Campaign management stays in More for Admin and Super Admin. It is absent for Telecaller, matching `!isTelecaller` in `ModernSidebar`.

---

## 12. More architecture

Route presentation: full screen, not a drawer. Grouped list. Row height 64. Icon 24 in a 40 circle, `primary` at 12% opacity. Title `cardTitle`. Subtitle `caption`, `textSecondary`. Chevron 20. Gap between groups 24.

| Group | Row | Subtitle | Who | Goes to |
|---|---|---|---|---|
| Account | Profile | Name and role | all | `/profile` |
| Account | Security | Password and MFA | all | profile security section |
| Work | Home summary | KPIs | SL, and TC only as a secondary link | `/dashboard` |
| Work | Lead allocation | Workload | SA AD if `page` allows `/admin/lead-allocation` | that route |
| Work | Employees | Team | SA AD if employee permission | `/users` |
| Work | Campaign | Connections and portals | SA AD, not TC | `/campaign/connections` |
| Work | Reports | Insight | SA AD; hidden for TC | reports home |
| Reference | Library | Rental, resale, agents | if `page.library` | `/library` |
| Reference | Recycle bin | Deleted listings | if `/bin` allowed | `/bin` |
| Reference | Messages | Team inbox | if `/messages` allowed | `/messages` |
| System | Settings | App and org | if `/settings` allowed | `/settings` |
| System | Audit logs | Super admin | SA only | `/settings/audit-logs` |
| System | Sync debug | Super admin | SA only | sync debug screen |

No badges until a count API is already on the row. Do not invent counts.

---

## 13. Screen specification template

Every screen below follows this contract:

- **Entry:** tab, push, or sheet as stated.
- **Exit:** tab switch, pop, or save-then-pop.
- **Scroll:** vertical only, unless the gallery says otherwise.
- **Loading / empty / error / offline / denied:** section 29.
- **Back:** pop one level. Dirty forms use the discard sheet.
- **Keyboard:** section 10.
- **Permission:** hide the action if the role cannot do it. If a deep link hits a forbidden route, show the permission state. The API still enforces.
- **Desktop at 700+:** keep the current screen. Do not force this phone layout onto desktop in Step 3.

Acceptance for each screen: the primary CTA is visible without scrolling on 360×800, except wizards where the CTA is the sticky bar.

---

## 14. Authentication

### MOB-001 Splash

Full screen, `background`. Center mark 64. One line caption “Opening PropKart”. No dialog unless session check fails: then the error state with Retry. No marketing carousel.

### MOB-002 Get started

One column, padding 24. Mark, `title` “PropKart”, body “Sign in to your workspace”. Primary “Continue” full width, 16 above the safe bottom, goes to `/login`. Terms and Privacy are text buttons under it.

### MOB-003 Login

Fields: email (email keyboard), password (obscured). Gap 12. Primary “Sign in” sticky. Error under the field or one banner if the API rejects the pair: “Email or password is incorrect.” Do not show the raw API body. MFA success continues to MOB-068 as a **page**, not a dialog.

### MOB-004 Reset password

Fields: new password, confirm. Sticky “Update password”. Success: “Password updated” and a button to Login.

### MOB-068 MFA

Page title “Verification code”. One numeric field, number keyboard, 6 digits if the current API expects a code. **REQUIRES RUNTIME VERIFICATION** of code length. Primary “Verify”. Back returns to login and clears the code.

---

## 15. Dashboards

### Admin and Super Admin home (`/dashboard`)

Above the fold, 2-column grid, gap 12:

1. Total Leads (KPI-02)
2. Leads Allocated (KPI-04)
3. Site Visits Done (KPI-06)
4. Deal Won (KPI-07). Do not also show “Deals Won”.

Carousel under that, height 104, gap 12: Available Inventory, Telecallers, Assigned to Sales, Sales Users. One card visible plus a peek of 24px.

Below: “Needs attention” list, max 5 rows, existing schedule/recent items that the dashboard already loads. Each row height 72.

Primary CTA: none on the dashboard. Tapping a KPI pushes the drilldown list. Filters: icon button opens the filter sheet.

Sales users do not use this as a tab. If they open Home summary from More, show only KPI-02, KPI-06, KPI-07 plus their own recent leads. Hide Telecallers and Sales Users.

Telecallers do not get this screen as home. A link in More may open it read-only.

### Sales dashboard widget

Do not mount `SalesDashboardScreen` tables on the phone. The three numbers above are enough. Team tables stay on desktop.

---

## 16. Properties

### List MOB-011

App bar “Properties”, search, overflow (sort). Body: active filter chips, then cards.

**Property card.** Height auto, min 112. Padding 12. Image 96×96, radius 12, cover. To the right, 12px gap: price `cardTitle` 15/700, locality `subheadline`, third line “BHK · area · listing type” caption. Status chip top-aligned. Call icon button 48 only if a phone exists on the record. The card itself opens detail. No table. No donut row on this screen. Mix chart moves to More → Reports or a single optional entry at the bottom: “Listing mix”, one chart card.

Sort sheet: the sort fields the list already supports. **REQUIRES RUNTIME VERIFICATION** of the exact sort keys.

### Search

Full-screen search. Context “Properties”. Results use the same card. See section 27.

### Detail MOB-012

Order, all full width, padding 16:

1. Gallery, height 220, 16:10 crop, page dots. Tap opens viewer.
2. Price, `largeTitle`.
3. Locality, `subheadline`.
4. Status and listing-type chips.
5. Core facts, two-column wrap only for short pairs (BHK, area, furnishing, floor). Each pair is a stacked label 12 and value 16. Gap 12.
6. Amenities, collapsed chips. “Show all” if more than 6.
7. Description, body, collapsed after 4 lines.
8. Remarks, collapsed.
9. Metadata (created, updated) caption, last.

Sticky bar height 64: Call, WhatsApp, Share. Each is equal width, icon 20 + label 12. Call and WhatsApp hidden if there is no number. Share uses the platform sheet. Edit is the overflow action, not a fourth sticky button. Delete is overflow, then confirm sheet naming the property.

### Add and edit MOB-013

Four steps. Progress “1 of 4” caption under the title. Sticky Next / Save.

| Step | Fields in order |
|---|---|
| 1 Basics | Listing type, transaction (rent/resale), BHK, property type, price or rent, deposit if rent |
| 2 Location | City, locality, area text, landmark if the form already has it |
| 3 Media | Photos then videos, using existing pickers as sheets |
| 4 Details | Furnishing, amenities, description, remarks, owner contact |

Exact field names must match the current form model. Do not add fields the form does not save. **REQUIRES RUNTIME VERIFICATION** to freeze the full field list from `add_edit_property_screen.dart` during implementation. Required fields stay required. Validation under the field. Back on step 1 with dirty state opens discard sheet.

### Filters

Sheet. Sections: listing type, BHK, price range, locality, status. Apply sticky. Chips above the list.

### Gallery, video, zoom

Viewer is full screen, black background `#000000`. Swipe horizontal between images. Pinch zoom in the zoom viewer that already exists. Close 48×48 top start. Video uses the existing slider, one video at a time, no autoplay of the next file.

### Recycle bin MOB-015

Same property card plus “Deleted” caption. Sticky is not used. Row actions: Restore (primary text), Delete permanently (destructive text). Delete opens a confirm sheet.

---

## 17. Leads

### Lead card

Min height 96. Padding 16. Line 1: name `cardTitle`. Line 2: phone `bodyMedium` 16. Line 3: budget · locality · source, caption. Status chip on the trailing edge. Call 48×48 if phone exists. Card tap opens detail.

### Lead list MOB-016

Title “Leads”. Telecaller label in More is not used on this tab; the tab is “Leads”. Search and filter. Rent / resale stays a segmented control height 36 under the app bar, because those tabs already exist via `initialTab`. Do not add a third visual style.

### Lead detail

Full page. Order: name, phone (tap to call), status chip, budget, locality, requirement type, timeline, remarks. Sticky: Call. Overflow: Edit, Assign (if permitted), Match, Change status.

### Add lead

Wizard, three steps. Sticky Next / Save.

| Step | Fields |
|---|---|
| 1 Contact | Name, phone, alternate phone, email |
| 2 Need | Requirement type, property type, BHK, transaction |
| 3 Budget and area | Budget min, budget max, city, locality, remarks |

Telecaller add uses the same wizard. Do not show admin-only assignment on step 1.

### Edit

Same wizard, fields filled, title “Edit lead”, sticky Save.

### Match

Sheet max 90%. Title “Matching properties”. List of property cards. Tap opens property detail. Empty: “No matches for this lead.”

### Assignment

Admin/super-admin only. Sheet: search people, one tap assigns. Success snackbar “Assigned to {name}”.

### Status transitions

All use a selection sheet titled with the lead name. Required fields and statuses stay the current enums. Do not add stages.

| Transition | UI | Required | Success |
|---|---|---|---|
| Follow-up | sheet: date, time, note | date | return to list, chip Follow up |
| Callback | same pattern as follow-up if the product treats them as different queues | date | item leaves the calling queue and appears on Callbacks |
| CNR | confirm sheet, optional note | none | item moves to CNR queue |
| Not interested | reason sheet, reasons already in the product | reason | leaves queue |
| Site visit | date sheet | date | status updates |
| Negotiation | selection only if this status exists | **REQUIRES PRODUCT DECISION** if no distinct status exists. Do not invent one |
| Won | sheet, then property pick if `RequirementWinPropertySelectionDialog` is required today | property when the current dialog requires it | status Won |
| Lost | reason sheet | reason if the current NI/lost flow requires it | status updated |
| Picked up | confirm | none | status updated |

Call history and remarks are sections on the detail timeline, newest first. A remark composer is one field at the bottom of the timeline, not a dialog.

---

## 18. Telecaller

Home is the queue. Card is the lead card plus source. No archives on this tab. Follow-ups that are due today stay in this queue if that is the current calling-queue rule (Step 1: follow-ups are not callbacks; due means the scheduled day is before today). Do not merge Callbacks into this list.

**Outcome bar** after the user taps Call, stuck to the bottom, height 64, four equal text buttons: CNR, Callback, Not interested, Picked up. This bar is the primary action. It does not show before Call is tapped, so the card stays readable.

**Call.** `tel:` via the existing launcher. There is no in-app call timer unless one already exists. **REQUIRES RUNTIME VERIFICATION.** Do not design a fake timer.

**Callback scheduling.** Sheet: date, time, note. Save returns to the queue and removes the card.

**Not interested.** Sheet: existing reasons as radio rows min height 48. Save.

**Remark.** Optional field on those sheets, max 4 lines. Not a second page.

**Next lead.** After save, the next card is at the top. No “next” wizard.

**Counts.** App bar subtitle caption: “{n} in queue” from the list length already loaded. Do not call a new API for this.

**Empty.** “No leads in this queue.” Text button “Check callbacks”.

**Availability / break.** Not a screen today. **REQUIRES RUNTIME VERIFICATION.** If the telecaller dashboard has no control, do not invent a shift system. A single status row can be added later only if product confirms the existing availability values the telecaller is allowed to set.

**Targets from Step 1, unchanged:** CNR with no remark under 20 seconds. Callback with a note under 40 seconds. These are design targets, not measured results.

**Taps:** open app already on queue (0) → call on card (1) → outcome (2) → save on the sheet (3). Call itself is one of those three primary taps.

---

## 19. Sales

1. Leads tab, cards scoped to the signed-in user when the list API already filters by user. If it does not, show the same list the sales role sees today and mark the filter **REQUIRES RUNTIME VERIFICATION**.
2. Lead detail as in section 17.
3. Match sheet.
4. Site visit from the status sheet.
5. Pipeline: **REQUIRES PRODUCT DECISION.** `PipelineScreen` is behind the clients redirect. Do not build a new pipeline. Use lead status on the detail until product restores that module.
6. Won / lost from the status sheet.
7. Add property from the Leads/Properties plus sheet, wizard in section 16.
8. Profile from More.

---

## 20. Admin

Home: section 15.  
Lead allocation: two cards per active telecaller, height 88. Name, workload “{n} / {capacity}”, status chip. Primary “Allocate” in the app bar, one button. Confirm sheet: “Allocate up to {batch} untouched leads?” with the existing batch field. Default batch stays the current default. Telecaller detail is a page of four KPIs plus a lead list, not 13 cards and not a dialog.

Employees: user cards, height 72. Name, role, caption. Tap opens detail.

Employee detail: header (avatar 64, name, role, phone). Then four KPIs in a 2-column grid. Remaining metrics from the current 13-card strip go in a “Performance” list of rows height 56. Do not drop the data; change the layout.

Team, telecaller, and sales performance on the phone are the report lists in section 21, not new dashboards.

---

## 21. Reports

One phone pattern for every live report:

1. App bar title, filter icon, export in overflow.
2. Date chip under the bar, height 32.
3. KPI stack, one column, gap 12. Not a grid of eight.
4. One chart card, width 100% of the padding box, height 200, legend under the plot, `chartLabel` 11.
5. “View records” pushes a full-screen card list. That replaces `LeadDrilldownDialog`, KPI expand, and user-performance dialog tables.

| Screen | Phone content |
|---|---|
| Overall insight MOB-040 | KPI stack from the cards that screen already builds, one chart (funnel or trend, not both above the fold). Second chart below the fold. |
| Telecaller report | List of people cards, not `telecaller_leads_table`. Tap opens that person’s lead cards. |
| Sales report MOB-043 | Empty state: “Sales report is not available yet.” No fake chart. |
| Lead metrics MOB-044 | Same pattern as insight. Ignore the placeholder class. |
| Super-admin metrics | Same pattern. Org switcher is a sheet if the screen already has an org control. **REQUIRES RUNTIME VERIFICATION.** |
| Property reports | Empty state: “Property reports are not available yet.” |

Export stays the existing menu actions, opened from overflow as a sheet. Print is omitted below 700px.

Filters: one sheet (section 28), not two bars.

---

## 22. Campaign

### Connections MOB-023

Title “Connections”. Cards already match the phone: one column, min height 88. Meta and Housing keep their current status words. Portal cards keep name, type, status. Primary on the page is the app-bar plus: Add integration. Google Sheets stays inside that flow, not a new tab.

### Meta and Housing settings

Full pages, one column. Secret values masked. Save sticky. Do not redesign the protocol. Only the layout.

### Portal wizard MOB-026 / MOB-087

Keep 8 steps: Basic, Authentication, Request, Parameters, Response, Mapping, Sync, Test. One column. Each dynamic row is a stacked card (label, field, remove 48×48), not a 3-column wrap. Credential entry is a sheet. Test result is a summary list, not a table. Activate is the sticky primary on step 8, disabled until the test passes unless the existing override checkbox is on.

### Portal leads, source drilldown, assigned leads

Same lead card as section 17. Title is the portal or source name. No second table.

Campaign archives (not interested, listed) are overflow entries on the queue: “Not interested” and “Archives”, each a full-screen list. They are not segments on the telecaller home.

---

## 23. Libraries

Library home: three rows, height 72. Rental, Resale, Service agents.  
Each library list uses the property card or a user card for agents. KPI strips become a 2-column grid of at most four, or one card if the screen only has one. Popups of more than three actions become a sheet. Priority: Medium. They live under More.

---

## 24. Settings

Settings home is a grouped list, not `_activeSection` side-by-side.

Rows, each pushing a page:

1. Profile  
2. Security  
3. Appearance (theme presets already in the product)  
4. Notifications — **REQUIRES RUNTIME VERIFICATION.** If no settings section exists, do not add a fake one. Omit the row.  
5. Matching threshold  
6. Upload limits  
7. Locations  
8. KPI configuration  
9. Permissions (admin)  
10. Audit logs (link, super admin)  
11. Sync debug (super admin)

Location config: list of cities. Add is a sheet (name field). Areas under a city are a second page. Tabs stay in the data, not as a desktop tab bar.

Permissions: one switch per permission row, height 56. Not a matrix table. Group by the existing feature groups.

Audit log: card per event. Title action, caption actor and time. Tap opens payload on a page. Filter sheet.

---

## 25. Profile

Header: avatar 72, name `title`, role caption, phone, email.  
Rows: Security, MFA, Appearance, Logout.  
Logout is last, `danger` text, confirm sheet “Log out of PropKart?”.  
MFA enroll/disable is a page when a code must be typed.

---

## 26. Messages

`/messages` is the inbox, full screen, list rows height 72. The messenger dialog is not the phone inbox. Thread is a page. Composer sticky, 56 plus send 48. **REQUIRES RUNTIME VERIFICATION** whether the shell currently opens the dialog first. Step 3 should route the bell or Messages row to `/messages`.

---

## 27. Public share

No shell, no bottom nav. Share pack is a list of property cards. Shared property uses the detail order from section 16 without Edit, Delete, or CRM metadata. Sticky Call and WhatsApp only, using the agent number passed on the link.

---

## 28. KPI system

Canonical names. Do not show both Deal Won and Deals Won. Keep **Deal Won** (KPI-07). KPI-10 is the same metric.

| ID | Name | Phone visibility | Size | Tap |
|---|---|---|---|---|
| KPI-01 | Available Inventory | Admin carousel | carousel card | property list |
| KPI-02 | Total Leads | Admin above fold | 2-col | lead list |
| KPI-03 | Telecallers | Admin carousel | carousel | employee list |
| KPI-04 | Leads Allocated | Admin above fold | 2-col | allocation or lead list. **REQUIRES RUNTIME VERIFICATION** of current tap target |
| KPI-05 | Assigned to Sales | Admin carousel | carousel | lead list filtered if the filter exists |
| KPI-06 | Site Visits Done | Admin above fold; sales More home | 2-col | lead list with visit filter if it exists |
| KPI-07 | Deal Won | Admin above fold; sales More home | 2-col | lead list won filter if it exists |
| KPI-08 | Sales Users | Admin carousel | carousel | employee list |
| KPI-09 | Active Requirements | Admin, under the grid, metric row height 48 | row | `/requirements` |
| KPI-11–21 | Existing `CRMKPICard` strips | 2-col, max 4 on phone; extra cards move to a “More stats” list | card | the list that screen already opens |

Definitions and formulas stay server-side. This table does not redefine them.

**2-column grid.** Used for the four admin decisions and for up to four strip KPIs. Width: `(screen − 32 padding − 12 gap) / 2`. Height 104. Padding 16. Number `statistics` 28, one line. Label `caption` 12, two lines max, ellipsis. Delta `captionBold` 12, success or danger, hidden if the API has no delta. Icon 20, optional, trailing top. Whole card is the tap target.

**Carousel.** Used for KPI-01, 03, 05, 08. Card width 70% of the content width, height 104, gap 12, snap. No dots required; the peek shows that it scrolls.

Report-only metrics stay on the report page, one column, height 88.

Loading: skeleton 104. Error: “Couldn’t load” and Retry on the card. Empty number: “—” not “0”, unless the API returns 0.

---

## 29. Table conversion

| Table | Mobile primary | Secondary | Hidden until detail | Actions |
|---|---|---|---|---|
| Campaign queue | Name, phone | Source, status | Columns the desktop customizer exposes | Call, open |
| Properties | Photo, price, locality | BHK, area, type | Owner, remarks, audit | Call, open |
| Requirements | Name, phone | Budget, locality, status | Full requirement | Call, open |
| Recycle bin | Photo, price | Deleted time | Rest of listing | Restore, delete |
| Report drilldown | Name, phone, status | Source, date | Remaining columns | Open lead |
| Telecaller report | Person, outcome count | Calls | Lead ids | Open person |
| Team ranking | Rank, name, value | — | — | Open person |
| Users | Name, role | Phone | KPIs | Open |
| Audit | Action, time | Actor | Payload | Open |
| Permission matrix | Permission name | Group | — | Switch |
| Service agents | Name, phone | Service | Notes | Call, open |
| Sales dashboard tables | Name, value | — | — | Open |
| Clients, owners, builders | — | — | — | Do not convert until route decision |

No horizontal scroll. Sort moves to a sheet. Filters move to the filter sheet. Lists page in batches of 30. Load more at 80% scroll. Bulk select is omitted on phone except allocation’s existing batch action. Empty and error use section 30.

---

## 30. Dialog, sheet, and page rules

| Current | Replacement | Why |
|---|---|---|
| 21 campaign dialogs that edit or confirm disposition | Outcome sheets and the lead page | Keyboard and queue speed |
| Property form dialogs (10) | Wizard page | Length |
| Requirement stepper dialog | 3-step page | Length |
| KPI drilldown dialogs (12) plus lead drilldown | Full-screen list | Tables in dialogs |
| Delete / logout alerts | Confirm sheet, 40% max | Thumb, named object |
| MFA dialog | Page | Keyboard |
| PDF options | Sheet 50% | Short choice |
| Dashboard notes and schedule | Sheet | Short form |
| Messenger dialog | Thread page | It is a destination |
| Filter dialogs | One filter sheet, 85% max, scroll, sticky Apply | Consistency |
| Portal credential alert | Sheet | Four fields |
| Session expiry and forced app update | Dialog, not dismissible by scrim | Blocking |
| Date and time | Platform pickers | Native |
| Popup menus with more than 3 items | Sheet titled with the record | 48px rows |
| Report export popup | Sheet | Short list |
| Profile overflow of 3 or fewer | Popup remains allowed | Small |

Sheet scrim tap cancels except when Apply is required; then scrim does not apply filters. Dirty short forms ask “Discard changes?” in a second sheet.

---

## 31. Forms

Input height 56. Radius `CRMBorderRadius.input` 12. Fill `surface`. Border 1px `border`, focused 1.5px primary. Error border `danger`. Helper and error `caption` 12, 4px under the field. Required mark is a 4px primary dot before the label, plus “required” in the semantics label.

Keyboard: phone → phone, email → email, money and area → number, notes → text, 4 lines min.

Focus order is visual order. On save failure, scroll to the first error. Sticky Save shows a spinner and ignores a second tap. Success pops the page. Failure shows the field error or one banner. Back with dirty state: “Discard changes?” Discard / Keep editing.

Login, reset, settings sliders, and portal steps follow this. Property and lead wizards follow sections 16 and 17.

---

## 32. Search

One full-screen search. Entry: app-bar search icon.

- Field height 48, autofocus, clear 48×48.
- Debounce 300ms. **REQUIRES RUNTIME VERIFICATION** if a different debounce already exists; keep the existing delay if it does.
- Recent searches: do not add. Step 1 found no store. Hint: “Type a name, phone, or locality.”
- Results: the card type of the context (property, lead, person).
- Empty: “No matches” and Clear.
- Loading: three skeleton cards.
- Error: section 30 banner and Retry.
- Back: pop, query discarded.

Contexts: Properties, Leads, Campaign queue, Libraries, Employees. Same chrome. Different result card and API. `/search` and `PropertySearchScreen` should open this one UI in Step 3. **REQUIRES RUNTIME VERIFICATION** which of those is wired today.

---

## 33. Filters

Trigger: filter icon, badge count of active filters.  
Chips under the app bar, height 32, removable.  
Sheet: grabber 4×32, title “Filters”, sections, Clear all as text, Apply sticky.  
Three or fewer boolean/chip filters apply on tap and do not need Apply. Price range, date range, and locality use Apply.  
Back or scrim closes without applying when Apply is present.  
Persistence: keep the in-memory filters the screen already keeps. Do not add a new saved-filter store.

---

## 34. Loading, empty, error, offline

| State | UI |
|---|---|
| Skeleton | Grey block `#E8ECF2` / dark `#334155`, radius 12, pulse 1200ms. Match card height. |
| Spinner | Only inside a button or a first-load center if there is no skeleton yet. 24px. |
| Empty | Icon 32, title 20, body 16, one primary button if an action exists. |
| Error | Title “Something went wrong.” Body one sentence. Retry. Never Dio, stack traces, or JSON. |
| Offline, cache exists | Show the cache. Caption “Offline · last updated {time}”. |
| Offline, no cache | “You’re offline” and Retry. Do not say there is no data. |
| Syncing | 16px caption “Syncing” under the app bar. Not a blocking page. |
| Pending local writes | Caption “Waiting to sync”. **REQUIRES RUNTIME VERIFICATION** of whether Isar queues user edits or only caches reads. |
| Sync failed | Banner “Sync failed” and Retry. |
| Success | Pop or update the card. Snackbar only for background actions, one at a time, 4s. |
| Permission denied | Title “You don’t have access.” Body “Ask an admin if you need this.” One button to the role home. |
| Session expired | Blocking dialog “Session ended.” Button “Sign in”. |

---

## 35. Accessibility

- Hit targets in section 9.
- Every icon button has a semantics label equal to its tooltip.
- Status uses text plus color, not color alone.
- Focus order follows visual order.
- Contrast of text primary on surface is the token pair above. Decorative terracotta on white **REQUIRES RUNTIME VERIFICATION** against WCAG.
- Support text scale to 1.3× without clipping the sticky CTA.
- Destructive actions name the object in the sheet title.

---

## 36. Gestures

| Gesture | Where | Alternative |
|---|---|---|
| Pull to refresh | Queues, lists, reports | Retry on error |
| Horizontal swipe | Gallery only | Next/previous 48px buttons |
| Sheet drag | All sheets | Close button 48 |
| Pinch zoom | Image viewer only | Double-tap if the viewer already supports it. **REQUIRES RUNTIME VERIFICATION** |

Do not swipe-to-delete leads or change status by gesture.

---

## 37. Motion

Page 250ms horizontal. Sheet 220ms vertical. Skeleton pulse 1200ms. Button press: opacity 0.85, 80ms. No confetti, no chart animation longer than 300ms. Success is the updated card, not a full-screen animation.

---

## 38. Performance rules (UI only)

- Phone lists request 30 rows, not 1000. Further pages on scroll. The 1000 limit in campaign fetch stays a desktop path unless Step 3 splits the call. Do not change the API contract; pass the existing limit parameter.
- Cards must be lazy children (`ListView.builder`).
- Gallery decodes to the displayed width × device pixel ratio, not the original file. **REQUIRES RUNTIME VERIFICATION** of current decode size.
- Chart painters must not rebuild with the parent list. One widget, one repaint boundary.
- One snackbar at a time.
- Queue, list, and detail are separate routes so the 12,000-line campaign widget is not built for a phone card. Step 3 may extract a phone widget that reads the same BLoC. That is a presentation split, not a rule change.

---

## 39. Responsive rules

Summarized from section 5. No screen may add its own breakpoint except the gallery height (200 on 320–359, 220 from 360 up) and padding 12 vs 16.

At 700px the phone shell is not mounted. `ModernSidebar` and the current pages remain.

---

## 40. Component library

Implement these as phone widgets in Step 3. Dimensions are the contract.

| Component | Size | Variants | Do not |
|---|---|---|---|
| MobileAppBar | 56 | root, back | Put tabs in it |
| MobileBottomNav | 64 + safe | per role | Exceed 5 items |
| MoreMenu | row 64 | groups in section 12 | One flat list |
| MobileSearch | field 48 | contextual results | A second search style |
| FilterChip | 32 / hit 40 | on, off, removable | Paragraph text |
| FilterSheet | max 85% | apply, instant | A full form |
| KpiCard | 104 tall | grid, carousel | Sparkline on phone home |
| PropertyCard | image 96, min 112 | list, match, bin | Tiny grid |
| LeadCard | min 96 | queue, track | Table row |
| UserCard | 72 | employee, rank | 13 KPIs |
| ActivityCard | min 72 | timeline row | — |
| Timeline | full width | remarks, calls | A table |
| StatusChip | 28 | semantic colors | New status names |
| PrimaryButton | 48 | sticky, inline | Two on one screen |
| SecondaryButton | 48 outline | — | As the only way to finish |
| DestructiveButton | 48 fill danger | sheet only | Beside primary as equal |
| MobileTextField | 56 | error, disabled | 14px input text |
| MobileDropdown | 56 | sheet if options > 8 | Desktop menu |
| MobileDatePicker / TimePicker | trigger 56 | platform | Custom calendar unless one exists |
| EmptyState | center | with one button | Blank page |
| ErrorState | center | retry | Exception text |
| OfflineState | banner or center | cache / no cache | “No data” when cache exists |
| SyncIndicator | caption 16 | syncing, failed | Blocking modal |
| SkeletonCard | matches card | list, kpi | Spinner for lists |
| ChartCard | height 200 | one series | Side legend |
| SectionHeader | 18/600 | — | — |
| StickyActionBar | 64 + safe | 1 primary or 3 equal contact actions | 4 equal primaries |
| ConfirmationSheet | max 40% | destructive, neutral | Long forms |
| SelectionSheet | max 70% | radios 48 | Hidden gestures |
| MediaGallery | height 220 | dots | Autoplay carousel of mixed video |
| MediaViewer | full screen | zoom, video | CRM chrome |

---

## 41. Screen master table

| ID | Screen | Role | Priority | Layout | Primary CTA | Navigation | Pattern | Status |
|---|---|---|---|---|---|---|---|---|
| MOB-001 | Splash | PUB | P3 | center | none | auto | loader | DESIGN COMPLETE |
| MOB-002 | Get started | PUB | P2 | column | Continue | push login | page | DESIGN COMPLETE |
| MOB-003 | Login | PUB | P1 | form | Sign in | push MFA or home | page | DESIGN COMPLETE |
| MOB-004 | Reset password | PUB | P2 | form | Update | pop | page | DESIGN COMPLETE |
| MOB-005 | Terms | PUB | P3 | scroll | none | pop | page | DESIGN COMPLETE |
| MOB-006 | Privacy | PUB | P3 | scroll | none | pop | page | DESIGN COMPLETE |
| MOB-007 | Not found | all | P1 | center | Home | go role home | error | DESIGN COMPLETE |
| MOB-008 | Admin home | SA AD | P0 | KPI grid | none | tabs | dashboard | DESIGN COMPLETE |
| MOB-009 | Telecaller on dashboard route | TC | P0 | not home | — | redirect to queue | — | REQUIRES RUNTIME VERIFICATION |
| MOB-010 | Sales dashboard tables | SL | P1 | do not show | — | More summary | — | DESIGN COMPLETE |
| MOB-011 | Properties | SA AD SL | P0 | cards | open card | tab | list | DESIGN COMPLETE |
| MOB-012 | Property detail | permitted | P0 | stack | Call | push | detail | DESIGN COMPLETE |
| MOB-013 | Property wizard | SA AD SL | P0 | 4 steps | Next/Save | push | wizard | DESIGN COMPLETE |
| MOB-014 | Property search | permitted | P1 | search | none | push | search | REQUIRES RUNTIME VERIFICATION |
| MOB-015 | Recycle bin | permitted | P2 | cards | Restore | More | list | DESIGN COMPLETE |
| MOB-016 | Leads | all | P0 | cards | open / call | tab | list | DESIGN COMPLETE |
| MOB-017 | Lead wizard | permitted | P0 | 3 steps | Next/Save | push | wizard | DESIGN COMPLETE |
| MOB-018 | Share pack | PUB | P1 | cards | open | public | list | DESIGN COMPLETE |
| MOB-019 | Shared property | PUB | P1 | stack | Call | public | detail | DESIGN COMPLETE |
| MOB-020 | Calling queue | TC SA AD | P0 | cards | Call | TC home tab | queue | DESIGN COMPLETE |
| MOB-021 | Source leads | SA AD | P2 | cards | open | push | list | DESIGN COMPLETE |
| MOB-022 | Assigned leads | SA AD | P2 | cards | open | push | list | DESIGN COMPLETE |
| MOB-023 | Connections | SA AD | P2 | cards | Add | More | list | DESIGN COMPLETE |
| MOB-024 | Meta settings | SA AD | P2 | form | Save | push | page | DESIGN COMPLETE |
| MOB-025 | Housing settings | SA AD | P2 | form | Save | push | page | DESIGN COMPLETE |
| MOB-026 | Portal wizard | SA AD | P2 | 8 steps | Next/Activate | push | wizard | DESIGN COMPLETE |
| MOB-027 | Portal leads | SA AD | P2 | cards | open | push | list | DESIGN COMPLETE |
| MOB-028 | Callbacks | TC | P0 | cards | Call | tab | queue | DESIGN COMPLETE |
| MOB-029 | CNR | TC | P0 | cards | Call | tab | queue | DESIGN COMPLETE |
| MOB-030 | Follow-up card | TC | P1 | card on queue | open | queue | card | DESIGN COMPLETE |
| MOB-031 | Telecaller leads wrapper | TC | P2 | — | — | — | — | REQUIRES RUNTIME VERIFICATION |
| MOB-032 | Allocation | SA AD | P1 | cards | Allocate | More | list | DESIGN COMPLETE |
| MOB-033 | Telecaller detail | SA AD | P1 | 4 KPIs + list | none | push | page | DESIGN COMPLETE |
| MOB-034 | Employees | SA AD | P1 | cards | open | More | list | DESIGN COMPLETE |
| MOB-035 | Employee detail | SA AD | P1 | 4 KPIs + list | none | push | page | DESIGN COMPLETE |
| MOB-036–039 | Libraries | permitted | P2 | cards | open | More | list | DESIGN COMPLETE |
| MOB-040 | Insight | SA AD | P1 | stack | View records | tab | report | DESIGN COMPLETE |
| MOB-041 | Telecaller report | SA AD | P1 | people cards | open | push | report | DESIGN COMPLETE |
| MOB-042 | Super-admin metrics | SA | P2 | stack | View records | More | report | REQUIRES RUNTIME VERIFICATION |
| MOB-043 | Sales report | SA AD | P3 | empty | none | push | empty | DESIGN COMPLETE |
| MOB-044 | Lead metrics | SA AD | P2 | stack | View records | push | report | DESIGN COMPLETE |
| MOB-045 | Property reports | SA AD | P3 | empty | none | push | empty | DESIGN COMPLETE |
| MOB-046 | Metrics placeholder | — | — | — | — | — | — | DEPRECATE |
| MOB-047 | Settings | permitted | P2 | grouped list | none | More | list | DESIGN COMPLETE |
| MOB-048 | Audit logs | SA | P2 | cards | open | More | list | DESIGN COMPLETE |
| MOB-049 | Locations | SA AD | P2 | list + sheet | Add | push | list | DESIGN COMPLETE |
| MOB-050 | KPI config | SA AD | P2 | switches | Save | push | form | DESIGN COMPLETE |
| MOB-051 | Sync debug | SA | P3 | existing content, one column | Retry | More | page | DESIGN COMPLETE |
| MOB-052 | Profile | all | P2 | header + rows | none | More | page | DESIGN COMPLETE |
| MOB-053 | Messages | permitted | P2 | list | open | More | list | REQUIRES RUNTIME VERIFICATION |
| MOB-054 | Messenger dialog | permitted | P2 | — | — | — | page instead | DESIGN COMPLETE |
| MOB-055 | Integration screen | — | — | — | — | — | — | DEPRECATE |
| MOB-056–062 | Clients, owners, builders, pipeline | — | — | — | — | — | — | REQUIRES PRODUCT DECISION |
| MOB-063 | Home | — | — | — | — | — | — | DEPRECATE |
| MOB-064 | Placeholder | — | — | — | — | — | — | DEPRECATE |
| MOB-065–067 | Gallery, zoom, video | permitted | P1 | viewer | close | push | media | DESIGN COMPLETE |
| MOB-068–070 | MFA, update | all | P1 | page or blocking dialog | Verify / Update | push | page | DESIGN COMPLETE |
| MOB-071–074 | Report dialogs | SA AD | P1 | — | — | — | full-screen list | DESIGN COMPLETE |
| MOB-075–077 | Requirement dialogs | permitted | P0 | — | — | — | wizard or sheet | DESIGN COMPLETE |
| MOB-078 | Phone bar | all | P0 | 5 tabs | role home | shell | nav | DESIGN COMPLETE |
| MOB-079–083 | Report chrome | SA AD | P1 | chips and sheet | Apply | in report | chrome | DESIGN COMPLETE |
| MOB-084–086 | Pickers | permitted | P1 | sheet or platform | Save | overlay | picker | DESIGN COMPLETE |
| MOB-087 | Portal steps | SA AD | P2 | included in MOB-026 | Next | wizard | steps | DESIGN COMPLETE |

---

## 42. Component decision matrix

| Existing | Current | Mobile | Reason | Priority |
|---|---|---|---|---|
| ModernSidebar | side nav | bottom nav + More under 700 | Thumb, role jobs | P0 |
| `_buildSidebarContent` | unused | not in the design | Dead duplicate | P1 |
| Data tables | grid | cards or switch list | Section 29 | P0 |
| AlertDialog forms | modal | page or sheet | Keyboard | P0 |
| KPI row of 8 | wrap | 4 grid + carousel | Hierarchy | P0 |
| Donut row | beside list | one chart card on reports | Not the list | P2 |
| Popup menus | 24px anchor | sheet if >3 items | Hit target | P1 |
| Property wide detail | drawer file | stacked page | Call must stick | P0 |
| Employee 13 KPIs | grid | 4 + list | Scroll | P1 |
| Multiple search boxes | several | one full-screen search | Consistency | P2 |
| Deal Won and Deals Won | two labels | one: Deal Won | Duplicate | P1 |

---

## 43. Workflows

**Telecaller.** Login → Queue. Tap call (1) → outcome (2) → sheet save (3) → next card. Failure: banner, card remains. Offline: show cached queue if present; Call still opens the dialer; save shows “Waiting to sync” only if a local queue exists (**REQUIRES RUNTIME VERIFICATION**).

**Sales.** Login → Leads → card → detail → Match sheet → property page → status sheet → Won or Lost. Back pops one page.

**Admin.** Login → Home → KPI → record list → lead or user page → the one action that page allows.

**Property.** Properties → card (1 tap) → detail → Call (1 tap).

**Add lead.** Plus → Contact → Need → Budget → Save. Back on step 1 discards only after confirm.

---

## 44. Task efficiency

| Task | Target |
|---|---|
| Start a call from the queue | 1 tap on the card |
| Save CNR | 2 taps after the call (CNR, confirm) |
| Save callback | 3 taps after the call (Callback, pickers count as the sheet, Save) |
| Add lead | 3 steps, one sticky button each |
| Open property | 1 tap from the card |
| Call from property detail | 1 tap on the sticky bar |
| Apply a complex filter | open, change, Apply |

Do not collapse Won-with-required-property into one tap. The current dialog requires a property. Keep that step.

---

## 45. RBAC

- Missing permission: row absent in More and action absent on the page.
- Deep link to a forbidden route: permission state, not a blank page and not a crash.
- Super-admin-only: Audit logs, sync debug, super-admin metrics.
- Admin-only: allocation, employees (unless the permission flag says otherwise), campaign builder.
- Telecaller: no campaign tree, no allocation, no audit.
- Disabled is not a substitute for hidden when the user can never perform the action.
- UI hiding is not security. Existing API checks stay.

---

## 46. Duplication control

| Item | Decision |
|---|---|
| Two sidebars | KEEP `ModernSidebar` at 700+. DEPRECATE `_buildSidebarContent` from the design. |
| Integration screen | DEPRECATE. Route already redirects. |
| Lead metrics placeholder | DEPRECATE if unreferenced. |
| Sales and property report placeholders | KEEP as empty states. |
| Clients, owners, builders, pipeline | REQUIRES PRODUCT DECISION. Do not design phone screens. |
| HomeScreen, CRMPlaceholderScreen | DEPRECATE if unreferenced. |
| Deal Won / Deals Won | KEEP ONE name: Deal Won. |
| Campaign list component | KEEP ONE data source. Phone chrome is separate. |
| Search entry points | MERGE into MobileSearch. |
| Dialog patterns | MERGE into sheet, page, or blocking dialog. |

No code is deleted in this step.

---

## 47. Implementation phases

| Phase | Build | Depends on | Done when | Regression risk |
|---|---|---|---|---|
| M0 | Tokens usage, shell, bars, states | none | 360px shell renders | Desktop shell must stay at 700+ |
| M1 | Role tabs and homes | M0 | TC lands on queue; admin lands on home | Login redirect |
| M2 | Queue, callbacks, CNR, outcomes | M1 | CNR and callback targets reachable in 3 taps | Lead status rules |
| M3 | Property cards, detail, wizard, bin | M0 | No property table under 700 | Media upload |
| M4 | Lead cards, detail, 3-step add, match | M2 | Requirements usable as cards | Assignment permissions |
| M5 | Sales tab set | M4 | Visits tab uses existing status | Wrong filter |
| M6 | Admin allocation and employees | M1 | Allocate confirm sheet | Batch size rules |
| M7 | Reports pattern | M0 | Drilldown is a page | KPI math |
| M8 | More, settings list, profile | M0 | Logout confirm | MFA |
| M9 | Connections and portal one-column | M8 | Wizard still saves | Credential masking |
| M10 | Libraries and public share | M3 | Share has no CRM edit | Public links |
| M11 | Pagination, semantics, snackbar single | all | 30-row pages, labels on icons | List truncation |

---

## 48. Acceptance criteria

- Telecaller’s first screen is the queue.
- Admin’s first screen is the four-KPI home.
- Callbacks and CNR are tabs for telecallers.
- No primary list under 700px is a horizontally scrolling table.
- Property and lead create are wizards, not alerts.
- Deal Won appears once on the admin home.
- Sticky Call is visible on property detail on 360×800.
- Icon buttons used on phone expose semantics labels.
- Error UI contains no “DioException”.
- Offline with cache still shows the list.
- Forbidden deep links show the permission state.
- 700px and above still uses `ModernSidebar` and current desktop pages.

---

## 49. QA checklist

For every screen marked DESIGN COMPLETE:

- [ ] Role matches section 41
- [ ] Tab or More entry matches section 11–12
- [ ] App bar 56, title 20
- [ ] One primary CTA
- [ ] Padding 16, gaps from section 8
- [ ] Type from section 7
- [ ] Targets from section 9
- [ ] Skeleton, empty, error, offline, denied
- [ ] Back and dirty discard
- [ ] Keyboard does not cover Save or Apply
- [ ] Vertical scroll only, except gallery
- [ ] Semantics on icon buttons
- [ ] Checked at 360, 390, 412, and 430 widths
- [ ] Desktop unchanged at 700+

---

## 50. Runtime verification register

| Item | Why | How | Result |
|---|---|---|---|
| Telecaller branch inside DashboardScreen | Step 1 could not prove the widget split | Sign in as telecaller, open `/dashboard` | Open |
| Which search `/search` mounts | Two search UIs | Tap shell search and visit `/search` | Open |
| TelecallerLeadsScreen vs campaign queue | Wrapper may be unused | Breakpoint on both constructors | Open |
| LeadMetricsPlaceholderScreen references | May be dead | Search call sites at implementation | Open |
| Drawer open gesture for sidebar on phone | Affects old nav only | Not required once bottom nav exists | Open |
| Report KPI captions from API | Labels are payload-driven | Load insight, list captions | Open |
| CNR and callback elapsed time | Targets are design goals | Timed task on device | Open |
| Telecaller break/offline control | Not found as a screen | Inspect telecaller home on device | Open |
| Notifications settings section | Not found | Read settings sections | Open |
| Recent searches | No store found | Confirm no local history | Open |
| Contrast | Not measured | WCAG check on device | Open |
| Semantics of icon buttons | Tooltips exist on desktop | TalkBack pass | Open |
| Tablet orientation / Android 16 | Manifest does not lock orientation | Rotate a tablet | Open |
| Image decode size | Cache may still fetch full files | Network trace one gallery | Open |
| Per-screen offline copy | Isar coverage varies | Airplane mode on queue and properties | Open |
| Pending write queue | May be read-cache only | Edit offline, observe copy | Open |
| Messages: dialog vs route | Both exist | Tap Messages | Open |
| IntegrationScreen push sites | Route redirects | Search `Navigator.push` | Open |
| List views that are not named ListView | Custom scrollables | Implementation pass | Open |
| Empty-state copy inventory | Heuristic count was rejected | Read each empty branch | Open |
| Property sort keys | Not frozen here | Read properties query | Open |
| Site visit status string | Sales Visits tab | Read status enum | Open |
| Sales “my leads” filter | May be client-side | Watch the request | Open |
| KPI-04 and KPI-06 tap targets | Not proven | Tap each KPI | Open |
| Super-admin org switcher | May not exist | Open metrics as super admin | Open |
| MFA code length | Not read in this pass | Read verify API | Open |
| In-app call timer | Probably absent | Place a test call | Open |
| Gallery double-tap zoom | Viewer exists | Pinch and double-tap | Open |
| Debounce duration | Spec says 300ms unless code differs | Read search listener | Open |
| Campaign 1000 limit on phone | Performance | Log the query from the phone widget | Open |

---

## 51. Future-state scores

These score the design in this document, not the current app, and not a device build.

| Area | Score | Why |
|---|---|---|
| Hierarchy | 8 | Role homes show the next action. Secondary KPIs move to a carousel or More. |
| Readability | 8 | 16px inputs, 28px KPI numbers, one-column cards. |
| Touch | 8 | 48px controls. Not device-verified. |
| Navigation | 9 | Role tabs match Step 1. |
| Spacing | 8 | Existing 4/8/12/16/24/32 scale with fixed uses. |
| Typography | 8 | Existing tokens, one mobile size override. |
| Density | 8 | Four KPIs, cards, collapsed sections. |
| Efficiency | 8 | Call in one tap from the queue. Won still needs the property step. |
| Accessibility | 7 | Labels and targets specified. Contrast unverified. |
| Clarity | 8 | One card pattern and one status map. |
| Discoverability | 8 | Sticky CTAs and role tabs. |
| Errors | 8 | One error pattern. Raw exceptions banned. |
| Loading | 8 | Skeletons for lists and KPIs. |
| Empty | 8 | Title, reason, one action. |
| Offline | 7 | Cache vs empty is specified. Pending-write behavior is unverified. |
| **Overall** | **8/10** | Not measured on a device. |

---

## 52. Final design rules

1. Under 700px, do not mount the desktop sidebar as the way to reach Queue, Callbacks, or CNR.
2. Do not ship a phone table for leads, properties, or reports.
3. Do not open property or lead creation in an `AlertDialog`.
4. Do not show Deal Won twice.
5. Do not invent statuses, KPIs, or notification settings.
6. Do not design Clients, Owners, Builders, or Pipeline until product decides.
7. Do not change allocation, matching, or permission rules to fit a layout.
8. At 700px and above, leave the current desktop UI in place.

---

## PROPKART MOBILE UI/UX MASTER SPECIFICATION COMPLETE

### Exact design scope

- Screens specified: all MOB-001–MOB-087 rows in section 41
- KPIs specified: KPI-01–KPI-11 and the card-strip rule for KPI-11–21
- Dialogs classified: section 30, covering the 152 call sites by category
- Bottom sheets classified: filters, confirms, short forms, pickers, export
- Forms specified: login, reset, MFA, property wizard, lead wizard, portal wizard, settings
- Tables converted: section 29, 12 active tables plus 3 held for a product decision
- Workflows specified: telecaller, sales, admin, property, add lead
- Components specified: 31 in section 40
- States specified: section 34
- Role navigation specified: Telecaller, Sales, Admin, Super Admin

### Open decisions

Runtime verification: the 29 rows in section 50.  
Product decisions: Clients, Owners, Builders, and Pipeline (restore or leave hidden). Negotiation as a status if it is not already a status. Telecaller self-serve break if no control exists.  
Deprecated from the design, not deleted: `_buildSidebarContent`, Integration screen, lead-metrics placeholder, HomeScreen, CRMPlaceholderScreen.

### Top 20 implementation priorities

1. Phone shell and role tabs (M0–M1).  
2. Telecaller lands on the queue.  
3. Callbacks and CNR as telecaller tabs.  
4. Queue lead card and Call button.  
5. Outcome bar and CNR sheet.  
6. Callback sheet.  
7. Not-interested reason sheet.  
8. Property cards.  
9. Property detail sticky Call / WhatsApp / Share.  
10. Property 4-step wizard.  
11. Lead cards on `/requirements`.  
12. Lead 3-step wizard.  
13. Lead detail timeline.  
14. Match sheet.  
15. Admin four-KPI home and Deal Won once.  
16. Report drilldown as a page.  
17. Allocation cards and confirm sheet.  
18. Employee detail reduced to four KPIs plus a list.  
19. More, settings list, profile logout sheet.  
20. List pagination at 30, single snackbar, semantics labels.

### Final principle

> **PropKart mobile is not a smaller desktop application. It is a purpose-built mobile operating experience using the same business truth, APIs, permissions and database architecture.**

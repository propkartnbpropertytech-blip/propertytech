# Change Plan — Support New UI (Step 2)

## 1. Task Metadata
- **Task Title**: Implement New_UI Support page from HTML prototype
- **Target Subsystem**: Flutter Presentation — Support
- **Assigned Agent Role**: UI / UX implement engineer

## 2. Objective & Scope
- **Primary Objective**: Restyle Support to match `support.html` (hero, KPIs, contact ways, raise-ticket form, my tickets, FAQ) while preserving SupportService, RBAC (`page.support.report_issue`), catalog/registry, and IssueDetailsDrawer.
- **Non-Goals**: Super-admin dashboard, backend API changes, push to remote, CreateIssueModal rewrite (kept for tests / advanced wizard).
- **Authoritative Source**: SupportService → PostgreSQL support issues

## 3. Files Allowed
- `lib/features/support/screens/support_screen.dart`
- `lib/features/support/widgets/support_ui/**` (new)
- `docs/ai-agent/change-plans/2026-03-25-support-new-ui.md`
- Additive report under `docs/ai-agent/reports/`

## 4. Strategy
1. Page-local tokens + overflow-safe widgets (hero, KPI, contact, FAQ, ticket row, form chrome).
2. Rebuild SupportScreen layout; wire inline raise-ticket form to SupportNavigationRegistry + SupportService.createIssue.
3. Ticket rows open existing IssueDetailsDrawer; KPI cards filter status.
4. Verify analyze + support role-based tests. Do not push.

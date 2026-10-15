import 'package:flutter/material.dart';
import '../../../core/security/role_guard.dart';

/// Categories of functions to determine tailored issue types
enum SupportFunctionCategory {
  kpi,
  filter,
  table,
  form,
  action,
  upload,
  integration,
  security,
  general,
}

/// A specific selectable function, KPI, button, or feature within a page
class SupportFunctionItem {
  final String key;
  final String name;
  final SupportFunctionCategory category;
  final String? badge;
  final IconData? icon;

  const SupportFunctionItem({
    required this.key,
    required this.name,
    this.category = SupportFunctionCategory.general,
    this.badge,
    this.icon,
  });
}

/// A nested subpage (e.g. Campaign -> Meta, Settings -> Themes)
class SupportSubpageItem {
  final String key;
  final String title;
  final String route;
  final IconData icon;
  final String? description;
  final List<SupportFunctionItem> functions;

  const SupportSubpageItem({
    required this.key,
    required this.title,
    required this.route,
    required this.icon,
    this.description,
    required this.functions,
  });
}

/// A top-level sidebar page for Support issue reporting
class SupportPageItem {
  final String key;
  final String title;
  final String route;
  final IconData icon;
  final String? description;
  final List<SupportSubpageItem> subpages;
  final List<SupportFunctionItem> directFunctions;

  const SupportPageItem({
    required this.key,
    required this.title,
    required this.route,
    required this.icon,
    this.description,
    this.subpages = const [],
    this.directFunctions = const [],
  });

  bool get hasSubpages => subpages.isNotEmpty;
}

/// Central registry providing role-based sidebar pages, nested subpages,
/// authentic granular functions (including individual KPIs), and tailored issue options.
class SupportNavigationRegistry {
  /// Tailored issue options for each function category (all ending with 'Other')
  static List<String> getIssueOptionsForFunction(SupportFunctionItem function) {
    switch (function.category) {
      case SupportFunctionCategory.kpi:
        return const [
          'Incorrect KPI count',
          'KPI data not updating',
          'KPI not loading / showing 0',
          'Date filter not working',
          'Incorrect data in drilldown dialog',
          'Drilldown dialog not opening',
          'Function not working',
          'Other',
        ];
      case SupportFunctionCategory.filter:
        return const [
          'Search returned no results or incorrect results',
          'Filter selection not updating the list',
          'Date range filter not applying',
          'Filter reset button not working',
          'Search auto-complete or dropdown missing',
          'Function not working',
          'Other',
        ];
      case SupportFunctionCategory.table:
        return const [
          'Data rows missing or not loading',
          'Pagination not working or skipping pages',
          'Column sorting not functioning',
          'Table columns clipped or layout broken',
          'Data not refreshing after change',
          'Function not working',
          'Other',
        ];
      case SupportFunctionCategory.form:
        return const [
          'Form validation error or unable to submit',
          'Data not saving after clicking submit',
          'Dropdown options missing or empty',
          'Input field not accepting text or numbers',
          'Form closing unexpectedly or resetting',
          'Function not working',
          'Other',
        ];
      case SupportFunctionCategory.action:
        return const [
          'Button click does nothing',
          'Download or export failed / corrupted file',
          'Generated output or PDF has incorrect data',
          'Action timed out with error message',
          'Status did not update after action',
          'Function not working',
          'Other',
        ];
      case SupportFunctionCategory.upload:
        return const [
          'Image / file upload failed',
          'Image preview not loading',
          'File size error or upload rejected',
          'Upload stuck at 0% or timeout',
          'Function not working',
          'Other',
        ];
      case SupportFunctionCategory.integration:
        return const [
          'Incoming webhook leads not appearing',
          'API connection disconnected or expired',
          'Duplicate leads not filtered out',
          'Field mapping incorrect or missing',
          'Function not working',
          'Other',
        ];
      case SupportFunctionCategory.security:
        return const [
          'Under Development screen not appearing',
          'Toggle switch not saving state',
          'Permission denied unexpectedly',
          'Incorrect role access applied',
          'Function not working',
          'Other',
        ];
      case SupportFunctionCategory.general:
        return const [
          'Function not working',
          'Incorrect data or count',
          'Data not saving or updating',
          'Error message or unexpected behavior',
          'Slow performance or freezing',
          'UI or display issue',
          'Access or permission issue',
          'Other',
        ];
    }
  }

  /// Builds the authoritative list of pages and subpages for [rawRole].
  /// Matches the exact sidebar items of that role.
  static List<SupportPageItem> getPagesForRole(String rawRole) {
    final role = rawRole.trim();
    final isSuper = RoleGuard.isSuperAdmin(role);
    final isAdmin = RoleGuard.isAdmin(role) || isSuper;
    final isTelecaller = RoleGuard.isTelecaller(role);
    final isSales = RoleGuard.isSales(role) || role.toLowerCase() == 'salesperson';

    final pages = <SupportPageItem>[];

    // 1. Dashboard
    if (RoleGuard.canViewPage(role, '/dashboard') || role.isEmpty) {
      if (isTelecaller) {
        pages.add(SupportPageItem(
          key: 'dashboard',
          title: 'Dashboard',
          route: '/dashboard',
          icon: Icons.grid_view_rounded,
          description: 'Telecaller operational overview, performance metrics and calling queues',
          directFunctions: const [
            SupportFunctionItem(key: 'kpi_tc_open_leads', name: 'Open Leads KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.assignment_outlined),
            SupportFunctionItem(key: 'kpi_tc_new_allocated', name: 'New Leads Allocated KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.assignment_ind_rounded),
            SupportFunctionItem(key: 'kpi_tc_old_allocated', name: 'Old Leads Allocated KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.history_toggle_off_rounded),
            SupportFunctionItem(key: 'kpi_tc_assigned_to_sales', name: 'Assigned to Sales KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.badge_rounded),
            SupportFunctionItem(key: 'kpi_tc_not_interested', name: 'Not Interested Leads KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.do_not_disturb_on_rounded),
            SupportFunctionItem(key: 'kpi_tc_callback', name: 'Callback Leads KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.event_repeat),
            SupportFunctionItem(key: 'kpi_tc_cnr', name: 'CNR Leads KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.phone_missed_rounded),
            SupportFunctionItem(key: 'kpi_tc_total', name: 'Total Calling Leads KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.format_list_bulleted_rounded),
            SupportFunctionItem(key: 'tc_date_filter', name: 'Date Range Filter (Today, Weekly, Monthly, Yearly, Custom)', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.calendar_today_rounded),
            SupportFunctionItem(key: 'tc_lead_type_filter', name: 'Lead Type Filter (Rent, Sale, Both)', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.tune_rounded),
            SupportFunctionItem(key: 'tc_scheduled_followups', name: 'My Scheduled Follow-ups List & Actions', category: SupportFunctionCategory.table, badge: 'List', icon: Icons.schedule_rounded),
            SupportFunctionItem(key: 'tc_transferred_leads', name: 'Recent Leads Transferred to Sales Table', category: SupportFunctionCategory.table, badge: 'Table', icon: Icons.arrow_forward_rounded),
            SupportFunctionItem(key: 'tc_personal_notes', name: 'Personal Notes & Quick Task Sheet', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.note_alt_outlined),
            SupportFunctionItem(key: 'tc_kpi_drilldown', name: 'KPI Drilldown Inspection Dialog', category: SupportFunctionCategory.general, badge: 'Dialog', icon: Icons.open_in_new_rounded),
          ],
        ));
      } else if (isSales) {
        pages.add(SupportPageItem(
          key: 'dashboard',
          title: 'Dashboard',
          route: '/dashboard',
          icon: Icons.grid_view_rounded,
          description: 'Sales representative performance dashboard, follow-up calendar and daily notes',
          directFunctions: const [
            SupportFunctionItem(key: 'kpi_sales_available_inventory', name: 'Available Inventory KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.home_work_rounded),
            SupportFunctionItem(key: 'kpi_sales_site_visit_done', name: 'Site Visit Done KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.location_on_rounded),
            SupportFunctionItem(key: 'kpi_sales_active_leads', name: 'Active Leads KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.trending_up_rounded),
            SupportFunctionItem(key: 'kpi_sales_deals_won', name: 'Deals Won KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.emoji_events_rounded),
            SupportFunctionItem(key: 'kpi_sales_assigned_leads', name: 'Assigned Leads KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.badge_rounded),
            SupportFunctionItem(key: 'kpi_sales_new_leads', name: 'New Leads KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.fiber_new_rounded),
            SupportFunctionItem(key: 'kpi_sales_followups_due', name: 'Follow-ups Due KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.notification_important_rounded),
            SupportFunctionItem(key: 'kpi_sales_active_followups', name: 'Active Follow-ups KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.event_available_rounded),
            SupportFunctionItem(key: 'sales_date_filter', name: 'Performance Date Filter', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.calendar_today_rounded),
            SupportFunctionItem(key: 'sales_followup_calendar', name: 'Scheduled Site Visits & Follow-up Calendar', category: SupportFunctionCategory.table, badge: 'Calendar', icon: Icons.calendar_month_rounded),
            SupportFunctionItem(key: 'sales_daily_notes', name: 'Daily Notes & Follow-up Task List', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.note_alt_outlined),
            SupportFunctionItem(key: 'sales_kpi_drilldown', name: 'KPI Drilldown Inspection Dialog', category: SupportFunctionCategory.general, badge: 'Dialog', icon: Icons.open_in_new_rounded),
          ],
        ));
      } else {
        // Admin / Super Admin Dashboard
        pages.add(SupportPageItem(
          key: 'dashboard',
          title: 'Dashboard',
          route: '/dashboard',
          icon: Icons.grid_view_rounded,
          description: 'Executive overview, company-wide operations, and KPI metric cards',
          directFunctions: const [
            SupportFunctionItem(key: 'kpi_available_inventory', name: 'Available Inventory KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.home_work_rounded),
            SupportFunctionItem(key: 'kpi_total_leads', name: 'Total Leads KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.assignment_rounded),
            SupportFunctionItem(key: 'kpi_telecallers', name: 'Telecallers Count KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.support_agent_rounded),
            SupportFunctionItem(key: 'kpi_new_leads_allocated', name: 'New Leads Allocated KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.assignment_ind_rounded),
            SupportFunctionItem(key: 'kpi_old_leads_allocated', name: 'Old Leads Allocated KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.history_toggle_off_rounded),
            SupportFunctionItem(key: 'kpi_cnr', name: 'CNR (No Response) KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.phone_missed_rounded),
            SupportFunctionItem(key: 'kpi_not_interested', name: 'Not Interested KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.do_not_disturb_on_rounded),
            SupportFunctionItem(key: 'kpi_sales_users', name: 'Sales Users Count KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.groups_rounded),
            SupportFunctionItem(key: 'kpi_assigned_to_sales', name: 'Assigned to Sales KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.badge_rounded),
            SupportFunctionItem(key: 'kpi_site_visits_done', name: 'Site Visits Done KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.location_on_rounded),
            SupportFunctionItem(key: 'kpi_rejected_after_visit', name: 'Rejected After Visit KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.person_off_rounded),
            SupportFunctionItem(key: 'kpi_deal_won', name: 'Deal Won KPI', category: SupportFunctionCategory.kpi, badge: 'KPI Card', icon: Icons.emoji_events_rounded),
            SupportFunctionItem(key: 'dashboard_date_filter', name: 'Date Range & Role Filter (Today, Weekly, Monthly, Yearly, Custom)', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.date_range_rounded),
            SupportFunctionItem(key: 'dashboard_pipeline_funnel', name: 'Lead Pipeline Funnel & Stage Progression Bar', category: SupportFunctionCategory.general, badge: 'Visual', icon: Icons.filter_alt_rounded),
            SupportFunctionItem(key: 'dashboard_recent_properties', name: 'Recent Properties Inventory Feed & Pagination', category: SupportFunctionCategory.table, badge: 'Feed', icon: Icons.real_estate_agent_outlined),
            SupportFunctionItem(key: 'dashboard_todays_schedule', name: 'Today\'s Schedule & Appointments Card', category: SupportFunctionCategory.table, badge: 'Schedule', icon: Icons.event_note_rounded),
            SupportFunctionItem(key: 'dashboard_quick_actions', name: 'Quick Action Shortcuts (+ New Property / Lead / User)', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.add_circle_outline_rounded),
            SupportFunctionItem(key: 'dashboard_kpi_drilldown', name: 'KPI Drilldown Dialogs', category: SupportFunctionCategory.general, badge: 'Dialog', icon: Icons.open_in_new_rounded),
          ],
        ));
      }
    }

    // 2. Properties
    if (RoleGuard.canViewPage(role, '/properties') || role.isEmpty) {
      pages.add(SupportPageItem(
        key: 'properties',
        title: 'Properties',
        route: '/properties',
        icon: Icons.home_work_outlined,
        description: 'Complete real estate property listings directory for sale and rent',
        directFunctions: const [
          SupportFunctionItem(key: 'prop_search_filter', name: 'Search Bar, Budget, BHK & Location Filters', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.search_rounded),
          SupportFunctionItem(key: 'prop_card_view', name: 'Property Cards Grid & List View Toggle', category: SupportFunctionCategory.table, badge: 'View', icon: Icons.grid_view_rounded),
          SupportFunctionItem(key: 'prop_add', name: 'Add New Property Listing Form & Wizard', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.add_home_outlined),
          SupportFunctionItem(key: 'prop_edit', name: 'Edit / Update Property Details Form', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.edit_note_rounded),
          SupportFunctionItem(key: 'prop_view_details', name: 'Property View Details Drawer & Specifications', category: SupportFunctionCategory.general, badge: 'Drawer', icon: Icons.visibility_outlined),
          SupportFunctionItem(key: 'prop_share_pdf', name: 'Share Property (PDF Generation, Custom Field Filter & Download)', category: SupportFunctionCategory.action, badge: 'Export', icon: Icons.picture_as_pdf_outlined),
          SupportFunctionItem(key: 'prop_share_whatsapp', name: 'Share Property via WhatsApp', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.share_rounded),
          SupportFunctionItem(key: 'prop_matching_requirements', name: 'Matching Buyer Requirements Drawer', category: SupportFunctionCategory.general, badge: 'Matchmaker', icon: Icons.people_outline_rounded),
          SupportFunctionItem(key: 'prop_delete_archive', name: 'Archive Property / Move to Recycle Bin', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.delete_outline_rounded),
          SupportFunctionItem(key: 'prop_image_gallery', name: 'Photo & Media Gallery Upload / Preview', category: SupportFunctionCategory.upload, badge: 'Upload', icon: Icons.photo_library_outlined),
        ],
      ));
    }

    // Telecaller-only pages
    if (isTelecaller) {
      // My Calling Leads
      if (RoleGuard.canViewPage(role, '/campaign/leads') || RoleGuard.canViewPage(role, '/telecaller/leads')) {
        pages.add(SupportPageItem(
          key: 'telecaller_calling_leads',
          title: 'My Calling Leads',
          route: '/campaign/leads',
          icon: Icons.phone_in_talk_outlined,
          description: 'Allocated calling queue and lead outcome recording for Telecaller',
          directFunctions: const [
            SupportFunctionItem(key: 'tc_queue_table', name: 'Allocated Calling Queue Table & Search', category: SupportFunctionCategory.table, badge: 'Table', icon: Icons.table_chart_outlined),
            SupportFunctionItem(key: 'tc_queue_call_action', name: 'Call Action & Dial Number', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.phone_forwarded_rounded),
            SupportFunctionItem(key: 'tc_queue_record_outcome', name: 'Record Call Outcome (Interested, Callback, CNR, Wrong Lead)', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.rate_review_outlined),
            SupportFunctionItem(key: 'tc_queue_disposition', name: 'Call Disposition Sheet & Call Remarks', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.comment_bank_outlined),
            SupportFunctionItem(key: 'tc_queue_transfer', name: 'Transfer Lead to Salesperson / Peer', category: SupportFunctionCategory.action, badge: 'Transfer', icon: Icons.swap_horiz_rounded),
            SupportFunctionItem(key: 'tc_queue_filter', name: 'Filter Calling Leads by Status & Source', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.filter_list_rounded),
          ],
        ));
      }

      // Callbacks
      if (RoleGuard.canViewPage(role, '/telecaller/callbacks')) {
        pages.add(SupportPageItem(
          key: 'telecaller_callbacks',
          title: 'Callbacks',
          route: '/telecaller/callbacks',
          icon: Icons.event_repeat,
          description: 'Scheduled callbacks and follow-up appointment desk',
          directFunctions: const [
            SupportFunctionItem(key: 'tc_callbacks_list', name: 'Scheduled Callbacks Queue & Priority Badges', category: SupportFunctionCategory.table, badge: 'List', icon: Icons.format_list_bulleted_rounded),
            SupportFunctionItem(key: 'tc_callbacks_reschedule', name: 'Reschedule Callback Date & Time', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.update_rounded),
            SupportFunctionItem(key: 'tc_callbacks_complete', name: 'Mark Callback Completed & Log Outcome', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.check_circle_outline_rounded),
            SupportFunctionItem(key: 'tc_callbacks_filter', name: 'Date Filter (Today, Missed, Upcoming)', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.filter_alt_outlined),
          ],
        ));
      }

      // CNR / Retry
      if (RoleGuard.canViewPage(role, '/telecaller/cnr')) {
        pages.add(SupportPageItem(
          key: 'telecaller_cnr',
          title: 'CNR / Retry',
          route: '/telecaller/cnr',
          icon: Icons.phone_missed_outlined,
          description: 'Queue for leads where call was not connected or no response received',
          directFunctions: const [
            SupportFunctionItem(key: 'tc_cnr_queue', name: 'CNR (No Response) Leads List', category: SupportFunctionCategory.table, badge: 'List', icon: Icons.list_alt_rounded),
            SupportFunctionItem(key: 'tc_cnr_retry_call', name: 'Retry Call Action & Attempt Counter', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.replay_rounded),
            SupportFunctionItem(key: 'tc_cnr_archive', name: 'Move to Not Interested / Archive', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.archive_outlined),
          ],
        ));
      }
    }

    // 3. Leads
    if (RoleGuard.canViewPage(role, '/requirements') || role.isEmpty) {
      final leadTitle = isTelecaller ? 'All Leads (Track)' : 'Leads';
      pages.add(SupportPageItem(
        key: 'leads',
        title: leadTitle,
        route: '/requirements',
        icon: Icons.assignment_outlined,
        description: 'Buyer & tenant inquiries pipeline, requirement matching and tracking',
        directFunctions: const [
          SupportFunctionItem(key: 'lead_category_tabs', name: 'Category Tabs (All, Residential, Commercial, Land)', category: SupportFunctionCategory.filter, badge: 'Tabs', icon: Icons.tab_rounded),
          SupportFunctionItem(key: 'lead_search_filter', name: 'Search Bar, Budget, City, Area & Status Filters', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.search_rounded),
          SupportFunctionItem(key: 'lead_add', name: 'Add New Lead / Requirement Form', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.person_add_alt_1_rounded),
          SupportFunctionItem(key: 'lead_edit', name: 'Edit / Update Lead Details Form', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.edit_note_rounded),
          SupportFunctionItem(key: 'lead_view_details', name: 'Lead View Details Drawer & Activity History', category: SupportFunctionCategory.general, badge: 'Drawer', icon: Icons.visibility_outlined),
          SupportFunctionItem(key: 'lead_status_update', name: 'Update Status (Interested, Callback, Closed, Not Interested)', category: SupportFunctionCategory.action, badge: 'Status', icon: Icons.published_with_changes_rounded),
          SupportFunctionItem(key: 'lead_schedule_callback', name: 'Schedule Callback Date & Time Modal', category: SupportFunctionCategory.form, badge: 'Modal', icon: Icons.event_repeat_rounded),
          SupportFunctionItem(key: 'lead_transfer', name: 'Transfer / Reassign Lead to Agent', category: SupportFunctionCategory.action, badge: 'Transfer', icon: Icons.swap_horiz_rounded),
          SupportFunctionItem(key: 'lead_matching_properties', name: 'Matching Properties Matchmaker Drawer', category: SupportFunctionCategory.general, badge: 'Matchmaker', icon: Icons.home_work_outlined),
          SupportFunctionItem(key: 'lead_export', name: 'Export Leads to Excel / CSV', category: SupportFunctionCategory.action, badge: 'Export', icon: Icons.file_download_outlined),
          SupportFunctionItem(key: 'lead_delete_archive', name: 'Archive Lead / Move to Recycle Bin', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.delete_outline_rounded),
        ],
      ));
    }

    // 4. Employees (Admin only)
    if (isAdmin && (RoleGuard.canManageEmployees(role) || RoleGuard.canViewPage(role, '/users'))) {
      pages.add(SupportPageItem(
        key: 'employees',
        title: 'Employees',
        route: '/users',
        icon: Icons.people_outline_rounded,
        description: 'Employee roster, role permissions, and staff account management',
        directFunctions: const [
          SupportFunctionItem(key: 'emp_directory_table', name: 'Employee Directory Table & Role Filter', category: SupportFunctionCategory.table, badge: 'Table', icon: Icons.people_alt_outlined),
          SupportFunctionItem(key: 'emp_create', name: 'Create New Employee Account Modal', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.person_add_rounded),
          SupportFunctionItem(key: 'emp_edit', name: 'Edit Employee Profile, Role & Work Shift', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.manage_accounts_outlined),
          SupportFunctionItem(key: 'emp_status_toggle', name: 'Activate / Deactivate Employee Account', category: SupportFunctionCategory.security, badge: 'Security', icon: Icons.toggle_on_outlined),
          SupportFunctionItem(key: 'emp_password_reset', name: 'Reset Password / Temporary Password Generation', category: SupportFunctionCategory.security, badge: 'Security', icon: Icons.lock_reset_rounded),
          SupportFunctionItem(key: 'emp_performance_stats', name: 'View Agent Performance Stats & History', category: SupportFunctionCategory.general, badge: 'Analytics', icon: Icons.bar_chart_rounded),
        ],
      ));
    }

    // 5. Reports (Admin only)
    if (isAdmin && (RoleGuard.canViewReports(role) || RoleGuard.canViewPage(role, '/reports'))) {
      pages.add(SupportPageItem(
        key: 'reports',
        title: 'Reports',
        route: '/reports',
        icon: Icons.bar_chart_rounded,
        description: 'Business intelligence dashboard, telecaller reports, and sales leaderboard',
        subpages: const [
          SupportSubpageItem(
            key: 'reports_overall',
            title: 'Overall Business Insight',
            route: '/reports/leads/overall-business-insight',
            icon: Icons.insights_rounded,
            description: 'Overall pipeline conversion, deal statistics and volume charts',
            functions: [
              SupportFunctionItem(key: 'rep_biz_charts', name: 'Business Overview Charts & Pipeline Summary', category: SupportFunctionCategory.general, badge: 'Charts', icon: Icons.pie_chart_outline_rounded),
              SupportFunctionItem(key: 'rep_biz_date_filter', name: 'Report Date Range & Period Filter', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.date_range_rounded),
              SupportFunctionItem(key: 'rep_biz_export_pdf', name: 'Export Executive Business Report (PDF)', category: SupportFunctionCategory.action, badge: 'Export', icon: Icons.picture_as_pdf_outlined),
            ],
          ),
          SupportSubpageItem(
            key: 'reports_telecaller',
            title: 'Telecaller Performance',
            route: '/reports/leads/telecaller',
            icon: Icons.support_agent_rounded,
            description: 'Telecaller call volume, talk time, dispositions and transfer rates',
            functions: [
              SupportFunctionItem(key: 'rep_tc_metrics_table', name: 'Telecaller Call Attempts & Disposition Table', category: SupportFunctionCategory.table, badge: 'Table', icon: Icons.table_chart_outlined),
              SupportFunctionItem(key: 'rep_tc_date_filter', name: 'Telecaller Performance Date Filter', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.calendar_today_rounded),
              SupportFunctionItem(key: 'rep_tc_export', name: 'Export Telecaller Performance Report (PDF/Excel)', category: SupportFunctionCategory.action, badge: 'Export', icon: Icons.file_download_outlined),
            ],
          ),
          SupportSubpageItem(
            key: 'reports_sales',
            title: 'Sales Leaderboard',
            route: '/reports/leads/sales',
            icon: Icons.leaderboard_rounded,
            description: 'Sales representative leaderboard, site visit conversions and revenue closed',
            functions: [
              SupportFunctionItem(key: 'rep_sales_rankings', name: 'Sales Leaderboard & Revenue Generated Table', category: SupportFunctionCategory.table, badge: 'Table', icon: Icons.military_tech_outlined),
              SupportFunctionItem(key: 'rep_sales_deals_won', name: 'Deals Won & Site Visits Conversion Chart', category: SupportFunctionCategory.general, badge: 'Chart', icon: Icons.show_chart_rounded),
              SupportFunctionItem(key: 'rep_sales_export', name: 'Export Sales Leaderboard Report', category: SupportFunctionCategory.action, badge: 'Export', icon: Icons.file_download_outlined),
            ],
          ),
          SupportSubpageItem(
            key: 'reports_metrics',
            title: 'Lead Source Metrics',
            route: '/reports/leads/metrics',
            icon: Icons.source_rounded,
            description: 'Lead origin channels, cost per lead and source-wise ROI analysis',
            functions: [
              SupportFunctionItem(key: 'rep_source_analytics', name: 'Lead Source Breakdown (Meta, Housing, Website, Direct)', category: SupportFunctionCategory.general, badge: 'Analytics', icon: Icons.donut_large_rounded),
              SupportFunctionItem(key: 'rep_source_conversion', name: 'Source-wise Conversion Rate Analysis', category: SupportFunctionCategory.table, badge: 'Table', icon: Icons.analytics_outlined),
            ],
          ),
          SupportSubpageItem(
            key: 'reports_properties',
            title: 'Properties Overview',
            route: '/reports/properties',
            icon: Icons.domain_rounded,
            description: 'Inventory turnaround, unit sales velocity and vacancy breakdown',
            functions: [
              SupportFunctionItem(key: 'rep_prop_inventory_stats', name: 'Available vs Sold/Rented Inventory Breakdown', category: SupportFunctionCategory.general, badge: 'Stats', icon: Icons.inventory_2_outlined),
              SupportFunctionItem(key: 'rep_prop_export', name: 'Export Properties Inventory Summary', category: SupportFunctionCategory.action, badge: 'Export', icon: Icons.picture_as_pdf_outlined),
            ],
          ),
        ],
      ));
    }

    // 6. Campaign (Admin only: Connection, Meta, Housing)
    if (!isTelecaller && (RoleGuard.canAccessCampaign(role) || RoleGuard.canViewPage(role, '/campaign') || role.isEmpty)) {
      pages.add(SupportPageItem(
        key: 'campaign',
        title: 'Campaign',
        route: '/campaign',
        icon: Icons.campaign_outlined,
        description: 'Marketing campaign connections, Meta Ads webhook ingestion, and portal integrations',
        subpages: const [
          SupportSubpageItem(
            key: 'campaign_connections',
            title: 'Connection',
            route: '/campaign/connections',
            icon: Icons.hub_outlined,
            description: 'Meta Ads Facebook Page connection and Housing.com portal API setup',
            functions: [
              SupportFunctionItem(key: 'camp_conn_meta', name: 'Meta Ads Facebook Page Connection & OAuth', category: SupportFunctionCategory.integration, badge: 'Connection', icon: Icons.facebook_rounded),
              SupportFunctionItem(key: 'camp_conn_housing', name: 'Housing.com API Key & Connector Setup', category: SupportFunctionCategory.integration, badge: 'Connection', icon: Icons.apartment_outlined),
              SupportFunctionItem(key: 'camp_conn_webhook_secret', name: 'Webhook Secret Key & Verify Token Configuration', category: SupportFunctionCategory.security, badge: 'Security', icon: Icons.vpn_key_outlined),
              SupportFunctionItem(key: 'camp_conn_health', name: 'Integration Health Diagnostics & Activity Logs', category: SupportFunctionCategory.general, badge: 'Diagnostics', icon: Icons.monitor_heart_outlined),
            ],
          ),
          SupportSubpageItem(
            key: 'campaign_meta',
            title: 'Meta',
            route: '/campaign/meta',
            icon: Icons.campaign_outlined,
            description: 'Meta Ads webhook ingestion inbox, lead parsing, and telecaller assignment',
            functions: [
              SupportFunctionItem(key: 'camp_meta_inbox', name: 'Meta Ads Webhook Ingestion Inbox Table', category: SupportFunctionCategory.table, badge: 'Inbox', icon: Icons.inbox_rounded),
              SupportFunctionItem(key: 'camp_meta_assign', name: 'Single & Bulk Lead Assignment to Telecallers', category: SupportFunctionCategory.action, badge: 'Assignment', icon: Icons.assignment_ind_outlined),
              SupportFunctionItem(key: 'camp_meta_dedup', name: 'Lead Deduplication & Quality Filter Engine', category: SupportFunctionCategory.general, badge: 'Filter', icon: Icons.filter_alt_outlined),
              SupportFunctionItem(key: 'camp_meta_upload_csv', name: 'Spreadsheet / CSV File Upload & Field Mapping', category: SupportFunctionCategory.upload, badge: 'Upload', icon: Icons.upload_file_rounded),
              SupportFunctionItem(key: 'camp_meta_export', name: 'Export Meta Campaign Leads Data', category: SupportFunctionCategory.action, badge: 'Export', icon: Icons.file_download_outlined),
            ],
          ),
          SupportSubpageItem(
            key: 'campaign_housing',
            title: 'Housing',
            route: '/campaign/housing',
            icon: Icons.apartment_outlined,
            description: 'Housing.com portal webhook stream, buyer inquiries, and ingestion logs',
            functions: [
              SupportFunctionItem(key: 'camp_housing_inbox', name: 'Housing.com Ingestion Stream Table', category: SupportFunctionCategory.table, badge: 'Stream', icon: Icons.stream_rounded),
              SupportFunctionItem(key: 'camp_housing_assign', name: 'Auto-Assignment & Manual Lead Distribution', category: SupportFunctionCategory.action, badge: 'Distribution', icon: Icons.people_outline_rounded),
              SupportFunctionItem(key: 'camp_housing_error_logs', name: 'Housing API Ingestion Error Logs', category: SupportFunctionCategory.table, badge: 'Logs', icon: Icons.bug_report_outlined),
            ],
          ),
        ],
      ));
    }

    // 7. Lead Allocation (Admin only)
    if (isAdmin && (RoleGuard.canViewPage(role, '/admin/lead-allocation') || role.isEmpty)) {
      pages.add(SupportPageItem(
        key: 'lead_allocation',
        title: 'Lead Allocation',
        route: '/admin/lead-allocation',
        icon: Icons.hub_outlined,
        description: 'Live lead distribution monitor and telecaller shift tracker',
        directFunctions: const [
          SupportFunctionItem(key: 'alloc_live_table', name: 'Live Telecaller Allocation Table & Active Status', category: SupportFunctionCategory.table, badge: 'Table', icon: Icons.table_chart_outlined),
          SupportFunctionItem(key: 'alloc_manual_reassign', name: 'Manual Lead Re-allocation & Batch Transfer', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.swap_horiz_rounded),
          SupportFunctionItem(key: 'alloc_telecaller_shifts', name: 'Telecaller Shift & Attendance Tracker', category: SupportFunctionCategory.general, badge: 'Attendance', icon: Icons.schedule_rounded),
          SupportFunctionItem(key: 'alloc_rules_engine', name: 'Lead Redistribution Rules & Maximum Capacity Gauge', category: SupportFunctionCategory.form, badge: 'Rules', icon: Icons.speed_rounded),
          SupportFunctionItem(key: 'alloc_history', name: 'Allocation Audit Trail & Activity Logs', category: SupportFunctionCategory.table, badge: 'Audit', icon: Icons.history_rounded),
        ],
      ));
    }

    // 8. Library
    if (RoleGuard.canViewPage(role, '/library') || role.isEmpty) {
      pages.add(SupportPageItem(
        key: 'library',
        title: 'Library',
        route: '/library',
        icon: Icons.folder_outlined,
        description: 'Agreement templates, deed documents, and service provider contact directory',
        subpages: const [
          SupportSubpageItem(
            key: 'lib_rent',
            title: 'Rental Agreements',
            route: '/rental-library',
            icon: Icons.receipt_long_outlined,
            description: 'Standard residential and commercial rental agreement templates',
            functions: [
              SupportFunctionItem(key: 'lib_rent_templates', name: 'Rental Agreement Templates Directory', category: SupportFunctionCategory.table, badge: 'Templates', icon: Icons.description_outlined),
              SupportFunctionItem(key: 'lib_rent_download', name: 'Download Word / PDF Agreement Template', category: SupportFunctionCategory.action, badge: 'Download', icon: Icons.file_download_outlined),
              SupportFunctionItem(key: 'lib_rent_upload', name: 'Upload Custom Agreement Template', category: SupportFunctionCategory.upload, badge: 'Upload', icon: Icons.upload_file_outlined),
            ],
          ),
          SupportSubpageItem(
            key: 'lib_resale',
            title: 'Resale Agreements',
            route: '/resale-library',
            icon: Icons.handshake_outlined,
            description: 'MOU, deed and purchase contract templates in English and Gujarati',
            functions: [
              SupportFunctionItem(key: 'lib_resale_templates', name: 'Resale Deed & MOU Agreement Templates', category: SupportFunctionCategory.table, badge: 'Templates', icon: Icons.description_outlined),
              SupportFunctionItem(key: 'lib_resale_download', name: 'Download Deed Template (Gujarati / English)', category: SupportFunctionCategory.action, badge: 'Download', icon: Icons.file_download_outlined),
              SupportFunctionItem(key: 'lib_resale_upload', name: 'Upload Custom Resale Template', category: SupportFunctionCategory.upload, badge: 'Upload', icon: Icons.upload_file_outlined),
            ],
          ),
          SupportSubpageItem(
            key: 'lib_agents',
            title: 'Service Agents',
            route: '/service-agent-library',
            icon: Icons.engineering_outlined,
            description: 'Approved vendor contacts for painting, carpentry, legal, and repairs',
            functions: [
              SupportFunctionItem(key: 'lib_agent_directory', name: 'Service Agent Directory & Provider Contacts', category: SupportFunctionCategory.table, badge: 'Directory', icon: Icons.contact_phone_outlined),
              SupportFunctionItem(key: 'lib_agent_add', name: 'Add New Service Provider Contact', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.person_add_alt_outlined),
              SupportFunctionItem(key: 'lib_agent_search', name: 'Search Agents by Category & Locality', category: SupportFunctionCategory.filter, badge: 'Search', icon: Icons.search_rounded),
            ],
          ),
        ],
      ));
    }

    // 9. Settings (Dynamically expanded subpages!)
    if (RoleGuard.canViewPage(role, '/settings') || role.isEmpty) {
      final settingsSubpages = <SupportSubpageItem>[];

      // Profile & Security (All roles)
      settingsSubpages.add(const SupportSubpageItem(
        key: 'settings_profile',
        title: 'Profile & Security',
        route: '/profile',
        icon: Icons.person_outline_rounded,
        description: 'Account information, contact details, password reset and MFA security',
        functions: [
          SupportFunctionItem(key: 'set_prof_info', name: 'View Account Profile Info & Role Badges', category: SupportFunctionCategory.general, badge: 'Profile', icon: Icons.badge_outlined),
          SupportFunctionItem(key: 'set_prof_edit', name: 'Edit Name, Mobile & Personal Details', category: SupportFunctionCategory.form, badge: 'Form', icon: Icons.edit_outlined),
          SupportFunctionItem(key: 'set_prof_password', name: 'Change Password Form', category: SupportFunctionCategory.form, badge: 'Security', icon: Icons.lock_outline_rounded),
          SupportFunctionItem(key: 'set_prof_mfa', name: 'TOTP MFA Authentication Setup & QR Code', category: SupportFunctionCategory.security, badge: 'Security', icon: Icons.security_rounded),
        ],
      ));

      // Themes (All roles)
      settingsSubpages.add(const SupportSubpageItem(
        key: 'settings_themes',
        title: 'Themes',
        route: '/settings?section=themes',
        icon: Icons.palette_outlined,
        description: 'Custom primary accent colors, preset themes, and color personalization',
        functions: [
          SupportFunctionItem(key: 'set_theme_preset', name: 'Color Preset Theme Selection', category: SupportFunctionCategory.general, badge: 'Theme', icon: Icons.color_lens_outlined),
          SupportFunctionItem(key: 'set_theme_custom', name: 'Custom Primary / Accent Hex Color Picker', category: SupportFunctionCategory.form, badge: 'Picker', icon: Icons.colorize_rounded),
          SupportFunctionItem(key: 'set_theme_mode', name: 'Dark Mode / Light Mode Toggle', category: SupportFunctionCategory.general, badge: 'Toggle', icon: Icons.dark_mode_outlined),
        ],
      ));

      // Appearance (All roles)
      settingsSubpages.add(const SupportSubpageItem(
        key: 'settings_appearance',
        title: 'Appearance',
        route: '/settings?section=appearance',
        icon: Icons.tune_rounded,
        description: 'Layout density, display contrast, and accessibility settings',
        functions: [
          SupportFunctionItem(key: 'set_app_contrast', name: 'Contrast & Layout Density Settings', category: SupportFunctionCategory.general, badge: 'Settings', icon: Icons.contrast_rounded),
          SupportFunctionItem(key: 'set_app_font', name: 'Typography & Display Scale Settings', category: SupportFunctionCategory.general, badge: 'Display', icon: Icons.text_fields_rounded),
        ],
      ));

      // Locations (All roles)
      settingsSubpages.add(const SupportSubpageItem(
        key: 'settings_locations',
        title: 'Locations',
        route: '/settings?section=locations',
        icon: Icons.location_city_outlined,
        description: 'Operational real estate micro-markets, cities, and pincode mapping',
        functions: [
          SupportFunctionItem(key: 'set_loc_city_table', name: 'Operational Cities Table & Add City', category: SupportFunctionCategory.table, badge: 'Cities', icon: Icons.location_city_rounded),
          SupportFunctionItem(key: 'set_loc_area_table', name: 'Micro-market Areas Table & Add Area', category: SupportFunctionCategory.table, badge: 'Areas', icon: Icons.map_outlined),
          SupportFunctionItem(key: 'set_loc_pincode', name: 'Pincode Mapping & Zone Assignment', category: SupportFunctionCategory.form, badge: 'Pincodes', icon: Icons.pin_drop_outlined),
        ],
      ));

      // Admin / Super Admin only settings sections
      if (isAdmin) {
        settingsSubpages.add(const SupportSubpageItem(
          key: 'settings_match_criteria',
          title: 'Run Match Criteria',
          route: '/settings?section=match_criteria',
          icon: Icons.bolt_rounded,
          description: 'Lead & property automated matchmaking score thresholds and weight rules',
          functions: [
            SupportFunctionItem(key: 'set_match_threshold', name: 'Match Score Threshold Slider (%)', category: SupportFunctionCategory.form, badge: 'Slider', icon: Icons.linear_scale_rounded),
            SupportFunctionItem(key: 'set_match_weights', name: 'Criteria Weights (Budget, Location, BHK, Furnishing)', category: SupportFunctionCategory.form, badge: 'Weights', icon: Icons.tune_rounded),
            SupportFunctionItem(key: 'set_match_save', name: 'Save & Apply Match Rulebook', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.save_outlined),
          ],
        ));

        settingsSubpages.add(const SupportSubpageItem(
          key: 'settings_upload_limits',
          title: 'Upload Limits',
          route: '/settings?section=upload_limits',
          icon: Icons.photo_library_outlined,
          description: 'Maximum property photos, video attachment limits, and file size thresholds',
          functions: [
            SupportFunctionItem(key: 'set_upload_max_images', name: 'Max Property Images Threshold Slider', category: SupportFunctionCategory.form, badge: 'Slider', icon: Icons.image_outlined),
            SupportFunctionItem(key: 'set_upload_max_videos', name: 'Max Property Videos Threshold Slider', category: SupportFunctionCategory.form, badge: 'Slider', icon: Icons.video_file_outlined),
            SupportFunctionItem(key: 'set_upload_file_size', name: 'Maximum File Size Limit (MB)', category: SupportFunctionCategory.form, badge: 'Threshold', icon: Icons.data_usage_rounded),
            SupportFunctionItem(key: 'set_upload_save', name: 'Save Upload Limits to Backend', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.cloud_upload_outlined),
          ],
        ));

        settingsSubpages.add(const SupportSubpageItem(
          key: 'settings_kpi_config',
          title: 'KPI Configuration',
          route: '/settings?section=kpi_config',
          icon: Icons.dashboard_customize_outlined,
          description: 'Monthly target quotas, dashboard KPI toggles, and rulebook engine config',
          functions: [
            SupportFunctionItem(key: 'set_kpi_targets', name: 'Monthly Sales & Telecaller Target Quotas', category: SupportFunctionCategory.form, badge: 'Quotas', icon: Icons.track_changes_rounded),
            SupportFunctionItem(key: 'set_kpi_toggles', name: 'Enable / Disable Specific KPI Cards', category: SupportFunctionCategory.security, badge: 'Toggles', icon: Icons.toggle_on_outlined),
            SupportFunctionItem(key: 'set_kpi_custom', name: 'Add Custom Dynamic KPI Metric', category: SupportFunctionCategory.form, badge: 'Metric', icon: Icons.add_chart_rounded),
          ],
        ));
      }

      // System (All roles)
      settingsSubpages.add(const SupportSubpageItem(
        key: 'settings_system',
        title: 'System & About',
        route: '/settings?section=system',
        icon: Icons.info_outline_rounded,
        description: 'App version, build telemetry, connection status and offline cache clearance',
        functions: [
          SupportFunctionItem(key: 'set_sys_version', name: 'App Version & Build Information', category: SupportFunctionCategory.general, badge: 'Info', icon: Icons.info_rounded),
          SupportFunctionItem(key: 'set_sys_telemetry', name: 'System Telemetry & Connection Health', category: SupportFunctionCategory.general, badge: 'Health', icon: Icons.network_check_rounded),
          SupportFunctionItem(key: 'set_sys_clear_cache', name: 'Clear Offline Cache & Local Storage', category: SupportFunctionCategory.action, badge: 'Cache', icon: Icons.cleaning_services_outlined),
        ],
      ));

      // Super Admin Exclusive Settings
      if (isSuper) {
        settingsSubpages.add(const SupportSubpageItem(
          key: 'settings_audit_logs',
          title: 'Audit Logs',
          route: '/settings/audit-logs',
          icon: Icons.history_rounded,
          description: 'System security audit trail, user authentication events, and mutation history',
          functions: [
            SupportFunctionItem(key: 'set_audit_table', name: 'System Security Audit Logs Table', category: SupportFunctionCategory.table, badge: 'Table', icon: Icons.security_update_good_outlined),
            SupportFunctionItem(key: 'set_audit_filters', name: 'Filter by Actor, Action Type & Date Range', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.filter_alt_outlined),
            SupportFunctionItem(key: 'set_audit_export', name: 'Export Security Audit Trail to CSV', category: SupportFunctionCategory.action, badge: 'Export', icon: Icons.download_rounded),
          ],
        ));

        settingsSubpages.add(const SupportSubpageItem(
          key: 'settings_page_control',
          title: 'Page Control',
          route: '/settings?section=page_control',
          icon: Icons.construction_rounded,
          description: 'Role-based Under Development screen control for Admin, Telecaller, and Sales',
          functions: [
            SupportFunctionItem(key: 'set_pgctrl_tabs', name: 'Role Tabs (Admin, Telecaller, Salesperson)', category: SupportFunctionCategory.general, badge: 'Tabs', icon: Icons.tab_rounded),
            SupportFunctionItem(key: 'set_pgctrl_toggles', name: 'Under Development Page Toggles', category: SupportFunctionCategory.security, badge: 'Toggles', icon: Icons.toggle_on_outlined),
            SupportFunctionItem(key: 'set_pgctrl_sync', name: 'Synchronize Shared Pages Across Roles', category: SupportFunctionCategory.action, badge: 'Sync', icon: Icons.sync_rounded),
          ],
        ));

        settingsSubpages.add(const SupportSubpageItem(
          key: 'settings_permissions',
          title: 'Permission Matrix',
          route: '/settings?section=permissions',
          icon: Icons.admin_panel_settings_rounded,
          description: 'Granular role-based capability matrix and action permissions',
          functions: [
            SupportFunctionItem(key: 'set_perm_matrix', name: 'Role-based Permission Matrix Table', category: SupportFunctionCategory.table, badge: 'Matrix', icon: Icons.table_view_rounded),
            SupportFunctionItem(key: 'set_perm_toggles', name: 'Permission Category Toggles', category: SupportFunctionCategory.security, badge: 'Toggles', icon: Icons.rule_folder_outlined),
            SupportFunctionItem(key: 'set_perm_save', name: 'Save Matrix Changes to Server', category: SupportFunctionCategory.action, badge: 'Action', icon: Icons.save_outlined),
          ],
        ));

        settingsSubpages.add(const SupportSubpageItem(
          key: 'settings_backups',
          title: 'Automated Backups',
          route: '/settings?section=backups',
          icon: Icons.cloud_download_rounded,
          description: 'Cloud snapshots, automated database backups, and point-in-time restore',
          functions: [
            SupportFunctionItem(key: 'set_backup_list', name: 'Cloud Backup Snapshots List', category: SupportFunctionCategory.table, badge: 'Snapshots', icon: Icons.cloud_done_outlined),
            SupportFunctionItem(key: 'set_backup_create', name: 'Create Immediate Database Snapshot', category: SupportFunctionCategory.action, badge: 'Snapshot', icon: Icons.add_to_photos_outlined),
            SupportFunctionItem(key: 'set_backup_restore', name: 'Restore Database from Snapshot', category: SupportFunctionCategory.security, badge: 'Restore', icon: Icons.restore_page_outlined),
          ],
        ));
      }

      pages.add(SupportPageItem(
        key: 'settings',
        title: 'Settings',
        route: '/settings',
        icon: Icons.settings_outlined,
        description: 'System preferences, appearance, location management, and role-based controls',
        subpages: settingsSubpages,
      ));
    }

    // 10. Audit Logs as direct sidebar item for Super Admin
    if (isSuper) {
      pages.add(const SupportPageItem(
        key: 'audit_logs_sidebar',
        title: 'Audit Logs',
        route: '/settings/audit-logs',
        icon: Icons.history_rounded,
        description: 'System security audit trail, user authentication events, and mutation history',
        directFunctions: [
          SupportFunctionItem(key: 'sidebar_audit_table', name: 'Security Audit Logs Table & Search', category: SupportFunctionCategory.table, badge: 'Table', icon: Icons.history_rounded),
          SupportFunctionItem(key: 'sidebar_audit_filter', name: 'Filter by Actor, Action Type & Date Range', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.filter_alt_outlined),
          SupportFunctionItem(key: 'sidebar_audit_export', name: 'Export Audit Trail to CSV', category: SupportFunctionCategory.action, badge: 'Export', icon: Icons.download_rounded),
        ],
      ));
    }

    // 11. Support
    if (RoleGuard.canViewPage(role, '/support') || role.isEmpty) {
      pages.add(const SupportPageItem(
        key: 'support',
        title: 'Support',
        route: '/support',
        icon: Icons.support_agent_rounded,
        description: 'Report software issues, track ticket progress and view resolutions',
        directFunctions: [
          SupportFunctionItem(key: 'supp_report_button', name: '+ Report an Issue Button & Form', category: SupportFunctionCategory.action, badge: 'Form', icon: Icons.add_circle_outline_rounded),
          SupportFunctionItem(key: 'supp_tickets_table', name: 'My Support Tickets Table', category: SupportFunctionCategory.table, badge: 'Table', icon: Icons.table_chart_outlined),
          SupportFunctionItem(key: 'supp_filter_status', name: 'Filter Tickets by Status (Open, In Progress, Resolved)', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.filter_list_rounded),
          SupportFunctionItem(key: 'supp_filter_priority', name: 'Filter Tickets by Priority', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.flag_outlined),
          SupportFunctionItem(key: 'supp_search', name: 'Search Tickets by Ticket # or Keyword', category: SupportFunctionCategory.filter, badge: 'Search', icon: Icons.search_rounded),
          SupportFunctionItem(key: 'supp_ticket_details', name: 'View Ticket Details & Discussion Drawer', category: SupportFunctionCategory.general, badge: 'Drawer', icon: Icons.chat_bubble_outline_rounded),
          SupportFunctionItem(key: 'supp_reply_chat', name: 'Send Reply / Message on Existing Ticket', category: SupportFunctionCategory.form, badge: 'Reply', icon: Icons.send_rounded),
        ],
      ));
    }

    // 12. Issue Management (Super Admin only)
    if (isSuper) {
      pages.add(const SupportPageItem(
        key: 'issue_management',
        title: 'Issue Management',
        route: '/admin/support',
        icon: Icons.admin_panel_settings_outlined,
        description: 'Super Admin ticket roster, status assignment, and organization resolution desk',
        directFunctions: [
          SupportFunctionItem(key: 'admin_supp_roster', name: 'All Organization Support Tickets Table', category: SupportFunctionCategory.table, badge: 'Roster', icon: Icons.receipt_long_outlined),
          SupportFunctionItem(key: 'admin_supp_role_filter', name: 'Filter Tickets by Reporter Role (Admin, Telecaller, Sales)', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.people_outline_rounded),
          SupportFunctionItem(key: 'admin_supp_status_filter', name: 'Filter Tickets by Status & Priority', category: SupportFunctionCategory.filter, badge: 'Filter', icon: Icons.tune_rounded),
          SupportFunctionItem(key: 'admin_supp_assign', name: 'Assign Ticket to Staff Member', category: SupportFunctionCategory.action, badge: 'Assign', icon: Icons.person_pin_outlined),
          SupportFunctionItem(key: 'admin_supp_update_status', name: 'Update Ticket Status (In Progress, Resolved, Closed)', category: SupportFunctionCategory.action, badge: 'Status', icon: Icons.update_rounded),
          SupportFunctionItem(key: 'admin_supp_admin_reply', name: 'Post Admin Response to User', category: SupportFunctionCategory.form, badge: 'Reply', icon: Icons.reply_rounded),
          SupportFunctionItem(key: 'admin_supp_internal_note', name: 'Post Internal Administrative Note', category: SupportFunctionCategory.form, badge: 'Internal', icon: Icons.note_rounded),
        ],
      ));
    }

    // 13. Recycle Bin
    if (RoleGuard.canViewPage(role, '/bin') || role.isEmpty) {
      pages.add(const SupportPageItem(
        key: 'recycle_bin',
        title: 'Recycle Bin',
        route: '/bin',
        icon: Icons.delete_outline_rounded,
        description: 'Deleted properties, archived requirements, and item restoration desk',
        directFunctions: [
          SupportFunctionItem(key: 'bin_properties_tab', name: 'Deleted Properties Tab & Listings', category: SupportFunctionCategory.table, badge: 'Properties', icon: Icons.home_work_outlined),
          SupportFunctionItem(key: 'bin_restore_property', name: 'Restore Property Action', category: SupportFunctionCategory.action, badge: 'Restore', icon: Icons.restore_from_trash_rounded),
          SupportFunctionItem(key: 'bin_leads_tab', name: 'Archived Leads Tab & Listings', category: SupportFunctionCategory.table, badge: 'Leads', icon: Icons.assignment_outlined),
          SupportFunctionItem(key: 'bin_restore_lead', name: 'Restore Lead Action', category: SupportFunctionCategory.action, badge: 'Restore', icon: Icons.restore_rounded),
          SupportFunctionItem(key: 'bin_permanent_delete', name: 'Permanently Delete Record', category: SupportFunctionCategory.action, badge: 'Delete', icon: Icons.delete_forever_rounded),
          SupportFunctionItem(key: 'bin_empty_all', name: 'Empty Entire Recycle Bin', category: SupportFunctionCategory.action, badge: 'Purge', icon: Icons.delete_sweep_rounded),
        ],
      ));
    }

    return pages;
  }
}

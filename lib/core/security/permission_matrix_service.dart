import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/dio_client.dart';

/// Represents a single controllable permission metric.
class PermissionItem {
  final String key;
  final String title;
  final String description;
  final String category;
  final String? relatedRoute;
  final bool defaultAdmin;
  final bool defaultTelecaller;
  final bool defaultSales;

  const PermissionItem({
    required this.key,
    required this.title,
    required this.description,
    required this.category,
    this.relatedRoute,
    required this.defaultAdmin,
    required this.defaultTelecaller,
    required this.defaultSales,
  });
}

/// Categories of permissions.
class PermissionCategory {
  static const String pages = 'App Shell & Pages';
  static const String properties = 'Properties Inventory';
  static const String leads = 'Leads & Pipeline';
  static const String campaign = 'Campaign & Ingestion';
  static const String employees = 'Team & Staff';
  static const String reports = 'Reports & Analytics';
  static const String system = 'Security & Administration';

  static const List<String> all = [
    pages,
    properties,
    leads,
    campaign,
    employees,
    reports,
    system,
  ];
}

/// Comprehensive service managing role permission metrics across the entire application.
class PermissionMatrixService extends ChangeNotifier {
  static final PermissionMatrixService _instance = PermissionMatrixService._internal();
  static PermissionMatrixService get instance => _instance;

  Timer? _pollingTimer;
  bool _syncInFlight = false;

  PermissionMatrixService._internal() {
    _init();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    // Permissions rarely change. A short poll was rebuilding the router on every tick.
    _pollingTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_syncInFlight) return;
      syncFromBackend();
    });
  }

  bool _putOverride(String role, String key, bool enabled) {
    final current = _overrides[role];
    if (current != null && current[key] == enabled) return false;
    _overrides.putIfAbsent(role, () => {})[key] = enabled;
    return true;
  }

  bool _applyRoleAssignments(String role, Map<String, dynamic> roleMap) {
    var changed = false;
    roleMap.forEach((key, value) {
      final enabled = value == true;
      if (_putOverride(role, key, enabled)) changed = true;
      if (key == 'page.recycle_bin' && _putOverride(role, 'page.bin', enabled)) changed = true;
      if (key == 'page.bin' && _putOverride(role, 'page.recycle_bin', enabled)) changed = true;
      if (key == 'page.employees' && _putOverride(role, 'page.users', enabled)) changed = true;
      if (key == 'page.users' && _putOverride(role, 'page.employees', enabled)) changed = true;
    });
    return changed;
  }

  static const String _storageKey = 'propkart_role_permission_matrix_v2';

  // Master definition of all permissions in the system
  static const List<PermissionItem> allPermissions = [
    // ── App Shell & Pages ──────────────────────────────
    PermissionItem(
      key: 'page.dashboard',
      title: 'Executive Dashboard Page',
      description: 'Access main overview KPIs, recent leads, and inventory summary (/dashboard).',
      category: PermissionCategory.pages,
      relatedRoute: '/dashboard',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.dashboard.followups',
      title: 'Follow-ups',
      description: 'Scheduled client reminders and follow-up activities desk on Admin Dashboard.',
      category: PermissionCategory.pages,
      relatedRoute: '/dashboard#followups',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.dashboard.site_visits',
      title: 'Site Visit Scheduled',
      description: 'Scheduled property inspections and client site visits on Admin Dashboard.',
      category: PermissionCategory.pages,
      relatedRoute: '/dashboard#site_visits',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.properties',
      title: 'Properties Inventory Page',
      description: 'Access the complete real estate property listings directory (/properties).',
      category: PermissionCategory.pages,
      relatedRoute: '/properties',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.leads',
      title: 'Leads & Requirements Page',
      description: 'Access buyer & tenant inquiries pipeline and matchmaking table (/requirements).',
      category: PermissionCategory.pages,
      relatedRoute: '/requirements',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.employees',
      title: 'Employees & Users Page',
      description: 'Access team member roster, role assignments, and agent management (/users).',
      category: PermissionCategory.pages,
      relatedRoute: '/users',
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.reports',
      title: 'Reports & Analytics Page',
      description: 'Access overall business intelligence, lead flow, and team ranking reports (/reports).',
      category: PermissionCategory.pages,
      relatedRoute: '/reports',
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.campaign',
      title: 'Campaign & Webhook Ingestion Page',
      description: 'Access Meta Ads webhook inbox, spreadsheet ingestion, and connectors (/campaign).',
      category: PermissionCategory.pages,
      relatedRoute: '/campaign',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.telecaller_leads',
      title: 'Telecaller Leads',
      description: 'Leads allocated to the signed-in Telecaller (/telecaller/leads).',
      category: PermissionCategory.pages,
      relatedRoute: '/telecaller/leads',
      defaultAdmin: false,
      defaultTelecaller: true,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.callbacks',
      title: 'Telecaller Callbacks',
      description: 'Owned callbacks (/telecaller/callbacks).',
      category: PermissionCategory.pages,
      relatedRoute: '/telecaller/callbacks',
      defaultAdmin: false,
      defaultTelecaller: true,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.cnr',
      title: 'CNR / Retry',
      description: 'Owned CNR retry desk (/telecaller/cnr).',
      category: PermissionCategory.pages,
      relatedRoute: '/telecaller/cnr',
      defaultAdmin: false,
      defaultTelecaller: true,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.lead_allocation',
      title: 'Lead Allocation Monitoring',
      description: 'Admin queue and Telecaller workload monitor (/admin/lead-allocation).',
      category: PermissionCategory.pages,
      relatedRoute: '/admin/lead-allocation',
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.support',
      title: 'Support & Help Desk Page',
      description: 'Access role-based support page to report issues and view resolution status (/support).',
      category: PermissionCategory.pages,
      relatedRoute: '/support',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.library',
      title: 'Shared Property Libraries Page',
      description: 'Access rental, resale, and service agent community database libraries (/library).',
      category: PermissionCategory.pages,
      relatedRoute: '/library',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.recycle_bin',
      title: 'Recycle Bin Page',
      description: 'Access deleted properties, archived requirements, and restore options (/bin).',
      category: PermissionCategory.pages,
      relatedRoute: '/bin',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.settings',
      title: 'System Settings Page',
      description: 'Access appearance, themes, locations, profile, and diagnostics (/settings).',
      category: PermissionCategory.pages,
      relatedRoute: '/settings',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.audit_logs',
      title: 'Security Audit Logs Page',
      description: 'Access chronological activity trail and authentication logs (/settings/audit-logs).',
      category: PermissionCategory.pages,
      relatedRoute: '/settings/audit-logs',
      defaultAdmin: false,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.clients',
      title: 'Client Directory Page',
      description: 'Access direct buyer and tenant contact list (/clients).',
      category: PermissionCategory.pages,
      relatedRoute: '/clients',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.owners',
      title: 'Property Owners Directory Page',
      description: 'Access landlord, seller, and investor contact list (/owners).',
      category: PermissionCategory.pages,
      relatedRoute: '/owners',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.builders',
      title: 'Builders & Developers Page',
      description: 'Access construction companies and partner builder registry (/builders).',
      category: PermissionCategory.pages,
      relatedRoute: '/builders',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.messages',
      title: 'Team Messages Page',
      description: 'Access direct real-time team messaging and conversations (/messages).',
      category: PermissionCategory.pages,
      relatedRoute: '/messages',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),

    // ── Properties Inventory Permissions ───────────────
    PermissionItem(
      key: 'properties.create',
      title: 'Create Property Listings',
      description: 'Add new rental or sale property units into the database.',
      category: PermissionCategory.properties,
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'properties.edit',
      title: 'Edit Property Details',
      description: 'Update rent, price, location, photos, configuration, and amenities.',
      category: PermissionCategory.properties,
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'properties.delete',
      title: 'Soft Delete Property',
      description: 'Move active property listing to the Recycle Bin.',
      category: PermissionCategory.properties,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'properties.restore',
      title: 'Restore Deleted Property',
      description: 'Restore properties from the Recycle Bin back to active inventory.',
      category: PermissionCategory.properties,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'properties.permanent_delete',
      title: 'Permanently Drop Property',
      description: 'Permanently delete property and its media from database records.',
      category: PermissionCategory.properties,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'properties.verify',
      title: 'Verify Property Listings',
      description: 'Audit and approve property with the verified blue check badge.',
      category: PermissionCategory.properties,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'properties.export',
      title: 'Export Properties to Excel',
      description: 'Download the complete property catalog in .xlsx format.',
      category: PermissionCategory.properties,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'properties.view_owner_contact',
      title: 'View Landlord Direct Contact',
      description: 'Access unmasked owner phone numbers and private callback notes.',
      category: PermissionCategory.properties,
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'properties.share_dossier',
      title: 'Share Property Cards & Dossiers',
      description: 'Generate client-safe WhatsApp messages and branded PDF dossiers.',
      category: PermissionCategory.properties,
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),

    // ── Leads & Pipeline Permissions ───────────────────
    PermissionItem(
      key: 'leads.create',
      title: 'Create Buyer/Tenant Inquiries',
      description: 'Register client requirements, budgets, configurations, and preferred areas.',
      category: PermissionCategory.leads,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'leads.edit',
      title: 'Edit Requirements & Matchmaking',
      description: 'Modify inquiry status, budget brackets, client preferences, and notes.',
      category: PermissionCategory.leads,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'leads.delete',
      title: 'Delete Client Inquiries',
      description: 'Move inactive or dropped leads to the Recycle Bin.',
      category: PermissionCategory.leads,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'leads.reassign',
      title: 'Reassign Leads across Agents',
      description: 'Transfer ownership of leads between telecallers and sales representatives.',
      category: PermissionCategory.leads,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'leads.export',
      title: 'Bulk Export Leads to Excel',
      description: 'Download lead databases and contact logs to Excel spreadsheets.',
      category: PermissionCategory.leads,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'leads.view_unmasked_phone',
      title: 'View Unmasked Client Phone',
      description: 'Display full phone numbers rather than masked digits (e.g. +91 98****3210).',
      category: PermissionCategory.leads,
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'leads.schedule_followup',
      title: 'Schedule Follow-ups & Reminders',
      description: 'Set date & time alarms and discussion remarks for client callbacks.',
      category: PermissionCategory.leads,
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),

    // ── Campaign & Ingestion Permissions ───────────────
    PermissionItem(
      key: 'campaign.view_inbox',
      title: 'View Campaign Ingestion Grid',
      description: 'Access the real-time Meta Ads and Google Sheets inbound lead queue.',
      category: PermissionCategory.campaign,
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'campaign.manage_connectors',
      title: 'Manage Webhooks & Google Sheets',
      description: 'Configure Meta Webhook secrets, verify tokens, and Google Sheet sync URLs.',
      category: PermissionCategory.campaign,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'campaign.edit_status',
      title: 'Update Campaign Lead Status',
      description: 'Tag inbound leads as Follow up, Interested, or Not interested.',
      category: PermissionCategory.campaign,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'campaign.move_to_crm',
      title: 'Move Leads to Main CRM',
      description: 'One-click transfer cleaned campaign leads to Leads or Properties pages.',
      category: PermissionCategory.campaign,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'campaign.deduplicate',
      title: 'Run Duplicate Cleaning Engine',
      description: 'Scan phone numbers across the database and merge repeat inquiries.',
      category: PermissionCategory.campaign,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'campaign.purge',
      title: 'Bulk Purge Campaign Leads',
      description: 'Bulk delete fake, invalid, or obsolete ad leads permanently.',
      category: PermissionCategory.campaign,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'campaign.import_payload',
      title: 'Simulate & Import Payloads',
      description: 'Directly paste JSON payloads or upload CSV batches into the campaign pipeline.',
      category: PermissionCategory.campaign,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),

    // ── Team & Employee Administration ─────────────────
    PermissionItem(
      key: 'employees.view',
      title: 'View Employee Directory',
      description: 'Browse all company agents, contact numbers, and login status.',
      category: PermissionCategory.employees,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'employees.create',
      title: 'Invite / Register Team Members',
      description: 'Create new user profiles for Sales executives and Telecallers.',
      category: PermissionCategory.employees,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'employees.edit',
      title: 'Edit Employee Role & Profile',
      description: 'Change name, phone, branch, or assigned reporting manager.',
      category: PermissionCategory.employees,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'employees.deactivate',
      title: 'Deactivate Employee Accounts',
      description: 'Instantly revoke application access and invalidate user sessions.',
      category: PermissionCategory.employees,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'employees.manage_admins',
      title: 'Create & Manage Admin Accounts',
      description: 'Promote users to Admin or delete Admin accounts (Super Admin exclusive).',
      category: PermissionCategory.employees,
      defaultAdmin: false,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'employees.reset_password',
      title: 'Trigger Password Reset Links',
      description: 'Dispatch administrative password reset links to employee emails.',
      category: PermissionCategory.employees,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),

    // ── Reports & Analytics ────────────────────────────
    PermissionItem(
      key: 'reports.overall_insights',
      title: 'Overall Business Insights',
      description: 'View executive revenue metrics, inventory turnover, and conversion rates.',
      category: PermissionCategory.reports,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'reports.telecaller_metrics',
      title: 'Telecaller Productivity Analytics',
      description: 'View calls connected, callback fulfillment, and lead qualification velocity.',
      category: PermissionCategory.reports,
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'reports.sales_performance',
      title: 'Sales Performance & Closures',
      description: 'View site visits performed, deals won, and sales executive rankings.',
      category: PermissionCategory.reports,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'reports.export',
      title: 'Export Analytical Reports',
      description: 'Download performance charts and team rankings as Excel or PDF summaries.',
      category: PermissionCategory.reports,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),

    // ── Security & System Administration ───────────────
    PermissionItem(
      key: 'system.view_audit_logs',
      title: 'View System Audit Trail',
      description: 'Review security logs, unauthorized attempts, and mutation audits.',
      category: PermissionCategory.system,
      defaultAdmin: false,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'system.manage_lookups',
      title: 'Manage Cities & Localities',
      description: 'Add and edit master city boundaries, localities, and area tags.',
      category: PermissionCategory.system,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'system.appearance_themes',
      title: 'Global Branding & Theme Presets',
      description: 'Configure company brand colors, primary accents, and theme modes.',
      category: PermissionCategory.system,
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'system.diagnostics',
      title: 'Database & VPS Health Diagnostics',
      description: 'Monitor PostgreSQL connectivity, Redis cache state, and server response times.',
      category: PermissionCategory.system,
      defaultAdmin: false,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'system.manage_permissions',
      title: 'Configure Permission Control Matrix',
      description: 'Master access control switchboard for all app roles (Super Admin exclusive).',
      category: PermissionCategory.system,
      defaultAdmin: false,
      defaultTelecaller: false,
      defaultSales: false,
    ),

    // ── App Shell Subpages & Nested Menus ─────────────────────────────────
    PermissionItem(
      key: 'page.campaign.connections',
      title: 'Campaign Connections',
      description: 'Webhook configurations, portal keys, and lead endpoints.',
      category: PermissionCategory.campaign,
      relatedRoute: '/campaign/connections',
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.campaign.meta',
      title: 'Campaign Meta',
      description: 'Meta Facebook/Instagram lead ads form integration.',
      category: PermissionCategory.campaign,
      relatedRoute: '/campaign/meta',
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.campaign.housing',
      title: 'Campaign Housing',
      description: 'Housing.com campaign webhooks and lead feed.',
      category: PermissionCategory.campaign,
      relatedRoute: '/campaign/housing',
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.settings.profile',
      title: 'Settings Profile',
      description: 'User profile details, credentials, and avatar.',
      category: PermissionCategory.system,
      relatedRoute: '/profile',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.settings.themes',
      title: 'Settings Themes',
      description: 'System color palettes and brand customization.',
      category: PermissionCategory.system,
      relatedRoute: '/settings?section=themes',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.settings.appearance',
      title: 'Settings Appearance',
      description: 'App dark mode, layout density, and UI styling.',
      category: PermissionCategory.system,
      relatedRoute: '/settings?section=appearance',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.settings.locations',
      title: 'Settings Locations',
      description: 'Operational cities, localities, and area management.',
      category: PermissionCategory.system,
      relatedRoute: '/settings/location-config',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.settings.match_criteria',
      title: 'Settings Run Match Criteria',
      description: 'Lead-to-property automated matching criteria configuration.',
      category: PermissionCategory.system,
      relatedRoute: '/settings?section=match_criteria',
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.settings.upload_limits',
      title: 'Settings Upload Limits',
      description: 'Property image quotas and document size limits.',
      category: PermissionCategory.system,
      relatedRoute: '/settings?section=upload_limits',
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.settings.kpi_config',
      title: 'Settings KPI Configuration',
      description: 'Performance KPI thresholds, targets, and scoring weights.',
      category: PermissionCategory.system,
      relatedRoute: '/settings/kpi-config',
      defaultAdmin: true,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.settings.backups',
      title: 'Settings Automated Backups',
      description: 'Automated database snapshots and recovery archive.',
      category: PermissionCategory.system,
      relatedRoute: '/settings?section=backups',
      defaultAdmin: false,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.settings.audit_logs',
      title: 'Settings Audit Logs',
      description: 'Security audit logs and chronological system events.',
      category: PermissionCategory.system,
      relatedRoute: '/settings/audit-logs',
      defaultAdmin: false,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.settings.system',
      title: 'Settings System',
      description: 'System runtime info, cache status, and diagnostics.',
      category: PermissionCategory.system,
      relatedRoute: '/settings?section=system',
      defaultAdmin: true,
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'page.admin.permissions',
      title: 'Permission Matrix',
      description: 'Access & Permission Matrix Studio (Super Admin exclusive).',
      category: PermissionCategory.system,
      relatedRoute: '/admin/permissions',
      defaultAdmin: false,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.admin.plans',
      title: 'Tier Plans Studio',
      description: 'Subscription plans and feature entitlements (Super Admin exclusive).',
      category: PermissionCategory.system,
      relatedRoute: '/admin/plans',
      defaultAdmin: false,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.admin.brokers',
      title: 'Broker Workspaces',
      description: 'Broker accounts and tenant organizations (Super Admin exclusive).',
      category: PermissionCategory.system,
      relatedRoute: '/admin/brokers',
      defaultAdmin: false,
      defaultTelecaller: false,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'page.admin.support',
      title: 'Issue Management',
      description: 'Super Admin centralized platform support desk.',
      category: PermissionCategory.system,
      relatedRoute: '/admin/support',
      defaultAdmin: false,
      defaultTelecaller: false,
      defaultSales: false,
    ),
  ];

  // Dynamic overrides: Map<Role, Map<PermissionKey, bool>>
  // Standardized role names: 'Admin', 'Telecaller', 'Sales'
  final Map<String, Map<String, bool>> _overrides = {
    'Admin': {},
    'Telecaller': {},
    'Sales': {},
  };

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Loads saved permission matrix from SharedPreferences
  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final decoded = jsonDecode(savedJson);
        if (decoded is Map<String, dynamic>) {
          for (final role in ['Admin', 'Telecaller', 'Sales']) {
            if (decoded[role] is Map) {
              final roleMap = Map<String, dynamic>.from(decoded[role] as Map);
              _overrides[role] = roleMap.map((k, v) => MapEntry(k, v == true));
            }
          }
        }
      }
    } catch (_) {
      // Gracefully defaults to system standard permissions if storage/binding is unavailable
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Syncs dynamic feature permissions directly from backend/database.
  /// Listeners are told only when a role's permissions actually change, so a
  /// repeated poll does not rebuild the router or the open screen.
  Future<void> syncFromBackend() async {
    if (_syncInFlight) return;
    _syncInFlight = true;
    try {
      final res = await DioClient.dio.get('/permissions/matrix/roles');
      if (res.statusCode == 200 && res.data != null) {
        final data = res.data['data'];
        if (data is Map && data['assignments'] is Map) {
          final assignments = data['assignments'] as Map;
          var changed = false;
          for (final role in ['Admin', 'Telecaller', 'Sales']) {
            if (assignments[role] is Map) {
              final roleMap = Map<String, dynamic>.from(assignments[role] as Map);
              if (_applyRoleAssignments(role, roleMap)) changed = true;
            }
          }
          if (changed) {
            notifyListeners();
            unawaited(_saveToStorage());
          }
          return;
        }
      }
    } catch (_) {
      // Non-blocking; continue to my-controls fallback
    } finally {
      _syncInFlight = false;
    }

    if (_syncInFlight) return;
    _syncInFlight = true;
    try {
      final resMy = await DioClient.dio.get('/permissions/my-controls');
      if (resMy.statusCode == 200 && resMy.data != null) {
        final data = resMy.data['data'];
        if (data is Map) {
          final role = _normalizeRole(data['role']?.toString());
          final controls = data['controls'];
          if (role != 'Super Admin' && controls is List) {
            final activeSet = controls.map((e) => e.toString()).toSet();
            var changed = false;
            for (final p in allPermissions) {
              final isAllowed = activeSet.contains(p.key) ||
                  (p.key == 'page.recycle_bin' && activeSet.contains('page.bin')) ||
                  (p.key == 'page.bin' && activeSet.contains('page.recycle_bin')) ||
                  (p.key == 'page.employees' && activeSet.contains('page.users')) ||
                  (p.key == 'page.users' && activeSet.contains('page.employees'));
              if (_putOverride(role, p.key, isAllowed)) changed = true;
            }
            if (changed) {
              notifyListeners();
              unawaited(_saveToStorage());
            }
          }
        }
      }
    } catch (_) {
    } finally {
      _syncInFlight = false;
    }
  }

  /// Evaluates whether a [role] has a specific [permissionKey].
  /// Note: 'Super Admin' always returns `true` (locked master).
  bool hasPermission(String? role, String permissionKey) {
    final normRole = _normalizeRole(role);
    if (normRole == 'Super Admin') return true;

    // Check if explicitly overridden in the dynamic matrix
    final roleOverrides = _overrides[normRole];
    if (roleOverrides != null) {
      if (roleOverrides.containsKey(permissionKey)) {
        return roleOverrides[permissionKey] == true;
      }
      // Check aliases
      if (permissionKey == 'page.recycle_bin' && roleOverrides.containsKey('page.bin')) {
        return roleOverrides['page.bin'] == true;
      }
      if (permissionKey == 'page.bin' && roleOverrides.containsKey('page.recycle_bin')) {
        return roleOverrides['page.recycle_bin'] == true;
      }
      if (permissionKey == 'page.employees' && roleOverrides.containsKey('page.users')) {
        return roleOverrides['page.users'] == true;
      }
      if (permissionKey == 'page.users' && roleOverrides.containsKey('page.employees')) {
        return roleOverrides['page.employees'] == true;
      }
    }

    // Otherwise fallback to system default
    final item = allPermissions.cast<PermissionItem?>().firstWhere(
          (p) => p?.key == permissionKey,
          orElse: () => null,
        );
    if (item == null) return false;

    switch (normRole) {
      case 'Admin':
        return item.defaultAdmin;
      case 'Telecaller':
        return item.defaultTelecaller;
      case 'Sales':
        return item.defaultSales;
      default:
        return false;
    }
  }

  /// Evaluates whether a [role] can view a specific app route.
  bool canViewRoute(String? role, String route) {
    final normRole = _normalizeRole(role);
    if (normRole == 'Super Admin') return true;

    final r = route.toLowerCase();

    // Settings subpage checks
    if (r.contains('section=themes')) {
      return hasPermission(normRole, 'page.settings') && hasPermission(normRole, 'page.settings.themes');
    }
    if (r.contains('section=appearance')) {
      return hasPermission(normRole, 'page.settings') && hasPermission(normRole, 'page.settings.appearance');
    }
    if (r.contains('section=match_criteria')) {
      return hasPermission(normRole, 'page.settings') && hasPermission(normRole, 'page.settings.match_criteria');
    }
    if (r.contains('section=upload_limits')) {
      return hasPermission(normRole, 'page.settings') && hasPermission(normRole, 'page.settings.upload_limits');
    }
    if (r.contains('section=kpi_config') || r.startsWith('/settings/kpi-config')) {
      return hasPermission(normRole, 'page.settings') && hasPermission(normRole, 'page.settings.kpi_config');
    }
    if (r.contains('section=backups')) {
      return hasPermission(normRole, 'page.settings') && hasPermission(normRole, 'page.settings.backups');
    }
    if (r.contains('section=system')) {
      return hasPermission(normRole, 'page.settings') && hasPermission(normRole, 'page.settings.system');
    }
    if (r.startsWith('/settings/location-config') || r.contains('section=locations')) {
      return hasPermission(normRole, 'page.settings') && hasPermission(normRole, 'page.settings.locations');
    }
    if (r == '/settings/audit-logs') {
      return hasPermission(normRole, 'page.settings') && (hasPermission(normRole, 'page.settings.audit_logs') || hasPermission(normRole, 'page.audit_logs'));
    }

    // Campaign subpage checks
    if (r.startsWith('/campaign/connections')) {
      return hasPermission(normRole, 'page.campaign') && hasPermission(normRole, 'page.campaign.connections');
    }
    if (r.startsWith('/campaign/meta')) {
      return hasPermission(normRole, 'page.campaign') && hasPermission(normRole, 'page.campaign.meta');
    }
    if (r.startsWith('/campaign/housing')) {
      return hasPermission(normRole, 'page.campaign') && hasPermission(normRole, 'page.campaign.housing');
    }

    // Top-level App Shell routes
    String? permKey;
    if (r == '/dashboard' || r == '/') {
      permKey = 'page.dashboard';
    } else if (r.startsWith('/properties')) {
      permKey = 'page.properties';
    } else if (r.startsWith('/telecaller/callbacks')) {
      permKey = 'page.callbacks';
    } else if (r.startsWith('/telecaller/cnr')) {
      permKey = 'page.cnr';
    } else if (r.startsWith('/telecaller') || r == '/campaign/leads') {
      permKey = 'page.telecaller_leads';
    } else if (r.startsWith('/admin/lead-allocation') || r.startsWith('/lead-allocation')) {
      permKey = 'page.lead_allocation';
    } else if (r.startsWith('/requirements')) {
      permKey = 'page.leads';
    } else if (r.startsWith('/users')) {
      permKey = 'page.employees';
    } else if (r.startsWith('/reports')) {
      permKey = 'page.reports';
    } else if (r.startsWith('/campaign') || r.startsWith('/integration')) {
      permKey = 'page.campaign';
    } else if (r.startsWith('/library')) {
      permKey = 'page.library';
    } else if (r.startsWith('/bin')) {
      permKey = 'page.recycle_bin';
    } else if (r.startsWith('/settings')) {
      permKey = 'page.settings';
    } else if (r.startsWith('/support')) {
      permKey = 'page.support';
    } else if (r.startsWith('/profile')) {
      permKey = 'page.settings.profile';
    } else if (r.startsWith('/clients')) {
      permKey = 'page.clients';
    } else if (r.startsWith('/owners')) {
      permKey = 'page.owners';
    } else if (r.startsWith('/messages')) {
      permKey = 'page.messages';
    } else if (r.startsWith('/builders')) {
      permKey = 'page.builders';
    } else if (r.startsWith('/admin/permissions') ||
               r.startsWith('/admin/plans') ||
               r.startsWith('/admin/brokers') ||
               r.startsWith('/admin/support')) {
      return normRole == 'Super Admin';
    }

    if (permKey != null) {
      return hasPermission(normRole, permKey);
    }
    return true;
  }

  /// Sets or toggles a permission for a specific role.
  Future<void> setPermission(String role, String permissionKey, bool allowed) async {
    final normRole = _normalizeRole(role);
    if (normRole == 'Super Admin') return; // Cannot modify Super Admin

    if (!_overrides.containsKey(normRole)) {
      _overrides[normRole] = {};
    }
    _overrides[normRole]![permissionKey] = allowed;
    if (permissionKey == 'page.employees') _overrides[normRole]!['page.users'] = allowed;
    if (permissionKey == 'page.users') _overrides[normRole]!['page.employees'] = allowed;
    if (permissionKey == 'page.recycle_bin') _overrides[normRole]!['page.bin'] = allowed;
    if (permissionKey == 'page.bin') _overrides[normRole]!['page.recycle_bin'] = allowed;
    if (permissionKey == 'page.audit_logs') _overrides[normRole]!['page.settings.audit_logs'] = allowed;
    if (permissionKey == 'page.settings.audit_logs') _overrides[normRole]!['page.audit_logs'] = allowed;

    notifyListeners();
    unawaited(_saveToStorage());

    // Persist permanently to backend database immediately
    try {
      await DioClient.dio.post('/permissions/matrix/role-control', data: {
        'roleName': normRole,
        'controlKey': permissionKey,
        'isEnabled': allowed,
      });
    } catch (e) {
      debugPrint('[PermissionMatrixService] Backend update failed: $e');
    }
  }

  /// Bulk updates all permissions for a category for a given role.
  Future<void> setCategoryPermissions(String role, String category, bool allowed) async {
    final normRole = _normalizeRole(role);
    if (normRole == 'Super Admin') return;

    final permsInCategory = allPermissions.where((p) => p.category == category).toList();
    if (!_overrides.containsKey(normRole)) {
      _overrides[normRole] = {};
    }
    final bulkMap = <String, bool>{};
    for (final p in permsInCategory) {
      _overrides[normRole]![p.key] = allowed;
      bulkMap[p.key] = allowed;
      if (p.key == 'page.employees') {
        _overrides[normRole]!['page.users'] = allowed;
        bulkMap['page.users'] = allowed;
      }
      if (p.key == 'page.users') {
        _overrides[normRole]!['page.employees'] = allowed;
        bulkMap['page.employees'] = allowed;
      }
      if (p.key == 'page.recycle_bin') {
        _overrides[normRole]!['page.bin'] = allowed;
        bulkMap['page.bin'] = allowed;
      }
      if (p.key == 'page.bin') {
        _overrides[normRole]!['page.recycle_bin'] = allowed;
        bulkMap['page.recycle_bin'] = allowed;
      }
      if (p.key == 'page.audit_logs') {
        _overrides[normRole]!['page.settings.audit_logs'] = allowed;
        bulkMap['page.settings.audit_logs'] = allowed;
      }
      if (p.key == 'page.settings.audit_logs') {
        _overrides[normRole]!['page.audit_logs'] = allowed;
        bulkMap['page.audit_logs'] = allowed;
      }
    }
    notifyListeners();
    unawaited(_saveToStorage());

    try {
      await DioClient.dio.put('/permissions/matrix/roles/$normRole', data: {
        'permissionsMap': bulkMap,
      });
    } catch (e) {
      debugPrint('[PermissionMatrixService] Bulk backend update failed: $e');
    }
  }

  /// Resets dynamic matrix back to standard PropKart defaults.
  Future<void> resetToDefaults() async {
    _overrides['Admin']?.clear();
    _overrides['Telecaller']?.clear();
    _overrides['Sales']?.clear();
    notifyListeners();
    await _saveToStorage();
  }

  /// Returns count of active permissions for a given role.
  int getActiveCount(String role) {
    final normRole = _normalizeRole(role);
    if (normRole == 'Super Admin') return allPermissions.length;

    int count = 0;
    for (final p in allPermissions) {
      if (hasPermission(normRole, p.key)) {
        count++;
      }
    }
    return count;
  }

  /// Exports current matrix configuration as JSON string.
  String exportJson() {
    final data = <String, dynamic>{
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'roles': {
        'Super Admin': allPermissions.map((p) => {p.key: true}).toList(),
        'Admin': {
          for (final p in allPermissions) p.key: hasPermission('Admin', p.key),
        },
        'Telecaller': {
          for (final p in allPermissions) p.key: hasPermission('Telecaller', p.key),
        },
        'Sales': {
          for (final p in allPermissions) p.key: hasPermission('Sales', p.key),
        },
      },
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_overrides));
    } catch (e) {
      debugPrint('Error saving permission matrix: $e');
    }
  }


  String _normalizeRole(String? raw) {
    final r = (raw ?? '').trim().toLowerCase();
    if (r == 'super admin' || r == 'superadmin') return 'Super Admin';
    if (r == 'admin') return 'Admin';
    if (r == 'telecaller') return 'Telecaller';
    return 'Sales';
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  PermissionMatrixService._internal() {
    _init();
  }

  static const String _storageKey = 'propkart_role_permission_matrix_v1';

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
      defaultTelecaller: false,
      defaultSales: false,
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
      defaultTelecaller: true,
      defaultSales: true,
    ),
    PermissionItem(
      key: 'leads.edit',
      title: 'Edit Requirements & Matchmaking',
      description: 'Modify inquiry status, budget brackets, client preferences, and notes.',
      category: PermissionCategory.leads,
      defaultAdmin: true,
      defaultTelecaller: true,
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
      defaultTelecaller: true,
      defaultSales: false,
    ),
    PermissionItem(
      key: 'campaign.move_to_crm',
      title: 'Move Leads to Main CRM',
      description: 'One-click transfer cleaned campaign leads to Leads or Properties pages.',
      category: PermissionCategory.campaign,
      defaultAdmin: true,
      defaultTelecaller: true,
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

  /// Evaluates whether a [role] has a specific [permissionKey].
  /// Note: 'Super Admin' always returns `true` (locked master).
  bool hasPermission(String? role, String permissionKey) {
    final normRole = _normalizeRole(role);
    if (normRole == 'Super Admin') return true;

    // Check if explicitly overridden in the dynamic matrix
    final roleOverrides = _overrides[normRole];
    if (roleOverrides != null && roleOverrides.containsKey(permissionKey)) {
      return roleOverrides[permissionKey] == true;
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

    // Map common routes to permission keys
    String? permKey;
    final r = route.toLowerCase();

    if (r == '/dashboard' || r == '/') {
      permKey = 'page.dashboard';
    } else if (r.startsWith('/properties')) {
      permKey = 'page.properties';
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
    } else if (r == '/settings/audit-logs') {
      permKey = 'page.audit_logs';
    } else if (r.startsWith('/settings')) {
      permKey = 'page.settings';
    } else if (r.startsWith('/clients')) {
      permKey = 'page.clients';
    } else if (r.startsWith('/owners')) {
      permKey = 'page.owners';
    } else if (r.startsWith('/messages')) {
      permKey = 'page.messages';
    } else if (r.startsWith('/builders')) {
      permKey = 'page.builders';
    }

    if (permKey != null) {
      return hasPermission(normRole, permKey);
    }
    return true; // Unrestricted default for general subpages
  }

  /// Sets or toggles a permission for a specific role.
  Future<void> setPermission(String role, String permissionKey, bool allowed) async {
    final normRole = _normalizeRole(role);
    if (normRole == 'Super Admin') return; // Cannot modify Super Admin

    if (!_overrides.containsKey(normRole)) {
      _overrides[normRole] = {};
    }
    _overrides[normRole]![permissionKey] = allowed;
    notifyListeners();
    await _saveToStorage();
  }

  /// Bulk updates all permissions for a category for a given role.
  Future<void> setCategoryPermissions(String role, String category, bool allowed) async {
    final normRole = _normalizeRole(role);
    if (normRole == 'Super Admin') return;

    final permsInCategory = allPermissions.where((p) => p.category == category);
    for (final p in permsInCategory) {
      if (!_overrides.containsKey(normRole)) {
        _overrides[normRole] = {};
      }
      _overrides[normRole]![p.key] = allowed;
    }
    notifyListeners();
    await _saveToStorage();
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

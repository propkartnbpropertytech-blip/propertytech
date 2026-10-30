import 'package:flutter/material.dart';

/// Represents a single navigable node in the PropKart App Shell,
/// including main sidebar items, dropdown parents, and nested subpages.
class AppNavItem {
  final String key;
  final String title;
  final String route;
  final IconData icon;
  final String? parentKey;
  final List<String> supportedRoles;
  final List<AppNavItem> children;
  final int sortOrder;

  const AppNavItem({
    required this.key,
    required this.title,
    required this.route,
    required this.icon,
    this.parentKey,
    required this.supportedRoles,
    this.children = const [],
    this.sortOrder = 0,
  });

  bool get isNested => parentKey != null;
  bool get hasChildren => children.isNotEmpty;

  AppNavItem copyWith({
    String? key,
    String? title,
    String? route,
    IconData? icon,
    String? parentKey,
    List<String>? supportedRoles,
    List<AppNavItem>? children,
    int? sortOrder,
  }) {
    return AppNavItem(
      key: key ?? this.key,
      title: title ?? this.title,
      route: route ?? this.route,
      icon: icon ?? this.icon,
      parentKey: parentKey ?? this.parentKey,
      supportedRoles: supportedRoles ?? this.supportedRoles,
      children: children ?? this.children,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Centralized authoritative navigation registry for PropKart.
/// Automatically detects and structures all menu items and nested subpages for each role.
class AppNavigationRegistry {
  static const List<AppNavItem> masterNavigationTree = [
    // 1. Dashboard
    AppNavItem(
      key: 'page.dashboard',
      title: 'Dashboard',
      route: '/dashboard',
      icon: Icons.grid_view_rounded,
      supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
      sortOrder: 10,
    ),

    // 2. Properties Inventory
    AppNavItem(
      key: 'page.properties',
      title: 'Properties',
      route: '/properties',
      icon: Icons.home_work_outlined,
      supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
      sortOrder: 20,
    ),

    // 3. Telecaller Exclusive: My Calling Leads
    AppNavItem(
      key: 'page.telecaller_leads',
      title: 'My Calling Leads',
      route: '/campaign/leads',
      icon: Icons.phone_in_talk_outlined,
      supportedRoles: ['Telecaller'],
      sortOrder: 25,
    ),

    // 4. Telecaller Exclusive: Callbacks
    AppNavItem(
      key: 'page.callbacks',
      title: 'Callbacks',
      route: '/telecaller/callbacks',
      icon: Icons.event_repeat,
      supportedRoles: ['Telecaller'],
      sortOrder: 26,
    ),

    // 5. Telecaller Exclusive: CNR / Retry Desk
    AppNavItem(
      key: 'page.cnr',
      title: 'CNR / Retry Desk',
      route: '/telecaller/cnr',
      icon: Icons.phone_missed_outlined,
      supportedRoles: ['Telecaller'],
      sortOrder: 27,
    ),

    // 6. Leads & Requirements Pipeline
    AppNavItem(
      key: 'page.leads',
      title: 'Leads & Requirements',
      route: '/requirements',
      icon: Icons.assignment_outlined,
      supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
      sortOrder: 30,
    ),

    // 7. Employees & Users Roster
    AppNavItem(
      key: 'page.employees',
      title: 'Employees & Users',
      route: '/users',
      icon: Icons.people_outline_rounded,
      supportedRoles: ['Super Admin', 'Admin'],
      sortOrder: 40,
    ),

    // 8. Reports & Insights
    AppNavItem(
      key: 'page.reports',
      title: 'Reports & Insights',
      route: '/reports',
      icon: Icons.bar_chart_rounded,
      supportedRoles: ['Super Admin', 'Admin'],
      sortOrder: 50,
    ),

    // 9. Campaign & Webhook Ingestion (Parent + Nested Subpages)
    AppNavItem(
      key: 'page.campaign',
      title: 'Campaign & Webhooks',
      route: '/campaign',
      icon: Icons.campaign_outlined,
      supportedRoles: ['Super Admin', 'Admin'],
      sortOrder: 60,
      children: [
        AppNavItem(
          key: 'page.campaign.connections',
          title: 'Connections',
          route: '/campaign/connections',
          icon: Icons.hub_outlined,
          parentKey: 'page.campaign',
          supportedRoles: ['Super Admin', 'Admin'],
          sortOrder: 61,
        ),
        AppNavItem(
          key: 'page.campaign.meta',
          title: 'Meta',
          route: '/campaign/meta',
          icon: Icons.campaign_outlined,
          parentKey: 'page.campaign',
          supportedRoles: ['Super Admin', 'Admin'],
          sortOrder: 62,
        ),
        AppNavItem(
          key: 'page.campaign.housing',
          title: 'Housing',
          route: '/campaign/housing',
          icon: Icons.apartment_outlined,
          parentKey: 'page.campaign',
          supportedRoles: ['Super Admin', 'Admin'],
          sortOrder: 63,
        ),
      ],
    ),

    // 10. Lead Allocation Monitor
    AppNavItem(
      key: 'page.lead_allocation',
      title: 'Lead Allocation',
      route: '/admin/lead-allocation',
      icon: Icons.hub_outlined,
      supportedRoles: ['Super Admin', 'Admin'],
      sortOrder: 70,
    ),

    // 11. Document Library
    AppNavItem(
      key: 'page.library',
      title: 'Document Library',
      route: '/library',
      icon: Icons.folder_outlined,
      supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
      sortOrder: 80,
    ),

    // 12. Settings & Config (Parent + All Nested Subpages)
    AppNavItem(
      key: 'page.settings',
      title: 'Settings & Config',
      route: '/settings',
      icon: Icons.settings_outlined,
      supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
      sortOrder: 90,
      children: [
        AppNavItem(
          key: 'page.settings.profile',
          title: 'Profile',
          route: '/profile',
          icon: Icons.person_outline_rounded,
          parentKey: 'page.settings',
          supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
          sortOrder: 91,
        ),
        AppNavItem(
          key: 'page.settings.themes',
          title: 'Themes',
          route: '/settings?section=themes',
          icon: Icons.palette_outlined,
          parentKey: 'page.settings',
          supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
          sortOrder: 92,
        ),
        AppNavItem(
          key: 'page.settings.appearance',
          title: 'Appearance',
          route: '/settings?section=appearance',
          icon: Icons.tune_rounded,
          parentKey: 'page.settings',
          supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
          sortOrder: 93,
        ),
        AppNavItem(
          key: 'page.settings.locations',
          title: 'Locations',
          route: '/settings/location-config',
          icon: Icons.location_city_outlined,
          parentKey: 'page.settings',
          supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
          sortOrder: 94,
        ),
        AppNavItem(
          key: 'page.settings.match_criteria',
          title: 'Run Match Criteria',
          route: '/settings?section=match_criteria',
          icon: Icons.bolt_rounded,
          parentKey: 'page.settings',
          supportedRoles: ['Super Admin', 'Admin'],
          sortOrder: 95,
        ),
        AppNavItem(
          key: 'page.settings.upload_limits',
          title: 'Upload Limits',
          route: '/settings?section=upload_limits',
          icon: Icons.photo_library_outlined,
          parentKey: 'page.settings',
          supportedRoles: ['Super Admin', 'Admin'],
          sortOrder: 96,
        ),
        AppNavItem(
          key: 'page.settings.kpi_config',
          title: 'KPI Configuration',
          route: '/settings/kpi-config',
          icon: Icons.dashboard_customize_outlined,
          parentKey: 'page.settings',
          supportedRoles: ['Super Admin', 'Admin'],
          sortOrder: 97,
        ),
        AppNavItem(
          key: 'page.settings.backups',
          title: 'Automated Backups',
          route: '/settings?section=backups',
          icon: Icons.cloud_download_rounded,
          parentKey: 'page.settings',
          supportedRoles: ['Super Admin'],
          sortOrder: 98,
        ),
        AppNavItem(
          key: 'page.settings.audit_logs',
          title: 'Audit Logs',
          route: '/settings/audit-logs',
          icon: Icons.history_rounded,
          parentKey: 'page.settings',
          supportedRoles: ['Super Admin'],
          sortOrder: 99,
        ),
        AppNavItem(
          key: 'page.settings.system',
          title: 'System',
          route: '/settings?section=system',
          icon: Icons.info_outline_rounded,
          parentKey: 'page.settings',
          supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
          sortOrder: 100,
        ),
      ],
    ),

    // 13. Super Admin Platform Management
    AppNavItem(
      key: 'page.admin.permissions',
      title: 'Permission Matrix',
      route: '/admin/permissions',
      icon: Icons.security_rounded,
      supportedRoles: ['Super Admin'],
      sortOrder: 110,
    ),
    AppNavItem(
      key: 'page.admin.plans',
      title: 'Tier Plans Studio',
      route: '/admin/plans',
      icon: Icons.workspace_premium_rounded,
      supportedRoles: ['Super Admin'],
      sortOrder: 120,
    ),
    AppNavItem(
      key: 'page.admin.brokers',
      title: 'Broker Workspaces',
      route: '/admin/brokers',
      icon: Icons.domain_rounded,
      supportedRoles: ['Super Admin'],
      sortOrder: 130,
    ),

    // 14. Support & Help Desk
    AppNavItem(
      key: 'page.support',
      title: 'Support',
      route: '/support',
      icon: Icons.support_agent_rounded,
      supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
      sortOrder: 140,
    ),

    // 15. Super Admin Centralized Support
    AppNavItem(
      key: 'page.admin.support',
      title: 'Issue Management',
      route: '/admin/support',
      icon: Icons.admin_panel_settings_outlined,
      supportedRoles: ['Super Admin'],
      sortOrder: 150,
    ),

    // 16. Recycle Bin
    AppNavItem(
      key: 'page.bin',
      title: 'Recycle Bin',
      route: '/bin',
      icon: Icons.delete_outline_rounded,
      supportedRoles: ['Super Admin', 'Admin', 'Telecaller', 'Sales'],
      sortOrder: 160,
    ),
  ];

  static String normalizeRole(String? raw) {
    final r = (raw ?? '').trim().toLowerCase();
    if (r == 'super admin' || r == 'superadmin') return 'Super Admin';
    if (r == 'admin') return 'Admin';
    if (r == 'telecaller') return 'Telecaller';
    return 'Sales';
  }

  /// Returns the complete navigation tree tailored for a specific role
  static List<AppNavItem> getNavItemsForRole(String role) {
    final norm = normalizeRole(role);
    final List<AppNavItem> result = [];
    for (final item in masterNavigationTree) {
      if (item.supportedRoles.contains(norm)) {
        final childrenForRole =
            item.children.where((c) => c.supportedRoles.contains(norm)).toList();
        result.add(item.copyWith(children: childrenForRole));
      }
    }
    return result;
  }

  /// Returns a flattened list of all top-level items and subpages for a role
  static List<AppNavItem> getFlatItemsForRole(String role) {
    final items = getNavItemsForRole(role);
    final List<AppNavItem> flat = [];
    for (final it in items) {
      flat.add(it);
      for (final child in it.children) {
        flat.add(child);
      }
    }
    return flat;
  }
}

import 'package:flutter/material.dart';

/// Represents a single navigable node in the PropKart App Shell,
/// including main sidebar items, dropdown parents, and nested subpages.
class AppNavItem {
  final String key;
  final String title;
  final String route;

  /// Name of the icon in [AppNavigationRegistry.icons]; persisted with the page.
  final String iconName;
  final String? parentKey;

  /// Permission Matrix key that gates this page. Defaults to [key].
  final String? permissionKey;
  final List<String> supportedRoles;
  final List<AppNavItem> children;
  final int sortOrder;

  const AppNavItem({
    required this.key,
    required this.title,
    required this.route,
    required this.iconName,
    this.parentKey,
    this.permissionKey,
    required this.supportedRoles,
    this.children = const [],
    this.sortOrder = 0,
  });

  IconData get icon => AppNavigationRegistry.iconFor(iconName);
  String get effectivePermissionKey => permissionKey ?? key;
  bool get isNested => parentKey != null;
  bool get hasChildren => children.isNotEmpty;

  /// Number of nested pages at every depth below this item.
  int get descendantCount =>
      children.fold<int>(0, (sum, c) => sum + 1 + c.descendantCount);

  AppNavItem copyWith({
    String? key,
    String? title,
    String? route,
    String? iconName,
    String? parentKey,
    String? permissionKey,
    List<String>? supportedRoles,
    List<AppNavItem>? children,
    int? sortOrder,
  }) {
    return AppNavItem(
      key: key ?? this.key,
      title: title ?? this.title,
      route: route ?? this.route,
      iconName: iconName ?? this.iconName,
      parentKey: parentKey ?? this.parentKey,
      permissionKey: permissionKey ?? this.permissionKey,
      supportedRoles: supportedRoles ?? this.supportedRoles,
      children: children ?? this.children,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Payload for `PUT /permissions/navigation/sync`.
  Map<String, dynamic> toSyncJson() => {
        'key': key,
        'title': title,
        'route': route,
        'icon': iconName,
        'parentKey': parentKey,
        'permissionKey': effectivePermissionKey,
        'sortOrder': sortOrder,
        'roles': supportedRoles,
      };

  /// A flat page row from `app_navigation_pages` (children are attached by the tree builder).
  factory AppNavItem.fromDbRow(Map<String, dynamic> row) {
    final roles = row['roles'];
    return AppNavItem(
      key: row['page_key']?.toString() ?? '',
      title: row['title']?.toString() ?? '',
      route: row['route']?.toString() ?? '/',
      iconName: row['icon']?.toString() ?? '',
      parentKey: (row['parent_key']?.toString().isNotEmpty ?? false) ? row['parent_key'].toString() : null,
      permissionKey: row['permission_key']?.toString(),
      supportedRoles: roles is List ? roles.map((r) => r.toString()).toList() : const [],
      sortOrder: row['sort_order'] is int ? row['sort_order'] as int : int.tryParse('${row['sort_order']}') ?? 0,
    );
  }
}

/// Centralized authoritative navigation registry for PropKart.
///
/// Every sidebar page and nested page must be declared here. The registry is
/// synced into the `app_navigation_pages` table, which the Permission Matrix
/// Live Nav Simulator reads, so a page added here appears there automatically.
class AppNavigationRegistry {
  static const Map<String, IconData> icons = {
    'grid_view_rounded': Icons.grid_view_rounded,
    'home_work_outlined': Icons.home_work_outlined,
    'phone_in_talk_outlined': Icons.phone_in_talk_outlined,
    'event_repeat': Icons.event_repeat,
    'phone_missed_outlined': Icons.phone_missed_outlined,
    'assignment_outlined': Icons.assignment_outlined,
    'campaign_outlined': Icons.campaign_outlined,
    'people_outline_rounded': Icons.people_outline_rounded,
    'bar_chart_rounded': Icons.bar_chart_rounded,
    'insights_rounded': Icons.insights_rounded,
    'headset_mic_outlined': Icons.headset_mic_outlined,
    'person_outline_rounded': Icons.person_outline_rounded,
    'tune_rounded': Icons.tune_rounded,
    'hub_outlined': Icons.hub_outlined,
    'source_outlined': Icons.source_outlined,
    'apartment_outlined': Icons.apartment_outlined,
    'folder_outlined': Icons.folder_outlined,
    'settings_outlined': Icons.settings_outlined,
    'palette_outlined': Icons.palette_outlined,
    'location_city_outlined': Icons.location_city_outlined,
    'bolt_rounded': Icons.bolt_rounded,
    'photo_library_outlined': Icons.photo_library_outlined,
    'dashboard_customize_outlined': Icons.dashboard_customize_outlined,
    'cloud_download_rounded': Icons.cloud_download_rounded,
    'history_rounded': Icons.history_rounded,
    'info_outline_rounded': Icons.info_outline_rounded,
    'security_rounded': Icons.security_rounded,
    'workspace_premium_rounded': Icons.workspace_premium_rounded,
    'domain_rounded': Icons.domain_rounded,
    'insights_outlined': Icons.insights_outlined,
    'support_agent_rounded': Icons.support_agent_rounded,
    'admin_panel_settings_outlined': Icons.admin_panel_settings_outlined,
    'delete_outline_rounded': Icons.delete_outline_rounded,
  };

  static IconData iconFor(String? name) => icons[name] ?? Icons.article_outlined;

  static const List<String> _allRoles = ['Super Admin', 'Admin', 'Telecaller', 'Sales'];
  static const List<String> _adminRoles = ['Super Admin', 'Admin'];
  static const List<String> _superAdminOnly = ['Super Admin'];

  static const List<AppNavItem> masterNavigationTree = [
    AppNavItem(
      key: 'page.dashboard',
      title: 'Dashboard',
      route: '/dashboard',
      iconName: 'grid_view_rounded',
      supportedRoles: _allRoles,
      sortOrder: 10,
    ),
    AppNavItem(
      key: 'page.properties',
      title: 'Properties',
      route: '/properties',
      iconName: 'home_work_outlined',
      supportedRoles: _allRoles,
      sortOrder: 20,
    ),
    AppNavItem(
      key: 'page.telecaller_leads',
      title: 'My Calling Leads',
      route: '/campaign/leads',
      iconName: 'phone_in_talk_outlined',
      supportedRoles: ['Telecaller'],
      sortOrder: 25,
    ),
    AppNavItem(
      key: 'page.callbacks',
      title: 'Callbacks',
      route: '/telecaller/callbacks',
      iconName: 'event_repeat',
      supportedRoles: ['Telecaller'],
      sortOrder: 26,
    ),
    AppNavItem(
      key: 'page.cnr',
      title: 'CNR / Retry Desk',
      route: '/telecaller/cnr',
      iconName: 'phone_missed_outlined',
      supportedRoles: ['Telecaller'],
      sortOrder: 27,
    ),
    AppNavItem(
      key: 'page.leads',
      title: 'Leads & Requirements',
      route: '/requirements',
      iconName: 'assignment_outlined',
      supportedRoles: _allRoles,
      sortOrder: 30,
    ),
    AppNavItem(
      key: 'page.employees',
      title: 'Employees & Users',
      route: '/users',
      iconName: 'people_outline_rounded',
      supportedRoles: _adminRoles,
      sortOrder: 40,
    ),
    AppNavItem(
      key: 'page.reports',
      title: 'Reports & Insights',
      route: '/reports',
      iconName: 'bar_chart_rounded',
      supportedRoles: _adminRoles,
      sortOrder: 50,
      children: [
        AppNavItem(
          key: 'page.reports.overall_insight',
          title: 'Overall Business Insight',
          route: '/reports/leads/overall-business-insight',
          iconName: 'insights_rounded',
          parentKey: 'page.reports',
          permissionKey: 'page.reports',
          supportedRoles: _adminRoles,
          sortOrder: 51,
        ),
        AppNavItem(
          key: 'page.reports.telecaller',
          title: 'Telecaller Report',
          route: '/reports/leads/telecaller',
          iconName: 'headset_mic_outlined',
          parentKey: 'page.reports',
          supportedRoles: _adminRoles,
          sortOrder: 52,
        ),
        AppNavItem(
          key: 'page.reports.sales',
          title: 'Sales Report',
          route: '/reports/leads/sales',
          iconName: 'person_outline_rounded',
          parentKey: 'page.reports',
          supportedRoles: _adminRoles,
          sortOrder: 53,
        ),
        AppNavItem(
          key: 'page.reports.lead_metrics',
          title: 'Lead Metrics',
          route: '/reports/leads/metrics',
          iconName: 'tune_rounded',
          parentKey: 'page.reports',
          supportedRoles: _adminRoles,
          sortOrder: 54,
        ),
        AppNavItem(
          key: 'page.reports.properties',
          title: 'Property Reports',
          route: '/reports/properties',
          iconName: 'home_work_outlined',
          parentKey: 'page.reports',
          supportedRoles: _adminRoles,
          sortOrder: 55,
        ),
      ],
    ),
    AppNavItem(
      key: 'page.campaign',
      title: 'Campaign & Webhooks',
      route: '/campaign',
      iconName: 'campaign_outlined',
      supportedRoles: _adminRoles,
      sortOrder: 60,
      children: [
        AppNavItem(
          key: 'page.campaign.connections',
          title: 'Connections',
          route: '/campaign/connections',
          iconName: 'hub_outlined',
          parentKey: 'page.campaign',
          supportedRoles: _adminRoles,
          sortOrder: 61,
        ),
        AppNavItem(
          key: 'page.campaign.sources',
          title: 'Sources',
          route: '/campaign/sources',
          iconName: 'source_outlined',
          parentKey: 'page.campaign',
          permissionKey: 'page.campaign',
          supportedRoles: _adminRoles,
          sortOrder: 62,
          children: [
            AppNavItem(
              key: 'page.campaign.meta',
              title: 'Meta',
              route: '/campaign/meta',
              iconName: 'campaign_outlined',
              parentKey: 'page.campaign.sources',
              supportedRoles: _adminRoles,
              sortOrder: 63,
            ),
            AppNavItem(
              key: 'page.campaign.housing',
              title: 'Housing',
              route: '/campaign/housing',
              iconName: 'apartment_outlined',
              parentKey: 'page.campaign.sources',
              supportedRoles: _adminRoles,
              sortOrder: 64,
            ),
          ],
        ),
      ],
    ),
    AppNavItem(
      key: 'page.lead_allocation',
      title: 'Lead Allocation',
      route: '/admin/lead-allocation',
      iconName: 'hub_outlined',
      supportedRoles: _adminRoles,
      sortOrder: 70,
    ),
    AppNavItem(
      key: 'page.library',
      title: 'Document Library',
      route: '/library',
      iconName: 'folder_outlined',
      supportedRoles: _allRoles,
      sortOrder: 80,
    ),
    AppNavItem(
      key: 'page.settings',
      title: 'Settings & Config',
      route: '/settings',
      iconName: 'settings_outlined',
      supportedRoles: _allRoles,
      sortOrder: 90,
      children: [
        AppNavItem(
          key: 'page.settings.profile',
          title: 'Profile',
          route: '/profile',
          iconName: 'person_outline_rounded',
          parentKey: 'page.settings',
          supportedRoles: _allRoles,
          sortOrder: 91,
        ),
        AppNavItem(
          key: 'page.settings.themes',
          title: 'Themes',
          route: '/settings?section=themes',
          iconName: 'palette_outlined',
          parentKey: 'page.settings',
          supportedRoles: _allRoles,
          sortOrder: 92,
        ),
        AppNavItem(
          key: 'page.settings.appearance',
          title: 'Appearance',
          route: '/settings?section=appearance',
          iconName: 'tune_rounded',
          parentKey: 'page.settings',
          supportedRoles: _allRoles,
          sortOrder: 93,
        ),
        AppNavItem(
          key: 'page.settings.locations',
          title: 'Locations',
          route: '/settings/location-config',
          iconName: 'location_city_outlined',
          parentKey: 'page.settings',
          supportedRoles: _allRoles,
          sortOrder: 94,
        ),
        AppNavItem(
          key: 'page.settings.match_criteria',
          title: 'Run Match Criteria',
          route: '/settings?section=match_criteria',
          iconName: 'bolt_rounded',
          parentKey: 'page.settings',
          supportedRoles: _adminRoles,
          sortOrder: 95,
        ),
        AppNavItem(
          key: 'page.settings.upload_limits',
          title: 'Upload Limits',
          route: '/settings?section=upload_limits',
          iconName: 'photo_library_outlined',
          parentKey: 'page.settings',
          supportedRoles: _adminRoles,
          sortOrder: 96,
        ),
        AppNavItem(
          key: 'page.settings.kpi_config',
          title: 'KPI Configuration',
          route: '/settings/kpi-config',
          iconName: 'dashboard_customize_outlined',
          parentKey: 'page.settings',
          supportedRoles: _adminRoles,
          sortOrder: 97,
        ),
        AppNavItem(
          key: 'page.settings.backups',
          title: 'Automated Backups',
          route: '/settings?section=backups',
          iconName: 'cloud_download_rounded',
          parentKey: 'page.settings',
          supportedRoles: _superAdminOnly,
          sortOrder: 98,
        ),
        AppNavItem(
          key: 'page.settings.audit_logs',
          title: 'Audit Logs',
          route: '/settings/audit-logs',
          iconName: 'history_rounded',
          parentKey: 'page.settings',
          supportedRoles: _superAdminOnly,
          sortOrder: 99,
        ),
        AppNavItem(
          key: 'page.settings.system',
          title: 'System',
          route: '/settings?section=system',
          iconName: 'info_outline_rounded',
          parentKey: 'page.settings',
          supportedRoles: _allRoles,
          sortOrder: 100,
        ),
      ],
    ),
    AppNavItem(
      key: 'page.admin.permissions',
      title: 'Permission Matrix',
      route: '/admin/permissions',
      iconName: 'security_rounded',
      supportedRoles: _superAdminOnly,
      sortOrder: 110,
    ),
    AppNavItem(
      key: 'page.admin.plans',
      title: 'Tier Plans Studio',
      route: '/admin/plans',
      iconName: 'workspace_premium_rounded',
      supportedRoles: _superAdminOnly,
      sortOrder: 120,
    ),
    AppNavItem(
      key: 'page.admin.brokers',
      title: 'Broker Workspaces',
      route: '/admin/brokers',
      iconName: 'domain_rounded',
      supportedRoles: _superAdminOnly,
      sortOrder: 130,
    ),
    AppNavItem(
      key: 'page.admin.metrics',
      title: 'Super Admin Metrics',
      route: '/reports/leads/super-admin-metrics',
      iconName: 'insights_outlined',
      supportedRoles: _superAdminOnly,
      sortOrder: 135,
    ),
    AppNavItem(
      key: 'page.support',
      title: 'Support',
      route: '/support',
      iconName: 'support_agent_rounded',
      supportedRoles: _allRoles,
      sortOrder: 140,
    ),
    AppNavItem(
      key: 'page.admin.support',
      title: 'Issue Management',
      route: '/admin/support',
      iconName: 'admin_panel_settings_outlined',
      supportedRoles: _superAdminOnly,
      sortOrder: 150,
    ),
    AppNavItem(
      key: 'page.bin',
      title: 'Recycle Bin',
      route: '/bin',
      iconName: 'delete_outline_rounded',
      supportedRoles: _allRoles,
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

  /// Every page in [masterNavigationTree] at every depth, parents before children.
  static List<AppNavItem> flattenAll([List<AppNavItem> items = masterNavigationTree]) {
    final flat = <AppNavItem>[];
    void walk(AppNavItem item) {
      flat.add(item);
      item.children.forEach(walk);
    }
    items.forEach(walk);
    return flat;
  }

  /// Builds the role's page tree from flat page rows (parent links via [AppNavItem.parentKey]).
  /// A nested page is shown only when its parent is also offered to the role.
  static List<AppNavItem> buildTreeForRole(List<AppNavItem> flatPages, String role) {
    final norm = normalizeRole(role);
    final offered = flatPages.where((p) => p.supportedRoles.contains(norm)).toList();
    final byParent = <String?, List<AppNavItem>>{};
    for (final p in offered) {
      byParent.putIfAbsent(p.parentKey, () => []).add(p);
    }

    List<AppNavItem> build(String? parentKey, Set<String> path) {
      final level = [...?byParent[parentKey]]
        ..sort((a, b) {
          final c = a.sortOrder.compareTo(b.sortOrder);
          return c != 0 ? c : a.title.compareTo(b.title);
        });
      return [
        for (final p in level)
          if (!path.contains(p.key)) p.copyWith(children: build(p.key, {...path, p.key})),
      ];
    }

    return build(null, const {});
  }

  /// Returns the complete navigation tree tailored for a specific role
  static List<AppNavItem> getNavItemsForRole(String role) =>
      buildTreeForRole(flattenAll(), role);

  /// Returns a flattened list of all top-level items and subpages for a role
  static List<AppNavItem> getFlatItemsForRole(String role) =>
      flattenAll(getNavItemsForRole(role));
}

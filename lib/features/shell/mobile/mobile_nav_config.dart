import 'package:flutter/material.dart';

import '../../../core/design_system/mobile/mobile_bottom_nav.dart';
import '../../../core/security/role_guard.dart';

typedef RouteVisibility = bool Function(String route);

/// What a More row does when tapped.
enum MobileMoreTarget {
  /// `context.go(route)`.
  route,

  /// Pushes the existing `SyncDebugScreen`, as Settings does (DR-017).
  syncDiagnostics,
}

/// One row in the More screen. [route] is also the permission key used to
/// decide visibility.
@immutable
class MobileMoreEntry {
  final String id;
  final String label;
  final IconData icon;
  final String route;
  final MobileMoreTarget target;

  const MobileMoreEntry({
    required this.id,
    required this.label,
    required this.icon,
    required this.route,
    this.target = MobileMoreTarget.route,
  });
}

@immutable
class MobileMoreSection {
  final String title;
  final List<MobileMoreEntry> entries;

  const MobileMoreSection({required this.title, required this.entries});
}

/// Where a location sits in the mobile shell.
@immutable
class MobileLocationInfo {
  /// Bottom-nav index to highlight, or -1.
  final int selectedIndex;
  final String title;

  /// True when the top bar should show Back (not a root tab).
  final bool isSecondary;

  /// Where Back goes when the router has nothing to pop.
  final String backFallback;

  const MobileLocationInfo({
    required this.selectedIndex,
    required this.title,
    required this.isSecondary,
    required this.backFallback,
  });
}

/// Route access as the existing app already decides it: the same
/// `RoleGuard` gates used by `ModernSidebar` and
/// `RoleGuard.sanitizeRedirectPath`, on top of `canViewPage`.
class MobileNavAccess {
  MobileNavAccess._();

  static bool canOpen(String? role, String route) {
    final r = route.toLowerCase();
    if (r.startsWith('/users') && !RoleGuard.canManageEmployees(role)) {
      return false;
    }
    if ((r.startsWith('/campaign') || r.startsWith('/integration')) &&
        !RoleGuard.canAccessCampaign(role)) {
      return false;
    }
    if (r.startsWith('/settings/audit-logs')) {
      return RoleGuard.canViewAuditLogs(role);
    }
    if (r.startsWith('/reports') && !RoleGuard.canViewReports(role)) {
      return false;
    }
    if (r.startsWith('/admin/lead-allocation') && !RoleGuard.isAdmin(role)) {
      return false;
    }
    return RoleGuard.canViewPage(role, route);
  }
}

/// Frozen per-role bottom tabs and More destinations.
///
/// Visibility defaults to [MobileNavAccess.canOpen]; this class grants
/// nothing new and tests inject their own visibility.
class MobileNavConfig {
  MobileNavConfig._();

  static const String moreRoute = '/more';
  static const String homeRoute = '/dashboard';

  static const _home = MobileNavItem(
    id: 'home',
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    route: homeRoute,
  );
  static const _more = MobileNavItem(
    id: 'more',
    label: 'More',
    icon: Icons.menu_rounded,
    route: moreRoute,
  );
  static const _leads = MobileNavItem(
    id: 'leads',
    label: 'Leads',
    icon: Icons.people_outline_rounded,
    selectedIcon: Icons.people_rounded,
    route: '/requirements',
  );
  static const _properties = MobileNavItem(
    id: 'properties',
    label: 'Properties',
    icon: Icons.apartment_outlined,
    selectedIcon: Icons.apartment_rounded,
    route: '/properties',
  );

  static RouteVisibility _defaultVisibility(String? role) =>
      (route) => MobileNavAccess.canOpen(role, route);

  /// Bottom tabs for [role], already filtered by permissions. A tab is shown
  /// when its route or any of its alternate prefixes is permitted (the
  /// sidebar shows "My Calling Leads" for `/telecaller/leads` or `/campaign`).
  static List<MobileNavItem> tabsForRole(
    String? role, {
    RouteVisibility? canView,
  }) {
    final visible = canView ?? _defaultVisibility(role);
    final List<MobileNavItem> tabs;
    if (RoleGuard.isTelecaller(role)) {
      tabs = const [
        _home,
        MobileNavItem(
          id: 'queue',
          label: 'My Calling',
          icon: Icons.phone_in_talk_outlined,
          selectedIcon: Icons.phone_in_talk_rounded,
          route: '/campaign/leads',
          matchPrefixes: ['/telecaller/leads'],
        ),
        MobileNavItem(
          id: 'callbacks',
          label: 'Callbacks',
          icon: Icons.event_outlined,
          selectedIcon: Icons.event_rounded,
          route: '/telecaller/callbacks',
        ),
        MobileNavItem(
          id: 'cnr',
          label: 'CNR',
          icon: Icons.phone_missed_outlined,
          selectedIcon: Icons.phone_missed_rounded,
          route: '/telecaller/cnr',
        ),
        _more,
      ];
    } else if (RoleGuard.isAdmin(role)) {
      tabs = const [
        _home,
        _leads,
        _properties,
        MobileNavItem(
          id: 'reports',
          label: 'Reports',
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart_rounded,
          route: '/reports/leads/overall-business-insight',
          matchPrefixes: ['/reports'],
        ),
        _more,
      ];
    } else {
      tabs = const [_home, _leads, _properties, _more];
    }
    return tabs
        .where((t) =>
            t.id == 'more' ||
            visible(t.route) ||
            (t.id == 'queue' && t.matchPrefixes.any(visible)))
        .toList(growable: false);
  }

  /// Index of the tab that owns [location], or -1 when none does.
  static int indexForLocation(List<MobileNavItem> tabs, String location) {
    return tabs.indexWhere((t) => t.matchesLocation(location));
  }

  /// More sections for [role], filtered by permissions. Empty sections are
  /// dropped.
  static List<MobileMoreSection> moreForRole(
    String? role, {
    RouteVisibility? canView,
  }) {
    final visible = canView ?? _defaultVisibility(role);
    final List<MobileMoreSection> sections;

    const profile = MobileMoreEntry(
      id: 'profile',
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      route: '/profile',
    );
    const library = MobileMoreEntry(
      id: 'library',
      label: 'Library',
      icon: Icons.photo_library_outlined,
      route: '/library',
    );
    const messages = MobileMoreEntry(
      id: 'messages',
      label: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      route: '/messages',
    );
    const settings = MobileMoreEntry(
      id: 'settings',
      label: 'Settings',
      icon: Icons.settings_outlined,
      route: '/settings',
    );
    const bin = MobileMoreEntry(
      id: 'bin',
      label: 'Recycle bin',
      icon: Icons.delete_outline_rounded,
      route: '/bin',
    );

    if (RoleGuard.isTelecaller(role)) {
      sections = const [
        MobileMoreSection(title: 'Work', entries: [
          MobileMoreEntry(
            id: 'all_leads',
            label: 'All leads',
            icon: Icons.people_outline_rounded,
            route: '/requirements',
          ),
          MobileMoreEntry(
            id: 'properties',
            label: 'Properties',
            icon: Icons.apartment_outlined,
            route: '/properties',
          ),
          library,
          messages,
        ]),
        MobileMoreSection(title: 'Account', entries: [profile, settings, bin]),
      ];
    } else if (RoleGuard.isAdmin(role)) {
      sections = [
        const MobileMoreSection(title: 'Operations', entries: [
          MobileMoreEntry(
            id: 'queue',
            label: 'Calling queue',
            icon: Icons.phone_in_talk_outlined,
            route: '/campaign/meta',
          ),
          MobileMoreEntry(
            id: 'connections',
            label: 'Campaign connections',
            icon: Icons.hub_outlined,
            route: '/campaign/connections',
          ),
          MobileMoreEntry(
            id: 'allocation',
            label: 'Lead allocation',
            icon: Icons.alt_route_rounded,
            route: '/admin/lead-allocation',
          ),
          MobileMoreEntry(
            id: 'callbacks',
            label: 'Callbacks',
            icon: Icons.event_outlined,
            route: '/telecaller/callbacks',
          ),
          MobileMoreEntry(
            id: 'cnr',
            label: 'CNR',
            icon: Icons.phone_missed_outlined,
            route: '/telecaller/cnr',
          ),
        ]),
        MobileMoreSection(title: 'Team', entries: [
          const MobileMoreEntry(
            id: 'employees',
            label: 'Employees',
            icon: Icons.badge_outlined,
            route: '/users',
          ),
          messages,
          if (RoleGuard.isSuperAdmin(role))
            const MobileMoreEntry(
              id: 'super_admin_metrics',
              label: 'Super admin metrics',
              icon: Icons.insights_outlined,
              route: '/reports/leads/super-admin-metrics',
            ),
        ]),
        const MobileMoreSection(title: 'Workspace', entries: [
          library,
          bin,
          MobileMoreEntry(
            id: 'audit_logs',
            label: 'Audit logs',
            icon: Icons.history_rounded,
            route: '/settings/audit-logs',
          ),
          settings,
          MobileMoreEntry(
            id: 'sync_diagnostics',
            label: 'Sync diagnostics',
            icon: Icons.sync_rounded,
            route: '/settings',
            target: MobileMoreTarget.syncDiagnostics,
          ),
        ]),
        const MobileMoreSection(title: 'Account', entries: [profile]),
      ];
    } else {
      sections = const [
        MobileMoreSection(title: 'Work', entries: [library, messages]),
        MobileMoreSection(title: 'Account', entries: [profile, settings, bin]),
      ];
    }

    return [
      for (final s in sections)
        if (s.entries.any((e) => visible(e.route)))
          MobileMoreSection(
            title: s.title,
            entries: s.entries.where((e) => visible(e.route)).toList(),
          ),
    ];
  }

  /// Title, selected tab, and back target for [location].
  ///
  /// Root tabs have no Back. Destinations listed in More highlight More and
  /// go back to `/more`; anything else goes back to Home.
  static MobileLocationInfo resolve(
    String? role,
    String location, {
    RouteVisibility? canView,
  }) {
    final tabs = tabsForRole(role, canView: canView);
    final tabIndex = indexForLocation(tabs, location);
    if (tabIndex >= 0) {
      return MobileLocationInfo(
        selectedIndex: tabIndex,
        title: tabs[tabIndex].label,
        isSecondary: false,
        backFallback: homeRoute,
      );
    }

    if (location == '/settings/location-config' ||
        location.startsWith('/settings/location-config/')) {
      final moreIndex = tabs.indexWhere((t) => t.id == 'more');
      return MobileLocationInfo(
        selectedIndex: moreIndex,
        title: 'Location Config',
        isSecondary: true,
        backFallback: '/settings',
      );
    }

    if (location.startsWith('/campaign/meta') ||
        location.startsWith('/campaign/leads') ||
        location.startsWith('/campaign/housing')) {
      final moreIndex = tabs.indexWhere((t) => t.id == 'more');
      return MobileLocationInfo(
        selectedIndex: moreIndex,
        title: 'Calling queue',
        isSecondary: true,
        backFallback: moreRoute,
      );
    }

    final entries = [
      for (final s in moreForRole(role, canView: canView))
        for (final e in s.entries)
          if (e.target == MobileMoreTarget.route) e,
    ]..sort((a, b) => b.route.length.compareTo(a.route.length));
    final owner = entries.where(
      (e) => location == e.route || location.startsWith('${e.route}/'),
    );
    final moreIndex = tabs.indexWhere((t) => t.id == 'more');
    if (owner.isNotEmpty) {
      return MobileLocationInfo(
        selectedIndex: moreIndex,
        title: owner.first.label,
        isSecondary: true,
        backFallback: moreRoute,
      );
    }
    return const MobileLocationInfo(
      selectedIndex: -1,
      title: 'PropKart',
      isSecondary: true,
      backFallback: homeRoute,
    );
  }
}

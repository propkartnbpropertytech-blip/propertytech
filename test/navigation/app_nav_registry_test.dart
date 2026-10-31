import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/navigation/app_nav_registry.dart';

List<String> _keys(List<AppNavItem> items) =>
    AppNavigationRegistry.flattenAll(items).map((p) => p.key).toList();

void main() {
  final all = AppNavigationRegistry.flattenAll();

  test('every sidebar route is registered (keeps the Live Nav Simulator complete)', () {
    final source = File('lib/features/shell/widgets/sidebar.dart').readAsStringSync();
    final sidebarRoutes = RegExp(r"route:\s*'(/[^']*)'")
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toSet();
    final registered = all.map((p) => p.route).toSet();
    expect(sidebarRoutes, isNotEmpty);
    expect(sidebarRoutes.difference(registered), isEmpty,
        reason: 'Add new sidebar pages to AppNavigationRegistry.masterNavigationTree');
  });

  test('page keys are unique, parents are linked and icons resolve', () {
    expect(all.map((p) => p.key).toSet().length, all.length);
    void check(AppNavItem parent) {
      for (final c in parent.children) {
        expect(c.parentKey, parent.key, reason: c.key);
        check(c);
      }
    }
    for (final root in AppNavigationRegistry.masterNavigationTree) {
      expect(root.parentKey, isNull, reason: root.key);
      check(root);
    }
    for (final p in all) {
      expect(AppNavigationRegistry.icons.containsKey(p.iconName), isTrue, reason: p.key);
    }
  });

  test('role trees include the role-specific and nested pages', () {
    final sales = _keys(AppNavigationRegistry.getNavItemsForRole('Sales'));
    expect(sales, contains('page.my_campaign_leads'));
    expect(sales, isNot(contains('page.campaign.sources')));

    final admin = AppNavigationRegistry.getNavItemsForRole('Admin');
    final campaign = admin.firstWhere((p) => p.key == 'page.campaign');
    final sources = campaign.children.firstWhere((p) => p.key == 'page.campaign.sources');
    expect(sources.children.map((c) => c.key), ['page.campaign.meta', 'page.campaign.housing']);
    expect(_keys(admin), isNot(contains('page.my_campaign_leads')));

    final telecaller = _keys(AppNavigationRegistry.getNavItemsForRole('Telecaller'));
    expect(telecaller, containsAll(['page.telecaller_leads', 'page.callbacks', 'page.cnr']));

    final superAdmin = _keys(AppNavigationRegistry.getNavItemsForRole('Super Admin'));
    expect(superAdmin, containsAll(['page.admin.permissions', 'page.admin.metrics', 'page.settings.audit_logs']));
  });

  test('database rows rebuild the same tree, including pages added only in the database', () {
    final rows = [
      for (final p in all)
        {
          'page_key': p.key,
          'title': p.title,
          'route': p.route,
          'icon': p.iconName,
          'parent_key': p.parentKey,
          'permission_key': p.effectivePermissionKey,
          'sort_order': p.sortOrder,
          'roles': p.supportedRoles,
        },
      {
        'page_key': 'page.reports.new_report',
        'title': 'New Report',
        'route': '/reports/new',
        'icon': 'unknown_icon',
        'parent_key': 'page.reports',
        'permission_key': 'page.reports',
        'sort_order': 59,
        'roles': ['Admin'],
      },
    ];
    final flat = rows.map(AppNavItem.fromDbRow).toList();
    for (final role in ['Super Admin', 'Admin', 'Telecaller', 'Sales']) {
      final fromDb = _keys(AppNavigationRegistry.buildTreeForRole(flat, role));
      final expected = _keys(AppNavigationRegistry.getNavItemsForRole(role));
      if (role == 'Admin') expected.insert(expected.indexOf('page.reports.properties') + 1, 'page.reports.new_report');
      expect(fromDb, expected, reason: role);
    }
  });
}

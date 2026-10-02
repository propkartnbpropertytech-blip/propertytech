import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/security/permission_matrix_service.dart';
import 'package:propkart/features/shell/mobile/mobile_nav_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<String> _labels(String role, {RouteVisibility? canView}) =>
    MobileNavConfig.tabsForRole(role, canView: canView)
        .map((t) => t.label)
        .toList();

List<String> _moreRoutes(String role, {RouteVisibility? canView}) => [
      for (final s in MobileNavConfig.moreForRole(role, canView: canView))
        for (final e in s.entries) e.route,
    ];

bool _all(String _) => true;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PermissionMatrixService.instance.resetToDefaults();
  });

  group('Frozen bottom tabs per role (all permissions granted)', () {
    test('Telecaller', () {
      expect(_labels('Telecaller', canView: _all),
          ['Home', 'Queue', 'Callbacks', 'CNR', 'More']);
    });

    test('Sales', () {
      expect(_labels('Sales', canView: _all),
          ['Home', 'Leads', 'Properties', 'More']);
    });

    test('Admin', () {
      expect(_labels('Admin', canView: _all),
          ['Home', 'Leads', 'Properties', 'Reports', 'More']);
    });

    test('Super Admin uses the Admin tabs', () {
      expect(_labels('Super Admin', canView: _all),
          ['Home', 'Leads', 'Properties', 'Reports', 'More']);
    });

    test('no role exceeds five tabs and none has a center action', () {
      for (final role in ['Telecaller', 'Sales', 'Admin', 'Super Admin']) {
        final tabs = MobileNavConfig.tabsForRole(role, canView: _all);
        expect(tabs.length, lessThanOrEqualTo(5));
        expect(tabs.map((t) => t.id), isNot(contains('add')));
      }
    });
  });

  group('Permission filtering', () {
    test('revoking a route hides its tab', () {
      final tabs = _labels(
        'Telecaller',
        canView: (r) =>
            !r.startsWith('/campaign') && !r.startsWith('/telecaller/leads'),
      );
      expect(tabs, isNot(contains('Queue')));
      expect(tabs, contains('More'));
    });

    test('Queue stays visible through /telecaller/leads (sidebar parity)', () {
      final tabs = _labels(
        'Telecaller',
        canView: (r) => !r.startsWith('/campaign'),
      );
      expect(tabs, contains('Queue'));
    });

    test('default matrix matches canViewRoute for every role', () {
      final service = PermissionMatrixService.instance;
      for (final role in ['Telecaller', 'Sales', 'Admin', 'Super Admin']) {
        for (final tab in MobileNavConfig.tabsForRole(role)) {
          expect(service.canViewRoute(role, tab.route), isTrue,
              reason: '$role tab ${tab.route}');
        }
        for (final route in _moreRoutes(role)) {
          expect(service.canViewRoute(role, route), isTrue,
              reason: '$role more $route');
        }
      }
    });

    test('Super Admin is never filtered', () {
      expect(_labels('Super Admin'),
          ['Home', 'Leads', 'Properties', 'Reports', 'More']);
    });
  });

  group('More destinations', () {
    test('Super Admin extras live in More, not in tabs', () {
      final routes = _moreRoutes('Super Admin');
      expect(routes, contains('/reports/leads/super-admin-metrics'));
      expect(routes, contains('/settings/audit-logs'));
      expect(_moreRoutes('Admin', canView: _all),
          isNot(contains('/reports/leads/super-admin-metrics')));
    });

    test('Sales More has no admin destinations', () {
      final routes = _moreRoutes('Sales', canView: _all);
      expect(routes, isNot(contains('/users')));
      expect(routes, isNot(contains('/admin/lead-allocation')));
      expect(routes, contains('/profile'));
    });

    test('empty sections are dropped', () {
      final sections =
          MobileNavConfig.moreForRole('Sales', canView: (r) => r == '/profile');
      expect(sections.length, 1);
      expect(sections.single.entries.single.route, '/profile');
    });

    test('no Clients / Owners / Builders destinations', () {
      for (final role in ['Telecaller', 'Sales', 'Admin', 'Super Admin']) {
        final routes = [
          ..._moreRoutes(role, canView: _all),
          ...MobileNavConfig.tabsForRole(role, canView: _all).map((t) => t.route),
        ];
        for (final r in routes) {
          expect(r, isNot(anyOf('/clients', '/owners', '/builders')));
        }
      }
    });
  });

  group('indexForLocation', () {
    final tabs = MobileNavConfig.tabsForRole('Admin', canView: _all);

    test('matches exact and nested routes', () {
      expect(MobileNavConfig.indexForLocation(tabs, '/dashboard'), 0);
      expect(MobileNavConfig.indexForLocation(tabs, '/properties/abc'), 2);
      expect(MobileNavConfig.indexForLocation(
              tabs, '/reports/leads/telecaller'), 3);
      expect(MobileNavConfig.indexForLocation(tabs, '/more'), 4);
    });

    test('unknown routes select nothing', () {
      expect(MobileNavConfig.indexForLocation(tabs, '/settings'), -1);
      expect(MobileNavConfig.indexForLocation(tabs, '/propertiesx'), -1);
    });
  });
}

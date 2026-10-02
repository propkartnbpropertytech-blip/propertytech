import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/design_system/mobile/mobile.dart';
import 'package:propkart/core/security/permission_matrix_service.dart';
import 'package:propkart/features/shell/mobile/mobile_app_shell.dart';
import 'package:propkart/features/shell/mobile/mobile_nav_config.dart';
import 'package:propkart/features/shell/mobile/more_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mobile_test_utils.dart';

bool _all(String _) => true;

const _roles = ['Telecaller', 'Sales', 'Admin', 'Super Admin'];
const _step31Widths = <double>[320, 360, 390, 412, 430, 480, 600, 767];

/// Same footprint as `TelecallerAvailabilityToggle(compact: true)`, without
/// starting shift services in a widget test.
const _toggleStandIn = SizedBox(
  key: Key('role_control'),
  width: 145,
  height: 36,
);

class _Calls {
  final navigated = <String>[];
  final back = <String>[];
  int search = 0;
  int notifications = 0;
  int quickActions = 0;
  int messages = 0;
}

Widget _app(
  _Calls calls, {
  String role = 'Admin',
  String location = '/dashboard',
  RouteVisibility canView = _all,
  int unreadNotifications = 0,
  int unreadMessages = 0,
  PreferredSizeWidget? searchBar,
  Widget child = const SizedBox.shrink(),
}) {
  return MaterialApp(
    home: MobileAppShell(
      role: role,
      location: location,
      canView: canView,
      onNavigate: calls.navigated.add,
      onBack: calls.back.add,
      onSearch: () => calls.search++,
      onNotifications: () => calls.notifications++,
      onQuickActions: () => calls.quickActions++,
      onMessages: () => calls.messages++,
      unreadNotifications: unreadNotifications,
      unreadMessages: unreadMessages,
      roleControl: role == 'Telecaller' ? _toggleStandIn : null,
      searchBar: searchBar,
      child: child,
    ),
  );
}

Future<void> _openOverflowAndPick(WidgetTester tester, String id) async {
  await tester.tap(find.byKey(const Key('mobile_more_actions')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('overflow_$id')));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PermissionMatrixService.instance.resetToDefaults();
  });

  group('Shell switch', () {
    test('mobile shell below 768, existing shell from 768', () {
      for (final w in kStep30Widths) {
        expect(MobileLayout.isMobileShell(w), w < 768, reason: '$w');
      }
    });

    test('CRMAppShell routes <768 to the mobile shell with no flag', () {
      final src =
          File('lib/core/design_system/widgets/app_shell.dart').readAsStringSync();
      expect(src, contains('MobileLayout.isMobileShell(size.width)'));
      expect(src, contains('return _buildMobileShell('));
      expect(src, isNot(contains('MobileShellFlags')));
      expect(src, isNot(contains('PROPKART_MOBILE_SHELL')));
      expect(
        File('lib/features/shell/mobile/mobile_shell_flags.dart').existsSync(),
        isFalse,
      );
    });

    test('old mobile drawer and bottom bar are gone from CRMAppShell', () {
      final src =
          File('lib/core/design_system/widgets/app_shell.dart').readAsStringSync();
      expect(src, isNot(contains('CustomBottomNavBar')));
      expect(src, isNot(contains('PersistentTabController')));
      expect(src, isNot(contains('drawer:')));
      expect(src, isNot(contains('child: ModernSidebar(\n')));
      expect(src, isNot(contains('onItemTapped: () => Navigator.of(context).pop()')));
      // Desktop / tablet sidebar is kept.
      expect(src, contains('ModernSidebar('));
      expect(src, contains('ModernTopBar('));
    });

    test('shift gate, notifications panel and sync overlay wrap the mobile shell',
        () {
      final src =
          File('lib/core/design_system/widgets/app_shell.dart').readAsStringSync();
      final start = src.indexOf('Widget _buildMobileShell(');
      final end = src.indexOf('void _closeMobileSearch()');
      final body = src.substring(start, end);
      expect(body, contains('TelecallerShiftGateOverlay('));
      expect(body, contains('_buildNotificationsPanel(context)'));
      expect(body, contains('_buildSyncOverlay()'));
      expect(body, contains('MobileSystemBackHandler('));
      expect(body, contains('_showQuickActionsBottomSheet'));
      expect(body, contains('TelecallerAvailabilityToggle(compact: true)'));
    });
  });

  group('MobileAppShell chrome at every mobile width', () {
    for (final role in _roles) {
      for (final width in _step31Widths) {
        testMobile('$role @ $width: no overflow, no drawer, actions reachable',
            (tester) async {
          await setSurface(tester, width);
          final calls = _Calls();
          await tester.pumpWidget(_app(calls, role: role, unreadMessages: 2));
          expect(tester.takeException(), isNull);
          expect(find.byType(Drawer), findsNothing);
          expect(find.byIcon(Icons.menu_open_rounded), findsNothing);
          expect(find.byType(MobileBottomNav), findsOneWidget);

          // Notifications: always a direct 48x48 action.
          final bell = find.byKey(const Key('mobile_notifications_action'));
          expect(tester.getSize(bell).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(bell).height, greaterThanOrEqualTo(48));
          await tester.tap(bell);
          expect(calls.notifications, 1);

          // Search: direct, or in More actions for a compact telecaller bar.
          final direct = find.byKey(const Key('mobile_search_action'));
          if (role == 'Telecaller' &&
              width < MobileAppShell.telecallerCompactWidth) {
            expect(direct, findsNothing);
            await _openOverflowAndPick(tester, 'search');
          } else {
            expect(tester.getSize(direct).width, greaterThanOrEqualTo(48));
            await tester.tap(direct);
          }
          expect(calls.search, 1);

          await _openOverflowAndPick(tester, 'quick_actions');
          expect(calls.quickActions, 1);
          await _openOverflowAndPick(tester, 'messages');
          expect(calls.messages, 1);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testMobile('telecaller role control is shown in the top bar',
        (tester) async {
      await setSurface(tester, 320);
      await tester.pumpWidget(_app(_Calls(), role: 'Telecaller'));
      expect(find.byKey(const Key('role_control')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Search mode', () {
    testMobile('search bar replaces the top bar and drives existing handlers',
        (tester) async {
      await setSurface(tester, 360);
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final link = LayerLink();
      final changed = <String>[];
      var closed = 0;
      var cleared = 0;
      await tester.pumpWidget(_app(
        _Calls(),
        searchBar: MobileSearchBar(
          controller: controller,
          layerLink: link,
          onChanged: changed.add,
          onClose: () => closed++,
          onClear: () {
            cleared++;
            controller.clear();
          },
        ),
      ));
      expect(find.byType(MobileTopBar), findsNothing);
      expect(
        find.byWidgetPredicate(
          (w) => w is CompositedTransformTarget && w.link == link,
        ),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'andheri');
      await tester.pump();
      expect(changed, ['andheri']);

      final clear = find.bySemanticsLabel('Clear search');
      expect(tester.getSize(clear).width, greaterThanOrEqualTo(48));
      await tester.tap(clear);
      await tester.pump();
      expect(cleared, 1);

      final back = find.bySemanticsLabel('Close search');
      expect(tester.getSize(back).height, greaterThanOrEqualTo(48));
      await tester.tap(back);
      expect(closed, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('Navigation and back', () {
    testMobile('root tab: no Back; tapping a tab navigates', (tester) async {
      await setSurface(tester, 390);
      final calls = _Calls();
      await tester.pumpWidget(_app(calls, role: 'Sales'));
      expect(find.bySemanticsLabel('Back'), findsNothing);
      Finder navLabel(String label) => find.descendant(
            of: find.byType(MobileBottomNav),
            matching: find.text(label),
          );
      await tester.tap(navLabel('Properties'));
      expect(calls.navigated, ['/properties']);
      await tester.tap(navLabel('Home'));
      expect(calls.navigated, ['/properties'], reason: 'already on Home');
    });

    testMobile('More-owned route: More highlighted, Back falls back to /more',
        (tester) async {
      await setSurface(tester, 390);
      final calls = _Calls();
      await tester.pumpWidget(_app(calls, role: 'Sales', location: '/library'));
      expect(find.text('Library'), findsOneWidget);
      final handle = tester.ensureSemantics();
      expect(
        tester.getSemantics(find.bySemanticsLabel('More')),
        isSemantics(isSelected: true, isButton: true),
      );
      handle.dispose();
      await tester.tap(find.bySemanticsLabel('Back'));
      expect(calls.back, ['/more']);
      await tester.tap(find.text('More'));
      expect(calls.navigated, ['/more']);
    });

    test('resolve: tabs, More-owned routes and unknown routes', () {
      final home = MobileNavConfig.resolve('Admin', '/dashboard', canView: _all);
      expect(home.isSecondary, isFalse);
      expect(home.title, 'Home');

      final reports = MobileNavConfig.resolve(
          'Admin', '/reports/leads/telecaller',
          canView: _all);
      expect(reports.isSecondary, isFalse);
      expect(reports.title, 'Reports');

      final audit = MobileNavConfig.resolve(
          'Super Admin', '/settings/audit-logs',
          canView: _all);
      expect(audit.title, 'Audit logs');
      expect(audit.backFallback, MobileNavConfig.moreRoute);
      expect(audit.selectedIndex, 4);

      final queueAlias = MobileNavConfig.resolve(
          'Telecaller', '/telecaller/leads',
          canView: _all);
      expect(queueAlias.title, 'Queue');
      expect(queueAlias.isSecondary, isFalse);

      final unknown =
          MobileNavConfig.resolve('Sales', '/properties-x/1', canView: _all);
      expect(unknown.isSecondary, isTrue);
      expect(unknown.backFallback, MobileNavConfig.homeRoute);
      expect(unknown.selectedIndex, -1);
    });
  });

  group('More per role', () {
    List<String> labels(String role) => [
          for (final s in MobileNavConfig.moreForRole(role, canView: _all))
            for (final e in s.entries) e.label,
        ];

    test('Telecaller', () {
      expect(labels('Telecaller'), [
        'All leads', 'Properties', 'Library', 'Messages', //
        'Profile', 'Settings', 'Recycle bin',
      ]);
    });

    test('Sales', () {
      expect(labels('Sales'),
          ['Library', 'Messages', 'Profile', 'Settings', 'Recycle bin']);
    });

    test('Admin has no Super Admin metrics; Super Admin does', () {
      expect(labels('Admin'), isNot(contains('Super admin metrics')));
      expect(labels('Super Admin'), contains('Super admin metrics'));
    });

    test('Super Admin does not inherit Telecaller/Sales-only rows', () {
      final ids = [
        for (final s in MobileNavConfig.moreForRole('Super Admin', canView: _all))
          for (final e in s.entries) e.id,
      ];
      expect(ids, isNot(contains('all_leads')));
      expect(
        MobileNavConfig.tabsForRole('Super Admin', canView: _all)
            .map((t) => t.id),
        isNot(contains('queue')),
      );
    });

    test('Sync diagnostics is Admin/Super Admin only and not a route', () {
      for (final role in _roles) {
        final entries = [
          for (final s in MobileNavConfig.moreForRole(role, canView: _all))
            ...s.entries,
        ].where((e) => e.id == 'sync_diagnostics');
        if (role == 'Admin' || role == 'Super Admin') {
          expect(entries.single.target, MobileMoreTarget.syncDiagnostics);
        } else {
          expect(entries, isEmpty, reason: role);
        }
      }
    });

    testMobile('More view passes the tapped entry and announces badges',
        (tester) async {
      await setSurface(tester, 360, height: 1600);
      final handle = tester.ensureSemantics();
      final opened = <MobileMoreEntry>[];
      await tester.pumpWidget(wrap(MobileMoreView(
        name: 'Neha',
        email: '',
        role: 'Admin',
        sections: MobileNavConfig.moreForRole('Admin', canView: _all),
        badges: const {'messages': 2},
        onOpen: opened.add,
      )));
      expect(find.bySemanticsLabel(RegExp(r'^Messages, 2 new')), findsOneWidget);
      await tester.tap(find.text('Sync diagnostics'));
      expect(opened.single.target, MobileMoreTarget.syncDiagnostics);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });

  group('Permissions (injected, no backend calls)', () {
    test('revoked routes disappear from tabs and More', () {
      bool canView(String r) =>
          !r.startsWith('/reports') && r != '/users' && r != '/library';
      final tabs = MobileNavConfig.tabsForRole('Admin', canView: canView)
          .map((t) => t.id);
      expect(tabs, isNot(contains('reports')));
      expect(tabs, contains('more'));
      final routes = [
        for (final s in MobileNavConfig.moreForRole('Admin', canView: canView))
          for (final e in s.entries) e.route,
      ];
      expect(routes, isNot(contains('/users')));
      expect(routes, isNot(contains('/library')));
      expect(routes, isNot(contains('/reports/leads/super-admin-metrics')));
    });

    test('default access mirrors RoleGuard gates', () {
      expect(MobileNavAccess.canOpen('Sales', '/users'), isFalse);
      expect(MobileNavAccess.canOpen('Sales', '/admin/lead-allocation'), isFalse);
      expect(MobileNavAccess.canOpen('Admin', '/settings/audit-logs'), isFalse);
      expect(
          MobileNavAccess.canOpen('Super Admin', '/settings/audit-logs'), isTrue);
      expect(MobileNavAccess.canOpen('Admin', '/admin/lead-allocation'), isTrue);
    });

    testMobile('shell hides a revoked tab', (tester) async {
      await setSurface(tester, 390);
      await tester.pumpWidget(_app(
        _Calls(),
        canView: (r) => !r.startsWith('/reports'),
      ));
      expect(find.text('Reports'), findsNothing);
      expect(find.text('More'), findsOneWidget);
    });
  });

  group('Accessibility', () {
    for (final role in _roles) {
      testMobile('$role: labelled 48px targets, header title, badges announced',
          (tester) async {
        await setSurface(tester, 360);
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(_app(
          _Calls(),
          role: role,
          unreadNotifications: 3,
          unreadMessages: 1,
        ));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        expect(find.bySemanticsLabel('Notifications, 3 new'), findsOneWidget);
        expect(find.bySemanticsLabel('More actions, 1 new'), findsOneWidget);
        expect(
          tester.getSemantics(find.descendant(
            of: find.byType(MobileTopBar),
            matching: find.text('Home'),
          )),
          isSemantics(isHeader: true),
        );
        handle.dispose();
      });
    }

    testMobile('MobileShellBadges exposes existing counts to routed pages',
        (tester) async {
      MobileShellBadges? seen;
      await tester.pumpWidget(_app(
        _Calls(),
        unreadNotifications: 5,
        unreadMessages: 4,
        child: Builder(builder: (context) {
          seen = MobileShellBadges.maybeOf(context);
          return const SizedBox.shrink();
        }),
      ));
      expect(seen?.unreadNotifications, 5);
      expect(seen?.unreadMessages, 4);
    });
  });
}

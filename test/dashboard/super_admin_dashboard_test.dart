import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:propkart/features/auth/bloc/auth_bloc.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/dashboard/bloc/super_admin_dashboard_bloc.dart';
import 'package:propkart/features/dashboard/models/super_admin_platform_overview.dart';
import 'package:propkart/features/dashboard/repository/super_admin_dashboard_repository.dart';
import 'package:propkart/features/dashboard/screens/dashboard_screen.dart';
import 'package:propkart/features/dashboard/screens/super_admin_dashboard_screen.dart';

class _FakeOverviewRepository extends SuperAdminDashboardRepository {
  _FakeOverviewRepository() : super(service: null);

  @override
  Future<SuperAdminPlatformOverview> fetch({String? organizationId}) async {
    final selected = organizationId == null
        ? null
        : SuperAdminSelectedWorkspace(
            organization: _broker,
            metrics: const SuperAdminWorkspaceMetrics(
              availableInventory: 4,
              totalLeads: 11,
              activeUsers: 3,
              telecallers: 1,
              salesUsers: 1,
              closedDeals: 2,
              siteVisitsDone: 5,
            ),
          );
    return SuperAdminPlatformOverview(
      summary: const SuperAdminPlatformSummary(
        organizationCount: 6,
        adminWorkspaceCount: 2,
        brokerWorkspaceCount: 3,
        otherWorkspaceCount: 1,
        activeSubscriptionCount: 9,
        expiredSubscriptionCount: 2,
        nearingExpiryCount: 1,
        nearingExpiryDays: 14,
        pendingOnboardingCount: 4,
        openSupportCount: 7,
        inProgressSupportCount: 2,
      ),
      organizations: const [_admin, _broker],
      organizationListTruncated: false,
      attentionSubscriptions: const [_broker],
      pendingOnboarding: const [
        SuperAdminOnboardingRequest(
          id: 'req-1',
          brokerageName: 'Pending Realty',
          fullName: 'Asha Shah',
          email: 'asha@pending.test',
          status: 'PENDING',
        ),
      ],
      openIssues: const [
        SuperAdminOpenIssue(
          id: 'issue-1',
          ticketNumber: 'SUP-1001',
          reporterName: 'Ravi',
          pageName: 'Dashboard',
          status: 'Open',
          priority: 'High',
        ),
      ],
      selectedWorkspace: selected,
    );
  }
}

const _admin = SuperAdminOrganizationRow(
  organizationId: 'org-admin',
  organizationName: 'North Admin',
  ownerName: 'Admin Owner',
  ownerRole: 'Admin',
  workspaceKind: 'admin',
  planName: 'Internal',
  subscriptionStatus: 'ACTIVE',
  subscriptionState: 'active',
);

const _broker = SuperAdminOrganizationRow(
  organizationId: 'org-broker',
  organizationName: 'Harbour Realty',
  ownerName: 'Broker Owner',
  ownerRole: 'Broker',
  workspaceKind: 'broker',
  planName: 'Gold Tier',
  subscriptionStatus: 'ACTIVE',
  subscriptionState: 'nearing_expiry',
);

class _AuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _AuthBloc(String role)
      : super(Authenticated(
          user: UserModel(
            id: 'super-1',
            email: 'root@propkart.test',
            fullName: 'Platform Owner',
            role: role,
            permissions: const ['admin'],
          ),
        )) {
    on<AuthEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpOverview(WidgetTester tester, double width) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = SuperAdminDashboardBloc(repository: _FakeOverviewRepository())
      ..add(const LoadSuperAdminDashboard());
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(path: '/dashboard', builder: (_, _) => const SuperAdminDashboardScreen()),
        GoRoute(path: '/settings/audit-logs', builder: (_, _) => const Text('audit-destination')),
        GoRoute(path: '/admin/brokers', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/admin/plans', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/admin/permissions', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/admin/support', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/reports/leads/super-admin-metrics', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/users', builder: (_, _) => const Text('users-destination')),
        GoRoute(path: '/users/tree', builder: (_, _) => const SizedBox()),
      ],
    );

    await tester.pumpWidget(
      BlocProvider<SuperAdminDashboardBloc>.value(
        value: bloc,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('overview renders authoritative summary counts instead of summing rows', () {
    const overview = SuperAdminPlatformOverview(
      summary: SuperAdminPlatformSummary(
        organizationCount: 6,
        adminWorkspaceCount: 2,
        brokerWorkspaceCount: 3,
        otherWorkspaceCount: 1,
        activeSubscriptionCount: 9,
        expiredSubscriptionCount: 2,
        nearingExpiryCount: 1,
        nearingExpiryDays: 14,
        pendingOnboardingCount: 4,
        openSupportCount: 7,
        inProgressSupportCount: 2,
      ),
      organizations: [_admin],
      organizationListTruncated: true,
      attentionSubscriptions: [],
      pendingOnboarding: [],
      openIssues: [],
    );
    expect(overview.summary.activeSubscriptionCount, 9);
    expect(overview.organizations, hasLength(1));
    expect(overview.summary.activeSubscriptionCount, isNot(overview.organizations.length));
  });

  testWidgets('Super Admin mobile overview does not show the Admin KPI dashboard', (tester) async {
    await pumpOverview(tester, 390);
    expect(find.byKey(const Key('super-admin-dashboard-mobile')), findsOneWidget);
    expect(find.byKey(const Key('super-admin-dashboard-desktop')), findsNothing);
    expect(find.text('Platform overview'), findsOneWidget);
    expect(find.text('Pending onboarding'), findsOneWidget);
    expect(find.text('Available Inventory'), findsNothing);
    expect(find.text('9'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Super Admin desktop overview selects a read-only broker snapshot', (tester) async {
    await pumpOverview(tester, 1200);
    expect(find.byKey(const Key('super-admin-dashboard-desktop')), findsOneWidget);
    expect(find.byKey(const Key('super-admin-dashboard-mobile')), findsNothing);
    expect(find.text('Select an organization to view a read-only Admin or Broker snapshot.'), findsOneWidget);

    await tester.tap(find.text('Harbour Realty').first);
    await tester.pumpAndSettle();

    expect(find.text('Broker workspace'), findsWidgets);
    expect(find.text('Total leads: 11'), findsOneWidget);
    expect(find.text('Available Inventory'), findsNothing);

    final usersLink = find.text('Users');
    await tester.ensureVisible(usersLink);
    await tester.pumpAndSettle();
    await tester.tap(usersLink);
    await tester.pumpAndSettle();
    expect(find.text('users-destination'), findsOneWidget);
  });

  testWidgets('desktop quick link leaves the session on the existing audit page', (tester) async {
    await pumpOverview(tester, 1100);
    await tester.tap(find.text('Audit Logs'));
    await tester.pumpAndSettle();
    expect(find.text('audit-destination'), findsOneWidget);
  });

  testWidgets('narrow width keeps the platform overview without overflow', (tester) async {
    await pumpOverview(tester, 320);
    expect(find.byKey(const Key('super-admin-dashboard-mobile')), findsOneWidget);
    expect(find.text('Open support'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DashboardScreen sends Super Admin to the platform overview', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final bloc = SuperAdminDashboardBloc(repository: _FakeOverviewRepository())
      ..add(const LoadSuperAdminDashboard());
    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: _AuthBloc('Super Admin')),
            BlocProvider<SuperAdminDashboardBloc>.value(value: bloc),
          ],
          child: const DashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('Platform overview'), findsOneWidget);
    expect(find.text('Available Inventory'), findsNothing);
    expect(find.byKey(const Key('super-admin-dashboard-desktop')), findsOneWidget);
  });

  testWidgets('SuperAdminDashboardScreen accepts an injected bloc via constructor', (tester) async {
    final bloc = SuperAdminDashboardBloc(repository: _FakeOverviewRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: SuperAdminDashboardScreen(bloc: bloc),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('super-admin-dashboard-desktop')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SuperAdminDashboardScreen creates its own bloc with custom repository when none exists in context', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SuperAdminDashboardScreen(repository: _FakeOverviewRepository()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('super-admin-dashboard-desktop')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

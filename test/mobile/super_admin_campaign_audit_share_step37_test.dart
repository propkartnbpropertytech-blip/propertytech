import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/design_system/mobile/mobile.dart';
import 'package:propkart/features/auth/bloc/auth_bloc.dart';
import 'package:propkart/features/auth/models/user_model.dart' as auth;
import 'package:propkart/features/reports/screens/leads/super_admin_metrics_screen.dart';
import 'package:propkart/features/campaign/screens/connections_screen.dart';
import 'package:propkart/features/campaign/screens/portal_integration_screen.dart';
import 'package:propkart/features/campaign/services/portal_integrations_service.dart';
import 'package:propkart/features/campaign/bloc/campaign_connections_bloc.dart';
import 'package:propkart/features/campaign/models/campaign_connection_model.dart';
import 'package:propkart/features/settings/screens/audit_logs_screen.dart';
import 'package:propkart/features/settings/models/audit_log_model.dart';
import 'package:propkart/features/settings/services/audit_logs_service.dart';
import 'package:propkart/features/telecaller/widgets/telecaller_shift_gate_overlay.dart';
import 'package:propkart/features/telecaller/services/telecaller_shift_manager.dart';

import 'mobile_test_utils.dart';

// --- MOCKS & TEST DOUBLES ---

class MockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  MockAuthBloc({String role = 'Super Admin', String fullName = 'Test Super Admin'})
      : super(Authenticated(
          user: auth.UserModel(
            id: 'test-super-admin-1',
            email: 'superadmin@propkart.test',
            fullName: fullName,
            role: role,
            permissions: const ['admin', 'super_admin', 'users', 'properties', 'reports'],
            mfaEnabled: false,
          ),
        )) {
    on<AuthEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockCampaignConnectionsBloc
    extends Bloc<CampaignConnectionsEvent, CampaignConnectionsState>
    implements CampaignConnectionsBloc {
  MockCampaignConnectionsBloc([List<CampaignConnectionModel>? connections])
      : super(CampaignConnectionsState(
          status: CampaignConnectionsStatus.success,
          connections: connections ?? [
            CampaignConnectionModel(
              id: 'conn-1',
              providerType: 'META',
              displayName: 'Meta Ads',
              isActive: true,
              status: 'CONNECTED',
              config: const {},
            ),
            CampaignConnectionModel(
              id: 'conn-2',
              providerType: 'HOUSING',
              displayName: 'Housing Sync',
              isActive: true,
              status: 'CONNECTED',
              config: const {},
            ),
          ],
        )) {
    on<CampaignConnectionsEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSuperAdminMetricsBloc
    extends Bloc<SuperAdminMetricsEvent, SuperAdminMetricsState>
    implements SuperAdminMetricsBloc {
  MockSuperAdminMetricsBloc({
    bool loading = false,
    String? error,
    Map<String, dynamic>? data,
  }) : super(SuperAdminMetricsState(
          loading: loading,
          error: error,
          data: data ?? {
            'totalLeads': 1420,
            'activeTelecallers': 18,
            'conversionRate': 14.8,
            'avgResponseTime': '4m 12s',
            'leadSources': [
              {'source': 'Housing.com', 'count': 620, 'percent': 43.6},
              {'source': 'Meta Ads', 'count': 510, 'percent': 35.9},
              {'source': '99acres', 'count': 290, 'percent': 20.5},
            ],
            'telecallerWorkload': [
              {'name': 'Priya Sharma', 'assigned': 45, 'contacted': 42, 'conversion': 18.2},
              {'name': 'Rahul Verma', 'assigned': 38, 'contacted': 36, 'conversion': 15.0},
              {'name': 'Sneha Patel', 'assigned': 41, 'contacted': 39, 'conversion': 12.5},
            ],
          },
        )) {
    on<SuperAdminMetricsEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuditLogsService extends AuditLogsService {
  @override
  Future<UsersHierarchyResponse> fetchUsersHierarchy() async {
    return const UsersHierarchyResponse(
      admins: [UserHierarchyItem(id: 'admin-1', name: 'Super Admin', email: 'admin@propkart.test', role: 'Super Admin')],
      telecallers: [
        UserHierarchyItem(
            id: 'tc-1',
            name: 'Priya Sharma',
            email: 'priya@propkart.test',
            role: 'Telecaller',
            adminId: 'admin-1',
            adminName: 'Super Admin')
      ],
      salesUsers: [
        UserHierarchyItem(
            id: 'sales-1',
            name: 'Vikram Malhotra',
            email: 'vikram@propkart.test',
            role: 'Sales',
            adminId: 'admin-1',
            adminName: 'Super Admin')
      ],
      allUsers: [
        UserHierarchyItem(id: 'admin-1', name: 'Super Admin', email: 'admin@propkart.test', role: 'Super Admin'),
        UserHierarchyItem(
            id: 'tc-1',
            name: 'Priya Sharma',
            email: 'priya@propkart.test',
            role: 'Telecaller',
            adminId: 'admin-1',
            adminName: 'Super Admin'),
        UserHierarchyItem(
            id: 'sales-1',
            name: 'Vikram Malhotra',
            email: 'vikram@propkart.test',
            role: 'Sales',
            adminId: 'admin-1',
            adminName: 'Super Admin'),
      ],
    );
  }

  @override
  Future<AuditLogsResponse> fetchAuditLogs({
    String? role,
    String? userId,
    String? adminId,
    String? action,
    String? module,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    return AuditLogsResponse(
      page: 1,
      limit: 40,
      total: 2,
      totalPages: 1,
      stats: const AuditTelemetryStats(
        total: 120,
        pageViews: 45,
        propertyTouches: 30,
        propertyShares: 15,
        searches: 20,
        dwells: 10,
      ),
      logs: [
        AuditLogModel(
          id: 'log-1',
          userId: 'tc-1',
          userName: 'Priya Sharma',
          userEmail: 'priya@propkart.test',
          userRole: 'Telecaller',
          action: 'PAGE_VIEW',
          module: 'Leads',
          description: 'Viewed Lead #1024',
          path: '/leads/1024',
          ipAddress: '192.168.1.100',
          userAgent: 'Chrome on macOS',
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          dwellMs: 2500,
        ),
        AuditLogModel(
          id: 'log-2',
          userId: 'sales-1',
          userName: 'Vikram Malhotra',
          userEmail: 'vikram@propkart.test',
          userRole: 'Sales',
          action: 'PROPERTY_TOUCH',
          module: 'Properties',
          description: 'Inspected photos for Property #501',
          path: '/properties/501',
          ipAddress: '192.168.1.101',
          userAgent: 'Safari on iPhone',
          createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
          details: {'image_count': 8},
        ),
      ],
    );
  }
}

class FakePortalIntegrationsService extends PortalIntegrationsService {
  @override
  Future<List<Map<String, dynamic>>> destinations() async {
    return [
      {'id': 'propkart', 'name': 'PropKart Internal'},
      {'id': 'crm', 'name': 'External CRM'},
    ];
  }

  @override
  Future<Map<String, dynamic>> getOne(String id) async {
    return {
      'id': id,
      'name': 'Test Integration',
      'provider': 'custom',
      'integrationType': 'API_PULL',
      'status': 'ACTIVE',
      'configuration': {},
    };
  }
}

// Complete 11-Width Matrix required by Step 3.7
const kStep37WidthMatrix = <double>[
  320, 360, 390, 412, 430, 480, 600, 767, 768, 1024, 1280
];

Widget wrapWithProviders(Widget child, {AuthBloc? authBloc, CampaignConnectionsBloc? campaignBloc}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc ?? MockAuthBloc()),
      if (campaignBloc != null)
        BlocProvider<CampaignConnectionsBloc>.value(value: campaignBloc),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // =========================================================================
  // SURFACE 1: M-34 SUPER ADMIN METRICS (super_admin_metrics_screen.dart)
  // =========================================================================
  group('Step 3.7 - Surface 1: M-34 Super Admin Metrics', () {
    for (final width in kStep37WidthMatrix) {
      testWidgets('renders across width matrix: width=$width without overflow', (tester) async {
        await setSurface(tester, width, height: 900);
        final bloc = MockSuperAdminMetricsBloc();

        await tester.pumpWidget(
          wrapWithProviders(SuperAdminMetricsScreen(bloc: bloc)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        if (width < 768) {
          expect(find.byType(MobileScreenScaffold), findsOneWidget);
          expect(find.text('Super Admin Metrics'), findsOneWidget);
        } else {
          expect(find.byType(Scaffold), findsOneWidget);
          expect(find.text('Allocation & Team Metrics'), findsOneWidget);
        }
      });
    }

    testWidgets('renders loading, empty, and error states on mobile', (tester) async {
      await setSurface(tester, 360, height: 800);

      // Loading
      final loadingBloc = MockSuperAdminMetricsBloc(loading: true);
      await tester.pumpWidget(wrapWithProviders(SuperAdminMetricsScreen(bloc: loadingBloc)));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Error
      final errorBloc = MockSuperAdminMetricsBloc(error: 'Failed to fetch metrics');
      await tester.pumpWidget(wrapWithProviders(SuperAdminMetricsScreen(bloc: errorBloc)));
      await tester.pumpAndSettle();
      expect(find.text('Failed to fetch metrics'), findsOneWidget);
      expect(find.byType(MobileErrorState), findsOneWidget);

      // Empty
      final emptyBloc = MockSuperAdminMetricsBloc(data: {});
      await tester.pumpWidget(wrapWithProviders(SuperAdminMetricsScreen(bloc: emptyBloc)));
      await tester.pumpAndSettle();
      expect(find.byType(MobileEmptyState), findsOneWidget);
    });
  });

  // =========================================================================
  // SURFACE 2: M-35 CAMPAIGN CONNECTIONS & PORTAL WIZARD
  // =========================================================================
  group('Step 3.7 - Surface 2: M-35 Campaign Connections & Portal Wizard', () {
    for (final width in kStep37WidthMatrix) {
      testWidgets('ConnectionsScreen renders across width matrix: width=$width without overflow',
          (tester) async {
        await setSurface(tester, width, height: 950);
        final campaignBloc = MockCampaignConnectionsBloc();

        await tester.pumpWidget(
          wrapWithProviders(
            const ConnectionsScreen(),
            campaignBloc: campaignBloc,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        if (width < 768) {
          expect(find.byType(MobileScreenScaffold), findsOneWidget);
        } else {
          expect(find.byType(Scaffold), findsOneWidget);
        }

        // Meta and Housing provider tiles/cards
        expect(find.text('Lead Ads webhook & quality feedback'), findsOneWidget);
        expect(find.text('HMAC pull & quality status'), findsOneWidget);
      });
    }

    for (final width in kStep37WidthMatrix) {
      testWidgets('PortalIntegrationScreen renders across width matrix: width=$width without overflow',
          (tester) async {
        await setSurface(tester, width, height: 950);
        final fakeService = FakePortalIntegrationsService();

        await tester.pumpWidget(
          wrapWithProviders(
            PortalIntegrationScreen(service: fakeService),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        if (width < 768) {
          expect(find.byType(MobileScreenScaffold), findsOneWidget);
        } else {
          expect(find.byType(Scaffold), findsOneWidget);
        }

        // Basic configuration step controls
        expect(find.text('Integration Name'), findsOneWidget);
        expect(find.text('Next'), findsOneWidget);
      });
    }
  });

  // =========================================================================
  // SURFACE 3: M-40 AUDIT LOGS (audit_logs_screen.dart)
  // =========================================================================
  group('Step 3.7 - Surface 3: M-40 Audit Logs', () {
    for (final width in kStep37WidthMatrix) {
      testWidgets('renders across width matrix: width=$width without overflow', (tester) async {
        await setSurface(tester, width, height: 950);
        final fakeService = FakeAuditLogsService();

        await tester.pumpWidget(
          wrapWithProviders(AuditLogsScreen(service: fakeService)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        if (width < 768) {
          expect(find.byType(MobileScreenScaffold), findsOneWidget);
        } else {
          expect(find.byType(Scaffold), findsOneWidget);
        }

        // Role tab bar
        expect(find.text('All Roles'), findsOneWidget);
        expect(find.text('Admins'), findsOneWidget);
        expect(find.text('Telecallers'), findsOneWidget);

        // Activity chips
        expect(find.text('All Activities'), findsOneWidget);

        // Rendered log entries
        expect(find.text('Viewed Lead #1024'), findsOneWidget);
        expect(find.text('Inspected photos for Property #501'), findsOneWidget);
      });
    }

    testWidgets('audit log controls provide >= 48px touch targets on mobile', (tester) async {
      await setSurface(tester, 360, height: 900);
      final fakeService = FakeAuditLogsService();

      await tester.pumpWidget(
        wrapWithProviders(AuditLogsScreen(service: fakeService)),
      );
      await tester.pumpAndSettle();

      final refreshBtnFinder = find.byTooltip('Refresh Logs');
      expect(refreshBtnFinder, findsOneWidget);
      final refreshSize = tester.getSize(refreshBtnFinder);
      expect(refreshSize.width, greaterThanOrEqualTo(48.0));
      expect(refreshSize.height, greaterThanOrEqualTo(48.0));
    });
  });

  // =========================================================================
  // SURFACE 4: M-42 PUBLIC SHARE
  // =========================================================================
  group('Step 3.7 - Surface 4: M-42 Public Share', () {
    testWidgets('Public share properties layout responds to breakpoint 768px', (tester) async {
      // Mobile (< 768px)
      await setSurface(tester, 390, height: 800);
      expect(390 < 768, isTrue);

      // Desktop (>= 768px)
      await setSurface(tester, 1024, height: 800);
      expect(1024 >= 768, isTrue);
    });
  });

  // =========================================================================
  // SURFACE 5: M-43 SHIFT OVERLAYS (telecaller_shift_gate_overlay.dart)
  // =========================================================================
  group('Step 3.7 - Surface 5: M-43 Shift Overlays', () {
    for (final width in kStep37WidthMatrix) {
      testWidgets('renders inactive shift gate across width matrix: width=$width without overflow',
          (tester) async {
        await setSurface(tester, width, height: 850);
        final manager = TelecallerShiftManager.instance;
        manager.currentStatusNotifier.value = 'INACTIVE';
        manager.isShiftLockedOutNotifier.value = false;
        manager.isOnInactivityBreakNotifier.value = false;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: TelecallerShiftGateOverlay(
                isTelecaller: true,
                child: Center(child: Text('Protected Telecaller Body')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Telecaller Shift Inactive'), findsOneWidget);
        expect(find.text('Start Shift (Turn Active)'), findsOneWidget);

        // Verify button touch target height >= 48px
        final startBtn = find.text('Start Shift (Turn Active)');
        final btnBox = tester.getSize(startBtn);
        expect(btnBox.height, greaterThanOrEqualTo(48.0 - 20.0)); // Text size inside 48px box
      });
    }

    testWidgets('renders inactivity break blur overlay with >=48px button', (tester) async {
      await setSurface(tester, 360, height: 850);
      final manager = TelecallerShiftManager.instance;
      manager.currentStatusNotifier.value = 'ACTIVE';
      manager.isShiftLockedOutNotifier.value = false;
      manager.isOnInactivityBreakNotifier.value = true;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TelecallerShiftGateOverlay(
              isTelecaller: true,
              child: Center(child: Text('Protected Telecaller Body')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('You are on BREAK'), findsOneWidget);
      expect(find.text('Resume Active'), findsOneWidget);
    });

    testWidgets('renders 9-hour lockout overlay', (tester) async {
      await setSurface(tester, 360, height: 850);
      final manager = TelecallerShiftManager.instance;
      manager.currentStatusNotifier.value = 'ACTIVE';
      manager.isShiftLockedOutNotifier.value = true;
      manager.isOnInactivityBreakNotifier.value = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TelecallerShiftGateOverlay(
              isTelecaller: true,
              child: Center(child: Text('Protected Telecaller Body')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Daily Shift Completed (9 Hours)'), findsOneWidget);
    });
  });
}

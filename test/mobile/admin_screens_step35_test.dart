import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/design_system/mobile/mobile.dart';
import 'package:propkart/core/design_system/tokens/app_spacing.dart';
import 'package:propkart/core/security/permission_matrix_service.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/core/theme/theme_manager.dart';
import 'package:propkart/features/auth/bloc/auth_bloc.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/users/bloc/users_bloc.dart';
import 'package:propkart/features/dashboard/bloc/dashboard_bloc.dart';
import 'package:propkart/features/dashboard/models/dashboard_summary.dart';
import 'package:propkart/features/dashboard/models/kpi_models.dart';
import 'package:propkart/features/dashboard/screens/dashboard_screen.dart';
import 'package:propkart/features/dashboard/widgets/stat_card.dart';
import 'package:propkart/features/requirements/bloc/requirements_bloc.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/requirements/screens/requirements_screen.dart';
import 'package:propkart/features/properties/bloc/properties_bloc.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/properties/screens/properties_screen.dart';
import 'package:propkart/features/reports/bloc/reports_bloc.dart';
import 'package:propkart/features/reports/bloc/reports_event.dart';
import 'package:propkart/features/reports/bloc/reports_state.dart';
import 'package:propkart/features/reports/models/report_configuration.dart';
import 'package:propkart/features/reports/models/report_data.dart';
import 'package:propkart/features/reports/screens/leads/overall_business_insight_screen.dart';
import 'package:propkart/features/reports/screens/leads/telecaller_report_screen.dart';
import 'package:propkart/features/shell/mobile/mobile_nav_config.dart';

import 'mobile_test_utils.dart';

// --- MOCKS ---

class MockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  MockAuthBloc({String role = 'Admin', String fullName = 'Test Admin'})
      : super(Authenticated(
          user: UserModel(
            id: 'test-admin-1',
            email: 'admin@propkart.test',
            fullName: fullName,
            role: role,
            permissions: const ['admin', 'requirements', 'properties', 'reports'],
          ),
        )) {
    on<AuthEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUsersBloc extends Bloc<UsersEvent, UsersState> implements UsersBloc {
  MockUsersBloc() : super(UsersInitial()) {
    on<UsersEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDashboardBloc extends Bloc<DashboardEvent, DashboardState> implements DashboardBloc {
  MockDashboardBloc([DashboardState? initialState])
      : super(initialState ??
            DashboardLoadedState(
              data: DashboardData(
                summary: const DashboardSummary(
                  totalProperties: 150,
                  available: 85,
                  sold: 35,
                  rented: 30,
                  requirements: 110,
                  users: 12,
                  rentalAvailable: 45,
                  resaleAvailable: 40,
                ),
                activity: const [],
                recentProperties: [
                  RecentProperty(
                    id: 'prop-1',
                    code: 'PK-101',
                    title: 'Bandra Sea View 3BHK',
                    area: 'Bandra West',
                    price: 85000,
                    status: 'Available',
                    areaName: 'Bandra West',
                    listingType: 'Rent',
                    createdBy: 'admin-1',
                    createdAt: DateTime.now().toIso8601String(),
                  ),
                ],
                checklist: const [],
                followups: const [],
                siteVisits: const [],
                inventoryLocations: const [],
              ),
              kpis: const DashboardKpisResponse(
                counts: DashboardKpiCounts(
                  availableInventory: 85,
                  totalLeads: 110,
                  telecallers: 5,
                  leadsAllocated: 24,
                  oldLeadsAllocated: 12,
                  assignedToSales: 18,
                  siteVisitsDone: 9,
                  dealWon: 7,
                  salesUsers: 6,
                ),
                config: [
                  KpiConfigItem(kpiKey: 'available_inventory', kpiLabel: 'Available Inventory', isEnabled: true, displayOrder: 1),
                  KpiConfigItem(kpiKey: 'total_leads', kpiLabel: 'Total Leads', isEnabled: true, displayOrder: 2),
                  KpiConfigItem(kpiKey: 'telecallers', kpiLabel: 'Telecallers', isEnabled: true, displayOrder: 3),
                  KpiConfigItem(kpiKey: 'leads_allocated', kpiLabel: 'New Leads Allocated', isEnabled: true, displayOrder: 4),
                  KpiConfigItem(kpiKey: 'old_leads_allocated', kpiLabel: 'Old Leads Allocated', isEnabled: true, displayOrder: 5),
                  KpiConfigItem(kpiKey: 'assigned_to_sales', kpiLabel: 'Assigned to Sales', isEnabled: true, displayOrder: 6),
                  KpiConfigItem(kpiKey: 'site_visits_done', kpiLabel: 'Site Visits Done', isEnabled: true, displayOrder: 7),
                  KpiConfigItem(kpiKey: 'deal_won', kpiLabel: 'Deal Won', isEnabled: true, displayOrder: 8),
                  KpiConfigItem(kpiKey: 'sales_users', kpiLabel: 'Sales Users', isEnabled: true, displayOrder: 9),
                ],
              ),
              kpiFilters: const KpiFilterParams(
                businessType: 'Rent',
                dateFilter: 'Weekly',
                leadType: 'Both',
              ),
              isKpiLoading: false,
            )) {
    on<DashboardEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockRequirementsBloc extends Bloc<RequirementsEvent, RequirementsState> implements RequirementsBloc {
  MockRequirementsBloc([RequirementsState? initialState])
      : super(initialState ??
            RequirementsLoaded(
              requirements: [
                RequirementModel(
                  id: 'req-1',
                  clientName: 'Alice Sharma',
                  clientMobile: '9876543210',
                  categoryId: 'cat-res',
                  categoryName: 'Residential',
                  propertyTypeId: 'pt-apt',
                  propertyTypeName: 'Apartment',
                  configurationName: '2 BHK',
                  listingTypeId: 'lt-rent',
                  listingTypeName: 'Rent',
                  minBudget: 25000,
                  maxBudget: 35000,
                  areaIds: const ['area-1'],
                  areaNames: const ['Bandra West'],
                  status: 'Active',
                  createdAt: DateTime.now(),
                  assignedTo: 'sales-1',
                  assigneeName: 'Test Sales',
                  createdBy: 'admin-1',
                  creatorName: 'Admin',
                ),
                RequirementModel(
                  id: 'req-2',
                  clientName: 'Bob Mehta',
                  clientMobile: '9876543211',
                  categoryId: 'cat-res',
                  categoryName: 'Residential',
                  propertyTypeId: 'pt-apt',
                  propertyTypeName: 'Apartment',
                  configurationName: '3 BHK',
                  listingTypeId: 'lt-resale',
                  listingTypeName: 'Re-Sale',
                  minBudget: 15000000,
                  maxBudget: 20000000,
                  areaIds: const ['area-2'],
                  areaNames: const ['Andheri West'],
                  status: 'Won',
                  createdAt: DateTime.now(),
                  assignedTo: 'sales-2',
                  assigneeName: 'Rohit Verma',
                  createdBy: 'admin-1',
                  creatorName: 'Admin',
                ),
              ],
            )) {
    on<RequirementsEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPropertiesBloc extends Bloc<PropertiesEvent, PropertiesState> implements PropertiesBloc {
  MockPropertiesBloc([PropertiesState? initialState])
      : super(initialState ??
            PropertiesLoaded(
              properties: [
                PropertyModel(
                  id: 'prop-1',
                  propertyCode: 'PROP-101',
                  title: 'Luxury 2BHK Apartment',
                  categoryId: 'cat-1',
                  categoryName: 'Residential',
                  propertyTypeId: 'pt-1',
                  propertyTypeName: 'Apartment',
                  listingTypeId: 'lt-rent',
                  listingTypeName: 'Rent',
                  propertyStatusId: 'ps-avail',
                  propertyStatusName: 'Available',
                  cityId: 'city-1',
                  cityName: 'Mumbai',
                  areaId: 'area-1',
                  areaName: 'Powai',
                  pincode: '400076',
                  address: 'Hiranandani Gardens',
                  price: 55000,
                  deposit: 150000,
                  maintenance: 3000,
                  bedrooms: 2,
                  bathrooms: 2,
                  balconies: 1,
                  parking: 1,
                  ownerName: 'Sunil Rao',
                  ownerMobile: '9988776655',
                  isVerified: true,
                  createdBy: 'admin-1',
                  createdByName: 'Admin',
                  createdAt: DateTime.now(),
                  images: const [],
                  amenities: const [],
                  videos: const [],
                ),
              ],
              metadata: PropertyMetadataModel(
                cities: const [],
                areas: const [],
                categories: const [],
                types: const [],
                configurations: const [],
                listingTypes: const [],
                statuses: const [],
                furnishings: const [],
                facings: const [],
                ownerships: const [],
                brokerages: const [],
                amenities: const [],
              ),
              bookmarkedIds: const {},
              activeTab: 'All',
            )) {
    on<PropertiesEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockReportsBloc extends Bloc<ReportsEvent, ReportsState> implements ReportsBloc {
  MockReportsBloc([ReportsState? initialState])
      : super(initialState ??
            ReportsLoaded(
              config: ReportConfiguration.initial(),
              data: const ReportOverallData(
                kpiValues: {},
                pipelineStages: [],
                funnelStages: [],
                followupCategories: [],
                telecallerRankings: [],
                salesRankings: [],
                insights: [],
                growthComparisonItems: [],
                leadSources: [],
                trendPoints: [],
                filteredLeads: [],
                availableStatuses: [],
                availableSources: [],
                availableTelecallers: [],
                availableSalesUsers: [],
                availableProperties: [],
              ),
            )) {
    on<ReportsEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget wrapWithRouter(
  Widget child, {
  String initialLocation = '/',
  double textScale = 1.0,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/requirements',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/properties',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => child,
      ),
      GoRoute(
        path: '/reports/leads/overall-business-insight',
        builder: (context, state) => child,
      ),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    builder: (context, routerChild) {
      Widget content = Material(child: routerChild!);
      if (textScale != 1.0) {
        content = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: content,
        );
      }
      return content;
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PermissionMatrixService.instance.resetToDefaults();
    RoleGuard.currentUser = const UserModel(
      id: 'test-admin-1',
      email: 'admin@propkart.test',
      fullName: 'Test Admin',
      role: 'Admin',
      permissions: ['admin', 'requirements', 'properties', 'reports'],
    );
    ThemeManager().setRentMode(true);
  });

  // =========================================================================
  // GROUP 1: Admin DashboardScreen Mobile Adaptation (/dashboard)
  // =========================================================================
  group('Admin DashboardScreen Mobile Adaptation', () {
    for (final width in [320.0, 360.0, 390.0, 412.0, 430.0, 480.0, 600.0, 767.0]) {
      testMobile('renders mobile layout and MobileScreenScaffold at width $width', (tester) async {
        await setSurface(tester, width);

        await tester.pumpWidget(
          wrapWithRouter(
            MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
                BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
                BlocProvider<DashboardBloc>.value(value: MockDashboardBloc()),
                BlocProvider<RequirementsBloc>.value(value: MockRequirementsBloc()),
              ],
              child: const DashboardScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // In mobile (< 768px), MobileScreenScaffold is used
        expect(find.byType(MobileScreenScaffold), findsOneWidget);

        // Header greeting
        expect(find.textContaining('Test Admin'), findsWidgets);

        // Global filter bar: Business filter pills
        expect(find.text('Rent'), findsWidgets);
        expect(find.text('Re-sale'), findsWidgets);
        expect(find.text('Both'), findsWidgets);

        // Date filter pills
        expect(find.text('Today'), findsWidgets);
        expect(find.text('Weekly'), findsWidgets);
        expect(find.text('Monthly'), findsWidgets);

        // Authoritative Admin KPI cards verified
        expect(find.text('Available Inventory'), findsOneWidget);
        expect(find.text('Total Leads'), findsOneWidget);
        expect(find.text('Telecallers'), findsOneWidget);
        expect(find.text('New Leads Allocated'), findsOneWidget);
        expect(find.text('Old Leads Allocated'), findsOneWidget);
        expect(find.text('Assigned to Sales'), findsOneWidget);
        expect(find.text('Site Visits Done'), findsOneWidget);
        expect(find.text('Deal Won'), findsOneWidget);
        expect(find.text('Sales Users'), findsOneWidget);

        // Verify values
        expect(find.text('85'), findsWidgets); // Available Inventory
        expect(find.text('110'), findsWidgets); // Total Leads
        expect(find.text('24'), findsWidgets); // New Leads Allocated
        expect(find.text('12'), findsWidgets); // Old Leads Allocated
        expect(find.text('18'), findsWidgets); // Assigned to Sales
        expect(find.text('9'), findsWidgets); // Site Visits Done
        expect(find.text('7'), findsWidgets); // Deal Won
        expect(find.text('6'), findsWidgets); // Sales Users

        // No uncaught overflow exception
        expect(tester.takeException(), isNull);
      });
    }

    testMobile('preserves desktop layout at >= 768px (no MobileScreenScaffold)', (tester) async {
      await setSurface(tester, 1024);

      await tester.pumpWidget(
        wrapWithRouter(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
              BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
              BlocProvider<DashboardBloc>.value(value: MockDashboardBloc()),
              BlocProvider<RequirementsBloc>.value(value: MockRequirementsBloc()),
            ],
            child: const DashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Desktop does NOT use MobileScreenScaffold
      expect(find.byType(MobileScreenScaffold), findsNothing);
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testMobile('renders cleanly under textScale 1.3 without overflow', (tester) async {
      await setSurface(tester, 360);

      await tester.pumpWidget(
        wrapWithRouter(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
              BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
              BlocProvider<DashboardBloc>.value(value: MockDashboardBloc()),
              BlocProvider<RequirementsBloc>.value(value: MockRequirementsBloc()),
            ],
            child: const DashboardScreen(),
          ),
          textScale: 1.3,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(MobileScreenScaffold), findsOneWidget);
    });

    testMobile('KPI cards meet minimum touch target height and accessibility semantics', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        wrapWithRouter(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
              BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
              BlocProvider<DashboardBloc>.value(value: MockDashboardBloc()),
              BlocProvider<RequirementsBloc>.value(value: MockRequirementsBloc()),
            ],
            child: const DashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final kpiFinder = find.text('Total Leads');
      final cardWidget = find.ancestor(of: kpiFinder, matching: find.byType(StatCard)).first;
      final size = tester.getSize(cardWidget);
      expect(size.height, greaterThanOrEqualTo(48.0));
      expect(size.width, greaterThanOrEqualTo(48.0));

      // Semantics verify
      final semanticsFinder = find.descendant(of: cardWidget, matching: find.byType(Semantics)).first;
      expect(semanticsFinder, findsOneWidget);
    });
  });

  // =========================================================================
  // GROUP 2: RequirementsScreen (Admin Leads) Mobile Adaptation
  // =========================================================================
  group('RequirementsScreen Admin Leads Mobile Adaptation', () {
    for (final width in [360.0, 390.0, 767.0]) {
      testMobile('renders MobileScreenScaffold with Admin attribution at width $width', (tester) async {
        await setSurface(tester, width);

        await tester.pumpWidget(
          wrapWithRouter(
            MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
                BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
                BlocProvider<RequirementsBloc>.value(value: MockRequirementsBloc()),
              ],
              child: const RequirementsScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(MobileScreenScaffold), findsOneWidget);

        // Admin tab: 'Won' tab is visible (not 'My Won')
        expect(find.text('Won'), findsWidgets);
        expect(find.text('My Won'), findsNothing);

        // Admin lead cards show 'Added by: ... • Assigned: ...'
        expect(find.textContaining('Added by: Admin • Assigned: Test Sales'), findsOneWidget);
      });
    }

    testMobile('preserves desktop layout at >= 768px for Admin leads', (tester) async {
      await setSurface(tester, 1024);

      await tester.pumpWidget(
        wrapWithRouter(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
              BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
              BlocProvider<RequirementsBloc>.value(value: MockRequirementsBloc()),
            ],
            child: const RequirementsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsNothing);
    });
  });

  // =========================================================================
  // GROUP 3: PropertiesScreen (Admin Properties) Mobile Adaptation
  // =========================================================================
  group('PropertiesScreen Admin Properties Mobile Adaptation', () {
    for (final width in [360.0, 390.0, 767.0]) {
      testMobile('renders MobileScreenScaffold with property cards at width $width', (tester) async {
        await setSurface(tester, width);

        await tester.pumpWidget(
          wrapWithRouter(
            MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
                BlocProvider<PropertiesBloc>.value(value: MockPropertiesBloc()),
              ],
              child: const PropertiesScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(MobileScreenScaffold), findsOneWidget);
        expect(find.text('Luxury 2BHK Apartment'), findsOneWidget);
      });
    }

    testMobile('preserves desktop layout at >= 768px for Admin properties', (tester) async {
      await setSurface(tester, 1024);

      await tester.pumpWidget(
        wrapWithRouter(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
              BlocProvider<PropertiesBloc>.value(value: MockPropertiesBloc()),
            ],
            child: const PropertiesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsNothing);
    });
  });

  // =========================================================================
  // GROUP 4: Admin Reports Screens & K1 Clearance
  // =========================================================================
  group('Admin Reports Mobile Adaptation & K1 Shell Clearance', () {
    testMobile('OverallBusinessInsightScreen inside MobileShellScope uses CRMSpacing.m bottom padding (K1 compliant)', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        wrapWithRouter(
          BlocProvider<ReportsBloc>.value(
            value: MockReportsBloc(),
            child: const MobileShellScope(
              child: OverallBusinessInsightScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);

      final scrollFinder = find.byType(SingleChildScrollView).first;
      expect(scrollFinder, findsOneWidget);
      final scrollWidget = tester.widget<SingleChildScrollView>(scrollFinder);
      final padding = scrollWidget.padding as EdgeInsets;
      // In shell, bottom padding must be CRMSpacing.m, NOT 96!
      expect(padding.bottom, equals(CRMSpacing.m));
    });

    testMobile('OverallBusinessInsightScreen outside shell on mobile uses 96 bottom padding', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        wrapWithRouter(
          BlocProvider<ReportsBloc>.value(
            value: MockReportsBloc(),
            child: const OverallBusinessInsightScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final scrollFinder = find.byType(SingleChildScrollView).first;
      expect(scrollFinder, findsOneWidget);
      final scrollWidget = tester.widget<SingleChildScrollView>(scrollFinder);
      final padding = scrollWidget.padding as EdgeInsets;
      expect(padding.bottom, equals(96));
    });

    testMobile('TelecallerReportScreen inside MobileShellScope uses CRMSpacing.m bottom padding (K1 compliant)', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        wrapWithRouter(
          BlocProvider<ReportsBloc>.value(
            value: MockReportsBloc(),
            child: const MobileShellScope(
              child: TelecallerReportScreen(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);

      final scrollFinder = find.byType(SingleChildScrollView).first;
      expect(scrollFinder, findsOneWidget);
      final scrollWidget = tester.widget<SingleChildScrollView>(scrollFinder);
      final padding = scrollWidget.padding as EdgeInsets;
      // In shell, bottom padding must be CRMSpacing.m, NOT 96!
      expect(padding.bottom, equals(CRMSpacing.m));
    });

    testMobile('OverallBusinessInsightScreen preserves desktop layout at >= 768px', (tester) async {
      await setSurface(tester, 1024);

      await tester.pumpWidget(
        wrapWithRouter(
          BlocProvider<ReportsBloc>.value(
            value: MockReportsBloc(),
            child: const OverallBusinessInsightScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final scrollFinder = find.byType(SingleChildScrollView).first;
      expect(scrollFinder, findsOneWidget);
      final scrollWidget = tester.widget<SingleChildScrollView>(scrollFinder);
      final padding = scrollWidget.padding as EdgeInsets;
      expect(padding.bottom, equals(CRMSpacing.m));
    });
  });

  // =========================================================================
  // GROUP 5: MobileNavConfig Admin Destinations & Role Boundaries
  // =========================================================================
  group('MobileNavConfig Admin Navigation & Role Isolation', () {
    test('Admin bottom navigation has exactly 5 authorized tabs', () {
      final tabs = MobileNavConfig.tabsForRole('Admin');
      expect(tabs.length, equals(5));
      expect(tabs[0].label, equals('Home'));
      expect(tabs[1].label, equals('Leads'));
      expect(tabs[2].label, equals('Properties'));
      expect(tabs[3].label, equals('Reports'));
      expect(tabs[4].label, equals('More'));
    });

    test('Admin More sections contain Operations, Team, Workspace, and Account', () {
      final sections = MobileNavConfig.moreForRole('Admin');
      final titles = sections.map((s) => s.title).toList();
      expect(titles, containsAll(['Operations', 'Team', 'Workspace', 'Account']));

      // Operations contains Lead allocation
      final ops = sections.firstWhere((s) => s.title == 'Operations');
      expect(ops.entries.any((e) => e.label == 'Lead allocation'), isTrue);

      // Workspace contains Settings and Library (Audit logs is Super Admin only)
      final ws = sections.firstWhere((s) => s.title == 'Workspace');
      expect(ws.entries.any((e) => e.label == 'Settings'), isTrue);
      expect(ws.entries.any((e) => e.label == 'Library'), isTrue);
      expect(ws.entries.any((e) => e.label == 'Audit logs'), isFalse);

      // Admin does NOT have Super admin metrics
      final team = sections.firstWhere((s) => s.title == 'Team');
      expect(team.entries.any((e) => e.label == 'Super admin metrics'), isFalse);
    });

    test('Super Admin sees Super admin metrics and Audit logs in More', () {
      final sections = MobileNavConfig.moreForRole('Super Admin');
      final team = sections.firstWhere((s) => s.title == 'Team');
      expect(team.entries.any((e) => e.label == 'Super admin metrics'), isTrue);
      final ws = sections.firstWhere((s) => s.title == 'Workspace');
      expect(ws.entries.any((e) => e.label == 'Audit logs'), isTrue);
    });

    test('Sales role CANNOT access Admin bottom tabs or Admin More entries', () {
      final salesTabs = MobileNavConfig.tabsForRole('Sales');
      expect(salesTabs.any((t) => t.label == 'Reports'), isFalse);

      final salesSections = MobileNavConfig.moreForRole('Sales');
      final allEntries = salesSections.expand((s) => s.entries).toList();
      expect(allEntries.any((e) => e.label == 'Lead allocation'), isFalse);
      expect(allEntries.any((e) => e.label == 'Audit logs'), isFalse);
      expect(allEntries.any((e) => e.label == 'Employees'), isFalse);
    });
  });
}

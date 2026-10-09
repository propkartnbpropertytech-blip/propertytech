import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/design_system/mobile/mobile.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/core/theme/theme_manager.dart';
import 'package:propkart/features/auth/bloc/auth_bloc.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/users/bloc/users_bloc.dart';
import 'package:propkart/features/sales/bloc/sales_dashboard_bloc.dart';
import 'package:propkart/features/sales/screens/sales_dashboard_screen.dart';
import 'package:propkart/features/requirements/bloc/requirements_bloc.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/requirements/screens/requirements_screen.dart';
import 'package:propkart/features/properties/bloc/properties_bloc.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/properties/screens/properties_screen.dart';

import 'mobile_test_utils.dart';

// --- MOCKS ---

class MockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  MockAuthBloc()
      : super(const Authenticated(
          user: UserModel(
            id: 'test-sales-1',
            email: 'sales@propkart.test',
            fullName: 'Test Sales',
            role: 'Sales',
            permissions: ['sales', 'requirements', 'properties'],
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

class MockSalesDashboardBloc extends Bloc<SalesDashboardEvent, SalesDashboardState> implements SalesDashboardBloc {
  MockSalesDashboardBloc([SalesDashboardState? initialState])
      : super(initialState ??
            SalesDashboardState(
              loading: false,
              data: {
                'availableInventory': 142,
                'siteVisitDone': 18,
                'activeLeads': 45,
                'dealsWon': 12,
                'assignedLeads': 60,
                'newLeads': 9,
                'followupsDue': 7,
                'activeFollowups': 24,
                'recentLeads': [
                  {
                    'id': 'lead-1',
                    'client_name': 'Rahul Verma',
                    'client_phone': '9811122233',
                    'status': 'Active',
                    'listing_type': 'Rent',
                    'configuration': '2 BHK',
                    'budget_min': 30000,
                    'budget_max': 40000,
                    'preferred_locations': ['Andheri West'],
                  }
                ],
                'recentProperties': [
                  {
                    'id': 'prop-1',
                    'title': 'Green Heights 2BHK',
                    'property_code': 'GH-201',
                    'listing_type': 'Rent',
                    'price': 45000,
                    'location': 'Andheri West',
                    'bhk': '2 BHK',
                  }
                ],
                'personalNotes': [
                  {
                    'id': 'note-1',
                    'content': 'Call Mr. Sharma regarding token amount',
                    'created_at': DateTime.now().toIso8601String(),
                  }
                ],
              },
            )) {
    on<SalesDashboardEvent>((event, emit) {});
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
                  assignedTo: 'test-sales-1',
                  assigneeName: 'Test Sales',
                  createdBy: 'admin-user',
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
                  status: 'Follow-up',
                  createdAt: DateTime.now(),
                  assignedTo: 'test-sales-1',
                  assigneeName: 'Test Sales',
                  createdBy: 'other-user',
                  creatorName: 'Other Agent',
                ),
                RequirementModel(
                  id: 'req-unpermitted',
                  clientName: 'Secret Client',
                  clientMobile: '9876543299',
                  categoryId: 'cat-res',
                  categoryName: 'Residential',
                  propertyTypeId: 'pt-apt',
                  propertyTypeName: 'Apartment',
                  configurationName: '4 BHK',
                  listingTypeId: 'lt-rent',
                  listingTypeName: 'Rent',
                  minBudget: 80000,
                  maxBudget: 120000,
                  areaIds: const ['area-3'],
                  areaNames: const ['Juhu'],
                  status: 'Active',
                  createdAt: DateTime.now(),
                  assignedTo: 'other-sales-agent',
                  assigneeName: 'Other Sales',
                  createdBy: 'other-sales-agent',
                  creatorName: 'Other Sales',
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
                  createdBy: 'test-sales-1',
                  createdByName: 'Test Sales',
                  createdAt: DateTime.now(),
                  images: const [],
                  amenities: const [],
                  videos: const [],
                ),
                PropertyModel(
                  id: 'prop-2',
                  propertyCode: 'PROP-102',
                  title: 'Commercial Office Space',
                  categoryId: 'cat-2',
                  categoryName: 'Commercial',
                  propertyTypeId: 'pt-2',
                  propertyTypeName: 'Commercial Office',
                  listingTypeId: 'lt-resale',
                  listingTypeName: 'Re-Sale',
                  propertyStatusId: 'ps-avail',
                  propertyStatusName: 'Available',
                  cityId: 'city-1',
                  cityName: 'Mumbai',
                  areaId: 'area-2',
                  areaName: 'BKC',
                  pincode: '400051',
                  address: 'G-Block, BKC',
                  price: 25000000,
                  deposit: 0,
                  maintenance: 15000,
                  bedrooms: 0,
                  bathrooms: 2,
                  balconies: 0,
                  parking: 2,
                  ownerName: 'Apex Corp',
                  ownerMobile: '9988776644',
                  isVerified: false,
                  createdBy: 'test-sales-1',
                  createdByName: 'Test Sales',
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
              bookmarkedIds: const {'prop-1'},
              activeTab: 'All',
            )) {
    on<PropertiesEvent>((event, emit) {});
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
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    builder: (context, routerChild) {
      if (textScale != 1.0) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: routerChild!,
        );
      }
      return routerChild!;
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    RoleGuard.currentUser = const UserModel(
      id: 'test-sales-1',
      email: 'sales@propkart.test',
      fullName: 'Test Sales',
      role: 'Sales',
      permissions: ['sales', 'requirements', 'properties'],
    );
    ThemeManager().setRentMode(true);
  });

  // =========================================================================
  // GROUP 1: SalesDashboardScreen Mobile Adaptation
  // =========================================================================
  group('SalesDashboardScreen Mobile Adaptation', () {
    for (final width in [320.0, 360.0, 390.0, 412.0, 430.0, 480.0, 600.0, 767.0]) {
      testMobile('renders mobile layout and MobileScreenScaffold at width $width', (tester) async {
        await setSurface(tester, width);

        await tester.pumpWidget(
          wrapWithRouter(
            SalesDashboardScreen(bloc: MockSalesDashboardBloc()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // In mobile (< 768px), MobileScreenScaffold is used
        expect(find.byType(MobileScreenScaffold), findsOneWidget);

        // Header greeting
        expect(find.textContaining('Test Sales'), findsWidgets);

        // Rent / Re-Sale toggle switch exists
        expect(find.text('Rent'), findsWidgets);
        expect(find.text('Re-Sale'), findsWidgets);

        // 8 KPI cards verified
        expect(find.text('Available Inventory'), findsOneWidget);
        expect(find.text('Site Visit Done'), findsOneWidget);
        expect(find.text('Active Leads'), findsOneWidget);
        expect(find.text('Deals Won'), findsOneWidget);
        expect(find.text('Assigned Leads'), findsOneWidget);
        expect(find.text('New Leads'), findsOneWidget);
        expect(find.text('Follow-ups Due'), findsOneWidget);
        expect(find.text('Active Follow-ups'), findsOneWidget);
      });
    }

    testMobile('preserves desktop layout at >= 768px (no MobileScreenScaffold)', (tester) async {
      await setSurface(tester, 1024);

      await tester.pumpWidget(
        wrapWithRouter(
          SalesDashboardScreen(bloc: MockSalesDashboardBloc()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Desktop does NOT use MobileScreenScaffold
      expect(find.byType(MobileScreenScaffold), findsNothing);
    });

    testMobile('renders cleanly under textScale 1.3 without overflow', (tester) async {
      await setSurface(tester, 360);

      await tester.pumpWidget(
        wrapWithRouter(
          SalesDashboardScreen(bloc: MockSalesDashboardBloc()),
          textScale: 1.3,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(MobileScreenScaffold), findsOneWidget);
    });

    testMobile('KPI cards meet minimum touch target height of 48px', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        wrapWithRouter(
          SalesDashboardScreen(bloc: MockSalesDashboardBloc()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final kpiFinder = find.text('Active Leads');
      final cardWidget = find.ancestor(of: kpiFinder, matching: find.byType(InkWell)).first;
      final size = tester.getSize(cardWidget);
      expect(size.height, greaterThanOrEqualTo(48.0));
      expect(size.width, greaterThanOrEqualTo(48.0));
    });
  });

  // =========================================================================
  // GROUP 2: RequirementsScreen (Sales Leads) Mobile Adaptation
  // =========================================================================
  group('RequirementsScreen Sales Leads Mobile Adaptation', () {
    for (final width in [360.0, 390.0, 767.0]) {
      testMobile('renders MobileScreenScaffold with sales lead chips at width $width', (tester) async {
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
        await tester.pump(const Duration(milliseconds: 200));

        // MobileScreenScaffold is used
        expect(find.byType(MobileScreenScaffold), findsOneWidget);

        // Mode toggle and Add Lead button
        expect(find.text('Rent'), findsWidgets);
        expect(find.text('Re-Sale'), findsWidgets);
        expect(find.text('Add Lead'), findsOneWidget);

        // Main section tabs
        expect(find.text('Leads'), findsWidgets);
        expect(find.text('Follow-ups'), findsWidgets);
        expect(find.textContaining('Won'), findsWidgets);
        expect(find.text('Rejected'), findsWidgets);

        // Sales lead group selector chips
        expect(find.textContaining('Assigned to Me'), findsOneWidget);
        expect(find.textContaining('Added by Me'), findsOneWidget);
        expect(find.byWidgetPredicate((w) => w is Text && (w.data?.contains('My Active Leads') == true || w.data?.contains('My Active Deals') == true)), findsOneWidget);
      });
    }

    testMobile('strictly enforces sales scoping - unpermitted leads never displayed', (tester) async {
      await setSurface(tester, 390);

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
      await tester.pump(const Duration(milliseconds: 200));

      // Permitted lead assigned to test-sales-1 is displayed
      expect(find.text('Alice Sharma'), findsOneWidget);

      // Unpermitted lead belonging to other-sales-agent is NEVER displayed
      expect(find.text('Secret Client'), findsNothing);
    });

    testMobile('desktop view preserved at 1024px', (tester) async {
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

      // Desktop does NOT use MobileScreenScaffold
      expect(find.byType(MobileScreenScaffold), findsNothing);
    });
  });

  // =========================================================================
  // GROUP 3: PropertiesScreen (Sales Properties) Mobile Adaptation
  // =========================================================================
  group('PropertiesScreen Sales Properties Mobile Adaptation', () {
    for (final width in [360.0, 390.0, 767.0]) {
      testMobile('renders MobileScreenScaffold with property filters at width $width', (tester) async {
        await setSurface(tester, width);

        await tester.pumpWidget(
          wrapWithRouter(
            MultiBlocProvider(
              providers: [
                BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
                BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
                BlocProvider<PropertiesBloc>.value(value: MockPropertiesBloc()),
              ],
              child: const PropertiesScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // MobileScreenScaffold is used
        expect(find.byType(MobileScreenScaffold), findsOneWidget);

        // Rent / Re-Sale toggle and Add Property button
        expect(find.text('Rent'), findsWidgets);
        expect(find.text('Re-Sale'), findsWidgets);
        expect(find.text('Add Property'), findsOneWidget);

        // Category filter chips
        expect(find.text('Residential'), findsWidgets);
        expect(find.text('Commercial'), findsWidgets);
        expect(find.text('Industrial'), findsWidgets);
        expect(find.text('Land & Plot'), findsWidgets);
      });
    }

    testMobile('renders property card with correct details', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        wrapWithRouter(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
              BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
              BlocProvider<PropertiesBloc>.value(value: MockPropertiesBloc()),
            ],
            child: const PropertiesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Property card with code and location
      expect(find.text('PROP-101'), findsOneWidget);
      expect(find.textContaining('Powai'), findsWidgets);
    });

    testMobile('desktop view preserved at 1024px', (tester) async {
      await setSurface(tester, 1024);

      await tester.pumpWidget(
        wrapWithRouter(
          MultiBlocProvider(
            providers: [
              BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
              BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
              BlocProvider<PropertiesBloc>.value(value: MockPropertiesBloc()),
            ],
            child: const PropertiesScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Desktop does NOT use MobileScreenScaffold
      expect(find.byType(MobileScreenScaffold), findsNothing);
    });
  });
}

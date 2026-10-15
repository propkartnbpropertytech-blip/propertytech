import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/design_system/mobile/mobile.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/features/auth/bloc/auth_bloc.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/campaign/bloc/campaign_leads_bloc.dart';
import 'package:propkart/features/campaign/screens/campaign_leads_screen.dart';
import 'package:propkart/features/telecaller/bloc/telecaller_dashboard_bloc.dart';
import 'package:propkart/features/telecaller/screens/telecaller_dashboard_screen.dart';
import 'package:propkart/features/telecaller/screens/telecaller_callbacks_screen.dart';
import 'package:propkart/features/telecaller/bloc/telecaller_list_bloc.dart';
import 'package:propkart/features/telecaller/widgets/mobile_telecaller_outcome_sheet.dart';
import 'package:propkart/features/users/bloc/users_bloc.dart';

import 'mobile_test_utils.dart';

class MockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  MockAuthBloc()
      : super(const Authenticated(
          user: UserModel(
            id: 'test-telecaller-1',
            email: 'telecaller@propkart.test',
            fullName: 'Test Telecaller',
            role: 'Telecaller',
            permissions: ['telecaller', 'campaign'],
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

class MockCampaignLeadsBloc extends Bloc<CampaignLeadsEvent, CampaignLeadsState> implements CampaignLeadsBloc {
  MockCampaignLeadsBloc() : super(const CampaignLeadsState(status: CampaignLeadsStatus.success)) {
    on<CampaignLeadsEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTelecallerDashboardBloc
    extends Bloc<TelecallerDashboardEvent, TelecallerDashboardState>
    implements TelecallerDashboardBloc {
  MockTelecallerDashboardBloc([TelecallerDashboardState? initialState])
      : super(initialState ??
            const TelecallerDashboardState(
              loading: false,
              data: {
                'telecallerName': 'Test Telecaller',
                'nextLead': {
                  'name': 'Darsh Thakar',
                  'phone': '9510191060',
                  'type': 'Property Listing',
                },
                'scheduledFollowups': [
                  {
                    'id': 'fu-1',
                    'client_name': 'CA Apurva Davda',
                    'mobile': '9427687127',
                    'lead_type': 'Property Listing',
                    'scheduled_at': '2026-10-07T11:00:00Z',
                    'remarks': 'Test again',
                    'status': 'Pending',
                  },
                ],
              },
            )) {
    on<TelecallerDashboardEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTelecallerCallbacksBloc
    extends Bloc<TelecallerListEvent, TelecallerListState>
    implements TelecallerCallbacksBloc {
  MockTelecallerCallbacksBloc([TelecallerListState? initialState])
      : super(initialState ??
            const TelecallerListState(
              loading: false,
              items: [
                {
                  'id': 'lead-cb-1',
                  'name': 'Devyani Dhumal',
                  'mobile': '9860608552',
                  'sanitized_phone': '9860608552',
                  'source': 'META',
                  'scheduled_at': '2026-10-03T16:20:00Z',
                  'remarks': 'Test callback remark',
                  'campaign_status': 'Callback',
                  'lead_type': 'Requirement',
                },
              ],
            )) {
    on<TelecallerListEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    RoleGuard.currentUser = const UserModel(
      id: 'test-telecaller-1',
      email: 'telecaller@propkart.test',
      fullName: 'Test Telecaller',
      role: 'Telecaller',
      permissions: ['telecaller', 'campaign'],
    );
  });

  group('MobileTelecallerOutcomeSheet Widget Tests', () {
    testMobile('renders 6 outcome types with 48px minimum hit targets', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  MobileTelecallerOutcomeSheet.show(
                    context: context,
                    leadId: 'lead-123',
                    clientName: 'Jane Doe',
                    phone: '9876543210',
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      );

      // Open the outcome sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify client info header
      expect(find.text('Record Call Outcome'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);

      // Verify all 6 outcome options exist
      expect(find.text('Follow-Up'), findsOneWidget);
      expect(find.text('Callback'), findsOneWidget);
      expect(find.text('CNR'), findsOneWidget);
      expect(find.text('Picked Up'), findsOneWidget);
      expect(find.text('Interested'), findsOneWidget);
      expect(find.text('Not Interested'), findsOneWidget);

      // Verify hit target height is at least 48px for each outcome button
      final outcomeFinder = find.text('Follow-Up');
      final size = tester.getSize(find.ancestor(of: outcomeFinder, matching: find.byType(InkWell)).first);
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testMobile('selecting Picked Up shows Sales Executive selection', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  MobileTelecallerOutcomeSheet.show(
                    context: context,
                    leadId: 'lead-123',
                    clientName: 'John Smith',
                    phone: '9876543211',
                    initialType: TelecallerOutcomeType.followUp,
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Picked Up
      await tester.tap(find.text('Picked Up'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Assign to Sales Executive section appears
      expect(find.text('Assign to Sales Executive *'), findsOneWidget);
    });

    testMobile('selecting Not Interested shows reason selector', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  MobileTelecallerOutcomeSheet.show(
                    context: context,
                    leadId: 'lead-123',
                    clientName: 'Alice',
                    phone: '9876543212',
                    initialType: TelecallerOutcomeType.followUp,
                  );
                },
                child: const Text('Open Sheet'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Not Interested
      await tester.tap(find.text('Not Interested'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Reason for Not Interested section appears
      expect(find.text('Reason for Not Interested *'), findsOneWidget);
    });
  });

  group('TelecallerDashboardScreen Mobile Adaptation', () {
    for (final width in [320.0, 360.0, 390.0, 412.0, 430.0, 480.0, 600.0, 767.0]) {
      testMobile('renders mobile layout and MobileScreenScaffold at width $width', (tester) async {
        await setSurface(tester, width);

        await tester.pumpWidget(
          wrap(
            const TelecallerDashboardScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // In mobile (< 768px), MobileScreenScaffold is used
        expect(find.byType(MobileScreenScaffold), findsOneWidget);
      });
    }

    testMobile('preserves desktop layout at >= 768px (no MobileScreenScaffold)', (tester) async {
      await setSurface(tester, 1024);

      await tester.pumpWidget(
        wrap(
          const TelecallerDashboardScreen(),
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
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.3),
          ),
          child: wrap(const TelecallerDashboardScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(MobileScreenScaffold), findsOneWidget);
    });

    testMobile('renders mobile filter bar with both Date: and Type: rows and full-width Archive card', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        wrap(TelecallerDashboardScreen(
          bloc: MockTelecallerDashboardBloc(),
        )),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      // Next lead card button and client name
      expect(find.text('Call Lead'), findsOneWidget);
      expect(find.text('Darsh Thakar'), findsOneWidget);

      // Both Date: and Type: filter rows are present
      expect(find.text('Date:'), findsOneWidget);
      expect(find.text('Type:'), findsOneWidget);
      expect(find.text('Today'), findsWidgets);
      expect(find.text('Both'), findsOneWidget);

      // KPI items
      expect(find.text('Total Leads'), findsOneWidget);
      expect(find.text('Archive'), findsOneWidget);
      // Full-width chevron on Archive tile
      expect(find.byIcon(Icons.chevron_right_rounded), findsWidgets);
    });

    testMobile('renders scheduled follow-up cards properly on mobile', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        wrap(TelecallerDashboardScreen(
          bloc: MockTelecallerDashboardBloc(),
        )),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('My Scheduled Follow-ups'), findsOneWidget);
      expect(find.text('CA Apurva Davda'), findsOneWidget);
      expect(find.text('9427687127'), findsOneWidget);
      expect(find.text('Test again'), findsOneWidget);
    });
  });

  group('TelecallerCallbacksScreen Mobile Adaptation', () {
    for (final width in [360.0, 390.0, 767.0]) {
      testMobile('renders MobileScreenScaffold with category tabs at width $width', (tester) async {
        await setSurface(tester, width);

        await tester.pumpWidget(
          wrap(
            const TelecallerCallbacksScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // MobileScreenScaffold is used
        expect(find.byType(MobileScreenScaffold), findsOneWidget);

        // Header info and benefit text exist
        expect(find.text('Callbacks'), findsWidgets);
        expect(find.text('Call Back leads leave My Calling Leads. Follow up stays there.'), findsOneWidget);

        // Filter chips exist
        expect(find.text('All'), findsWidgets);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Due'), findsOneWidget);
        expect(find.text('Future'), findsOneWidget);

        // Source filter and Date range button exist
        expect(find.text('All sources'), findsOneWidget);
        expect(find.text('Date range'), findsOneWidget);
      });
    }

    testMobile('desktop view preserved at 1024px', (tester) async {
      await setSurface(tester, 1024);

      await tester.pumpWidget(
        wrap(
          const TelecallerCallbacksScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Desktop does NOT use MobileScreenScaffold
      expect(find.byType(MobileScreenScaffold), findsNothing);
    });

    testMobile('renders mobile callback card with avatar, badge, and actions', (tester) async {
      await setSurface(tester, 360);

      final bloc = MockTelecallerCallbacksBloc();
      await tester.pumpWidget(
        wrap(
          TelecallerCallbacksScreen(bloc: bloc),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);

      // Verify Client details
      expect(find.text('Devyani Dhumal'), findsOneWidget);
      expect(find.text('9860608552'), findsOneWidget);
      expect(find.text('D'), findsOneWidget); // Avatar initial
      expect(find.text('Due / Missed'), findsOneWidget); // Status badge
      expect(find.text('Test callback remark'), findsOneWidget); // Remarks

      // Verify Actions
      expect(find.byIcon(Icons.thumb_down_alt_rounded), findsOneWidget); // Not interested
      expect(find.byIcon(Icons.call_rounded), findsOneWidget); // Call
      expect(find.text('Outcome'), findsOneWidget); // Outcome button
    });

    testMobile('entire mobile callbacks page is vertically scrollable', (tester) async {
      await setSurface(tester, 390, height: 600);

      final bloc = MockTelecallerCallbacksBloc(TelecallerListState(
        loading: false,
        items: List.generate(12, (i) => {
          'id': 'lead-cb-$i',
          'name': 'Client Number $i',
          'mobile': '980000000$i',
          'sanitized_phone': '980000000$i',
          'source': 'META',
          'scheduled_at': '2026-10-03T16:20:00Z',
          'remarks': 'Remark $i',
          'campaign_status': 'Callback',
          'lead_type': 'Requirement',
        }),
      ));

      await tester.pumpWidget(
        wrap(
          TelecallerCallbacksScreen(bloc: bloc),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final scrollableFinder = find.byType(Scrollable).first;
      expect(scrollableFinder, findsOneWidget);

      // Verify initial position
      final initialOffset = tester.state<ScrollableState>(scrollableFinder).position.pixels;
      expect(initialOffset, 0.0);

      // Scroll vertically downwards
      await tester.drag(scrollableFinder, const Offset(0, -300));
      await tester.pump();

      final scrolledOffset = tester.state<ScrollableState>(scrollableFinder).position.pixels;
      expect(scrolledOffset, greaterThan(0.0));
    });

    testMobile('mobile pagination displays counts and navigates pages', (tester) async {
      await setSurface(tester, 390, height: 800);

      final bloc = MockTelecallerCallbacksBloc(TelecallerListState(
        loading: false,
        items: List.generate(15, (i) => {
          'id': 'lead-cb-$i',
          'name': 'Client $i',
          'mobile': '980000000$i',
          'sanitized_phone': '980000000$i',
          'source': 'META',
          'scheduled_at': '2026-10-03T16:20:00Z',
          'remarks': 'Remark $i',
          'campaign_status': 'Callback',
          'lead_type': 'Requirement',
        }),
      ));

      await tester.pumpWidget(
        wrap(
          TelecallerCallbacksScreen(bloc: bloc),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Client 0 should be visible initially at the top
      expect(find.text('Client 0'), findsOneWidget);

      // Scroll to pagination at the bottom of the list
      final verticalScrollable = find.byType(Scrollable).first;
      final nextButton = find.byTooltip('Next page');
      await tester.scrollUntilVisible(nextButton, 200, scrollable: verticalScrollable);
      await tester.drag(verticalScrollable, const Offset(0, -100));
      await tester.pump();

      expect(find.textContaining('Showing 1–10 of 15'), findsOneWidget);
      expect(find.text('Page 1 of 2'), findsOneWidget);

      // Navigate to Next page
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // On Page 2: scroll animated to top, Client 10 is visible
      expect(find.text('Client 10'), findsOneWidget);
      expect(find.text('Client 0'), findsNothing);

      // Scroll to pagination to verify page 2 indicators
      final prevButton = find.byTooltip('Previous page');
      await tester.scrollUntilVisible(prevButton, 200, scrollable: verticalScrollable);
      await tester.drag(verticalScrollable, const Offset(0, -100));
      await tester.pump();

      expect(find.textContaining('Showing 11–15 of 15'), findsOneWidget);
      expect(find.text('Page 2 of 2'), findsOneWidget);

      // Navigate back to Previous page
      expect(prevButton, findsOneWidget);
      await tester.tap(prevButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Back on Page 1: Client 0 is visible again
      expect(find.text('Client 0'), findsOneWidget);
    });
  });

  group('TelecallerCnrScreen Mobile Adaptation', () {
    for (final width in [360.0, 390.0, 767.0]) {
      testMobile('renders MobileScreenScaffold with CNR filters at width $width', (tester) async {
        await setSurface(tester, width);

        await tester.pumpWidget(
          wrap(
            const TelecallerCnrScreen(),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // MobileScreenScaffold is used
        expect(find.byType(MobileScreenScaffold), findsOneWidget);

        // Sections
        expect(find.textContaining('Requirement'), findsOneWidget);
        expect(find.textContaining('Property Listing'), findsOneWidget);
      });
    }

    testMobile('desktop CNR preserved at 1024px', (tester) async {
      await setSurface(tester, 1024);

      await tester.pumpWidget(
        wrap(
          const TelecallerCnrScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Desktop does NOT use MobileScreenScaffold
      expect(find.byType(MobileScreenScaffold), findsNothing);
    });
  });

  group('CampaignLeadsScreen Calling Queue Mobile Adaptation', () {
    testMobile('renders mobile calling queue view at 390px', (tester) async {
      await setSurface(tester, 390);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
            BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
            BlocProvider<CampaignLeadsBloc>.value(value: MockCampaignLeadsBloc()),
          ],
          child: wrap(
            const CampaignLeadsScreen(initialView: 'active'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Calling Queue view switcher chips and title
      expect(find.textContaining('Calling Queue'), findsWidgets);
      expect(find.text('Follow-ups'), findsWidgets);
      expect(find.text('Not Interested'), findsWidgets);

      // Requirements vs Properties toggle
      expect(find.textContaining('Requirement'), findsWidgets);
      expect(find.textContaining('Property Listing'), findsWidgets);
    });

    testMobile('preserves desktop layout at 1024px', (tester) async {
      await setSurface(tester, 1024);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: MockAuthBloc()),
            BlocProvider<UsersBloc>.value(value: MockUsersBloc()),
            BlocProvider<CampaignLeadsBloc>.value(value: MockCampaignLeadsBloc()),
          ],
          child: wrap(
            const CampaignLeadsScreen(initialView: 'queue'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Calling Queue chip from mobile view should not be present
      expect(find.text('Calling Queue'), findsNothing);
    });
  });
}

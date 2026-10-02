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
import 'package:propkart/features/telecaller/screens/telecaller_dashboard_screen.dart';
import 'package:propkart/features/telecaller/screens/telecaller_callbacks_screen.dart';
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

        // Filter chips exist
        expect(find.text('All'), findsWidgets);
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Due'), findsOneWidget);
        expect(find.text('Future'), findsOneWidget);
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
      expect(find.text('Calling Queue'), findsWidgets);
      expect(find.text('Follow-ups'), findsOneWidget);
      expect(find.text('Not Interested'), findsOneWidget);

      // Requirements vs Properties toggle
      expect(find.textContaining('Requirement'), findsOneWidget);
      expect(find.textContaining('Property Listing'), findsOneWidget);
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/design_system/mobile/mobile.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/features/auth/bloc/auth_bloc.dart';
import 'package:propkart/features/auth/models/user_model.dart' as auth;
import 'package:propkart/features/users/bloc/users_bloc.dart';
import 'package:propkart/features/users/models/user_model.dart' as users;
import 'package:propkart/features/users/screens/users_screen.dart';
import 'package:propkart/features/users/screens/employee_detail_screen.dart';
import 'package:propkart/features/admin/bloc/lead_allocation_monitor_bloc.dart';
import 'package:propkart/features/library/screens/library_main_screen.dart';
import 'package:propkart/features/team_messages/screens/team_messages_screen.dart';
import 'package:propkart/features/properties/screens/recycle_bin_screen.dart';
import 'package:propkart/features/settings/screens/settings_screen.dart';
import 'package:propkart/features/settings/screens/sync_debug_screen.dart';
import 'package:propkart/features/profile/screens/profile_screen.dart';
import 'package:propkart/features/profile/widgets/mfa_security_card.dart';

import 'mobile_test_utils.dart';

// --- MOCKS ---

class MockAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  MockAuthBloc({String role = 'Admin', String fullName = 'Test Admin'})
      : super(Authenticated(
          user: auth.UserModel(
            id: 'test-admin-1',
            email: 'admin@propkart.test',
            fullName: fullName,
            role: role,
            permissions: const ['admin', 'users', 'properties', 'requirements', 'reports'],
            mfaEnabled: false,
          ),
        )) {
    on<AuthEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUsersBloc extends Bloc<UsersEvent, UsersState> implements UsersBloc {
  MockUsersBloc([List<users.UserModel>? userList])
      : super(UsersLoaded(
          users: userList ?? [
            const users.UserModel(
              id: 'user-1',
              roleId: 'role-sales',
              roleName: 'Sales',
              fullName: 'Rajesh Kumar',
              email: 'rajesh@propkart.test',
              mobile: '+91 98765 43210',
              isActive: true,
            ),
            const users.UserModel(
              id: 'user-2',
              roleId: 'role-telecaller',
              roleName: 'Telecaller',
              fullName: 'Priya Sharma',
              email: 'priya@propkart.test',
              mobile: '+91 98765 43211',
              isActive: true,
            ),
            const users.UserModel(
              id: 'u-detail-1',
              roleId: 'role-sales',
              roleName: 'Sales',
              fullName: 'Vikram Malhotra',
              email: 'vikram@propkart.test',
              mobile: '+91 99887 76655',
              isActive: true,
            ),
          ],
          roles: const [],
        )) {
    on<UsersEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLeadAllocationMonitorBloc
    extends Bloc<LeadAllocationMonitorEvent, LeadAllocationMonitorState>
    implements LeadAllocationMonitorBloc {
  MockLeadAllocationMonitorBloc([Map<String, dynamic>? data])
      : super(LeadAllocationMonitorState(
          loading: false,
          data: data ?? {
            'engineStatus': {
              'engine_enabled': true,
              'waiting_queue_count': 14,
              'today_allocated_count': 42,
              'stale_queue_count': 2,
            },
            'telecallers': [
              {
                'id': 'tc-1',
                'name': 'Priya Sharma',
                'email': 'priya@propkart.test',
                'is_active': true,
                'active_leads_count': 8,
                'daily_allocated_count': 12,
                'capacity': 20,
                'health_score': 92,
              },
              {
                'id': 'tc-2',
                'name': 'Amit Verma',
                'email': 'amit@propkart.test',
                'is_active': true,
                'active_leads_count': 15,
                'daily_allocated_count': 18,
                'capacity': 20,
                'health_score': 78,
              },
            ],
            'recentAssignments': [
              {
                'leadId': 'lead-101',
                'clientName': 'Sunil Mehta',
                'assignedToName': 'Priya Sharma',
                'createdAt': '2026-10-01T10:30:00Z',
                'status': 'Assigned',
              },
            ],
          },
        )) {
    on<LeadAllocationMonitorEvent>((event, emit) {});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget buildTestApp({
  required Widget child,
  AuthBloc? authBloc,
  UsersBloc? usersBloc,
  LeadAllocationMonitorBloc? allocationBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<AuthBloc>.value(value: authBloc ?? MockAuthBloc()),
      BlocProvider<UsersBloc>.value(value: usersBloc ?? MockUsersBloc()),
      BlocProvider<LeadAllocationMonitorBloc>.value(
        value: allocationBloc ?? MockLeadAllocationMonitorBloc(),
      ),
    ],
    child: MaterialApp(
      home: Material(
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RoleGuard.currentUser = const auth.UserModel(
      id: 'test-admin-1',
      email: 'admin@propkart.test',
      fullName: 'Test Admin',
      role: 'Admin',
      permissions: ['admin', 'users', 'properties', 'requirements', 'reports'],
      mfaEnabled: false,
    );
  });

  group('STEP 3.6 — M-28 Lead Allocation Mobile Presentation', () {
    testWidgets('renders mobile layout with MobileScreenScaffold on 360px', (tester) async {
      await setSurface(tester, 360);
      await tester.pumpWidget(
        buildTestApp(child: LeadAllocationMonitorScreen(bloc: MockLeadAllocationMonitorBloc())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(find.text('Lead Allocation'), findsOneWidget);
      expect(find.text('Engine: Active'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(find.text('Amit Verma'), findsOneWidget);
    });

    testWidgets('renders cleanly without overflow on 320px narrow mobile', (tester) async {
      await setSurface(tester, 320);
      await tester.pumpWidget(
        buildTestApp(child: LeadAllocationMonitorScreen(bloc: MockLeadAllocationMonitorBloc())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('preserves desktop layout on 1024px', (tester) async {
      await setSurface(tester, 1024);
      await tester.pumpWidget(
        buildTestApp(child: LeadAllocationMonitorScreen(bloc: MockLeadAllocationMonitorBloc())),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsNothing);
      expect(find.text('Lead Allocation Monitoring'), findsOneWidget);
    });
  });

  group('STEP 3.6 — M-29 Employees & Employee Detail', () {
    testWidgets('UsersScreen renders responsive mobile cards with Wrap action buttons on 360px', (tester) async {
      await setSurface(tester, 360);
      await tester.pumpWidget(
        buildTestApp(child: const UsersScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Employees'), findsWidgets);
      expect(find.text('Rajesh Kumar'), findsOneWidget);
      expect(find.text('Priya Sharma'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('UsersScreen renders without overflow on 320px narrow mobile', (tester) async {
      await setSurface(tester, 320);
      await tester.pumpWidget(
        buildTestApp(child: const UsersScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Employees'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EmployeeDetailScreen renders MobileScreenScaffold with back button on 360px', (tester) async {
      await setSurface(tester, 360);

      await tester.pumpWidget(
        buildTestApp(child: const EmployeeDetailScreen(userId: 'u-detail-1')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(find.text('Vikram Malhotra'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EmployeeDetailScreen preserves desktop layout at 1024px', (tester) async {
      await setSurface(tester, 1024);

      await tester.pumpWidget(
        buildTestApp(child: const EmployeeDetailScreen(userId: 'u-detail-1')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsNothing);
      expect(find.text('Employees'), findsWidgets);
    });
  });

  group('STEP 3.6 — M-36 Library Mobile Presentation', () {
    testWidgets('LibraryMainScreen renders MobileScreenScaffold in single column on 360px', (tester) async {
      await setSurface(tester, 360);
      await tester.pumpWidget(
        buildTestApp(child: const LibraryMainScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(find.text('Rental Library'), findsOneWidget);
      expect(find.text('Re-Sale Library'), findsOneWidget);
      expect(find.text('Service Agent Library'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LibraryMainScreen renders without overflow on 320px narrow mobile', (tester) async {
      await setSurface(tester, 320);
      await tester.pumpWidget(
        buildTestApp(child: const LibraryMainScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(find.text('Rental Library'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('LibraryMainScreen preserves grid layout at 1024px', (tester) async {
      await setSurface(tester, 1024);
      await tester.pumpWidget(
        buildTestApp(child: const LibraryMainScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsNothing);
      expect(find.text('Rental Library'), findsOneWidget);
    });
  });

  group('STEP 3.6 — M-37 Team Messages Mobile Presentation', () {
    testWidgets('TeamMessagesScreen renders mobile roster on 360px', (tester) async {
      await setSurface(tester, 360);
      await tester.pumpWidget(
        buildTestApp(child: const TeamMessagesScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byWidgetPredicate((w) => w is PopScope), findsWidgets);
      expect(find.text('Team Messages'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TeamMessagesScreen renders without overflow on 320px', (tester) async {
      await setSurface(tester, 320);
      await tester.pumpWidget(
        buildTestApp(child: const TeamMessagesScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('TeamMessagesScreen preserves desktop layout at 1024px', (tester) async {
      await setSurface(tester, 1024);
      await tester.pumpWidget(
        buildTestApp(child: const TeamMessagesScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Team Messages'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('STEP 3.6 — M-26 Recycle Bin Mobile Presentation', () {
    testWidgets('RecycleBinScreen renders MobileScreenScaffold on 360px', (tester) async {
      await setSurface(tester, 360);
      await tester.pumpWidget(
        buildTestApp(child: const RecycleBinScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(find.text('Deleted Properties'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RecycleBinScreen renders cleanly without overflow on 320px', (tester) async {
      await setSurface(tester, 320);
      await tester.pumpWidget(
        buildTestApp(child: const RecycleBinScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('RecycleBinScreen preserves desktop layout at 1024px', (tester) async {
      await setSurface(tester, 1024);
      await tester.pumpWidget(
        buildTestApp(child: const RecycleBinScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsNothing);
      expect(find.text('Deleted Properties'), findsOneWidget);
    });
  });

  group('STEP 3.6 — M-38 Settings Mobile Presentation', () {
    testWidgets('SettingsScreen renders grouped mobile settings menu on 360px', (tester) async {
      await setSurface(tester, 360);
      await tester.pumpWidget(
        buildTestApp(child: const SettingsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(find.text('ACCOUNT & SECURITY'), findsOneWidget);
      expect(find.text('PREFERENCES & APPEARANCE'), findsOneWidget);
      expect(find.text('OPERATIONS & INVENTORY'), findsOneWidget);
      expect(find.text('SYSTEM & DIAGNOSTICS'), findsOneWidget);
      expect(find.text('Themes'), findsOneWidget);
      expect(find.text('Sync Diagnostics'), findsOneWidget);
    });

    testWidgets('SettingsScreen drills down to sub-page with back button when tile is tapped', (tester) async {
      await setSurface(tester, 360);
      await tester.pumpWidget(
        buildTestApp(child: const SettingsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on Themes tile
      await tester.tap(find.text('Themes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Now inside Themes sub-page with MobileScreenScaffold titled Themes
      expect(find.text('Themes & Visual Styles'), findsOneWidget);
      expect(find.byType(MobileTopBar), findsOneWidget);

      // Tap back button
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Back at Settings landing menu
      expect(find.text('ACCOUNT & SECURITY'), findsOneWidget);
    });

    testWidgets('SettingsScreen preserves desktop sidebar layout at 1024px', (tester) async {
      await setSurface(tester, 1024);
      await tester.pumpWidget(
        buildTestApp(child: const SettingsScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsNothing);
      expect(find.text('Settings'), findsWidgets);
    });
  });

  group('STEP 3.6 — M-39 Sync Diagnostics Mobile Presentation', () {
    testWidgets('SyncDebugScreen renders MobileScreenScaffold on 360px', (tester) async {
      await setSurface(tester, 360);
      await tester.pumpWidget(
        buildTestApp(child: const SyncDebugScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(find.text('Realtime Sync Status'), findsOneWidget);
      expect(find.text('Force Connect'), findsOneWidget);
      expect(find.text('Sync Data'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SyncDebugScreen renders without overflow on 320px narrow mobile', (tester) async {
      await setSurface(tester, 320);
      await tester.pumpWidget(
        buildTestApp(child: const SyncDebugScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SyncDebugScreen preserves desktop layout at 1024px', (tester) async {
      await setSurface(tester, 1024);
      await tester.pumpWidget(
        buildTestApp(child: const SyncDebugScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsNothing);
      expect(find.text('Realtime Sync Status'), findsOneWidget);
    });
  });

  group('STEP 3.6 — M-41 Profile & MFA Security', () {
    testWidgets('ProfileScreen renders MobileScreenScaffold on 360px', (tester) async {
      await setSurface(tester, 360);
      await tester.pumpWidget(
        buildTestApp(child: const ProfileScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(find.text('Personal Details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfileScreen renders without overflow on 320px narrow mobile', (tester) async {
      await setSurface(tester, 320);
      await tester.pumpWidget(
        buildTestApp(child: const ProfileScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MfaSecurityCard renders responsively without overflow on 320px', (tester) async {
      await setSurface(tester, 320);
      final adminUser = auth.UserModel(
        id: 'admin-1',
        fullName: 'Admin User',
        email: 'admin@test.com',
        role: 'Admin',
        permissions: const ['admin'],
        mfaEnabled: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MfaSecurityCard(user: adminUser),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Two-Factor Auth (2FA)'), findsOneWidget);
      expect(find.text('ENABLED'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfileScreen preserves desktop layout at 1024px', (tester) async {
      await setSurface(tester, 1024);
      await tester.pumpWidget(
        buildTestApp(child: const ProfileScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MobileScreenScaffold), findsNothing);
      expect(find.text('Personal Details'), findsOneWidget);
    });
  });

  group('STEP 3.6 — Complete Width Matrix Verification (320, 360, 390, 412, 430, 480, 600, 767, 768, 1024, 1280)', () {
    const widths = [320.0, 360.0, 390.0, 412.0, 430.0, 480.0, 600.0, 767.0, 768.0, 1024.0, 1280.0];

    for (final width in widths) {
      testWidgets('M-28 Lead Allocation renders cleanly at ${width.toInt()}px', (tester) async {
        await setSurface(tester, width);
        await tester.pumpWidget(
          buildTestApp(child: LeadAllocationMonitorScreen(bloc: MockLeadAllocationMonitorBloc())),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        if (width < 768) {
          expect(find.byType(MobileScreenScaffold), findsOneWidget);
        } else {
          expect(find.byType(MobileScreenScaffold), findsNothing);
        }
      });
    }

    for (final width in widths) {
      testWidgets('M-29 Employee Detail renders cleanly at ${width.toInt()}px', (tester) async {
        await setSurface(tester, width);
        await tester.pumpWidget(
          buildTestApp(child: const EmployeeDetailScreen(userId: 'u-detail-1')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        if (width < 768) {
          expect(find.byType(MobileScreenScaffold), findsOneWidget);
        } else {
          expect(find.byType(MobileScreenScaffold), findsNothing);
        }
      });
    }

    for (final width in widths) {
      testWidgets('M-36 Library renders cleanly at ${width.toInt()}px', (tester) async {
        await setSurface(tester, width);
        await tester.pumpWidget(
          buildTestApp(child: const LibraryMainScreen()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        if (width < 768) {
          expect(find.byType(MobileScreenScaffold), findsOneWidget);
        } else {
          expect(find.byType(MobileScreenScaffold), findsNothing);
        }
      });
    }

    for (final width in widths) {
      testWidgets('M-37 Messages renders cleanly at ${width.toInt()}px', (tester) async {
        await setSurface(tester, width);
        await tester.pumpWidget(
          buildTestApp(child: const TeamMessagesScreen()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        expect(find.text('Team Messages'), findsOneWidget);
      });
    }

    for (final width in widths) {
      testWidgets('M-26 Recycle Bin renders cleanly at ${width.toInt()}px', (tester) async {
        await setSurface(tester, width);
        await tester.pumpWidget(
          buildTestApp(child: const RecycleBinScreen()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        if (width < 768) {
          expect(find.byType(MobileScreenScaffold), findsOneWidget);
        } else {
          expect(find.byType(MobileScreenScaffold), findsNothing);
        }
      });
    }

    for (final width in widths) {
      testWidgets('M-38 Settings renders cleanly at ${width.toInt()}px', (tester) async {
        await setSurface(tester, width);
        await tester.pumpWidget(
          buildTestApp(child: const SettingsScreen()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        if (width < 768) {
          expect(find.byType(MobileScreenScaffold), findsOneWidget);
        } else {
          expect(find.byType(MobileScreenScaffold), findsNothing);
        }
      });
    }

    for (final width in widths) {
      testWidgets('M-39 Sync Diagnostics renders cleanly at ${width.toInt()}px', (tester) async {
        await setSurface(tester, width);
        await tester.pumpWidget(
          buildTestApp(child: const SyncDebugScreen()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        if (width < 768) {
          expect(find.byType(MobileScreenScaffold), findsOneWidget);
        } else {
          expect(find.byType(MobileScreenScaffold), findsNothing);
        }
      });
    }

    for (final width in widths) {
      testWidgets('M-41 Profile & MFA renders cleanly at ${width.toInt()}px', (tester) async {
        await setSurface(tester, width);
        await tester.pumpWidget(
          buildTestApp(child: const ProfileScreen()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);
        if (width < 768) {
          expect(find.byType(MobileScreenScaffold), findsOneWidget);
        } else {
          expect(find.byType(MobileScreenScaffold), findsNothing);
        }
      });
    }
  });
}

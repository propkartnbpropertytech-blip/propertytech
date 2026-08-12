import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/properties/screens/properties_screen.dart';
import '../../features/properties/screens/property_detail_screen.dart';
import '../../features/properties/bloc/properties_bloc.dart';
import '../../features/users/screens/users_screen.dart';
import '../../features/requirements/screens/requirements_screen.dart';
import '../../features/clients/screens/clients_screen.dart';

import '../../features/owners/screens/owners_screen.dart';
import '../../features/builders/screens/builders_screen.dart';
import '../../splash.dart';
import '../../get_started_screen.dart';
import '../../modules/legal/presentation/terms_and_conditions_page.dart';
import '../../modules/legal/presentation/privacy_policy_page.dart';
import '../design_system/widgets/app_shell.dart';
import '../design_system/widgets/crm_page_transition.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/audit_logs_screen.dart';
import '../../features/settings/screens/location_config_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/properties/screens/recycle_bin_screen.dart';
import '../network/sync_manager.dart';
import '../storage/secure_storage.dart';
import '../storage/session_cleanup.dart';
import '../../features/requirements/screens/share_properties_page.dart';
import '../../features/requirements/screens/public_property_detail_screen.dart';
import '../security/role_guard.dart';
import '../../features/library/screens/library_main_screen.dart';
import '../../features/library/screens/rental_library_screen.dart';
import '../../features/library/screens/resale_library_screen.dart';
import '../../features/library/screens/service_agent_library_screen.dart';
import '../utils/seo_helper.dart';


class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/get-started',
        builder: (context, state) => const GetStartedScreen(),
      ),
      GoRoute(
        path: '/terms-and-conditions',
        builder: (context, state) => const TermsAndConditionsPage(),
      ),
      GoRoute(
        path: '/terms_and_conditions',
        builder: (context, state) => const TermsAndConditionsPage(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/privacy_policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => ResetPasswordScreen(
          errorCode: state.uri.queryParameters['error_code'] ?? state.uri.queryParameters['error'],
          errorDescription: state.uri.queryParameters['error_description'],
          tokenHash: state.uri.queryParameters['token_hash'],
          type: state.uri.queryParameters['type'],
          code: state.uri.queryParameters['code'],
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => CRMAppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              name: state.name,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/properties',
            pageBuilder: (context, state) {
              final openId = state.uri.queryParameters['openId'] ?? (state.extra as String?);
              return crmFadeSlidePage(
                key: state.pageKey,
                name: state.name,
                child: BlocProvider(
                  create: (context) => PropertiesBloc(),
                  child: PropertiesScreen(openPropertyId: openId),
                ),
              );
            },
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const UsersScreen(),
            ),
          ),
          GoRoute(
            path: '/requirements',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const RequirementsScreen(),
            ),
          ),
          GoRoute(
            path: '/clients',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const ClientsScreen(),
            ),
          ),

          GoRoute(
            path: '/owners',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const OwnersScreen(),
            ),
          ),
          GoRoute(
            path: '/builders',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const BuildersScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings/audit-logs',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const AuditLogsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings/location-config',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const LocationConfigScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: '/bin',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const RecycleBinScreen(),
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const LibraryMainScreen(),
            ),
          ),
          GoRoute(
            path: '/rental-library',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: RentalLibraryScreen(
                initialArgs: state.extra as Map<String, dynamic>?,
              ),
            ),
          ),
          GoRoute(
            path: '/resale-library',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: ResaleLibraryScreen(
                initialArgs: state.extra as Map<String, dynamic>?,
              ),
            ),
          ),
          GoRoute(
            path: '/service-agent-library',
            pageBuilder: (context, state) => crmFadeSlidePage(
              key: state.pageKey,
              child: const ServiceAgentLibraryScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/properties/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PropertyDetailScreen(propertyId: id);
        },
      ),
      GoRoute(
        path: '/share/:sessionId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final agentName = state.uri.queryParameters['agentName'];
          final agentMobile = state.uri.queryParameters['agentMobile'];
          return SharePropertiesPage(
            sessionId: sessionId,
            agentName: agentName,
            agentMobile: agentMobile,
          );
        },
      ),
      GoRoute(
        path: '/share/:sessionId/property/:propertyId',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          final propertyId = state.pathParameters['propertyId']!;
          final agentName = state.uri.queryParameters['agentName'];
          final agentMobile = state.uri.queryParameters['agentMobile'];
          return PublicPropertyDetailScreen(
            sessionId: sessionId,
            propertyId: propertyId,
            agentName: agentName,
            agentMobile: agentMobile,
          );
        },
      ),
    ],
    errorBuilder: (context, state) {
      final uri = state.uri;
      final path = uri.path;
      // Production builds / deep links sometimes surface recovery URLs via errorBuilder.
      if (path == '/reset-password' || path.startsWith('/reset-password')) {
        return ResetPasswordScreen(
          errorCode: uri.queryParameters['error_code'] ?? uri.queryParameters['error'],
          errorDescription: uri.queryParameters['error_description'],
          tokenHash: uri.queryParameters['token_hash'],
          type: uri.queryParameters['type'],
          code: uri.queryParameters['code'],
        );
      }
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Page Not Found', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(state.error?.toString() ?? 'No routes for location: ${state.uri}', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                TextButton(onPressed: () => context.go('/login'), child: const Text('Home')),
              ],
            ),
          ),
        ),
      );
    },
    redirect: (context, state) async {
      _applySecureRouteSeo(state.matchedLocation);
      final authState = authBloc.state;
      final loggingIn = state.matchedLocation == '/login';
      final onSplash = state.matchedLocation == '/splash';
      final onGetStarted = state.matchedLocation == '/get-started';
      final isPublicShare = state.matchedLocation.startsWith('/share/') || state.uri.path.startsWith('/share/');
      final onUsers = state.matchedLocation.startsWith('/users');
      final onAudit = state.matchedLocation.startsWith('/settings/audit-logs');
      final onTerms = state.matchedLocation == '/terms-and-conditions' || state.matchedLocation == '/terms_and_conditions' || state.uri.path == '/terms-and-conditions' || state.uri.path == '/terms_and_conditions';
      final onPrivacy = state.matchedLocation == '/privacy-policy' || state.matchedLocation == '/privacy_policy' || state.uri.path == '/privacy-policy' || state.uri.path == '/privacy_policy';
      final onResetPassword = state.matchedLocation == '/reset-password' || state.uri.path == '/reset-password';
      final isAuthGate = loggingIn || onSplash || onGetStarted || isPublicShare || onTerms || onPrivacy || onResetPassword;

      if (authState is Authenticated) {
        // Check 9-hour inactivity timeout
        final secureStorage = SecureStorage();
        final isInactiveExpired = await secureStorage.isSessionExpiredDueToInactivity();
        if (isInactiveExpired) {
          await SessionCleanup.clearLocalSession(clearToken: true);
          authBloc.add(AuthSessionExpired());
          final target = state.uri.toString();
          return '/get-started?from=${Uri.encodeComponent(target)}';
        }
        
        // Otherwise, update last activity timestamp since they are active
        await secureStorage.updateLastActivity();

        final role = authState.user.role;

        // Trigger background sync if not completed and not already syncing.
        if (!SyncManager().isSyncCompleted && !SyncManager().isSyncing.value) {
          SyncManager().performStartupSync().catchError((e) {
            debugPrint("Background sync error: $e");
          });
        }

        if (onUsers && !RoleGuard.canManageEmployees(role)) {
          return '/dashboard';
        }
        if (onAudit && !RoleGuard.canViewAuditLogs(role)) {
          return '/dashboard';
        }

        if (loggingIn || onGetStarted) {
          final from = state.uri.queryParameters['from'];
          return RoleGuard.sanitizeRedirectPath(from, role: role) ?? '/dashboard';
        }
        if (onSplash) {
          if (!SyncManager().isSyncCompleted) {
            return null;
          }
          final from = state.uri.queryParameters['from'];
          return RoleGuard.sanitizeRedirectPath(from, role: role) ?? '/dashboard';
        }
        return null;
      }

      if (authState is Unauthenticated || authState is AuthError) {
        if (!isAuthGate) {
          final target = state.uri.toString();
          return '/get-started?from=${Uri.encodeComponent(target)}';
        }
        return null;
      }

      // If authentication state is still initializing/loading (AuthInitial/AuthLoading),
      // we do not force a redirect to the splash screen. This allows deep links and hard refreshes
      // to stay on their target route while the auth check completes.
      return null;
    },
  );

  void _applySecureRouteSeo(String location) {
    if (location.startsWith('/dashboard')) {
      SeoHelper.updateTags(
        title: 'Dashboard | PropKart CRM',
        description: 'PropKart business dashboard and real-time performance indicators.',
        noIndex: true,
      );
    } else if (location.startsWith('/properties')) {
      SeoHelper.updateTags(
        title: 'Manage Properties | PropKart CRM',
        description: 'Browse, edit, and configure property listings in inventory.',
        noIndex: true,
      );
    } else if (location.startsWith('/users')) {
      SeoHelper.updateTags(
        title: 'User Management | PropKart CRM',
        description: 'Manage staff, agents, roles and administrative access.',
        noIndex: true,
      );
    } else if (location.startsWith('/requirements')) {
      SeoHelper.updateTags(
        title: 'Leads Tracker | PropKart CRM',
        description: 'Review client listing requests and buy/rent matchmaking preferences.',
        noIndex: true,
      );
    } else if (location.startsWith('/clients')) {
      SeoHelper.updateTags(
        title: 'Client Index | PropKart CRM',
        description: 'Manage client contacts, historical activities, and lead funnels.',
        noIndex: true,
      );
    } else if (location.startsWith('/owners')) {
      SeoHelper.updateTags(
        title: 'Property Owners | PropKart CRM',
        description: 'Manage land owners, builders, and lessor details.',
        noIndex: true,
      );
    } else if (location.startsWith('/builders')) {
      SeoHelper.updateTags(
        title: 'Builders Directory | PropKart CRM',
        description: 'Access developers and construction company listings.',
        noIndex: true,
      );
    } else if (location.startsWith('/settings')) {
      SeoHelper.updateTags(
        title: 'System Settings | PropKart CRM',
        description: 'Configure audit logs, location parameters, and security policies.',
        noIndex: true,
      );
    } else if (location.startsWith('/profile')) {
      SeoHelper.updateTags(
        title: 'My Profile | PropKart CRM',
        description: 'Update agent personal information and security credentials.',
        noIndex: true,
      );
    } else if (location.startsWith('/bin')) {
      SeoHelper.updateTags(
        title: 'Recycle Bin | PropKart CRM',
        description: 'Review and restore archived or deleted property listings.',
        noIndex: true,
      );
    } else if (location.startsWith('/library') ||
               location.startsWith('/rental-library') ||
               location.startsWith('/resale-library') ||
               location.startsWith('/service-agent-library')) {
      SeoHelper.updateTags(
        title: 'Shared Libraries | PropKart CRM',
        description: 'View rental and resale property library databases.',
        noIndex: true,
      );
    } else if (location.startsWith('/splash')) {
      SeoHelper.updateTags(
        title: 'PropKart CRM',
        description: 'The Future of Property Management.',
        noIndex: true,
      );
    }
  }
}

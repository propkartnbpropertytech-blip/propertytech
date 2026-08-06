import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/repository/auth_repository.dart';
import 'features/dashboard/repository/dashboard_repository.dart';
import 'features/users/repository/users_repository.dart';
import 'features/requirements/repository/requirements_repository.dart';
import 'features/clients/repository/clients_repository.dart';
import 'features/owners/repository/owners_repository.dart';
import 'features/builders/repository/builders_repository.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/users/bloc/users_bloc.dart';
import 'features/requirements/bloc/requirements_bloc.dart';
import 'features/clients/bloc/clients_bloc.dart';
import 'features/owners/bloc/owners_bloc.dart';
import 'features/builders/bloc/builders_bloc.dart';
import 'core/navigation/app_router.dart';
import 'core/design_system/theme/propkart_theme.dart';
import 'core/theme/theme_manager.dart';

import 'core/storage/isar_service.dart';
import 'core/storage/performance_logger.dart';
import 'core/network/sync_manager.dart';
import 'core/storage/repository_coordinator.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/api/api_constants.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint("Error initializing Supabase: $e");
  }
  
  try {
    await IsarService().initialize();
    await PerformanceLogger().initialize();
    // Do NOT connect Supabase Realtime before login — auth gates sync.
    await SyncManager().initialize();

    final lookupCount = await RepositoryCoordinator().lookupLocal.getLookupsCount();
    if (lookupCount > 0) {
      SyncManager().isSyncCompleted = true;
    }
  } catch (e, stackTrace) {
    debugPrint("🚨 Error during startup initialization: $e");
    debugPrint("🚨 Startup initialization stack trace:\n$stackTrace");
    MyApp.startupError = e.toString();
    MyApp.startupStackTrace = stackTrace.toString();
  }

  final authRepository = AuthRepository();

  if (ApiConstants.sentryDsn != 'YOUR_SENTRY_DSN') {
    await SentryFlutter.init(
      (options) {
        options.dsn = ApiConstants.sentryDsn;
        options.tracesSampleRate = 1.0;
        // ignore: experimental_member_use
        options.profilesSampleRate = 1.0;
        options.environment = kReleaseMode ? 'production' : 'development';
      },
      appRunner: () => runApp(MyApp(authRepository: authRepository)),
    );
  } else {
    runApp(MyApp(authRepository: authRepository));
  }
}

class MyApp extends StatefulWidget {
  final AuthRepository authRepository;
  static String? startupError;
  static String? startupStackTrace;

  const MyApp({super.key, required this.authRepository});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter;
  late final AuthBloc _authBloc;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authRepository: widget.authRepository)..add(AuthCheckStatus());
    _appRouter = AppRouter(_authBloc);
  }

  @override
  Widget build(BuildContext context) {
    if (MyApp.startupError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1E1E1E),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "PropKart Startup Error",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please capture/copy this message to help diagnose the issue.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: SelectionArea(
                          child: Text(
                            "ERROR:\n${MyApp.startupError}\n\nSTACK TRACE:\n${MyApp.startupStackTrace}",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.authRepository),
        RepositoryProvider(create: (context) => DashboardRepository()),
        RepositoryProvider(create: (context) => UsersRepository()),
        RepositoryProvider(create: (context) => RequirementsRepository()),
        RepositoryProvider(create: (context) => ClientsRepository()),
        RepositoryProvider(create: (context) => OwnersRepository()),
        RepositoryProvider(create: (context) => BuildersRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider(
            create: (context) => DashboardBloc(
              dashboardRepository: context.read<DashboardRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => UsersBloc(
              usersRepository: context.read<UsersRepository>(),
              authBloc: context.read<AuthBloc>(),
            ),
          ),
          BlocProvider(
            create: (context) => RequirementsBloc(
              requirementsRepository: context.read<RequirementsRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => ClientsBloc(
              clientsRepository: context.read<ClientsRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => OwnersBloc(
              ownersRepository: context.read<OwnersRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => BuildersBloc(
              buildersRepository: context.read<BuildersRepository>(),
            ),
          ),
        ],
        child: ListenableBuilder(
          listenable: ThemeManager(),
          builder: (context, _) {
            final isDark = ThemeManager().isDarkMode;
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'PropKart',
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              theme: PropKartTheme.light(),
              darkTheme: PropKartTheme.dark(),
              routerConfig: _appRouter.router,
            );
          },
        ),
      ),
    );
  }
}
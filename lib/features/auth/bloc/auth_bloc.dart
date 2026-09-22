import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';
import '../../../core/network/sync_manager.dart';
import '../../../core/storage/session_cleanup.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/services/notification_center.dart';

// ==========================================
// Auth Events
// ==========================================
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckStatus extends AuthEvent {}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;
  final String? captchaId;
  final String? captchaAnswer;

  const LoginSubmitted({
    required this.email,
    required this.password,
    required this.rememberMe,
    this.captchaId,
    this.captchaAnswer,
  });

  @override
  List<Object?> get props => [email, rememberMe, captchaId, captchaAnswer];
}

class LogoutRequested extends AuthEvent {}

class MfaSubmitted extends AuthEvent {
  final String mfaChallengeId;
  final String code;
  final bool rememberMe;

  const MfaSubmitted({
    required this.mfaChallengeId,
    required this.code,
    required this.rememberMe,
  });

  @override
  List<Object?> get props => [mfaChallengeId, code, rememberMe];
}

/// Internal: session killed by 401 / forced cleanup.
class AuthSessionExpired extends AuthEvent {}

// ==========================================
// Auth States
// ==========================================
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class MfaChallengeRequired extends AuthState {
  final String mfaChallengeId;
  final String email;
  final String role;
  final bool rememberMe;
  final bool mfaSetupRequired;
  final String? secret;
  final String? otpauthUrl;

  const MfaChallengeRequired({
    required this.mfaChallengeId,
    required this.email,
    required this.role,
    required this.rememberMe,
    this.mfaSetupRequired = false,
    this.secret,
    this.otpauthUrl,
  });

  @override
  List<Object?> get props => [
        mfaChallengeId,
        email,
        role,
        rememberMe,
        mfaSetupRequired,
        secret,
        otpauthUrl,
      ];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

// ==========================================
// Auth BLoC
// ==========================================
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<void>? _forcedLogoutSub;
  Timer? _sessionWatchdogTimer;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckStatus>(_onAuthCheckStatus);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<MfaSubmitted>(_onMfaSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);

    _forcedLogoutSub = SessionCleanup.onForcedLogout.listen((_) {
      if (!isClosed && state is Authenticated) {
        add(AuthSessionExpired());
      }
    });
  }

  void _startSessionWatchdog() async {
    _sessionWatchdogTimer?.cancel();
    final secureStorage = SecureStorage();
    final loginTime = await secureStorage.getSessionLoginTime();
    if (loginTime == null) return;

    final expirationHours = await secureStorage.getSessionExpirationHours();
    final maxDurationMs = expirationHours * 3600 * 1000;
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - loginTime.millisecondsSinceEpoch;
    final remainingMs = maxDurationMs - elapsedMs;

    if (remainingMs <= 0) {
      AppLogger.w('[AuthBloc] Session reached limit ($expirationHours hours). Auto-logging out.');
      add(AuthSessionExpired());
      return;
    }

    AppLogger.i('[AuthBloc] Session watchdog scheduled: expires in ${(remainingMs / 3600000).toStringAsFixed(1)} hours.');
    _sessionWatchdogTimer = Timer(Duration(milliseconds: remainingMs), () {
      AppLogger.w('[AuthBloc] Session expired ($expirationHours hours). Firing AuthSessionExpired.');
      add(AuthSessionExpired());
    });
  }

  @override
  Future<void> close() async {
    _sessionWatchdogTimer?.cancel();
    await _forcedLogoutSub?.cancel();
    return super.close();
  }

  Future<void> _onAuthCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (isAuth) {
        final user = await _authRepository.getProfile();
        RoleGuard.currentUser = user;
        emit(Authenticated(user: user));
        _startSessionWatchdog();
        unawaited(PushNotificationService.registerCurrentUser());
        unawaited(() async {
          try {
            await SyncManager().performStartupSync();
            SyncManager().isSyncCompleted = true;
          } catch (syncErr) {
            AppLogger.w('Startup background sync warning', syncErr);
          }
        }());
      } else {
        RoleGuard.currentUser = null;
        emit(Unauthenticated());
      }
    } catch (_) {
      RoleGuard.currentUser = null;
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authRepository.login(
        event.email,
        event.password,
        event.rememberMe,
        captchaId: event.captchaId,
        captchaAnswer: event.captchaAnswer,
      );

      if (result is Map && result['mfaRequired'] == true) {
        emit(MfaChallengeRequired(
          mfaChallengeId: result['mfaChallengeId'] ?? '',
          email: result['email'] ?? event.email,
          role: result['role'] ?? '',
          rememberMe: event.rememberMe,
          mfaSetupRequired: result['mfaSetupRequired'] == true,
          secret: result['secret']?.toString(),
          otpauthUrl: result['otpauthUrl']?.toString(),
        ));
        return;
      }

      final user = result as UserModel;
      RoleGuard.currentUser = user;
      AppLogger.i('User ${user.email} (${user.role}) logged in successfully');

      emit(Authenticated(user: user));
      _startSessionWatchdog();
      unawaited(PushNotificationService.registerCurrentUser());

      unawaited(() async {
        try {
          await SyncManager().performStartupSync();
          SyncManager().isSyncCompleted = true;
          await SyncManager().connectAfterAuth();
        } catch (syncErr) {
          SyncManager().isSyncCompleted = false;
          AppLogger.w('Post-login background sync warning', syncErr);
        }
      }());
    } catch (e, stackTrace) {
      AppLogger.e('Login failed for ${event.email}', e, stackTrace);
      RoleGuard.currentUser = null;
      emit(AuthError(message: e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> _onMfaSubmitted(
    MfaSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.verifyMfa(
        event.mfaChallengeId,
        event.code,
        event.rememberMe,
      );
      RoleGuard.currentUser = user;
      AppLogger.i('User ${user.email} (${user.role}) logged in successfully via 2FA');

      emit(Authenticated(user: user));
      _startSessionWatchdog();
      unawaited(PushNotificationService.registerCurrentUser());

      unawaited(() async {
        try {
          await SyncManager().performStartupSync();
          SyncManager().isSyncCompleted = true;
          await SyncManager().connectAfterAuth();
        } catch (syncErr) {
          SyncManager().isSyncCompleted = false;
          AppLogger.w('Post-login background sync warning', syncErr);
        }
      }());
    } catch (e, stackTrace) {
      AppLogger.e('2FA verification failed for challenge ${event.mfaChallengeId}', e, stackTrace);
      RoleGuard.currentUser = null;
      emit(AuthError(message: e.toString().replaceAll('Exception: ', '')));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    _sessionWatchdogTimer?.cancel();
    RoleGuard.currentUser = null;
    try {
      await NotificationCenter.clearSession();
    } catch (_) {}
    // Emit first so the router does not bounce /get-started back to /dashboard
    // while network sign-out is still in flight.
    emit(Unauthenticated());
    try {
      await _authRepository.logout();
    } catch (_) {}
    try {
      await SessionCleanup.clearLocalSession(clearToken: true);
    } catch (_) {}
    unawaited(SyncManager().disconnect());
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    _sessionWatchdogTimer?.cancel();
    try {
      await SessionCleanup.clearLocalSession(clearToken: true);
    } catch (_) {}
    unawaited(SyncManager().disconnect());
    RoleGuard.currentUser = null;
    try {
      await NotificationCenter.clearSession();
    } catch (_) {}
    emit(Unauthenticated());
  }
}

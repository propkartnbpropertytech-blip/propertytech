import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/user_model.dart';
import '../repository/auth_repository.dart';
import '../../../core/network/sync_manager.dart';
import '../../../core/storage/session_cleanup.dart';
import '../../../core/security/role_guard.dart';

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

  const LoginSubmitted({
    required this.email,
    required this.password,
    required this.rememberMe,
  });

  @override
  List<Object?> get props => [email, rememberMe];
}

class LogoutRequested extends AuthEvent {}

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

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckStatus>(_onAuthCheckStatus);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);

    _forcedLogoutSub = SessionCleanup.onForcedLogout.listen((_) {
      if (!isClosed) add(AuthSessionExpired());
    });
  }

  @override
  Future<void> close() async {
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
        unawaited(SyncManager().connectAfterAuth());
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
      await _authRepository.login(
        event.email,
        event.password,
        event.rememberMe,
      );
      final user = await _authRepository.getProfile();
      RoleGuard.currentUser = user;
      try {
        await SyncManager().performStartupSync();
        SyncManager().isSyncCompleted = true;
        // Realtime only after authenticated sync.
        await SyncManager().connectAfterAuth();
      } catch (syncErr) {
        SyncManager().isSyncCompleted = false;
        if (kDebugMode) {
          // ignore: avoid_print
          print('⚠️ [LOGIN SYNC WARNING] Startup sync failed during login');
        }
      }
      emit(Authenticated(user: user));
    } catch (e) {
      RoleGuard.currentUser = null;
      emit(AuthError(message: e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    RoleGuard.currentUser = null;
    // Emit first so the router does not bounce /get-started back to /dashboard
    // while network sign-out is still in flight.
    emit(Unauthenticated());
    try {
      await _authRepository.logout();
    } catch (_) {}
    try {
      await SessionCleanup.clearLocalSession(clearToken: true);
    } catch (_) {}
    emit(Unauthenticated());
  }

  Future<void> _onSessionExpired(
    AuthSessionExpired event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await SessionCleanup.clearLocalSession(clearToken: true);
    } catch (_) {}
    RoleGuard.currentUser = null;
    emit(Unauthenticated());
  }
}

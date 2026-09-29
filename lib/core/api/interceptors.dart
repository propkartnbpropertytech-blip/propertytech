import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../storage/secure_storage.dart';
import '../storage/session_cleanup.dart';
import '../../features/auth/repository/auth_repository.dart';
import 'dio_credentials_stub.dart'
    if (dart.library.html) 'dio_credentials_web.dart' as credentials;

class JwtInterceptor extends Interceptor {
  final SecureStorage _secureStorage = SecureStorage();
  final AuthRepository _authRepository = AuthRepository();

  static Completer<bool>? _refreshCompleter;

  /// Paths that must not trigger forced logout / refresh on 401.
  static const _authExemptPrefixes = <String>[
    '/auth/login',
    '/auth/register',
    '/auth/forgot',
    '/auth/reset',
    '/auth/refresh',
    '/health',
    '/audit/events',
    '/audit',
  ];

  /// Public endpoints should not receive Authorization (confused deputy).
  static const _publicPrefixes = <String>[
    '/share-sessions/public',
    '/auth/login',
    '/auth/refresh',
    '/auth/forgot',
    '/health',
  ];

  bool _matchesAny(String path, List<String> prefixes) {
    for (final prefix in prefixes) {
      if (path.contains(prefix)) return true;
    }
    return false;
  }

  /// Bare client for 401 retries — credentials on, no interceptors (avoids loops).
  Dio _retryClient(RequestOptions opts) {
    final dio = Dio(
      BaseOptions(
        baseUrl: opts.baseUrl,
        connectTimeout: opts.connectTimeout,
        receiveTimeout: opts.receiveTimeout,
        headers: Map<String, dynamic>.from(opts.headers),
      ),
    );
    credentials.configureDioCredentials(dio);
    return dio;
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (!_matchesAny(options.path, _publicPrefixes)) {
        await _secureStorage.updateLastActivity();
      }

      if (kIsWeb) {
        options.headers['X-Auth-Transport'] = 'cookie';
        if (!_matchesAny(options.path, _publicPrefixes)) {
          // Memory Bearer fallback when HttpOnly cookies are not sent yet.
          final token = await _secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            options.headers.remove('Authorization');
          }
        } else {
          options.headers.remove('Authorization');
        }
      } else if (!_matchesAny(options.path, _publicPrefixes)) {
        final token = await _secureStorage.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } else {
        options.headers.remove('Authorization');
      }
    } catch (_) {}
    super.onRequest(options, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (status == 401 && !_matchesAny(path, _authExemptPrefixes)) {
      // 1. If the request was sent without a Bearer token, it was an unauthenticated call.
      // Do NOT attempt token refresh or forced logout.
      final reqAuth = err.requestOptions.headers['Authorization']?.toString();
      if (reqAuth == null || !reqAuth.startsWith('Bearer ')) {
        super.onError(err, handler);
        return;
      }

      // 2. Check if the token on the failing request is the CURRENT token.
      final currentToken = await _secureStorage.getToken();
      if (currentToken == null || currentToken.isEmpty) {
        // No current token in storage; user is already unauthenticated.
        super.onError(err, handler);
        return;
      }
      final failedToken = reqAuth.substring(7).trim();
      if (failedToken != currentToken) {
        // The 401 came from a stale request sent with an old/superseded token.
        // A new login has already established a new token. Ignore.
        super.onError(err, handler);
        return;
      }

      bool refreshed = false;
      if (_refreshCompleter != null) {
        // Another parallel request is currently refreshing the session.
        // Wait for it instead of immediately triggering forced logout.
        refreshed = await _refreshCompleter!.future;
      } else {
        final completer = Completer<bool>();
        _refreshCompleter = completer;
        try {
          refreshed = await _authRepository.refreshSession();
          completer.complete(refreshed);
        } catch (e) {
          completer.complete(false);
          refreshed = false;
        } finally {
          _refreshCompleter = null;
        }
      }

      if (refreshed) {
        final opts = err.requestOptions;
        if (kIsWeb) {
          opts.headers['X-Auth-Transport'] = 'cookie';
          final token = await _secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            opts.headers['Authorization'] = 'Bearer $token';
          } else {
            opts.headers.remove('Authorization');
          }
        } else {
          final token = await _secureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            opts.headers['Authorization'] = 'Bearer $token';
          }
        }
        try {
          final clone = await _retryClient(opts).fetch(opts);
          return handler.resolve(clone);
        } catch (retryErr) {
          if (retryErr is DioException) {
            return handler.reject(retryErr);
          }
        }
      } else {
        // Refresh failed for the current active token.
        // Double-check that a new login hasn't occurred in the meantime.
        final latestToken = await _secureStorage.getToken();
        if (latestToken != null && latestToken == currentToken) {
          await SessionCleanup.clearLocalSession(clearToken: true);
          SessionCleanup.notifyForcedLogout();
        }
      }
    }
    super.onError(err, handler);
  }
}

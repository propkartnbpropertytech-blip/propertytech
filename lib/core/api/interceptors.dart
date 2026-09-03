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

  bool _isRefreshing = false;

  /// Paths that must not trigger forced logout / refresh on 401.
  static const _authExemptPrefixes = <String>[
    '/auth/login',
    '/auth/register',
    '/auth/forgot',
    '/auth/reset',
    '/auth/refresh',
    '/health',
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
      if (!_isRefreshing) {
        _isRefreshing = true;
        try {
          final refreshed = await _authRepository.refreshSession();
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
              opts.headers['Authorization'] = 'Bearer $token';
            }
            try {
              final clone = await _retryClient(opts).fetch(opts);
              _isRefreshing = false;
              return handler.resolve(clone);
            } catch (_) {
              // fall through to logout
            }
          }
        } finally {
          _isRefreshing = false;
        }
      }

      await SessionCleanup.clearLocalSession(clearToken: true);
      SessionCleanup.notifyForcedLogout();
    }
    super.onError(err, handler);
  }
}

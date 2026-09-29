import 'package:flutter/foundation.dart';

/// Explicit environment selection.
/// - In local development (debug mode, or APP_ENV=local): defaults to local backend (http://127.0.0.1:5001/api/v1).
/// - In live deployment (release build, or APP_ENV=production): connects to Hostinger VPS (https://api-propkart.nbpropertytech.com/api/v1).
class AppEnv {
  static const name = String.fromEnvironment('APP_ENV');
  static const apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static const localApi = 'http://127.0.0.1:5001/api/v1';
  static const productionApi =
      'https://api-propkart.nbpropertytech.com/api/v1';

  static final _prodHostRe = RegExp(
    r'nbpropertytech\.com|200\.234\.36\.120|api-propkart',
    caseSensitive: false,
  );
  static final _localHostRe = RegExp(r'localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\]');

  /// When running locally (debug mode, or explicitly APP_ENV=local)
  static bool get isLocal => name == 'local' || (!kReleaseMode && name != 'production');

  /// When deployed to production (release mode build, or explicitly APP_ENV=production)
  static bool get isProduction => name == 'production' || (kReleaseMode && name != 'local');

  static String get apiBaseUrl {
    // 1. Live deployment (release build) or explicitly set to production
    if (name == 'production' || (kReleaseMode && name != 'local')) {
      final url = apiBaseUrlOverride.isEmpty ? productionApi : apiBaseUrlOverride;
      if (_localHostRe.hasMatch(url) && kReleaseMode) {
        throw StateError('Release build must not use localhost API_BASE_URL.');
      }
      return _stripSlash(url);
    }

    // 2. Local development (debug mode, or APP_ENV=local)
    final url = apiBaseUrlOverride.isEmpty ? localApi : apiBaseUrlOverride;
    if (_prodHostRe.hasMatch(url)) {
      throw StateError(
        'Local development must not use a production API URL: $url',
      );
    }
    return _stripSlash(url);
  }

  static String _stripSlash(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  static void assertConfigured() {
    final url = apiBaseUrl;
    debugPrint(
      '[AppEnv] Mode=${isLocal ? "LOCAL DEV" : "PRODUCTION"} '
      'APP_ENV=${name.isEmpty ? (isLocal ? "(debug default local)" : "(release default production)") : name} '
      'API=$url',
    );
  }
}

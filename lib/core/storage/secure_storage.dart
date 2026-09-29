import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'auth_refresh_token';
  static const _webSessionHintKey = 'web_cookie_session';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static String? inMemoryToken;
  static String? inMemoryRefreshToken;
  /// Web cookie-session marker (not a secret — cookies hold the tokens).
  static bool webCookieSession = false;

  /// On web and mobile: persist access token to storage.
  Future<void> saveToken(String token, {bool persist = true}) async {
    inMemoryToken = token;
    await _storage.delete(key: _tokenKey);
    if (persist) {
      await _storage.write(key: _tokenKey, value: token);
    }
  }

  Future<void> saveRefreshToken(String? refreshToken, {bool persist = true}) async {
    inMemoryRefreshToken = refreshToken;
    await _storage.delete(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return;
    if (persist) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<void> markWebCookieSession({required bool active, bool persistHint = false}) async {
    webCookieSession = active;
    if (!kIsWeb) return;
    if (active && persistHint) {
      await _storage.write(key: _webSessionHintKey, value: '1');
    } else {
      await _storage.delete(key: _webSessionHintKey);
    }
  }

  Future<bool> hasWebSessionHint() async {
    if (!kIsWeb) return false;
    if (webCookieSession) return true;
    final v = await _storage.read(key: _webSessionHintKey);
    return v == '1';
  }

  Future<String?> getToken() async {
    return inMemoryToken ?? await _storage.read(key: _tokenKey);
  }

  Future<String?> getRefreshToken() async {
    return inMemoryRefreshToken ?? await _storage.read(key: _refreshTokenKey);
  }

  static const _sessionLoginTimeKey = 'session_login_time';
  static const _tokenExpirationHoursKey = 'token_expiration_hours';
  static const _lastActivityTimeKey = 'last_activity_time';

  Future<void> saveSessionLoginTime(DateTime time) async {
    await _storage.write(key: _sessionLoginTimeKey, value: time.millisecondsSinceEpoch.toString());
  }

  Future<DateTime?> getSessionLoginTime() async {
    final str = await _storage.read(key: _sessionLoginTimeKey);
    if (str == null) return null;
    final ms = int.tryParse(str);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveSessionExpirationHours(int hours) async {
    await _storage.write(key: _tokenExpirationHoursKey, value: hours.toString());
  }

  Future<int> getSessionExpirationHours() async {
    final str = await _storage.read(key: _tokenExpirationHoursKey);
    if (str == null) return 8; // Default 8 hours
    return int.tryParse(str) ?? 8;
  }

  Future<void> deleteToken() async {
    inMemoryToken = null;
    inMemoryRefreshToken = null;
    webCookieSession = false;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _webSessionHintKey);
    await _storage.delete(key: _lastActivityTimeKey);
    await _storage.delete(key: _sessionLoginTimeKey);
  }

  Future<void> updateLastActivity() async {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.write(key: _lastActivityTimeKey, value: now);
  }

  Future<bool> isSessionExpired({int? maxDurationHours}) async {
    final loginTime = await getSessionLoginTime();
    // If no login time is recorded yet (e.g. fresh in-flight login), NEVER consider expired!
    if (loginTime == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - loginTime.millisecondsSinceEpoch;

    // Safety guard: if login was within the last 2 minutes, it is physically impossible to be expired.
    // This completely prevents the "2-time login" bug!
    if (elapsed < 120 * 1000) return false;

    final hours = maxDurationHours ?? await getSessionExpirationHours();
    final maxDurationMs = hours * 3600 * 1000;
    return elapsed >= maxDurationMs;
  }

  Future<bool> isSessionExpiredDueToInactivity() async {
    return isSessionExpired();
  }
}

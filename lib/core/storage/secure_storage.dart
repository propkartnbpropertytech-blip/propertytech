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

  Future<void> deleteToken() async {
    inMemoryToken = null;
    inMemoryRefreshToken = null;
    webCookieSession = false;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _webSessionHintKey);
    await _storage.delete(key: 'last_activity_time');
  }

  Future<void> updateLastActivity() async {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    await _storage.write(key: 'last_activity_time', value: now);
  }

  Future<bool> isSessionExpiredDueToInactivity() async {
    final lastTimeStr = await _storage.read(key: 'last_activity_time');
    if (lastTimeStr == null) return false;
    final lastTime = int.tryParse(lastTimeStr);
    if (lastTime == null) return false;
    final diff = DateTime.now().millisecondsSinceEpoch - lastTime;
    // 9 hours in milliseconds = 9 * 60 * 60 * 1000 = 32,400,000 ms
    return diff > 32400000;
  }
}

import 'package:flutter/foundation.dart';

import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/session_cleanup.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();

  Future<UserModel> login(String email, String password, bool rememberMe) async {
    await SessionCleanup.clearLocalSession(clearToken: true);

    final responseData = await _authService.login(
      email,
      password,
      rememberMe: rememberMe,
    );
    final user = UserModel.fromJson(responseData);

    if (user.token == null || user.token!.isEmpty) {
      throw Exception('Login succeeded but no access token was returned.');
    }

    final refresh = _extractRefreshToken(responseData);
    await _secureStorage.saveToken(user.token!, persist: rememberMe);
    if (refresh != null && refresh.isNotEmpty) {
      await _secureStorage.saveRefreshToken(refresh, persist: rememberMe);
    }

    if (kIsWeb) {
      await _secureStorage.markWebCookieSession(
        active: true,
        persistHint: rememberMe,
      );
    }

    // Immediately record session login timestamp and active activity timestamp.
    // This guarantees that router redirect checks will NEVER detect a stale or expired session.
    await _secureStorage.saveSessionLoginTime(DateTime.now());
    await _secureStorage.updateLastActivity();

    final rawData = responseData['data'];
    final expHours = rawData is Map<String, dynamic>
        ? (rawData['tokenExpirationHours'] ?? (rawData['extra'] is Map ? rawData['extra']['tokenExpirationHours'] : null))
        : null;
    if (expHours is int && expHours > 0) {
      await _secureStorage.saveSessionExpirationHours(expHours);
    }

    return user;
  }

  String? _extractRefreshToken(Map<String, dynamic> responseData) {
    final data = responseData['data'];
    if (data is Map<String, dynamic>) {
      return data['refreshToken']?.toString() ?? data['refresh_token']?.toString();
    }
    return responseData['refreshToken']?.toString() ??
        responseData['refresh_token']?.toString();
  }

  Future<bool> refreshSession() async {
    final refresh = await _secureStorage.getRefreshToken();
    try {
      final response = await _authService.refresh(refresh);
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      final access = data['token']?.toString() ?? data['accessToken']?.toString();
      final nextRefresh = data['refreshToken']?.toString() ?? data['refresh_token']?.toString();
      if (access == null || access.isEmpty) return false;

      final hadPersisted = await _secureStorage.getRefreshToken() != null;
      await _secureStorage.saveToken(access, persist: hadPersisted);
      if (nextRefresh != null && nextRefresh.isNotEmpty) {
        await _secureStorage.saveRefreshToken(nextRefresh, persist: hadPersisted);
      }
      if (kIsWeb) {
        await _secureStorage.markWebCookieSession(
          active: true,
          persistHint: await _secureStorage.hasWebSessionHint(),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final responseData = await _authService.getProfile();
      if (kIsWeb) {
        await _secureStorage.markWebCookieSession(active: true);
      }
      return UserModel.fromJson(responseData).copyWith(token: null);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    if (kIsWeb) {
      try {
        await _authService.logout(refreshToken: null);
      } catch (_) {}
      await SessionCleanup.clearLocalSession(clearToken: true);
      return;
    }

    final refresh = await _secureStorage.getRefreshToken();
    try {
      await _authService.logout(refreshToken: refresh);
    } catch (_) {}
    await SessionCleanup.clearLocalSession(clearToken: true);
  }

  Future<String?> getSavedToken() async {
    return await _secureStorage.getToken();
  }

  Future<bool> isAuthenticated() async {
    if (kIsWeb) {
      final mem = await _secureStorage.getToken();
      if (mem != null && mem.isNotEmpty) return true;
      if (SecureStorage.webCookieSession) return true;
      if (await _secureStorage.hasWebSessionHint()) {
        try {
          await _authService.getProfile();
          SecureStorage.webCookieSession = true;
          return true;
        } catch (_) {
          await _secureStorage.markWebCookieSession(active: false);
          return false;
        }
      }
      try {
        await _authService.getProfile();
        SecureStorage.webCookieSession = true;
        return true;
      } catch (_) {
        return false;
      }
    }

    final token = await getSavedToken();
    return token != null && token.isNotEmpty;
  }
}

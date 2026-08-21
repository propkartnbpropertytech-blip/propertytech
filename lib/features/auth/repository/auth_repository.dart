import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_constants.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/storage/session_cleanup.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService = AuthService();
  final SecureStorage _secureStorage = SecureStorage();
  SupabaseClient get _supabase => Supabase.instance.client;

  Future<UserModel> login(String email, String password, bool rememberMe) async {
    await SessionCleanup.clearLocalSession(clearToken: true);

    final responseData = await _authService.login(
      email,
      password,
      rememberMe: rememberMe,
    );
    final user = UserModel.fromJson(responseData);

    if (ApiConstants.useSupabaseDirect) {
      // Supabase handles session storage automatically. No need to call secure storage.
      return user.copyWith(token: null);
    }

    if (kIsWeb) {
      // Prefer HttpOnly cookies (same-origin proxy). Keep access token in memory
      // as fallback when the browser blocks cross-site cookies.
      await _secureStorage.markWebCookieSession(
        active: true,
        persistHint: rememberMe,
      );
      if (user.token != null && user.token!.isNotEmpty) {
        await _secureStorage.saveToken(user.token!, persist: rememberMe);
      }
      return user.copyWith(token: null);
    }

    if (user.token == null || user.token!.isEmpty) {
      throw Exception('Login succeeded but no access token was returned.');
    }

    final refresh = _extractRefreshToken(responseData);
    await _secureStorage.saveToken(user.token!, persist: rememberMe);
    await _secureStorage.saveRefreshToken(refresh, persist: rememberMe);

    return user.copyWith(token: null);
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
    if (ApiConstants.useSupabaseDirect) {
      try {
        final session = _supabase.auth.currentSession;
        if (session == null) return false;
        
        // Supabase Dart SDK manages auto refresh. We check if active.
        return !session.isExpired;
      } catch (_) {
        return false;
      }
    }

    if (kIsWeb) {
      try {
        final response = await _authService.refresh(null);
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final access = data['token']?.toString() ?? data['accessToken']?.toString();
        if (access != null && access.isNotEmpty) {
          await _secureStorage.saveToken(access, persist: false);
        }
        await _secureStorage.markWebCookieSession(
          active: true,
          persistHint: await _secureStorage.hasWebSessionHint(),
        );
        return true;
      } catch (_) {
        return false;
      }
    }

    final refresh = await _secureStorage.getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final response = await _authService.refresh(refresh);
      final data = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      final access = data['token']?.toString() ?? data['accessToken']?.toString();
      final nextRefresh = data['refreshToken']?.toString() ?? data['refresh_token']?.toString();
      if (access == null || access.isEmpty) return false;

      final hadPersistedRefresh = await _secureStorage.getRefreshToken() != null;
      await _secureStorage.saveToken(access, persist: hadPersistedRefresh);
      if (nextRefresh != null && nextRefresh.isNotEmpty) {
        await _secureStorage.saveRefreshToken(nextRefresh, persist: hadPersistedRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final responseData = await _authService.getProfile();
      if (kIsWeb && !ApiConstants.useSupabaseDirect) {
        await _secureStorage.markWebCookieSession(active: true);
      }
      return UserModel.fromJson(responseData).copyWith(token: null);
    } catch (e) {
      await logout();
      rethrow;
    }
  }

  Future<void> logout() async {
    if (ApiConstants.useSupabaseDirect) {
      try {
        await _authService.logout();
      } catch (_) {}
      await SessionCleanup.clearLocalSession(clearToken: true);
      return;
    }

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
    if (ApiConstants.useSupabaseDirect) {
      return _supabase.auth.currentSession?.accessToken;
    }
    return await _secureStorage.getToken();
  }

  Future<bool> isAuthenticated() async {
    if (ApiConstants.useSupabaseDirect) {
      final session = _supabase.auth.currentSession;
      if (session != null && !session.isExpired) {
        return true;
      }
      // Wait for auth to initialize or restore session
      final restoredSession = _supabase.auth.currentSession;
      return restoredSession != null;
    }

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

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/sync_manager.dart';
import 'isar_service.dart';
import 'local_repositories.dart';
import 'secure_storage.dart';

/// Clears all user-scoped local state so the next login cannot see prior data.
/// Theme preference is intentionally preserved.
class SessionCleanup {
  static const _userScopedPrefsKeys = <String>[
    'cached_properties',
    'cached_requirements',
    'cached_lookups',
    'shortlisted_properties',
    'last_lookup_version',
  ];

  static final StreamController<void> _forcedLogoutController =
      StreamController<void>.broadcast();

  /// Fired when the session is invalidated (e.g. HTTP 401).
  static Stream<void> get onForcedLogout => _forcedLogoutController.stream;

  static void notifyForcedLogout() {
    if (!_forcedLogoutController.isClosed) {
      _forcedLogoutController.add(null);
    }
  }

  /// Wipe tokens, Isar/web caches, sync state, and user-scoped prefs.
  static Future<void> clearLocalSession({bool clearToken = true}) async {
    try {
      await SyncManager().disconnect();
    } catch (_) {}

    SyncManager().isSyncCompleted = false;
    SyncManager().isSyncing.value = false;

    if (clearToken) {
      try {
        await SecureStorage().deleteToken();
      } catch (_) {}
    }

    _clearInMemoryCaches();

    try {
      if (!kIsWeb) {
        await IsarService().clearAll();
      }
    } catch (e) {
      debugPrint('SessionCleanup: Isar clear failed: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _userScopedPrefsKeys) {
        await prefs.remove(key);
      }
      // Best-effort: any other shortlist / recycle keys
      for (final key in prefs.getKeys()) {
        if (key.startsWith('cached_') ||
            key.startsWith('shortlisted_') ||
            key.startsWith('recycle_') ||
            key == 'auto_delete_days') {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('SessionCleanup: prefs clear failed: $e');
    }
  }

  static void _clearInMemoryCaches() {
    PropertyLocalRepository.inMemory.clear();
    RequirementLocalRepository.inMemory.clear();
    FollowupLocalRepository.inMemory.clear();
    BuilderLocalRepository.inMemory.clear();
    OwnerLocalRepository.inMemory.clear();
    LookupLocalRepository.inMemory.clear();
    OutboxLocalRepository.inMemory.clear();
    ClientLocalRepository.inMemory.clear();
  }
}

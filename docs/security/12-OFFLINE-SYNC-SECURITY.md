# 12 — OFFLINE SYNC & OUTBOX DATA SECURITY

## 1. Offline-First Security Challenges

As an offline-first enterprise mobile application, PropKart caches data locally in Isar database collections and buffers mutations in an Outbox queue. This creates distinct security challenges:
1. Shared device contamination when users switch accounts.
2. Mutation replay under the wrong identity.
3. Offline tamper vulnerability of local records.

---

## 2. In-Memory and Storage Purge Protocol (`SessionCleanup`)

To prevent data contamination across users on the same physical device:
```dart
class SessionCleanup {
  static Future<void> clearLocalSession({bool clearToken = true}) async {
    // 1. Terminate background coordinators
    TelecallerShiftManager.instance.dispose();
    PeriodicWorkCoordinator.instance.onLogout();
    await SyncManager().disconnect();

    // 2. Wipe secure auth credentials
    if (clearToken) {
      await SecureStorage().deleteToken();
    }

    // 3. Purge all in-memory repository caches
    PropertyLocalRepository.inMemory.clear();
    RequirementLocalRepository.inMemory.clear();
    FollowupLocalRepository.inMemory.clear();
    BuilderLocalRepository.inMemory.clear();
    OwnerLocalRepository.inMemory.clear();
    LookupLocalRepository.inMemory.clear();
    OutboxLocalRepository.inMemory.clear();
    ClientLocalRepository.inMemory.clear();

    // 4. Wipe physical local database
    if (!kIsWeb) {
      await IsarService().clearAll();
    } else {
      await WebStorage().clearAllStores();
    }

    // 5. Purge user-scoped preferences & shortlists
    final prefs = await SharedPreferences.getInstance();
    for (final key in _userScopedPrefsKeys) {
      await prefs.remove(key);
    }
  }
}
```

---

## 3. Outbox Mutation Integrity & Idempotency

1. **Identity & Tenant Binding**:
   - Outbox operations (`OutboxLocal`) record the specific API endpoint, HTTP method, and serialized mutation JSON.
   - Operations are tagged with a unique, cryptographically random `id` and client `deviceId`.
2. **Replay Prevention on User Switch**:
   - Calling `clearLocalSession()` completely clears `OutboxLocalRepository`, ensuring mutations queued by User A are never delivered under User B's token.
3. **Server-Side Idempotency**:
   - Handled via `X-Idempotency-Key` / request correlation, preventing duplicate creations if a network retry occurs.

---

## 4. Verification Evidence

- `test/security/sync_security_test.dart`: Verifies that `SessionCleanup` resets sync states and disconnects socket replication.
- `test/security/outbox_security_test.dart`: Verifies that outbox items cannot survive user logout and that payload entity integrity is preserved.
- `test/security/cache_security_test.dart`: Verifies that all 8 in-memory repositories are cleared during cleanup.

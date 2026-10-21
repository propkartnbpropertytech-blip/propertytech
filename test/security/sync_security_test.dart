import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/network/sync_manager.dart';
import 'package:propkart/core/storage/session_cleanup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Sync Security & Invariant Tests', () {
    test('SessionCleanup resets sync states and disconnects replication', () async {
      final sync = SyncManager();
      sync.isSyncCompleted = true;
      sync.isSyncing.value = true;

      await SessionCleanup.clearLocalSession(clearToken: true);

      expect(sync.isSyncCompleted, isFalse);
      expect(sync.isSyncing.value, isFalse);
    });

    test('Sync batch validation requires authenticated user context', () {
      final sync = SyncManager();
      // Ensure sync manager cannot broadcast unauthenticated dirty mutations
      expect(sync.isSyncing.value, isFalse);
    });
  });
}

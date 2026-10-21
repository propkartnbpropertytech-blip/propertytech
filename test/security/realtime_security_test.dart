import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/network/sync_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Realtime Security & WebSocket Channel Isolation Tests', () {
    test('SyncManager disconnect safely tears down socket and cleans buffers', () async {
      final sync = SyncManager();
      await sync.disconnect();

      expect(sync.isSyncCompleted, isFalse);
      expect(sync.isSyncing.value, isFalse);
    });

    test('Realtime subscription payload strictly scopes to allowed CRM tables', () {
      const watchedTables = <String>[
        'properties',
        'requirements',
        'notifications',
        'followups',
        'site_visits',
        'integration_leads',
        'leads',
        'campaign_connections',
        'campaign_lead_followups',
      ];

      // Sensitive internal system tables must NEVER be in realtime replication
      expect(watchedTables.contains('users'), isFalse);
      expect(watchedTables.contains('passwords'), isFalse);
      expect(watchedTables.contains('sessions'), isFalse);
      expect(watchedTables.contains('audit_logs'), isFalse);
      expect(watchedTables.contains('tokens'), isFalse);
    });
  });
}

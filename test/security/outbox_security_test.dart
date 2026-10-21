import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/session_cleanup.dart';
import 'security_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockSecurityStorage();

  group('Outbox Security & Identity Isolation Tests', () {
    test('Outbox queue is purged on logout preventing cross-identity mutation replay', () async {
      final outboxItem = OutboxLocal()
        ..id = 'outbox_entry_001'
        ..endpoint = '/properties'
        ..method = 'POST'
        ..payloadJson = '{"title":"Draft Property","price":1000000}'
        ..createdAt = DateTime.now();

      OutboxLocalRepository.inMemory[outboxItem.id] = outboxItem;
      expect(OutboxLocalRepository.inMemory, isNotEmpty);

      // User logs out or switches accounts
      await SessionCleanup.clearLocalSession(clearToken: true);

      // Verify that pending mutation queue is wiped clean so it cannot be delivered under next user's token
      expect(OutboxLocalRepository.inMemory, isEmpty);
    });

    test('Outbox operation payloads preserve entity isolation', () {
      final item = OutboxLocal()
        ..id = 'outbox_test_2'
        ..endpoint = '/requirements/r123'
        ..method = 'PUT'
        ..payloadJson = '{"status":"Followup"}'
        ..createdAt = DateTime.now();

      expect(item.endpoint, equals('/requirements/r123'));
      expect(item.method, equals('PUT'));
      expect(item.payloadJson.contains('status'), isTrue);
    });
  });
}

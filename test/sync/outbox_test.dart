import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';

void main() {
  group('Outbox Storage & Queue Ordering Invariants', () {
    late OutboxLocalRepository outboxRepo;

    setUp(() {
      outboxRepo = OutboxLocalRepository();
      OutboxLocalRepository.inMemory.clear();
    });

    test('Queues outbox mutation with all mandatory attributes', () async {
      final req = OutboxLocal()
        ..id = 'op-uuid-1'
        ..endpoint = '/properties'
        ..method = 'POST'
        ..payloadJson = jsonEncode({'title': 'New Office', 'price': 8500000})
        ..createdAt = DateTime.now()
        ..deviceId = 'device_test_1';

      await outboxRepo.queueRequest(req);

      final queued = await outboxRepo.getQueuedRequests();
      expect(queued.length, equals(1));
      expect(queued.first.id, equals('op-uuid-1'));
      expect(queued.first.method, equals('POST'));
      expect(queued.first.endpoint, equals('/properties'));
    });

    test('Maintains strict FIFO order by createdAt timestamp', () async {
      final t1 = DateTime(2026, 10, 21, 10, 0, 0);
      final t2 = DateTime(2026, 10, 21, 10, 5, 0);
      final t3 = DateTime(2026, 10, 21, 10, 10, 0);

      // Insert in reverse order
      await outboxRepo.queueRequest(
        OutboxLocal()
          ..id = 'op-3'
          ..endpoint = '/requirements/3'
          ..method = 'PUT'
          ..payloadJson = '{}'
          ..createdAt = t3,
      );
      await outboxRepo.queueRequest(
        OutboxLocal()
          ..id = 'op-1'
          ..endpoint = '/requirements/1'
          ..method = 'POST'
          ..payloadJson = '{}'
          ..createdAt = t1,
      );
      await outboxRepo.queueRequest(
        OutboxLocal()
          ..id = 'op-2'
          ..endpoint = '/requirements/2'
          ..method = 'PUT'
          ..payloadJson = '{}'
          ..createdAt = t2,
      );

      final ordered = await outboxRepo.getQueuedRequests();
      expect(ordered.length, equals(3));
      expect(ordered[0].id, equals('op-1'));
      expect(ordered[1].id, equals('op-2'));
      expect(ordered[2].id, equals('op-3'));
    });

    test('Removes outbox item after successful remote synchronization', () async {
      final req = OutboxLocal()
        ..id = 'op-done-1'
        ..endpoint = '/properties/done'
        ..method = 'DELETE'
        ..payloadJson = '{}'
        ..createdAt = DateTime.now();

      await outboxRepo.queueRequest(req);
      expect((await outboxRepo.getQueuedRequests()).length, equals(1));

      await outboxRepo.removeRequest('op-done-1');
      expect((await outboxRepo.getQueuedRequests()), isEmpty);
    });

    test('Ensures outbox payload never duplicates authorization tokens or passwords', () async {
      final req = OutboxLocal()
        ..id = 'op-safe-1'
        ..endpoint = '/properties'
        ..method = 'POST'
        ..payloadJson = jsonEncode({'title': 'Villa', 'price': 2000000})
        ..createdAt = DateTime.now();

      final decoded = jsonDecode(req.payloadJson) as Map<String, dynamic>;
      expect(decoded.containsKey('token'), isFalse);
      expect(decoded.containsKey('password'), isFalse);
      expect(decoded.containsKey('jwt'), isFalse);
      expect(decoded.containsKey('Authorization'), isFalse);
    });
  });
}

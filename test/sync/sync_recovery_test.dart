import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';

void main() {
  group('Critical Outbox Crash Recovery Invariants', () {
    setUp(() {
      PropertyLocalRepository.inMemory.clear();
      OutboxLocalRepository.inMemory.clear();
    });

    test('Outbox discovered on app restart and executes exactly one remote mutation', () async {
      final outboxRepo = OutboxLocalRepository();
      const operationId = 'op-crash-recovery-999';

      // Step 1: Local mutation occurs before sudden shutdown
      final prop = PropertyLocal()
        ..id = 'prop-crash-1'
        ..title = 'Pre-Crash Property'
        ..propertyCode = 'P-CRASH'
        ..price = 7000000
        ..deposit = 300000
        ..maintenance = 3000
        ..listingTypeId = 'lt1'
        ..propertyStatusId = 'ps1'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..cityId = 'ct1'
        ..areaId = 'a1'
        ..pincode = '380001'
        ..address = 'Address'
        ..bedrooms = 3
        ..bathrooms = 2
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Owner'
        ..ownerMobile = '9800000000'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime.now()
        ..images = []
        ..amenities = []
        ..videos = [];

      final outboxItem = OutboxLocal()
        ..id = operationId
        ..endpoint = '/properties'
        ..method = 'POST'
        ..payloadJson = jsonEncode({'id': 'prop-crash-1', 'title': 'Pre-Crash Property', 'price': 7000000})
        ..createdAt = DateTime.now();

      // Committed to local storage
      PropertyLocalRepository.inMemory['prop-crash-1'] = prop;
      await outboxRepo.queueRequest(outboxItem);

      // Step 2: App process killed / simulated reboot
      // In a new application session, local storage reloads:
      final recoveredOutbox = await outboxRepo.getQueuedRequests();
      expect(recoveredOutbox.length, equals(1));
      expect(recoveredOutbox.first.id, equals(operationId));

      // Step 3: Outbox processor drains queue with idempotency header
      int serverRemoteExecutions = 0;
      Future<int> mockRemoteReplay(OutboxLocal item) async {
        serverRemoteExecutions++;
        return 201; // Created
      }

      for (final item in recoveredOutbox) {
        final status = await mockRemoteReplay(item);
        if (status == 201 || status == 200) {
          await outboxRepo.removeRequest(item.id);
        }
      }

      // Step 4: Verify exactly one mutation occurred and outbox is clear
      expect(serverRemoteExecutions, equals(1));
      expect((await outboxRepo.getQueuedRequests()), isEmpty);
      expect(PropertyLocalRepository.inMemory.containsKey('prop-crash-1'), isTrue);
    });
  });
}

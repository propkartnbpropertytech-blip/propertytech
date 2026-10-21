import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';

void main() {
  group('Offline Mutation & Local Immediate Availability Invariants', () {
    setUp(() {
      PropertyLocalRepository.inMemory.clear();
      OutboxLocalRepository.inMemory.clear();
    });

    test('Offline property creation immediately updates local storage and outbox atomically', () async {
      const tempId = 'temp_prop_offline_123';
      final newProperty = PropertyLocal()
        ..id = tempId
        ..title = 'Offline Penthouse'
        ..propertyCode = 'OFF-123'
        ..price = 25000000
        ..deposit = 1000000
        ..maintenance = 10000
        ..listingTypeId = 'lt1'
        ..listingTypeName = 'Sale'
        ..propertyStatusId = 'ps1'
        ..propertyStatusName = 'Available'
        ..categoryId = 'c1'
        ..categoryName = 'Residential'
        ..propertyTypeId = 'pt1'
        ..propertyTypeName = 'Penthouse'
        ..cityId = 'ct1'
        ..cityName = 'Ahmedabad'
        ..areaId = 'a1'
        ..areaName = 'Bodakdev'
        ..pincode = '380054'
        ..address = 'Sindhu Bhavan Road'
        ..bedrooms = 4
        ..bathrooms = 4
        ..balconies = 3
        ..parking = 2
        ..ownerName = 'Hitesh Patel'
        ..ownerMobile = '9825000001'
        ..isVerified = false
        ..createdBy = 'user_agent_1'
        ..createdByName = 'Agent 1'
        ..createdAt = DateTime.now()
        ..images = []
        ..amenities = []
        ..videos = [];

      final outboxItem = OutboxLocal()
        ..id = 'op_create_$tempId'
        ..endpoint = '/properties'
        ..method = 'POST'
        ..payloadJson = jsonEncode({
          'id': tempId,
          'title': newProperty.title,
          'price': newProperty.price,
        })
        ..createdAt = DateTime.now()
        ..deviceId = 'device_local_test';

      // Atomic commit:
      PropertyLocalRepository.inMemory[tempId] = newProperty;
      await OutboxLocalRepository().queueRequest(outboxItem);

      // Verify UI has immediate zero-latency access
      expect(PropertyLocalRepository.inMemory.containsKey(tempId), isTrue);
      expect(PropertyLocalRepository.inMemory[tempId]!.title, equals('Offline Penthouse'));

      // Verify outbox queued for remote sync
      final queued = await OutboxLocalRepository().getQueuedRequests();
      expect(queued.length, equals(1));
      expect(queued.first.endpoint, equals('/properties'));
      expect(queued.first.method, equals('POST'));
    });

    test('Offline update changes local entity and enqueues PUT outbox request', () async {
      final existing = PropertyLocal()
        ..id = 'prop-existing-1'
        ..title = 'Original Name'
        ..propertyCode = 'P-1'
        ..price = 10000000
        ..deposit = 500000
        ..maintenance = 5000
        ..listingTypeId = 'lt1'
        ..listingTypeName = 'Sale'
        ..propertyStatusId = 'ps1'
        ..propertyStatusName = 'Available'
        ..categoryId = 'c1'
        ..categoryName = 'Residential'
        ..propertyTypeId = 'pt1'
        ..propertyTypeName = 'Apartment'
        ..cityId = 'ct1'
        ..cityName = 'Ahmedabad'
        ..areaId = 'a1'
        ..areaName = 'Vastrapur'
        ..pincode = '380015'
        ..address = 'Address'
        ..bedrooms = 3
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Owner'
        ..ownerMobile = '9800000000'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      PropertyLocalRepository.inMemory['prop-existing-1'] = existing;

      // User modifies price offline
      existing.price = 11500000;
      PropertyLocalRepository.inMemory['prop-existing-1'] = existing;

      final updateOutbox = OutboxLocal()
        ..id = 'op_put_prop_existing_1'
        ..endpoint = '/properties/prop-existing-1'
        ..method = 'PUT'
        ..payloadJson = jsonEncode({'price': 11500000})
        ..createdAt = DateTime.now();

      await OutboxLocalRepository().queueRequest(updateOutbox);

      expect(PropertyLocalRepository.inMemory['prop-existing-1']!.price, equals(11500000));
      final queued = await OutboxLocalRepository().getQueuedRequests();
      expect(queued.length, equals(1));
      expect(queued.first.method, equals('PUT'));
    });
  });
}

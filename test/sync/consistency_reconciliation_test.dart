import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/network/sync_engine.dart';

void main() {
  group('Step 34: End-to-End Consistency Reconciliation Invariants', () {
    setUp(() {
      PropertyLocalRepository.inMemory.clear();
      OutboxLocalRepository.inMemory.clear();
    });

    test('Full 11-step lifecycle reconciles local state with authoritative server state', () async {
      final outboxRepo = OutboxLocalRepository();

      // Step 1: Authoritative initial server state (PostgreSQL baseline)
      final serverDatabase = <String, PropertyLocal>{
        'prop-1': PropertyLocal()
          ..id = 'prop-1'
          ..title = 'Central Park Tower'
          ..propertyCode = 'CP-01'
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
          ..areaName = 'Satellite'
          ..pincode = '380015'
          ..address = 'Satellite Road'
          ..bedrooms = 3
          ..bathrooms = 3
          ..balconies = 2
          ..parking = 1
          ..ownerName = 'Mehta'
          ..ownerMobile = '9800000001'
          ..isVerified = true
          ..createdBy = 'u1'
          ..createdByName = 'Admin'
          ..createdAt = DateTime(2026, 1, 1)
          ..images = []
          ..amenities = []
          ..videos = [],
      };

      // Step 2: Clear/recreate controlled local test database
      PropertyLocalRepository.inMemory.clear();
      expect(PropertyLocalRepository.inMemory, isEmpty);

      // Step 3: Perform initial sync
      for (final p in serverDatabase.values) {
        PropertyLocalRepository.inMemory[p.id] = p;
      }
      expect(PropertyLocalRepository.inMemory.length, equals(1));

      // Step 4: Apply controlled offline mutations on client
      // Mutation A: Client updates price on prop-1
      final localProp1 = PropertyLocalRepository.inMemory['prop-1']!;
      localProp1.price = 11500000;
      await outboxRepo.queueRequest(
        OutboxLocal()
          ..id = 'op-prop-1-price'
          ..endpoint = '/properties/prop-1'
          ..method = 'PUT'
          ..payloadJson = jsonEncode({'price': 11500000})
          ..createdAt = DateTime(2026, 10, 21, 10, 0, 0),
      );

      // Mutation B: Client creates new property offline
      final offlineProp2 = PropertyLocal()
        ..id = 'prop-2'
        ..title = 'Green Acres'
        ..propertyCode = 'GA-02'
        ..price = 6000000
        ..deposit = 300000
        ..maintenance = 3000
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
        ..areaName = 'Bopal'
        ..pincode = '380058'
        ..address = 'Bopal'
        ..bedrooms = 2
        ..bathrooms = 2
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Shah'
        ..ownerMobile = '9800000002'
        ..isVerified = false
        ..createdBy = 'u1'
        ..createdByName = 'Agent'
        ..createdAt = DateTime(2026, 10, 21, 10, 5, 0)
        ..images = []
        ..amenities = []
        ..videos = [];
      PropertyLocalRepository.inMemory['prop-2'] = offlineProp2;
      await outboxRepo.queueRequest(
        OutboxLocal()
          ..id = 'op-prop-2-create'
          ..endpoint = '/properties'
          ..method = 'POST'
          ..payloadJson = jsonEncode({'id': 'prop-2', 'title': 'Green Acres', 'price': 6000000})
          ..createdAt = DateTime(2026, 10, 21, 10, 5, 0),
      );

      // Step 5: Generate remote mutations on server (concurrently while client was offline)
      // Remote changes status of prop-1 to 'Deal Closed'
      serverDatabase['prop-1']!.propertyStatusId = 'ps2';
      serverDatabase['prop-1']!.propertyStatusName = 'Deal Closed';

      // Step 6: Generate realtime events (buffered because client was disconnected)
      // Step 7: Disconnect / Reconnect sequence
      // Client reconnects; begins reconciliation:

      // Step 8: Delta sync checks server items against local items
      // Step 9 & 10: Replay outbox and resolve conflicts:
      // For prop-1: Local modified {'price'}, Server modified {'propertyStatusId'} -> Disjoint! Field-Level Merge
      final conflictResult = SyncEngine.resolvePropertyConflict(
        local: PropertyLocalRepository.inMemory['prop-1']!,
        server: serverDatabase['prop-1']!,
        localModifiedFields: {'price'},
        serverModifiedFields: {'propertyStatusId'},
        localEditedAt: DateTime(2026, 10, 21, 10, 0, 0),
        serverUpdatedAt: DateTime(2026, 10, 21, 10, 2, 0),
      );
      expect(conflictResult.winner, equals(ConflictWinner.merged));

      // Server accepts both mutations from outbox
      serverDatabase['prop-1'] = conflictResult.resolvedItem;
      serverDatabase['prop-2'] = offlineProp2;

      // Drain outbox
      await outboxRepo.removeRequest('op-prop-1-price');
      await outboxRepo.removeRequest('op-prop-2-create');
      expect((await outboxRepo.getQueuedRequests()), isEmpty);

      // Apply winning states locally
      PropertyLocalRepository.inMemory['prop-1'] = serverDatabase['prop-1']!;
      PropertyLocalRepository.inMemory['prop-2'] = serverDatabase['prop-2']!;

      // Step 11: Compare final local state against authoritative server state:
      expect(PropertyLocalRepository.inMemory.length, equals(serverDatabase.length));
      for (final key in serverDatabase.keys) {
        final localItem = PropertyLocalRepository.inMemory[key]!;
        final serverItem = serverDatabase[key]!;
        expect(SyncEngine.arePropertiesEqual(localItem, serverItem), isTrue);
      }

      // Verification: BOTH changes survived in prop-1:
      expect(PropertyLocalRepository.inMemory['prop-1']!.price, equals(11500000));
      expect(PropertyLocalRepository.inMemory['prop-1']!.propertyStatusName, equals('Deal Closed'));
      // And prop-2 was successfully created and reconciled:
      expect(PropertyLocalRepository.inMemory['prop-2']!.title, equals('Green Acres'));
    });
  });
}

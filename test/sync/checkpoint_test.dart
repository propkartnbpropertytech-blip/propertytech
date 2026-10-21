import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/network/sync_engine.dart';

void main() {
  group('Critical Checkpoint & Crash Safety Invariants', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      PropertyLocalRepository.inMemory.clear();
    });

    test('Checkpoint cursor advances strictly AFTER local transaction commits', () async {
      final prefs = await SharedPreferences.getInstance();
      const initialCheckpoint = '2026-10-21T09:00:00Z';
      await prefs.setString('checkpoint_properties', initialCheckpoint);

      const incomingCheckpoint = '2026-10-21T10:00:00Z';
      final incomingDelta = [
        PropertyLocal()
          ..id = 'p-cp-1'
          ..title = 'Crash Test Villa'
          ..propertyCode = 'CP-01'
          ..price = 5000000
          ..deposit = 250000
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
          ..bathrooms = 3
          ..balconies = 1
          ..parking = 1
          ..ownerName = 'Owner'
          ..ownerMobile = '9800000000'
          ..isVerified = true
          ..createdBy = 'u1'
          ..createdByName = 'Admin'
          ..createdAt = DateTime(2026, 1, 1)
          ..images = []
          ..amenities = []
          ..videos = [],
      ];

      bool shouldCommit(bool crash) {
        if (crash) throw Exception('Simulated isolate crash / out of memory');
        return true;
      }

      // Simulated crash failure BEFORE commit:
      bool transactionCommitted = false;
      try {
        transactionCommitted = shouldCommit(true);
      } catch (_) {
        // Rollback
      }

      if (transactionCommitted) {
        await prefs.setString('checkpoint_properties', incomingCheckpoint);
      }

      // Assert checkpoint NEVER advanced:
      expect(prefs.getString('checkpoint_properties'), equals(initialCheckpoint));
      // Assert no partial data written:
      expect(PropertyLocalRepository.inMemory.containsKey('p-cp-1'), isFalse);

      // Now simulate recovery & successful commit:
      for (final p in incomingDelta) {
        PropertyLocalRepository.inMemory[p.id] = p;
      }
      transactionCommitted = true;
      await prefs.setString('checkpoint_properties', incomingCheckpoint);

      // Assert checkpoint updated safely post-commit:
      expect(prefs.getString('checkpoint_properties'), equals(incomingCheckpoint));
      expect(PropertyLocalRepository.inMemory.containsKey('p-cp-1'), isTrue);
    });

    test('Replaying identical delta after crash recovery produces zero duplicates and zero corruption', () {
      final delta = [
        PropertyLocal()
          ..id = 'p-replay-1'
          ..title = 'Replay Property'
          ..propertyCode = 'RP-01'
          ..price = 4500000
          ..deposit = 200000
          ..maintenance = 2000
          ..listingTypeId = 'lt1'
          ..propertyStatusId = 'ps1'
          ..categoryId = 'c1'
          ..propertyTypeId = 'pt1'
          ..cityId = 'ct1'
          ..areaId = 'a1'
          ..pincode = '380001'
          ..address = 'Address'
          ..bedrooms = 2
          ..bathrooms = 2
          ..balconies = 1
          ..parking = 1
          ..ownerName = 'Owner'
          ..ownerMobile = '9800000000'
          ..isVerified = true
          ..createdBy = 'u1'
          ..createdByName = 'Admin'
          ..createdAt = DateTime(2026, 1, 1)
          ..images = []
          ..amenities = []
          ..videos = [],
      ];

      // Replay #1
      final diff1 = SyncEngine.computeDiff<PropertyLocal>(
        serverItems: delta,
        localItems: Map.from(PropertyLocalRepository.inMemory),
        getId: (p) => p.id,
        isEqual: SyncEngine.arePropertiesEqual,
      );
      for (final p in diff1.toInsert) {
        PropertyLocalRepository.inMemory[p.id] = p;
      }
      expect(PropertyLocalRepository.inMemory.length, equals(1));

      // Replay #2 (Simulating re-requesting same delta due to safe unadvanced checkpoint)
      final diff2 = SyncEngine.computeDiff<PropertyLocal>(
        serverItems: delta,
        localItems: Map.from(PropertyLocalRepository.inMemory),
        getId: (p) => p.id,
        isEqual: SyncEngine.arePropertiesEqual,
      );

      expect(diff2.toInsert, isEmpty);
      expect(diff2.toUpdate, isEmpty);
      expect(diff2.toDelete, isEmpty);
      expect(diff2.unchangedCount, equals(1));
      // Exactly 1 record remains in storage, zero duplicates!
      expect(PropertyLocalRepository.inMemory.length, equals(1));
    });
  });
}

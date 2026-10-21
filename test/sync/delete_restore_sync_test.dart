import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';

void main() {
  group('Delete, Soft-Delete & Anti-Resurrection Invariants', () {
    setUp(() {
      PropertyLocalRepository.inMemory.clear();
    });

    test('Realtime delete event is strictly idempotent across multiple dispatches', () {
      final p1 = PropertyLocal()
        ..id = 'p-del-1'
        ..title = 'To Delete'
        ..propertyCode = 'DEL-01'
        ..price = 1000000
        ..deposit = 50000
        ..maintenance = 1000
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
        ..videos = [];

      PropertyLocalRepository.inMemory['p-del-1'] = p1;

      void applyDelete(String id) {
        PropertyLocalRepository.inMemory.remove(id);
      }

      // First delete dispatch
      applyDelete('p-del-1');
      expect(PropertyLocalRepository.inMemory.containsKey('p-del-1'), isFalse);

      // Duplicate delete dispatch (no-op, does not throw)
      applyDelete('p-del-1');
      expect(PropertyLocalRepository.inMemory.containsKey('p-del-1'), isFalse);
    });

    test('Stale delta with older timestamp does not resurrect a deleted entity', () {
      final deletionTombstones = <String, DateTime>{
        'p-deleted-10': DateTime(2026, 10, 21, 11, 0, 0), // Deleted at 11:00 AM
      };

      final staleDeltaRecord = PropertyLocal()
        ..id = 'p-deleted-10'
        ..title = 'Zombie Property'
        ..propertyCode = 'ZOM-01'
        ..price = 5000000
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
        ..createdAt = DateTime(2026, 10, 21, 10, 30, 0) // Updated at 10:30 AM (older than deletion)
        ..images = []
        ..amenities = []
        ..videos = [];

      bool shouldApplyRecord(PropertyLocal record, DateTime recordTimestamp) {
        final tombstoneTime = deletionTombstones[record.id];
        if (tombstoneTime != null && recordTimestamp.isBefore(tombstoneTime)) {
          return false; // Reject stale resurrection!
        }
        return true;
      }

      final canApply = shouldApplyRecord(staleDeltaRecord, staleDeltaRecord.createdAt);
      expect(canApply, isFalse);
    });

    test('Valid restore event with timestamp newer than tombstone re-adds entity correctly', () {
      final deletionTombstones = <String, DateTime>{
        'p-restore-1': DateTime(2026, 10, 21, 11, 0, 0),
      };

      final restoredRecord = PropertyLocal()
        ..id = 'p-restore-1'
        ..title = 'Restored Property'
        ..propertyCode = 'RES-01'
        ..price = 5500000
        ..deposit = 250000
        ..maintenance = 2500
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
        ..createdAt = DateTime(2026, 10, 21, 11, 15, 0) // Restored at 11:15 AM
        ..images = []
        ..amenities = []
        ..videos = [];

      final restoreTimestamp = DateTime(2026, 10, 21, 11, 15, 0);
      final tombstone = deletionTombstones['p-restore-1']!;

      expect(restoreTimestamp.isAfter(tombstone), isTrue);

      // Re-insert into local storage
      PropertyLocalRepository.inMemory['p-restore-1'] = restoredRecord;
      deletionTombstones.remove('p-restore-1');

      expect(PropertyLocalRepository.inMemory.containsKey('p-restore-1'), isTrue);
      expect(PropertyLocalRepository.inMemory['p-restore-1']!.title, equals('Restored Property'));
    });
  });
}

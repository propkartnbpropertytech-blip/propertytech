import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/network/sync_engine.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/local_repositories.dart';

void main() {
  group('Delta Sync Incremental Engine Invariants', () {
    setUp(() {
      PropertyLocalRepository.inMemory.clear();
      RequirementLocalRepository.inMemory.clear();
    });

    test('Identifies purely incremental changes without clearing existing tables', () {
      final p1 = PropertyLocal()
        ..id = 'prop-1'
        ..title = 'Original Title'
        ..propertyCode = 'P-100'
        ..price = 1000000
        ..deposit = 50000
        ..maintenance = 2000
        ..listingTypeId = 'lt1'
        ..propertyStatusId = 'ps1'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..cityId = 'ct1'
        ..areaId = 'a1'
        ..pincode = '380001'
        ..address = 'Address 1'
        ..bedrooms = 3
        ..bathrooms = 2
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

      PropertyLocalRepository.inMemory['prop-1'] = p1;

      // Incoming delta with updated price
      final p1Server = PropertyLocal()
        ..id = 'prop-1'
        ..title = 'Original Title'
        ..propertyCode = 'P-100'
        ..price = 1250000 // Server modified
        ..deposit = 50000
        ..maintenance = 2000
        ..listingTypeId = 'lt1'
        ..propertyStatusId = 'ps1'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..cityId = 'ct1'
        ..areaId = 'a1'
        ..pincode = '380001'
        ..address = 'Address 1'
        ..bedrooms = 3
        ..bathrooms = 2
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

      final diff = SyncEngine.computeDiff<PropertyLocal>(
        serverItems: [p1Server],
        localItems: Map.from(PropertyLocalRepository.inMemory),
        getId: (p) => p.id,
        isEqual: SyncEngine.arePropertiesEqual,
      );

      expect(diff.toInsert, isEmpty);
      expect(diff.toUpdate.length, equals(1));
      expect(diff.toUpdate.first.price, equals(1250000));
      expect(diff.toDelete, isEmpty);
      expect(diff.unchangedCount, equals(0));
    });

    test('Zero mutations produced when server delta matches local cache exactly', () {
      final p1 = PropertyLocal()
        ..id = 'prop-1'
        ..title = 'Title'
        ..propertyCode = 'P-100'
        ..price = 1000000
        ..deposit = 50000
        ..maintenance = 2000
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
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      PropertyLocalRepository.inMemory['prop-1'] = p1;

      final diff = SyncEngine.computeDiff<PropertyLocal>(
        serverItems: [p1],
        localItems: Map.from(PropertyLocalRepository.inMemory),
        getId: (p) => p.id,
        isEqual: SyncEngine.arePropertiesEqual,
      );

      expect(diff.hasChanges, isFalse);
      expect(diff.totalChanges, equals(0));
      expect(diff.unchangedCount, equals(1));
    });

    test('Preserves offline-created pending outbox records from server deletion sweep', () {
      final localCreatedOffline = PropertyLocal()
        ..id = 'local-offline-uuid-99'
        ..title = 'Offline Property'
        ..propertyCode = 'OFF-99'
        ..price = 900000
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
        ..bathrooms = 1
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Owner'
        ..ownerMobile = '9800000000'
        ..isVerified = false
        ..createdBy = 'u1'
        ..createdByName = 'Agent'
        ..createdAt = DateTime.now()
        ..images = []
        ..amenities = []
        ..videos = [];

      PropertyLocalRepository.inMemory['local-offline-uuid-99'] = localCreatedOffline;

      // Server list does not yet have this record because it hasn't synced yet
      final serverItems = <PropertyLocal>[];

      // With pendingOutboxIds protecting it:
      final diff = SyncEngine.computeDiff<PropertyLocal>(
        serverItems: serverItems,
        localItems: Map.from(PropertyLocalRepository.inMemory),
        getId: (p) => p.id,
        isEqual: SyncEngine.arePropertiesEqual,
        pendingOutboxIds: {'local-offline-uuid-99'},
      );

      expect(diff.toDelete, isEmpty);
    });

    test('Preserves local isarId to enable O(1) in-place row replacement', () {
      final local = RequirementLocal()
        ..id = 'req-1'
        ..clientName = 'Old Client'
        ..clientMobile = '9800000000'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..minBudget = 1000000
        ..maxBudget = 2000000
        ..status = 'Active'
        ..createdAt = DateTime(2025, 1, 1)
        ..areaIds = []
        ..areaNames = []
        ..configurationIds = []
        ..propertyTypeIds = []
        ..furnishingIds = []
        ..facingIds = [];
      local.isarId = 42; // Isar internal primary key

      final server = RequirementLocal()
        ..id = 'req-1'
        ..clientName = 'Updated Client'
        ..clientMobile = '9800000000'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..minBudget = 1500000
        ..maxBudget = 2500000
        ..status = 'Active'
        ..createdAt = DateTime(2025, 1, 1)
        ..areaIds = []
        ..areaNames = []
        ..configurationIds = []
        ..propertyTypeIds = []
        ..furnishingIds = []
        ..facingIds = [];

      final diff = SyncEngine.computeDiff<RequirementLocal>(
        serverItems: [server],
        localItems: {'req-1': local},
        getId: (r) => r.id,
        isEqual: SyncEngine.areRequirementsEqual,
        preserveLocalMetadata: (sItem, lItem) {
          sItem.isarId = lItem.isarId;
        },
      );

      expect(diff.toUpdate.first.isarId, equals(42));
    });
  });
}

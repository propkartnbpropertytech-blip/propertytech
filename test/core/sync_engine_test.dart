import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/network/sync_engine.dart';
import 'package:propkart/core/storage/isar_collections.dart';

void main() {
  group('SyncEngine.computeDiff', () {
    test('identifies new items to insert', () {
      final serverItems = [
        PropertyLocal()
          ..id = 'p1'
          ..title = 'Villa 1'
          ..propertyCode = 'P-001'
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
          ..bathrooms = 3
          ..balconies = 1
          ..parking = 1
          ..ownerName = 'John'
          ..ownerMobile = '9876543210'
          ..isVerified = true
          ..createdBy = 'u1'
          ..createdByName = 'Admin'
          ..createdAt = DateTime(2025, 1, 1)
          ..images = []
          ..amenities = []
          ..videos = [],
      ];

      final Map<String, PropertyLocal> localItems = {};

      final diff = SyncEngine.computeDiff<PropertyLocal>(
        serverItems: serverItems,
        localItems: localItems,
        getId: (p) => p.id,
        isEqual: SyncEngine.arePropertiesEqual,
      );

      expect(diff.toInsert.length, 1);
      expect(diff.toInsert.first.id, 'p1');
      expect(diff.toUpdate, isEmpty);
      expect(diff.toDelete, isEmpty);
      expect(diff.unchangedCount, 0);
      expect(diff.hasChanges, isTrue);
    });

    test('identifies modified items and unchanged items correctly', () {
      final p1Server = PropertyLocal()
        ..id = 'p1'
        ..title = 'Villa 1 Updated' // Modified!
        ..propertyCode = 'P-001'
        ..price = 1200000
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
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'John'
        ..ownerMobile = '9876543210'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final p2Server = PropertyLocal()
        ..id = 'p2'
        ..title = 'Flat 2' // Unchanged!
        ..propertyCode = 'P-002'
        ..price = 500000
        ..deposit = 25000
        ..maintenance = 1000
        ..listingTypeId = 'lt2'
        ..propertyStatusId = 'ps2'
        ..categoryId = 'c2'
        ..propertyTypeId = 'pt2'
        ..cityId = 'ct1'
        ..areaId = 'a2'
        ..pincode = '380002'
        ..address = 'Address 2'
        ..bedrooms = 2
        ..bathrooms = 2
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Alice'
        ..ownerMobile = '9876543211'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final p1Local = PropertyLocal()
        ..id = 'p1'
        ..title = 'Villa 1 Old'
        ..propertyCode = 'P-001'
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
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'John'
        ..ownerMobile = '9876543210'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final p2Local = PropertyLocal()
        ..id = 'p2'
        ..title = 'Flat 2'
        ..propertyCode = 'P-002'
        ..price = 500000
        ..deposit = 25000
        ..maintenance = 1000
        ..listingTypeId = 'lt2'
        ..propertyStatusId = 'ps2'
        ..categoryId = 'c2'
        ..propertyTypeId = 'pt2'
        ..cityId = 'ct1'
        ..areaId = 'a2'
        ..pincode = '380002'
        ..address = 'Address 2'
        ..bedrooms = 2
        ..bathrooms = 2
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Alice'
        ..ownerMobile = '9876543211'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final diff = SyncEngine.computeDiff<PropertyLocal>(
        serverItems: [p1Server, p2Server],
        localItems: {'p1': p1Local, 'p2': p2Local},
        getId: (p) => p.id,
        isEqual: SyncEngine.arePropertiesEqual,
      );

      expect(diff.toInsert, isEmpty);
      expect(diff.toUpdate.length, 1);
      expect(diff.toUpdate.first.id, 'p1');
      expect(diff.unchangedCount, 1);
      expect(diff.toDelete, isEmpty);
      expect(diff.hasChanges, isTrue);
    });

    test('reconciles deleted items when absent from server', () {
      final p1Server = PropertyLocal()
        ..id = 'p1'
        ..title = 'Villa 1'
        ..propertyCode = 'P-001'
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
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'John'
        ..ownerMobile = '9876543210'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final p2Local = PropertyLocal()
        ..id = 'p2_deleted_on_server'
        ..title = 'Removed Villa'
        ..propertyCode = 'P-002'
        ..price = 500000
        ..deposit = 25000
        ..maintenance = 1000
        ..listingTypeId = 'lt2'
        ..propertyStatusId = 'ps2'
        ..categoryId = 'c2'
        ..propertyTypeId = 'pt2'
        ..cityId = 'ct1'
        ..areaId = 'a2'
        ..pincode = '380002'
        ..address = 'Address 2'
        ..bedrooms = 2
        ..bathrooms = 2
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Alice'
        ..ownerMobile = '9876543211'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final diff = SyncEngine.computeDiff<PropertyLocal>(
        serverItems: [p1Server],
        localItems: {'p1': p1Server, 'p2_deleted_on_server': p2Local},
        getId: (p) => p.id,
        isEqual: SyncEngine.arePropertiesEqual,
      );

      expect(diff.toInsert, isEmpty);
      expect(diff.toUpdate, isEmpty);
      expect(diff.unchangedCount, 1);
      expect(diff.toDelete, ['p2_deleted_on_server']);
      expect(diff.hasChanges, isTrue);
    });

    test('protects offline-created pending outbox records from being deleted', () {
      final p1Server = PropertyLocal()
        ..id = 'p1'
        ..title = 'Villa 1'
        ..propertyCode = 'P-001'
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
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'John'
        ..ownerMobile = '9876543210'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final pPendingOffline = PropertyLocal()
        ..id = 'offline_p99'
        ..title = 'Pending Villa'
        ..propertyCode = 'P-099'
        ..price = 800000
        ..deposit = 40000
        ..maintenance = 1500
        ..listingTypeId = 'lt1'
        ..propertyStatusId = 'ps1'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..cityId = 'ct1'
        ..areaId = 'a1'
        ..pincode = '380001'
        ..address = 'Address 99'
        ..bedrooms = 2
        ..bathrooms = 2
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Bob'
        ..ownerMobile = '9876543299'
        ..isVerified = false
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final diff = SyncEngine.computeDiff<PropertyLocal>(
        serverItems: [p1Server],
        localItems: {'p1': p1Server, 'offline_p99': pPendingOffline},
        getId: (p) => p.id,
        isEqual: SyncEngine.arePropertiesEqual,
        pendingOutboxIds: {'offline_p99'}, // In outbox!
      );

      // Should NOT delete offline_p99 because it is pending outbox replay
      expect(diff.toDelete, isEmpty);
      expect(diff.unchangedCount, 1);
      expect(diff.hasChanges, isFalse);
    });

    test('is fully idempotent: identical datasets produce zero changes', () {
      final r1 = RequirementLocal()
        ..id = 'r1'
        ..clientName = 'Rajesh Kumar'
        ..clientMobile = '9825000001'
        ..categoryId = 'c1'
        ..categoryName = 'Residential'
        ..propertyTypeId = 'pt1'
        ..propertyTypeName = 'Apartment'
        ..minBudget = 5000000
        ..maxBudget = 7500000
        ..minArea = 1200
        ..maxArea = 1800
        ..status = 'Active'
        ..createdAt = DateTime(2025, 1, 1)
        ..areaIds = ['a1']
        ..areaNames = ['Vastrapur']
        ..configurationIds = ['cfg1']
        ..propertyTypeIds = ['pt1']
        ..furnishingIds = []
        ..facingIds = [];

      final diff1 = SyncEngine.computeDiff<RequirementLocal>(
        serverItems: [r1],
        localItems: {'r1': r1},
        getId: (r) => r.id,
        isEqual: SyncEngine.areRequirementsEqual,
      );

      expect(diff1.hasChanges, isFalse);
      expect(diff1.totalChanges, 0);
      expect(diff1.unchangedCount, 1);
      expect(diff1.toInsert, isEmpty);
      expect(diff1.toUpdate, isEmpty);
      expect(diff1.toDelete, isEmpty);
    });
  });

  group('SyncEngine.applyBatchedWrites', () {
    test('chunks updates and deletes into batchSize correctly', () async {
      final diff = SyncDiffResult<String>(
        toInsert: List.generate(5, (i) => 'insert_$i'),
        toUpdate: List.generate(5, (i) => 'update_$i'),
        toDelete: ['del_1', 'del_2', 'del_3'],
        unchangedCount: 20,
      );

      final putBatches = <List<String>>[];
      final deleteBatches = <List<String>>[];

      final total = await SyncEngine.applyBatchedWrites<String>(
        diff: diff,
        putBatch: (batch) async => putBatches.add(List.from(batch)),
        deleteBatch: (ids) async => deleteBatches.add(List.from(ids)),
        batchSize: 4, // batchSize = 4 means 10 items split into 4, 4, 2
      );

      expect(total, 13);
      expect(putBatches.length, 3);
      expect(putBatches[0].length, 4);
      expect(putBatches[1].length, 4);
      expect(putBatches[2].length, 2);

      // 3 deletes with batchSize 4 = 1 batch of 3
      expect(deleteBatches.length, 1);
      expect(deleteBatches[0].length, 3);
    });

    test('skips execution entirely when diff has no changes', () async {
      const diff = SyncDiffResult<String>(
        toInsert: [],
        toUpdate: [],
        toDelete: [],
        unchangedCount: 50,
      );

      bool putCalled = false;
      bool deleteCalled = false;

      final total = await SyncEngine.applyBatchedWrites<String>(
        diff: diff,
        putBatch: (b) async => putCalled = true,
        deleteBatch: (d) async => deleteCalled = true,
      );

      expect(total, 0);
      expect(putCalled, isFalse);
      expect(deleteCalled, isFalse);
    });
  });

  group('SyncEngine entity comparators', () {
    test('arePropertiesEqual detects price and status mutations', () {
      final pOriginal = PropertyLocal()
        ..id = 'p1'
        ..title = 'Villa'
        ..propertyCode = 'P-001'
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
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'John'
        ..ownerMobile = '9876543210'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final pCloned = PropertyLocal()
        ..id = 'p1'
        ..title = 'Villa'
        ..propertyCode = 'P-001'
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
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'John'
        ..ownerMobile = '9876543210'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2025, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      expect(SyncEngine.arePropertiesEqual(pOriginal, pCloned), isTrue);

      pCloned.price = 1100000;
      expect(SyncEngine.arePropertiesEqual(pOriginal, pCloned), isFalse);

      pCloned.price = 1000000;
      pCloned.propertyStatusId = 'ps_sold';
      expect(SyncEngine.arePropertiesEqual(pOriginal, pCloned), isFalse);
    });

    test('areRequirementsEqual detects status and assignee mutations', () {
      final r1 = RequirementLocal()
        ..id = 'r1'
        ..clientName = 'Rajesh Kumar'
        ..clientMobile = '9825000001'
        ..categoryId = 'c1'
        ..categoryName = 'Residential'
        ..propertyTypeId = 'pt1'
        ..propertyTypeName = 'Apartment'
        ..minBudget = 5000000
        ..maxBudget = 7500000
        ..status = 'Active'
        ..assignedTo = 'u1'
        ..createdAt = DateTime(2025, 1, 1)
        ..areaIds = []
        ..areaNames = []
        ..configurationIds = []
        ..propertyTypeIds = []
        ..furnishingIds = []
        ..facingIds = [];

      final r2 = RequirementLocal()
        ..id = 'r1'
        ..clientName = 'Rajesh Kumar'
        ..clientMobile = '9825000001'
        ..categoryId = 'c1'
        ..categoryName = 'Residential'
        ..propertyTypeId = 'pt1'
        ..propertyTypeName = 'Apartment'
        ..minBudget = 5000000
        ..maxBudget = 7500000
        ..status = 'Active'
        ..assignedTo = 'u1'
        ..createdAt = DateTime(2025, 1, 1)
        ..areaIds = []
        ..areaNames = []
        ..configurationIds = []
        ..propertyTypeIds = []
        ..furnishingIds = []
        ..facingIds = [];

      expect(SyncEngine.areRequirementsEqual(r1, r2), isTrue);

      r2.status = 'Deal Closed';
      expect(SyncEngine.areRequirementsEqual(r1, r2), isFalse);

      r2.status = 'Active';
      r2.assignedTo = 'u2';
      expect(SyncEngine.areRequirementsEqual(r1, r2), isFalse);
    });
  });
}

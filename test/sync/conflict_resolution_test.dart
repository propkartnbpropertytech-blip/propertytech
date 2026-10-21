import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/network/sync_engine.dart';
import 'package:propkart/core/storage/isar_collections.dart';

void main() {
  group('Multi-Tier Conflict Resolution Pipeline Invariants', () {
    test('Tier 1: Disjoint field modifications merge cleanly so both updates survive', () {
      final local = PropertyLocal()
        ..id = 'p-conflict-1'
        ..title = 'Villa'
        ..propertyCode = 'P-101'
        ..price = 12000000 // Device A updated price
        ..deposit = 500000
        ..maintenance = 5000
        ..listingTypeId = 'lt1'
        ..listingTypeName = 'Sale'
        ..propertyStatusId = 'ps1'
        ..propertyStatusName = 'Available' // Server hasn't updated status locally yet
        ..categoryId = 'c1'
        ..categoryName = 'Residential'
        ..propertyTypeId = 'pt1'
        ..propertyTypeName = 'Villa'
        ..cityId = 'ct1'
        ..cityName = 'Ahmedabad'
        ..areaId = 'a1'
        ..areaName = 'Thaltej'
        ..pincode = '380054'
        ..address = 'Address'
        ..bedrooms = 4
        ..bathrooms = 4
        ..balconies = 2
        ..parking = 2
        ..ownerName = 'Patel'
        ..ownerMobile = '9800000000'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2026, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final server = PropertyLocal()
        ..id = 'p-conflict-1'
        ..title = 'Villa'
        ..propertyCode = 'P-101'
        ..price = 10000000 // Server has old price
        ..deposit = 500000
        ..maintenance = 5000
        ..listingTypeId = 'lt1'
        ..listingTypeName = 'Sale'
        ..propertyStatusId = 'ps2'
        ..propertyStatusName = 'Deal Closed' // Server closed the deal
        ..categoryId = 'c1'
        ..categoryName = 'Residential'
        ..propertyTypeId = 'pt1'
        ..propertyTypeName = 'Villa'
        ..cityId = 'ct1'
        ..cityName = 'Ahmedabad'
        ..areaId = 'a1'
        ..areaName = 'Thaltej'
        ..pincode = '380054'
        ..address = 'Address'
        ..bedrooms = 4
        ..bathrooms = 4
        ..balconies = 2
        ..parking = 2
        ..ownerName = 'Patel'
        ..ownerMobile = '9800000000'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2026, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final result = SyncEngine.resolvePropertyConflict(
        local: local,
        server: server,
        localModifiedFields: {'price'},
        serverModifiedFields: {'propertyStatusId'},
      );

      expect(result.winner, equals(ConflictWinner.merged));
      expect(result.tier, equals('FIELD_MERGE'));
      expect(result.mergedFields, contains('price'));
      // Both survive in merged record:
      expect(result.resolvedItem.price, equals(12000000)); // Local new price
      expect(result.resolvedItem.propertyStatusName, equals('Deal Closed')); // Server new status
    });

    test('Tier 2: Higher version counter wins when modifying colliding fields', () {
      final local = PropertyLocal()
        ..id = 'p-conflict-2'
        ..title = 'Villa'
        ..propertyCode = 'P-102'
        ..price = 11000000
        ..deposit = 500000
        ..maintenance = 5000
        ..listingTypeId = 'lt1'
        ..propertyStatusId = 'ps1'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..cityId = 'ct1'
        ..areaId = 'a1'
        ..pincode = '380054'
        ..address = 'Address'
        ..bedrooms = 3
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Patel'
        ..ownerMobile = '9800000000'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2026, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final server = PropertyLocal()
        ..id = 'p-conflict-2'
        ..title = 'Villa'
        ..propertyCode = 'P-102'
        ..price = 13000000
        ..deposit = 500000
        ..maintenance = 5000
        ..listingTypeId = 'lt1'
        ..propertyStatusId = 'ps1'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..cityId = 'ct1'
        ..areaId = 'a1'
        ..pincode = '380054'
        ..address = 'Address'
        ..bedrooms = 3
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Patel'
        ..ownerMobile = '9800000000'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2026, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final result = SyncEngine.resolvePropertyConflict(
        local: local,
        server: server,
        localModifiedFields: {'price'},
        serverModifiedFields: {'price'}, // Collision on price
        localVersion: 3,
        serverVersion: 5, // Server has higher version
      );

      expect(result.winner, equals(ConflictWinner.server));
      expect(result.tier, equals('VERSION_COUNTER'));
      expect(result.resolvedItem.price, equals(13000000));
    });

    test('Tier 3: Later timestamp wins on colliding fields when versions are equal', () {
      final local = PropertyLocal()
        ..id = 'p-conflict-3'
        ..title = 'Local Title'
        ..propertyCode = 'P-103'
        ..price = 10000000
        ..deposit = 500000
        ..maintenance = 5000
        ..listingTypeId = 'lt1'
        ..propertyStatusId = 'ps1'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..cityId = 'ct1'
        ..areaId = 'a1'
        ..pincode = '380054'
        ..address = 'Address'
        ..bedrooms = 3
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Patel'
        ..ownerMobile = '9800000000'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2026, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final server = PropertyLocal()
        ..id = 'p-conflict-3'
        ..title = 'Server Title'
        ..propertyCode = 'P-103'
        ..price = 10000000
        ..deposit = 500000
        ..maintenance = 5000
        ..listingTypeId = 'lt1'
        ..propertyStatusId = 'ps1'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..cityId = 'ct1'
        ..areaId = 'a1'
        ..pincode = '380054'
        ..address = 'Address'
        ..bedrooms = 3
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Patel'
        ..ownerMobile = '9800000000'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2026, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final localTime = DateTime(2026, 10, 21, 10, 0, 0);
      final serverTime = DateTime(2026, 10, 21, 10, 5, 0); // Server is 5 mins later

      final result = SyncEngine.resolvePropertyConflict(
        local: local,
        server: server,
        localModifiedFields: {'title'},
        serverModifiedFields: {'title'},
        localEditedAt: localTime,
        serverUpdatedAt: serverTime,
      );

      expect(result.winner, equals(ConflictWinner.server));
      expect(result.tier, equals('TIMESTAMP_LWW'));
      expect(result.resolvedItem.title, equals('Server Title'));
    });

    test('Tier 4: Deterministic tie-break produces identical winner on equal timestamps', () {
      final local = PropertyLocal()
        ..id = 'p-conflict-4'
        ..title = 'Local'
        ..propertyCode = 'P-104'
        ..price = 10000000
        ..deposit = 500000
        ..maintenance = 5000
        ..listingTypeId = 'lt1'
        ..propertyStatusId = 'ps1'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..cityId = 'ct1'
        ..areaId = 'a1'
        ..pincode = '380054'
        ..address = 'Address'
        ..bedrooms = 3
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Patel'
        ..ownerMobile = '9800000000'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2026, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final server = PropertyLocal()
        ..id = 'p-conflict-4'
        ..title = 'Server'
        ..propertyCode = 'P-104'
        ..price = 10000000
        ..deposit = 500000
        ..maintenance = 5000
        ..listingTypeId = 'lt1'
        ..propertyStatusId = 'ps1'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..cityId = 'ct1'
        ..areaId = 'a1'
        ..pincode = '380054'
        ..address = 'Address'
        ..bedrooms = 3
        ..bathrooms = 3
        ..balconies = 1
        ..parking = 1
        ..ownerName = 'Patel'
        ..ownerMobile = '9800000000'
        ..isVerified = true
        ..createdBy = 'u1'
        ..createdByName = 'Admin'
        ..createdAt = DateTime(2026, 1, 1)
        ..images = []
        ..amenities = []
        ..videos = [];

      final exactTime = DateTime(2026, 10, 21, 10, 0, 0, 500);

      final result = SyncEngine.resolvePropertyConflict(
        local: local,
        server: server,
        localModifiedFields: {'title'},
        serverModifiedFields: {'title'},
        localEditedAt: exactTime,
        serverUpdatedAt: exactTime,
      );

      expect(result.tier, equals('TIE_BREAK'));
      expect(result.winner, isNotNull);
    });

    test('Requirement conflict resolution merges disjoint fields cleanly', () {
      final local = RequirementLocal()
        ..id = 'req-c-1'
        ..clientName = 'Client'
        ..clientMobile = '9800000000'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..minBudget = 2000000 // Device A updated budget
        ..maxBudget = 4000000
        ..status = 'Active'
        ..createdAt = DateTime(2026, 1, 1)
        ..areaIds = []
        ..areaNames = []
        ..configurationIds = []
        ..propertyTypeIds = []
        ..furnishingIds = []
        ..facingIds = [];

      final server = RequirementLocal()
        ..id = 'req-c-1'
        ..clientName = 'Client'
        ..clientMobile = '9800000000'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..minBudget = 1000000
        ..maxBudget = 2000000
        ..status = 'Deal Closed' // Server closed deal
        ..createdAt = DateTime(2026, 1, 1)
        ..areaIds = []
        ..areaNames = []
        ..configurationIds = []
        ..propertyTypeIds = []
        ..furnishingIds = []
        ..facingIds = [];

      final result = SyncEngine.resolveRequirementConflict(
        local: local,
        server: server,
        localModifiedFields: {'minBudget', 'maxBudget'},
        serverModifiedFields: {'status'},
      );

      expect(result.winner, equals(ConflictWinner.merged));
      expect(result.resolvedItem.minBudget, equals(2000000));
      expect(result.resolvedItem.status, equals('Deal Closed'));
    });
  });
}

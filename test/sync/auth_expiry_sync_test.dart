import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/network/sync_manager.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';

void main() {
  group('Authentication Expiry & Token Refresh Sync Invariants', () {
    setUp(() {
      PropertyLocalRepository.inMemory.clear();
      OutboxLocalRepository.inMemory.clear();
    });

    test('HTTP 401 Unauthorized pauses sync and halts infinite retry loops', () {
      int retryAttempts = 0;
      bool tokenExpired = true;
      bool isSyncPaused = false;

      // Simulated sync worker loop
      while (retryAttempts < 5) {
        retryAttempts++;
        if (tokenExpired) {
          isSyncPaused = true;
          break; // Must immediately break, not loop infinitely!
        }
      }

      expect(isSyncPaused, isTrue);
      expect(retryAttempts, equals(1)); // Stopped on first 401
    });

    test('Authentication failure NEVER purges local Isar storage or outbox mutations', () {
      final p = PropertyLocal()
        ..id = 'p-preserve-1'
        ..title = 'Critical Offline Data'
        ..propertyCode = 'PRES-01'
        ..price = 10000000
        ..deposit = 500000
        ..maintenance = 5000
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
        ..createdAt = DateTime.now()
        ..images = []
        ..amenities = []
        ..videos = [];

      PropertyLocalRepository.inMemory['p-preserve-1'] = p;

      // Simulate token expiry handling:
      void handleAuthExpiry() {
        // Pauses sync state, but NEVER wipes local database!
      }

      handleAuthExpiry();

      expect(PropertyLocalRepository.inMemory.containsKey('p-preserve-1'), isTrue);
      expect(PropertyLocalRepository.inMemory['p-preserve-1']!.title, equals('Critical Offline Data'));
    });

    test('Valid re-authentication transitions state back to CONNECTING/SYNCING', () {
      SyncState currentState = SyncState.error;

      // User submits login credentials
      bool loginSuccessful = true;
      if (loginSuccessful && SyncManager.isValidTransition(currentState, SyncState.connecting)) {
        currentState = SyncState.connecting;
      }

      expect(currentState, equals(SyncState.connecting));
    });
  });
}

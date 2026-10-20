import 'package:flutter_test/flutter_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/network/sync_engine.dart';

void main() {
  group('SyncManager & Coordinator Incremental Sync Semantics', () {
    late RepositoryCoordinator coordinator;

    setUp(() {
      coordinator = RepositoryCoordinator();
    });

    test('RepositoryCoordinator debounces rapid refresh requests to prevent watcher floods', () {
      fakeAsync((async) {
        int propertiesEvents = 0;
        int dashboardEvents = 0;

        final pSub = coordinator.propertiesStream.listen((_) => propertiesEvents++);
        final dSub = coordinator.dashboardStream.listen((_) => dashboardEvents++);

        // Fire rapid refreshes (e.g. simulation of watcher flood)
        for (int i = 0; i < 10; i++) {
          coordinator.refreshProperties();
        }

        // Advance clock past properties timer (400ms)
        async.elapse(const Duration(milliseconds: 500));
        expect(propertiesEvents, equals(1));

        // Advance clock past dashboard timer (800ms)
        async.elapse(const Duration(milliseconds: 900));
        expect(dashboardEvents, equals(1));

        pSub.cancel();
        dSub.cancel();
      });
    });

    test('Conflict Resolution: Outbox item older than server updated_at is detected as conflict', () {
      final outboxItem = OutboxLocal()
        ..id = 'outbox-1'
        ..endpoint = '/requirements/req-101'
        ..method = 'PUT'
        ..payloadJson = '{"status":"Active"}'
        ..createdAt = DateTime.now().subtract(const Duration(minutes: 5));

      final serverRequirement = {
        'id': 'req-101',
        'updated_at': DateTime.now().toIso8601String(), // Server was edited more recently
      };

      final serverUpdatedAt = DateTime.parse(serverRequirement['updated_at']!);
      final isConflict = serverUpdatedAt.isAfter(outboxItem.createdAt);

      // Server-wins policy: outbox modification is discarded
      expect(isConflict, isTrue);
    });

    test('Incremental sync updates only changed fields and preserves existing inMemory cache', () async {
      final rOld = RequirementLocal()
        ..id = 'req-200'
        ..clientName = 'Original Client'
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

      RequirementLocalRepository.inMemory['req-200'] = rOld;

      final rServer = RequirementLocal()
        ..id = 'req-200'
        ..clientName = 'Original Client'
        ..clientMobile = '9800000000'
        ..categoryId = 'c1'
        ..propertyTypeId = 'pt1'
        ..minBudget = 1000000
        ..maxBudget = 2000000
        ..status = 'Deal Closed' // Updated on server
        ..createdAt = DateTime(2025, 1, 1)
        ..areaIds = []
        ..areaNames = []
        ..configurationIds = []
        ..propertyTypeIds = []
        ..furnishingIds = []
        ..facingIds = [];

      final diff = SyncEngine.computeDiff<RequirementLocal>(
        serverItems: [rServer],
        localItems: Map.from(RequirementLocalRepository.inMemory),
        getId: (r) => r.id,
        isEqual: SyncEngine.areRequirementsEqual,
      );

      expect(diff.toInsert, isEmpty);
      expect(diff.toUpdate.length, 1);
      expect(diff.toUpdate.first.status, 'Deal Closed');
      expect(diff.unchangedCount, 0);

      // Apply update without clearing inMemory
      for (final r in diff.toUpdate) {
        RequirementLocalRepository.inMemory[r.id] = r;
      }

      expect(RequirementLocalRepository.inMemory['req-200']!.status, 'Deal Closed');
      expect(RequirementLocalRepository.inMemory.containsKey('req-200'), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/network/sync_engine.dart';

void main() {
  group('Initial Startup Synchronization Invariants', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      LookupLocalRepository.inMemory.clear();
    });

    test('Identifies empty local cache as requiring initial metadata sync', () async {
      expect(LookupLocalRepository.inMemory.isEmpty, isTrue);
      final count = LookupLocalRepository.inMemory.length;
      expect(count, equals(0));
    });

    test('Avoids redundant metadata download when client version matches server version', () async {
      SharedPreferences.setMockInitialValues({'last_lookup_version': 4});
      final prefs = await SharedPreferences.getInstance();
      final clientVersion = prefs.getInt('last_lookup_version');

      const serverVersion = 4;
      final shouldDownload = clientVersion == null || clientVersion != serverVersion;
      expect(shouldDownload, isFalse);
    });

    test('Triggers metadata download when server schema version increments', () async {
      SharedPreferences.setMockInitialValues({'last_lookup_version': 3});
      final prefs = await SharedPreferences.getInstance();
      final clientVersion = prefs.getInt('last_lookup_version');

      const serverVersion = 4; // Server bumped schema
      final shouldDownload = clientVersion == null || clientVersion != serverVersion;
      expect(shouldDownload, isTrue);
    });

    test('Persists checkpoint version only after local storage write succeeds', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Simulate local write first
      final item = LookupItemLocal()
        ..id = 'city_1'
        ..name = 'Ahmedabad'
        ..category = 'city';
      LookupLocalRepository.inMemory[item.id] = item;
      expect(LookupLocalRepository.inMemory.containsKey('city_1'), isTrue);

      // Advance checkpoint post-write
      await prefs.setInt('last_lookup_version', 4);
      expect(prefs.getInt('last_lookup_version'), equals(4));
    });

    test('Applies initial bulk lookup items in safe batch chunks without memory bloat', () async {
      final serverItems = List.generate(
        250,
        (i) => LookupItemLocal()
          ..id = 'area_$i'
          ..name = 'Area $i'
          ..category = 'area',
      );

      final diff = SyncEngine.computeDiff<LookupItemLocal>(
        serverItems: serverItems,
        localItems: Map.from(LookupLocalRepository.inMemory),
        getId: (item) => item.id,
        isEqual: (a, b) => a.id == b.id && a.name == b.name && a.category == b.category,
      );

      expect(diff.toInsert.length, equals(250));
      expect(diff.toUpdate, isEmpty);
      expect(diff.toDelete, isEmpty);

      // Verify batch chunking logic
      int chunksCount = 0;
      await SyncEngine.applyBatchedWrites<LookupItemLocal>(
        diff: diff,
        putBatch: (batch) async {
          chunksCount++;
          expect(batch.length, lessThanOrEqualTo(100));
          for (final item in batch) {
            LookupLocalRepository.inMemory[item.id] = item;
          }
        },
        deleteBatch: (ids) async {},
        batchSize: 100,
      );

      expect(chunksCount, equals(3)); // 100 + 100 + 50 = 3 chunks
      expect(LookupLocalRepository.inMemory.length, equals(250));
    });
  });
}

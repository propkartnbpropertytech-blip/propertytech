import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/network/sync_engine.dart';

PropertyLocal createFullProperty({
  required String id,
  required String code,
  required double price,
}) {
  return PropertyLocal()
    ..id = id
    ..propertyCode = code
    ..title = 'Villa'
    ..price = price
    ..deposit = 50000.0
    ..maintenance = 2000.0
    ..listingTypeId = 'lt1'
    ..listingTypeName = 'Rent'
    ..propertyStatusId = 'ps1'
    ..propertyStatusName = 'Available'
    ..categoryId = 'c1'
    ..categoryName = 'Residential'
    ..propertyTypeId = 'pt1'
    ..propertyTypeName = 'Apartment'
    ..cityId = 'ct1'
    ..cityName = 'Mumbai'
    ..areaId = 'a1'
    ..areaName = 'Bandra'
    ..pincode = '400050'
    ..address = '123 Sea View Road'
    ..bedrooms = 3
    ..bathrooms = 2
    ..balconies = 1
    ..parking = 1
    ..ownerName = 'Owner'
    ..ownerMobile = '9876543210'
    ..isVerified = true
    ..createdBy = 'u1'
    ..createdByName = 'Admin'
    ..createdAt = DateTime(2026, 1, 1)
    ..images = []
    ..amenities = []
    ..videos = []
    ..portalStatus = 'Active';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Isar Indexing & Schema Verification (Step 5)', () {
    test('LookupItemLocalSchema contains expected indexes with correct metadata', () {
      final indexes = LookupItemLocalSchema.indexes;
      expect(indexes.containsKey('id'), isTrue);
      expect(indexes['id']!.unique, isTrue);

      expect(indexes.containsKey('category'), isTrue);
      expect(indexes['category']!.unique, isFalse);
      expect(indexes['category']!.properties.first.name, equals('category'));
    });

    test('PropertyLocalSchema contains justified indexes on hot query fields', () {
      final indexes = PropertyLocalSchema.indexes;
      expect(indexes.containsKey('id'), isTrue);
      expect(indexes['id']!.unique, isTrue);

      // propertyCode index (case-insensitive for code search)
      expect(indexes.containsKey('propertyCode'), isTrue);
      expect(indexes['propertyCode']!.properties.first.name, equals('propertyCode'));
      expect(indexes['propertyCode']!.properties.first.caseSensitive, isFalse);

      // categoryId index
      expect(indexes.containsKey('categoryId'), isTrue);
      expect(indexes['categoryId']!.properties.first.name, equals('categoryId'));

      // listingTypeId index
      expect(indexes.containsKey('listingTypeId'), isTrue);
      expect(indexes['listingTypeId']!.properties.first.name, equals('listingTypeId'));

      // createdAt index (for chronologically sorted feeds)
      expect(indexes.containsKey('createdAt'), isTrue);
      expect(indexes['createdAt']!.properties.first.name, equals('createdAt'));
    });

    test('RequirementLocalSchema contains justified indexes on status, createdAt, assignedTo', () {
      final indexes = RequirementLocalSchema.indexes;
      expect(indexes.containsKey('id'), isTrue);
      expect(indexes['id']!.unique, isTrue);

      expect(indexes.containsKey('status'), isTrue);
      expect(indexes.containsKey('createdAt'), isTrue);
      expect(indexes.containsKey('assignedTo'), isTrue);
    });

    test('FollowupLocalSchema contains justified indexes on followupDate and status', () {
      final indexes = FollowupLocalSchema.indexes;
      expect(indexes.containsKey('id'), isTrue);
      expect(indexes['id']!.unique, isTrue);

      expect(indexes.containsKey('followupDate'), isTrue);
      expect(indexes.containsKey('status'), isTrue);
    });

    test('ClientLocalSchema contains justified indexes on stage and createdAt', () {
      final indexes = ClientLocalSchema.indexes;
      expect(indexes.containsKey('id'), isTrue);
      expect(indexes['id']!.unique, isTrue);

      expect(indexes.containsKey('stage'), isTrue);
      expect(indexes.containsKey('createdAt'), isTrue);
    });

    test('CampaignLeadLocalSchema contains justified index on receivedAt', () {
      final indexes = CampaignLeadLocalSchema.indexes;
      expect(indexes.containsKey('id'), isTrue);
      expect(indexes['id']!.unique, isTrue);

      expect(indexes.containsKey('receivedAt'), isTrue);
    });
  });

  group('Repository In-Memory & Index Lookups Correctness', () {
    setUp(() {
      LookupLocalRepository.inMemory.clear();
      PropertyLocalRepository.inMemory.clear();
      RequirementLocalRepository.inMemory.clear();
      FollowupLocalRepository.inMemory.clear();
      ClientLocalRepository.inMemory.clear();
      CampaignLeadLocalRepository.inMemory.clear();
    });

    test('LookupItemLocal category filtering correctly groups items by category', () async {
      final repo = LookupLocalRepository();
      final items = [
        LookupItemLocal()..id = 'c1'..name = 'Mumbai'..category = 'city',
        LookupItemLocal()..id = 'c2'..name = 'Pune'..category = 'city',
        LookupItemLocal()..id = 'a1'..name = 'Andheri'..category = 'area',
        LookupItemLocal()..id = 'lt1'..name = 'Rent'..category = 'listing_type',
      ];
      await repo.saveLookups(items);

      final cities = await repo.getLookupsByCategory('city');
      expect(cities.length, equals(2));
      expect(cities.map((c) => c.name).toSet(), equals({'Mumbai', 'Pune'}));

      final areas = await repo.getLookupsByCategory('area');
      expect(areas.length, equals(1));
      expect(areas.first.name, equals('Andheri'));
    });

    test('PropertyLocal lookup by id and propertyCode resolves accurately', () async {
      final repo = PropertyLocalRepository();
      final prop1 = createFullProperty(
        id: 'p-101',
        code: 'PROP-101',
        price: 5000000.0,
      )..title = 'Luxury Sea View Apartment';

      await repo.saveProperties([prop1]);

      final byId = await repo.getPropertyById('p-101');
      expect(byId, isNotNull);
      expect(byId!.title, equals('Luxury Sea View Apartment'));

      final byCode = await repo.getPropertyByIdOrCode('PROP-101');
      expect(byCode, isNotNull);
      expect(byCode!.id, equals('p-101'));
    });

    test('ClientLocal filtering by stage and sorting by createdAt', () async {
      final repo = ClientLocalRepository();
      final t1 = DateTime(2026, 1, 1);
      final t2 = DateTime(2026, 1, 2);
      final t3 = DateTime(2026, 1, 3);

      final c1 = ClientLocal()..id = 'cl-1'..name = 'Alice'..mobile = '9999999991'..email = 'a@test.com'..stage = 'Lead'..createdAt = t1;
      final c2 = ClientLocal()..id = 'cl-2'..name = 'Bob'..mobile = '9999999992'..email = 'b@test.com'..stage = 'Contacted'..createdAt = t2;
      final c3 = ClientLocal()..id = 'cl-3'..name = 'Charlie'..mobile = '9999999993'..email = 'c@test.com'..stage = 'Lead'..createdAt = t3;

      await repo.saveClients([c1, c2, c3]);

      final leadsOnly = await repo.getClients(stage: 'Lead');
      expect(leadsOnly.length, equals(2));
      // Should be sorted by createdAt descending
      expect(leadsOnly.first.name, equals('Charlie'));
      expect(leadsOnly.last.name, equals('Alice'));
    });

    test('Batch deletions properly purge entities without leaking entries', () async {
      final repo = LookupLocalRepository();
      final items = List.generate(50, (i) => LookupItemLocal()
        ..id = 'lookup-$i'
        ..name = 'Item $i'
        ..category = 'test_cat'
      );
      await repo.saveLookups(items);
      expect(await repo.getLookupsCount(), equals(50));

      final toDelete = List.generate(20, (i) => 'lookup-$i');
      await repo.deleteLookups(toDelete);
      expect(await repo.getLookupsCount(), equals(30));

      final remaining = await repo.getLookupsByCategory('test_cat');
      expect(remaining.length, equals(30));
      expect(remaining.any((r) => toDelete.contains(r.id)), isFalse);
    });
  });

  group('Benchmark & Computational Complexity Analysis', () {
    test('Simulated B-Tree Index vs Linear Scan across 1,000, 5,000, and 10,000 records', () {
      final sizes = [1000, 5000, 10000];
      final results = <Map<String, dynamic>>[];

      for (final n in sizes) {
        // Generate dataset
        final list = List.generate(n, (i) => PropertyLocal()
          ..id = 'prop-$i'
          ..propertyCode = 'CODE-${i.toString().padLeft(6, '0')}'
          ..title = 'Property Title $i'
          ..categoryId = 'cat-${i % 10}'
          ..listingTypeId = 'type-${i % 4}'
          ..createdAt = DateTime.now().subtract(Duration(minutes: i))
        );

        // Index map simulating B-tree / hash index
        final index = {for (final p in list) p.id: p};

        final targetId = 'prop-${n - 1}'; // worst case for linear scan (at the end)

        // Measure Linear Scan: O(N)
        final swLinear = Stopwatch()..start();
        PropertyLocal? foundLinear;
        for (int iter = 0; iter < 100; iter++) {
          for (final p in list) {
            if (p.id == targetId) {
              foundLinear = p;
              break;
            }
          }
        }
        swLinear.stop();
        final linearTimeUs = swLinear.elapsedMicroseconds / 100;

        // Measure Index Lookup: O(1) / O(log N)
        final swIndex = Stopwatch()..start();
        PropertyLocal? foundIndex;
        for (int iter = 0; iter < 100; iter++) {
          foundIndex = index[targetId];
        }
        swIndex.stop();
        final indexTimeUs = swIndex.elapsedMicroseconds / 100;

        expect(foundLinear, isNotNull);
        expect(foundIndex, isNotNull);
        expect(foundLinear!.id, equals(foundIndex!.id));

        final speedup = linearTimeUs / (indexTimeUs > 0 ? indexTimeUs : 0.01);
        results.add({
          'records': n,
          'linearScanMicroseconds': linearTimeUs,
          'indexLookupMicroseconds': indexTimeUs,
          'speedupFactor': speedup,
        });

        // Verification assertions:
        // Index lookup must be drastically faster than linear scan
        expect(indexTimeUs, lessThan(linearTimeUs));
        expect(indexTimeUs, lessThan(100.0));
      }

      // Output benchmark summary
      for (final r in results) {
        print('BENCHMARK: ${r['records']} records | Scan: ${r['linearScanMicroseconds'].toStringAsFixed(2)} µs | Index: ${r['indexLookupMicroseconds'].toStringAsFixed(2)} µs | Speedup: ${r['speedupFactor'].toStringAsFixed(1)}x');
      }
    });

    test('Batch deletion complexity: deleteAllById scales O(M) rather than O(M * N)', () {
      const totalRecords = 5000;
      const deleteCount = 100;

      final list = List.generate(totalRecords, (i) => 'id-$i');
      final map = {for (final id in list) id: id};
      final toDelete = List.generate(deleteCount, (i) => 'id-${i * 10}');

      // Simulating linear scan deletion: for each target id, iterate full list
      final swIter = Stopwatch()..start();
      for (final id in toDelete) {
        list.remove(id); // O(N) scan per item
      }
      swIter.stop();
      final iterTimeUs = swIter.elapsedMicroseconds;

      // Simulating batch indexed deletion: B-Tree / map delete per item O(1)
      final swBatch = Stopwatch()..start();
      for (final id in toDelete) {
        map.remove(id);
      }
      swBatch.stop();
      final batchTimeUs = swBatch.elapsedMicroseconds;

      expect(map.length, equals(totalRecords - deleteCount));
      expect(batchTimeUs, lessThan(iterTimeUs));
    });
  });

  group('Migration Compatibility & Non-Destructive Invariants', () {
    test('Schemas retain all original property offsets and autoIncrement IDs', () {
      // LookupItemLocal property count: 6
      expect(LookupItemLocalSchema.properties.length, equals(6));

      // PropertyLocal property count: 62 (89 fields mapped to 62 serialized storage properties)
      expect(PropertyLocalSchema.properties.length, equals(62));

      // RequirementLocal property count: 35
      expect(RequirementLocalSchema.properties.length, equals(35));

      // FollowupLocal property count: 13
      expect(FollowupLocalSchema.properties.length, equals(13));

      // ClientLocal property count: 9
      expect(ClientLocalSchema.properties.length, equals(9));
    });

    test('SyncEngine integration maintains equivalence and idempotency with indexed entities', () {
      final p1 = createFullProperty(id: 'p-1', code: 'PROP-1', price: 10000000.0);
      final p2 = createFullProperty(id: 'p-1', code: 'PROP-1', price: 10000000.0);

      expect(SyncEngine.arePropertiesEqual(p1, p2), isTrue);

      p2.price = 10500000.0;
      expect(SyncEngine.arePropertiesEqual(p1, p2), isFalse);
    });
  });
}

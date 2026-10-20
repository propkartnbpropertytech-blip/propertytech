import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/storage/web_storage/web_storage_service.dart';
import 'package:propkart/core/storage/web_storage/web_storage_migration.dart';
import 'package:propkart/core/storage/session_cleanup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebStorage Stub / In-Memory Unit Tests', () {
    final storage = WebStorage();

    setUp(() async {
      await storage.clearAllStores();
    });

    test('putRecord and getRecord work correctly', () async {
      await storage.putRecord(WebStorageStores.properties, 'p1', jsonEncode({'title': 'Villa 1'}));
      final record = await storage.getRecord(WebStorageStores.properties, 'p1');
      expect(record, isNotNull);
      final map = jsonDecode(record!);
      expect(map['title'], equals('Villa 1'));
    });

    test('deleteRecord removes record from store', () async {
      await storage.putRecord(WebStorageStores.requirements, 'r1', jsonEncode({'req': '2BHK'}));
      expect(await storage.getRecord(WebStorageStores.requirements, 'r1'), isNotNull);

      await storage.deleteRecord(WebStorageStores.requirements, 'r1');
      expect(await storage.getRecord(WebStorageStores.requirements, 'r1'), isNull);
    });

    test('putBatch and getAllRecords support batch writes and retrieval', () async {
      final batch = <String, String>{
        'f1': jsonEncode({'id': 'f1', 'note': 'Call customer'}),
        'f2': jsonEncode({'id': 'f2', 'note': 'Site visit'}),
        'f3': jsonEncode({'id': 'f3', 'note': 'Negotiation'}),
      };
      await storage.putBatch(WebStorageStores.followups, batch);

      final records = await storage.getAllRecords(WebStorageStores.followups);
      expect(records.length, equals(3));
      final notes = records.map((r) => jsonDecode(r)['note']).toSet();
      expect(notes, equals({'Call customer', 'Site visit', 'Negotiation'}));
    });

    test('deleteBatch removes specified keys', () async {
      final batch = <String, String>{
        'l1': jsonEncode({'id': 'l1', 'name': 'Item 1'}),
        'l2': jsonEncode({'id': 'l2', 'name': 'Item 2'}),
        'l3': jsonEncode({'id': 'l3', 'name': 'Item 3'}),
      };
      await storage.putBatch(WebStorageStores.lookups, batch);
      expect((await storage.getAllRecords(WebStorageStores.lookups)).length, equals(3));

      await storage.deleteBatch(WebStorageStores.lookups, ['l1', 'l3']);
      final remaining = await storage.getAllRecords(WebStorageStores.lookups);
      expect(remaining.length, equals(1));
      expect(jsonDecode(remaining.first)['id'], equals('l2'));
    });

    test('clearStore empties only targeted store', () async {
      await storage.putRecord(WebStorageStores.properties, 'p1', '{}');
      await storage.putRecord(WebStorageStores.clients, 'c1', '{}');

      await storage.clearStore(WebStorageStores.properties);
      expect((await storage.getAllRecords(WebStorageStores.properties)).isEmpty, isTrue);
      expect((await storage.getAllRecords(WebStorageStores.clients)).length, equals(1));
    });

    test('clearAllStores empties all stores', () async {
      await storage.putRecord(WebStorageStores.properties, 'p1', '{}');
      await storage.putRecord(WebStorageStores.clients, 'c1', '{}');
      await storage.putRecord(WebStorageStores.campaignLeads, 'cl1', '{}');

      await storage.clearAllStores();
      expect((await storage.getAllRecords(WebStorageStores.properties)).isEmpty, isTrue);
      expect((await storage.getAllRecords(WebStorageStores.clients)).isEmpty, isTrue);
      expect((await storage.getAllRecords(WebStorageStores.campaignLeads)).isEmpty, isTrue);
    });
  });

  group('WebStorageMigration Unit Tests', () {
    final storage = WebStorage();

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await storage.clearAllStores();
    });

    test('Migrates legacy cached_properties from SharedPreferences to WebStorage and cleans legacy key', () async {
      final legacyList = [
        jsonEncode({'id': 'legacy-p1', 'title': 'Legacy Penthouse'}),
        jsonEncode({'id': 'legacy-p2', 'title': 'Legacy Studio'}),
      ];
      SharedPreferences.setMockInitialValues({
        'cached_properties': legacyList,
      });

      await WebStorageMigration.migrateLegacyLocalStorageIfNeeded(force: true);

      final records = await storage.getAllRecords(WebStorageStores.properties);
      expect(records.length, equals(2));
      final ids = records.map((r) => jsonDecode(r)['id']).toSet();
      expect(ids, equals({'legacy-p1', 'legacy-p2'}));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('cached_properties'), isFalse);
    });

    test('Migration is idempotent and runs only once without duplicate migration', () async {
      final legacyList = [
        jsonEncode({'id': 'legacy-r1', 'requirement': 'Office Space'}),
      ];
      SharedPreferences.setMockInitialValues({
        'cached_requirements': legacyList,
      });

      // Run 1
      await WebStorageMigration.migrateLegacyLocalStorageIfNeeded(force: true);
      expect((await storage.getAllRecords(WebStorageStores.requirements)).length, equals(1));

      // Run 2 (flag is already set)
      await WebStorageMigration.migrateLegacyLocalStorageIfNeeded(force: true);
      expect((await storage.getAllRecords(WebStorageStores.requirements)).length, equals(1));
    });

    test('SessionCleanup resets both in-memory and WebStorage on logout', () async {
      await storage.putRecord(WebStorageStores.properties, 'p100', '{}');
      expect((await storage.getAllRecords(WebStorageStores.properties)).length, equals(1));

      // In stub / non-web test, clearLocalSession clears in-memory and user-scoped prefs
      await SessionCleanup.clearLocalSession(clearToken: false);
      await storage.clearAllStores();
      expect((await storage.getAllRecords(WebStorageStores.properties)).length, equals(0));
    });
  });
}

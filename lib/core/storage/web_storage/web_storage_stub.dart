import 'dart:async';
import 'web_storage_service.dart';

WebStorageAdapter createWebStorageAdapter() => WebStorageStub();

/// In-memory stub implementation of [WebStorageAdapter] for non-web platforms and VM tests.
class WebStorageStub implements WebStorageAdapter {
  final Map<String, Map<String, String>> _stores = {};

  Map<String, String> _getStore(String storeName) {
    return _stores.putIfAbsent(storeName, () => <String, String>{});
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> getRecord(String storeName, String key) async {
    return _getStore(storeName)[key];
  }

  @override
  Future<List<String>> getAllRecords(String storeName) async {
    return _getStore(storeName).values.toList();
  }

  @override
  Future<void> putRecord(String storeName, String key, String jsonValue) async {
    _getStore(storeName)[key] = jsonValue;
  }

  @override
  Future<void> putBatch(String storeName, Map<String, String> records) async {
    _getStore(storeName).addAll(records);
  }

  @override
  Future<void> deleteRecord(String storeName, String key) async {
    _getStore(storeName).remove(key);
  }

  @override
  Future<void> deleteBatch(String storeName, List<String> keys) async {
    final store = _getStore(storeName);
    for (final k in keys) {
      store.remove(k);
    }
  }

  @override
  Future<void> clearStore(String storeName) async {
    _getStore(storeName).clear();
  }

  @override
  Future<void> clearAllStores() async {
    _stores.clear();
  }

  @override
  Future<int> count(String storeName) async {
    return _getStore(storeName).length;
  }

  @override
  Future<void> close() async {
    _stores.clear();
  }
}

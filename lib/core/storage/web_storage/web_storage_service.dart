import 'package:flutter/foundation.dart';
import 'web_storage.dart' as impl;

/// Identifiers for all persistent Web IndexedDB object stores.
class WebStorageStores {
  static const String properties = 'properties';
  static const String requirements = 'requirements';
  static const String followups = 'followups';
  static const String lookups = 'lookup_items';
  static const String campaignLeads = 'campaign_leads';
  static const String builders = 'builders';
  static const String owners = 'owners';
  static const String clients = 'clients';
  static const String outbox = 'outbox';
  static const String dashboard = 'dashboard';
  static const String metadata = 'metadata';

  static const List<String> all = [
    properties,
    requirements,
    followups,
    lookups,
    campaignLeads,
    builders,
    owners,
    clients,
    outbox,
    dashboard,
    metadata,
  ];
}

/// Abstract contract for asynchronous Web storage.
abstract class WebStorageAdapter {
  Future<void> initialize();
  Future<String?> getRecord(String storeName, String key);
  Future<List<String>> getAllRecords(String storeName);
  Future<void> putRecord(String storeName, String key, String jsonValue);
  Future<void> putBatch(String storeName, Map<String, String> records);
  Future<void> deleteRecord(String storeName, String key);
  Future<void> deleteBatch(String storeName, List<String> keys);
  Future<void> clearStore(String storeName);
  Future<void> clearAllStores();
  Future<int> count(String storeName);
  Future<void> close();
}

/// Singleton manager for Web IndexedDB persistence.
class WebStorage {
  static final WebStorage _instance = WebStorage._internal();
  factory WebStorage() => _instance;
  WebStorage._internal();

  static WebStorage get instance => _instance;

  final WebStorageAdapter _adapter = impl.createWebStorageAdapter();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await _adapter.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('WebStorage: Initialization failed: $e');
    }
  }

  Future<String?> getRecord(String storeName, String key) =>
      _adapter.getRecord(storeName, key);

  Future<List<String>> getAllRecords(String storeName) =>
      _adapter.getAllRecords(storeName);

  Future<void> putRecord(String storeName, String key, String jsonValue) =>
      _adapter.putRecord(storeName, key, jsonValue);

  Future<void> putBatch(String storeName, Map<String, String> records) =>
      _adapter.putBatch(storeName, records);

  Future<void> deleteRecord(String storeName, String key) =>
      _adapter.deleteRecord(storeName, key);

  Future<void> deleteBatch(String storeName, List<String> keys) =>
      _adapter.deleteBatch(storeName, keys);

  Future<void> clearStore(String storeName) => _adapter.clearStore(storeName);

  Future<void> clearAllStores() => _adapter.clearAllStores();

  Future<int> count(String storeName) => _adapter.count(storeName);

  Future<void> close() => _adapter.close();
}

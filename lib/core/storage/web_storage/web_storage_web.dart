import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'web_storage_service.dart';

WebStorageAdapter createWebStorageAdapter() => WebStorageWeb();

/// Genuine IndexedDB implementation of [WebStorageAdapter] for Flutter Web.
class WebStorageWeb implements WebStorageAdapter {
  static const String _dbName = 'propkart_web_db';
  static const int _dbVersion = 1;

  dynamic _db;
  bool _fallbackMode = false;
  final Map<String, Map<String, String>> _fallbackStores = {};

  Map<String, String> _getFallbackStore(String storeName) {
    return _fallbackStores.putIfAbsent(storeName, () => <String, String>{});
  }

  bool get _isIndexedDBAvailable {
    try {
      return html.window.indexedDB != null;
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> _getDb() async {
    if (_fallbackMode) return null;
    if (_db != null) return _db!;

    if (!_isIndexedDBAvailable) {
      debugPrint('WebStorageWeb: IndexedDB unavailable. Enabling in-memory fallback.');
      _fallbackMode = true;
      return null;
    }

    try {
      _db = await html.window.indexedDB!.open(
        _dbName,
        version: _dbVersion,
        onUpgradeNeeded: _onUpgradeNeeded,
      );
      try { _db?.onClose?.listen((_) {
        debugPrint('WebStorageWeb: Database connection closed.');
        _db = null;
      }); } catch (_) {}
      return _db!;
    } catch (e) {
      debugPrint('WebStorageWeb: Failed to open IndexedDB: $e. Falling back to memory.');
      _fallbackMode = true;
      return null;
    }
  }

  void _onUpgradeNeeded(dynamic e) {
    try {
      final db = (e.target as dynamic).result;
      for (final store in WebStorageStores.all) {
        if (!db.objectStoreNames!.contains(store)) {
          db.createObjectStore(store);
        }
      }
    } catch (err) {
      debugPrint('WebStorageWeb: Error during onUpgradeNeeded: $err');
    }
  }

  @override
  Future<void> initialize() async {
    await _getDb();
  }

  @override
  Future<String?> getRecord(String storeName, String key) async {
    try {
      final db = await _getDb();
      if (db == null) return _getFallbackStore(storeName)[key];

      final txn = db.transaction(storeName, 'readonly');
      final store = txn.objectStore(storeName);
      final dynamic raw = await store.getObject(key);
      await txn.completed;
      return raw is String ? raw : null;
    } catch (e) {
      debugPrint('WebStorageWeb: getRecord error ($storeName, $key): $e');
      return _getFallbackStore(storeName)[key];
    }
  }

  @override
  Future<List<String>> getAllRecords(String storeName) async {
    try {
      final db = await _getDb();
      if (db == null) return _getFallbackStore(storeName).values.toList();

      final txn = db.transaction(storeName, 'readonly');
      final store = txn.objectStore(storeName);
      final results = <String>[];
      final cursorStream = store.openCursor(autoAdvance: true);
      await for (final cursor in cursorStream) {
        final val = cursor.value;
        if (val is String) {
          results.add(val);
        }
      }
      await txn.completed;
      return results;
    } catch (e) {
      debugPrint('WebStorageWeb: getAllRecords error ($storeName): $e');
      return _getFallbackStore(storeName).values.toList();
    }
  }

  @override
  Future<void> putRecord(String storeName, String key, String jsonValue) async {
    try {
      final db = await _getDb();
      if (db == null) {
        _getFallbackStore(storeName)[key] = jsonValue;
        return;
      }

      final txn = db.transaction(storeName, 'readwrite');
      final store = txn.objectStore(storeName);
      store.put(jsonValue, key);
      await txn.completed;
    } catch (e) {
      debugPrint('WebStorageWeb: putRecord error ($storeName, $key): $e');
      _getFallbackStore(storeName)[key] = jsonValue;
    }
  }

  @override
  Future<void> putBatch(String storeName, Map<String, String> records) async {
    if (records.isEmpty) return;
    try {
      final db = await _getDb();
      if (db == null) {
        _getFallbackStore(storeName).addAll(records);
        return;
      }

      final txn = db.transaction(storeName, 'readwrite');
      final store = txn.objectStore(storeName);
      records.forEach((key, val) {
        store.put(val, key);
      });
      await txn.completed;
    } catch (e) {
      debugPrint('WebStorageWeb: putBatch error ($storeName, count: ${records.length}): $e');
      _getFallbackStore(storeName).addAll(records);
    }
  }

  @override
  Future<void> deleteRecord(String storeName, String key) async {
    try {
      final db = await _getDb();
      if (db == null) {
        _getFallbackStore(storeName).remove(key);
        return;
      }

      final txn = db.transaction(storeName, 'readwrite');
      final store = txn.objectStore(storeName);
      store.delete(key);
      await txn.completed;
    } catch (e) {
      debugPrint('WebStorageWeb: deleteRecord error ($storeName, $key): $e');
      _getFallbackStore(storeName).remove(key);
    }
  }

  @override
  Future<void> deleteBatch(String storeName, List<String> keys) async {
    if (keys.isEmpty) return;
    try {
      final db = await _getDb();
      if (db == null) {
        final store = _getFallbackStore(storeName);
        for (final k in keys) {
          store.remove(k);
        }
        return;
      }

      final txn = db.transaction(storeName, 'readwrite');
      final store = txn.objectStore(storeName);
      for (final key in keys) {
        store.delete(key);
      }
      await txn.completed;
    } catch (e) {
      debugPrint('WebStorageWeb: deleteBatch error ($storeName, count: ${keys.length}): $e');
      final store = _getFallbackStore(storeName);
      for (final k in keys) {
        store.remove(k);
      }
    }
  }

  @override
  Future<void> clearStore(String storeName) async {
    try {
      final db = await _getDb();
      if (db == null) {
        _getFallbackStore(storeName).clear();
        return;
      }

      final txn = db.transaction(storeName, 'readwrite');
      final store = txn.objectStore(storeName);
      store.clear();
      await txn.completed;
    } catch (e) {
      debugPrint('WebStorageWeb: clearStore error ($storeName): $e');
      _getFallbackStore(storeName).clear();
    }
  }

  @override
  Future<void> clearAllStores() async {
    try {
      final db = await _getDb();
      if (db == null) {
        _fallbackStores.clear();
        return;
      }

      final txn = db.transactionList(WebStorageStores.all, 'readwrite');
      for (final storeName in WebStorageStores.all) {
        txn.objectStore(storeName).clear();
      }
      await txn.completed;
    } catch (e) {
      debugPrint('WebStorageWeb: clearAllStores error: $e');
      _fallbackStores.clear();
    }
  }

  @override
  Future<int> count(String storeName) async {
    try {
      final db = await _getDb();
      if (db == null) return _getFallbackStore(storeName).length;

      final txn = db.transaction(storeName, 'readonly');
      final store = txn.objectStore(storeName);
      final count = await store.count();
      await txn.completed;
      return count;
    } catch (e) {
      debugPrint('WebStorageWeb: count error ($storeName): $e');
      return _getFallbackStore(storeName).length;
    }
  }

  @override
  Future<void> close() async {
    try {
      _db?.close();
      _db = null;
    } catch (_) {}
  }
}

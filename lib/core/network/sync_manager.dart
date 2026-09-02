import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dio/dio.dart';
import 'package:propkart/core/api/api_constants.dart';
import 'package:propkart/core/api/api_client.dart';
import 'package:propkart/core/storage/isar_service.dart';
import 'package:propkart/core/storage/repository_coordinator.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/performance_logger.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/properties/services/properties_service.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/requirements/services/requirements_service.dart';
import 'package:propkart/features/dashboard/models/dashboard_summary.dart';
import 'package:propkart/features/builders/models/builder_model.dart';
import 'package:propkart/features/builders/services/builders_service.dart';
import 'package:propkart/features/owners/models/owner_model.dart';
import 'package:propkart/features/owners/services/owners_service.dart';
import 'package:propkart/core/storage/model_mappers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/features/properties/repository/properties_repository.dart';
import '../utils/app_logger.dart';

enum SyncState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  syncing,
  offline
}

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  final RepositoryCoordinator _coordinator = RepositoryCoordinator();

  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  SyncState _state = SyncState.disconnected;
  SyncState get state => _state;

  bool isSyncCompleted = false;
  final ValueNotifier<bool> isSyncing = ValueNotifier<bool>(false);

  Future<bool> hasLocalCache() async {
    try {
      final count = await _coordinator.lookupLocal.getLookupsCount();
      return count > 0;
    } catch (_) {
      return false;
    }
  }

  Future<void> performStartupSync() async {
    isSyncing.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientVersion = prefs.getInt('last_lookup_version') ?? 0;
      
      int serverVersion = 0;
      try {
        final response = await ApiClient().get('/sync/status');
        serverVersion = response.data['schemaVersion'] ?? 0;
      } catch (e) {
        AppLogger.w("Failed to fetch sync status: $e");
        final lookupCount = await _coordinator.lookupLocal.getLookupsCount();
        if (lookupCount == 0) {
          rethrow;
        }
      }
      
      final lookupCount = await _coordinator.lookupLocal.getLookupsCount();
      if (lookupCount == 0 || serverVersion != clientVersion) {
        AppLogger.sync("Lookup version mismatch or empty. Downloading lookup tables...");
        await PropertiesRepository().fetchAndSaveMetadata();
        if (serverVersion > 0) {
          await prefs.setInt('last_lookup_version', serverVersion);
        }
      } else {
        AppLogger.sync("Lookup tables up to date (version: $clientVersion). Skipping lookup sync.");
      }
      
      await triggerDeltaSync();
      isSyncCompleted = true;
    } finally {
      isSyncing.value = false;
    }
  }

  final _stateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get stateStream => _stateController.stream;

  int _ref = 0;
  int _reconnectAttempts = 0;

  final List<Map<String, dynamic>> _incomingBuffer = [];
  Timer? _batchTimer;

  Future<void> initialize() async {
  }

  /// Trigger delta sync after user authentication.
  Future<void> connectAfterAuth() async {
    await connect();
  }

  void _updateState(SyncState newState) {
    _state = newState;
    _stateController.add(newState);
    AppLogger.d("Sync State changed to: $newState");
  }

  Future<void> connect() async {
    try {
      _updateState(SyncState.connecting);
      await triggerDeltaSync();
      _updateState(SyncState.connected);
      _reconnectAttempts = 0;
    } catch (e) {
      _handleDisconnect("Sync failure: $e");
    }
  }

  void _joinReplicationChannel() {
    // Scoped tables only — never subscribe to entire public schema.
    const watchedTables = <String>[
      'properties',
      'requirements',
      'notifications',
      'followups',
      'site_visits',
    ];
    _sendJson({
      "topic": "realtime:propkart",
      "event": "phx_join",
      "payload": {
        "config": {
          "postgres_changes": watchedTables
              .map((table) => {
                    "event": "*",
                    "schema": "public",
                    "table": table,
                  })
              .toList(),
        }
      },
      "ref": (++_ref).toString()
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_state == SyncState.connected) {
        _sendJson({
          "topic": "phoenix",
          "event": "heartbeat",
          "payload": {},
          "ref": (++_ref).toString()
        });
      }
    });
  }

  void _sendJson(Map<String, dynamic> data) {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode(data));
      } catch (_) {}
    }
  }

  void _handleIncomingMessage(dynamic rawMessage) {
    try {
      final data = jsonDecode(rawMessage as String);
      final event = data['event'];
      final topic = data['topic'];

      if (event == "postgres_changes" && topic == "realtime:public") {
        final payload = data['payload'] as Map<String, dynamic>? ?? {};
        final table = payload['table'] as String?;
        final record = payload['record'] as Map<String, dynamic>?;
        final oldRecord = payload['old_record'] as Map<String, dynamic>?;
        final eventType = payload['type'] as String?;

        if (table != null && eventType != null) {
          _incomingBuffer.add({
            'table': table,
            'type': eventType,
            'record': record,
            'old_record': oldRecord,
          });

          _batchTimer ??= Timer(const Duration(milliseconds: 100), _processBatch);
        }
      }
    } catch (e) {
      AppLogger.e("Error parsing raw socket stream: $e");
    }
  }

  Future<void> _processBatch() async {
    _batchTimer = null;
    if (_incomingBuffer.isEmpty) return;

    final batch = List<Map<String, dynamic>>.from(_incomingBuffer);
    _incomingBuffer.clear();

    final start = DateTime.now();
    final tablesToRefresh = <String>{};

    final propertiesToPut = <PropertyLocal>[];
    final propertiesToDelete = <String>[];

    final requirementsToPut = <RequirementLocal>[];
    final requirementsToDelete = <String>[];

    final followupsToPut = <FollowupLocal>[];
    final followupsToDelete = <String>[];

    final buildersToPut = <BuilderLocal>[];
    final buildersToDelete = <String>[];

    final ownersToPut = <OwnerLocal>[];
    final ownersToDelete = <String>[];

    final apiClient = ApiClient();

    for (final item in batch) {
      final table = item['table'] as String;
      final type = item['type'] as String;
      final record = item['record'] as Map<String, dynamic>?;
      final oldRecord = item['old_record'] as Map<String, dynamic>?;

      tablesToRefresh.add(table);

      if (type == "DELETE" && oldRecord != null) {
        final id = oldRecord['id'] as String?;
        if (id != null) {
          if (table == "properties") propertiesToDelete.add(id);
          else if (table == "requirements") requirementsToDelete.add(id);
          else if (table == "followups") followupsToDelete.add(id);
          else if (table == "builders") buildersToDelete.add(id);
          else if (table == "owners") ownersToDelete.add(id);
        }
      } else if (record != null) {
        if (table == "properties") {
          try {
            final id = record['id'] as String;
            final response = await apiClient.get('/properties/$id');
            if (response.statusCode == 200 && response.data != null) {
              final data = response.data['data']?['property'];
              if (data != null) {
                propertiesToPut.add(PropertyModel.fromJson(data).toLocal());
              } else {
                throw Exception("Property data not found in response");
              }
            } else {
              throw Exception("Failed to fetch property details: Status ${response.statusCode}");
            }
          } catch (e) {
            AppLogger.w("Failed to fetch property details for $record, falling back to raw record: $e");
            final enriched = await _enrichRawRecord("properties", record);
            propertiesToPut.add(PropertyModel.fromJson(enriched).toLocal());
          }
        } else if (table == "requirements") {
          try {
            final id = record['id'] as String;
            final response = await apiClient.get('/requirements/$id');
            if (response.statusCode == 200 && response.data != null) {
              final data = response.data['data']?['requirement'];
              if (data != null) {
                requirementsToPut.add(RequirementModel.fromJson(data).toLocal());
              } else {
                throw Exception("Requirement data not found in response");
              }
            } else {
              throw Exception("Failed to fetch requirement details: Status ${response.statusCode}");
            }
          } catch (e) {
            AppLogger.w("Failed to fetch requirement details for $record, falling back to raw record: $e");
            final enriched = await _enrichRawRecord("requirements", record);
            requirementsToPut.add(RequirementModel.fromJson(enriched).toLocal());
          }
        } else if (table == "followups") {
          followupsToPut.add(DashboardFollowup.fromJson(record).toLocal('System'));
        } else if (table == "builders") {
          buildersToPut.add(BuilderModel.fromJson(record).toLocal());
        } else if (table == "owners") {
          ownersToPut.add(OwnerModel.fromJson(record).toLocal());
        }
      }
    }

    final writeStart = DateTime.now();

    if (kIsWeb) {
      for (final p in propertiesToPut) PropertyLocalRepository.inMemory[p.id] = p;
      for (final id in propertiesToDelete) PropertyLocalRepository.inMemory.remove(id);

      for (final r in requirementsToPut) RequirementLocalRepository.inMemory[r.id] = r;
      for (final id in requirementsToDelete) RequirementLocalRepository.inMemory.remove(id);

      for (final f in followupsToPut) FollowupLocalRepository.inMemory[f.id] = f;
      for (final id in followupsToDelete) FollowupLocalRepository.inMemory.remove(id);

      for (final b in buildersToPut) BuilderLocalRepository.inMemory[b.id] = b;
      for (final id in buildersToDelete) BuilderLocalRepository.inMemory.remove(id);

      for (final o in ownersToPut) OwnerLocalRepository.inMemory[o.id] = o;
      for (final id in ownersToDelete) OwnerLocalRepository.inMemory.remove(id);
    } else {
      final isar = IsarService().isar;
      try {
        await isar.writeTxn(() async {
          if (propertiesToPut.isNotEmpty) await isar.propertyLocals.putAll(propertiesToPut);
          for (final id in propertiesToDelete) {
            await isar.propertyLocals.filter().idEqualTo(id).deleteAll();
          }

          if (requirementsToPut.isNotEmpty) await isar.requirementLocals.putAll(requirementsToPut);
          for (final id in requirementsToDelete) {
            await isar.requirementLocals.filter().idEqualTo(id).deleteAll();
          }

          if (followupsToPut.isNotEmpty) await isar.followupLocals.putAll(followupsToPut);
          for (final id in followupsToDelete) {
            await isar.followupLocals.filter().idEqualTo(id).deleteAll();
          }

          if (buildersToPut.isNotEmpty) await isar.builderLocals.putAll(buildersToPut);
          for (final id in buildersToDelete) {
            await isar.builderLocals.filter().idEqualTo(id).deleteAll();
          }

          if (ownersToPut.isNotEmpty) await isar.ownerLocals.putAll(ownersToPut);
          for (final id in ownersToDelete) {
            await isar.ownerLocals.filter().idEqualTo(id).deleteAll();
          }
        });
      } catch (e) {
        AppLogger.e("Batch write transaction failed: $e");
      }
    }

    final isarWriteMs = DateTime.now().difference(writeStart).inMilliseconds;

    for (final table in tablesToRefresh) {
      if (table == "properties") _coordinator.refreshProperties();
      else if (table == "requirements") _coordinator.refreshRequirements();
      else if (table == "followups" || table == "site_visits") _coordinator.refreshDashboard();
      else if (table == "builders") _coordinator.refreshBuilders();
      else if (table == "owners") _coordinator.refreshOwners();
    }
    final totalMs = DateTime.now().difference(start).inMilliseconds;

    PerformanceLogger().logMetric(
      operation: 'SyncManager: Realtime Event | Tables: ${tablesToRefresh.join(", ")} | Batch: ${batch.length} rows',
      isarWriteMs: isarWriteMs,
      totalMs: totalMs,
    );
  }

  void _handleDisconnect(String reason) {
    AppLogger.d("Sync disconnected: $reason");
    _heartbeatTimer?.cancel();
    _channelSubscription?.cancel();
    try {
      _channel?.sink.close();
    } catch (_) {}

    _updateState(SyncState.disconnected);
    PerformanceLogger().logMetric(
      operation: 'SyncManager: Realtime disconnected | $reason',
      totalMs: 0,
    );

    _reconnectAttempts++;
    final backoffSeconds = (_reconnectAttempts * 2).clamp(2, 30);
    AppLogger.d("Sync reconnecting in $backoffSeconds seconds... (Attempt $_reconnectAttempts)");

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      connect();
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _batchTimer?.cancel();
    _channelSubscription?.cancel();
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    _incomingBuffer.clear();
    isSyncCompleted = false;
    isSyncing.value = false;
    _updateState(SyncState.disconnected);
  }

  Future<void> triggerDeltaSync() async {
    _updateState(SyncState.syncing);
    AppLogger.sync("Starting Delta Sync...");
    final start = DateTime.now();

    try {
      // 1. Fetch fresh lists from backend services
      final propRes = await PropertiesService().getProperties();
      final reqRes = await RequirementsService().getRequirements();
      final builderRes = await BuildersService().getBuilders();
      final ownerRes = await OwnersService().getOwners();

      final List<dynamic> serverProperties = propRes['data']?['properties'] ?? [];
      final List<dynamic> serverRequirements = reqRes['data']?['requirements'] ?? [];
      final List<dynamic> serverBuilders = builderRes['data']?['builders'] ?? [];
      final List<dynamic> serverOwners = ownerRes['data']?['owners'] ?? [];

      // 2. Perform Conflict Detection before replaying outbox
      final outboxItems = await _coordinator.outboxLocal.getQueuedRequests();
      final conflictedIds = <String>{};

      for (final item in outboxItems) {
        final uriParts = item.endpoint.split('/');
        final targetId = uriParts.length > 2 ? uriParts[2] : null;

        if (targetId != null) {
          if (item.endpoint.startsWith('/properties')) {
            final serverItem = serverProperties.firstWhere((p) => p['id'] == targetId, orElse: () => null);
            if (serverItem != null && serverItem['updated_at'] != null) {
              final serverUpdatedAt = DateTime.parse(serverItem['updated_at']);
              if (serverUpdatedAt.isAfter(item.createdAt)) {
                conflictedIds.add(item.id);
                AppLogger.w("Conflict detected: Property $targetId has a newer server edit. Server wins.");
              }
            }
          } else if (item.endpoint.startsWith('/requirements')) {
            final serverItem = serverRequirements.firstWhere((r) => r['id'] == targetId, orElse: () => null);
            if (serverItem != null && serverItem['updated_at'] != null) {
              final serverUpdatedAt = DateTime.parse(serverItem['updated_at']);
              if (serverUpdatedAt.isAfter(item.createdAt)) {
                conflictedIds.add(item.id);
                AppLogger.w("Conflict detected: Requirement $targetId has a newer server edit. Server wins.");
              }
            }
          }
        }
      }

      // Remove conflicted outbox requests (Server-wins conflict policy)
      for (final outboxId in conflictedIds) {
        await _coordinator.outboxLocal.removeRequest(outboxId);
      }

      // 3. Replay remaining safe outbox operations
      await processOutboxQueue();

      // 4. Merge server data into local database
      final pList = serverProperties.map((item) => PropertyModel.fromJson(item).toLocal()).toList();
      final rList = serverRequirements.map((item) => RequirementModel.fromJson(item).toLocal()).toList();
      final bList = serverBuilders.map((item) => BuilderModel.fromJson(item).toLocal()).toList();
      final oList = serverOwners.map((item) => OwnerModel.fromJson(item).toLocal()).toList();

      if (kIsWeb) {
        PropertyLocalRepository.inMemory.clear();
        for (final p in pList) PropertyLocalRepository.inMemory[p.id] = p;

        RequirementLocalRepository.inMemory.clear();
        for (final r in rList) RequirementLocalRepository.inMemory[r.id] = r;

        BuilderLocalRepository.inMemory.clear();
        for (final b in bList) BuilderLocalRepository.inMemory[b.id] = b;

        OwnerLocalRepository.inMemory.clear();
        for (final o in oList) OwnerLocalRepository.inMemory[o.id] = o;
      } else {
        final isar = IsarService().isar;
        await isar.writeTxn(() async {
          await isar.propertyLocals.clear();
          await isar.propertyLocals.putAll(pList);

          await isar.requirementLocals.clear();
          await isar.requirementLocals.putAll(rList);

          await isar.builderLocals.clear();
          await isar.builderLocals.putAll(bList);

          await isar.ownerLocals.clear();
          await isar.ownerLocals.putAll(oList);
        });
      }

      _coordinator.refreshProperties();
      _coordinator.refreshRequirements();
      _coordinator.refreshBuilders();
      _coordinator.refreshOwners();

      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'SyncManager: Delta Sync completed successfully | Merged: ${pList.length + rList.length} records',
        totalMs: totalMs,
      );

    } catch (e) {
      AppLogger.e("Delta Sync failed: $e");
    }
  }

  Future<void> processOutboxQueue() async {
    AppLogger.sync("Replaying Outbox Queue...");
    final start = DateTime.now();
    final outboxItems = await _coordinator.outboxLocal.getQueuedRequests();

    if (outboxItems.isEmpty) return;

    final apiClient = ApiClient();
    int replayedCount = 0;

    for (final item in outboxItems) {
      try {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;

        Response? response;
        if (item.method == 'POST') {
          response = await apiClient.post(item.endpoint, payload);
        } else if (item.method == 'PUT') {
          response = await apiClient.put(item.endpoint, payload);
        } else if (item.method == 'DELETE') {
          response = await apiClient.delete(item.endpoint);
        }

        if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
          await _coordinator.outboxLocal.removeRequest(item.id);
          replayedCount++;
        }
      } catch (e) {
        AppLogger.w("Outbox replay failed for ${item.endpoint}: $e");
        break; // Stop replaying on network failure, retry on next cycle
      }
    }

    if (replayedCount > 0) {
      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'SyncManager: Replayed $replayedCount outbox items successfully',
        totalMs: totalMs,
      );
    }
  }

  Future<Map<String, dynamic>> _enrichRawRecord(String table, Map<String, dynamic> record) async {
    final enriched = Map<String, dynamic>.from(record);

    Future<String> getName(String category, String? id) async {
      if (id == null || id.isEmpty) return 'N/A';
      if (kIsWeb) {
        for (final l in LookupLocalRepository.inMemory.values) {
          if (l.category == category && l.id == id) {
            return l.name;
          }
        }
        return 'N/A';
      } else {
        final isar = IsarService().isar;
        final match = await isar.lookupItemLocals.filter().categoryEqualTo(category).idEqualTo(id).findFirst();
        return match?.name ?? 'N/A';
      }
    }

    if (table == "properties") {
      enriched['category'] = {'name': await getName('property_category', record['category_id'])};
      enriched['property_type'] = {'name': await getName('property_type', record['property_type_id'])};
      enriched['configuration'] = {'name': await getName('configuration', record['configuration_id'])};
      enriched['listing_type'] = {'name': await getName('listing_type', record['listing_type_id'])};
      enriched['property_status'] = {'name': await getName('property_status', record['property_status_id'])};
      enriched['city'] = {'city_name': await getName('city', record['city_id'])};
      enriched['area'] = {
        'area_name': await getName('area', record['area_id']),
        'pincode': record['pincode'] ?? 'N/A'
      };
      
      enriched['furnishing_type'] = {'name': await getName('furnishing_type', record['furnishing_type_id'])};
      enriched['facing_type'] = {'name': await getName('facing_type', record['facing_type_id'])};
      enriched['ownership_type'] = {'name': await getName('ownership_type', record['ownership_type_id'])};
      enriched['brokerage_type'] = {'name': await getName('brokerage_type', record['brokerage_type_id'])};
    } else if (table == "requirements") {
      enriched['category'] = {'name': await getName('property_category', record['category_id'])};
      enriched['property_type'] = {'name': await getName('property_type', record['property_type_id'])};
      enriched['configuration'] = {'name': await getName('configuration', record['configuration_id'])};
      enriched['listing_type'] = {'name': await getName('listing_type', record['listing_type_id'])};
      enriched['city'] = {'city_name': await getName('city', record['city_id'])};
      enriched['area'] = {'area_name': await getName('area', record['area_id'])};
    }

    return enriched;
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../storage/isar_service.dart';
import '../storage/repository_coordinator.dart';
import '../storage/local_repositories.dart';
import '../storage/performance_logger.dart';
import '../storage/isar_collections.dart';
import '../../features/properties/models/property_model.dart';
import '../../features/properties/services/properties_service.dart';
import '../../features/requirements/models/requirement_model.dart';
import '../../features/requirements/services/requirements_service.dart';
import '../../features/dashboard/models/dashboard_summary.dart';
import '../../features/builders/models/builder_model.dart';
import '../../features/builders/services/builders_service.dart';
import '../../features/owners/models/owner_model.dart';
import '../../features/owners/services/owners_service.dart';
import '../storage/model_mappers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/clients/models/client_model.dart';
import '../../features/clients/services/clients_service.dart';
import '../../features/dashboard/services/dashboard_service.dart';
import '../../features/properties/repository/properties_repository.dart';
import '../../features/integration/services/integration_service.dart';
import '../../features/requirements/services/match_criteria_manager.dart';
import '../../features/settings/services/upload_limits_manager.dart';
import '../../features/campaign/bloc/campaign_connections_bloc.dart';
import '../utils/app_logger.dart';
import 'sync_engine.dart';
import 'sync_telemetry.dart';

enum SyncState {
  initializing,
  offline,
  connecting,
  syncing,
  live,
  degraded,
  reconnecting,
  conflictResolution,
  error,
  stopped,

  // Legacy aliases for backward compatibility
  connected,
  disconnected,
}

extension SyncStateX on SyncState {
  String get nameUpper {
    switch (this) {
      case SyncState.initializing:
        return 'INITIALIZING';
      case SyncState.offline:
        return 'OFFLINE';
      case SyncState.connecting:
        return 'CONNECTING';
      case SyncState.syncing:
        return 'SYNCING';
      case SyncState.live:
      case SyncState.connected:
        return 'LIVE';
      case SyncState.degraded:
        return 'DEGRADED';
      case SyncState.reconnecting:
        return 'RECONNECTING';
      case SyncState.conflictResolution:
        return 'CONFLICT_RESOLUTION';
      case SyncState.error:
        return 'ERROR';
      case SyncState.stopped:
      case SyncState.disconnected:
        return 'STOPPED';
    }
  }

  bool get isLive => this == SyncState.live || this == SyncState.connected;
  bool get isOffline => this == SyncState.offline || this == SyncState.disconnected;
  bool get isSyncing => this == SyncState.syncing;
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
    final hasCache = await hasLocalCache();
    if (!hasCache) {
      isSyncing.value = true;
    }
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

      // Ensure authoritative match criteria is loaded from backend DB for the team
      unawaited(MatchCriteriaManager().fetchFromBackend(silent: true));
      unawaited(UploadLimitsManager().fetchFromBackend(silent: true));

      // Prewarm campaign leads so they are ready before navigating to Campaign tab
      try {
        await IntegrationService().ensureLoaded();
        unawaited(IntegrationService().fetchServerLeads(silent: true));
        unawaited(IntegrationService().fetchHealthAlerts());
      } catch (e) {
        AppLogger.w("Campaign leads startup prefetch error: $e");
      }
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
    await connect(skipDeltaSync: true);
  }

  static bool isValidTransition(SyncState from, SyncState to) {
    if (from == to) return false;
    // Normalize aliases
    final f = (from == SyncState.connected) ? SyncState.live : (from == SyncState.disconnected ? SyncState.offline : from);
    final t = (to == SyncState.connected) ? SyncState.live : (to == SyncState.disconnected ? SyncState.offline : to);
    if (f == t) return false;

    switch (f) {
      case SyncState.initializing:
        return t == SyncState.connecting || t == SyncState.offline || t == SyncState.error;
      case SyncState.offline:
        return t == SyncState.connecting || t == SyncState.stopped;
      case SyncState.connecting:
        return t == SyncState.syncing || t == SyncState.live || t == SyncState.reconnecting || t == SyncState.offline || t == SyncState.error;
      case SyncState.syncing:
        return t == SyncState.live || t == SyncState.conflictResolution || t == SyncState.degraded || t == SyncState.reconnecting || t == SyncState.offline || t == SyncState.error;
      case SyncState.live:
        return t == SyncState.syncing || t == SyncState.reconnecting || t == SyncState.offline || t == SyncState.conflictResolution || t == SyncState.stopped;
      case SyncState.degraded:
        return t == SyncState.syncing || t == SyncState.live || t == SyncState.reconnecting || t == SyncState.offline || t == SyncState.stopped;
      case SyncState.reconnecting:
        return t == SyncState.connecting || t == SyncState.syncing || t == SyncState.offline || t == SyncState.error || t == SyncState.stopped;
      case SyncState.conflictResolution:
        return t == SyncState.syncing || t == SyncState.live || t == SyncState.error;
      case SyncState.error:
        return t == SyncState.initializing || t == SyncState.connecting || t == SyncState.stopped;
      case SyncState.stopped:
        return t == SyncState.initializing || t == SyncState.connecting || t == SyncState.offline;
      default:
        return true;
    }
  }

  bool transitionTo(SyncState newState, {String? reason}) {
    if (!isValidTransition(_state, newState)) {
      AppLogger.w("Invalid or redundant SyncState transition: $_state -> $newState (${reason ?? 'no reason'})");
      return false;
    }
    final oldState = _state;
    _state = newState;
    _stateController.add(newState);
    AppLogger.d("Sync State changed: $oldState -> $newState (${reason ?? ''})");
    return true;
  }

  void _updateState(SyncState newState, {String? reason}) {
    if (_state == newState) return;
    SyncState target = newState;
    if (target == SyncState.connected) target = SyncState.live;
    if (target == SyncState.disconnected) target = SyncState.offline;

    if (isValidTransition(_state, target)) {
      transitionTo(target, reason: reason);
    } else {
      _state = target;
      _stateController.add(target);
      AppLogger.d("Sync State set to: $target (${reason ?? ''})");
    }
  }

  Future<void> connect({bool skipDeltaSync = false}) async {
    try {
      _updateState(SyncState.connecting);
      if (!skipDeltaSync) {
        await triggerDeltaSync();
      }
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
      'integration_leads',
      'leads',
      'campaign_connections',
      'campaign_lead_followups',
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

      if (table == "integration_leads" || table == "leads") {
        IntegrationService().handleRealtimeEvent(type, record, oldRecord);
        continue;
      } else if (table == "campaign_connections") {
        CampaignConnectionsBloc().add(const FetchCampaignConnectionsEvent(silent: true));
        continue;
      } else if (table == "campaign_lead_followups") {
        IntegrationService().handleFollowupRealtimeEvent(type, record, oldRecord);
        continue;
      } else if (table == "settings") {
        unawaited(MatchCriteriaManager().fetchFromBackend(silent: true));
        continue;
      }

      if (type == "DELETE" && oldRecord != null) {
        final id = oldRecord['id'] as String?;
        if (id != null) {
          if (table == "properties") propertiesToDelete.add(id);
          else if (table == "requirements") requirementsToDelete.add(id);
          else if (table == "followups") followupsToDelete.add(id);
          else if (table == "builders") buildersToDelete.add(id);
          else if (table == "owners") ownersToDelete.add(id);
          else if (table == "integration_leads" || table == "leads") {
            unawaited(IntegrationService().fetchServerLeads(silent: true));
          } else if (table == "campaign_connections") {
            CampaignConnectionsBloc().add(const FetchCampaignConnectionsEvent(silent: true));
          }
        }
      } else if (record != null) {
        if (table == "integration_leads" || table == "leads") {
          unawaited(IntegrationService().fetchServerLeads(silent: true));
        } else if (table == "campaign_connections") {
          CampaignConnectionsBloc().add(const FetchCampaignConnectionsEvent(silent: true));
        } else if (table == "properties") {
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
          if (propertiesToDelete.isNotEmpty) await isar.propertyLocals.deleteAllById(propertiesToDelete);

          if (requirementsToPut.isNotEmpty) await isar.requirementLocals.putAll(requirementsToPut);
          if (requirementsToDelete.isNotEmpty) await isar.requirementLocals.deleteAllById(requirementsToDelete);

          if (followupsToPut.isNotEmpty) await isar.followupLocals.putAll(followupsToPut);
          if (followupsToDelete.isNotEmpty) await isar.followupLocals.deleteAllById(followupsToDelete);

          if (buildersToPut.isNotEmpty) await isar.builderLocals.putAll(buildersToPut);
          if (buildersToDelete.isNotEmpty) await isar.builderLocals.deleteAllById(buildersToDelete);

          if (ownersToPut.isNotEmpty) await isar.ownerLocals.putAll(ownersToPut);
          if (ownersToDelete.isNotEmpty) await isar.ownerLocals.deleteAllById(ownersToDelete);
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

      // 4. Incremental merge into local database (Zero table clears!)
      final pendingOutboxIds = await _getPendingOutboxTargetIds();
      final pList = serverProperties.map((item) => PropertyModel.fromJson(item).toLocal()).toList();
      final rList = serverRequirements.map((item) => RequirementModel.fromJson(item).toLocal()).toList();
      final bList = serverBuilders.map((item) => BuilderModel.fromJson(item).toLocal()).toList();
      final oList = serverOwners.map((item) => OwnerModel.fromJson(item).toLocal()).toList();

      final propChanges = await _syncPropertiesIncremental(pList, pendingOutboxIds);
      final reqChanges = await _syncRequirementsIncremental(rList, pendingOutboxIds);
      final builderChanges = await _syncBuildersIncremental(bList, pendingOutboxIds);
      final ownerChanges = await _syncOwnersIncremental(oList, pendingOutboxIds);

      // Only broadcast refresh if actual data was mutated
      if (propChanges > 0) _coordinator.refreshProperties();
      if (reqChanges > 0) _coordinator.refreshRequirements();
      if (builderChanges > 0) _coordinator.refreshBuilders();
      if (ownerChanges > 0) _coordinator.refreshOwners();

      final totalChanges = propChanges + reqChanges + builderChanges + ownerChanges;
      final totalMs = DateTime.now().difference(start).inMilliseconds;
      PerformanceLogger().logMetric(
        operation: 'SyncManager: Delta Sync completed | Mutated: $totalChanges records (${pList.length + rList.length} verified)',
        totalMs: totalMs,
      );

      SyncTelemetryLogger().record(SyncTelemetryRecord(
        syncId: 'sync_${DateTime.now().millisecondsSinceEpoch}',
        syncType: 'DELTA',
        stateFrom: 'SYNCING',
        stateTo: 'LIVE',
        startedAt: start,
        completedAt: DateTime.now(),
        durationMs: totalMs,
        recordsReceived: pList.length + rList.length + bList.length + oList.length,
        recordsApplied: totalChanges,
        recordsSkipped: (pList.length + rList.length + bList.length + oList.length) - totalChanges,
        conflictsDetected: conflictedIds.length,
        conflictsResolved: conflictedIds.length,
        success: true,
      ));

    } catch (e) {
      AppLogger.e("Delta Sync failed: $e");
      SyncTelemetryLogger().record(SyncTelemetryRecord(
        syncId: 'sync_err_${DateTime.now().millisecondsSinceEpoch}',
        syncType: 'DELTA',
        stateFrom: 'SYNCING',
        stateTo: 'ERROR',
        startedAt: start,
        completedAt: DateTime.now(),
        durationMs: DateTime.now().difference(start).inMilliseconds,
        success: false,
        failureReason: e.toString(),
      ));
    }
  }

  bool _isPingInProgress = false;

  /// Lightweight, non-blocking 9-second periodic database ping.
  /// Replays outbox, checks for server deltas across all core entities in parallel,
  /// merges them into local Isar storage, and notifies reactive UI streams ONLY on actual changes.
  Future<int> pingDatabase() async {
    if (_isPingInProgress) {
      AppLogger.d("SyncManager: Ping already in progress, skipping tick.");
      return 0;
    }
    _isPingInProgress = true;
    final start = DateTime.now();

    try {
      // 1. Replay queued offline mutations first
      await processOutboxQueue();

      // 2. Fetch server data across all core entities in parallel
      final coreFutures = Future.wait<Map<String, dynamic>>([
        PropertiesService().getProperties().catchError((e) => <String, dynamic>{}),
        RequirementsService().getRequirements().catchError((e) => <String, dynamic>{}),
        BuildersService().getBuilders().catchError((e) => <String, dynamic>{}),
        OwnersService().getOwners().catchError((e) => <String, dynamic>{}),
        ClientsService().getClients().catchError((e) => <String, dynamic>{}),
        DashboardService().getDashboardData().catchError((e) => <String, dynamic>{}),
      ]);
      final campaignFuture = IntegrationService().fetchServerLeads(silent: true).catchError((e) => 0);
      unawaited(MatchCriteriaManager().fetchFromBackend(silent: true));

      final results = await coreFutures;
      final campaignCount = await campaignFuture;

      final propRes = results[0];
      final reqRes = results[1];
      final builderRes = results[2];
      final ownerRes = results[3];
      final clientRes = results[4];
      final dashRes = results[5];

      final List<dynamic> serverProperties = propRes['data']?['properties'] ?? [];
      final List<dynamic> serverRequirements = reqRes['data']?['requirements'] ?? [];
      final List<dynamic> serverBuilders = builderRes['data']?['builders'] ?? [];
      final List<dynamic> serverOwners = ownerRes['data']?['owners'] ?? [];
      final List<dynamic> serverClients = clientRes['data']?['clients'] ?? [];

      final pList = serverProperties.map((item) => PropertyModel.fromJson(item).toLocal()).toList();
      final rList = serverRequirements.map((item) => RequirementModel.fromJson(item).toLocal()).toList();
      final bList = serverBuilders.map((item) => BuilderModel.fromJson(item).toLocal()).toList();
      final oList = serverOwners.map((item) => OwnerModel.fromJson(item).toLocal()).toList();
      final cList = serverClients.map((item) => ClientModel.fromJson(item).toLocal()).toList();

      DashboardData? freshDashboard;
      List<FollowupLocal> fList = [];
      if (dashRes.isNotEmpty && (dashRes['summary'] != null || dashRes['metrics'] != null)) {
        try {
          freshDashboard = DashboardData.fromJson(dashRes);
          final listData = dashRes['followups'] as List? ?? [];
          final freshFollowups = listData.map((item) => DashboardFollowup.fromJson(item)).toList();
          fList = freshFollowups.map((f) => f.toLocal('System')).toList();
        } catch (_) {}
      }

      // Reconcile pending outbox IDs to avoid deleting offline created entities
      final pendingOutboxIds = await _getPendingOutboxTargetIds();

      // Incremental sync for each table (returns number of actual modified records)
      final propChanges = await _syncPropertiesIncremental(pList, pendingOutboxIds);
      final reqChanges = await _syncRequirementsIncremental(rList, pendingOutboxIds);
      final builderChanges = await _syncBuildersIncremental(bList, pendingOutboxIds);
      final ownerChanges = await _syncOwnersIncremental(oList, pendingOutboxIds);
      final clientChanges = await _syncClientsIncremental(cList, pendingOutboxIds);
      final followupChanges = await _syncFollowupsIncremental(fList, pendingOutboxIds);
      final dashChanges = await _syncDashboardIncremental(freshDashboard);

      // Notify debounced UI streams ONLY if actual data changed!
      if (propChanges > 0) _coordinator.refreshProperties();
      if (reqChanges > 0) _coordinator.refreshRequirements();
      if (builderChanges > 0) _coordinator.refreshBuilders();
      if (ownerChanges > 0) _coordinator.refreshOwners();
      if (clientChanges > 0) _coordinator.refreshClients();
      if (dashChanges > 0 || followupChanges > 0) _coordinator.refreshDashboard();

      final totalUpdated = propChanges + reqChanges + builderChanges + ownerChanges + clientChanges + followupChanges + campaignCount;
      final elapsedMs = DateTime.now().difference(start).inMilliseconds;
      AppLogger.sync("SyncManager: 9s database ping completed in ${elapsedMs}ms ($totalUpdated actual changes applied)");

      return totalUpdated;
    } catch (e) {
      AppLogger.w("SyncManager: 9s database ping encountered issue: $e");
      return 0;
    } finally {
      _isPingInProgress = false;
    }
  }

  Future<Set<String>> _getPendingOutboxTargetIds() async {
    final pendingRequests = await _coordinator.outboxLocal.getQueuedRequests();
    final ids = <String>{};
    for (final req in pendingRequests) {
      final parts = req.endpoint.split('/');
      if (parts.length > 2 && parts[2].isNotEmpty) {
        ids.add(parts[2]);
      }
    }
    return ids;
  }

  Future<int> _syncPropertiesIncremental(List<PropertyLocal> serverList, Set<String> pendingOutboxIds) async {
    if (serverList.isEmpty) return 0;

    final isar = kIsWeb ? null : IsarService().isar;
    final Map<String, PropertyLocal> localMap;
    if (kIsWeb) {
      localMap = Map<String, PropertyLocal>.from(PropertyLocalRepository.inMemory);
    } else {
      final all = await isar!.propertyLocals.where().findAll();
      localMap = {for (final p in all) p.id: p};
    }

    final diff = SyncEngine.computeDiff<PropertyLocal>(
      serverItems: serverList,
      localItems: localMap,
      getId: (p) => p.id,
      isEqual: SyncEngine.arePropertiesEqual,
      pendingOutboxIds: pendingOutboxIds,
      preserveLocalMetadata: (serverItem, localItem) {
        serverItem.isarId = localItem.isarId;
      },
    );

    if (!diff.hasChanges) {
      return 0;
    }

    if (kIsWeb) {
      for (final p in diff.toInsert) {
        PropertyLocalRepository.inMemory[p.id] = p;
      }
      for (final p in diff.toUpdate) {
        PropertyLocalRepository.inMemory[p.id] = p;
      }
      for (final id in diff.toDelete) {
        PropertyLocalRepository.inMemory.remove(id);
      }
      await _coordinator.propertyLocal.saveInMemoryCacheOnlyIfChanged();
      return diff.totalChanges;
    }

    await SyncEngine.applyBatchedWrites<PropertyLocal>(
      diff: diff,
      putBatch: (batch) => isar!.writeTxn(() => isar.propertyLocals.putAll(batch)),
      deleteBatch: (ids) => isar!.writeTxn(() => isar.propertyLocals.deleteAllById(ids)),
      batchSize: SyncEngine.defaultBatchSize,
    );

    return diff.totalChanges;
  }

  Future<int> _syncRequirementsIncremental(List<RequirementLocal> serverList, Set<String> pendingOutboxIds) async {
    if (serverList.isEmpty) return 0;

    final isar = kIsWeb ? null : IsarService().isar;
    final Map<String, RequirementLocal> localMap;
    if (kIsWeb) {
      localMap = Map<String, RequirementLocal>.from(RequirementLocalRepository.inMemory);
    } else {
      final all = await isar!.requirementLocals.where().findAll();
      localMap = {for (final r in all) r.id: r};
    }

    final diff = SyncEngine.computeDiff<RequirementLocal>(
      serverItems: serverList,
      localItems: localMap,
      getId: (r) => r.id,
      isEqual: SyncEngine.areRequirementsEqual,
      pendingOutboxIds: pendingOutboxIds,
      preserveLocalMetadata: (serverItem, localItem) {
        serverItem.isarId = localItem.isarId;
      },
    );

    if (!diff.hasChanges) {
      return 0;
    }

    if (kIsWeb) {
      for (final r in diff.toInsert) {
        RequirementLocalRepository.inMemory[r.id] = r;
      }
      for (final r in diff.toUpdate) {
        RequirementLocalRepository.inMemory[r.id] = r;
      }
      for (final id in diff.toDelete) {
        RequirementLocalRepository.inMemory.remove(id);
      }
      await _coordinator.requirementLocal.saveInMemoryCacheOnlyIfChanged();
      return diff.totalChanges;
    }

    await SyncEngine.applyBatchedWrites<RequirementLocal>(
      diff: diff,
      putBatch: (batch) => isar!.writeTxn(() => isar.requirementLocals.putAll(batch)),
      deleteBatch: (ids) => isar!.writeTxn(() => isar.requirementLocals.deleteAllById(ids)),
      batchSize: SyncEngine.defaultBatchSize,
    );

    return diff.totalChanges;
  }

  Future<int> _syncBuildersIncremental(List<BuilderLocal> serverList, Set<String> pendingOutboxIds) async {
    if (serverList.isEmpty) return 0;

    final isar = kIsWeb ? null : IsarService().isar;
    final Map<String, BuilderLocal> localMap;
    if (kIsWeb) {
      localMap = Map<String, BuilderLocal>.from(BuilderLocalRepository.inMemory);
    } else {
      final all = await isar!.builderLocals.where().findAll();
      localMap = {for (final b in all) b.id: b};
    }

    final diff = SyncEngine.computeDiff<BuilderLocal>(
      serverItems: serverList,
      localItems: localMap,
      getId: (b) => b.id,
      isEqual: SyncEngine.areBuildersEqual,
      pendingOutboxIds: pendingOutboxIds,
      preserveLocalMetadata: (serverItem, localItem) {
        serverItem.isarId = localItem.isarId;
      },
    );

    if (!diff.hasChanges) {
      return 0;
    }

    if (kIsWeb) {
      for (final b in diff.toInsert) {
        BuilderLocalRepository.inMemory[b.id] = b;
      }
      for (final b in diff.toUpdate) {
        BuilderLocalRepository.inMemory[b.id] = b;
      }
      for (final id in diff.toDelete) {
        BuilderLocalRepository.inMemory.remove(id);
      }
      return diff.totalChanges;
    }

    await SyncEngine.applyBatchedWrites<BuilderLocal>(
      diff: diff,
      putBatch: (batch) => isar!.writeTxn(() => isar.builderLocals.putAll(batch)),
      deleteBatch: (ids) => isar!.writeTxn(() => isar.builderLocals.deleteAllById(ids)),
      batchSize: SyncEngine.defaultBatchSize,
    );

    return diff.totalChanges;
  }

  Future<int> _syncOwnersIncremental(List<OwnerLocal> serverList, Set<String> pendingOutboxIds) async {
    if (serverList.isEmpty) return 0;

    final isar = kIsWeb ? null : IsarService().isar;
    final Map<String, OwnerLocal> localMap;
    if (kIsWeb) {
      localMap = Map<String, OwnerLocal>.from(OwnerLocalRepository.inMemory);
    } else {
      final all = await isar!.ownerLocals.where().findAll();
      localMap = {for (final o in all) o.id: o};
    }

    final diff = SyncEngine.computeDiff<OwnerLocal>(
      serverItems: serverList,
      localItems: localMap,
      getId: (o) => o.id,
      isEqual: SyncEngine.areOwnersEqual,
      pendingOutboxIds: pendingOutboxIds,
      preserveLocalMetadata: (serverItem, localItem) {
        serverItem.isarId = localItem.isarId;
      },
    );

    if (!diff.hasChanges) {
      return 0;
    }

    if (kIsWeb) {
      for (final o in diff.toInsert) {
        OwnerLocalRepository.inMemory[o.id] = o;
      }
      for (final o in diff.toUpdate) {
        OwnerLocalRepository.inMemory[o.id] = o;
      }
      for (final id in diff.toDelete) {
        OwnerLocalRepository.inMemory.remove(id);
      }
      return diff.totalChanges;
    }

    await SyncEngine.applyBatchedWrites<OwnerLocal>(
      diff: diff,
      putBatch: (batch) => isar!.writeTxn(() => isar.ownerLocals.putAll(batch)),
      deleteBatch: (ids) => isar!.writeTxn(() => isar.ownerLocals.deleteAllById(ids)),
      batchSize: SyncEngine.defaultBatchSize,
    );

    return diff.totalChanges;
  }

  Future<int> _syncClientsIncremental(List<ClientLocal> serverList, Set<String> pendingOutboxIds) async {
    if (serverList.isEmpty) return 0;

    final isar = kIsWeb ? null : IsarService().isar;
    final Map<String, ClientLocal> localMap;
    if (kIsWeb) {
      localMap = Map<String, ClientLocal>.from(ClientLocalRepository.inMemory);
    } else {
      final all = await isar!.clientLocals.where().findAll();
      localMap = {for (final c in all) c.id: c};
    }

    final diff = SyncEngine.computeDiff<ClientLocal>(
      serverItems: serverList,
      localItems: localMap,
      getId: (c) => c.id,
      isEqual: SyncEngine.areClientsEqual,
      pendingOutboxIds: pendingOutboxIds,
      preserveLocalMetadata: (serverItem, localItem) {
        serverItem.isarId = localItem.isarId;
      },
    );

    if (!diff.hasChanges) {
      return 0;
    }

    if (kIsWeb) {
      for (final c in diff.toInsert) {
        ClientLocalRepository.inMemory[c.id] = c;
      }
      for (final c in diff.toUpdate) {
        ClientLocalRepository.inMemory[c.id] = c;
      }
      for (final id in diff.toDelete) {
        ClientLocalRepository.inMemory.remove(id);
      }
      return diff.totalChanges;
    }

    await SyncEngine.applyBatchedWrites<ClientLocal>(
      diff: diff,
      putBatch: (batch) => isar!.writeTxn(() => isar.clientLocals.putAll(batch)),
      deleteBatch: (ids) => isar!.writeTxn(() => isar.clientLocals.deleteAllById(ids)),
      batchSize: SyncEngine.defaultBatchSize,
    );

    return diff.totalChanges;
  }

  Future<int> _syncFollowupsIncremental(List<FollowupLocal> serverList, Set<String> pendingOutboxIds) async {
    if (serverList.isEmpty) return 0;

    final isar = kIsWeb ? null : IsarService().isar;
    final Map<String, FollowupLocal> localMap;
    if (kIsWeb) {
      localMap = Map<String, FollowupLocal>.from(FollowupLocalRepository.inMemory);
    } else {
      final all = await isar!.followupLocals.where().findAll();
      localMap = {for (final f in all) f.id: f};
    }

    final diff = SyncEngine.computeDiff<FollowupLocal>(
      serverItems: serverList,
      localItems: localMap,
      getId: (f) => f.id,
      isEqual: SyncEngine.areFollowupsEqual,
      pendingOutboxIds: pendingOutboxIds,
      preserveLocalMetadata: (serverItem, localItem) {
        serverItem.isarId = localItem.isarId;
      },
    );

    if (!diff.hasChanges) {
      return 0;
    }

    if (kIsWeb) {
      for (final f in diff.toInsert) {
        FollowupLocalRepository.inMemory[f.id] = f;
      }
      for (final f in diff.toUpdate) {
        FollowupLocalRepository.inMemory[f.id] = f;
      }
      for (final id in diff.toDelete) {
        FollowupLocalRepository.inMemory.remove(id);
      }
      await _coordinator.followupLocal.saveInMemoryCacheOnlyIfChanged();
      return diff.totalChanges;
    }

    await SyncEngine.applyBatchedWrites<FollowupLocal>(
      diff: diff,
      putBatch: (batch) => isar!.writeTxn(() => isar.followupLocals.putAll(batch)),
      deleteBatch: (ids) => isar!.writeTxn(() => isar.followupLocals.deleteAllById(ids)),
      batchSize: SyncEngine.defaultBatchSize,
    );

    return diff.totalChanges;
  }

  Future<int> _syncDashboardIncremental(DashboardData? freshDashboard) async {
    if (freshDashboard == null) return 0;
    final incomingLocal = freshDashboard.toLocal();

    if (kIsWeb) {
      final current = DashboardLocalRepository.inMemoryDashboard;
      if (current != null && SyncEngine.areDashboardsEqual(current, incomingLocal)) {
        return 0;
      }
      DashboardLocalRepository.inMemoryDashboard = incomingLocal;
      return 1;
    }

    final isar = IsarService().isar;
    final current = await isar.dashboardLocals.getById('singleton');
    if (current != null) {
      incomingLocal.isarId = current.isarId;
      if (SyncEngine.areDashboardsEqual(current, incomingLocal)) {
        return 0;
      }
    }

    await isar.writeTxn(() async {
      await isar.dashboardLocals.put(incomingLocal);
    });
    return 1;
  }

  Future<int> processOutboxQueue() async {
    AppLogger.sync("Replaying Outbox Queue...");
    final start = DateTime.now();
    final outboxItems = await _coordinator.outboxLocal.getQueuedRequests();

    if (outboxItems.isEmpty) return 0;

    final apiClient = ApiClient();
    int replayedCount = 0;
    int failedCount = 0;

    for (final item in outboxItems) {
      try {
        final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;

        final options = Options(headers: {
          'X-Idempotency-Key': item.id,
        });

        Response? response;
        if (item.method == 'POST') {
          response = await apiClient.post(item.endpoint, payload, options: options);
        } else if (item.method == 'PUT') {
          response = await apiClient.put(item.endpoint, payload, options: options);
        } else if (item.method == 'DELETE') {
          response = await apiClient.delete(item.endpoint, options: options);
        }

        if (response != null && (response.statusCode == 200 || response.statusCode == 201)) {
          await _coordinator.outboxLocal.removeRequest(item.id);
          replayedCount++;
        } else if (response != null && response.statusCode != null && response.statusCode! >= 400 && response.statusCode! < 500) {
          failedCount++;
          await _coordinator.outboxLocal.removeRequest(item.id);
          AppLogger.w("Non-retryable outbox failure (${response.statusCode}) for ${item.endpoint}");
        }
      } catch (e) {
        failedCount++;
        AppLogger.w("Outbox replay failed for ${item.endpoint}: $e");
        break; // Stop replaying on network failure, retry on next cycle
      }
    }

    final totalMs = DateTime.now().difference(start).inMilliseconds;
    if (replayedCount > 0 || failedCount > 0) {
      PerformanceLogger().logMetric(
        operation: 'SyncManager: Replayed $replayedCount outbox items ($failedCount failed)',
        totalMs: totalMs,
      );
    }
    return replayedCount;
  }

  Future<void> saveCheckpoint(String entityType, String checkpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checkpoint_$entityType', checkpoint);
  }

  Future<String?> getCheckpoint(String entityType) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('checkpoint_$entityType');
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

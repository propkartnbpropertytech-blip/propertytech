import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/campaign_connection_model.dart';
import '../services/campaign_connections_service.dart';

// --- EVENTS ---

abstract class CampaignConnectionsEvent extends Equatable {
  const CampaignConnectionsEvent();

  @override
  List<Object?> get props => [];
}

class FetchCampaignConnectionsEvent extends CampaignConnectionsEvent {
  final bool silent;
  const FetchCampaignConnectionsEvent({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class ToggleCampaignConnectionEvent extends CampaignConnectionsEvent {
  final String id;
  final bool isActive;
  const ToggleCampaignConnectionEvent({required this.id, required this.isActive});

  @override
  List<Object?> get props => [id, isActive];
}

class TestCampaignConnectionEvent extends CampaignConnectionsEvent {
  final String id;
  const TestCampaignConnectionEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class SyncCampaignConnectionEvent extends CampaignConnectionsEvent {
  final String id;
  const SyncCampaignConnectionEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class SaveCampaignConnectionEvent extends CampaignConnectionsEvent {
  final Map<String, dynamic> data;
  const SaveCampaignConnectionEvent({required this.data});

  @override
  List<Object?> get props => [data];
}

class ClearCampaignConnectionMessageEvent extends CampaignConnectionsEvent {
  const ClearCampaignConnectionMessageEvent();
}

// --- STATE ---

enum CampaignConnectionsStatus { initial, loading, success, failure }

class CampaignConnectionsState extends Equatable {
  final CampaignConnectionsStatus status;
  final List<CampaignConnectionModel> connections;
  final Set<String> syncingIds;
  final Set<String> testingIds;
  final Set<String> togglingIds;
  final String? successMessage;
  final String? errorMessage;

  const CampaignConnectionsState({
    this.status = CampaignConnectionsStatus.initial,
    this.connections = const [],
    this.syncingIds = const {},
    this.testingIds = const {},
    this.togglingIds = const {},
    this.successMessage,
    this.errorMessage,
  });

  CampaignConnectionModel? findByProvider(String providerType) {
    final upper = providerType.toUpperCase();
    try {
      return connections.firstWhere((c) => c.providerType == upper);
    } catch (_) {
      return null;
    }
  }

  List<CampaignConnectionModel> get activeConnections =>
      connections.where((c) => c.isActive).toList();

  CampaignConnectionsState copyWith({
    CampaignConnectionsStatus? status,
    List<CampaignConnectionModel>? connections,
    Set<String>? syncingIds,
    Set<String>? testingIds,
    Set<String>? togglingIds,
    String? successMessage,
    String? errorMessage,
    bool clearMessages = false,
  }) {
    return CampaignConnectionsState(
      status: status ?? this.status,
      connections: connections ?? this.connections,
      syncingIds: syncingIds ?? this.syncingIds,
      testingIds: testingIds ?? this.testingIds,
      togglingIds: togglingIds ?? this.togglingIds,
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        connections,
        syncingIds,
        testingIds,
        togglingIds,
        successMessage,
        errorMessage,
      ];
}

// --- BLOC ---

class CampaignConnectionsBloc
    extends Bloc<CampaignConnectionsEvent, CampaignConnectionsState> {
  final CampaignConnectionsService _service;
  static CampaignConnectionsBloc? _singletonInstance;

  factory CampaignConnectionsBloc({CampaignConnectionsService? service}) {
    return _singletonInstance ??= CampaignConnectionsBloc._internal(
      service: service ?? CampaignConnectionsService(),
    );
  }

  CampaignConnectionsBloc._internal({required CampaignConnectionsService service})
      : _service = service,
        super(const CampaignConnectionsState()) {
    on<FetchCampaignConnectionsEvent>(_onFetchConnections);
    on<ToggleCampaignConnectionEvent>(_onToggleConnection);
    on<TestCampaignConnectionEvent>(_onTestConnection);
    on<SyncCampaignConnectionEvent>(_onSyncConnection);
    on<SaveCampaignConnectionEvent>(_onSaveConnection);
    on<ClearCampaignConnectionMessageEvent>(_onClearMessage);
  }

  Future<void> _onFetchConnections(
    FetchCampaignConnectionsEvent event,
    Emitter<CampaignConnectionsState> emit,
  ) async {
    if (!event.silent && state.status != CampaignConnectionsStatus.success) {
      emit(state.copyWith(status: CampaignConnectionsStatus.loading, clearMessages: true));
    }
    try {
      final list = await _service.getConnections();
      emit(state.copyWith(
        status: CampaignConnectionsStatus.success,
        connections: list,
        clearMessages: true,
      ));
    } catch (e) {
      debugPrint('[CampaignConnectionsBloc] Error fetching connections: $e');
      emit(state.copyWith(
        status: CampaignConnectionsStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onToggleConnection(
    ToggleCampaignConnectionEvent event,
    Emitter<CampaignConnectionsState> emit,
  ) async {
    final nextToggling = Set<String>.from(state.togglingIds)..add(event.id);
    emit(state.copyWith(togglingIds: nextToggling, clearMessages: true));

    try {
      final updated = await _service.toggleConnection(event.id, event.isActive);
      final nextList = state.connections.map((c) => c.id == updated.id ? updated : c).toList();
      final updatedToggling = Set<String>.from(state.togglingIds)..remove(event.id);
      emit(state.copyWith(
        connections: nextList,
        togglingIds: updatedToggling,
        successMessage: '${updated.displayName} is now ${updated.isActive ? "enabled" : "disabled"}.',
      ));
    } catch (e) {
      final updatedToggling = Set<String>.from(state.togglingIds)..remove(event.id);
      emit(state.copyWith(
        togglingIds: updatedToggling,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onTestConnection(
    TestCampaignConnectionEvent event,
    Emitter<CampaignConnectionsState> emit,
  ) async {
    final nextTesting = Set<String>.from(state.testingIds)..add(event.id);
    emit(state.copyWith(testingIds: nextTesting, clearMessages: true));

    try {
      final result = await _service.testConnection(event.id);
      final updatedTesting = Set<String>.from(state.testingIds)..remove(event.id);
      final msg = result['message'] ?? 'Connection test passed successfully!';
      emit(state.copyWith(
        testingIds: updatedTesting,
        successMessage: msg,
      ));
    } catch (e) {
      final updatedTesting = Set<String>.from(state.testingIds)..remove(event.id);
      emit(state.copyWith(
        testingIds: updatedTesting,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSyncConnection(
    SyncCampaignConnectionEvent event,
    Emitter<CampaignConnectionsState> emit,
  ) async {
    final nextSyncing = Set<String>.from(state.syncingIds)..add(event.id);
    emit(state.copyWith(syncingIds: nextSyncing, clearMessages: true));

    try {
      final result = await _service.syncConnection(event.id);
      final updatedSyncing = Set<String>.from(state.syncingIds)..remove(event.id);
      final fetched = result['leads_fetched'] ?? result['fetched'] ?? 0;
      final inserted = result['leads_inserted'] ?? result['inserted'] ?? 0;
      final skipped = result['duplicates_skipped'] ?? result['skipped'] ?? 0;
      final msg = 'Sync complete: $fetched fetched, $inserted new leads ingested, $skipped duplicates skipped.';
      
      // Refresh list to update last_sync_at timestamp
      add(const FetchCampaignConnectionsEvent(silent: true));

      emit(state.copyWith(
        syncingIds: updatedSyncing,
        successMessage: msg,
      ));
    } catch (e) {
      final updatedSyncing = Set<String>.from(state.syncingIds)..remove(event.id);
      emit(state.copyWith(
        syncingIds: updatedSyncing,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSaveConnection(
    SaveCampaignConnectionEvent event,
    Emitter<CampaignConnectionsState> emit,
  ) async {
    emit(state.copyWith(status: CampaignConnectionsStatus.loading, clearMessages: true));
    try {
      final saved = await _service.saveConnection(event.data);
      final exists = state.connections.any((c) => c.id == saved.id);
      final nextList = exists
          ? state.connections.map((c) => c.id == saved.id ? saved : c).toList()
          : [...state.connections, saved];
      emit(state.copyWith(
        status: CampaignConnectionsStatus.success,
        connections: nextList,
        successMessage: '${saved.displayName} saved successfully.',
      ));
    } catch (e) {
      emit(state.copyWith(
        status: CampaignConnectionsStatus.failure,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  void _onClearMessage(
    ClearCampaignConnectionMessageEvent event,
    Emitter<CampaignConnectionsState> emit,
  ) {
    emit(state.copyWith(clearMessages: true));
  }
}

import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../integration/models/integration_lead_model.dart';
import '../../integration/services/integration_service.dart';

/// Available date range filter presets
enum CampaignDateFilter {
  today,
  yesterday,
  last7Days,
  thisMonth,
  customRange,
  allTime,
}

extension CampaignDateFilterX on CampaignDateFilter {
  String get label {
    switch (this) {
      case CampaignDateFilter.today:
        return 'Today';
      case CampaignDateFilter.yesterday:
        return 'Yesterday';
      case CampaignDateFilter.last7Days:
        return 'Last 7 Days';
      case CampaignDateFilter.thisMonth:
        return 'This Month';
      case CampaignDateFilter.customRange:
        return 'Custom Range';
      case CampaignDateFilter.allTime:
        return 'All Time';
    }
  }
}

// --- EVENTS ---

abstract class CampaignLeadsEvent extends Equatable {
  const CampaignLeadsEvent();

  @override
  List<Object?> get props => [];
}

/// Initial load or explicit refresh of campaign leads from server
class FetchCampaignLeadsEvent extends CampaignLeadsEvent {
  final bool silent;
  final bool resetWithServer;

  const FetchCampaignLeadsEvent({
    this.silent = false,
    this.resetWithServer = false,
  });

  @override
  List<Object?> get props => [silent, resetWithServer];
}

/// Periodic 1-minute ping to verify and pull new incoming leads
class PollCampaignLeadsPingEvent extends CampaignLeadsEvent {
  const PollCampaignLeadsPingEvent();
}

/// Change the active date filter preset
class SetCampaignDateFilterEvent extends CampaignLeadsEvent {
  final CampaignDateFilter filter;
  final DateTime? customStart;
  final DateTime? customEnd;

  const SetCampaignDateFilterEvent({
    required this.filter,
    this.customStart,
    this.customEnd,
  });

  @override
  List<Object?> get props => [filter, customStart, customEnd];
}

/// Acknowledge arrival of new leads (resets newLeadsJustArrivedCount to 0)
class AcknowledgeNewLeadsEvent extends CampaignLeadsEvent {
  const AcknowledgeNewLeadsEvent();
}

/// Fast local synchronization when IntegrationService updates in-memory leads
class SyncLocalLeadsEvent extends CampaignLeadsEvent {
  final List<IntegrationLeadModel> leads;
  const SyncLocalLeadsEvent(this.leads);

  @override
  List<Object?> get props => [leads.length, leads.isNotEmpty ? leads.first.id : ''];
}

// --- STATE ---

enum CampaignLeadsStatus { initial, loading, success, failure }

class CampaignLeadsState extends Equatable {
  final CampaignLeadsStatus status;
  final List<IntegrationLeadModel> leads;
  final CampaignDateFilter dateFilter;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final bool isPinging;
  final DateTime? lastPingAt;
  final int newLeadsJustArrivedCount;
  final List<IntegrationLeadModel> recentlyArrivedLeads;
  final String? errorMessage;

  const CampaignLeadsState({
    this.status = CampaignLeadsStatus.initial,
    this.leads = const [],
    this.dateFilter = CampaignDateFilter.today, // TODAY IS DEFAULT
    this.customStartDate,
    this.customEndDate,
    this.isPinging = false,
    this.lastPingAt,
    this.newLeadsJustArrivedCount = 0,
    this.recentlyArrivedLeads = const [],
    this.errorMessage,
  });

  CampaignLeadsState copyWith({
    CampaignLeadsStatus? status,
    List<IntegrationLeadModel>? leads,
    CampaignDateFilter? dateFilter,
    DateTime? customStartDate,
    DateTime? customEndDate,
    bool? isPinging,
    DateTime? lastPingAt,
    int? newLeadsJustArrivedCount,
    List<IntegrationLeadModel>? recentlyArrivedLeads,
    String? errorMessage,
  }) {
    return CampaignLeadsState(
      status: status ?? this.status,
      leads: leads ?? this.leads,
      dateFilter: dateFilter ?? this.dateFilter,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
      isPinging: isPinging ?? this.isPinging,
      lastPingAt: lastPingAt ?? this.lastPingAt,
      newLeadsJustArrivedCount: newLeadsJustArrivedCount ?? this.newLeadsJustArrivedCount,
      recentlyArrivedLeads: recentlyArrivedLeads ?? this.recentlyArrivedLeads,
      errorMessage: errorMessage,
    );
  }

  /// Get leads matching current date filter
  List<IntegrationLeadModel> get dateFilteredLeads {
    return leads.where((lead) {
      return matchesDateFilter(lead.receivedAt, dateFilter,
          customStart: customStartDate, customEnd: customEndDate);
    }).toList();
  }

  /// Count of leads matching a specific date filter
  int countForFilter(CampaignDateFilter filter, {String? section}) {
    return leads.where((lead) {
      if (section != null && lead.leadType != section) return false;
      return matchesDateFilter(lead.receivedAt, filter,
          customStart: customStartDate, customEnd: customEndDate);
    }).length;
  }

  /// Helper to test if a given lead timestamp falls within a date filter
  static bool matchesDateFilter(
    DateTime receivedAt,
    CampaignDateFilter filter, {
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    if (filter == CampaignDateFilter.allTime) return true;
    final local = receivedAt.toLocal();
    final now = DateTime.now();

    switch (filter) {
      case CampaignDateFilter.today:
        return local.year == now.year &&
            local.month == now.month &&
            local.day == now.day;
      case CampaignDateFilter.yesterday:
        final yest = now.subtract(const Duration(days: 1));
        return local.year == yest.year &&
            local.month == yest.month &&
            local.day == yest.day;
      case CampaignDateFilter.last7Days:
        final cutoff = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return local.isAfter(cutoff.subtract(const Duration(milliseconds: 1)));
      case CampaignDateFilter.thisMonth:
        return local.year == now.year && local.month == now.month;
      case CampaignDateFilter.customRange:
        if (customStart == null && customEnd == null) return true;
        final start = customStart != null
            ? DateTime(customStart.year, customStart.month, customStart.day)
            : DateTime(2000);
        final end = customEnd != null
            ? DateTime(customEnd.year, customEnd.month, customEnd.day, 23, 59, 59, 999)
            : DateTime(2100);
        return local.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
            local.isBefore(end.add(const Duration(milliseconds: 1)));
      case CampaignDateFilter.allTime:
        return true;
    }
  }

  @override
  List<Object?> get props => [
        status,
        leads,
        dateFilter,
        customStartDate,
        customEndDate,
        isPinging,
        lastPingAt,
        newLeadsJustArrivedCount,
        recentlyArrivedLeads,
        errorMessage,
      ];
}

// --- BLOC ---

class CampaignLeadsBloc extends Bloc<CampaignLeadsEvent, CampaignLeadsState> {
  final IntegrationService _integrationService;
  Timer? _oneMinutePingTimer;
  VoidCallback? _serviceListener;
  bool _isFetchingServer = false;

  CampaignLeadsBloc({IntegrationService? integrationService})
      : _integrationService = integrationService ?? IntegrationService(),
        super(const CampaignLeadsState()) {
    on<FetchCampaignLeadsEvent>(_onFetchCampaignLeads);
    on<PollCampaignLeadsPingEvent>(_onPollCampaignLeadsPing);
    on<SetCampaignDateFilterEvent>(_onSetCampaignDateFilter);
    on<AcknowledgeNewLeadsEvent>(_onAcknowledgeNewLeads);
    on<SyncLocalLeadsEvent>(_onSyncLocalLeads);

    // Fast O(1) binding to IntegrationService notifications
    _serviceListener = () {
      final currentLeads = _integrationService.leads;
      final currentLength = currentLeads.length;
      final stateLength = state.leads.length;

      // Avoid listEquals loop over 500 items. Check length or first lead identity.
      if (currentLength != stateLength ||
          (currentLength > 0 && stateLength > 0 && currentLeads.first.id != state.leads.first.id)) {
        add(SyncLocalLeadsEvent(currentLeads));
      }
    };
    _integrationService.addListener(_serviceListener!);

    // Start 1-Minute Live Ping Timer
    _startOneMinutePing();
  }

  void _onSyncLocalLeads(
    SyncLocalLeadsEvent event,
    Emitter<CampaignLeadsState> emit,
  ) {
    emit(state.copyWith(
      status: CampaignLeadsStatus.success,
      leads: event.leads,
    ));
  }

  void _startOneMinutePing() {
    _oneMinutePingTimer?.cancel();
    _oneMinutePingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      add(const PollCampaignLeadsPingEvent());
    });
  }

  @override
  Future<void> close() {
    _oneMinutePingTimer?.cancel();
    if (_serviceListener != null) {
      _integrationService.removeListener(_serviceListener!);
    }
    return super.close();
  }

  Future<void> _onFetchCampaignLeads(
    FetchCampaignLeadsEvent event,
    Emitter<CampaignLeadsState> emit,
  ) async {
    if (_isFetchingServer) return;
    _isFetchingServer = true;

    if (!event.silent && state.status != CampaignLeadsStatus.success) {
      emit(state.copyWith(status: CampaignLeadsStatus.loading));
    }

    try {
      await _integrationService.ensureLoaded();
      await _integrationService.fetchServerLeads(
        silent: event.silent,
        resetWithServer: event.resetWithServer,
      );

      final currentLeads = _integrationService.leads;
      emit(state.copyWith(
        status: CampaignLeadsStatus.success,
        leads: currentLeads,
        lastPingAt: DateTime.now(),
      ));
    } catch (e) {
      debugPrint('[CampaignLeadsBloc] Error fetching leads: $e');
      emit(state.copyWith(
        status: CampaignLeadsStatus.failure,
        errorMessage: e.toString(),
      ));
    } finally {
      _isFetchingServer = false;
    }
  }

  Future<void> _onPollCampaignLeadsPing(
    PollCampaignLeadsPingEvent event,
    Emitter<CampaignLeadsState> emit,
  ) async {
    emit(state.copyWith(isPinging: true));

    try {
      final previousIds = state.leads.map((l) => l.id).toSet();
      final previousExtIds = state.leads
          .map((l) => l.externalLeadId)
          .whereType<String>()
          .toSet();

      // Silent fetch from server
      await _integrationService.fetchServerLeads(silent: true);
      final latestLeads = _integrationService.leads;

      // Identify newly arrived leads that were not present previously
      final newlyArrived = latestLeads.where((lead) {
        final isNewId = !previousIds.contains(lead.id);
        final isNewExtId = lead.externalLeadId != null &&
            !previousExtIds.contains(lead.externalLeadId!);
        return isNewId && (lead.externalLeadId == null || isNewExtId);
      }).toList();

      emit(state.copyWith(
        status: CampaignLeadsStatus.success,
        leads: latestLeads,
        isPinging: false,
        lastPingAt: DateTime.now(),
        newLeadsJustArrivedCount: newlyArrived.length,
        recentlyArrivedLeads: newlyArrived,
      ));
    } catch (e) {
      debugPrint('[CampaignLeadsBloc] 1-minute ping error: $e');
      emit(state.copyWith(isPinging: false, lastPingAt: DateTime.now()));
    }
  }

  void _onSetCampaignDateFilter(
    SetCampaignDateFilterEvent event,
    Emitter<CampaignLeadsState> emit,
  ) {
    emit(state.copyWith(
      dateFilter: event.filter,
      customStartDate: event.customStart,
      customEndDate: event.customEnd,
    ));
  }

  void _onAcknowledgeNewLeads(
    AcknowledgeNewLeadsEvent event,
    Emitter<CampaignLeadsState> emit,
  ) {
    emit(state.copyWith(
      newLeadsJustArrivedCount: 0,
      recentlyArrivedLeads: const [],
    ));
  }
}

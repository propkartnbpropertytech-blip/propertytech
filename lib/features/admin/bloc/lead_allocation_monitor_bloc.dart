import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../../integration/services/integration_service.dart';

export '../screens/lead_allocation_monitor_screen.dart';

abstract class LeadAllocationMonitorEvent extends Equatable {
  const LeadAllocationMonitorEvent();
  @override
  List<Object?> get props => [];
}

class LeadAllocationMonitorRequested extends LeadAllocationMonitorEvent {
  final bool silent;
  const LeadAllocationMonitorRequested({this.silent = false});
  @override
  List<Object?> get props => [silent];
}

class RecoverStaleLeadsRequested extends LeadAllocationMonitorEvent {
  final int timeoutMinutes;
  const RecoverStaleLeadsRequested({this.timeoutMinutes = 30});
  @override
  List<Object?> get props => [timeoutMinutes];
}

class TokenExpirationUpdateRequested extends LeadAllocationMonitorEvent {
  final int hours;
  const TokenExpirationUpdateRequested(this.hours);
  @override
  List<Object?> get props => [hours];
}

class LeadReassignRequested extends LeadAllocationMonitorEvent {
  final String leadId;
  final String toTelecallerId;
  final String reason;
  final bool overrideEligibility;
  const LeadReassignRequested({
    required this.leadId,
    required this.toTelecallerId,
    required this.reason,
    this.overrideEligibility = false,
  });
  @override
  List<Object?> get props => [leadId, toTelecallerId, reason, overrideEligibility];
}

class AllocateOldLeadsRequested extends LeadAllocationMonitorEvent {
  final int limit;
  const AllocateOldLeadsRequested({this.limit = 25});
  @override
  List<Object?> get props => [limit];
}

class ToggleAllocationEngineRequested extends LeadAllocationMonitorEvent {
  final bool enabled;
  const ToggleAllocationEngineRequested({required this.enabled});
  @override
  List<Object?> get props => [enabled];
}

class LeadAllocationMonitorState extends Equatable {
  final bool loading;
  final String? error;
  final String? info;
  final Map<String, dynamic> data;
  const LeadAllocationMonitorState({
    this.loading = false,
    this.error,
    this.info,
    this.data = const {},
  });
  @override
  List<Object?> get props => [loading, error, info, data];
}

class LeadAllocationMonitorBloc
    extends Bloc<LeadAllocationMonitorEvent, LeadAllocationMonitorState> {
  bool _isFetching = false;

  LeadAllocationMonitorBloc() : super(const LeadAllocationMonitorState(loading: true)) {
    on<LeadAllocationMonitorRequested>((event, emit) async {
      if (_isFetching) return;
      _isFetching = true;
      try {
        if (!event.silent) {
          emit(LeadAllocationMonitorState(loading: true, data: state.data));
        }
        final res = await DioClient.dio.get(ApiConstants.adminAllocationMonitor);
        final data = Map<String, dynamic>.from(res.data['data'] ?? {});
        data['recentAssignments'] = await _mergePeerTransfers(
          List<dynamic>.from(data['recentAssignments'] ?? []),
        );
        data['_fetchedAt'] = DateTime.now().toIso8601String();
        emit(LeadAllocationMonitorState(data: data));
      } catch (e) {
        if (!event.silent) {
          emit(LeadAllocationMonitorState(error: e.toString(), data: state.data));
        }
      } finally {
        _isFetching = false;
      }
    });
    on<RecoverStaleLeadsRequested>((event, emit) async {
      emit(LeadAllocationMonitorState(loading: true, data: state.data));
      try {
        final res = await DioClient.dio.post(
          ApiConstants.adminRecoverStaleLeads,
          data: {'timeoutMinutes': event.timeoutMinutes},
        );
        final recovered = res.data['data']?['recoveredCount'] ?? res.data['recoveredCount'] ?? 0;
        emit(LeadAllocationMonitorState(
          info: 'Recovered $recovered stale leads back to waiting queue.',
          data: state.data,
        ));
        add(LeadAllocationMonitorRequested());
      } catch (e) {
        emit(LeadAllocationMonitorState(error: e.toString(), data: state.data, loading: false));
      }
    });
    on<LeadReassignRequested>((event, emit) async {
      try {
        await DioClient.dio.post(
          ApiConstants.adminReassignLead,
          data: {
            'leadId': event.leadId,
            'toTelecallerId': event.toTelecallerId,
            'reason': event.reason,
            'overrideEligibility': event.overrideEligibility,
          },
        );
        add(LeadAllocationMonitorRequested());
      } catch (e) {
        emit(LeadAllocationMonitorState(error: e.toString(), data: state.data, loading: false));
      }
    });
    on<AllocateOldLeadsRequested>((event, emit) async {
      emit(LeadAllocationMonitorState(loading: true, data: state.data));
      try {
        final res = await DioClient.dio.post(
          ApiConstants.adminAllocateOldLeads,
          data: {'limit': event.limit},
        );
        final data = res.data['data'];
        final assigned = data?['count'] ?? data?['allocatedCount'] ?? data?['assignedCount'] ?? (data?['allocated'] as List?)?.length ?? 0;
        final isSales = (state.data['targetRole'] ?? 'Telecaller').toString().toLowerCase() == 'sales';
        final message = data?['message'] ?? (assigned > 0
            ? 'Successfully allocated $assigned old untouched leads.'
            : (isSales
                ? 'No leads allocated: all active salespersons are at maximum capacity or no matching campaign/category rules found.'
                : 'No leads allocated: all active telecallers are at maximum capacity (0 free slots available).'));
        emit(LeadAllocationMonitorState(
          info: message,
          data: state.data,
        ));
        add(LeadAllocationMonitorRequested());
      } catch (e) {
        emit(LeadAllocationMonitorState(error: e.toString(), data: state.data, loading: false));
      }
    });
    on<ToggleAllocationEngineRequested>((event, emit) async {
      final updatedData = Map<String, dynamic>.from(state.data);
      updatedData['engineEnabled'] = event.enabled;
      emit(LeadAllocationMonitorState(
        data: updatedData,
        loading: false,
        info: event.enabled ? 'Enabling allocation engine...' : 'Pausing allocation engine...',
      ));
      try {
        await DioClient.dio.post(
          ApiConstants.adminAllocationEngineToggle,
          data: {'enabled': event.enabled},
        );
        add(LeadAllocationMonitorRequested());
      } catch (e) {
        emit(LeadAllocationMonitorState(error: e.toString(), data: state.data, loading: false));
      }
    });
    on<TokenExpirationUpdateRequested>((event, emit) async {
      final currentData = Map<String, dynamic>.from(state.data);
      currentData['tokenExpirationHours'] = event.hours;
      emit(LeadAllocationMonitorState(
        data: currentData,
        info: 'Updating session expiration to ${event.hours} hours...',
        loading: false,
      ));
      try {
        await DioClient.dio.post(
          ApiConstants.adminTokenExpiration,
          data: {'hours': event.hours},
        );
        await SecureStorage().saveSessionExpirationHours(event.hours);
        emit(LeadAllocationMonitorState(
          data: currentData,
          info: 'Token expiration successfully updated to ${event.hours} hours.',
          loading: false,
        ));
      } catch (e) {
        emit(LeadAllocationMonitorState(error: e.toString(), data: state.data, loading: false));
      }
    });
  }

  Future<List<dynamic>> _mergePeerTransfers(List<dynamic> serverHistory) async {
    final local = await IntegrationService().peerTransferHistory();
    if (local.isEmpty) return serverHistory;

    final merged = <Map<String, dynamic>>[
      for (final raw in serverHistory)
        if (raw is Map) Map<String, dynamic>.from(raw),
    ];

    bool sameMove(Map<String, dynamic> server, Map<String, dynamic> entry) {
      if (server['lead_id']?.toString() != entry['lead_id']?.toString()) return false;
      if (server['to_telecaller_id']?.toString() != entry['to_telecaller_id']?.toString()) return false;
      final serverAt = DateTime.tryParse(server['assigned_at']?.toString() ?? '');
      final localAt = DateTime.tryParse(entry['assigned_at']?.toString() ?? '');
      if (serverAt == null || localAt == null) return false;
      return serverAt.difference(localAt).inMinutes.abs() <= 5;
    }

    for (final entry in local) {
      final matchIndex = merged.indexWhere((row) => sameMove(row, entry));
      if (matchIndex == -1) {
        merged.add(entry);
        continue;
      }
      final row = merged[matchIndex];
      if ((row['from_telecaller_name']?.toString() ?? '').isEmpty &&
          (entry['from_telecaller_name']?.toString() ?? '').isNotEmpty) {
        row['from_telecaller_id'] = entry['from_telecaller_id'];
        row['from_telecaller_name'] = entry['from_telecaller_name'];
        row['assignment_type'] = entry['assignment_type'] ?? row['assignment_type'];
        row['reason'] = row['reason'] ?? entry['reason'];
      }
    }

    merged.sort((a, b) {
      final aTime = DateTime.tryParse(a['assigned_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b['assigned_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return merged;
  }
}

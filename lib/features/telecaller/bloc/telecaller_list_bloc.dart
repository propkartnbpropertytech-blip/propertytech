import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/security/role_guard.dart';
import '../../integration/services/integration_service.dart';
import '../data/telecaller_repository.dart';

abstract class TelecallerListEvent extends Equatable {
  const TelecallerListEvent();
  @override
  List<Object?> get props => [];
}

class TelecallerCallbacksRequested extends TelecallerListEvent {
  final String? search;
  final String? from;
  final String? to;
  final String? source;
  const TelecallerCallbacksRequested({this.search, this.from, this.to, this.source});
  @override
  List<Object?> get props => [search, from, to, source];
}

class TelecallerCnrRequested extends TelecallerListEvent {
  final String? search;
  final String? from;
  final String? to;
  final String? source;
  const TelecallerCnrRequested({this.search, this.from, this.to, this.source});
  @override
  List<Object?> get props => [search, from, to, source];
}

class TelecallerLeadRemoved extends TelecallerListEvent {
  final String leadId;
  const TelecallerLeadRemoved(this.leadId);
  @override
  List<Object?> get props => [leadId];
}

class TelecallerListState extends Equatable {
  final bool loading;
  final String? error;
  final List<dynamic> items;
  const TelecallerListState({
    this.loading = false,
    this.error,
    this.items = const [],
  });
  @override
  List<Object?> get props => [loading, error, items];
}

class TelecallerCallbacksBloc extends Bloc<TelecallerListEvent, TelecallerListState> {
  TelecallerCallbacksBloc({TelecallerRepository? repository})
      : _repository = repository ?? TelecallerRepository(),
        super(const TelecallerListState(loading: true)) {
    _leadEventsSub = IntegrationService.leadEvents.stream.listen((_) {
      add(const TelecallerCallbacksRequested());
    });

    on<TelecallerCallbacksRequested>((event, emit) async {
      emit(TelecallerListState(loading: true, items: state.items));
      try {
        final serverItems = await _repository.callbacks(
          search: event.search,
          from: event.from,
          to: event.to,
          source: event.source,
        );
        final items = _keptForCurrentTelecaller(serverItems);

        // Merge local in-memory leads marked as Callback so they appear immediately
        final existingIds = items.map((raw) {
          if (raw is! Map) return '';
          return (raw['lead_id'] ?? raw['id'] ?? raw['legacy_integration_lead_id'] ?? '').toString();
        }).toSet();

        final localCbLeads = IntegrationService().leads.where((l) {
          final isCb = l.campaignStatus == 'Callback' || l.campaignStatus == 'Call Back' || l.allocationStatus == 'CALLBACK';
          if (!isCb) return false;
          // Strictly exclude follow-ups
          if (l.campaignStatus == 'Follow up' || l.campaignStatus == 'Follow-up' || l.allocationStatus == 'FOLLOWUP') {
            return false;
          }
          final myId = RoleGuard.currentUser?.id.trim().toLowerCase();
          final isTelecaller = RoleGuard.isTelecaller(RoleGuard.currentUser?.role);
          if (isTelecaller && myId != null && myId.isNotEmpty) {
            final assigned = l.assignedTelecallerId?.trim().toLowerCase();
            if (assigned != null && assigned.isNotEmpty && assigned != myId) {
              return false;
            }
          }
          return true;
        });

        for (final l in localCbLeads) {
          String clientName = '';
          for (final k in ['Client Name', 'full_name', 'Client / Owner Name', 'Name', 'Customer Name', 'Owner Name', 'name', 'client_name']) {
            final v = l.getStringValue(k).trim();
            if (v.isNotEmpty && v != 'Callback Client' && v != 'Lead') {
              clientName = v;
              break;
            }
          }
          if (clientName.isEmpty) clientName = 'Lead ${l.getStringValue('phone_number')}';

          final phone = l.getStringValue('phone_number').isNotEmpty
              ? l.getStringValue('phone_number')
              : l.getStringValue('phone');

          final existingIdx = items.indexWhere((raw) {
            if (raw is! Map) return false;
            final rid = (raw['lead_id'] ?? raw['id'] ?? raw['legacy_integration_lead_id'] ?? '').toString();
            return rid == l.id;
          });

          if (existingIdx != -1) {
            final m = Map<String, dynamic>.from(items[existingIdx] as Map);
            m['client_name'] = clientName;
            m['customer_name'] = clientName;
            m['mobile'] = phone;
            m['remarks'] = l.callbackRemarks ?? m['remarks'];
            m['scheduled_at'] = l.callbackScheduledAt != null ? l.callbackScheduledAt!.toIso8601String() : m['scheduled_at'];
            items[existingIdx] = m;
          } else {
            existingIds.add(l.id);
            items.insert(0, {
              'id': 'local_${l.id}',
              'lead_id': l.id,
              'lead_type': l.leadType,
              'client_name': clientName,
              'customer_name': clientName,
              'mobile': phone,
              'scheduled_at': l.callbackScheduledAt != null ? l.callbackScheduledAt!.toIso8601String() : DateTime.now().toIso8601String(),
              'remarks': l.callbackRemarks ?? '',
              'status': l.callbackStatus ?? 'Pending',
              'created_at': l.receivedAt.toIso8601String(),
              'lead': {
                'id': l.id,
                'sanitized_phone': phone,
                'campaign_name': l.getStringValue('campaign_name'),
                'raw_json': l.rawJson,
                'allocation_status': 'CALLBACK',
                'campaign_status': 'Callback',
                'assigned_telecaller_id': l.assignedTelecallerId,
                'source': l.source,
              },
            });
          }
        }

        emit(TelecallerListState(items: items));
      } catch (e) {
        emit(TelecallerListState(error: e.toString(), items: state.items));
      }
    });

    on<TelecallerLeadRemoved>((event, emit) {
      final target = event.leadId.trim().toLowerCase();
      final filtered = state.items.where((raw) {
        if (raw is! Map) return true;
        final id = (raw['id'] ?? '').toString().trim().toLowerCase();
        final leadId = (raw['lead_id'] ?? raw['leadId'] ?? '').toString().trim().toLowerCase();
        final legacyId = (raw['legacy_integration_lead_id'] ?? raw['legacyIntegrationLeadId'] ?? '').toString().trim().toLowerCase();
        final nested = raw['lead'];
        final nestedId = nested is Map ? (nested['id'] ?? nested['lead_id'] ?? nested['leadId'] ?? '').toString().trim().toLowerCase() : '';
        return id != target && leadId != target && legacyId != target && nestedId != target;
      }).toList();
      emit(TelecallerListState(items: filtered, loading: false));
    });
  }

  final TelecallerRepository _repository;
  StreamSubscription? _leadEventsSub;

  @override
  Future<void> close() {
    _leadEventsSub?.cancel();
    return super.close();
  }
}

class TelecallerCnrBloc extends Bloc<TelecallerListEvent, TelecallerListState> {
  TelecallerCnrBloc({TelecallerRepository? repository})
      : _repository = repository ?? TelecallerRepository(),
        super(const TelecallerListState(loading: true)) {
    _leadEventsSub = IntegrationService.leadEvents.stream.listen((_) {
      add(const TelecallerCnrRequested());
    });

    on<TelecallerCnrRequested>((event, emit) async {
      emit(TelecallerListState(loading: true, items: state.items));
      try {
        final serverItems = await _repository.cnr(
          search: event.search,
          from: event.from,
          to: event.to,
          source: event.source,
        );
        final items = _keptForCurrentTelecaller(serverItems);

        // Merge local in-memory leads marked as CNR so they appear immediately
        final existingIds = items.map((raw) {
          if (raw is! Map) return '';
          return (raw['id'] ?? raw['lead_id'] ?? raw['legacy_integration_lead_id'] ?? '').toString();
        }).toSet();

        final localCnrLeads = IntegrationService().leads.where((l) {
          final isCnr = l.campaignStatus == 'CNR' || l.allocationStatus == 'CNR';
          if (!isCnr) return false;
          final myId = RoleGuard.currentUser?.id.trim().toLowerCase();
          final isTelecaller = RoleGuard.isTelecaller(RoleGuard.currentUser?.role);
          if (isTelecaller && myId != null && myId.isNotEmpty) {
            final assigned = l.assignedTelecallerId?.trim().toLowerCase();
            final interacted = (l.rawJson['_transfer']?['interacted_by'] ?? l.rawJson['interacted_by'])?.toString().trim().toLowerCase();
            if (assigned != null && assigned.isNotEmpty && assigned != myId && interacted != null && interacted.isNotEmpty && interacted != myId) {
              return false;
            }
          }
          return true;
        });

        for (final l in localCnrLeads) {
          String clientName = '';
          for (final k in ['Client Name', 'full_name', 'Client / Owner Name', 'Name', 'Customer Name', 'Owner Name', 'name', 'client_name']) {
            final v = l.getStringValue(k).trim();
            if (v.isNotEmpty && v != 'CNR Client' && v != 'Lead') {
              clientName = v;
              break;
            }
          }
          if (clientName.isEmpty) clientName = 'Lead ${l.getStringValue('phone_number')}';

          final phone = l.getStringValue('phone_number').isNotEmpty
              ? l.getStringValue('phone_number')
              : l.getStringValue('phone');

          final existingIdx = items.indexWhere((raw) {
            if (raw is! Map) return false;
            final rid = (raw['id'] ?? raw['lead_id'] ?? raw['legacy_integration_lead_id'] ?? '').toString();
            return rid == l.id;
          });

          if (existingIdx != -1) {
            final m = Map<String, dynamic>.from(items[existingIdx] as Map);
            m['customer_name'] = clientName;
            m['client_name'] = clientName;
            m['sanitized_phone'] = phone;
            m['raw_json'] = l.rawJson;
            items[existingIdx] = m;
          } else {
            existingIds.add(l.id);
            items.insert(0, {
              'id': l.id,
              'lead_id': l.id,
              'legacy_integration_lead_id': l.id,
              'customer_name': clientName,
              'client_name': clientName,
              'sanitized_phone': phone,
              'campaign_name': l.getStringValue('campaign_name'),
              'campaign_status': 'CNR',
              'allocation_status': 'CNR',
              'call_attempt_count': 1,
              'raw_json': l.rawJson,
              'created_at': l.receivedAt.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        }

        emit(TelecallerListState(items: items));
      } catch (e) {
        emit(TelecallerListState(error: e.toString(), items: state.items));
      }
    });

    on<TelecallerLeadRemoved>((event, emit) {
      final target = event.leadId.trim().toLowerCase();
      final filtered = state.items.where((raw) {
        if (raw is! Map) return true;
        final id = (raw['id'] ?? '').toString().trim().toLowerCase();
        final leadId = (raw['lead_id'] ?? raw['leadId'] ?? '').toString().trim().toLowerCase();
        final legacyId = (raw['legacy_integration_lead_id'] ?? raw['legacyIntegrationLeadId'] ?? '').toString().trim().toLowerCase();
        final nested = raw['lead'];
        final nestedId = nested is Map ? (nested['id'] ?? nested['lead_id'] ?? nested['leadId'] ?? '').toString().trim().toLowerCase() : '';
        return id != target && leadId != target && legacyId != target && nestedId != target;
      }).toList();
      emit(TelecallerListState(items: filtered, loading: false));
    });
  }

  final TelecallerRepository _repository;
  StreamSubscription? _leadEventsSub;

  @override
  Future<void> close() {
    _leadEventsSub?.cancel();
    return super.close();
  }
}

List<dynamic> _keptForCurrentTelecaller(List<dynamic> items) {
  if (!RoleGuard.isTelecaller(RoleGuard.currentUser?.role)) return items;
  final myId = RoleGuard.currentUser?.id.trim().toLowerCase();
  if (myId == null || myId.isEmpty) return items;
  return items.where((raw) {
    if (raw is! Map) return true;
    final id = (raw['lead_id'] ?? raw['campaign_lead_id'] ?? raw['campaignLeadId'] ?? raw['id'])
        ?.toString();
    if (id == null || id.isEmpty) return true;
    final local = IntegrationService().getLeadById(id);
    final assigned = local?.assignedTelecallerId?.trim().toLowerCase();
    final rawAssigned = (raw['assigned_telecaller_id'] ?? raw['assignedTelecallerId'] ?? (raw['lead'] is Map ? raw['lead']['assigned_telecaller_id'] : ''))?.toString().trim().toLowerCase() ?? '';
    final rawInteracted = (raw['interacted_by'] ?? raw['interactedBy'] ?? raw['raw_json']?['_transfer']?['interacted_by'] ?? '')?.toString().trim().toLowerCase() ?? '';

    // If assigned to current telecaller or interacted by current telecaller
    if (assigned == myId || rawAssigned == myId || rawInteracted == myId) return true;

    // If completely unassigned / unknown locally, keep it (backend already scoped it)
    if ((assigned == null || assigned.isEmpty) && rawAssigned.isEmpty && rawInteracted.isEmpty) return true;

    // If assigned to a DIFFERENT telecaller and not interacted by this telecaller, filter out
    if (assigned != null && assigned.isNotEmpty && assigned != myId && rawInteracted != myId) {
      return false;
    }
    if (rawAssigned.isNotEmpty && rawAssigned != myId && rawInteracted != myId) {
      return false;
    }

    return true;
  }).toList();
}

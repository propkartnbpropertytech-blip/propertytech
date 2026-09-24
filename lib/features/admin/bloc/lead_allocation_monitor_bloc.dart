import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/storage/secure_storage.dart';
import '../../integration/services/integration_service.dart';
import '../widgets/telecaller_detail_dialog.dart';
import 'package:propkart/core/design_system/tokens/app_breakpoints.dart';

abstract class LeadAllocationMonitorEvent extends Equatable {
  const LeadAllocationMonitorEvent();
  @override
  List<Object?> get props => [];
}

class LeadAllocationMonitorRequested extends LeadAllocationMonitorEvent {}

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
  LeadAllocationMonitorBloc() : super(const LeadAllocationMonitorState(loading: true)) {
    on<LeadAllocationMonitorRequested>((event, emit) async {
      emit(LeadAllocationMonitorState(loading: true, data: state.data));
      try {
        final res = await DioClient.dio.get(ApiConstants.adminAllocationMonitor);
        final data = Map<String, dynamic>.from(res.data['data'] ?? {});
        data['recentAssignments'] = await _mergePeerTransfers(
          List<dynamic>.from(data['recentAssignments'] ?? []),
        );
        emit(LeadAllocationMonitorState(data: data));
      } catch (e) {
        emit(LeadAllocationMonitorState(error: e.toString(), data: state.data));
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
        final message = data?['message'] ?? (assigned > 0
            ? 'Successfully allocated $assigned old untouched leads.'
            : 'No leads allocated: all active telecallers are at maximum capacity (0 free slots available).');
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

class LeadAllocationMonitorScreen extends StatelessWidget {
  const LeadAllocationMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeadAllocationMonitorBloc()..add(LeadAllocationMonitorRequested()),
      child: const _LeadAllocationMonitorView(),
    );
  }
}

class _LeadAllocationMonitorView extends StatelessWidget {
  const _LeadAllocationMonitorView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LeadAllocationMonitorBloc, LeadAllocationMonitorState>(
      listener: (context, state) {
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
        } else if (state.info != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.info!),
              backgroundColor: Colors.green.shade800,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state.loading && state.data.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final queue = Map<String, dynamic>.from(state.data['queue'] ?? {});
        final telecallers = List<dynamic>.from(state.data['telecallers'] ?? []);
        final history = List<dynamic>.from(state.data['recentAssignments'] ?? []);

        return RefreshIndicator(
          onRefresh: () async {
            context.read<LeadAllocationMonitorBloc>().add(LeadAllocationMonitorRequested());
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: CRMPageHeader(
                      title: 'Lead Allocation Monitoring',
                      benefit: 'Real-time queue depth, Telecaller workload, and assignment history.',
                    ),
                  ),
                  Row(
                    children: [
                      Builder(
                        builder: (ctx) {
                          final bool isEngineOn = state.data['engineEnabled'] ?? true;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isEngineOn ? const Color(0xFF16A34A) : Colors.amber.shade800).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isEngineOn ? const Color(0xFF16A34A) : Colors.amber.shade800,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isEngineOn ? Icons.check_circle : Icons.pause_circle_outline,
                                  size: 16,
                                  color: isEngineOn ? const Color(0xFF16A34A) : Colors.amber.shade800,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isEngineOn ? 'Engine: Active' : 'Engine: Paused',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isEngineOn ? const Color(0xFF16A34A) : Colors.amber.shade800,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                SizedBox(
                                  height: 22,
                                  width: 34,
                                  child: FittedBox(
                                    fit: BoxFit.fill,
                                    child: Switch(
                                      value: isEngineOn,
                                      activeThumbColor: const Color(0xFF16A34A),
                                      onChanged: (val) {
                                        context.read<LeadAllocationMonitorBloc>().add(
                                          ToggleAllocationEngineRequested(enabled: val),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade800,
                          side: BorderSide(color: Colors.orange.shade400),
                        ),
                        icon: const Icon(Icons.timer_off_outlined, size: 16),
                        label: const Text('Recover Stale Leads'),
                        onPressed: () => _confirmRecoverStaleLeads(context),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh Monitor',
                        onPressed: () {
                          context.read<LeadAllocationMonitorBloc>().add(LeadAllocationMonitorRequested());
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                ),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _chip('Waiting', '${queue['waitingLeads'] ?? 0}', Colors.blue),
                  _chip('> 5 min', '${queue['waitingOver5Minutes'] ?? 0}', Colors.orange),
                  _chip('> 15 min', '${queue['waitingOver15Minutes'] ?? 0}', Colors.deepOrange),
                  _chip('> 1 hour', '${queue['waitingOver1Hour'] ?? 0}', Colors.red),
                  _chip('Longest wait', '${queue['longestWaitingMinutes'] ?? 0}m', Colors.purple),
                  _chip('Old Untouched', '${queue['unallocatedOldUntouchedCount'] ?? 0}', Colors.teal),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: const Color(0xFFF0FDF4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFBBF7D0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.archive_outlined, color: Color(0xFF16A34A), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Old Untouched Leads Allocation',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF14532D)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${queue['unallocatedOldUntouchedCount'] ?? 0} historical leads waiting for allocation to active telecallers.',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                        onPressed: () => _confirmAllocateOldLeads(context, queue['unallocatedOldUntouchedCount'] ?? 0),
                        icon: const Icon(Icons.auto_mode, size: 18),
                        label: const Text('Allocate Leads'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final int expirationHours = int.tryParse(state.data['tokenExpirationHours']?.toString() ?? '') ?? 8;
                  final isDark = Theme.of(context).brightness == Brightness.dark;

                  return Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF4F46E5).withValues(alpha: 0.12),
                            ),
                            child: const Icon(Icons.timer_outlined, color: Color(0xFF4F46E5), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Text(
                                      'Session & Token Expiration',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    SizedBox(width: 8),
                                    Chip(
                                      label: Text('Auto-Logout', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Automatic logout timeout for user shifts and sessions (Telecaller, Sales, and Admin accounts).',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: [4, 8, 12, 24].contains(expirationHours) ? expirationHours : 8,
                                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4F46E5)),
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                items: const [
                                  DropdownMenuItem(value: 4, child: Text('4 Hours')),
                                  DropdownMenuItem(value: 8, child: Text('8 Hours (Default)')),
                                  DropdownMenuItem(value: 12, child: Text('12 Hours')),
                                  DropdownMenuItem(value: 24, child: Text('24 Hours')),
                                ],
                                onChanged: (newHours) {
                                  if (newHours != null && newHours != expirationHours) {
                                    context
                                        .read<LeadAllocationMonitorBloc>()
                                        .add(TokenExpirationUpdateRequested(newHours));
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Text('Telecallers Workload & Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final raw in telecallers)
                    Builder(
                      builder: (context) {
                        final t = Map<String, dynamic>.from(raw as Map);
                        final status = (t['status'] ?? 'INACTIVE').toString();
                        final isFresh = t['heartbeatFresh'] == true;
                        final color = status == 'ACTIVE'
                            ? (isFresh ? Colors.green : Colors.orange)
                            : (status == 'BREAK' ? Colors.blue : Colors.grey);
                        final workload = (t['currentWorkload'] is int)
                            ? t['currentWorkload'] as int
                            : int.tryParse(t['currentWorkload']?.toString() ?? '0') ?? 0;
                        final capacity = (t['maxCapacity'] is int)
                            ? t['maxCapacity'] as int
                            : int.tryParse(t['maxCapacity']?.toString() ?? '10') ?? 10;
                        final progress = capacity > 0 ? (workload / capacity).clamp(0.0, 1.0) : 0.0;
                        final isDark = Theme.of(context).brightness == Brightness.dark;

                        return SizedBox(
                          width: 310,
                          child: Card(
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: color.withValues(alpha: 0.4), width: 1.5),
                            ),
                            child: InkWell(
                              onTap: () {
                                TelecallerDetailDialog.show(
                                  context,
                                  telecallerId: t['id']?.toString() ?? '',
                                  telecallerName: t['name']?.toString() ?? '',
                                  allTelecallers: telecallers,
                                  onLeadReassigned: () {
                                    context.read<LeadAllocationMonitorBloc>().add(LeadAllocationMonitorRequested());
                                  },
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            t['name']?.toString() ?? 'Telecaller',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Workload: $workload / $capacity Leads',
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '${t['availableCapacity'] ?? 0} free',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: (t['availableCapacity'] ?? 0) > 0 ? Colors.green.shade700 : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress.toDouble(),
                                        minHeight: 6,
                                        backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          progress >= 1.0
                                              ? Colors.red
                                              : progress >= 0.7
                                                  ? Colors.orange
                                                  : CRMColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Heartbeat: ${isFresh ? "Fresh" : "Stale"} · '
                                      'New: ${t['newLeads'] ?? 0} · CNR: ${t['cnr'] ?? 0} · CB: ${t['callbacks'] ?? 0}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Sales: ${t['salesTransfers'] ?? 0}',
                                          style: TextStyle(fontSize: 12, color: CRMColors.primary, fontWeight: FontWeight.w600),
                                        ),
                                        const Row(
                                          children: [
                                            Text(
                                              'View Details',
                                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                            ),
                                            Icon(Icons.chevron_right, size: 14, color: Color(0xFF64748B)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 28),
              const Text('Recent Assignments & Reassignments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              if (history.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No recent assignments recorded.'),
                ),
              for (final raw in history)
                Builder(
                  builder: (context) {
                    final h = Map<String, dynamic>.from(raw as Map);
                    final leadId = h['lead_id']?.toString() ?? '';
                    final type = h['assignment_type']?.toString() ?? 'ASSIGNMENT';
                    final destId = h['to_telecaller_id']?.toString() ?? '';
                    final destName = h['to_telecaller_name']?.toString() ?? destId;
                    final leadName = (h['lead_name'] != null && h['lead_name'].toString().isNotEmpty)
                        ? h['lead_name'].toString()
                        : (h['lead_phone']?.toString().isNotEmpty == true ? h['lead_phone'].toString() : 'Lead');
                    final date = h['assigned_at']?.toString().split('.').first.replaceFirst('T', ' ') ?? '';
                    final isOld = type == 'OLD_UNTOUCHED_ALLOCATION';
                    final fromName = (h['from_telecaller_name'] ?? h['fromTelecallerName'])?.toString() ?? '';
                    final isPeer = type == 'PEER_TRANSFER' ||
                        type == 'TELECALLER_TRANSFER' ||
                        fromName.isNotEmpty;
                    final movement = fromName.isNotEmpty ? '$fromName → $destName' : destName;

                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isPeer
                              ? const Color(0xFF0284C7).withValues(alpha: 0.45)
                              : (isOld ? Colors.amber.shade200 : const Color(0xFFE2E8F0)),
                          width: isPeer || isOld ? 1.5 : 1.0,
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        dense: true,
                        onTap: () => _showLeadDetailsDialog(context, h),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: (isPeer
                                  ? const Color(0xFF0284C7)
                                  : (isOld ? Colors.amber : Colors.blue))
                              .withValues(alpha: 0.15),
                          child: Icon(
                            isPeer
                                ? Icons.swap_horiz_rounded
                                : (isOld ? Icons.history : Icons.person_outline),
                            color: isPeer
                                ? const Color(0xFF0369A1)
                                : (isOld ? Colors.amber.shade800 : Colors.blue.shade700),
                            size: 18,
                          ),
                        ),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                leadName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                            ),
                            Flexible(
                              child: Text(
                                movement,
                                style: TextStyle(fontWeight: FontWeight.w600, color: CRMColors.primary, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isPeer)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                                ),
                                child: const Text(
                                  'Telecaller transfer',
                                  style: TextStyle(fontSize: 10, color: Color(0xFF0369A1), fontWeight: FontWeight.bold),
                                ),
                              ),
                            if (isOld)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber.shade400),
                                ),
                                child: Text(
                                  'Old Untouched',
                                  style: TextStyle(fontSize: 10, color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            isPeer
                                ? 'Moved between telecallers · ${h['lead_phone'] ?? ''} · $date${(h['reason']?.toString().isNotEmpty == true) ? ' · ${h['reason']}' : ''}'
                                : '${h['lead_campaign'] != null && h['lead_campaign'].toString().isNotEmpty ? h['lead_campaign'] : "Meta Ads"} · ${h['lead_phone'] ?? ""} · Assigned: $date',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _showLeadDetailsDialog(context, h),
                              icon: const Icon(Icons.info_outline, size: 14),
                              label: const Text('Details'),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => _reassign(context, leadId, telecallers),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                              child: const Text('Reassign'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static Widget _chip(String label, String value, Color color) {
    return Chip(
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
      label: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  static Future<void> _reassign(
    BuildContext context,
    String leadId,
    List<dynamic> telecallers,
  ) async {
    if (leadId.isEmpty) return;
    String? selectedTelecaller = telecallers.isNotEmpty ? telecallers.first['id']?.toString() : null;
    final reasonCtrl = TextEditingController(text: 'Admin reassignment');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Reassign Lead to Telecaller'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lead ID: $leadId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              const Text('Select Destination Telecaller:', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedTelecaller,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final t in telecallers)
                    DropdownMenuItem<String>(
                      value: t['id']?.toString(),
                      child: Text(
                        '${t['name']} (${t['status']} - load ${t['currentWorkload']}/${t['maxCapacity']})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (val) {
                  setModalState(() {
                    selectedTelecaller = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason for reassignment',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reassign')),
          ],
        ),
      ),
    );

    if (ok == true && selectedTelecaller != null && context.mounted) {
      context.read<LeadAllocationMonitorBloc>().add(
            LeadReassignRequested(
              leadId: leadId,
              toTelecallerId: selectedTelecaller!,
              reason: reasonCtrl.text.trim(),
              overrideEligibility: true,
            ),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead reassigned successfully.')),
      );
    }
  }

  static Future<void> _confirmRecoverStaleLeads(BuildContext context) async {
    final timeoutCtrl = TextEditingController(text: '30');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.timer_off_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Text('Recover Stale Assigned Leads'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This will safely reclaim leads assigned to telecallers that have had no calls, activity, or updates past the timeout, resetting them back to the UNASSIGNED_WAITING queue for reallocation.',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: timeoutCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stale Timeout (Minutes)',
                hintText: 'e.g. 30',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Run Recovery'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final timeout = int.tryParse(timeoutCtrl.text.trim()) ?? 30;
      context.read<LeadAllocationMonitorBloc>().add(RecoverStaleLeadsRequested(timeoutMinutes: timeout));
    }
  }

  static Future<void> _confirmAllocateOldLeads(
    BuildContext context,
    dynamic unallocatedCount,
  ) async {
    final count = (unallocatedCount is int)
        ? unallocatedCount
        : int.tryParse(unallocatedCount.toString()) ?? 0;
    if (count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No old untouched leads available to allocate.')),
      );
      return;
    }

    final limitCtrl = TextEditingController(text: '25');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Allocate Old Untouched Leads'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('There are $count old untouched leads waiting for allocation.'),
            const SizedBox(height: 12),
            const Text(
              'The allocation engine will distribute these leads in a round-robin manner to currently active and available telecallers with capacity.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: limitCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Batch size limit',
                hintText: 'e.g. 25',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Allocate Now'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final limit = int.tryParse(limitCtrl.text.trim()) ?? 25;
      context.read<LeadAllocationMonitorBloc>().add(AllocateOldLeadsRequested(limit: limit));
    }
  }

  static void _showLeadDetailsDialog(BuildContext context, Map<String, dynamic> h) {
    final leadId = h['lead_id']?.toString() ?? '';
    final lead = (h['lead'] is Map) ? Map<String, dynamic>.from(h['lead'] as Map) : <String, dynamic>{};
    dynamic rawData = lead['raw_json'];
    if (rawData is String && rawData.isNotEmpty) {
      try {
        rawData = jsonDecode(rawData);
      } catch (_) {}
    }
    final raw = (rawData is Map) ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};

    final leadName = (h['lead_name'] != null && h['lead_name'].toString().isNotEmpty && h['lead_name'] != 'Lead')
        ? h['lead_name'].toString()
        : (raw['full_name'] ??
                raw['Full Name'] ??
                raw['name'] ??
                raw['Name'] ??
                raw['Client Name'] ??
                raw['client name'] ??
                raw['customer_name'] ??
                h['lead_name'] ??
                'Lead')
            .toString();
    final phone = (h['lead_phone'] != null && h['lead_phone'].toString().isNotEmpty)
        ? h['lead_phone'].toString()
        : (lead['sanitized_phone'] ?? raw['phone_number'] ?? raw['phone'] ?? '').toString();
    final email = (lead['sanitized_email'] ?? raw['email'] ?? '').toString();
    final campaign = (h['lead_campaign'] != null && h['lead_campaign'].toString().isNotEmpty)
        ? h['lead_campaign'].toString()
        : (lead['campaign_name'] ?? raw['Campaign Name'] ?? raw['campaign_name'] ?? '').toString();
    final source = (h['lead_source'] ?? lead['source'] ?? 'Meta Ads').toString();
    final telecallerName = (h['to_telecaller_name'] ?? h['to_telecaller_id'] ?? '').toString();
    final assignmentType = (h['assignment_type'] ?? 'ASSIGNMENT').toString();
    final assignedAt = h['assigned_at']?.toString().split('.').first ?? '';
    final allocationStatus = (lead['allocation_status'] ?? 'ASSIGNED_TO_TELECALLER').toString();
    final isOld = lead['is_old_untouched'] == true || assignmentType == 'OLD_UNTOUCHED_ALLOCATION';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: (isOld ? Colors.amber : Colors.blue).withValues(alpha: 0.2),
              child: Icon(
                isOld ? Icons.history : Icons.person,
                color: isOld ? Colors.amber.shade900 : Colors.blue.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(leadName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('Lead ID: $leadId', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isOld ? Colors.amber.shade100 : Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isOld ? Colors.amber.shade400 : Colors.blue.shade300),
              ),
              child: Text(
                isOld ? 'Old Untouched' : 'Active Lead',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isOld ? Colors.amber.shade900 : Colors.blue.shade900,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: CRMBreakpoints.adaptiveWidth(context, 540),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _sectionHeader('Contact Information'),
                _detailRow('Customer Name', leadName),
                _detailRow('Phone Number', phone.isNotEmpty ? phone : 'N/A'),
                if (email.isNotEmpty) _detailRow('Email Address', email),
                if (campaign.isNotEmpty) _detailRow('Campaign', campaign),
                _detailRow('Lead Source', source),
                _detailRow('Allocation Status', allocationStatus),

                const SizedBox(height: 16),
                _sectionHeader('Assignment Details'),
                _detailRow('Assigned Telecaller', telecallerName),
                _detailRow('Assignment Type', assignmentType),
                _detailRow('Assigned At', assignedAt),
                if (h['reason'] != null) _detailRow('Reason', h['reason'].toString()),

                if (raw.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _sectionHeader('Meta Lead Form & Question Responses'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in raw.entries)
                          if (!_isInternalMetaKey(entry.key))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      _cleanKeyLabel(entry.key),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF475569)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      entry.value?.toString() ?? '',
                                      style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
      ),
    );
  }

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isInternalMetaKey(String key) {
    final k = key.toLowerCase();
    return k == 'full_name' || k == 'phone_number' || k == 'email' || k == 'client name';
  }

  static String _cleanKeyLabel(String key) {
    return key.replaceAll('_', ' ').replaceAll('?', '').trim();
  }
}

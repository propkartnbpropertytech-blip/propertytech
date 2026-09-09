import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/sync_manager.dart';
import '../../../core/storage/performance_logger.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';

class SyncDebugScreen extends StatefulWidget {
  const SyncDebugScreen({super.key});

  @override
  State<SyncDebugScreen> createState() => _SyncDebugScreenState();
}

class _SyncDebugScreenState extends State<SyncDebugScreen> {
  final SyncManager _syncManager = SyncManager();
  final RepositoryCoordinator _coordinator = RepositoryCoordinator();
  StreamSubscription<SyncState>? _stateSubscription;
  Timer? _metricsTimer;

  int _outboxCount = 0;
  List<Map<String, dynamic>> _telemetryLogs = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadMetrics();

    // Subscribe to realtime state transitions
    _stateSubscription = _syncManager.stateStream.listen((state) {
      if (mounted) setState(() {});
      _loadMetrics();
    });

    // Periodically refresh metrics
    _metricsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadMetrics();
    });
  }

  Future<void> _loadMetrics() async {
    if (_isRefreshing) return;
    _isRefreshing = true;

    try {
      final outboxItems = await _coordinator.outboxLocal.getQueuedRequests();
      final logs = PerformanceLogger().getLogs();
      if (mounted) {
        setState(() {
          _outboxCount = outboxItems.length;
          _telemetryLogs = logs.reversed.toList();
        });
      }
    } catch (_) {} finally {
      _isRefreshing = false;
    }
  }

  Color _getStateColor(SyncState state) {
    switch (state) {
      case SyncState.connected:
        return CRMColors.success;
      case SyncState.connecting:
      case SyncState.reconnecting:
      case SyncState.syncing:
        return CRMColors.warning;
      case SyncState.disconnected:
      case SyncState.offline:
      default:
        return CRMColors.danger;
    }
  }

  String _getStateLabel(SyncState state) {
    switch (state) {
      case SyncState.connected:
        return 'Connected';
      case SyncState.connecting:
        return 'Connecting';
      case SyncState.reconnecting:
        return 'Reconnecting';
      case SyncState.syncing:
        return 'Syncing';
      case SyncState.offline:
        return 'Offline';
      case SyncState.disconnected:
      default:
        return 'Disconnected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _syncManager.state;
    final stateColor = _getStateColor(state);
    final stateLabel = _getStateLabel(state);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Sync Diagnostics',
          style: CRMTypography.sectionTitle.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: CRMColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CRMSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            CRMCard(
              elevated: true,
              title: 'Realtime Sync Status',
              subtitle: 'Current network sync channel connection health metrics',
              child: Padding(
                padding: const EdgeInsets.only(top: CRMSpacing.m),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Connection Status',
                          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: stateColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: stateColor.withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: CRMSpacing.s),
                            Text(
                              stateLabel,
                              style: CRMTypography.bodyMedium.copyWith(
                                color: stateColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: CRMSpacing.l),
                    _buildMetricRow('Sync Mode', 'Offline-First (Isar Local Cache)'),
                    _buildMetricRow('Outbox Queue', '$_outboxCount pending writes'),
                    _buildMetricRow('Last Pulse', DateFormat('HH:mm:ss').format(DateTime.now())),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CRMSpacing.l),

            // Performance Logger Summary
            CRMCard(
              title: 'Performance & Network Metrics',
              subtitle: 'Recent local database queries and background sync latencies',
              child: Padding(
                padding: const EdgeInsets.only(top: CRMSpacing.m),
                child: SizedBox(
                  height: 350,
                  child: _telemetryLogs.isEmpty
                      ? Center(
                          child: Text(
                            'No telemetry data captured yet.',
                            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                          ),
                        )
                      : ListView.separated(
                          itemCount: _telemetryLogs.length.clamp(0, 50),
                          separatorBuilder: (_, __) => Divider(color: CRMColors.borderOf(context).withOpacity(0.5), height: 1),
                          itemBuilder: (context, index) {
                            final log = _telemetryLogs[index];
                            final operation = log['operation'] as String? ?? 'Unknown';
                            final totalMs = log['totalMs'] as int? ?? 0;
                            final timestamp = log['timestamp'] as String? ?? '';
                            final isarWriteMs = log['isarWriteMs'] as int? ?? 0;
                            final isarReadMs = log['isarReadMs'] as int? ?? 0;
                            final networkMs = log['networkMs'] as int? ?? 0;

                            final timeStr = timestamp.isNotEmpty
                                ? DateFormat('HH:mm:ss').format(DateTime.parse(timestamp))
                                : '';

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                operation,
                                style: CRMTypography.captionBold.copyWith(color: CRMColors.text),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                'IsarRead: ${isarReadMs}ms | Network: ${networkMs}ms | IsarWrite: ${isarWriteMs}ms',
                                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${totalMs}ms',
                                    style: CRMTypography.captionBold.copyWith(
                                      color: totalMs > 500 ? CRMColors.danger : CRMColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    timeStr,
                                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondary, fontSize: 10),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: CRMSpacing.l),

            // Trigger buttons
            Row(
              children: [
                Expanded(
                  child: CRMButton(
                    label: 'Force Connect',
                    onPressed: () => _syncManager.connect(),
                  ),
                ),
                const SizedBox(width: CRMSpacing.m),
                Expanded(
                  child: CRMButton(
                    label: 'Sync Data',
                    onPressed: () => _loadMetrics(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondary)),
          Text(value, style: CRMTypography.bodyMedium.copyWith(color: CRMColors.text, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _metricsTimer?.cancel();
    super.dispose();
  }
}

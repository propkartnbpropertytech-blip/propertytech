import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../integration/services/integration_service.dart';
import 'package:propkart/core/design_system/tokens/app_breakpoints.dart';

class TelecallerDetailDialog extends StatefulWidget {
  final String telecallerId;
  final String? telecallerName;
  final List<dynamic> allTelecallers;
  final VoidCallback? onLeadReassigned;

  const TelecallerDetailDialog({
    super.key,
    required this.telecallerId,
    this.telecallerName,
    this.allTelecallers = const [],
    this.onLeadReassigned,
  });

  static Future<void> show(
    BuildContext context, {
    required String telecallerId,
    String? telecallerName,
    List<dynamic> allTelecallers = const [],
    VoidCallback? onLeadReassigned,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TelecallerDetailDialog(
        telecallerId: telecallerId,
        telecallerName: telecallerName,
        allTelecallers: allTelecallers,
        onLeadReassigned: onLeadReassigned,
      ),
    );
  }

  @override
  State<TelecallerDetailDialog> createState() => _TelecallerDetailDialogState();
}

class _TelecallerDetailDialogState extends State<TelecallerDetailDialog> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  int _selectedCapacity = 10;
  int _savedCapacity = 10;
  bool _savingCapacity = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await DioClient.dio.get(
        ApiConstants.adminTelecallerDetails(widget.telecallerId),
      );
      if (mounted) {
        final data = Map<String, dynamic>.from(res.data['data'] ?? {});
        data['history'] = await _withPeerTransfers(
          widget.telecallerId,
          List<dynamic>.from(data['history'] ?? []),
        );
        if (!mounted) return;
        final cap = (data['workload']?['capacity'] as num?)?.toInt() ?? 10;
        setState(() {
          _data = data;
          _selectedCapacity = cap.clamp(1, 300);
          _savedCapacity = cap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<List<dynamic>> _withPeerTransfers(String telecallerId, List<dynamic> serverHistory) async {
    final local = await IntegrationService().peerTransferHistory();
    final mine = local.where((entry) {
      final fromId = entry['from_telecaller_id']?.toString();
      final toId = entry['to_telecaller_id']?.toString();
      return fromId == telecallerId || toId == telecallerId;
    }).toList();
    if (mine.isEmpty) return serverHistory;
    final merged = <Map<String, dynamic>>[
      for (final raw in serverHistory)
        if (raw is Map) Map<String, dynamic>.from(raw),
    ];
    for (final entry in mine) {
      final exists = merged.any((row) {
        if (row['lead_id']?.toString() != entry['lead_id']?.toString()) return false;
        if (row['to_telecaller_id']?.toString() != entry['to_telecaller_id']?.toString()) return false;
        final serverAt = DateTime.tryParse(row['assigned_at']?.toString() ?? '');
        final localAt = DateTime.tryParse(entry['assigned_at']?.toString() ?? '');
        if (serverAt == null || localAt == null) return false;
        return serverAt.difference(localAt).inMinutes.abs() <= 5;
      });
      if (!exists) merged.add(entry);
    }
    merged.sort((a, b) {
      final aTime = DateTime.tryParse(a['assigned_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = DateTime.tryParse(b['assigned_at']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return merged;
  }

  Future<void> _showManualCapacityInputDialog() async {
    final controller = TextEditingController(text: '$_selectedCapacity');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Max Capacity Limit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter a capacity limit between 1 and 300 leads for this telecaller.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Max Capacity (1 - 300)',
                  hintText: 'e.g. 150',
                  suffixText: 'Leads',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (val) {
                  final n = int.tryParse(val?.trim() ?? '');
                  if (n == null) return 'Please enter a valid number';
                  if (n < 1 || n > 300) return 'Must be between 1 and 300 leads';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                final val = int.parse(controller.text.trim());
                Navigator.pop(ctx);
                setState(() => _selectedCapacity = val);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateCapacity(int newCapacity) async {
    if (_savingCapacity || newCapacity < 1 || newCapacity > 300) return;
    setState(() => _savingCapacity = true);
    try {
      await DioClient.dio.patch(
        ApiConstants.adminTelecallerCapacity(widget.telecallerId),
        data: {'maxCapacity': newCapacity},
      );
      if (mounted) {
        setState(() {
          _savedCapacity = newCapacity;
          _selectedCapacity = newCapacity;
          if (_data != null && _data!['workload'] != null) {
            _data!['workload']['capacity'] = newCapacity;
            final currentLoad = (_data!['workload']['currentWorkload'] as num?)?.toInt() ?? 0;
            _data!['workload']['availableSlots'] = (newCapacity - currentLoad).clamp(0, 999);
          }
          _savingCapacity = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Max capacity updated to $newCapacity leads for ${widget.telecallerName ?? "telecaller"}.'),
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 2),
          ),
        );
        widget.onLeadReassigned?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _savingCapacity = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update capacity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reassignLead(String leadId) async {
    final otherTelecallers = widget.allTelecallers
        .where((t) => t['id']?.toString() != widget.telecallerId)
        .toList();

    String? selectedDest = otherTelecallers.isNotEmpty
        ? otherTelecallers.first['id']?.toString()
        : null;
    final reasonCtrl = TextEditingController(text: 'Admin reassignment from monitor');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reassign Active Lead'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lead ID: $leadId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 16),
              const Text('Select New Telecaller:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (otherTelecallers.isEmpty)
                const Text('No other telecallers available.', style: TextStyle(color: Colors.red))
              else
                DropdownButtonFormField<String>(
                  initialValue: selectedDest,
                  isExpanded: true,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: [
                    for (final t in otherTelecallers)
                      DropdownMenuItem<String>(
                        value: t['id']?.toString(),
                        child: Text(
                          '${t['name']} (${t['status']} · load ${t['currentWorkload']}/${t['maxCapacity']})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (val) {
                    setDialogState(() => selectedDest = val);
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
            FilledButton(
              onPressed: otherTelecallers.isEmpty || selectedDest == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Confirm Reassignment'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedDest != null && mounted) {
      try {
        await DioClient.dio.post(
          ApiConstants.adminReassignLead,
          data: {
            'leadId': leadId,
            'toTelecallerId': selectedDest,
            'reason': reasonCtrl.text.trim(),
            'overrideEligibility': true,
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lead reassigned successfully.')),
          );
          widget.onLeadReassigned?.call();
          _fetchDetails();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reassign: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: CRMBreakpoints.adaptiveWidth(context, 780),
        height: 720,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: CRMColors.primary.withValues(alpha: 0.15),
                      child: Icon(Icons.person, color: CRMColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.telecallerName ?? _data?['profile']?['name']?.toString() ?? 'Telecaller Details',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        if (_data?['profile'] != null)
                          Text(
                            '${_data!['profile']['email'] ?? ''} · ${_data!['profile']['phone'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Refresh',
                      onPressed: _fetchDetails,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),

            // Body
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(_error!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              OutlinedButton(onPressed: _fetchDetails, child: const Text('Retry')),
                            ],
                          ),
                        )
                      : _buildContent(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final profile = Map<String, dynamic>.from(_data?['profile'] ?? {});
    final workload = Map<String, dynamic>.from(_data?['workload'] ?? {});
    final outcomes = Map<String, dynamic>.from(_data?['outcomes'] ?? {});
    final currentLeads = List<dynamic>.from(_data?['currentLeads'] ?? []);
    final history = List<dynamic>.from(_data?['history'] ?? []);

    final status = profile['availability']?.toString() ?? 'INACTIVE';
    final isFresh = profile['heartbeatFresh'] == true;
    final statusColor = status == 'ACTIVE'
        ? (isFresh ? Colors.green : Colors.orange)
        : (status == 'BREAK' ? Colors.blue : Colors.grey);

    final capacity = workload['capacity'] ?? 10;
    final currentLoad = workload['currentWorkload'] ?? 0;
    final availableSlots = workload['availableSlots'] ?? 0;
    final staleCount = workload['staleCount'] ?? 0;
    final progress = capacity > 0 ? (currentLoad / capacity).clamp(0.0, 1.0) : 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Status & Workload Progress Card
          Card(
            elevation: 0,
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isFresh ? 'Online (Heartbeat Active)' : 'Offline / Inactive Heartbeat',
                            style: TextStyle(
                              fontSize: 12,
                              color: isFresh ? Colors.green.shade700 : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Workload: $currentLoad / $capacity Leads',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress.toDouble(),
                      minHeight: 8,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$availableSlots lead slots available for new allocation',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      if (staleCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Text(
                            '$staleCount Untouched (>30m) - Stale',
                            style: TextStyle(fontSize: 11, color: Colors.red.shade800, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.tune, size: 18, color: CRMColors.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Max Capacity Limit',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: _savingCapacity ? null : () => _showManualCapacityInputDialog(),
                            child: Tooltip(
                              message: 'Click to enter custom limit (1 - 300)',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: CRMColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: CRMColors.primary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$_selectedCapacity Leads',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: CRMColors.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.edit, size: 12, color: CRMColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (_selectedCapacity != _savedCapacity)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                '(Unsaved: $_selectedCapacity)',
                                style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            ),
                            onPressed: _savingCapacity || _selectedCapacity == _savedCapacity
                                ? null
                                : () => _updateCapacity(_selectedCapacity),
                            icon: _savingCapacity
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.check, size: 14),
                            label: Text(_savingCapacity ? 'Saving...' : 'Save Limit', style: const TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton.outlined(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove, size: 16),
                        tooltip: 'Decrease by 1',
                        onPressed: _selectedCapacity > 1
                            ? () => setState(() => _selectedCapacity--)
                            : null,
                      ),
                      Expanded(
                        child: Slider(
                          value: _selectedCapacity.toDouble().clamp(1.0, 300.0),
                          min: 1.0,
                          max: 300.0,
                          divisions: 299,
                          label: '$_selectedCapacity',
                          activeColor: CRMColors.primary,
                          onChanged: (val) {
                            setState(() => _selectedCapacity = val.round());
                          },
                        ),
                      ),
                      IconButton.outlined(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add, size: 16),
                        tooltip: 'Increase by 1',
                        onPressed: _selectedCapacity < 300
                            ? () => setState(() => _selectedCapacity++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        'Presets:',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                      for (final preset in [5, 10, 15, 20, 25, 30, 50, 100, 200, 300])
                        ActionChip(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                          label: Text(
                            preset == 10 ? '10 (Default)' : '$preset',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: _selectedCapacity == preset ? FontWeight.bold : FontWeight.normal,
                              color: _selectedCapacity == preset ? Colors.white : null,
                            ),
                          ),
                          backgroundColor: _selectedCapacity == preset ? CRMColors.primary : null,
                          onPressed: () {
                            setState(() => _selectedCapacity = preset);
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Row 2: Performance Summary Grid (Strictly 4 KPIs)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metricBox(
                'Assigned',
                _directory.isEmpty
                    ? '${_data?['leadStats']?['activeAssigned'] ?? currentLeads.length}'
                    : '${_callingQueue.length}',
                Icons.assignment_outlined,
                Colors.blue,
                isDark,
                onTap: () => _showLeadList(
                  'Assigned now',
                  _callingQueue,
                  subtitle: 'New and follow-up leads still on this telecaller\'s calling queue.',
                ),
              ),
              _metricBox(
                'Overall Assigned',
                _directory.isEmpty
                    ? '${_data?['leadStats']?['overallAssigned'] ?? _data?['leadStats']?['totalAssigned'] ?? 0}'
                    : '${_directory.length}',
                Icons.history_rounded,
                Colors.indigo,
                isDark,
                onTap: () => _showLeadList(
                  'Every lead assigned to ${widget.telecallerName ?? 'this telecaller'}',
                  _directory,
                  subtitle: 'Current status of each lead. One row per customer.',
                ),
              ),
              _metricBox(
                'CNR',
                '${outcomes['cnr'] ?? 0}',
                Icons.phone_missed,
                Colors.orange,
                isDark,
                onTap: () => _openTelecallerQueue('/telecaller/cnr'),
              ),
              _metricBox(
                'Callbacks',
                '${outcomes['callbacks'] ?? 0}',
                Icons.phone_callback_rounded,
                Colors.blue,
                isDark,
                onTap: () => _openTelecallerQueue('/telecaller/callbacks'),
              ),
              _metricBox(
                'Assigned to Sales',
                _directory.isEmpty ? '${outcomes['salesHandoffs'] ?? 0}' : '${_salesHandoffs.length}',
                Icons.check_circle_outline,
                Colors.green,
                isDark,
                onTap: () => _showLeadList(
                  'Handed to sales',
                  _salesHandoffs,
                  subtitle: 'The lead and the sales person it was handed to.',
                  showHandedTo: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Section 3: Active Assigned Leads List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calling queue (${_directory.isEmpty ? currentLeads.length : _callingQueue.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'New and follow-up leads still on My Calling Leads. CNR and Callback are counted on their own cards.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (currentLeads.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text('No active leads currently assigned to this telecaller.'),
              ),
            )
          else
            for (final rawLead in currentLeads)
              Builder(
                builder: (context) {
                  final lead = Map<String, dynamic>.from(rawLead as Map);
                  final leadId = lead['id']?.toString() ?? '';
                  final name = lead['name']?.toString() ?? 'Lead';
                  final phone = lead['phone']?.toString() ?? '';
                  final campaign = lead['campaign']?.toString() ?? 'Meta Ads';
                  final priority = lead['priority']?.toString() ?? 'NORMAL';
                  final allocStatus = lead['allocationStatus']?.toString() ?? '';
                  final ageMinutes = lead['ageMinutes'] ?? 0;
                  final isStale = lead['isStale'] == true;
                  final callAttempts = lead['callAttemptCount'] ?? 0;

                  Color priorityColor;
                  switch (priority) {
                    case 'HOT':
                      priorityColor = Colors.red;
                      break;
                    case 'OLD_PENDING':
                      priorityColor = Colors.amber.shade800;
                      break;
                    default:
                      priorityColor = Colors.blue;
                  }

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isStale
                            ? Colors.red.shade300
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        width: isStale ? 1.5 : 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: priorityColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: priorityColor.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              priority,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: priorityColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      phone,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                    if (isStale) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade100,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'STALE (>30m untouched)',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Campaign: $campaign · Status: $allocStatus · Assigned: ${ageMinutes}m ago · Calls: $callAttempts',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            ),
                            onPressed: () => _reassignLead(leadId),
                            icon: const Icon(Icons.swap_horiz, size: 14),
                            label: const Text('Reassign', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          const SizedBox(height: 20),

          // Section 4: Recent Assignment History
          const Text('Recent Assignment History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No history entries recorded for this telecaller.', style: TextStyle(color: Colors.grey)),
            )
          else
            for (final rawH in history)
              Builder(
                builder: (context) {
                  final h = Map<String, dynamic>.from(rawH as Map);
                  final type = h['assignment_type']?.toString() ?? 'ASSIGNMENT';
                  final date = h['assigned_at']?.toString().split('.').first.replaceFirst('T', ' ') ?? '';
                  final reason = h['reason']?.toString() ?? '';
                  final fromName = (h['from_telecaller_name'] ?? '').toString();
                  final toName = (h['to_telecaller_name'] ?? '').toString();
                  final isPeer = type == 'PEER_TRANSFER' || fromName.isNotEmpty;
                  final label = isPeer ? 'TELECALLER TRANSFER' : type;
                  final detail = isPeer
                      ? '${fromName.isNotEmpty ? fromName : 'Telecaller'} → ${toName.isNotEmpty ? toName : 'Telecaller'}${reason.isNotEmpty ? ' · $reason' : ''}'
                      : (reason.isNotEmpty ? reason : 'Assigned');

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(
                          isPeer
                              ? Icons.swap_horiz_rounded
                              : type.contains('RECOVERY')
                                  ? Icons.restart_alt
                                  : type.contains('OLD')
                                      ? Icons.history
                                      : Icons.arrow_forward,
                          size: 14,
                          color: isPeer
                              ? const Color(0xFF0369A1)
                              : type.contains('RECOVERY')
                                  ? Colors.red
                                  : CRMColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            detail,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(date, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _directory {
    final raw = _data?['leadDirectory'];
    if (raw is! List) return const [];
    return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  bool _isCnrRow(Map<String, dynamic> lead) {
    final status = (lead['campaignStatus'] ?? '').toString().trim().toLowerCase();
    final alloc = (lead['allocationStatus'] ?? '').toString();
    return alloc == 'CNR' || status == 'cnr';
  }

  bool _isCallbackRow(Map<String, dynamic> lead) {
    if (_isCnrRow(lead)) return false;
    final status = (lead['campaignStatus'] ?? '').toString().trim().toLowerCase();
    final alloc = (lead['allocationStatus'] ?? '').toString();
    return alloc == 'CALLBACK' || status == 'callback' || status == 'call back';
  }

  List<Map<String, dynamic>> get _callingQueue => _directory.where((lead) {
    final status = (lead['campaignStatus'] ?? '').toString().trim().toLowerCase();
    final alloc = (lead['allocationStatus'] ?? '').toString().toUpperCase();
    if (status.contains('not interest') || status == 'archived' || status == 'closed' || status == 'won' || status == 'property listed' || status == 'listed') {
      return false;
    }
    if (alloc == 'HANDED_TO_SALES' || status == 'assigned' || status == 'picked up') return false;
    if ((lead['handedToName'] ?? '').toString().trim().isNotEmpty) return false;
    if (status == 'follow up' || status == 'follow-up' || alloc == 'FOLLOWUP') return true;
    if (_isCnrRow(lead) || _isCallbackRow(lead)) return false;
    return true;
  }).toList();

  List<Map<String, dynamic>> get _salesHandoffs => _directory.where((lead) {
    final status = (lead['campaignStatus'] ?? '').toString().trim().toLowerCase();
    final alloc = (lead['allocationStatus'] ?? '').toString();
    return alloc == 'HANDED_TO_SALES' || status == 'assigned';
  }).toList();

  void _openTelecallerQueue(String path) {
    final name = (widget.telecallerName ?? _data?['profile']?['name']?.toString() ?? '').trim();
    final uri = Uri(
      path: path,
      queryParameters: {
        'telecallerId': widget.telecallerId,
        if (name.isNotEmpty) 'telecallerName': name,
      },
    );
    Navigator.of(context).pop();
    context.go(uri.toString());
  }

  void _showLeadList(String title, List<Map<String, dynamic>> leads, {String? subtitle, bool showHandedTo = false}) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ),
                if (leads.isEmpty)
                  const Text('No leads in this list.')
                else
                  SizedBox(
                    height: 360,
                    child: ListView.separated(
                      itemCount: leads.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final lead = leads[index];
                        final status = (lead['campaignStatus'] ?? 'New').toString();
                        final handed = (lead['handedToName'] ?? '').toString();
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text((lead['name'] ?? 'Lead').toString()),
                          subtitle: Text(
                            [
                              if ((lead['phone'] ?? '').toString().isNotEmpty) lead['phone'],
                              lead['leadType'] ?? 'Requirement',
                              'Status: $status',
                              if (showHandedTo && handed.isNotEmpty) 'Handed to $handed',
                            ].join(' · '),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _metricBox(String label, String value, IconData icon, Color color, bool isDark, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

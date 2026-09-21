import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/security/role_guard.dart';
import '../../campaign/models/campaign_followup_model.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../../integration/services/integration_service.dart';
import '../bloc/telecaller_dashboard_bloc.dart';
import '../data/telecaller_repository.dart';
import '../widgets/telecaller_availability_toggle.dart';

class TelecallerDashboardScreen extends StatelessWidget {
  const TelecallerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TelecallerDashboardBloc()..add(TelecallerDashboardRequested()),
      child: const _TelecallerDashboardView(),
    );
  }
}

class _TelecallerDashboardView extends StatefulWidget {
  const _TelecallerDashboardView();

  @override
  State<_TelecallerDashboardView> createState() => _TelecallerDashboardViewState();
}

class _TelecallerDashboardViewState extends State<_TelecallerDashboardView> {
  final TelecallerRepository _repository = TelecallerRepository();
  final TextEditingController _noteController = TextEditingController();

  // Personal Notes state
  List<Map<String, dynamic>> _personalNotes = [];

  // Transferred leads state
  int _transferredPage = 1;
  int _transferredTotal = 0;
  int _transferredTotalPages = 1;
  List<dynamic> _transferredLeads = [];
  bool _loadingTransferred = false;

  // Active followups preview state
  List<CampaignFollowupModel> _followups = [];
  bool _loadingFollowups = false;

  @override
  void initState() {
    super.initState();
    _loadPersonalNotes();
    _loadTransferredLeads();
    _loadFollowups();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // --- PERSONAL NOTES PERSISTENCE ---
  String get _notesStorageKey =>
      'telecaller_notes_${RoleGuard.currentUser?.id ?? 'default'}';

  Future<void> _loadPersonalNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_notesStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        if (mounted) {
          setState(() {
            _personalNotes = decoded
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _savePersonalNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notesStorageKey, jsonEncode(_personalNotes));
    } catch (_) {}
  }

  void _addPersonalNote() {
    final text = _noteController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _personalNotes.insert(0, {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': text,
        'isDone': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      _noteController.clear();
    });
    _savePersonalNotes();
  }

  void _toggleNoteDone(int index) {
    setState(() {
      _personalNotes[index]['isDone'] = !(_personalNotes[index]['isDone'] == true);
    });
    _savePersonalNotes();
  }

  void _deleteNote(int index) {
    setState(() {
      _personalNotes.removeAt(index);
    });
    _savePersonalNotes();
  }

  // --- TRANSFERRED LEADS API ---
  Future<void> _loadTransferredLeads([int? page]) async {
    final targetPage = page ?? _transferredPage;
    setState(() => _loadingTransferred = true);
    try {
      final res = await _repository.getTransferredLeads(page: targetPage, limit: 10);
      if (mounted) {
        setState(() {
          _transferredPage = targetPage;
          _transferredLeads = res['leads'] as List? ?? [];
          _transferredTotal = res['total'] as int? ?? 0;
          _transferredTotalPages = res['totalPages'] as int? ?? 1;
          _loadingTransferred = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingTransferred = false);
    }
  }

  // --- FOLLOWUPS API ---
  Future<void> _loadFollowups() async {
    setState(() => _loadingFollowups = true);
    try {
      final list = await IntegrationService().fetchFollowups(filter: 'all');
      if (mounted) {
        setState(() {
          _followups = list.take(6).toList();
          _loadingFollowups = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFollowups = false);
    }
  }

  // --- REMARKS EDIT MODAL ---
  void _showEditRemarksDialog(Map<String, dynamic> activity) {
    final remarksCtrl = TextEditingController(text: activity['remarks'] ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit_note_rounded, color: CRMColors.primary),
            const SizedBox(width: 8),
            const Text('Edit Call Remark', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Client: ${activity['clientName'] ?? 'Lead'} (${activity['phone'] ?? ''})',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: remarksCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter updated call remarks...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CRMColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newRemarks = remarksCtrl.text.trim();
              Navigator.of(dialogCtx).pop();
              try {
                await _repository.updateAttemptRemarks(activity['id'], newRemarks);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Remark updated successfully.'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                  context.read<TelecallerDashboardBloc>().add(TelecallerDashboardRequested());
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update remark: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Save Remark'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TelecallerDashboardBloc, TelecallerDashboardState>(
      builder: (context, state) {
        final data = state.data;
        if (state.loading && data.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final next = data['nextLead'] as Map<String, dynamic>?;
        final recentActivities = (data['recentActivity'] as List?) ?? [];
        final isWide = MediaQuery.of(context).size.width >= 1050;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<TelecallerDashboardBloc>().add(TelecallerDashboardRequested());
            await Future.wait([
              _loadTransferredLeads(1),
              _loadFollowups(),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              const CRMPageHeader(
                title: 'Telecaller Dashboard',
                benefit: 'Availability, workload, and next lead come from the server.',
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                ),

              // Availability bar
              Row(
                children: [
                  const TelecallerAvailabilityToggle(),
                  const SizedBox(width: 12),
                  Text(
                    data['heartbeatFresh'] == true
                        ? '• System Live: Eligible to receive fresh incoming leads.'
                        : '• Standby: Turn switch ACTIVE to start receiving leads.',
                    style: TextStyle(
                      color: data['heartbeatFresh'] == true ? const Color(0xFF059669) : const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // KPI Cards Grid (including Not Interested)
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _clickableKpi(context, 'My assigned leads', '${data['assignedLeads'] ?? 0}', Icons.assignment_outlined, '/telecaller/leads'),
                  _clickableKpi(context, 'Uncontacted', '${data['uncontacted'] ?? 0}', Icons.mark_email_unread_outlined, '/telecaller/leads'),
                  _clickableKpi(context, 'Callbacks', '${data['callbackCount'] ?? 0}', Icons.event_repeat, '/telecaller/callbacks'),
                  _clickableKpi(context, "Today's callbacks", '${data['todaysCallbacks'] ?? 0}', Icons.today_outlined, '/telecaller/callbacks'),
                  _clickableKpi(context, 'CNR / Retries', '${data['cnrCount'] ?? 0}', Icons.phone_missed_outlined, '/telecaller/cnr'),
                  _clickableKpi(context, 'Picked up', '${data['pickedUp'] ?? 0}', Icons.call_received, '/telecaller/leads'),
                  _clickableKpi(context, 'Handed to Sales', '${data['handedToSales'] ?? 0}', Icons.handshake_outlined, '/telecaller/leads'),
                  _clickableKpi(
                    context,
                    'Not Interested',
                    '${data['notInterestedCount'] ?? 0}',
                    Icons.do_not_disturb_on_rounded,
                    '/campaign/leads?view=not_interested',
                    accentColor: const Color(0xFFEF4444),
                  ),
                  _clickableKpi(
                    context,
                    'Workload',
                    '${data['currentWorkload'] ?? 0}/${data['maxCapacity'] ?? 0}',
                    Icons.speed,
                    '/telecaller/leads',
                  ),
                  _clickableKpi(context, 'Remaining Capacity', '${data['remainingCapacity'] ?? 0}', Icons.hourglass_bottom, '/telecaller/leads'),
                ],
              ),
              const SizedBox(height: 24),

              // Next Lead Callout Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0.5,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE0E7FF),
                    child: Icon(Icons.phone_forwarded_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  title: const Text('Next waiting lead', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    next == null
                        ? 'No actionable lead. Go ACTIVE to receive waiting-queue work.'
                        : _leadDisplayName(next),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () => context.go('/telecaller/leads'),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Call Queue'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CRMColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  onTap: () => context.go('/telecaller/leads'),
                ),
              ),
              const SizedBox(height: 24),

              // Two-Column Section: Left (Followups & Transferred Leads), Right (Personal Notes & Recent Activity)
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          _buildFollowupsCard(context),
                          const SizedBox(height: 24),
                          _buildTransferredLeadsCard(context),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          _buildPersonalNotesCard(context),
                          const SizedBox(height: 24),
                          _buildRecentActivityCard(context, recentActivities),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _buildFollowupsCard(context),
                    const SizedBox(height: 24),
                    _buildPersonalNotesCard(context),
                    const SizedBox(height: 24),
                    _buildRecentActivityCard(context, recentActivities),
                    const SizedBox(height: 24),
                    _buildTransferredLeadsCard(context),
                  ],
                ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET 1: FOLLOW-UPS PREVIEW CARD ---
  Widget _buildFollowupsCard(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('My Scheduled Follow-ups', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                  child: Text('${_followups.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.go('/campaign/leads?view=followups'),
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_loadingFollowups)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_followups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_available_rounded, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No scheduled callbacks today.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _followups.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final fu = _followups[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.access_time_rounded, color: Color(0xFFD97706), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      fu.clientName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (fu.isToday)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('Today', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                    ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                    child: Text(fu.leadType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text(DateFormat('EEE, d MMM • h:mm a').format(fu.scheduledAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  if (fu.mobile.isNotEmpty) ...[
                                    const SizedBox(width: 10),
                                    Icon(Icons.phone_outlined, size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(fu.mobile, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  ],
                                ],
                              ),
                              if (fu.remarks.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  fu.remarks,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (fu.mobile.isNotEmpty) ...[
                              IconButton(
                                icon: const Icon(Icons.phone_forwarded, size: 18, color: Color(0xFF059669)),
                                tooltip: 'Call client',
                                onPressed: () async {
                                  final uri = Uri.parse('tel:${fu.mobile}');
                                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.chat_outlined, size: 18, color: Color(0xFF25D366)),
                                tooltip: 'WhatsApp',
                                onPressed: () async {
                                  final clean = fu.mobile.replaceAll(RegExp(r'\D'), '');
                                  final uri = Uri.parse('https://wa.me/$clean');
                                  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                                },
                              ),
                            ],
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                              tooltip: 'Open in Follow-ups tab',
                              onPressed: () => context.go('/campaign/leads?view=followups'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET 2: RECENT LEADS TRANSFERRED TO SALES TABLE WITH PAGINATION ---
  Widget _buildTransferredLeadsCard(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.handshake_outlined, color: Color(0xFF059669), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Recent Leads Transferred to Sales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(12)),
                  child: Text('$_transferredTotal', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Refresh transferred leads',
                  onPressed: () => _loadTransferredLeads(_transferredPage),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_loadingTransferred)
              const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
            else if (_transferredLeads.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No transferred leads yet.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  horizontalMargin: 8,
                  columnSpacing: 18,
                  headingRowHeight: 40,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 56,
                  headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Client Name')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Transferred To')),
                    DataColumn(label: Text('Transferred At')),
                    DataColumn(label: Text('Remarks')),
                  ],
                  rows: _transferredLeads.asMap().entries.map((entry) {
                    final index = (_transferredPage - 1) * 10 + entry.key + 1;
                    final lead = entry.value as Map;
                    final clientName = (lead['clientName'] ?? 'Lead').toString();
                    final phone = (lead['phone'] ?? '').toString();
                    final leadType = (lead['leadType'] ?? 'Requirement').toString();
                    final transferredTo = (lead['transferredToName'] ?? 'Sales Rep').toString();
                    final remarks = (lead['remarks'] ?? '').toString();

                    String timeStr = '-';
                    if (lead['transferredAt'] != null) {
                      final dt = DateTime.tryParse(lead['transferredAt'].toString());
                      if (dt != null) timeStr = DateFormat('d MMM, h:mm a').format(dt.toLocal());
                    }

                    return DataRow(
                      cells: [
                        DataCell(Text('$index', style: const TextStyle(fontSize: 12, color: Colors.grey))),
                        DataCell(Text(clientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                        DataCell(Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF475569)))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: leadType.toLowerCase().contains('property') ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(leadType, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: leadType.toLowerCase().contains('property') ? const Color(0xFFD97706) : const Color(0xFF2563EB))),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircleAvatar(radius: 10, backgroundColor: Color(0xFFE2E8F0), child: Icon(Icons.person, size: 12, color: Color(0xFF475569))),
                              const SizedBox(width: 6),
                              Text(transferredTo, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                            ],
                          ),
                        ),
                        DataCell(Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey))),
                        DataCell(
                          SizedBox(
                            width: 180,
                            child: Text(
                              remarks.isEmpty ? '-' : remarks,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Pagination Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Showing ${min((_transferredPage - 1) * 10 + 1, _transferredTotal)}–${min(_transferredPage * 10, _transferredTotal)} of $_transferredTotal transferred leads',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _transferredPage > 1 ? () => _loadTransferredLeads(_transferredPage - 1) : null,
                        icon: const Icon(Icons.chevron_left, size: 16),
                        label: const Text('Previous', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text('Page $_transferredPage of $_transferredTotalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _transferredPage < _transferredTotalPages ? () => _loadTransferredLeads(_transferredPage + 1) : null,
                        icon: const Icon(Icons.chevron_right, size: 16),
                        label: const Text('Next', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- WIDGET 3: PERSONAL NOTES & TASKS CHECKLIST ---
  Widget _buildPersonalNotesCard(BuildContext context) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.checklist_rtl_rounded, color: Color(0xFF8B5CF6), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Personal Notes & Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)),
                  child: Text('${_personalNotes.where((n) => n['isDone'] != true).length} active', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Add Note Input Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    onSubmitted: (_) => _addPersonalNote(),
                    decoration: InputDecoration(
                      hintText: 'Add a personal note or reminder...',
                      hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addPersonalNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  child: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_personalNotes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: Text('No notes yet. Add your personal reminders above.', style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _personalNotes.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final note = _personalNotes[i];
                  final isDone = note['isDone'] == true;
                  return InkWell(
                    onTap: () => _toggleNoteDone(i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // Exact left-side checkbox
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isDone,
                              activeColor: const Color(0xFF8B5CF6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (_) => _toggleNoteDone(i),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              (note['text'] ?? '').toString(),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDone ? Colors.grey.shade400 : const Color(0xFF1E293B),
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                decorationColor: Colors.grey.shade400,
                                decorationThickness: 2,
                                fontWeight: isDone ? FontWeight.normal : FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                            onPressed: () => _deleteNote(i),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET 4: RECENT ACTIVITY & CALL LOG FEED ---
  Widget _buildRecentActivityCard(BuildContext context, List<dynamic> recentActivities) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.history_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                const SizedBox(width: 10),
                const Text('Recent Activity & Call Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                const Spacer(),
                Text(
                  'Today: ${recentActivities.length}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const Divider(height: 24),
            if (recentActivities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.phone_missed_outlined, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No calls logged today yet.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentActivities.length,
                separatorBuilder: (context, index) => const Divider(height: 16),
                itemBuilder: (context, i) {
                  final act = Map<String, dynamic>.from(recentActivities[i] as Map);
                  final clientName = (act['clientName'] ?? 'Lead').toString();
                  final phone = (act['phone'] ?? '').toString();
                  final outcome = (act['outcome'] ?? '').toString().toUpperCase();
                  final remarks = (act['remarks'] ?? '').toString();
                  final attemptNum = act['attemptNumber'] ?? 1;
                  final transferredTo = act['transferredTo'];

                  String timeStr = '-';
                  if (act['createdAt'] != null) {
                    final dt = DateTime.tryParse(act['createdAt'].toString());
                    if (dt != null) timeStr = DateFormat('h:mm a').format(dt.toLocal());
                  }

                  // Color & label based on outcome
                  Color badgeBg;
                  Color badgeText;
                  String badgeLabel;
                  if (outcome == 'PICKED_UP' || transferredTo != null) {
                    badgeBg = const Color(0xFFECFDF5);
                    badgeText = const Color(0xFF059669);
                    badgeLabel = transferredTo != null ? 'Handed to Sales: $transferredTo' : 'Picked up / Qualified';
                  } else if (outcome == 'CALLBACK') {
                    badgeBg = const Color(0xFFFEF3C7);
                    badgeText = const Color(0xFFD97706);
                    badgeLabel = 'Callback Scheduled';
                  } else if (outcome == 'CNR') {
                    badgeBg = const Color(0xFFFFEDD5);
                    badgeText = const Color(0xFFEA580C);
                    badgeLabel = 'CNR (Attempt $attemptNum)';
                  } else if (outcome == 'NOT_INTERESTED' || outcome.contains('LOST')) {
                    badgeBg = const Color(0xFFFEE2E2);
                    badgeText = const Color(0xFFDC2626);
                    badgeLabel = 'Not Interested';
                  } else {
                    badgeBg = const Color(0xFFF1F5F9);
                    badgeText = const Color(0xFF475569);
                    badgeLabel = outcome;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(timeStr, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              clientName,
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (phone.isNotEmpty) ...[
                            Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(width: 8),
                          ],
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF64748B)),
                            tooltip: 'Edit remarks',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showEditRemarksDialog(act),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(6)),
                            child: Text(badgeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeText)),
                          ),
                        ],
                      ),
                      if (remarks.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '“$remarks”',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _clickableKpi(BuildContext context, String title, String value, IconData icon, String route, {Color? accentColor}) {
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(12),
          child: StatCard(
            title: title,
            value: value,
            icon: icon,
            accentColor: accentColor ?? CRMColors.primary,
            isCompact: true,
          ),
        ),
      ),
    );
  }

  static String _leadDisplayName(Map next) {
    dynamic raw = next['raw_json'];
    if (raw is String && raw.isNotEmpty) {
      try {
        raw = jsonDecode(raw);
      } catch (_) {}
    }
    if (raw is Map) {
      final candidates = [
        raw['full_name'],
        raw['Full Name'],
        raw['name'],
        raw['Name'],
        raw['client name'],
        raw['Client Name'],
        raw['customer_name'],
        next['customer_name'],
        next['name'],
      ];
      for (final c in candidates) {
        if (c != null && c.toString().trim().isNotEmpty) {
          return c.toString().trim();
        }
      }
    }
    final phone = (next['sanitized_phone'] ?? (raw is Map ? raw['phone_number'] : null))?.toString().trim();
    if (phone != null && phone.isNotEmpty) {
      return 'Lead ($phone)';
    }
    return 'Lead assigned';
  }
}

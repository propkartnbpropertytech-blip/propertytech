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
import '../../../core/security/role_guard.dart';
import '../../campaign/models/campaign_followup_model.dart';
import '../../dashboard/widgets/stat_card.dart';
import '../../dashboard/widgets/welcome_header.dart';
import '../../integration/services/integration_service.dart';
import '../bloc/telecaller_dashboard_bloc.dart';
import '../data/telecaller_repository.dart';
import 'package:propkart/core/design_system/tokens/app_breakpoints.dart';

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
  int _notesPage = 1;
  static const int _notesPerPage = 5;

  // Transferred leads state
  int _transferredPage = 1;
  int _transferredTotal = 0;
  int _transferredTotalPages = 1;
  List<dynamic> _transferredLeads = [];
  bool _loadingTransferred = false;

  // Active followups preview state
  List<CampaignFollowupModel> _followups = [];
  int _followupsPage = 1;
  static const int _followupsPerPage = 5;
  bool _loadingFollowups = false;

  // Recent activity pagination state
  int _activityPage = 1;
  static const int _activityPerPage = 10;

  StreamSubscription<Map<String, dynamic>>? _leadEventsSub;

  @override
  void initState() {
    super.initState();
    _loadPersonalNotes();
    _loadTransferredLeads();
    _loadFollowups();
    _leadEventsSub = IntegrationService.leadEvents.stream.listen((event) {
      if (!mounted) return;
      final type = event['type']?.toString();
      if (type == 'PEER_TRANSFER' || type == 'TRANSFER_COMPLETED' || type == 'OUTCOME_RECORDED') {
        _loadFollowups();
        _loadTransferredLeads(_transferredPage);
      }
    });
  }

  @override
  void dispose() {
    _leadEventsSub?.cancel();
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
      _notesPage = 1;
    });
    _savePersonalNotes();
  }

  void _toggleNoteDone(String id) {
    final idx = _personalNotes.indexWhere((n) => n['id'] == id);
    if (idx != -1) {
      setState(() {
        _personalNotes[idx]['isDone'] = !(_personalNotes[idx]['isDone'] == true);
      });
      _savePersonalNotes();
    }
  }

  void _deleteNote(String id) {
    setState(() {
      _personalNotes.removeWhere((n) => n['id'] == id);
      final totalPages = (_personalNotes.isEmpty ? 1 : (_personalNotes.length / _notesPerPage).ceil());
      if (_notesPage > totalPages) {
        _notesPage = totalPages;
      }
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
        final rawLeads = List<dynamic>.from(res['leads'] as List? ?? []);
        rawLeads.sort((a, b) {
          final dtA = DateTime.tryParse(a['transferredAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          final dtB = DateTime.tryParse(b['transferredAt']?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
          return dtB.compareTo(dtA);
        });
        setState(() {
          _transferredPage = targetPage;
          _transferredLeads = rawLeads;
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
  bool _followupBelongsToMe(CampaignFollowupModel followup) {
    final myId = RoleGuard.currentUser?.id.trim().toLowerCase();
    if (myId == null || myId.isEmpty) return true;
    if (followup.telecallerId != null && followup.telecallerId!.trim().toLowerCase() == myId) {
      return true;
    }
    final local = IntegrationService().getLeadById(followup.leadId);
    final assigned = (local?.assignedTelecallerId ?? followup.lead?.assignedTelecallerId)
        ?.trim()
        .toLowerCase();
    if (assigned == null || assigned.isEmpty) return true;
    return assigned == myId;
  }

  Future<void> _loadFollowups() async {
    setState(() => _loadingFollowups = true);
    try {
      final service = IntegrationService();
      if (service.leads.isEmpty) {
        try {
          await service.fetchServerLeads(silent: true);
        } catch (_) {}
      }
      final list = await service.fetchFollowups(filter: 'all');
      if (mounted) {
        final activeFollowups = list.where((f) {
          if (f.status == 'Completed' || f.status == 'Cancelled') return false;
          final local = service.getLeadById(f.leadId);
          final cs = (local?.campaignStatus ?? f.lead?.campaignStatus ?? '').trim().toLowerCase();
          final alloc = (local?.allocationStatus ?? f.lead?.allocationStatus ?? '').trim().toUpperCase();
          if (cs == 'callback' || cs == 'call back' || alloc == 'CALLBACK') return false;
          if (cs == 'cnr' || alloc == 'CNR') return false;
          if (cs == 'not interested' || alloc == 'RELEASED') return false;
          return _followupBelongsToMe(f);
        }).toList();
        final seenLeadIds = activeFollowups.map((f) => f.leadId).toSet();
        final myId = RoleGuard.currentUser?.id.trim().toLowerCase();
        for (final lead in service.leads) {
          if (seenLeadIds.contains(lead.id)) continue;
          final cs = lead.campaignStatus.trim().toLowerCase();
          final alloc = (lead.allocationStatus ?? '').trim().toUpperCase();
          final markedFollowup = cs == 'follow up' || cs == 'follow-up' || alloc == 'FOLLOWUP';
          if (!markedFollowup) continue;
          if (cs == 'callback' || cs == 'call back' || alloc == 'CALLBACK') continue;
          if (cs == 'cnr' || alloc == 'CNR') continue;
          final fuStatus = (lead.followupStatus ?? 'Pending').trim().toLowerCase();
          if (fuStatus == 'completed' || fuStatus == 'cancelled') continue;
          final assigned = lead.assignedTelecallerId?.trim().toLowerCase();
          if (myId != null && myId.isNotEmpty && assigned != null && assigned.isNotEmpty && assigned != myId) {
            continue;
          }
          final name = lead.getStringValue('full_name').trim().isNotEmpty
              ? lead.getStringValue('full_name').trim()
              : (lead.getStringValue('name').trim().isNotEmpty ? lead.getStringValue('name').trim() : 'Campaign Lead');
          final phone = lead.getStringValue('phone_number').trim().isNotEmpty
              ? lead.getStringValue('phone_number').trim()
              : lead.getStringValue('phone').trim();
          activeFollowups.add(CampaignFollowupModel(
            id: 'local_${lead.id}',
            leadId: lead.id,
            leadType: lead.leadType,
            clientName: name,
            mobile: phone,
            scheduledAt: lead.followupScheduledAt ?? DateTime.now(),
            remarks: lead.followupRemarks ?? '',
            status: lead.followupStatus ?? 'Pending',
            createdAt: lead.receivedAt,
            lead: lead,
            telecallerId: lead.assignedTelecallerId,
          ));
          seenLeadIds.add(lead.id);
        }
        activeFollowups.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

        setState(() {
          _followups = activeFollowups;
          _followupsPage = 1;
          _loadingFollowups = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFollowups = false);
    }
  }


  void _showTransferRemarkDialog(
    BuildContext context,
    String clientName,
    String remarks,
    String transferredTo,
    String timeStr,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.comment_outlined, color: Color(0xFF2563EB), size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Transfer Remarks', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: CRMBreakpoints.adaptiveWidth(context, 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Client: $clientName',
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Transferred to: $transferredTo ($timeStr)',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  remarks.trim().isEmpty ? 'No remarks provided for this transfer.' : remarks.trim(),
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: remarks.trim().isEmpty ? Colors.grey : const Color(0xFF1E293B),
                    fontStyle: remarks.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: CRMColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Close'),
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
        final viewport = MediaQuery.sizeOf(context).width;
        final isWide = viewport >= 1050;
        final isPhone = viewport < 700;

        return RefreshIndicator(
          onRefresh: () async {
            if (mounted) setState(() => _activityPage = 1);
            context.read<TelecallerDashboardBloc>().add(TelecallerDashboardRequested());
            await Future.wait([
              _loadTransferredLeads(1),
              _loadFollowups(),
            ]);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(isPhone ? 12 : 24, isPhone ? 12 : 20, isPhone ? 12 : 24, isPhone ? 28 : 20),
            children: [
              WelcomeHeader(
                userName: RoleGuard.currentUser?.fullName.isNotEmpty == true
                    ? RoleGuard.currentUser!.fullName
                    : (data['telecallerName']?.toString().isNotEmpty == true
                        ? data['telecallerName'].toString()
                        : 'Telecaller'),
              ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 20),

              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  final cols = constraints.maxWidth < 340
                      ? 1
                      : (constraints.maxWidth < 900 ? 2 : (constraints.maxWidth / 220).floor().clamp(2, 5));
                  final cardW = (constraints.maxWidth - gap * (cols - 1)) / cols;
                  final cards = <Widget>[
                    _clickableKpi(context, 'My assigned leads', '${data['assignedLeads'] ?? 0}', Icons.assignment_outlined, '/telecaller/leads', width: cardW),
                    _clickableKpi(context, 'Uncontacted', '${data['uncontacted'] ?? 0}', Icons.mark_email_unread_outlined, '/telecaller/leads', width: cardW),
                    _clickableKpi(context, 'Callbacks', '${data['callbackCount'] ?? 0}', Icons.event_repeat, '/telecaller/callbacks', width: cardW),
                    _clickableKpi(context, "Today's callbacks", '${data['todaysCallbacks'] ?? 0}', Icons.today_outlined, '/telecaller/callbacks', width: cardW),
                    _clickableKpi(context, 'CNR / Retries', '${data['cnrCount'] ?? 0}', Icons.phone_missed_outlined, '/telecaller/cnr', width: cardW),
                    _clickableKpi(context, 'Picked up', '${data['pickedUp'] ?? 0}', Icons.call_received, '/telecaller/leads', width: cardW),
                    _clickableKpi(context, 'Handed to Sales', '${data['handedToSales'] ?? 0}', Icons.handshake_outlined, '/telecaller/leads', width: cardW),
                    _clickableKpi(context, 'Not Interested', '${data['notInterestedCount'] ?? 0}', Icons.do_not_disturb_on_rounded, '/campaign/leads?view=not_interested', accentColor: const Color(0xFFEF4444), width: cardW),
                    _clickableKpi(context, 'Workload', '${data['currentWorkload'] ?? 0}/${data['maxCapacity'] ?? 0}', Icons.speed, '/telecaller/leads', width: cardW),
                    _clickableKpi(context, 'Remaining Capacity', '${data['remainingCapacity'] ?? 0}', Icons.hourglass_bottom, '/telecaller/leads', width: cardW),
                  ];
                  return Wrap(spacing: gap, runSpacing: gap, children: cards);
                },
              ),
              const SizedBox(height: 24),

              // Next Lead Callout Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0.5,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => context.go('/telecaller/leads'),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: isPhone
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _nextLeadSummary(next),
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _callQueueButton(context),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _nextLeadSummary(next)),
                              const SizedBox(width: 12),
                              _callQueueButton(context),
                            ],
                          ),
                  ),
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
            _sectionTitle(
              icon: Icons.schedule_rounded,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFEF3C7),
              title: 'My Scheduled Follow-ups',
              badge: '${_followups.length}',
              badgeColor: const Color(0xFF475569),
              badgeBg: const Color(0xFFF1F5F9),
              trailing: MediaQuery.sizeOf(context).width < 700
                  ? IconButton(
                      tooltip: 'View all',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                      onPressed: () => context.go('/campaign/leads?view=followups'),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    )
                  : TextButton.icon(
                      onPressed: () => context.go('/campaign/leads?view=followups'),
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: const Text('View All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
            ),
            const Divider(height: 24),
            if (_loadingFollowups && _followups.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_followups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_available_rounded, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text('No scheduled follow-ups.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              )
            else ...[
              Builder(
                builder: (context) {
                  final totalPages = (_followups.isEmpty ? 1 : (_followups.length / _followupsPerPage).ceil());
                  final safeTotalPages = totalPages < 1 ? 1 : totalPages;
                  final currentPage = _followupsPage.clamp(1, safeTotalPages);
                  final startIndex = (currentPage - 1) * _followupsPerPage;
                  final pagedFollowups = _followups.skip(startIndex).take(_followupsPerPage).toList();

                  return Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pagedFollowups.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final fu = pagedFollowups[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 520;
                                final details = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fu.clientName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        if (fu.isToday)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                                            child: const Text('Today', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                          child: Text(fu.leadType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('EEE, d MMM • h:mm a').format(fu.scheduledAt),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    if (fu.mobile.isNotEmpty)
                                      Text(fu.mobile, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    if (fu.remarks.isNotEmpty)
                                      Text(
                                        fu.remarks,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                );
                                final actions = Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (fu.mobile.isNotEmpty) ...[
                                      _compactIconButton(
                                        icon: Icons.phone_forwarded,
                                        color: const Color(0xFF059669),
                                        tooltip: 'Call client',
                                        onPressed: () async {
                                          final uri = Uri.parse('tel:${fu.mobile}');
                                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                                        },
                                      ),
                                      _compactIconButton(
                                        icon: Icons.chat_outlined,
                                        color: const Color(0xFF25D366),
                                        tooltip: 'WhatsApp',
                                        onPressed: () async {
                                          final clean = fu.mobile.replaceAll(RegExp(r'\D'), '');
                                          final uri = Uri.parse('https://wa.me/$clean');
                                          if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                                        },
                                      ),
                                    ],
                                    _compactIconButton(
                                      icon: Icons.arrow_forward_ios_rounded,
                                      color: Colors.grey,
                                      tooltip: 'Open in Follow-ups tab',
                                      onPressed: () => context.go('/campaign/leads?view=followups'),
                                    ),
                                  ],
                                );
                                if (narrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      details,
                                      Align(alignment: Alignment.centerRight, child: actions),
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.access_time_rounded, color: Color(0xFFD97706), size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(child: details),
                                    actions,
                                  ],
                                );
                              },
                            ),
                          );
                        },
                      ),
                      if (_followups.length > _followupsPerPage) ...[
                        const SizedBox(height: 12),
                        _pageControls(
                          label: 'Showing ${startIndex + 1}–${min(startIndex + _followupsPerPage, _followups.length)} of ${_followups.length} follow-ups',
                          page: currentPage,
                          totalPages: safeTotalPages,
                          onPrevious: currentPage > 1 ? () => setState(() => _followupsPage = currentPage - 1) : null,
                          onNext: currentPage < safeTotalPages ? () => setState(() => _followupsPage = currentPage + 1) : null,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- WIDGET 2: RECENT LEADS TRANSFERRED TO SALES TABLE WITH PAGINATION ---
  Widget _buildTransferredLeadsCard(BuildContext context) {
    final safeTransferredTotalPages = _transferredTotalPages < 1 ? 1 : _transferredTotalPages;
    final currentTransferredPage = _transferredPage.clamp(1, safeTransferredTotalPages);

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              icon: Icons.handshake_outlined,
              iconColor: const Color(0xFF059669),
              iconBg: const Color(0xFFECFDF5),
              title: 'Recent Leads Transferred to Sales',
              badge: '$_transferredTotal',
              badgeColor: const Color(0xFF059669),
              badgeBg: const Color(0xFFECFDF5),
              trailing: IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 18),
                tooltip: 'Refresh transferred leads',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                onPressed: () => _loadTransferredLeads(currentTransferredPage),
              ),
            ),
            const Divider(height: 24),
            if (_loadingTransferred && _transferredLeads.isEmpty)
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
            else if (MediaQuery.sizeOf(context).width < 700) ...[
              ..._transferredLeads.asMap().entries.map((entry) {
                final index = (currentTransferredPage - 1) * 10 + entry.key + 1;
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('#$index', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                clientName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(phone.isEmpty ? 'No phone' : phone, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(leadType, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB))),
                            Text('· $transferredTo', style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(timeStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _showTransferRemarkDialog(context, clientName, remarks, transferredTo, timeStr),
                            child: const Text('View remarks'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              _pageControls(
                label: 'Showing ${_transferredTotal == 0 ? 0 : (currentTransferredPage - 1) * 10 + 1}–${min(currentTransferredPage * 10, _transferredTotal)} of $_transferredTotal',
                page: currentTransferredPage,
                totalPages: safeTransferredTotalPages,
                onPrevious: currentTransferredPage > 1 ? () => _loadTransferredLeads(currentTransferredPage - 1) : null,
                onNext: currentTransferredPage < safeTransferredTotalPages ? () => _loadTransferredLeads(currentTransferredPage + 1) : null,
              ),
            ] else ...[
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
                    final index = (currentTransferredPage - 1) * 10 + entry.key + 1;
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
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              side: BorderSide(
                                color: remarks.trim().isEmpty ? Colors.grey.shade300 : const Color(0xFF3B82F6).withValues(alpha: 0.5),
                              ),
                              backgroundColor: remarks.trim().isEmpty ? const Color(0xFFF8FAFC) : const Color(0xFFEFF6FF),
                              foregroundColor: remarks.trim().isEmpty ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                            ),
                            icon: Icon(
                              Icons.visibility_outlined,
                              size: 14,
                              color: remarks.trim().isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF2563EB),
                            ),
                            label: const Text(
                              'View',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                            ),
                            onPressed: () => _showTransferRemarkDialog(context, clientName, remarks, transferredTo, timeStr),
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
                    'Showing ${_transferredTotal == 0 ? 0 : (currentTransferredPage - 1) * 10 + 1}–${min(currentTransferredPage * 10, _transferredTotal)} of $_transferredTotal transferred leads',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: currentTransferredPage > 1 ? () => _loadTransferredLeads(currentTransferredPage - 1) : null,
                        icon: const Icon(Icons.chevron_left, size: 16),
                        label: const Text('Previous', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text('Page $currentTransferredPage of $safeTransferredTotalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: currentTransferredPage < safeTransferredTotalPages ? () => _loadTransferredLeads(currentTransferredPage + 1) : null,
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
                const Expanded(
                  child: Text(
                    'Personal Notes & Tasks',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
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
            else ...[
              Builder(
                builder: (context) {
                  final totalPages = (_personalNotes.isEmpty ? 1 : (_personalNotes.length / _notesPerPage).ceil());
                  final safeTotalPages = totalPages < 1 ? 1 : totalPages;
                  final currentPage = _notesPage.clamp(1, safeTotalPages);
                  final startIndex = (currentPage - 1) * _notesPerPage;
                  final pagedNotes = _personalNotes.skip(startIndex).take(_notesPerPage).toList();

                  return Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pagedNotes.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final note = pagedNotes[i];
                          final id = (note['id'] ?? '').toString();
                          final isDone = note['isDone'] == true;

                          DateTime? dt;
                          if (note['createdAt'] != null) {
                            dt = DateTime.tryParse(note['createdAt'].toString());
                          }
                          if (dt == null && note['id'] != null) {
                            final ms = int.tryParse(note['id'].toString());
                            if (ms != null && ms > 1000000000000) {
                              dt = DateTime.fromMillisecondsSinceEpoch(ms);
                            }
                          }
                          String timeSubtitle = '';
                          if (dt != null) {
                            timeSubtitle = DateFormat('EEE, d MMM • h:mm a').format(dt.toLocal());
                          }

                          return InkWell(
                            onTap: () => _toggleNoteDone(id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Exact left-side checkbox
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: isDone,
                                      activeColor: const Color(0xFF8B5CF6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      onChanged: (_) => _toggleNoteDone(id),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
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
                                        if (timeSubtitle.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            timeSubtitle,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              color: isDone ? Colors.grey.shade400 : const Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close_rounded, size: 16, color: Colors.grey.shade400),
                                    onPressed: () => _deleteNote(id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (_personalNotes.length > _notesPerPage) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${startIndex + 1}–${min(startIndex + _notesPerPage, _personalNotes.length)} of ${_personalNotes.length} notes',
                              style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                            ),
                            Row(
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: const Size(0, 28),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: currentPage > 1 ? () => setState(() => _notesPage = currentPage - 1) : null,
                                  child: const Icon(Icons.chevron_left, size: 16),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('$currentPage / $safeTotalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: const Size(0, 28),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: currentPage < safeTotalPages ? () => setState(() => _notesPage = currentPage + 1) : null,
                                  child: const Icon(Icons.chevron_right, size: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
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
                const Expanded(
                  child: Text(
                    'Recent Activity & Call Log',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ),
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
            else ...[
              Builder(
                builder: (context) {
                  final totalItems = recentActivities.length;
                  final totalPages = (totalItems <= 0 ? 1 : (totalItems / _activityPerPage).ceil());
                  final safeTotalPages = totalPages < 1 ? 1 : totalPages;
                  final currentPage = _activityPage.clamp(1, safeTotalPages);
                  final startIndex = (currentPage - 1) * _activityPerPage;
                  final pagedActivities = recentActivities.skip(startIndex).take(_activityPerPage).toList();

                  return Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pagedActivities.length,
                        separatorBuilder: (context, index) => const Divider(height: 16),
                        itemBuilder: (context, i) {
                          final act = Map<String, dynamic>.from(pagedActivities[i] as Map);
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
                                  if (phone.isNotEmpty)
                                    Flexible(
                                      child: Text(
                                        phone,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
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
                      if (totalItems > _activityPerPage) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Showing ${startIndex + 1}–${min(startIndex + _activityPerPage, totalItems)} of $totalItems calls',
                              style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                            ),
                            Row(
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: const Size(0, 28),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: currentPage > 1 ? () => setState(() => _activityPage = currentPage - 1) : null,
                                  child: const Icon(Icons.chevron_left, size: 16),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text('$currentPage / $safeTotalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                ),
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    minimumSize: const Size(0, 28),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  onPressed: currentPage < safeTotalPages ? () => setState(() => _activityPage = currentPage + 1) : null,
                                  child: const Icon(Icons.chevron_right, size: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
          child: Text(badge, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: badgeColor)),
        ),
        ?trailing,
      ],
    );
  }

  Widget _compactIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      onPressed: onPressed,
    );
  }

  Widget _nextLeadSummary(Map<String, dynamic>? next) {
    return Row(
      children: [
        const CircleAvatar(
          backgroundColor: Color(0xFFE0E7FF),
          child: Icon(Icons.phone_forwarded_rounded, color: Color(0xFF4F46E5), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Next waiting lead', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                next == null
                    ? 'No actionable lead. Go ACTIVE to receive waiting-queue work.'
                    : _leadDisplayName(next),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _callQueueButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => context.go('/telecaller/leads'),
      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
      label: const Text('Call Queue'),
      style: ElevatedButton.styleFrom(
        backgroundColor: CRMColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _pageControls({
    required String label,
    required int page,
    required int totalPages,
    required VoidCallback? onPrevious,
    required VoidCallback? onNext,
  }) {
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$page / $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        IconButton(
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Align(alignment: Alignment.centerRight, child: buttons),
      ],
    );
  }

  Widget _clickableKpi(BuildContext context, String title, String value, IconData icon, String route, {Color? accentColor, double width = 220}) {
    return SizedBox(
      width: width,
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

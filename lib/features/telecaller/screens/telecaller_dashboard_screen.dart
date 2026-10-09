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
import '../../integration/models/integration_lead_model.dart';
import '../bloc/telecaller_dashboard_bloc.dart';
import '../data/telecaller_repository.dart';
import '../widgets/telecaller_kpi_dialogs.dart';
import 'telecaller_callbacks_screen.dart' show queueLeadType;
import 'package:propkart/core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/mobile/mobile.dart';

class TelecallerDashboardScreen extends StatelessWidget {
  final TelecallerDashboardBloc? bloc;
  const TelecallerDashboardScreen({super.key, this.bloc});

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<TelecallerDashboardBloc>.value(
        value: bloc!,
        child: const _TelecallerDashboardView(),
      );
    }
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

  // Active callbacks preview state
  List<dynamic> _callbacks = [];

  // Active CNR leads preview state
  List<dynamic> _cnrLeads = [];

  // Recent activity pagination state
  int _activityPage = 1;
  static const int _activityPerPage = 10;

  StreamSubscription<Map<String, dynamic>>? _leadEventsSub;

  // Authoritative KPI state
  String _kpiDateFilter = 'Today';
  String? _customStartDate;
  String? _customEndDate;
  String _kpiLeadType = 'Both';
  Map<String, dynamic> _kpiSummary = {};
  bool _loadingKpis = false;

  @override
  void initState() {
    super.initState();
    _loadPersonalNotes();
    _loadTransferredLeads();
    _loadFollowups();
    _loadCallbacks();
    _loadCnr();
    _loadKpiSummary();
    if (IntegrationService().leads.isEmpty) {
      IntegrationService().fetchServerLeads(silent: true);
    }
    IntegrationService().addListener(_onIntegrationChanged);
    _leadEventsSub = IntegrationService.leadEvents.stream.listen((event) {
      if (!mounted) return;
      final type = event['type']?.toString();
      if (type == 'PEER_TRANSFER' || type == 'TRANSFER_COMPLETED' || type == 'OUTCOME_RECORDED' || type == 'FOLLOWUP_UPDATED' || type == 'STATUS_UPDATED') {
        _loadFollowups(forceRefresh: true);
        _loadCallbacks();
        _loadCnr();
        _loadTransferredLeads(_transferredPage);
        _loadKpiSummary();
      }
    });
  }

  Future<void> _loadKpiSummary() async {
    if (!mounted) return;
    setState(() => _loadingKpis = true);
    try {
      final res = await _repository.getKpiSummary(
        dateFilter: _kpiDateFilter,
        startDate: _customStartDate,
        endDate: _customEndDate,
        leadType: _kpiLeadType,
      );
      if (mounted) {
        setState(() {
          _kpiSummary = res;
          _loadingKpis = false;
        });
      }
    } catch (e, stack) {
      debugPrint('[TelecallerDashboard] _loadKpiSummary error: $e\n$stack');
      if (!mounted) return;
      setState(() => _loadingKpis = false);
    }
  }

  void _selectDateFilter(String filter) {
    if (_kpiDateFilter == filter && _customStartDate == null) return;
    setState(() {
      _kpiDateFilter = filter;
      _customStartDate = null;
      _customEndDate = null;
    });
    _loadKpiSummary();
  }

  void _selectLeadType(String leadType) {
    if (_kpiLeadType == leadType) return;
    setState(() {
      _kpiLeadType = leadType;
    });
    _loadKpiSummary();
  }

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(
              start: DateTime.tryParse(_customStartDate!) ?? now.subtract(const Duration(days: 7)),
              end: DateTime.tryParse(_customEndDate!) ?? now,
            )
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );

    if (!mounted) return;

    if (picked != null) {
      if (picked.start.isAfter(picked.end)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Start Date must be less than or equal to End Date.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      final startStr = DateFormat('yyyy-MM-dd').format(picked.start);
      final endStr = DateFormat('yyyy-MM-dd').format(picked.end);

      setState(() {
        _kpiDateFilter = 'Custom Range';
        _customStartDate = startStr;
        _customEndDate = endStr;
      });
      _loadKpiSummary();
    }
  }

  String _computeKpiDateRangeDisplay() {
    if (_kpiSummary['filters'] is Map &&
        _kpiSummary['filters']['dateRangeDisplay'] != null &&
        _kpiSummary['filters']['dateRangeDisplay'].toString().trim().isNotEmpty) {
      return _kpiSummary['filters']['dateRangeDisplay'].toString().trim();
    }
    final now = DateTime.now();
    final formatter = DateFormat('dd MMM yyyy');
    final filter = _kpiDateFilter.trim().toLowerCase();
    if (filter == 'today') {
      return 'Today: ${formatter.format(now)}';
    } else if (filter == 'weekly') {
      final start = now.subtract(const Duration(days: 7));
      return '${formatter.format(start)} – ${formatter.format(now)}';
    } else if (filter == 'monthly' || filter == 'this month') {
      final start = now.subtract(const Duration(days: 30));
      return '${formatter.format(start)} – ${formatter.format(now)}';
    } else if (filter == 'yearly' || filter == 'this year') {
      final start = now.subtract(const Duration(days: 365));
      return '${formatter.format(start)} – ${formatter.format(now)}';
    } else if (_customStartDate != null && _customEndDate != null) {
      final s = DateTime.tryParse(_customStartDate!);
      final e = DateTime.tryParse(_customEndDate!);
      if (s != null && e != null) {
        return '${formatter.format(s)} – ${formatter.format(e)}';
      }
      return '$_customStartDate ~ $_customEndDate';
    }
    return '';
  }

  int get _followupsKpiCount {
    if (_followups.isEmpty) {
      final s = _kpiSummary['follow_ups'];
      if (s is int) return s;
      if (s != null) return int.tryParse(s.toString()) ?? 0;
      return 0;
    }

    final filtered = _followups.where((f) {
      // 1. Lead Type Filter
      if (_kpiLeadType == 'Listing') {
        final lt = f.leadType.toLowerCase();
        if (!lt.contains('listing') && !lt.contains('property')) return false;
      } else if (_kpiLeadType == 'Requirement') {
        final lt = f.leadType.toLowerCase();
        if (!lt.contains('requirement')) return false;
      }

      // 2. Date Filter
      final filter = _kpiDateFilter.trim().toLowerCase();
      final now = DateTime.now();
      final local = f.scheduledAt.toLocal();

      if (filter == 'today') {
        return local.year == now.year && local.month == now.month && local.day == now.day;
      } else if (filter == 'weekly') {
        final startOf7Days = DateTime(now.year, now.month, now.day - 6);
        final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        return !local.isBefore(startOf7Days) && !local.isAfter(endOfToday);
      } else if (filter == 'monthly' || filter == 'this month') {
        return local.year == now.year && local.month == now.month;
      } else if (filter == 'yearly' || filter == 'this year') {
        return local.year == now.year;
      } else if (filter == 'custom' || filter == 'custom range') {
        if (_customStartDate != null && _customEndDate != null) {
          final s = DateTime.tryParse(_customStartDate!);
          final e = DateTime.tryParse('${_customEndDate!} 23:59:59');
          if (s != null && e != null) {
            return !local.isBefore(s) && !local.isAfter(e);
          }
        }
      }
      return true;
    }).toList();

    return filtered.length;
  }

  int get _callbacksKpiCount {
    if (_callbacks.isEmpty) {
      final s = _kpiSummary['callbacks'];
      if (s is int) return s;
      if (s != null) return int.tryParse(s.toString()) ?? 0;
      return 0;
    }

    final valid = _callbacks.where((raw) {
      if (raw is! Map) return false;
      final lead = raw['lead'];
      final cs = ((lead is Map ? lead['campaign_status'] : null) ?? raw['campaign_status'] ?? '').toString().trim();
      if (cs == 'Property Listed' || cs == 'Listed' || cs == 'Archived') return false;
      final leadId = (raw['lead_id'] ?? raw['id'] ?? '').toString();
      final localLead = IntegrationService().getLeadById(leadId);
      if (localLead != null && (localLead.campaignStatus == 'Property Listed' || localLead.campaignStatus == 'Listed' || localLead.campaignStatus == 'Archived')) {
        return false;
      }
      return true;
    }).toList();

    final filtered = valid.where((raw) {
      final isListing = queueLeadType(raw) == 'Property Listing';
      if (_kpiLeadType == 'Listing') return isListing;
      if (_kpiLeadType == 'Requirement') return !isListing;
      return true;
    }).toList();

    return filtered.length;
  }

  int get _cnrKpiCount {
    if (_cnrLeads.isEmpty) {
      final s = _kpiSummary['cnr'];
      if (s is int) return s;
      if (s != null) return int.tryParse(s.toString()) ?? 0;
      return 0;
    }

    final filtered = _cnrLeads.where((raw) {
      final isListing = queueLeadType(raw) == 'Property Listing';
      if (_kpiLeadType == 'Listing') return isListing;
      if (_kpiLeadType == 'Requirement') return !isListing;
      return true;
    }).toList();

    return filtered.length;
  }

  int get _notInterestedKpiCount {
    final leads = IntegrationService().leads;
    if (leads.isEmpty) {
      final s = _kpiSummary['not_interested'];
      if (s is int) return s;
      if (s != null) return int.tryParse(s.toString()) ?? 0;
      return 0;
    }

    final valid = leads.where((l) {
      final cs = l.campaignStatus.trim().toLowerCase();
      final isNI = cs == 'not interested' || cs == 'not_interested' || cs == 'disqualified';
      if (!isNI) return false;
      final isArchived = cs == 'archived' ||
          cs == 'property listed' ||
          cs == 'listed' ||
          l.importStatus.trim().toLowerCase() == 'archived';
      return !isArchived;
    }).toList();

    final filtered = valid.where((l) {
      final isListing = l.leadType.toLowerCase().contains('listing') || l.leadType.toLowerCase().contains('property');
      if (_kpiLeadType == 'Listing') return isListing;
      if (_kpiLeadType == 'Requirement') return !isListing;
      return true;
    }).toList();

    return filtered.length;
  }

  static bool _isLeadArchived(IntegrationLeadModel l) {
    if (l.archivedAt != null) return true;
    if (l.rawJson['archived_at'] != null && l.rawJson['archived_at'].toString().trim().isNotEmpty) return true;
    final s = l.campaignStatus.trim().toLowerCase();
    if (s == 'archived' || s == 'property listed' || s == 'listed') return true;
    if (l.importStatus.trim().toLowerCase() == 'archived') return true;
    return false;
  }

  static bool _isOpenUntouchedLead(IntegrationLeadModel l) {
    if (_isLeadArchived(l)) return false;
    final cs = l.campaignStatus.trim().toLowerCase();
    if (cs == 'not interested' || cs == 'not_interested' || cs == 'disqualified') return false;
    if (cs == 'assigned' || l.importStatus.trim().toLowerCase() == 'imported') return false;
    if (l.assignedTo != null && l.assignedTo!.isNotEmpty && l.assignedTo != 'Unassigned') return false;
    if (cs == 'cnr' || (l.allocationStatus ?? '').toUpperCase() == 'CNR') return false;
    if (cs == 'callback' || cs == 'call back' || (l.allocationStatus ?? '').toUpperCase() == 'CALLBACK') return false;
    if (l.callbackScheduledAt != null && (l.callbackStatus?.toLowerCase() == 'pending')) return false;
    if (cs == 'follow up' || cs == 'follow-up' || (l.allocationStatus ?? '').toUpperCase() == 'FOLLOWUP') return false;
    if (l.followupScheduledAt != null) return false;
    if (cs == 'interested' || cs == 'picked up') return false;
    if (l.isInteracted || l.interactedAt != null) return false;
    final attempts = int.tryParse(l.rawJson['call_attempt_count']?.toString() ?? '0') ?? 0;
    if (attempts > 0) return false;
    return cs == 'new' || cs.isEmpty;
  }

  int get _openLeadsKpiCount {
    final leads = IntegrationService().leads;
    if (leads.isEmpty) {
      final s = _kpiSummary['open_leads'];
      if (s is int) return s;
      if (s != null) return int.tryParse(s.toString()) ?? 0;
      return 0;
    }

    final valid = leads.where((l) => _isOpenUntouchedLead(l)).toList();
    final filtered = valid.where((l) {
      final isListing = l.leadType.toLowerCase().contains('listing') || l.leadType.toLowerCase().contains('property');
      if (_kpiLeadType == 'Listing') return isListing;
      if (_kpiLeadType == 'Requirement') return !isListing;
      return true;
    }).toList();

    return filtered.length;
  }

  int get _archivedKpiCount {
    final leads = IntegrationService().leads;
    if (leads.isEmpty) {
      final s = _kpiSummary['archived'];
      if (s is int) return s;
      if (s != null) return int.tryParse(s.toString()) ?? 0;
      return 0;
    }

    final valid = leads.where((l) => _isLeadArchived(l)).toList();
    final filtered = valid.where((l) {
      final isListing = l.leadType.toLowerCase().contains('listing') || l.leadType.toLowerCase().contains('property');
      if (_kpiLeadType == 'Listing') return isListing;
      if (_kpiLeadType == 'Requirement') return !isListing;
      return true;
    }).toList();

    return filtered.length;
  }

  void _openOpenLeadsDrilldown() {
    TelecallerKpiDialogs.showOpenLeadsDrilldown(
      context,
      dateFilter: _kpiDateFilter,
      startDate: _customStartDate,
      endDate: _customEndDate,
      leadType: _kpiLeadType,
    );
  }

  void _openArchiveDrilldown() {
    TelecallerKpiDialogs.showArchiveLeadsDrilldown(
      context,
      dateFilter: _kpiDateFilter,
      startDate: _customStartDate,
      endDate: _customEndDate,
      leadType: _kpiLeadType,
    );
  }

  void _openFollowupsDrilldown() {
    TelecallerKpiDialogs.showFollowupsDrilldown(
      context,
      followups: _followups,
      dateFilter: _kpiDateFilter,
      startDate: _customStartDate,
      endDate: _customEndDate,
      leadType: _kpiLeadType,
    );
  }

  void _openKpiDrilldown({required String category, required String title}) {
    TelecallerKpiDialogs.showKpiLeadsDrilldown(
      context,
      category: category,
      title: title,
      dateFilter: _kpiDateFilter,
      startDate: _customStartDate,
      endDate: _customEndDate,
      leadType: _kpiLeadType,
    );
  }

  void _openSalesUsersDrilldown() {
    TelecallerKpiDialogs.showSalesUsersBreakdown(
      context,
      dateFilter: _kpiDateFilter,
      startDate: _customStartDate,
      endDate: _customEndDate,
      leadType: _kpiLeadType,
    );
  }

  Widget _buildFilterPill(
    String label,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    final primaryColor = CRMColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiFilterBar(bool isDark) {
    final primaryColor = CRMColors.primary;
    final dateRangeText = _computeKpiDateRangeDisplay();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Date Filter
            Text(
              'Date:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 32,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterPill('Today', _kpiDateFilter == 'Today', () => _selectDateFilter('Today'), isDark),
                  _buildFilterPill('Weekly', _kpiDateFilter == 'Weekly', () => _selectDateFilter('Weekly'), isDark),
                  _buildFilterPill('Monthly', _kpiDateFilter == 'Monthly', () => _selectDateFilter('Monthly'), isDark),
                  _buildFilterPill('Yearly', _kpiDateFilter == 'Yearly', () => _selectDateFilter('Yearly'), isDark),
                  _buildFilterPill(
                    _kpiDateFilter.startsWith('Custom') && _customStartDate != null
                        ? '$_customStartDate ~ $_customEndDate'
                        : 'Custom Range',
                    _kpiDateFilter.startsWith('Custom'),
                    () => _pickCustomDateRange(),
                    isDark,
                  ),
                ],
              ),
            ),
            if (dateRangeText.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      dateRangeText,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                    ),
                  ],
                ),
              ),
            ],

            // Separator
            Container(
              height: 20,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),

            // 2. Lead Type Filter
            Text(
              'Lead Type:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 32,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterPill('Both', _kpiLeadType == 'Both', () => _selectLeadType('Both'), isDark),
                  _buildFilterPill('Listing', _kpiLeadType == 'Listing', () => _selectLeadType('Listing'), isDark),
                  _buildFilterPill('Requirement', _kpiLeadType == 'Requirement', () => _selectLeadType('Requirement'), isDark),
                ],
              ),
            ),

            if (_loadingKpis) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onIntegrationChanged() {
    if (!mounted) return;
    _loadFollowups();
    _loadCallbacks();
    _loadCnr();
    setState(() {});
  }

  @override
  void dispose() {
    IntegrationService().removeListener(_onIntegrationChanged);
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
  Future<void> _loadFollowups({bool forceRefresh = false}) async {
    setState(() => _loadingFollowups = true);
    try {
      final list = await IntegrationService().getUnifiedFollowups(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _followups = list;
          _followupsPage = 1;
          _loadingFollowups = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFollowups = false);
    }
  }

  // --- CALLBACKS API ---
  Future<void> _loadCallbacks() async {
    try {
      final list = await _repository.callbacks();
      if (mounted) {
        setState(() {
          _callbacks = list;
        });
      }
    } catch (_) {}
  }

  // --- CNR API ---
  Future<void> _loadCnr() async {
    try {
      final list = await _repository.cnr();
      if (mounted) {
        setState(() {
          _cnrLeads = list;
        });
      }
    } catch (_) {}
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
        final viewport = MediaQuery.sizeOf(context).width;
        final next = data['nextLead'] as Map<String, dynamic>?;
        final recentActivities = (data['recentActivity'] as List?) ?? [];

        if (MobileLayout.isMobileShell(viewport)) {
          return _buildMobileView(context, state, data, next, recentActivities);
        }

        if (state.loading && data.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final isWide = viewport >= 1050;
        final isPhone = viewport < 700;

        return RefreshIndicator(
          onRefresh: () async {
            if (mounted) setState(() => _activityPage = 1);
            context.read<TelecallerDashboardBloc>().add(TelecallerDashboardRequested());
            await Future.wait([
              _loadTransferredLeads(1),
              _loadFollowups(),
              _loadCallbacks(),
              _loadCnr(),
              _loadKpiSummary(),
              IntegrationService().fetchServerLeads(silent: true),
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

              // Date & Lead Type Filter Bar above KPIs
              _buildKpiFilterBar(Theme.of(context).brightness == Brightness.dark),
              const SizedBox(height: 16),

              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  final cols = constraints.maxWidth < 340
                      ? 1
                      : (constraints.maxWidth < 900 ? 2 : (constraints.maxWidth / 220).floor().clamp(2, 4));
                  final cardW = (constraints.maxWidth - gap * (cols - 1)) / cols;
                  final cards = <Widget>[
                    _clickableKpi(
                      context,
                      'Total Leads',
                      '${_kpiSummary['total_leads'] ?? 0}',
                      Icons.assignment_outlined,
                      onTap: () => _openKpiDrilldown(category: 'total', title: 'Total Leads'),
                      width: cardW,
                    ),
                    _clickableKpi(
                      context,
                      'New Leads Allocated',
                      '${_kpiSummary['new_allocated'] ?? 0}',
                      Icons.person_add_alt_1_outlined,
                      accentColor: const Color(0xFF059669),
                      onTap: () => _openKpiDrilldown(category: 'new_allocated', title: 'New Leads Allocated'),
                      width: cardW,
                    ),
                    _clickableKpi(
                      context,
                      'Old Leads Allocated',
                      '${_kpiSummary['old_allocated'] ?? 0}',
                      Icons.history_toggle_off_rounded,
                      accentColor: const Color(0xFF6366F1),
                      onTap: () => _openKpiDrilldown(category: 'old_allocated', title: 'Old Leads Allocated'),
                      width: cardW,
                    ),
                    _clickableKpi(
                      context,
                      'Open Leads',
                      '$_openLeadsKpiCount',
                      Icons.folder_open_rounded,
                      accentColor: const Color(0xFF3B82F6),
                      onTap: _openOpenLeadsDrilldown,
                      width: cardW,
                    ),
                    _clickableKpi(
                      context,
                      'Assigned to Sales',
                      '${_kpiSummary['assigned_to_sales'] ?? 0}',
                      Icons.handshake_outlined,
                      accentColor: const Color(0xFF2563EB),
                      onTap: () => _openKpiDrilldown(category: 'assigned_to_sales', title: 'Assigned to Sales'),
                      width: cardW,
                    ),
                    _clickableKpi(
                      context,
                      'Sales Users',
                      '${_kpiSummary['sales_users_count'] ?? 0}',
                      Icons.badge_outlined,
                      accentColor: const Color(0xFF8B5CF6),
                      onTap: () => _openSalesUsersDrilldown(),
                      width: cardW,
                    ),
                    _clickableKpi(
                      context,
                      'Not Interested',
                      '$_notInterestedKpiCount',
                      Icons.do_not_disturb_on_rounded,
                      accentColor: const Color(0xFFEF4444),
                      onTap: () => _openKpiDrilldown(category: 'not_interested', title: 'Not Interested Leads'),
                      width: cardW,
                    ),
                    _clickableKpi(
                      context,
                      'Callback',
                      '$_callbacksKpiCount',
                      Icons.event_repeat,
                      accentColor: const Color(0xFFD97706),
                      onTap: () => _openKpiDrilldown(category: 'callback', title: 'Callback Leads'),
                      width: cardW,
                    ),
                    _clickableKpi(
                      context,
                      'CNR',
                      '$_cnrKpiCount',
                      Icons.phone_missed_outlined,
                      accentColor: const Color(0xFFEA580C),
                      onTap: () => _openKpiDrilldown(category: 'cnr', title: 'CNR Leads'),
                      width: cardW,
                    ),
                    _clickableKpi(
                      context,
                      'Follow-Ups',
                      '$_followupsKpiCount',
                      Icons.schedule_rounded,
                      accentColor: const Color(0xFFD97706),
                      onTap: _openFollowupsDrilldown,
                      width: cardW,
                    ),
                    _clickableKpi(
                      context,
                      'Archive',
                      '$_archivedKpiCount',
                      Icons.archive_outlined,
                      accentColor: const Color(0xFF64748B),
                      onTap: _openArchiveDrilldown,
                      width: cardW,
                    ),
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
                          _buildFollowupsCard(context, _visibleFollowups(data)),
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
                    _buildFollowupsCard(context, _visibleFollowups(data)),
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

  Widget _buildMobileView(
    BuildContext context,
    TelecallerDashboardState state,
    Map<String, dynamic> data,
    Map<String, dynamic>? next,
    List<dynamic> recentActivities,
  ) {
    if (state.loading && data.isEmpty) {
      return const MobileScreenScaffold(
        scrollable: false,
        body: MobileLoadingState(mode: MobileLoadingMode.initial),
      );
    }

    if (state.error != null && data.isEmpty) {
      return MobileScreenScaffold(
        scrollable: false,
        body: MobileErrorState(
          title: 'Unable to load dashboard',
          message: state.error!,
          onRetry: () => context.read<TelecallerDashboardBloc>().add(TelecallerDashboardRequested()),
        ),
      );
    }

    final userName = RoleGuard.currentUser?.fullName.isNotEmpty == true
        ? RoleGuard.currentUser!.fullName
        : (data['telecallerName']?.toString().isNotEmpty == true
            ? data['telecallerName'].toString()
            : 'Telecaller');

    return MobileScreenScaffold(
      scrollable: true,
      onRefresh: () async {
        if (mounted) setState(() => _activityPage = 1);
        context.read<TelecallerDashboardBloc>().add(TelecallerDashboardRequested());
        await Future.wait([
          _loadTransferredLeads(1),
          _loadFollowups(),
          _loadCallbacks(),
          _loadCnr(),
          _loadKpiSummary(),
        ]);
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WelcomeHeader(userName: userName),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Text(
                state.error!,
                style: const TextStyle(color: CRMColors.danger, fontSize: 13),
              ),
            ),
          const SizedBox(height: 16),

          // Next Lead Callout Card
          _buildMobileNextLeadCard(context, next),
          const SizedBox(height: 16),

          // Date & Lead Type Filter Bar above KPIs
          _buildMobileFilterBar(Theme.of(context).brightness == Brightness.dark),
          const SizedBox(height: 16),

          // KPIs Grid (8 metrics)
          _buildMobileKpiGrid(context),
          const SizedBox(height: 20),

          // Followups preview
          _buildFollowupsCard(context, _visibleFollowups(data)),
          const SizedBox(height: 16),

          // Transferred Leads
          _buildTransferredLeadsCard(context),
          const SizedBox(height: 16),

          // Personal Notes
          _buildPersonalNotesCard(context),
          const SizedBox(height: 16),

          // Recent Activity
          _buildRecentActivityCard(context, recentActivities),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMobileNextLeadCard(BuildContext context, Map<String, dynamic>? next) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (next == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2430) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: CRMColors.primary.withValues(alpha: 0.12),
              child: Icon(Icons.phone_in_talk_rounded, color: CRMColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Calling Queue',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No pending leads in queue',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => context.go('/telecaller/leads'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Open Queue', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final name = (next['client_name'] ?? next['customer_name'] ?? next['name'] ?? 'Next Lead').toString();
    final phone = (next['phone'] ?? next['mobile'] ?? '').toString();
    final reqType = (next['lead_type'] ?? next['type'] ?? 'Requirement').toString();

    return InkWell(
      onTap: () => context.go('/telecaller/leads'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2430) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF059669).withValues(alpha: 0.12),
              child: const Icon(Icons.phone_forwarded_rounded, color: Color(0xFF059669), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Wrap(
                    spacing: 6,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          reqType,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => context.go('/telecaller/leads'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: const Size(0, 38),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.call_rounded, size: 16, color: Colors.white),
              label: const Text(
                'Call Lead',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFilterBar(bool isDark) {
    final primaryColor = CRMColors.primary;
    final dateRangeText = _computeKpiDateRangeDisplay();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Date Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Date:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 32,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterPill('Today', _kpiDateFilter == 'Today', () => _selectDateFilter('Today'), isDark),
                      _buildFilterPill('Weekly', _kpiDateFilter == 'Weekly', () => _selectDateFilter('Weekly'), isDark),
                      _buildFilterPill('Monthly', _kpiDateFilter == 'Monthly', () => _selectDateFilter('Monthly'), isDark),
                      _buildFilterPill('Yearly', _kpiDateFilter == 'Yearly', () => _selectDateFilter('Yearly'), isDark),
                      _buildFilterPill(
                        _kpiDateFilter.startsWith('Custom') && _customStartDate != null
                            ? '$_customStartDate ~ $_customEndDate'
                            : 'Custom Range',
                        _kpiDateFilter.startsWith('Custom'),
                        () => _pickCustomDateRange(),
                        isDark,
                      ),
                    ],
                  ),
                ),
                if (dateRangeText.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.2),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 12, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          dateRangeText,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_loadingKpis) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
                const SizedBox(width: 4),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Row 2: Lead Type Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Type:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 32,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterPill('Both', _kpiLeadType == 'Both', () => _selectLeadType('Both'), isDark),
                      _buildFilterPill('Listing', _kpiLeadType == 'Listing', () => _selectLeadType('Listing'), isDark),
                      _buildFilterPill('Requirement', _kpiLeadType == 'Requirement', () => _selectLeadType('Requirement'), isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileKpiGrid(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isVerySmall = width < 340;

    final kpis = <_MobileKpiItem>[
      _MobileKpiItem(
        label: 'Total Leads',
        value: '${_kpiSummary['total_leads'] ?? 0}',
        icon: Icons.assignment_outlined,
        onTap: () => _openKpiDrilldown(category: 'total', title: 'Total Leads'),
      ),
      _MobileKpiItem(
        label: 'New Leads Allocated',
        value: '${_kpiSummary['new_allocated'] ?? 0}',
        icon: Icons.person_add_alt_1_outlined,
        accentColor: const Color(0xFF059669),
        onTap: () => _openKpiDrilldown(category: 'new_allocated', title: 'New Leads Allocated'),
      ),
      _MobileKpiItem(
        label: 'Old Leads Allocated',
        value: '${_kpiSummary['old_allocated'] ?? 0}',
        icon: Icons.history_toggle_off_rounded,
        accentColor: const Color(0xFF6366F1),
        onTap: () => _openKpiDrilldown(category: 'old_allocated', title: 'Old Leads Allocated'),
      ),
      _MobileKpiItem(
        label: 'Open Leads',
        value: '$_openLeadsKpiCount',
        icon: Icons.folder_open_rounded,
        accentColor: const Color(0xFF3B82F6),
        onTap: _openOpenLeadsDrilldown,
      ),
      _MobileKpiItem(
        label: 'Assigned to Sales',
        value: '${_kpiSummary['assigned_to_sales'] ?? 0}',
        icon: Icons.handshake_outlined,
        accentColor: const Color(0xFF2563EB),
        onTap: () => _openKpiDrilldown(category: 'assigned_to_sales', title: 'Assigned to Sales'),
      ),
      _MobileKpiItem(
        label: 'Sales Users',
        value: '${_kpiSummary['sales_users_count'] ?? 0}',
        icon: Icons.badge_outlined,
        accentColor: const Color(0xFF8B5CF6),
        onTap: () => _openSalesUsersDrilldown(),
      ),
      _MobileKpiItem(
        label: 'Not Interested',
        value: '$_notInterestedKpiCount',
        icon: Icons.do_not_disturb_on_rounded,
        accentColor: const Color(0xFFEF4444),
        onTap: () => _openKpiDrilldown(category: 'not_interested', title: 'Not Interested Leads'),
      ),
      _MobileKpiItem(
        label: 'Callback',
        value: '$_callbacksKpiCount',
        icon: Icons.event_repeat,
        accentColor: const Color(0xFFD97706),
        onTap: () => _openKpiDrilldown(category: 'callback', title: 'Callback Leads'),
      ),
      _MobileKpiItem(
        label: 'CNR',
        value: '$_cnrKpiCount',
        icon: Icons.phone_missed_outlined,
        accentColor: const Color(0xFFEA580C),
        onTap: () => _openKpiDrilldown(category: 'cnr', title: 'CNR Leads'),
      ),
      _MobileKpiItem(
        label: 'Follow-Ups',
        value: '$_followupsKpiCount',
        icon: Icons.schedule_rounded,
        accentColor: const Color(0xFFD97706),
        onTap: _openFollowupsDrilldown,
      ),
      _MobileKpiItem(
        label: 'Archive',
        value: '$_archivedKpiCount',
        icon: Icons.archive_outlined,
        accentColor: const Color(0xFF64748B),
        onTap: _openArchiveDrilldown,
      ),
    ];

    if (isVerySmall) {
      return Column(
        children: kpis.map((kpi) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildMobileKpiCard(context, kpi),
        )).toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: kpis.asMap().entries.map((entry) {
            final idx = entry.key;
            final kpi = entry.value;
            final isLastOdd = idx == kpis.length - 1 && kpis.length.isOdd;
            return SizedBox(
              width: isLastOdd ? constraints.maxWidth : cardW,
              child: _buildMobileKpiCard(context, kpi, isFullWidth: isLastOdd),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildMobileKpiCard(BuildContext context, _MobileKpiItem item, {bool isFullWidth = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = item.accentColor ?? CRMColors.primary;

    return Semantics(
      button: true,
      label: '${item.label}: ${item.value}',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: item.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2430) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(item.icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.value,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isFullWidth)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<CampaignFollowupModel> _visibleFollowups(Map<String, dynamic> data) {
    if (_followups.isNotEmpty) return _followups;
    final raw = data['scheduledFollowups'];
    if (raw is! List || raw.isEmpty) return _followups;
    final parsed = <CampaignFollowupModel>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final map = Map<String, dynamic>.from(item);
      final status = map['status']?.toString() ?? 'Pending';
      if (status == 'Completed' || status == 'Cancelled') continue;
      parsed.add(CampaignFollowupModel(
        id: map['id']?.toString() ?? '',
        leadId: map['lead_id']?.toString() ?? '',
        leadType: map['lead_type']?.toString() ?? 'Requirement',
        clientName: (map['client_name']?.toString().trim().isNotEmpty ?? false)
            ? map['client_name'].toString().trim()
            : 'Campaign Lead',
        mobile: map['mobile']?.toString() ?? '',
        scheduledAt: DateTime.tryParse(map['scheduled_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        remarks: map['remarks']?.toString() ?? '',
        status: status,
        createdAt: DateTime.tryParse(map['scheduled_at']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
        telecallerId: map['telecaller_id']?.toString(),
      ));
    }
    parsed.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return parsed.isEmpty ? _followups : parsed;
  }

  // --- WIDGET 1: FOLLOW-UPS PREVIEW CARD ---
  Widget _buildFollowupsCard(BuildContext context, List<CampaignFollowupModel> followups) {
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
              badge: '${followups.length}',
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
            if (_loadingFollowups && followups.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (followups.isEmpty)
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
                  final totalPages = (followups.isEmpty ? 1 : (followups.length / _followupsPerPage).ceil());
                  final safeTotalPages = totalPages < 1 ? 1 : totalPages;
                  final currentPage = _followupsPage.clamp(1, safeTotalPages);
                  final startIndex = (currentPage - 1) * _followupsPerPage;
                  final pagedFollowups = followups.skip(startIndex).take(_followupsPerPage).toList();

                  return Column(
                    children: [
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: pagedFollowups.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final fu = pagedFollowups[i];
                          final isDark = Theme.of(context).brightness == Brightness.dark;
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final narrow = constraints.maxWidth < 520;
                                final details = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fu.clientName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
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
                                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    ),
                                    if (fu.mobile.isNotEmpty)
                                      Text(fu.mobile, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                                    if (fu.remarks.isNotEmpty)
                                      Text(
                                        fu.remarks,
                                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontStyle: FontStyle.italic),
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
                                      const SizedBox(width: 4),
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
                                      const SizedBox(width: 4),
                                    ],
                                    _compactIconButton(
                                      icon: Icons.arrow_forward_ios_rounded,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey,
                                      tooltip: 'Open in Follow-ups tab',
                                      onPressed: () => context.go('/campaign/leads?view=followups'),
                                    ),
                                  ],
                                );
                                if (narrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              fu.clientName,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.5,
                                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Wrap(
                                            spacing: 6,
                                            children: [
                                              if (fu.isToday)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEF3C7),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text('Today', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                                ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEFF6FF),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(fu.leadType, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFFD97706)),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat('EEE, d MMM • h:mm a').format(fu.scheduledAt),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (fu.mobile.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.phone_outlined, size: 13, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                                            const SizedBox(width: 4),
                                            Text(
                                              fu.mobile,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (fu.remarks.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.format_quote_rounded, size: 13, color: isDark ? Colors.grey.shade500 : const Color(0xFF94A3B8)),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  fu.remarks,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 8),
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
                      if (followups.length > _followupsPerPage) ...[
                        const SizedBox(height: 12),
                        _pageControls(
                          label: 'Showing ${startIndex + 1}–${min(startIndex + _followupsPerPage, followups.length)} of ${followups.length} follow-ups',
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
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Index pill + Name + Lead Type badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '#$index',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey.shade300 : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                clientName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                leadType,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Row 2: Phone + Transferred to
                        Row(
                          children: [
                            if (phone.isNotEmpty) ...[
                              Icon(Icons.phone_outlined, size: 13, color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                phone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.grey.shade400 : const Color(0xFF475569),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF059669)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                transferredTo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 3: Timestamp & View Remarks button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.access_time_rounded, size: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  timeStr,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => _showTransferRemarkDialog(context, clientName, remarks, transferredTo, timeStr),
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF059669)),
                                    SizedBox(width: 4),
                                    Text(
                                      'View remarks',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF059669),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
    Color? backgroundColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 17, color: color),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        onPressed: onPressed,
      ),
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

  Widget _clickableKpi(
    BuildContext context,
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
    Color? accentColor,
    double width = 220,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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

class _MobileKpiItem {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accentColor;

  const _MobileKpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.accentColor,
  });
}

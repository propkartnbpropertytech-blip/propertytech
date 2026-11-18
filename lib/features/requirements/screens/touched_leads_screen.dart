import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/crm_permission_denied.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../repository/requirements_repository.dart';

/// Admin-only page displaying all Touched Leads (where a salesperson has changed
/// status or interacted with the lead), split by Rent / Re-Sale and
/// Property Listing Leads / Requirement Leads.
class TouchedLeadsScreen extends StatefulWidget {
  const TouchedLeadsScreen({super.key});

  @override
  State<TouchedLeadsScreen> createState() => _TouchedLeadsScreenState();
}

class _TouchedLeadsScreenState extends State<TouchedLeadsScreen> {
  final RequirementsRepository _repo = RequirementsRepository();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;

  String _activeListingTab = 'Rent'; // 'Rent' | 'Re-Sale'
  String _activeLeadTypeTab = 'Requirement'; // 'Property Listing' | 'Requirement'
  String _selectedSalesperson = 'All';
  String _selectedStatus = 'All';
  String _selectedSource = 'All';
  int _currentPage = 1;
  static const int _perPage = 25;

  List<Map<String, dynamic>> _propertyListingLeads = [];
  List<Map<String, dynamic>> _requirementLeads = [];

  StreamSubscription<void>? _reqSub;
  StreamSubscription<void>? _dashSub;

  @override
  void initState() {
    super.initState();
    _loadData();
    _reqSub = RepositoryCoordinator().requirementsStream.listen((_) {
      _loadData(silent: true);
    });
    _dashSub = RepositoryCoordinator().dashboardStream.listen((_) {
      _loadData(silent: true);
    });
  }

  @override
  void dispose() {
    _reqSub?.cancel();
    _dashSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await _repo.getTouchedLeads();
      if (!mounted) return;
      final pl = (data['propertyListingLeads'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      final reqs = (data['requirementLeads'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      setState(() {
        _propertyListingLeads = pl;
        _requirementLeads = reqs;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> _leadsForMode(List<Map<String, dynamic>> list, String mode) {
    return list.where((l) => (l['listingMode']?.toString() ?? 'Rent') == mode).toList();
  }

  List<Map<String, dynamic>> get _activeBaseList {
    final sourceList = _activeLeadTypeTab == 'Property Listing'
        ? _propertyListingLeads
        : _requirementLeads;
    return _leadsForMode(sourceList, _activeListingTab);
  }

  List<Map<String, dynamic>> get _filteredLeads {
    final query = _searchController.text.trim().toLowerCase();
    return _activeBaseList.where((lead) {
      if (_selectedSalesperson != 'All') {
        final sp = (lead['currentSalespersonName'] ?? '').toString().trim();
        if (sp != _selectedSalesperson) return false;
      }
      if (_selectedStatus != 'All') {
        final st = (lead['currentStatus'] ?? '').toString().trim();
        if (st != _selectedStatus) return false;
      }
      if (_selectedSource != 'All') {
        final src = (lead['source'] ?? '').toString().trim();
        if (src != _selectedSource) return false;
      }
      if (query.isNotEmpty) {
        final blob = [
          lead['clientName'],
          lead['phone'],
          lead['details'],
          lead['budget'],
          lead['source'],
          lead['allocationOrigin'],
          lead['currentSalespersonName'],
          lead['currentStatus'],
          lead['previousStatus'],
          lead['lastTouchedBy'],
        ].map((v) => (v ?? '').toString().toLowerCase()).join(' ');
        if (!blob.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  List<String> get _salespersonOptions {
    final set = <String>{};
    for (final l in _activeBaseList) {
      final sp = (l['currentSalespersonName'] ?? '').toString().trim();
      if (sp.isNotEmpty) set.add(sp);
    }
    return set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  List<String> get _statusOptions {
    final set = <String>{};
    for (final l in _activeBaseList) {
      final st = (l['currentStatus'] ?? '').toString().trim();
      if (st.isNotEmpty) set.add(st);
    }
    return set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  List<String> get _sourceOptions {
    final set = <String>{};
    for (final l in _activeBaseList) {
      final src = (l['source'] ?? '').toString().trim();
      if (src.isNotEmpty) set.add(src);
    }
    return set.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedSalesperson = 'All';
      _selectedStatus = 'All';
      _selectedSource = 'All';
      _currentPage = 1;
    });
  }

  Color _statusColor(String status) {
    final low = status.trim().toLowerCase();
    if (low.contains('won') || low.contains('closed')) return const Color(0xFF059669);
    if (low.contains('interested')) return const Color(0xFF10B981);
    if (low.contains('follow')) return const Color(0xFF6366F1);
    if (low.contains('site visit')) return const Color(0xFF0284C7);
    if (low.contains('reject') || low.contains('not interested')) return const Color(0xFFEF4444);
    if (low.contains('call')) return const Color(0xFFF59E0B);
    return const Color(0xFF475569);
  }

  String _formatTimestamp(dynamic raw) {
    if (raw == null) return '—';
    final dt = DateTime.tryParse(raw.toString())?.toLocal();
    if (dt == null) return '—';
    return DateFormat("dd MMM ''yy, h:mm a").format(dt);
  }

  void _showHistoryDialog(Map<String, dynamic> lead) {
    final history = (lead['statusHistory'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    final currentStatus = (lead['currentStatus'] ?? '—').toString();
    final previousStatus = (lead['previousStatus'] ?? '—').toString();

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 580),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CRMColors.primaryOf(ctx).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.timeline_rounded, color: CRMColors.primaryOf(ctx), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (lead['clientName'] ?? 'Lead').toString(),
                            style: CRMTypography.subheadline.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${lead['phone'] ?? '—'} · ${lead['leadType']} · ${lead['listingMode']}',
                            style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(ctx)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CRMColors.backgroundOf(ctx),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CRMColors.borderOf(ctx)),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _infoMeta(ctx, 'Current Salesperson', (lead['currentSalespersonName'] ?? 'Unassigned').toString()),
                      _infoMeta(ctx, 'Source', '${lead['source']} (${lead['allocationOrigin']})'),
                      _infoMeta(ctx, 'Current Status', currentStatus),
                      _infoMeta(ctx, 'Previous Status', previousStatus),
                      _infoMeta(ctx, 'Last Touched By', '${lead['lastTouchedBy'] ?? '—'} · ${_formatTimestamp(lead['lastTouchedAt'])}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Status Change History',
                  style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Latest state: $previousStatus → $currentStatus (updated ${_formatTimestamp(lead['lastTouchedAt'])})',
                      style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(ctx)),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: history.length,
                      separatorBuilder: (_, __) => const Divider(height: 12),
                      itemBuilder: (_, idx) {
                        final h = history[idx];
                        final fromSt = (h['fromStatus'] ?? '—').toString();
                        final toSt = (h['toStatus'] ?? '—').toString();
                        final actor = (h['changedBy'] ?? 'User').toString();
                        final role = (h['changedByRole'] ?? '').toString();
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _statusColor(toSt),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 6,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(fromSt, style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(ctx))),
                                      const Icon(Icons.arrow_forward_rounded, size: 13),
                                      _statusPill(toSt),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${role.isNotEmpty ? '$actor ($role)' : actor} · ${_formatTimestamp(h['changedAt'])}',
                                    style: CRMTypography.caption.copyWith(color: CRMColors.textMutedOf(ctx), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoMeta(BuildContext ctx, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: CRMTypography.caption.copyWith(color: CRMColors.textMutedOf(ctx), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 12.5)),
      ],
    );
  }

  Widget _statusPill(String status) {
    final c = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is Authenticated ? authState.user : null;
    final isAdmin = currentUser != null &&
        (currentUser.role == 'Admin' || currentUser.role == 'Super Admin');

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: SafeArea(
          child: CRMPermissionDenied(
            onGoBack: () => context.go('/requirements'),
            title: 'Admin Access Required',
            message: 'Touched Leads tracking is accessible only to Admin.',
          ),
        ),
      );
    }

    final rentPlCount = _leadsForMode(_propertyListingLeads, 'Rent').length;
    final rentReqCount = _leadsForMode(_requirementLeads, 'Rent').length;
    final resalePlCount = _leadsForMode(_propertyListingLeads, 'Re-Sale').length;
    final resaleReqCount = _leadsForMode(_requirementLeads, 'Re-Sale').length;

    final rentTotal = rentPlCount + rentReqCount;
    final resaleTotal = resalePlCount + resaleReqCount;

    final activePlCount = _activeListingTab == 'Rent' ? rentPlCount : resalePlCount;
    final activeReqCount = _activeListingTab == 'Rent' ? rentReqCount : resaleReqCount;

    final filtered = _filteredLeads;
    final totalPages = (filtered.length / _perPage).ceil().clamp(1, 9999);
    final safePage = _currentPage.clamp(1, totalPages);
    final startIdx = (safePage - 1) * _perPage;
    final endIdx = (startIdx + _perPage).clamp(0, filtered.length);
    final pageRows = startIdx < filtered.length ? filtered.sublist(startIdx, endIdx) : <Map<String, dynamic>>[];

    final isMobile = MediaQuery.sizeOf(context).width < 760;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? CRMSpacing.m : CRMSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/requirements'),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Back to Leads'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Touched Leads',
                        style: CRMTypography.headline.copyWith(fontSize: isMobile ? 20 : 24),
                      ),
                      Text(
                        'Leads updated or interacted with by Salespersons, with live owner & status tracking',
                        style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => _loadData(),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),

            // Rent / Re-Sale Toggle
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 44,
                width: 280,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CRMColors.backgroundOf(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: CRMColors.borderOf(context).withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildModePill('Rent', rentTotal)),
                    const SizedBox(width: 4),
                    Expanded(child: _buildModePill('Re-Sale', resaleTotal)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CRMSpacing.m),

            // Property Listing Leads & Requirement Leads sub-tabs
            Row(
              children: [
                Expanded(
                  child: _buildLeadTypeCard(
                    type: 'Property Listing',
                    title: 'Property Listing Leads',
                    subtitle: _activeListingTab == 'Rent'
                        ? 'Touched owner rental listing leads'
                        : 'Touched owner resale listing leads',
                    count: activePlCount,
                    icon: Icons.home_work_outlined,
                  ),
                ),
                const SizedBox(width: CRMSpacing.m),
                Expanded(
                  child: _buildLeadTypeCard(
                    type: 'Requirement',
                    title: 'Requirement Leads',
                    subtitle: _activeListingTab == 'Rent'
                        ? 'Touched tenant requirement leads'
                        : 'Touched buyer requirement leads',
                    count: activeReqCount,
                    icon: Icons.groups_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: CRMSpacing.m),

            // Filter Card
            CRMCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() => _currentPage = 1),
                    decoration: InputDecoration(
                      hintText: 'Search by client, phone, salesperson, status, or source...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: CRMColors.backgroundOf(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        borderSide: BorderSide(color: CRMColors.borderOf(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(CRMBorderRadius.s),
                        borderSide: BorderSide(color: CRMColors.borderOf(context)),
                      ),
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  Wrap(
                    spacing: CRMSpacing.m,
                    runSpacing: CRMSpacing.s,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildFilterDropdown(
                        label: 'Current Salesperson',
                        value: _salespersonOptions.contains(_selectedSalesperson) ? _selectedSalesperson : 'All',
                        options: _salespersonOptions,
                        allLabel: 'All Salespersons',
                        onChanged: (v) => setState(() {
                          _selectedSalesperson = v ?? 'All';
                          _currentPage = 1;
                        }),
                      ),
                      _buildFilterDropdown(
                        label: 'Status',
                        value: _statusOptions.contains(_selectedStatus) ? _selectedStatus : 'All',
                        options: _statusOptions,
                        allLabel: 'All Statuses',
                        onChanged: (v) => setState(() {
                          _selectedStatus = v ?? 'All';
                          _currentPage = 1;
                        }),
                      ),
                      _buildFilterDropdown(
                        label: 'Source',
                        value: _sourceOptions.contains(_selectedSource) ? _selectedSource : 'All',
                        options: _sourceOptions,
                        allLabel: 'All Sources',
                        onChanged: (v) => setState(() {
                          _selectedSource = v ?? 'All';
                          _currentPage = 1;
                        }),
                      ),
                      CRMButton(
                        label: 'Clear Filters',
                        variant: CRMButtonVariant.outline,
                        onPressed: _clearFilters,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: CRMSpacing.m),

            // Table / Cards Body
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 64),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              CRMCard(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Failed to load Touched Leads', style: CRMTypography.subheadline),
                      const SizedBox(height: 8),
                      Text(_error!, style: CRMTypography.caption.copyWith(color: CRMColors.danger)),
                      const SizedBox(height: 12),
                      CRMButton(label: 'Retry', onPressed: () => _loadData()),
                    ],
                  ),
                ),
              )
            else if (pageRows.isEmpty)
              CRMCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  child: Column(
                    children: [
                      Icon(Icons.touch_app_outlined, size: 40, color: CRMColors.textMutedOf(context)),
                      const SizedBox(height: 12),
                      Text(
                        'No Touched $_activeLeadTypeTab Leads in $_activeListingTab',
                        style: CRMTypography.subheadline,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Leads updated or interacted with by salespersons will appear here automatically.',
                        style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              if (isMobile)
                Column(
                  children: [
                    for (final row in pageRows) ...[
                      _buildMobileRowCard(row),
                      const SizedBox(height: 10),
                    ],
                  ],
                )
              else
                CRMCard(
                  padding: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: MediaQuery.sizeOf(context).width - 310),
                      child: DataTable(
                        headingRowHeight: 46,
                        dataRowMinHeight: 58,
                        dataRowMaxHeight: 72,
                        columnSpacing: 20,
                        showCheckboxColumn: false,
                        columns: [
                          DataColumn(label: Text(_activeLeadTypeTab == 'Property Listing' ? 'Owner' : 'Client', style: const TextStyle(fontWeight: FontWeight.w700))),
                          const DataColumn(label: Text('Lead Details', style: TextStyle(fontWeight: FontWeight.w700))),
                          const DataColumn(label: Text('Source / Origin', style: TextStyle(fontWeight: FontWeight.w700))),
                          const DataColumn(label: Text('Current Salesperson', style: TextStyle(fontWeight: FontWeight.w700))),
                          const DataColumn(label: Text('Status & Tracking', style: TextStyle(fontWeight: FontWeight.w700))),
                          const DataColumn(label: Text('Last Touched', style: TextStyle(fontWeight: FontWeight.w700))),
                        ],
                        rows: pageRows.map((lead) {
                          final currentSt = (lead['currentStatus'] ?? '—').toString();
                          final prevSt = (lead['previousStatus'] ?? '').toString();
                          final changeCount = (lead['statusChangeCount'] as num?)?.toInt() ?? 0;
                          final spName = (lead['currentSalespersonName'] ?? 'Unassigned').toString();
                          return DataRow(
                            onSelectChanged: (_) => _showHistoryDialog(lead),
                            cells: [
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      (lead['clientName'] ?? 'Lead').toString(),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (lead['phone'] ?? '—').toString(),
                                      style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      (lead['details'] ?? '—').toString(),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (lead['budget'] ?? 'Budget on Request').toString(),
                                      style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      (lead['source'] ?? 'Manual').toString(),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      (lead['allocationOrigin'] ?? '').toString(),
                                      style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 13,
                                      backgroundColor: CRMColors.primaryOf(context).withValues(alpha: 0.14),
                                      child: Text(
                                        spName.isNotEmpty ? spName[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: CRMColors.primaryOf(context),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      spName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _statusPill(currentSt),
                                    const SizedBox(height: 3),
                                    Text(
                                      prevSt.isNotEmpty && prevSt.toLowerCase() != currentSt.toLowerCase()
                                          ? '$prevSt → $currentSt${changeCount > 1 ? ' ($changeCount updates)' : ''}'
                                          : (changeCount > 0 ? '$changeCount status update(s)' : 'Interacted'),
                                      style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      (lead['lastTouchedBy'] ?? 'Salesperson').toString(),
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatTimestamp(lead['lastTouchedAt']),
                                      style: TextStyle(color: CRMColors.textMutedOf(context), fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              if (totalPages > 1) ...[
                const SizedBox(height: CRMSpacing.m),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${startIdx + 1}–$endIdx of ${filtered.length} touched leads',
                      style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: safePage > 1 ? () => setState(() => _currentPage = safePage - 1) : null,
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Text('$safePage / $totalPages', style: CRMTypography.bodyMedium),
                        IconButton(
                          onPressed: safePage < totalPages ? () => setState(() => _currentPage = safePage + 1) : null,
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModePill(String mode, int count) {
    final selected = _activeListingTab == mode;
    return GestureDetector(
      onTap: () => setState(() {
        _activeListingTab = mode;
        _selectedSalesperson = 'All';
        _selectedStatus = 'All';
        _selectedSource = 'All';
        _currentPage = 1;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mode,
              style: TextStyle(
                color: selected ? Colors.white : CRMColors.textSecondaryOf(context),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.18) : CRMColors.primaryOf(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : CRMColors.primaryOf(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
  }) {
    final selected = _activeLeadTypeTab == type;
    final primary = CRMColors.primaryOf(context);
    return InkWell(
      onTap: () => setState(() {
        _activeLeadTypeTab = type;
        _selectedSalesperson = 'All';
        _selectedStatus = 'All';
        _selectedSource = 'All';
        _currentPage = 1;
      }),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? CRMColors.cardBgOf(context) : CRMColors.backgroundOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? primary : CRMColors.borderOf(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (selected ? primary : CRMColors.textMutedOf(context)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: selected ? primary : CRMColors.textSecondaryOf(context)),
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
                          title,
                          style: CRMTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: selected ? primary : CRMColors.borderOf(context),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: selected ? Colors.white : CRMColors.textOf(context),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11.5),
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

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required String allLabel,
    required ValueChanged<String?> onChanged,
  }) {
    return SizedBox(
      width: 210,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: CRMColors.backgroundOf(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.borderOf(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(CRMBorderRadius.s),
            borderSide: BorderSide(color: CRMColors.borderOf(context)),
          ),
        ),
        items: [
          DropdownMenuItem(value: 'All', child: Text(allLabel, overflow: TextOverflow.ellipsis)),
          ...options.map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMobileRowCard(Map<String, dynamic> lead) {
    final currentSt = (lead['currentStatus'] ?? '—').toString();
    final prevSt = (lead['previousStatus'] ?? '').toString();
    return InkWell(
      onTap: () => _showHistoryDialog(lead),
      borderRadius: BorderRadius.circular(12),
      child: CRMCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((lead['clientName'] ?? 'Lead').toString(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text((lead['phone'] ?? '—').toString(), style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 12)),
                    ],
                  ),
                ),
                _statusPill(currentSt),
              ],
            ),
            const SizedBox(height: 8),
            Text('${lead['details'] ?? '—'} · ${lead['budget'] ?? ''}', style: const TextStyle(fontSize: 12.5)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                Text('Salesperson: ${lead['currentSalespersonName'] ?? 'Unassigned'}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                Text('Source: ${lead['source']} (${lead['allocationOrigin']})', style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context))),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${prevSt.isNotEmpty && prevSt != currentSt ? '$prevSt → $currentSt · ' : ''}Touched by ${lead['lastTouchedBy']} (${_formatTimestamp(lead['lastTouchedAt'])})',
              style: TextStyle(fontSize: 11.5, color: CRMColors.textMutedOf(context)),
            ),
          ],
        ),
      ),
    );
  }
}

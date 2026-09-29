import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/design_system/widgets/app_status_snackbar.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../integration/services/integration_service.dart';
import '../../integration/models/integration_lead_model.dart';
import '../bloc/telecaller_list_bloc.dart';
import '../data/telecaller_repository.dart';
import 'package:propkart/core/design_system/tokens/app_breakpoints.dart';

class TelecallerCallbacksScreen extends StatelessWidget {
  final String? telecallerId;
  final String? telecallerName;
  final String? initialSearch;
  const TelecallerCallbacksScreen({super.key, this.telecallerId, this.telecallerName, this.initialSearch});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TelecallerCallbacksBloc(telecallerId: telecallerId)
        ..add(const TelecallerCallbacksRequested()),
      child: _TelecallerCallbacksView(initialSearch: initialSearch, focusName: telecallerName),
    );
  }
}

class _LeadQueueFilters extends StatefulWidget {
  final void Function({String? search, String? source, DateTimeRange? range}) onChanged;
  final String? initialSearch;
  const _LeadQueueFilters({required this.onChanged, this.initialSearch});

  @override
  State<_LeadQueueFilters> createState() => _LeadQueueFiltersState();
}

class _LeadQueueFiltersState extends State<_LeadQueueFilters> {
  late final TextEditingController _search;
  String _source = 'All';
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialSearch ?? '');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(search: _search.text.trim(), source: _source, range: _range);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 260,
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                hintText: 'Search name, phone, remarks',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _emit(),
            ),
          ),
          DropdownButton<String>(
            value: _source,
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All sources')),
              DropdownMenuItem(value: 'META', child: Text('Meta')),
              DropdownMenuItem(value: 'HOUSING', child: Text('Housing')),
            ],
            onChanged: (val) {
              if (val == null) return;
              setState(() => _source = val);
              _emit();
            },
          ),
          OutlinedButton.icon(
            icon: const Icon(Icons.date_range_rounded, size: 18),
            label: Text(
              _range == null
                  ? 'Date range'
                  : '${DateFormat('dd MMM').format(_range!.start)} – ${DateFormat('dd MMM').format(_range!.end)}',
            ),
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2024),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: _range,
              );
              if (picked != null) {
                setState(() => _range = picked);
                _emit();
              }
            },
          ),
          if (_range != null)
            TextButton(
              onPressed: () {
                setState(() => _range = null);
                _emit();
              },
              child: const Text('Clear dates'),
            ),
        ],
      ),
    );
  }
}

class _TelecallerCallbacksView extends StatefulWidget {
  final String? initialSearch;
  final String? focusName;
  const _TelecallerCallbacksView({this.initialSearch, this.focusName});

  @override
  State<_TelecallerCallbacksView> createState() => _TelecallerCallbacksViewState();
}

class _TelecallerCallbacksViewState extends State<_TelecallerCallbacksView> {
  String _selectedTab = 'all'; // 'all', 'today', 'due', 'future'
  final Map<String, TextEditingController> _tabSearchControllers = {
    'all': TextEditingController(),
    'today': TextEditingController(),
    'due': TextEditingController(),
    'future': TextEditingController(),
  };
  final Map<String, String> _tabSearchQueries = {
    'all': '',
    'today': '',
    'due': '',
    'future': '',
  };
  String _source = 'All';
  DateTimeRange? _range;
  String _section = 'Requirement';

  @override
  void initState() {
    super.initState();
    final incoming = widget.initialSearch?.trim() ?? '';
    if (incoming.isNotEmpty) {
      _tabSearchQueries['all'] = incoming;
      _tabSearchControllers['all']!.text = incoming;
    }
  }

  @override
  void dispose() {
    for (final c in _tabSearchControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _fetchFromBloc() {
    context.read<TelecallerCallbacksBloc>().add(
      TelecallerCallbacksRequested(
        source: _source,
        from: _range?.start.toIso8601String(),
        to: _range?.end.toIso8601String(),
      ),
    );
  }

  DateTime? _parseScheduledTime(dynamic raw) {
    if (raw is! Map) return null;
    final val = raw['scheduled_at']?.toString();
    if (val == null || val.isEmpty) return null;
    return DateTime.tryParse(val)?.toLocal();
  }

  bool _isTodayCallback(dynamic raw) {
    final dt = _parseScheduledTime(raw);
    if (dt == null) return false;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isDueCallback(dynamic raw) {
    if (raw is! Map) return false;
    final scheduledAtRaw = raw['scheduled_at']?.toString();
    return _isOverdue(scheduledAtRaw);
  }

  bool _isFutureCallback(dynamic raw) {
    final dt = _parseScheduledTime(raw);
    if (dt == null) return false;
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return dt.isAfter(endOfToday);
  }

  bool _matchesCallbackSearch(dynamic raw, String query) {
    return queueItemMatchesSearch(raw, query);
  }

  String _getTabDisplayName(String tab) {
    switch (tab) {
      case 'today':
        return 'Today';
      case 'due':
        return 'Due';
      case 'future':
        return 'Future';
      case 'all':
      default:
        return 'All Callbacks';
    }
  }

  Widget _buildTabChip(String label, String value, int count) {
    final isSelected = _selectedTab == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Color(0xFF2563EB);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() => _selectedTab = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TelecallerCallbacksBloc, TelecallerListState>(
      builder: (context, state) {
        if (state.loading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final allRawItems = state.items;
        final totalCount = allRawItems.length;
        final todayCount = allRawItems.where(_isTodayCallback).length;
        final dueCount = allRawItems.where(_isDueCallback).length;
        final futureCount = allRawItems.where(_isFutureCallback).length;

        List<dynamic> tabScopedItems = List.from(allRawItems);
        if (_selectedTab == 'today') {
          tabScopedItems = tabScopedItems.where(_isTodayCallback).toList();
        } else if (_selectedTab == 'due') {
          tabScopedItems = tabScopedItems.where(_isDueCallback).toList();
        } else if (_selectedTab == 'future') {
          tabScopedItems = tabScopedItems.where(_isFutureCallback).toList();
        }

        final currentSearchController = _tabSearchControllers[_selectedTab]!;
        final currentQuery = (_tabSearchQueries[_selectedTab] ?? '').trim().toLowerCase();

        List<dynamic> filteredItems = List.from(tabScopedItems);
        if (currentQuery.isNotEmpty) {
          filteredItems = filteredItems.where((raw) => _matchesCallbackSearch(raw, currentQuery)).toList();
        }
        final requirementCount = filteredItems.where((raw) => queueLeadType(raw) != 'Property Listing').length;
        final listingCount = filteredItems.where((raw) => queueLeadType(raw) == 'Property Listing').length;
        filteredItems = filteredItems.where((raw) {
          final listing = queueLeadType(raw) == 'Property Listing';
          return _section == 'Property Listing' ? listing : !listing;
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            context.read<TelecallerCallbacksBloc>().add(
              TelecallerCallbacksRequested(
                source: _source,
                from: _range?.start.toIso8601String(),
                to: _range?.end.toIso8601String(),
              ),
            );
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CRMPageHeader(
                title: 'Callbacks',
                benefit: (widget.focusName ?? '').trim().isEmpty
                    ? 'Call Back leads leave My Calling Leads. Follow up stays there.'
                    : 'Call Back leads for ${widget.focusName}. Follow ups stay on My Calling Leads.',
                trailing: (widget.focusName ?? '').trim().isEmpty
                    ? null
                    : TextButton.icon(
                        onPressed: () => context.go('/admin/lead-allocation'),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Lead Allocation'),
                      ),
              ),

              // Category Tabs: All Callbacks, Today, Due, Future
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabChip('All Callbacks', 'all', totalCount),
                    const SizedBox(width: 8),
                    _buildTabChip('Today', 'today', todayCount),
                    const SizedBox(width: 8),
                    _buildTabChip('Due', 'due', dueCount),
                    const SizedBox(width: 8),
                    _buildTabChip('Future', 'future', futureCount),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _QueueSectionSwitch(
                section: _section,
                requirementCount: requirementCount,
                listingCount: listingCount,
                onChanged: (value) => setState(() => _section = value),
              ),
              const SizedBox(height: 16),

              // Search & Filter controls
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 280,
                      child: TextField(
                        key: ValueKey('callback_search_$_selectedTab'),
                        controller: currentSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search ${_getTabDisplayName(_selectedTab)} by name, phone, remarks',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          suffixIcon: currentSearchController.text.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(Icons.close_rounded, size: 16),
                                  onPressed: () {
                                    currentSearchController.clear();
                                    setState(() {
                                      _tabSearchQueries[_selectedTab] = '';
                                    });
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setState(() {
                            _tabSearchQueries[_selectedTab] = val.trim();
                          });
                        },
                      ),
                    ),
                    DropdownButton<String>(
                      value: _source,
                      items: const [
                        DropdownMenuItem(value: 'All', child: Text('All sources')),
                        DropdownMenuItem(value: 'META', child: Text('Meta')),
                        DropdownMenuItem(value: 'HOUSING', child: Text('Housing')),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() => _source = val);
                        _fetchFromBloc();
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                      label: Text(
                        _range == null
                            ? 'Date range'
                            : '${DateFormat('dd MMM').format(_range!.start)} – ${DateFormat('dd MMM').format(_range!.end)}',
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2024),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: _range,
                        );
                        if (picked != null) {
                          setState(() => _range = picked);
                          _fetchFromBloc();
                        }
                      },
                    ),
                    if (_range != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _range = null);
                          _fetchFromBloc();
                        },
                        child: const Text('Clear dates'),
                      ),
                  ],
                ),
              ),

              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Could not load callbacks. Refresh the page.',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              if (state.error == null && filteredItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        currentQuery.isNotEmpty ? Icons.search_off_rounded : Icons.event_available_rounded,
                        size: 48,
                        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        currentQuery.isNotEmpty
                            ? 'No matching callbacks in ${_getTabDisplayName(_selectedTab)}.'
                            : 'No ${_getTabDisplayName(_selectedTab)} scheduled.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentQuery.isNotEmpty
                            ? 'Try searching with a different client name, phone number, or remark.'
                            : 'Leads marked Call Back leave My Calling Leads and appear in this ${_section == 'Property Listing' ? 'listing' : 'requirement'} table.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              for (final raw in filteredItems)
                Builder(
                  builder: (context) {
                    final item = Map<String, dynamic>.from(raw as Map);
                    final leadId = _campaignLeadId(item);
                    final cached = IntegrationService().getLeadById(leadId);
                    final phone = (cached?.getStringValue('phone_number').isNotEmpty == true
                        ? cached!.getStringValue('phone_number')
                        : (item['mobile'] ?? item['sanitized_phone'] ?? '')).toString();
                    final clientName = resolveLeadClientName(item, cachedLead: cached);
                    final scheduledAtRaw = (cached?.callbackScheduledAt != null
                        ? cached!.callbackScheduledAt!.toIso8601String()
                        : (item['scheduled_at']?.toString() ?? ''));
                    final remarks = (cached?.callbackRemarks != null && cached!.callbackRemarks!.isNotEmpty
                        ? cached.callbackRemarks!
                        : (item['remarks'] ?? '').toString());
                    final formattedTime = _formatScheduledTime(scheduledAtRaw);
                    final overdue = _isOverdue(scheduledAtRaw);

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: overdue
                              ? const Color(0xFFEF4444).withValues(alpha: 0.35)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _showLeadDetailsModal(
                            context,
                            leadId: leadId,
                            fallbackData: item,
                            fallbackLead: item['lead'] is Map ? Map<String, dynamic>.from(item['lead'] as Map) : null,
                            onOutcomeUpdated: () {
                              context.read<TelecallerCallbacksBloc>().add(TelecallerCallbacksRequested());
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              // Avatar with initials
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                child: Text(
                                  clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Main details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            clientName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (phone.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '($phone)',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                        if (overdue) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                                            ),
                                            child: const Text(
                                              'Due / Missed',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFDC2626),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time_rounded,
                                          size: 14,
                                          color: overdue ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          formattedTime,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: overdue ? const Color(0xFFDC2626) : const Color(0xFF1D4ED8),
                                          ),
                                        ),
                                        if (remarks.isNotEmpty) ...[
                                          Text('  ·  ', style: TextStyle(color: Colors.grey.shade400)),
                                          Expanded(
                                            child: Text(
                                              remarks,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Trailing buttons
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  IconButton(
                                    tooltip: 'Not Interested',
                                    icon: const Icon(Icons.thumb_down_alt_rounded, size: 20, color: Color(0xFFEF4444)),
                                    onPressed: () => _handleNotInterested(
                                      context,
                                      leadId: leadId,
                                      unifiedLeadId: item['id']?.toString(),
                                      clientName: clientName,
                                      phone: phone,
                                      onDone: () {
                                        context.read<TelecallerCallbacksBloc>().add(TelecallerLeadRemoved(leadId));
                                        if (item['id'] != null) {
                                          context.read<TelecallerCallbacksBloc>().add(TelecallerLeadRemoved(item['id'].toString()));
                                        }
                                        context.read<TelecallerCallbacksBloc>().add(TelecallerCallbacksRequested());
                                      },
                                    ),
                                  ),
                                  if (phone.isNotEmpty)
                                    IconButton(
                                      tooltip: 'Call Phone',
                                      icon: const Icon(Icons.call_rounded, size: 20, color: Color(0xFF10B981)),
                                      onPressed: () => _handleStartCall(context, leadId, phone),
                                    ),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.bolt_rounded, size: 16),
                                    label: const Text('Outcome'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B82F6),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () => _handleOutcome(context, leadId, () {
                                      context.read<TelecallerCallbacksBloc>().add(TelecallerLeadRemoved(leadId));
                                      context.read<TelecallerCallbacksBloc>().add(TelecallerCallbacksRequested());
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
}

class TelecallerCnrScreen extends StatelessWidget {
  final String? telecallerId;
  final String? telecallerName;
  final String? initialSearch;
  const TelecallerCnrScreen({super.key, this.telecallerId, this.telecallerName, this.initialSearch});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TelecallerCnrBloc(telecallerId: telecallerId)..add(const TelecallerCnrRequested()),
      child: _TelecallerCnrView(initialSearch: initialSearch, focusName: telecallerName),
    );
  }
}

class _TelecallerCnrView extends StatefulWidget {
  final String? initialSearch;
  final String? focusName;
  const _TelecallerCnrView({this.initialSearch, this.focusName});

  @override
  State<_TelecallerCnrView> createState() => _TelecallerCnrViewState();
}

class _TelecallerCnrViewState extends State<_TelecallerCnrView> {
  String _query = '';
  String _section = 'Requirement';
  String _loadedSource = 'All';
  DateTimeRange? _loadedRange;

  @override
  void initState() {
    super.initState();
    _query = widget.initialSearch?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<TelecallerCnrBloc, TelecallerListState>(
      builder: (context, state) {
        if (state.loading && state.items.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () async {
            context.read<TelecallerCnrBloc>().add(TelecallerCnrRequested());
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              CRMPageHeader(
                title: 'CNR / Retry',
                benefit: (widget.focusName ?? '').trim().isEmpty
                    ? 'CNR leads leave My Calling Leads and stay here for retry.'
                    : 'CNR leads for ${widget.focusName}. They are not on My Calling Leads.',
                trailing: (widget.focusName ?? '').trim().isEmpty
                    ? null
                    : TextButton.icon(
                        onPressed: () => context.go('/admin/lead-allocation'),
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: const Text('Lead Allocation'),
                      ),
              ),
              _LeadQueueFilters(
                initialSearch: _query,
                onChanged: ({search, source, range}) {
                  setState(() => _query = search ?? '');
                  final nextSource = source ?? 'All';
                  final sameSource = nextSource == _loadedSource;
                  final sameRange = range?.start == _loadedRange?.start && range?.end == _loadedRange?.end;
                  if (sameSource && sameRange) return;
                  _loadedSource = nextSource;
                  _loadedRange = range;
                  context.read<TelecallerCnrBloc>().add(
                    TelecallerCnrRequested(
                      source: nextSource,
                      from: range?.start.toIso8601String(),
                      to: range?.end.toIso8601String(),
                    ),
                  );
                },
              ),
              _QueueSectionSwitch(
                section: _section,
                requirementCount: state.items.where((raw) => queueItemMatchesSearch(raw, _query) && queueLeadType(raw) != 'Property Listing').length,
                listingCount: state.items.where((raw) => queueItemMatchesSearch(raw, _query) && queueLeadType(raw) == 'Property Listing').length,
                onChanged: (value) => setState(() => _section = value),
              ),
              const SizedBox(height: 12),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Could not load CNR leads. Refresh the page.',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (state.error == null && state.items.where((raw) => queueItemMatchesSearch(raw, _query) && (queueLeadType(raw) == 'Property Listing') == (_section == 'Property Listing')).isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.phone_callback_rounded, size: 48, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No CNR leads pending retry.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Leads marked as Customer Not Received will appear here for retry attempts.',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              for (final raw in state.items.where((raw) => queueItemMatchesSearch(raw, _query) && (queueLeadType(raw) == 'Property Listing') == (_section == 'Property Listing')))
                _CnrCard(
                  lead: Map<String, dynamic>.from(raw as Map),
                  onOutcomeRecorded: () {
                    context.read<TelecallerCnrBloc>().add(TelecallerCnrRequested());
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CnrCard extends StatefulWidget {
  final Map<String, dynamic> lead;
  final VoidCallback onOutcomeRecorded;
  const _CnrCard({required this.lead, required this.onOutcomeRecorded});

  @override
  State<_CnrCard> createState() => _CnrCardState();
}

class _CnrCardState extends State<_CnrCard> {
  List<dynamic> _history = const [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final history = await TelecallerRepository().callHistory(widget.lead['id'].toString());
      if (mounted) setState(() { _history = history; _loaded = true; });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leadId = _campaignLeadId(widget.lead);
    final cached = IntegrationService().getLeadById(leadId);
    final name = resolveLeadClientName(widget.lead, cachedLead: cached);
    final phone = (widget.lead['sanitized_phone'] ?? widget.lead['phone'] ?? cached?.getStringValue('phone_number') ?? '').toString();

    int historyMax = 0;
    for (final h in _history) {
      if (h is Map && h['attempt_number'] != null) {
        final num = int.tryParse(h['attempt_number'].toString()) ?? 0;
        if (num > historyMax) historyMax = num;
      }
    }
    final leadAttempts = int.tryParse((widget.lead['call_attempt_count'] ?? 0).toString()) ?? 0;
    final attempts = [leadAttempts, historyMax, _history.length, 1].reduce(math.max);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: const Color(0xFFD97706).withValues(alpha: 0.12),
          child: const Icon(Icons.phone_missed_rounded, color: Color(0xFFD97706), size: 18),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                '$name',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Attempt #$attempts',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
              ),
            ),
          ],
        ),
        subtitle: Text(
          phone.isNotEmpty ? phone : 'No phone recorded',
          style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
        ),
        trailing: Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: 'Not Interested',
              icon: const Icon(Icons.thumb_down_alt_rounded, size: 20, color: Color(0xFFEF4444)),
              onPressed: () => _handleNotInterested(
                context,
                leadId: leadId,
                unifiedLeadId: widget.lead['id']?.toString(),
                clientName: name,
                phone: phone,
                onDone: () {
                  context.read<TelecallerCnrBloc>().add(TelecallerLeadRemoved(leadId));
                  if (widget.lead['id'] != null) {
                    context.read<TelecallerCnrBloc>().add(TelecallerLeadRemoved(widget.lead['id'].toString()));
                  }
                  context.read<TelecallerCnrBloc>().add(TelecallerCnrRequested());
                  _load();
                  widget.onOutcomeRecorded();
                },
              ),
            ),
            IconButton(
              tooltip: 'View Full Lead Details',
              icon: const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF3B82F6)),
              onPressed: () {
                _showLeadDetailsModal(
                  context,
                  leadId: leadId,
                  fallbackLead: widget.lead,
                  onOutcomeUpdated: () {
                    context.read<TelecallerCnrBloc>().add(TelecallerLeadRemoved(leadId));
                    context.read<TelecallerCnrBloc>().add(TelecallerCnrRequested());
                    widget.onOutcomeRecorded();
                  },
                );
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.call_rounded, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              onPressed: () => _handleStartCall(context, leadId, phone),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.bolt_rounded, size: 15),
              label: const Text('Outcome'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _handleOutcome(context, leadId, () {
                context.read<TelecallerCnrBloc>().add(TelecallerLeadRemoved(leadId));
                context.read<TelecallerCnrBloc>().add(TelecallerCnrRequested());
                _load();
                widget.onOutcomeRecorded();
              }),
            ),
          ],
        ),
        children: [
          if (!_loaded) const LinearProgressIndicator(),
          if (_loaded && _history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('No call history recorded yet.'),
            ),
          for (final h in _history)
            ListTile(
              dense: true,
              title: Text('Attempt ${(h as Map)['attempt_number']} — ${h['outcome']}'),
              subtitle: Text('${h['remarks'] ?? 'No remarks'} · ${h['created_at'] ?? ''}'),
            ),
        ],
      ),
    );
  }
}

/// Formats raw scheduled ISO string into human readable time
String _formatScheduledTime(String? raw) {
  if (raw == null || raw.isEmpty) return 'Time not set';
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return raw;
  final now = DateTime.now();
  final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
  final tomorrow = now.add(const Duration(days: 1));
  final isTomorrow = dt.year == tomorrow.year && dt.month == tomorrow.month && dt.day == tomorrow.day;
  final yesterday = now.subtract(const Duration(days: 1));
  final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

  final timeStr = DateFormat('hh:mm a').format(dt);
  if (isToday) return 'Today, $timeStr';
  if (isTomorrow) return 'Tomorrow, $timeStr';
  if (isYesterday) return 'Yesterday, $timeStr';
  return '${DateFormat('d MMM yyyy').format(dt)}, $timeStr';
}

/// Due means the scheduled calendar day is before today.
/// A callback set for today stays on Today until the next date.
bool _isOverdue(String? raw) {
  if (raw == null || raw.isEmpty) return false;
  final dt = DateTime.tryParse(raw)?.toLocal();
  if (dt == null) return false;
  final now = DateTime.now();
  final scheduledDay = DateTime(dt.year, dt.month, dt.day);
  final today = DateTime(now.year, now.month, now.day);
  return scheduledDay.isBefore(today);
}

Future<void> _handleStartCall(BuildContext context, String leadId, String phone) async {
  try {
    await TelecallerRepository().startCall(leadId);
    if (phone.isNotEmpty) {
      final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$clean');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
    if (context.mounted) {
      AppStatusSnackBar.show(
        context,
        message: 'Call started and recorded on server.',
        isSuccess: true,
      );
    }
  } catch (e) {
    if (context.mounted) {
      AppStatusSnackBar.show(
        context,
        message: 'Could not start call: $e',
        isSuccess: false,
      );
    }
  }
}

/// Displays the full lead details modal with all questions, contact info, and actions
Future<void> _showLeadDetailsModal(
  BuildContext context, {
  required String leadId,
  Map<String, dynamic>? fallbackData,
  Map<String, dynamic>? fallbackLead,
  VoidCallback? onOutcomeUpdated,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final isMobile = MediaQuery.of(context).size.width < 600;

  // Retrieve lead from IntegrationService cache or server
  final cachedLead = IntegrationService().getLeadById(leadId);
  Map<String, dynamic> rawMap = {};
  String name = '';
  String phone = '';
  String email = '';
  String leadType = 'Requirement';
  String campaignName = '';
  String adName = '';
  String formName = '';
  String currentStatus = '';
  String remarks = '';
  String scheduledAt = '';

  if (cachedLead != null) {
    rawMap = cachedLead.rawJson;
    name = resolveLeadClientName(cachedLead.rawJson, cachedLead: cachedLead);
    phone = cachedLead.getStringValue('phone_number').isNotEmpty
        ? cachedLead.getStringValue('phone_number')
        : (cachedLead.getStringValue('phone').isNotEmpty
            ? cachedLead.getStringValue('phone')
            : (cachedLead.getStringValue('mobile')));
    email = cachedLead.getStringValue('email');
    leadType = cachedLead.leadType;
    campaignName = cachedLead.getStringValue('campaign_name');
    adName = cachedLead.getStringValue('ad_name');
    formName = cachedLead.getStringValue('form_name');
    currentStatus = cachedLead.callbackStatus ?? (cachedLead.campaignStatus.isNotEmpty ? cachedLead.campaignStatus : 'Callback');
    remarks = cachedLead.callbackRemarks ?? '';
    scheduledAt = cachedLead.callbackScheduledAt != null
        ? _formatScheduledTime(cachedLead.callbackScheduledAt!.toIso8601String())
        : '';
  } else if (fallbackLead != null) {
    final raw = fallbackLead['raw_json'];
    rawMap = raw is Map<String, dynamic> ? raw : (raw is Map ? Map<String, dynamic>.from(raw) : {});
    name = resolveLeadClientName(fallbackLead);
    phone = (fallbackLead['sanitized_phone'] ?? rawMap['phone_number'] ?? rawMap['phone'] ?? '').toString();
    email = (fallbackLead['sanitized_email'] ?? rawMap['email'] ?? '').toString();
    leadType = (fallbackLead['lead_type'] ?? 'Requirement').toString();
    campaignName = (fallbackLead['campaign_name'] ?? rawMap['campaign_name'] ?? '').toString();
    adName = (fallbackLead['ad_name'] ?? rawMap['ad_name'] ?? '').toString();
    currentStatus = (fallbackLead['campaign_status'] ?? fallbackLead['allocation_status'] ?? 'Callback').toString();
    remarks = (rawMap['_callback'] is Map ? rawMap['_callback']['remarks']?.toString() : null) ?? '';
    scheduledAt = (rawMap['_callback'] is Map && rawMap['_callback']['scheduled_at'] != null)
        ? _formatScheduledTime(rawMap['_callback']['scheduled_at'].toString())
        : '';
  } else if (fallbackData != null) {
    final leadObj = fallbackData['lead'] is Map ? Map<String, dynamic>.from(fallbackData['lead'] as Map) : null;
    final raw = leadObj?['raw_json'];
    rawMap = raw is Map<String, dynamic> ? raw : (raw is Map ? Map<String, dynamic>.from(raw) : {});
    name = resolveLeadClientName(fallbackData);
    phone = (fallbackData['mobile'] ?? leadObj?['sanitized_phone'] ?? '').toString();
    email = (rawMap['email'] ?? '').toString();
    leadType = (fallbackData['lead_type'] ?? 'Requirement').toString();
    campaignName = (leadObj?['campaign_name'] ?? rawMap['campaign_name'] ?? '').toString();
    remarks = (fallbackData['remarks'] ?? '').toString();
    scheduledAt = _formatScheduledTime(fallbackData['scheduled_at']?.toString());
    currentStatus = 'Callback';
  }

  // Extract questionnaire key-values from raw_json
  final ignoredKeys = {
    'id', 'ad_id', 'form_id', 'adset_id', 'campaign_id', 'platform',
    'is_organic', 'lead_status', 'created_time', 'phone_number', 'full_name',
    'email', 'Ad Name', 'ad_name', 'Campaign Name', 'campaign_name', 'form_name',
    'Form Name', 'adset_name', 'city', 'City', 'Name', 'name', 'Status', 'status',
    'Remarks', 'Remarks ', 'Number', '', '_transfer', '_lead_type', 'lead_type'
  };

  final questionnaire = <MapEntry<String, String>>[];
  for (final entry in rawMap.entries) {
    final k = entry.key.toString().trim();
    final v = entry.value?.toString().trim() ?? '';
    if (!ignoredKeys.contains(k) && !k.startsWith('_') && v.isNotEmpty) {
      var title = k.replaceAll('_', ' ').replaceAll('?', '').trim();
      if (title.isNotEmpty) {
        title = title.substring(0, 1).toUpperCase() + title.substring(1);
      }
      questionnaire.add(MapEntry(title, v));
    }
  }

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, anim1, anim2) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(16),
      title: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: (leadType == 'Property Listing' ? const Color(0xFF6366F1) : const Color(0xFF10B981))
                .withValues(alpha: 0.15),
            child: Icon(
              leadType == 'Property Listing' ? Icons.home_work_rounded : Icons.person_search_rounded,
              color: leadType == 'Property Listing' ? const Color(0xFF4F46E5) : const Color(0xFF059669),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : 'Lead Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 16 : 18,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Lead ID: $leadId',
                  style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (leadType == 'Property Listing' ? const Color(0xFF6366F1) : const Color(0xFF10B981))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (leadType == 'Property Listing' ? const Color(0xFF6366F1) : const Color(0xFF10B981))
                    .withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              leadType,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: leadType == 'Property Listing' ? const Color(0xFF4F46E5) : const Color(0xFF059669),
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

              // Quick Action Bar: Call & WhatsApp
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: const Text('Call Lead'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: phone.isNotEmpty ? () => _handleStartCall(context, leadId, phone) : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('WhatsApp'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: phone.isNotEmpty
                            ? () async {
                                final clean = phone.replaceAll(RegExp(r'[^\d]'), '');
                                final fullPhone = clean.length == 10 ? '91$clean' : clean;
                                final uri = Uri.parse('https://wa.me/$fullPhone');
                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Contact Information section
              _sectionHeader(context, 'Contact & Source'),
              _detailRow(context, Icons.person_outline, 'Customer Name', name),
              if (phone.isNotEmpty) _detailRow(context, Icons.phone_outlined, 'Phone Number', phone),
              if (email.isNotEmpty) _detailRow(context, Icons.email_outlined, 'Email', email),
              if (campaignName.isNotEmpty) _detailRow(context, Icons.campaign_outlined, 'Campaign', campaignName),
              if (adName.isNotEmpty) _detailRow(context, Icons.ad_units_outlined, 'Ad Name', adName),
              if (formName.isNotEmpty) _detailRow(context, Icons.description_outlined, 'Form Name', formName),
              if (currentStatus.isNotEmpty) _detailRow(context, Icons.flag_outlined, 'Current Status', currentStatus),

              if (scheduledAt.isNotEmpty || remarks.isNotEmpty) ...[
                const SizedBox(height: 14),
                _sectionHeader(context, 'Callback Details'),
                if (scheduledAt.isNotEmpty) _detailRow(context, Icons.access_time_rounded, 'Callback Timing', scheduledAt),
                if (remarks.isNotEmpty) _detailRow(context, Icons.notes_rounded, 'Callback Remarks', remarks),
              ],

              if (questionnaire.isNotEmpty) ...[
                const SizedBox(height: 14),
                _sectionHeader(context, 'Form Questionnaire & Responses'),
                for (final q in questionnaire)
                  _detailRow(context, Icons.check_circle_outline, q.key, q.value),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Close', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
        ),
        ElevatedButton.icon(
          icon: const Icon(Icons.bolt_rounded, size: 16),
          label: const Text('Update Outcome'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: () {
            Navigator.pop(ctx);
            _handleOutcome(context, leadId, () {
              onOutcomeUpdated?.call();
            });
          },
        ),
      ],
    ),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
        child: FadeTransition(opacity: curve, child: child),
      );
    },
  );
}

Widget _sectionHeader(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: CRMColors.textSecondaryOf(context),
        letterSpacing: 0.5,
      ),
    ),
  );
}

Widget _detailRow(BuildContext context, IconData icon, String label, String value) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _QueueSectionSwitch extends StatelessWidget {
  final String section;
  final int requirementCount;
  final int listingCount;
  final ValueChanged<String> onChanged;
  const _QueueSectionSwitch({
    required this.section,
    required this.requirementCount,
    required this.listingCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, int count) {
      final selected = section == label;
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF2563EB)
                : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
            ),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip('Requirement', requirementCount),
        chip('Property Listing', listingCount),
      ],
    );
  }
}

String queueLeadType(dynamic raw) {
  if (raw is! Map) return 'Requirement';
  String? explicit;
  final sources = <Map>[raw];
  if (raw['lead'] is Map) sources.add(raw['lead'] as Map);
  for (final source in sources) {
    final value = (source['lead_type'] ?? source['leadType'] ?? '').toString().trim();
    if (value == 'Property Listing' || value == 'Requirement') return value;
    if (value.isNotEmpty && explicit == null) explicit = value;
  }
  Map<String, dynamic> json = {};
  if (raw['raw_json'] is Map) {
    json = Map<String, dynamic>.from(raw['raw_json'] as Map);
  } else if (raw['lead'] is Map && (raw['lead'] as Map)['raw_json'] is Map) {
    json = Map<String, dynamic>.from((raw['lead'] as Map)['raw_json'] as Map);
  }
  return IntegrationLeadModel.resolveLeadType(explicit, json);
}

bool queueItemMatchesSearch(dynamic raw, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final qDigits = q.replaceAll(RegExp(r'\D'), '');
  final map = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  final cached = IntegrationService().getLeadById(_campaignLeadId(map));
  final parts = <String>[resolveLeadClientName(raw, cachedLead: cached).toLowerCase()];
  void add(dynamic value) {
    if (value == null) return;
    if (value is Map) {
      for (final entry in value.values) {
        add(entry);
      }
      return;
    }
    if (value is List) return;
    final text = value.toString().trim();
    if (text.isNotEmpty) parts.add(text.toLowerCase());
  }

  add(map['client_name']);
  add(map['customer_name']);
  add(map['mobile']);
  add(map['phone']);
  add(map['sanitized_phone']);
  add(map['remarks']);
  add(map['campaign_name']);
  add(map['source']);
  add(map['campaign_status']);
  add(map['raw_json']);
  add(map['lead']);
  final text = parts.join(' ');
  if (text.contains(q)) return true;
  return qDigits.length >= 4 && text.replaceAll(RegExp(r'\D'), '').contains(qDigits);
}

/// Resolves the human-readable client name from all candidate keys in raw_json,
/// the item itself, or the in-memory cache of IntegrationService.
bool isPlaceholderLeadName(String value) {
  final lower = value.trim().toLowerCase();
  if (lower.isEmpty || lower == 'lead' || lower == 'client' || lower == 'cnr client' || lower == 'callback client' || lower == 'campaign lead' || lower == 'meta lead') {
    return true;
  }
  return RegExp(r'^lead\s*\d{6,}$').hasMatch(lower);
}

String resolveLeadClientName(dynamic itemOrRaw, {IntegrationLeadModel? cachedLead}) {
  if (cachedLead != null) {
    final fromLead = cachedLead.getStringValue('full_name').trim();
    if (!isPlaceholderLeadName(fromLead)) return fromLead;
  }
  final map = itemOrRaw is Map ? Map<String, dynamic>.from(itemOrRaw) : <String, dynamic>{};
  final sources = <Map>[];
  if (map['raw_json'] is Map) sources.add(map['raw_json'] as Map);
  if (map['lead'] is Map) {
    final nested = map['lead'] as Map;
    if (nested['raw_json'] is Map) sources.add(nested['raw_json'] as Map);
    sources.add(nested);
  }
  sources.add(map);
  const keys = [
    'Full Name', 'lead_name', 'full_name', 'Client Name', 'Client / Owner Name',
    'Customer Name', 'customer_name', 'Owner Name', 'owner_name', 'buyer_name',
    'Name of client', 'client_name', 'Name', 'name',
  ];
  for (final source in sources) {
    for (final key in keys) {
      final value = (source[key] ?? '').toString().trim();
      if (!isPlaceholderLeadName(value)) return value;
    }
  }
  final phone = (map['sanitized_phone'] ?? map['phone'] ?? map['mobile'] ?? cachedLead?.getStringValue('phone_number') ?? '').toString().trim();
  if (phone.isNotEmpty) return 'Lead $phone';
  return 'Client';
}

/// Campaign lead id used by transfer and follow-up. Callback rows are
/// follow-up records, so their own `id` is not the lead.
String _campaignLeadId(Map item) {
  final nested = item['lead'];
  final nestedId = nested is Map
      ? (nested['legacy_integration_lead_id'] ?? nested['legacyIntegrationLeadId'] ?? nested['id'] ?? nested['lead_id'] ?? nested['leadId'])
      : null;
  return (item['legacy_integration_lead_id'] ??
          item['legacyIntegrationLeadId'] ??
          nestedId ??
          item['lead_id'] ??
          item['leadId'] ??
          item['campaign_lead_id'] ??
          item['campaignLeadId'] ??
          item['id'])
      ?.toString() ??
      '';
}

/// Displays the existing Not Interested dialog and marks the selected client as Not Interested
Future<void> _handleNotInterested(
  BuildContext context, {
  required String leadId,
  String? unifiedLeadId,
  required String clientName,
  required String phone,
  required VoidCallback onDone,
}) async {
  final notesController = TextEditingController();
  bool hasError = false;
  bool isSubmitting = false;

  await showDialog(
    context: context,
    barrierDismissible: !isSubmitting,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.thumb_down_alt_rounded, color: Color(0xFFEF4444), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Mark as Not Interested',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$clientName ${phone.isNotEmpty ? '($phone)' : ''}',
                      style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Reason / Notes ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CRMColors.textOf(ctx),
                      ),
                      children: const [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: notesController,
                    maxLines: 3,
                    autofocus: true,
                    enabled: !isSubmitting,
                    onChanged: (val) {
                      if (hasError && val.trim().isNotEmpty) {
                        setDialogState(() => hasError = false);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter reason why client is not interested (e.g., budget mismatch, not looking, bought elsewhere)...',
                      hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                      errorText: hasError ? 'Please enter a reason or note. This field is mandatory.' : null,
                      errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                      filled: true,
                      fillColor: CRMColors.surfaceElevatedOf(ctx),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: CRMColors.borderOf(ctx)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: hasError ? const Color(0xFFEF4444) : CRMColors.borderOf(ctx),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: Color(0xFFEF4444),
                          width: 1.5,
                        ),
                      ),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This client will be marked as Not Interested and removed from your calling queue.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.grey.shade300 : const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: CRMColors.textSecondaryOf(ctx))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final note = notesController.text.trim();
                      if (note.isEmpty) {
                        setDialogState(() => hasError = true);
                        return;
                      }

                      setDialogState(() => isSubmitting = true);
                      Navigator.pop(dialogCtx);

                      try {
                        final ok = await IntegrationService().updateLeadCampaignStatus(
                          leadId,
                          'Not interested',
                          reason: note,
                        );
                        if (!ok) {
                          throw Exception('Failed to update lead status on server');
                        }

                        IntegrationService().notifyOutcomeRecorded(
                          leadId,
                          outcome: 'NOT_INTERESTED',
                          remarks: note,
                        );

                        if (unifiedLeadId != null && unifiedLeadId.isNotEmpty && unifiedLeadId != leadId) {
                          IntegrationService().notifyOutcomeRecorded(
                            unifiedLeadId,
                            outcome: 'NOT_INTERESTED',
                            remarks: note,
                          );
                        }

                        await IntegrationService().fetchServerLeads(resetWithServer: true);

                        onDone();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$clientName marked as Not Interested.'),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to mark client as Not Interested: $e'),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Mark Not Interested', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    ),
  );
}

/// Replaces the old bottom sheet with a unified, animated center dialog
Future<void> _handleOutcome(BuildContext context, String leadId, VoidCallback onDone) async {
  final res = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (ctx, anim1, anim2) => _OutcomeDialog(
      leadId: leadId,
      onDone: onDone,
    ),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curve = CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic);
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
        child: FadeTransition(opacity: curve, child: child),
      );
    },
  );
  if (res == true) {
    onDone();
  }
}

class _OutcomeDialog extends StatefulWidget {
  final String leadId;
  final VoidCallback onDone;

  const _OutcomeDialog({
    required this.leadId,
    required this.onDone,
  });

  @override
  State<_OutcomeDialog> createState() => _OutcomeDialogState();
}

class _OutcomeDialogState extends State<_OutcomeDialog> {
  String _selectedStatus = 'Picked Up'; // 'Picked Up', 'Callback', 'CNR'
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _callbackRemarksController = TextEditingController();
  final TextEditingController _cnrRemarksController = TextEditingController();

  DateTime _selectedCallbackDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedCallbackTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  String? _selectedSalesUserId;
  List<Map<String, dynamic>> _salesUsers = [];
  bool _loadingSalesUsers = true;
  String? _remarksError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchSalesUsers();
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _callbackRemarksController.dispose();
    _cnrRemarksController.dispose();
    super.dispose();
  }

  Future<void> _fetchSalesUsers() async {
    try {
      final res = await DioClient.dio.get('/telecaller/sales-users');
      final list = List<dynamic>.from(res.data['data'] ?? []);
      if (mounted) {
        setState(() {
          _salesUsers = list.map((u) => Map<String, dynamic>.from(u as Map)).toList();
          _loadingSalesUsers = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingSalesUsers = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedStatus == 'Picked Up') {
      if (_remarksController.text.trim().isEmpty) {
        setState(() {
          _remarksError = 'Property key points (remarks) are mandatory for sales handoff.';
        });
        return;
      }
      if (_selectedSalesUserId == null || _selectedSalesUserId!.isEmpty) {
        AppStatusSnackBar.show(context, message: 'Please select a sales user to assign the lead to.', isSuccess: false);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      String outcomeCode = 'PICKED_UP';
      String? cleanRemarks;
      String? callbackAtIso;
      String? targetSalesId;

      String? targetSalesName;
      if (_selectedStatus == 'Picked Up') {
        outcomeCode = 'PICKED_UP';
        cleanRemarks = _remarksController.text.trim();
        targetSalesId = _selectedSalesUserId;
        for (final user in _salesUsers) {
          if (user['id']?.toString() == targetSalesId) {
            targetSalesName = (user['full_name'] ?? user['fullName'] ?? 'Sales User').toString();
            break;
          }
        }
      } else if (_selectedStatus == 'Callback') {
        outcomeCode = 'CALLBACK';
        final scheduledDateTime = DateTime(
          _selectedCallbackDate.year,
          _selectedCallbackDate.month,
          _selectedCallbackDate.day,
          _selectedCallbackTime.hour,
          _selectedCallbackTime.minute,
        );
        callbackAtIso = scheduledDateTime.toUtc().toIso8601String();
        cleanRemarks = _callbackRemarksController.text.trim();
      } else {
        outcomeCode = 'CNR';
        cleanRemarks = _cnrRemarksController.text.trim();
      }

      await TelecallerRepository().recordOutcome(
        widget.leadId,
        outcome: outcomeCode,
        remarks: cleanRemarks,
        salesUserId: targetSalesId,
        assignedToName: targetSalesName,
        callbackAt: callbackAtIso,
      );

      // Real-time synchronization across all pages
      IntegrationService().notifyOutcomeRecorded(
        widget.leadId,
        outcome: outcomeCode,
        remarks: cleanRemarks,
        salesUserId: targetSalesId,
        assignedToName: targetSalesName,
        callbackAt: callbackAtIso,
      );

      widget.onDone();

      if (mounted) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        Navigator.of(context).pop(true);
        if (messenger != null) {
          final successMsg = _selectedStatus == 'Picked Up'
              ? 'Lead handed off to Sales! Status updated to Assigned.'
              : (_selectedStatus == 'Callback'
                  ? 'Callback scheduled successfully.'
                  : 'Lead marked as CNR.');
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      successMsg,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0F766E),
              duration: const Duration(milliseconds: 2600),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        AppStatusSnackBar.show(
          context,
          message: 'Failed to record outcome: $e',
          isSuccess: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryActionColor = _selectedStatus == 'CNR'
        ? const Color(0xFFD97706)
        : (_selectedStatus == 'Callback'
            ? const Color(0xFF3B82F6)
            : const Color(0xFF10B981));

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryActionColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.bolt_rounded, color: primaryActionColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record Call Outcome',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  'Select status and handoff action for this lead',
                  style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: CRMBreakpoints.adaptiveWidth(context, 520),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),

              // Outcome 3-Card Selector Row
              Row(
                children: [
                  _buildOutcomeCard(
                    context,
                    title: 'Picked Up',
                    subtitle: 'Handoff to Sales',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF10B981),
                    isSelected: _selectedStatus == 'Picked Up',
                    onTap: () => setState(() {
                      _selectedStatus = 'Picked Up';
                      _remarksError = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _buildOutcomeCard(
                    context,
                    title: 'Callback',
                    subtitle: 'Schedule retry',
                    icon: Icons.event_repeat_rounded,
                    color: const Color(0xFF3B82F6),
                    isSelected: _selectedStatus == 'Callback',
                    onTap: () => setState(() {
                      _selectedStatus = 'Callback';
                      _remarksError = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  _buildOutcomeCard(
                    context,
                    title: 'CNR',
                    subtitle: 'No answer',
                    icon: Icons.phone_missed_rounded,
                    color: const Color(0xFFD97706),
                    isSelected: _selectedStatus == 'CNR',
                    onTap: () => setState(() {
                      _selectedStatus = 'CNR';
                      _remarksError = null;
                    }),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Outcome Specific Form
              if (_selectedStatus == 'Picked Up') ...[
                RichText(
                  text: TextSpan(
                    text: 'Property Key Points / Remarks ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(context)),
                    children: const [
                      TextSpan(text: '*', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _remarksController,
                  maxLines: 3,
                  enabled: !_isSubmitting,
                  onChanged: (v) {
                    if (_remarksError != null) setState(() => _remarksError = null);
                  },
                  decoration: InputDecoration(
                    errorText: _remarksError,
                    hintText: 'Enter buyer/tenant preferences, budget, property details, visit timing...',
                    hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                    filled: true,
                    fillColor: CRMColors.surfaceElevatedOf(context),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 14),

                RichText(
                  text: TextSpan(
                    text: 'Select Sales User to Assign ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(context)),
                    children: const [
                      TextSpan(text: '*', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                if (_loadingSalesUsers)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSalesUserId,
                    isExpanded: true,
                    hint: Text(
                      'Choose a sales team member...',
                      style: TextStyle(fontSize: 13, color: CRMColors.textSecondaryOf(context)),
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: CRMColors.surfaceElevatedOf(context),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _salesUsers.map((u) {
                      final name = (u['full_name'] ?? 'Sales Agent').toString();
                      final email = (u['email'] ?? '').toString();
                      return DropdownMenuItem<String>(
                        value: u['id'].toString(),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$name ($email)',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: _isSubmitting ? null : (v) => setState(() => _selectedSalesUserId = v),
                  ),
              ],

              if (_selectedStatus == 'Callback') ...[
                Text(
                  'Scheduled Date & Time',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(context)),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedCallbackDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 90)),
                          );
                          if (picked != null) setState(() => _selectedCallbackDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: CRMColors.surfaceElevatedOf(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CRMColors.borderOf(context)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event_rounded, size: 18, color: Color(0xFF3B82F6)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  DateFormat('EEE, d MMM yyyy').format(_selectedCallbackDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedCallbackTime,
                          );
                          if (picked != null) setState(() => _selectedCallbackTime = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: CRMColors.surfaceElevatedOf(context),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CRMColors.borderOf(context)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF3B82F6)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedCallbackTime.format(context),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Text(
                  'Callback Discussion Notes',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(context)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _callbackRemarksController,
                  maxLines: 3,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'Enter discussion notes, preferred callback timing, client preferences...',
                    hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                    filled: true,
                    fillColor: CRMColors.surfaceElevatedOf(context),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],

              if (_selectedStatus == 'CNR') ...[
                Text(
                  'CNR Discussion Notes (Optional)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(context)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cnrRemarksController,
                  maxLines: 3,
                  enabled: !_isSubmitting,
                  decoration: InputDecoration(
                    hintText: 'e.g. Call rang fully, no answer. Client will be retried later...',
                    hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                    filled: true,
                    fillColor: CRMColors.surfaceElevatedOf(context),
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryActionColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  _selectedStatus == 'Picked Up'
                      ? 'Assign & Transfer Lead'
                      : (_selectedStatus == 'Callback'
                          ? 'Schedule Callback'
                          : 'Confirm CNR'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }

  Widget _buildOutcomeCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: isDark ? 0.22 : 0.12)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 22),
              const SizedBox(height: 6),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? color : CRMColors.textOf(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

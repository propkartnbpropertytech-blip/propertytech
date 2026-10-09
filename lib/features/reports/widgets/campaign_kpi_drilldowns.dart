import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/theme/theme_manager.dart';
import '../models/business_insight_summary.dart';
import '../services/business_insight_service.dart';

// Helper Breadcrumb Button
Widget _buildDrilldownBreadcrumb(BuildContext context, String previousLabel, VoidCallback onBack) {
  final primaryColor = CRMColors.primary;
  return InkWell(
    onTap: onBack,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_back_rounded, size: 16, color: primaryColor),
          const SizedBox(width: 6),
          Text(
            'Back to $previousLabel',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    ),
  );
}

// Helper Responsive Drilldown Header
Widget _buildDrilldownHeader({
  required BuildContext context,
  required String title,
  required String subtitle,
  required Widget badge,
}) {
  final isDark = ThemeManager().isDarkMode;

  return LayoutBuilder(
    builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 650;
      if (isMobile) {
        final isVerySmall = constraints.maxWidth < 420;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isVerySmall) ...[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              badge,
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  badge,
                ],
              ),
            ],
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        );
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          badge,
        ],
      );
    },
  );
}

// ============================================================================
// 1. NEW / OPEN LEADS DRILLDOWN VIEW
// ============================================================================
class NewOpenLeadsDrilldownView extends StatefulWidget {
  final BusinessInsightSummary summary;
  final VoidCallback onBack;
  final DateTime? from;
  final DateTime? to;

  const NewOpenLeadsDrilldownView({
    super.key,
    required this.summary,
    required this.onBack,
    this.from,
    this.to,
  });

  @override
  State<NewOpenLeadsDrilldownView> createState() => _NewOpenLeadsDrilldownViewState();
}

class _NewOpenLeadsDrilldownViewState extends State<NewOpenLeadsDrilldownView> with TickerProviderStateMixin {
  int _selectedSourceIndex = 0; // 0: Meta, 1: Housing, 2: Webhook, 3: Manually Added
  int _selectedTypeIndex = 0; // 0: Property Listing Leads — New, 1: Requirement Leads — New

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  List<BusinessInsightLead> _leads = [];
  bool _isLoading = true;

  final List<String> _sources = ['Meta', 'Housing', 'Webhook', 'Manually Added'];

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  @override
  void didUpdateWidget(covariant NewOpenLeadsDrilldownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from || oldWidget.to != widget.to || oldWidget.summary != widget.summary) {
      _fetchLeads();
    }
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    final currentSource = _sources[_selectedSourceIndex];
    final isManual = currentSource == 'Manually Added';
    final leadType = isManual
        ? null
        : (_selectedTypeIndex == 0 ? 'Property Listing' : 'Requirement');

    try {
      final res = await BusinessInsightService.instance.fetchLeads(
        source: currentSource == 'Manually Added' ? 'manual' : currentSource,
        leadType: leadType,
        kpi: 'new_open',
        from: widget.from,
        to: widget.to,
        limit: 500,
      );
      if (mounted) {
        setState(() {
          _leads = (res['leads'] as List<dynamic>?)?.cast<BusinessInsightLead>() ?? [];
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final isManual = _selectedSourceIndex == 3;

    final metaData = widget.summary.newOpenLeads.bySource['meta'] ?? const SourcePropReqBreakdown(total: 0);
    final housingData = widget.summary.newOpenLeads.bySource['housing'] ?? const SourcePropReqBreakdown(total: 0);
    final webhookData = widget.summary.newOpenLeads.bySource['webhook'] ?? const SourcePropReqBreakdown(total: 0);
    final manualData = widget.summary.newOpenLeads.bySource['manual'] ?? const SourcePropReqBreakdown(total: 0);

    final counts = [metaData.total, housingData.total, webhookData.total, manualData.total];

    final filteredLeads = _leads.where((l) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return l.customerName.toLowerCase().contains(q) ||
          l.phone.contains(q) ||
          l.email.toLowerCase().contains(q) ||
          (l.telecallerName ?? '').toLowerCase().contains(q);
    }).toList();

    final totalPages = (filteredLeads.length / _rowsPerPage).ceil().clamp(1, 999);
    final pagedLeads = filteredLeads
        .skip((_currentPage - 1) * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDrilldownBreadcrumb(context, 'Overall Business Insights', widget.onBack),
        const SizedBox(height: CRMSpacing.m),

        // Header
        _buildDrilldownHeader(
          context: context,
          title: 'New / Open Leads',
          subtitle: 'Total New / Open Leads: ${widget.summary.newOpenLeads.total} currently untouched across all sources.',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.3)),
            ),
            child: Text(
              'Total New: ${widget.summary.newOpenLeads.total}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.l),

        // 4 Source Tabs with accurate KPI counts
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_sources.length, (idx) {
            final isSelected = _selectedSourceIndex == idx;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedSourceIndex = idx;
                  _selectedTypeIndex = 0;
                });
                _fetchLeads();
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _sources[idx],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.25) : primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${counts[idx]}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Subtabs for Meta / Housing / Webhook (Not shown for Manually Added)
        if (!isManual) ...[
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSubTabButton(
                    context,
                    label: 'Property Listing Leads — New',
                    count: _selectedSourceIndex == 0
                        ? metaData.propertyListing
                        : (_selectedSourceIndex == 1 ? housingData.propertyListing : webhookData.propertyListing),
                    isSelected: _selectedTypeIndex == 0,
                    onTap: () {
                      setState(() => _selectedTypeIndex = 0);
                      _fetchLeads();
                    },
                  ),
                  const SizedBox(width: 6),
                  _buildSubTabButton(
                    context,
                    label: 'Requirement Leads — New',
                    count: _selectedSourceIndex == 0
                        ? metaData.requirement
                        : (_selectedSourceIndex == 1 ? housingData.requirement : webhookData.requirement),
                    isSelected: _selectedTypeIndex == 1,
                    onTap: () {
                      setState(() => _selectedTypeIndex = 1);
                      _fetchLeads();
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: CRMSpacing.m),
        ],

        // Search & Table Card
        Container(
          padding: const EdgeInsets.all(CRMSpacing.m),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CRMColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: constraints.maxWidth < 500 ? double.infinity : 320,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                    }),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search new leads by name, phone...',
                      hintStyle: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CRMSpacing.m),

              // Table Content
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredLeads.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded, size: 42, color: CRMColors.textSecondaryOf(context)),
                        const SizedBox(height: 8),
                        Text(
                          'No currently new/open leads found for this source.',
                          style: TextStyle(fontSize: 13, color: CRMColors.textSecondaryOf(context)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildLeadsTable(context, pagedLeads),

              // Pagination Footer
              if (!_isLoading && filteredLeads.isNotEmpty) ...[
                const SizedBox(height: CRMSpacing.m),
                _buildPaginationFooter(context, filteredLeads.length, totalPages),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton(
    BuildContext context, {
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primaryColor = CRMColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : CRMColors.textOf(context),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadsTable(BuildContext context, List<BusinessInsightLead> leads) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 24,
        headingRowColor: WidgetStateProperty.all(CRMColors.cardBgOf(context)),
        columns: const [
          DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Lead Type', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Telecaller', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: leads.map((l) {
          final dateStr = l.createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(l.createdAt!) : 'N/A';
          return DataRow(
            cells: [
              DataCell(Text(l.customerName, style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(l.phone.isEmpty ? 'N/A' : l.phone)),
              DataCell(_buildSourceBadge(l.source)),
              DataCell(Text(l.leadType.isEmpty ? 'Requirement' : l.leadType)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('NEW', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                ),
              ),
              DataCell(Text(l.telecallerName ?? 'Unassigned')),
              DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaginationFooter(BuildContext context, int totalCount, int totalPages) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Showing ${((_currentPage - 1) * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage).clamp(1, totalCount)} of $totalCount leads',
          style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            ),
            Text('Page $_currentPage of $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 2. CNR KPI DRILLDOWN VIEW
// ============================================================================
class CnrLeadsDrilldownView extends StatefulWidget {
  final BusinessInsightSummary summary;
  final VoidCallback onBack;
  final DateTime? from;
  final DateTime? to;

  const CnrLeadsDrilldownView({
    super.key,
    required this.summary,
    required this.onBack,
    this.from,
    this.to,
  });

  @override
  State<CnrLeadsDrilldownView> createState() => _CnrLeadsDrilldownViewState();
}

class _CnrLeadsDrilldownViewState extends State<CnrLeadsDrilldownView> {
  int _selectedSourceIndex = 0; // 0: Meta, 1: Housing, 2: Webhook
  int _selectedTypeIndex = 0; // 0: Property Listing Leads, 1: Requirement Leads
  final List<String> _sources = ['Meta', 'Housing', 'Webhook'];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  List<BusinessInsightLead> _leads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  @override
  void didUpdateWidget(covariant CnrLeadsDrilldownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from || oldWidget.to != widget.to || oldWidget.summary != widget.summary) {
      _fetchLeads();
    }
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    final src = _sources[_selectedSourceIndex];
    final type = _selectedTypeIndex == 0 ? 'Property Listing' : 'Requirement';

    try {
      final res = await BusinessInsightService.instance.fetchLeads(
        source: src,
        leadType: type,
        kpi: 'cnr',
        from: widget.from,
        to: widget.to,
        limit: 500,
      );
      if (mounted) {
        setState(() {
          _leads = (res['leads'] as List<dynamic>?)?.cast<BusinessInsightLead>() ?? [];
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    final metaData = widget.summary.cnrLeads.bySource['meta'] ?? const SourcePropReqBreakdown(total: 0);
    final housingData = widget.summary.cnrLeads.bySource['housing'] ?? const SourcePropReqBreakdown(total: 0);
    final webhookData = widget.summary.cnrLeads.bySource['webhook'] ?? const SourcePropReqBreakdown(total: 0);
    final counts = [metaData.total, housingData.total, webhookData.total];

    final filteredLeads = _leads.where((l) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return l.customerName.toLowerCase().contains(q) ||
          l.phone.contains(q) ||
          (l.cnrRemark ?? '').toLowerCase().contains(q) ||
          (l.telecallerName ?? '').toLowerCase().contains(q);
    }).toList();

    final totalPages = (filteredLeads.length / _rowsPerPage).ceil().clamp(1, 999);
    final pagedLeads = filteredLeads
        .skip((_currentPage - 1) * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDrilldownBreadcrumb(context, 'Overall Business Insights', widget.onBack),
        const SizedBox(height: CRMSpacing.m),

        _buildDrilldownHeader(
          context: context,
          title: 'CNR Leads',
          subtitle: 'Total Campaign CNR Leads: ${widget.summary.cnrLeads.total} across Meta, Housing, and Webhook.',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEA580C).withValues(alpha: 0.3)),
            ),
            child: Text(
              'Total CNR: ${widget.summary.cnrLeads.total}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.l),

        // Source Tabs
        Wrap(
          spacing: 10,
          children: List.generate(_sources.length, (idx) {
            final isSelected = _selectedSourceIndex == idx;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedSourceIndex = idx;
                  _selectedTypeIndex = 0;
                });
                _fetchLeads();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _sources[idx],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.25) : primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${counts[idx]}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Subtabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypeTab(
                  context,
                  label: 'Property Listing Leads',
                  count: _selectedSourceIndex == 0
                      ? metaData.propertyListing
                      : (_selectedSourceIndex == 1 ? housingData.propertyListing : webhookData.propertyListing),
                  isSelected: _selectedTypeIndex == 0,
                  onTap: () {
                    setState(() => _selectedTypeIndex = 0);
                    _fetchLeads();
                  },
                ),
                const SizedBox(width: 6),
                _buildTypeTab(
                  context,
                  label: 'Requirement Leads',
                  count: _selectedSourceIndex == 0
                      ? metaData.requirement
                      : (_selectedSourceIndex == 1 ? housingData.requirement : webhookData.requirement),
                  isSelected: _selectedTypeIndex == 1,
                  onTap: () {
                    setState(() => _selectedTypeIndex = 1);
                    _fetchLeads();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Table
        Container(
          padding: const EdgeInsets.all(CRMSpacing.m),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CRMColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: constraints.maxWidth < 500 ? double.infinity : 320,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                    }),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search CNR leads or remarks...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CRMSpacing.m),
              if (_isLoading)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (filteredLeads.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text('No CNR leads found for this source.', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('CNR Remark', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Marked By (Telecaller)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: pagedLeads.map((l) {
                      final dateStr = l.createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(l.createdAt!) : 'N/A';
                      return DataRow(
                        cells: [
                          DataCell(Text(l.customerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(l.phone.isEmpty ? 'N/A' : l.phone)),
                          DataCell(_buildSourceBadge(l.source)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEA580C).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.cnrRemark ?? 'Marked as CNR',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFEA580C), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          DataCell(Text(l.telecallerName ?? 'System / Unassigned')),
                          DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              if (!_isLoading && filteredLeads.isNotEmpty) ...[
                const SizedBox(height: CRMSpacing.m),
                _buildPaginationRow(context, filteredLeads.length, totalPages),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeTab(BuildContext context, {required String label, required int count, required bool isSelected, required VoidCallback onTap}) {
    final primaryColor = CRMColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : CRMColors.textOf(context))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.25) : primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationRow(BuildContext context, int totalCount, int totalPages) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Showing ${((_currentPage - 1) * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage).clamp(1, totalCount)} of $totalCount leads',
          style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            ),
            Text('Page $_currentPage of $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 3. CALLBACK KPI DRILLDOWN VIEW
// ============================================================================
class CallbackLeadsDrilldownView extends StatefulWidget {
  final BusinessInsightSummary summary;
  final VoidCallback onBack;
  final DateTime? from;
  final DateTime? to;

  const CallbackLeadsDrilldownView({
    super.key,
    required this.summary,
    required this.onBack,
    this.from,
    this.to,
  });

  @override
  State<CallbackLeadsDrilldownView> createState() => _CallbackLeadsDrilldownViewState();
}

class _CallbackLeadsDrilldownViewState extends State<CallbackLeadsDrilldownView> {
  int _selectedSourceIndex = 0; // 0: Meta, 1: Housing, 2: Webhook
  int _selectedTypeIndex = 0; // 0: Property Listing, 1: Requirement
  final List<String> _sources = ['Meta', 'Housing', 'Webhook'];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  List<BusinessInsightLead> _leads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  @override
  void didUpdateWidget(covariant CallbackLeadsDrilldownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from || oldWidget.to != widget.to || oldWidget.summary != widget.summary) {
      _fetchLeads();
    }
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    final src = _sources[_selectedSourceIndex];
    final type = _selectedTypeIndex == 0 ? 'Property Listing' : 'Requirement';

    try {
      final res = await BusinessInsightService.instance.fetchLeads(
        source: src,
        leadType: type,
        kpi: 'callback',
        from: widget.from,
        to: widget.to,
        limit: 500,
      );
      if (mounted) {
        setState(() {
          _leads = (res['leads'] as List<dynamic>?)?.cast<BusinessInsightLead>() ?? [];
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    final metaData = widget.summary.callbackLeads.bySource['meta'] ?? const SourcePropReqBreakdown(total: 0);
    final housingData = widget.summary.callbackLeads.bySource['housing'] ?? const SourcePropReqBreakdown(total: 0);
    final webhookData = widget.summary.callbackLeads.bySource['webhook'] ?? const SourcePropReqBreakdown(total: 0);
    final counts = [metaData.total, housingData.total, webhookData.total];

    final filteredLeads = _leads.where((l) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return l.customerName.toLowerCase().contains(q) ||
          l.phone.contains(q) ||
          (l.callbackRemark ?? '').toLowerCase().contains(q) ||
          (l.telecallerName ?? '').toLowerCase().contains(q);
    }).toList();

    final totalPages = (filteredLeads.length / _rowsPerPage).ceil().clamp(1, 999);
    final pagedLeads = filteredLeads
        .skip((_currentPage - 1) * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDrilldownBreadcrumb(context, 'Overall Business Insights', widget.onBack),
        const SizedBox(height: CRMSpacing.m),

        _buildDrilldownHeader(
          context: context,
          title: 'Callback Leads',
          subtitle: 'Total Campaign Callback Leads: ${widget.summary.callbackLeads.total} scheduled callbacks.',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
            ),
            child: Text(
              'Total Callback: ${widget.summary.callbackLeads.total}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.l),

        // Sources
        Wrap(
          spacing: 10,
          children: List.generate(_sources.length, (idx) {
            final isSelected = _selectedSourceIndex == idx;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedSourceIndex = idx;
                  _selectedTypeIndex = 0;
                });
                _fetchLeads();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _sources[idx],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.25) : primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${counts[idx]}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Subtabs
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCallbackTypeTab(
                  context,
                  label: 'Property Listing Leads',
                  count: _selectedSourceIndex == 0
                      ? metaData.propertyListing
                      : (_selectedSourceIndex == 1 ? housingData.propertyListing : webhookData.propertyListing),
                  isSelected: _selectedTypeIndex == 0,
                  onTap: () {
                    setState(() => _selectedTypeIndex = 0);
                    _fetchLeads();
                  },
                ),
                const SizedBox(width: 6),
                _buildCallbackTypeTab(
                  context,
                  label: 'Requirement Leads',
                  count: _selectedSourceIndex == 0
                      ? metaData.requirement
                      : (_selectedSourceIndex == 1 ? housingData.requirement : webhookData.requirement),
                  isSelected: _selectedTypeIndex == 1,
                  onTap: () {
                    setState(() => _selectedTypeIndex = 1);
                    _fetchLeads();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Table
        Container(
          padding: const EdgeInsets.all(CRMSpacing.m),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CRMColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: constraints.maxWidth < 500 ? double.infinity : 320,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                    }),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search Callback leads or remarks...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CRMSpacing.m),
              if (_isLoading)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (filteredLeads.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text('No Callback leads found for this source.', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Callback Remark', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Created By (Telecaller)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: pagedLeads.map((l) {
                      final dateStr = l.createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(l.createdAt!) : 'N/A';
                      return DataRow(
                        cells: [
                          DataCell(Text(l.customerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(l.phone.isEmpty ? 'N/A' : l.phone)),
                          DataCell(_buildSourceBadge(l.source)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD97706).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.callbackRemark ?? 'Callback requested',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          DataCell(Text(l.telecallerName ?? 'System / Unassigned')),
                          DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              if (!_isLoading && filteredLeads.isNotEmpty) ...[
                const SizedBox(height: CRMSpacing.m),
                _buildCallbackPaginationRow(context, filteredLeads.length, totalPages),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCallbackTypeTab(BuildContext context, {required String label, required int count, required bool isSelected, required VoidCallback onTap}) {
    final primaryColor = CRMColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(fontSize: 12.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : CRMColors.textOf(context))),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: isSelected ? Colors.white.withValues(alpha: 0.25) : primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallbackPaginationRow(BuildContext context, int totalCount, int totalPages) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Showing ${((_currentPage - 1) * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage).clamp(1, totalCount)} of $totalCount leads',
          style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            ),
            Text('Page $_currentPage of $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// 4. CAMPAIGN FOLLOW-UPS DRILLDOWN VIEW
// ============================================================================
class CampaignFollowupsDrilldownView extends StatefulWidget {
  final BusinessInsightSummary summary;
  final VoidCallback onBack;
  final DateTime? from;
  final DateTime? to;

  const CampaignFollowupsDrilldownView({
    super.key,
    required this.summary,
    required this.onBack,
    this.from,
    this.to,
  });

  @override
  State<CampaignFollowupsDrilldownView> createState() => _CampaignFollowupsDrilldownViewState();
}

class _CampaignFollowupsDrilldownViewState extends State<CampaignFollowupsDrilldownView> {
  String _selectedSourceFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  List<BusinessInsightLead> _leads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  @override
  void didUpdateWidget(covariant CampaignFollowupsDrilldownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from || oldWidget.to != widget.to || oldWidget.summary != widget.summary) {
      _fetchLeads();
    }
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    try {
      final res = await BusinessInsightService.instance.fetchLeads(
        source: _selectedSourceFilter == 'All' ? null : _selectedSourceFilter,
        kpi: 'campaign_followup',
        from: widget.from,
        to: widget.to,
        limit: 500,
      );
      if (mounted) {
        setState(() {
          _leads = (res['leads'] as List<dynamic>?)?.cast<BusinessInsightLead>() ?? [];
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = CRMColors.primary;

    final filteredLeads = _leads.where((l) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return l.customerName.toLowerCase().contains(q) ||
          l.phone.contains(q) ||
          (l.followupRemark ?? '').toLowerCase().contains(q) ||
          (l.telecallerName ?? '').toLowerCase().contains(q);
    }).toList();

    final totalPages = (filteredLeads.length / _rowsPerPage).ceil().clamp(1, 999);
    final pagedLeads = filteredLeads
        .skip((_currentPage - 1) * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDrilldownBreadcrumb(context, 'Overall Business Insights', widget.onBack),
        const SizedBox(height: CRMSpacing.m),

        _buildDrilldownHeader(
          context: context,
          title: 'Campaign Follow-Ups',
          subtitle: 'Displaying all ${widget.summary.followupLeads.total} active Campaign Follow-Ups with responsible telecaller and remarks.',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
            ),
            child: Text(
              'Total Follow-Ups: ${widget.summary.followupLeads.total}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.l),

        // Source Filters
        Wrap(
          spacing: 8,
          children: ['All', 'Meta', 'Housing', 'Webhook'].map((src) {
            final isSelected = _selectedSourceFilter == src;
            final count = src == 'All'
                ? widget.summary.followupLeads.total
                : (widget.summary.followupLeads.bySource[src.toLowerCase()] ?? 0);
            return FilterChip(
              label: Text('$src ($count)'),
              selected: isSelected,
              onSelected: (val) {
                setState(() => _selectedSourceFilter = src);
                _fetchLeads();
              },
              selectedColor: primaryColor.withValues(alpha: 0.15),
              checkmarkColor: primaryColor,
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primaryColor : CRMColors.textOf(context),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Table
        Container(
          padding: const EdgeInsets.all(CRMSpacing.m),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CRMColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: constraints.maxWidth < 500 ? double.infinity : 320,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                    }),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search follow-ups or telecaller...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CRMSpacing.m),
              if (_isLoading)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (filteredLeads.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text('No Campaign Follow-Ups found.', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Follow-Up Remark', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Responsible Telecaller', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Scheduled / Created Date', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: pagedLeads.map((l) {
                      final dateStr = l.createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(l.createdAt!) : 'N/A';
                      return DataRow(
                        cells: [
                          DataCell(Text(l.customerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(l.phone.isEmpty ? 'N/A' : l.phone)),
                          DataCell(_buildSourceBadge(l.source)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.followupRemark ?? 'Scheduled follow-up',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          DataCell(Text(l.telecallerName ?? 'System / Unassigned')),
                          DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              if (!_isLoading && filteredLeads.isNotEmpty) ...[
                const SizedBox(height: CRMSpacing.m),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Showing ${((_currentPage - 1) * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage).clamp(1, filteredLeads.length)} of ${filteredLeads.length} leads',
                      style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                        ),
                        Text('Page $_currentPage of $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 5. NOT INTERESTED KPI DRILLDOWN VIEW
// ============================================================================
class NotInterestedLeadsDrilldownView extends StatefulWidget {
  final BusinessInsightSummary summary;
  final VoidCallback onBack;
  final DateTime? from;
  final DateTime? to;

  const NotInterestedLeadsDrilldownView({
    super.key,
    required this.summary,
    required this.onBack,
    this.from,
    this.to,
  });

  @override
  State<NotInterestedLeadsDrilldownView> createState() => _NotInterestedLeadsDrilldownViewState();
}

class _NotInterestedLeadsDrilldownViewState extends State<NotInterestedLeadsDrilldownView> {
  int _selectedSourceIndex = 0; // 0: Meta, 1: Housing, 2: Webhook, 3: Manually Added
  final List<String> _sources = ['Meta', 'Housing', 'Webhook', 'Manually Added'];

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  List<BusinessInsightLead> _leads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  @override
  void didUpdateWidget(covariant NotInterestedLeadsDrilldownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from || oldWidget.to != widget.to || oldWidget.summary != widget.summary) {
      _fetchLeads();
    }
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    final src = _sources[_selectedSourceIndex];
    try {
      final res = await BusinessInsightService.instance.fetchLeads(
        source: src,
        kpi: 'not_interested',
        from: widget.from,
        to: widget.to,
        limit: 500,
      );
      if (mounted) {
        setState(() {
          _leads = (res['leads'] as List<dynamic>?)?.cast<BusinessInsightLead>() ?? [];
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    final metaCount = widget.summary.notInterestedLeads.bySource['meta'] ?? widget.summary.sources['meta']?.notInterested ?? 0;
    final housingCount = widget.summary.notInterestedLeads.bySource['housing'] ?? widget.summary.sources['housing']?.notInterested ?? 0;
    final webhookCount = widget.summary.notInterestedLeads.bySource['webhook'] ?? widget.summary.sources['webhook']?.notInterested ?? 0;
    final manualCount = widget.summary.notInterestedLeads.bySource['manual'] ?? widget.summary.sources['manual']?.notInterested ?? 0;
    final counts = [metaCount, housingCount, webhookCount, manualCount];

    final filteredLeads = _leads.where((l) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return l.customerName.toLowerCase().contains(q) ||
          l.phone.contains(q) ||
          (l.notInterestedRemark ?? '').toLowerCase().contains(q) ||
          (l.telecallerName ?? '').toLowerCase().contains(q);
    }).toList();

    final totalPages = (filteredLeads.length / _rowsPerPage).ceil().clamp(1, 999);
    final pagedLeads = filteredLeads
        .skip((_currentPage - 1) * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDrilldownBreadcrumb(context, 'Overall Business Insights', widget.onBack),
        const SizedBox(height: CRMSpacing.m),

        _buildDrilldownHeader(
          context: context,
          title: 'Not Interested Leads',
          subtitle: 'Total Not Interested Leads: ${widget.summary.notInterestedLeads.total} across Meta, Housing, Webhook, and Manually Added.',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
            ),
            child: Text(
              'Total: ${widget.summary.notInterestedLeads.total}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.l),

        // Sources
        Wrap(
          spacing: 10,
          children: List.generate(_sources.length, (idx) {
            final isSelected = _selectedSourceIndex == idx;
            return InkWell(
              onTap: () {
                setState(() => _selectedSourceIndex = idx);
                _fetchLeads();
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _sources[idx],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.25) : primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${counts[idx]}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Table
        Container(
          padding: const EdgeInsets.all(CRMSpacing.m),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CRMColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  width: constraints.maxWidth < 500 ? double.infinity : 320,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {
                      _searchQuery = val.trim();
                      _currentPage = 1;
                    }),
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search Not Interested leads...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: CRMSpacing.m),
              if (_isLoading)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (filteredLeads.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text('No Not Interested leads found for this source.', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    columns: const [
                      DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Lead Type', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Not Interested Remark', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Marked By (Telecaller)', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: pagedLeads.map((l) {
                      final dateStr = l.createdAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(l.createdAt!) : 'N/A';
                      return DataRow(
                        cells: [
                          DataCell(Text(l.customerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(Text(l.phone.isEmpty ? 'N/A' : l.phone)),
                          DataCell(_buildSourceBadge(l.source)),
                          DataCell(Text(l.leadType.isEmpty ? 'Requirement' : l.leadType)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.notInterestedRemark ?? 'Not Interested',
                                style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                          DataCell(Text(l.telecallerName ?? 'System / Unassigned')),
                          DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              if (!_isLoading && filteredLeads.isNotEmpty) ...[
                const SizedBox(height: CRMSpacing.m),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Showing ${((_currentPage - 1) * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage).clamp(1, filteredLeads.length)} of ${filteredLeads.length} leads',
                      style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                        ),
                        Text('Page $_currentPage of $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 6. LEADS ASSIGNED TO SALES (PICKED UP) DRILLDOWN VIEW
// ============================================================================
class SalesAssignedPickedUpDrilldownView extends StatefulWidget {
  final BusinessInsightSummary summary;
  final VoidCallback onBack;
  final DateTime? from;
  final DateTime? to;

  const SalesAssignedPickedUpDrilldownView({
    super.key,
    required this.summary,
    required this.onBack,
    this.from,
    this.to,
  });

  @override
  State<SalesAssignedPickedUpDrilldownView> createState() => _SalesAssignedPickedUpDrilldownViewState();
}

class _SalesAssignedPickedUpDrilldownViewState extends State<SalesAssignedPickedUpDrilldownView> {
  String? _selectedTelecallerId; // null = all
  String _selectedTelecallerName = 'All Telecallers';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  List<BusinessInsightLead> _leads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  @override
  void didUpdateWidget(covariant SalesAssignedPickedUpDrilldownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from || oldWidget.to != widget.to || oldWidget.summary != widget.summary) {
      _fetchLeads();
    }
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    try {
      final res = await BusinessInsightService.instance.fetchLeads(
        kpi: 'assigned_to_sales',
        telecallerId: _selectedTelecallerId,
        from: widget.from,
        to: widget.to,
        limit: 500,
      );
      if (mounted) {
        setState(() {
          _leads = (res['leads'] as List<dynamic>?)?.cast<BusinessInsightLead>() ?? [];
          _isLoading = false;
          _currentPage = 1;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final telecallerList = widget.summary.assignedToSalesPickedUp.byTelecaller;

    final filteredLeads = _leads.where((l) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return l.customerName.toLowerCase().contains(q) ||
          l.phone.contains(q) ||
          (l.salespersonName ?? '').toLowerCase().contains(q) ||
          (l.telecallerName ?? '').toLowerCase().contains(q) ||
          (l.assignmentRemark ?? '').toLowerCase().contains(q) ||
          (l.salespersonWorkflowStatus ?? '').toLowerCase().contains(q);
    }).toList();

    final totalPages = (filteredLeads.length / _rowsPerPage).ceil().clamp(1, 999);
    final pagedLeads = filteredLeads
        .skip((_currentPage - 1) * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDrilldownBreadcrumb(context, 'Overall Business Insights', widget.onBack),
        const SizedBox(height: CRMSpacing.m),

        _buildDrilldownHeader(
          context: context,
          title: 'Leads Assigned to Sales (Picked Up)',
          subtitle: 'Total ${widget.summary.assignedToSalesPickedUp.total} leads transferred or picked up by Salespersons.',
          badge: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
            ),
            child: Text(
              'Total Assigned: ${widget.summary.assignedToSalesPickedUp.total}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.l),

        // Telecaller-wise Count Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 700;
            final cardWidth = isSmall ? constraints.maxWidth : (constraints.maxWidth - 24) / 3;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                // "All Telecallers" Card
                _buildTelecallerCard(
                  context,
                  width: cardWidth,
                  name: 'All Telecallers',
                  count: widget.summary.assignedToSalesPickedUp.total,
                  isSelected: _selectedTelecallerId == null,
                  onTap: () {
                    setState(() {
                      _selectedTelecallerId = null;
                      _selectedTelecallerName = 'All Telecallers';
                    });
                    _fetchLeads();
                  },
                ),
                ...telecallerList.map((tc) {
                  final isSelected = _selectedTelecallerId == tc.telecallerId;
                  return _buildTelecallerCard(
                    context,
                    width: cardWidth,
                    name: tc.telecallerName,
                    count: tc.count,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedTelecallerId = tc.telecallerId;
                        _selectedTelecallerName = tc.telecallerName;
                      });
                      _fetchLeads();
                    },
                  );
                }),
              ],
            );
          },
        ),
        const SizedBox(height: CRMSpacing.l),

        // Assigned Leads Table Card
        Container(
          padding: const EdgeInsets.all(CRMSpacing.m),
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CRMColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 650;
                  final titleWidget = Text(
                    '$_selectedTelecallerName — Assigned Leads (${filteredLeads.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  );
                  final searchWidget = SizedBox(
                    width: isCompact ? double.infinity : 300,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {
                        _searchQuery = val.trim();
                        _currentPage = 1;
                      }),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search leads, salesperson, remark...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  );

                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        titleWidget,
                        const SizedBox(height: 10),
                        searchWidget,
                      ],
                    );
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      titleWidget,
                      searchWidget,
                    ],
                  );
                },
              ),
              const SizedBox(height: CRMSpacing.m),
              if (_isLoading)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (filteredLeads.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text('No assigned leads found for this telecaller.', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
                  ),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 22,
                    columns: const [
                      DataColumn(label: Text('Customer Name', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Source / Type', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Telecaller', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Assigned Salesperson', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Salesperson Workflow Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Assignment Remark', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Assigned Date', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: pagedLeads.map((l) {
                      final assignedDateStr = l.salesAssignedAt != null
                          ? DateFormat('dd MMM yyyy, hh:mm a').format(l.salesAssignedAt!)
                          : (l.createdAt != null ? DateFormat('dd MMM yyyy').format(l.createdAt!) : 'N/A');
                      return DataRow(
                        cells: [
                          DataCell(Text(l.customerName, style: const TextStyle(fontWeight: FontWeight.w600))),
                          DataCell(
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(l.phone.isEmpty ? 'No Phone' : l.phone, style: const TextStyle(fontSize: 12.5)),
                                if (l.email.isNotEmpty)
                                  Text(l.email, style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context))),
                              ],
                            ),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildSourceBadge(l.source),
                                const SizedBox(width: 6),
                                Text(l.leadType.isEmpty ? 'Req' : (l.leadType == 'Property Listing' ? 'Listing' : 'Req'), style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                          DataCell(Text(l.telecallerName ?? 'Direct / Unassigned', style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.salespersonName ?? 'Salesperson',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getStatusBadgeColor(l.salespersonWorkflowStatus ?? 'Assigned').withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                l.salespersonWorkflowStatus ?? 'Assigned',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusBadgeColor(l.salespersonWorkflowStatus ?? 'Assigned'),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Text(
                                l.assignmentRemark ?? 'Transferred to sales',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(Text(assignedDateStr, style: const TextStyle(fontSize: 12))),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              if (!_isLoading && filteredLeads.isNotEmpty) ...[
                const SizedBox(height: CRMSpacing.m),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Text(
                      'Showing ${((_currentPage - 1) * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage).clamp(1, filteredLeads.length)} of ${filteredLeads.length} leads',
                      style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                        ),
                        Text('Page $_currentPage of $totalPages', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTelecallerCard(
    BuildContext context, {
    required double width,
    required String name,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = const Color(0xFF7C3AED);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        padding: const EdgeInsets.all(CRMSpacing.m),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.12)
              : CRMColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : CRMColors.borderOf(context),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    name.isEmpty ? 'T' : name[0].toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Assigned Leads',
                      style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isSelected ? primaryColor : CRMColors.textOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusBadgeColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('won')) return const Color(0xFF16A34A);
    if (s.contains('lost') || s.contains('reject')) return const Color(0xFFDC2626);
    if (s.contains('visit')) return const Color(0xFF9333EA);
    if (s.contains('follow')) return const Color(0xFF0D9488);
    if (s.contains('negotiation')) return const Color(0xFFF59E0B);
    if (s.contains('interested')) return const Color(0xFF16A34A);
    return const Color(0xFF2563EB);
  }
}

// -------------------------------------------------------------
// SOURCE BADGE HELPER
// -------------------------------------------------------------
Widget _buildSourceBadge(String source) {
  Color bg = const Color(0xFFF1F5F9);
  Color fg = const Color(0xFF475569);
  final s = source.toUpperCase();
  if (s.contains('META') || s.contains('FACEBOOK')) {
    bg = const Color(0xFF1877F2).withValues(alpha: 0.12);
    fg = const Color(0xFF1877F2);
  } else if (s.contains('HOUSING')) {
    bg = const Color(0xFF0D9488).withValues(alpha: 0.12);
    fg = const Color(0xFF0D9488);
  } else if (s.contains('WEBHOOK')) {
    bg = const Color(0xFF7C3AED).withValues(alpha: 0.12);
    fg = const Color(0xFF7C3AED);
  } else {
    bg = const Color(0xFFEA580C).withValues(alpha: 0.12);
    fg = const Color(0xFFEA580C);
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      source,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
    ),
  );
}

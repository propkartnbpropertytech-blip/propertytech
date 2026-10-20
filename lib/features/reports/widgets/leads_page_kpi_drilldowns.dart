import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/theme/theme_manager.dart';
import '../models/business_insight_summary.dart';
import '../models/report_kpi_type.dart';
import '../models/report_data.dart';
import '../services/business_insight_service.dart';

Widget _buildLeadsBreadcrumb(BuildContext context, String previousLabel, VoidCallback onBack) {
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

class LeadsPageKpiDrilldownView extends StatefulWidget {
  final ReportKpiType kpiType;
  final ReportOverallData reportData;
  final VoidCallback onBack;
  final DateTime? from;
  final DateTime? to;

  const LeadsPageKpiDrilldownView({
    super.key,
    required this.kpiType,
    required this.reportData,
    required this.onBack,
    this.from,
    this.to,
  });

  @override
  State<LeadsPageKpiDrilldownView> createState() => _LeadsPageKpiDrilldownViewState();
}

class _LeadsPageKpiDrilldownViewState extends State<LeadsPageKpiDrilldownView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  // Sub-filter for Call Attempted ('picked_up' vs 'open')
  String _callAttemptedSubTab = 'picked_up';

  // Sub-filter for Follow-Ups & Re-Follow-Ups ('all', 'today', 'due', 'future')
  String _followupSubTab = 'all';

  List<BusinessInsightLead> _leads = [];
  bool _isLoading = true;
  int _totalServerCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  @override
  void didUpdateWidget(covariant LeadsPageKpiDrilldownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kpiType != widget.kpiType ||
        oldWidget.from != widget.from ||
        oldWidget.to != widget.to) {
      _fetchLeads();
    }
  }

  String _resolveBackendKpi() {
    switch (widget.kpiType) {
      case ReportKpiType.leadsNotStarted:
        return 'not_started';
      case ReportKpiType.leadsCallAttempted:
        if (_callAttemptedSubTab == 'picked_up') return 'call_attempted_picked_up';
        if (_callAttemptedSubTab == 'open') return 'call_attempted_open';
        return 'call_attempted';
      case ReportKpiType.leadsFollowups:
        return 'follow_ups';
      case ReportKpiType.leadsReFollowups:
        return 're_follow_ups';
      case ReportKpiType.leadsInterested:
        return 'interested';
      case ReportKpiType.leadsSiteVisitScheduled:
        return 'site_visit_scheduled';
      case ReportKpiType.leadsSiteVisitDone:
      case ReportKpiType.siteVisitsDone:
        return 'site_visit_done';
      case ReportKpiType.leadsNegotiation:
        return 'negotiation';
      case ReportKpiType.leadsRejected:
        return 'rejected';
      default:
        return 'all';
    }
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    final kpiKey = _resolveBackendKpi();
    try {
      final res = await BusinessInsightService.instance.fetchLeads(
        kpi: kpiKey,
        from: widget.from,
        to: widget.to,
        limit: 1000,
      );
      if (mounted) {
        setState(() {
          _leads = (res['leads'] as List<dynamic>?)?.cast<BusinessInsightLead>() ?? [];
          _totalServerCount = (res['total'] as int?) ?? _leads.length;
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

    // Title & Description according to KPI
    String title = widget.kpiType.displayName;
    String subtitle = 'Leads page pipeline metrics.';
    Color headerColor = widget.kpiType.defaultColor;

    switch (widget.kpiType) {
      case ReportKpiType.leadsNotStarted:
        subtitle = 'Showing all leads whose current status is Not Started.';
        break;
      case ReportKpiType.leadsCallAttempted:
        subtitle = 'Combined count of Picked Up + Open leads from the Leads page.';
        break;
      case ReportKpiType.leadsFollowups:
        subtitle = 'Categorized Follow-Ups synchronized with the Leads Follow-Ups tab.';
        break;
      case ReportKpiType.leadsReFollowups:
        subtitle = 'Categorized Re-Follow-Ups synchronized with the Leads page.';
        break;
      case ReportKpiType.leadsInterested:
        subtitle = 'Leads currently expressing active interest.';
        break;
      case ReportKpiType.leadsSiteVisitScheduled:
        subtitle = 'Leads with upcoming or active site visits scheduled.';
        break;
      case ReportKpiType.leadsSiteVisitDone:
      case ReportKpiType.siteVisitsDone:
        subtitle = 'Leads where site visits have been completed.';
        break;
      case ReportKpiType.leadsNegotiation:
        subtitle = 'Leads currently in negotiation stage.';
        break;
      case ReportKpiType.leadsRejected:
        subtitle = 'All rejected leads with rejection reason, remark, and assigned salesperson.';
        break;
      default:
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLeadsBreadcrumb(context, 'Overall Business Insights', widget.onBack),
        const SizedBox(height: CRMSpacing.m),

        // Header Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            final badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: headerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: headerColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Count: ${_calculateTotalCount()}',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: headerColor),
              ),
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(widget.kpiType.icon, color: headerColor, size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.4),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      badge,
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
                      Row(
                        children: [
                          Icon(widget.kpiType.icon, color: headerColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            title,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                badge,
              ],
            );
          },
        ),
        const SizedBox(height: CRMSpacing.l),

        // Subtabs (if Call Attempted, Follow-Ups, or Re-Follow-Ups)
        if (widget.kpiType == ReportKpiType.leadsCallAttempted)
          _buildCallAttemptedSubtabs(context)
        else if (widget.kpiType == ReportKpiType.leadsFollowups || widget.kpiType == ReportKpiType.leadsReFollowups)
          _buildFollowupSubtabs(context),

        if (widget.kpiType == ReportKpiType.leadsCallAttempted ||
            widget.kpiType == ReportKpiType.leadsFollowups ||
            widget.kpiType == ReportKpiType.leadsReFollowups)
          const SizedBox(height: CRMSpacing.m),

        // Content Table Card
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
              // Search Bar
              LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth < 400 ? double.infinity : 320,
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {
                        _searchQuery = val.trim();
                        _currentPage = 1;
                      }),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Search leads, phone, salesperson...',
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
                  );
                },
              ),
              const SizedBox(height: CRMSpacing.m),

              // Render Leads Table
              _buildLeadsContent(context),
            ],
          ),
        ),
      ],
    );
  }

  int _calculateTotalCount() {
    final lpk = widget.reportData.insightSummary?.leadsPageKpis;
    if (lpk != null) {
      switch (widget.kpiType) {
        case ReportKpiType.leadsNotStarted:
          return lpk.notStarted;
        case ReportKpiType.leadsCallAttempted:
          if (_callAttemptedSubTab == 'picked_up') return lpk.callAttemptedPickedUp;
          if (_callAttemptedSubTab == 'open') return lpk.callAttemptedOpen;
          return lpk.callAttempted;
        case ReportKpiType.leadsFollowups:
          return lpk.followUps;
        case ReportKpiType.leadsReFollowups:
          return lpk.reFollowUps;
        case ReportKpiType.leadsInterested:
          return lpk.interested;
        case ReportKpiType.leadsSiteVisitScheduled:
          return lpk.siteVisitScheduled;
        case ReportKpiType.leadsSiteVisitDone:
        case ReportKpiType.siteVisitsDone:
          return lpk.siteVisitDone;
        case ReportKpiType.leadsNegotiation:
          return lpk.negotiation;
        case ReportKpiType.leadsRejected:
          return lpk.rejectedLeads;
        default:
          break;
      }
    }
    final kpiVal = widget.reportData.kpiValues[widget.kpiType];
    if (kpiVal != null) {
      return kpiVal.count;
    }
    return _totalServerCount > 0 ? _totalServerCount : _leads.length;
  }

  Widget _buildCallAttemptedSubtabs(BuildContext context) {
    final lpk = widget.reportData.insightSummary?.leadsPageKpis;
    final pickedUpCount = lpk?.callAttemptedPickedUp ?? 0;
    final openCount = lpk?.callAttemptedOpen ?? 0;

    final isDark = ThemeManager().isDarkMode;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _buildSubtabPill(
            label: 'Picked Up',
            count: pickedUpCount,
            isSelected: _callAttemptedSubTab == 'picked_up',
            color: const Color(0xFF0284C7),
            onTap: () {
              setState(() {
                _callAttemptedSubTab = 'picked_up';
                _currentPage = 1;
              });
              _fetchLeads();
            },
          ),
          _buildSubtabPill(
            label: 'Open',
            count: openCount,
            isSelected: _callAttemptedSubTab == 'open',
            color: const Color(0xFF2563EB),
            onTap: () {
              setState(() {
                _callAttemptedSubTab = 'open';
                _currentPage = 1;
              });
              _fetchLeads();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFollowupSubtabs(BuildContext context) {
    final isReFollowup = widget.kpiType == ReportKpiType.leadsReFollowups;
    final lpk = widget.reportData.insightSummary?.leadsPageKpis;
    final totalFollowups = isReFollowup ? (lpk?.reFollowUps ?? _leads.length) : (lpk?.followUps ?? _leads.length);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int todayCount = 0;
    int dueCount = 0;
    int futureCount = 0;

    for (final l in _leads) {
      final dt = l.createdAt ?? now;
      final targetDate = DateTime(dt.year, dt.month, dt.day);

      if (targetDate.isBefore(today)) {
        dueCount++;
      } else if (targetDate.isAfter(today)) {
        futureCount++;
      } else {
        todayCount++;
      }
    }

    final isDark = ThemeManager().isDarkMode;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _buildSubtabPill(
            label: 'All Follow-Ups',
            count: totalFollowups,
            isSelected: _followupSubTab == 'all',
            color: CRMColors.primary,
            onTap: () => setState(() {
              _followupSubTab = 'all';
              _currentPage = 1;
            }),
          ),
          _buildSubtabPill(
            label: isReFollowup ? 'Today Re-Follow-Ups' : 'Today Follow-Ups',
            count: todayCount,
            isSelected: _followupSubTab == 'today',
            color: const Color(0xFF0D9488),
            onTap: () => setState(() {
              _followupSubTab = 'today';
              _currentPage = 1;
            }),
          ),
          _buildSubtabPill(
            label: isReFollowup ? 'Due Re-Follow-Ups' : 'Due Follow-Ups',
            count: dueCount,
            isSelected: _followupSubTab == 'due',
            color: const Color(0xFFDC2626),
            onTap: () => setState(() {
              _followupSubTab = 'due';
              _currentPage = 1;
            }),
          ),
          _buildSubtabPill(
            label: isReFollowup ? 'Future Re-Follow-Ups' : 'Future Follow-Ups',
            count: futureCount,
            isSelected: _followupSubTab == 'future',
            color: const Color(0xFF2563EB),
            onTap: () => setState(() {
              _followupSubTab = 'future';
              _currentPage = 1;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtabPill({
    required String label,
    required int count,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
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
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadsContent(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    List<BusinessInsightLead> filtered = _leads;

    // Filter by Follow-up subtab if active
    if ((widget.kpiType == ReportKpiType.leadsFollowups || widget.kpiType == ReportKpiType.leadsReFollowups) && _followupSubTab != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      filtered = filtered.where((l) {
        final dt = l.createdAt ?? now;
        final targetDate = DateTime(dt.year, dt.month, dt.day);

        if (_followupSubTab == 'due') return targetDate.isBefore(today);
        if (_followupSubTab == 'future') return targetDate.isAfter(today);
        return targetDate.isAtSameMomentAs(today);
      }).toList();
    }

    // Apply Search Query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((l) {
        return l.customerName.toLowerCase().contains(q) ||
            l.phone.contains(q) ||
            (l.salespersonName ?? '').toLowerCase().contains(q) ||
            (l.telecallerName ?? '').toLowerCase().contains(q) ||
            (l.stage).toLowerCase().contains(q) ||
            (l.source).toLowerCase().contains(q) ||
            (l.rejectionReason ?? '').toLowerCase().contains(q) ||
            (l.followupRemark ?? '').toLowerCase().contains(q) ||
            (l.notInterestedRemark ?? '').toLowerCase().contains(q) ||
            (l.assignmentRemark ?? '').toLowerCase().contains(q);
      }).toList();
    }

    if (filtered.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 42, color: CRMColors.textSecondaryOf(context)),
              const SizedBox(height: 8),
              Text(
                'No leads match the current filters.',
                style: TextStyle(fontSize: 13, color: CRMColors.textSecondaryOf(context)),
              ),
            ],
          ),
        ),
      );
    }

    final totalPages = (filtered.length / _rowsPerPage).ceil().clamp(1, 999);
    final pagedLeads = filtered
        .skip((_currentPage - 1) * _rowsPerPage)
        .take(_rowsPerPage)
        .toList();

    final isRejectedKpi = widget.kpiType == ReportKpiType.leadsRejected;
    final isFollowupKpi = widget.kpiType == ReportKpiType.leadsFollowups || widget.kpiType == ReportKpiType.leadsReFollowups;
    final isDark = ThemeManager().isDarkMode;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        Widget contentWidget;
        if (isMobile) {
          contentWidget = Column(
            children: pagedLeads
                .map((lead) => _buildMobileLeadCard(context, lead, isFollowupKpi, isRejectedKpi, isDark))
                .toList(),
          );
        } else {
          contentWidget = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 22,
              columns: [
                const DataColumn(label: Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Source / Lead Type', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Assigned Sales / Telecaller', style: TextStyle(fontWeight: FontWeight.bold))),
                if (isFollowupKpi) ...[
                  const DataColumn(label: Text('Follow-Up Remark', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                if (isRejectedKpi) ...[
                  const DataColumn(label: Text('Rejection Reason', style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(label: Text('Rejection Remark', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                if (!isFollowupKpi && !isRejectedKpi)
                  const DataColumn(label: Text('Stage / Status', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Date / Time', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: pagedLeads.map((lead) {
                final dateStr = lead.createdAt != null
                    ? DateFormat('dd MMM yyyy, hh:mm a').format(lead.createdAt!)
                    : 'N/A';

                final staff = lead.salespersonName?.isNotEmpty == true
                    ? lead.salespersonName!
                    : (lead.telecallerName?.isNotEmpty == true ? lead.telecallerName! : 'Unassigned');

                return DataRow(
                  cells: [
                    // Client Details
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(lead.customerName, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text(lead.phone.isEmpty ? 'No Phone' : lead.phone, style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context))),
                        ],
                      ),
                    ),

                    // Source & Type
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildSourceBadge(lead.source),
                          const SizedBox(width: 6),
                          Text(lead.leadType.isEmpty ? 'Requirement' : lead.leadType, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),

                    // Assigned Staff
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          staff,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                        ),
                      ),
                    ),

                    // Follow-Up Specifics
                    if (isFollowupKpi) ...[
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(lead.followupRemark ?? 'Scheduled follow-up', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],

                    // Rejection Specifics
                    if (isRejectedKpi) ...[
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(lead.rejectionReason ?? 'Rejected', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                        ),
                      ),
                      DataCell(
                        Container(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(lead.notInterestedRemark ?? lead.assignmentRemark ?? 'Rejected lead', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],

                    // Default Status Badge
                    if (!isFollowupKpi && !isRejectedKpi)
                      DataCell(_buildStatusBadge(lead.stage)),

                    // Date / Time
                    DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                  ],
                );
              }).toList(),
            ),
          );
        }

        return Column(
          children: [
            contentWidget,
            const SizedBox(height: CRMSpacing.m),

            // Pagination
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  'Showing ${((_currentPage - 1) * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage).clamp(1, filtered.length)} of ${filtered.length} leads',
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
        );
      },
    );
  }

  Widget _buildMobileLeadCard(
    BuildContext context,
    BusinessInsightLead lead,
    bool isFollowupKpi,
    bool isRejectedKpi,
    bool isDark,
  ) {
    final dateStr = lead.createdAt != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(lead.createdAt!)
        : 'N/A';

    final staff = lead.salespersonName?.isNotEmpty == true
        ? lead.salespersonName!
        : (lead.telecallerName?.isNotEmpty == true ? lead.telecallerName! : 'Unassigned');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Client Name + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  lead.customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (isRejectedKpi)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      lead.rejectionReason ?? 'Rejected',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
              else if (!isFollowupKpi)
                Flexible(child: _buildStatusBadge(lead.stage)),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Phone & Source
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (lead.phone.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_outlined, size: 12, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(width: 3),
                    Text(
                      lead.phone,
                      style: TextStyle(fontSize: 11.5, color: CRMColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              _buildSourceBadge(lead.source),
              Text(
                lead.leadType.isEmpty ? 'Requirement' : lead.leadType,
                style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 3: Staff + Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person_rounded, size: 13, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          staff,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context)),
              ),
            ],
          ),

          // Optional Follow-Up Specifics
          if (isFollowupKpi) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF0D9488).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_repeat_rounded, size: 13, color: Color(0xFF0D9488)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Remark: ${lead.followupRemark ?? "Scheduled follow-up"}',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0D9488)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Optional Rejection Specifics
          if (isRejectedKpi && (lead.notInterestedRemark != null || lead.assignmentRemark != null)) ...[
            const SizedBox(height: 6),
            Text(
              'Remark: ${lead.notInterestedRemark ?? lead.assignmentRemark}',
              style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context), fontStyle: FontStyle.italic),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceBadge(String source) {
    Color color;
    final s = source.toLowerCase();
    if (s.contains('meta') || s.contains('facebook')) {
      color = const Color(0xFF1877F2);
    } else if (s.contains('housing')) {
      color = const Color(0xFFE11D48);
    } else if (s.contains('webhook')) {
      color = const Color(0xFF8B5CF6);
    } else {
      color = const Color(0xFFEA580C);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        source.isEmpty ? 'Direct' : source,
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getLeadsStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.isEmpty ? 'Active' : status,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Color _getLeadsStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('won')) return const Color(0xFF16A34A);
    if (s.contains('lost') || s.contains('reject')) return const Color(0xFFDC2626);
    if (s.contains('visit')) return const Color(0xFF9333EA);
    if (s.contains('follow')) return const Color(0xFF0D9488);
    if (s.contains('negotiation')) return const Color(0xFFF59E0B);
    if (s.contains('interested')) return const Color(0xFF16A34A);
    if (s.contains('not started')) return const Color(0xFF64748B);
    return const Color(0xFF0284C7);
  }
}

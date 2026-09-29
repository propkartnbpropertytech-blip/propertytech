import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/design_system/tokens/app_colors.dart';
import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../core/theme/theme_manager.dart';
import '../../requirements/models/requirement_model.dart';
import '../models/report_kpi_type.dart';
import '../models/report_data.dart';

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

  const LeadsPageKpiDrilldownView({
    super.key,
    required this.kpiType,
    required this.reportData,
    required this.onBack,
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

  // Sub-filter for Follow-Ups & Re-Follow-Ups ('today', 'due', 'future')
  String _followupSubTab = 'today';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final allLeads = widget.reportData.allLeads;

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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: headerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: headerColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Count: ${_calculateTotalCount(allLeads)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: headerColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: CRMSpacing.l),

        // Subtabs (if Call Attempted, Follow-Ups, or Re-Follow-Ups)
        if (widget.kpiType == ReportKpiType.leadsCallAttempted)
          _buildCallAttemptedSubtabs(context, allLeads)
        else if (widget.kpiType == ReportKpiType.leadsFollowups || widget.kpiType == ReportKpiType.leadsReFollowups)
          _buildFollowupSubtabs(context, allLeads),

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
              SizedBox(
                width: 320,
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
              ),
              const SizedBox(height: CRMSpacing.m),

              // Render Leads Table
              _buildLeadsContent(context, allLeads),
            ],
          ),
        ),
      ],
    );
  }

  int _calculateTotalCount(List<RequirementModel> allLeads) {
    switch (widget.kpiType) {
      case ReportKpiType.leadsNotStarted:
        return allLeads.where((l) => l.status.trim().toLowerCase() == 'not started').length;
      case ReportKpiType.leadsCallAttempted:
        return allLeads.where((l) =>
            l.status.toLowerCase().startsWith('call attempted') ||
            l.status.toLowerCase() == 'picked up' ||
            l.status.toLowerCase() == 'open' ||
            l.status.toLowerCase() == 'assigned').length;
      case ReportKpiType.leadsFollowups:
        return allLeads.where((l) =>
            l.status.trim().toLowerCase() == 'follow-up' ||
            l.status.trim().toLowerCase() == 'followup').length;
      case ReportKpiType.leadsReFollowups:
        return allLeads.where((l) =>
            l.status.trim().toLowerCase() == 're-followup' ||
            l.status.trim().toLowerCase() == 're-follow-up' ||
            l.status.trim().toLowerCase() == 'refollowup').length;
      case ReportKpiType.leadsInterested:
        return allLeads.where((l) => l.status.trim().toLowerCase() == 'interested').length;
      case ReportKpiType.leadsSiteVisitScheduled:
        return allLeads.where((l) =>
            l.status.trim().toLowerCase() == 'site visit' ||
            l.status.trim().toLowerCase() == 'site visit scheduled').length;
      case ReportKpiType.leadsSiteVisitDone:
        return allLeads.where((l) => l.status.trim().toLowerCase() == 'site visit done').length;
      case ReportKpiType.leadsNegotiation:
        return allLeads.where((l) => l.status.trim().toLowerCase().contains('negotiation')).length;
      case ReportKpiType.leadsRejected:
        return allLeads.where((l) => l.status.trim().toLowerCase().startsWith('rejected')).length;
      default:
        return 0;
    }
  }

  Widget _buildCallAttemptedSubtabs(BuildContext context, List<RequirementModel> allLeads) {
    final pickedUpCount = allLeads.where((l) =>
        l.status.toLowerCase() == 'call attempted (picked up)' ||
        l.status.toLowerCase() == 'picked up').length;
    final openCount = allLeads.where((l) =>
        l.status.toLowerCase() == 'call attempted (open)' ||
        l.status.toLowerCase() == 'open' ||
        l.status.toLowerCase() == 'assigned').length;

    final isDark = ThemeManager().isDarkMode;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSubtabPill(
            label: 'Picked Up',
            count: pickedUpCount,
            isSelected: _callAttemptedSubTab == 'picked_up',
            color: const Color(0xFF0284C7),
            onTap: () => setState(() {
              _callAttemptedSubTab = 'picked_up';
              _currentPage = 1;
            }),
          ),
          const SizedBox(width: 8),
          _buildSubtabPill(
            label: 'Open',
            count: openCount,
            isSelected: _callAttemptedSubTab == 'open',
            color: const Color(0xFF2563EB),
            onTap: () => setState(() {
              _callAttemptedSubTab = 'open';
              _currentPage = 1;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowupSubtabs(BuildContext context, List<RequirementModel> allLeads) {
    final isReFollowup = widget.kpiType == ReportKpiType.leadsReFollowups;
    final targetLeads = allLeads.where((l) {
      final s = l.status.trim().toLowerCase();
      if (isReFollowup) {
        return s == 're-followup' || s == 're-follow-up' || s == 'refollowup';
      } else {
        return s == 'follow-up' || s == 'followup';
      }
    }).toList();

    // Categorize using FollowupSyncEngine logic
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int todayCount = 0;
    int dueCount = 0;
    int futureCount = 0;

    for (final l in targetLeads) {
      DateTime? dt;
      if (l.nextFollowupDate != null && l.nextFollowupDate!.trim().isNotEmpty) {
        dt = DateTime.tryParse(l.nextFollowupDate!.trim());
      }
      dt ??= l.createdAt;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
          const SizedBox(width: 8),
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
          const SizedBox(width: 8),
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

  Widget _buildLeadsContent(BuildContext context, List<RequirementModel> allLeads) {
    List<RequirementModel> filtered = [];

    switch (widget.kpiType) {
      case ReportKpiType.leadsNotStarted:
        filtered = allLeads.where((l) => l.status.trim().toLowerCase() == 'not started').toList();
        break;

      case ReportKpiType.leadsCallAttempted:
        if (_callAttemptedSubTab == 'picked_up') {
          filtered = allLeads.where((l) =>
              l.status.toLowerCase() == 'call attempted (picked up)' ||
              l.status.toLowerCase() == 'picked up').toList();
        } else {
          filtered = allLeads.where((l) =>
              l.status.toLowerCase() == 'call attempted (open)' ||
              l.status.toLowerCase() == 'open' ||
              l.status.toLowerCase() == 'assigned').toList();
        }
        break;

      case ReportKpiType.leadsFollowups:
      case ReportKpiType.leadsReFollowups:
        final isRe = widget.kpiType == ReportKpiType.leadsReFollowups;
        final targetLeads = allLeads.where((l) {
          final s = l.status.trim().toLowerCase();
          if (isRe) {
            return s == 're-followup' || s == 're-follow-up' || s == 'refollowup';
          } else {
            return s == 'follow-up' || s == 'followup';
          }
        }).toList();

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        filtered = targetLeads.where((l) {
          DateTime? dt;
          if (l.nextFollowupDate != null && l.nextFollowupDate!.trim().isNotEmpty) {
            dt = DateTime.tryParse(l.nextFollowupDate!.trim());
          }
          dt ??= l.createdAt;
          final targetDate = DateTime(dt.year, dt.month, dt.day);

          if (_followupSubTab == 'due') return targetDate.isBefore(today);
          if (_followupSubTab == 'future') return targetDate.isAfter(today);
          return targetDate.isAtSameMomentAs(today);
        }).toList();
        break;

      case ReportKpiType.leadsInterested:
        filtered = allLeads.where((l) => l.status.trim().toLowerCase() == 'interested').toList();
        break;

      case ReportKpiType.leadsSiteVisitScheduled:
        filtered = allLeads.where((l) =>
            l.status.trim().toLowerCase() == 'site visit' ||
            l.status.trim().toLowerCase() == 'site visit scheduled').toList();
        break;

      case ReportKpiType.leadsSiteVisitDone:
        filtered = allLeads.where((l) => l.status.trim().toLowerCase() == 'site visit done').toList();
        break;

      case ReportKpiType.leadsNegotiation:
        filtered = allLeads.where((l) => l.status.trim().toLowerCase().contains('negotiation')).toList();
        break;

      case ReportKpiType.leadsRejected:
        filtered = allLeads.where((l) => l.status.trim().toLowerCase().startsWith('rejected')).toList();
        break;

      default:
        filtered = allLeads;
        break;
    }

    // Apply Search Query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((l) {
        return l.clientName.toLowerCase().contains(q) ||
            l.clientMobile.contains(q) ||
            (l.assigneeName ?? '').toLowerCase().contains(q) ||
            (l.status).toLowerCase().contains(q) ||
            (l.remarks ?? '').toLowerCase().contains(q);
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

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 22,
            columns: [
              const DataColumn(label: Text('Client Details', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Requirement / Config', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Assigned Salesperson', style: TextStyle(fontWeight: FontWeight.bold))),
              if (isFollowupKpi) ...[
                const DataColumn(label: Text('Follow-Up Date/Time', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Follow-Up Remark', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              if (isRejectedKpi) ...[
                const DataColumn(label: Text('Rejection Reason / Status', style: TextStyle(fontWeight: FontWeight.bold))),
                const DataColumn(label: Text('Rejection Remark', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              if (!isFollowupKpi && !isRejectedKpi)
                const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              const DataColumn(label: Text('Date / Time', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: pagedLeads.map((req) {
              final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(req.createdAt);
              final followupDateStr = req.nextFollowupDate != null && req.nextFollowupDate!.trim().isNotEmpty
                  ? (DateTime.tryParse(req.nextFollowupDate!.trim()) != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(req.nextFollowupDate!.trim()))
                      : req.nextFollowupDate!)
                  : 'Pending';

              // Extract reason from status e.g. "Rejected (Budget Mismatch)" -> "Budget Mismatch"
              String rejectionReason = 'Rejected';
              if (req.status.contains('(') && req.status.contains(')')) {
                rejectionReason = req.status.substring(req.status.indexOf('(') + 1, req.status.indexOf(')'));
              }

              final salesperson = (req.assigneeName != null && req.assigneeName!.trim().isNotEmpty)
                  ? req.assigneeName!.trim()
                  : ((req.assignedTo != null && req.assignedTo!.trim().isNotEmpty)
                      ? req.assignedTo!.trim()
                      : 'Unassigned');

              return DataRow(
                cells: [
                  // Client Details
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(req.clientName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(req.clientMobile.isEmpty ? 'No Phone' : req.clientMobile, style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context))),
                      ],
                    ),
                  ),

                  // Requirement / Config
                  DataCell(
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          req.configurationName ?? (req.categoryName.isNotEmpty ? req.categoryName : 'Residential'),
                          style: const TextStyle(fontSize: 12.5),
                        ),
                        if (req.areaNames.isNotEmpty)
                          Text(
                            req.areaNames.join(', '),
                            style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context)),
                          ),
                      ],
                    ),
                  ),

                  // Assigned Salesperson
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        salesperson,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                      ),
                    ),
                  ),

                  // Follow-Up Specifics
                  if (isFollowupKpi) ...[
                    DataCell(Text(followupDateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(req.remarks ?? (req.notes ?? 'Scheduled follow-up'), style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
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
                        child: Text(rejectionReason, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(req.remarks ?? 'Rejected lead', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],

                  // Default Status Badge
                  if (!isFollowupKpi && !isRejectedKpi)
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getLeadsStatusColor(req.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(req.status, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _getLeadsStatusColor(req.status))),
                      ),
                    ),

                  // Date / Time
                  DataCell(Text(dateStr, style: const TextStyle(fontSize: 12))),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: CRMSpacing.m),

        // Pagination
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${((_currentPage - 1) * _rowsPerPage) + 1} - ${(_currentPage * _rowsPerPage).clamp(1, filtered.length)} of ${filtered.length} leads',
              style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
            ),
            Row(
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

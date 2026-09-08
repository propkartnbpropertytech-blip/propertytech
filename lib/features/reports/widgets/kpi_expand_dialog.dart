import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_kpi_type.dart';
import '../models/report_data.dart';

class KpiExpandDialog extends StatelessWidget {
  final ReportKpiType kpiType;
  final ReportOverallData reportData;

  const KpiExpandDialog({
    super.key,
    required this.kpiType,
    required this.reportData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final kpiVal = reportData.kpiValues[kpiType];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 780,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kpiType.defaultColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(kpiType.icon, size: 20, color: kpiType.defaultColor),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kpiType.displayName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          kpiVal?.denominatorLabel ?? kpiType.denominatorExplanation,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: kpiType.defaultColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            kpiVal?.formattedCount ?? '0',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kpiType.defaultColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${kpiVal?.formattedPercentage ?? '0%'})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kpiType.defaultColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Dynamic Content tailored for this specific KPI
            Expanded(
              child: _buildKpiSpecificContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiSpecificContent(BuildContext context) {
    switch (kpiType) {
      case ReportKpiType.totalLeads:
      case ReportKpiType.leadsContacted:
      case ReportKpiType.leadsAssignedToSales:
      case ReportKpiType.leadQualificationRate:
        return _buildLeadsBreakdownView(context);

      case ReportKpiType.telecallers:
        return _buildTelecallersRankingView(context);

      case ReportKpiType.salesUsers:
        return _buildSalesUsersRankingView(context);

      case ReportKpiType.callAttempted:
      case ReportKpiType.callPickedUp:
      case ReportKpiType.callOpen:
        return _buildCallBreakdownView(context);

      case ReportKpiType.siteVisitsScheduled:
      case ReportKpiType.siteVisitsDone:
        return _buildSiteVisitsBreakdownView(context);

      case ReportKpiType.convertedToWon:
        return _buildWonDealsView(context);

      case ReportKpiType.lostUnsuccessful:
        return _buildLostLeadsView(context);
    }
  }

  // 1. Leads breakdown list
  Widget _buildLeadsBreakdownView(BuildContext context) {
    final leads = reportData.filteredLeads;
    if (leads.isEmpty) {
      return const Center(child: Text('No leads available for this metric.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Leads Breakdown (${leads.length} leads)',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: leads.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final lead = leads[idx];
              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: CRMColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    lead.clientName.isNotEmpty ? lead.clientName[0].toUpperCase() : 'L',
                    style: TextStyle(color: CRMColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(lead.clientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text(
                  '${lead.clientMobile} · ${lead.categoryName} · Added: ${DateFormat('dd MMM yyyy').format(lead.createdAt)}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: CRMColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        lead.status,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CRMColors.primary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, size: 18),
                  ],
                ),
                onTap: () {
                  context.go('/requirements?search=${Uri.encodeComponent(lead.clientName)}');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 2. Telecallers performance view
  Widget _buildTelecallersRankingView(BuildContext context) {
    final list = reportData.telecallerRankings;
    if (list.isEmpty) {
      return const Center(child: Text('No telecaller records found.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Telecaller Team Performance',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final t = list[idx];
              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF64748B).withValues(alpha: 0.15),
                  child: Text('#${t.rank}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                title: Text(t.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Leads Managed: ${t.leadsCount} · Qualified: ${t.qualifiedCount} · Won: ${t.wonCount}', style: const TextStyle(fontSize: 11)),
                trailing: ElevatedButton(
                  onPressed: () => context.go('/reports/leads/telecaller'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View Report', style: TextStyle(fontSize: 11)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 3. Sales Users ranking view
  Widget _buildSalesUsersRankingView(BuildContext context) {
    final list = reportData.salesRankings;
    if (list.isEmpty) {
      return const Center(child: Text('No sales user records found.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales Team Closures & Rankings',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: list.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final s = list[idx];
              return ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF16A34A).withValues(alpha: 0.15),
                  child: Text('#${s.rank}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF16A34A))),
                ),
                title: Text(s.userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Assigned: ${s.leadsCount} · Site Visits: ${s.siteVisitsCount} · Won: ${s.wonCount} (${s.conversionRate.toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 11)),
                trailing: ElevatedButton(
                  onPressed: () => context.go('/reports/leads/sales'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View Report', style: TextStyle(fontSize: 11)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 4. Call breakdown view
  Widget _buildCallBreakdownView(BuildContext context) {
    final callsAttempted = reportData.kpiValues[ReportKpiType.callAttempted]?.count ?? 0;
    final pickedUp = reportData.kpiValues[ReportKpiType.callPickedUp]?.count ?? 0;
    final open = reportData.kpiValues[ReportKpiType.callOpen]?.count ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricMiniCard('Total Attempted', callsAttempted.toString(), const Color(0xFFD97706)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricMiniCard('Picked Up / Connected', pickedUp.toString(), const Color(0xFF059669)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricMiniCard('Open / Pending', open.toString(), const Color(0xFFE11D48)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Follow-up Call Activity Feed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: reportData.followupCategories.isEmpty
              ? const Center(child: Text('No call activity logged.'))
              : ListView.separated(
                  itemCount: reportData.followupCategories.first.items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = reportData.followupCategories.first.items[i];
                    return ListTile(
                      dense: true,
                      title: Text(item.leadName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      subtitle: Text('${item.clientMobile ?? ''} · Date: ${DateFormat('dd MMM, hh:mm a').format(item.followupDateTime)}', style: const TextStyle(fontSize: 11)),
                      trailing: Text(item.nextAction, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      onTap: () {
                        context.go('/requirements?search=${Uri.encodeComponent(item.leadName)}');
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // 5. Site visits breakdown view
  Widget _buildSiteVisitsBreakdownView(BuildContext context) {
    final scheduled = reportData.kpiValues[ReportKpiType.siteVisitsScheduled]?.count ?? 0;
    final done = reportData.kpiValues[ReportKpiType.siteVisitsDone]?.count ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricMiniCard('Visits Scheduled', scheduled.toString(), const Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricMiniCard('Visits Completed / Done', done.toString(), const Color(0xFF9333EA)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Site Visit Opportunities', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: _buildLeadsBreakdownView(context),
        ),
      ],
    );
  }

  // 6. Won deals view
  Widget _buildWonDealsView(BuildContext context) {
    final wonLeads = reportData.filteredLeads.where((l) => l.status.toLowerCase() == 'won' || l.status.toLowerCase() == 'closed').toList();

    if (wonLeads.isEmpty) {
      return const Center(child: Text('No deals marked as Won in this period.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Converted Won Deals (${wonLeads.length})',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: wonLeads.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final lead = wonLeads[idx];
              return ListTile(
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF16A34A),
                  child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 16),
                ),
                title: Text(lead.clientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text(
                  'Sales Rep: ${lead.assigneeName ?? 'Assigned'} · Closed: ${DateFormat('dd MMM yyyy').format(lead.createdAt)}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Text('Rs ${lead.maxBudget.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF16A34A))),
                onTap: () {
                  context.go('/requirements?search=${Uri.encodeComponent(lead.clientName)}');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // 7. Lost leads view
  Widget _buildLostLeadsView(BuildContext context) {
    final lostLeads = reportData.filteredLeads.where((l) {
      final s = l.status.toLowerCase();
      return s.startsWith('rejected') || s == 'lost' || s == 'dead' || s == 'suspended' || s == 'bin';
    }).toList();

    if (lostLeads.isEmpty) {
      return const Center(child: Text('No lost or rejected leads in this period.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lost & Unsuccessful Leads (${lostLeads.length})',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: lostLeads.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final lead = lostLeads[idx];
              return ListTile(
                leading: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFDC2626),
                  child: Icon(Icons.cancel_outlined, color: Colors.white, size: 16),
                ),
                title: Text(lead.clientName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('Status: ${lead.status} · Remarks: ${lead.remarks ?? 'N/A'}', style: const TextStyle(fontSize: 11)),
                onTap: () {
                  context.go('/requirements?search=${Uri.encodeComponent(lead.clientName)}');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMetricMiniCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

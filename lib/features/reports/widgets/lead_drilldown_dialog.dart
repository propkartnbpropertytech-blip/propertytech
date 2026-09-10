import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../../requirements/models/requirement_model.dart';
import '../../requirements/screens/add_edit_requirement_screen.dart';

class LeadDrilldownDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<RequirementModel> leads;

  const LeadDrilldownDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leads,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        width: 900,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$subtitle · ${leads.length} Leads found',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Leads Table
            Expanded(
              child: leads.isEmpty
                  ? Center(
                      child: Text(
                        'No leads match this criteria in the selected period.',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowHeight: 40,
                          dataRowMinHeight: 48,
                          dataRowMaxHeight: 52,
                          columns: const [
                            DataColumn(label: Text('Client Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Mobile', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Assigned To', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Created / Telecaller', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Budget Range', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Next Follow-up', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: leads.map((lead) {
                            final nextFollowup = lead.nextFollowupDate != null
                                ? DateFormat('dd MMM').format(DateTime.tryParse(lead.nextFollowupDate!) ?? lead.createdAt)
                                : '—';
                            final budget = 'Rs ${(lead.maxBudget / 100000).toStringAsFixed(1)}L';

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    lead.clientName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                  onTap: () => _openLeadDetail(context, lead),
                                ),
                                DataCell(Text(lead.clientMobile)),
                                DataCell(
                                  Builder(
                                    builder: (context) {
                                      final statusColor = _getStatusColor(lead.status);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          lead.status,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: statusColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                DataCell(Text(lead.assigneeName ?? 'Unassigned')),
                                DataCell(Text(lead.creatorName ?? 'System')),
                                DataCell(Text(budget)),
                                DataCell(Text(nextFollowup)),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                    tooltip: 'View in Leads Manager',
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      context.go('/requirements?search=${Uri.encodeComponent(lead.clientName)}');
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLeadDetail(BuildContext context, RequirementModel lead) {
    showDialog(
      context: context,
      builder: (dialogContext) => AddEditRequirementScreen(
        requirement: lead,
        onSaved: () {},
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.startsWith('won')) return const Color(0xFF16A34A);
    if (s.startsWith('reject') || s == 'dead' || s == 'bin' || s == 'suspended' || s == 'lost' || s == 'not interested') {
      return const Color(0xFFDC2626);
    }
    if (s.startsWith('call attempted') || s.startsWith('call')) {
      return const Color(0xFF0288D1);
    }
    if (s.contains('visit')) return const Color(0xFF9333EA);
    if (s.contains('negotiation')) return const Color(0xFFEA580C);
    if (s.contains('follow')) return const Color(0xFFD97706);
    if (s == 'interested' || s == 'active' || s == 'live') return const Color(0xFF0284C7);
    return const Color(0xFF64748B);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/theme/theme_manager.dart';
import '../../integration/models/integration_lead_model.dart';
import 'telecaller_assigned_leads_page.dart';

class SourceTotalLeadsPage extends StatefulWidget {
  final String sourceTitle; // 'Meta' or 'Housing'
  final String sourceName; // 'Meta Ads' or 'Housing.com'
  final String dateRangeLabel; // e.g. 'Today', 'This Month', etc.
  final List<IntegrationLeadModel> leads;

  const SourceTotalLeadsPage({
    super.key,
    required this.sourceTitle,
    required this.sourceName,
    this.dateRangeLabel = 'All Time',
    required this.leads,
  });

  @override
  State<SourceTotalLeadsPage> createState() => _SourceTotalLeadsPageState();
}

class _SourceTotalLeadsPageState extends State<SourceTotalLeadsPage> {
  String _selectedLeadTypeTab = 'Property Listing'; // 'Property Listing' or 'Requirement'
  String _searchLeadQuery = '';
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    final propCount = widget.leads.where((l) => l.leadType == 'Property Listing').length;
    final reqCount = widget.leads.where((l) => l.leadType == 'Requirement').length;
    if (propCount == 0 && reqCount > 0) {
      _selectedLeadTypeTab = 'Requirement';
    }
  }

  Color get _sourceColor {
    final s = widget.sourceTitle.toLowerCase();
    if (s.contains('meta')) return const Color(0xFF1877F2);
    if (s.contains('housing')) return const Color(0xFFE11D48);
    return const Color(0xFF6366F1);
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase().trim();
    if (s == 'new') return const Color(0xFF3B82F6);
    if (s.contains('follow')) return const Color(0xFFF59E0B);
    if (s == 'interested') return const Color(0xFF10B981);
    if (s == 'cnr') return const Color(0xFF8B5CF6);
    if (s.contains('not interested')) return const Color(0xFFEF4444);
    if (s.contains('listed') || s.contains('archive')) return const Color(0xFF6B7280);
    return const Color(0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final allLeads = widget.leads;
    final propLeads = allLeads.where((l) => l.leadType == 'Property Listing').toList();
    final reqLeads = allLeads.where((l) => l.leadType == 'Requirement').toList();
    final assignedLeads = allLeads.where(TelecallerAssignedLeadsPage.isLeadAssignedToTelecaller).toList();

    final activeTabLeads = _selectedLeadTypeTab == 'Property Listing' ? propLeads : reqLeads;

    // Filter by search & status
    final query = _searchLeadQuery.trim().toLowerCase();
    final filteredLeads = activeTabLeads.where((lead) {
      if (_selectedStatusFilter != 'All') {
        final st = lead.campaignStatus.trim().toLowerCase();
        if (st != _selectedStatusFilter.toLowerCase()) return false;
      }
      if (query.isNotEmpty) {
        final name = lead.getStringValue('Full Name').toLowerCase();
        final name2 = lead.getStringValue('Name').toLowerCase();
        final phone = lead.getStringValue('Phone Number').toLowerCase();
        final phone2 = lead.getStringValue('Mobile').toLowerCase();
        final email = lead.getStringValue('Email').toLowerCase();
        final status = lead.campaignStatus.toLowerCase();
        final remarks = (lead.followupRemarks ?? lead.callbackRemarks ?? '').toLowerCase();
        final tcName = TelecallerAssignedLeadsPage.extractTelecallerName(lead).toLowerCase();

        if (!name.contains(query) &&
            !name2.contains(query) &&
            !phone.contains(query) &&
            !phone2.contains(query) &&
            !email.contains(query) &&
            !status.contains(query) &&
            !remarks.contains(query) &&
            !tcName.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Campaign',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: _sourceColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _sourceColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.sourceTitle.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: _sourceColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                '${widget.sourceTitle} · Total Leads (${widget.dateRangeLabel})',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.pie_chart_rounded, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${allLeads.length} Total Leads',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Metrics Summary Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: CRMColors.borderOf(context)),
                boxShadow: CRMShadows.soft,
              ),
              child: Row(
                children: [
                  _buildSummaryStat(
                    context,
                    title: 'Total Leads (${widget.dateRangeLabel})',
                    count: allLeads.length,
                    color: _sourceColor,
                    icon: Icons.pie_chart_rounded,
                  ),
                  _buildStatDivider(context),
                  _buildSummaryStat(
                    context,
                    title: 'Property Listing Leads',
                    count: propLeads.length,
                    color: const Color(0xFF0284C7),
                    icon: Icons.home_work_rounded,
                  ),
                  _buildStatDivider(context),
                  _buildSummaryStat(
                    context,
                    title: 'Requirement Leads',
                    count: reqLeads.length,
                    color: const Color(0xFF10B981),
                    icon: Icons.people_alt_rounded,
                  ),
                  _buildStatDivider(context),
                  _buildSummaryStat(
                    context,
                    title: 'Assigned to Telecaller',
                    count: assignedLeads.length,
                    color: const Color(0xFF6366F1),
                    icon: Icons.support_agent_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Date Range Notice Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _sourceColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _sourceColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: _sourceColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing leads received from ${widget.sourceTitle} for date range: ${widget.dateRangeLabel} (including Active, Follow-up, Interested, Not Interested, and Listed).',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: CRMColors.textOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Two Separate Tabs: Property Listing Leads vs Requirement Leads
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CRMColors.borderOf(context)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildLeadTypeTabButton(
                      context,
                      title: 'Property Listing Leads',
                      subtitle: 'Owners listing properties',
                      count: propLeads.length,
                      icon: Icons.home_work_rounded,
                      activeColor: const Color(0xFF0284C7),
                      isSelected: _selectedLeadTypeTab == 'Property Listing',
                      onTap: () {
                        if (_selectedLeadTypeTab != 'Property Listing') {
                          setState(() {
                            _selectedLeadTypeTab = 'Property Listing';
                            _searchLeadQuery = '';
                            _selectedStatusFilter = 'All';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildLeadTypeTabButton(
                      context,
                      title: 'Requirement Leads',
                      subtitle: 'Tenants & buyers seeking property',
                      count: reqLeads.length,
                      icon: Icons.people_alt_rounded,
                      activeColor: const Color(0xFF10B981),
                      isSelected: _selectedLeadTypeTab == 'Requirement',
                      onTap: () {
                        if (_selectedLeadTypeTab != 'Requirement') {
                          setState(() {
                            _selectedLeadTypeTab = 'Requirement';
                            _searchLeadQuery = '';
                            _selectedStatusFilter = 'All';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search and status filter bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchLeadQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search by client name, phone, email, notes, telecaller...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: CRMColors.borderOf(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: CRMColors.borderOf(context)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CRMColors.borderOf(context)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedStatusFilter,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CRMColors.textOf(context),
                      ),
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      items: [
                        'All',
                        'New',
                        'Follow up',
                        'Interested',
                        'CNR',
                        'Not interested',
                        'Property Listed',
                        'Archived',
                      ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatusFilter = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CRMColors.borderOf(context)),
                  ),
                  child: Text(
                    '${filteredLeads.length} Lead(s)',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Leads list
            if (filteredLeads.isEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CRMColors.borderOf(context)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 48, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(height: 12),
                    Text(
                      'No $_selectedLeadTypeTab Leads found in ${widget.sourceTitle} for ${widget.dateRangeLabel}.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredLeads.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final lead = filteredLeads[index];
                  return _buildLeadItemCard(context, lead, index + 1);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: CRMColors.textOf(context),
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: CRMColors.textSecondaryOf(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    return Container(
      height: 36,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: CRMColors.borderOf(context),
    );
  }

  Widget _buildLeadTypeTabButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color activeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeManager().isDarkMode;
    final activeBg = isDark ? const Color(0xFF262E3D) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(color: activeColor.withValues(alpha: 0.5), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.15)
                    : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: isSelected ? activeColor : CRMColors.textSecondaryOf(context), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? CRMColors.textOf(context) : CRMColors.textSecondaryOf(context),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? activeColor : activeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : activeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: CRMColors.textSecondaryOf(context),
                    ),
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

  Widget _buildLeadItemCard(BuildContext context, IntegrationLeadModel lead, int rowNumber) {
    final isDark = ThemeManager().isDarkMode;
    final name = lead.getStringValue('Full Name').isNotEmpty
        ? lead.getStringValue('Full Name')
        : (lead.getStringValue('Name').isNotEmpty ? lead.getStringValue('Name') : 'Lead #${lead.id}');
    final phone = lead.getStringValue('Phone Number').isNotEmpty
        ? lead.getStringValue('Phone Number')
        : lead.getStringValue('Mobile');
    final email = lead.getStringValue('Email');
    final status = lead.campaignStatus.trim().isEmpty ? 'New' : lead.campaignStatus;
    final statusColor = _statusColor(status);
    final dateStr = DateFormat('d MMM y, h:mm a').format(lead.receivedAt);
    final isAssigned = TelecallerAssignedLeadsPage.isLeadAssignedToTelecaller(lead);
    final tcName = TelecallerAssignedLeadsPage.extractTelecallerName(lead);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.borderOf(context)),
        boxShadow: CRMShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row number pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '#$rowNumber',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CRMColors.textSecondaryOf(context)),
                ),
              ),
              const SizedBox(width: 10),
              // Client Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Received: $dateStr · Source: ${lead.source}',
                      style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ),
              // Telecaller badge if assigned
              if (isAssigned) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_pin_rounded, size: 12, color: Color(0xFF6366F1)),
                      const SizedBox(width: 4),
                      Text(
                        tcName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Contact details & actions row
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (phone.isNotEmpty) ...[
                InkWell(
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_rounded, size: 13, color: Color(0xFF10B981)),
                        const SizedBox(width: 5),
                        Text(
                          phone,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  tooltip: 'Copy phone',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Phone number copied'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ],
              if (email.isNotEmpty) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.email_outlined, size: 13, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(width: 4),
                    Text(
                      email,
                      style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
              ],
              TextButton.icon(
                onPressed: () => _showLeadCompleteDetailsDialog(context, lead),
                icon: const Icon(Icons.info_outline_rounded, size: 14),
                label: const Text('Complete Details', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),

          // Remarks or notes if present
          if ((lead.followupRemarks != null && lead.followupRemarks!.isNotEmpty) ||
              (lead.callbackRemarks != null && lead.callbackRemarks!.isNotEmpty) ||
              (lead.notInterestedReason != null && lead.notInterestedReason!.isNotEmpty)) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262E3D) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes_rounded, size: 13, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lead.followupRemarks ?? lead.callbackRemarks ?? lead.notInterestedReason ?? '',
                      style: const TextStyle(fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showLeadCompleteDetailsDialog(BuildContext context, IntegrationLeadModel lead) {
    final isDark = ThemeManager().isDarkMode;
    final name = lead.getStringValue('Full Name').isNotEmpty
        ? lead.getStringValue('Full Name')
        : (lead.getStringValue('Name').isNotEmpty ? lead.getStringValue('Name') : 'Lead #${lead.id}');
    final phone = lead.getStringValue('Phone Number').isNotEmpty
        ? lead.getStringValue('Phone Number')
        : lead.getStringValue('Mobile');
    final email = lead.getStringValue('Email');
    final tcName = TelecallerAssignedLeadsPage.extractTelecallerName(lead);

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 680),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dialog Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _sourceColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.assignment_rounded, color: _sourceColor, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${lead.leadType} · ${lead.source}',
                              style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  // Scrollable details body
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailSectionTitle('Client Contact Details'),
                          const SizedBox(height: 8),
                          _buildDetailRow('Full Name', name),
                          if (phone.isNotEmpty) _buildDetailRow('Phone Number', phone),
                          if (email.isNotEmpty) _buildDetailRow('Email', email),
                          _buildDetailRow('Received Date', DateFormat('d MMM y, h:mm:ss a').format(lead.receivedAt)),
                          _buildDetailRow('Campaign Status', lead.campaignStatus),
                          if (TelecallerAssignedLeadsPage.isLeadAssignedToTelecaller(lead)) ...[
                            _buildDetailRow('Assigned Telecaller', tcName),
                          ],
                          if (lead.allocationStatus != null && lead.allocationStatus!.isNotEmpty) ...[
                            _buildDetailRow('Allocation Status', lead.allocationStatus!),
                          ],

                          if (lead.rawJson.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildDetailSectionTitle('Campaign Form Responses (${widget.sourceTitle})'),
                            const SizedBox(height: 8),
                            ...lead.rawJson.entries
                                .where((e) =>
                                    !e.key.startsWith('_') &&
                                    e.key != 'raw_json' &&
                                    e.value != null &&
                                    e.value.toString().trim().isNotEmpty)
                                .map((e) => _buildDetailRow(e.key, e.value.toString())),
                          ],

                          if (lead.followupRemarks != null ||
                              lead.callbackRemarks != null ||
                              lead.notInterestedReason != null) ...[
                            const SizedBox(height: 16),
                            _buildDetailSectionTitle('Calling Remarks & Notes'),
                            const SizedBox(height: 8),
                            if (lead.followupRemarks != null && lead.followupRemarks!.isNotEmpty)
                              _buildDetailRow('Follow-up Remarks', lead.followupRemarks!),
                            if (lead.callbackRemarks != null && lead.callbackRemarks!.isNotEmpty)
                              _buildDetailRow('Callback Remarks', lead.callbackRemarks!),
                            if (lead.notInterestedReason != null && lead.notInterestedReason!.isNotEmpty)
                              _buildDetailRow('Not Interested Reason', lead.notInterestedReason!),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
        color: Color(0xFF6366F1),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = ThemeManager().isDarkMode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CRMColors.textSecondaryOf(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: CRMColors.textOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

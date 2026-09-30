import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/theme/theme_manager.dart';
import '../../integration/models/integration_lead_model.dart';

class TelecallerAssignedLeadsPage extends StatefulWidget {
  final String sourceTitle; // 'Meta' or 'Housing'
  final String sourceName; // 'Meta Ads' or 'Housing.com'
  final String dateRangeLabel; // e.g. 'Today', 'This Month', etc.
  final List<IntegrationLeadModel> allSourceLeads;

  const TelecallerAssignedLeadsPage({
    super.key,
    required this.sourceTitle,
    required this.sourceName,
    this.dateRangeLabel = 'All Time',
    required this.allSourceLeads,
  });

  // Helper to extract clean telecaller name from lead
  static String extractTelecallerName(IntegrationLeadModel lead) {
    if (lead.assignedTelecallerName != null && lead.assignedTelecallerName!.trim().isNotEmpty) {
      return lead.assignedTelecallerName!.trim();
    }
    final rawTc = lead.rawJson['assigned_telecaller_name']?.toString().trim();
    if (rawTc != null && rawTc.isNotEmpty) {
      return rawTc;
    }
    final rawTc2 = lead.rawJson['_assigned_telecaller_name']?.toString().trim();
    if (rawTc2 != null && rawTc2.isNotEmpty) {
      return rawTc2;
    }
    final tcObjName = lead.rawJson['telecaller'] is Map ? lead.rawJson['telecaller']['full_name']?.toString().trim() : null;
    if (tcObjName != null && tcObjName.isNotEmpty) {
      return tcObjName;
    }
    final statusTc = lead.rawJson['status_updated_by_name']?.toString().trim();
    if (statusTc != null && statusTc.isNotEmpty) {
      return statusTc;
    }
    return 'Assigned Telecaller';
  }

  // Helper to check if lead is assigned to telecaller
  static bool isLeadAssignedToTelecaller(IntegrationLeadModel lead) {
    final hasTcName = lead.assignedTelecallerName != null && lead.assignedTelecallerName!.trim().isNotEmpty;
    final hasTcId = lead.assignedTelecallerId != null && lead.assignedTelecallerId!.trim().isNotEmpty;
    final rawTc = lead.rawJson['assigned_telecaller_name']?.toString().trim();
    final rawTc2 = lead.rawJson['_assigned_telecaller_name']?.toString().trim();
    final tcObjName = lead.rawJson['telecaller'] is Map ? lead.rawJson['telecaller']['full_name']?.toString().trim() : null;
    return hasTcName || hasTcId || (rawTc != null && rawTc.isNotEmpty) || (rawTc2 != null && rawTc2.isNotEmpty) || (tcObjName != null && tcObjName.isNotEmpty);
  }

  @override
  State<TelecallerAssignedLeadsPage> createState() => _TelecallerAssignedLeadsPageState();
}

class _TelecallerAssignedLeadsPageState extends State<TelecallerAssignedLeadsPage> {
  String? _selectedTelecaller;
  String _selectedLeadTypeTab = 'Property Listing'; // 'Property Listing' or 'Requirement'
  String _searchTelecallerQuery = '';
  String _searchLeadQuery = '';
  String _selectedStatusFilter = 'All';

  List<IntegrationLeadModel> get _assignedLeads {
    return widget.allSourceLeads.where(TelecallerAssignedLeadsPage.isLeadAssignedToTelecaller).toList();
  }

  Map<String, List<IntegrationLeadModel>> get _telecallerMap {
    final map = <String, List<IntegrationLeadModel>>{};
    for (final lead in _assignedLeads) {
      final tcName = TelecallerAssignedLeadsPage.extractTelecallerName(lead);
      map.putIfAbsent(tcName, () => []).add(lead);
    }
    return map;
  }

  Color get _sourceColor {
    final s = widget.sourceTitle.toLowerCase();
    if (s.contains('meta')) return const Color(0xFF1877F2);
    if (s.contains('housing')) return const Color(0xFFE11D48);
    return const Color(0xFF6366F1);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Campaign',
          onPressed: () {
            if (_selectedTelecaller != null) {
              setState(() {
                _selectedTelecaller = null;
                _searchLeadQuery = '';
                _selectedStatusFilter = 'All';
              });
            } else {
              Navigator.of(context).pop();
            }
          },
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
                _selectedTelecaller == null
                    ? '${widget.sourceTitle} · Leads Assigned to Telecallers (${widget.dateRangeLabel})'
                    : '$_selectedTelecaller · Assigned Leads (${widget.dateRangeLabel})',
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
                const Icon(Icons.assignment_ind_rounded, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${_assignedLeads.length} Total Assigned',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _selectedTelecaller == null
          ? _buildTelecallersListView(context)
          : _buildSelectedTelecallerDetailView(context),
    );
  }

  // --- VIEW 1: TELECALLERS LIST ---
  Widget _buildTelecallersListView(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final map = _telecallerMap;
    final query = _searchTelecallerQuery.trim().toLowerCase();
    final telecallerEntries = map.entries.where((e) {
      if (query.isEmpty) return true;
      return e.key.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    final totalAssigned = _assignedLeads.length;
    final propCount = _assignedLeads.where((l) => l.leadType == 'Property Listing').length;
    final reqCount = _assignedLeads.where((l) => l.leadType == 'Requirement').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics summary banner
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
                  title: 'Total Assigned (${widget.dateRangeLabel})',
                  count: totalAssigned,
                  color: _sourceColor,
                  icon: Icons.assignment_ind_rounded,
                ),
                _buildStatDivider(context),
                _buildSummaryStat(
                  context,
                  title: 'Active Telecallers',
                  count: map.length,
                  color: const Color(0xFF6366F1),
                  icon: Icons.groups_rounded,
                ),
                _buildStatDivider(context),
                _buildSummaryStat(
                  context,
                  title: 'Property Listing Leads',
                  count: propCount,
                  color: const Color(0xFF0284C7),
                  icon: Icons.home_work_rounded,
                ),
                _buildStatDivider(context),
                _buildSummaryStat(
                  context,
                  title: 'Requirement Leads',
                  count: reqCount,
                  color: const Color(0xFF10B981),
                  icon: Icons.people_alt_rounded,
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
                    'Showing leads assigned to telecallers from ${widget.sourceTitle} for date range: ${widget.dateRangeLabel}.',
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

          // Search and filter bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => setState(() => _searchTelecallerQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search telecallers by name...',
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CRMColors.borderOf(context)),
                ),
                child: Text(
                  '${telecallerEntries.length} Telecaller(s)',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (telecallerEntries.isEmpty) ...[
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
                  Icon(Icons.person_off_rounded, size: 48, color: CRMColors.textSecondaryOf(context)),
                  const SizedBox(height: 12),
                  Text(
                    query.isNotEmpty
                        ? 'No telecallers match "$query"'
                        : 'No leads from ${widget.sourceTitle} (${widget.dateRangeLabel}) are currently assigned to telecallers.',
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
            // Telecallers grid
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;
                final isMedium = constraints.maxWidth >= 600;
                final crossAxisCount = isWide ? 3 : (isMedium ? 2 : 1);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    mainAxisExtent: 155,
                  ),
                  itemCount: telecallerEntries.length,
                  itemBuilder: (context, index) {
                    final entry = telecallerEntries[index];
                    final tcName = entry.key;
                    final leads = entry.value;
                    final tcPropCount = leads.where((l) => l.leadType == 'Property Listing').length;
                    final tcReqCount = leads.where((l) => l.leadType == 'Requirement').length;

                    return _buildTelecallerCard(
                      context,
                      name: tcName,
                      totalLeads: leads.length,
                      propCount: tcPropCount,
                      reqCount: tcReqCount,
                      onTap: () {
                        setState(() {
                          _selectedTelecaller = tcName;
                          _searchLeadQuery = '';
                          _selectedStatusFilter = 'All';
                        });
                      },
                    );
                  },
                );
              },
            ),
          ],
        ],
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

  Widget _buildTelecallerCard(
    BuildContext context, {
    required String name,
    required int totalLeads,
    required int propCount,
    required int reqCount,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeManager().isDarkMode;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'T';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: CRMColors.borderOf(context)),
          boxShadow: CRMShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Avatar, Name, Total Badge
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _sourceColor.withValues(alpha: 0.15),
                  child: Text(
                    initial,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _sourceColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Telecaller',
                        style: TextStyle(
                          fontSize: 11,
                          color: CRMColors.textSecondaryOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _sourceColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalLeads Leads',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _sourceColor,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Divider(height: 1),
            const SizedBox(height: 10),
            // Row 2: Breakdown chips
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.home_work_rounded, size: 12, color: Color(0xFF0284C7)),
                        const SizedBox(width: 4),
                        Text(
                          'Property: $propCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_alt_rounded, size: 12, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'Req: $reqCount',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, size: 18, color: CRMColors.textSecondaryOf(context)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- VIEW 2: SELECTED TELECALLER LEADS WITH 2 TABS ---
  Widget _buildSelectedTelecallerDetailView(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final tcName = _selectedTelecaller!;
    final allTcLeads = _assignedLeads.where((l) => TelecallerAssignedLeadsPage.extractTelecallerName(l) == tcName).toList();

    final propLeads = allTcLeads.where((l) => l.leadType == 'Property Listing').toList();
    final reqLeads = allTcLeads.where((l) => l.leadType == 'Requirement').toList();

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
        final phone = lead.getStringValue('Phone Number').toLowerCase();
        final email = lead.getStringValue('Email').toLowerCase();
        final status = lead.campaignStatus.toLowerCase();
        final remarks = (lead.followupRemarks ?? lead.callbackRemarks ?? '').toLowerCase();
        if (!name.contains(query) &&
            !phone.contains(query) &&
            !email.contains(query) &&
            !status.contains(query) &&
            !remarks.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb & telecaller header banner
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
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedTelecaller = null;
                      _searchLeadQuery = '';
                      _selectedStatusFilter = 'All';
                    });
                  },
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('All Telecallers'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    side: BorderSide(color: CRMColors.borderOf(context)),
                  ),
                ),
                const SizedBox(width: 16),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _sourceColor.withValues(alpha: 0.15),
                  child: Text(
                    tcName.isNotEmpty ? tcName[0].toUpperCase() : 'T',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _sourceColor,
                    ),
                  ),
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
                              tcName,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: _sourceColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.sourceTitle,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _sourceColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${allTcLeads.length} Total Leads assigned from ${widget.sourceTitle} (${widget.dateRangeLabel})',
                        style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                      ),
                    ],
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
                    hintText: 'Search by client name, phone, email, notes...',
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
                    'No $_selectedLeadTypeTab Leads found for $tcName in ${widget.sourceTitle}.',
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
                color: isSelected ? activeColor.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04)),
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
    final name = lead.customerName.isNotEmpty
        ? lead.customerName
        : (lead.getStringValue('Client / Owner Name').isNotEmpty
            ? lead.getStringValue('Client / Owner Name')
            : 'Lead #${lead.id.length > 8 ? lead.id.substring(0, 8) : lead.id}');
    final phone = lead.getStringValue('Phone Number').isNotEmpty
        ? lead.getStringValue('Phone Number')
        : lead.getStringValue('Mobile');
    final email = lead.getStringValue('Email');
    final status = lead.campaignStatus.trim().isEmpty ? 'New' : lead.campaignStatus;
    final statusColor = _statusColor(status);
    final dateStr = DateFormat('d MMM y, h:mm a').format(lead.receivedAt);

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
              if (lead.allocationStatus != null && lead.allocationStatus!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    lead.allocationStatus!,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)),
                  ),
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
              (lead.callbackRemarks != null && lead.callbackRemarks!.isNotEmpty)) ...[
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
                      lead.followupRemarks ?? lead.callbackRemarks ?? '',
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

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s == 'new') return const Color(0xFF0284C7);
    if (s.contains('interested') && !s.contains('not')) return const Color(0xFF10B981);
    if (s.contains('follow') || s.contains('callback') || s.contains('call back')) return const Color(0xFFF59E0B);
    if (s.contains('cnr')) return const Color(0xFFD97706);
    if (s.contains('not interested')) return const Color(0xFFEF4444);
    if (s.contains('listed')) return const Color(0xFF059669);
    if (s.contains('archive')) return const Color(0xFF6366F1);
    return const Color(0xFF64748B);
  }

  void _showLeadCompleteDetailsDialog(BuildContext context, IntegrationLeadModel lead) {
    final name = lead.customerName.isNotEmpty
        ? lead.customerName
        : (lead.getStringValue('Client / Owner Name').isNotEmpty
            ? lead.getStringValue('Client / Owner Name')
            : 'Lead #${lead.id.length > 8 ? lead.id.substring(0, 8) : lead.id}');

    // Extract questionnaire
    final questions = <MapEntry<String, String>>[];
    for (final entry in lead.rawJson.entries) {
      final k = entry.key;
      final v = entry.value?.toString().trim() ?? '';
      if (v.isNotEmpty &&
          !k.startsWith('_') &&
          k != 'id' &&
          k != 'external_id' &&
          k != 'raw_json' &&
          k != 'meta_response') {
        questions.add(MapEntry(k, v));
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _sourceColor.withValues(alpha: 0.15),
              child: Icon(Icons.person_rounded, color: _sourceColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('Source: ${lead.source} · Type: ${lead.leadType}',
                      style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context))),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSectionHeader('Lead Information'),
                _buildDetailRow('Lead ID', lead.id),
                _buildDetailRow('Source', lead.source),
                _buildDetailRow('Lead Type', lead.leadType),
                _buildDetailRow('Status', lead.campaignStatus),
                _buildDetailRow('Received Date', DateFormat('d MMM y, h:mm a').format(lead.receivedAt)),
                if (lead.assignedTelecallerName != null)
                  _buildDetailRow('Assigned Telecaller', lead.assignedTelecallerName!),
                if (lead.telecallerAssignedAt != null)
                  _buildDetailRow('Assigned At', DateFormat('d MMM y, h:mm a').format(lead.telecallerAssignedAt!)),

                const SizedBox(height: 14),
                _buildDetailSectionHeader('Form Data & Questionnaire (${questions.length})'),
                if (questions.isEmpty)
                  Text('No custom form answers attached.',
                      style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)))
                else
                  ...questions.map((q) => _buildDetailRow(q.key, q.value)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

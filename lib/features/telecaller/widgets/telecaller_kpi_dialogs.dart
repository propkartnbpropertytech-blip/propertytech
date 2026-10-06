import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:propkart/core/design_system/tokens/app_colors.dart';
import 'package:propkart/core/theme/theme_manager.dart';

import '../../dashboard/models/kpi_models.dart';
import '../../dashboard/widgets/kpi_drilldown_dialogs.dart';
import '../../campaign/models/campaign_followup_model.dart';
import '../../integration/services/integration_service.dart';
import '../../integration/models/integration_lead_model.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/telecaller_repository.dart';

class TelecallerKpiDialogs {
  /// Opens Drilldown modal for a Telecaller KPI category
  static Future<void> showKpiLeadsDrilldown(
    BuildContext context, {
    required String category,
    required String title,
    String? salesUserId,
    String? salesUserName,
    required String dateFilter,
    String? startDate,
    String? endDate,
    required String leadType,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => TelecallerKpiLeadsDialog(
        category: category,
        title: title,
        salesUserId: salesUserId,
        salesUserName: salesUserName,
        dateFilter: dateFilter,
        startDate: startDate,
        endDate: endDate,
        leadType: leadType,
      ),
    );
  }

  /// Opens Open Leads drilldown modal
  static Future<void> showOpenLeadsDrilldown(
    BuildContext context, {
    required String dateFilter,
    String? startDate,
    String? endDate,
    required String leadType,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => TelecallerOpenLeadsDialog(
        dateFilter: dateFilter,
        startDate: startDate,
        endDate: endDate,
        leadType: leadType,
      ),
    );
  }

  /// Opens Archive Leads drilldown modal with two separate tabs: Property Listing & Requirement
  static Future<void> showArchiveLeadsDrilldown(
    BuildContext context, {
    required String dateFilter,
    String? startDate,
    String? endDate,
    required String leadType,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => TelecallerArchiveLeadsDialog(
        dateFilter: dateFilter,
        startDate: startDate,
        endDate: endDate,
        leadType: leadType,
      ),
    );
  }

  /// Opens Follow-ups drilldown modal
  static Future<void> showFollowupsDrilldown(
    BuildContext context, {
    required List<CampaignFollowupModel> followups,
    required String dateFilter,
    String? startDate,
    String? endDate,
    required String leadType,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => TelecallerFollowupsDialog(
        followups: followups,
        dateFilter: dateFilter,
        startDate: startDate,
        endDate: endDate,
        leadType: leadType,
      ),
    );
  }

  /// Opens Sales Users breakdown modal
  static Future<void> showSalesUsersBreakdown(
    BuildContext context, {
    required String dateFilter,
    String? startDate,
    String? endDate,
    required String leadType,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => TelecallerSalesUsersDialog(
        dateFilter: dateFilter,
        startDate: startDate,
        endDate: endDate,
        leadType: leadType,
      ),
    );
  }

  static Widget buildLeadCardItem(
    BuildContext context,
    LeadListItem lead,
    bool isDark,
    Color primaryColor,
  ) {
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final isListing = lead.leadType.toLowerCase().contains('listing');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        KpiDrilldownDialogs.showLeadDetails(context, lead: lead);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Client Name, Lead Type Badge, Details chevron
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          lead.customerName.isNotEmpty ? lead.customerName : 'Lead (${lead.phone})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isListing
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          lead.leadType,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isListing ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 6),

            // Second Row: Phone, Locality, Configuration, Budget
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (lead.phone.isNotEmpty)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: lead.phone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied ${lead.phone} to clipboard'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(
                          lead.phone,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (lead.configuration != null && lead.configuration!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home_outlined, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        lead.configuration!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                if (lead.locality != null && lead.locality!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        lead.locality!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                if (lead.budgetDisplay != null && lead.budgetDisplay!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.currency_rupee, size: 13, color: primaryColor),
                      Text(
                        lead.budgetDisplay!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Third Row: Category / Allocation Badges & Salesperson info
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (lead.salesUserName != null && lead.salesUserName!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined, size: 12, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned to Sales: ${lead.salesUserName}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (lead.rejectionReason != null && lead.rejectionReason!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Reason: ${lead.rejectionReason}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                if (lead.archiveReason != null && lead.archiveReason!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Archive: ${lead.archiveReason}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ),
                if (lead.stage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Stage: ${lead.stage}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                Text(
                  'Date: ${_formatLeadDate(lead.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),

            // Optional: Remarks Preview
            if ((lead.telecallerRemarks != null && lead.telecallerRemarks!.trim().isNotEmpty) ||
                (lead.transferRemarks != null && lead.transferRemarks!.trim().isNotEmpty)) ...[
              const SizedBox(height: 4),
              Text(
                'Remark: ${lead.telecallerRemarks ?? lead.transferRemarks}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatLeadDate(String? dtStr) {
    if (dtStr == null || dtStr.isEmpty) return '-';
    final dt = DateTime.tryParse(dtStr);
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy, h:mm a').format(dt.toLocal());
  }
}

class TelecallerKpiLeadsDialog extends StatefulWidget {
  final String category;
  final String title;
  final String? salesUserId;
  final String? salesUserName;
  final String dateFilter;
  final String? startDate;
  final String? endDate;
  final String leadType;

  const TelecallerKpiLeadsDialog({
    super.key,
    required this.category,
    required this.title,
    this.salesUserId,
    this.salesUserName,
    required this.dateFilter,
    this.startDate,
    this.endDate,
    required this.leadType,
  });

  @override
  State<TelecallerKpiLeadsDialog> createState() => _TelecallerKpiLeadsDialogState();
}

class _TelecallerKpiLeadsDialogState extends State<TelecallerKpiLeadsDialog> {
  final TelecallerRepository _repository = TelecallerRepository();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<LeadListItem> _leads = [];
  int _total = 0;
  int _page = 1;
  static const int _limit = 20;
  bool _loading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeads() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _repository.getKpiLeads(
        category: widget.category,
        salesUserId: widget.salesUserId,
        dateFilter: widget.dateFilter,
        startDate: widget.startDate,
        endDate: widget.endDate,
        leadType: widget.leadType,
        page: _page,
        limit: _limit,
        search: _searchQuery,
      );
      if (mounted) {
        final rawLeads = res['leads'] as List? ?? [];
        final parsed = rawLeads
            .map((e) => LeadListItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        setState(() {
          _leads = parsed;
          _total = (res['total'] as num?)?.toInt() ?? 0;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() {
          _searchQuery = val.trim();
          _page = 1;
        });
        _fetchLeads();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final totalPages = (_total <= 0 ? 1 : (_total / _limit).ceil());
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 32,
        vertical: isPhone ? 16 : 28,
      ),
      child: Container(
        width: 780,
        height: 680,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.leaderboard_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Date: ${widget.dateFilter}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Type: ${widget.leadType}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          if (widget.salesUserName != null && widget.salesUserName!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Salesperson: ${widget.salesUserName}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 2. Search & Info Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by client name, phone, email, salesperson...',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_total Leads',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 3. Leads List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _leads.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No leads matching "$_searchQuery".'
                                    : 'No leads found for this filter.',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _leads.length,
                          separatorBuilder: (context, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final lead = _leads[index];
                            return _buildLeadItemCard(context, lead, isDark, primaryColor);
                          },
                        ),
            ),
            const SizedBox(height: 12),

            // 4. Footer Pagination
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _total > 0
                      ? 'Showing ${(_page - 1) * _limit + 1}–${((_page - 1) * _limit + _leads.length)} of $_total'
                      : '0 leads',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _page > 1
                          ? () {
                              setState(() => _page--);
                              _fetchLeads();
                            }
                          : null,
                      child: const Row(
                        children: [
                          Icon(Icons.chevron_left_rounded, size: 16),
                          Text('Prev', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$_page / $totalPages',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _page < totalPages
                          ? () {
                              setState(() => _page++);
                              _fetchLeads();
                            }
                          : null,
                      child: const Row(
                        children: [
                          Text('Next', style: TextStyle(fontSize: 12)),
                          Icon(Icons.chevron_right_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadItemCard(
    BuildContext context,
    LeadListItem lead,
    bool isDark,
    Color primaryColor,
  ) => TelecallerKpiDialogs.buildLeadCardItem(context, lead, isDark, primaryColor);
}

class TelecallerSalesUsersDialog extends StatefulWidget {
  final String dateFilter;
  final String? startDate;
  final String? endDate;
  final String leadType;

  const TelecallerSalesUsersDialog({
    super.key,
    required this.dateFilter,
    this.startDate,
    this.endDate,
    required this.leadType,
  });

  @override
  State<TelecallerSalesUsersDialog> createState() => _TelecallerSalesUsersDialogState();
}

class _TelecallerSalesUsersDialogState extends State<TelecallerSalesUsersDialog> {
  final TelecallerRepository _repository = TelecallerRepository();
  List<Map<String, dynamic>> _salesUsers = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchSalesUsers();
  }

  Future<void> _fetchSalesUsers() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final res = await _repository.getSalesUsersBreakdown(
        dateFilter: widget.dateFilter,
        startDate: widget.startDate,
        endDate: widget.endDate,
        leadType: widget.leadType,
      );
      if (mounted) {
        final list = List<Map<String, dynamic>>.from(
          (res['sales_users'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        setState(() {
          _salesUsers = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 32,
        vertical: isPhone ? 16 : 28,
      ),
      child: Container(
        width: 600,
        height: 580,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.badge_outlined, color: Color(0xFF8B5CF6), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sales Users',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Salespersons who received leads from you',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter context tags
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Date: ${widget.dateFilter}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Type: ${widget.leadType}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F3FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_salesUsers.length} Salespersons',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Sales Users List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _salesUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                'No leads assigned to any salesperson for this filter.',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _salesUsers.length,
                          separatorBuilder: (context, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final su = _salesUsers[index];
                            final name = (su['sales_user_name'] ?? 'Salesperson').toString();
                            final email = (su['sales_user_email'] ?? '').toString();
                            final phone = (su['sales_user_phone'] ?? '').toString();
                            final count = (su['lead_count'] as num?)?.toInt() ?? 0;
                            final salesUserId = (su['sales_user_id'] ?? '').toString();

                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                // Open exact leads assigned to this salesperson
                                TelecallerKpiDialogs.showKpiLeadsDrilldown(
                                  context,
                                  category: 'assigned_to_sales',
                                  title: 'Leads Assigned to $name',
                                  salesUserId: salesUserId,
                                  salesUserName: name,
                                  dateFilter: widget.dateFilter,
                                  startDate: widget.startDate,
                                  endDate: widget.endDate,
                                  leadType: widget.leadType,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                      child: Text(
                                        name.isNotEmpty ? name[0].toUpperCase() : 'S',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF7C3AED),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            phone.isNotEmpty ? '$phone • $email' : (email.isNotEmpty ? email : 'Sales User'),
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '$count Leads',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey.shade400),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class TelecallerFollowupsDialog extends StatefulWidget {
  final List<CampaignFollowupModel> followups;
  final String dateFilter;
  final String? startDate;
  final String? endDate;
  final String leadType;

  const TelecallerFollowupsDialog({
    super.key,
    required this.followups,
    required this.dateFilter,
    this.startDate,
    this.endDate,
    required this.leadType,
  });

  @override
  State<TelecallerFollowupsDialog> createState() => _TelecallerFollowupsDialogState();
}

class _TelecallerFollowupsDialogState extends State<TelecallerFollowupsDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeTab = 'all'; // 'all', 'today', 'upcoming', 'overdue'
  List<CampaignFollowupModel> _followupList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _followupList = List.from(widget.followups);
    if (_followupList.isEmpty) {
      _loadFreshFollowups();
    }
  }

  Future<void> _loadFreshFollowups() async {
    setState(() => _isLoading = true);
    try {
      final list = await IntegrationService().getUnifiedFollowups(forceRefresh: true);
      if (mounted) {
        setState(() {
          _followupList = list;
          _isLoading = false;
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

  bool _matchesLeadType(CampaignFollowupModel f) {
    if (widget.leadType == 'Both') return true;
    final lt = f.leadType.toLowerCase();
    if (widget.leadType == 'Listing') {
      return lt.contains('listing') || lt.contains('property');
    }
    if (widget.leadType == 'Requirement') {
      return lt.contains('requirement');
    }
    return true;
  }

  bool _matchesDateFilter(DateTime dt) {
    final filter = widget.dateFilter.trim().toLowerCase();
    final now = DateTime.now();
    final local = dt.toLocal();
    if (filter == 'today') {
      return local.year == now.year && local.month == now.month && local.day == now.day;
    } else if (filter == 'weekly') {
      final start = now.subtract(const Duration(days: 7));
      return !local.isBefore(start) && !local.isAfter(now.add(const Duration(days: 1)));
    } else if (filter == 'monthly' || filter == 'this month') {
      return local.year == now.year && local.month == now.month;
    } else if (filter == 'yearly' || filter == 'this year') {
      return local.year == now.year;
    } else if (filter == 'custom' || filter == 'custom range') {
      if (widget.startDate != null && widget.endDate != null) {
        final s = DateTime.tryParse(widget.startDate!);
        final e = DateTime.tryParse('${widget.endDate!} 23:59:59');
        if (s != null && e != null) {
          return !local.isBefore(s) && !local.isAfter(e);
        }
      }
    }
    return true;
  }

  List<CampaignFollowupModel> get _allScopedFollowups {
    final source = _followupList.isNotEmpty ? _followupList : widget.followups;
    return source.where((f) {
      if (!_matchesLeadType(f)) return false;
      return true;
    }).toList();
  }

  List<CampaignFollowupModel> get _filteredFollowups {
    var list = _allScopedFollowups;

    if (_activeTab == 'today') {
      list = list.where((f) => f.isToday).toList();
    } else if (_activeTab == 'upcoming') {
      list = list.where((f) => f.isFuture).toList();
    } else if (_activeTab == 'overdue') {
      list = list.where((f) => f.isPast && !f.isToday).toList();
    } else if (widget.dateFilter.toLowerCase() != 'all') {
      // By default in 'all' tab, respect date filter if user has chosen a specific filter
      list = list.where((f) => _matchesDateFilter(f.scheduledAt)).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final cleanQ = q.replaceAll(RegExp(r'\D'), '');
      list = list.where((f) {
        final name = f.clientName.toLowerCase();
        final phone = f.mobile.replaceAll(RegExp(r'\D'), '');
        final remarks = f.remarks.toLowerCase();
        final lt = f.leadType.toLowerCase();
        return name.contains(q) ||
            remarks.contains(q) ||
            lt.contains(q) ||
            (cleanQ.isNotEmpty && phone.contains(cleanQ));
      }).toList();
    }

    return list;
  }

  Widget _buildTabChip(String label, String tabKey, int count) {
    final isSelected = _activeTab == tabKey;
    const activeColor = Color(0xFFD97706);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _activeTab = tabKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
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
    final allScoped = _allScopedFollowups;
    final filtered = _filteredFollowups;
    final totalCount = allScoped.length;
    final todayCount = allScoped.where((f) => f.isToday).length;
    final upcomingCount = allScoped.where((f) => f.isFuture).length;
    final overdueCount = allScoped.where((f) => f.isPast && !f.isToday).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        width: 720,
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Follow-Up Leads',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${filtered.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Showing scheduled follow-ups matching active filters (${widget.leadType} leads)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.go('/campaign/leads?view=followups');
                    },
                    icon: const Icon(Icons.open_in_new_rounded, size: 15),
                    label: const Text('Open in My Calling Leads', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Filter Tabs & Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim()),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search by client name, phone, or remarks...',
                            hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                            prefixIcon: const Icon(Icons.search_rounded, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTabChip('All Follow-ups', 'all', totalCount),
                        const SizedBox(width: 8),
                        _buildTabChip('Today', 'today', todayCount),
                        const SizedBox(width: 8),
                        _buildTabChip('Upcoming', 'upcoming', upcomingCount),
                        const SizedBox(width: 8),
                        _buildTabChip('Overdue', 'overdue', overdueCount),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Follow-ups List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No follow-ups matching "$_searchQuery"'
                                : 'No follow-ups in this view',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Try clearing your search query.'
                                : 'Schedule follow-ups from the Calling Leads section.',
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final fu = filtered[i];
                        final formattedTime = DateFormat('EEE, d MMM • h:mm a').format(fu.scheduledAt);
                        final isListing = fu.leadType.toLowerCase().contains('property') || fu.leadType.toLowerCase().contains('listing');

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: const Color(0xFFFEF3C7),
                                    child: const Icon(Icons.schedule_rounded, color: Color(0xFFD97706), size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                fu.clientName.isNotEmpty ? fu.clientName : 'Client',
                                                style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (fu.isToday)
                                              Container(
                                                margin: const EdgeInsets.only(left: 6),
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF3C7),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Text(
                                                  'Today',
                                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: isListing ? const Color(0xFFFEF3C7) : const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                fu.leadType,
                                                style: TextStyle(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: isListing ? const Color(0xFFD97706) : const Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.calendar_month_outlined, size: 12, color: Colors.grey.shade500),
                                                const SizedBox(width: 4),
                                                Text(
                                                  formattedTime,
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                                ),
                                              ],
                                            ),
                                            if (fu.mobile.isNotEmpty)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.phone_outlined, size: 12, color: Colors.grey.shade500),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    fu.mobile,
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quick contact actions
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (fu.mobile.isNotEmpty) ...[
                                        IconButton(
                                          icon: const Icon(Icons.phone_forwarded, size: 18, color: Color(0xFF059669)),
                                          tooltip: 'Call ${fu.mobile}',
                                          visualDensity: VisualDensity.compact,
                                          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                          onPressed: () async {
                                            final uri = Uri.parse('tel:${fu.mobile}');
                                            if (await canLaunchUrl(uri)) await launchUrl(uri);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.chat_outlined, size: 18, color: Color(0xFF25D366)),
                                          tooltip: 'WhatsApp',
                                          visualDensity: VisualDensity.compact,
                                          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
                                          onPressed: () async {
                                            final clean = fu.mobile.replaceAll(RegExp(r'\D'), '');
                                            final uri = Uri.parse('https://wa.me/$clean');
                                            if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                              if (fu.remarks.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '“${fu.remarks}”',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? Colors.grey.shade300 : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

LeadListItem _leadModelToListItem(IntegrationLeadModel l) {
  final phone = l.getStringValue('Phone Number').isNotEmpty
      ? l.getStringValue('Phone Number')
      : (l.rawJson['phone_number'] ?? l.rawJson['phone'] ?? '').toString();
  final email = l.getStringValue('Email ID').isNotEmpty
      ? l.getStringValue('Email ID')
      : (l.rawJson['email'] ?? '').toString();
  final conf = l.getStringValue('Configuration');
  final loc = l.getStringValue('Location').isNotEmpty
      ? l.getStringValue('Location')
      : l.getStringValue('Locality');
  final budget = l.getStringValue('Budget');

  return LeadListItem(
    id: l.id,
    customerName: l.customerName.isNotEmpty ? l.customerName : (phone.isNotEmpty ? 'Lead ($phone)' : 'Lead'),
    phone: phone,
    sanitizedPhone: phone,
    email: email.isNotEmpty ? email : null,
    sanitizedEmail: email.isNotEmpty ? email : null,
    source: l.source.isNotEmpty ? l.source : 'Other',
    leadType: l.leadType,
    stage: l.campaignStatus.isNotEmpty ? l.campaignStatus : 'NEW',
    allocationStatus: l.allocationStatus,
    archiveReason: l.displayArchiveRemark,
    telecallerRemarks: l.followupRemarks ?? l.callbackRemarks,
    transferRemarks: l.transferRemarks,
    configuration: conf.isNotEmpty ? conf : null,
    locality: loc.isNotEmpty ? loc : null,
    budgetDisplay: budget.isNotEmpty ? budget : null,
    createdAt: l.receivedAt.toIso8601String(),
    updatedAt: (l.statusUpdatedAt ?? l.receivedAt).toIso8601String(),
    telecallerId: l.assignedTelecallerId,
    telecallerName: l.assignedTelecallerName,
    rawJson: l.rawJson,
  );
}

bool _isLeadArchived(IntegrationLeadModel l) {
  if (l.archivedAt != null) return true;
  if (l.rawJson['archived_at'] != null && l.rawJson['archived_at'].toString().trim().isNotEmpty) return true;
  final s = l.campaignStatus.trim().toLowerCase();
  if (s == 'archived' || s == 'property listed' || s == 'listed') return true;
  if (l.importStatus.trim().toLowerCase() == 'archived') return true;
  return false;
}

bool _isOpenUntouchedLead(IntegrationLeadModel l) {
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

class TelecallerOpenLeadsDialog extends StatefulWidget {
  final String dateFilter;
  final String? startDate;
  final String? endDate;
  final String leadType;

  const TelecallerOpenLeadsDialog({
    super.key,
    required this.dateFilter,
    this.startDate,
    this.endDate,
    required this.leadType,
  });

  @override
  State<TelecallerOpenLeadsDialog> createState() => _TelecallerOpenLeadsDialogState();
}

class _TelecallerOpenLeadsDialogState extends State<TelecallerOpenLeadsDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _loading = false;
  int _page = 1;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    if (IntegrationService().leads.isEmpty) {
      _loadLeads();
    }
  }

  Future<void> _loadLeads() async {
    setState(() => _loading = true);
    try {
      await IntegrationService().fetchServerLeads(silent: true);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<IntegrationLeadModel> get _allOpenLeads {
    final valid = IntegrationService().leads.where((l) => _isOpenUntouchedLead(l)).toList();
    return valid.where((l) {
      final isListing = l.leadType.toLowerCase().contains('listing') || l.leadType.toLowerCase().contains('property');
      if (widget.leadType == 'Listing') return isListing;
      if (widget.leadType == 'Requirement') return !isListing;
      return true;
    }).toList();
  }

  List<IntegrationLeadModel> get _filteredLeads {
    final list = _allOpenLeads;
    if (_searchQuery.isEmpty) return list;
    final q = _searchQuery.toLowerCase();
    return list.where((l) {
      final name = l.customerName.toLowerCase();
      final phone = l.getStringValue('Phone Number').toLowerCase();
      final source = l.source.toLowerCase();
      return name.contains(q) || phone.contains(q) || source.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    final openLeads = _filteredLeads;
    final total = openLeads.length;
    final totalPages = (total <= 0 ? 1 : (total / _limit).ceil());
    final startIndex = ((_page - 1) * _limit).clamp(0, total);
    final endIndex = (startIndex + _limit).clamp(0, total);
    final pageLeads = total > 0 ? openLeads.sublist(startIndex, endIndex) : <IntegrationLeadModel>[];

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 32,
        vertical: isPhone ? 16 : 28,
      ),
      child: Container(
        width: 820,
        height: 700,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.folder_open_rounded, color: Color(0xFF3B82F6), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Open Leads',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_allOpenLeads.length} Leads',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Untouched leads waiting for interaction (${widget.leadType} leads)',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go('/campaign/leads');
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: const Text('Open in My Calling Leads', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {
                _searchQuery = val.trim();
                _page = 1;
              }),
              decoration: InputDecoration(
                hintText: 'Search by client name, phone number, source...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _page = 1;
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Leads list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : total == 0
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_rounded, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No open leads matching "$_searchQuery".'
                                    : 'No open untouched leads.',
                                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: pageLeads.length,
                          separatorBuilder: (context, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final lead = pageLeads[index];
                            return TelecallerKpiDialogs.buildLeadCardItem(
                              context,
                              _leadModelToListItem(lead),
                              isDark,
                              primaryColor,
                            );
                          },
                        ),
            ),
            const SizedBox(height: 10),

            // Pagination
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  total > 0 ? 'Showing ${startIndex + 1}–$endIndex of $total' : '0 leads',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _page > 1
                          ? () => setState(() => _page--)
                          : null,
                      child: const Row(
                        children: [
                          Icon(Icons.chevron_left_rounded, size: 16),
                          Text('Prev', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '$_page / $totalPages',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: const Size(0, 32),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _page < totalPages
                          ? () => setState(() => _page++)
                          : null,
                      child: const Row(
                        children: [
                          Text('Next', style: TextStyle(fontSize: 12)),
                          Icon(Icons.chevron_right_rounded, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TelecallerArchiveLeadsDialog extends StatefulWidget {
  final String dateFilter;
  final String? startDate;
  final String? endDate;
  final String leadType;

  const TelecallerArchiveLeadsDialog({
    super.key,
    required this.dateFilter,
    this.startDate,
    this.endDate,
    required this.leadType,
  });

  @override
  State<TelecallerArchiveLeadsDialog> createState() => _TelecallerArchiveLeadsDialogState();
}

class _TelecallerArchiveLeadsDialogState extends State<TelecallerArchiveLeadsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _loading = false;
  int _listingPage = 1;
  int _requirementPage = 1;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.leadType == 'Requirement' ? 1 : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    if (IntegrationService().leads.isEmpty) {
      _loadLeads();
    }
  }

  Future<void> _loadLeads() async {
    setState(() => _loading = true);
    try {
      await IntegrationService().fetchServerLeads(silent: true);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<IntegrationLeadModel> get _allArchivedLeads {
    return IntegrationService().leads.where((l) => _isLeadArchived(l)).toList();
  }

  List<IntegrationLeadModel> get _listingArchivedLeads {
    return _allArchivedLeads.where((l) {
      final lt = l.leadType.toLowerCase();
      return lt.contains('listing') || lt.contains('property');
    }).toList();
  }

  List<IntegrationLeadModel> get _requirementArchivedLeads {
    return _allArchivedLeads.where((l) {
      final lt = l.leadType.toLowerCase();
      return !lt.contains('listing') && !lt.contains('property');
    }).toList();
  }

  List<IntegrationLeadModel> _applySearch(List<IntegrationLeadModel> leads) {
    if (_searchQuery.isEmpty) return leads;
    final q = _searchQuery.toLowerCase();
    return leads.where((l) {
      final name = l.customerName.toLowerCase();
      final phone = l.getStringValue('Phone Number').toLowerCase();
      final remark = (l.displayArchiveRemark ?? '').toLowerCase();
      final status = l.campaignStatus.toLowerCase();
      final source = l.source.toLowerCase();
      return name.contains(q) ||
          phone.contains(q) ||
          remark.contains(q) ||
          status.contains(q) ||
          source.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;
    final isPhone = MediaQuery.sizeOf(context).width < 600;

    final allListing = _listingArchivedLeads;
    final allRequirement = _requirementArchivedLeads;
    final filteredListing = _applySearch(allListing);
    final filteredRequirement = _applySearch(allRequirement);

    final totalCombined = allListing.length + allRequirement.length;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 32,
        vertical: isPhone ? 16 : 28,
      ),
      child: Container(
        width: 820,
        height: 700,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64748B).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.archive_outlined, color: Color(0xFF64748B), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Archived Leads',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64748B).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$totalCombined Total',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Combined archive of Property Listing and Requirement Leads',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    final view = _tabController.index == 0 ? 'archive_listed' : 'archive_requirements';
                    context.go('/campaign/leads?view=$view');
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 15),
                  label: const Text('Open in My Calling Leads', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // TabBar with 2 tabs
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
              indicatorColor: primaryColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13.5),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home_work_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('Property Listing Leads (${allListing.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_search_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text('Requirement Leads (${allRequirement.length})'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Search bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() {
                _searchQuery = val.trim();
                _listingPage = 1;
                _requirementPage = 1;
              }),
              decoration: InputDecoration(
                hintText: 'Search by client name, phone number, archive remarks...',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _listingPage = 1;
                            _requirementPage = 1;
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // TabBarView
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabContent(context, filteredListing, isListingTab: true, isDark: isDark, primaryColor: primaryColor),
                        _buildTabContent(context, filteredRequirement, isListingTab: false, isDark: isDark, primaryColor: primaryColor),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    List<IntegrationLeadModel> leads, {
    required bool isListingTab,
    required bool isDark,
    required Color primaryColor,
  }) {
    final page = isListingTab ? _listingPage : _requirementPage;
    final total = leads.length;
    final totalPages = (total <= 0 ? 1 : (total / _limit).ceil());
    final startIndex = ((page - 1) * _limit).clamp(0, total);
    final endIndex = (startIndex + _limit).clamp(0, total);
    final pageLeads = total > 0 ? leads.sublist(startIndex, endIndex) : <IntegrationLeadModel>[];

    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No archived leads matching "$_searchQuery".'
                  : (isListingTab ? 'No archived Property Listing leads.' : 'No archived Requirement leads.'),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: pageLeads.length,
            separatorBuilder: (context, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final lead = pageLeads[index];
              return TelecallerKpiDialogs.buildLeadCardItem(
                context,
                _leadModelToListItem(lead),
                isDark,
                primaryColor,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Pagination
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              total > 0 ? 'Showing ${startIndex + 1}–$endIndex of $total' : '0 leads',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
              ),
            ),
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: page > 1
                      ? () {
                          setState(() {
                            if (isListingTab) {
                              _listingPage--;
                            } else {
                              _requirementPage--;
                            }
                          });
                        }
                      : null,
                  child: const Row(
                    children: [
                      Icon(Icons.chevron_left_rounded, size: 16),
                      Text('Prev', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '$page / $totalPages',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: const Size(0, 32),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: page < totalPages
                      ? () {
                          setState(() {
                            if (isListingTab) {
                              _listingPage++;
                            } else {
                              _requirementPage++;
                            }
                          });
                        }
                      : null,
                  child: const Row(
                    children: [
                      Text('Next', style: TextStyle(fontSize: 12)),
                      Icon(Icons.chevron_right_rounded, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

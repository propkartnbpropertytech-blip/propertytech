import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_manager.dart';
import '../services/dashboard_service.dart';

/// Modal dialog that visualizes the multi-table pipeflow derivation
/// and displays the authoritative leads list for any pipeline stage or sales agent.
class PipelineStageDrilldownDialog extends StatefulWidget {
  final String? stage;
  final String? stageLabel;
  final String? salesUserId;
  final String? salesUserName;
  final Map<String, dynamic>? initialFilters;

  const PipelineStageDrilldownDialog({
    super.key,
    this.stage,
    this.stageLabel,
    this.salesUserId,
    this.salesUserName,
    this.initialFilters,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    String? stage,
    String? stageLabel,
    String? salesUserId,
    String? salesUserName,
    Map<String, dynamic>? initialFilters,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PipelineStageDrilldownDialog(
        stage: stage,
        stageLabel: stageLabel,
        salesUserId: salesUserId,
        salesUserName: salesUserName,
        initialFilters: initialFilters,
      ),
    );
  }

  @override
  State<PipelineStageDrilldownDialog> createState() =>
      _PipelineStageDrilldownDialogState();
}

class _PipelineStageDrilldownDialogState
    extends State<PipelineStageDrilldownDialog> {
  final DashboardService _service = DashboardService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _data = {};
  int _currentPage = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeads() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final dateFilter = widget.initialFilters?['dateFilter'] ?? 'All Time';
      final startDate = widget.initialFilters?['startDate'];
      final endDate = widget.initialFilters?['endDate'];
      final leadType = widget.initialFilters?['leadType'] ?? 'Both';

      final res = await _service.getLifecycleLeads(
        stage: widget.stage,
        salesUserId: widget.salesUserId,
        leadType: leadType,
        dateFilter: dateFilter,
        startDate: startDate,
        endDate: endDate,
        page: _currentPage,
        limit: _limit,
        search: _searchController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _data = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  static Color _parseColor(dynamic rawColor) {
    if (rawColor is Color) return rawColor;
    if (rawColor is String && rawColor.startsWith('#')) {
      final hex = rawColor.replaceFirst('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }
    return const Color(0xFF3B82F6);
  }

  static IconData _parseIcon(dynamic rawIcon) {
    final name = rawIcon?.toString() ?? '';
    switch (name) {
      case 'inbox_rounded':
        return Icons.inbox_rounded;
      case 'phone_missed_rounded':
        return Icons.phone_missed_rounded;
      case 'phone_callback_rounded':
        return Icons.phone_callback_rounded;
      case 'sync_rounded':
        return Icons.sync_rounded;
      case 'handshake_rounded':
        return Icons.handshake_rounded;
      case 'assignment_late_rounded':
        return Icons.assignment_late_rounded;
      case 'verified_rounded':
        return Icons.verified_rounded;
      case 'cancel_outlined':
        return Icons.cancel_outlined;
      case 'real_estate_agent_rounded':
        return Icons.real_estate_agent_rounded;
      case 'person_rounded':
        return Icons.person_rounded;
      default:
        return Icons.account_tree_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final rawColor = _data['color'] ?? '#3B82F6';
    final stageColor = _parseColor(rawColor);
    final stageIcon = _parseIcon(_data['icon']);
    final stageLabel = _data['stage_label'] ??
        widget.stageLabel ??
        widget.salesUserName ??
        widget.stage ??
        'Pipeline Stage';
    final stageDescription = _data['stage_description'] ??
        'Database-authoritative pipeline lead records.';
    final totalCount = (_data['total_count'] as num?)?.toInt() ?? 0;
    final totalPages = (_data['total_pages'] as num?)?.toInt() ?? 1;
    final pipeflow = (_data['pipeflow'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    final leads = (_data['leads'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 1200 ? 1120.0 : (screenWidth * 0.95);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 820),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Bar
            _buildHeader(
              stageLabel: stageLabel,
              stageDescription: stageDescription,
              totalCount: totalCount,
              stageColor: stageColor,
              stageIcon: stageIcon,
              textColor: textColor,
              subColor: subColor,
              borderColor: borderColor,
              isDark: isDark,
            ),

            // Content Area
            Expanded(
              child: _isLoading && _data.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : _errorMessage.isNotEmpty
                      ? _buildErrorView(textColor, subColor)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Pipeflow Derivation Section
                              if (pipeflow.isNotEmpty) ...[
                                _buildPipeflowVisualizer(
                                  pipeflow: pipeflow,
                                  accentColor: stageColor,
                                  isDark: isDark,
                                  borderColor: borderColor,
                                  textColor: textColor,
                                  subColor: subColor,
                                ),
                                const SizedBox(height: 18),
                              ],

                              // Search & Lead Table Controls
                              _buildSearchAndFiltersBar(
                                textColor: textColor,
                                subColor: subColor,
                                borderColor: borderColor,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 14),

                              // Leads Data Table
                              _buildLeadsTable(
                                leads: leads,
                                textColor: textColor,
                                subColor: subColor,
                                borderColor: borderColor,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),

                              // Pagination Controls
                              if (totalPages > 1)
                                _buildPagination(
                                  currentPage: _currentPage,
                                  totalPages: totalPages,
                                  totalCount: totalCount,
                                  textColor: textColor,
                                  subColor: subColor,
                                  borderColor: borderColor,
                                  isDark: isDark,
                                ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String stageLabel,
    required String stageDescription,
    required int totalCount,
    required Color stageColor,
    required IconData stageIcon,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: stageColor.withValues(alpha: isDark ? 0.08 : 0.04),
        border: Border(bottom: BorderSide(color: borderColor)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: stageColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(stageIcon, color: stageColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        stageLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: stageColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalCount Leads',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  stageDescription,
                  style: TextStyle(fontSize: 12.5, color: subColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh_rounded, size: 20, color: subColor),
            onPressed: _fetchLeads,
          ),
          IconButton(
            tooltip: 'Close',
            icon: Icon(Icons.close_rounded, size: 22, color: subColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPipeflowVisualizer({
    required List<Map<String, dynamic>> pipeflow,
    required Color accentColor,
    required bool isDark,
    required Color borderColor,
    required Color textColor,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hub_rounded, size: 16, color: accentColor),
              const SizedBox(width: 6),
              Text(
                'MULTI-TABLE PIPEFLOW DERIVATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Text(
                'Guarantees 100% Normalized Mapping',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: subColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(pipeflow.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24, left: 6, right: 6),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: accentColor.withValues(alpha: 0.6),
                        ),
                      );
                    }
                    final stepIndex = index ~/ 2;
                    final step = pipeflow[stepIndex];
                    return Expanded(
                      child: _buildPipeflowStepCard(
                        step: step,
                        accentColor: accentColor,
                        isDark: isDark,
                        borderColor: borderColor,
                        textColor: textColor,
                        subColor: subColor,
                      ),
                    );
                  }),
                );
              } else {
                return Column(
                  children: List.generate(pipeflow.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Icon(
                          Icons.arrow_downward_rounded,
                          size: 16,
                          color: accentColor.withValues(alpha: 0.6),
                        ),
                      );
                    }
                    final stepIndex = index ~/ 2;
                    final step = pipeflow[stepIndex];
                    return _buildPipeflowStepCard(
                      step: step,
                      accentColor: accentColor,
                      isDark: isDark,
                      borderColor: borderColor,
                      textColor: textColor,
                      subColor: subColor,
                    );
                  }),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPipeflowStepCard({
    required Map<String, dynamic> step,
    required Color accentColor,
    required bool isDark,
    required Color borderColor,
    required Color textColor,
    required Color subColor,
  }) {
    final stepNum = step['step']?.toString() ?? '1';
    final title = step['title']?.toString() ?? 'Step';
    final table = step['table']?.toString() ?? 'Database';
    final description = step['description']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'STEP $stepNum',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.check_circle_outline_rounded,
                  size: 14, color: Color(0xFF10B981)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              table,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 10.5,
              color: subColor,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFiltersBar({
    required Color textColor,
    required Color subColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              onSubmitted: (_) {
                _currentPage = 1;
                _fetchLeads();
              },
              style: TextStyle(fontSize: 13, color: textColor),
              decoration: InputDecoration(
                hintText: 'Search by customer name or phone...',
                hintStyle: TextStyle(fontSize: 12.5, color: subColor),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: subColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 16, color: subColor),
                        onPressed: () {
                          _searchController.clear();
                          _currentPage = 1;
                          _fetchLeads();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () {
            _currentPage = 1;
            _fetchLeads();
          },
          icon: const Icon(Icons.search, size: 16),
          label: const Text('Filter', style: TextStyle(fontSize: 12.5)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildLeadsTable({
    required List<Map<String, dynamic>> leads,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
    required bool isDark,
  }) {
    if (leads.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: subColor),
            const SizedBox(height: 10),
            Text(
              'No leads found matching current stage and filter parameters.',
              style: TextStyle(fontSize: 13, color: subColor),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            ),
            headingTextStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            dataTextStyle: TextStyle(fontSize: 12, color: textColor),
            horizontalMargin: 16,
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('Customer Name')),
              DataColumn(label: Text('Phone')),
              DataColumn(label: Text('Source')),
              DataColumn(label: Text('Assigned Sales')),
              DataColumn(label: Text('Telecaller')),
              DataColumn(label: Text('Requirement / Notes')),
              DataColumn(label: Text('Created At')),
              DataColumn(label: Text('Copy Phone')),
            ],
            rows: leads.map((lead) {
              final name = lead['customer_name']?.toString() ?? '—';
              final phone = lead['phone']?.toString() ?? '—';
              final source = lead['source']?.toString() ?? 'Direct';
              final sales = lead['assigned_sales_name']?.toString() ?? 'Unassigned';
              final telecaller = lead['assigned_telecaller_name']?.toString() ?? 'Unallocated';
              final reqNotes = lead['requirement_notes']?.toString() ?? '';
              final createdAt = lead['created_at']?.toString() ?? '';
              final formattedDate = createdAt.length >= 10
                  ? createdAt.substring(0, 10)
                  : createdAt;

              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(phone)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getSourceColor(source).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: _getSourceColor(source).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        source,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getSourceColor(source),
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      sales,
                      style: TextStyle(
                        fontWeight: sales != 'Unassigned'
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: sales != 'Unassigned'
                            ? const Color(0xFF10B981)
                            : subColor,
                      ),
                    ),
                  ),
                  DataCell(Text(telecaller)),
                  DataCell(
                    Container(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(
                        reqNotes.isNotEmpty ? reqNotes : '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: subColor),
                      ),
                    ),
                  ),
                  DataCell(Text(formattedDate)),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      tooltip: 'Copy Phone',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: phone));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Copied $phone to clipboard'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination({
    required int currentPage,
    required int totalPages,
    required int totalCount,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing page $currentPage of $totalPages ($totalCount total leads)',
          style: TextStyle(fontSize: 12, color: subColor),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: currentPage > 1
                  ? () {
                      setState(() {
                        _currentPage--;
                      });
                      _fetchLeads();
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Previous', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: currentPage < totalPages
                  ? () {
                      setState(() {
                        _currentPage++;
                      });
                      _fetchLeads();
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Next', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildErrorView(Color textColor, Color subColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
          const SizedBox(height: 10),
          Text(_errorMessage, style: TextStyle(color: textColor)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _fetchLeads,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  static Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'meta ads':
      case 'meta':
      case 'facebook':
        return const Color(0xFF1877F2);
      case 'housing':
      case 'housing.com':
        return const Color(0xFF10B981);
      case 'webhook api':
      case 'webhook':
        return const Color(0xFF8B5CF6);
      case 'manual':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }
}

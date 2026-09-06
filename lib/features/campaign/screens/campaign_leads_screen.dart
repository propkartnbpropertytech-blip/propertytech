import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/crm_permission_denied.dart';
import '../../integration/services/integration_service.dart';
import '../../integration/models/integration_lead_model.dart';
import 'campaign_subshell_header.dart';

class CampaignLeadsScreen extends StatefulWidget {
  const CampaignLeadsScreen({super.key});

  @override
  State<CampaignLeadsScreen> createState() => _CampaignLeadsScreenState();
}

class _CampaignLeadsScreenState extends State<CampaignLeadsScreen> {
  final IntegrationService _service = IntegrationService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedSourceFilter = 'All';
  String _selectedDuplicateFilter = 'All';
  final Set<String> _selectedLeadIds = {};
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  List<IntegrationLeadModel> get _filteredLeads {
    var list = _service.leads;

    // Filter by Source
    if (_selectedSourceFilter != 'All') {
      list = list.where((l) => l.source == _selectedSourceFilter).toList();
    }

    // Filter by Duplicate status
    if (_selectedDuplicateFilter == 'Duplicates Only') {
      list = list.where((l) => l.isDuplicate).toList();
    } else if (_selectedDuplicateFilter == 'Unique Only') {
      list = list.where((l) => !l.isDuplicate).toList();
    }

    // Search query across all cell values
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((lead) {
        if (lead.source.toLowerCase().contains(query)) return true;
        if (lead.qualityStatus.toLowerCase().contains(query)) return true;
        for (final val in lead.rawJson.values) {
          if (val != null && val.toString().toLowerCase().contains(query)) {
            return true;
          }
        }
        return false;
      }).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String userRole = '';
    if (authState is Authenticated) {
      userRole = authState.user.role;
    }

    // RBAC Guard
    if (!RoleGuard.canAccessCampaign(userRole)) {
      return Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: SafeArea(
          child: CRMPermissionDenied(
            onGoBack: () => Navigator.of(context).maybePop(),
          ),
        ),
      );
    }

    final allDetectedHeaders = _service.getDetectedHeaders();
    final visibleHeaders = _service.getActiveVisibleHeaders();
    final leads = _filteredLeads;
    final totalLeads = _service.leads.length;
    final uniqueLeads = _service.leads.where((l) => !l.isDuplicate).length;
    final dupLeads = _service.leads.where((l) => l.isDuplicate).length;
    final metaResponsesSent = _service.leads.where((l) => l.metaFeedbackEventId != null).length;

    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Page Header
              CampaignSubshellHeader(
                activeTab: 'leads',
                trailing: CRMButton(
                  label: 'Paste JSON Payload',
                  prefixIcon: Icons.code_rounded,
                  variant: CRMButtonVariant.outline,
                  height: 40,
                  onPressed: () => _showPasteJsonDialog(context),
                ),
              ),

              const SizedBox(height: CRMSpacing.m),

              // KPI Analytics Cards (Compact)
              _buildKpiMetricsRow(context, totalLeads, uniqueLeads, dupLeads, metaResponsesSent),

              const SizedBox(height: CRMSpacing.m),

              // Batch Actions Bar when checkboxes are selected
              if (_selectedLeadIds.isNotEmpty) ...[
                _buildBatchActionBar(context, leads),
                const SizedBox(height: CRMSpacing.m),
              ],

              // Excel-like Interactive Spreadsheet Section
              _buildExcelSpreadsheetCard(context, allDetectedHeaders, visibleHeaders, leads),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildKpiMetricsRow(BuildContext context, int total, int unique, int dups, int metaSent) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              _buildMetricItem(context, 'Total Leads', total.toString(), Icons.inbox_rounded, CRMColors.primaryOf(context)),
              const SizedBox(width: CRMSpacing.s),
              _buildMetricItem(context, 'Unique Leads', unique.toString(), Icons.verified_user_rounded, CRMColors.success),
            ],
          ),
          const SizedBox(height: CRMSpacing.s),
          Row(
            children: [
              _buildMetricItem(context, 'Duplicates', dups.toString(), Icons.copy_rounded, CRMColors.warning),
              const SizedBox(width: CRMSpacing.s),
              _buildMetricItem(context, 'Meta Synced', metaSent.toString(), Icons.insights_rounded, CRMColors.textSecondaryOf(context)),
            ],
          ),
        ],
      );
    }
    return Row(
      children: [
        _buildMetricItem(context, 'Total Leads', total.toString(), Icons.inbox_rounded, CRMColors.primaryOf(context)),
        const SizedBox(width: CRMSpacing.s),
        _buildMetricItem(context, 'Unique Leads', unique.toString(), Icons.verified_user_rounded, CRMColors.success),
        const SizedBox(width: CRMSpacing.s),
        _buildMetricItem(context, 'Duplicates', dups.toString(), Icons.copy_rounded, CRMColors.warning),
        const SizedBox(width: CRMSpacing.s),
        _buildMetricItem(context, 'Meta Synced', metaSent.toString(), Icons.insights_rounded, CRMColors.textSecondaryOf(context)),
      ],
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 10),
        decoration: BoxDecoration(
          color: CRMColors.cardBgOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.card),
          border: Border.all(color: CRMColors.borderOf(context)),
          boxShadow: CRMShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: CRMSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: CRMTypography.headline.copyWith(color: CRMColors.textOf(context), fontSize: 17, height: 1.1),
                  ),
                  Text(
                    label,
                    style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
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

  // --- MULTI-SELECT BATCH ACTION BAR ---
  Widget _buildBatchActionBar(BuildContext context, List<IntegrationLeadModel> visibleLeads) {
    final count = _selectedLeadIds.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 8),
      decoration: BoxDecoration(
        color: CRMColors.primaryOf(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(color: CRMColors.primaryOf(context).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CRMColors.primaryOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.input),
            ),
            child: Text(
              '$count Selected',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: CRMSpacing.s),

          // Bulk Delete (Database Sync with Warning)
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.delete_forever_rounded, size: 16),
              label: Text('Delete ($count)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CRMColors.danger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              onPressed: () => _confirmBatchDeleteDialog(context),
            ),
          ),
          const SizedBox(width: CRMSpacing.s),

          // Bulk Merge (if 2+ selected)
          if (count >= 2) ...[
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.merge_type_rounded, size: 16),
                label: const Text('Merge Selected'),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onPressed: () => _showMergeSelectedLeadsDialog(context),
              ),
            ),
            const SizedBox(width: CRMSpacing.s),
          ],

          // Bulk Quality Status Menu
          PopupMenuButton<String>(
            tooltip: 'Update Quality Status',
            onSelected: (status) async {
              await _service.bulkUpdateQualityStatus(_selectedLeadIds.toList(), status);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated $count leads to $status')),
                );
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'Qualified', child: Text('Mark Qualified')),
              PopupMenuItem(value: 'Converted', child: Text('Mark Converted')),
              PopupMenuItem(value: 'Disqualified', child: Text('Mark Disqualified')),
              PopupMenuItem(value: 'Junk', child: Text('Mark Junk')),
              PopupMenuItem(value: 'Pending', child: Text('Mark Pending')),
            ],
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: CRMColors.cardBgOf(context),
                borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                border: Border.all(color: CRMColors.borderOf(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_half_rounded, size: 16, color: CRMColors.textOf(context)),
                  const SizedBox(width: 4),
                  Text('Set Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CRMColors.textOf(context))),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: CRMSpacing.s),

          // Bulk Import to CRM
          CRMButton(
            label: _isImporting ? 'Importing...' : 'Import to CRM ($count)',
            prefixIcon: Icons.cloud_upload_rounded,
            variant: CRMButtonVariant.primary,
            height: 36,
            isLoading: _isImporting,
            onPressed: () => _importSelectedLeadsToCrm(),
          ),

          const Spacer(),

          // Clear Selection Button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Clear Selection',
            onPressed: () => setState(() => _selectedLeadIds.clear()),
          ),
        ],
      ),
    );
  }

  // --- SPREADSHEET CARD ---
  Widget _buildExcelSpreadsheetCard(
    BuildContext context,
    List<String> allDetectedHeaders,
    List<String> visibleHeaders,
    List<IntegrationLeadModel> leads,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

    final columnsButton = SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.tune_rounded, size: 15),
        label: Text('Columns (${visibleHeaders.length}/${allDetectedHeaders.length} visible)'),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onPressed: () => _showColumnVisibilityDialog(context, allDetectedHeaders),
      ),
    );

    final addHeaderButton = CRMButton(
      label: 'Add Header',
      prefixIcon: Icons.add_rounded,
      variant: CRMButtonVariant.secondary,
      height: 36,
      onPressed: () => _showAddCustomHeaderDialog(context),
    );

    final moreToolsButton = PopupMenuButton<String>(
      tooltip: 'More Tools',
      onSelected: (action) {
        if (action == 'merge') {
          _showMergeHeadersDialog(context, allDetectedHeaders);
        } else if (action == 'dedup') {
          _service.deduplicateAll();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deduplication scan complete. Duplicates flagged.')),
          );
        } else if (action == 'purge') {
          _service.purgeDuplicates();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed all duplicate lead entries.')),
          );
        } else if (action == 'json') {
          _showPasteJsonDialog(context);
        } else if (action == 'clear') {
          _confirmClearAllLeadsDialog(context);
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'merge',
          child: Row(
            children: [
              Icon(Icons.merge_type_rounded, size: 16),
              SizedBox(width: 8),
              Text('Merge Columns'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'dedup',
          child: Row(
            children: [
              Icon(Icons.cleaning_services_rounded, size: 16),
              SizedBox(width: 8),
              Text('Scan for Duplicates'),
            ],
          ),
        ),
        if (_service.leads.any((l) => l.isDuplicate))
          const PopupMenuItem(
            value: 'purge',
            child: Row(
              children: [
                Icon(Icons.delete_sweep_rounded, size: 18, color: CRMColors.danger),
                SizedBox(width: 10),
                Text('Purge Duplicates', style: TextStyle(color: CRMColors.danger)),
              ],
            ),
          ),
        const PopupMenuItem(
          value: 'json',
          child: Row(
            children: [
              Icon(Icons.code_rounded, size: 18),
              SizedBox(width: 10),
              Text('Paste JSON Payload'),
            ],
          ),
        ),
        if (_service.leads.isNotEmpty) ...[
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'clear',
            child: Row(
              children: [
                Icon(Icons.clear_all_rounded, size: 18, color: CRMColors.danger),
                SizedBox(width: 10),
                Text('Clear All Leads', style: TextStyle(color: CRMColors.danger)),
              ],
            ),
          ),
        ],
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CRMColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          border: Border.all(color: CRMColors.borderOf(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_horiz_rounded, size: 16, color: CRMColors.textOf(context)),
            if (!isMobile) ...[
              const SizedBox(width: 4),
              Text('More Tools', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: CRMColors.textOf(context))),
            ],
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );

    final searchInput = SizedBox(
      height: 38,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search cell data, names, phone, email...',
          hintStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: CRMColors.borderOf(context)),
          ),
          filled: true,
          fillColor: CRMColors.cardBgOf(context),
        ),
      ),
    );

    final sourceDropdown = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: isMobile,
          value: _selectedSourceFilter,
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Sources')),
            DropdownMenuItem(value: 'Meta Ads', child: Text('Meta Ads ')),
            DropdownMenuItem(value: 'Google Sheets', child: Text('Google Sheets ')),
            DropdownMenuItem(value: 'Webhook API', child: Text('Webhook API ')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedSourceFilter = val);
          },
        ),
      ),
    );

    final duplicateDropdown = Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: isMobile,
          value: _selectedDuplicateFilter,
          items: const [
            DropdownMenuItem(value: 'All', child: Text('Show All Leads')),
            DropdownMenuItem(value: 'Duplicates Only', child: Text('Duplicates Only ')),
            DropdownMenuItem(value: 'Unique Only', child: Text('Unique Leads Only ')),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedDuplicateFilter = val);
          },
        ),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: CRMCard(
        elevated: true,
        title: 'Spreadsheet view',
        subtitle: isMobile ? null : 'Dynamic column headers with visibility controls, header merging & automated deduplication.',
        headerAction: isMobile
            ? moreToolsButton
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  columnsButton,
                  const SizedBox(width: CRMSpacing.s),
                  addHeaderButton,
                  const SizedBox(width: CRMSpacing.s),
                  moreToolsButton,
                ],
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toolbar Filters & Search (Responsive)
            if (isMobile) ...[
              Wrap(
                spacing: CRMSpacing.s,
                runSpacing: CRMSpacing.s,
                children: [
                  columnsButton,
                  addHeaderButton,
                ],
              ),
              const SizedBox(height: CRMSpacing.s),
              searchInput,
              const SizedBox(height: CRMSpacing.s),
              Row(
                children: [
                  Expanded(child: sourceDropdown),
                  const SizedBox(width: CRMSpacing.s),
                  Expanded(child: duplicateDropdown),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(flex: 3, child: searchInput),
                  const SizedBox(width: CRMSpacing.m),
                  sourceDropdown,
                  const SizedBox(width: CRMSpacing.m),
                  duplicateDropdown,
                ],
              ),
            ],

            const SizedBox(height: CRMSpacing.m),

            // Spreadsheet Data Table or Clean Empty State
            if (leads.isEmpty)
              Container(
                height: 240,
                width: double.infinity,
                padding: const EdgeInsets.all(CRMSpacing.l),
                decoration: BoxDecoration(
                  border: Border.all(color: CRMColors.borderOf(context)),
                  borderRadius: BorderRadius.circular(8),
                  color: CRMColors.cardBgOf(context),
                ),
                alignment: Alignment.center,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 48, color: CRMColors.primaryOf(context)),
                      const SizedBox(height: CRMSpacing.m),
                      Text(
                        'No Leads Ingested Yet',
                        style: CRMTypography.headline.copyWith(fontSize: 17),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: CRMSpacing.xs),
                      Text(
                        'Your Webhook is live. New leads from Meta Lead Ads and Google Sheets will automatically appear in this table.',
                        style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: CRMSpacing.m),
                      Wrap(
                        spacing: CRMSpacing.s,
                        runSpacing: CRMSpacing.s,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Define Dynamic Header'),
                            onPressed: () => _showAddCustomHeaderDialog(context),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.code_rounded, size: 16),
                            label: const Text('Paste JSON Payload'),
                            onPressed: () => _showPasteJsonDialog(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: CRMColors.borderOf(context)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minWidth: constraints.maxWidth),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: DataTable(
                      showCheckboxColumn: true,
                      onSelectAll: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedLeadIds.addAll(leads.map((l) => l.id));
                          } else {
                            _selectedLeadIds.clear();
                          }
                        });
                      },
                      headingRowColor: WidgetStateProperty.all(
                        CRMColors.surfaceElevatedOf(context),
                      ),
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: 64,
                      horizontalMargin: 12,
                      columnSpacing: 18,
                      columns: [
                        const DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                        const DataColumn(label: Text('Source', style: TextStyle(fontWeight: FontWeight.bold))),
                        const DataColumn(label: Text('Meta Lead Quality', style: TextStyle(fontWeight: FontWeight.bold))),
                        const DataColumn(label: Text('CRM Status', style: TextStyle(fontWeight: FontWeight.bold))),

                        // Dynamic Column Headers (Only Visible Ones)
                        ...visibleHeaders.map((header) {
                          final crmTarget = _service.columnMappings[header];
                          return DataColumn(
                            label: InkWell(
                              onTap: () => _showHeaderOptionsDialog(context, header),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(header, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.arrow_drop_down, size: 16),
                                        ],
                                      ),
                                      if (crmTarget != null)
                                        Text(
                                          '-> CRM: $crmTarget',
                                          style: TextStyle(fontSize: 10, color: CRMColors.primaryOf(context), fontWeight: FontWeight.w600),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: leads.asMap().entries.map((entry) {
                        final index = entry.key;
                        final lead = entry.value;
                        final isSelected = _selectedLeadIds.contains(lead.id);

                        return DataRow(
                          selected: isSelected,
                          onSelectChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedLeadIds.add(lead.id);
                              } else {
                                _selectedLeadIds.remove(lead.id);
                              }
                            });
                          },
                          color: WidgetStateProperty.resolveWith<Color?>((states) {
                            if (lead.isDuplicate) {
                              return CRMColors.warning.withValues(alpha: 0.12);
                            }
                            if (lead.importStatus == 'Imported') {
                              return CRMColors.success.withValues(alpha: 0.05);
                            }
                            return index.isEven ? CRMColors.cardBgOf(context).withValues(alpha: 0.4) : null;
                          }),
                          cells: [
                            // Row Index
                            DataCell(Text('${index + 1}')),

                            // Source Badge
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: lead.source == 'Meta Ads'
                                      ? CRMColors.terracotta.withValues(alpha: 0.15)
                                      : CRMColors.sage.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: lead.source == 'Meta Ads'
                                        ? CRMColors.terracotta.withValues(alpha: 0.4)
                                        : CRMColors.sage.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  lead.source,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: lead.source == 'Meta Ads' ? CRMColors.terracotta : CRMColors.sage,
                                  ),
                                ),
                              ),
                            ),

                            // Meta Lead Quality Dropdown & Trigger
                            DataCell(
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: lead.qualityStatus,
                                  isDense: true,
                                  items: const [
                                    DropdownMenuItem(value: 'Pending', child: Text('Pending ')),
                                    DropdownMenuItem(value: 'Qualified', child: Text('Qualified ')),
                                    DropdownMenuItem(value: 'Disqualified', child: Text('Disqualified ')),
                                    DropdownMenuItem(value: 'Converted', child: Text('Converted ')),
                                    DropdownMenuItem(value: 'Junk', child: Text('Junk ')),
                                  ],
                                  onChanged: (newStatus) async {
                                    if (newStatus != null && newStatus != lead.qualityStatus) {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final primaryColor = CRMColors.primaryOf(context);
                                      try {
                                        final res = await _service.sendMetaQualityFeedback(
                                          leadId: lead.id,
                                          qualityStatus: newStatus,
                                        );
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text('Dispatched Meta Conversions API: ${res['status']} (${res['eventId']})'),
                                              backgroundColor: primaryColor,
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          messenger.showSnackBar(
                                            SnackBar(content: Text('Error: $e'), backgroundColor: CRMColors.danger),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),

                            // CRM Import Status
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (lead.isDuplicate)
                                    Tooltip(
                                      message: lead.duplicateReason ?? 'Duplicate lead record detected',
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: CRMColors.warning,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'DUP',
                                          style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  Text(
                                    lead.importStatus,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: lead.importStatus == 'Imported'
                                          ? CRMColors.success
                                          : (lead.importStatus == 'Ignored' ? CRMColors.textSecondaryOf(context) : CRMColors.primaryOf(context)),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Dynamic Visible Cells mapped to JSON keys
                            ...visibleHeaders.map((header) {
                              final val = lead.getStringValue(header);
                              return DataCell(
                                Tooltip(
                                  message: val,
                                  child: Text(
                                    val.isEmpty ? '-' : val,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }),

                            // Actions (Inspect JSON & Delete with Warning Dialog)
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.data_object_rounded, size: 18),
                                    tooltip: 'Inspect JSON Payload',
                                    onPressed: () => _showInspectLeadDialog(context, lead),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: CRMColors.danger),
                                    tooltip: 'Delete Lead',
                                    onPressed: () => _confirmDeleteSingleLeadDialog(context, lead),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    ),
  );
}

  // --- DIALOGS & ACTIONS ---

  /// Delete Confirmation Dialog for a Single Lead (Database Sync)
  void _confirmDeleteSingleLeadDialog(BuildContext context, IntegrationLeadModel lead) {
    final leadName = lead.getStringValue('Full Name').isNotEmpty ? lead.getStringValue('Full Name') : (lead.getStringValue('Name').isNotEmpty ? lead.getStringValue('Name') : 'this lead');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: CRMColors.danger),
            const SizedBox(width: 8),
            const Text('Delete Lead Permanently?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$leadName"? This action cannot be undone and will permanently delete the lead from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CRMColors.danger, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final deleted = await _service.deleteLead(lead.id);
              if (mounted) {
                setState(() => _selectedLeadIds.remove(lead.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(deleted ? 'Lead deleted from database.' : 'Lead removed.')),
                );
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  /// Batch Delete Confirmation Dialog (Database Sync)
  void _confirmBatchDeleteDialog(BuildContext context) {
    final count = _selectedLeadIds.length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: CRMColors.danger),
            const SizedBox(width: 8),
            Text('Delete $count Leads Permanently?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete all $count selected leads? This action cannot be undone and will delete them permanently from the database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CRMColors.danger, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final idsToDelete = _selectedLeadIds.toList();
              final deletedCount = await _service.deleteLeads(idsToDelete);
              if (mounted) {
                setState(() => _selectedLeadIds.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully deleted $deletedCount lead(s) from database.')),
                );
              }
            },
            child: Text('Delete $count Leads'),
          ),
        ],
      ),
    );
  }

  /// Merge Selected Leads Dialog
  void _showMergeSelectedLeadsDialog(BuildContext context) {
    final selectedLeads = _service.leads.where((l) => _selectedLeadIds.contains(l.id)).toList();
    if (selectedLeads.length < 2) return;

    String primaryId = selectedLeads.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.merge_type_rounded, color: CRMColors.primaryOf(context)),
                const SizedBox(width: 8),
                const Text('Merge Selected Leads'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select the primary lead to keep. All non-empty fields and remarks from other selected leads will be consolidated into this primary record, and secondary records will be removed from the database.'),
                  const SizedBox(height: CRMSpacing.m),
                  const Text('Primary Lead Record:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: CRMSpacing.xs),
                  ...selectedLeads.map((l) {
                    final name = l.getStringValue('Full Name').isNotEmpty ? l.getStringValue('Full Name') : (l.getStringValue('Name').isNotEmpty ? l.getStringValue('Name') : 'Lead #${l.id.substring(0, 8)}');
                    final phone = l.getStringValue('Phone Number').isNotEmpty ? l.getStringValue('Phone Number') : l.getStringValue('Phone');
                    return RadioListTile<String>(
                      title: Text('$name ($phone) - ${l.source}'),
                      subtitle: Text('ID: ${l.id} | Quality: ${l.qualityStatus}'),
                      value: l.id,
                      groupValue: primaryId,
                      onChanged: (val) {
                        if (val != null) setModalState(() => primaryId = val);
                      },
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final secondaries = _selectedLeadIds.where((id) => id != primaryId).toList();
                  await _service.mergeSelectedLeads(
                    primaryLeadId: primaryId,
                    secondaryLeadIds: secondaries,
                  );
                  if (mounted) {
                    setState(() => _selectedLeadIds.clear());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Leads successfully merged into primary record.')),
                    );
                  }
                },
                child: const Text('Confirm Merge'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmClearAllLeadsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: CRMColors.danger),
            const SizedBox(width: 8),
            const Text('Clear All Ingested Leads?'),
          ],
        ),
        content: const Text('Are you sure you want to clear all leads in memory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CRMColors.danger, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _service.clearAllLeads();
              setState(() => _selectedLeadIds.clear());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleared all ingested leads.')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  /// Header Visibility & Column Selection Modal with Checkboxes
  void _showColumnVisibilityDialog(BuildContext context, List<String> allHeaders) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentAllHeaders = _service.getDetectedHeaders();
            final visibleCount = _service.getActiveVisibleHeaders().length;
            final totalCount = currentAllHeaders.length;

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.view_column_rounded, color: CRMColors.primaryOf(context)),
                  const SizedBox(width: 8),
                  Text('Select Visible Headers ($visibleCount of $totalCount visible)'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.check_box_rounded, size: 16),
                          label: const Text('Select All'),
                          onPressed: () {
                            _service.setAllHeadersVisibility(true);
                            setModalState(() {});
                            setState(() {});
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.check_box_outline_blank_rounded, size: 16),
                          label: const Text('Deselect All'),
                          onPressed: () {
                            _service.setAllHeadersVisibility(false);
                            setModalState(() {});
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    SizedBox(
                      height: 350,
                      child: ListView.builder(
                        itemCount: currentAllHeaders.length,
                        itemBuilder: (context, i) {
                          final h = currentAllHeaders[i];
                          final isChecked = _service.isHeaderVisible(h);
                          final crmTarget = _service.columnMappings[h];

                          return CheckboxListTile(
                            dense: true,
                            title: Row(
                              children: [
                                Expanded(child: Text(h, style: const TextStyle(fontWeight: FontWeight.w600))),
                                if (crmTarget != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CRMColors.primaryOf(context).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '-> $crmTarget',
                                      style: TextStyle(fontSize: 10, color: CRMColors.primaryOf(context), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                            value: isChecked,
                            onChanged: (val) {
                              _service.setHeaderVisibility(h, val ?? false);
                              setModalState(() {});
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Define a custom header modal
  void _showAddCustomHeaderDialog(BuildContext context) {
    final textController = TextEditingController();
    String? selectedCrmTarget;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.add_box_rounded, color: CRMColors.primaryOf(context)),
              const SizedBox(width: 8),
              const Text('Add Dynamic Column Header'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Define a column name in advance (or match future webhook keys).',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: CRMSpacing.m),
                TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Header Name (e.g. Preferred Location, Move-in Date)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: CRMSpacing.m),
                const Text('Map to CRM Field (Optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedCrmTarget,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('None (Keep as raw custom field)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None (Raw JSON Field)')),
                    ...IntegrationService.standardCrmFields.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text('${e.value} (${e.key})'));
                    }),
                  ],
                  onChanged: (val) {
                    setModalState(() => selectedCrmTarget = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  _service.addCustomHeader(name, crmField: selectedCrmTarget);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added header: "$name"')),
                  );
                }
              },
              child: const Text('Add Header'),
            ),
          ],
        ),
      ),
    );
  }

  /// Column Header Options Dialog (Rename, Map to CRM, Merge, Hide, Delete)
  void _showHeaderOptionsDialog(BuildContext context, String header) {
    String? currentTarget = _service.columnMappings[header];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.tune_rounded, color: CRMColors.primaryOf(context)),
              const SizedBox(width: 8),
              Text('Header: "$header"'),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CRM Lead Field Mapping', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text(
                  'When leads are imported, this column value will automatically map into the selected CRM field.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: currentTarget,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  hint: const Text('Select CRM Target Field'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None (Unmapped / Raw)')),
                    ...IntegrationService.standardCrmFields.entries.map((e) {
                      return DropdownMenuItem(value: e.key, child: Text(e.value));
                    }),
                  ],
                  onChanged: (val) {
                    setModalState(() => currentTarget = val);
                    _service.setColumnMapping(header, val);
                  },
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Rename Header'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showRenameHeaderDialog(context, header);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.visibility_off_rounded),
                  title: const Text('Hide this Column'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () {
                    _service.setHeaderVisibility(header, false);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Column "$header" hidden from table view.')),
                    );
                  },
                ),
                if (_service.customHeaders.contains(header))
                  ListTile(
                    leading: const Icon(Icons.delete_forever_rounded, color: CRMColors.danger),
                    title: const Text('Delete Custom Header', style: TextStyle(color: CRMColors.danger)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    onTap: () {
                      _service.removeCustomHeader(header);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Custom column "$header" removed.')),
                      );
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  void _showRenameHeaderDialog(BuildContext context, String oldHeader) {
    final controller = TextEditingController(text: oldHeader);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rename Header "$oldHeader"'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New Header Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != oldHeader) {
                _service.renameHeader(oldHeader, newName);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Renamed "$oldHeader" to "$newName"')),
                );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showMergeHeadersDialog(BuildContext context, List<String> headers) {
    final Set<String> selectedHeadersToMerge = {};
    String targetHeader = headers.isNotEmpty ? headers.first : '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.merge_type_rounded, color: CRMColors.primaryOf(context)),
              const SizedBox(width: 8),
              const Text('Merge Multiple Headers into One'),
            ],
          ),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select multiple columns to merge (e.g. "Full Name", "Client_Name", "Name"). Their values across all ingested leads will be combined into a single target column.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: CRMSpacing.m),
                const Text('Select Source Headers to Combine:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: CRMColors.borderOf(context)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView(
                    children: headers.map((h) {
                      final isChecked = selectedHeadersToMerge.contains(h);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(h),
                        value: isChecked,
                        onChanged: (val) {
                          setModalState(() {
                            if (val == true) {
                              selectedHeadersToMerge.add(h);
                            } else {
                              selectedHeadersToMerge.remove(h);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: CRMSpacing.m),
                const Text('Destination Target Header:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: targetHeader.isNotEmpty && headers.contains(targetHeader) ? targetHeader : null,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: headers.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => targetHeader = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: selectedHeadersToMerge.isEmpty || targetHeader.isEmpty
                  ? null
                  : () {
                      _service.mergeHeaders(
                        sourceHeaders: selectedHeadersToMerge.toList(),
                        targetHeader: targetHeader,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Merged ${selectedHeadersToMerge.length} headers into "$targetHeader".')),
                      );
                    },
              child: const Text('Merge Headers'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPasteJsonDialog(BuildContext context) {
    final controller = TextEditingController(
      text: '{\n  "Full Name": "Aarav Sharma",\n  "Phone Number": "+91 9876543210",\n  "Email ID": "aarav.sharma@example.com",\n  "City": "Mumbai",\n  "Budget": "1.5 Cr",\n  "Configuration": "3 BHK",\n  "Campaign Name": "Meta Ads Luxury Q3"\n}',
    );
    String source = 'Meta Ads';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.code_rounded, color: CRMColors.primaryOf(context)),
              const SizedBox(width: 8),
              const Text('Paste JSON Payload (Simulate Ingestion)'),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Source Tag:'),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: source,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Meta Ads', child: Text('Meta Ads ')),
                    DropdownMenuItem(value: 'Google Sheets', child: Text('Google Sheets ')),
                    DropdownMenuItem(value: 'Webhook API', child: Text('Webhook API ')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => source = val);
                  },
                ),
                const SizedBox(height: CRMSpacing.m),
                const Text('Raw JSON Payload:'),
                const SizedBox(height: 4),
                TextField(
                  controller: controller,
                  maxLines: 9,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  final parsed = jsonDecode(controller.text);
                  if (parsed is Map<String, dynamic>) {
                    await _service.ingestRawLead(source: source, rawJson: parsed);
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lead payload successfully ingested!')),
                      );
                    }
                  } else {
                    throw Exception("JSON must be a key-value object");
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid JSON: $e'), backgroundColor: CRMColors.danger),
                  );
                }
              },
              child: const Text('Ingest Lead'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInspectLeadDialog(BuildContext context, IntegrationLeadModel lead) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.data_object_rounded),
            const SizedBox(width: 8),
            Text('Payload Inspector: ${lead.source}'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Received: ${lead.receivedAt.toLocal()}'),
                Text('External Lead ID: ${lead.externalLeadId ?? "N/A"}'),
                Text('Quality: ${lead.qualityStatus} | CRM Status: ${lead.importStatus}'),
                if (lead.isDuplicate)
                  Text('Duplicate: ${lead.duplicateReason}', style: const TextStyle(color: CRMColors.warning, fontWeight: FontWeight.bold)),
                const Divider(),
                const Text('Raw JSON:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(lead.rawJson),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _importSelectedLeadsToCrm() async {
    setState(() => _isImporting = true);
    final count = await _service.importLeadsToCrm(_selectedLeadIds.toList());
    if (mounted) {
      setState(() {
        _isImporting = false;
        _selectedLeadIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $count lead(s) into PropKart CRM clients database!'),
          backgroundColor: CRMColors.success,
        ),
      );
    }
  }
}
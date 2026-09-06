import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/tokens/app_shadows.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/design_system/widgets/crm_permission_denied.dart';
import '../services/integration_service.dart';
import '../models/integration_lead_model.dart';

class IntegrationScreen extends StatefulWidget {
  const IntegrationScreen({super.key});

  @override
  State<IntegrationScreen> createState() => _IntegrationScreenState();
}

class _IntegrationScreenState extends State<IntegrationScreen> {
  final IntegrationService _service = IntegrationService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedSourceFilter = 'All';
  String _selectedDuplicateFilter = 'All';
  final Set<String> _selectedLeadIds = {};
  bool _isImporting = false;
  bool _showWebhookConfig = false;

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

    // Role-based Access Control Guard: Only Admin and Super Admin
    if (!RoleGuard.canAccessIntegration(userRole)) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page Header
              CRMPageHeader(
                eyebrow: 'AUTOMATION & DATA PIPELINES',
                title: 'Integrations & Webhooks',
                benefit: 'Direct Meta Lead Ads & Google Sheets live ingestion with dynamic header management & deduplication.',
                trailing: OutlinedButton.icon(
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: const Text('Setup Guides'),
                  onPressed: () => _showSetupGuidesModal(context),
                ),
              ),

              const SizedBox(height: CRMSpacing.m),

              // Top Webhook Configuration Card (Collapsible)
              _buildWebhookGeneratorCard(context),

              const SizedBox(height: CRMSpacing.m),

              // KPI Analytics Cards (Compact)
              _buildKpiMetricsRow(context, totalLeads, uniqueLeads, dupLeads, metaResponsesSent),

              const SizedBox(height: CRMSpacing.m),

              // Excel-like Interactive Spreadsheet Section
              _buildExcelSpreadsheetCard(context, allDetectedHeaders, visibleHeaders, leads),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildWebhookGeneratorCard(BuildContext context) {
    if (!_showWebhookConfig) {
      return Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CRMColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: CRMColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: CRMColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'WEBHOOK LIVE',
                    style: CRMTypography.captionBold.copyWith(color: CRMColors.success, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: CRMSpacing.m),
            Expanded(
              child: Text(
                _service.webhookUrl,
                style: CRMTypography.caption.copyWith(
                  fontFamily: 'monospace',
                  color: CRMColors.textSecondaryOf(context),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              tooltip: 'Copy Webhook URL',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _service.webhookUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Production Webhook URL copied!')),
                );
              },
            ),
            const SizedBox(width: CRMSpacing.xs),
            OutlinedButton.icon(
              icon: const Icon(Icons.tune_rounded, size: 14),
              label: const Text('Webhook & Meta Keys', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _showWebhookConfig = true),
            ),
          ],
        ),
      );
    }

    return CRMCard(
      elevated: true,
      accentBorder: CRMColors.primary.withValues(alpha: 0.3),
      title: 'Hostinger VPS Ingestion Webhook & Meta Conversions API',
      subtitle: 'Connect your Meta Lead Ads form and Google Sheets Apps Script to automatically ingest leads.',
      headerAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: CRMColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CRMColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: CRMColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE & LISTENING',
                  style: CRMTypography.captionBold.copyWith(color: CRMColors.success, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: CRMSpacing.s),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Collapse Webhook Config',
            onPressed: () => setState(() => _showWebhookConfig = false),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: CRMSpacing.s),
          // Webhook URL display with Copy button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HOSTINGER VPS WEBHOOK ENDPOINT (POST)',
                style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
              ),
              Text(
                'Hostinger VPS IP: 200.234.36.120',
                style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context)),
              ),
            ],
          ),
          const SizedBox(height: CRMSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: CRMSpacing.s),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(CRMBorderRadius.input),
              border: Border.all(color: CRMColors.borderOf(context)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.link_rounded, color: CRMColors.primaryOf(context), size: 20),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Production Domain URL (SSL):', style: TextStyle(fontSize: 10, color: CRMColors.textSecondaryOf(context), fontWeight: FontWeight.bold)),
                          SelectableText(
                            _service.webhookUrl,
                            style: CRMTypography.body.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: CRMColors.primaryOf(context),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy Production URL',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _service.webhookUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Production Webhook URL copied!')),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(height: 12),
                Row(
                  children: [
                    Icon(Icons.dns_rounded, color: CRMColors.textSecondaryOf(context), size: 18),
                    const SizedBox(width: CRMSpacing.s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Direct Hostinger VPS IP URL:', style: TextStyle(fontSize: 10, color: CRMColors.textSecondaryOf(context), fontWeight: FontWeight.bold)),
                          SelectableText(
                            _service.vpsDirectWebhookUrl,
                            style: CRMTypography.caption.copyWith(
                              fontFamily: 'monospace',
                              color: CRMColors.textSecondaryOf(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      tooltip: 'Copy Direct VPS IP URL',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _service.vpsDirectWebhookUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Direct VPS IP Webhook URL copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: CRMSpacing.m),

          // Secret & Meta Verify Token Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'META WEBHOOK VERIFY TOKEN',
                      style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 8),
                      decoration: BoxDecoration(
                        color: CRMColors.cardBgOf(context),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                        border: Border.all(color: CRMColors.borderOf(context)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              _service.metaVerifyToken,
                              style: CRMTypography.caption.copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _service.metaVerifyToken));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Meta Verify Token copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEBHOOK SECRET (HMAC SHA-256)',
                      style: CRMTypography.captionBold.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 11),
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: CRMSpacing.m, vertical: 8),
                      decoration: BoxDecoration(
                        color: CRMColors.cardBgOf(context),
                        borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                        border: Border.all(color: CRMColors.borderOf(context)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              _service.webhookSecret,
                              style: CRMTypography.caption.copyWith(fontFamily: 'monospace'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _service.webhookSecret));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Webhook Secret copied!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: CRMSpacing.m),

          // Setup Guide Action Buttons
          Wrap(
            spacing: CRMSpacing.m,
            runSpacing: CRMSpacing.s,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.facebook_rounded, color: CRMColors.terracotta, size: 18),
                label: const Text('Meta Lead Ads Setup Guide'),
                onPressed: () => _showMetaSetupGuide(context),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.table_chart_rounded, color: CRMColors.sage, size: 18),
                label: const Text('Google Sheets Apps Script Guide'),
                onPressed: () => _showGoogleSheetsSetupGuide(context),
              ),
              OutlinedButton.icon(
                icon: Icon(Icons.send_rounded, color: CRMColors.primaryOf(context), size: 18),
                label: const Text('Meta Conversions API (Lead Quality)'),
                onPressed: () => _showMetaConversionsApiInfo(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsRow(BuildContext context, int total, int unique, int dups, int metaSent) {
    return Row(
      children: [
        _buildMetricItem(context, 'Total Ingested', total.toString(), Icons.inbox_rounded, CRMColors.primaryOf(context)),
        const SizedBox(width: CRMSpacing.s),
        _buildMetricItem(context, 'Unique Valid', unique.toString(), Icons.verified_user_rounded, CRMColors.success),
        const SizedBox(width: CRMSpacing.s),
        _buildMetricItem(context, 'Duplicates Blocked', dups.toString(), Icons.copy_rounded, CRMColors.warning),
        const SizedBox(width: CRMSpacing.s),
        _buildMetricItem(context, 'Meta Responses', metaSent.toString(), Icons.insights_rounded, CRMColors.terracotta),
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

  Widget _buildExcelSpreadsheetCard(
    BuildContext context,
    List<String> allDetectedHeaders,
    List<String> visibleHeaders,
    List<IntegrationLeadModel> leads,
  ) {
    return CRMCard(
      elevated: true,
      title: 'Incoming Ingestion Grid (Excel Mode)',
      subtitle: 'Dynamic column headers with visibility controls, header merging & automated deduplication.',
      headerAction: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Visibility Checkbox Selector Button
          OutlinedButton.icon(
            icon: const Icon(Icons.tune_rounded, size: 15),
            label: Text('Columns (${visibleHeaders.length}/${allDetectedHeaders.length} visible)'),
            onPressed: () => _showColumnVisibilityDialog(context, allDetectedHeaders),
          ),
          const SizedBox(width: CRMSpacing.s),
          CRMButton(
            label: 'Add Header',
            prefixIcon: Icons.add_rounded,
            variant: CRMButtonVariant.secondary,
            onPressed: () => _showAddCustomHeaderDialog(context),
          ),
          const SizedBox(width: CRMSpacing.s),
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: CRMColors.surfaceElevatedOf(context),
                borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                border: Border.all(color: CRMColors.borderOf(context)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.more_horiz_rounded, size: 16, color: CRMColors.textOf(context)),
                  const SizedBox(width: 4),
                  Text('More Tools', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.textOf(context))),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
            tooltip: 'More Ingestion Tools',
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
                _service.clearAllLeads();
                _selectedLeadIds.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cleared all ingested leads.')),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'merge',
                child: Row(
                  children: [
                    Icon(Icons.merge_type_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Merge Headers'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'dedup',
                child: Row(
                  children: [
                    Icon(Icons.filter_alt_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('Auto-Deduplicate'),
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar Filters & Batch Ingestion
          Row(
            children: [
              // Search Input
              Expanded(
                flex: 3,
                child: SizedBox(
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
                ),
              ),
              const SizedBox(width: CRMSpacing.m),

              // Source Filter
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: CRMColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CRMColors.borderOf(context)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSourceFilter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('All Sources')),
                      DropdownMenuItem(value: 'Meta Ads', child: Text('Meta Ads 🟦')),
                      DropdownMenuItem(value: 'Google Sheets', child: Text('Google Sheets 🟩')),
                      DropdownMenuItem(value: 'Webhook API', child: Text('Webhook API ⚡')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSourceFilter = val);
                    },
                  ),
                ),
              ),

              const SizedBox(width: CRMSpacing.m),

              // Duplicate Filter
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: CRMColors.cardBgOf(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CRMColors.borderOf(context)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDuplicateFilter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('Show All Leads')),
                      DropdownMenuItem(value: 'Duplicates Only', child: Text('Duplicates Only ⚠️')),
                      DropdownMenuItem(value: 'Unique Only', child: Text('Unique Leads Only ✅')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDuplicateFilter = val);
                    },
                  ),
                ),
              ),

              const SizedBox(width: CRMSpacing.m),

              // Import Selected Action
              CRMButton(
                label: _isImporting
                    ? 'Importing...'
                    : 'Import to CRM (${_selectedLeadIds.isEmpty ? leads.length : _selectedLeadIds.length})',
                prefixIcon: Icons.cloud_upload_rounded,
                variant: CRMButtonVariant.primary,
                isLoading: _isImporting,
                onPressed: leads.isEmpty ? null : () => _importLeadsToCrm(),
              ),
            ],
          ),

          const SizedBox(height: CRMSpacing.m),

          // Spreadsheet Data Table or Clean Empty State
          if (leads.isEmpty)
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.all(CRMSpacing.l),
              decoration: BoxDecoration(
                border: Border.all(color: CRMColors.borderOf(context)),
                borderRadius: BorderRadius.circular(8),
                color: CRMColors.cardBgOf(context),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: CRMColors.primaryOf(context)),
                  const SizedBox(height: CRMSpacing.m),
                  Text('No Leads Ingested Yet', style: CRMTypography.headline.copyWith(fontSize: 17)),
                  const SizedBox(height: CRMSpacing.xs),
                  Text(
                    'Your Hostinger VPS Webhook is live and listening. New leads from Meta Lead Ads and Google Sheets will automatically appear in this Excel table.',
                    style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  Wrap(
                    spacing: CRMSpacing.s,
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
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: CRMColors.borderOf(context)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                                          '→ CRM: $crmTarget',
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
                                    DropdownMenuItem(value: 'Pending', child: Text('Pending ⏳')),
                                    DropdownMenuItem(value: 'Qualified', child: Text('Qualified ⭐')),
                                    DropdownMenuItem(value: 'Disqualified', child: Text('Disqualified ❌')),
                                    DropdownMenuItem(value: 'Converted', child: Text('Converted 🏆')),
                                    DropdownMenuItem(value: 'Junk', child: Text('Junk 🗑️')),
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
                                    val.isEmpty ? '—' : val,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            }),

                            // Actions
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
                                    tooltip: 'Delete',
                                    onPressed: () => _service.deleteLead(lead.id),
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
        ],
      ),
    );
  }

  // --- DIALOGS & ACTIONS ---

  /// Setup Guides Modal
  void _showSetupGuidesModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.integration_instructions_rounded, color: CRMColors.primaryOf(context)),
            const SizedBox(width: 10),
            const Text('Integration Setup Guides'),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: const Icon(Icons.facebook_rounded, color: CRMColors.terracotta, size: 28),
                title: const Text('Meta Lead Ads Setup Guide', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Connect Facebook & Instagram lead forms to auto-ingest into CRM'),
                trailing: const Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: CRMColors.borderOf(context)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMetaSetupGuide(context);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.table_chart_rounded, color: CRMColors.sage, size: 28),
                title: const Text('Google Sheets Apps Script Guide', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Sync new spreadsheet rows directly to your CRM webhook'),
                trailing: const Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: CRMColors.borderOf(context)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showGoogleSheetsSetupGuide(context);
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Icon(Icons.send_rounded, color: CRMColors.primaryOf(context), size: 28),
                title: const Text('Meta Conversions API (Lead Quality)', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Send qualified/converted offline lead feedback back to Meta algorithms'),
                trailing: const Icon(Icons.chevron_right),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: CRMColors.borderOf(context)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showMetaConversionsApiInfo(context);
                },
              ),
            ],
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

  /// Header Visibility & Column Selection Modal with Checkboxes
  void _showColumnVisibilityDialog(BuildContext context, List<String> allHeaders) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final visibleCount = _service.getActiveVisibleHeaders().length;
            final totalCount = allHeaders.length;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Check the headers you want to display in your Excel table view. Unchecked headers remain stored and can be re-enabled anytime.',
                      style: CRMTypography.body.copyWith(fontSize: 13, color: CRMColors.textSecondaryOf(context)),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _service.setAllHeadersVisibility(true);
                            });
                          },
                          child: const Text('Select All'),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _service.setAllHeadersVisibility(false);
                            });
                          },
                          child: const Text('Deselect All'),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Header'),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showAddCustomHeaderDialog(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.xs),
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        border: Border.all(color: CRMColors.borderOf(context)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListView.builder(
                        itemCount: allHeaders.length,
                        itemBuilder: (context, index) {
                          final h = allHeaders[index];
                          final isChecked = _service.isHeaderVisible(h);
                          final crmTarget = _service.columnMappings[h];

                          return CheckboxListTile(
                            dense: true,
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(h, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                if (crmTarget != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: CRMColors.primaryOf(context).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '→ $crmTarget',
                                      style: TextStyle(fontSize: 10, color: CRMColors.primaryOf(context)),
                                    ),
                                  ),
                              ],
                            ),
                            value: isChecked,
                            onChanged: (val) {
                              setModalState(() {
                                _service.setHeaderVisibility(h, val ?? false);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Apply Column Selection'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Add Custom Dynamic Header Dialog
  void _showAddCustomHeaderDialog(BuildContext context) {
    final headerNameController = TextEditingController();
    String? selectedCrmTarget;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.add_box_rounded, color: CRMColors.primaryOf(context)),
                  const SizedBox(width: 8),
                  const Text('Add Dynamic Column / Header'),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Define a new header for your incoming lead schema. It will be added to the Excel grid and will automatically capture matching JSON keys from Meta & Google Sheets.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    const Text('HEADER / COLUMN NAME:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: CRMSpacing.xs),
                    TextField(
                      controller: headerNameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'e.g. Preferred Locality, Loan Required, BHK',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    const Text('MAP TO CRM FIELD (OPTIONAL):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: CRMSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCrmTarget,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('— Auto-Detect Mapping —')),
                        ...IntegrationService.standardCrmFields.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text('${e.value} [${e.key}]'));
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    final name = headerNameController.text.trim();
                    if (name.isNotEmpty) {
                      _service.addCustomHeader(name, crmField: selectedCrmTarget);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added header "$name" to active grid!')),
                      );
                    }
                  },
                  child: const Text('Add Header'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMergeHeadersDialog(BuildContext context, List<String> headers) {
    final selectedHeadersToMerge = <String>{};
    final targetHeaderController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.merge_type_rounded, color: CRMColors.primaryOf(context)),
                  const SizedBox(width: 8),
                  const Text('Merge Column Headers'),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select two or more column headers (e.g. "phone_number" and "Contact") to consolidate into a single unified column, removing data duplicacy.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    const Text('1. SELECT HEADERS TO MERGE:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: CRMSpacing.xs),
                    Container(
                      height: 160,
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
                                  if (targetHeaderController.text.isEmpty) {
                                    targetHeaderController.text = h;
                                  }
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
                    const Text('2. UNIFIED TARGET HEADER NAME:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: CRMSpacing.xs),
                    TextField(
                      controller: targetHeaderController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Phone Number or Mobile',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: selectedHeadersToMerge.isEmpty || targetHeaderController.text.trim().isEmpty
                      ? null
                      : () {
                          _service.mergeHeaders(
                            sourceHeaders: selectedHeadersToMerge.toList(),
                            targetHeader: targetHeaderController.text.trim(),
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Successfully merged headers into "${targetHeaderController.text.trim()}"',
                              ),
                            ),
                          );
                        },
                  child: const Text('Merge Headers'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showHeaderOptionsDialog(BuildContext context, String header) {
    final currentTarget = _service.columnMappings[header];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(CRMSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Header Options: "$header"', style: CRMTypography.sectionTitle),
              const SizedBox(height: CRMSpacing.m),
              const Text('Map this column to a standard PropKart CRM field:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: CRMSpacing.s),
              DropdownButtonFormField<String>(
                initialValue: currentTarget,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  labelText: 'Target CRM Field',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('— Not Mapped —')),
                  ...IntegrationService.standardCrmFields.entries.map((e) {
                    return DropdownMenuItem(value: e.key, child: Text('${e.value} [${e.key}]'));
                  }),
                ],
                onChanged: (val) {
                  _service.setColumnMapping(header, val);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mapped "$header" to CRM field "$val"')),
                  );
                },
              ),
              const SizedBox(height: CRMSpacing.l),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPasteJsonDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Paste Raw JSON Payload'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Paste any incoming JSON payload. Keys will dynamically populate columns in the Excel grid:'),
                const SizedBox(height: CRMSpacing.s),
                TextField(
                  controller: controller,
                  maxLines: 10,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: InputDecoration(
                    hintText: '{\n  "Full Name": "Client Name",\n  "Phone Number": "+91 98765 43210",\n  "City": "Mumbai",\n  "Budget": "₹3 Cr"\n}',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final raw = controller.text.trim();
                if (raw.isEmpty) return;
                try {
                  final decoded = jsonDecode(raw);
                  if (decoded is Map<String, dynamic>) {
                    _service.ingestRawLead(source: 'Webhook API', rawJson: decoded);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('JSON payload ingested successfully!')),
                    );
                  } else {
                    throw Exception('JSON must be a key-value object.');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid JSON: $e'), backgroundColor: CRMColors.danger),
                  );
                }
              },
              child: const Text('Ingest JSON'),
            ),
          ],
        );
      },
    );
  }

  void _showInspectLeadDialog(BuildContext context, IntegrationLeadModel lead) {
    final prettyJson = const JsonEncoder.withIndent('  ').convert(lead.rawJson);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                lead.source == 'Meta Ads' ? Icons.facebook_rounded : Icons.table_chart_rounded,
                color: lead.source == 'Meta Ads' ? CRMColors.terracotta : CRMColors.sage,
              ),
              const SizedBox(width: 8),
              Text('Lead Details: ${lead.getStringValue("Full Name")}'),
            ],
          ),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (lead.isDuplicate)
                    Container(
                      margin: const EdgeInsets.only(bottom: CRMSpacing.m),
                      padding: const EdgeInsets.all(CRMSpacing.m),
                      decoration: BoxDecoration(
                        color: CRMColors.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CRMColors.warning),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: CRMColors.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              lead.duplicateReason ?? 'Duplicate record identified.',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text('RAW JSON PAYLOAD (KEY : VALUE)', style: CRMTypography.captionBold),
                  const SizedBox(height: CRMSpacing.xs),
                  Container(
                    padding: const EdgeInsets.all(CRMSpacing.m),
                    decoration: BoxDecoration(
                      color: CRMColors.surfaceElevatedOf(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CRMColors.borderOf(context)),
                    ),
                    child: SelectableText(
                      prettyJson,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  if (lead.metaFeedbackEventId != null) ...[
                    Text('META CONVERSIONS API FEEDBACK', style: CRMTypography.captionBold),
                    const SizedBox(height: CRMSpacing.xs),
                    Text('Status: ${lead.qualityStatus} | Event ID: ${lead.metaFeedbackEventId}'),
                    Text('Dispatched At: ${lead.metaFeedbackSentAt}'),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _showMetaSetupGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Meta Lead Ads Webhook Setup Guide'),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Follow these steps to connect your Meta Facebook & Instagram Lead Ads to PropKart:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: CRMSpacing.m),
                  _buildGuideStep('1', 'Go to developers.facebook.com and select your Meta App.'),
                  _buildGuideStep('2', 'Under Products, add "Webhooks" and select "Page" subscription.'),
                  _buildGuideStep('3', 'Paste your PropKart Webhook URL into the Callback URL field:'),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: CRMColors.cardBgOf(context), borderRadius: BorderRadius.circular(6)),
                    child: SelectableText(_service.webhookUrl, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ),
                  _buildGuideStep('4', 'Enter the Verify Token: "${_service.metaVerifyToken}" and click "Verify & Save".'),
                  _buildGuideStep('5', 'Subscribe to the "leadgen" field to receive new leads instantly.'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Got it')),
          ],
        );
      },
    );
  }

  void _showGoogleSheetsSetupGuide(BuildContext context) {
    final scriptSnippet = 'function onFormSubmit(e) {\n'
        '  var url = "${_service.webhookUrl}";\n'
        '  var sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();\n'
        '  var lastRow = sheet.getLastRow();\n'
        '  var headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];\n'
        '  var rowValues = sheet.getRange(lastRow, 1, 1, sheet.getLastColumn()).getValues()[0];\n'
        '  var payload = {};\n'
        '  for (var i = 0; i < headers.length; i++) {\n'
        '    payload[headers[i]] = rowValues[i];\n'
        '  }\n'
        '  var options = {\n'
        '    "method": "post",\n'
        '    "contentType": "application/json",\n'
        '    "payload": JSON.stringify(payload)\n'
        '  };\n'
        '  UrlFetchApp.fetch(url, options);\n'
        '}';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Google Sheets Apps Script Integration Guide'),
          content: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Paste this script in Google Sheets (Extensions > Apps Script) to push leads in real time:'),
                  const SizedBox(height: CRMSpacing.m),
                  Container(
                    padding: const EdgeInsets.all(CRMSpacing.m),
                    decoration: BoxDecoration(color: CRMColors.surfaceElevatedOf(context), borderRadius: BorderRadius.circular(8)),
                    child: SelectableText(scriptSnippet, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: scriptSnippet));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Apps Script snippet copied!')));
              },
              child: const Text('Copy Script'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }

  void _showMetaConversionsApiInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Meta Lead Quality Conversions API'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'How Meta Lead Quality Response Works:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: CRMSpacing.s),
                Text(
                  '1. When an agent qualifies or converts a lead in PropKart, selecting "Qualified" or "Converted" sends an event to Meta Conversions API (Graph API v19.0).\n\n'
                  '2. Meta matches the lead ID and hashed contact information to train Meta Ads Machine Learning algorithms.\n\n'
                  '3. This automatically optimizes your real estate campaigns to target high-intent buyers, reducing cost per qualified lead.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _buildGuideStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 10, child: Text(num, style: const TextStyle(fontSize: 11))),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _importLeadsToCrm() async {
    final targetIds = _selectedLeadIds.isEmpty ? _filteredLeads.map((l) => l.id).toList() : _selectedLeadIds.toList();

    setState(() => _isImporting = true);

    try {
      final count = await _service.importLeadsToCrm(targetIds);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully imported $count lead(s) into PropKart CRM!'),
          backgroundColor: CRMColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import error: $e'), backgroundColor: CRMColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as xl;
import '../../../core/utils/file_downloader.dart';
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
import '../bloc/campaign_leads_bloc.dart';
import 'campaign_subshell_header.dart';

class CampaignLeadsScreen extends StatefulWidget {
  const CampaignLeadsScreen({super.key});

  @override
  State<CampaignLeadsScreen> createState() => _CampaignLeadsScreenState();
}

class _CampaignLeadsScreenState extends State<CampaignLeadsScreen> {
  final IntegrationService _service = IntegrationService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedSection = 'Property Listing'; // 'Property Listing' (Owners) or 'Requirement' (Tenants)
  String _selectedSourceFilter = 'All';
  String _selectedDuplicateFilter = 'All';
  CampaignDateFilter _selectedDateFilter = CampaignDateFilter.today; // TODAY IS DEFAULT
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  final Set<String> _selectedLeadIds = {};
  bool _isImporting = false;
  bool _isSyncingSheet = false;
  int _currentPage = 1;
  int _pageSize = 25;
  String _searchQuery = '';
  Timer? _searchDebounce;
  Timer? _uiDebounce;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceUpdate);
    _service.watchCampaignUi();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _uiDebounce?.cancel();
    _service.unwatchCampaignUi();
    _service.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  List<IntegrationLeadModel>? _cachedFilteredLeads;
  int _cachedUniqueLeads = 0;
  int _cachedDupLeads = 0;
  int _cachedImportedCount = 0;
  List<String> _cachedAllDetectedHeaders = [];
  List<String> _cachedVisibleHeaders = [];
  int _cachedPropertyListingCount = 0;
  int _cachedRequirementCount = 0;
  int _cachedAllTimeSectionCount = 0;
  int _cachedCountToday = 0;
  int _cachedCountYesterday = 0;
  int _cachedCountLast7Days = 0;
  int _cachedCountThisMonth = 0;
  int _cachedCountAllTime = 0;
  List<IntegrationLeadModel>? _lastServiceLeadsRef;
  String? _lastSectionFilter;
  String? _lastSourceFilter;
  String? _lastDuplicateFilter;
  CampaignDateFilter? _lastDateFilter;
  DateTime? _lastCustomStartDate;
  DateTime? _lastCustomEndDate;
  String? _lastSearchQuery;

  // Excel Column Filters & Sorting
  final Map<String, Set<String>> _columnFilters = {};
  String? _sortColumn;
  bool _sortAscending = true;
  int? _lastColumnFiltersHash;
  String? _lastSortColumn;
  bool? _lastSortAscending;

  int _computeColumnFiltersHash() {
    int hash = 0;
    for (final entry in _columnFilters.entries) {
      hash ^= entry.key.hashCode;
      for (final val in entry.value) {
        hash ^= val.hashCode;
      }
    }
    return hash;
  }

  String _getDisplayNameForColumn(String columnKey) {
    if (columnKey == '#Source') return 'Source';
    if (columnKey == '#MetaQuality') return 'Meta Rating';
    if (columnKey == '#CrmStatus') return 'Import Status';
    if (columnKey == '#MainCrmStatus') return 'Main CRM Status';

    final clean = columnKey.trim();
    final lower = clean.toLowerCase();

    // Map questions to friendly header titles
    if (lower == 'full_name' || lower == 'name' || lower == 'client name') {
      return _selectedSection == 'Property Listing' ? 'Owner Name' : 'Client Name';
    }
    if (lower == 'phone_number' || lower == 'phone' || lower == 'mobile' || lower == 'number') {
      return 'Phone Number';
    }
    if (lower == 'email' || lower == 'email id') {
      return 'Email ID';
    }
    if (lower.contains('where_is_your_property_located') || lower.contains('where is your property located')) {
      return 'Property Location';
    }
    if (lower.contains('what_type_of_property') || lower.contains('looking_to_rent_out') || lower.contains('rent out')) {
      return 'Property Type';
    }
    if (lower.contains('expected_monthly_rent') || lower.contains('expected monthly rent')) {
      return 'Expected Rent';
    }
    if (lower.contains('complete_address') || lower.contains('complete address')) {
      return 'Property Address';
    }
    if (lower.contains('which_area_are_you_looking') || lower.contains('area are you looking')) {
      return 'Looking Area';
    }
    if (lower.contains('which_location_are_you_looking')) {
      return 'Looking Location';
    }
    if (lower.contains('type_of_home') || lower.contains('type of home')) {
      return 'Home Type';
    }
    if (lower.contains('monthly_rental_budget') || lower.contains('monthly rental budget')) {
      return 'Rental Budget';
    }
    if (lower.contains('staying_in_the_property') || lower.contains('who will be staying')) {
      return 'Who Will Stay';
    }

    if (clean.contains('_')) {
      return clean
          .replaceAll('_', ' ')
          .replaceAll('?', '')
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ')
          .trim();
    }
    return columnKey;
  }

  String _formatDisplayCellValue(String key, String val) {
    if (val.isEmpty) return '-';
    // Format snake_case choices like "vaishnodevi_circle" -> "Vaishnodevi Circle"
    if (val.contains('_') && !val.contains('@') && !val.startsWith('http')) {
      return val
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ')
          .trim();
    }
    return val;
  }

  void _onServiceUpdate() {
    _uiDebounce?.cancel();
    _uiDebounce = Timer(const Duration(milliseconds: 80), () {
      if (mounted) {
        _cachedFilteredLeads = null;
        setState(() {});
      }
    });
  }

  void _recomputeFilteredLeadsIfNeeded() {
    final currentLeads = _service.leads;
    final currentFiltersHash = _computeColumnFiltersHash();

    if (_cachedFilteredLeads != null &&
        identical(_lastServiceLeadsRef, currentLeads) &&
        _lastSectionFilter == _selectedSection &&
        _lastSourceFilter == _selectedSourceFilter &&
        _lastDuplicateFilter == _selectedDuplicateFilter &&
        _lastDateFilter == _selectedDateFilter &&
        _lastCustomStartDate == _customStartDate &&
        _lastCustomEndDate == _customEndDate &&
        _lastSearchQuery == _searchQuery &&
        _lastColumnFiltersHash == currentFiltersHash &&
        _lastSortColumn == _sortColumn &&
        _lastSortAscending == _sortAscending) {
      return;
    }

    _lastServiceLeadsRef = currentLeads;
    _lastSectionFilter = _selectedSection;
    _lastSourceFilter = _selectedSourceFilter;
    _lastDuplicateFilter = _selectedDuplicateFilter;
    _lastDateFilter = _selectedDateFilter;
    _lastCustomStartDate = _customStartDate;
    _lastCustomEndDate = _customEndDate;
    _lastSearchQuery = _searchQuery;
    _lastColumnFiltersHash = currentFiltersHash;
    _lastSortColumn = _sortColumn;
    _lastSortAscending = _sortAscending;

    // Filter by Section First (Property Listing vs Requirement)
    var list = currentLeads.where((l) => l.leadType == _selectedSection).toList();

    // Filter by Date (Today is default, Yesterday, Last 7 Days, This Month, Custom Range, All Time)
    if (_selectedDateFilter != CampaignDateFilter.allTime) {
      list = list.where((l) => CampaignLeadsState.matchesDateFilter(
        l.receivedAt,
        _selectedDateFilter,
        customStart: _customStartDate,
        customEnd: _customEndDate,
      )).toList();
    }

    var u = 0;
    var d = 0;
    var imp = 0;
    for (final lead in list) {
      if (lead.isDuplicate) {
        d++;
      } else {
        u++;
      }
      if (lead.importStatus == 'Imported') imp++;
    }
    _cachedUniqueLeads = u;
    _cachedDupLeads = d;
    _cachedImportedCount = imp;

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
    final query = _searchQuery;
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

    // Excel Column Level Multi-Select Filters
    if (_columnFilters.isNotEmpty) {
      list = list.where((lead) {
        for (final entry in _columnFilters.entries) {
          final colKey = entry.key;
          final allowedValues = entry.value;

          String cellVal;
          if (colKey == '#Source') {
            cellVal = lead.source;
          } else if (colKey == '#MetaQuality') {
            cellVal = lead.qualityStatus;
          } else if (colKey == '#CrmStatus') {
            cellVal = lead.importStatus;
          } else if (colKey == '#MainCrmStatus') {
            cellVal = lead.crmMatch?.inCrm == true
                ? '${lead.crmMatch?.table == 'properties' ? 'In Inventory' : 'In Leads'} (${lead.crmMatch?.status ?? "Active"})'
                : 'Not in CRM';
          } else {
            cellVal = lead.getStringValue(colKey).trim();
          }

          if (cellVal.isEmpty) {
            cellVal = '(Blanks)';
          }

          if (!allowedValues.contains(cellVal)) {
            return false;
          }
        }
        return true;
      }).toList();
    }

    // Excel Column Sorting
    if (_sortColumn != null) {
      list = List<IntegrationLeadModel>.from(list);
      list.sort((a, b) {
        String valA = '';
        String valB = '';
        if (_sortColumn == '#Source') {
          valA = a.source;
          valB = b.source;
        } else if (_sortColumn == '#MetaQuality') {
          valA = a.qualityStatus;
          valB = b.qualityStatus;
        } else if (_sortColumn == '#CrmStatus') {
          valA = a.importStatus;
          valB = b.importStatus;
        } else if (_sortColumn == '#MainCrmStatus') {
          valA = a.crmMatch?.inCrm == true ? 'In CRM' : 'Not in CRM';
          valB = b.crmMatch?.inCrm == true ? 'In CRM' : 'Not in CRM';
        } else {
          valA = a.getStringValue(_sortColumn!).trim();
          valB = b.getStringValue(_sortColumn!).trim();
        }

        final numA = double.tryParse(valA.replaceAll(RegExp(r'[^\d.-]'), ''));
        final numB = double.tryParse(valB.replaceAll(RegExp(r'[^\d.-]'), ''));
        int cmp;
        if (numA != null && numB != null && valA.isNotEmpty && valB.isNotEmpty) {
          cmp = numA.compareTo(numB);
        } else {
          cmp = valA.toLowerCase().compareTo(valB.toLowerCase());
        }
        return _sortAscending ? cmp : -cmp;
      });
    }

    _cachedFilteredLeads = list;

    // Single-pass computation for section counts and date filter counts
    int allTimeSectionCount = 0;
    int propListingCount = 0;
    int reqCount = 0;
    int countToday = 0;
    int countYesterday = 0;
    int countLast7Days = 0;
    int countThisMonth = 0;

    for (final l in currentLeads) {
      final isProp = l.leadType == 'Property Listing';
      final isReq = l.leadType == 'Requirement';
      final isSelectedSec = l.leadType == _selectedSection;

      if (isSelectedSec) {
        allTimeSectionCount++;
        if (CampaignLeadsState.matchesDateFilter(l.receivedAt, CampaignDateFilter.today)) countToday++;
        if (CampaignLeadsState.matchesDateFilter(l.receivedAt, CampaignDateFilter.yesterday)) countYesterday++;
        if (CampaignLeadsState.matchesDateFilter(l.receivedAt, CampaignDateFilter.last7Days)) countLast7Days++;
        if (CampaignLeadsState.matchesDateFilter(l.receivedAt, CampaignDateFilter.thisMonth)) countThisMonth++;
      }

      if (isProp &&
          CampaignLeadsState.matchesDateFilter(l.receivedAt, _selectedDateFilter,
              customStart: _customStartDate, customEnd: _customEndDate)) {
        propListingCount++;
      }
      if (isReq &&
          CampaignLeadsState.matchesDateFilter(l.receivedAt, _selectedDateFilter,
              customStart: _customStartDate, customEnd: _customEndDate)) {
        reqCount++;
      }
    }

    _cachedAllTimeSectionCount = allTimeSectionCount;
    _cachedPropertyListingCount = propListingCount;
    _cachedRequirementCount = reqCount;
    _cachedCountToday = countToday;
    _cachedCountYesterday = countYesterday;
    _cachedCountLast7Days = countLast7Days;
    _cachedCountThisMonth = countThisMonth;
    _cachedCountAllTime = allTimeSectionCount;

    _cachedAllDetectedHeaders = _service.getDetectedHeaders(leadsSubset: list);
    _cachedVisibleHeaders = _service.getActiveVisibleHeaders(leadsSubset: list);
  }

  List<IntegrationLeadModel> get _filteredLeads {
    _recomputeFilteredLeadsIfNeeded();
    return _cachedFilteredLeads!;
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

    final leads = _filteredLeads;
    final allDetectedHeaders = _cachedAllDetectedHeaders;
    final visibleHeaders = _cachedVisibleHeaders;
    final uniqueLeads = _cachedUniqueLeads;
    final dupLeads = _cachedDupLeads;
    final importedCount = _cachedImportedCount;
    final propertyListingCount = _cachedPropertyListingCount;
    final requirementCount = _cachedRequirementCount;
    final totalLeads = leads.length;
    final totalPages = leads.isEmpty ? 1 : (leads.length / _pageSize).ceil();
    final currentPage = _currentPage.clamp(1, totalPages);
    final startIndex = (currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, leads.length);
    final pageLeads = leads.isEmpty ? const <IntegrationLeadModel>[] : leads.sublist(startIndex, endIndex);

    return BlocListener<CampaignLeadsBloc, CampaignLeadsState>(
      listenWhen: (previous, current) =>
          current.newLeadsJustArrivedCount > 0 ||
          (previous.errorMessage == null && current.errorMessage != null),
      listener: (context, state) {
        if (state.newLeadsJustArrivedCount > 0) {
          final count = state.newLeadsJustArrivedCount;
          final names = state.recentlyArrivedLeads.map((l) {
            final n = l.getStringValue('full_name').isNotEmpty
                ? l.getStringValue('full_name')
                : l.getStringValue('name');
            return n.isNotEmpty ? n : 'New Lead';
          }).take(2).join(', ');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '⚡ $count New Meta Lead${count > 1 ? 's' : ''} Received Live!',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          names.isNotEmpty ? '$names • Staged and up to date' : 'All campaign data is up to date.',
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          context.read<CampaignLeadsBloc>().add(const AcknowledgeNewLeadsEvent());
        }
      },
      child: Scaffold(
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
                  trailing: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildAutoSyncLiveBadge(context),
                      CRMButton(
                        label: _service.isFetchingServerLeads ? 'Refreshing...' : 'Refresh Leads',
                        prefixIcon: Icons.refresh_rounded,
                        variant: CRMButtonVariant.outline,
                        height: 40,
                        isLoading: _service.isFetchingServerLeads,
                        onPressed: _service.isFetchingServerLeads
                            ? null
                            : () async {
                                await _service.syncMetaLeads();
                                final count = await _service.fetchServerLeads();
                                if (mounted) {
                                  context.read<CampaignLeadsBloc>().add(const FetchCampaignLeadsEvent(silent: true));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        count > 0
                                            ? 'Synced with Meta! $count leads up to date.'
                                            : 'Campaign leads are up to date.',
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    CRMButton(
                      label: 'Clean Duplicates',
                      prefixIcon: Icons.cleaning_services_rounded,
                      variant: CRMButtonVariant.outline,
                      height: 40,
                      onPressed: () => _cleanDuplicatesDialog(context),
                    ),
                    CRMButton(
                      label: _isSyncingSheet ? 'Syncing...' : 'Sync Google Sheet',
                      prefixIcon: Icons.sync_rounded,
                      variant: CRMButtonVariant.outline,
                      height: 40,
                      isLoading: _isSyncingSheet,
                      onPressed: _isSyncingSheet ? null : () => _syncGoogleSheet(context),
                    ),
                    CRMButton(
                      label: 'Export Excel',
                      prefixIcon: Icons.table_view_rounded,
                      variant: CRMButtonVariant.outline,
                      height: 40,
                      onPressed: () => _exportCurrentSpreadsheetToExcel(context),
                    ),
                    CRMButton(
                      label: 'Import CSV',
                      prefixIcon: Icons.upload_file_rounded,
                      variant: CRMButtonVariant.outline,
                      height: 40,
                      onPressed: () => _importCsvFile(context),
                    ),
                    CRMButton(
                      label: _isImporting
                          ? 'Moving...'
                          : (_selectedSection == 'Property Listing' ? 'Move to Properties page' : 'Move to Leads page'),
                      prefixIcon: _selectedSection == 'Property Listing'
                          ? Icons.home_work_rounded
                          : Icons.drive_file_move_rounded,
                      height: 40,
                      isLoading: _isImporting,
                      onPressed: _isImporting
                          ? null
                          : () => _selectedSection == 'Property Listing'
                              ? _moveSelectedToPropertiesPage(context)
                              : _moveSelectedToLeadsPage(context),
                    ),
                    CRMButton(
                      label: 'Paste JSON',
                      prefixIcon: Icons.code_rounded,
                      variant: CRMButtonVariant.outline,
                      height: 40,
                      onPressed: () => _showPasteJsonDialog(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: CRMSpacing.m),

              // Dual-Section Segmented Tab Switcher (Property Listing Leads vs Requirement Leads)
              _buildLeadTypeSegmentedControl(context, propertyListingCount, requirementCount),

              const SizedBox(height: CRMSpacing.m),

              // Date Range Filter Bar (Today default, Yesterday, Last 7 Days, This Month, Custom Range, All Time)
              _buildDateFilterBar(context),

              // Notice Banner when viewing Today
              _buildTodayNoticeBanner(context, totalLeads, _cachedAllTimeSectionCount),

              const SizedBox(height: CRMSpacing.m),

              // KPI Analytics Cards (Compact)
              _buildKpiMetricsRow(context, totalLeads, uniqueLeads, dupLeads, importedCount),

              const SizedBox(height: CRMSpacing.m),

              // Batch Actions Bar when checkboxes are selected
              if (_selectedLeadIds.isNotEmpty) ...[
                _buildBatchActionBar(context, leads),
                const SizedBox(height: CRMSpacing.m),
              ],

              // Excel Active Filters Chips Bar
              _buildActiveFiltersBar(context),

              // Excel-like Interactive Spreadsheet Section
              _buildExcelSpreadsheetCard(context, allDetectedHeaders, visibleHeaders, leads, pageLeads, startIndex, currentPage, totalPages),
            ],
          ),
        ),
      ),
    ),
  );
}

  // --- WIDGETS ---

  Widget _buildLeadTypeSegmentedControl(BuildContext context, int propCount, int reqCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSectionTabItem(
              context: context,
              title: 'Property Listing Leads',
              subtitle: 'Owners listing properties for rent -> destination: Properties page',
              icon: Icons.home_work_rounded,
              count: propCount,
              badgeColor: const Color(0xFF0284C7),
              isSelected: _selectedSection == 'Property Listing',
              onTap: () {
                if (_selectedSection != 'Property Listing') {
                  setState(() {
                    _selectedSection = 'Property Listing';
                    _selectedLeadIds.clear();
                    _currentPage = 1;
                    _cachedFilteredLeads = null;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSectionTabItem(
              context: context,
              title: 'Requirement Leads',
              subtitle: 'Tenants searching for rental homes -> destination: Leads page',
              icon: Icons.people_alt_rounded,
              count: reqCount,
              badgeColor: const Color(0xFF10B981),
              isSelected: _selectedSection == 'Requirement',
              onTap: () {
                if (_selectedSection != 'Requirement') {
                  setState(() {
                    _selectedSection = 'Requirement';
                    _selectedLeadIds.clear();
                    _currentPage = 1;
                    _cachedFilteredLeads = null;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required int count,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? const Color(0xFF262E3D) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          border: isSelected
              ? Border.all(color: CRMColors.primaryOf(context).withOpacity(0.4), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? CRMColors.primaryOf(context).withOpacity(0.15)
                    : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected ? CRMColors.primaryOf(context) : CRMColors.textSecondaryOf(context),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected
                                ? CRMColors.textOf(context)
                                : CRMColors.textSecondaryOf(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? badgeColor : badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: CRMColors.textSecondaryOf(context).withOpacity(0.85),
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

  Widget _buildKpiMetricsRow(BuildContext context, int total, int unique, int dups, int imported) {
    final destinationLabel = _selectedSection == 'Property Listing' ? 'In Inventory' : 'In CRM Leads';
    final destinationIcon = _selectedSection == 'Property Listing' ? Icons.home_work_rounded : Icons.contacts_rounded;
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
              _buildMetricItem(context, destinationLabel, imported.toString(), destinationIcon, CRMColors.info),
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
        _buildMetricItem(context, destinationLabel, imported.toString(), destinationIcon, CRMColors.info),
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

  // --- DATE RANGE FILTERS & LIVE 1-MINUTE HEARTBEAT ---

  Widget _buildDateFilterBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Read pre-computed counters directly from cache (O(1) instant build)
    final countToday = _cachedCountToday;
    final countYesterday = _cachedCountYesterday;
    final countLast7Days = _cachedCountLast7Days;
    final countThisMonth = _cachedCountThisMonth;
    final countAllTime = _cachedCountAllTime;

    String customRangeLabel = 'Custom Range';
    if (_customStartDate != null && _customEndDate != null) {
      final f = DateFormat('d MMM');
      customRangeLabel = '${f.format(_customStartDate!)} - ${f.format(_customEndDate!)}';
    }

    final items = [
      (CampaignDateFilter.today, 'Today', countToday, Icons.today_rounded),
      (CampaignDateFilter.yesterday, 'Yesterday', countYesterday, Icons.history_rounded),
      (CampaignDateFilter.last7Days, 'Last 7 Days', countLast7Days, Icons.date_range_rounded),
      (CampaignDateFilter.thisMonth, 'This Month', countThisMonth, Icons.calendar_month_rounded),
      (CampaignDateFilter.customRange, customRangeLabel, null, Icons.calendar_today_rounded),
      (CampaignDateFilter.allTime, 'All Time', countAllTime, Icons.all_inclusive_rounded),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.borderOf(context)),
        boxShadow: CRMShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_rounded, size: 16, color: CRMColors.primaryOf(context)),
              const SizedBox(width: 8),
              Text(
                'DATE FILTER:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
              const SizedBox(width: 6),
              if (_selectedDateFilter == CampaignDateFilter.today)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'DEFAULT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              const Spacer(),
              // 1-minute ping heartbeat badge
              _buildOneMinutePingBadge(context),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: items.map((item) {
                final filter = item.$1;
                final label = item.$2;
                final count = item.$3;
                final icon = item.$4;
                final isSelected = _selectedDateFilter == filter;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (filter == CampaignDateFilter.customRange) {
                        _pickCustomDateRange(context);
                      } else {
                        setState(() {
                          _selectedDateFilter = filter;
                          _cachedFilteredLeads = null;
                          _currentPage = 1;
                        });
                        context.read<CampaignLeadsBloc>().add(
                          SetCampaignDateFilterEvent(filter: filter),
                        );
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? CRMColors.primaryOf(context)
                            : (isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? CRMColors.primaryOf(context)
                              : CRMColors.borderOf(context),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 14,
                            color: isSelected ? Colors.white : CRMColors.textSecondaryOf(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              color: isSelected ? Colors.white : CRMColors.textOf(context),
                            ),
                          ),
                          if (count != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withOpacity(0.25)
                                    : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : CRMColors.textSecondaryOf(context),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOneMinutePingBadge(BuildContext context) {
    return BlocBuilder<CampaignLeadsBloc, CampaignLeadsState>(
      builder: (context, state) {
        final lastPing = state.lastPingAt;
        String pingText = 'Live ping: 1m';
        if (state.isPinging) {
          pingText = 'Pinging Meta...';
        } else if (lastPing != null) {
          final diff = DateTime.now().difference(lastPing);
          if (diff.inSeconds < 60) {
            pingText = 'Live • Just now';
          } else {
            pingText = 'Live • ${diff.inMinutes}m ago';
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                pingText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayNoticeBanner(BuildContext context, int totalLeads, int allTimeCount) {
    if (_selectedDateFilter != CampaignDateFilter.today) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: CRMSpacing.s),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 12, color: CRMColors.textOf(context)),
                children: [
                  const TextSpan(text: 'Showing '),
                  TextSpan(
                    text: "Today's leads ($totalLeads)",
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0284C7)),
                  ),
                  const TextSpan(text: ' by default. Fresh leads arrive automatically every 1 minute.'),
                ],
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              setState(() {
                _selectedDateFilter = CampaignDateFilter.allTime;
                _cachedFilteredLeads = null;
                _currentPage = 1;
              });
              context.read<CampaignLeadsBloc>().add(
                const SetCampaignDateFilterEvent(filter: CampaignDateFilter.allTime),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All ($allTimeCount)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0284C7),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF0284C7)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
    );

    if (picked != null) {
      setState(() {
        _selectedDateFilter = CampaignDateFilter.customRange;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _cachedFilteredLeads = null;
        _currentPage = 1;
      });
      context.read<CampaignLeadsBloc>().add(
        SetCampaignDateFilterEvent(
          filter: CampaignDateFilter.customRange,
          customStart: picked.start,
          customEnd: picked.end,
        ),
      );
    }
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

          // Move cleaned campaign leads to appropriate CRM destination
          CRMButton(
            label: _isImporting
                ? 'Moving...'
                : (_selectedSection == 'Property Listing' ? 'Move to Properties page ($count)' : 'Move to Leads page ($count)'),
            prefixIcon: _selectedSection == 'Property Listing' ? Icons.home_work_rounded : Icons.drive_file_move_rounded,
            variant: CRMButtonVariant.primary,
            height: 36,
            isLoading: _isImporting,
            onPressed: () => _selectedSection == 'Property Listing'
                ? _moveSelectedToPropertiesPage(context)
                : _moveSelectedToLeadsPage(context),
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
    List<IntegrationLeadModel> pageLeads,
    int startIndex,
    int currentPage,
    int totalPages,
  ) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 700;

    final reorderColumnsButton = SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.swap_horiz_rounded, size: 15),
        label: const Text('Reorder Columns'),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onPressed: () => _showReorderColumnsDialog(context),
      ),
    );

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

    final exportExcelButton = SizedBox(
      height: 36,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.table_view_rounded, size: 15),
        label: const Text('Export Excel'),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        onPressed: () => _exportCurrentSpreadsheetToExcel(context),
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
        if (action == 'reorder') {
          _showReorderColumnsDialog(context);
        } else if (action == 'export') {
          _exportCurrentSpreadsheetToExcel(context);
        } else if (action == 'clear_filters') {
          setState(() {
            _columnFilters.clear();
            _sortColumn = null;
            _sortAscending = true;
            _cachedFilteredLeads = null;
            _currentPage = 1;
          });
        } else if (action == 'merge') {
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
        } else if (action == 'csv') {
          _importCsvFile(context);
        } else if (action == 'sheet') {
          _syncGoogleSheet(context);
        } else if (action == 'clear') {
          _confirmClearAllLeadsDialog(context);
        }
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'reorder',
          child: Row(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 16),
              SizedBox(width: 8),
              Text('Reorder Columns (Drag & Drop)'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.table_view_rounded, size: 16),
              SizedBox(width: 8),
              Text('Export Spreadsheet to Excel (.xlsx)'),
            ],
          ),
        ),
        if (_columnFilters.isNotEmpty || _sortColumn != null)
          const PopupMenuItem(
            value: 'clear_filters',
            child: Row(
              children: [
                Icon(Icons.filter_alt_off_rounded, size: 16, color: CRMColors.danger),
                SizedBox(width: 8),
                Text('Clear All Column Filters', style: TextStyle(color: CRMColors.danger)),
              ],
            ),
          ),
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
          value: 'csv',
          child: Row(
            children: [
              Icon(Icons.upload_file_rounded, size: 18),
              SizedBox(width: 10),
              Text('Import CSV / Google Sheet export'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'sheet',
          child: Row(
            children: [
              Icon(Icons.sync_rounded, size: 18),
              SizedBox(width: 10),
              Text('Sync connected Google Sheet'),
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
        onChanged: (value) {
          _searchDebounce?.cancel();
          _searchDebounce = Timer(const Duration(milliseconds: 250), () {
            if (!mounted) return;
            setState(() {
              _searchQuery = value.trim().toLowerCase();
              _currentPage = 1;
            });
          });
        },
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
            if (val != null) {
              setState(() {
                _selectedSourceFilter = val;
                _currentPage = 1;
              });
            }
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
            if (val != null) {
              setState(() {
                _selectedDuplicateFilter = val;
                _currentPage = 1;
              });
            }
          },
        ),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: CRMCard(
        elevated: true,
        title: 'Spreadsheet view',
        subtitle: isMobile
            ? null
            : 'Exact Google Sheet column sequence with drag-and-place reordering, Excel-style filtration & sorting.',
        headerAction: isMobile
            ? moreToolsButton
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  reorderColumnsButton,
                  const SizedBox(width: CRMSpacing.s),
                  columnsButton,
                  const SizedBox(width: CRMSpacing.s),
                  exportExcelButton,
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
                  reorderColumnsButton,
                  columnsButton,
                  exportExcelButton,
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
                        'Connect your Google Sheet, then Sync or Import CSV. Leads stay here until you filter, delete fakes, and click Move to Leads page.',
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
            else ...[
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
                        child: DataTable(
                      showCheckboxColumn: true,
                      onSelectAll: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedLeadIds.addAll(pageLeads.map((l) => l.id));
                          } else {
                            for (final lead in pageLeads) {
                              _selectedLeadIds.remove(lead.id);
                            }
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
                        _buildExcelDataColumn(context, title: 'Source', columnKey: '#Source', isStandard: true),
                        _buildExcelDataColumn(context, title: 'Meta Rating', columnKey: '#MetaQuality', isStandard: true),
                        _buildExcelDataColumn(context, title: 'Import Status', columnKey: '#CrmStatus', isStandard: true),
                        _buildExcelDataColumn(context, title: 'Main CRM Status', columnKey: '#MainCrmStatus', isStandard: true),

                        // Dynamic Column Headers (Only Visible Ones, strictly preserving Google Sheet / user drag-and-place order)
                        ...visibleHeaders.map((header) {
                          final crmTarget = _service.columnMappings[header];
                          return _buildExcelDataColumn(
                            context,
                            title: header,
                            columnKey: header,
                            crmTarget: crmTarget,
                            isStandard: false,
                          );
                        }),

                        const DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: pageLeads.asMap().entries.map((entry) {
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
                            DataCell(Text('${startIndex + index + 1}')),

                            // Source Badge + Enquiry Frequency Badge
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
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
                                  if (lead.enquiryCount > 1) ...[
                                    const SizedBox(width: 6),
                                    Tooltip(
                                      message: 'Enquired ${lead.enquiryCount} times across campaigns',
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: CRMColors.primaryOf(context).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: CRMColors.primaryOf(context).withValues(alpha: 0.4)),
                                        ),
                                        child: Text(
                                          '${lead.enquiryCount}x',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: CRMColors.primaryOf(context),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
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

                            // Main CRM Status Comparison Cell
                            DataCell(
                              Builder(
                                builder: (context) {
                                  final isDark = Theme.of(context).brightness == Brightness.dark;
                                  final match = lead.crmMatch;
                                  final inCrm = match?.inCrm == true;

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: inCrm
                                          ? const Color(0xFF10B981).withValues(alpha: 0.14)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: inCrm
                                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                            : CRMColors.borderOf(context),
                                      ),
                                    ),
                                    child: Tooltip(
                                      message: inCrm
                                          ? '${match?.name ?? ""}\n${match?.details ?? ""}\nMatched in: ${match?.table ?? "CRM"}'
                                          : 'Lead is not yet in Main Leads or Properties inventory',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            inCrm ? Icons.check_circle_rounded : Icons.fiber_new_rounded,
                                            size: 13,
                                            color: inCrm ? const Color(0xFF10B981) : CRMColors.textSecondaryOf(context),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            inCrm
                                                ? '${match?.table == 'properties' ? 'In Inventory' : 'In Leads'}: ${match?.status ?? "Active"}'
                                                : 'Not in CRM',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: inCrm ? const Color(0xFF10B981) : CRMColors.textSecondaryOf(context),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Dynamic Visible Cells mapped to JSON keys
                            ...visibleHeaders.map((header) {
                              final val = lead.getStringValue(header);
                              return DataCell(
                                Text(
                                  _formatDisplayCellValue(header, val),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
        const SizedBox(height: CRMSpacing.s),
        _buildCampaignPager(context, leads.length, startIndex, currentPage, totalPages),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCampaignPager(
    BuildContext context,
    int totalFiltered,
    int startIndex,
    int currentPage,
    int totalPages,
  ) {
    final from = totalFiltered == 0 ? 0 : startIndex + 1;
    final to = (startIndex + _pageSize).clamp(0, totalFiltered);
    return Row(
      children: [
        Text(
          'Showing $from–$to of $totalFiltered leads',
          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 32,
          decoration: BoxDecoration(
            color: CRMColors.cardBgOf(context),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: CRMColors.borderOf(context)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _pageSize,
              items: const [
                DropdownMenuItem(value: 25, child: Text('25 / page', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 50, child: Text('50 / page', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 100, child: Text('100 / page', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val == null) return;
                setState(() {
                  _pageSize = val;
                  _currentPage = 1;
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          tooltip: 'First page',
          onPressed: currentPage <= 1
              ? null
              : () => setState(() => _currentPage = 1),
          icon: const Icon(Icons.first_page_rounded, size: 20),
        ),
        IconButton(
          tooltip: 'Previous page',
          onPressed: currentPage <= 1
              ? null
              : () => setState(() => _currentPage = currentPage - 1),
          icon: const Icon(Icons.chevron_left_rounded, size: 20),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: CRMColors.surfaceElevatedOf(context),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: CRMColors.borderOf(context)),
          ),
          child: Text(
            'Page $currentPage of $totalPages',
            style: CRMTypography.caption.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          tooltip: 'Next page',
          onPressed: currentPage >= totalPages
              ? null
              : () => setState(() => _currentPage = currentPage + 1),
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
        ),
        IconButton(
          tooltip: 'Last page',
          onPressed: currentPage >= totalPages
              ? null
              : () => setState(() => _currentPage = totalPages),
          icon: const Icon(Icons.last_page_rounded, size: 20),
        ),
      ],
    );
  }

  // --- EXCEL FEATURES, FILTERING, SORTING & DRAG-AND-PLACE REORDERING ---

  /// Live Auto-Sync Status Badge (1-minute engine indicator)
  Widget _buildAutoSyncLiveBadge(BuildContext context) {
    final hasSheet = _service.googleSheetUrl.isNotEmpty;
    final lastSync = _service.lastSyncAt;

    String syncTimeText;
    if (!hasSheet) {
      syncTimeText = 'Sheet not connected';
    } else if (_isSyncingSheet) {
      syncTimeText = 'Syncing now...';
    } else if (lastSync == null) {
      syncTimeText = 'Engine active (1 min)';
    } else {
      final diff = DateTime.now().difference(lastSync);
      if (diff.inSeconds < 60) {
        syncTimeText = 'Synced just now';
      } else if (diff.inMinutes < 60) {
        syncTimeText = 'Synced ${diff.inMinutes}m ago';
      } else {
        syncTimeText = 'Synced at ${DateFormat('HH:mm').format(lastSync.toLocal())}';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: hasSheet
            ? CRMColors.success.withValues(alpha: 0.1)
            : CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.input),
        border: Border.all(
          color: hasSheet
              ? CRMColors.success.withValues(alpha: 0.35)
              : CRMColors.borderOf(context),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasSheet ? CRMColors.success : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            hasSheet ? 'Auto-sync: 1 min' : 'Auto-sync: Idle',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: hasSheet ? CRMColors.success : CRMColors.textSecondaryOf(context),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '• $syncTimeText',
            style: TextStyle(
              fontSize: 11,
              color: CRMColors.textSecondaryOf(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Active Filters Bar (Excel-Style filter chips row)
  Widget _buildActiveFiltersBar(BuildContext context) {
    if (_columnFilters.isEmpty && _sortColumn == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.m),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CRMColors.primaryOf(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CRMColors.primaryOf(context).withValues(alpha: 0.2)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_alt_rounded, size: 16, color: CRMColors.primaryOf(context)),
              const SizedBox(width: 4),
              Text(
                'Excel Filters (${_columnFilters.length + (_sortColumn != null ? 1 : 0)} active):',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: CRMColors.primaryOf(context),
                ),
              ),
            ],
          ),

          // Chips for each filtered column
          ..._columnFilters.entries.map((entry) {
            final colKey = entry.key;
            final values = entry.value;
            final colName = _getDisplayNameForColumn(colKey);

            final summary = values.length <= 2
                ? values.join(', ')
                : '${values.first} +${values.length - 1} more';

            return Chip(
              label: Text('$colName: $summary', style: const TextStyle(fontSize: 11)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () {
                setState(() {
                  _columnFilters.remove(colKey);
                  _cachedFilteredLeads = null;
                  _currentPage = 1;
                });
              },
              backgroundColor: CRMColors.cardBgOf(context),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }),

          // Chip for active sort
          if (_sortColumn != null)
            Chip(
              avatar: Icon(
                _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: CRMColors.primaryOf(context),
              ),
              label: Text(
                'Sorted: ${_getDisplayNameForColumn(_sortColumn!)} (${_sortAscending ? "A-Z" : "Z-A"})',
                style: const TextStyle(fontSize: 11),
              ),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () {
                setState(() {
                  _sortColumn = null;
                  _sortAscending = true;
                  _cachedFilteredLeads = null;
                });
              },
              backgroundColor: CRMColors.cardBgOf(context),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),

          // Clear All Filters button
          TextButton(
            onPressed: () {
              setState(() {
                _columnFilters.clear();
                _sortColumn = null;
                _sortAscending = true;
                _cachedFilteredLeads = null;
                _currentPage = 1;
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              'Clear All Filters',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CRMColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  /// DataColumn builder with Excel-Style Filter Badge & Sort Arrows
  DataColumn _buildExcelDataColumn(
    BuildContext context, {
    required String title,
    required String columnKey,
    String? crmTarget,
    bool isStandard = false,
  }) {
    final isFiltered = _columnFilters.containsKey(columnKey);
    final isSorted = _sortColumn == columnKey;

    return DataColumn(
      label: InkWell(
        onTap: () {
          if (isStandard) {
            _showExcelColumnFilterDialog(context, columnKey, columnTitle: title);
          } else {
            _showHeaderOptionsDialog(context, columnKey);
          }
        },
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
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isFiltered ? CRMColors.primaryOf(context) : null,
                      ),
                    ),
                    if (isSorted) ...[
                      const SizedBox(width: 4),
                      Icon(
                        _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 14,
                        color: CRMColors.primaryOf(context),
                      ),
                    ],
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _showExcelColumnFilterDialog(context, columnKey, columnTitle: title),
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                        decoration: isFiltered
                            ? BoxDecoration(
                                color: CRMColors.primaryOf(context).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              )
                            : null,
                        child: Icon(
                          isFiltered ? Icons.filter_alt_rounded : Icons.arrow_drop_down,
                          size: 16,
                          color: isFiltered ? CRMColors.primaryOf(context) : Colors.grey,
                        ),
                      ),
                    ),
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
  }

  /// Excel-Style Column Filter & Sort Dialog (Distinct values checkboxes, A-Z/Z-A sorting, Search)
  void _showExcelColumnFilterDialog(
    BuildContext context,
    String columnKey, {
    required String columnTitle,
  }) {
    final distinctValueCounts = <String, int>{};
    for (final lead in _service.leads) {
      String val;
      if (columnKey == '#Source') {
        val = lead.source;
      } else if (columnKey == '#MetaQuality') {
        val = lead.qualityStatus;
      } else if (columnKey == '#CrmStatus') {
        val = lead.importStatus;
      } else if (columnKey == '#MainCrmStatus') {
        val = lead.crmMatch?.inCrm == true
            ? '${lead.crmMatch?.table == 'properties' ? 'In Inventory' : 'In Leads'} (${lead.crmMatch?.status ?? "Active"})'
            : 'Not in CRM';
      } else {
        val = lead.getStringValue(columnKey).trim();
      }
      if (val.isEmpty) val = '(Blanks)';
      distinctValueCounts[val] = (distinctValueCounts[val] ?? 0) + 1;
    }

    final allDistinctValues = distinctValueCounts.keys.toList()
      ..sort((a, b) {
        if (a == '(Blanks)') return 1;
        if (b == '(Blanks)') return -1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    final currentlySelected = _columnFilters.containsKey(columnKey)
        ? Set<String>.from(_columnFilters[columnKey]!)
        : Set<String>.from(allDistinctValues);

    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final query = searchController.text.trim().toLowerCase();
          final visibleValues = query.isEmpty
              ? allDistinctValues
              : allDistinctValues.where((v) => v.toLowerCase().contains(query)).toList();

          final isAllVisibleSelected = visibleValues.isNotEmpty &&
              visibleValues.every((v) => currentlySelected.contains(v));

          final isCurrentlySortedAsc = _sortColumn == columnKey && _sortAscending;
          final isCurrentlySortedDesc = _sortColumn == columnKey && !_sortAscending;

          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            title: Row(
              children: [
                Icon(Icons.filter_alt_rounded, color: CRMColors.primaryOf(context), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filter & Sort: $columnTitle',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Excel Sort Section
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CRMColors.surfaceElevatedOf(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CRMColors.borderOf(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(
                              Icons.arrow_upward_rounded,
                              size: 15,
                              color: isCurrentlySortedAsc ? CRMColors.primaryOf(context) : null,
                            ),
                            label: Text(
                              'Sort A to Z',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrentlySortedAsc ? FontWeight.bold : FontWeight.normal,
                                color: isCurrentlySortedAsc ? CRMColors.primaryOf(context) : null,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isCurrentlySortedAsc
                                  ? CRMColors.primaryOf(context).withValues(alpha: 0.1)
                                  : null,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () {
                              setState(() {
                                _sortColumn = columnKey;
                                _sortAscending = true;
                                _cachedFilteredLeads = null;
                              });
                              setModalState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(
                              Icons.arrow_downward_rounded,
                              size: 15,
                              color: isCurrentlySortedDesc ? CRMColors.primaryOf(context) : null,
                            ),
                            label: Text(
                              'Sort Z to A',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrentlySortedDesc ? FontWeight.bold : FontWeight.normal,
                                color: isCurrentlySortedDesc ? CRMColors.primaryOf(context) : null,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: isCurrentlySortedDesc
                                  ? CRMColors.primaryOf(context).withValues(alpha: 0.1)
                                  : null,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () {
                              setState(() {
                                _sortColumn = columnKey;
                                _sortAscending = false;
                                _cachedFilteredLeads = null;
                              });
                              setModalState(() {});
                            },
                          ),
                        ),
                        if (_sortColumn == columnKey) ...[
                          const SizedBox(width: 6),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            tooltip: 'Clear Sort',
                            onPressed: () {
                              setState(() {
                                _sortColumn = null;
                                _sortAscending = true;
                                _cachedFilteredLeads = null;
                              });
                              setModalState(() {});
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Search values within this column
                  SizedBox(
                    height: 36,
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search values in this column...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 16),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 14),
                                onPressed: () {
                                  searchController.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Select All / Deselect All
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            if (isAllVisibleSelected) {
                              currentlySelected.removeAll(visibleValues);
                            } else {
                              currentlySelected.addAll(visibleValues);
                            }
                          });
                        },
                        child: Text(
                          isAllVisibleSelected ? 'Deselect All' : '(Select All)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${currentlySelected.length} of ${allDistinctValues.length} selected',
                        style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context)),
                      ),
                    ],
                  ),

                  const Divider(height: 1),

                  // Unique values checkbox list
                  SizedBox(
                    height: 200,
                    child: visibleValues.isEmpty
                        ? const Center(child: Text('No matching values', style: TextStyle(fontSize: 12, color: Colors.grey)))
                        : ListView.builder(
                            itemCount: visibleValues.length,
                            itemBuilder: (ctx, i) {
                              final val = visibleValues[i];
                              final isChecked = currentlySelected.contains(val);
                              final count = distinctValueCounts[val] ?? 0;

                              return CheckboxListTile(
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                                value: isChecked,
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        val,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: val == '(Blanks)' ? FontStyle.italic : FontStyle.normal,
                                          color: val == '(Blanks)' ? CRMColors.textSecondaryOf(context) : null,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: CRMColors.surfaceElevatedOf(context),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                onChanged: (checked) {
                                  setModalState(() {
                                    if (checked == true) {
                                      currentlySelected.add(val);
                                    } else {
                                      currentlySelected.remove(val);
                                    }
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
              if (_columnFilters.containsKey(columnKey))
                TextButton(
                  onPressed: () {
                    setState(() {
                      _columnFilters.remove(columnKey);
                      _cachedFilteredLeads = null;
                      _currentPage = 1;
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Clear Filter', style: TextStyle(color: CRMColors.danger)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (currentlySelected.length >= allDistinctValues.length) {
                      _columnFilters.remove(columnKey);
                    } else {
                      _columnFilters[columnKey] = Set<String>.from(currentlySelected);
                    }
                    _cachedFilteredLeads = null;
                    _currentPage = 1;
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Drag-and-Drop Column Reordering Dialog
  void _showReorderColumnsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final allHeaders = _service.getDetectedHeaders();

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.swap_horiz_rounded, color: CRMColors.primaryOf(context)),
                const SizedBox(width: 8),
                const Text('Reorder Spreadsheet Columns'),
              ],
            ),
            content: SizedBox(
              width: 520,
              height: 440,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Drag and drop columns using the handles (⠿) to change their display order. The layout is saved automatically and matches the Google Sheet sequence by default.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${allHeaders.length} Columns',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.restore_page_rounded, size: 16),
                        label: const Text('Reset to Sheet Order'),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await _service.resetHeaderOrderToSheet();
                          setModalState(() {});
                          setState(() {});
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Reset column order to original Google Sheet sequence.')),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 8),
                  Expanded(
                    child: ReorderableListView.builder(
                      itemCount: allHeaders.length,
                      onReorder: (oldIndex, newIndex) async {
                        await _service.reorderHeaders(oldIndex, newIndex);
                        setModalState(() {});
                        setState(() {});
                      },
                      itemBuilder: (ctx, i) {
                        final h = allHeaders[i];
                        final isVisible = _service.isHeaderVisible(h);
                        final crmTarget = _service.columnMappings[h];

                        return ListTile(
                          key: ValueKey('reorder_$h'),
                          dense: true,
                          leading: const Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                          title: Row(
                            children: [
                              Text(
                                '${i + 1}. ',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                              ),
                              Expanded(
                                child: Text(
                                  h,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    decoration: isVisible ? null : TextDecoration.lineThrough,
                                    color: isVisible ? null : Colors.grey,
                                  ),
                                ),
                              ),
                              if (crmTarget != null)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Quick shift up/down buttons
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18),
                                tooltip: 'Move Up',
                                onPressed: i > 0
                                    ? () async {
                                        await _service.moveHeader(h, -1);
                                        setModalState(() {});
                                        setState(() {});
                                      }
                                    : null,
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                                tooltip: 'Move Down',
                                onPressed: i < allHeaders.length - 1
                                    ? () async {
                                        await _service.moveHeader(h, 1);
                                        setModalState(() {});
                                        setState(() {});
                                      }
                                    : null,
                              ),
                              Switch(
                                value: isVisible,
                                activeThumbColor: CRMColors.primaryOf(context),
                                onChanged: (val) {
                                  _service.setHeaderVisibility(h, val);
                                  setModalState(() {});
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
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
      ),
    );
  }

  /// Export current filtered spreadsheet directly to genuine Excel (.xlsx)
  Future<void> _exportCurrentSpreadsheetToExcel(BuildContext context) async {
    final leadsToExport = _filteredLeads;
    if (leadsToExport.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No leads match the current filters to export.')),
      );
      return;
    }

    final visibleHeaders = _service.getActiveVisibleHeaders();
    final excel = xl.Excel.createExcel();
    final sheet = excel['Campaign Leads'];

    // Header Row
    final headerCells = <xl.CellValue>[
      xl.TextCellValue('#'),
      xl.TextCellValue('Source'),
      xl.TextCellValue('Meta Quality'),
      xl.TextCellValue('CRM Status'),
      ...visibleHeaders.map((h) => xl.TextCellValue(h)),
      xl.TextCellValue('Received Date'),
    ];
    sheet.appendRow(headerCells);

    // Data Rows
    for (var i = 0; i < leadsToExport.length; i++) {
      final lead = leadsToExport[i];
      final rowCells = <xl.CellValue>[
        xl.IntCellValue(i + 1),
        xl.TextCellValue(lead.source),
        xl.TextCellValue(lead.qualityStatus),
        xl.TextCellValue(lead.importStatus),
        ...visibleHeaders.map((h) => xl.TextCellValue(lead.getStringValue(h))),
        xl.TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(lead.receivedAt)),
      ];
      sheet.appendRow(rowCells);
    }

    final bytes = excel.save();
    if (bytes != null) {
      final filename = 'PropKart_Campaign_Leads_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      await FileDownloader.download(bytes, filename);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${leadsToExport.length} lead(s) to Excel ($filename).'),
            backgroundColor: CRMColors.success,
          ),
        );
      }
    }
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
                const Divider(height: 20),
                ListTile(
                  leading: Icon(Icons.filter_alt_rounded, color: CRMColors.primaryOf(context)),
                  title: const Text('Excel Filter & Sort...', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Filter distinct values, sort A-Z / Z-A', style: TextStyle(fontSize: 11)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showExcelColumnFilterDialog(context, header, columnTitle: header);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_back_rounded),
                  title: const Text('Move Column Left'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _service.moveHeader(header, -1);
                    if (mounted) setState(() {});
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_forward_rounded),
                  title: const Text('Move Column Right'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _service.moveHeader(header, 1);
                    if (mounted) setState(() {});
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded),
                  title: const Text('Reorder All Columns (Drag & Drop)'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReorderColumnsDialog(context);
                  },
                ),
                const Divider(height: 20),
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
                if (lead.crmMatch?.inCrm == true) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Already in ${lead.crmMatch?.table == "properties" ? "Properties Inventory" : "Main Leads"}: ${lead.crmMatch?.name} (${lead.crmMatch?.status})\n${lead.crmMatch?.details ?? ""}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF047857)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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

  Future<void> _syncGoogleSheet(BuildContext context) async {
    if (_service.googleSheetUrl.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste your Google Sheet link on Campaign → Connections first.')),
      );
      return;
    }
    setState(() => _isSyncingSheet = true);
    try {
      final count = await _service.syncGoogleSheet();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count == 0
                ? (_service.lastSyncError ?? 'No new rows found in the Google Sheet.')
                : 'Synced $count row(s) into Campaign Leads. Filter and clean them here, then click Move to Leads page.',
          ),
          backgroundColor: count == 0 ? null : CRMColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_service.lastSyncError ?? e.toString()),
          backgroundColor: CRMColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncingSheet = false);
    }
  }

  Future<void> _importCsvFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    if (file.bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that file. Try exporting the sheet as CSV again.')),
      );
      return;
    }
    final csv = utf8.decode(file.bytes!);
    setState(() => _isSyncingSheet = true);
    try {
      final count = await _service.ingestCsv(csv);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported $count row(s) into Campaign Leads. Clean them here, then click Move to Leads page.'),
          backgroundColor: CRMColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV import failed: $e'), backgroundColor: CRMColors.danger),
      );
    } finally {
      if (mounted) setState(() => _isSyncingSheet = false);
    }
  }

  Future<void> _moveSelectedToPropertiesPage(BuildContext context) async {
    final selected = _selectedLeadIds.toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select the property listing leads you want to move.')),
      );
      return;
    }

    final pendingIds = _service.leads
        .where((l) => selected.contains(l.id) && l.importStatus != 'Imported')
        .map((l) => l.id)
        .toList();

    if (pendingIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Those property leads were already moved to the Properties page.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.home_work_rounded, color: CRMColors.primaryOf(context)),
            const SizedBox(width: 8),
            const Text('Move to Properties page?'),
          ],
        ),
        content: Text(
          'Move ${pendingIds.length} Property Listing lead(s) to your Properties inventory?\n\n'
          'Each will be added as a rental inventory item with Owner Name, Mobile, Expected Rent, Location, and Property Type.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton.icon(
            icon: const Icon(Icons.home_work_rounded, size: 16),
            onPressed: () => Navigator.pop(ctx, true),
            label: const Text('Move to Properties page'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isImporting = true);
    final count = await _service.importLeadsToProperties(pendingIds);
    if (!mounted) return;
    setState(() {
      _isImporting = false;
      _selectedLeadIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'No properties were created. Check property metadata or details.'
              : 'Moved $count property lead(s) to Properties inventory.',
        ),
        backgroundColor: count == 0 ? null : CRMColors.success,
      ),
    );
  }

  Future<void> _moveSelectedToLeadsPage(BuildContext context) async {
    final selected = _selectedLeadIds.toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select the leads you want to move after filtering and deleting fakes.')),
      );
      return;
    }

    final pendingIds = _service.leads
        .where((l) => selected.contains(l.id) && l.importStatus != 'Imported')
        .map((l) => l.id)
        .toList();

    if (pendingIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Those campaign leads were already moved to the Leads page.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Leads page?'),
        content: Text(
          'Move ${pendingIds.length} cleaned campaign lead(s) to the main Leads page? They will not be copied until you confirm.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Move to Leads page')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isImporting = true);
    final count = await _service.importLeadsToCrm(pendingIds);
    if (!mounted) return;
    setState(() {
      _isImporting = false;
      _selectedLeadIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'No leads were moved. Check for missing names/phones or duplicates already on the Leads page.'
              : 'Moved $count lead(s) to the Leads page.',
        ),
        backgroundColor: count == 0 ? null : CRMColors.success,
      ),
    );
  }

  Future<void> _cleanDuplicatesDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: CRMColors.primaryOf(context)),
            const SizedBox(width: 8),
            const Text('Clean & Merge Duplicates?'),
          ],
        ),
        content: const Text(
          'This runs the deduplication engine across the database:\n\n'
          '• Multiple inquiries with the same phone will be merged into 1 master lead with an enquiry counter.\n'
          '• Blank rows with no phone/name will be purged.\n'
          '• Your clean leads will be refreshed immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: CRMColors.primaryOf(context),
              foregroundColor: Colors.white,
            ),
            child: const Text('Clean Now'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final messenger = ScaffoldMessenger.of(context);
      final res = await _service.cleanDuplicates();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Cleanup Complete: ${res['deletedDuplicates'] ?? 0} duplicates merged, ${res['purgedJunk'] ?? 0} junk purged. ${res['remainingCleanLeads'] ?? 0} clean leads remaining.',
            ),
            backgroundColor: CRMColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clean duplicates: $e'), backgroundColor: CRMColors.danger),
        );
      }
    }
  }
}
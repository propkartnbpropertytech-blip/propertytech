import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as xl;
import 'package:url_launcher/url_launcher.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/config/app_env.dart';
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
import 'package:flutter/services.dart';
import '../../integration/services/integration_service.dart';
import '../../integration/models/integration_lead_model.dart';
import '../../integration/services/lead_understanding_engine.dart';
import '../models/campaign_followup_model.dart';
import '../bloc/campaign_leads_bloc.dart';
import 'campaign_subshell_header.dart';
import '../../users/repository/users_repository.dart';
import '../../users/bloc/users_bloc.dart';
import '../../users/models/user_model.dart' as users_model;
import '../../team_messages/services/team_messages_service.dart';
import '../../../core/utils/team_user_visibility.dart';
import 'package:propkart/core/design_system/tokens/app_breakpoints.dart';

class CampaignLeadsScreen extends StatefulWidget {
  final String? initialSource;
  final String? lockSource;
  final String? portalTabId;
  final String? initialView;
  final String? initialSearch;
  const CampaignLeadsScreen({super.key, this.initialSource, this.lockSource, this.portalTabId, this.initialView, this.initialSearch});

  @override
  State<CampaignLeadsScreen> createState() => _CampaignLeadsScreenState();
}

class _CampaignLeadsScreenState extends State<CampaignLeadsScreen> {
  final IntegrationService _service = IntegrationService();
  final UsersRepository _usersRepository = UsersRepository();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _notInterestedSearchController = TextEditingController();
  final TextEditingController _followupSearchController = TextEditingController();
  final Map<String, TextEditingController> _followupTabSearchControllers = {
    'all': TextEditingController(),
    'today': TextEditingController(),
    'future': TextEditingController(),
    'missed': TextEditingController(),
  };
  final Map<String, String> _followupTabSearchQueries = {
    'all': '',
    'today': '',
    'future': '',
    'missed': '',
  };
  String _selectedFollowupTelecaller = 'All';
  String _followupSearchQuery = '';
  Timer? _followupSearchDebounce;
  List<users_model.UserModel>? _cachedUsers;

  // Active view mode: 'active' (default pipeline), 'followups' (scheduled callbacks), 'not_interested' (archived)
  String _viewMode = 'active';
  String _followupFilter = 'all'; // 'all', 'today', 'future', 'missed'
  List<CampaignFollowupModel> _followupsList = [];
  bool _isLoadingFollowups = false;

  // Persisted view settings across tab navigation
  static String _persistedSection = 'Property Listing';
  static CampaignDateFilter _persistedDateFilter = CampaignDateFilter.allTime;
  bool _telecallerQueueAligned = false;
  static String _persistedSourceFilter = 'All';
  static String _persistedDuplicateFilter = 'All';

  late String _selectedSection = _persistedSection;
  late String _selectedSourceFilter = _persistedSourceFilter;
  late String _selectedDuplicateFilter = _persistedDuplicateFilter;
  String _selectedUserFilterId = 'All';
  late CampaignDateFilter _selectedDateFilter = _persistedDateFilter;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  final Set<String> _selectedLeadIds = {};
  bool _isImporting = false;
  bool _isSyncingSheet = false;
  int _currentPage = 1;
  int _pageSize = 25;
  int _notInterestedPage = 1;
  int _notInterestedPageSize = 25;
  String _searchQuery = '';
  String _notInterestedSearchQuery = '';
  Timer? _searchDebounce;
  Timer? _notInterestedSearchDebounce;
  Timer? _uiDebounce;
  StreamSubscription<Map<String, dynamic>>? _leadEventsSub;

  @override
  void initState() {
    super.initState();
    if (widget.initialView != null && widget.initialView!.isNotEmpty) {
      _viewMode = widget.initialView!;
      if (_viewMode == 'followups') {
        unawaited(_loadFollowups());
      }
    }
    if (widget.lockSource != null && widget.lockSource!.isNotEmpty) {
      _selectedSourceFilter = widget.lockSource!;
    } else if (widget.initialSource != null && widget.initialSource!.isNotEmpty) {
      _selectedSourceFilter = widget.initialSource!;
    }
    final incomingSearch = widget.initialSearch?.trim() ?? '';
    if (incomingSearch.isNotEmpty) {
      _searchQuery = incomingSearch.toLowerCase();
      _searchController.text = incomingSearch;
    }
    _service.addListener(_onServiceUpdate);
    _service.watchCampaignUi();
    // Warm up leads immediately from storage and sync in background
    _service.ensureLoaded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _alignTelecallerQueue();
      _cachedFilteredLeads = null;
      setState(() {});
    });
    unawaited(_bootstrapLockedSource());
    unawaited(_service.fetchHealthAlerts());
    unawaited(_preloadFilterUsers());
    unawaited(_loadFollowups());
    _leadEventsSub = IntegrationService.leadEvents.stream.listen((event) {
      if (!mounted) return;
      final type = event['type']?.toString();
      if (type == 'PEER_TRANSFER' || type == 'TRANSFER_COMPLETED' || type == 'OUTCOME_RECORDED') {
        unawaited(_loadFollowups());
      }
    });
  }

  String _usersFingerprint(List<users_model.UserModel>? users) {
    if (users == null || users.isEmpty) return '';
    return users.map((u) => '${u.id}|${u.fullName}|${u.roleName}|${u.isActive}').join(';');
  }

  /// Same Sales + Telecaller directory the Admin Employees page lists.
  List<users_model.UserModel> _employeesDirectoryUsers(List<users_model.UserModel> users) {
    return users
        .where((u) {
          final r = u.roleName.toLowerCase();
          return r == 'sales' || r == 'telecaller';
        })
        .toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  }

  void _applyDirectoryUsers(List<users_model.UserModel> users) {
    if (_usersFingerprint(_cachedUsers) == _usersFingerprint(users)) return;
    _cachedUsers = users;
    _cachedFilteredLeads = null;
    if (mounted) setState(() {});
  }

  bool _isAssignableSalesRole(String roleName) {
    final r = roleName.toLowerCase();
    return r.contains('sales') ||
        r.contains('agent') ||
        r.contains('advisor') ||
        r.contains('executive');
  }

  List<users_model.UserModel> _salesUsersFrom(List<users_model.UserModel> users) {
    final active = users.where((u) => u.isActive).toList();
    final sales = active.where((u) => _isAssignableSalesRole(u.roleName)).toList();
    return sales.isNotEmpty ? sales : active;
  }

  Future<List<users_model.UserModel>> _loadUsersForLeadAssign() async {
    List<users_model.UserModel> users = [];
    try {
      users = await _usersRepository.getUsers();
    } catch (_) {}

    if (users.isEmpty) {
      try {
        final team = await TeamMessagesService().getTeamUsers();
        users = team
            .map((u) => users_model.UserModel(
                  id: u.id,
                  roleId: '',
                  roleName: u.role,
                  fullName: u.name,
                  email: u.email,
                  isActive: true,
                ))
            .where((u) => u.id.isNotEmpty)
            .toList();
      } catch (_) {}
    }

    return users.where((u) => u.isActive).toList();
  }

  @override
  void didUpdateWidget(CampaignLeadsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lockSource != oldWidget.lockSource && widget.lockSource != null) {
      setState(() {
        _selectedSourceFilter = widget.lockSource!;
        _currentPage = 1;
      });
    } else if (widget.initialSource != oldWidget.initialSource && widget.initialSource != null) {
      setState(() {
        _selectedSourceFilter = widget.initialSource!;
        _currentPage = 1;
      });
    }
  }

  Future<void> _bootstrapLockedSource() async {
    final locked = widget.lockSource ?? '';
    if (locked.toUpperCase().contains('HOUSING')) {
      await _service.syncHousingLeads();
      return;
    }
    await _service.fetchServerLeads(
      silent: true,
      source: locked.isEmpty ? null : locked,
    );
  }

  Future<void> _preloadFilterUsers() async {
    if (mounted) {
      context.read<UsersBloc>().add(const FetchUsers());
    }
    try {
      final allUsers = await _usersRepository.getUsers();
      if (!mounted || allUsers.isEmpty) return;
      _applyDirectoryUsers(allUsers);
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _notInterestedSearchDebounce?.cancel();
    _followupSearchDebounce?.cancel();
    _uiDebounce?.cancel();
    _leadEventsSub?.cancel();
    _service.unwatchCampaignUi();
    _service.removeListener(_onServiceUpdate);
    _searchController.dispose();
    _notInterestedSearchController.dispose();
    _followupSearchController.dispose();
    for (final c in _followupTabSearchControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  static bool isNotInterestedStatus(String? status) {
    if (status == null) return false;
    final s = status.trim().toLowerCase();
    return s == 'not interested' || s == 'not_interested' || s == 'disqualified';
  }

  String _notInterestedSubFilter = 'all';

  List<IntegrationLeadModel>? _cachedFilteredLeads;
  int _cachedUniqueLeads = 0;
  int _cachedDupLeads = 0;
  int _cachedImportedCount = 0;
  int _cachedInterestedCount = 0;
  int _cachedFollowupCount = 0;
  int _cachedNotInterestedCount = 0;
  int _cachedNotInterestedTodayCount = 0;
  int _cachedTotalActiveCount = 0;
  int _cachedListedCount = 0;
  int _cachedArchivedReqCount = 0;
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
  String? _lastViewMode;
  String? _lastSectionFilter;
  String? _lastSourceFilter;
  String? _lastDuplicateFilter;
  String? _lastUserFilter;
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
    if (columnKey == '#CampaignStatus') return 'Status';
    if (columnKey == '#TransferLeads') return 'Transfer Leads';
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
    if (lower == 'received on' || lower == 'received_on' || lower == 'receivedon' || lower == 'created_at' || lower == 'arrival time' || lower == 'date') {
      return 'Received On';
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
      if (!mounted) return;
      _alignTelecallerQueue();
      _cachedFilteredLeads = null;
      setState(() {});
    });
  }

  DateTime _queueTime(IntegrationLeadModel lead) {
    if (RoleGuard.isTelecaller(RoleGuard.currentUser?.role)) {
      return lead.telecallerAssignedAt ?? lead.receivedAt;
    }
    return lead.receivedAt;
  }

  bool _isOpenCallingLead(IntegrationLeadModel lead) {
    if (isNotInterestedStatus(lead.campaignStatus)) return false;
    if (lead.campaignStatus == 'Property Listed' ||
        lead.campaignStatus == 'Listed' ||
        lead.campaignStatus == 'Archived' ||
        lead.campaignStatus == 'Assigned') {
      return false;
    }
    if (lead.importStatus == 'Imported') return false;
    if (lead.assignedTo != null && lead.assignedTo!.isNotEmpty && lead.assignedTo != 'Unassigned') {
      return false;
    }
    if (_leftCallingQueue(lead)) return false;
    return true;
  }

  /// CNR and scheduled callbacks live on their own pages. New and Follow up stay here.
  bool _leftCallingQueue(IntegrationLeadModel lead) {
    if (!RoleGuard.isTelecaller(RoleGuard.currentUser?.role)) return false;
    final status = lead.campaignStatus.trim().toLowerCase();
    final alloc = (lead.allocationStatus ?? '').trim().toUpperCase();
    if (status == 'follow up' || status == 'follow-up' || alloc == 'FOLLOWUP') return false;
    if (status == 'cnr' || alloc == 'CNR') return true;
    if (status == 'callback' || status == 'call back' || alloc == 'CALLBACK') return true;
    return false;
  }

  /// Telecallers land on an empty Property Listing tab when their queue is requirements.
  /// Open All Time once, then move to whichever section actually has assigned leads.
  void _alignTelecallerQueue() {
    if (!RoleGuard.isTelecaller(RoleGuard.currentUser?.role)) return;
    if (!_telecallerQueueAligned) {
      _telecallerQueueAligned = true;
      _selectedDateFilter = CampaignDateFilter.allTime;
    }
    final open = _service.leads.where(_isOpenCallingLead).toList();
    if (open.isEmpty) return;
    if (open.any((lead) => lead.leadType == _selectedSection)) return;
    final requirement = open.where((lead) => lead.leadType == 'Requirement').length;
    final listing = open.where((lead) => lead.leadType == 'Property Listing').length;
    if (requirement == 0 && listing == 0) return;
    _selectedSection = requirement >= listing ? 'Requirement' : 'Property Listing';
    _persistedSection = _selectedSection;
  }

  void _recomputeFilteredLeadsIfNeeded() {
    final currentLeads = _service.leads;
    final currentFiltersHash = _computeColumnFiltersHash();

    if (_cachedFilteredLeads != null &&
        identical(_lastServiceLeadsRef, currentLeads) &&
        _lastViewMode == _viewMode &&
        _lastSectionFilter == _selectedSection &&
        _lastSourceFilter == _selectedSourceFilter &&
        _lastDuplicateFilter == _selectedDuplicateFilter &&
        _lastUserFilter == _selectedUserFilterId &&
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
    _lastViewMode = _viewMode;
    _lastSectionFilter = _selectedSection;
    _lastSourceFilter = _selectedSourceFilter;
    _lastDuplicateFilter = _selectedDuplicateFilter;
    _lastUserFilter = _selectedUserFilterId;
    _lastDateFilter = _selectedDateFilter;
    _lastCustomStartDate = _customStartDate;
    _lastCustomEndDate = _customEndDate;
    _lastSearchQuery = _searchQuery;
    _lastColumnFiltersHash = currentFiltersHash;
    _lastSortColumn = _sortColumn;
    _lastSortAscending = _sortAscending;

    // Filter by Section and View Mode:
    // In 'not_interested' mode, show leads where campaignStatus == 'Not interested'.
    // In 'archive_listed' (or legacy 'listed') mode, show leads where leadType == 'Property Listing' and campaignStatus is listed/archived.
    // In 'archive_requirements' mode, show leads where leadType == 'Requirement' and campaignStatus is archived/closed/won.
    // In 'active' mode (default), filter out 'Not interested', 'Property Listed' / 'Listed', and 'Archived' leads.
    final userFilterActive = _selectedUserFilterId != 'All' && _selectedUserFilterId.isNotEmpty;
    users_model.UserModel? selectedFilterUser;
    if (userFilterActive && _cachedUsers != null) {
      for (final u in _cachedUsers!) {
        if (u.id == _selectedUserFilterId) {
          selectedFilterUser = u;
          break;
        }
      }
    }

    final sourceFilter = widget.lockSource ?? _selectedSourceFilter;
    final scopedLeads = currentLeads
        .where((l) => IntegrationService.matchesCampaignSource(l.source, sourceFilter))
        .toList();

    List<IntegrationLeadModel> list;
    final selectedUser = selectedFilterUser;
    list = _viewMode == 'not_interested'
        ? scopedLeads.where((l) => isNotInterestedStatus(l.campaignStatus)).toList()
        : (_viewMode == 'archive_listed' || _viewMode == 'listed'
            ? scopedLeads.where((l) => l.leadType == 'Property Listing' && (l.campaignStatus == 'Property Listed' || l.campaignStatus == 'Listed' || l.campaignStatus == 'Archived')).toList()
            : (_viewMode == 'archive_requirements'
                ? scopedLeads.where((l) => l.leadType == 'Requirement' && (l.campaignStatus == 'Archived' || l.campaignStatus == 'Closed' || l.campaignStatus == 'Won' || l.campaignStatus == 'Property Listed' || l.campaignStatus == 'Listed')).toList()
                : scopedLeads.where((l) {
                    if (l.leadType != _selectedSection) return false;
                    return !isNotInterestedStatus(l.campaignStatus) && l.campaignStatus != 'Property Listed' && l.campaignStatus != 'Listed' && l.campaignStatus != 'Archived' && l.campaignStatus != 'Assigned' && l.importStatus != 'Imported' && !(l.assignedTo != null && l.assignedTo!.isNotEmpty && l.assignedTo != 'Unassigned') && !_leftCallingQueue(l);
                  }).toList()));
    if (userFilterActive && selectedUser != null) {
      list = list.where((l) => TeamUserVisibility.campaignLeadBelongsToUser(l, selectedUser)).toList();
    }

    // Filter by Date (Today is default, Yesterday, Last 7 Days, This Month, Custom Range, All Time)
    if (_selectedDateFilter != CampaignDateFilter.allTime) {
      list = list.where((l) => CampaignLeadsState.matchesDateFilter(
        _queueTime(l),
        _selectedDateFilter,
        customStart: _customStartDate,
        customEnd: _customEndDate,
      )).toList();
    }

    var u = 0;
    var d = 0;
    var imp = 0;
    var interested = 0;
    for (final lead in list) {
      if (lead.isDuplicate) {
        d++;
      } else {
        u++;
      }
      if (lead.importStatus == 'Imported' || (lead.assignedTo != null && lead.assignedTo!.isNotEmpty)) {
        imp++;
      }
      if (lead.campaignStatus == 'Interested' && lead.importStatus != 'Imported') {
        interested++;
      }
    }
    _cachedUniqueLeads = u;
    _cachedDupLeads = d;
    _cachedImportedCount = imp;
    _cachedInterestedCount = interested;

    // Filter by Duplicate status
    if (_selectedDuplicateFilter == 'Duplicates Only') {
      list = list.where((l) => l.isDuplicate).toList();
    } else if (_selectedDuplicateFilter == 'Unique Only') {
      list = list.where((l) => !l.isDuplicate).toList();
    }

    // Search query across all cell values
    final query = _searchQuery;
    if (query.isNotEmpty) {
      final queryDigits = query.replaceAll(RegExp(r'\D'), '');
      list = list.where((lead) {
        final blob = StringBuffer()
          ..write(lead.source)
          ..write(' ')
          ..write(lead.campaignStatus)
          ..write(' ')
          ..write(lead.qualityStatus);
        for (final val in lead.rawJson.values) {
          if (val != null) blob.write(' $val');
        }
        final text = blob.toString().toLowerCase();
        if (text.contains(query)) return true;
        return queryDigits.length >= 4 && text.replaceAll(RegExp(r'\D'), '').contains(queryDigits);
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
          } else if (colKey == '#CampaignStatus') {
            cellVal = lead.campaignStatus;
          } else if (colKey == '#TransferLeads') {
            cellVal = lead.assignedToName?.isNotEmpty == true
                ? 'Assigned: ${lead.assignedToName}'
                : (lead.campaignStatus == 'CNR' ? 'CNR (Interacted)' : 'Not Assigned');
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
        } else if (_sortColumn == '#CampaignStatus') {
          valA = a.campaignStatus;
          valB = b.campaignStatus;
        } else if (_sortColumn == '#TransferLeads') {
          valA = a.assignedToName ?? (a.campaignStatus == 'CNR' ? 'CNR' : '');
          valB = b.assignedToName ?? (b.campaignStatus == 'CNR' ? 'CNR' : '');
        } else if (_sortColumn == '#MetaQuality') {
          valA = a.qualityStatus;
          valB = b.qualityStatus;
        } else if (_sortColumn == '#CrmStatus') {
          valA = a.importStatus;
          valB = b.importStatus;
        } else if (_sortColumn == '#MainCrmStatus') {
          valA = a.crmMatch?.inCrm == true ? 'In CRM' : 'Not in CRM';
          valB = b.crmMatch?.inCrm == true ? 'In CRM' : 'Not in CRM';
        } else if (_sortColumn == 'Received On' || _sortColumn == 'received_at' || _sortColumn == 'date') {
          final cmp = a.receivedAt.compareTo(b.receivedAt);
          return _sortAscending ? cmp : -cmp;
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

    // Single-pass computation for section counts, date filter counts, and status metrics
    int allTimeSectionCount = 0;
    int propListingCount = 0;
    int reqCount = 0;
    int countToday = 0;
    int countYesterday = 0;
    int countLast7Days = 0;
    int countThisMonth = 0;
    int followupCount = 0;
    int notInterestedCount = 0;
    int notInterestedTodayCount = 0;
    int totalActiveCount = 0;
    int listedCount = 0;
    int archivedReqCount = 0;

    for (final l in scopedLeads) {
      final isProp = l.leadType == 'Property Listing';
      final isReq = l.leadType == 'Requirement';
      final isSelectedSec = l.leadType == _selectedSection;
      final isNotInterested = isNotInterestedStatus(l.campaignStatus);
      final isListed = isProp && (l.campaignStatus == 'Property Listed' || l.campaignStatus == 'Listed' || l.campaignStatus == 'Archived');
      final isArchivedReq = isReq && (l.campaignStatus == 'Archived' || l.campaignStatus == 'Closed' || l.campaignStatus == 'Won' || l.campaignStatus == 'Property Listed' || l.campaignStatus == 'Listed');

      final isOpenPipeline = _isOpenCallingLead(l);
      if (isNotInterested) {
        notInterestedCount++;
        if (CampaignLeadsState.matchesDateFilter(l.receivedAt, CampaignDateFilter.today)) {
          notInterestedTodayCount++;
        }
      } else if (isListed) {
        listedCount++;
      } else if (isArchivedReq) {
        archivedReqCount++;
      } else if (isOpenPipeline) {
        totalActiveCount++;
      }

      final isFollowupStatus = l.campaignStatus == 'Follow up' || l.campaignStatus == 'Follow-up';
      if (isFollowupStatus && isOpenPipeline && isSelectedSec) {
        followupCount++;
      }

      // Section badges and date chips must match the spreadsheet. Transferred,
      // imported, and sales-assigned leads stay out of this pipeline.
      if (isSelectedSec && isOpenPipeline) {
        allTimeSectionCount++;
        if (CampaignLeadsState.matchesDateFilter(_queueTime(l), CampaignDateFilter.today)) countToday++;
        if (CampaignLeadsState.matchesDateFilter(_queueTime(l), CampaignDateFilter.yesterday)) countYesterday++;
        if (CampaignLeadsState.matchesDateFilter(_queueTime(l), CampaignDateFilter.last7Days)) countLast7Days++;
        if (CampaignLeadsState.matchesDateFilter(_queueTime(l), CampaignDateFilter.thisMonth)) countThisMonth++;
      }

      if (isProp && isOpenPipeline &&
          CampaignLeadsState.matchesDateFilter(_queueTime(l), _selectedDateFilter,
              customStart: _customStartDate, customEnd: _customEndDate)) {
        propListingCount++;
      }
      if (isReq && isOpenPipeline &&
          CampaignLeadsState.matchesDateFilter(_queueTime(l), _selectedDateFilter,
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
    _cachedFollowupCount = followupCount;
    _cachedNotInterestedCount = notInterestedCount;
    _cachedNotInterestedTodayCount = notInterestedTodayCount;
    _cachedTotalActiveCount = totalActiveCount;
    _cachedListedCount = listedCount;
    _cachedArchivedReqCount = archivedReqCount;

    _cachedAllDetectedHeaders = _service.getDetectedHeaders(leadsSubset: list, section: _selectedSection);
    _cachedVisibleHeaders = _service.getActiveVisibleHeaders(leadsSubset: list, section: _selectedSection);
  }

  List<IntegrationLeadModel> get _scopedLeads {
    final filter = widget.lockSource ?? _selectedSourceFilter;
    return _service.leads.where((l) => IntegrationService.matchesCampaignSource(l.source, filter)).toList();
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
            title: 'Access Restricted',
            message:
                'You do not have the required permissions to view this module. Please contact your system administrator.',
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

    return BlocListener<UsersBloc, UsersState>(
      listener: (context, state) {
        if (state is UsersLoaded) {
          _applyDirectoryUsers(state.users);
        }
      },
      child: BlocListener<CampaignLeadsBloc, CampaignLeadsState>(
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
        } else if (state.errorMessage != null && state.errorMessage!.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: CRMColors.backgroundOf(context),
        body: SafeArea(
          top: false,
          bottom: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              MediaQuery.sizeOf(context).width < 700 ? CRMSpacing.m : CRMSpacing.l,
              MediaQuery.sizeOf(context).width < 700 ? CRMSpacing.s : CRMSpacing.l,
              MediaQuery.sizeOf(context).width < 700 ? CRMSpacing.m : CRMSpacing.l,
              MediaQuery.sizeOf(context).width < 700 ? 96 : CRMSpacing.l,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page Header
                CampaignSubshellHeader(
                  activeTab: widget.portalTabId ??
                      ((widget.lockSource ?? _selectedSourceFilter).toUpperCase() == 'HOUSING.COM' ||
                              (widget.lockSource ?? _selectedSourceFilter).toUpperCase() == 'HOUSING'
                          ? 'housing'
                          : ((widget.lockSource ?? _selectedSourceFilter).toUpperCase() == 'META ADS' ||
                                  (widget.lockSource ?? _selectedSourceFilter).toUpperCase() == 'META'
                              ? 'meta'
                              : 'connections')),
                  trailing: _buildHeaderActions(context),
                ),

              SizedBox(height: MediaQuery.sizeOf(context).width < 700 ? CRMSpacing.s : CRMSpacing.m),

              // Main View Mode Selector (Active Leads, Follow-ups, Not Interested)
              _buildViewSelector(context),

              const SizedBox(height: CRMSpacing.m),

              if (_viewMode == 'followups') ...[
                _buildFollowupsView(context),
              ] else if (_viewMode == 'not_interested') ...[
                _buildNotInterestedView(context),
              ] else ...[
                if (_viewMode == 'archive_listed' || _viewMode == 'archive_requirements' || _viewMode == 'listed') ...[
                  _buildArchiveNoticeBanner(context),
                ],
                // Dual-Section Segmented Tab Switcher (Property Listing Leads vs Requirement Leads)
                _buildLeadTypeSegmentedControl(context, propertyListingCount, requirementCount),

                const SizedBox(height: CRMSpacing.m),

                // Date Range Filter Bar (Today default, Yesterday, Last 7 Days, This Month, Custom Range, All Time)
                _buildDateFilterBar(context),

                // Notice Banner when viewing Today
                _buildTodayNoticeBanner(context, totalLeads, _cachedAllTimeSectionCount),

                const SizedBox(height: CRMSpacing.m),

                // Highlighted Interested Leads Ready to Move Banner
                if (_cachedInterestedCount > 0) ...[
                  _buildInterestedLeadsAlertBanner(context),
                  const SizedBox(height: CRMSpacing.m),
                ],

                if (widget.lockSource == null) ...[
                  _buildKpiMetricsRow(context, totalLeads, uniqueLeads, dupLeads, importedCount),
                  const SizedBox(height: CRMSpacing.m),
                ],

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
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeaderActions(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    final isTelecaller = RoleGuard.isTelecaller(RoleGuard.currentUser?.role);

    final refreshButton = CRMButton(
      label: _service.isFetchingServerLeads ? 'Refreshing...' : 'Refresh Leads',
      prefixIcon: Icons.refresh_rounded,
      variant: CRMButtonVariant.outline,
      height: 36,
      isLoading: _service.isFetchingServerLeads,
      onPressed: _service.isFetchingServerLeads
          ? null
          : () async {
              if (!isTelecaller) {
                final locked = widget.lockSource ?? '';
                if (locked.toUpperCase().contains('HOUSING')) {
                  await _service.syncHousingLeads();
                } else {
                  await _service.syncMetaLeads();
                }
              }
              final count = await _service.fetchServerLeads();
              if (mounted) {
                context.read<CampaignLeadsBloc>().add(const FetchCampaignLeadsEvent(silent: true));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      count > 0
                          ? 'Campaign leads up to date ($count leads).'
                          : 'Campaign leads are up to date.',
                    ),
                  ),
                );
              }
            },
    );

    final exportExcelButton = CRMButton(
      label: 'Export Excel',
      prefixIcon: Icons.table_view_rounded,
      variant: CRMButtonVariant.outline,
      height: 36,
      onPressed: () => _exportCurrentSpreadsheetToExcel(context),
    );

    final isPropertyListing = _selectedSection == 'Property Listing';
    final isArchiveMode = _viewMode == 'archive_listed' || _viewMode == 'archive_requirements' || _viewMode == 'listed';
    final archiveCount = isPropertyListing ? _cachedListedCount : _cachedArchivedReqCount;

    final archiveHeaderButton = CRMButton(
      label: isArchiveMode
          ? 'Exit Archive'
          : (isMobile
              ? 'Archive ($archiveCount)'
              : (isPropertyListing
                  ? 'Property Archive ($archiveCount)'
                  : 'Requirement Archive ($archiveCount)')),
      prefixIcon: isArchiveMode ? Icons.arrow_back_rounded : Icons.inventory_2_outlined,
      variant: isArchiveMode ? CRMButtonVariant.primary : CRMButtonVariant.outline,
      height: 36,
      onPressed: () {
        setState(() {
          if (isArchiveMode) {
            _viewMode = 'active';
          } else {
            _viewMode = isPropertyListing ? 'archive_listed' : 'archive_requirements';
          }
          _cachedFilteredLeads = null;
          _selectedLeadIds.clear();
          _currentPage = 1;
        });
      },
    );

    if (isTelecaller) {
      if (isMobile) {
        return Row(
          children: [
            Expanded(child: archiveHeaderButton),
            const SizedBox(width: 8),
            Expanded(child: refreshButton),
            const SizedBox(width: 8),
            Expanded(child: exportExcelButton),
          ],
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          archiveHeaderButton,
          refreshButton,
          exportExcelButton,
        ],
      );
    }

    final syncSheetButton = CRMButton(
      label: _isSyncingSheet ? 'Syncing...' : (isMobile ? 'Sync Sheet' : 'Sync Google Sheet'),
      prefixIcon: Icons.sync_rounded,
      variant: CRMButtonVariant.outline,
      height: 36,
      isLoading: _isSyncingSheet,
      onPressed: _isSyncingSheet ? null : () => _syncGoogleSheet(context),
    );

    final moreButton = PopupMenuButton<String>(
      tooltip: 'More actions',
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (val) {
        if (val == 'import_csv') _importCsvFile(context);
        if (val == 'clean_duplicates') _cleanDuplicatesDialog(context);
        if (val == 'paste_json') _showPasteJsonDialog(context);
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'import_csv',
          child: Row(
            children: [
              Icon(Icons.upload_file_rounded, size: 18),
              SizedBox(width: 10),
              Text('Import CSV', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'clean_duplicates',
          child: Row(
            children: [
              Icon(Icons.cleaning_services_rounded, size: 18),
              SizedBox(width: 10),
              Text('Clean Duplicates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'paste_json',
          child: Row(
            children: [
              Icon(Icons.code_rounded, size: 18),
              SizedBox(width: 10),
              Text('Paste Raw JSON', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: CRMColors.surfaceElevatedOf(context),
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          border: Border.all(color: CRMColors.borderOf(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.more_horiz_rounded, size: 18, color: CRMColors.textOf(context)),
            const SizedBox(width: 4),
            Text(
              'More',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CRMColors.textOf(context),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: CRMColors.textSecondaryOf(context)),
          ],
        ),
      ),
    );

    if (widget.lockSource != null) {
      if (isMobile) {
        return Row(
          children: [
            Expanded(child: archiveHeaderButton),
            const SizedBox(width: 8),
            Expanded(child: refreshButton),
            const SizedBox(width: 8),
            Expanded(child: exportExcelButton),
          ],
        );
      }
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: [archiveHeaderButton, refreshButton, exportExcelButton],
      );
    }

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status Badges Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMetaLiveDiagnosticBadge(context),
                const SizedBox(width: 8),
                _buildAutoSyncLiveBadge(context),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Action Buttons 2x2 Grid Layout
          Row(
            children: [
              Expanded(child: archiveHeaderButton),
              const SizedBox(width: 6),
              Expanded(child: refreshButton),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: syncSheetButton),
              const SizedBox(width: 6),
              Expanded(child: exportExcelButton),
              const SizedBox(width: 6),
              Expanded(child: moreButton),
            ],
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildMetaLiveDiagnosticBadge(context),
        _buildAutoSyncLiveBadge(context),
        archiveHeaderButton,
        refreshButton,
        syncSheetButton,
        exportExcelButton,
        moreButton,
      ],
    );
  }

  Widget _buildViewSelector(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    final tabs = [
      _buildViewTabItem(
        context: context,
        title: 'Active Leads',
        subtitle: 'Clean campaign pipeline & incoming leads',
        icon: Icons.table_chart_rounded,
        count: _cachedTotalActiveCount,
        badgeColor: CRMColors.primaryOf(context),
        isSelected: _viewMode == 'active',
        isMobile: isMobile,
        onTap: () {
          if (_viewMode != 'active') {
            setState(() {
              _viewMode = 'active';
              _cachedFilteredLeads = null;
              _currentPage = 1;
            });
          }
        },
      ),
      _buildViewTabItem(
        context: context,
        title: 'Follow-ups',
        subtitle: 'Today, future & scheduled callbacks',
        icon: Icons.access_time_filled_rounded,
        count: _pendingDueFollowupLeadCount(),
        badgeColor: const Color(0xFFF59E0B),
        isSelected: _viewMode == 'followups',
        isMobile: isMobile,
        onTap: () {
          if (_viewMode != 'followups') {
            setState(() {
              _viewMode = 'followups';
            });
            _loadFollowups();
          }
        },
      ),
      _buildViewTabItem(
        context: context,
        title: 'Not Interested',
        subtitle: 'Archived non-interested leads',
        icon: Icons.do_not_disturb_on_rounded,
        count: _cachedNotInterestedCount,
        badgeColor: const Color(0xFFEF4444),
        isSelected: _viewMode == 'not_interested',
        isMobile: isMobile,
        onTap: () {
          if (_viewMode != 'not_interested') {
            setState(() {
              _viewMode = 'not_interested';
              _selectedDateFilter = CampaignDateFilter.allTime;
              _notInterestedSubFilter = 'all';
              _cachedFilteredLeads = null;
              _currentPage = 1;
            });
          }
        },
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Expanded(child: tabs[0]),
          const SizedBox(width: 4),
          Expanded(child: tabs[1]),
          const SizedBox(width: 4),
          Expanded(child: tabs[2]),
        ],
      ),
    );
  }

  Widget _buildViewTabItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required int count,
    required Color badgeColor,
    required bool isSelected,
    required VoidCallback onTap,
    bool isMobile = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? const Color(0xFF262E3D) : Colors.white;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 14,
          vertical: isMobile ? 8 : 10,
        ),
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
        child: isMobile
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? badgeColor : CRMColors.textSecondaryOf(context),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? badgeColor : badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? CRMColors.textOf(context) : CRMColors.textSecondaryOf(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? badgeColor.withValues(alpha: 0.15)
                          : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? badgeColor : CRMColors.textSecondaryOf(context),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
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

  Widget _buildStatusDropdownCell(BuildContext context, IntegrationLeadModel lead) {
    final status = lead.campaignStatus;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = (RoleGuard.currentUser?.role ?? '').toLowerCase();
    final isRealAdmin = role == 'admin' || role == 'super admin';

    final isArchiveLead = status == 'Archived' ||
        status == 'Property Listed' ||
        status == 'Listed' ||
        _viewMode == 'archive_listed' ||
        _viewMode == 'archive_requirements';
    final archName = lead.archivedByName?.trim().isNotEmpty == true
        ? lead.archivedByName!
        : (lead.statusUpdatedByName?.trim().isNotEmpty == true
            ? lead.statusUpdatedByName!
            : (lead.assignedTelecallerName?.trim().isNotEmpty == true ? lead.assignedTelecallerName! : ''));
    final updaterName = lead.statusUpdatedByName?.trim().isNotEmpty == true
        ? lead.statusUpdatedByName!
        : (lead.assignedTelecallerName?.trim().isNotEmpty == true ? lead.assignedTelecallerName! : '');
    final actionUser = isArchiveLead ? (archName.isNotEmpty ? archName : updaterName) : updaterName;
    final actionLabelText = isArchiveLead ? 'Archived by: $actionUser' : 'By: $actionUser';

    Color badgeBg;
    Color badgeBorder;
    Color textColor;
    IconData icon;

    if (status == 'Interested') {
      badgeBg = const Color(0xFF10B981).withValues(alpha: 0.15);
      badgeBorder = const Color(0xFF10B981).withValues(alpha: 0.45);
      textColor = const Color(0xFF10B981);
      icon = Icons.star_rounded;
    } else if (status == 'Callback' || status == 'Call Back') {
      badgeBg = const Color(0xFF0284C7).withValues(alpha: 0.15);
      badgeBorder = const Color(0xFF0284C7).withValues(alpha: 0.45);
      textColor = const Color(0xFF0284C7);
      icon = Icons.phone_callback_rounded;
    } else if (status == 'Follow up' || status == 'Follow-up') {
      badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      badgeBorder = const Color(0xFFF59E0B).withValues(alpha: 0.45);
      textColor = const Color(0xFFF59E0B);
      icon = Icons.schedule_rounded;
    } else if (status == 'CNR') {
      badgeBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      badgeBorder = const Color(0xFFF59E0B).withValues(alpha: 0.45);
      textColor = const Color(0xFFD97706);
      icon = Icons.phone_missed_rounded;
    } else if (status == 'Picked Up' || status == 'Assigned') {
      badgeBg = const Color(0xFF10B981).withValues(alpha: 0.15);
      badgeBorder = const Color(0xFF10B981).withValues(alpha: 0.45);
      textColor = const Color(0xFF10B981);
      icon = Icons.assignment_ind_rounded;
    } else if (status == 'Property Listed' || status == 'Listed') {
      badgeBg = const Color(0xFF10B981).withValues(alpha: 0.15);
      badgeBorder = const Color(0xFF10B981).withValues(alpha: 0.45);
      textColor = const Color(0xFF10B981);
      icon = Icons.verified_rounded;
    } else if (status == 'Archived') {
      badgeBg = const Color(0xFF6366F1).withValues(alpha: 0.15);
      badgeBorder = const Color(0xFF6366F1).withValues(alpha: 0.45);
      textColor = const Color(0xFF6366F1);
      icon = Icons.archive_rounded;
    } else if (status == 'Not interested') {
      badgeBg = const Color(0xFFEF4444).withValues(alpha: 0.15);
      badgeBorder = const Color(0xFFEF4444).withValues(alpha: 0.45);
      textColor = const Color(0xFFEF4444);
      icon = Icons.thumb_down_alt_rounded;
    } else if (lead.assignedTelecallerName?.isNotEmpty == true) {
      badgeBg = const Color(0xFF0284C7).withValues(alpha: 0.12);
      badgeBorder = const Color(0xFF38BDF8).withValues(alpha: 0.50);
      textColor = const Color(0xFF0369A1);
      icon = Icons.support_agent_rounded;
    } else {
      badgeBg = CRMColors.primaryOf(context).withValues(alpha: 0.10);
      badgeBorder = CRMColors.borderOf(context);
      textColor = CRMColors.primaryOf(context);
      icon = Icons.fiber_new_rounded;
    }

    String label = status.isEmpty ? 'New' : status;
    if ((status == 'Follow up' || status == 'Follow-up') && lead.followupScheduledAt != null) {
      label = 'Follow up (${DateFormat('d MMM, h:mm a').format(lead.followupScheduledAt!)})';
    } else if (status == 'Callback' || status == 'Call Back') {
      if (lead.followupScheduledAt != null) {
        label = 'Callback (${DateFormat('d MMM, h:mm a').format(lead.followupScheduledAt!)})';
      } else if (lead.assignedTelecallerName?.isNotEmpty == true) {
        label = 'Callback (${lead.assignedTelecallerName})';
      } else {
        label = 'Callback';
      }
    } else if (status == 'CNR') {
      label = lead.assignedTelecallerName?.isNotEmpty == true ? 'CNR (${lead.assignedTelecallerName})' : 'CNR';
    } else if (status == 'Assigned' && lead.assignedToName?.isNotEmpty == true) {
      label = 'Assigned (${lead.assignedToName})';
    } else if (lead.assignedTelecallerName?.isNotEmpty == true) {
      if (lead.allocationStatus == 'ASSIGNED_TO_TELECALLER') {
        label = 'Allocated: ${lead.assignedTelecallerName}';
      } else if (lead.allocationStatus == 'IN_CALL') {
        label = 'In Call (${lead.assignedTelecallerName})';
      } else if (lead.allocationStatus == 'CALLBACK') {
        label = 'Callback (${lead.assignedTelecallerName})';
      } else if (lead.allocationStatus == 'HANDED_TO_SALES') {
        label = 'Handed to Sales (${lead.assignedToName ?? lead.assignedTelecallerName})';
      } else {
        label = 'Allocated: ${lead.assignedTelecallerName}';
      }
    }

    final popup = PopupMenuButton<String>(
      tooltip: isRealAdmin && actionUser.isNotEmpty && status != 'New' && status != 'Assigned' && status != 'Transfer'
          ? '$label • $actionLabelText'
          : 'Change Status (Follow up, Interested, CNR, Transfer, Not interested)',
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 300),
      onSelected: (newStatus) async {
        if (newStatus == 'Unarchive') {
          await _unarchiveLead(lead);
        } else if (newStatus == 'Archive Property' || newStatus == 'Archive Requirement') {
          await _archiveLead(lead);
        } else if (newStatus == 'Call Outcome' || newStatus == 'Update Call Outcome') {
          _showPropertyListingOutcomeDialog(context, lead);
        } else if (newStatus == 'Follow up') {
          _showScheduleFollowupDialog(context, lead);
        } else if (newStatus == 'Transfer') {
          _showTransferDialog(context, lead);
        } else if (newStatus == 'CNR') {
          final result = await _service.transferLead(lead.id, status: 'CNR');
          _service.notifyOutcomeRecorded(
            lead.id,
            outcome: 'CNR',
            remarks: 'Marked as CNR',
          );
          if (mounted) {
            setState(() {
              _cachedFilteredLeads = null;
            });
            final ok = result['success'] == true;
            unawaited(_loadFollowups());
            unawaited(_service.fetchServerLeads(resetWithServer: true));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ok
                      ? 'Lead marked as CNR and highlighted as interacted.'
                      : (result['message']?.toString() ?? 'Failed to mark lead as CNR.'),
                ),
                backgroundColor: ok ? const Color(0xFFD97706) : const Color(0xFFEF4444),
              ),
            );
          }
        } else if (newStatus == 'Property Listed') {
          await _service.updateLeadCampaignStatus(lead.id, 'Property Listed');
          unawaited(_service.fetchServerLeads(resetWithServer: true));
          if (mounted) {
            setState(() {
              _cachedFilteredLeads = null;
            });
            unawaited(_loadFollowups());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Property listing marked as Listed and saved in Archive.'),
                backgroundColor: const Color(0xFF10B981),
                action: SnackBarAction(
                  label: 'View Archive',
                  textColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _viewMode = 'archive_listed';
                      _selectedSection = 'Property Listing';
                      _cachedFilteredLeads = null;
                      _currentPage = 1;
                    });
                  },
                ),
              ),
            );
          }
        } else if (newStatus == 'Archive Requirement') {
          await _service.updateLeadCampaignStatus(lead.id, 'Archived');
          unawaited(_service.fetchServerLeads(resetWithServer: true));
          if (mounted) {
            setState(() {
              _cachedFilteredLeads = null;
            });
            unawaited(_loadFollowups());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Requirement lead archived and saved in Archive.'),
                backgroundColor: const Color(0xFF6366F1),
                action: SnackBarAction(
                  label: 'View Archive',
                  textColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _viewMode = 'archive_requirements';
                      _selectedSection = 'Requirement';
                      _cachedFilteredLeads = null;
                      _currentPage = 1;
                    });
                  },
                ),
              ),
            );
          }
        } else if (newStatus == 'Wrong Lead Property Listing') {
          final targetType = 'Property Listing';
          final isArchive = _viewMode == 'archive_requirements' || _viewMode == 'archive_listed' || _viewMode == 'listed';
          _service.reclassifyLeadOptimistic(lead.id, targetType);
          _cachedFilteredLeads = null;
          _currentPage = 1;
          if (_viewMode == 'archive_requirements') {
            _viewMode = 'archive_listed';
            _selectedSection = 'Property Listing';
            _persistedSection = 'Property Listing';
          }
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isArchive ? 'Lead moved to Property Listing Archive table.' : 'Lead moved to Property Listing table.'),
                backgroundColor: const Color(0xFF0284C7),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _selectedSection = 'Property Listing';
                      _persistedSection = 'Property Listing';
                      if (isArchive) {
                        _viewMode = 'archive_listed';
                      }
                      _cachedFilteredLeads = null;
                      _currentPage = 1;
                    });
                  },
                ),
              ),
            );
          }
          unawaited(_service.reclassifyLead(lead.id, targetType).then((ok) {
            if (!ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to update lead classification on server. Please try again.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            }
          }));
        } else if (newStatus == 'Wrong Lead Requirement') {
          final targetType = 'Requirement';
          final isArchive = _viewMode == 'archive_listed' || _viewMode == 'listed' || _viewMode == 'archive_requirements';
          _service.reclassifyLeadOptimistic(lead.id, targetType);
          _cachedFilteredLeads = null;
          _currentPage = 1;
          if (_viewMode == 'archive_listed' || _viewMode == 'listed') {
            _viewMode = 'archive_requirements';
            _selectedSection = 'Requirement';
            _persistedSection = 'Requirement';
          }
          if (mounted) {
            setState(() {});
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isArchive ? 'Lead moved to Requirement Archive table.' : 'Lead moved to Requirement table.'),
                backgroundColor: const Color(0xFF8B5CF6),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () {
                    setState(() {
                      _selectedSection = 'Requirement';
                      _persistedSection = 'Requirement';
                      if (isArchive) {
                        _viewMode = 'archive_requirements';
                      }
                      _cachedFilteredLeads = null;
                      _currentPage = 1;
                    });
                  },
                ),
              ),
            );
          }
          unawaited(_service.reclassifyLead(lead.id, targetType).then((ok) {
            if (!ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to update lead classification on server. Please try again.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            }
          }));
        } else if (newStatus == 'Interested') {
          await _service.updateLeadCampaignStatus(lead.id, 'Interested');
          unawaited(_service.fetchServerLeads(resetWithServer: true));
          if (mounted) {
            setState(() {
              _cachedFilteredLeads = null;
            });
            unawaited(_loadFollowups());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lead marked as Interested! Highlighted row is ready to move to Leads page.'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        } else if (newStatus == 'Not interested') {
          _showNotInterestedReasonDialog(context, lead);
        }
      },
      itemBuilder: (ctx) => [
        if (isArchiveLead)
          PopupMenuItem(
            value: 'Unarchive',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.unarchive_rounded, size: 16, color: Color(0xFF10B981)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Unarchive Lead', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF10B981)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Restore back to active leads tab', style: TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (_selectedSection != 'Property Listing' && lead.leadType != 'Property Listing')
          PopupMenuItem(
            value: 'Follow up',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFFF59E0B)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Follow up', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Pick date, time & notes', style: TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (lead.leadType == 'Property Listing' || _selectedSection == 'Property Listing')
          PopupMenuItem(
            value: 'Call Outcome',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.call_split_rounded, size: 16, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Call Outcome', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0284C7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Follow-Ups, Call Back, CNR', style: TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (_selectedSection != 'Property Listing')
        PopupMenuItem(
          value: 'Transfer',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: CRMColors.primaryOf(context).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.swap_horiz_rounded, size: 16, color: CRMColors.primaryOf(context)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Transfer Lead...', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('CNR or Picked Up & Assign', style: TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (lead.leadType == 'Property Listing' || _selectedSection == 'Property Listing') ...[
          PopupMenuItem(
            value: 'Wrong Lead Requirement',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF8B5CF6)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Wrong Lead (move to requirement table)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF8B5CF6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Customer wants a property', style: TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          PopupMenuItem(
            value: 'Wrong Lead Property Listing',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.home_work_rounded, size: 16, color: Color(0xFF0284C7)),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Wrong Lead (move to property listing table)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0284C7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Customer wants to list property', style: TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        PopupMenuItem(
          value: 'Not interested',
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.thumb_down_alt_rounded, size: 16, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Not interested', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFEF4444)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('Move to Not Interested tab', style: TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isArchiveLead)
          PopupMenuItem(
            value: _selectedSection == 'Property Listing' ? 'Archive Property' : 'Archive Requirement',
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: (_selectedSection == 'Property Listing' ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _selectedSection == 'Property Listing' ? Icons.inventory_2_rounded : Icons.archive_rounded,
                    size: 16,
                    color: _selectedSection == 'Property Listing' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedSection == 'Property Listing' ? 'Archive Property' : 'Archive Requirement',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _selectedSection == 'Property Listing' ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _selectedSection == 'Property Listing'
                            ? 'Save to Property Listing archive'
                            : 'Save to Requirement archive',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: badgeBorder),
        ),
        child: isRealAdmin && actionUser.isNotEmpty && status != 'New' && status != 'Assigned' && status != 'Transfer'
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: textColor),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(Icons.arrow_drop_down_rounded, size: 16, color: textColor),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        actionLabelText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 14, color: textColor),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.arrow_drop_down_rounded, size: 16, color: textColor),
                ],
              ),
      ),
    );

    return popup;
  }

  Future<void> _showPropertyListingOutcomeDialog(BuildContext context, IntegrationLeadModel lead) async {
    final clientName = lead.getStringValue('full_name').isNotEmpty
        ? lead.getStringValue('full_name')
        : (lead.getStringValue('name').isNotEmpty ? lead.getStringValue('name') : 'Client');
    final phone = lead.getStringValue('phone_number').isNotEmpty
        ? lead.getStringValue('phone_number')
        : lead.getStringValue('phone');

    String selectedOption = 'Follow-Ups';
    final followupRemarksController = TextEditingController(text: lead.followupRemarks ?? '');
    final callbackRemarksController = TextEditingController(text: lead.callbackRemarks ?? '');
    final cnrRemarksController = TextEditingController();

    DateTime selectedFollowupDate = lead.followupScheduledAt ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedFollowupTime = lead.followupScheduledAt != null
        ? TimeOfDay.fromDateTime(lead.followupScheduledAt!)
        : const TimeOfDay(hour: 11, minute: 0);

    DateTime selectedCallbackDate = lead.callbackScheduledAt ?? DateTime.now().add(const Duration(hours: 2));
    TimeOfDay selectedCallbackTime = lead.callbackScheduledAt != null
        ? TimeOfDay.fromDateTime(lead.callbackScheduledAt!)
        : TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2)));

    bool remarksError = false;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.call_split_rounded, color: Color(0xFF0284C7), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Update Call Outcome',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$clientName ${phone.isNotEmpty ? '($phone)' : ''}',
                        style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Call Outcome *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Option 1: Follow-Ups
                          Expanded(
                            child: InkWell(
                              onTap: isSubmitting ? null : () => setDialogState(() => selectedOption = 'Follow-Ups'),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedOption == 'Follow-Ups'
                                      ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                                      : CRMColors.surfaceElevatedOf(ctx),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedOption == 'Follow-Ups'
                                        ? const Color(0xFFF59E0B)
                                        : CRMColors.borderOf(ctx),
                                    width: selectedOption == 'Follow-Ups' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 18,
                                      color: selectedOption == 'Follow-Ups' ? const Color(0xFFF59E0B) : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Follow-Ups',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: selectedOption == 'Follow-Ups' ? const Color(0xFFF59E0B) : null,
                                            ),
                                          ),
                                          Text(
                                            'Schedule follow-up',
                                            style: TextStyle(fontSize: 10, color: CRMColors.textSecondaryOf(ctx)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Option 2: Call Back
                          Expanded(
                            child: InkWell(
                              onTap: isSubmitting ? null : () => setDialogState(() => selectedOption = 'Call Back'),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedOption == 'Call Back'
                                      ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                                      : CRMColors.surfaceElevatedOf(ctx),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedOption == 'Call Back'
                                        ? const Color(0xFF3B82F6)
                                        : CRMColors.borderOf(ctx),
                                    width: selectedOption == 'Call Back' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.event_repeat_rounded,
                                      size: 18,
                                      color: selectedOption == 'Call Back' ? const Color(0xFF3B82F6) : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Call Back',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: selectedOption == 'Call Back' ? const Color(0xFF3B82F6) : null,
                                            ),
                                          ),
                                          Text(
                                            'Schedule call',
                                            style: TextStyle(fontSize: 10, color: CRMColors.textSecondaryOf(ctx)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Option 3: CNR
                          Expanded(
                            child: InkWell(
                              onTap: isSubmitting ? null : () => setDialogState(() => selectedOption = 'CNR'),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedOption == 'CNR'
                                      ? const Color(0xFFD97706).withValues(alpha: 0.12)
                                      : CRMColors.surfaceElevatedOf(ctx),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedOption == 'CNR'
                                        ? const Color(0xFFD97706)
                                        : CRMColors.borderOf(ctx),
                                    width: selectedOption == 'CNR' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone_missed_rounded,
                                      size: 18,
                                      color: selectedOption == 'CNR' ? const Color(0xFFD97706) : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'CNR',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: selectedOption == 'CNR' ? const Color(0xFFD97706) : null,
                                            ),
                                          ),
                                          Text(
                                            'Not received',
                                            style: TextStyle(fontSize: 10, color: CRMColors.textSecondaryOf(ctx)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // If Follow-Ups or Call Back is selected: Date & Time Picker + Remarks
                      if (selectedOption == 'Follow-Ups' || selectedOption == 'Call Back') ...[
                        Text(
                          selectedOption == 'Follow-Ups' ? 'Follow-up Date & Time *' : 'Callback Date & Time *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Date Picker
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: isSubmitting
                                    ? null
                                    : () async {
                                        final isFu = selectedOption == 'Follow-Ups';
                                        final currentD = isFu ? selectedFollowupDate : selectedCallbackDate;
                                        final picked = await showDatePicker(
                                          context: ctx,
                                          initialDate: currentD,
                                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (picked != null) {
                                          setDialogState(() {
                                            if (isFu) {
                                              selectedFollowupDate = picked;
                                            } else {
                                              selectedCallbackDate = picked;
                                            }
                                          });
                                        }
                                      },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: CRMColors.surfaceElevatedOf(ctx),
                                    border: Border.all(color: CRMColors.borderOf(ctx)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.event_rounded,
                                        size: 18,
                                        color: selectedOption == 'Follow-Ups' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          DateFormat('EEE, d MMM yyyy').format(
                                            selectedOption == 'Follow-Ups' ? selectedFollowupDate : selectedCallbackDate,
                                          ),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Time Picker
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: isSubmitting
                                    ? null
                                    : () async {
                                        final isFu = selectedOption == 'Follow-Ups';
                                        final currentT = isFu ? selectedFollowupTime : selectedCallbackTime;
                                        final picked = await showTimePicker(
                                          context: ctx,
                                          initialTime: currentT,
                                        );
                                        if (picked != null) {
                                          setDialogState(() {
                                            if (isFu) {
                                              selectedFollowupTime = picked;
                                            } else {
                                              selectedCallbackTime = picked;
                                            }
                                          });
                                        }
                                      },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: CRMColors.surfaceElevatedOf(ctx),
                                    border: Border.all(color: CRMColors.borderOf(ctx)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        size: 18,
                                        color: selectedOption == 'Follow-Ups' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          (selectedOption == 'Follow-Ups' ? selectedFollowupTime : selectedCallbackTime).format(ctx),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedOption == 'Follow-Ups' ? 'Remarks & Notes *' : 'Callback Notes (Remarks)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx)),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: selectedOption == 'Follow-Ups' ? followupRemarksController : callbackRemarksController,
                          maxLines: 3,
                          enabled: !isSubmitting,
                          onChanged: (_) {
                            if (remarksError) {
                              setDialogState(() => remarksError = false);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: selectedOption == 'Follow-Ups'
                                ? 'Enter discussion notes, follow-up requirements, client preferences...'
                                : 'Enter callback discussion notes, preferred callback timing...',
                            hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                            errorText: remarksError ? 'Remark is required' : null,
                            filled: true,
                            fillColor: CRMColors.surfaceElevatedOf(ctx),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: CRMColors.borderOf(ctx)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: CRMColors.borderOf(ctx)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: selectedOption == 'Follow-Ups' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (selectedOption == 'Follow-Ups' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (selectedOption == 'Follow-Ups' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6)).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: selectedOption == 'Follow-Ups' ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedOption == 'Follow-Ups'
                                      ? 'Lead will be updated to Follow-Up and scheduled with the selected date and notes.'
                                      : 'Lead status will become Callback and move to your Callbacks section with scheduled reminder timing.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey.shade300 : (selectedOption == 'Follow-Ups' ? const Color(0xFF92400E) : const Color(0xFF1E40AF)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // If CNR is selected:
                      if (selectedOption == 'CNR') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD97706).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFD97706)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mark as Interacted (CNR)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lead status will be updated to CNR and highlighted in warm amber in the table to indicate that this lead has already been interacted with.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey.shade300 : const Color(0xFF78350F),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Reason / Remarks (Optional)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx)),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: cnrRemarksController,
                          maxLines: 2,
                          enabled: !isSubmitting,
                          decoration: InputDecoration(
                            hintText: 'Enter any remarks (e.g. Call Not Received, Busy)...',
                            hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                            filled: true,
                            fillColor: CRMColors.surfaceElevatedOf(ctx),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: CRMColors.borderOf(ctx)),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: CRMColors.textSecondaryOf(ctx))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedOption == 'Follow-Ups'
                      ? const Color(0xFFF59E0B)
                      : (selectedOption == 'Call Back'
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFD97706)),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (selectedOption == 'Follow-Ups') {
                          final remarks = followupRemarksController.text.trim();
                          if (remarks.isEmpty) {
                            setDialogState(() => remarksError = true);
                            return;
                          }
                          final scheduledDateTime = DateTime(
                            selectedFollowupDate.year,
                            selectedFollowupDate.month,
                            selectedFollowupDate.day,
                            selectedFollowupTime.hour,
                            selectedFollowupTime.minute,
                          );

                          Navigator.pop(dialogCtx);
                          setState(() {
                            _cachedFilteredLeads = null;
                          });

                          final success = await _service.scheduleFollowup(
                            lead.id,
                            scheduledDateTime,
                            remarks,
                            status: 'Follow up',
                          );
                          if (mounted) {
                            if (success) {
                              _service.notifyOutcomeRecorded(
                                lead.id,
                                outcome: 'FOLLOWUP',
                                remarks: remarks,
                                callbackAt: scheduledDateTime.toUtc().toIso8601String(),
                              );
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Follow-up scheduled for ${DateFormat('d MMM, h:mm a').format(scheduledDateTime)}!'
                                      : 'Failed to schedule follow-up. Please check connection.',
                                ),
                                backgroundColor: success ? const Color(0xFFF59E0B) : CRMColors.danger,
                              ),
                            );
                            _loadFollowups();
                            unawaited(_service.fetchServerLeads(resetWithServer: true));
                          }
                          return;
                        }

                        if (selectedOption == 'Call Back') {
                          final scheduledDateTime = DateTime(
                            selectedCallbackDate.year,
                            selectedCallbackDate.month,
                            selectedCallbackDate.day,
                            selectedCallbackTime.hour,
                            selectedCallbackTime.minute,
                          );

                          Navigator.pop(dialogCtx);
                          setState(() {
                            _cachedFilteredLeads = null;
                          });

                          try {
                            final remarks = callbackRemarksController.text.trim();
                            final ok = await _service.scheduleFollowup(
                              lead.id,
                              scheduledDateTime,
                              remarks,
                              status: 'Callback',
                            );
                            if (!mounted) return;
                            setState(() {
                              _cachedFilteredLeads = null;
                            });
                            unawaited(_loadFollowups());
                            unawaited(_service.fetchServerLeads(resetWithServer: true));
                            _service.notifyOutcomeRecorded(
                              lead.id,
                              outcome: 'CALLBACK',
                              remarks: remarks,
                              callbackAt: scheduledDateTime.toUtc().toIso8601String(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Callback scheduled for ${DateFormat('dd MMM, hh:mm a').format(scheduledDateTime)}!'
                                    : 'Failed to schedule callback.'),
                                backgroundColor: ok ? const Color(0xFF0284C7) : const Color(0xFFEF4444),
                              ),
                            );
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to schedule callback: $e'),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                          return;
                        }

                        if (selectedOption == 'CNR') {
                          Navigator.pop(dialogCtx);
                          setState(() {
                            _cachedFilteredLeads = null;
                          });
                          final remarks = cnrRemarksController.text.trim();
                          final result = await _service.transferLead(lead.id, status: 'CNR', remarks: remarks.isNotEmpty ? remarks : 'Marked as CNR');
                          _service.notifyOutcomeRecorded(
                            lead.id,
                            outcome: 'CNR',
                            remarks: remarks.isNotEmpty ? remarks : 'Marked as CNR',
                          );
                          if (mounted) {
                            setState(() {
                              _cachedFilteredLeads = null;
                            });
                            final ok = result['success'] == true;
                            unawaited(_loadFollowups());
                            unawaited(_service.fetchServerLeads(resetWithServer: true));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Lead marked as CNR and updated on CNR page.'
                                      : (result['message']?.toString() ?? 'Failed to mark lead as CNR.'),
                                ),
                                backgroundColor: ok ? const Color(0xFFD97706) : const Color(0xFFEF4444),
                              ),
                            );
                          }
                          return;
                        }
                      },
                child: Text(
                  selectedOption == 'Follow-Ups'
                      ? 'Save Follow-up'
                      : (selectedOption == 'Call Back' ? 'Schedule Call Back' : 'Mark as CNR'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showScheduleFollowupDialog(BuildContext context, IntegrationLeadModel lead) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 11, minute: 0);
    final remarksController = TextEditingController(text: lead.followupRemarks ?? '');

    if (lead.followupScheduledAt != null) {
      selectedDate = lead.followupScheduledAt!;
      selectedTime = TimeOfDay.fromDateTime(lead.followupScheduledAt!);
    }

    final clientName = lead.getStringValue('full_name').isNotEmpty
        ? lead.getStringValue('full_name')
        : (lead.getStringValue('name').isNotEmpty ? lead.getStringValue('name') : 'Client');
    final phone = lead.getStringValue('phone_number').isNotEmpty
        ? lead.getStringValue('phone_number')
        : lead.getStringValue('phone');

    bool remarksMissing = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_month_rounded, color: Color(0xFFF59E0B), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Schedule Follow-up', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        '$clientName ${phone.isNotEmpty ? '($phone)' : ''}',
                        style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date & Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Date Picker Button
                        Expanded(
                          flex: 3,
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: ctx,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                border: Border.all(color: CRMColors.borderOf(ctx)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event_rounded, size: 18, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      DateFormat('EEE, d MMM yyyy').format(selectedDate),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Time Picker Button
                        Expanded(
                          flex: 2,
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: ctx,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setDialogState(() => selectedTime = picked);
                              }
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                                border: Border.all(color: CRMColors.borderOf(ctx)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedTime.format(ctx),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Remarks & Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: remarksController,
                      maxLines: 4,
                      onChanged: (_) {
                        if (remarksMissing) {
                          setDialogState(() => remarksMissing = false);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter discussion notes, callback requirements, client preferences...',
                        hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                        errorText: remarksMissing ? 'Remark is required' : null,
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: CRMColors.borderOf(ctx)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Save Follow-up'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final remarks = remarksController.text.trim();
                  if (remarks.isEmpty) {
                    setDialogState(() => remarksMissing = true);
                    return;
                  }
                  final scheduledDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  Navigator.pop(ctx);
                  setState(() {
                    _cachedFilteredLeads = null;
                  });

                  final success = await _service.scheduleFollowup(
                    lead.id,
                    scheduledDateTime,
                    remarks,
                    status: 'Follow up',
                  );
                  if (mounted) {
                    setState(() {
                      _cachedFilteredLeads = null;
                    });
                    if (success) {
                      _service.notifyOutcomeRecorded(
                        lead.id,
                        outcome: 'FOLLOWUP',
                        remarks: remarks,
                        callbackAt: scheduledDateTime.toUtc().toIso8601String(),
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? 'Follow-up scheduled for ${DateFormat('d MMM, h:mm a').format(scheduledDateTime)}!'
                              : 'Failed to schedule follow-up. Please check connection.',
                        ),
                        backgroundColor: success ? const Color(0xFFF59E0B) : CRMColors.danger,
                      ),
                    );
                    _loadFollowups();
                    unawaited(_service.fetchServerLeads(resetWithServer: true));
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showNotInterestedReasonDialog(BuildContext context, IntegrationLeadModel lead) async {
    final clientName = lead.getStringValue('full_name').isNotEmpty
        ? lead.getStringValue('full_name')
        : (lead.getStringValue('name').isNotEmpty ? lead.getStringValue('name') : 'Client');
    final phone = lead.getStringValue('phone_number').isNotEmpty
        ? lead.getStringValue('phone_number')
        : lead.getStringValue('phone');

    final notesController = TextEditingController();
    bool hasError = false;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.thumb_down_alt_rounded, color: Color(0xFFEF4444), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Mark as Not Interested',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$clientName ${phone.isNotEmpty ? '($phone)' : ''}',
                        style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Reason / Notes ',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CRMColors.textOf(ctx),
                        ),
                        children: const [
                          TextSpan(
                            text: '*',
                            style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notesController,
                      maxLines: 3,
                      autofocus: true,
                      enabled: !isSubmitting,
                      onChanged: (val) {
                        if (hasError && val.trim().isNotEmpty) {
                          setDialogState(() => hasError = false);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter reason why client is not interested (e.g., budget mismatch, not looking, bought elsewhere)...',
                        hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                        errorText: hasError ? 'Please enter a reason or note. This field is mandatory.' : null,
                        errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                        filled: true,
                        fillColor: CRMColors.surfaceElevatedOf(ctx),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: CRMColors.borderOf(ctx)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: hasError ? const Color(0xFFEF4444) : CRMColors.borderOf(ctx),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFEF4444),
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This note will be saved with the client and displayed in the Not Interested tab.',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade300 : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: CRMColors.textSecondaryOf(ctx))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final note = notesController.text.trim();
                        if (note.isEmpty) {
                          setDialogState(() => hasError = true);
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        Navigator.pop(dialogCtx);
                        setState(() {
                          _cachedFilteredLeads = null;
                        });

                        try {
                          await _service.updateLeadCampaignStatus(lead.id, 'Not interested', reason: note);
                          if (!context.mounted) return;
                          setState(() {
                            _cachedFilteredLeads = null;
                          });
                          unawaited(_loadFollowups());
                          unawaited(_service.fetchServerLeads(resetWithServer: true));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Lead marked as Not Interested and moved to Not Interested tab.'),
                              backgroundColor: const Color(0xFFEF4444),
                              action: SnackBarAction(
                                label: 'View',
                                textColor: Colors.white,
                                onPressed: () {
                                  setState(() {
                                    _viewMode = 'not_interested';
                                    _cachedFilteredLeads = null;
                                  });
                                },
                              ),
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to mark lead as Not Interested: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Mark Not Interested', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showBulkNotInterestedReasonDialog(BuildContext context, List<String> leadIds) async {
    final count = leadIds.length;
    final notesController = TextEditingController();
    bool hasError = false;
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.thumb_down_alt_rounded, color: Color(0xFFEF4444), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Mark Selected as Not Interested',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$count lead(s) selected',
                        style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        text: 'Reason / Notes ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textOf(ctx)),
                        children: const [
                          TextSpan(text: '*', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: notesController,
                      maxLines: 3,
                      autofocus: true,
                      enabled: !isSubmitting,
                      onChanged: (val) {
                        if (hasError && val.trim().isNotEmpty) {
                          setDialogState(() => hasError = false);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Enter reason why selected leads are not interested...',
                        hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                        errorText: hasError ? 'Please enter a reason or note. This field is mandatory.' : null,
                        errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                        filled: true,
                        fillColor: CRMColors.surfaceElevatedOf(ctx),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: CRMColors.textSecondaryOf(ctx))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final note = notesController.text.trim();
                        if (note.isEmpty) {
                          setDialogState(() => hasError = true);
                          return;
                        }
                        setDialogState(() => isSubmitting = true);
                        Navigator.pop(dialogCtx);
                        await _service.bulkUpdateCampaignStatus(leadIds, 'Not interested', reason: note);
                        unawaited(_service.fetchServerLeads(resetWithServer: true));
                        if (mounted) {
                          setState(() {
                            _selectedLeadIds.clear();
                            _cachedFilteredLeads = null;
                          });
                          unawaited(_loadFollowups());
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$count lead(s) marked as Not Interested and moved to Not Interested tab.'),
                              backgroundColor: const Color(0xFFEF4444),
                              action: SnackBarAction(
                                label: 'View',
                                textColor: Colors.white,
                                onPressed: () {
                                  setState(() {
                                    _viewMode = 'not_interested';
                                    _cachedFilteredLeads = null;
                                  });
                                },
                              ),
                            ),
                          );
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Mark Not Interested', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNotInterestedLeadDetailsDialog(BuildContext context, IntegrationLeadModel lead) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final name = lead.getStringValue('full_name').isNotEmpty
        ? lead.getStringValue('full_name')
        : (lead.getStringValue('name').isNotEmpty ? lead.getStringValue('name') : 'Lead');
    final phone = lead.getStringValue('phone_number').isNotEmpty
        ? lead.getStringValue('phone_number')
        : (lead.getStringValue('phone').isNotEmpty ? lead.getStringValue('phone') : '-');
    final email = lead.getStringValue('email').isNotEmpty ? lead.getStringValue('email') : '-';
    final campaignName = lead.getStringValue('campaign_name');
    final adName = lead.getStringValue('ad_name');
    final formName = lead.getStringValue('form_name');
    final notInterestedNote = lead.notInterestedReason?.trim().isNotEmpty == true
        ? lead.notInterestedReason!.trim()
        : (lead.rawJson['not_interested_reason']?.toString().trim().isNotEmpty == true
            ? lead.rawJson['not_interested_reason'].toString().trim()
            : (lead.rawJson['not_interested_notes']?.toString().trim().isNotEmpty == true
                ? lead.rawJson['not_interested_notes'].toString().trim()
                : (lead.rawJson['rejection_reason']?.toString().trim().isNotEmpty == true
                    ? lead.rawJson['rejection_reason'].toString().trim()
                    : (lead.rawJson['notes']?.toString().trim().isNotEmpty == true
                        ? lead.rawJson['notes'].toString().trim()
                        : (lead.getStringValue('notes').isNotEmpty
                            ? lead.getStringValue('notes')
                            : '-')))));

    final markedBy = lead.notInterestedByName?.trim().isNotEmpty == true
        ? lead.notInterestedByName!
        : (lead.statusUpdatedByName?.trim().isNotEmpty == true
            ? lead.statusUpdatedByName!
            : (lead.assignedTelecallerName?.trim().isNotEmpty == true ? lead.assignedTelecallerName! : 'Telecaller'));

    final markedAtText = lead.notInterestedAt != null
        ? DateFormat('d MMM yyyy, h:mm a').format(lead.notInterestedAt!.toLocal())
        : (lead.statusUpdatedAt != null
            ? DateFormat('d MMM yyyy, h:mm a').format(lead.statusUpdatedAt!.toLocal())
            : DateFormat('d MMM yyyy, h:mm a').format(lead.receivedAt.toLocal()));

    final ignoredKeys = {
      'id', 'ad_id', 'form_id', 'adset_id', 'campaign_id', 'platform',
      'is_organic', 'lead_status', 'created_time', 'phone_number', 'full_name',
      'email', 'Ad Name', 'ad_name', 'Campaign Name', 'campaign_name', 'form_name',
      'Form Name', 'adset_name', 'city', 'City', 'Name', 'name', 'Status', 'status',
      'Remarks', 'Remarks ', 'Number', '', '_transfer', '_lead_type', 'lead_type',
      'not_interested_reason', 'not_interested_notes', 'not_interested_by_name',
      'not_interested_by_id', 'not_interested_at', 'status_updated_by_name',
      'status_updated_by_id', 'status_updated_at', 'status_updated_by_role'
    };

    final questionnaire = <MapEntry<String, String>>[];
    for (final entry in lead.rawJson.entries) {
      final k = entry.key.toString().trim();
      final v = entry.value?.toString().trim() ?? '';
      if (!ignoredKeys.contains(k) && !k.startsWith('_') && v.isNotEmpty) {
        var title = k.replaceAll('_', ' ').replaceAll('?', '').trim();
        if (title.isNotEmpty) {
          title = title.substring(0, 1).toUpperCase() + title.substring(1);
        }
        questionnaire.add(MapEntry(title, v));
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        actionsPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
              child: const Icon(Icons.thumb_down_alt_rounded, color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Lead ID: ${lead.id}',
                    style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context)),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
              ),
              child: const Text(
                'Not Interested',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: CRMBreakpoints.adaptiveWidth(context, 520),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Highlighted Not Interested Note Card (Prominently displayed)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notes_rounded, color: Color(0xFFDC2626), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Not Interested Reason / Notes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notInterestedNote != '-' && notInterestedNote.isNotEmpty
                            ? notInterestedNote
                            : 'No note was recorded for this client.',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: notInterestedNote != '-' && notInterestedNote.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                          color: notInterestedNote != '-' && notInterestedNote.isNotEmpty
                              ? (isDark ? Colors.white : const Color(0xFF1E293B))
                              : CRMColors.textSecondaryOf(context),
                          fontStyle: notInterestedNote != '-' && notInterestedNote.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.support_agent_rounded, size: 13, color: Color(0xFF6366F1)),
                              const SizedBox(width: 4),
                              Text(
                                'Marked by: $markedBy',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded, size: 13, color: CRMColors.textSecondaryOf(context)),
                              const SizedBox(width: 4),
                              Text(
                                markedAtText,
                                style: TextStyle(fontSize: 11, color: CRMColors.textSecondaryOf(context)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Quick Call & WhatsApp Action Buttons
                if (phone != '-' && phone.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.call_rounded, size: 15),
                          label: const Text('Call Client'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                          onPressed: () => _launchTel(phone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                          label: const Text('WhatsApp'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF22C55E),
                            side: const BorderSide(color: Color(0xFF22C55E)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                          ),
                          onPressed: () => _launchWhatsApp(phone, name),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                // Contact & Source Information
                Text(
                  'Contact & Source Details',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CRMColors.textSecondaryOf(context)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: CRMColors.borderOf(context)),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(context, Icons.person_outline, 'Customer Name', name),
                      _buildDetailRow(context, Icons.phone_outlined, 'Phone', phone),
                      if (email != '-') _buildDetailRow(context, Icons.email_outlined, 'Email', email),
                      _buildDetailRow(context, Icons.source_rounded, 'Source', lead.source),
                      _buildDetailRow(context, Icons.category_outlined, 'Lead Type', lead.leadType),
                      _buildDetailRow(context, Icons.calendar_today_rounded, 'Received Date', DateFormat('d MMM yyyy, h:mm a').format(lead.receivedAt)),
                      if (campaignName.isNotEmpty) _buildDetailRow(context, Icons.campaign_outlined, 'Campaign', campaignName),
                      if (adName.isNotEmpty) _buildDetailRow(context, Icons.ad_units_outlined, 'Ad Name', adName),
                      if (formName.isNotEmpty) _buildDetailRow(context, Icons.description_outlined, 'Form Name', formName),
                    ],
                  ),
                ),

                // Form Questionnaire & Responses (if present)
                if (questionnaire.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Form Questionnaire & Responses',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: CRMColors.textSecondaryOf(context)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: CRMColors.borderOf(context)),
                    ),
                    child: Column(
                      children: questionnaire.map((q) => _buildDetailRow(context, Icons.check_circle_outline_rounded, q.key, q.value)).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: CRMColors.textSecondaryOf(context))),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.restore_rounded, size: 15),
            label: const Text('Restore to Active'),
            style: ElevatedButton.styleFrom(
              backgroundColor: CRMColors.primaryOf(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.updateLeadCampaignStatus(lead.id, 'New');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lead restored to Active Leads.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: CRMColors.textSecondaryOf(context)),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context), fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferLeadCell(BuildContext context, IntegrationLeadModel lead) {
    final isCnr = lead.campaignStatus == 'CNR';
    final isAssigned = lead.campaignStatus == 'Assigned' || (lead.assignedTo != null && lead.assignedTo!.isNotEmpty);
    final assignedName = lead.assignedToName;
    final remarks = lead.transferRemarks;
    final isPropertyListing = lead.leadType == 'Property Listing' || _selectedSection == 'Property Listing';
    final hasBadge = isAssigned || isCnr || (lead.assignedTelecallerName != null && lead.assignedTelecallerName!.isNotEmpty);
    final userRole = RoleGuard.currentUser?.role ?? '';
    final isTelecaller = RoleGuard.isTelecaller(userRole);
    final isAdminOrSuperAdmin = userRole == 'Admin' || userRole == 'Super Admin';
    final canTransferLead = isTelecaller || isAdminOrSuperAdmin;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canTransferLead) ...[
          Tooltip(
            message: isAdminOrSuperAdmin
                ? 'Assign or transfer this lead to a telecaller'
                : 'Transfer this lead to another telecaller',
            child: ElevatedButton.icon(
              onPressed: () => _showPartnerTelecallerDialog(context, lead),
              icon: const Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white),
              label: const Text(
                'Transfer',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                elevation: 0.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        if (isAssigned) ...[
          Tooltip(
            message: remarks?.isNotEmpty == true
                ? 'Assigned to ${assignedName ?? "Agent"}\nRemarks: $remarks'
                : 'Assigned to ${assignedName ?? "Agent"}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.assignment_ind_rounded, size: 14, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      assignedName?.isNotEmpty == true ? assignedName! : 'Assigned',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (remarks?.isNotEmpty == true) ...[
            const SizedBox(width: 4),
            Tooltip(
              message: 'Telecaller Key Points:\n$remarks',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF0F766E).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.speaker_notes_rounded, size: 12, color: Color(0xFF0F766E)),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 90),
                      child: Text(
                        remarks!,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!isPropertyListing) const SizedBox(width: 6),
        ] else if (isCnr) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone_missed_rounded, size: 13, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Text(
                  lead.assignedTelecallerName?.isNotEmpty == true
                      ? 'CNR (${lead.assignedTelecallerName})'
                      : 'CNR (Interacted)',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          if (!isPropertyListing) const SizedBox(width: 6),
        ] else if (lead.assignedTelecallerName?.isNotEmpty == true) ...[
          Tooltip(
            message: 'Allocated to Telecaller: ${lead.assignedTelecallerName}\nStatus: ${lead.allocationStatus ?? "ASSIGNED"}',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.support_agent_rounded, size: 14, color: Color(0xFF0284C7)),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 110),
                    child: Text(
                      lead.assignedTelecallerName!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isPropertyListing) const SizedBox(width: 6),
        ],

        // Transfer Button (Only for Requirement Leads, removed on Property Listing Leads tab)
        if (!isPropertyListing) ...[
          ElevatedButton.icon(
            onPressed: () => _showTransferDialog(context, lead),
            icon: Icon(
              isAssigned ? Icons.edit_note_rounded : Icons.swap_horiz_rounded,
              size: 14,
              color: Colors.white,
            ),
            label: Text(
              isTelecaller
                  ? (isAssigned ? 'Re-assign' : 'Outcome')
                  : (isAssigned ? 'Re-transfer' : 'Transfer'),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isAssigned
                  ? const Color(0xFF0F766E)
                  : (isCnr ? const Color(0xFFD97706) : CRMColors.primaryOf(context)),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              elevation: 0.5,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ] else if (!hasBadge) ...[
          const Text('—', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchPartnerTelecallers() async {
    final myId = RoleGuard.currentUser?.id.trim();
    final role = RoleGuard.currentUser?.role ?? '';
    final isAdminOrSuperAdmin = role == 'Admin' || role == 'Super Admin';
    try {
      final res = await DioClient.dio.get('/telecaller/partner-telecallers');
      final list = List<dynamic>.from(res.data['data'] ?? []);
      final partners = list
          .map((u) => Map<String, dynamic>.from(u as Map))
          .where((u) {
            if (!isAdminOrSuperAdmin && myId != null && myId.isNotEmpty && u['id']?.toString() == myId) {
              return false;
            }
            return true;
          })
          .toList();
      if (partners.isNotEmpty) return partners;
    } catch (e) {
      debugPrint('[PartnerTransfer] partner directory error: $e');
    }

    try {
      final allUsers = await _usersRepository.getUsers();
      return allUsers
          .where((u) {
            final r = u.roleName.toLowerCase();
            if (!r.contains('telecaller')) return false;
            if (!u.isActive) return false;
            if (!isAdminOrSuperAdmin && myId != null && myId.isNotEmpty && u.id == myId) return false;
            return true;
          })
          .map((u) => {
                'id': u.id,
                'full_name': u.fullName,
                'email': u.email,
              })
          .toList();
    } catch (e) {
      debugPrint('[PartnerTransfer] telecaller directory error: $e');
      return [];
    }
  }

  Future<void> _showPartnerTelecallerDialog(BuildContext context, IntegrationLeadModel lead) async {
    final clientName = lead.getStringValue('full_name').isNotEmpty
        ? lead.getStringValue('full_name')
        : (lead.getStringValue('name').isNotEmpty ? lead.getStringValue('name') : 'Lead');
    final phone = lead.getStringValue('phone_number').isNotEmpty
        ? lead.getStringValue('phone_number')
        : lead.getStringValue('phone');
    final noteController = TextEditingController();
    String? selectedId;
    var partners = <Map<String, dynamic>>[];
    var loading = true;
    var submitting = false;
    var started = false;
    final role = RoleGuard.currentUser?.role ?? '';
    final isAdminOrSuperAdmin = role == 'Admin' || role == 'Super Admin';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          if (!started) {
            started = true;
            _fetchPartnerTelecallers().then((users) {
              if (!dialogCtx.mounted) return;
              setDialogState(() {
                partners = users;
                loading = false;
                if (partners.isNotEmpty) {
                  // If current lead is assigned to someone in the list, preselect or select first alternative
                  final currentTelecallerId = lead.assignedTelecallerId;
                  if (isAdminOrSuperAdmin && currentTelecallerId != null && currentTelecallerId.isNotEmpty) {
                    final altList = partners.where((p) => p['id']?.toString() != currentTelecallerId).toList();
                    selectedId = (altList.isNotEmpty ? altList.first['id'] : partners.first['id'])?.toString();
                  } else {
                    selectedId = partners.first['id']?.toString();
                  }
                }
              });
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isAdminOrSuperAdmin ? 'Assign / Transfer Lead' : 'Transfer Lead'),
            content: SizedBox(
              width: CRMBreakpoints.adaptiveWidth(ctx, 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$clientName${phone.isNotEmpty ? ' · $phone' : ''}',
                    style: TextStyle(fontSize: 13, color: CRMColors.textSecondaryOf(ctx)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAdminOrSuperAdmin
                        ? 'Assign or transfer this lead to a telecaller. The lead and its activities will move to the selected telecaller.'
                        : 'This lead, including its follow-ups, moves to the telecaller you choose. It leaves your My Leads list.',
                    style: const TextStyle(fontSize: 12.5, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (partners.isEmpty)
                    const Text(
                      'No active telecaller is available.',
                      style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: selectedId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: isAdminOrSuperAdmin ? 'Select Telecaller' : 'Partner telecaller',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        for (final partner in partners)
                          DropdownMenuItem<String>(
                            value: partner['id']?.toString(),
                            child: Text(
                              (partner['full_name']?.toString().trim().isNotEmpty == true)
                                  ? (partner['id']?.toString() == lead.assignedTelecallerId
                                      ? '${partner['full_name']} (Currently Assigned)'
                                      : partner['full_name'].toString())
                                  : (partner['email']?.toString() ?? 'Telecaller'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: submitting
                          ? null
                          : (value) => setDialogState(() => selectedId = value),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    enabled: !submitting,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: isAdminOrSuperAdmin ? 'Assignment Note (optional)' : 'Note for admin (optional)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: submitting || loading || partners.isEmpty || selectedId == null
                    ? null
                    : () => Navigator.pop(ctx, true),
                child: Text(isAdminOrSuperAdmin ? 'Assign / Transfer' : 'Transfer'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true || selectedId == null || !context.mounted) {
      noteController.dispose();
      return;
    }

    Map<String, dynamic>? partner;
    for (final item in partners) {
      if (item['id']?.toString() == selectedId) {
        partner = item;
        break;
      }
    }
    final partnerName = partner?['full_name']?.toString().trim() ?? '';
    final destName = partnerName.isNotEmpty ? partnerName : 'Telecaller';

    submitting = true;
    final result = await _service.transferLeadToPartnerTelecaller(
      lead.id,
      toTelecallerId: selectedId!,
      toTelecallerName: destName,
      reason: noteController.text,
    );
    noteController.dispose();
    if (!context.mounted) return;
    final ok = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text((result['message'] ?? (ok ? 'Lead transferred.' : 'Transfer failed.')).toString()),
        backgroundColor: ok ? const Color(0xFF047857) : const Color(0xFFB91C1C),
      ),
    );
    if (ok) {
      unawaited(_loadFollowups());
      unawaited(_service.fetchServerLeads(resetWithServer: true));
      if (mounted) {
        setState(() {
          _cachedFilteredLeads = null;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSalesUsersForTransfer() async {
    try {
      final res = await DioClient.dio.get('/telecaller/sales-users');
      final list = List<dynamic>.from(res.data['data'] ?? []);
      if (list.isNotEmpty) {
        return list.map((u) => Map<String, dynamic>.from(u as Map)).toList();
      }
    } catch (e) {
      debugPrint('[TransferDialog] /telecaller/sales-users fetch error: $e');
    }

    // Fallback to /users
    try {
      final allUsers = await _usersRepository.getUsers();
      final salesUsers = allUsers.where((u) {
        final r = u.roleName.toLowerCase();
        return r.contains('sales') || r.contains('agent') || r.contains('advisor');
      }).toList();
      final pool = salesUsers.isNotEmpty ? salesUsers : allUsers.where((u) => u.isActive).toList();
      return pool.map((u) => {
        'id': u.id,
        'full_name': u.fullName,
        'email': u.email,
        'role_name': u.roleName,
      }).toList();
    } catch (e) {
      debugPrint('[TransferDialog] /users fetch error: $e');
    }

    return [];
  }

  Future<void> _showTransferDialog(BuildContext context, IntegrationLeadModel lead) async {
    final clientName = lead.getStringValue('full_name').isNotEmpty
        ? lead.getStringValue('full_name')
        : (lead.getStringValue('name').isNotEmpty ? lead.getStringValue('name') : 'Lead');
    final phone = lead.getStringValue('phone_number').isNotEmpty
        ? lead.getStringValue('phone_number')
        : lead.getStringValue('phone');

    String selectedStatus = lead.campaignStatus == 'CNR'
        ? 'CNR'
        : (lead.campaignStatus == 'Follow up' || lead.campaignStatus == 'Follow-up' ? 'Callback' : 'Picked Up');
    final remarksController = TextEditingController(text: lead.transferRemarks ?? '');
    DateTime selectedCallbackDate = lead.callbackScheduledAt ?? DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedCallbackTime = lead.callbackScheduledAt != null
        ? TimeOfDay.fromDateTime(lead.callbackScheduledAt!)
        : const TimeOfDay(hour: 11, minute: 0);
    final callbackRemarksController = TextEditingController(text: lead.callbackRemarks ?? '');
    final cnrRemarksController = TextEditingController();
    String? remarksError;
    bool isSubmitting = false;

    List<Map<String, dynamic>> assignableUsers = [];
    bool isLoadingUsers = true;
    String? selectedUserId = lead.assignedTo;
    bool didInitiateFetch = false;

    await showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          if (!didInitiateFetch) {
            didInitiateFetch = true;
            _fetchSalesUsersForTransfer().then((users) {
              if (dialogCtx.mounted) {
                setDialogState(() {
                  assignableUsers = users;
                  isLoadingUsers = false;
                  if (selectedUserId == null || !assignableUsers.any((u) => u['id'] == selectedUserId)) {
                    selectedUserId = assignableUsers.isNotEmpty ? assignableUsers.first['id'] as String? : null;
                  }
                });
              }
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CRMColors.primaryOf(ctx).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.swap_horiz_rounded, color: CRMColors.primaryOf(ctx), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Update Call Outcome',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$clientName ${phone.isNotEmpty ? '($phone)' : ''}',
                        style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Three Choice Question Cards: Picked Up, Callback, CNR
                      Text(
                        'Call Outcome *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Choice 1: Call picked up ?
                          Expanded(
                            child: InkWell(
                              onTap: isSubmitting ? null : () => setDialogState(() => selectedStatus = 'Picked Up'),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedStatus == 'Picked Up'
                                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                      : CRMColors.surfaceElevatedOf(ctx),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedStatus == 'Picked Up'
                                        ? const Color(0xFF10B981)
                                        : CRMColors.borderOf(ctx),
                                    width: selectedStatus == 'Picked Up' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone_in_talk_rounded,
                                      size: 18,
                                      color: selectedStatus == 'Picked Up' ? const Color(0xFF10B981) : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Picked Up',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: selectedStatus == 'Picked Up' ? const Color(0xFF10B981) : null,
                                            ),
                                          ),
                                          Text(
                                            'Assign to sales',
                                            style: TextStyle(fontSize: 10, color: CRMColors.textSecondaryOf(ctx)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Choice 2: Callback
                          Expanded(
                            child: InkWell(
                              onTap: isSubmitting ? null : () => setDialogState(() => selectedStatus = 'Callback'),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedStatus == 'Callback'
                                      ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
                                      : CRMColors.surfaceElevatedOf(ctx),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedStatus == 'Callback'
                                        ? const Color(0xFF3B82F6)
                                        : CRMColors.borderOf(ctx),
                                    width: selectedStatus == 'Callback' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.event_repeat_rounded,
                                      size: 18,
                                      color: selectedStatus == 'Callback' ? const Color(0xFF3B82F6) : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Callback',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: selectedStatus == 'Callback' ? const Color(0xFF3B82F6) : null,
                                            ),
                                          ),
                                          Text(
                                            'Schedule call',
                                            style: TextStyle(fontSize: 10, color: CRMColors.textSecondaryOf(ctx)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Choice 3: CNR
                          Expanded(
                            child: InkWell(
                              onTap: isSubmitting ? null : () => setDialogState(() => selectedStatus = 'CNR'),
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                                decoration: BoxDecoration(
                                  color: selectedStatus == 'CNR'
                                      ? const Color(0xFFD97706).withValues(alpha: 0.12)
                                      : CRMColors.surfaceElevatedOf(ctx),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedStatus == 'CNR'
                                        ? const Color(0xFFD97706)
                                        : CRMColors.borderOf(ctx),
                                    width: selectedStatus == 'CNR' ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.phone_missed_rounded,
                                      size: 18,
                                      color: selectedStatus == 'CNR' ? const Color(0xFFD97706) : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'CNR',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: selectedStatus == 'CNR' ? const Color(0xFFD97706) : null,
                                            ),
                                          ),
                                          Text(
                                            'Not received',
                                            style: TextStyle(fontSize: 10, color: CRMColors.textSecondaryOf(ctx)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // On CNR: Explanation & interaction highlight notice
                      if (selectedStatus == 'CNR') ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFD97706)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mark as Interacted (CNR)',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lead status will be updated to CNR and highlighted in warm amber in the table to indicate that this lead has already been interacted with. No sales assignment will be performed.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey.shade300 : const Color(0xFF78350F),
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Reason / Remarks (Optional)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx)),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: cnrRemarksController,
                          maxLines: 2,
                          enabled: !isSubmitting,
                          decoration: InputDecoration(
                            hintText: 'Enter any remarks (e.g. Call Not Received, Busy)...',
                            hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                            filled: true,
                            fillColor: CRMColors.surfaceElevatedOf(ctx),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: CRMColors.borderOf(ctx)),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],

                      // On Callback: Date & Time Picker + Discussion Notes
                      if (selectedStatus == 'Callback') ...[
                        Text(
                          'Callback Date & Time *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Date Picker
                            Expanded(
                              flex: 3,
                              child: InkWell(
                                onTap: isSubmitting
                                    ? null
                                    : () async {
                                        final picked = await showDatePicker(
                                          context: ctx,
                                          initialDate: selectedCallbackDate,
                                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                                          lastDate: DateTime.now().add(const Duration(days: 365)),
                                        );
                                        if (picked != null) {
                                          setDialogState(() => selectedCallbackDate = picked);
                                        }
                                      },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: CRMColors.surfaceElevatedOf(ctx),
                                    border: Border.all(color: CRMColors.borderOf(ctx)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.event_rounded, size: 18, color: Color(0xFF3B82F6)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          DateFormat('EEE, d MMM yyyy').format(selectedCallbackDate),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Time Picker
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: isSubmitting
                                    ? null
                                    : () async {
                                        final picked = await showTimePicker(
                                          context: ctx,
                                          initialTime: selectedCallbackTime,
                                        );
                                        if (picked != null) {
                                          setDialogState(() => selectedCallbackTime = picked);
                                        }
                                      },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: CRMColors.surfaceElevatedOf(ctx),
                                    border: Border.all(color: CRMColors.borderOf(ctx)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 18, color: Color(0xFF3B82F6)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selectedCallbackTime.format(ctx),
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Callback Discussion Notes (Remarks)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx)),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: callbackRemarksController,
                          maxLines: 3,
                          enabled: !isSubmitting,
                          decoration: InputDecoration(
                            hintText: 'Enter discussion notes, preferred callback timing, client requirements...',
                            hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                            filled: true,
                            fillColor: CRMColors.surfaceElevatedOf(ctx),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: CRMColors.borderOf(ctx)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: CRMColors.borderOf(ctx)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: CRMColors.primaryOf(ctx), width: 1.5),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF3B82F6)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Lead status will become Follow up and move to your Callbacks tab/page with scheduled reminder timing.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey.shade300 : const Color(0xFF1E40AF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // On Picked Up: Show "Type property key points here" and "Lead Assign Dropdown"
                      if (selectedStatus == 'Picked Up') ...[
                        // 1. "Type property key points here *" (Mandatory)
                        RichText(
                          text: TextSpan(
                            text: 'Type property key points here ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx)),
                            children: const [
                              TextSpan(text: '*', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: remarksController,
                          maxLines: 3,
                          enabled: !isSubmitting,
                          onChanged: (val) {
                            if (remarksError != null) {
                              setDialogState(() => remarksError = null);
                            }
                          },
                          decoration: InputDecoration(
                            errorText: remarksError,
                            errorStyle: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                            hintText: 'Type property key points (e.g. 3 BHK in Shela/Bopal, budget ₹35k, client preferences, visit timing)...',
                            hintStyle: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(ctx)),
                            filled: true,
                            fillColor: CRMColors.surfaceElevatedOf(ctx),
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: CRMColors.borderOf(ctx)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: CRMColors.borderOf(ctx)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: CRMColors.primaryOf(ctx), width: 1.5),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 16),

                        // 2. Lead Assign Dropdown
                        Text(
                          'Lead Assign Dropdown (Sales Users) *',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CRMColors.textSecondaryOf(ctx)),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: CRMColors.surfaceElevatedOf(ctx),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CRMColors.borderOf(ctx)),
                          ),
                          child: isLoadingUsers
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                      SizedBox(width: 10),
                                      Text('Loading sales team from database...', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                    ],
                                  ),
                                )
                              : (assignableUsers.isEmpty
                                  ? const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Text('No active sales users found in your organization.', style: TextStyle(fontSize: 13, color: Colors.orange)),
                                    )
                                  : DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: assignableUsers.any((u) => u['id'] == selectedUserId) ? selectedUserId : null,
                                        isExpanded: true,
                                        hint: const Text('Select Sales User to Assign', style: TextStyle(fontSize: 13)),
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                        items: assignableUsers.map((u) {
                                          final uId = u['id']?.toString() ?? '';
                                          final uName = u['full_name']?.toString() ?? 'User';
                                          final uRole = u['role_name']?.toString() ?? 'Sales';
                                          return DropdownMenuItem<String>(
                                            value: uId,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: CRMColors.primaryOf(ctx).withValues(alpha: 0.15),
                                                  child: Text(
                                                    uName.isNotEmpty ? uName[0].toUpperCase() : 'U',
                                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CRMColors.primaryOf(ctx)),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '$uName ($uRole)',
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: isSubmitting
                                            ? null
                                            : (val) {
                                                setDialogState(() => selectedUserId = val);
                                              },
                                      ),
                                    )),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFF10B981)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Status will become Assigned automatically, and the sales user will receive a push notification.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey.shade300 : const Color(0xFF065F46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: Text('Cancel', style: TextStyle(color: CRMColors.textSecondaryOf(ctx))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedStatus == 'CNR'
                      ? const Color(0xFFD97706)
                      : (selectedStatus == 'Callback'
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFF10B981)),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (selectedStatus == 'Callback') {
                          final scheduledDateTime = DateTime(
                            selectedCallbackDate.year,
                            selectedCallbackDate.month,
                            selectedCallbackDate.day,
                            selectedCallbackTime.hour,
                            selectedCallbackTime.minute,
                          );

                          setDialogState(() => isSubmitting = true);
                          Navigator.pop(dialogCtx);
                          setState(() {
                            _cachedFilteredLeads = null;
                          });

                          try {
                            final ok = await _service.scheduleFollowup(
                              lead.id,
                              scheduledDateTime,
                              callbackRemarksController.text.trim(),
                              status: 'Callback',
                            );
                            if (!context.mounted) return;
                            setState(() {
                              _cachedFilteredLeads = null;
                            });
                            unawaited(_loadFollowups());
                            unawaited(_service.fetchServerLeads(resetWithServer: true));
                            _service.notifyOutcomeRecorded(
                              lead.id,
                              outcome: 'CALLBACK',
                              remarks: callbackRemarksController.text.trim(),
                              callbackAt: scheduledDateTime.toUtc().toIso8601String(),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(ok
                                    ? 'Callback scheduled for ${DateFormat('dd MMM, hh:mm a').format(scheduledDateTime)}!'
                                    : 'Failed to schedule callback.'),
                                backgroundColor: ok ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
                              ),
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to schedule callback: $e'),
                                  backgroundColor: const Color(0xFFEF4444),
                                ),
                              );
                            }
                          }
                          return;
                        }

                        if (selectedStatus == 'Picked Up') {
                          if (remarksController.text.trim().isEmpty) {
                            setDialogState(() {
                              remarksError = 'Property key points (remarks) are mandatory when assigning a lead.';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter property key points. Remarks are mandatory when assigning a lead.'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }
                          if (selectedUserId == null || selectedUserId!.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a sales user to assign the lead to.'),
                                backgroundColor: Color(0xFFEF4444),
                              ),
                            );
                            return;
                          }
                        }

                        try {
                          setDialogState(() => isSubmitting = true);

                          final targetUser = assignableUsers.firstWhere(
                            (u) => u['id']?.toString() == selectedUserId?.toString(),
                            orElse: () => {'full_name': 'Sales User'},
                          );
                          final targetUserName = (targetUser['full_name'] as String?) ?? 'Sales User';

                          // Pop dialog immediately so user is never stuck in loading
                          if (dialogCtx.mounted) {
                            Navigator.pop(dialogCtx);
                          }
                          setState(() {
                            _cachedFilteredLeads = null;
                          });

                          final cnrRemarks = cnrRemarksController.text.trim();
                          final effectiveRemarks = selectedStatus == 'CNR'
                              ? (cnrRemarks.isNotEmpty ? cnrRemarks : 'Marked as CNR')
                              : remarksController.text.trim();

                          final result = await _service.transferLead(
                            lead.id,
                            status: selectedStatus,
                            assignedTo: selectedStatus == 'Picked Up' ? selectedUserId : null,
                            assignedToName: selectedStatus == 'Picked Up' ? targetUserName : null,
                            remarks: effectiveRemarks,
                          );
                          _service.notifyOutcomeRecorded(
                            lead.id,
                            outcome: selectedStatus == 'Picked Up' ? 'PICKED_UP' : (selectedStatus == 'Callback' ? 'CALLBACK' : 'CNR'),
                            remarks: effectiveRemarks,
                            salesUserId: selectedStatus == 'Picked Up' ? selectedUserId : null,
                            assignedToName: selectedStatus == 'Picked Up' ? targetUserName : null,
                          );
                          if (!context.mounted) return;
                          setState(() {
                            _cachedFilteredLeads = null;
                          });
                          unawaited(_loadFollowups());
                          final ok = result['success'] == true;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? (selectedStatus == 'CNR'
                                        ? 'Lead status changed to CNR.'
                                        : 'Lead transferred & assigned to $targetUserName! Status automatically set to Assigned.')
                                    : (result['message']?.toString() ?? 'Failed to transfer lead.'),
                              ),
                              backgroundColor: !ok
                                  ? const Color(0xFFEF4444)
                                  : (selectedStatus == 'CNR'
                                      ? const Color(0xFFD97706)
                                      : const Color(0xFF10B981)),
                            ),
                          );
                        } catch (e) {
                          if (dialogCtx.mounted) {
                            setDialogState(() => isSubmitting = false);
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to transfer lead: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          }
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        selectedStatus == 'CNR'
                            ? 'Confirm CNR'
                            : (selectedStatus == 'Callback'
                                ? 'Schedule Callback'
                                : 'Assign & Transfer Lead'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _moveInterestedToCrm(BuildContext context) async {
    final interestedLeads = _scopedLeads.where((l) =>
        l.leadType == _selectedSection &&
        l.campaignStatus == 'Interested' &&
        l.importStatus != 'Imported').toList();

    if (interestedLeads.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No new interested leads to move in this section.')),
      );
      return;
    }

    final ids = interestedLeads.map((l) => l.id).toList();
    final targetPage = _selectedSection == 'Property Listing' ? 'Properties' : 'Leads';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Move to $targetPage Page?',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'Move ${ids.length} interested lead(s) to the $targetPage page? Our CRM will automatically ingest and manage these leads.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Move ${ids.length} to $targetPage'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isImporting = true);
    final count = _selectedSection == 'Property Listing'
        ? await _service.importLeadsToProperties(ids)
        : await _service.importLeadsToCrm(ids);
    if (!mounted) return;
    setState(() {
      _isImporting = false;
      _selectedLeadIds.clear();
      _cachedFilteredLeads = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully moved $count interested lead(s) to $targetPage page.'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Widget _buildInterestedLeadsAlertBanner(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    final actionButton = ElevatedButton.icon(
      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
      label: Text(
        _selectedSection == 'Property Listing'
            ? 'Move to Properties ($_cachedInterestedCount)'
            : 'Move to Leads Page ($_cachedInterestedCount)',
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _isImporting ? null : () => _moveInterestedToCrm(context),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.star_rounded, color: Color(0xFF10B981), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$_cachedInterestedCount Interested Lead${_cachedInterestedCount > 1 ? 's' : ''} Ready for CRM',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'These leads are marked as interested. Click below to transfer them directly into the ${_selectedSection == 'Property Listing' ? 'Properties' : 'Leads'} page.',
                  style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                ),
                const SizedBox(height: 10),
                actionButton,
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_cachedInterestedCount Interested Lead${_cachedInterestedCount > 1 ? 's' : ''} Ready for CRM',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'These leads are marked as interested. Click below to transfer them directly into the ${_selectedSection == 'Property Listing' ? 'Properties' : 'Leads'} page.',
                        style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                actionButton,
              ],
            ),
    );
  }

  bool _followupBelongsToCurrentTelecaller(CampaignFollowupModel followup) {
    if (!RoleGuard.isTelecaller(RoleGuard.currentUser?.role)) return true;
    final myId = RoleGuard.currentUser?.id.trim().toLowerCase();
    if (myId == null || myId.isEmpty) return true;
    if (followup.telecallerId != null && followup.telecallerId!.trim().toLowerCase() == myId) {
      return true;
    }
    final local = _service.getLeadById(followup.leadId);
    final assigned = (local?.assignedTelecallerId ?? followup.lead?.assignedTelecallerId)
        ?.trim()
        .toLowerCase();
    if (assigned == null || assigned.isEmpty) return true;
    return assigned == myId;
  }

  Future<void> _loadFollowups() async {
    if (_isLoadingFollowups) return;
    setState(() => _isLoadingFollowups = true);
    try {
      final list = await _service.fetchFollowups(filter: 'all');
      if (mounted) {
        setState(() {
          _followupsList = list.where((f) {
            if (f.status == 'Completed' || f.status == 'Cancelled' || f.status == 'Callback' || f.status == 'CALLBACK') return false;
            final local = _service.getLeadById(f.leadId);
            final leadStatus = (local?.campaignStatus ?? f.lead?.campaignStatus ?? '').trim().toLowerCase();
            final allocStatus = (local?.allocationStatus ?? f.lead?.allocationStatus ?? '').trim().toUpperCase();
            if (leadStatus == 'callback' || leadStatus == 'call back' || allocStatus == 'CALLBACK') {
              return false;
            }
            if (leadStatus == 'cnr' || allocStatus == 'CNR') {
              return false;
            }
            if (leadStatus == 'not interested' || allocStatus == 'RELEASED') {
              return false;
            }
            return _followupBelongsToCurrentTelecaller(f);
          }).toList();
          _isLoadingFollowups = false;
          _cachedFilteredLeads = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingFollowups = false);
      }
    }
  }

  Widget _buildFollowupSubChip(String label, String value, int count) {
    final isSelected = _followupFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() => _followupFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF59E0B)
              : (isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFF59E0B) : CRMColors.borderOf(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : CRMColors.textOf(context),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
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
        ),
      ),
    );
  }

  int _pendingDueFollowupLeadCount() {
    final leadIds = <String>{};
    final serviceLeadMap = {for (final l in _service.leads) l.id: l};
    for (final f in _followupsList) {
      if (f.status == 'Completed' || f.status == 'Cancelled' || f.status == 'Callback' || f.status == 'CALLBACK') continue;
      final localLead = serviceLeadMap[f.leadId] ?? f.lead;
      if (localLead != null) {
        final cs = localLead.campaignStatus;
        final isFollowup = cs == 'Follow up' || cs == 'Follow-up';
        if (!isFollowup && (cs == 'Callback' || cs == 'Call Back')) continue;
        if (!isFollowup && cs != null && cs.isNotEmpty) continue;
      }
      leadIds.add(f.leadId);
    }
    for (final lead in _service.leads) {
      if (lead.campaignStatus == 'Follow up' || lead.campaignStatus == 'Follow-up') {
        final fuStatus = (lead.followupStatus ?? 'Pending').trim().toLowerCase();
        if (fuStatus == 'completed' || fuStatus == 'cancelled') continue;
        leadIds.add(lead.id);
      }
    }
    return leadIds.length;
  }

  String _followupDisplayName(CampaignFollowupModel item) {
    IntegrationLeadModel? live;
    try {
      live = _service.leads.firstWhere((lead) => lead.id == item.leadId);
    } catch (_) {}
    live ??= item.lead;
    final fromLead = live?.getStringValue('full_name').trim() ?? '';
    if (fromLead.isNotEmpty) return fromLead;
    final stored = item.clientName.trim();
    return stored.isNotEmpty ? stored : 'Client';
  }

  Widget _buildFollowupsView(BuildContext context) {
    final allItems = List<CampaignFollowupModel>.from(_followupsList);

    // If items empty or incomplete, incorporate leads in memory that have scheduled followups
    final leadFollowupIds = allItems.map((f) => f.leadId).toSet();
    for (final lead in _scopedLeads) {
      if ((lead.campaignStatus == 'Follow up' || lead.campaignStatus == 'Follow-up') &&
          !leadFollowupIds.contains(lead.id)) {
        final name = lead.getStringValue('full_name').isNotEmpty
            ? lead.getStringValue('full_name')
            : (lead.getStringValue('name').isNotEmpty ? lead.getStringValue('name') : 'Campaign Lead');
        final phone = lead.getStringValue('phone_number').isNotEmpty
            ? lead.getStringValue('phone_number')
            : lead.getStringValue('phone');
        final tcName = lead.assignedTelecallerName ??
            (lead.rawJson['assigned_telecaller_name'] ??
                    lead.rawJson['status_updated_by_name'])
                ?.toString();

        allItems.add(CampaignFollowupModel(
          id: 'local_${lead.id}',
          leadId: lead.id,
          leadType: lead.leadType,
          clientName: name,
          mobile: phone,
          scheduledAt: lead.followupScheduledAt ?? DateTime.now().add(const Duration(hours: 1)),
          remarks: lead.followupRemarks ?? '',
          status: lead.followupStatus ?? 'Pending',
          createdAt: lead.receivedAt,
          lead: lead,
          telecallerName: tcName,
        ));
      }
    }

    final role = (RoleGuard.currentUser?.role ?? '').toLowerCase().trim();
    final currentAuth = context.read<AuthBloc>().state;
    final currentRoleStr = (currentAuth is Authenticated ? currentAuth.user.role : null)?.toLowerCase().trim() ?? '';
    final isAdminOnly = role == 'admin' || role == 'super admin' || currentRoleStr == 'admin' || currentRoleStr == 'super admin';
    final canUseTelecallerFilter = isAdminOnly;

    // Extract telecallers strictly (exclude salespersons and admins)
    final Map<String, int> telecallerCounts = {};
    final telecallerUsers = (_cachedUsers ?? const <users_model.UserModel>[])
        .where((u) {
          final r = u.roleName.toLowerCase().trim();
          return r == 'telecaller' || (r.contains('telecaller') && !r.contains('sales'));
        })
        .toList()
      ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

    final nonTelecallerNames = (_cachedUsers ?? const <users_model.UserModel>[])
        .where((u) {
          final r = u.roleName.toLowerCase().trim();
          return r != 'telecaller' && !r.contains('telecaller');
        })
        .map((u) => u.fullName.trim().toLowerCase())
        .toSet();

    for (final f in allItems) {
      final tcName = (f.telecallerName ??
              f.lead?.assignedTelecallerName ??
              f.lead?.rawJson['assigned_telecaller_name'] ??
              '')
          .toString()
          .trim();
      if (tcName.isNotEmpty && !nonTelecallerNames.contains(tcName.toLowerCase())) {
        telecallerCounts[tcName] = (telecallerCounts[tcName] ?? 0) + 1;
      }
    }
    for (final u in telecallerUsers) {
      final name = u.fullName.trim();
      if (name.isNotEmpty && !telecallerCounts.containsKey(name)) {
        telecallerCounts[name] = 0;
      }
    }
    final telecallerNames = telecallerCounts.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // Filter by telecaller only if Admin and a specific telecaller is selected
    List<CampaignFollowupModel> telecallerScopedItems = List.from(allItems);
    if (isAdminOnly && _selectedFollowupTelecaller != 'All' && _selectedFollowupTelecaller.isNotEmpty) {
      telecallerScopedItems = telecallerScopedItems.where((f) {
        final tcName = (f.telecallerName ??
                f.lead?.assignedTelecallerName ??
                f.lead?.rawJson['assigned_telecaller_name'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();
        return tcName == _selectedFollowupTelecaller.toLowerCase();
      }).toList();
    }

    final totalCount = telecallerScopedItems.length;
    final todayCount = telecallerScopedItems.where((f) => f.isToday).length;
    final futureCount = telecallerScopedItems.where((f) => f.isFuture).length;
    final missedCount = telecallerScopedItems.where((f) => f.isPast).length;

    List<CampaignFollowupModel> items = List.from(telecallerScopedItems);
    if (_followupFilter == 'today') {
      items = items.where((f) => f.isToday).toList();
    } else if (_followupFilter == 'future') {
      items = items.where((f) => f.isFuture).toList();
    } else if (_followupFilter == 'missed') {
      items = items.where((f) => f.isPast).toList();
    }

    // Now filter by search for the active tab
    final currentTabController = _followupTabSearchControllers[_followupFilter] ?? _followupSearchController;
    final tabSearchQuery = (_followupTabSearchQueries[_followupFilter] ?? '').trim().toLowerCase();

    if (tabSearchQuery.isNotEmpty) {
      final q = tabSearchQuery;
      final cleanQ = q.replaceAll(RegExp(r'\D'), '');
      items = items.where((f) {
        final name = f.clientName.toLowerCase();
        final mobile = f.mobile.replaceAll(RegExp(r'\D'), '');
        final remarks = f.remarks.toLowerCase();
        final leadType = f.leadType.toLowerCase();
        final email = (f.lead?.getStringValue('email') ?? '').toLowerCase();
        final source = (f.lead?.getStringValue('source') ?? '').toLowerCase();
        final tcName = (f.telecallerName ?? f.lead?.assignedTelecallerName ?? '').toLowerCase();

        return name.contains(q) ||
            (cleanQ.isNotEmpty && mobile.contains(cleanQ)) ||
            f.mobile.toLowerCase().contains(q) ||
            remarks.contains(q) ||
            leadType.contains(q) ||
            email.contains(q) ||
            source.contains(q) ||
            tcName.contains(q);
      }).toList();
    }

    items.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFollowupSubChip('All Follow-ups', 'all', totalCount),
                    const SizedBox(width: 8),
                    _buildFollowupSubChip('Today', 'today', todayCount),
                    const SizedBox(width: 8),
                    _buildFollowupSubChip('Future', 'future', futureCount),
                    const SizedBox(width: 8),
                    _buildFollowupSubChip('Overdue', 'missed', missedCount),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh Follow-ups',
              onPressed: _loadFollowups,
            ),
          ],
        ),

        if (canUseTelecallerFilter && telecallerNames.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFollowupTelecallerChip('All Telecallers', 'All', allItems.length),
                      for (final name in telecallerNames) ...[
                        const SizedBox(width: 6),
                        _buildFollowupTelecallerChip(name, name, telecallerCounts[name] ?? 0),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 12),
        SizedBox(
          height: 38,
          child: TextField(
            key: ValueKey('followup_search_$_followupFilter'),
            controller: currentTabController,
            onChanged: (val) {
              _followupSearchDebounce?.cancel();
              _followupSearchDebounce = Timer(const Duration(milliseconds: 150), () {
                if (!mounted) return;
                setState(() {
                  _followupTabSearchQueries[_followupFilter] = val.trim().toLowerCase();
                });
              });
            },
            decoration: InputDecoration(
              hintText: 'Search ${_getFollowupTabLabel(_followupFilter)} by client name, phone, remarks...',
              hintStyle: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: currentTabController.text.isNotEmpty
                  ? IconButton(
                      tooltip: 'Clear',
                      icon: const Icon(Icons.close_rounded, size: 16),
                      onPressed: () {
                        _followupSearchDebounce?.cancel();
                        currentTabController.clear();
                        setState(() {
                          _followupTabSearchQueries[_followupFilter] = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: CRMColors.borderOf(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: CRMColors.borderOf(context)),
              ),
              filled: true,
              fillColor: CRMColors.cardBgOf(context),
            ),
          ),
        ),

        const SizedBox(height: CRMSpacing.m),

        if (_isLoadingFollowups)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else if (items.isEmpty)
          CRMCard(
            child: Container(
              height: 220,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.schedule_rounded, size: 48, color: Color(0xFFF59E0B)),
                  const SizedBox(height: 12),
                  Text(
                    tabSearchQuery.isNotEmpty
                        ? 'No Matching Follow-ups'
                        : (isAdminOnly && _selectedFollowupTelecaller != 'All'
                            ? 'No Follow-ups for $_selectedFollowupTelecaller'
                            : 'No ${_getFollowupTabLabel(_followupFilter)} Found'),
                    style: CRMTypography.headline.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tabSearchQuery.isNotEmpty
                        ? 'Try searching with a different name, phone number, or remark.'
                        : (isAdminOnly && _selectedFollowupTelecaller != 'All'
                            ? 'This telecaller has no follow-ups in the selected tab.'
                            : 'Schedule a follow-up from the Active Leads table using the Status dropdown.'),
                    style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          ...items.map((item) => _buildFollowupCard(context, item)),
      ],
    );
  }

  String _getFollowupTabLabel(String filter) {
    switch (filter) {
      case 'today':
        return 'Today';
      case 'future':
        return 'Future';
      case 'missed':
        return 'Overdue';
      case 'all':
      default:
        return 'All Follow-ups';
    }
  }

  Widget _buildFollowupTelecallerChip(String label, String value, int count) {
    final isSelected = _selectedFollowupTelecaller.toLowerCase() == value.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const activeColor = Color(0xFF6366F1);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        setState(() {
          _selectedFollowupTelecaller = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? activeColor : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value == 'All' ? Icons.groups_rounded : Icons.support_agent_rounded,
              size: 14,
              color: isSelected ? Colors.white : activeColor,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : CRMColors.textOf(context),
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.25)
                    : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : CRMColors.textSecondaryOf(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowupCard(BuildContext context, CampaignFollowupModel item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;
    Color tagColor = const Color(0xFF3B82F6);
    String tagLabel = 'Upcoming';
    if (item.isToday) {
      tagColor = const Color(0xFFF59E0B);
      tagLabel = 'Today';
    } else if (item.isPast) {
      tagColor = const Color(0xFFEF4444);
      tagLabel = 'Overdue';
    }

    final role = (RoleGuard.currentUser?.role ?? '').toLowerCase();
    final isRealAdmin = role == 'admin' || role == 'super admin';

    final formattedDateTime = DateFormat('EEE, d MMM yyyy • h:mm a').format(item.scheduledAt);

    final actionButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.mobile.isNotEmpty) ...[
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: Color(0xFF10B981), size: 18),
            tooltip: 'Call Client',
            onPressed: () => _launchTel(item.mobile),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF22C55E), size: 18),
            tooltip: 'Chat on WhatsApp',
            onPressed: () => _launchWhatsApp(item.mobile, item.clientName),
          ),
        ],
        IconButton(
          icon: const Icon(Icons.edit_calendar_rounded, color: Color(0xFFF59E0B), size: 18),
          tooltip: 'Reschedule Follow-up',
          onPressed: () {
            final lead = item.lead ?? _service.leads.firstWhere(
              (l) => l.id == item.leadId,
              orElse: () => IntegrationLeadModel(
                id: item.leadId,
                source: 'Meta Ads',
                receivedAt: item.createdAt,
                rawJson: {'full_name': item.clientName, 'phone_number': item.mobile},
              ),
            );
            _showScheduleFollowupDialog(context, lead);
          },
        ),
        IconButton(
          icon: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF10B981), size: 19),
          tooltip: 'Transfer Lead',
          onPressed: () {
            IntegrationLeadModel? foundLead;
            try {
              foundLead = _service.leads.firstWhere((l) => l.id == item.leadId);
            } catch (_) {}
            final lead = foundLead ??
                item.lead ??
                IntegrationLeadModel(
                  id: item.leadId,
                  source: 'Meta Ads',
                  leadType: item.leadType,
                  receivedAt: item.createdAt,
                  rawJson: {'full_name': item.clientName, 'phone_number': item.mobile},
                );
            _showTransferDialog(context, lead);
          },
        ),
        IconButton(
          icon: const Icon(Icons.thumb_down_alt_rounded, color: Color(0xFFEF4444), size: 18),
          tooltip: 'Mark Not Interested',
          onPressed: () {
            IntegrationLeadModel? foundLead;
            try {
              foundLead = _service.leads.firstWhere((l) => l.id == item.leadId);
            } catch (_) {}
            final lead = foundLead ??
                item.lead ??
                IntegrationLeadModel(
                  id: item.leadId,
                  source: 'Meta Ads',
                  leadType: item.leadType,
                  receivedAt: item.createdAt,
                  rawJson: {'full_name': item.clientName, 'phone_number': item.mobile},
                );
            _showNotInterestedReasonDialog(context, lead);
          },
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.s),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.borderOf(context)),
        boxShadow: CRMShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.schedule_rounded, color: tagColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _followupDisplayName(item),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tagLabel,
                            style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.leadType,
                            style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (isRealAdmin && item.telecallerName != null && item.telecallerName!.trim().isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.support_agent_rounded, size: 12, color: Color(0xFF6366F1)),
                                const SizedBox(width: 4),
                                Text(
                                  'Telecaller: ${item.telecallerName}',
                                  style: const TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 13, color: tagColor),
                            const SizedBox(width: 5),
                            Text(
                              formattedDateTime,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tagColor),
                            ),
                          ],
                        ),
                        if (item.mobile.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone_rounded, size: 13, color: CRMColors.textSecondaryOf(context)),
                              const SizedBox(width: 5),
                              Text(item.mobile, style: TextStyle(fontSize: 12, color: CRMColors.textSecondaryOf(context))),
                            ],
                          ),
                      ],
                    ),
                    if (item.remarks.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: CRMColors.borderOf(context)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.notes_rounded, size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                item.remarks,
                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 12),
                actionButtons,
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: actionButtons,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileNotInterestedCard(
    BuildContext context,
    IntegrationLeadModel lead,
    int index,
  ) {
    final name = lead.getStringValue('full_name').isNotEmpty
        ? lead.getStringValue('full_name')
        : (lead.getStringValue('name').isNotEmpty
            ? lead.getStringValue('name')
            : (lead.getStringValue('Client Name').isNotEmpty
                ? lead.getStringValue('Client Name')
                : 'Lead #${index + 1}'));
    final phone = lead.getStringValue('phone_number').isNotEmpty
        ? lead.getStringValue('phone_number')
        : (lead.getStringValue('phone').isNotEmpty
            ? lead.getStringValue('phone')
            : (lead.getStringValue('Phone Number').isNotEmpty
                ? lead.getStringValue('Phone Number')
                : '-'));
    final email = lead.getStringValue('email').isNotEmpty ? lead.getStringValue('email') : '-';
    final role = (RoleGuard.currentUser?.role ?? '').toLowerCase();
    final isRealAdmin = role == 'admin' || role == 'super admin';
    final markedBy = lead.notInterestedByName?.trim().isNotEmpty == true
        ? lead.notInterestedByName!
        : (lead.statusUpdatedByName?.trim().isNotEmpty == true
            ? lead.statusUpdatedByName!
            : (lead.assignedTelecallerName?.trim().isNotEmpty == true ? lead.assignedTelecallerName! : '-'));
    final notInterestedReason = lead.notInterestedReason?.trim().isNotEmpty == true
        ? lead.notInterestedReason!.trim()
        : (lead.getStringValue('not_interested_reason').isNotEmpty
            ? lead.getStringValue('not_interested_reason')
            : (lead.getStringValue('not_interested_notes').isNotEmpty
                ? lead.getStringValue('not_interested_notes')
                : (lead.getStringValue('rejection_reason').isNotEmpty
                    ? lead.getStringValue('rejection_reason')
                    : '')));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: CRMColors.borderOf(context)),
        boxShadow: CRMShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '#${index + 1}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: CRMColors.terracotta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: CRMColors.terracotta.withValues(alpha: 0.4)),
                ),
                child: Text(
                  lead.source.isEmpty ? 'Meta Ads' : lead.source,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: CRMColors.terracotta),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: (lead.leadType == 'Property Listing' ? const Color(0xFF0284C7) : const Color(0xFF10B981)).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: (lead.leadType == 'Property Listing' ? const Color(0xFF0284C7) : const Color(0xFF10B981)).withValues(alpha: 0.4)),
                ),
                child: Text(
                  lead.leadType,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: lead.leadType == 'Property Listing' ? const Color(0xFF0284C7) : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 14),

          // Name with Date underneath
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person_rounded, size: 14, color: CRMColors.textSecondaryOf(context)),
                const SizedBox(width: 6),
                Text('Name: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context))),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('d MMM yyyy, h:mm a').format(lead.receivedAt),
                        style: TextStyle(fontSize: 10.5, color: CRMColors.textSecondaryOf(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Phone + Call & WhatsApp icons
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.phone_rounded, size: 14, color: CRMColors.textSecondaryOf(context)),
                const SizedBox(width: 6),
                Text('Phone: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context))),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(phone, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CRMColors.primaryOf(context))),
                      if (phone != '-' && phone.isNotEmpty) ...[
                        InkWell(
                          onTap: () => _launchTel(phone),
                          child: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF10B981)),
                        ),
                        InkWell(
                          onTap: () => _launchWhatsApp(phone, name),
                          child: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF22C55E)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Email
          if (email != '-') ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.email_rounded, size: 14, color: CRMColors.textSecondaryOf(context)),
                  const SizedBox(width: 6),
                  Text('Email: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context))),
                  Expanded(child: Text(email, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ],

          if (isRealAdmin && markedBy != '-') ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.support_agent_rounded, size: 14, color: Color(0xFF6366F1)),
                  const SizedBox(width: 6),
                  Text('Marked by: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context))),
                  Expanded(
                    child: Text(
                      markedBy,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Notes / Reason (Replaces Date Received)
          if (notInterestedReason.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_alt_outlined, size: 14, color: Color(0xFFEF4444)),
                  const SizedBox(width: 6),
                  Text('Notes: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context))),
                  Expanded(
                    child: Text(
                      notInterestedReason,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB91C1C)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 4),

          // Actions Footer
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: CRMColors.borderOf(context).withValues(alpha: 0.4))),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 70, maxWidth: 100),
                  child: SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.visibility_outlined, size: 13),
                      label: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => _showNotInterestedLeadDetailsDialog(context, lead),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 130, maxWidth: 180),
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.restore_rounded, size: 14),
                      label: const Text('Restore to Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CRMColors.primaryOf(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () async {
                        await _service.updateLeadCampaignStatus(lead.id, 'New');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lead restored to Active Leads.')),
                          );
                        }
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.schedule_rounded, size: 17, color: Color(0xFFF59E0B)),
                  tooltip: 'Schedule Follow-up',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showScheduleFollowupDialog(context, lead),
                ),
                IconButton(
                  icon: const Icon(Icons.star_rounded, size: 17, color: Color(0xFF10B981)),
                  tooltip: 'Mark Interested',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () async {
                    await _service.updateLeadCampaignStatus(lead.id, 'Interested');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lead moved to Interested.')),
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 17, color: CRMColors.danger),
                  tooltip: 'Delete Lead',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDeleteSingleLeadDialog(context, lead),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotInterestedFullWidthTable(
    BuildContext context,
    List<IntegrationLeadModel> displayedLeads, {
    int indexOffset = 0,
  }) {
    final role = (RoleGuard.currentUser?.role ?? '').toLowerCase();
    final isRealAdmin = role == 'admin' || role == 'super admin';

    Widget cell(Widget child, {bool header = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: header ? 12 : 12,
            fontWeight: header ? FontWeight.w700 : FontWeight.w500,
            color: header ? CRMColors.textOf(context) : CRMColors.textOf(context),
          ),
          child: child,
        ),
      );
    }

    TableRow buildHeader() {
      return TableRow(
        decoration: BoxDecoration(color: CRMColors.surfaceElevatedOf(context)),
        children: [
          cell(const Text('#'), header: true),
          cell(const Text('Source'), header: true),
          cell(const Text('Type'), header: true),
          cell(const Text('Name'), header: true),
          cell(const Text('Phone'), header: true),
          cell(const Text('Email'), header: true),
          if (isRealAdmin) cell(const Text('Telecaller'), header: true),
          cell(const Text('Notes'), header: true),
          cell(const Text('Actions'), header: true),
        ],
      );
    }

    TableRow buildRow(IntegrationLeadModel lead, int index) {
      final name = lead.getStringValue('full_name').isNotEmpty
          ? lead.getStringValue('full_name')
          : (lead.getStringValue('name').isNotEmpty ? lead.getStringValue('name') : '-');
      final phone = lead.getStringValue('phone_number').isNotEmpty
          ? lead.getStringValue('phone_number')
          : (lead.getStringValue('phone').isNotEmpty ? lead.getStringValue('phone') : '-');
      final email = lead.getStringValue('email').isNotEmpty ? lead.getStringValue('email') : '-';
      final markedBy = lead.notInterestedByName?.trim().isNotEmpty == true
          ? lead.notInterestedByName!
          : (lead.statusUpdatedByName?.trim().isNotEmpty == true
              ? lead.statusUpdatedByName!
              : (lead.assignedTelecallerName?.trim().isNotEmpty == true ? lead.assignedTelecallerName! : '-'));
      final notInterestedNote = lead.notInterestedReason?.trim().isNotEmpty == true
          ? lead.notInterestedReason!.trim()
          : (lead.getStringValue('not_interested_reason').isNotEmpty
              ? lead.getStringValue('not_interested_reason')
              : (lead.getStringValue('not_interested_notes').isNotEmpty
                  ? lead.getStringValue('not_interested_notes')
                  : (lead.getStringValue('rejection_reason').isNotEmpty
                      ? lead.getStringValue('rejection_reason')
                      : '-')));

      return TableRow(
        children: [
          cell(Text('${indexOffset + index + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
          cell(
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: CRMColors.terracotta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(lead.source, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          cell(Text(lead.leadType)),
          cell(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Text(
                  DateFormat('d MMM yyyy, h:mm a').format(lead.receivedAt),
                  style: TextStyle(
                    fontSize: 10.5,
                    color: CRMColors.textSecondaryOf(context),
                  ),
                ),
              ],
            ),
          ),
          cell(Text(phone)),
          cell(Text(email)),
          if (isRealAdmin)
            cell(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.support_agent_rounded, size: 14, color: Color(0xFF6366F1)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      markedBy,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6366F1),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          cell(
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.visibility_outlined, size: 13),
                label: const Text('View', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  minimumSize: const Size(64, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(color: CRMColors.borderOf(context)),
                ),
                onPressed: () => _showNotInterestedLeadDetailsDialog(context, lead),
              ),
            ),
          ),
          cell(
            Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<String>(
                tooltip: 'Actions',
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded, size: 18, color: CRMColors.textOf(context)),
                onSelected: (value) async {
                  if (value == 'view') {
                    _showNotInterestedLeadDetailsDialog(context, lead);
                  } else if (value == 'restore') {
                    await _service.updateLeadCampaignStatus(lead.id, 'New');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lead restored to Active Leads.')),
                      );
                    }
                  } else if (value == 'followup') {
                    _showScheduleFollowupDialog(context, lead);
                  } else if (value == 'interested') {
                    await _service.updateLeadCampaignStatus(lead.id, 'Interested');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lead moved to Interested.')),
                      );
                    }
                  } else if (value == 'delete') {
                    _confirmDeleteSingleLeadDialog(context, lead);
                  }
                },
                itemBuilder: (menuContext) => [
                  const PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF6366F1)),
                        SizedBox(width: 10),
                        Text('View Details'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'restore',
                    child: Row(
                      children: [
                        Icon(Icons.restore_rounded, size: 18, color: Color(0xFF10B981)),
                        SizedBox(width: 10),
                        Text('Restore to Active'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'followup',
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 18, color: Color(0xFFF59E0B)),
                        SizedBox(width: 10),
                        Text('Schedule Follow-up'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'interested',
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, size: 18, color: Color(0xFF10B981)),
                        SizedBox(width: 10),
                        Text('Mark Interested'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: CRMColors.danger),
                        const SizedBox(width: 10),
                        const Text('Delete Lead'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: CRMColors.borderOf(context)),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        columnWidths: isRealAdmin
            ? const {
                0: FlexColumnWidth(0.4),
                1: FlexColumnWidth(0.85),
                2: FlexColumnWidth(0.95),
                3: FlexColumnWidth(1.45),
                4: FlexColumnWidth(1.15),
                5: FlexColumnWidth(1.35),
                6: FlexColumnWidth(1.15),
                7: FlexColumnWidth(0.9),
                8: FlexColumnWidth(0.6),
              }
            : const {
                0: FlexColumnWidth(0.45),
                1: FlexColumnWidth(0.9),
                2: FlexColumnWidth(1.0),
                3: FlexColumnWidth(1.6),
                4: FlexColumnWidth(1.2),
                5: FlexColumnWidth(1.4),
                6: FlexColumnWidth(0.9),
                7: FlexColumnWidth(0.6),
              },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: TableBorder(
          horizontalInside: BorderSide(color: CRMColors.borderOf(context)),
        ),
        children: [
          buildHeader(),
          ...displayedLeads.asMap().entries.map((entry) => buildRow(entry.value, entry.key)),
        ],
      ),
    );
  }

  Widget _buildNotInterestedView(BuildContext context) {
    final notInterestedLeads = _scopedLeads
        .where((l) => isNotInterestedStatus(l.campaignStatus))
        .toList();

    final propListingCount = notInterestedLeads.where((l) => l.leadType == 'Property Listing').length;
    final reqCount = notInterestedLeads.where((l) => l.leadType == 'Requirement').length;
    final totalCount = notInterestedLeads.length;
    final todayCount = notInterestedLeads
        .where((l) => CampaignLeadsState.matchesDateFilter(l.receivedAt, CampaignDateFilter.today))
        .length;

    List<IntegrationLeadModel> filteredBySub = notInterestedLeads;
    if (_notInterestedSubFilter == 'today') {
      filteredBySub = notInterestedLeads.where((l) => CampaignLeadsState.matchesDateFilter(l.receivedAt, CampaignDateFilter.today)).toList();
    } else if (_notInterestedSubFilter == 'property_listing') {
      filteredBySub = notInterestedLeads.where((l) => l.leadType == 'Property Listing').toList();
    } else if (_notInterestedSubFilter == 'requirement') {
      filteredBySub = notInterestedLeads.where((l) => l.leadType == 'Requirement').toList();
    }

    final query = _notInterestedSearchQuery.trim().toLowerCase();
    final displayedLeads = query.isEmpty
        ? filteredBySub
        : filteredBySub.where((l) => _matchesNotInterestedSearch(l, query)).toList();

    final niTotal = displayedLeads.length;
    final niTotalPages = niTotal == 0 ? 1 : (niTotal / _notInterestedPageSize).ceil();
    final niCurrentPage = _notInterestedPage.clamp(1, niTotalPages);
    final niStartIndex = (niCurrentPage - 1) * _notInterestedPageSize;
    final niEndIndex = (niStartIndex + _notInterestedPageSize).clamp(0, niTotal);
    final pageLeads = niTotal == 0
        ? const <IntegrationLeadModel>[]
        : displayedLeads.sublist(niStartIndex, niEndIndex);

    final isMobile = MediaQuery.of(context).size.width < 700;
    Widget wrapMetric(Widget item, String filterKey) {
      final isSelected = _notInterestedSubFilter == filterKey;
      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() {
              _notInterestedSubFilter = isSelected ? 'all' : filterKey;
              _notInterestedPage = 1;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: isSelected ? Border.all(color: CRMColors.primaryOf(context), width: 2) : null,
            ),
            child: item,
          ),
        ),
      );
    }

    final metricItems = [
      wrapMetric(_buildMetricItem(context, 'Total Not Interested', totalCount.toString(), Icons.do_not_disturb_on_rounded, const Color(0xFFEF4444)), 'all'),
      wrapMetric(_buildMetricItem(context, 'Not Interested Today', todayCount.toString(), Icons.today_rounded, const Color(0xFFF97316)), 'today'),
      wrapMetric(_buildMetricItem(context, 'Property Listings', propListingCount.toString(), Icons.home_work_rounded, const Color(0xFF0284C7)), 'property_listing'),
      wrapMetric(_buildMetricItem(context, 'Requirements', reqCount.toString(), Icons.people_alt_rounded, const Color(0xFF10B981)), 'requirement'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMobile) ...[
          Row(children: [metricItems[0], const SizedBox(width: CRMSpacing.s), metricItems[1]]),
          const SizedBox(height: CRMSpacing.s),
          Row(children: [metricItems[2], const SizedBox(width: CRMSpacing.s), metricItems[3]]),
        ] else ...[
          Row(
            children: [
              metricItems[0],
              const SizedBox(width: CRMSpacing.s),
              metricItems[1],
              const SizedBox(width: CRMSpacing.s),
              metricItems[2],
              const SizedBox(width: CRMSpacing.s),
              metricItems[3],
            ],
          ),
        ],

        const SizedBox(height: CRMSpacing.m),

        CRMCard(
          elevated: true,
          title: 'Not Interested Leads',
          subtitle: 'Archived leads kept separate to keep active leads clean. You can restore them anytime.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 40,
                            child: TextField(
                              controller: _notInterestedSearchController,
                              onChanged: (value) {
                                _notInterestedSearchDebounce?.cancel();
                                _notInterestedSearchDebounce = Timer(const Duration(milliseconds: 250), () {
                                  if (!mounted) return;
                              setState(() {
                                _notInterestedSearchQuery = value.trim().toLowerCase();
                                _notInterestedPage = 1;
                              });
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search by client name, phone, email, source...',
                                hintStyle: CRMTypography.caption.copyWith(
                                  color: CRMColors.textSecondaryOf(context),
                                ),
                                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                suffixIcon: _notInterestedSearchController.text.isNotEmpty
                                    ? IconButton(
                                        tooltip: 'Clear',
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        onPressed: () {
                                          _notInterestedSearchDebounce?.cancel();
                                          _notInterestedSearchController.clear();
                                      setState(() {
                                        _notInterestedSearchQuery = '';
                                        _notInterestedPage = 1;
                                      });
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: CRMColors.borderOf(context)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: CRMColors.borderOf(context)),
                                ),
                                filled: true,
                                fillColor: CRMColors.cardBgOf(context),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: CRMButton(
                              label: 'Search',
                              onPressed: () {
                                _notInterestedSearchDebounce?.cancel();
                                setState(() {
                                  _notInterestedSearchQuery =
                                      _notInterestedSearchController.text.trim().toLowerCase();
                                  _notInterestedPage = 1;
                                });
                              },
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: TextField(
                                controller: _notInterestedSearchController,
                                onChanged: (value) {
                                  _notInterestedSearchDebounce?.cancel();
                                  _notInterestedSearchDebounce = Timer(const Duration(milliseconds: 250), () {
                                    if (!mounted) return;
                              setState(() {
                                _notInterestedSearchQuery = value.trim().toLowerCase();
                                _notInterestedPage = 1;
                              });
                                  });
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search by client name, phone, email, source...',
                                  hintStyle: CRMTypography.caption.copyWith(
                                    color: CRMColors.textSecondaryOf(context),
                                  ),
                                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                                  suffixIcon: _notInterestedSearchController.text.isNotEmpty
                                      ? IconButton(
                                          tooltip: 'Clear',
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          onPressed: () {
                                            _notInterestedSearchDebounce?.cancel();
                                            _notInterestedSearchController.clear();
                                      setState(() {
                                        _notInterestedSearchQuery = '';
                                        _notInterestedPage = 1;
                                      });
                                          },
                                        )
                                      : null,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: CRMColors.borderOf(context)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: CRMColors.borderOf(context)),
                                  ),
                                  filled: true,
                                  fillColor: CRMColors.cardBgOf(context),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: CRMSpacing.s),
                          CRMButton(
                            label: 'Search',
                            onPressed: () {
                              _notInterestedSearchDebounce?.cancel();
                              setState(() {
                                _notInterestedSearchQuery =
                                    _notInterestedSearchController.text.trim().toLowerCase();
                                _notInterestedPage = 1;
                              });
                            },
                          ),
                        ],
                      ),
              ),
              displayedLeads.isEmpty
              ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 44, color: Color(0xFF10B981)),
                      const SizedBox(height: 12),
                      Text(
                        query.isEmpty ? 'No Not-Interested Leads' : 'No matching Not Interested leads',
                        style: CRMTypography.headline.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        query.isEmpty
                            ? 'Any lead marked as "Not interested" will be kept here safely.'
                            : 'Try a different name, phone number, or other lead detail.',
                          style: TextStyle(color: CRMColors.textSecondaryOf(context), fontSize: 13)),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    isMobile
                        ? Column(
                            children: pageLeads.asMap().entries.map((entry) {
                              return _buildMobileNotInterestedCard(
                                context,
                                entry.value,
                                niStartIndex + entry.key,
                              );
                            }).toList(),
                          )
                        : _buildNotInterestedFullWidthTable(
                            context,
                            pageLeads,
                            indexOffset: niStartIndex,
                          ),
                    const SizedBox(height: CRMSpacing.s),
                    _buildCampaignPager(
                      context,
                      niTotal,
                      niStartIndex,
                      niCurrentPage,
                      niTotalPages,
                      pageSize: _notInterestedPageSize,
                      onPageChanged: (page) => setState(() => _notInterestedPage = page),
                      onPageSizeChanged: (size) => setState(() {
                        _notInterestedPageSize = size;
                        _notInterestedPage = 1;
                      }),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  bool _matchesNotInterestedSearch(IntegrationLeadModel lead, String query) {
    if (query.isEmpty) return true;
    final name = lead.getStringValue('full_name').isNotEmpty
        ? lead.getStringValue('full_name')
        : lead.getStringValue('name');
    final phone = lead.getStringValue('phone_number').isNotEmpty
        ? lead.getStringValue('phone_number')
        : lead.getStringValue('phone');
    final email = lead.getStringValue('email');
    if (name.toLowerCase().contains(query)) return true;
    if (phone.toLowerCase().contains(query)) return true;
    if (email.toLowerCase().contains(query)) return true;
    if (lead.source.toLowerCase().contains(query)) return true;
    if (lead.leadType.toLowerCase().contains(query)) return true;
    if (lead.notInterestedReason != null && lead.notInterestedReason!.toLowerCase().contains(query)) return true;
    for (final val in lead.rawJson.values) {
      if (val != null && val.toString().toLowerCase().contains(query)) return true;
    }
    return false;
  }

  Future<void> _launchTel(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWhatsApp(String phone, String clientName) async {
    var clean = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 10) clean = '91$clean';
    final uri = Uri.parse('https://wa.me/$clean?text=Hello%20${Uri.encodeComponent(clientName)},%20following%20up%20regarding%20your%20property%20inquiry.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildArchiveNoticeBanner(BuildContext context) {
    final isListed = _selectedSection == 'Property Listing';
    final themeColor = isListed ? const Color(0xFF10B981) : const Color(0xFF6366F1);
    final count = isListed ? _cachedListedCount : _cachedArchivedReqCount;
    final title = isListed
        ? 'Archive: Listed Properties ($count)'
        : 'Archive: Requirements ($count)';
    final desc = isListed
        ? 'Showing closed and listed property leads saved in the archive. You can search, filter, export, or change status to restore them to active leads.'
        : 'Showing archived requirement leads saved in the archive. You can search, filter, export, or change status to restore them to active leads.';

    return Container(
      margin: const EdgeInsets.only(bottom: CRMSpacing.m),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isListed ? Icons.inventory_2_rounded : Icons.archive_rounded,
              size: 18,
              color: themeColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: themeColor),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CRMButton(
            label: 'Exit Archive',
            prefixIcon: Icons.arrow_back_rounded,
            height: 32,
            variant: CRMButtonVariant.secondary,
            onPressed: () {
              setState(() {
                _viewMode = 'active';
                _cachedFilteredLeads = null;
                _currentPage = 1;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeadTypeSegmentedControl(BuildContext context, int propCount, int reqCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 700;

    final propTab = _buildSectionTabItem(
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
            _persistedSection = 'Property Listing';
            if (_viewMode == 'archive_requirements') {
              _viewMode = 'archive_listed';
            }
            _selectedLeadIds.clear();
            _currentPage = 1;
            _cachedFilteredLeads = null;
          });
        }
      },
    );

    final reqTab = _buildSectionTabItem(
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
            _persistedSection = 'Requirement';
            if (_viewMode == 'archive_listed' || _viewMode == 'listed') {
              _viewMode = 'archive_requirements';
            }
            _selectedLeadIds.clear();
            _currentPage = 1;
            _cachedFilteredLeads = null;
          });
        }
      },
    );

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2430) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: isMobile
          ? Column(
              children: [
                propTab,
                const SizedBox(height: 6),
                reqTab,
              ],
            )
          : Row(
              children: [
                Expanded(child: propTab),
                const SizedBox(width: 8),
                Expanded(child: reqTab),
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
    final isMobile = MediaQuery.of(context).size.width < 800;

    final items = [
      _buildMetricItem(context, 'Total Leads', total.toString(), Icons.inbox_rounded, CRMColors.primaryOf(context)),
      _buildMetricItem(context, 'Interested', _cachedInterestedCount.toString(), Icons.star_rounded, const Color(0xFF10B981)),
      _buildMetricItem(context, 'Follow-ups', _cachedFollowupCount.toString(), Icons.schedule_rounded, const Color(0xFFF59E0B)),
      _buildMetricItem(context, 'Unique Leads', unique.toString(), Icons.verified_user_rounded, CRMColors.success),
      _buildMetricItem(context, 'Duplicates', dups.toString(), Icons.copy_rounded, CRMColors.warning),
      _buildMetricItem(context, destinationLabel, imported.toString(), destinationIcon, CRMColors.info),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(children: [Expanded(child: items[0]), const SizedBox(width: CRMSpacing.s), Expanded(child: items[1])]),
          const SizedBox(height: CRMSpacing.s),
          Row(children: [Expanded(child: items[2]), const SizedBox(width: CRMSpacing.s), Expanded(child: items[3])]),
          const SizedBox(height: CRMSpacing.s),
          Row(children: [Expanded(child: items[4]), const SizedBox(width: CRMSpacing.s), Expanded(child: items[5])]),
        ],
      );
    }
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: CRMSpacing.s),
          Expanded(child: items[i]),
        ],
      ],
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, IconData icon, Color color) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : CRMSpacing.m,
        vertical: isMobile ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.card),
        border: Border.all(color: CRMColors.borderOf(context)),
        boxShadow: CRMShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 5 : 7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: isMobile ? 15 : 18),
          ),
          SizedBox(width: isMobile ? 6 : CRMSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: CRMTypography.headline.copyWith(
                    color: CRMColors.textOf(context),
                    fontSize: isMobile ? 15 : 17,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: CRMTypography.caption.copyWith(
                    color: CRMColors.textSecondaryOf(context),
                    fontSize: isMobile ? 10 : 11,
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
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
                ],
              ),
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
                          _persistedDateFilter = filter;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMetaBlocked = _service.metaStatus == 'BLOCKED' ||
        _service.activeHealthAlerts.any((a) => a['code'] == 'META_ACCESS_BLOCKED');

    if (totalLeads == 0) {
      return Container(
        margin: const EdgeInsets.only(top: CRMSpacing.s),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMetaBlocked
              ? (isDark ? const Color(0xFF3B1D1D) : const Color(0xFFFEF2F2))
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isMetaBlocked
                ? const Color(0xFFEF4444).withValues(alpha: 0.5)
                : const Color(0xFF0284C7).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isMetaBlocked ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                  color: isMetaBlocked ? const Color(0xFFDC2626) : const Color(0xFF0284C7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isMetaBlocked
                        ? "0 leads received today • Meta Graph API Token is blocked (OAuthException Code 200)"
                        : "0 leads received today so far.",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isMetaBlocked
                          ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C))
                          : (isDark ? const Color(0xFF93C5FD) : const Color(0xFF0369A1)),
                    ),
                  ),
                ),
                if (isMetaBlocked)
                  InkWell(
                    onTap: () => _showMetaDiagnosticDialog(context),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.build_circle_outlined, size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 4),
                          Text('Diagnose', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isMetaBlocked
                  ? "Meta has restricted App ID 1632855004850842. Google Sheets & direct webhooks are operational. You have ${_cachedCountYesterday} leads from Yesterday and $allTimeCount Total leads."
                  : "New leads will appear here automatically. You have ${_cachedCountYesterday} leads from Yesterday and $allTimeCount Total leads.",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (_cachedCountYesterday > 0)
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDateFilter = CampaignDateFilter.yesterday;
                        _persistedDateFilter = CampaignDateFilter.yesterday;
                        _cachedFilteredLeads = null;
                        _currentPage = 1;
                      });
                      context.read<CampaignLeadsBloc>().add(
                        const SetCampaignDateFilterEvent(filter: CampaignDateFilter.yesterday),
                      );
                    },
                    icon: const Icon(Icons.history_rounded, size: 14),
                    label: Text('View Yesterday (${_cachedCountYesterday})'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (allTimeCount > 0)
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDateFilter = CampaignDateFilter.allTime;
                        _persistedDateFilter = CampaignDateFilter.allTime;
                        _cachedFilteredLeads = null;
                        _currentPage = 1;
                      });
                      context.read<CampaignLeadsBloc>().add(
                        const SetCampaignDateFilterEvent(filter: CampaignDateFilter.allTime),
                      );
                    },
                    icon: const Icon(Icons.table_rows_rounded, size: 14),
                    label: Text('View All Time ($allTimeCount)'),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

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
                _persistedDateFilter = CampaignDateFilter.allTime;
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


  Future<void> _archiveLead(IntegrationLeadModel lead) async {
    final currentStatus = lead.campaignStatus.trim().isEmpty ? 'New' : lead.campaignStatus;
    lead.rawJson['pre_archive_status'] = currentStatus;

    final isProp = lead.leadType == 'Property Listing' || _selectedSection == 'Property Listing';
    final archiveStatus = isProp ? 'Property Listed' : 'Archived';
    await _service.updateLeadCampaignStatus(lead.id, archiveStatus);
    unawaited(_service.fetchServerLeads(resetWithServer: true));

    if (mounted) {
      setState(() {
        _cachedFilteredLeads = null;
        _selectedLeadIds.remove(lead.id);
      });
      unawaited(_loadFollowups());
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isProp
              ? 'Property listing archived.'
              : 'Requirement lead archived.'),
          backgroundColor: isProp ? const Color(0xFF10B981) : const Color(0xFF6366F1),
          action: SnackBarAction(
            label: 'View Archive',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _viewMode = isProp ? 'archive_listed' : 'archive_requirements';
                _selectedSection = isProp ? 'Property Listing' : 'Requirement';
                _persistedSection = _selectedSection;
                _cachedFilteredLeads = null;
                _currentPage = 1;
              });
            },
          ),
        ),
      );
    }
  }

  Future<void> _unarchiveLead(IntegrationLeadModel lead) async {
    String restoredStatus = (lead.rawJson['pre_archive_status'] ?? '').toString().trim();
    if (restoredStatus.isEmpty || restoredStatus == 'Archived' || restoredStatus == 'Property Listed' || restoredStatus == 'Listed') {
      restoredStatus = 'New';
    }

    final isProp = lead.leadType == 'Property Listing';
    await _service.updateLeadCampaignStatus(lead.id, restoredStatus);
    unawaited(_service.fetchServerLeads(resetWithServer: true));

    if (mounted) {
      setState(() {
        _cachedFilteredLeads = null;
        _selectedLeadIds.remove(lead.id);
      });
      unawaited(_loadFollowups());
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isProp
              ? 'Property listing restored to active Property Listing Leads tab.'
              : 'Requirement lead restored to active Requirement Leads tab.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _bulkArchiveSelectedLeads(BuildContext context) async {
    final selectedIds = _selectedLeadIds.toList();
    if (selectedIds.isEmpty) return;
    final count = selectedIds.length;
    final isProp = _selectedSection == 'Property Listing';
    final archiveStatus = isProp ? 'Property Listed' : 'Archived';

    await _service.bulkUpdateCampaignStatus(selectedIds, archiveStatus);
    unawaited(_service.fetchServerLeads(resetWithServer: true));

    if (mounted) {
      setState(() {
        _selectedLeadIds.clear();
        _cachedFilteredLeads = null;
      });
      unawaited(_loadFollowups());
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count lead(s) archived.'),
          backgroundColor: isProp ? const Color(0xFF10B981) : const Color(0xFF6366F1),
          action: SnackBarAction(
            label: 'View Archive',
            textColor: Colors.white,
            onPressed: () {
              setState(() {
                _viewMode = isProp ? 'archive_listed' : 'archive_requirements';
                _cachedFilteredLeads = null;
                _currentPage = 1;
              });
            },
          ),
        ),
      );
    }
  }

  Future<void> _bulkUnarchiveSelectedLeads(BuildContext context) async {
    final selectedIds = _selectedLeadIds.toList();
    if (selectedIds.isEmpty) return;
    final count = selectedIds.length;

    await _service.bulkUpdateCampaignStatus(selectedIds, 'New');
    unawaited(_service.fetchServerLeads(resetWithServer: true));

    if (mounted) {
      setState(() {
        _selectedLeadIds.clear();
        _cachedFilteredLeads = null;
      });
      unawaited(_loadFollowups());
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count lead(s) restored to active $_selectedSection Leads tab.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _handleBulkStatusAction(BuildContext context, String action) async {
    final selectedIds = _selectedLeadIds.toList();
    if (selectedIds.isEmpty) return;
    final count = selectedIds.length;

    if (action == 'Archive') {
      await _bulkArchiveSelectedLeads(context);
      return;
    } else if (action == 'Unarchive') {
      await _bulkUnarchiveSelectedLeads(context);
      return;
    }

    if (action == 'Property Listed') {
      await _service.bulkUpdateCampaignStatus(selectedIds, 'Property Listed');
      unawaited(_service.fetchServerLeads(resetWithServer: true));
      if (mounted) {
        setState(() {
          _selectedLeadIds.clear();
          _cachedFilteredLeads = null;
        });
        unawaited(_loadFollowups());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count property listing(s) marked as Listed and saved in Archive.'),
            backgroundColor: const Color(0xFF10B981),
            action: SnackBarAction(
              label: 'View Archive',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _viewMode = 'archive_listed';
                  _selectedSection = 'Property Listing';
                  _cachedFilteredLeads = null;
                  _currentPage = 1;
                });
              },
            ),
          ),
        );
      }
    } else if (action == 'Archive Requirement') {
      await _service.bulkUpdateCampaignStatus(selectedIds, 'Archived');
      unawaited(_service.fetchServerLeads(resetWithServer: true));
      if (mounted) {
        setState(() {
          _selectedLeadIds.clear();
          _cachedFilteredLeads = null;
        });
        unawaited(_loadFollowups());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count requirement lead(s) archived and saved in Archive.'),
            backgroundColor: const Color(0xFF6366F1),
            action: SnackBarAction(
              label: 'View Archive',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _viewMode = 'archive_requirements';
                  _selectedSection = 'Requirement';
                  _cachedFilteredLeads = null;
                  _currentPage = 1;
                });
              },
            ),
          ),
        );
      }
    } else if (action == 'Wrong Lead Requirement') {
      final targetType = 'Requirement';
      final isArchive = _viewMode == 'archive_listed' || _viewMode == 'listed' || _viewMode == 'archive_requirements';
      _service.bulkReclassifyLeadsOptimistic(selectedIds, targetType);
      _cachedFilteredLeads = null;
      _currentPage = 1;
      _selectedLeadIds.clear();
      if (_viewMode == 'archive_listed' || _viewMode == 'listed') {
        _viewMode = 'archive_requirements';
        _selectedSection = 'Requirement';
        _persistedSection = 'Requirement';
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArchive
                ? '$count lead(s) moved to Requirement Archive table.'
                : '$count lead(s) moved to Requirement table.'),
            backgroundColor: const Color(0xFF8B5CF6),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _selectedSection = 'Requirement';
                  _persistedSection = 'Requirement';
                  if (isArchive) {
                    _viewMode = 'archive_requirements';
                  }
                  _cachedFilteredLeads = null;
                  _currentPage = 1;
                });
              },
            ),
          ),
        );
      }
      unawaited(Future.wait(selectedIds.map((id) => _service.reclassifyLead(id, targetType))).then((results) {
        final failedCount = results.where((ok) => !ok).length;
        if (failedCount > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update $failedCount lead(s) classification on server. Please try again.'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }));
    } else if (action == 'Wrong Lead Property Listing') {
      final targetType = 'Property Listing';
      final isArchive = _viewMode == 'archive_requirements' || _viewMode == 'archive_listed' || _viewMode == 'listed';
      _service.bulkReclassifyLeadsOptimistic(selectedIds, targetType);
      _cachedFilteredLeads = null;
      _currentPage = 1;
      _selectedLeadIds.clear();
      if (_viewMode == 'archive_requirements') {
        _viewMode = 'archive_listed';
        _selectedSection = 'Property Listing';
        _persistedSection = 'Property Listing';
      }
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArchive
                ? '$count lead(s) moved to Property Listing Archive table.'
                : '$count lead(s) moved to Property Listing table.'),
            backgroundColor: const Color(0xFF0284C7),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _selectedSection = 'Property Listing';
                  _persistedSection = 'Property Listing';
                  if (isArchive) {
                    _viewMode = 'archive_listed';
                  }
                  _cachedFilteredLeads = null;
                  _currentPage = 1;
                });
              },
            ),
          ),
        );
      }
      unawaited(Future.wait(selectedIds.map((id) => _service.reclassifyLead(id, targetType))).then((results) {
        final failedCount = results.where((ok) => !ok).length;
        if (failedCount > 0 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update $failedCount lead(s) classification on server. Please try again.'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }));
    } else if (action == 'Not interested') {
      _showBulkNotInterestedReasonDialog(context, selectedIds);
      return;
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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

            if (!RoleGuard.isTelecaller(RoleGuard.currentUser?.role)) ...[

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
            ],



            if (_viewMode == 'archive_listed' || _viewMode == 'archive_requirements' || _viewMode == 'listed') ...[
              SizedBox(
                height: 36,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.unarchive_rounded, size: 16),
                  label: Text('Unarchive Selected ($count)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _bulkUnarchiveSelectedLeads(context),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
            ] else ...[
              SizedBox(
                height: 36,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.archive_outlined, size: 16),
                  label: Text('Archive Selected ($count)'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.input)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _bulkArchiveSelectedLeads(context),
                ),
              ),
              const SizedBox(width: CRMSpacing.s),
            ],

            // Bulk Status Action Menu (Shown for calling leads / replacing "Move to Properties" on calling leads)
            PopupMenuButton<String>(
              tooltip: 'Status Actions ($count)',
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 340),
              onSelected: (action) => _handleBulkStatusAction(context, action),
              itemBuilder: (ctx) => [
                if (_selectedSection == 'Property Listing') ...[
                  PopupMenuItem(
                    value: 'Wrong Lead Requirement',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFF8B5CF6)),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Wrong Lead (move to requirement table)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF8B5CF6)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Customer wants a property', style: TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  PopupMenuItem(
                    value: 'Wrong Lead Property Listing',
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.home_work_rounded, size: 16, color: Color(0xFF0284C7)),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Wrong Lead (move to property listing table)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0284C7)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('Customer wants to list property', style: TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                PopupMenuItem(
                  value: 'Not interested',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.thumb_down_alt_rounded, size: 16, color: Color(0xFFEF4444)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Not interested', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFEF4444)), maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('Move to Not Interested tab', style: TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(CRMBorderRadius.input),
                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.assignment_turned_in_rounded, size: 16, color: Color(0xFF0284C7)),
                    const SizedBox(width: 6),
                    Text(
                      'Status ($count)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down_rounded, size: 18, color: Color(0xFF0284C7)),
                  ],
                ),
              ),
            ),


            const SizedBox(width: CRMSpacing.m),

            // Clear Selection Button
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Clear Selection',
              onPressed: () => setState(() => _selectedLeadIds.clear()),
            ),
          ],
        ),
      ),
    );
  }

  // --- MOBILE CARD VIEW FOR SPREADSHEET LEADS ---
  Widget _buildMobileCardListHeader(BuildContext context, List<IntegrationLeadModel> pageLeads) {
    final allSelected = pageLeads.isNotEmpty && pageLeads.every((l) => _selectedLeadIds.contains(l.id));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CRMColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            visualDensity: VisualDensity.compact,
            onChanged: (val) {
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
          ),
          const SizedBox(width: 4),
          Text(
            allSelected ? 'Deselect All Page Leads' : 'Select All Page Leads (${pageLeads.length})',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          if (_selectedLeadIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: CRMColors.primaryOf(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_selectedLeadIds.length} Selected',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: CRMColors.primaryOf(context)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceBadge(String rawSource) {
    final s = rawSource.isEmpty ? 'Meta Ads' : rawSource;
    final upper = s.toUpperCase();
    final Color badgeColor;
    if (upper.contains('HOUSING')) {
      badgeColor = const Color(0xFF6C5CE7);
    } else if (upper.contains('META')) {
      badgeColor = CRMColors.terracotta;
    } else if (upper.contains('SHEET')) {
      badgeColor = CRMColors.sage;
    } else {
      badgeColor = const Color(0xFF0984E3);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        s,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildMobileLeadCard(
    BuildContext context,
    IntegrationLeadModel lead,
    int index,
    int startIndex,
    List<String> visibleHeaders,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedLeadIds.contains(lead.id);

    Color cardBg = CRMColors.cardBgOf(context);
    Color borderColor = CRMColors.borderOf(context);
    if (lead.campaignStatus == 'Interested') {
      cardBg = const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.08);
      borderColor = const Color(0xFF10B981).withValues(alpha: 0.4);
    } else if (lead.campaignStatus == 'Follow up' || lead.campaignStatus == 'Follow-up') {
      cardBg = const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.18 : 0.06);
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.35);
    } else if (lead.isDuplicate) {
      cardBg = CRMColors.warning.withValues(alpha: isDark ? 0.20 : 0.08);
      borderColor = CRMColors.warning.withValues(alpha: 0.4);
    } else if (lead.importStatus == 'Imported') {
      cardBg = CRMColors.success.withValues(alpha: isDark ? 0.15 : 0.05);
    }

    if (isSelected) {
      borderColor = CRMColors.primaryOf(context);
    }

    final phone = lead.getStringValue('phone_number').isNotEmpty
        ? lead.getStringValue('phone_number')
        : (lead.getStringValue('phone').isNotEmpty
            ? lead.getStringValue('phone')
            : lead.getStringValue('Phone Number'));

    final name = lead.getStringValue('full_name').isNotEmpty
        ? lead.getStringValue('full_name')
        : (lead.getStringValue('name').isNotEmpty
            ? lead.getStringValue('name')
            : (lead.getStringValue('Client Name').isNotEmpty
                ? lead.getStringValue('Client Name')
                : (lead.getStringValue('Client / Owner Name').isNotEmpty
                    ? lead.getStringValue('Client / Owner Name')
                    : 'Lead #${startIndex + index + 1}')));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
        boxShadow: CRMShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Checkbox, Row Index, Source Badge, Status Dropdown Cell
          Row(
            children: [
              Checkbox(
                value: isSelected,
                visualDensity: VisualDensity.compact,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _selectedLeadIds.add(lead.id);
                    } else {
                      _selectedLeadIds.remove(lead.id);
                    }
                  });
                },
              ),
              Text(
                '#${startIndex + index + 1}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 6),
              // Source Badge
              _buildSourceBadge(lead.source),
              if (lead.enquiryCount > 1) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: CRMColors.primaryOf(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${lead.enquiryCount}x',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: CRMColors.primaryOf(context)),
                  ),
                ),
              ],
              const SizedBox(width: 6),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: _buildStatusDropdownCell(context, lead),
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 14),

          // Render all visible header fields dynamically so ALL fields from Image 3 are present
          ...visibleHeaders.map((header) {
            if (header == 'Received On') {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: CRMColors.textSecondaryOf(context)),
                    const SizedBox(width: 6),
                    Text(
                      'Received On: ',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)),
                    ),
                    Expanded(
                      child: Text(
                        '${lead.formattedReceivedAt} (${lead.relativeTimeAgo})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }

            final val = lead.getStringValue(header);
            final displayVal = _formatDisplayCellValue(header, val);

            if (displayVal.isEmpty) return const SizedBox.shrink();

            IconData fieldIcon = Icons.info_outline_rounded;
            final lowerHeader = header.toLowerCase();
            if (lowerHeader.contains('name') || lowerHeader.contains('client') || lowerHeader.contains('owner')) {
              fieldIcon = Icons.person_rounded;
            } else if (lowerHeader.contains('phone') || lowerHeader.contains('mobile') || lowerHeader.contains('contact')) {
              fieldIcon = Icons.phone_rounded;
            } else if (lowerHeader.contains('rent') || lowerHeader.contains('budget') || lowerHeader.contains('price')) {
              fieldIcon = Icons.payments_rounded;
            } else if (lowerHeader.contains('type') || lowerHeader.contains('config') || lowerHeader.contains('bhk')) {
              fieldIcon = Icons.home_work_rounded;
            } else if (lowerHeader.contains('location') || lowerHeader.contains('city') || lowerHeader.contains('area')) {
              fieldIcon = Icons.location_on_rounded;
            }

            final isPhoneField = lowerHeader.contains('phone') || lowerHeader.contains('mobile') || lowerHeader.contains('contact');

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(fieldIcon, size: 14, color: CRMColors.textSecondaryOf(context)),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 4,
                    child: Text(
                      '$header:',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: CRMColors.textSecondaryOf(context)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 6,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          displayVal,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isPhoneField ? CRMColors.primaryOf(context) : CRMColors.textOf(context),
                          ),
                        ),
                        if (isPhoneField && displayVal.isNotEmpty) ...[
                          InkWell(
                            onTap: () => _launchTel(displayVal),
                            child: const Icon(Icons.phone_rounded, size: 16, color: Color(0xFF10B981)),
                          ),
                          InkWell(
                            onTap: () => _launchWhatsApp(displayVal, name),
                            child: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF22C55E)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 4),

          // Actions Footer
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: CRMColors.borderOf(context).withValues(alpha: 0.4))),
            ),
            child: Row(
              children: [
                if (RoleGuard.isTelecaller(RoleGuard.currentUser?.role) ||
                    RoleGuard.currentUser?.role == 'Admin' ||
                    RoleGuard.currentUser?.role == 'Super Admin') ...[
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.swap_horiz_rounded, size: 14),
                        label: const Text(
                          'Transfer',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0284C7),
                          side: const BorderSide(color: Color(0xFF0284C7)),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () => _showPartnerTelecallerDialog(context, lead),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ElevatedButton.icon(
                      icon: Icon(
                        _selectedSection == 'Property Listing' ? Icons.home_work_rounded : Icons.contacts_rounded,
                        size: 14,
                      ),
                      label: Text(
                        _selectedSection == 'Property Listing' ? 'Move to Properties' : 'Move to Leads',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CRMColors.primaryOf(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedLeadIds.clear();
                          _selectedLeadIds.add(lead.id);
                        });
                        if (_selectedSection == 'Property Listing') {
                          _moveSelectedToPropertiesPage(context);
                        } else {
                          _moveSelectedToLeadsPage(context);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 17, color: Color(0xFF6366F1)),
                  tooltip: 'Lead Intelligence Engine',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showUnderstandLeadDialog(context, lead),
                ),
                IconButton(
                  icon: const Icon(Icons.data_object_rounded, size: 17),
                  tooltip: 'Inspect JSON Payload',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showInspectLeadDialog(context, lead),
                ),
                IconButton(
                  icon: Icon(
                    (_viewMode == 'archive_listed' || _viewMode == 'archive_requirements' || _viewMode == 'listed')
                        ? Icons.unarchive_rounded
                        : Icons.archive_outlined,
                    size: 17,
                    color: (_viewMode == 'archive_listed' || _viewMode == 'archive_requirements' || _viewMode == 'listed')
                        ? const Color(0xFF10B981)
                        : const Color(0xFF6366F1),
                  ),
                  tooltip: (_viewMode == 'archive_listed' || _viewMode == 'archive_requirements' || _viewMode == 'listed')
                      ? 'Unarchive Lead'
                      : 'Archive Lead',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    if (_viewMode == 'archive_listed' || _viewMode == 'archive_requirements' || _viewMode == 'listed') {
                      _unarchiveLead(lead);
                    } else {
                      _archiveLead(lead);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 17, color: CRMColors.danger),
                  tooltip: 'Delete Lead',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _confirmDeleteSingleLeadDialog(context, lead),
                ),
              ],
            ),
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
        onPressed: () => _showReorderColumnsDialog(context, allDetectedHeaders, leads),
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
        if (action == 'archive_listed') {
          setState(() {
            _viewMode = 'archive_listed';
            _selectedSection = 'Property Listing';
            _cachedFilteredLeads = null;
            _currentPage = 1;
          });
        } else if (action == 'archive_requirements') {
          setState(() {
            _viewMode = 'archive_requirements';
            _selectedSection = 'Requirement';
            _cachedFilteredLeads = null;
            _currentPage = 1;
          });
        } else if (action == 'reorder') {
          _showReorderColumnsDialog(context, allDetectedHeaders, leads);
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
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: (_selectedSourceFilter.toUpperCase().contains('HOUSING'))
              ? 'Housing.com'
              : (_selectedSourceFilter.toUpperCase().contains('META')
                  ? 'Meta Ads'
                  : (_selectedSourceFilter == 'Google Sheets'
                      ? 'Google Sheets'
                      : (_selectedSourceFilter == 'Webhook API' ? 'Webhook API' : 'All'))),
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All Sources')),
            DropdownMenuItem(value: 'Meta Ads', child: Text('Meta Ads')),
            DropdownMenuItem(value: 'Housing.com', child: Text('Housing.com')),
            DropdownMenuItem(value: 'Google Sheets', child: Text('Google Sheets')),
            DropdownMenuItem(value: 'Webhook API', child: Text('Webhook API')),
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

    final currentAuth = context.read<AuthBloc>().state;
    final currentRole = currentAuth is Authenticated ? currentAuth.user.role : null;
    final filterUsers = TeamUserVisibility.canUseFilter(currentRole)
        ? _employeesDirectoryUsers(_cachedUsers ?? const [])
        : <users_model.UserModel>[];
    final userDropdownItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'All', child: Text('All Users', overflow: TextOverflow.ellipsis, maxLines: 1)),
      ...filterUsers.map(
        (u) => DropdownMenuItem(
          value: u.id,
          child: Text(
            '${u.fullName} (${u.roleName})',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    ];
    final userDropdownValue = userDropdownItems.any((i) => i.value == _selectedUserFilterId)
        ? _selectedUserFilterId
        : 'All';

    final userDropdown = TeamUserVisibility.canUseFilter(currentRole)
        ? Container(
            height: 38,
            constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 240),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: CRMColors.cardBgOf(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CRMColors.borderOf(context)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                hint: const Text('User'),
                value: userDropdownValue,
                items: userDropdownItems,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedUserFilterId = val;
                      _cachedFilteredLeads = null;
                      _currentPage = 1;
                    });
                  }
                },
              ),
            ),
          )
        : const SizedBox.shrink();

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
          isExpanded: true,
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
            : FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
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
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toolbar Filters & Search (Responsive)
            if (isMobile) ...[
              Row(
                children: [
                  Expanded(child: reorderColumnsButton),
                  const SizedBox(width: CRMSpacing.xs),
                  Expanded(child: columnsButton),
                ],
              ),
              const SizedBox(height: CRMSpacing.xs),
              Row(
                children: [
                  Expanded(child: exportExcelButton),
                  const SizedBox(width: CRMSpacing.xs),
                  Expanded(child: addHeaderButton),
                ],
              ),
              const SizedBox(height: CRMSpacing.s),
              searchInput,
              const SizedBox(height: CRMSpacing.s),
              if (widget.lockSource == null) sourceDropdown,
              if (TeamUserVisibility.canUseFilter(currentRole)) ...[
                const SizedBox(height: CRMSpacing.s),
                userDropdown,
              ],
              const SizedBox(height: CRMSpacing.s),
              duplicateDropdown,
            ] else ...[
              Row(
                children: [
                  Expanded(flex: 3, child: searchInput),
                  if (widget.lockSource == null) ...[
                    const SizedBox(width: CRMSpacing.m),
                    Flexible(child: sourceDropdown),
                  ],
                  if (TeamUserVisibility.canUseFilter(currentRole)) ...[
                    const SizedBox(width: CRMSpacing.m),
                    Flexible(child: userDropdown),
                  ],
                  const SizedBox(width: CRMSpacing.m),
                  Flexible(child: duplicateDropdown),
                ],
              ),
            ],

            const SizedBox(height: CRMSpacing.m),

            // Spreadsheet Data Table or Clean Empty State
            if (leads.isEmpty) ...[
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
                        RoleGuard.isTelecaller(currentRole) ? 'No leads assigned to you' : 'No Leads Ingested Yet',
                        style: CRMTypography.headline.copyWith(fontSize: 17),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: CRMSpacing.xs),
                      Text(
                        RoleGuard.isTelecaller(currentRole)
                            ? 'Leads allocated while you are ACTIVE show up in this list. Switch the section tabs if a count is sitting on the other type.'
                            : 'Connect your Google Sheet, then Sync or Import CSV. Leads stay here until you filter, delete fakes, and click Move to Leads page.',
                        style: CRMTypography.body.copyWith(color: CRMColors.textSecondaryOf(context), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      if (!RoleGuard.isTelecaller(currentRole)) ...[
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
                    ],
                  ),
                ),
              ),
            ] else if (isMobile) ...[
              _buildMobileCardListHeader(context, pageLeads),
              ...pageLeads.asMap().entries.map((entry) {
                return _buildMobileLeadCard(context, entry.value, entry.key, startIndex, visibleHeaders);
              }),
            ] else ...[
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
                      dataRowMinHeight: 44,
                      dataRowMaxHeight: 52,
                      horizontalMargin: 12,
                      columnSpacing: 18,
                      columns: [
                        const DataColumn(label: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                        _buildExcelDataColumn(context, title: 'Source', columnKey: '#Source', isStandard: true),
                        _buildExcelDataColumn(context, title: 'Status', columnKey: '#CampaignStatus', isStandard: true),
                        _buildExcelDataColumn(context, title: 'Transfer Leads', columnKey: '#TransferLeads', isStandard: true),

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
                            if (lead.campaignStatus == 'CNR') {
                              return const Color(0xFFF59E0B).withValues(alpha: 0.12);
                            }
                            if (lead.campaignStatus == 'Picked Up' || lead.campaignStatus == 'Assigned') {
                              return const Color(0xFF10B981).withValues(alpha: 0.10);
                            }
                            if (lead.campaignStatus == 'Interested') {
                              return const Color(0xFF10B981).withValues(alpha: 0.14);
                            }
                            if (lead.campaignStatus == 'Follow up') {
                              return const Color(0xFFF59E0B).withValues(alpha: 0.08);
                            }
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
                                  _buildSourceBadge(lead.source),
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

                            // Status Dropdown Cell (Follow up, Interested, Not interested)
                            DataCell(_buildStatusDropdownCell(context, lead)),

                            // Transfer Leads Cell
                            DataCell(_buildTransferLeadCell(context, lead)),

                            // Dynamic Visible Cells mapped to JSON keys
                            ...visibleHeaders.map((header) {
                              if (header == 'Received On') {
                                return DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        lead.formattedReceivedAt,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        lead.relativeTimeAgo,
                                        style: TextStyle(fontSize: 10, color: CRMColors.textSecondaryOf(context)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              final val = lead.getStringValue(header);
                              return DataCell(
                                Text(
                                  _formatDisplayCellValue(header, val),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }),

                            // Actions (Lead Intelligence Engine, Inspect JSON, Archive/Unarchive & Delete)
                            DataCell(
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (RoleGuard.isTelecaller(RoleGuard.currentUser?.role) ||
                                      RoleGuard.currentUser?.role == 'Admin' ||
                                      RoleGuard.currentUser?.role == 'Super Admin')
                                    IconButton(
                                      icon: const Icon(Icons.swap_horiz_rounded, size: 18, color: Color(0xFF0284C7)),
                                      tooltip: (RoleGuard.currentUser?.role == 'Admin' || RoleGuard.currentUser?.role == 'Super Admin')
                                          ? 'Assign / Transfer to telecaller'
                                          : 'Transfer to another telecaller',
                                      onPressed: () => _showPartnerTelecallerDialog(context, lead),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF6366F1)),
                                    tooltip: '⚡ Lead Intelligence Engine (1-Click WhatsApp & CRM)',
                                    onPressed: () => _showUnderstandLeadDialog(context, lead),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.data_object_rounded, size: 18),
                                    tooltip: 'Inspect JSON Payload',
                                    onPressed: () => _showInspectLeadDialog(context, lead),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      (_viewMode == 'archive_listed' || _viewMode == 'archive_requirements' || _viewMode == 'listed')
                                          ? Icons.unarchive_rounded
                                          : Icons.archive_outlined,
                                      size: 18,
                                      color: (_viewMode == 'archive_listed' || _viewMode == 'archive_requirements' || _viewMode == 'listed')
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF6366F1),
                                    ),
                                    tooltip: (_viewMode == 'archive_listed' || _viewMode == 'archive_requirements' || _viewMode == 'listed')
                                        ? 'Unarchive Lead'
                                        : 'Archive Lead',
                                    onPressed: () {
                                      if (_viewMode == 'archive_listed' || _viewMode == 'archive_requirements' || _viewMode == 'listed') {
                                        _unarchiveLead(lead);
                                      } else {
                                        _archiveLead(lead);
                                      }
                                    },
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
        ],
        const SizedBox(height: CRMSpacing.s),
        _buildCampaignPager(context, leads.length, startIndex, currentPage, totalPages),
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
    int totalPages, {
    int? pageSize,
    void Function(int page)? onPageChanged,
    void Function(int size)? onPageSizeChanged,
  }) {
    final size = pageSize ?? _pageSize;
    final from = totalFiltered == 0 ? 0 : startIndex + 1;
    final to = (startIndex + size).clamp(0, totalFiltered);
    final isMobile = MediaQuery.of(context).size.width < 600;

    void goToPage(int page) {
      if (onPageChanged != null) {
        onPageChanged(page);
      } else {
        setState(() => _currentPage = page);
      }
    }

    final pageSizeDropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: 32,
      decoration: BoxDecoration(
        color: CRMColors.cardBgOf(context),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CRMColors.borderOf(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: size,
          items: const [
            DropdownMenuItem(value: 25, child: Text('25 / page', style: TextStyle(fontSize: 12))),
            DropdownMenuItem(value: 50, child: Text('50 / page', style: TextStyle(fontSize: 12))),
            DropdownMenuItem(value: 100, child: Text('100 / page', style: TextStyle(fontSize: 12))),
          ],
          onChanged: (val) {
            if (val == null) return;
            if (onPageSizeChanged != null) {
              onPageSizeChanged(val);
            } else {
              setState(() {
                _pageSize = val;
                _currentPage = 1;
              });
            }
          },
        ),
      ),
    );

    final navButtons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'First page',
          onPressed: currentPage <= 1 ? null : () => goToPage(1),
          icon: const Icon(Icons.first_page_rounded, size: 20),
        ),
        IconButton(
          tooltip: 'Previous page',
          onPressed: currentPage <= 1 ? null : () => goToPage(currentPage - 1),
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
          onPressed: currentPage >= totalPages ? null : () => goToPage(currentPage + 1),
          icon: const Icon(Icons.chevron_right_rounded, size: 20),
        ),
        IconButton(
          tooltip: 'Last page',
          onPressed: currentPage >= totalPages ? null : () => goToPage(totalPages),
          icon: const Icon(Icons.last_page_rounded, size: 20),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing $from–$to of $totalFiltered leads',
                style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontWeight: FontWeight.w600),
              ),
              pageSizeDropdown,
            ],
          ),
          const SizedBox(height: 6),
          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: navButtons,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          'Showing $from–$to of $totalFiltered leads',
          style: CRMTypography.caption.copyWith(color: CRMColors.textSecondaryOf(context), fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        pageSizeDropdown,
        const SizedBox(width: 6),
        navButtons,
      ],
    );
  }

  // --- EXCEL FEATURES, FILTERING, SORTING & DRAG-AND-PLACE REORDERING ---

  /// Live Auto-Sync Status Badge (reflects Meta Lead Ads, VPS backend, and Google Sheets)
  Widget _buildAutoSyncLiveBadge(BuildContext context) {
    final hasSheet = _service.googleSheetUrl.isNotEmpty;
    final lastSheetSync = _service.lastSyncAt;
    final isFetching = _service.isFetchingServerLeads || _isSyncingSheet;

    final blocState = context.watch<CampaignLeadsBloc>().state;
    final lastServerPing = blocState.lastPingAt;
    final isServerPinging = blocState.isPinging;

    final bool isSyncingNow = isFetching || isServerPinging;

    String syncTimeText;
    if (isSyncingNow) {
      syncTimeText = 'Syncing now...';
    } else {
      DateTime? mostRecent = lastSheetSync;
      if (mostRecent == null || (lastServerPing != null && lastServerPing.isAfter(mostRecent))) {
        mostRecent = lastServerPing;
      }

      if (mostRecent == null) {
        syncTimeText = hasSheet ? 'Live (Sheet + Meta)' : 'Live • Meta & Server';
      } else {
        final diff = DateTime.now().difference(mostRecent);
        if (diff.inSeconds < 45) {
          syncTimeText = 'Synced just now';
        } else if (diff.inMinutes < 60) {
          syncTimeText = 'Synced ${diff.inMinutes}m ago';
        } else {
          syncTimeText = 'Synced at ${DateFormat('HH:mm').format(mostRecent.toLocal())}';
        }
      }
    }

    final String titleText = hasSheet ? 'Live Sync (Sheet + Meta)' : 'Live Leads: Active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: CRMColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(CRMBorderRadius.input),
        border: Border.all(
          color: CRMColors.success.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CRMColors.success,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            titleText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: CRMColors.success,
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

  /// Live Meta Diagnostics Badge
  Widget _buildMetaLiveDiagnosticBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isBlocked = _service.metaStatus == 'BLOCKED' ||
        _service.activeHealthAlerts.any((a) => a['code'] == 'META_ACCESS_BLOCKED');

    return InkWell(
      onTap: () => _showMetaDiagnosticDialog(context),
      borderRadius: BorderRadius.circular(CRMBorderRadius.input),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isBlocked
              ? (isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2))
              : CRMColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(CRMBorderRadius.input),
          border: Border.all(
            color: isBlocked
                ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                : CRMColors.success.withValues(alpha: 0.35),
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
                color: isBlocked ? const Color(0xFFEF4444) : CRMColors.success,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isBlocked ? 'Meta: Token Blocked' : 'Meta: Connected',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isBlocked ? const Color(0xFFDC2626) : CRMColors.success,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              isBlocked ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              size: 13,
              color: isBlocked ? const Color(0xFFDC2626) : CRMColors.success,
            ),
          ],
        ),
      ),
    );
  }

  void _showMetaDiagnosticDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alert = _service.activeHealthAlerts.firstWhere(
      (a) => a['code'] == 'META_ACCESS_BLOCKED',
      orElse: () => {
        'title': 'Meta Integration Diagnostic',
        'diagnosticSummary': 'Meta Graph API token or webhook connection status.',
        'rootCause': 'Token permissions or Meta App Review requirement.',
        'impact': 'Automated polling from Meta Lead Ads paused. Sheets and Direct Webhooks remain active.',
        'resolutionSteps': [
          'Review Meta App Dashboard alerts.',
          'Generate fresh Page/System User Access Token with leads_retrieval permission.',
          'Update META_DEFAULT_PAGE_TOKEN on VPS backend.'
        ]
      },
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        actionsPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hub_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                alert['title']?.toString() ?? 'Meta Graph API Diagnostic',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: CRMBreakpoints.adaptiveWidth(context, 540),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DIAGNOSTIC SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text(
                        alert['diagnosticSummary']?.toString() ?? 'Meta has restricted API access on App ID 1632855004850842.',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                      if (alert['rootCause'] != null) ...[
                        const SizedBox(height: 8),
                        const Text('ROOT CAUSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Text(
                          alert['rootCause']?.toString() ?? '',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('ACTIONABLE RESOLUTION STEPS:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                ...?((alert['resolutionSteps'] as List?)?.map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(step.toString(), style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                ))),
              ],
            ),
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              launchUrl(Uri.parse('${AppEnv.apiBaseUrl}/health'));
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 14),
            label: const Text('Open Health Portal'),
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
    final sectionLeads = _viewMode == 'not_interested'
        ? _scopedLeads.where((l) => isNotInterestedStatus(l.campaignStatus)).toList()
        : _scopedLeads.where((l) => l.leadType == _selectedSection && !isNotInterestedStatus(l.campaignStatus) && l.campaignStatus != 'Property Listed' && l.campaignStatus != 'Listed' && l.campaignStatus != 'Archived' && l.campaignStatus != 'Assigned' && l.importStatus != 'Imported' && !(l.assignedTo != null && l.assignedTo!.isNotEmpty && l.assignedTo != 'Unassigned') && !_leftCallingQueue(l)).toList();

    for (final lead in sectionLeads) {
      String val;
      if (columnKey == '#Source') {
        val = lead.source;
      } else if (columnKey == '#CampaignStatus') {
        val = lead.campaignStatus;
      } else if (columnKey == '#TransferLeads') {
        val = lead.assignedToName?.isNotEmpty == true
            ? 'Assigned: ${lead.assignedToName}'
            : (lead.campaignStatus == 'CNR' ? 'CNR (Interacted)' : 'Not Assigned');
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
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SizedBox(
                width: double.maxFinite,
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
  void _showReorderColumnsDialog(BuildContext context, [List<String>? sectionHeaders, List<IntegrationLeadModel>? sectionLeads]) {
    final targetLeads = sectionLeads ?? _filteredLeads;
    final orderBefore = List<String>.from(_service.headerOrderFor(_selectedSection));
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final allHeaders = sectionHeaders ?? _cachedAllDetectedHeaders ?? _service.getDetectedHeaders(leadsSubset: targetLeads, section: _selectedSection);

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.swap_horiz_rounded, color: CRMColors.primaryOf(context)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reorder ${_selectedSection} Columns',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 440),
              child: SizedBox(
                width: double.maxFinite,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drag and drop ${_selectedSection} columns using the handles (⠿) to change their display order. Layout is saved for ${_selectedSection} tab.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${allHeaders.length} ${_selectedSection} Columns',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.restore_page_rounded, size: 16),
                        label: const Text('Reset to Sheet Order'),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await _service.resetHeaderOrderToSheet(
                            leadsSubset: targetLeads,
                            section: _selectedSection,
                            persist: false,
                          );
                          setModalState(() {});
                          setState(() {});
                          messenger.showSnackBar(
                            SnackBar(content: Text('Reset $_selectedSection column order to standard sequence.')),
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
                        await _service.reorderHeaders(
                          oldIndex,
                          newIndex,
                          leadsSubset: targetLeads,
                          section: _selectedSection,
                          persist: false,
                        );
                        setModalState(() {});
                        setState(() {});
                      },
                      itemBuilder: (ctx, i) {
                        final h = allHeaders[i];
                        final isVisible = _service.isHeaderVisible(h, section: _selectedSection);
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
                                        await _service.moveHeader(h, -1, leadsSubset: targetLeads, section: _selectedSection);
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
                                        await _service.moveHeader(h, 1, leadsSubset: targetLeads, section: _selectedSection);
                                        setModalState(() {});
                                        setState(() {});
                                      }
                                    : null,
                              ),
                              Switch(
                                value: isVisible,
                                activeThumbColor: CRMColors.primaryOf(context),
                                onChanged: (val) {
                                  _service.setHeaderVisibility(h, val, section: _selectedSection);
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
          ),
          actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final after = _service.headerOrderFor(_selectedSection);
                  final changed = after.length != orderBefore.length ||
                      after.asMap().entries.any((entry) => entry.value != orderBefore[entry.key]);
                  if (!changed || !mounted) return;
                  final scope = await _showSaveScopeDialog(
                    context,
                    actionLabel: 'Reorder $_selectedSection columns',
                  );
                  if (!mounted) return;
                  if (scope == null) {
                    _service.replaceSectionHeaderOrder(_selectedSection, orderBefore);
                    setState(() {});
                    return;
                  }
                  final ok = await _service.saveColumnLayoutToServer(
                    section: _selectedSection,
                    scope: scope,
                  );
                  if (!mounted) return;
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Column order saved ${scope == 'global' ? 'for everyone' : 'only for you'}.'
                            : 'Could not save the column order. Try again.',
                      ),
                    ),
                  );
                },
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

    final visibleHeaders = _service.getActiveVisibleHeaders(leadsSubset: leadsToExport, section: _selectedSection);
    final excel = xl.Excel.createExcel();
    final sheet = excel['Campaign Leads'];

    // Header Row
    final headerCells = <xl.CellValue>[
      xl.TextCellValue('#'),
      xl.TextCellValue('Source'),
      xl.TextCellValue('Status'),
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
        xl.TextCellValue(lead.campaignStatus),
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
            const Expanded(
              child: Text(
                'Delete Lead Permanently?',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            Expanded(
              child: Text(
                'Delete $count Leads Permanently?',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
                const Expanded(
                  child: Text(
                    'Merge Selected Leads',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
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
            const Expanded(
              child: Text(
                'Clear All Ingested Leads?',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
            final currentAllHeaders = _service.getDetectedHeaders(leadsSubset: _filteredLeads, section: _selectedSection);
            final visibleCount = _service.getActiveVisibleHeaders(leadsSubset: _filteredLeads, section: _selectedSection).length;
            final totalCount = currentAllHeaders.length;

            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.view_column_rounded, color: CRMColors.primaryOf(context)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Select Visible Headers ($visibleCount of $totalCount visible)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.check_box_rounded, size: 16),
                            label: const Text('Select All'),
                            onPressed: () async {
                              final scope = await _showSaveScopeDialog(context, actionLabel: 'Show all columns');
                              if (scope == null) return;
                              final ok = await _service.setAllHeadersVisibility(true, section: _selectedSection, scope: scope);
                              setModalState(() {});
                              setState(() {});
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(ok
                                    ? 'All columns shown ${scope == 'global' ? 'for everyone' : 'only for you'}.'
                                    : 'Could not save this column change.')),
                              );
                            },
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.check_box_outline_blank_rounded, size: 16),
                            label: const Text('Deselect All'),
                            onPressed: () async {
                              final scope = await _showSaveScopeDialog(context, actionLabel: 'Hide all optional columns');
                              if (scope == null) return;
                              final ok = await _service.setAllHeadersVisibility(false, section: _selectedSection, scope: scope);
                              setModalState(() {});
                              setState(() {});
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(ok
                                    ? 'Columns hidden ${scope == 'global' ? 'for everyone' : 'only for you'}.'
                                    : 'Could not save this column change.')),
                              );
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
                            final isChecked = _service.isHeaderVisible(h, section: _selectedSection);
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
                              onChanged: (val) async {
                                final scope = await _showSaveScopeDialog(context, actionLabel: (val == true ? 'Show column "$h"' : 'Hide column "$h"'));
                                if (scope != null) {
                                  final ok = await _service.setHeaderVisibility(h, val ?? false, section: _selectedSection, scope: scope);
                                  setModalState(() {});
                                  setState(() {});
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(ok
                                        ? 'Saved ${scope == 'global' ? 'for everyone' : 'only for you'}.'
                                        : 'Could not save this column change.')),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
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

  /// Scope Selection Dialog: "Change only for me" vs "Change for all users"
  Future<String?> _showSaveScopeDialog(BuildContext context, {required String actionLabel}) async {
    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.tune_rounded, color: CRMColors.primaryOf(context)),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Save Column Layout Changes',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How would you like to save this column layout change ($actionLabel)?',
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: CRMColors.borderOf(context)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_rounded, color: Color(0xFF3B82F6)),
                    title: const Text('Change only for me', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('Saves column layout to your personal user profile on the server.', style: TextStyle(fontSize: 11)),
                    onTap: () => Navigator.pop(ctx, 'user'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.groups_rounded, color: Color(0xFF10B981)),
                    title: const Text('Change for all users', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    subtitle: const Text('Saves column layout as the default organization layout on the server.', style: TextStyle(fontSize: 11)),
                    onTap: () => Navigator.pop(ctx, 'global'),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
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
              const Expanded(
                child: Text(
                  'Add Dynamic Column Header',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
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
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(ctx);
                  final scope = await _showSaveScopeDialog(context, actionLabel: 'Add header "$name"');
                  if (scope != null) {
                    final ok = await _service.addCustomHeader(name, crmField: selectedCrmTarget, section: _selectedSection, scope: scope);
                    if (mounted) {
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                        SnackBar(content: Text(ok
                            ? 'Added header "$name" ${scope == 'global' ? 'for everyone' : 'only for you'}.'
                            : 'Could not save header "$name".')),
                      );
                    }
                  }
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
              Expanded(
                child: Text(
                  'Header: "$header"',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
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
                        final scope = await _showSaveScopeDialog(context, actionLabel: 'Move "$header" left');
                        if (scope != null) {
                          final ok = await _service.moveHeader(header, -1, leadsSubset: _filteredLeads, section: _selectedSection, scope: scope);
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok
                                  ? 'Column moved ${scope == 'global' ? 'for everyone' : 'only for you'}.'
                                  : 'Could not save this column change.')),
                            );
                          }
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.arrow_forward_rounded),
                      title: const Text('Move Column Right'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onTap: () async {
                        Navigator.pop(ctx);
                        final scope = await _showSaveScopeDialog(context, actionLabel: 'Move "$header" right');
                        if (scope != null) {
                          final ok = await _service.moveHeader(header, 1, leadsSubset: _filteredLeads, section: _selectedSection, scope: scope);
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ok
                                  ? 'Column moved ${scope == 'global' ? 'for everyone' : 'only for you'}.'
                                  : 'Could not save this column change.')),
                            );
                          }
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.swap_horiz_rounded),
                      title: const Text('Reorder All Columns (Drag & Drop)'),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showReorderColumnsDialog(context, _cachedAllDetectedHeaders, _filteredLeads);
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
                      onTap: () async {
                        Navigator.pop(ctx);
                        final scope = await _showSaveScopeDialog(context, actionLabel: 'Hide "$header"');
                        if (scope != null) {
                          final ok = await _service.setHeaderVisibility(header, false, section: _selectedSection, scope: scope);
                          if (mounted) {
                            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                              SnackBar(content: Text(ok
                                  ? 'Column "$header" hidden ${scope == 'global' ? 'for everyone' : 'only for you'}.'
                                  : 'Could not save this column change.')),
                            );
                          }
                        }
                      },
                    ),
                    if (_service.customHeadersFor(_selectedSection).contains(header) || _service.customHeaders.contains(header))
                      ListTile(
                        leading: const Icon(Icons.delete_forever_rounded, color: CRMColors.danger),
                        title: const Text('Delete Custom Header', style: TextStyle(color: CRMColors.danger)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onTap: () async {
                          Navigator.pop(ctx);
                          final scope = await _showSaveScopeDialog(context, actionLabel: 'Delete "$header"');
                          if (scope != null) {
                            final ok = await _service.removeCustomHeader(header, section: _selectedSection, scope: scope);
                            if (mounted) {
                              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                                SnackBar(content: Text(ok
                                    ? 'Custom column "$header" removed ${scope == 'global' ? 'for everyone' : 'only for you'}.'
                                    : 'Could not save this column change.')),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),
              ),
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
        title: Text('Rename Header "$oldHeader"', overflow: TextOverflow.ellipsis),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'New Header Name'),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty || newName == oldHeader) return;
              Navigator.pop(ctx);
              final scope = await _showSaveScopeDialog(context, actionLabel: 'Rename "$oldHeader" to "$newName"');
              if (scope == null || !mounted) return;
              _service.renameHeader(oldHeader, newName, section: _selectedSection);
              final ok = await _service.saveColumnLayoutToServer(section: _selectedSection, scope: scope);
              if (!mounted) return;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(ok
                    ? 'Renamed "$oldHeader" to "$newName" ${scope == 'global' ? 'for everyone' : 'only for you'}.'
                    : 'Could not save the renamed header.')),
              );
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
              const Expanded(
                child: Text(
                  'Merge Multiple Headers into One',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
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
              const Expanded(
                child: Text(
                  'Paste JSON Payload (Simulate Ingestion)',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12.0 : 40.0,
          vertical: isMobile ? 16.0 : 24.0,
        ),
        title: Row(
          children: [
            const Icon(Icons.data_object_rounded),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Payload Inspector: ${lead.source}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SizedBox(
            width: double.maxFinite,
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
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showUnderstandLeadDialog(BuildContext context, IntegrationLeadModel lead) {
    final understanding = LeadUnderstandingEngine.analyze(lead);
    final isOwner = understanding.persona == LeadPersona.ownerListing;
    final isImported = lead.importStatus == 'Imported';
    final targetCrmPage = isOwner ? 'Properties Inventory' : 'Leads (Requirements)';
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12.0 : 40.0,
          vertical: isMobile ? 16.0 : 24.0,
        ),
        titlePadding: EdgeInsets.fromLTRB(
          isMobile ? 14 : 20,
          isMobile ? 14 : 18,
          isMobile ? 10 : 20,
          isMobile ? 8 : 10,
        ),
        contentPadding: EdgeInsets.fromLTRB(
          isMobile ? 14 : 20,
          10,
          isMobile ? 14 : 20,
          10,
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          isMobile ? 14 : 20,
          10,
          isMobile ? 14 : 20,
          isMobile ? 14 : 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Lead Intelligence Engine',
                    style: TextStyle(fontSize: isMobile ? 15 : 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Persona diagnosis, urgency & 1-click workflows',
                    style: TextStyle(fontSize: isMobile ? 11 : 12, color: CRMColors.textSecondaryOf(context)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 580,
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Persona & Quality Badges
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Persona Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isOwner
                            ? const Color(0xFF6366F1).withValues(alpha: 0.12)
                            : const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isOwner
                              ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                              : const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOwner ? Icons.home_work_rounded : Icons.person_search_rounded,
                            size: 15,
                            color: isOwner ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOwner ? 'Owner Listing' : 'Tenant Requirement',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isOwner ? const Color(0xFF4F46E5) : const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Freshness Badge
                    if (lead.freshnessBadge.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: lead.freshnessBadge.contains('Today')
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: lead.freshnessBadge.contains('Today')
                                ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          lead.freshnessBadge,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: lead.freshnessBadge.contains('Today')
                                ? const Color(0xFF047857)
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    // Arrival Time
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: CRMColors.surfaceElevatedOf(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: CRMColors.borderOf(context)),
                      ),
                      child: Text(
                        '🕒 ${lead.formattedReceivedAt} (${lead.relativeTimeAgo})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Executive One-Line Summary Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF6366F1), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          understanding.oneLineSummary,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Key Extracted Details Card
                const Text('Key Lead Attributes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CRMColors.cardBgOf(context),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CRMColors.borderOf(context)),
                  ),
                  child: Text(
                    understanding.keyDetails,
                    style: const TextStyle(fontSize: 12.5, height: 1.5),
                  ),
                ),

                const SizedBox(height: 14),

                // Recommended Action Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Next Action: ${understanding.recommendedAction}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Pre-drafted WhatsApp Message Preview
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('1-Click Personalized WhatsApp:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    TextButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text('Copy Text', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: understanding.personalizedWhatsAppMessage));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('WhatsApp message copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    understanding.personalizedWhatsAppMessage,
                    style: const TextStyle(fontSize: 12, height: 1.4, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: isMobile
            ? [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (understanding.whatsAppUrl != null) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('Open WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(understanding.whatsAppUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (understanding.dialerUrl != null) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                        label: const Text('Call Lead'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(understanding.dialerUrl!);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (!isImported) ...[
                      ElevatedButton.icon(
                        icon: Icon(isOwner ? Icons.home_work_rounded : Icons.drive_file_move_rounded, size: 16),
                        label: Text(isOwner ? 'Move to Properties' : 'Move to Leads'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CRMColors.primaryOf(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isImporting = true);
                          if (isOwner) {
                            await _service.importLeadsToProperties([lead.id]);
                          } else {
                            await _service.importLeadsToCrm([lead.id]);
                          }
                          if (mounted) {
                            setState(() {
                              _isImporting = false;
                              _cachedFilteredLeads = null;
                            });
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Lead moved to $targetCrmPage successfully!'),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }
                        },
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                            SizedBox(width: 6),
                            Text('In CRM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10B981))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ]
            : [
                // 1-Click WhatsApp Button
                if (understanding.whatsAppUrl != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('Open WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () async {
                      final uri = Uri.parse(understanding.whatsAppUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),

                // 1-Click Call Button
                if (understanding.dialerUrl != null)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                    label: const Text('Call Lead'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () async {
                      final uri = Uri.parse(understanding.dialerUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                  ),

                // 1-Click Move to CRM Button
                if (!isImported)
                  ElevatedButton.icon(
                    icon: Icon(isOwner ? Icons.home_work_rounded : Icons.drive_file_move_rounded, size: 16),
                    label: Text(isOwner ? 'Move to Properties' : 'Move to Leads'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CRMColors.primaryOf(context),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      setState(() => _isImporting = true);
                      if (isOwner) {
                        await _service.importLeadsToProperties([lead.id]);
                      } else {
                        await _service.importLeadsToCrm([lead.id]);
                      }
                      if (mounted) {
                        setState(() {
                          _isImporting = false;
                          _cachedFilteredLeads = null;
                        });
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Lead moved to $targetCrmPage successfully!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text('In CRM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF10B981))),
                      ],
                    ),
                  ),
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
    List<int>? fileBytes = file.bytes;
    if (fileBytes == null && file.path != null && !kIsWeb) {
      try {
        fileBytes = await File(file.path!).readAsBytes();
      } catch (e) {
        debugPrint('Failed to read CSV file from path: $e');
      }
    }
    if (fileBytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read that file. Try exporting the sheet as CSV again.')),
      );
      return;
    }
    final csv = utf8.decode(fileBytes, allowMalformed: true);
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
            const Expanded(
              child: Text(
                'Move to Properties page?',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to Leads page?'),
        content: Text(
          'Move ${selected.length} cleaned campaign lead(s) to the main Leads page? They will be active and visible on the Leads page.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Move to Leads page')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isImporting = true);
    final count = await _service.importLeadsToCrm(selected, forceReimport: true);
    if (!mounted) return;
    setState(() {
      _isImporting = false;
      _selectedLeadIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          count == 0
              ? 'Lead(s) are active and visible on the Leads page.'
              : 'Moved $count lead(s) to the Leads page.',
        ),
        backgroundColor: const Color(0xFF10B981),
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
            const Expanded(
              child: Text(
                'Clean & Merge Duplicates?',
                overflow: TextOverflow.ellipsis,
              ),
            ),
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
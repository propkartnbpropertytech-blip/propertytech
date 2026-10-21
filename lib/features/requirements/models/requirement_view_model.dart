import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../models/requirement_model.dart';
import '../../auth/models/user_model.dart';
import '../../users/models/user_model.dart' as users_model;
import '../../../core/utils/budget_formatter.dart';
import '../../../core/utils/team_user_visibility.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/storage/local_repositories.dart';
import '../../properties/models/property_model.dart' show PropertyMetadataModel;

enum LeadDateFilterPreset {
  today,
  yesterday,
  last7Days,
  thisMonth,
  customRange,
  allTime,
}

/// Pre-computed, immutable view model for a Requirement in lists, cards, and tables.
/// Eliminates repeated string lowercasing, date parsing, status mapping,
/// and linear lookups during build passes.
class RequirementListItemViewModel {
  final RequirementModel requirement;
  final String listingTypeLabel;
  final String effectiveStatus;
  final String mappedStatus;
  final bool isWon;
  final bool isRejected;
  final bool isClosed;
  final bool isUnhandledAssigned;
  final String budgetText;
  final String dateText;
  final String specsText;
  final String areasText;
  final DateTime? rejectedAt;
  final DateTime filterDate;
  final int sortDateMillis;
  final int normalSortDateMillis;
  final String normalizedSearchTokens;
  final String clientNameLower;
  final String clientMobileLower;
  final String creatorNameLower;
  final String assigneeNameLower;
  final String matchingReadiness;

  const RequirementListItemViewModel({
    required this.requirement,
    required this.listingTypeLabel,
    required this.effectiveStatus,
    required this.mappedStatus,
    required this.isWon,
    required this.isRejected,
    required this.isClosed,
    required this.isUnhandledAssigned,
    required this.budgetText,
    required this.dateText,
    required this.specsText,
    required this.areasText,
    required this.rejectedAt,
    required this.filterDate,
    required this.sortDateMillis,
    required this.normalSortDateMillis,
    required this.normalizedSearchTokens,
    required this.clientNameLower,
    required this.clientMobileLower,
    required this.creatorNameLower,
    required this.assigneeNameLower,
    required this.matchingReadiness,
  });

  factory RequirementListItemViewModel.fromRequirement(
    RequirementModel r, {
    UserModel? currentUser,
    DateTime? relativeNow,
  }) {
    // 1. Listing type label
    final ltName = r.listingTypeName ?? '';
    final ltId = r.listingTypeId ?? '';
    final combinedLt = '$ltName $ltId'.toLowerCase();
    final String listingLabel = (combinedLt.contains('sale') || combinedLt.contains('resale'))
        ? 'Re-Sale'
        : 'Rent';

    // 2. Effective status & mapped status
    final now = relativeNow ?? DateTime.now();
    String effStatus = r.status;
    if (effStatus == 'New' || effStatus.isEmpty) {
      if (now.difference(r.createdAt) >= const Duration(hours: 24)) {
        effStatus = 'Not Started';
      } else {
        effStatus = 'New';
      }
    }

    // Is won / rejected check
    final stLower = r.status.trim().toLowerCase();
    final bool won = stLower == 'won' || stLower == 'closed' || stLower == 'deal won';
    final bool rej = r.status.trim().isNotEmpty &&
        r.status.trim().toLowerCase() != 'bin' &&
        r.status.trim().toLowerCase().startsWith('rejected');

    // Unhandled assigned check for Sales
    bool unhandledAssigned = false;
    if (currentUser != null && currentUser.role == 'Sales') {
      if (!_checkLeadTransferredAway(r, currentUser)) {
        final isAssigned = _checkUserAssignee(r, currentUser);
        final isCreator = _checkUserCreator(r, currentUser);
        if (isAssigned && !isCreator) {
          final meta = r.metaCustomFields;
          final hasReassigned = meta != null && (meta['reassigned_by'] != null || meta['reassigned_by_name'] != null);
          final hasFollowup = r.nextFollowupDate != null && r.nextFollowupDate!.trim().isNotEmpty;
          final salesHandled = _checkSalesHasHandledLead(r);
          if (!hasReassigned && !hasFollowup && !salesHandled && !won && !rej) {
            unhandledAssigned = true;
          }
        }
      }
    }

    String mapped = rej
        ? effStatus
        : ((r.status == 'Assigned' || r.status == 'Assigned to Sales')
            ? 'Assigned to Sales'
            : (unhandledAssigned ? 'Not Started' : effStatus));
    if (mapped == 'Active' || mapped == 'Live') mapped = 'Interested';
    if (mapped == 'Closed' || mapped == 'Won') mapped = 'Won';
    if (mapped == 'Suspended' || mapped == 'Dead') mapped = 'Not Interested';
    if (mapped.startsWith('Rejected') || mapped == 'Bin') mapped = 'Rejected';

    // Is closed or terminal
    final bool closed = won ||
        rej ||
        stLower == 'suspended' ||
        stLower == 'dead' ||
        stLower == 'not interested' ||
        stLower == 'bin';

    // Budget text
    final String budget = (r.minBudget > 0 || r.maxBudget > 0)
        ? '₹${BudgetFormatter.format(r.minBudget)} - ₹${BudgetFormatter.format(r.maxBudget)}'
        : 'Budget on Request';

    // Date text
    final String dateStr = DateFormat("dd MMM ''yy, h:mm a").format(r.createdAt.toLocal());

    // Specs text
    final String specs = '${r.propertyTypeName} (${(r.configurationName != null && r.configurationName!.isNotEmpty) ? r.configurationName : "Any Config"})';

    // Areas text
    final String areas = r.displayAreasText;

    // Rejected date parsing
    DateTime? rejDate;
    final meta = r.metaCustomFields;
    if (meta != null) {
      for (final key in ['rejected_at', 'rejectedAt', 'sales_handled_at']) {
        final raw = meta[key];
        if (raw == null) continue;
        final parsed = DateTime.tryParse(raw.toString());
        if (parsed != null) {
          rejDate = parsed.toLocal();
          break;
        }
      }
    }

    final localCreated = r.createdAt.toLocal();
    final dtForFilter = rejDate ?? localCreated;
    final int sortMillis = (rejDate ?? r.salesAssignedAt ?? r.createdAt).millisecondsSinceEpoch;
    final int normSortMillis = (r.salesAssignedAt ?? r.createdAt).millisecondsSinceEpoch;

    // Normalized search tokens
    final cNameLower = r.clientName.toLowerCase();
    final cMobileLower = r.clientMobile.toLowerCase();
    final reqCodeLower = r.requirementCode.toLowerCase();
    final reqIdLower = r.id.toLowerCase();
    final crNameLower = (r.creatorName ?? '').toLowerCase();
    final asNameLower = (r.assigneeName ?? '').toLowerCase();
    final specsCombined = '${r.propertyTypeName} ${r.configurationName ?? ""} ${r.listingTypeName ?? ""} ${r.categoryName}'.toLowerCase();
    final remarksLower = (r.remarks ?? '').toLowerCase();
    final areasLower = r.areaNames.join(' ').toLowerCase();

    final searchBuffer = StringBuffer()
      ..write(cNameLower)..write(' ')
      ..write(cMobileLower)..write(' ')
      ..write(reqCodeLower)..write(' ')
      ..write(reqIdLower)..write(' ')
      ..write(specsCombined)..write(' ')
      ..write(remarksLower)..write(' ')
      ..write(areasLower)..write(' ')
      ..write(crNameLower)..write(' ')
      ..write(asNameLower);

    return RequirementListItemViewModel(
      requirement: r,
      listingTypeLabel: listingLabel,
      effectiveStatus: effStatus,
      mappedStatus: mapped,
      isWon: won,
      isRejected: rej,
      isClosed: closed,
      isUnhandledAssigned: unhandledAssigned,
      budgetText: budget,
      dateText: dateStr,
      specsText: specs,
      areasText: areas,
      rejectedAt: rejDate,
      filterDate: dtForFilter,
      sortDateMillis: sortMillis,
      normalSortDateMillis: normSortMillis,
      normalizedSearchTokens: searchBuffer.toString(),
      clientNameLower: cNameLower,
      clientMobileLower: cMobileLower,
      creatorNameLower: crNameLower,
      assigneeNameLower: asNameLower,
      matchingReadiness: r.matchingReadiness,
    );
  }

  static bool _checkUserCreator(RequirementModel r, dynamic user) {
    if (user == null) return false;
    final uid = user is UserModel ? user.id : (user is users_model.UserModel ? user.id : '');
    if (r.createdBy == uid) return true;
    final uName = (user is UserModel ? user.fullName : (user is users_model.UserModel ? user.fullName : '')).trim().toLowerCase();
    if (uName.isNotEmpty) {
      if (r.createdBy != null && r.createdBy!.trim().toLowerCase() == uName) return true;
      if (r.creatorName != null && r.creatorName!.trim().toLowerCase() == uName) return true;
    }
    return false;
  }

  static bool _checkUserAssignee(RequirementModel r, dynamic user) {
    if (user == null) return false;
    final uid = user is UserModel ? user.id : (user is users_model.UserModel ? user.id : '');
    if (r.assignedTo != null && r.assignedTo == uid) return true;
    final uName = (user is UserModel ? user.fullName : (user is users_model.UserModel ? user.fullName : '')).trim().toLowerCase();
    if (uName.isNotEmpty) {
      if (r.assignedTo != null && r.assignedTo!.trim().toLowerCase() == uName) return true;
      if (r.assigneeName != null && r.assigneeName!.trim().toLowerCase() == uName) return true;
    }
    return false;
  }

  static bool _checkLeadTransferredAway(RequirementModel r, dynamic currentUser) {
    if (currentUser == null) return false;
    final role = (currentUser is UserModel ? currentUser.role : (currentUser is users_model.UserModel ? currentUser.roleName : ''));
    if (!role.toLowerCase().contains('sales')) return false;
    final isAssignee = _checkUserAssignee(r, currentUser);
    final isCreator = _checkUserCreator(r, currentUser);
    if (!isCreator) return false;
    final assigned = r.assignedTo;
    if (assigned == null || assigned.isEmpty) return false;
    return !isAssignee;
  }

  static bool _checkSalesHasHandledLead(RequirementModel req) {
    final meta = {
      ...?RequirementLocalRepository.metaCustomFieldsById[req.id],
      ...?req.metaCustomFields,
    };
    if (meta.isEmpty) return false;
    final handled = meta['handled_by_sales'];
    if (handled == true || handled == 'true' || handled == 1 || handled == '1') {
      return true;
    }
    if (meta['sales_handled_at'] != null && meta['sales_handled_at'].toString().trim().isNotEmpty) {
      return true;
    }
    final telecallerStatus = meta['telecaller_status']?.toString().trim() ?? '';
    if (telecallerStatus.isNotEmpty &&
        req.status.trim() != telecallerStatus &&
        req.status != 'Assigned' &&
        req.status != 'New') {
      return true;
    }
    return false;
  }
}

/// Standalone filter and sorting pipeline for Requirement records.
/// Executes completely outside of widget build() methods.
class RequirementFilterEngine {
  static bool _matchStatus(String rStatus, String mappedStatus, String selected) {
    if (selected == 'All' || selected.isEmpty) return true;
    final sel = selected.trim().toLowerCase();
    final rSt = rStatus.trim().toLowerCase();
    final mSt = mappedStatus.trim().toLowerCase();

    if (sel == rSt || sel == mSt) return true;

    final selNorm = sel.replaceAll(RegExp(r'[\s\-_]'), '');
    final rStNorm = rSt.replaceAll(RegExp(r'[\s\-_]'), '');
    final mStNorm = mSt.replaceAll(RegExp(r'[\s\-_]'), '');
    if (selNorm == rStNorm || selNorm == mStNorm) return true;

    // Assigned to Sales / Assigned
    if (sel == 'assigned' || sel == 'assigned to sales') {
      return rSt == 'assigned' ||
          rSt == 'assigned to sales' ||
          mSt == 'assigned' ||
          mSt == 'assigned to sales';
    }

    // Site Visit Done
    if (sel == 'site visit done') {
      return rSt == 'site visit done' || mSt == 'site visit done';
    }

    // Site Visit Sche. / Site Visit Scheduled / Site Visit
    if (sel == 'site visit' || sel == 'site visit sche.' || sel == 'site visit scheduled') {
      if (rSt == 'site visit done' || mSt == 'site visit done') return false;
      return rSt.startsWith('site visit') || mSt.startsWith('site visit');
    }

    // Call Attempted
    if (sel == 'call attempted') {
      return rSt.startsWith('call attempted') || mSt.startsWith('call attempted');
    }

    // Won / Closed
    if (sel == 'won' || sel == 'closed') {
      return rSt == 'won' || rSt == 'closed' || rSt == 'deal won' || mSt == 'won' || mSt == 'closed';
    }

    // Interested / Active / Live
    if (sel == 'interested') {
      return rSt == 'interested' || rSt == 'active' || rSt == 'live' || mSt == 'interested';
    }

    // Negotiation
    if (sel == 'negotiation') {
      return rSt.contains('negotiat') || mSt.contains('negotiat');
    }

    // Not Started
    if (sel == 'not started') {
      return rSt == 'not started' || mSt == 'not started';
    }

    // New
    if (sel == 'new') {
      return mSt == 'new' || rSt == 'new';
    }

    // Rejected
    if (sel == 'rejected') {
      return rSt.startsWith('rejected') || mSt.startsWith('rejected');
    }

    return false;
  }

  static List<RequirementListItemViewModel> filterAndSort({
    required List<RequirementListItemViewModel> items,
    UserModel? currentUser,
    String activeMainTab = 'Leads',
    String activeListingTab = 'Rent',
    String? selectedCategoryId,
    Set<String> selectedConfigIds = const {},
    String selectedStatus = 'All',
    String salesLeadGroupFilter = 'assigned',
    String selectedSalesFilterId = 'All',
    Set<String> selectedTelecallerFilterIds = const {},
    String selectedReadiness = 'All',
    String searchQuery = '',
    LeadDateFilterPreset datePreset = LeadDateFilterPreset.allTime,
    DateTime? customStartDate,
    DateTime? customEndDate,
    List<users_model.UserModel> knownUsers = const [],
    Set<String>? unassignedLeadIds,
    PropertyMetadataModel? metadata,
  }) {
    if (items.isEmpty) return const [];

    // Pre-calculate date boundaries ONCE outside the loop
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final yestStart = todayStart.subtract(const Duration(days: 1));
    final yestEnd = DateTime(yestStart.year, yestStart.month, yestStart.day, 23, 59, 59, 999);
    final last7Start = todayStart.subtract(const Duration(days: 6));
    final monthStart = DateTime(now.year, now.month, 1);

    DateTime? customStart;
    DateTime? customEnd;
    if (datePreset == LeadDateFilterPreset.customRange &&
        customStartDate != null &&
        customEndDate != null) {
      customStart = DateTime(customStartDate.year, customStartDate.month, customStartDate.day);
      customEnd = DateTime(customEndDate.year, customEndDate.month, customEndDate.day, 23, 59, 59, 999);
    }

    // Pre-resolve selected sales user ONCE outside the loop
    final bool salesFilterActive = selectedSalesFilterId != "All" && selectedSalesFilterId.isNotEmpty;
    final bool telecallerFilterActive = selectedTelecallerFilterIds.isNotEmpty;
    final bool userFilterActive = salesFilterActive || telecallerFilterActive;

    users_model.UserModel? selectedSales;
    if (salesFilterActive) {
      selectedSales = knownUsers.firstWhereOrNull((u) => u.id == selectedSalesFilterId);
    }

    List<users_model.UserModel> selectedTelecallers = const [];
    if (telecallerFilterActive) {
      selectedTelecallers = knownUsers.where((u) => selectedTelecallerFilterIds.contains(u.id)).toList();
    }

    // Pre-resolve selected category name
    String? selectedCategoryName;
    if (selectedCategoryId != null && selectedCategoryId.isNotEmpty && metadata != null) {
      final cat = metadata.categories.firstWhereOrNull((c) => c.id == selectedCategoryId);
      if (cat != null) {
        selectedCategoryName = cat.name.trim().toLowerCase();
      }
    }

    // Pre-resolve selected configuration & property type names
    final Set<String> selectedConfigNames = {};
    final Set<String> selectedTypeNames = {};
    if (selectedConfigIds.isNotEmpty && metadata != null) {
      for (final cfg in metadata.configurations) {
        if (selectedConfigIds.contains(cfg.id) || selectedConfigIds.contains(cfg.name)) {
          selectedConfigNames.add(cfg.name.trim().toLowerCase());
        }
      }
      for (final t in metadata.types) {
        if (selectedConfigIds.contains(t.id) || selectedConfigIds.contains(t.name)) {
          selectedTypeNames.add(t.name.trim().toLowerCase());
        }
      }
    }

    final query = searchQuery.trim().toLowerCase();
    final bool hasSearch = query.isNotEmpty;

    final String userRole = currentUser?.role.trim().toLowerCase() ?? '';
    final bool isSuperAdmin = userRole == 'super admin';
    final bool isAdmin = userRole == 'admin' || isSuperAdmin;
    final bool isSales = userRole == 'sales' || userRole == 'salesperson' || userRole == 'employee' || userRole == 'broker' || RoleGuard.isSales(userRole);
    final bool isTelecaller = userRole == 'telecaller' || RoleGuard.isTelecaller(userRole);

    final bool isWonTab = activeMainTab == 'My Won' || activeMainTab == 'Won';
    final bool isRejectedTab = activeMainTab == 'Rejected';
    final bool isLeadsAddedByMe = activeMainTab == 'Leads Added by Me';

    final bool viewAllRejected = isRejectedTab && (currentUser == null || isAdmin);

    final bool unassignFilter = !viewAllRejected &&
        !isWonTab &&
        selectedStatus == 'Unassign' &&
        (currentUser == null || isAdmin);

    final filtered = <RequirementListItemViewModel>[];

    for (int i = 0; i < items.length; i++) {
      final vm = items[i];
      final r = vm.requirement;

      // 1. Leads Added by Me check
      if (isLeadsAddedByMe) {
        if (currentUser == null || !RequirementListItemViewModel._checkUserCreator(r, currentUser)) {
          continue;
        }
      }

      // 2. Authoritative RBAC Scoping
      if (currentUser != null) {
        if (isSales) {
          // SALES USER: STRICTLY CAN ONLY SEE LEADS ASSIGNED TO THEM
          if (RequirementListItemViewModel._checkLeadTransferredAway(r, currentUser)) {
            continue;
          }
          final canView = RequirementListItemViewModel._checkUserCreator(r, currentUser) ||
              RequirementListItemViewModel._checkUserAssignee(r, currentUser);
          if (!canView) continue;

          if (activeMainTab == 'Leads') {
            if (salesLeadGroupFilter == 'assigned') {
              final isAssigned = RequirementListItemViewModel._checkUserAssignee(r, currentUser);
              final isCreator = RequirementListItemViewModel._checkUserCreator(r, currentUser);
              if (!isAssigned || isCreator) continue;
            } else if (salesLeadGroupFilter == 'added') {
              if (!RequirementListItemViewModel._checkUserCreator(r, currentUser)) continue;
            }
          }
        } else if (isTelecaller) {
          // TELECALLER USER: CAN ONLY SEE LEADS OF ITSELF ASSIGNED TO SALES
          final canView = TeamUserVisibility.telecallerLeadSentToSalesperson(r, null, currentUser);
          if (!canView) continue;
        } else if (isAdmin) {
          // ADMIN / SUPER ADMIN: CAN SEE ALL LEADS IN ORGANIZATION
        } else {
          // DEFAULT-DENY: ANY UNRECOGNIZED CALLER GETS ZERO LEADS
          continue;
        }
      }

      // 4. Listing tab match
      if (vm.listingTypeLabel != activeListingTab) continue;

      // 5. Category filter
      if (selectedCategoryId != null && selectedCategoryId.isNotEmpty) {
        final matchesCatId = r.categoryId == selectedCategoryId;
        final matchesCatName = selectedCategoryName != null &&
            r.categoryName.trim().toLowerCase() == selectedCategoryName;
        if (!matchesCatId && !matchesCatName) continue;
      }

      // 6. Config / BHK / Spec filter
      if (selectedConfigIds.isNotEmpty) {
        final rConfigName = (r.configurationName ?? '').trim().toLowerCase();
        final rTypeName = r.propertyTypeName.trim().toLowerCase();
        final matchesSpec = selectedConfigIds.contains(r.configurationId) ||
            selectedConfigIds.contains(r.propertyTypeId) ||
            r.configurationIds.any((id) => selectedConfigIds.contains(id)) ||
            r.propertyTypeIds.any((id) => selectedConfigIds.contains(id)) ||
            (rConfigName.isNotEmpty && selectedConfigNames.contains(rConfigName)) ||
            (rTypeName.isNotEmpty && selectedTypeNames.contains(rTypeName)) ||
            selectedConfigIds.any((id) {
              final idLower = id.trim().toLowerCase();
              return idLower == rConfigName || idLower == rTypeName;
            });
        if (!matchesSpec) continue;
      }

      // 7. Tab vs Status logic
      final mappedStatus = vm.mappedStatus;
      if (isWonTab) {
        if (!vm.isWon && mappedStatus != 'Won' && r.status != 'Won' && r.status != 'Closed') {
          continue;
        }
      } else if (isRejectedTab) {
        if (!vm.isRejected) continue;
      } else if (activeMainTab == 'Leads') {
        if (selectedStatus != 'Rejected' && vm.isRejected) continue;
        if (vm.isWon || mappedStatus == 'Won' || r.status == 'Won' || r.status == 'Closed') {
          if (selectedStatus != 'Won') continue;
        }
      }

      // Exclude Won requirements from active Leads unless viewing Won
      if (!isLeadsAddedByMe &&
          !isWonTab &&
          !userFilterActive &&
          selectedStatus != 'Won' &&
          !unassignFilter &&
          mappedStatus == 'Won') {
        continue;
      }

      // 8. Status match
      if (isWonTab || isRejectedTab || viewAllRejected) {
        // Handled above
      } else if (unassignFilter) {
        if (unassignedLeadIds != null) {
          if (!unassignedLeadIds.contains(r.id)) continue;
        } else {
          final assigned = (r.assignedTo ?? '').trim().toLowerCase();
          final name = (r.assigneeName ?? '').trim().toLowerCase();
          final isUnassigned = assigned.isEmpty || assigned == 'unassigned' || name == 'unassigned';
          if (!isUnassigned) continue;
        }
      } else if (selectedStatus != "All") {
        if (!_matchStatus(r.status, mappedStatus, selectedStatus)) {
          continue;
        }
      }

      // 9. Sales & Telecaller filters
      if (!isLeadsAddedByMe && userFilterActive) {
        if (salesFilterActive) {
          bool matchesSales = false;
          if (selectedSales != null) {
            matchesSales = (isTelecaller || (currentUser != null && currentUser.role == 'Telecaller'))
                ? TeamUserVisibility.telecallerLeadSentToSalesperson(r, selectedSales, currentUser)
                : TeamUserVisibility.requirementBelongsToUser(r, selectedSales);
          } else {
            matchesSales = r.assignedTo == selectedSalesFilterId || r.createdBy == selectedSalesFilterId;
          }
          if (!matchesSales) continue;

          if (activeMainTab == 'Leads' && salesLeadGroupFilter != 'all') {
            final salesRole = selectedSales?.roleName ?? '';
            if (salesRole.toLowerCase().contains('sales') || selectedSales == null) {
              if (salesLeadGroupFilter == 'assigned') {
                final isAssigned = selectedSales != null
                    ? (RequirementListItemViewModel._checkUserAssignee(r, selectedSales) &&
                        !RequirementListItemViewModel._checkUserCreator(r, selectedSales))
                    : (r.assignedTo == selectedSalesFilterId && r.createdBy != selectedSalesFilterId);
                if (!isAssigned) continue;
              } else if (salesLeadGroupFilter == 'added') {
                final isCreator = selectedSales != null
                    ? RequirementListItemViewModel._checkUserCreator(r, selectedSales)
                    : (r.createdBy == selectedSalesFilterId);
                if (!isCreator) continue;
              }
            }
          }
        }

        if (telecallerFilterActive) {
          bool matchesTelecaller = false;
          if (selectedTelecallers.isNotEmpty) {
            matchesTelecaller = selectedTelecallers.any(
              (tc) => TeamUserVisibility.requirementBelongsToUser(r, tc),
            );
          }
          if (!matchesTelecaller) {
            matchesTelecaller = selectedTelecallerFilterIds.contains(r.assignedTelecallerId) ||
                selectedTelecallerFilterIds.contains(r.createdBy) ||
                selectedTelecallerFilterIds.contains(r.assignedTo) ||
                (r.metaCustomFields != null &&
                    (selectedTelecallerFilterIds.contains(r.metaCustomFields!['telecaller_id']) ||
                        selectedTelecallerFilterIds.contains(r.metaCustomFields!['assigned_telecaller_id']) ||
                        selectedTelecallerFilterIds.contains(r.metaCustomFields!['telecaller_by_id']) ||
                        selectedTelecallerFilterIds.contains(r.metaCustomFields!['telecaller_by'])));
          }
          if (!matchesTelecaller) continue;
        }
      }

      // 10. Search query
      if (hasSearch) {
        final queryTokens = query.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
        bool matchesSalesman(String token) {
          if (isAdmin || (currentUser != null &&
              (currentUser.role == 'Admin' || currentUser.role == 'Super Admin' || currentUser.role == 'Telecaller'))) {
            return vm.creatorNameLower.contains(token) || vm.assigneeNameLower.contains(token);
          }
          return false;
        }

        final matchesSearch = queryTokens.every((token) =>
            vm.clientNameLower.contains(token) ||
            vm.clientMobileLower.contains(token) ||
            vm.normalizedSearchTokens.contains(token) ||
            matchesSalesman(token));
        if (!matchesSearch) continue;
      }

      // 11. Readiness
      if (selectedReadiness != "All") {
        if (selectedReadiness == "Needs Details") {
          if (vm.matchingReadiness == 'Ready') continue;
        } else {
          if (vm.matchingReadiness != selectedReadiness) continue;
        }
      }

      // 12. Date filter
      final dt = isRejectedTab ? vm.filterDate : vm.requirement.createdAt.toLocal();
      bool matchesDate = true;
      switch (datePreset) {
        case LeadDateFilterPreset.today:
          matchesDate = !dt.isBefore(todayStart) && !dt.isAfter(todayEnd);
          break;
        case LeadDateFilterPreset.yesterday:
          matchesDate = !dt.isBefore(yestStart) && !dt.isAfter(yestEnd);
          break;
        case LeadDateFilterPreset.last7Days:
          matchesDate = !dt.isBefore(last7Start) && !dt.isAfter(todayEnd);
          break;
        case LeadDateFilterPreset.thisMonth:
          matchesDate = !dt.isBefore(monthStart) && !dt.isAfter(todayEnd);
          break;
        case LeadDateFilterPreset.customRange:
          if (customStart != null && customEnd != null) {
            matchesDate = !dt.isBefore(customStart) && !dt.isAfter(customEnd);
          }
          break;
        case LeadDateFilterPreset.allTime:
          matchesDate = true;
          break;
      }
      if (!matchesDate) continue;

      filtered.add(vm);
    }

    // Sort: Rejected tab uses sortDateMillis (rejectedAt ?? salesAssignedAt ?? createdAt)
    // Other tabs use normalSortDateMillis (salesAssignedAt ?? createdAt)
    if (isRejectedTab) {
      filtered.sort((a, b) => b.sortDateMillis.compareTo(a.sortDateMillis));
    } else {
      filtered.sort((a, b) => b.normalSortDateMillis.compareTo(a.normalSortDateMillis));
    }

    return filtered;
  }
}

import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/design_system/mobile/mobile_screen.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/network/sync_manager.dart';
import '../../../core/security/permission_matrix_service.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/storage/local_repositories.dart';
import '../../../core/storage/model_mappers.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../../core/utils/currency.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart' as auth_model;
import '../../requirements/models/requirement_model.dart';
import '../../requirements/services/requirements_service.dart';
import '../../users/models/user_model.dart' as user_settings_model;
import '../../users/repository/users_repository.dart';
import '../models/property_model.dart';
import '../services/properties_service.dart';
import '../widgets/recycle_bin/recycle_bin_tokens.dart';
import '../widgets/recycle_bin/recycle_bin_widgets.dart';

class RecycleBinScreen extends StatefulWidget {
  /// Set by a search link: 'properties' or 'requirements'.
  final String? initialTab;
  /// Set by a search link: 'rent' or 'resale'.
  final String? initialListing;
  final String? initialSearch;
  /// Changes on every search link, so opening the same record twice still applies it.
  final String? linkStamp;

  const RecycleBinScreen({
    super.key,
    this.initialTab,
    this.initialListing,
    this.initialSearch,
    this.linkStamp,
  });

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RestoredSessionItem {
  final String id;
  final String name;
  final String kind; // prop | lead

  const _RestoredSessionItem({
    required this.id,
    required this.name,
    required this.kind,
  });
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  final PropertiesService _propertiesService = PropertiesService();
  final RequirementsService _requirementsService = RequirementsService();

  bool _isLoading = true;
  /// HTML kind: Properties (`prop`) or Leads (`lead`).
  String _kind = 'prop';
  /// Rent | Re-sale | All
  String _typeFilter = 'Rent';
  /// list | req | ni  (leads only)
  String _leadKind = 'list';
  int _autoDeleteDays = 30;

  List<PropertyModel> _binProperties = [];
  List<RequirementModel> _binRequirements = [];
  List<RequirementModel> _notInterestedRequirements = [];
  final Map<String, String> _binDeletedFrom = {};
  final Map<String, DateTime> _deletedAtById = {};
  final Map<String, user_settings_model.UserModel> _usersMap = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _serverPropertySearch;
  String? _serverRequirementSearch;
  int _binSearchRequest = 0;
  Timer? _binSearchDebounce;
  StreamSubscription<Set<String>>? _binRefreshSub;

  int _perPage = 15;
  int _currentPage = 1;

  final Set<String> _selectedIds = {};
  final List<_RestoredSessionItem> _restoredSession = [];

  late String _binActionSignature;

  bool _can(String key) => RoleGuard.canAction(key);

  String _currentBinActionSignature() => PermissionMatrixService.adminActionKeys
      .where((k) => k.startsWith('page.recycle_bin.'))
      .map((k) => _can(k) ? '1' : '0')
      .join();

  void _onBinActionPermissionsChanged() {
    final next = _currentBinActionSignature();
    if (next == _binActionSignature || !mounted) return;
    setState(() => _binActionSignature = next);
  }

  bool _isRentProperty(PropertyModel p) {
    final typeName = p.listingTypeName.toLowerCase();
    if (typeName.contains('re-sale') || typeName.contains('resale') || typeName.contains('sell') || typeName.contains('sale')) {
      return false;
    }
    if (typeName.contains('rent')) return true;
    final lookupName = LookupLocalRepository.getLookupNameSync(p.listingTypeId)?.toLowerCase() ?? '';
    if (lookupName.contains('re-sale') || lookupName.contains('resale') || lookupName.contains('sell') || lookupName.contains('sale')) {
      return false;
    }
    if (lookupName.contains('rent')) return true;
    return false;
  }

  bool _isRentRequirement(RequirementModel r) {
    final typeName = (r.listingTypeName ?? '').toLowerCase();
    if (typeName.contains('re-sale') || typeName.contains('resale') || typeName.contains('sell') || typeName.contains('sale')) {
      return false;
    }
    if (typeName.contains('rent')) return true;
    final lookupName = LookupLocalRepository.getLookupNameSync(r.listingTypeId ?? '')?.toLowerCase() ?? '';
    if (lookupName.contains('re-sale') || lookupName.contains('resale') || lookupName.contains('sell') || lookupName.contains('sale')) {
      return false;
    }
    if (lookupName.contains('rent')) return true;
    return false;
  }

  bool _matchesTypeProperty(PropertyModel p) {
    if (_typeFilter == 'All') return true;
    return _typeFilter == 'Rent' ? _isRentProperty(p) : !_isRentProperty(p);
  }

  bool _matchesTypeRequirement(RequirementModel r) {
    if (_typeFilter == 'All') return true;
    return _typeFilter == 'Rent' ? _isRentRequirement(r) : !_isRentRequirement(r);
  }

  bool _isListingLead(RequirementModel r) =>
      _binDeletedFrom[r.id] == RecycleBinSource.campaignPropertyListing;

  List<PropertyModel> get _visibleBinProperties =>
      _binProperties.where(_matchesTypeProperty).where(_propertyMatchesSearch).toList();

  List<RequirementModel> get _binListingLeads =>
      _binRequirements.where(_isListingLead).where(_matchesTypeRequirement).where(_requirementMatchesSearch).toList();

  List<RequirementModel> get _binRequirementLeads =>
      _binRequirements.where((r) => !_isListingLead(r)).where(_matchesTypeRequirement).where(_requirementMatchesSearch).toList();

  List<RequirementModel> get _visibleNotInterested =>
      _notInterestedRequirements.where(_matchesTypeRequirement).where(_requirementMatchesSearch).toList();

  List<RequirementModel> get _visibleLeads {
    switch (_leadKind) {
      case 'list':
        return _binListingLeads;
      case 'ni':
        return _visibleNotInterested;
      default:
        return _binRequirementLeads;
    }
  }

  bool _propertyMatchesSearch(PropertyModel p) {
    final q = _searchQuery;
    if (q.isEmpty || _serverPropertySearch == q) return true;
    final haystack = [
      p.propertyCode,
      p.title,
      p.ownerName,
      p.ownerMobile,
      p.areaName,
      p.cityName,
      p.address,
      p.createdByName,
      p.propertyTypeName,
      p.configurationName ?? '',
      p.listingTypeName,
      CRMCurrencyFormatter.formatShort(p.price),
      p.price.toString(),
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  bool _requirementMatchesSearch(RequirementModel r) {
    final q = _searchQuery;
    if (q.isEmpty || _serverRequirementSearch == q) return true;
    final salesperson = r.creatorName ?? r.assigneeName ?? '';
    final mappedUser = r.assignedTo != null ? _usersMap[r.assignedTo]?.fullName ?? '' : '';
    final haystack = [
      r.clientName,
      r.clientMobile,
      r.propertyTypeName,
      r.configurationName ?? '',
      r.listingTypeName ?? '',
      r.areaNames.join(' '),
      salesperson,
      mappedUser,
      r.creatorMobile ?? '',
      r.creatorEmail ?? '',
      r.remarks ?? '',
      CRMCurrencyFormatter.formatShort(r.minBudget),
      CRMCurrencyFormatter.formatShort(r.maxBudget),
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  int _daysLeft(String id) {
    final deletedAt = _deletedAtById[id];
    if (deletedAt == null) return _autoDeleteDays;
    final elapsed = DateTime.now().difference(deletedAt).inDays;
    final left = _autoDeleteDays - elapsed;
    return left < 0 ? 0 : left;
  }

  DateTime? _parseDeletedAt(dynamic raw) {
    if (raw is! Map) return null;
    final str = raw['deleted_at'] ?? raw['deletedAt'] ?? raw['updated_at'] ?? raw['updatedAt'];
    if (str == null) return null;
    return DateTime.tryParse(str.toString());
  }

  @override
  void initState() {
    super.initState();
    _binActionSignature = _currentBinActionSignature();
    PermissionMatrixService.instance.addListener(_onBinActionPermissionsChanged);
    _binRefreshSub = SyncManager().tableChanges.listen((tables) {
      if (!mounted) return;
      if (tables.contains('properties') || tables.contains('requirements')) {
        _fetchAllBinData();
      }
    });
    _loadAutoDeleteDays();
    _applySearchLink();
    _fetchAllBinData();
  }

  @override
  void didUpdateWidget(covariant RecycleBinScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed = widget.linkStamp != oldWidget.linkStamp ||
        widget.initialSearch != oldWidget.initialSearch ||
        widget.initialTab != oldWidget.initialTab ||
        widget.initialListing != oldWidget.initialListing;
    if (!changed) return;
    var applied = false;
    setState(() => applied = _applySearchLink());
    if (applied) _fetchAllBinData();
  }

  bool _applySearchLink() {
    final tab = widget.initialTab?.trim().toLowerCase() ?? '';
    final search = widget.initialSearch?.trim() ?? '';
    if (tab.isEmpty && search.isEmpty) return false;
    final listing = widget.initialListing?.trim().toLowerCase() ?? '';
    final listingTab = listing == 'rent'
        ? 'Rent'
        : listing == 'resale'
            ? 'Re-sale'
            : null;
    if (tab == 'properties') {
      _kind = 'prop';
      if (listingTab != null) _typeFilter = listingTab;
    } else if (tab == 'requirements') {
      _kind = 'lead';
      _leadKind = 'req';
      if (listingTab != null) _typeFilter = listingTab;
    }
    if (search.isNotEmpty) {
      _searchController.text = search;
      _searchQuery = search.toLowerCase();
    }
    _currentPage = 1;
    _selectedIds.clear();
    return true;
  }

  @override
  void dispose() {
    PermissionMatrixService.instance.removeListener(_onBinActionPermissionsChanged);
    _binSearchDebounce?.cancel();
    _binRefreshSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAutoDeleteDays() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _autoDeleteDays = prefs.getInt('auto_delete_days') ?? 30);
  }

  Future<void> _saveAutoDeleteDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_delete_days', days);
    if (!mounted) return;
    setState(() => _autoDeleteDays = days);
  }

  Future<void> _fetchAllBinData() async {
    final request = ++_binSearchRequest;
    final query = _searchQuery;
    setState(() {
      _isLoading = true;
      _currentPage = 1;
    });

    try {
      if (_usersMap.isEmpty) {
        try {
          final usersList = await UsersRepository().getUsers();
          for (final u in usersList) {
            _usersMap[u.id] = u;
          }
        } catch (_) {}
      }

      final results = await Future.wait([
        _propertiesService.getBinProperties(search: query),
        _requirementsService.getBinRequirements(search: query),
        _requirementsService.getRequirements(status: 'Not Interested'),
      ]);

      if (!mounted || request != _binSearchRequest) return;

      final propRes = results[0];
      final reqRes = results[1];
      final niRes = results[2];

      final propList = (propRes['data'] as Map<String, dynamic>? ?? {})['properties'] as List? ?? [];
      final reqList = (reqRes['data'] as Map<String, dynamic>? ?? {})['requirements'] as List? ?? [];
      final niList = (niRes['data'] as Map<String, dynamic>? ?? {})['requirements'] as List? ?? [];

      propList.sort(_compareDeletedDesc);
      reqList.sort(_compareDeletedDesc);
      niList.sort(_compareDeletedDesc);

      final deletedAt = <String, DateTime>{};
      for (final raw in [...propList, ...reqList, ...niList]) {
        final id = raw is Map ? raw['id']?.toString() : null;
        final at = _parseDeletedAt(raw);
        if (id != null && at != null) deletedAt[id] = at;
      }

      final deletedFrom = <String, String>{
        for (final raw in reqList)
          if (raw is Map && raw['id'] != null && (raw['deleted_from'] ?? '').toString().isNotEmpty)
            raw['id'].toString(): raw['deleted_from'].toString(),
      };

      var parsedReqs = reqList.map((r) => RequirementModel.fromJson(r)).toList();
      var parsedNi = niList.map((r) => RequirementModel.fromJson(r)).toList();
      parsedReqs = _filterRequirementsForRole(parsedReqs);
      parsedNi = _filterRequirementsForRole(parsedNi);

      setState(() {
        _binProperties = propList.map((p) => PropertyModel.fromJson(p)).toList();
        _binRequirements = parsedReqs;
        _notInterestedRequirements = parsedNi;
        _binDeletedFrom
          ..clear()
          ..addAll(deletedFrom);
        _deletedAtById
          ..clear()
          ..addAll(deletedAt);
        _serverPropertySearch = query;
        _serverRequirementSearch = query;
        _isLoading = false;
        _selectedIds.removeWhere(
          (id) =>
              !_binProperties.any((p) => p.id == id) &&
              !_binRequirements.any((r) => r.id == id) &&
              !_notInterestedRequirements.any((r) => r.id == id),
        );
      });
    } catch (e) {
      if (!mounted || request != _binSearchRequest) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load recycle bin: $e'), backgroundColor: CRMColors.danger),
      );
    }
  }

  int _compareDeletedDesc(dynamic a, dynamic b) {
    DateTime dateA = DateTime.fromMillisecondsSinceEpoch(0);
    DateTime dateB = DateTime.fromMillisecondsSinceEpoch(0);
    final parsedA = _parseDeletedAt(a);
    final parsedB = _parseDeletedAt(b);
    if (parsedA != null) dateA = parsedA;
    if (parsedB != null) dateB = parsedB;
    return dateB.compareTo(dateA);
  }

  List<RequirementModel> _filterRequirementsForRole(List<RequirementModel> parsedList) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return parsedList;
    final currentUser = authState.user;

    final role = currentUser.role;
    final uName = currentUser.fullName.trim().toLowerCase();
    final currentUserId = currentUser.id;
    final currentAdminId = currentUser.adminId;

    if (role == 'Admin') {
      return parsedList.where((r) {
        final isCreator = r.createdBy == currentUserId ||
            (r.createdBy != null && uName.isNotEmpty && r.createdBy!.trim().toLowerCase() == uName) ||
            (r.creatorName != null && uName.isNotEmpty && r.creatorName!.trim().toLowerCase() == uName);
        return isCreator || r.adminId == currentUserId;
      }).toList();
    }
    if (role == 'Telecaller') {
      return parsedList.where((r) {
        final isCreator = r.createdBy == currentUserId ||
            (r.createdBy != null && uName.isNotEmpty && r.createdBy!.trim().toLowerCase() == uName) ||
            (r.creatorName != null && uName.isNotEmpty && r.creatorName!.trim().toLowerCase() == uName);
        return isCreator || r.adminId == currentAdminId;
      }).toList();
    }
    if (role != 'Super Admin') {
      return parsedList.where((r) {
        final isCreator = r.createdBy == currentUserId ||
            (r.createdBy != null && uName.isNotEmpty && r.createdBy!.trim().toLowerCase() == uName) ||
            (r.creatorName != null && uName.isNotEmpty && r.creatorName!.trim().toLowerCase() == uName);
        final isAssignee = (r.assignedTo != null &&
                (r.assignedTo == currentUserId || (uName.isNotEmpty && r.assignedTo!.trim().toLowerCase() == uName))) ||
            (r.assigneeName != null && uName.isNotEmpty && r.assigneeName!.trim().toLowerCase() == uName);
        return isCreator || isAssignee;
      }).toList();
    }
    return parsedList;
  }

  Future<void> _restoreProperty(String id) async {
    final item = _binProperties.firstWhereOrNull((p) => p.id == id);
    setState(() {
      _binProperties.removeWhere((p) => p.id == id);
      _selectedIds.remove(id);
      if (item != null) {
        _restoredSession.insert(
          0,
          _RestoredSessionItem(id: item.propertyCode.isNotEmpty ? item.propertyCode : id, name: item.title, kind: 'prop'),
        );
      }
    });

    if (item != null) {
      try {
        final restoredItem = item.copyWith(portalStatus: 'Active');
        await RepositoryCoordinator().propertyLocal.saveProperties([restoredItem.toLocal()]);
        RepositoryCoordinator().refreshProperties();
        RepositoryCoordinator().refreshDashboard();
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('↺ Property restored to Properties'),
          backgroundColor: CRMColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      await _propertiesService.restoreProperty(id);
    } catch (e) {
      debugPrint('⚠️ Restore property API error: $e');
    }
  }

  Future<void> _restoreRequirement(RequirementModel r) async {
    final fromBin = _leadKind != 'ni';
    setState(() {
      if (fromBin) {
        _binRequirements.removeWhere((item) => item.id == r.id);
      } else {
        _notInterestedRequirements.removeWhere((item) => item.id == r.id);
      }
      _selectedIds.remove(r.id);
      _restoredSession.insert(
        0,
        _RestoredSessionItem(id: r.id, name: r.clientName, kind: 'lead'),
      );
    });

    final String newStatus = fromBin
        ? r.status
        : (r.status == 'Bin' || r.status.startsWith('Rejected') ? 'Follow-up' : (r.status.isEmpty ? 'Active' : r.status));
    final restoredReq = r.copyWith(status: newStatus);
    try {
      await RepositoryCoordinator().requirementLocal.saveRequirements([restoredReq.toLocal()]);
      RepositoryCoordinator().refreshRequirements();
      RepositoryCoordinator().refreshDashboard();
    } catch (_) {}

    final source = fromBin ? _binDeletedFrom.remove(r.id) : null;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == null
                ? '↺ Lead restored to Leads'
                : '↺ Lead restored to ${RecycleBinSource.label(source)}',
          ),
          backgroundColor: CRMColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    try {
      if (fromBin) {
        await _requirementsService.restoreRequirement(r.id);
      } else {
        await _requirementsService.updateRequirement(r.id, {'status': newStatus});
      }
    } catch (e) {
      debugPrint('⚠️ Restore requirement API error: $e');
    }
  }

  Future<void> _deleteRequirementToBin(RequirementModel r) async {
    setState(() {
      _notInterestedRequirements.removeWhere((item) => item.id == r.id);
      _selectedIds.remove(r.id);
    });
    try {
      await _requirementsService.deleteRequirement(r.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Requirement moved to Recycle Bin'), backgroundColor: CRMColors.success),
        );
      }
      await _fetchAllBinData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete requirement: $e'), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  Future<bool> _confirmDanger({
    required String title,
    required String body,
    required String confirmLabel,
    bool requireDeleteTyped = false,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            final typedOk = !requireDeleteTyped || controller.text.trim().toUpperCase() == 'DELETE';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CRMBorderRadius.dialog)),
              title: Text(title, style: CRMTypography.sectionTitle.copyWith(fontWeight: FontWeight.w700)),
              content: SizedBox(
                width: CRMBreakpoints.adaptiveWidth(ctx, 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(body, style: CRMTypography.body.copyWith(color: RbTokens.ink2(ctx), height: 1.45)),
                    if (requireDeleteTyped) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Type DELETE to confirm',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => setLocal(() {}),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: RbTokens.red),
                  onPressed: typedOk ? () => Navigator.pop(ctx, true) : null,
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    return result == true;
  }

  Future<void> _permanentDeleteProperty(String id) async {
    final ok = await _confirmDanger(
      title: 'Delete for good?',
      body: 'This can’t be undone — the item will not come back to Properties.',
      confirmLabel: 'Delete forever',
    );
    if (!ok) return;

    setState(() {
      _binProperties.removeWhere((p) => p.id == id);
      _selectedIds.remove(id);
    });

    try {
      await RepositoryCoordinator().propertyLocal.deleteProperty(id);
      RepositoryCoordinator().refreshProperties();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑 Property permanently deleted'), backgroundColor: CRMColors.success),
      );
    }

    try {
      await _propertiesService.permanentDeleteProperty(id);
    } catch (e) {
      debugPrint('⚠️ Permanent delete property error: $e');
    }
  }

  Future<void> _permanentDeleteRequirement(String id) async {
    final ok = await _confirmDanger(
      title: 'Delete for good?',
      body: 'This can’t be undone — the item will not come back to Leads.',
      confirmLabel: 'Delete forever',
    );
    if (!ok) return;

    setState(() {
      _binRequirements.removeWhere((r) => r.id == id);
      _notInterestedRequirements.removeWhere((r) => r.id == id);
      _selectedIds.remove(id);
    });

    try {
      await RepositoryCoordinator().requirementLocal.deleteRequirement(id);
      RepositoryCoordinator().refreshRequirements();
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑 Lead permanently deleted'), backgroundColor: CRMColors.success),
      );
    }

    try {
      await _requirementsService.permanentDeleteRequirement(id);
    } catch (e) {
      debugPrint('⚠️ Permanent delete requirement error: $e');
    }
  }

  Future<void> _emptyCurrentBin() async {
    final total = _binProperties.length + _binRequirements.length;
    if (total == 0 && _kind == 'prop') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The bin is already empty')),
      );
      return;
    }

    final ok = await _confirmDanger(
      title: 'Empty the whole bin?',
      body: _kind == 'prop'
          ? 'All deleted properties in the bin will be removed permanently. There’s no undo.'
          : 'All deleted leads in the bin will be removed permanently. There’s no undo.',
      confirmLabel: 'Empty bin',
      requireDeleteTyped: true,
    );
    if (!ok) return;

    try {
      if (_kind == 'prop') {
        await _propertiesService.emptyBin();
      } else {
        await _requirementsService.emptyBin();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🗑 Bin emptied'), backgroundColor: CRMColors.success),
        );
      }
      await _fetchAllBinData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to empty bin: $e'), backgroundColor: CRMColors.danger),
        );
      }
    }
  }

  Future<void> _restoreSelected() async {
    final ids = _selectedIds.toList();
    if (_kind == 'prop') {
      for (final id in ids) {
        await _restoreProperty(id);
      }
    } else {
      final items = _visibleLeads.where((r) => ids.contains(r.id)).toList();
      for (final r in items) {
        if (_leadKind == 'ni') {
          await _restoreRequirement(r);
        } else {
          await _restoreRequirement(r);
        }
      }
    }
  }

  Future<void> _deleteSelectedForever() async {
    final ids = _selectedIds.toList();
    final ok = await _confirmDanger(
      title: 'Delete ${ids.length} item${ids.length == 1 ? '' : 's'} forever?',
      body: 'This can’t be undone.',
      confirmLabel: 'Delete forever',
    );
    if (!ok) return;
    if (_kind == 'prop') {
      for (final id in ids) {
        setState(() {
          _binProperties.removeWhere((p) => p.id == id);
          _selectedIds.remove(id);
        });
        try {
          await RepositoryCoordinator().propertyLocal.deleteProperty(id);
        } catch (_) {}
        try {
          await _propertiesService.permanentDeleteProperty(id);
        } catch (_) {}
      }
      RepositoryCoordinator().refreshProperties();
    } else {
      for (final id in ids) {
        setState(() {
          _binRequirements.removeWhere((r) => r.id == id);
          _notInterestedRequirements.removeWhere((r) => r.id == id);
          _selectedIds.remove(id);
        });
        try {
          await RepositoryCoordinator().requirementLocal.deleteRequirement(id);
        } catch (_) {}
        try {
          await _requirementsService.permanentDeleteRequirement(id);
        } catch (_) {}
      }
      RepositoryCoordinator().refreshRequirements();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑 ${ids.length} item${ids.length == 1 ? '' : 's'} deleted forever'), backgroundColor: CRMColors.success),
      );
    }
  }

  String get _crumbLabel {
    if (_kind == 'prop') {
      return 'Properties · ${_typeFilter == 'All' ? 'All' : _typeFilter}';
    }
    final kindLabel = switch (_leadKind) {
      'list' => 'Property listing',
      'ni' => 'Not Interested',
      _ => 'Requirement',
    };
    return 'Leads · ${_typeFilter == 'All' ? 'All' : _typeFilter} · $kindLabel';
  }

  String get _listTitle {
    if (_kind == 'prop') {
      return 'Deleted properties · ${_typeFilter == 'All' ? 'Rent & re-sale' : _typeFilter}';
    }
    final noun = switch (_leadKind) {
      'list' => 'property listing leads',
      'ni' => 'not interested leads',
      _ => 'requirement leads',
    };
    return 'Deleted $noun · ${_typeFilter == 'All' ? 'Rent & re-sale' : _typeFilter}';
  }

  String get _leadListingSubtitle {
    if (_typeFilter == 'Rent') return 'Owners listing a home for rent';
    if (_typeFilter == 'Re-sale') return 'Owners selling a property';
    return 'Owners listing for rent or re-sale';
  }

  String get _leadRequirementSubtitle {
    if (_typeFilter == 'Rent') return 'Tenants looking for a home';
    if (_typeFilter == 'Re-sale') return 'Buyers looking for a property';
    return 'Tenants and buyers looking for a home';
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    var isAdmin = false;
    auth_model.UserModel? currentUser;
    if (authState is Authenticated) {
      currentUser = authState.user;
      final role = currentUser.role.toLowerCase();
      isAdmin = role == 'admin' || role == 'super admin' || role == 'telecaller';
    }

    final isMobile = CRMBreakpoints.isPhone(context);
    final wide = CRMBreakpoints.widthOf(context) >= 1200;
    final hasData = _kind == 'prop' ? _binProperties.isNotEmpty : (_leadKind == 'ni' ? _notInterestedRequirements.isNotEmpty : _binRequirements.isNotEmpty);

    final body = _buildPageBody(
      context: context,
      isMobile: isMobile,
      wide: wide,
      isAdmin: isAdmin,
      currentUser: currentUser,
      hasData: hasData,
    );

    if (isMobile) {
      return MobileScreenScaffold(
        title: 'Recycle Bin',
        onRefresh: _fetchAllBinData,
        padding: EdgeInsets.all(CRMBreakpoints.pagePadding(context)),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _fetchAllBinData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(CRMBreakpoints.pagePadding(context)),
          child: body,
        ),
      ),
    );
  }

  Widget _buildPageBody({
    required BuildContext context,
    required bool isMobile,
    required bool wide,
    required bool isAdmin,
    required auth_model.UserModel? currentUser,
    required bool hasData,
  }) {
    final listingCount = _binRequirements.where(_isListingLead).where(_matchesTypeRequirement).length;
    final requirementCount = _binRequirements.where((r) => !_isListingLead(r)).where(_matchesTypeRequirement).length;
    final niCount = _notInterestedRequirements.where(_matchesTypeRequirement).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, isMobile: isMobile, isAdmin: isAdmin, hasData: hasData),
        const SizedBox(height: CRMSpacing.m),
        RbInfoBanner(
          autoDeleteDays: _autoDeleteDays,
          countLabel: '${_binProperties.length} properties · ${_binRequirements.length} leads in the bin',
        ),
        const SizedBox(height: CRMSpacing.m),
        _buildTools(context, isMobile: isMobile),
        if (_kind == 'lead') ...[
          const SizedBox(height: CRMSpacing.m),
          RbLeadKindCards(
            selected: _leadKind,
            listingCount: listingCount,
            requirementCount: requirementCount,
            notInterestedCount: niCount,
            listingSubtitle: _leadListingSubtitle,
            requirementSubtitle: _leadRequirementSubtitle,
            onChanged: (v) {
              setState(() {
                _leadKind = v;
                _currentPage = 1;
                _selectedIds.clear();
              });
            },
          ),
        ],
        const SizedBox(height: CRMSpacing.m),
        if (wide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildListPanel(context, currentUser: currentUser)),
              const SizedBox(width: 14),
              SizedBox(width: 330, child: _buildSidebar(context)),
            ],
          )
        else ...[
          _buildListPanel(context, currentUser: currentUser),
          const SizedBox(height: CRMSpacing.m),
          _buildSidebar(context),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, {required bool isMobile, required bool isAdmin, required bool hasData}) {
    final controls = Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: RbTokens.panelBg(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: RbTokens.line(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: RbTokens.muted(context)),
              const SizedBox(width: 8),
              Text('Auto-delete after', style: CRMTypography.caption.copyWith(color: RbTokens.ink2(context))),
              const SizedBox(width: 6),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _autoDeleteDays,
                  isDense: true,
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 days')),
                    DropdownMenuItem(value: 30, child: Text('30 days')),
                    DropdownMenuItem(value: 60, child: Text('60 days')),
                  ],
                  onChanged: !_can('page.recycle_bin.auto_delete')
                      ? null
                      : (v) {
                          if (v == null) return;
                          _saveAutoDeleteDays(v);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Auto-delete period set to $v days'),
                              backgroundColor: CRMColors.success,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
        if (hasData && isAdmin && _can('page.recycle_bin.empty_bin'))
          OutlinedButton.icon(
            onPressed: _emptyCurrentBin,
            icon: const Icon(Icons.delete_forever_rounded, size: 16),
            label: const Text('Empty bin'),
            style: OutlinedButton.styleFrom(
              foregroundColor: RbTokens.red,
              backgroundColor: RbTokens.redBgOf(context),
              side: BorderSide(color: RbTokens.redLineOf(context)),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            style: CRMTypography.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: RbTokens.muted(context)),
            children: [
              const TextSpan(text: 'Recycle Bin / '),
              TextSpan(text: _crumbLabel, style: TextStyle(color: RbTokens.greenTextOf(context), fontWeight: FontWeight.w700)),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          'Recycle Bin',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CRMTypography.pageTitle.copyWith(
            color: RbTokens.ink(context),
            fontWeight: FontWeight.w800,
            fontSize: isMobile ? 24 : 28,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Deleted properties and leads wait here, so nothing is lost by mistake.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: CRMTypography.body.copyWith(color: RbTokens.muted(context), fontSize: 13),
        ),
      ],
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: CRMSpacing.s),
          controls,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        Flexible(child: Align(alignment: Alignment.topRight, child: controls)),
      ],
    );
  }

  Widget _buildTools(BuildContext context, {required bool isMobile}) {
    final search = SizedBox(
      width: isMobile ? double.infinity : 380,
      height: 40,
      child: TextField(
        controller: _searchController,
        style: CRMTypography.body.copyWith(color: RbTokens.ink(context)),
        decoration: InputDecoration(
          hintText: _kind == 'prop'
              ? 'Search code, property name, owner or area'
              : 'Search lead ID, client name, owner or area',
          hintStyle: CRMTypography.caption.copyWith(color: RbTokens.muted(context)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                    });
                    _fetchAllBinData();
                  },
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          filled: true,
          fillColor: RbTokens.panelBg(context),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: RbTokens.line(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: RbTokens.line(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: RbTokens.green),
          ),
        ),
        onChanged: (value) {
          final next = value.trim().toLowerCase();
          setState(() {
            _searchQuery = next;
            _currentPage = 1;
          });
          _binSearchDebounce?.cancel();
          _binSearchDebounce = Timer(const Duration(milliseconds: 250), () {
            if (mounted) _fetchAllBinData();
          });
        },
      ),
    );

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RbKindSegment(
          selected: _kind,
          propertyCount: _binProperties.length,
          leadCount: _binRequirements.length + _notInterestedRequirements.length,
          onChanged: (v) {
            setState(() {
              _kind = v;
              _currentPage = 1;
              _selectedIds.clear();
            });
          },
        ),
        RbTypeChips(
          selected: _typeFilter,
          onChanged: (v) {
            setState(() {
              _typeFilter = v;
              _currentPage = 1;
              _selectedIds.clear();
            });
          },
        ),
        search,
      ],
    );
  }

  Widget _buildListPanel(BuildContext context, {required auth_model.UserModel? currentUser}) {
    final isUserAdminOrSuperAdmin = currentUser != null &&
        (currentUser.role == 'Admin' || currentUser.role == 'Super Admin' || currentUser.role == 'Telecaller');
    final canPermanentlyDeleteProps = currentUser != null &&
        (currentUser.role.toLowerCase() == 'admin' || currentUser.role.toLowerCase() == 'super admin') &&
        _can('page.recycle_bin.properties_delete');

    final itemsProp = _visibleBinProperties;
    final itemsLead = _visibleLeads;
    final totalItems = _kind == 'prop' ? itemsProp.length : itemsLead.length;
    final totalPages = totalItems <= 0 ? 1 : (totalItems / _perPage).ceil();
    final safePage = _currentPage.clamp(1, totalPages);
    final startIndex = (safePage - 1) * _perPage;
    final endIndex = (startIndex + _perPage).clamp(0, totalItems);

    final pageProp = _kind == 'prop' ? itemsProp.sublist(startIndex, endIndex) : const <PropertyModel>[];
    final pageLead = _kind == 'lead' ? itemsLead.sublist(startIndex, endIndex) : const <RequirementModel>[];

    final pageIds = _kind == 'prop' ? pageProp.map((e) => e.id).toList() : pageLead.map((e) => e.id).toList();
    final allSelected = pageIds.isNotEmpty && pageIds.every(_selectedIds.contains);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: RbTokens.panelBg(context),
        borderRadius: BorderRadius.circular(CRMBorderRadius.m),
        border: Border.all(color: RbTokens.line(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _listTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: CRMTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: RbTokens.ink(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Showing ${totalItems == 0 ? 0 : startIndex + 1}–$endIndex of $totalItems',
                        style: CRMTypography.caption.copyWith(color: RbTokens.muted(context)),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: allSelected,
                        onChanged: pageIds.isEmpty
                            ? null
                            : (v) {
                                setState(() {
                                  if (v == true) {
                                    _selectedIds.addAll(pageIds);
                                  } else {
                                    _selectedIds.removeAll(pageIds);
                                  }
                                });
                              },
                        activeColor: RbTokens.green,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Select all',
                      style: CRMTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: RbBulkBar(
              count: _selectedIds.length,
              onClear: () => setState(_selectedIds.clear),
              onRestore: (_kind == 'prop' ? _can('page.recycle_bin.properties_restore') : _can('page.recycle_bin.requirements_restore'))
                  ? _restoreSelected
                  : null,
              onDelete: (_kind == 'prop'
                      ? canPermanentlyDeleteProps
                      : (isUserAdminOrSuperAdmin && _can('page.recycle_bin.requirements_delete') && _leadKind != 'ni'))
                  ? _deleteSelectedForever
                  : (_leadKind == 'ni' && _can('page.recycle_bin.requirements_delete')
                      ? () async {
                          for (final id in _selectedIds.toList()) {
                            final r = _visibleLeads.firstWhereOrNull((e) => e.id == id);
                            if (r != null) await _deleteRequirementToBin(r);
                          }
                        }
                      : null),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (totalItems == 0)
            RbEmptyState(
              noun: _kind == 'prop'
                  ? 'properties'
                  : (_leadKind == 'list'
                      ? 'property listing leads'
                      : (_leadKind == 'ni' ? 'not interested leads' : 'requirement leads')),
              typeLabel: _typeFilter,
            )
          else if (_kind == 'prop')
            ...pageProp.map((p) {
              final days = _daysLeft(p.id);
              final isRent = _isRentProperty(p);
              return RbItemRow(
                selected: _selectedIds.contains(p.id),
                onSelected: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedIds.add(p.id);
                    } else {
                      _selectedIds.remove(p.id);
                    }
                  });
                },
                thumbIcon: Icons.home_rounded,
                tags: [
                  RbBadge(label: p.propertyCode.isEmpty ? p.id : p.propertyCode, mono: true),
                  RbBadge(
                    label: isRent ? 'RENT' : 'RE-SALE',
                    background: RbTokens.green,
                    foreground: Colors.white,
                  ),
                  const RbBadge(label: 'Deleted', background: Color(0xFFFEE2E2), foreground: Color(0xFFB91C1C)),
                  RbBadge(
                    label: '$days days left',
                    background: days <= 7 ? RbTokens.amberBg : const Color(0xFFE5E7EB),
                    foreground: days <= 7 ? RbTokens.amber : RbTokens.ink2(context),
                  ),
                ],
                title: p.title.isNotEmpty ? p.title : 'Property (${p.propertyCode})',
                metaSpans: _metaSpans(context, [
                  ('📍 ', p.areaName.isEmpty ? '—' : p.areaName, false),
                  ('Owner: ', p.ownerName.isEmpty ? '—' : p.ownerName, true),
                  if (isUserAdminOrSuperAdmin) ('Listed by ', p.createdByName.isEmpty ? '—' : p.createdByName, true),
                  if ((p.remarks ?? '').isNotEmpty) ('Reason: ', p.remarks!, false),
                ]),
                price: CRMCurrencyFormatter.formatShort(p.price),
                priceHint: isRent ? 'per month' : 'price',
                canRestore: _can('page.recycle_bin.properties_restore'),
                canDeleteForever: canPermanentlyDeleteProps,
                onRestore: () => _restoreProperty(p.id),
                onDeleteForever: () => _permanentDeleteProperty(p.id),
              );
            })
          else
            ...pageLead.map((r) {
              final days = _daysLeft(r.id);
              final isRent = _isRentRequirement(r);
              final isListing = _leadKind == 'list' || _isListingLead(r);
              final salesperson = r.creatorName ?? r.assigneeName ?? '—';
              final budget = '${CRMCurrencyFormatter.formatShort(r.minBudget)} – ${CRMCurrencyFormatter.formatShort(r.maxBudget)}';
              final config = '${r.configurationName ?? r.propertyTypeName} · $budget';
              final source = _binDeletedFrom[r.id];
              return RbItemRow(
                selected: _selectedIds.contains(r.id),
                onSelected: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedIds.add(r.id);
                    } else {
                      _selectedIds.remove(r.id);
                    }
                  });
                },
                thumbIcon: isListing ? Icons.home_rounded : Icons.vpn_key_rounded,
                tags: [
                  RbBadge(label: r.id.length > 12 ? r.id.substring(0, 12) : r.id, mono: true),
                  RbBadge(
                    label: isRent ? 'RENT' : 'RE-SALE',
                    background: RbTokens.green,
                    foreground: Colors.white,
                  ),
                  RbBadge(
                    label: _leadKind == 'ni' ? 'Not Interested' : 'Deleted',
                    background: const Color(0xFFFEE2E2),
                    foreground: const Color(0xFFB91C1C),
                  ),
                  if (_leadKind != 'ni')
                    RbBadge(
                      label: '$days days left',
                      background: days <= 7 ? RbTokens.amberBg : const Color(0xFFE5E7EB),
                      foreground: days <= 7 ? RbTokens.amber : RbTokens.ink2(context),
                    ),
                  if (source != null) RbBadge(label: RecycleBinSource.label(source)),
                ],
                title: r.clientName.isNotEmpty ? r.clientName : 'Lead',
                metaSpans: _metaSpans(context, [
                  ('📍 ', r.areaNames.isEmpty ? '—' : r.areaNames.join(', '), false),
                  if (isUserAdminOrSuperAdmin) ('Salesperson: ', salesperson, true),
                  ('Source ', (r.leadSource ?? '—'), true),
                  if ((r.rejectionRemark ?? r.remarks ?? '').isNotEmpty)
                    ('Reason: ', r.rejectionRemark ?? r.remarks!, false),
                ]),
                price: config,
                priceHint: isListing ? 'listing' : 'requirement',
                canRestore: _can('page.recycle_bin.requirements_restore'),
                canDeleteForever: _leadKind == 'ni'
                    ? _can('page.recycle_bin.requirements_delete')
                    : (isUserAdminOrSuperAdmin && _can('page.recycle_bin.requirements_delete')),
                restoreLabel: _leadKind == 'ni' ? 'Make active' : 'Restore',
                deleteLabel: _leadKind == 'ni' ? 'Move to bin' : 'Delete forever',
                onRestore: () => _restoreRequirement(r),
                onDeleteForever: _leadKind == 'ni'
                    ? () => _deleteRequirementToBin(r)
                    : () => _permanentDeleteRequirement(r.id),
              );
            }),
          _buildPager(context, totalItems: totalItems, totalPages: totalPages, currentPage: safePage),
        ],
      ),
    );
  }

  List<InlineSpan> _metaSpans(BuildContext context, List<(String, String, bool)> parts) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) {
        spans.add(TextSpan(
          text: '   ',
          style: CRMTypography.caption.copyWith(fontSize: 12, color: RbTokens.muted(context)),
        ));
      }
      final (prefix, value, boldValue) = parts[i];
      spans.add(TextSpan(
        text: prefix,
        style: CRMTypography.caption.copyWith(fontSize: 12, color: RbTokens.muted(context)),
      ));
      spans.add(TextSpan(
        text: value,
        style: CRMTypography.caption.copyWith(
          fontSize: 12,
          color: boldValue ? RbTokens.ink(context) : RbTokens.muted(context),
          fontWeight: boldValue ? FontWeight.w600 : FontWeight.w400,
        ),
      ));
    }
    return spans;
  }

  Widget _buildPager(BuildContext context, {required int totalItems, required int totalPages, required int currentPage}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: RbTokens.pageBg(context),
        border: Border(top: BorderSide(color: RbTokens.line(context))),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            'Page $currentPage of $totalPages · $totalItems items',
            style: CRMTypography.caption.copyWith(fontSize: 12.5, color: RbTokens.muted(context)),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rows', style: CRMTypography.caption.copyWith(color: RbTokens.muted(context))),
              const SizedBox(width: 6),
              DropdownButton<int>(
                value: _perPage,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15')),
                  DropdownMenuItem(value: 30, child: Text('30')),
                  DropdownMenuItem(value: 50, child: Text('50')),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _perPage = v;
                    _currentPage = 1;
                  });
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: currentPage > 1 ? () => setState(() => _currentPage--) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final rentProps = _binProperties.where(_isRentProperty).length;
    final saleProps = _binProperties.length - rentProps;
    final listingLeads = _binRequirements.where(_isListingLead).length;
    final reqLeads = _binRequirements.length - listingLeads;
    final deletingSoon = [..._binProperties.map((p) => p.id), ..._binRequirements.map((r) => r.id)]
        .where((id) => _daysLeft(id) <= 7)
        .length;

    return Column(
      children: [
        RbSidePanel(
          title: 'Restored this session',
          trailing: Text(
            '${_restoredSession.length} item${_restoredSession.length == 1 ? '' : 's'}',
            style: CRMTypography.caption.copyWith(color: RbTokens.muted(context)),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: RbTokens.pageBg(context),
              borderRadius: BorderRadius.circular(9),
            ),
            child: _restoredSession.isEmpty
                ? Text.rich(
                    TextSpan(
                      style: CRMTypography.caption.copyWith(fontSize: 12.5, color: RbTokens.ink2(context), height: 1.4),
                      children: [
                        const TextSpan(text: 'Nothing restored yet. Click '),
                        TextSpan(
                          text: 'Restore',
                          style: TextStyle(color: RbTokens.greenTextOf(context), fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: ' on any item.'),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _restoredSession.take(8).map((x) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text.rich(
                          TextSpan(
                            style: CRMTypography.caption.copyWith(fontSize: 12.5, color: RbTokens.ink2(context)),
                            children: [
                              const TextSpan(text: '✓ '),
                              TextSpan(text: x.id, style: const TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text: ' ${x.name} → back in ${x.kind == 'prop' ? 'Properties' : 'Leads'}'),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        RbSidePanel(
          title: 'Bin settings',
          child: Column(
            children: [
              _settingRow(
                context,
                icon: Icons.schedule_rounded,
                iconBg: RbTokens.violetBg,
                iconColor: RbTokens.violet,
                title: 'Auto-delete after $_autoDeleteDays days',
                subtitle: 'Change it from the menu at the top',
              ),
              const SizedBox(height: 12),
              _settingRow(
                context,
                icon: Icons.replay_rounded,
                iconBg: RbTokens.greenBg,
                iconColor: RbTokens.green,
                title: 'Restore returns it to its list',
                subtitle: 'Find it again under Properties or Leads',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        RbSidePanel(
          title: 'In the bin',
          child: Column(
            children: [
              _sumRow(context, '🏠 Properties · Rent', rentProps),
              _sumRow(context, '🏠 Properties · Re-sale', saleProps),
              _sumRow(context, '🏠 Property listing leads', listingLeads),
              _sumRow(context, '🔑 Requirement leads', reqLeads),
              _sumRow(context, '⏳ Deleting within 7 days', deletingSoon, last: true),
              const SizedBox(height: 8),
              Text(
                'To remove everything now, use Empty bin at the top of the page.',
                style: CRMTypography.caption.copyWith(fontSize: 11.5, color: RbTokens.muted(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingRow(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CRMTypography.bodyMedium.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: CRMTypography.caption.copyWith(fontSize: 12, color: RbTokens.muted(context)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sumRow(BuildContext context, String label, int value, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: RbTokens.line(context), style: BorderStyle.solid)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CRMTypography.caption.copyWith(fontSize: 12.5, color: RbTokens.ink2(context)),
            ),
          ),
          Text(
            '$value',
            style: CRMTypography.captionBold.copyWith(fontSize: 12.5, color: RbTokens.ink(context)),
          ),
        ],
      ),
    );
  }
}

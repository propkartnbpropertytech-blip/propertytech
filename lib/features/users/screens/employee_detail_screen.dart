import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/widgets/dialogs.dart';
import '../../../core/design_system/widgets/app_status_snackbar.dart';
import '../../../core/design_system/widgets/drawers.dart';
import '../../../core/utils/budget_formatter.dart';
import '../../properties/models/property_model.dart';
import '../../properties/repository/properties_repository.dart';
import '../../properties/services/properties_service.dart';
import '../../requirements/models/requirement_model.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../../requirements/services/requirements_service.dart';
import '../bloc/users_bloc.dart';
import '../models/user_model.dart';
import '../utils/employee_activity.dart';
import '../widgets/employee_detail_ui/employee_detail_tokens.dart';
import '../widgets/employee_detail_ui/employee_detail_widgets.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/design_system/tokens/app_breakpoints.dart';
import '../../../core/design_system/mobile/mobile.dart';

enum _LeadFocus { all, won, rejected, followup, overdue, visits, assigned, created }

class EmployeeDetailScreen extends StatefulWidget {
  final String userId;

  const EmployeeDetailScreen({super.key, required this.userId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final _scrollController = ScrollController();
  final _propertiesKey = GlobalKey();
  final _leadsKey = GlobalKey();
  final _teamKey = GlobalKey();

  bool _loadingActivity = true;
  bool _updatingAccess = false;
  bool _removing = false;
  String? _activityError;
  List<PropertyModel> _properties = [];
  List<RequirementModel> _requirements = [];
  List<Map<String, dynamic>>? _followupRows;
  List<Map<String, dynamic>>? _siteVisitRows;
  Map<String, dynamic>? _adminStats;

  String _listingFilter = 'All';
  _LeadFocus _leadFocus = _LeadFocus.all;

  @override
  void initState() {
    super.initState();
    final usersState = context.read<UsersBloc>().state;
    final found = usersState is UsersLoaded &&
        usersState.users.any((u) => u.id == widget.userId);
    if (!found) {
      context.read<UsersBloc>().add(const FetchUsers());
    }
    _loadActivity();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _loadingActivity = true;
      _activityError = null;
    });
    try {
      final results = await Future.wait([
        _fetchLiveProperties(),
        _fetchLiveRequirements(),
      ]);
      final followupRows = await _fetchFollowupRows();
      final siteVisitRows = await _fetchSiteVisitRows();
      Map<String, dynamic>? adminStats;
      try {
        final response =
            await DioClient.dio.get('/users/admins/${widget.userId}/stats');
        final body = response.data;
        if (body is Map && body['success'] == true && body['data'] is Map) {
          adminStats = Map<String, dynamic>.from(body['data'] as Map);
        }
      } catch (_) {
        adminStats = null;
      }
      if (!mounted) return;
      setState(() {
        _properties = results[0] as List<PropertyModel>;
        _requirements = results[1] as List<RequirementModel>;
        _followupRows = followupRows;
        _siteVisitRows = siteVisitRows;
        _adminStats = adminStats;
        _loadingActivity = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activityError = 'Could not load employee activity.';
        _loadingActivity = false;
      });
    }
  }

  Future<List<PropertyModel>> _fetchLiveProperties() async {
    try {
      final response = await PropertiesService().getProperties(
        includeDeleted: false,
      );
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final list = data['properties'] as List? ?? [];
      return list
          .whereType<Map>()
          .map((item) => PropertyModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (_) {
      return PropertiesRepository().getProperties(
        refreshFromServer: true,
        includeDeleted: false,
      );
    }
  }

  Future<List<RequirementModel>> _fetchLiveRequirements() async {
    try {
      final response = await RequirementsService().getRequirements();
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final list = data['requirements'] as List? ?? [];
      return list
          .whereType<Map>()
          .map((item) => RequirementModel.fromJson(Map<String, dynamic>.from(item)))
          .where((r) => r.status.trim().toLowerCase() != 'bin')
          .toList();
    } catch (_) {
      final local = await RequirementsRepository().getRequirements(
        refreshFromServer: true,
      );
      return local
          .where((r) => r.status.trim().toLowerCase() != 'bin')
          .toList();
    }
  }

  Future<void> _setCampaignAccess(UserModel user, bool enabled) async {
    setState(() => _updatingAccess = true);
    try {
      final response = await DioClient.dio.patch(
        '/users/admins/${user.id}/access',
        data: {'campaignEnabled': enabled},
      );
      final body = response.data;
      final ok = body is Map && body['success'] == true;
      if (!mounted) return;
      setState(() {
        _updatingAccess = false;
        if (ok && _adminStats != null) {
          _adminStats = {
            ..._adminStats!,
            'campaignEnabled': enabled,
          };
        }
      });
      if (!mounted) return;
      AppStatusSnackBar.show(
        context,
        message: ok
            ? (enabled
                ? 'Campaign access enabled for this workspace.'
                : 'Campaign access turned off. This admin keeps an empty campaign inbox.')
            : 'Could not update campaign access.',
        isSuccess: ok,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _updatingAccess = false);
      AppStatusSnackBar.show(
        context,
        message: 'Could not update campaign access.',
        isSuccess: false,
      );
    }
  }

  Future<List<Map<String, dynamic>>?> _fetchFollowupRows() async {
    try {
      final response = await DioClient.dio.get('/followups');
      final body = response.data;
      if (body is Map && body['data'] is Map) {
        final list = body['data']['followups'] as List? ?? [];
        return list
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>?> _fetchSiteVisitRows() async {
    try {
      final response = await DioClient.dio.get('/site-visits');
      final body = response.data;
      if (body is Map && body['data'] is Map) {
        final list = body['data']['siteVisits'] as List? ??
            body['data']['site_visits'] as List? ??
            [];
        return list
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}
    return null;
  }

  String? _actorNameFromRow(Map<String, dynamic> row) {
    final creator = row['creator'];
    if (creator is Map) {
      final name = creator['full_name'] ?? creator['fullName'] ?? creator['name'];
      if (name != null) return name.toString();
    }
    return (row['creator_name'] ?? row['creatorName'] ?? row['scheduled_by_name'])
        ?.toString();
  }

  String _actorIdFromRow(Map<String, dynamic> row) {
    for (final key in [
      'created_by',
      'createdBy',
      'scheduled_by',
      'scheduledBy',
    ]) {
      final value = (row[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  bool _rowMatchesSalesUser(Map<String, dynamic> row, UserModel user) {
    return EmployeeActivity.matchesActor(
      user,
      id: _actorIdFromRow(row),
      name: _actorNameFromRow(row),
    );
  }

  String? _requirementIdFromRow(Map<String, dynamic> row) {
    final nested = row['requirement'];
    if (nested is Map && nested['id'] != null) return nested['id'].toString();
    final id = row['requirement_id'] ?? row['requirementId'];
    return id?.toString();
  }

  String? _rowListingBucket(
    Map<String, dynamic> row,
    Map<String, String> listingByReqId,
  ) {
    final reqId = _requirementIdFromRow(row);
    if (reqId != null && reqId.isNotEmpty) {
      final mapped = listingByReqId[reqId];
      if (mapped == 'Rent' || mapped == 'Re-Sale') return mapped;
    }
    final nested = row['requirement'];
    final nestedMap = nested is Map ? nested : null;
    final combined = (
      '${nestedMap?['listing_type_name'] ?? nestedMap?['listingTypeName'] ?? ''} '
      '${nestedMap?['listing_type_id'] ?? nestedMap?['listingTypeId'] ?? ''} '
      '${row['listing_type_name'] ?? row['listingTypeName'] ?? row['listing_type'] ?? ''} '
      '${row['listing_type_id'] ?? row['listingTypeId'] ?? ''}'
    ).toLowerCase();
    if (combined.contains('rent')) return 'Rent';
    if (combined.contains('sale') || combined.contains('resale')) return 'Re-Sale';
    return null;
  }

  bool _rowMatchesListing(
    Map<String, dynamic> row,
    Map<String, String> listingByReqId, {
    String? listing,
  }) {
    final filter = listing ?? _listingFilter;
    final bucket = _rowListingBucket(row, listingByReqId);
    if (bucket == null) return false;
    if (filter == 'All') return bucket == 'Rent' || bucket == 'Re-Sale';
    return bucket == filter;
  }

  List<Map<String, dynamic>> get _followupList =>
      _followupRows ?? const <Map<String, dynamic>>[];

  List<Map<String, dynamic>> get _siteVisitList =>
      _siteVisitRows ?? const <Map<String, dynamic>>[];

  bool _rowOnCurrentSalesLead(Map<String, dynamic> row, UserModel user) {
    final reqId = _requirementIdFromRow(row);
    if (reqId == null || reqId.isEmpty) {
      return _rowMatchesSalesUser(row, user);
    }
    for (final r in _requirements) {
      if (r.id == reqId) {
        if (EmployeeActivity.isWon(r) || EmployeeActivity.isRejected(r)) {
          return false;
        }
        return EmployeeActivity.isSalesOwnedLead(r, user);
      }
    }
    return false;
  }

  bool _rowBelongsToSalesUser(Map<String, dynamic> row, UserModel user) {
    if (_rowMatchesSalesUser(row, user)) return true;
    final reqId = _requirementIdFromRow(row);
    if (reqId != null && reqId.isNotEmpty) {
      for (final r in _requirements) {
        if (r.id == reqId) {
          return EmployeeActivity.isSalesOwnedLead(r, user);
        }
      }
    }
    return false;
  }

  List<Map<String, dynamic>> _salesFollowups(
    UserModel user,
    Map<String, String> listingByReqId, {
    bool currentLeadsOnly = false,
    required String listing,
  }) {
    return _followupList.where((row) {
      final status = (row['status'] ?? '').toString();
      if (EmployeeActivity.isSiteVisitStatus(status)) return false;
      if (!_rowMatchesListing(row, listingByReqId, listing: listing)) {
        return false;
      }
      if (currentLeadsOnly) {
        return _rowOnCurrentSalesLead(row, user);
      }
      return _rowBelongsToSalesUser(row, user);
    }).toList();
  }

  List<Map<String, dynamic>> _salesSiteVisits(
    UserModel user,
    Map<String, String> listingByReqId, {
    bool currentLeadsOnly = false,
    required String listing,
  }) {
    final fromVisits = _siteVisitList.where((row) {
      if (!_rowMatchesListing(row, listingByReqId, listing: listing)) {
        return false;
      }
      if (currentLeadsOnly) {
        return _rowOnCurrentSalesLead(row, user);
      }
      return _rowBelongsToSalesUser(row, user);
    });
    final fromFollowups = _followupList.where((row) {
      final status = (row['status'] ?? '').toString();
      if (!EmployeeActivity.isSiteVisitStatus(status)) return false;
      if (!_rowMatchesListing(row, listingByReqId, listing: listing)) {
        return false;
      }
      if (currentLeadsOnly) {
        return _rowOnCurrentSalesLead(row, user);
      }
      return _rowBelongsToSalesUser(row, user);
    });
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];
    for (final row in [...fromVisits, ...fromFollowups]) {
      final key = (row['id'] ??
              '${row['requirement_id']}-${row['visit_date'] ?? row['followup_date']}-${row['notes'] ?? row['remarks']}')
          .toString();
      if (!seen.add(key)) continue;
      merged.add(row);
    }
    return merged;
  }

  int _totalOverdueCount(List<Map<String, dynamic>> rows) {
    return rows.where((row) {
      final dt = _rowDate(row);
      if (dt == null) return false;
      return EmployeeActivity.isDateBeforeToday(dt);
    }).length;
  }

  DateTime? _rowDate(Map<String, dynamic> row) {
    return EmployeeActivity.tryParseDate(
      (row['followup_date'] ??
              row['followupDate'] ??
              row['visit_date'] ??
              row['visitDate'])
          ?.toString(),
    );
  }

  UserModel? _lastUser;

  UserModel? _userFrom(UsersState state) {
    if (state is UsersLoaded) {
      for (final u in state.users) {
        if (u.id == widget.userId) {
          _lastUser = u;
          return u;
        }
      }
    }
    if (_lastUser?.id == widget.userId) return _lastUser;
    return null;
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.08,
    );
  }

  Future<void> _launchExternal(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      AppStatusSnackBar.show(
        context,
        message: 'Could not open this action.',
        isSuccess: false,
      );
    }
  }

  Future<void> _call(String? mobile) async {
    final clean = (mobile ?? '').replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return;
    await _launchExternal(Uri.parse('tel:$clean'));
  }

  Future<void> _email(String email) async {
    if (email.trim().isEmpty) return;
    await _launchExternal(Uri.parse('mailto:${email.trim()}'));
  }

  Future<void> _whatsapp(String? mobile) async {
    var clean = (mobile ?? '').replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return;
    if (clean.length == 10) clean = '91$clean';
    await _launchExternal(Uri.parse('https://wa.me/$clean'));
  }

  String _formatCreatedDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatFollowup(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CRMColors.backgroundOf(context),
      body: SafeArea(
        child: BlocListener<UsersBloc, UsersState>(
          listener: (context, state) {
            if (state is UsersOperationSuccess) {
              AppStatusSnackBar.show(
                context,
                message: state.message,
                isSuccess: true,
              );
              if (_removing) {
                _removing = false;
                context.go('/users');
                return;
              }
              context.read<UsersBloc>().add(const FetchUsers());
            } else if (state is UsersError) {
              _removing = false;
              AppStatusSnackBar.show(
                context,
                message: state.message,
                isSuccess: false,
              );
            }
          },
          child: BlocBuilder<UsersBloc, UsersState>(
            builder: (context, state) {
              if ((state is UsersLoading || state is UsersInitial) &&
                  _lastUser == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final user = _userFrom(state);
              if (user == null) {
                return _NotFound(onBack: () => context.go('/users'));
              }
              return _buildPage(context, user, state);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    UserModel user,
    UsersState usersState,
  ) {
    final isMobile = CRMBreakpoints.isPhone(context);
    final role = user.roleName.toLowerCase();
    final isAdminRole = role == 'admin' || role == 'super admin';
    final isSalesRole = role == 'sales';
    final isTelecallerRole = role == 'telecaller';

    final allProps = _properties
        .where(
          (p) => isSalesRole
              ? EmployeeActivity.isPropertyAddedBy(p, user)
              : EmployeeActivity.belongsToProperty(p, user),
        )
        .toList();
    final allReqs = _requirements
        .where(
          (r) {
            if (r.status.trim().toLowerCase() == 'bin') return false;
            return isSalesRole
                ? EmployeeActivity.isSalesOwnedLead(r, user)
                : EmployeeActivity.belongsToRequirement(r, user);
          },
        )
        .toList();

    var visibleProps = allProps;
    var visibleReqs = allReqs;
    if (_listingFilter != 'All') {
      visibleProps = allProps
          .where(
            (p) => EmployeeActivity.propertyListingBucket(p) == _listingFilter,
          )
          .toList();
      visibleReqs = allReqs
          .where(
            (r) =>
                EmployeeActivity.requirementListingBucket(r) == _listingFilter,
          )
          .toList();
    }

    final listingByReqId = <String, String>{
      for (final r in _requirements)
        r.id: EmployeeActivity.requirementListingBucket(r),
    };

    List<RequirementModel> reqsIn(String listing) {
      if (listing == 'All') return allReqs;
      return allReqs
          .where(
            (r) => EmployeeActivity.requirementListingBucket(r) == listing,
          )
          .toList();
    }

    final rentReqs = reqsIn('Rent');
    final resaleReqs = reqsIn('Re-Sale');

    bool isFollowupStatus(String statusStr) {
      final s = statusStr.trim().toLowerCase();
      return s == 'follow-up' || s == 'followup' || s == 're-followup' || s == 'refollowup' || s == 'pending';
    }

    bool isSiteVisitStatus(String statusStr) {
      final s = statusStr.trim().toLowerCase();
      if (s.contains('done')) return false;
      return s.contains('site visit') || s.contains('sitevisit') || s == 'sv' || s.startsWith('site visit');
    }

    bool matchesFocus(RequirementModel r, _LeadFocus focus) {
      switch (focus) {
        case _LeadFocus.all:
          return true;
        case _LeadFocus.won:
          return EmployeeActivity.isWon(r);
        case _LeadFocus.rejected:
          return EmployeeActivity.isRejected(r);
        case _LeadFocus.followup:
          if (EmployeeActivity.isWon(r) || EmployeeActivity.isRejected(r)) return false;
          if (isTelecallerRole && !EmployeeActivity.isCreatedBy(r, user)) return false;
          return isFollowupStatus(r.status);
        case _LeadFocus.overdue:
          if (EmployeeActivity.isWon(r) || EmployeeActivity.isRejected(r)) return false;
          if (isTelecallerRole && !EmployeeActivity.isCreatedBy(r, user)) return false;
          return isFollowupStatus(r.status) && EmployeeActivity.isOverdueFollowup(r);
        case _LeadFocus.visits:
          if (EmployeeActivity.isWon(r) || EmployeeActivity.isRejected(r)) return false;
          if (isTelecallerRole && !EmployeeActivity.isCreatedBy(r, user)) return false;
          return isSiteVisitStatus(r.status);
        case _LeadFocus.assigned:
          if (isTelecallerRole) {
            return (r.createdBy == user.id || EmployeeActivity.isCreatedBy(r, user)) &&
                r.assignedTo != null &&
                r.assignedTo!.trim().isNotEmpty &&
                r.assignedTo != user.id &&
                !EmployeeActivity.isWon(r) &&
                !EmployeeActivity.isRejected(r);
          }
          return EmployeeActivity.isAssignedTo(r, user) &&
              !EmployeeActivity.isCreatedBy(r, user) &&
              !EmployeeActivity.isWon(r) &&
              !EmployeeActivity.isRejected(r);
        case _LeadFocus.created:
          return EmployeeActivity.isCreatedBy(r, user) &&
              !EmployeeActivity.isTransferredAway(r, user) &&
              !EmployeeActivity.isWon(r) &&
              !EmployeeActivity.isRejected(r);
      }
    }

    final focusedReqs =
        visibleReqs.where((r) => matchesFocus(r, _leadFocus)).toList();

    int assignedOf(List<RequirementModel> reqs) {
      if (isTelecallerRole) {
        return reqs.where((r) =>
            (r.createdBy == user.id || EmployeeActivity.isCreatedBy(r, user)) &&
            r.assignedTo != null &&
            r.assignedTo!.trim().isNotEmpty &&
            r.assignedTo != user.id).length;
      }
      return reqs.where((r) =>
          EmployeeActivity.isAssignedTo(r, user) &&
          !EmployeeActivity.isCreatedBy(r, user) &&
          !EmployeeActivity.isWon(r) &&
          !EmployeeActivity.isRejected(r)).length;
    }

    int createdOf(List<RequirementModel> reqs) {
      return reqs.where((r) =>
          EmployeeActivity.isCreatedBy(r, user) &&
          !EmployeeActivity.isTransferredAway(r, user) &&
          !EmployeeActivity.isWon(r) &&
          !EmployeeActivity.isRejected(r)).length;
    }

    int activeLeadsOf(List<RequirementModel> reqs) {
      if (isSalesRole) {
        return assignedOf(reqs) + createdOf(reqs);
      }
      return reqs.where((r) =>
          (EmployeeActivity.isCreatedBy(r, user) || EmployeeActivity.isAssignedTo(r, user)) &&
          !EmployeeActivity.isWon(r) &&
          !EmployeeActivity.isRejected(r)).length;
    }

    final assignedRent = assignedOf(rentReqs);
    final assignedResale = assignedOf(resaleReqs);
    final createdRent = createdOf(rentReqs);
    final createdResale = createdOf(resaleReqs);
    final leadsRent = activeLeadsOf(rentReqs);
    final leadsResale = activeLeadsOf(resaleReqs);

    final wonCount = visibleReqs.where(EmployeeActivity.isWon).length;
    final rejectedCount = visibleReqs.where(EmployeeActivity.isRejected).length;
    final assignedCount = assignedOf(visibleReqs);
    final createdCount = createdOf(visibleReqs);
    final totalLeadsCount = activeLeadsOf(visibleReqs);
    final conversion =
        visibleReqs.isEmpty ? 0.0 : (wonCount / visibleReqs.length) * 100;

    int pendingFollowupsOf(List<RequirementModel> reqs) {
      return reqs.where((r) {
        if (EmployeeActivity.isWon(r) || EmployeeActivity.isRejected(r)) return false;
        if (isTelecallerRole && !EmployeeActivity.isCreatedBy(r, user)) return false;
        return isFollowupStatus(r.status);
      }).length;
    }

    int overdueFollowupsOf(List<RequirementModel> reqs) {
      return reqs.where((r) {
        if (EmployeeActivity.isWon(r) || EmployeeActivity.isRejected(r)) return false;
        if (isTelecallerRole && !EmployeeActivity.isCreatedBy(r, user)) return false;
        if (!isFollowupStatus(r.status)) return false;
        return EmployeeActivity.isOverdueFollowup(r);
      }).length;
    }

    int siteVisitsOf(List<RequirementModel> reqs) {
      return reqs.where((r) {
        if (EmployeeActivity.isWon(r) || EmployeeActivity.isRejected(r)) return false;
        if (isTelecallerRole && !EmployeeActivity.isCreatedBy(r, user)) return false;
        return isSiteVisitStatus(r.status);
      }).length;
    }

    final pendingFollowupsRent = pendingFollowupsOf(rentReqs);
    final pendingFollowupsResale = pendingFollowupsOf(resaleReqs);
    final overdueFollowupsRent = overdueFollowupsOf(rentReqs);
    final overdueFollowupsResale = overdueFollowupsOf(resaleReqs);
    final siteVisitsRent = siteVisitsOf(rentReqs);
    final siteVisitsResale = siteVisitsOf(resaleReqs);

    var totalFollowupsRent = pendingFollowupsRent;
    var totalFollowupsResale = pendingFollowupsResale;
    var totalOverdueFollowupsRent = overdueFollowupsRent;
    var totalOverdueFollowupsResale = overdueFollowupsResale;
    var totalSiteVisitsRent = siteVisitsRent;
    var totalSiteVisitsResale = siteVisitsResale;

    if (_followupRows != null) {
      final followupsTakenRent = _salesFollowups(
        user,
        listingByReqId,
        listing: 'Rent',
      );
      final followupsTakenResale = _salesFollowups(
        user,
        listingByReqId,
        listing: 'Re-Sale',
      );
      totalFollowupsRent = followupsTakenRent.length;
      totalFollowupsResale = followupsTakenResale.length;
      totalOverdueFollowupsRent = _totalOverdueCount(followupsTakenRent);
      totalOverdueFollowupsResale = _totalOverdueCount(followupsTakenResale);
    }

    if (_siteVisitRows != null || _followupRows != null) {
      final visitsTakenRent = _salesSiteVisits(
        user,
        listingByReqId,
        listing: 'Rent',
      );
      final visitsTakenResale = _salesSiteVisits(
        user,
        listingByReqId,
        listing: 'Re-Sale',
      );
      totalSiteVisitsRent = visitsTakenRent.length;
      totalSiteVisitsResale = visitsTakenResale.length;
    }

    final pendingFollowups = _listingFilter == 'Rent'
        ? pendingFollowupsRent
        : _listingFilter == 'Re-Sale'
            ? pendingFollowupsResale
            : pendingFollowupsRent + pendingFollowupsResale;
    final totalFollowups = _listingFilter == 'Rent'
        ? totalFollowupsRent
        : _listingFilter == 'Re-Sale'
            ? totalFollowupsResale
            : totalFollowupsRent + totalFollowupsResale;
    final overdueFollowups = _listingFilter == 'Rent'
        ? overdueFollowupsRent
        : _listingFilter == 'Re-Sale'
            ? overdueFollowupsResale
            : overdueFollowupsRent + overdueFollowupsResale;
    final totalOverdueFollowups = _listingFilter == 'Rent'
        ? totalOverdueFollowupsRent
        : _listingFilter == 'Re-Sale'
            ? totalOverdueFollowupsResale
            : totalOverdueFollowupsRent + totalOverdueFollowupsResale;
    final siteVisits = _listingFilter == 'Rent'
        ? siteVisitsRent
        : _listingFilter == 'Re-Sale'
            ? siteVisitsResale
            : siteVisitsRent + siteVisitsResale;
    final totalSiteVisits = _listingFilter == 'Rent'
        ? totalSiteVisitsRent
        : _listingFilter == 'Re-Sale'
            ? totalSiteVisitsResale
            : totalSiteVisitsRent + totalSiteVisitsResale;

    var team = const <UserModel>[];
    if (usersState is UsersLoaded) {
      team = usersState.users
          .where((m) => EmployeeActivity.isTeamMemberOf(m, user))
          .toList();
    }

    final salesCreated = _adminStats?['salesCreated'] ?? team.length;
    final activeSales =
        _adminStats?['activeSales'] ?? team.where((m) => m.isActive).length;
    final inactiveSales =
        _adminStats?['inactiveSales'] ?? team.where((m) => !m.isActive).length;

    final canEdit = RoleGuard.canAction('page.employees.edit');
    final canDelete = RoleGuard.canAction('page.employees.delete');
    final canToggle = RoleGuard.canAction('page.employees.active_toggle');
    final hasMobile = (user.mobile ?? '').trim().isNotEmpty;
    final first = user.fullName.trim().isEmpty
        ? 'them'
        : user.fullName.trim().split(RegExp(r'\s+')).first;
    final salesLike = isSalesRole;
    final splitByListing = _listingFilter == 'All';

    (String, EvTone) leadBadge(RequirementModel r) {
      if (EmployeeActivity.isWon(r)) return ('Won', EvTone.green);
      if (EmployeeActivity.isRejected(r)) {
        return (_statusLabel(r.status), EvTone.red);
      }
      if (isSiteVisitStatus(r.status)) {
        return (_statusLabel(r.status), EvTone.violet);
      }
      if (isFollowupStatus(r.status)) {
        return (
          _statusLabel(r.status),
          EmployeeActivity.isOverdueFollowup(r) ? EvTone.red : EvTone.amber,
        );
      }
      return (_statusLabel(r.status), EvTone.blue);
    }

    final focusChips = <_LeadFocus, String>{
      _LeadFocus.all: 'All',
      _LeadFocus.won: 'Won',
      if (isSalesRole) _LeadFocus.rejected: 'Rejected',
      _LeadFocus.followup: 'Follow-up',
      _LeadFocus.overdue: 'Overdue',
      _LeadFocus.visits: 'Site visits',
      _LeadFocus.assigned: 'Assigned',
      _LeadFocus.created: 'Created',
    };
    final focusCounts = <_LeadFocus, int>{
      for (final f in focusChips.keys)
        f: visibleReqs.where((r) => matchesFocus(r, f)).length,
    };

    EvKpiItem leadKpi({
      required String title,
      required IconData icon,
      required Color color,
      required String value,
      required String hint,
      required _LeadFocus focus,
      String? hoverValue,
      String? hoverHint,
    }) {
      return EvKpiItem(
        title: title,
        icon: icon,
        color: color,
        value: value,
        hint: hint,
        selected: focus != _LeadFocus.all && _leadFocus == focus,
        onTap: () => _focusLeads(focus),
        hoverValue: hoverValue,
        hoverHint: hoverHint,
      );
    }

    // Rent / Re-Sale hover split (sales only), same semantics as before.
    String? splitValue(int rent, int resale, int total) {
      if (!salesLike) return null;
      return splitByListing ? _rentResaleLabel(rent, resale) : total.toString();
    }

    String? splitHint(int rent, int resale, int total, String totalCaption) {
      if (!salesLike) return null;
      return splitByListing
          ? 'Rent $rent  •  Re-Sale $resale'
          : '$totalCaption: $total';
    }

    final primaryKpis = <EvKpiItem>[
      EvKpiItem(
        title: 'Properties',
        icon: Icons.home_work_outlined,
        color: EmTokens.green,
        value: visibleProps.length.toString(),
        hint: visibleProps.isEmpty
            ? 'Tap to view inventory'
            : 'Listed by $first',
        onTap: () => _scrollTo(_propertiesKey),
      ),
      leadKpi(
        title: 'Leads',
        icon: Icons.groups_2_outlined,
        color: EvTokens.blue,
        value: totalLeadsCount.toString(),
        hint: 'Assigned + created',
        focus: _LeadFocus.all,
        hoverValue: salesLike && splitByListing
            ? _rentResaleLabel(leadsRent, leadsResale)
            : null,
        hoverHint: 'Rent $leadsRent  •  Re-Sale $leadsResale',
      ),
      leadKpi(
        title: 'Won clients',
        icon: Icons.emoji_events_outlined,
        color: EmTokens.green,
        value: wonCount.toString(),
        hint: '${conversion.toStringAsFixed(0)}% conversion',
        focus: _LeadFocus.won,
      ),
      if (isSalesRole)
        leadKpi(
          title: 'Rejected',
          icon: Icons.person_off_outlined,
          color: EmTokens.redText,
          value: rejectedCount.toString(),
          hint: 'Leads they marked rejected',
          focus: _LeadFocus.rejected,
        ),
      leadKpi(
        title: 'Follow-ups',
        icon: Icons.event_available_rounded,
        color: EmTokens.amber,
        value: pendingFollowups.toString(),
        hint: 'Current follow-ups',
        focus: _LeadFocus.followup,
        hoverValue: splitValue(
          pendingFollowupsRent,
          pendingFollowupsResale,
          totalFollowups,
        ),
        hoverHint: splitHint(
          pendingFollowupsRent,
          pendingFollowupsResale,
          totalFollowups,
          'Total follow-ups taken',
        ),
      ),
      leadKpi(
        title: 'Overdue',
        icon: Icons.event_busy_rounded,
        color: EmTokens.redText,
        value: overdueFollowups.toString(),
        hint: 'Past the due time',
        focus: _LeadFocus.overdue,
        hoverValue: splitValue(
          overdueFollowupsRent,
          overdueFollowupsResale,
          totalOverdueFollowups,
        ),
        hoverHint: splitHint(
          overdueFollowupsRent,
          overdueFollowupsResale,
          totalOverdueFollowups,
          'Total overdue follow-ups',
        ),
      ),
      leadKpi(
        title: 'Site visits',
        icon: Icons.location_on_outlined,
        color: EmTokens.violet,
        value: siteVisits.toString(),
        hint: 'Visits planned or done',
        focus: _LeadFocus.visits,
        hoverValue: splitValue(
          siteVisitsRent,
          siteVisitsResale,
          totalSiteVisits,
        ),
        hoverHint: splitHint(
          siteVisitsRent,
          siteVisitsResale,
          totalSiteVisits,
          'Total site visits',
        ),
      ),
    ];

    final adminKpis = <EvKpiItem>[
      if (isAdminRole)
        EvKpiItem(
          title: 'Team size',
          icon: Icons.group_outlined,
          color: EmTokens.green,
          value: '$salesCreated',
          hint: '$activeSales active  •  $inactiveSales inactive',
          onTap: () => _scrollTo(_teamKey),
        ),
      if (isAdminRole && _adminStats != null) ...[
        EvKpiItem(
          title: 'Telecallers',
          icon: Icons.headset_mic_outlined,
          color: EvTokens.blue,
          value: '${_adminStats!['telecallersCreated'] ?? 0}',
          hint: '${_adminStats!['activeTelecallers'] ?? 0} active',
        ),
        EvKpiItem(
          title: 'Won deals',
          icon: Icons.emoji_events_outlined,
          color: EmTokens.green,
          value: '${_adminStats!['wonRequirements'] ?? wonCount}',
          hint: 'Closed from this team',
        ),
        EvKpiItem(
          title: 'Campaign leads',
          icon: Icons.campaign_outlined,
          color: EmTokens.amber,
          value: '${_adminStats!['campaignLeads'] ?? 0}',
          hint: (_adminStats!['campaignEnabled'] == true)
              ? 'In their own inbox'
              : 'Inbox disconnected',
        ),
        EvKpiItem(
          title: 'Imported',
          icon: Icons.file_download_done_outlined,
          color: EmTokens.green,
          value: '${_adminStats!['campaignImported'] ?? 0}',
          hint: '${_adminStats!['campaignPending'] ?? 0} still pending',
        ),
        EvKpiItem(
          title: 'Owners',
          icon: Icons.apartment_outlined,
          color: EmTokens.green,
          value: '${_adminStats!['ownersCount'] ?? 0}',
          hint: 'Owner records in workspace',
        ),
        EvKpiItem(
          title: 'Clients',
          icon: Icons.people_outline,
          color: EvTokens.blue,
          value: '${_adminStats!['clientsCount'] ?? 0}',
          hint: 'Client records in workspace',
        ),
        EvKpiItem(
          title: 'Meta page',
          icon: Icons.link_outlined,
          color: (_adminStats!['webhookConnected'] == true)
              ? EmTokens.green
              : EmTokens.gray,
          value: (_adminStats!['webhookConnected'] == true) ? 'ON' : 'OFF',
          hint: (_adminStats!['campaignEnabled'] == true)
              ? 'Webhook scoped to this admin'
              : 'Campaign access is off',
        ),
      ],
    ];

    final assignedSummary = EvSummaryData(
      icon: Icons.move_to_inbox_outlined,
      tone: EvTone.blue,
      label: isTelecallerRole ? 'ASSIGNED TO SALES' : 'ASSIGNED LEADS',
      value: (isSalesRole || isTelecallerRole) && splitByListing
          ? _rentResaleLabel(assignedRent, assignedResale)
          : assignedCount.toString(),
      caption: isTelecallerRole
          ? 'Leads $first passed to the sales team'
          : 'Given to $first by Lead Allocation or an admin',
      onTap: () => _focusLeads(_LeadFocus.assigned),
    );
    final createdSummary = EvSummaryData(
      icon: Icons.edit_note_rounded,
      tone: EvTone.green,
      label: 'CREATED LEADS',
      value: createdCount.toString(),
      caption: isSalesRole && splitByListing
          ? 'Leads $first added personally  •  Rent $createdRent  •  Re-Sale $createdResale'
          : 'Leads $first added personally',
      onTap: () => _focusLeads(_LeadFocus.created),
    );

    void openProperties() => context.push(
          '/properties?search=${Uri.encodeComponent(user.fullName)}',
        );
    void openLeads() => context.push(
          '/requirements?search=${Uri.encodeComponent(user.fullName)}',
        );

    final propertiesCard = KeyedSubtree(
      key: _propertiesKey,
      child: _PropertiesSection(
        user: user,
        properties: visibleProps,
        onOpenAll: openProperties,
      ),
    );
    final leadsCard = KeyedSubtree(
      key: _leadsKey,
      child: _LeadsSection(
        leads: focusedReqs,
        totalUnfiltered: visibleReqs.length,
        focus: _leadFocus,
        chips: focusChips,
        counts: focusCounts,
        formatFollowup: _formatFollowup,
        badgeFor: leadBadge,
        onChangeFocus: (focus) => setState(() => _leadFocus = focus),
        onOpenAll: openLeads,
      ),
    );

    const gap = SizedBox(height: 16);

    final scrollContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!isMobile) ...[
          EvBreadcrumb(
            current: user.fullName,
            onEmployees: () => context.go('/users'),
          ),
          const SizedBox(height: 10),
        ],
        EvHead(
          title: user.fullName,
          subtitle:
              '${user.roleName}  •  ${user.isActive ? 'Active login' : 'Login off'}',
          showTitle: !isMobile,
          onBack: isMobile ? null : _goBack,
          onCall: hasMobile ? () => _call(user.mobile) : null,
          onWhatsapp: hasMobile ? () => _whatsapp(user.mobile) : null,
          onEmail: () => _email(user.email),
        ),
        gap,
        EvProfileCard(
          user: user,
          joinedLabel: _formatCreatedDate(user.createdAt),
          reportingLabel: (user.createdByName ?? '').trim().isEmpty
              ? '—'
              : user.createdByName!,
          onToggleLogin: canToggle
              ? (val) => context.read<UsersBloc>().add(
                    ToggleUserStatusRequested(id: user.id, isActive: val),
                  )
              : null,
          onEmail: () => _email(user.email),
          onCall: () => _call(user.mobile),
          onEdit: canEdit ? () => _editDetails(user) : null,
          onReset: canEdit ? () => _resetPassword(user) : null,
          onRemove: canDelete ? () => _remove(user) : null,
        ),
        if (RoleGuard.isSuperAdmin(RoleGuard.currentUser?.role) &&
            user.roleName.toLowerCase() == 'admin') ...[
          gap,
          _WorkspaceAccessCard(
            organizationName: _adminStats?['organizationName']?.toString() ??
                user.organizationName ??
                'Isolated admin workspace',
            enabled: (_adminStats?['campaignEnabled'] as bool?) ??
                user.campaignEnabled,
            busy: _updatingAccess,
            onChanged: (val) => _setCampaignAccess(user, val),
          ),
        ],
        gap,
        if (_loadingActivity)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_activityError != null)
          EvCardShell(
            title: 'Activity unavailable',
            subtitle: _activityError!,
            actionLabel: 'Retry',
            onAction: _loadActivity,
            children: const [
              EvEmpty(
                title: 'Could not load activity',
                message: 'Check your connection and retry.',
              ),
            ],
          )
        else ...[
          EvBizSeg(
            options: const ['All', 'Rent', 'Re-Sale'],
            labels: const {'Re-Sale': 'Re-sale'},
            selected: _listingFilter,
            onChanged: (v) => setState(() => _listingFilter = v),
          ),
          gap,
          EvKpiGrid(items: primaryKpis),
          gap,
          EvSummaryPair(left: assignedSummary, right: createdSummary),
          if (adminKpis.isNotEmpty) ...[
            gap,
            EvKpiGrid(items: adminKpis),
          ],
          gap,
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= 900) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: propertiesCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 7, child: leadsCard),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [propertiesCard, gap, leadsCard],
              );
            },
          ),
          if (isAdminRole || team.isNotEmpty) ...[
            gap,
            KeyedSubtree(
              key: _teamKey,
              child: _TeamSection(members: team),
            ),
          ],
        ],
      ],
    );

    if (isMobile) {
      return MobileScreenScaffold(
        title: user.fullName,
        showBack: true,
        onBack: _goBack,
        backFallback: '/users',
        scrollable: false,
        body: RefreshIndicator(
          onRefresh: _loadActivity,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              CRMSpacing.m,
              CRMSpacing.m,
              CRMSpacing.m,
              CRMSpacing.xl,
            ),
            child: scrollContent,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActivity,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          CRMSpacing.l,
          CRMSpacing.m,
          CRMSpacing.l,
          CRMSpacing.xl,
        ),
        child: scrollContent,
      ),
    );
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/users');
    }
  }

  String _rentResaleLabel(int rent, int resale) =>
      'Rent $rent  •  Re-Sale $resale';

  /// KPI tap: toggle the lead focus and scroll to the leads card.
  void _focusLeads(_LeadFocus focus) {
    setState(() {
      _leadFocus =
          (_leadFocus == focus && focus != _LeadFocus.all) ? _LeadFocus.all : focus;
    });
    _scrollTo(_leadsKey);
  }

  Future<void> _editDetails(UserModel user) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EditEmployeeDialog(user: user),
    );
    if (data == null || !mounted) return;
    context.read<UsersBloc>().add(
          UpdateUserRequested(id: user.id, userData: data),
        );
  }

  Future<void> _resetPassword(UserModel user) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _ResetPasswordDialog(user: user),
    );
    if (password == null || !mounted) return;
    context.read<UsersBloc>().add(
          UpdateUserRequested(id: user.id, userData: {'password': password}),
        );
  }

  Future<void> _remove(UserModel user) async {
    final confirmed = await CRMDialogs.showDeleteConfirmation(
      context,
      title: 'Remove employee',
      content:
          'Are you sure you want to remove ${user.fullName}? This user will be permanently removed from the system.',
    );
    if (confirmed == true && mounted) {
      _removing = true;
      context.read<UsersBloc>().add(DeleteUserRequested(id: user.id));
    }
  }
}

String _statusLabel(String status) {
  if (status == 'Assigned') return 'Assigned';
  if (status == 'New') return 'New';
  if (status == 'Not Started') return 'Not Started';
  if (status == 'Not Interested') return 'Not Interested';
  if (status == 'Live' || status == 'Active') return 'Interested';
  if (status == 'Dead' || status == 'Suspended') return 'Not Interested';
  if (status == 'Re-Followup') return 'Re-Followup';
  return status;
}

// -----------------------------------------------------------------------------
// Sections composed from employee_detail_ui widgets
// -----------------------------------------------------------------------------

class _WorkspaceAccessCard extends StatelessWidget {
  final String organizationName;
  final bool enabled;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _WorkspaceAccessCard({
    required this.organizationName,
    required this.enabled,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return EvCardShell(
      title: 'Workspace access',
      subtitle: organizationName,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campaign / Meta inbox',
                      style: EvTokens.text(
                        size: 13,
                        weight: FontWeight.w600,
                        color: EmTokens.ink(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enabled
                          ? 'Connected — this admin can ingest Meta and Sheets leads into their own inbox.'
                          : 'Off — new admin starts empty. Enable when they should run campaigns.',
                      style: EvTokens.text(
                        size: 12,
                        color: EmTokens.muted(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              EvToggle(value: enabled, onChanged: busy ? null : onChanged),
            ],
          ),
        ),
      ],
    );
  }
}

class _PropertiesSection extends StatefulWidget {
  final UserModel user;
  final List<PropertyModel> properties;
  final VoidCallback onOpenAll;

  const _PropertiesSection({
    required this.user,
    required this.properties,
    required this.onOpenAll,
  });

  @override
  State<_PropertiesSection> createState() => _PropertiesSectionState();
}

class _PropertiesSectionState extends State<_PropertiesSection> {
  int _page = 1;
  int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final total = widget.properties.length;
    final totalPages = total == 0 ? 1 : (total / _pageSize).ceil();
    if (_page > totalPages) _page = totalPages;
    if (_page < 1) _page = 1;
    final start = total == 0 ? 0 : (_page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, total);
    final paged = widget.properties.sublist(start, end);
    final first = widget.user.fullName.trim().split(RegExp(r'\s+')).first;

    return EvCardShell(
      title: 'Properties added',
      subtitle: total == 0
          ? 'No inventory linked to ${widget.user.fullName}'
          : '$total listed by $first',
      actionLabel: 'Open in Properties →',
      onAction: widget.onOpenAll,
      children: [
        if (total == 0)
          EvEmpty(
            title: 'No properties yet',
            message: 'Properties $first adds will show up here.',
          )
        else ...[
          for (final p in paged)
            EvPropRow(
              title: p.title,
              subtitle:
                  '${p.propertyCode}  •  ${p.areaName}  •  ${p.configurationName ?? '${p.bedrooms} BHK'}  •  ${EmployeeActivity.propertyListingBucket(p)}',
              price: '₹${BudgetFormatter.format(p.price)}',
              priceSuffix:
                  EmployeeActivity.propertyListingBucket(p) == 'Rent' ? '/mo' : null,
              onTap: () => showCRMPropertyDrawer(context, p),
            ),
          EvPager(
            total: total,
            page: _page,
            pageSize: _pageSize,
            onPageChanged: (v) => setState(() => _page = v),
            onPageSizeChanged: (v) => setState(() {
              _pageSize = v;
              _page = 1;
            }),
          ),
        ],
      ],
    );
  }
}

class _LeadsSection extends StatefulWidget {
  final List<RequirementModel> leads;
  final int totalUnfiltered;
  final _LeadFocus focus;
  final Map<_LeadFocus, String> chips;
  final Map<_LeadFocus, int> counts;
  final String Function(String?) formatFollowup;
  final (String, EvTone) Function(RequirementModel) badgeFor;
  final ValueChanged<_LeadFocus> onChangeFocus;
  final VoidCallback onOpenAll;

  const _LeadsSection({
    required this.leads,
    required this.totalUnfiltered,
    required this.focus,
    required this.chips,
    required this.counts,
    required this.formatFollowup,
    required this.badgeFor,
    required this.onChangeFocus,
    required this.onOpenAll,
  });

  @override
  State<_LeadsSection> createState() => _LeadsSectionState();
}

class _LeadsSectionState extends State<_LeadsSection> {
  int _page = 1;
  int _pageSize = 10;

  static const _avatarTones = [
    EvTone.green,
    EvTone.amber,
    EvTone.blue,
    EvTone.violet,
  ];

  @override
  void didUpdateWidget(covariant _LeadsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focus != widget.focus) _page = 1;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.leads.length;
    final totalPages = total == 0 ? 1 : (total / _pageSize).ceil();
    if (_page > totalPages) _page = totalPages;
    if (_page < 1) _page = 1;
    final start = total == 0 ? 0 : (_page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, total);
    final paged = widget.leads.sublist(start, end);

    return EvCardShell(
      title: 'Leads',
      subtitle:
          '$total shown of ${widget.totalUnfiltered}  •  tap a row to open',
      actionLabel: 'Open in Leads →',
      onAction: widget.onOpenAll,
      children: [
        EvFilterChips(
          items: [
            for (final e in widget.chips.entries)
              EvChipItem(
                label: e.value,
                count: widget.counts[e.key] ?? 0,
                selected: widget.focus == e.key,
                onTap: () => widget.onChangeFocus(e.key),
              ),
          ],
        ),
        if (total == 0)
          const EvEmpty(title: 'No leads here', message: 'Try another filter.')
        else ...[
          for (final lead in paged) _row(context, lead),
          EvPager(
            total: total,
            page: _page,
            pageSize: _pageSize,
            onPageChanged: (v) => setState(() => _page = v),
            onPageSizeChanged: (v) => setState(() {
              _pageSize = v;
              _page = 1;
            }),
          ),
        ],
      ],
    );
  }

  Widget _row(BuildContext context, RequirementModel lead) {
    final followup = widget.formatFollowup(lead.nextFollowupDate);
    final (label, tone) = widget.badgeFor(lead);
    final mobile = lead.clientMobile.toString();
    return EvLeadRow(
      name: lead.clientName,
      subtitle: [
        if (mobile.trim().isNotEmpty) mobile,
        EmployeeActivity.requirementListingBucket(lead),
        lead.displayAreasText,
        if (followup.isNotEmpty) 'Follow-up $followup',
      ].where((s) => s.toString().trim().isNotEmpty).join('  •  '),
      budget:
          '₹${BudgetFormatter.format(lead.minBudget)} – ₹${BudgetFormatter.format(lead.maxBudget)}',
      statusLabel: label,
      statusTone: tone,
      avatarTone: _avatarTones[lead.clientName.length % _avatarTones.length],
      onTap: () =>
          context.push('/requirements?openId=${Uri.encodeComponent(lead.id)}'),
    );
  }
}

class _TeamSection extends StatelessWidget {
  final List<UserModel> members;

  const _TeamSection({required this.members});

  @override
  Widget build(BuildContext context) {
    final canOpen = RoleGuard.canAction('page.employees.details');
    return EvCardShell(
      title: 'Team members',
      subtitle: members.isEmpty
          ? 'No sales or telecaller profiles report to this admin'
          : '${members.length} people  •  tap to open their page',
      children: [
        if (members.isEmpty)
          const EvEmpty(
            title: 'No team yet',
            message: 'People who report to this admin will show up here.',
          )
        else
          for (final m in members)
            EvLeadRow(
              name: m.fullName,
              subtitle: m.email,
              budget: m.roleName,
              statusLabel: m.isActive ? 'Active' : 'Inactive',
              statusTone: m.isActive ? EvTone.green : EvTone.gray,
              avatarTone: EvTokens.roleTone(m.roleName),
              onTap: canOpen ? () => context.push('/users/${m.id}') : null,
            ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Dialogs (dispatch UpdateUserRequested via the screen)
// -----------------------------------------------------------------------------

InputDecoration _fieldDecoration(BuildContext context, String label) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: BorderSide(color: EmTokens.line(context)),
  );
  return InputDecoration(
    labelText: label,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: const BorderSide(color: EmTokens.green, width: 1.5),
    ),
    labelStyle: EvTokens.text(size: 13, color: EmTokens.muted(context)),
  );
}

class _EvDialogFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget body;
  final List<Widget> actions;

  const _EvDialogFrame({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: EmTokens.panelBg(context),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EvTokens.radiusCard),
        side: BorderSide(color: EmTokens.line(context)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: EvTokens.text(
                  size: 17,
                  weight: FontWeight.w700,
                  color: EmTokens.ink(context),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: EvTokens.text(size: 12.5, color: EmTokens.muted(context)),
              ),
              const SizedBox(height: 16),
              body,
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions[i],
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditEmployeeDialog extends StatefulWidget {
  final UserModel user;
  const _EditEmployeeDialog({required this.user});

  @override
  State<_EditEmployeeDialog> createState() => _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends State<_EditEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.user.fullName);
  late final TextEditingController _email =
      TextEditingController(text: widget.user.email);
  late final TextEditingController _mobile =
      TextEditingController(text: widget.user.mobile ?? '');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, <String, dynamic>{
      'full_name': _name.text.trim(),
      'email': _email.text.trim(),
      'mobile': _mobile.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _EvDialogFrame(
      title: 'Edit details',
      subtitle: 'Update ${widget.user.fullName}’s name, email and mobile.',
      body: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: _fieldDecoration(context, 'Full name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Full name required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: _fieldDecoration(context, 'Email *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Email required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: _fieldDecoration(context, 'Mobile *'),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                if (digits.isEmpty) return 'Phone number required';
                if (digits.length != 10) return 'Enter a valid 10-digit mobile';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        EvButton(label: 'Cancel', onTap: () => Navigator.pop(context)),
        EvButton(label: 'Save changes', primary: true, onTap: _save),
      ],
    );
  }
}

class _ResetPasswordDialog extends StatefulWidget {
  final UserModel user;
  const _ResetPasswordDialog({required this.user});

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pop(context, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    return _EvDialogFrame(
      title: 'Reset password',
      subtitle: 'Set a new password for ${widget.user.fullName}.',
      body: Form(
        key: _formKey,
        child: TextFormField(
          controller: _password,
          obscureText: _obscure,
          decoration: _fieldDecoration(context, 'New password *').copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password required';
            if (v.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
      ),
      actions: [
        EvButton(label: 'Cancel', onTap: () => Navigator.pop(context)),
        EvButton(label: 'Set password', primary: true, onTap: _save),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  final VoidCallback onBack;
  const _NotFound({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(CRMSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 48,
              color: EmTokens.muted(context),
            ),
            const SizedBox(height: CRMSpacing.m),
            Text(
              'Employee not found',
              style: EvTokens.text(
                size: 17,
                weight: FontWeight.w700,
                color: EmTokens.ink(context),
              ),
            ),
            const SizedBox(height: CRMSpacing.s),
            Text(
              'This profile may have been removed or you do not have access.',
              textAlign: TextAlign.center,
              style: EvTokens.text(size: 13, color: EmTokens.muted(context)),
            ),
            const SizedBox(height: CRMSpacing.l),
            EvButton(
              label: 'Back to Employees',
              primary: true,
              onTap: onBack,
            ),
          ],
        ),
      ),
    );
  }
}

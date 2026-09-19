import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/design_system/tokens/app_typography.dart';
import '../../../core/design_system/widgets/buttons.dart';
import '../../../core/design_system/widgets/cards.dart';
import '../../../core/design_system/widgets/crm_page_header.dart';
import '../../../core/design_system/widgets/crm_network_image.dart';
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
import '../../../core/security/role_guard.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? (enabled
                    ? 'Campaign access enabled for this workspace.'
                    : 'Campaign access turned off. This admin keeps an empty campaign inbox.')
                : 'Could not update campaign access.',
          ),
          backgroundColor: ok ? CRMColors.success : CRMColors.danger,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _updatingAccess = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update campaign access.'),
          backgroundColor: CRMColors.danger,
        ),
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

  int _pendingFollowupCount(List<Map<String, dynamic>> rows) {
    return rows.where((row) {
      final dt = _rowDate(row);
      if (dt == null) return false;
      return EmployeeActivity.isOpenFollowupStatus(
            (row['status'] ?? '').toString(),
          ) &&
          EmployeeActivity.isDateOnOrAfterToday(dt);
    }).length;
  }

  int _currentOverdueCount(List<Map<String, dynamic>> rows) {
    return rows.where((row) {
      final dt = _rowDate(row);
      if (dt == null) return false;
      return EmployeeActivity.isOpenFollowupStatus(
            (row['status'] ?? '').toString(),
          ) &&
          EmployeeActivity.isDateBeforeToday(dt);
    }).length;
  }

  int _totalOverdueCount(List<Map<String, dynamic>> rows) {
    return rows.where((row) {
      final dt = _rowDate(row);
      if (dt == null) return false;
      return EmployeeActivity.isDateBeforeToday(dt);
    }).length;
  }

  int _openSiteVisitCount(List<Map<String, dynamic>> rows) {
    return rows
        .where(
          (row) => EmployeeActivity.isOpenSiteVisitStatus(
            (row['status'] ?? '').toString(),
          ),
        )
        .length;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this action.')),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: CRMColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<UsersBloc>().add(const FetchUsers());
            } else if (state is UsersError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: CRMColors.danger,
                  behavior: SnackBarBehavior.floating,
                ),
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
    final isMobile = MediaQuery.of(context).size.width < 700;
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

    final focusedReqs = visibleReqs.where((r) {
      switch (_leadFocus) {
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
              !EmployeeActivity.isWon(r) &&
              !EmployeeActivity.isRejected(r);
      }
    }).toList();

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

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CRMSpacing.l,
            CRMSpacing.m,
            CRMSpacing.l,
            0,
          ),
          child: CRMPageHeader(
            title: user.fullName,
            eyebrow: 'Employee',
            benefit:
                '${user.roleName}  •  ${user.isActive ? 'Active login' : 'Inactive'}',
            breadcrumbs: [
              InkWell(
                onTap: () => context.go('/users'),
                child: Text(
                  'Employees',
                  style: CRMTypography.captionBold.copyWith(
                    color: CRMColors.primaryOf(context),
                  ),
                ),
              ),
              Text(
                '  /  ',
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textMutedOf(context),
                ),
              ),
              Text(
                user.fullName,
                style: CRMTypography.caption.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
            ],
            trailing: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                CRMButton(
                  label: 'Back',
                  prefixIcon: Icons.arrow_back_rounded,
                  variant: CRMButtonVariant.outline,
                  height: 36,
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/users');
                    }
                  },
                ),
                if ((user.mobile ?? '').trim().isNotEmpty)
                  CRMButton(
                    label: 'Call',
                    prefixIcon: Icons.call_rounded,
                    variant: CRMButtonVariant.outline,
                    height: 36,
                    onPressed: () => _call(user.mobile),
                  ),
                if ((user.mobile ?? '').trim().isNotEmpty)
                  CRMButton(
                    label: 'WhatsApp',
                    prefixIcon: Icons.chat_rounded,
                    variant: CRMButtonVariant.secondary,
                    height: 36,
                    onPressed: () => _whatsapp(user.mobile),
                  ),
                CRMButton(
                  label: 'Email',
                  prefixIcon: Icons.mail_outline_rounded,
                  variant: CRMButtonVariant.primary,
                  height: 36,
                  onPressed: () => _email(user.email),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: CRMSpacing.m),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadActivity,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                CRMSpacing.l,
                0,
                CRMSpacing.l,
                CRMSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileSummaryCard(
                    user: user,
                    onCall: () => _call(user.mobile),
                    onEmail: () => _email(user.email),
                    onToggleActive: (val) {
                      context.read<UsersBloc>().add(
                            ToggleUserStatusRequested(
                              id: user.id,
                              isActive: val,
                            ),
                          );
                    },
                    createdLabel: _formatCreatedDate(user.createdAt),
                  ),
                  if (RoleGuard.isSuperAdmin(RoleGuard.currentUser?.role) &&
                      user.roleName.toLowerCase() == 'admin') ...[
                    const SizedBox(height: CRMSpacing.m),
                    CRMCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Workspace access',
                            style: CRMTypography.sectionTitle.copyWith(
                              color: CRMColors.textOf(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _adminStats?['organizationName']?.toString() ??
                                user.organizationName ??
                                'Isolated admin workspace',
                            style: CRMTypography.caption.copyWith(
                              color: CRMColors.textSecondaryOf(context),
                            ),
                          ),
                          const SizedBox(height: CRMSpacing.s),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Campaign / Meta inbox'),
                            subtitle: Text(
                              ((_adminStats?['campaignEnabled'] as bool?) ??
                                      user.campaignEnabled)
                                  ? 'Connected — this admin can ingest Meta and Sheets leads into their own inbox.'
                                  : 'Off — new admin starts empty. Enable when they should run campaigns.',
                            ),
                            value: (_adminStats?['campaignEnabled'] as bool?) ??
                                user.campaignEnabled,
                            onChanged: _updatingAccess
                                ? null
                                : (val) => _setCampaignAccess(user, val),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: CRMSpacing.m),
                  if (_loadingActivity)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_activityError != null)
                    CRMCard(
                      child: Column(
                        children: [
                          Text(_activityError!, style: CRMTypography.body),
                          const SizedBox(height: CRMSpacing.m),
                          CRMButton(label: 'Retry', onPressed: _loadActivity),
                        ],
                      ),
                    )
                  else ...[
                    _listingToggle(context),
                    const SizedBox(height: CRMSpacing.m),
                    CRMResponsiveKpiRow(
                      minCardWidth: 150,
                      children: [
                        CRMKPICard(
                          title: 'PROPERTIES',
                          value: visibleProps.length.toString(),
                          icon: Icons.home_work_outlined,
                          iconColor: CRMColors.primaryOf(context),
                          benefit: 'Tap to view inventory they added',
                          onTap: () => _scrollTo(_propertiesKey),
                        ),
                        _salesKpiCard(
                          title: 'LEADS',
                          value: totalLeadsCount.toString(),
                          icon: Icons.assignment_outlined,
                          iconColor: CRMColors.info,
                          benefit: isSalesRole && _listingFilter == 'All'
                              ? 'Assigned + created  •  Hover for Rent / Re-Sale'
                              : 'Tap to view assigned & created leads',
                          hoverValue: isSalesRole && _listingFilter == 'All'
                              ? _rentResaleLabel(leadsRent, leadsResale)
                              : null,
                          hoverBenefit: 'Rent $leadsRent  •  Re-Sale $leadsResale',
                          onTap: () {
                            setState(() => _leadFocus = _LeadFocus.all);
                            _scrollTo(_leadsKey);
                          },
                        ),
                        CRMKPICard(
                          title: 'WON CLIENTS',
                          value: wonCount.toString(),
                          icon: Icons.workspace_premium_outlined,
                          iconColor: CRMColors.success,
                          benefit:
                              '${conversion.toStringAsFixed(0)}% conversion  •  Tap to filter',
                          onTap: () {
                            setState(() => _leadFocus = _LeadFocus.won);
                            _scrollTo(_leadsKey);
                          },
                        ),
                        if (isSalesRole)
                          CRMKPICard(
                            title: 'REJECTED CLIENT',
                            value: rejectedCount.toString(),
                            icon: Icons.person_off_outlined,
                            iconColor: CRMColors.danger,
                            benefit: 'Leads they marked rejected  •  Tap to filter',
                            onTap: () {
                              setState(() => _leadFocus = _LeadFocus.rejected);
                              _scrollTo(_leadsKey);
                            },
                          ),
                        _salesKpiCard(
                          title: 'FOLLOW-UPS',
                          value: pendingFollowups.toString(),
                          icon: Icons.event_available_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          benefit: isSalesRole
                              ? (_listingFilter == 'All'
                                  ? 'Current follow-ups  •  Hover for Rent / Re-Sale'
                                  : 'Current follow-ups  •  Hover for total')
                              : 'Upcoming  •  Tap to open',
                          hoverValue: !isSalesRole
                              ? null
                              : _listingFilter == 'All'
                                  ? _rentResaleLabel(
                                      pendingFollowupsRent,
                                      pendingFollowupsResale,
                                    )
                                  : totalFollowups.toString(),
                          hoverBenefit: !isSalesRole
                              ? null
                              : _listingFilter == 'All'
                                  ? 'Rent $pendingFollowupsRent  •  Re-Sale $pendingFollowupsResale'
                                  : 'Total follow-ups taken: $totalFollowups',
                          onTap: () {
                            setState(() => _leadFocus = _LeadFocus.followup);
                            _scrollTo(_leadsKey);
                          },
                        ),
                        _salesKpiCard(
                          title: 'OVERDUE',
                          value: overdueFollowups.toString(),
                          icon: Icons.event_busy_rounded,
                          iconColor: CRMColors.danger,
                          benefit: isSalesRole
                              ? (_listingFilter == 'All'
                                  ? 'Current overdue  •  Hover for Rent / Re-Sale'
                                  : 'Current overdue  •  Hover for total')
                              : 'Missed follow-ups  •  Tap to open',
                          hoverValue: !isSalesRole
                              ? null
                              : _listingFilter == 'All'
                                  ? _rentResaleLabel(
                                      overdueFollowupsRent,
                                      overdueFollowupsResale,
                                    )
                                  : totalOverdueFollowups.toString(),
                          hoverBenefit: !isSalesRole
                              ? null
                              : _listingFilter == 'All'
                                  ? 'Rent $overdueFollowupsRent  •  Re-Sale $overdueFollowupsResale'
                                  : 'Total overdue follow-ups: $totalOverdueFollowups',
                          onTap: () {
                            setState(() => _leadFocus = _LeadFocus.overdue);
                            _scrollTo(_leadsKey);
                          },
                        ),
                        _salesKpiCard(
                          title: 'SITE VISITS',
                          value: siteVisits.toString(),
                          icon: Icons.location_on_outlined,
                          iconColor: const Color(0xFF8B5CF6),
                          benefit: isSalesRole
                              ? (_listingFilter == 'All'
                                  ? 'Current site visits  •  Hover for Rent / Re-Sale'
                                  : 'Current site visits  •  Hover for total')
                              : 'Leads with visits  •  Tap to open',
                          hoverValue: !isSalesRole
                              ? null
                              : _listingFilter == 'All'
                                  ? _rentResaleLabel(
                                      siteVisitsRent,
                                      siteVisitsResale,
                                    )
                                  : totalSiteVisits.toString(),
                          hoverBenefit: !isSalesRole
                              ? null
                              : _listingFilter == 'All'
                                  ? 'Rent $siteVisitsRent  •  Re-Sale $siteVisitsResale'
                                  : 'Total site visits: $totalSiteVisits',
                          onTap: () {
                            setState(() => _leadFocus = _LeadFocus.visits);
                            _scrollTo(_leadsKey);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.s),
                    CRMResponsiveKpiRow(
                      minCardWidth: 150,
                      children: [
                        _salesKpiCard(
                          title: isTelecallerRole ? 'ASSIGNED TO SALES' : 'ASSIGNED LEADS',
                          value: assignedCount.toString(),
                          icon: Icons.person_pin_circle_outlined,
                          iconColor: CRMColors.info,
                          benefit: isTelecallerRole
                              ? 'Leads passed to sales team'
                              : (isSalesRole && _listingFilter == 'All'
                                  ? 'Currently on their plate  •  Hover for Rent / Re-Sale'
                                  : 'Currently on their plate'),
                          hoverValue: (isSalesRole || isTelecallerRole) && _listingFilter == 'All'
                              ? _rentResaleLabel(assignedRent, assignedResale)
                              : null,
                          hoverBenefit:
                              'Rent $assignedRent  •  Re-Sale $assignedResale',
                          onTap: () {
                            setState(() => _leadFocus = _LeadFocus.assigned);
                            _scrollTo(_leadsKey);
                          },
                        ),
                        _salesKpiCard(
                          title: 'CREATED LEADS',
                          value: createdCount.toString(),
                          icon: Icons.post_add_rounded,
                          iconColor: CRMColors.primaryOf(context),
                          benefit: isSalesRole && _listingFilter == 'All'
                              ? 'Leads they originated  •  Hover for Rent / Re-Sale'
                              : 'Leads they originated',
                          hoverValue: isSalesRole && _listingFilter == 'All'
                              ? _rentResaleLabel(createdRent, createdResale)
                              : null,
                          hoverBenefit:
                              'Rent $createdRent  •  Re-Sale $createdResale',
                          onTap: () {
                            setState(() => _leadFocus = _LeadFocus.created);
                            _scrollTo(_leadsKey);
                          },
                        ),
                        if (isAdminRole)
                          CRMKPICard(
                            title: 'TEAM SIZE',
                            value: '$salesCreated',
                            icon: Icons.group_outlined,
                            iconColor: CRMColors.primaryOf(context),
                            benefit:
                                '$activeSales active  •  $inactiveSales inactive',
                            onTap: () => _scrollTo(_teamKey),
                          ),
                        if (isAdminRole && _adminStats != null)
                          CRMKPICard(
                            title: 'TELECALLERS',
                            value: '${_adminStats!['telecallersCreated'] ?? 0}',
                            icon: Icons.headset_mic_outlined,
                            iconColor: CRMColors.info,
                            benefit:
                                '${_adminStats!['activeTelecallers'] ?? 0} active on this workspace',
                          ),
                        if (isAdminRole && _adminStats != null)
                          CRMKPICard(
                            title: 'WON DEALS',
                            value: '${_adminStats!['wonRequirements'] ?? wonCount}',
                            icon: Icons.emoji_events_outlined,
                            iconColor: CRMColors.success,
                            benefit: 'Closed from this admin team',
                          ),
                        if (isAdminRole && _adminStats != null)
                          CRMKPICard(
                            title: 'CAMPAIGN LEADS',
                            value: '${_adminStats!['campaignLeads'] ?? 0}',
                            icon: Icons.campaign_outlined,
                            iconColor: CRMColors.warning,
                            benefit: (_adminStats!['campaignEnabled'] == true)
                                ? 'In their own Meta/Sheets inbox'
                                : 'Inbox disconnected',
                          ),
                        if (isAdminRole && _adminStats != null)
                          CRMKPICard(
                            title: 'IMPORTED',
                            value: '${_adminStats!['campaignImported'] ?? 0}',
                            icon: Icons.file_download_done_outlined,
                            iconColor: CRMColors.success,
                            benefit:
                                '${_adminStats!['campaignPending'] ?? 0} still pending in their inbox',
                          ),
                        if (isAdminRole && _adminStats != null)
                          CRMKPICard(
                            title: 'OWNERS',
                            value: '${_adminStats!['ownersCount'] ?? 0}',
                            icon: Icons.apartment_outlined,
                            iconColor: CRMColors.primaryOf(context),
                            benefit: 'Owner records in this workspace only',
                          ),
                        if (isAdminRole && _adminStats != null)
                          CRMKPICard(
                            title: 'CLIENTS',
                            value: '${_adminStats!['clientsCount'] ?? 0}',
                            icon: Icons.people_outline,
                            iconColor: CRMColors.info,
                            benefit: 'Client records in this workspace only',
                          ),
                        if (isAdminRole && _adminStats != null)
                          CRMKPICard(
                            title: 'META PAGE',
                            value: (_adminStats!['webhookConnected'] == true)
                                ? 'ON'
                                : 'OFF',
                            icon: Icons.link_outlined,
                            iconColor: (_adminStats!['webhookConnected'] == true)
                                ? CRMColors.success
                                : CRMColors.textSecondaryOf(context),
                            benefit: (_adminStats!['campaignEnabled'] == true)
                                ? 'Webhook scoped to this admin workspace'
                                : 'Campaign access is off until you enable it',
                          ),
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.m),
                    if (!isMobile && MediaQuery.of(context).size.width >= 900)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: KeyedSubtree(
                              key: _propertiesKey,
                              child: _PropertiesSection(
                                user: user,
                                properties: visibleProps,
                                isMobile: isMobile,
                                onOpenAll: () => context.push(
                                  '/properties?search=${Uri.encodeComponent(user.fullName)}',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: CRMSpacing.m),
                          Expanded(
                            child: KeyedSubtree(
                              key: _leadsKey,
                              child: _LeadsSection(
                                leads: focusedReqs,
                                totalUnfiltered: visibleReqs.length,
                                focus: _leadFocus,
                                isMobile: isMobile,
                                formatFollowup: _formatFollowup,
                                onChangeFocus: (focus) =>
                                    setState(() => _leadFocus = focus),
                                showRejected: isSalesRole,
                                onOpenAll: () => context.push(
                                  '/requirements?search=${Uri.encodeComponent(user.fullName)}',
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      KeyedSubtree(
                        key: _propertiesKey,
                        child: _PropertiesSection(
                          user: user,
                          properties: visibleProps,
                          isMobile: isMobile,
                          onOpenAll: () => context.push(
                            '/properties?search=${Uri.encodeComponent(user.fullName)}',
                          ),
                        ),
                      ),
                      const SizedBox(height: CRMSpacing.m),
                      KeyedSubtree(
                        key: _leadsKey,
                        child: _LeadsSection(
                          leads: focusedReqs,
                          totalUnfiltered: visibleReqs.length,
                          focus: _leadFocus,
                          isMobile: isMobile,
                          formatFollowup: _formatFollowup,
                          onChangeFocus: (focus) =>
                              setState(() => _leadFocus = focus),
                          showRejected: isSalesRole,
                          onOpenAll: () => context.push(
                            '/requirements?search=${Uri.encodeComponent(user.fullName)}',
                          ),
                        ),
                      ),
                    ],
                    if (isAdminRole || team.isNotEmpty) ...[
                      const SizedBox(height: CRMSpacing.m),
                      KeyedSubtree(
                        key: _teamKey,
                        child: _TeamSection(members: team),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _rentResaleLabel(int rent, int resale) =>
      'Rent $rent  •  Re-Sale $resale';

  Widget _salesKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required String benefit,
    VoidCallback? onTap,
    String? hoverValue,
    String? hoverBenefit,
  }) {
    final front = CRMKPICard(
      title: title,
      value: value,
      icon: icon,
      iconColor: iconColor,
      benefit: benefit,
      onTap: onTap,
    );
    if (hoverValue == null || hoverValue.isEmpty) return front;
    return _HoverFlipKpi(
      front: front,
      back: CRMKPICard(
        title: title,
        value: hoverValue,
        icon: icon,
        iconColor: iconColor,
        benefit: hoverBenefit ?? benefit,
        onTap: onTap,
      ),
    );
  }

  Widget _listingToggle(BuildContext context) {
    const options = ['All', 'Rent', 'Re-Sale'];
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        children: [
          for (final option in options)
            ChoiceChip(
              label: Text(option),
              selected: _listingFilter == option,
              onSelected: (_) => setState(() => _listingFilter = option),
              selectedColor:
                  CRMColors.primaryOf(context).withValues(alpha: 0.18),
              labelStyle: TextStyle(
                fontWeight: FontWeight.w600,
                color: _listingFilter == option
                    ? CRMColors.primaryOf(context)
                    : CRMColors.textSecondaryOf(context),
              ),
            ),
        ],
      ),
    );
  }
}

class _HoverFlipKpi extends StatefulWidget {
  final Widget front;
  final Widget back;

  const _HoverFlipKpi({
    required this.front,
    required this.back,
  });

  @override
  State<_HoverFlipKpi> createState() => _HoverFlipKpiState();
}

class _HoverFlipKpiState extends State<_HoverFlipKpi> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.topLeft,
            children: [
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final rotate = Tween<double>(begin: math.pi / 2, end: 0).animate(animation);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotate.value),
                child: child,
              );
            },
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_hovered),
          child: _hovered ? widget.back : widget.front,
        ),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onCall;
  final VoidCallback onEmail;
  final ValueChanged<bool> onToggleActive;
  final String createdLabel;

  const _ProfileSummaryCard({
    required this.user,
    required this.onCall,
    required this.onEmail,
    required this.onToggleActive,
    required this.createdLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.roleName.toLowerCase() == 'admin' ||
        user.roleName.toLowerCase() == 'super admin';
    final hasPhoto =
        user.profilePhoto != null && user.profilePhoto!.isNotEmpty;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return CRMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: hasPhoto
                      ? CrmNetworkImage(
                          url: user.profilePhoto!,
                          fit: BoxFit.cover,
                          width: 56,
                          height: 56,
                          cacheLogicalWidth: 56,
                          error: (_) => Icon(
                            isAdmin
                                ? Icons.admin_panel_settings_rounded
                                : Icons.person_rounded,
                            color: isAdmin
                                ? CRMColors.info
                                : CRMColors.primaryOf(context),
                          ),
                        )
                      : ColoredBox(
                          color: isAdmin
                              ? CRMColors.info.withValues(alpha: 0.12)
                              : CRMColors.primaryOf(context).withValues(alpha: 0.12),
                          child: Icon(
                            isAdmin
                                ? Icons.admin_panel_settings_rounded
                                : Icons.person_rounded,
                            color: isAdmin
                                ? CRMColors.info
                                : CRMColors.primaryOf(context),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: CRMSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          user.fullName,
                          style: CRMTypography.sectionTitle.copyWith(
                            color: CRMColors.textOf(context),
                          ),
                        ),
                        _StatusChip(
                          label: user.roleName,
                          color: isAdmin
                              ? CRMColors.info
                              : CRMColors.primaryOf(context),
                        ),
                        _StatusChip(
                          label: user.isActive ? 'Active' : 'Inactive',
                          color: user.isActive
                              ? CRMColors.success
                              : CRMColors.danger,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Joined $createdLabel',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                Row(
                  children: [
                    Text(
                      'Active login',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                    Switch(
                      value: user.isActive,
                      activeColor: CRMColors.primaryOf(context),
                      onChanged: onToggleActive,
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: CRMSpacing.m),
          Divider(
            color: CRMColors.borderOf(context).withValues(alpha: 0.5),
            height: 1,
          ),
          const SizedBox(height: CRMSpacing.m),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _InfoAction(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: user.email,
                onTap: onEmail,
              ),
              _InfoAction(
                icon: Icons.phone_outlined,
                label: 'Mobile',
                value: (user.mobile ?? '').trim().isEmpty ? '—' : user.mobile!,
                onTap: (user.mobile ?? '').trim().isEmpty ? null : onCall,
              ),
              _InfoAction(
                icon: Icons.badge_outlined,
                label: 'Reporting / created by',
                value: (user.createdByName ?? '').trim().isEmpty
                    ? '—'
                    : user.createdByName!,
              ),
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: CRMSpacing.s),
            Row(
              children: [
                Text(
                  'Active login',
                  style: CRMTypography.caption.copyWith(
                    color: CRMColors.textSecondaryOf(context),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: user.isActive,
                  activeColor: CRMColors.primaryOf(context),
                  onChanged: onToggleActive,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(CRMBorderRadius.round),
      ),
      child: Text(
        label,
        style: CRMTypography.captionBold.copyWith(color: color, fontSize: 11),
      ),
    );
  }
}

class _InfoAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _InfoAction({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: CRMColors.textSecondaryOf(context)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: CRMTypography.captionBold.copyWith(
                color: CRMColors.textMutedOf(context),
                fontSize: 10,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              value,
              style: CRMTypography.bodyMedium.copyWith(
                color: onTap != null
                    ? CRMColors.primaryOf(context)
                    : CRMColors.textOf(context),
                fontWeight: onTap != null ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
    if (onTap == null) return child;
    return InkWell(onTap: onTap, child: child);
  }
}

Widget _buildSectionPagination({
  required BuildContext context,
  required int startItem,
  required int endItem,
  required int totalItems,
  required int pageSize,
  required int currentPage,
  required int totalPages,
  required ValueChanged<int> onPageSizeChanged,
  required ValueChanged<int> onPageChanged,
}) {
  return Container(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(
          color: CRMColors.borderOf(context).withValues(alpha: 0.4),
        ),
      ),
    ),
    child: LayoutBuilder(
      builder: (context, constraints) {
        final showCompact = constraints.maxWidth < 280;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing $startItem–$endItem of $totalItems',
              style: CRMTypography.caption.copyWith(
                color: CRMColors.textSecondaryOf(context),
                fontSize: 11,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!showCompact)
                  Text(
                    'Rows: ',
                    style: CRMTypography.caption.copyWith(
                      color: CRMColors.textSecondaryOf(context),
                      fontSize: 11,
                    ),
                  ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pageSize,
                    isDense: true,
                    dropdownColor: CRMColors.surfaceElevatedOf(context),
                    icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
                    style: CRMTypography.captionBold.copyWith(
                      color: CRMColors.textOf(context),
                      fontSize: 11,
                    ),
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 15, child: Text('15')),
                    ],
                    onChanged: (val) {
                      if (val != null) onPageSizeChanged(val);
                    },
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed:
                      currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '$currentPage / $totalPages',
                    style: CRMTypography.captionBold.copyWith(
                      color: CRMColors.textOf(context),
                      fontSize: 11,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: currentPage < totalPages
                      ? () => onPageChanged(currentPage + 1)
                      : null,
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _PropertiesSection extends StatefulWidget {
  final UserModel user;
  final List<PropertyModel> properties;
  final bool isMobile;
  final VoidCallback onOpenAll;

  const _PropertiesSection({
    required this.user,
    required this.properties,
    required this.isMobile,
    required this.onOpenAll,
  });

  @override
  State<_PropertiesSection> createState() => _PropertiesSectionState();
}

class _PropertiesSectionState extends State<_PropertiesSection> {
  int _currentPage = 1;
  int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final total = widget.properties.length;
    final totalPages = total == 0 ? 1 : (total / _pageSize).ceil();
    if (_currentPage > totalPages) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;

    final startIndex = (total == 0) ? 0 : (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, total);
    final paged = widget.properties.sublist(startIndex, endIndex);

    final startItem = total == 0 ? 0 : startIndex + 1;
    final endItem = endIndex;

    return CRMCard(
      title: 'Properties added',
      subtitle: total == 0
          ? 'No inventory linked to ${widget.user.fullName}'
          : '$total listing${total == 1 ? '' : 's'}  •  tap a row to open',
      headerAction: TextButton.icon(
        onPressed: widget.onOpenAll,
        icon: const Icon(Icons.open_in_new_rounded, size: 14),
        label: Text(widget.isMobile ? 'All' : 'Open in Properties'),
      ),
      child: total == 0
          ? const SizedBox(height: 8)
          : Column(
              children: [
                for (var i = 0; i < paged.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: CRMColors.borderOf(context).withValues(alpha: 0.4),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onTap: () => showCRMPropertyDrawer(context, paged[i]),
                    title: Text(
                      paged[i].title,
                      style: CRMTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CRMColors.textOf(context),
                      ),
                    ),
                    subtitle: Text(
                      '${paged[i].propertyCode}  •  ${paged[i].areaName}  •  ${paged[i].configurationName ?? '${paged[i].bedrooms} BHK'}  •  ${EmployeeActivity.propertyListingBucket(paged[i])}',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                    trailing: Text(
                      BudgetFormatter.format(paged[i].price),
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.primaryOf(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: CRMSpacing.s),
                _buildSectionPagination(
                  context: context,
                  startItem: startItem,
                  endItem: endItem,
                  totalItems: total,
                  pageSize: _pageSize,
                  currentPage: _currentPage,
                  totalPages: totalPages,
                  onPageSizeChanged: (newSize) {
                    setState(() {
                      _pageSize = newSize;
                      _currentPage = 1;
                    });
                  },
                  onPageChanged: (newPage) {
                    setState(() {
                      _currentPage = newPage;
                    });
                  },
                ),
              ],
            ),
    );
  }
}

class _LeadsSection extends StatefulWidget {
  final List<RequirementModel> leads;
  final int totalUnfiltered;
  final _LeadFocus focus;
  final bool isMobile;
  final String Function(String?) formatFollowup;
  final ValueChanged<_LeadFocus> onChangeFocus;
  final bool showRejected;
  final VoidCallback onOpenAll;

  const _LeadsSection({
    required this.leads,
    required this.totalUnfiltered,
    required this.focus,
    required this.isMobile,
    required this.formatFollowup,
    required this.onChangeFocus,
    this.showRejected = false,
    required this.onOpenAll,
  });

  @override
  State<_LeadsSection> createState() => _LeadsSectionState();
}

class _LeadsSectionState extends State<_LeadsSection> {
  int _currentPage = 1;
  int _pageSize = 10;

  @override
  void didUpdateWidget(covariant _LeadsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focus != widget.focus) {
      _currentPage = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.leads.length;
    final totalPages = total == 0 ? 1 : (total / _pageSize).ceil();
    if (_currentPage > totalPages) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;

    final startIndex = (total == 0) ? 0 : (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, total);
    final paged = widget.leads.sublist(startIndex, endIndex);

    final startItem = total == 0 ? 0 : startIndex + 1;
    final endItem = endIndex;

    return CRMCard(
      title: 'Leads',
      subtitle: '$total shown of ${widget.totalUnfiltered}  •  tap a row to open',
      headerAction: TextButton.icon(
        onPressed: widget.onOpenAll,
        icon: const Icon(Icons.open_in_new_rounded, size: 14),
        label: Text(widget.isMobile ? 'All' : 'Open in Leads'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _focusChip(context, 'All', _LeadFocus.all),
              _focusChip(context, 'Won', _LeadFocus.won),
              if (widget.showRejected)
                _focusChip(context, 'Rejected', _LeadFocus.rejected),
              _focusChip(context, 'Follow-up', _LeadFocus.followup),
              _focusChip(context, 'Overdue', _LeadFocus.overdue),
              _focusChip(context, 'Site visits', _LeadFocus.visits),
              _focusChip(context, 'Assigned', _LeadFocus.assigned),
              _focusChip(context, 'Created', _LeadFocus.created),
            ],
          ),
          const SizedBox(height: CRMSpacing.s),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No leads in this filter.',
                style: CRMTypography.body.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
            )
          else ...[
            for (var i = 0; i < paged.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: CRMColors.borderOf(context).withValues(alpha: 0.4),
                ),
              _LeadTile(lead: paged[i], formatFollowup: widget.formatFollowup),
            ],
            const SizedBox(height: CRMSpacing.s),
            _buildSectionPagination(
              context: context,
              startItem: startItem,
              endItem: endItem,
              totalItems: total,
              pageSize: _pageSize,
              currentPage: _currentPage,
              totalPages: totalPages,
              onPageSizeChanged: (newSize) {
                setState(() {
                  _pageSize = newSize;
                  _currentPage = 1;
                });
              },
              onPageChanged: (newPage) {
                setState(() {
                  _currentPage = newPage;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _focusChip(BuildContext context, String label, _LeadFocus value) {
    final selected = widget.focus == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => widget.onChangeFocus(value),
      selectedColor: CRMColors.primaryOf(context).withValues(alpha: 0.18),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 12,
        color: selected
            ? CRMColors.primaryOf(context)
            : CRMColors.textSecondaryOf(context),
      ),
    );
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

class _LeadTile extends StatelessWidget {
  final RequirementModel lead;
  final String Function(String?) formatFollowup;

  const _LeadTile({required this.lead, required this.formatFollowup});

  @override
  Widget build(BuildContext context) {
    final won = EmployeeActivity.isWon(lead);
    final followup = formatFollowup(lead.nextFollowupDate);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onTap: () => context.push('/requirements?openId=${Uri.encodeComponent(lead.id)}'),
      title: Text(
        lead.clientName,
        style: CRMTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: CRMColors.textOf(context),
        ),
      ),
      subtitle: Text(
        [
          lead.clientMobile,
          '${lead.propertyTypeName}${lead.configurationName != null ? ' (${lead.configurationName})' : ''}',
          if (lead.areaNames.isNotEmpty) lead.areaNames.join(', '),
          if (followup.isNotEmpty) 'Follow-up $followup',
        ].join('  •  '),
        style: CRMTypography.caption.copyWith(
          color: CRMColors.textSecondaryOf(context),
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${BudgetFormatter.format(lead.minBudget)} – ₹${BudgetFormatter.format(lead.maxBudget)}',
            style: CRMTypography.caption.copyWith(
              color: CRMColors.primaryOf(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (won ? CRMColors.success : CRMColors.primaryOf(context))
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _statusLabel(lead.status),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: won ? CRMColors.success : CRMColors.primaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  final List<UserModel> members;

  const _TeamSection({required this.members});

  @override
  Widget build(BuildContext context) {
    return CRMCard(
      title: 'Team members',
      subtitle: members.isEmpty
          ? 'No sales or telecaller profiles report to this admin'
          : '${members.length} people  •  tap to open their page',
      child: members.isEmpty
          ? const SizedBox(height: 8)
          : Column(
              children: [
                for (var i = 0; i < members.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: CRMColors.borderOf(context).withValues(alpha: 0.4),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => context.push('/users/${members[i].id}'),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          CRMColors.primaryOf(context).withValues(alpha: 0.12),
                      child: Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: CRMColors.primaryOf(context),
                      ),
                    ),
                    title: Text(
                      members[i].fullName,
                      style: CRMTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CRMColors.textOf(context),
                      ),
                    ),
                    subtitle: Text(
                      '${members[i].roleName}  •  ${members[i].email}',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                    trailing: _StatusChip(
                      label: members[i].isActive ? 'Active' : 'Inactive',
                      color: members[i].isActive
                          ? CRMColors.success
                          : CRMColors.danger,
                    ),
                  ),
                ],
              ],
            ),
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
              color: CRMColors.textMutedOf(context),
            ),
            const SizedBox(height: CRMSpacing.m),
            Text('Employee not found', style: CRMTypography.sectionTitle),
            const SizedBox(height: CRMSpacing.s),
            Text(
              'This profile may have been removed or you do not have access.',
              textAlign: TextAlign.center,
              style: CRMTypography.body.copyWith(
                color: CRMColors.textSecondaryOf(context),
              ),
            ),
            const SizedBox(height: CRMSpacing.l),
            CRMButton(label: 'Back to Employees', onPressed: onBack),
          ],
        ),
      ),
    );
  }
}

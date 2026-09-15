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
import '../../requirements/models/requirement_model.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../bloc/users_bloc.dart';
import '../models/user_model.dart';
import '../utils/employee_activity.dart';

enum _LeadFocus { all, won, followup, overdue, visits, assigned, created }

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
  String? _activityError;
  List<PropertyModel> _properties = [];
  List<RequirementModel> _requirements = [];
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
        PropertiesRepository().getProperties(),
        RequirementsRepository().getRequirements(),
      ]);
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

    final allProps = _properties
        .where((p) => EmployeeActivity.belongsToProperty(p, user))
        .toList();
    final allReqs = _requirements
        .where((r) => EmployeeActivity.belongsToRequirement(r, user))
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

    final focusedReqs = visibleReqs.where((r) {
      switch (_leadFocus) {
        case _LeadFocus.all:
          return true;
        case _LeadFocus.won:
          return EmployeeActivity.isWon(r);
        case _LeadFocus.followup:
          return EmployeeActivity.isPendingFollowup(r);
        case _LeadFocus.overdue:
          return EmployeeActivity.isOverdueFollowup(r);
        case _LeadFocus.visits:
          return EmployeeActivity.hasSiteVisit(r);
        case _LeadFocus.assigned:
          return EmployeeActivity.isAssignedTo(r, user);
        case _LeadFocus.created:
          return EmployeeActivity.isCreatedBy(r, user);
      }
    }).toList();

    final wonCount = visibleReqs.where(EmployeeActivity.isWon).length;
    final pendingFollowups =
        visibleReqs.where(EmployeeActivity.isPendingFollowup).length;
    final overdueFollowups =
        visibleReqs.where(EmployeeActivity.isOverdueFollowup).length;
    final siteVisits = visibleReqs.where(EmployeeActivity.hasSiteVisit).length;
    final assignedCount = visibleReqs
        .where((r) => EmployeeActivity.isAssignedTo(r, user))
        .length;
    final createdCount = visibleReqs
        .where((r) => EmployeeActivity.isCreatedBy(r, user))
        .length;
    final conversion =
        visibleReqs.isEmpty ? 0.0 : (wonCount / visibleReqs.length) * 100;

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
                        CRMKPICard(
                          title: 'LEADS',
                          value: visibleReqs.length.toString(),
                          icon: Icons.assignment_outlined,
                          iconColor: CRMColors.info,
                          benefit: 'Tap to view assigned & created leads',
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
                        CRMKPICard(
                          title: 'FOLLOW-UPS',
                          value: pendingFollowups.toString(),
                          icon: Icons.event_available_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          benefit: 'Upcoming  •  Tap to open',
                          onTap: () {
                            setState(() => _leadFocus = _LeadFocus.followup);
                            _scrollTo(_leadsKey);
                          },
                        ),
                        CRMKPICard(
                          title: 'OVERDUE',
                          value: overdueFollowups.toString(),
                          icon: Icons.event_busy_rounded,
                          iconColor: CRMColors.danger,
                          benefit: 'Missed follow-ups  •  Tap to open',
                          onTap: () {
                            setState(() => _leadFocus = _LeadFocus.overdue);
                            _scrollTo(_leadsKey);
                          },
                        ),
                        CRMKPICard(
                          title: 'SITE VISITS',
                          value: siteVisits.toString(),
                          icon: Icons.location_on_outlined,
                          iconColor: const Color(0xFF8B5CF6),
                          benefit: 'Leads with visits  •  Tap to open',
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
                        CRMKPICard(
                          title: 'ASSIGNED LEADS',
                          value: assignedCount.toString(),
                          icon: Icons.person_pin_circle_outlined,
                          iconColor: CRMColors.info,
                          benefit: 'Currently on their plate',
                          onTap: () {
                            setState(() => _leadFocus = _LeadFocus.assigned);
                            _scrollTo(_leadsKey);
                          },
                        ),
                        CRMKPICard(
                          title: 'CREATED LEADS',
                          value: createdCount.toString(),
                          icon: Icons.post_add_rounded,
                          iconColor: CRMColors.primaryOf(context),
                          benefit: 'Leads they originated',
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
                      ],
                    ),
                    const SizedBox(height: CRMSpacing.m),
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
                        onOpenAll: () => context.push(
                          '/requirements?search=${Uri.encodeComponent(user.fullName)}',
                        ),
                      ),
                    ),
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

class _PropertiesSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return CRMCard(
      title: 'Properties added',
      subtitle: properties.isEmpty
          ? 'No inventory linked to ${user.fullName}'
          : '${properties.length} listing${properties.length == 1 ? '' : 's'}  •  tap a row to open',
      headerAction: TextButton.icon(
        onPressed: onOpenAll,
        icon: const Icon(Icons.open_in_new_rounded, size: 14),
        label: Text(isMobile ? 'All' : 'Open in Properties'),
      ),
      child: properties.isEmpty
          ? const SizedBox(height: 8)
          : Column(
              children: [
                for (var i = 0; i < properties.take(30).length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: CRMColors.borderOf(context).withValues(alpha: 0.4),
                    ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onTap: () =>
                        showCRMPropertyDrawer(context, properties[i]),
                    title: Text(
                      properties[i].title,
                      style: CRMTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: CRMColors.textOf(context),
                      ),
                    ),
                    subtitle: Text(
                      '${properties[i].propertyCode}  •  ${properties[i].areaName}  •  ${properties[i].configurationName ?? '${properties[i].bedrooms} BHK'}  •  ${EmployeeActivity.propertyListingBucket(properties[i])}',
                      style: CRMTypography.caption.copyWith(
                        color: CRMColors.textSecondaryOf(context),
                      ),
                    ),
                    trailing: Text(
                      BudgetFormatter.format(properties[i].price),
                      style: CRMTypography.bodyMedium.copyWith(
                        color: CRMColors.primaryOf(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (properties.length > 30)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: onOpenAll,
                      child: Text('View all ${properties.length} properties'),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _LeadsSection extends StatelessWidget {
  final List<RequirementModel> leads;
  final int totalUnfiltered;
  final _LeadFocus focus;
  final bool isMobile;
  final String Function(String?) formatFollowup;
  final ValueChanged<_LeadFocus> onChangeFocus;
  final VoidCallback onOpenAll;

  const _LeadsSection({
    required this.leads,
    required this.totalUnfiltered,
    required this.focus,
    required this.isMobile,
    required this.formatFollowup,
    required this.onChangeFocus,
    required this.onOpenAll,
  });

  @override
  Widget build(BuildContext context) {
    return CRMCard(
      title: 'Leads & follow-ups',
      subtitle: '${leads.length} shown of $totalUnfiltered  •  tap a row to open',
      headerAction: TextButton.icon(
        onPressed: onOpenAll,
        icon: const Icon(Icons.open_in_new_rounded, size: 14),
        label: Text(isMobile ? 'All' : 'Open in Leads'),
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
              _focusChip(context, 'Follow-up', _LeadFocus.followup),
              _focusChip(context, 'Overdue', _LeadFocus.overdue),
              _focusChip(context, 'Site visits', _LeadFocus.visits),
              _focusChip(context, 'Assigned', _LeadFocus.assigned),
              _focusChip(context, 'Created', _LeadFocus.created),
            ],
          ),
          const SizedBox(height: CRMSpacing.s),
          if (leads.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No leads in this filter.',
                style: CRMTypography.body.copyWith(
                  color: CRMColors.textSecondaryOf(context),
                ),
              ),
            )
          else
            for (var i = 0; i < leads.take(30).length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  color: CRMColors.borderOf(context).withValues(alpha: 0.4),
                ),
              _LeadTile(lead: leads[i], formatFollowup: formatFollowup),
            ],
          if (leads.length > 30)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: onOpenAll,
                child: Text('View all ${leads.length} leads'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _focusChip(BuildContext context, String label, _LeadFocus value) {
    final selected = focus == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onChangeFocus(value),
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

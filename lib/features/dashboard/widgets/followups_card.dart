import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/security/role_guard.dart';
import '../../../core/storage/local_repositories.dart';
import '../../../core/storage/model_mappers.dart';
import '../../../core/storage/repository_coordinator.dart';
import '../../requirements/models/requirement_model.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../../requirements/services/followup_sync_engine.dart';
import '../../users/bloc/users_bloc.dart';
import '../models/dashboard_summary.dart';

class FollowupsCard extends StatefulWidget {
  final List<DashboardFollowup> followups;
  final List<DashboardSiteVisit>? siteVisits;
  final VoidCallback? onViewAll;
  final Function(DashboardFollowup)? onFollowupTap;
  final VoidCallback? onAddFollowup;

  const FollowupsCard({
    super.key,
    required this.followups,
    this.siteVisits,
    this.onViewAll,
    this.onFollowupTap,
    this.onAddFollowup,
  });

  @override
  State<FollowupsCard> createState() => _FollowupsCardState();
}

class _FollowupsCardState extends State<FollowupsCard> {
  String _mainSection = 'Follow ups';
  String _activeTab = 'Today';
  late Future<List<RequirementModel>> _requirementsFuture;
  StreamSubscription? _requirementsStreamSub;
  StreamSubscription? _dashboardStreamSub;

  @override
  void initState() {
    super.initState();
    _requirementsFuture = RequirementsRepository().getRequirements(refreshFromServer: false);
    _requirementsStreamSub = RepositoryCoordinator().requirementsStream.listen((_) {
      if (mounted) {
        setState(() {
          _requirementsFuture = RequirementsRepository().getRequirements(refreshFromServer: false);
        });
      }
    });
    _dashboardStreamSub = RepositoryCoordinator().dashboardStream.listen((_) {
      if (mounted) {
        setState(() {
          _requirementsFuture = RequirementsRepository().getRequirements(refreshFromServer: false);
        });
      }
    });
  }

  @override
  void dispose() {
    _requirementsStreamSub?.cancel();
    _dashboardStreamSub?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(FollowupsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.followups != widget.followups || oldWidget.siteVisits != widget.siteVisits) {
      _requirementsFuture = RequirementsRepository().getRequirements(refreshFromServer: false);
    }
  }

  Widget _buildMainModeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final primaryColor = ThemeManager().primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor
              : (isDark ? const Color(0xFF243044) : const Color(0xFFF1F4F9)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? primaryColor
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;

    return FutureBuilder<List<RequirementModel>>(
      future: _requirementsFuture,
      builder: (context, snapshot) {
        final reqsList = snapshot.data ?? [];

        List<dynamic>? users;
        try {
          final usersState = context.read<UsersBloc>().state;
          if (usersState is UsersLoaded) {
            users = usersState.users;
          }
        } catch (_) {}

        final localFollowups = FollowupLocalRepository.inMemory.values.map((fl) => fl.toModel()).toList();
        final targetListingType = ThemeManager().isRentMode ? 'Rent' : 'Re-Sale';
        final isSiteVisitSection = _mainSection == 'Site Visit Scheduled';

        final syncResult = FollowupSyncEngine.categorizeFollowups(
          serverFollowups: widget.followups,
          localFollowups: localFollowups,
          reqsList: reqsList,
          siteVisits: widget.siteVisits,
          isSiteVisitSection: isSiteVisitSection,
          targetListingType: targetListingType,
          currentUser: RoleGuard.currentUser,
          users: users,
        );

        final todayList = syncResult.today;
        final dueList = syncResult.due;
        final futureList = syncResult.future;
        final allClients = syncResult.allClients;

        List<DashboardFollowup> activeItems;
        if (_activeTab == 'Due') {
          activeItems = dueList;
        } else if (_activeTab == 'Future') {
          activeItems = futureList;
        } else {
          activeItems = todayList;
        }

        final totalPending = allClients.length;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Card Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_available_rounded,
                          size: 18,
                          color: ThemeManager().primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scheduled',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF14213D),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeManager().primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$totalPending Pending',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: ThemeManager().primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.onAddFollowup != null)
                      InkWell(
                        onTap: widget.onAddFollowup,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ThemeManager().primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: ThemeManager().primaryColor,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Add',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: ThemeManager().primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Main Mode Switcher: Follow ups vs Site Visit Scheduled ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMainModeButton(
                        label: 'Follow ups',
                        icon: Icons.phone_callback_rounded,
                        isSelected: _mainSection == 'Follow ups',
                        isDark: isDark,
                        onTap: () => setState(() => _mainSection = 'Follow ups'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMainModeButton(
                        label: 'Site Visit Scheduled',
                        icon: Icons.directions_car_rounded,
                        isSelected: _mainSection == 'Site Visit Scheduled',
                        isDark: isDark,
                        onTap: () => setState(() => _mainSection = 'Site Visit Scheduled'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── Segment Sub-Tabs: Today, Due, Future ────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF243044)
                        : const Color(0xFFF1F4F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      _buildTab('Today', 'Today (${todayList.length})', isDark),
                      _buildTab('Due', 'Due (${dueList.length})', isDark),
                      _buildTab('Future', 'Future (${futureList.length})', isDark),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
              ),

              // ── Items List ───────────────────────────────────────
              if (activeItems.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeItems.length.clamp(0, 4),
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color:
                        isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
                  ),
                  itemBuilder: (context, index) {
                    final item = activeItems[index];
                    return _buildFollowupRow(item, isDark);
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 36,
                          color: ThemeManager().primaryColor.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isSiteVisitSection ? 'No $_activeTab site visits' : 'No $_activeTab follow-ups',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF14213D),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isSiteVisitSection ? 'Scheduled site visits will appear here.' : 'Scheduled reminders will appear here.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF68738A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

              Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
              ),

              // ── Bottom "View All" Button ──────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton(
                    onPressed:
                        widget.onViewAll ??
                        () => context.go('/requirements?tab=Follow-ups&section=${isSiteVisitSection ? "Site Visit Scheduled" : "Follow ups"}'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ThemeManager().primaryColor,
                      side: BorderSide(color: ThemeManager().primaryColor, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isSiteVisitSection ? 'View All Site Visits' : 'View All Follow-ups',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTab(String key, String label, bool isDark) {
    final isSelected = _activeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = key),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected
                  ? ThemeManager().primaryColor
                  : (isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF68738A)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowupRow(DashboardFollowup item, bool isDark) {
    final role = (RoleGuard.currentUser?.role ?? '').toLowerCase();
    final isRealAdmin = role == 'admin' || role == 'super admin';

    final clientName = item.clientName.isNotEmpty
        ? item.clientName
        : (item.requirementCustomerName ?? 'Client');
    final phone = item.mobile;
    final modeLabel = ThemeManager().isRentMode ? 'Rent' : 'Re-Sale';
    final property = [
      if (item.propertyTitle != null && item.propertyTitle!.isNotEmpty)
        item.propertyTitle!
      else
        modeLabel,
      if (item.notes != null && item.notes!.isNotEmpty) item.notes!,
    ].join(' · ');

    final dt = parseFollowupDateTime(item.followupDate);
    final timeText = dt != null
        ? DateFormat('d MMM, h:mm a').format(dt)
        : (item.followupDate.isNotEmpty ? item.followupDate : 'Scheduled');

    final displaySalesperson = (item.salespersonName != null &&
            item.salespersonName!.trim().isNotEmpty &&
            item.salespersonName != 'System' &&
            item.salespersonName != 'Unassigned')
        ? item.salespersonName!.trim()
        : ((item.creatorName != null &&
                item.creatorName!.trim().isNotEmpty &&
                item.creatorName != 'System' &&
                item.creatorName != 'Unassigned')
            ? item.creatorName!.trim()
            : null);

    final primaryColor = ThemeManager().primaryColor;

    return InkWell(
      onTap: () => widget.onFollowupTap?.call(item),
      hoverColor: isDark ? const Color(0xFF243044) : const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: primaryColor.withValues(alpha: 0.1),
              child: Text(
                clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF14213D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isRealAdmin && displaySalesperson != null && displaySalesperson.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 12,
                          color: Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            'Salesperson: $displaySalesperson',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (property.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      property,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF68738A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: primaryColor,
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(
                        'tel:${phone.replaceAll(' ', '')}',
                      );
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone_in_talk_rounded,
                          size: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF68738A),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF68738A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

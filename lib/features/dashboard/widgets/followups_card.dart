import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';
import '../../../core/theme/theme_manager.dart';
import '../../../core/storage/local_repositories.dart';
import '../../../core/storage/model_mappers.dart';
import '../../requirements/models/requirement_model.dart';
import '../../requirements/repository/requirements_repository.dart';
import '../models/dashboard_summary.dart';

DateTime? _parseFollowupDateTime(dynamic raw) {
  if (raw == null) return null;
  String str = raw.toString().trim();
  if (str.isEmpty) return null;

  final parsed = DateTime.tryParse(str);
  if (parsed != null) {
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  try {
    final parts = str.split(RegExp(r'[T\s]'));
    final dateParts = parts[0].split(RegExp(r'[/\\-]'));
    if (dateParts.length == 3) {
      int d, m, y;
      if (dateParts[0].length == 4) {
        y = int.parse(dateParts[0]);
        m = int.parse(dateParts[1]);
        d = int.parse(dateParts[2]);
      } else {
        d = int.parse(dateParts[0]);
        m = int.parse(dateParts[1]);
        y = int.parse(dateParts[2]);
      }
      int h = 0, min = 0, sec = 0;
      if (parts.length > 1 && parts[1].isNotEmpty) {
        final timeParts = parts[1].split(':');
        if (timeParts.length >= 2) {
          h = int.tryParse(timeParts[0]) ?? 0;
          min = int.tryParse(timeParts[1].replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          if (timeParts.length >= 3) {
            sec = int.tryParse(timeParts[2].replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
          }
        }
      }
      return DateTime(y, m, d, h, min, sec);
    }
  } catch (_) {}

  return null;
}

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

  @override
  void initState() {
    super.initState();
    _requirementsFuture = RequirementsRepository().getRequirements(refreshFromServer: false);
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return FutureBuilder<List<RequirementModel>>(
      future: _requirementsFuture,
      builder: (context, snapshot) {
        final reqsList = snapshot.data ?? [];

        final localFollowups = FollowupLocalRepository.inMemory.values.map((fl) => fl.toModel()).toList();
        final followups = [
          ...localFollowups,
          ...widget.followups,
        ];

        bool isSameMobile(String m1, String m2) {
          final d1 = m1.replaceAll(RegExp(r'\D'), '');
          final d2 = m2.replaceAll(RegExp(r'\D'), '');
          if (d1.isEmpty || d2.isEmpty) return false;
          if (d1 == d2) return true;
          final s1 = d1.length >= 10 ? d1.substring(d1.length - 10) : d1;
          final s2 = d2.length >= 10 ? d2.substring(d2.length - 10) : d2;
          return s1 == s2;
        }

        String getListingTypeLabel(RequirementModel r) {
          final name = r.listingTypeName ?? '';
          final id = r.listingTypeId ?? '';
          final combined = '$name $id'.toLowerCase();
          if (combined.contains('rent')) {
            return 'Rent';
          } else if (combined.contains('sale') || combined.contains('resale')) {
            return 'Re-Sale';
          }
          return 'Rent';
        }

        bool isSiteVisitStatus(String statusStr) {
          final s = statusStr.toLowerCase();
          return s.contains('site visit') || s.contains('site-visit');
        }

        final isRentMode = ThemeManager().isRentMode;
        final targetListingType = isRentMode ? 'Rent' : 'Re-Sale';

        final isSiteVisitSection = _mainSection == 'Site Visit Scheduled';
        final Map<String, DashboardFollowup> itemsMap = {};

        if (isSiteVisitSection) {
          // A) SITE VISIT SCHEDULED SECTION
          if (reqsList.isNotEmpty) {
            for (final req in reqsList) {
              final reqStatus = req.status;
              if (reqStatus == 'Bin' || reqStatus == 'Won' || reqStatus == 'Closed' || reqStatus.startsWith('Rejected') || reqStatus == 'Dead') continue;
              if (getListingTypeLabel(req) != targetListingType) continue;

              if (isSiteVisitStatus(reqStatus)) {
                final matchingF = followups.firstWhereOrNull((f) =>
                    (f.requirementId != null && f.requirementId!.isNotEmpty && req.id == f.requirementId) ||
                    (f.mobile.isNotEmpty && req.clientMobile.isNotEmpty && isSameMobile(req.clientMobile, f.mobile)) ||
                    (f.clientName.isNotEmpty && req.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));

                final dateStr = matchingF?.followupDate ?? req.nextFollowupDate ?? req.createdAt.toIso8601String();
                final notesStr = matchingF?.notes ?? req.remarks;

                itemsMap[req.id] = DashboardFollowup(
                  id: matchingF?.id ?? 'sv_${req.id}',
                  clientName: req.clientName,
                  mobile: req.clientMobile,
                  followupDate: dateStr,
                  notes: notesStr,
                  status: reqStatus,
                  propertyTitle: matchingF?.propertyTitle,
                  requirementCustomerName: req.clientName,
                  requirementId: req.id,
                  creatorName: matchingF?.creatorName,
                );
              }
            }
          }
          if (widget.siteVisits != null) {
            for (final sv in widget.siteVisits!) {
              RequirementModel? req;
              if (reqsList.isNotEmpty) {
                req = reqsList.firstWhereOrNull((r) =>
                    (sv.requirementId != null && sv.requirementId!.isNotEmpty && r.id == sv.requirementId) ||
                    (sv.requirementCustomerName != null && sv.requirementCustomerName!.isNotEmpty && r.clientName.trim().toLowerCase() == sv.requirementCustomerName!.trim().toLowerCase()));

                if (req != null) {
                  final reqStatus = req.status;
                  if (reqStatus == 'Bin' || reqStatus == 'Won' || reqStatus == 'Closed' || reqStatus.startsWith('Rejected') || reqStatus == 'Dead') continue;
                  if (getListingTypeLabel(req) != targetListingType) continue;
                }
              }

              final key = req?.id ?? sv.id;
              if (!itemsMap.containsKey(key)) {
                itemsMap[key] = DashboardFollowup(
                  id: sv.id,
                  clientName: sv.requirementCustomerName ?? 'Client',
                  mobile: req?.clientMobile ?? '',
                  followupDate: sv.visitDate,
                  notes: sv.remarks,
                  status: sv.status,
                  propertyTitle: sv.propertyTitle,
                  requirementCustomerName: sv.requirementCustomerName,
                  requirementId: sv.requirementId,
                  creatorName: sv.creatorName,
                );
              }
            }
          }
        } else {
          // B) FOLLOW UPS SECTION
          for (final f in followups) {
            RequirementModel? req;
            if (reqsList.isNotEmpty) {
              req = reqsList.firstWhereOrNull((r) =>
                  (f.requirementId != null && f.requirementId!.isNotEmpty && r.id == f.requirementId) ||
                  (f.mobile.isNotEmpty && r.clientMobile.isNotEmpty && isSameMobile(r.clientMobile, f.mobile)) ||
                  (f.clientName.isNotEmpty && r.clientName.trim().toLowerCase() == f.clientName.trim().toLowerCase()));

              if (req == null) continue;

              final reqStatus = req.status;
              if (reqStatus == 'Bin' || reqStatus == 'Won' || reqStatus == 'Closed' || reqStatus.startsWith('Rejected') || reqStatus == 'Dead') continue;

              // EXCLUDE if lead status is Site Visit!
              if (isSiteVisitStatus(reqStatus)) continue;

              if (getListingTypeLabel(req) != targetListingType) continue;
            } else {
              final statusLower = f.status.toLowerCase();
              if (statusLower == 'completed' ||
                  statusLower == 'resolved' ||
                  statusLower == 'closed' ||
                  statusLower == 'done' ||
                  statusLower == 'bin' ||
                  statusLower == 'deleted' ||
                  statusLower.contains('site visit')) {
                continue;
              }
            }

            final key = req != null ? req.id : (f.requirementId ?? f.id);
            final existing = itemsMap[key];
            if (existing == null) {
              itemsMap[key] = f;
            } else {
              final bool fIsPending = f.status == 'Pending' || f.status == 'Follow-up' || f.status == 'Re-Followup';
              final bool existingIsPending = existing.status == 'Pending' || existing.status == 'Follow-up' || existing.status == 'Re-Followup';

              if (f.id.startsWith('local_') && !existing.id.startsWith('local_')) {
                itemsMap[key] = f;
              } else if (!f.id.startsWith('local_') && existing.id.startsWith('local_')) {
                // Keep existing local
              } else if (fIsPending && !existingIsPending) {
                itemsMap[key] = f;
              } else {
                itemsMap[key] = f;
              }
            }
          }
        }

        final todayList = <DashboardFollowup>[];
        final dueList = <DashboardFollowup>[];
        final futureList = <DashboardFollowup>[];

        for (final f in itemsMap.values) {
          DateTime? parsed = _parseFollowupDateTime(f.followupDate);
          if (parsed == null && f.followupDate.isNotEmpty) {
            try {
              final parts = f.followupDate.split(RegExp(r'[/\\-]'));
              if (parts.length >= 3) {
                final d = int.tryParse(parts[0]);
                final m = int.tryParse(parts[1]);
                final y = int.tryParse(parts[2]);
                if (d != null && m != null && y != null) {
                  parsed = DateTime(y, m, d);
                }
              }
            } catch (_) {}
          }
          if (parsed == null) {
            dueList.add(f);
            continue;
          }
          final fDate = DateTime(parsed.year, parsed.month, parsed.day);

          if (fDate.isBefore(today)) {
            dueList.add(f);
          } else if (fDate.isAfter(today)) {
            futureList.add(f);
          } else {
            todayList.add(f);
          }
        }

        todayList.sort(
          (a, b) => (_parseFollowupDateTime(a.followupDate) ?? DateTime(1970)).compareTo(
            _parseFollowupDateTime(b.followupDate) ?? DateTime(1970),
          ),
        );
        dueList.sort(
          (a, b) => (_parseFollowupDateTime(b.followupDate) ?? DateTime(1970)).compareTo(
            _parseFollowupDateTime(a.followupDate) ?? DateTime(1970),
          ),
        );
        futureList.sort(
          (a, b) => (_parseFollowupDateTime(a.followupDate) ?? DateTime(1970)).compareTo(
            _parseFollowupDateTime(b.followupDate) ?? DateTime(1970),
          ),
        );

        List<DashboardFollowup> activeItems;
        if (_activeTab == 'Due') {
          activeItems = dueList;
        } else if (_activeTab == 'Future') {
          activeItems = futureList;
        } else {
          activeItems = todayList;
        }

        final totalPending = todayList.length + dueList.length;

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
                        () => context.go('/requirements?tab=${isSiteVisitSection ? "Leads" : "Follow-ups"}'),
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

    final dt = _parseFollowupDateTime(item.followupDate);
    final timeText = dt != null
        ? DateFormat('d MMM, h:mm a').format(dt)
        : (item.followupDate.isNotEmpty ? item.followupDate : 'Scheduled');

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

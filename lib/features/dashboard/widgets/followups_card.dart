import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/dashboard_summary.dart';

class FollowupsCard extends StatefulWidget {
  final List<DashboardFollowup> followups;
  final VoidCallback? onViewAll;
  final Function(DashboardFollowup)? onFollowupTap;
  final VoidCallback? onAddFollowup;

  const FollowupsCard({
    super.key,
    required this.followups,
    this.onViewAll,
    this.onFollowupTap,
    this.onAddFollowup,
  });

  @override
  State<FollowupsCard> createState() => _FollowupsCardState();
}

class _FollowupsCardState extends State<FollowupsCard> {
  String _activeTab = 'Today';

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final Map<String, DashboardFollowup> latestDashFollowupsMap = {};
    for (final f in widget.followups) {
      final reqIdStr = f.requirementId ?? '';
      final key = reqIdStr.isNotEmpty ? reqIdStr : f.id;
      final existing = latestDashFollowupsMap[key];
      if (existing == null) {
        latestDashFollowupsMap[key] = f;
      } else {
        final dtExisting =
            DateTime.tryParse(existing.followupDate) ?? DateTime(1970);
        final dtCurrent = DateTime.tryParse(f.followupDate) ?? DateTime(1970);
        if (dtCurrent.isAfter(dtExisting)) {
          latestDashFollowupsMap[key] = f;
        }
      }
    }

    final activeFollowups = latestDashFollowupsMap.values.where((f) {
      final statusLower = f.status.toLowerCase();
      return statusLower != 'completed' &&
          statusLower != 'resolved' &&
          statusLower != 'closed' &&
          statusLower != 'done';
    }).toList();

    final todayList = <DashboardFollowup>[];
    final dueList = <DashboardFollowup>[];
    final futureList = <DashboardFollowup>[];

    for (final f in activeFollowups) {
      final parsed = DateTime.tryParse(f.followupDate);
      if (parsed == null) continue;
      final fDate = DateTime(parsed.year, parsed.month, parsed.day);
      if (fDate.isBefore(today)) {
        dueList.add(f);
      } else if (fDate.isAtSameMomentAs(today)) {
        todayList.add(f);
      } else {
        futureList.add(f);
      }
    }

    todayList.sort(
      (a, b) => (DateTime.tryParse(b.followupDate) ?? DateTime(0)).compareTo(
        DateTime.tryParse(a.followupDate) ?? DateTime(0),
      ),
    );
    dueList.sort(
      (a, b) => (DateTime.tryParse(b.followupDate) ?? DateTime(0)).compareTo(
        DateTime.tryParse(a.followupDate) ?? DateTime(0),
      ),
    );
    futureList.sort(
      (a, b) => (DateTime.tryParse(b.followupDate) ?? DateTime(0)).compareTo(
        DateTime.tryParse(a.followupDate) ?? DateTime(0),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.phone_callback_rounded,
                      size: 18,
                      color: ThemeManager().primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Follow-ups',
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

          // ── Segment Tabs: Today, Due, Future ────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Container(
              height: 36,
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
                      'No $_activeTab follow-ups',
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
                      'Scheduled reminders will appear here.',
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

          // ── Bottom "View All Follow-ups" Button ──────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton(
                onPressed:
                    widget.onViewAll ??
                    () => context.go('/requirements?tab=Follow-ups'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ThemeManager().primaryColor,
                  side: BorderSide(color: ThemeManager().primaryColor, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'View All Follow-ups',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
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
    final property = [
      if (item.propertyTitle != null && item.propertyTitle!.isNotEmpty)
        item.propertyTitle!,
      if (item.notes != null && item.notes!.isNotEmpty) item.notes!,
    ].join(' · ');

    final dt = DateTime.tryParse(item.followupDate);
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

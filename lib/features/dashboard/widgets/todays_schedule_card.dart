import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/dashboard_summary.dart';

class TodaysScheduleCard extends StatelessWidget {
  final List<DashboardSiteVisit> siteVisits;
  final VoidCallback? onViewCalendar;
  final Function(DashboardSiteVisit)? onSiteVisitTap;

  const TodaysScheduleCard({
    super.key,
    required this.siteVisits,
    this.onViewCalendar,
    this.onSiteVisitTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;

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
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: ThemeManager().primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF14213D),
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (siteVisits.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF243044)
                              : const Color(0xFFF1F4F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${siteVisits.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF68738A),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton(
                  onPressed:
                      onViewCalendar ??
                      () {
                        _showSiteVisitsCalendarDialog(context, siteVisits);
                      },
                  style: TextButton.styleFrom(
                    foregroundColor: ThemeManager().primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('View Calendar'),
                ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          ),

          // ── Schedule Item List ───────────────────────────────
          if (siteVisits.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: siteVisits.length.clamp(0, 4),
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color:
                    isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
              ),
              itemBuilder: (context, index) {
                final visit = siteVisits[index];
                final parsed = DateTime.tryParse(visit.visitDate);
                final timeStr = parsed != null
                    ? '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}'
                    : (visit.visitDate.isNotEmpty ? visit.visitDate : 'Today');

                final title =
                    visit.requirementCustomerName != null &&
                        visit.requirementCustomerName!.isNotEmpty
                    ? 'Visit: ${visit.requirementCustomerName}'
                    : (visit.propertyTitle ?? 'Property Site Visit');

                final detailsList = [
                  if (visit.propertyTitle != null &&
                      visit.propertyTitle!.isNotEmpty &&
                      visit.requirementCustomerName != null)
                    visit.propertyTitle!,
                  if (visit.creatorName != null &&
                      visit.creatorName!.isNotEmpty)
                    'Agent: ${visit.creatorName}',
                  if (visit.remarks != null && visit.remarks!.isNotEmpty)
                    visit.remarks!,
                ];
                final subtitle = detailsList.isNotEmpty
                    ? detailsList.join(' · ')
                    : 'Scheduled Visit';

                return ScheduleItem(
                  title: title,
                  activityType: visit.status.isNotEmpty
                      ? visit.status
                      : 'Site Visit',
                  time: timeStr,
                  locationAndPhone: subtitle,
                  onTap: () => onSiteVisitTap?.call(visit),
                );
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
                      Icons.calendar_month_outlined,
                      size: 36,
                      color: const Color(0xFF68738A).withValues(alpha: 0.35),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No site visits scheduled today',
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
                      'Client visits and inspections will appear here.',
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
        ],
      ),
    );
  }
}

class ScheduleItem extends StatelessWidget {
  final String title;
  final String activityType;
  final String time;
  final String locationAndPhone;
  final String? phone;
  final VoidCallback? onTap;

  const ScheduleItem({
    super.key,
    required this.title,
    required this.activityType,
    required this.time,
    required this.locationAndPhone,
    this.phone,
    this.onTap,
  });

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'inspection':
        return const Color(0xFF3B82F6);
      case 'documentation':
        return const Color(0xFF8B5CF6);
      case 'site visit':
      default:
        return ThemeManager().primaryColor;
    }
  }

  Future<void> _makeCall(BuildContext context) async {
    if (phone != null && phone!.isNotEmpty) {
      final uri = Uri.parse('tel:${phone!.replaceAll(' ', '')}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Calling $phone')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = ThemeManager();
    final isDark = themeManager.isDarkMode;
    final primaryColor = themeManager.primaryColor;
    final color = _getTypeColor(activityType);

    return InkWell(
      onTap: onTap,
      hoverColor: isDark ? const Color(0xFF243044) : const Color(0xFFF8FAFC),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF243044)
                    : const Color(0xFFF1F4F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF14213D),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF14213D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          activityType,
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    locationAndPhone,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF68738A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            if (phone != null && phone!.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.phone_rounded,
                    color: primaryColor,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => _makeCall(context),
                  tooltip: 'Call client',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _showSiteVisitsCalendarDialog(BuildContext context, List<DashboardSiteVisit> siteVisits) {
  showDialog(
    context: context,
    builder: (context) {
      DateTime selectedMonth = DateTime.now();
      DateTime? selectedDate;
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = ThemeManager().isDarkMode;
          final primaryColor = ThemeManager().primaryColor;

          final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
          final firstWeekday = DateTime(selectedMonth.year, selectedMonth.month, 1).weekday % 7;

          final monthName = [
            'January', 'February', 'March', 'April', 'May', 'June',
            'July', 'August', 'September', 'October', 'November', 'December'
          ][selectedMonth.month - 1];

          final Map<int, List<DashboardSiteVisit>> visitsByDay = {};
          for (final visit in siteVisits) {
            DateTime? dt;
            if (visit.visitDate.isNotEmpty) {
              dt = DateTime.tryParse(visit.visitDate);
            }
            dt ??= DateTime.now();
            if (dt.year == selectedMonth.year && dt.month == selectedMonth.month) {
              visitsByDay.putIfAbsent(dt.day, () => []).add(visit);
            }
          }

          final selectedDayVisits = selectedDate != null && selectedDate!.month == selectedMonth.month && selectedDate!.year == selectedMonth.year
              ? (visitsByDay[selectedDate!.day] ?? [])
              : [];

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_month_rounded, color: primaryColor, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              'Site Visits Calendar',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF14213D),
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () {
                            setDialogState(() {
                              selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                              selectedDate = null;
                            });
                          },
                        ),
                        Text(
                          '$monthName ${selectedMonth.year}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () {
                            setDialogState(() {
                              selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                              selectedDate = null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'].map((w) {
                        return Expanded(
                          child: Center(
                            child: Text(
                              w,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.1,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: firstWeekday + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < firstWeekday) {
                          return const SizedBox.shrink();
                        }
                        final dayNum = index - firstWeekday + 1;
                        final dayVisits = visitsByDay[dayNum] ?? [];
                        final count = dayVisits.length;
                        final isToday = dayNum == DateTime.now().day &&
                            selectedMonth.month == DateTime.now().month &&
                            selectedMonth.year == DateTime.now().year;
                        final isSelected = selectedDate != null && selectedDate!.day == dayNum;

                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedDate = DateTime(selectedMonth.year, selectedMonth.month, dayNum);
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor.withValues(alpha: 0.2)
                                  : (isToday ? primaryColor.withValues(alpha: 0.08) : Colors.transparent),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : (isToday ? primaryColor.withValues(alpha: 0.5) : Colors.transparent),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNum',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: (isToday || isSelected || count > 0) ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected
                                        ? primaryColor
                                        : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$count visit${count > 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    if (selectedDate != null) ...[
                      const Divider(height: 20),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Scheduled Visits on ${selectedDate!.day} $monthName:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (selectedDayVisits.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Text(
                            'No site visits scheduled for this date.',
                            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 12),
                          ),
                        )
                      else
                        Column(
                          children: selectedDayVisits.map((v) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 15, color: primaryColor),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (v.requirementCustomerName != null && v.requirementCustomerName!.isNotEmpty)
                                              ? v.requirementCustomerName!
                                              : (v.propertyTitle ?? 'Client Visit'),
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                        ),
                                        if (v.remarks != null && v.remarks!.isNotEmpty)
                                          Text(
                                            v.remarks!,
                                            style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      v.status.isNotEmpty ? v.status : 'Scheduled',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

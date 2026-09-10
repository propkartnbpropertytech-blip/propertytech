import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/theme/theme_manager.dart';
import '../models/report_date_range.dart';

class ReportDateFilterBar extends StatelessWidget {
  final ReportDateRange activeRange;
  final ValueChanged<ReportDateRange> onRangeChanged;

  const ReportDateFilterBar({
    super.key,
    required this.activeRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8ECF2),
          width: 1,
        ),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          // Segmented Period Pills
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPeriodOption(
                context,
                title: 'Today',
                isSelected: activeRange.periodType == ReportPeriodType.today,
                onTap: () => onRangeChanged(ReportDateRange.today()),
              ),
              const SizedBox(width: 4),
              _buildPeriodMenu(
                context,
                title: 'Weekly',
                isSelected: activeRange.periodType == ReportPeriodType.weekly,
                isCurrent: activeRange.subOption == ReportSubPeriodOption.current,
                onSelectCurrent: () => onRangeChanged(ReportDateRange.currentWeek()),
                onSelectCustom: () => _pickCustomWeek(context),
              ),
              const SizedBox(width: 4),
              _buildPeriodMenu(
                context,
                title: 'Monthly',
                isSelected: activeRange.periodType == ReportPeriodType.monthly,
                isCurrent: activeRange.subOption == ReportSubPeriodOption.current,
                onSelectCurrent: () => onRangeChanged(ReportDateRange.currentMonth()),
                onSelectCustom: () => _pickCustomMonth(context),
              ),
              const SizedBox(width: 4),
              _buildPeriodMenu(
                context,
                title: 'Yearly',
                isSelected: activeRange.periodType == ReportPeriodType.yearly,
                isCurrent: activeRange.subOption == ReportSubPeriodOption.current,
                onSelectCurrent: () => onRangeChanged(ReportDateRange.currentYear()),
                onSelectCustom: () => _pickCustomYear(context),
              ),
              const SizedBox(width: 4),
              _buildPeriodOption(
                context,
                title: 'Date Range',
                isSelected: activeRange.periodType == ReportPeriodType.customRange,
                onTap: () => _pickCustomDateRange(context),
              ),
            ],
          ),

          // Active Formatted Period Label & Calendar Icon
          InkWell(
            onTap: () => _pickCustomDateRange(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    activeRange.formattedRange,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF14213D),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodOption(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodMenu(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required bool isCurrent,
    required VoidCallback onSelectCurrent,
    required VoidCallback onSelectCustom,
  }) {
    final isDark = ThemeManager().isDarkMode;
    final primaryColor = CRMColors.primary;

    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'current') {
          onSelectCurrent();
        } else {
          onSelectCustom();
        }
      },
      tooltip: 'Select $title period',
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'current',
          child: Row(
            children: [
              Icon(
                Icons.check,
                size: 14,
                color: isSelected && isCurrent ? primaryColor : Colors.transparent,
              ),
              const SizedBox(width: 8),
              Text('Current $title'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'custom',
          child: Row(
            children: [
              Icon(
                Icons.check,
                size: 14,
                color: isSelected && !isCurrent ? primaryColor : Colors.transparent,
              ),
              const SizedBox(width: 8),
              Text('Custom $title Range...'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 14,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomWeek(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: activeRange.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      helpText: 'Select any day within the desired week',
    );
    if (picked != null) {
      final weekday = picked.weekday;
      final start = DateTime(picked.year, picked.month, picked.day - (weekday - 1), 0, 0, 0);
      final end = DateTime(picked.year, picked.month, picked.day + (7 - weekday), 23, 59, 59, 999);
      onRangeChanged(
        ReportDateRange.custom(
          start: start,
          end: end,
          periodType: ReportPeriodType.weekly,
        ),
      );
    }
  }

  Future<void> _pickCustomMonth(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: activeRange.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      helpText: 'Select month by choosing any day in that month',
    );
    if (picked != null) {
      final start = DateTime(picked.year, picked.month, 1, 0, 0, 0);
      final nextMonth = picked.month == 12 ? DateTime(picked.year + 1, 1, 1) : DateTime(picked.year, picked.month + 1, 1);
      final end = nextMonth.subtract(const Duration(milliseconds: 1));
      onRangeChanged(
        ReportDateRange.custom(
          start: start,
          end: end,
          periodType: ReportPeriodType.monthly,
        ),
      );
    }
  }

  Future<void> _pickCustomYear(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: activeRange.startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select year',
    );
    if (picked != null) {
      final start = DateTime(picked.year, 1, 1, 0, 0, 0);
      final end = DateTime(picked.year, 12, 31, 23, 59, 59, 999);
      onRangeChanged(
        ReportDateRange.custom(
          start: start,
          end: end,
          periodType: ReportPeriodType.yearly,
        ),
      );
    }
  }

  Future<void> _pickCustomDateRange(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: DateTimeRange(
        start: activeRange.startDate,
        end: activeRange.endDate,
      ),
      helpText: 'Select Date Range for Business Report',
    );
    if (range != null) {
      onRangeChanged(
        ReportDateRange.custom(
          start: range.start,
          end: range.end,
          periodType: ReportPeriodType.customRange,
        ),
      );
    }
  }
}

import 'package:intl/intl.dart';

enum ReportPeriodType {
  today,
  weekly,
  monthly,
  yearly,
  customRange;

  String get displayName {
    switch (this) {
      case ReportPeriodType.today:
        return 'Today';
      case ReportPeriodType.weekly:
        return 'Weekly';
      case ReportPeriodType.monthly:
        return 'Monthly';
      case ReportPeriodType.yearly:
        return 'Yearly';
      case ReportPeriodType.customRange:
        return 'Date Range';
    }
  }
}

enum ReportSubPeriodOption {
  current,
  custom;

  String get displayName {
    switch (this) {
      case ReportSubPeriodOption.current:
        return 'Current';
      case ReportSubPeriodOption.custom:
        return 'Custom Range';
    }
  }
}

class ReportDateRange {
  final ReportPeriodType periodType;
  final ReportSubPeriodOption subOption;
  final DateTime startDate;
  final DateTime endDate;

  const ReportDateRange({
    required this.periodType,
    this.subOption = ReportSubPeriodOption.current,
    required this.startDate,
    required this.endDate,
  });

  /// Factory for Today
  factory ReportDateRange.today() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return ReportDateRange(
      periodType: ReportPeriodType.today,
      subOption: ReportSubPeriodOption.current,
      startDate: start,
      endDate: end,
    );
  }

  /// Factory for Current Week (Monday to Sunday or last 7 days)
  factory ReportDateRange.currentWeek() {
    final now = DateTime.now();
    final weekday = now.weekday; // 1 = Monday
    final start = DateTime(now.year, now.month, now.day - (weekday - 1), 0, 0, 0);
    final end = DateTime(now.year, now.month, now.day + (7 - weekday), 23, 59, 59, 999);
    return ReportDateRange(
      periodType: ReportPeriodType.weekly,
      subOption: ReportSubPeriodOption.current,
      startDate: start,
      endDate: end,
    );
  }

  /// Factory for Current Month
  factory ReportDateRange.currentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1, 0, 0, 0);
    final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
    final end = nextMonth.subtract(const Duration(milliseconds: 1));
    return ReportDateRange(
      periodType: ReportPeriodType.monthly,
      subOption: ReportSubPeriodOption.current,
      startDate: start,
      endDate: end,
    );
  }

  /// Factory for Current Year
  factory ReportDateRange.currentYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1, 0, 0, 0);
    final end = DateTime(now.year, 12, 31, 23, 59, 59, 999);
    return ReportDateRange(
      periodType: ReportPeriodType.yearly,
      subOption: ReportSubPeriodOption.current,
      startDate: start,
      endDate: end,
    );
  }

  /// Factory for Custom Range
  factory ReportDateRange.custom({
    required DateTime start,
    required DateTime end,
    ReportPeriodType periodType = ReportPeriodType.customRange,
  }) {
    final s = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final e = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
    return ReportDateRange(
      periodType: periodType,
      subOption: ReportSubPeriodOption.custom,
      startDate: s,
      endDate: e,
    );
  }

  String get formattedRange {
    final formatter = DateFormat('MMM d, yyyy');
    if (periodType == ReportPeriodType.today) {
      return DateFormat('EEEE, MMM d, yyyy').format(startDate);
    }
    return '${formatter.format(startDate)} – ${formatter.format(endDate)}';
  }

  bool contains(DateTime date) {
    return (date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
        (date.isBefore(endDate) || date.isAtSameMomentAs(endDate));
  }

  ReportDateRange copyWith({
    ReportPeriodType? periodType,
    ReportSubPeriodOption? subOption,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ReportDateRange(
      periodType: periodType ?? this.periodType,
      subOption: subOption ?? this.subOption,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

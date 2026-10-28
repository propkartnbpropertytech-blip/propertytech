import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CRMDatesHelper {
  static final DateFormat _dateFormat = DateFormat(AppConstants.dateFormat);
  static final DateFormat _timeFormat = DateFormat(AppConstants.timeFormat);
  static final DateFormat _dateTimeFormat = DateFormat(AppConstants.dateTimeFormat);

  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return _timeFormat.format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '';
    return _dateTimeFormat.format(date);
  }

  static DateTime? parseDate(String dateStr) {
    try {
      return _dateFormat.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  static bool isValidDateRange(DateTime start, DateTime end) {
    return !end.isBefore(start);
  }

  static String formatTimeOfDay(BuildContext? context, DateTime date) {
    return formatTime(date);
  }

  /// Formats any UTC date or ISO-8601 string to Indian Standard Time (IST, UTC+5:30)
  /// e.g. "28 Oct 2026, 12:04 PM IST"
  static String formatToIST(dynamic input, {bool includeSeconds = false}) {
    if (input == null) return 'N/A';
    try {
      DateTime dt;
      if (input is DateTime) {
        dt = input.toUtc();
      } else {
        String cleanStr = input.toString().trim();
        if (cleanStr.isEmpty) return 'N/A';
        if (cleanStr.contains(' ') && !cleanStr.contains('T')) {
          cleanStr = cleanStr.replaceFirst(' ', 'T');
        }
        if (!cleanStr.endsWith('Z') && !RegExp(r'[+-]\d\d:?\d\d$').hasMatch(cleanStr)) {
          cleanStr = '${cleanStr}Z';
        }
        dt = DateTime.parse(cleanStr).toUtc();
      }

      // Explicitly convert UTC to IST (UTC + 5 hours 30 minutes)
      final istDt = dt.add(const Duration(hours: 5, minutes: 30));
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final day = istDt.day.toString().padLeft(2, '0');
      final month = months[istDt.month - 1];
      final year = istDt.year;
      final hour = istDt.hour % 12 == 0 ? 12 : istDt.hour % 12;
      final minute = istDt.minute.toString().padLeft(2, '0');
      final ampm = istDt.hour >= 12 ? 'PM' : 'AM';
      final sec = includeSeconds ? ':${istDt.second.toString().padLeft(2, '0')}' : '';

      return '$day $month $year, $hour:$minute$sec $ampm IST';
    } catch (_) {
      return input.toString();
    }
  }
}

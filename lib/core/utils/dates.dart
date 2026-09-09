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

  static String formatTimeOfDay(context, DateTime date) {
    return formatTime(date);
  }
}

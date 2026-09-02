import '../utils/app_logger.dart';

/// Debug-only logger that redacts secrets from messages.
class SecureLog {
  static void d(String message, [Object? error]) {
    AppLogger.d(message, error);
  }

  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    AppLogger.e(message, error, stackTrace);
  }

  static void i(String message, [Object? error]) {
    AppLogger.i(message, error);
  }

  static void w(String message, [Object? error]) {
    AppLogger.w(message, error);
  }

  static String redact(String message) {
    return AppLogger.redact(message);
  }
}

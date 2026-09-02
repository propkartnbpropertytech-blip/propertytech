import 'package:logger/logger.dart';

/// Centralized application logger utilizing `package:logger`.
/// Provides structured, pretty-printed, categorized logs with sensitive data redaction.
class AppLogger {
  static final Logger _logger = Logger(
    filter: DevelopmentFilter(),
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 100,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    output: ConsoleOutput(),
  );

  /// Sensitive regex to redact secrets from printed logs.
  static final RegExp _sensitivePattern = RegExp(
    r'(Bearer\s+[A-Za-z0-9\-._~+/]+=*)|(eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)|(password["\s:=]+[^,\s}"]+)|(refreshToken["\s:=]+[^,\s}"]+)|(Authorization["\s:=]+[^,\s}"]+)',
    caseSensitive: false,
  );

  static dynamic _sanitize(dynamic input) {
    if (input == null) return null;
    if (input is String) {
      return input.replaceAllMapped(_sensitivePattern, (_) => '[REDACTED]');
    }
    return input;
  }

  /// Trace log (verbose)
  static void t(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.t(_sanitize(message), error: _sanitize(error), stackTrace: stackTrace);
  }

  /// Debug log
  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(_sanitize(message), error: _sanitize(error), stackTrace: stackTrace);
  }

  /// Info log
  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(_sanitize(message), error: _sanitize(error), stackTrace: stackTrace);
  }

  /// Warning log
  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(_sanitize(message), error: _sanitize(error), stackTrace: stackTrace);
  }

  /// Error log
  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(_sanitize(message), error: _sanitize(error), stackTrace: stackTrace);
  }

  /// Fatal log (WTF / critical error)
  static void f(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(_sanitize(message), error: _sanitize(error), stackTrace: stackTrace);
  }

  /// Specialized network log
  static void network(
    String method,
    String url, {
    int? statusCode,
    dynamic data,
    dynamic error,
    int? durationMs,
  }) {
    final statusStr = statusCode != null ? ' [$statusCode]' : '';
    final durationStr = durationMs != null ? ' in ${durationMs}ms' : '';
    final logMessage = '🌐 [HTTP $method] $url$statusStr$durationStr';

    if (error != null || (statusCode != null && statusCode >= 400)) {
      _logger.e(
        logMessage,
        error: _sanitize(error ?? 'Status $statusCode'),
      );
    } else {
      _logger.i(logMessage);
    }
  }

  /// Specialized sync engine log
  static void sync(String message, {dynamic error, StackTrace? stackTrace}) {
    if (error != null) {
      _logger.w('🔄 [SYNC] $message', error: _sanitize(error), stackTrace: stackTrace);
    } else {
      _logger.i('🔄 [SYNC] $message');
    }
  }

  /// Specialized telemetry / performance log
  static void telemetry(
    String operation, {
    int isarReadMs = 0,
    int networkMs = 0,
    int jsonParseMs = 0,
    int isarWriteMs = 0,
    required int totalMs,
  }) {
    final details =
        'IsarRead: ${isarReadMs}ms | Network: ${networkMs}ms | Parse: ${jsonParseMs}ms | IsarWrite: ${isarWriteMs}ms | Total: ${totalMs}ms';
    _logger.d('⏱️ [TELEMETRY] $operation\n   ↳ $details');
  }

  /// Redacts sensitive information from a string.
  static String redact(String input) {
    return _sanitize(input) as String;
  }
}

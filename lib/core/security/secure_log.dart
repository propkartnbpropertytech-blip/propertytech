import 'package:flutter/foundation.dart';

/// Debug-only logger that redacts secrets from messages.
class SecureLog {
  static final _sensitive = RegExp(
    r'(Bearer\s+[A-Za-z0-9\-._~+/]+=*)|(eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)|(password["\s:=]+[^,\s}"]+)|(refreshToken["\s:=]+[^,\s}"]+)|(Authorization["\s:=]+[^,\s}"]+)',
    caseSensitive: false,
  );

  static String redact(Object? input) {
    final s = input?.toString() ?? '';
    return s.replaceAllMapped(_sensitive, (_) => '[REDACTED]');
  }

  static void d(String message, [Object? error]) {
    if (!kDebugMode) return;
    if (error != null) {
      debugPrint('${redact(message)} | ${redact(error)}');
    } else {
      debugPrint(redact(message));
    }
  }
}

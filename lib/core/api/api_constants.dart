class ApiConstants {
  static const String primaryBaseUrl = "https://api-propkart.nbpropertytech.com/api/v1";
  static const String backupBaseUrl = "https://api-propkart.nbpropertytech.com/api/v1";

  /// Connect directly to backend subdomain for cross-site cookie authentication.
  static String get baseUrl => primaryBaseUrl;

  static const String cloudinaryCloudName = "jdvya1gl";
  static const String cloudinaryApiKey = "131871686761399";
  static const String cloudinaryApiSecret = "mXh1pyefWhgjKN5oi8fp3Xe7a7w";

  static const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: 'https://60d7ddcd27827fcd0b9ebe472ce8cd39@o4511857602658304.ingest.us.sentry.io/4511857636999168',
  );

  static const login = "/auth/login";
  static const register = "/auth/register";
  static const me = "/auth/me";
  static const refresh = "/auth/refresh";
  static const logout = "/auth/logout";
  static const health = "/health";

  /// Public web URL used in password-recovery emails.
  static const passwordResetRedirectTo = 'https://propkart.nbpropertytech.com/reset-password';

  /// Mobile deep-link scheme for recovery redirects into the native app.
  static const passwordResetDeepLink = 'io.nbpropertytech.propkart://reset-password';

  static void assertConfig() {
    // Configuration assertions if needed
  }
}

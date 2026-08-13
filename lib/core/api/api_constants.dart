import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String primaryBaseUrl = "https://prop-kart-backend.vercel.app/api/v1";
  static const String backupBaseUrl = "https://prop-kart-backend.vercel.app/api/v1";

  /// Toggle this to true to connect Flutter directly to Supabase.
  /// Set to false to fall back to the custom Node.js Express backend.
  static const bool useSupabaseDirect = true;

  /// Connect directly to backend subdomain for cross-site cookie authentication.
  static String get baseUrl => primaryBaseUrl;

  /// Prefer compile-time defines in CI:
  /// `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
  /// Anon key is public-by-design for Supabase; security depends on RLS.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://oomylxpyeqntphbarqbz.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9vbXlseHB5ZXFudHBoYmFycWJ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODU3NDkzMzQsImV4cCI6MjEwMTMyNTMzNH0.xxxe4If9NHdkJgsH4D5xxltejDXIZ5B9txEyhcTqeUc',
  );

  static const String cloudinaryCloudName = "jdvya1gl";
  static const String cloudinaryApiKey = "131871686761399";
  static const String cloudinaryApiSecret = "mXh1pyefWhgjKN5oi8fp3Xe7a7w";

  static const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: 'https://60d7ddcd27827fcd0b9ebe472ce8cd39@o4511857602658304.ingest.us.sentry.io/4511857636999168',
  );

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const login = "/auth/login";
  static const register = "/auth/register";
  static const me = "/auth/me";
  static const refresh = "/auth/refresh";
  static const logout = "/auth/logout";
  static const health = "/health";

  /// Public web URL used in password-recovery emails (must be allow-listed in Supabase Auth).
  static const passwordResetRedirectTo = 'https://propkart.nbpropertytech.com/reset-password';

  /// Mobile deep-link scheme for recovery redirects into the native app.
  static const passwordResetDeepLink = 'io.nbpropertytech.propkart://reset-password';

  static void assertConfig() {
    if (kDebugMode && !hasSupabaseConfig) {
      debugPrint('ApiConstants: Supabase URL/anon key missing — realtime disabled.');
    }
  }
}

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

  static const String cloudinaryCloudName = "ujn8lj3r";
  static const String cloudinaryApiKey = "495168782694392";
  static const String cloudinaryApiSecret = "Mle5fuL-8IOhq_L0R0HIusM_jDE";

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const login = "/auth/login";
  static const register = "/auth/register";
  static const me = "/auth/me";
  static const refresh = "/auth/refresh";
  static const logout = "/auth/logout";
  static const health = "/health";

  static void assertConfig() {
    if (kDebugMode && !hasSupabaseConfig) {
      debugPrint('ApiConstants: Supabase URL/anon key missing — realtime disabled.');
    }
  }
}

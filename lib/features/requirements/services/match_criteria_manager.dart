import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/app_logger.dart';

class MatchCriteriaManager extends ChangeNotifier {
  static final MatchCriteriaManager _instance = MatchCriteriaManager._internal();
  factory MatchCriteriaManager() => _instance;

  static const String prefsKey = 'propkart_run_match_criteria_threshold';
  static const int defaultThreshold = 60; // Default 60% as requested by admin

  int _threshold = defaultThreshold;
  bool _isLoaded = false;
  bool _isSyncing = false;

  MatchCriteriaManager._internal() {
    _loadPersisted();
  }

  int get threshold => _threshold;
  bool get isLoaded => _isLoaded;
  bool get isSyncing => _isSyncing;

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getInt(prefsKey);
      if (cached != null) {
        _threshold = cached.clamp(10, 100);
      }
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLoaded = true;
    }

    // Always fetch latest authoritative team threshold from backend database
    await fetchFromBackend(silent: true);
  }

  /// Fetches the Admin's configured match criteria from PostgreSQL database
  Future<void> fetchFromBackend({bool silent = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final response = await ApiClient().get('/config/match-criteria');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final serverThreshold = (data?['threshold'] as num?)?.toInt();
        if (serverThreshold != null) {
          final clamped = serverThreshold.clamp(10, 100);
          if (clamped != _threshold) {
            _threshold = clamped;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt(prefsKey, _threshold);
            notifyListeners();
            AppLogger.d("MatchCriteriaManager: Updated team threshold to $_threshold% from database");
          }
        }
      }
      _isLoaded = true;
    } catch (e) {
      if (!silent) {
        AppLogger.w("MatchCriteriaManager: Failed to fetch criteria from backend: $e");
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Sets threshold, saves to database so it stays at this preference permanently for the whole team
  Future<bool> setThreshold(int percent, {bool syncBackend = true}) async {
    final clamped = percent.clamp(10, 100);
    final changed = (_threshold != clamped);

    _threshold = clamped;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(prefsKey, _threshold);
    } catch (_) {}

    if (syncBackend) {
      try {
        final response = await ApiClient().put('/config/match-criteria', {
          'threshold': clamped,
        });
        if (response.statusCode == 200) {
          AppLogger.d("MatchCriteriaManager: Persisted threshold $clamped% to database for team");
          return true;
        }
      } catch (e) {
        AppLogger.e("MatchCriteriaManager: Failed to persist threshold to database: $e");
        return false;
      }
    }
    return changed;
  }

  Future<void> resetToDefault() async {
    await setThreshold(defaultThreshold, syncBackend: true);
  }

  /// Color corresponding to the current threshold
  Color get thresholdColor {
    if (_threshold >= 80) return const Color(0xFF10B981); // Emerald Green
    if (_threshold >= 60) return const Color(0xFF0F766E); // Teal
    if (_threshold >= 40) return const Color(0xFF0288D1); // Ocean Blue
    return const Color(0xFFD97706); // Amber
  }

  /// Human-readable label for the current threshold mode
  String get thresholdModeLabel {
    if (_threshold >= 80) return 'Strict (High Precision)';
    if (_threshold >= 60) return 'Balanced (Recommended)';
    if (_threshold >= 40) return 'Flexible (Moderate)';
    return 'Loose (Broad Match)';
  }

  /// Description of what criteria are typically satisfied at this threshold
  String get thresholdDescription {
    if (_threshold >= 80) {
      return 'High-precision mode: Properties must match almost all primary criteria (Budget + Configuration + Locality) to qualify.';
    } else if (_threshold >= 60) {
      return 'Recommended mode: Properties must match at least two major criteria (e.g. Budget + Configuration, or Budget + Locality) to appear in Run Matches.';
    } else if (_threshold >= 40) {
      return 'Flexible mode: Properties matching at least one major criterion plus secondary attributes (e.g. Budget + Property Type, or Locality + Listing Type) will qualify.';
    } else {
      return 'Broad mode: Shows properties if any single primary criterion matches (e.g. Budget alone, or Configuration alone).';
    }
  }

  /// Returns true if a given match percentage satisfies the active threshold
  bool isMatch(int score) => score >= _threshold;
}

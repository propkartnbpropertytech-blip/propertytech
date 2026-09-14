import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MatchCriteriaManager extends ChangeNotifier {
  static final MatchCriteriaManager _instance = MatchCriteriaManager._internal();
  factory MatchCriteriaManager() => _instance;

  static const String prefsKey = 'propkart_run_match_criteria_threshold';
  static const int defaultThreshold = 60; // Default 60% as requested by admin

  int _threshold = defaultThreshold;
  bool _isLoaded = false;

  MatchCriteriaManager._internal() {
    _loadPersisted();
  }

  int get threshold => _threshold;
  bool get isLoaded => _isLoaded;

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _threshold = prefs.getInt(prefsKey) ?? defaultThreshold;
      _isLoaded = true;
      notifyListeners();
    } catch (_) {
      _isLoaded = true;
    }
  }

  Future<void> setThreshold(int percent) async {
    final clamped = percent.clamp(10, 100);
    if (_threshold == clamped) return;
    _threshold = clamped;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(prefsKey, _threshold);
    } catch (_) {}
  }

  Future<void> resetToDefault() async {
    await setThreshold(defaultThreshold);
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

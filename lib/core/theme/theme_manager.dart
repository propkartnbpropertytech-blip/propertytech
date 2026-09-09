import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_presets.dart';

class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;

  static const _prefsKey = 'propkart_dark_mode';
  static const _themeIdPrefsKey = 'propkart_active_theme_id';
  static const _systemDefaultThemeIdPrefsKey = 'propkart_system_default_theme_id';

  ThemeManager._internal() {
    _isDarkMode = false; // Default to Light Mode on first launch
    _systemDefaultThemeId = AppThemePresets.defaultTheme.id;
    _selectedThemeId = AppThemePresets.defaultTheme.id;
    _loadPersisted();
  }

  bool _isDarkMode = false;
  bool _loaded = false;
  bool _isRentMode = true;
  String _selectedThemeId = AppThemePresets.defaultTheme.id;
  String _systemDefaultThemeId = AppThemePresets.defaultTheme.id;

  bool get isDarkMode => _isDarkMode;
  bool get isLoaded => _loaded;
  bool get isRentMode => _isRentMode;
  String get selectedThemeId => _selectedThemeId;
  String get systemDefaultThemeId => _systemDefaultThemeId;

  /// Returns the currently active theme preset. Defaults to [AppThemePresets.defaultTheme].
  AppThemePreset get currentTheme => AppThemePresets.getById(_selectedThemeId);

  /// Returns the system default theme preset.
  AppThemePreset get defaultTheme => AppThemePresets.getById(_systemDefaultThemeId);

  /// Convenient getter for current primary brand color based on brightness.
  Color get primaryColor =>
      _isDarkMode ? currentTheme.primaryDark : currentTheme.primaryLight;

  /// Convenient getter for current primary hover color based on brightness.
  Color get primaryHoverColor => _isDarkMode
      ? currentTheme.primaryHoverDark
      : currentTheme.primaryHoverLight;

  /// Check if a theme preset is the system default.
  bool isSystemDefault(String themeId) => _systemDefaultThemeId == themeId;

  /// All registered themes available in PropKart.
  List<AppThemePreset> get availableThemes => AppThemePresets.all;

  /// Updates Rent/Re-Sale accent mode.
  void setRentMode(bool value) {
    if (_isRentMode == value) return;
    _isRentMode = value;
    notifyListeners();
  }

  Future<void> _loadPersisted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_prefsKey)) {
        _isDarkMode = prefs.getBool(_prefsKey) ?? _isDarkMode;
      }
      if (prefs.containsKey(_systemDefaultThemeIdPrefsKey)) {
        final savedDefaultId = prefs.getString(_systemDefaultThemeIdPrefsKey);
        if (savedDefaultId != null && savedDefaultId.isNotEmpty) {
          _systemDefaultThemeId = savedDefaultId;
        }
      }
      if (prefs.containsKey(_themeIdPrefsKey)) {
        final savedThemeId = prefs.getString(_themeIdPrefsKey);
        if (savedThemeId != null && savedThemeId.isNotEmpty) {
          _selectedThemeId = savedThemeId;
        } else {
          _selectedThemeId = _systemDefaultThemeId;
        }
      } else {
        _selectedThemeId = _systemDefaultThemeId;
      }
      _loaded = true;
      notifyListeners();
    } catch (_) {
      _loaded = true;
    }
  }

  /// Sets the active application theme preset for the user session and persists the preference.
  Future<void> setTheme(String themeId) async {
    final preset = AppThemePresets.getById(themeId);
    _selectedThemeId = preset.id;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeIdPrefsKey, _selectedThemeId);
    } catch (_) {}
  }

  /// Sets the system-wide default theme (Super Admin action).
  ///
  /// Anyone visiting the site or app without a personal override will see this theme.
  Future<void> setSystemDefaultTheme(String themeId) async {
    final preset = AppThemePresets.getById(themeId);
    _systemDefaultThemeId = preset.id;
    _selectedThemeId = preset.id;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_systemDefaultThemeIdPrefsKey, _systemDefaultThemeId);
      await prefs.setString(_themeIdPrefsKey, _selectedThemeId);
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _isDarkMode);
    } catch (_) {}
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, _isDarkMode);
    } catch (_) {}
  }
}


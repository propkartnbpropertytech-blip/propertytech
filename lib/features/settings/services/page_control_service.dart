import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/security/role_guard.dart';
import '../models/page_control_model.dart';

/// Central reactive service managing Page Under Development status.
class PageControlService extends ChangeNotifier with WidgetsBindingObserver {
  static final PageControlService _instance = PageControlService._internal();
  static PageControlService get instance => _instance;

  Timer? _syncTimer;
  Future<void>? _inFlightFetch;
  int _fetchCounter = 0;
  bool _isPaused = false;

  PageControlService._internal() {
    _init();
  }

  static const List<PageControlModel> _defaultControls = [
    PageControlModel(pageKey: 'dashboard', title: 'Dashboard', route: '/dashboard', icon: 'grid_view_rounded', category: 'Main', roles: ['Admin', 'Telecaller', 'Sales'], sortOrder: 10),
    PageControlModel(pageKey: 'properties', title: 'Properties', route: '/properties', icon: 'home_work_outlined', category: 'Main', roles: ['Admin', 'Telecaller', 'Sales'], sortOrder: 20),
    PageControlModel(pageKey: 'telecaller_calling_leads', title: 'My Calling Leads', route: '/campaign/leads', icon: 'phone_in_talk_outlined', category: 'Telecaller', roles: ['Telecaller'], sortOrder: 25),
    PageControlModel(pageKey: 'telecaller_callbacks', title: 'Callbacks', route: '/telecaller/callbacks', icon: 'event_repeat', category: 'Telecaller', roles: ['Telecaller'], sortOrder: 26),
    PageControlModel(pageKey: 'telecaller_cnr', title: 'CNR / Retry', route: '/telecaller/cnr', icon: 'phone_missed_outlined', category: 'Telecaller', roles: ['Telecaller'], sortOrder: 27),
    PageControlModel(pageKey: 'leads', title: 'Leads', route: '/requirements', icon: 'assignment_outlined', category: 'Main', roles: ['Admin', 'Telecaller', 'Sales'], sortOrder: 30),
    PageControlModel(pageKey: 'employees', title: 'Employees', route: '/users', icon: 'people_outline_rounded', category: 'Main', roles: ['Admin'], sortOrder: 40),
    PageControlModel(pageKey: 'reports', title: 'Reports', route: '/reports', icon: 'bar_chart_rounded', category: 'Main', roles: ['Admin'], sortOrder: 50),
    PageControlModel(pageKey: 'campaign_connections', title: 'Campaign → Connections', route: '/campaign/connections', icon: 'hub_outlined', category: 'Campaign', roles: ['Admin'], sortOrder: 60),
    PageControlModel(pageKey: 'campaign_meta', title: 'Campaign → Meta', route: '/campaign/meta', icon: 'campaign_outlined', category: 'Campaign', roles: ['Admin'], sortOrder: 61),
    PageControlModel(pageKey: 'campaign_housing', title: 'Campaign → Housing', route: '/campaign/housing', icon: 'apartment_outlined', category: 'Campaign', roles: ['Admin'], sortOrder: 62),
    PageControlModel(pageKey: 'lead_allocation', title: 'Lead Allocations', route: '/admin/lead-allocation', icon: 'hub_outlined', category: 'Main', roles: ['Admin'], sortOrder: 70),
    PageControlModel(pageKey: 'library', title: 'Library', route: '/library', icon: 'folder_outlined', category: 'Main', roles: ['Admin', 'Telecaller', 'Sales'], sortOrder: 80),
    PageControlModel(pageKey: 'settings_profile', title: 'Settings → Profile', route: '/profile', icon: 'person_outline_rounded', category: 'Settings', roles: ['Admin', 'Telecaller', 'Sales'], sortOrder: 90),
    PageControlModel(pageKey: 'settings_themes', title: 'Settings → Themes', route: '/settings?section=themes', icon: 'palette_outlined', category: 'Settings', roles: ['Admin', 'Telecaller', 'Sales'], sortOrder: 91),
    PageControlModel(pageKey: 'settings_appearance', title: 'Settings → Appearance', route: '/settings?section=appearance', icon: 'tune_rounded', category: 'Settings', roles: ['Admin', 'Telecaller', 'Sales'], sortOrder: 92),
    PageControlModel(pageKey: 'settings_locations', title: 'Settings → Locations', route: '/settings?section=locations', icon: 'location_city_outlined', category: 'Settings', roles: ['Admin', 'Telecaller', 'Sales'], sortOrder: 93),
    PageControlModel(pageKey: 'settings_match_criteria', title: 'Settings → Run Match Criteria', route: '/settings?section=match_criteria', icon: 'bolt_rounded', category: 'Settings', roles: ['Admin'], sortOrder: 94),
    PageControlModel(pageKey: 'settings_upload_limits', title: 'Settings → Upload Limits', route: '/settings?section=upload_limits', icon: 'photo_library_outlined', category: 'Settings', roles: ['Admin'], sortOrder: 95),
    PageControlModel(pageKey: 'settings_kpi_config', title: 'Settings → KPI Configuration', route: '/settings?section=kpi_config', icon: 'dashboard_customize_outlined', category: 'Settings', roles: ['Admin'], sortOrder: 96),
    PageControlModel(pageKey: 'settings_system', title: 'Settings → System', route: '/settings?section=system', icon: 'info_outline_rounded', category: 'Settings', roles: ['Admin', 'Telecaller', 'Sales'], sortOrder: 97),
    PageControlModel(pageKey: 'audit_logs', title: 'Audit Log', route: '/settings/audit-logs', icon: 'history_rounded', category: 'Settings', roles: ['Admin'], sortOrder: 100),
    PageControlModel(pageKey: 'support', title: 'Support', route: '/support', icon: 'support_agent_rounded', category: 'Main', roles: ['Admin', 'Telecaller', 'Sales'], sortOrder: 110),
    PageControlModel(pageKey: 'recycle_bin', title: 'Recycle Bin', route: '/bin', icon: 'delete_outline_rounded', category: 'Main', roles: ['Admin', 'Telecaller', 'Sales'], sortOrder: 120),
  ];

  static const String _cacheKey = 'propkart_page_controls_cache_v1';

  List<PageControlModel> _controls = List.from(_defaultControls);
  bool _isLoading = false;
  DateTime? _lastFetchedAt;

  List<PageControlModel> get controls => List.unmodifiable(_controls);
  bool get isLoading => _isLoading;
  DateTime? get lastFetchedAt => _lastFetchedAt;

  bool _mergeIncoming(List<PageControlModel> incoming) {
    final Map<String, PageControlModel> map = {
      for (final c in _controls) c.pageKey: c,
    };
    bool hasChanged = false;
    for (final inc in incoming) {
      final existing = map[inc.pageKey];
      if (existing != null) {
        final updated = existing.copyWith(
          isUnderDevelopment: inc.isUnderDevelopment,
          underDevelopmentRoles: inc.underDevelopmentRoles,
          message: inc.message,
          updatedAt: inc.updatedAt,
        );
        if (!existing.isEffectivelyEqualTo(updated)) {
          map[inc.pageKey] = updated;
          hasChanged = true;
        }
      } else {
        map[inc.pageKey] = inc;
        hasChanged = true;
      }
    }
    if (hasChanged) {
      _controls = map.values.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }
    return hasChanged;
  }

  Future<void> _init() async {
    _registerLifecycleObserver();
    await _loadFromCache();
    await fetchControls(silent: true);
    _startPeriodicSync();
  }

  void _registerLifecycleObserver() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {
      // Binding may be uninitialized in unit test or headless environments
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isPaused = false;
      _startPeriodicSync();
      _checkAndRefreshIfStale();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _isPaused = true;
      _syncTimer?.cancel();
    }
  }

  void _checkAndRefreshIfStale() {
    final last = _lastFetchedAt;
    if (last == null || DateTime.now().difference(last) > const Duration(minutes: 5)) {
      fetchControls(silent: true);
    }
  }

  void _startPeriodicSync() {
    _syncTimer?.cancel();
    if (_isPaused) return;
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      fetchControls(silent: true);
    });
  }

  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final cached = decoded
              .whereType<Map<String, dynamic>>()
              .map((e) => PageControlModel.fromJson(e))
              .toList();
          final hasChanged = _mergeIncoming(cached);
          if (hasChanged) {
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('[PageControlService] Error loading cache: $e');
    }
  }

  Future<void> _saveToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_controls.map((e) => e.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);
    } catch (e) {
      debugPrint('[PageControlService] Error saving cache: $e');
    }
  }

  /// Fetches authoritative page controls from backend API.
  /// Deduplicates concurrent invocations, prevents race conditions,
  /// and only notifies listeners if effective control state has actually changed.
  Future<void> fetchControls({bool silent = false}) async {
    if (_inFlightFetch != null) {
      return _inFlightFetch!;
    }

    final completer = Completer<void>();
    _inFlightFetch = completer.future;
    final currentFetchId = ++_fetchCounter;

    bool didEnterLoading = false;
    if (!silent && !_isLoading) {
      _isLoading = true;
      didEnterLoading = true;
      notifyListeners();
    }

    try {
      final dio = DioClient.dio;
      final response = await dio.get('/page-controls');

      // Drop stale response if a newer fetch was initiated
      if (currentFetchId != _fetchCounter) {
        return;
      }

      if (response.statusCode == 200) {
        final data = response.data;
        final isSuccess = data is Map && (data['success'] == true || data['success'] == 'true');
        if (isSuccess && data['data'] is List) {
          final list = data['data'] as List;
          final incoming = list
              .whereType<Map>()
              .map((e) => PageControlModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();

          final hasChanged = _mergeIncoming(incoming);
          _lastFetchedAt = DateTime.now();

          if (hasChanged) {
            await _saveToCache();
          }

          if (didEnterLoading) {
            _isLoading = false;
            didEnterLoading = false;
            notifyListeners();
          } else if (hasChanged) {
            notifyListeners();
          }
        }
      }
    } catch (e) {
      debugPrint('[PageControlService] fetchControls error: $e');
    } finally {
      if (didEnterLoading) {
        _isLoading = false;
        notifyListeners();
      }
      _inFlightFetch = null;
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  /// Helper to normalize role names across tabs and security
  static String? normalizeRole(String? r) {
    if (r == null || r.isEmpty) return null;
    final lower = r.trim().toLowerCase();
    if (lower.contains('admin')) return 'Admin';
    if (lower.contains('telecaller')) return 'Telecaller';
    if (lower.contains('sales')) return 'Sales';
    return r.trim();
  }

  /// Toggles or updates Under Development state for a page.
  /// If [role] is provided, toggles ONLY for that specific role independently.
  Future<bool> toggleUnderDevelopment(
    String pageKey,
    bool isUnderDev, {
    String? role,
    String? customMessage,
  }) async {
    final idx = _controls.indexWhere((c) => c.pageKey == pageKey);
    if (idx == -1) return false;

    final target = _controls[idx];
    final previousUnderDev = target.isUnderDevelopment;
    final previousUnderDevRoles = List<String>.from(target.underDevelopmentRoles);

    // Compute updated roles optimistically
    List<String> newRoles = List<String>.from(target.underDevelopmentRoles);
    final targetRole = normalizeRole(role);
    if (targetRole != null) {
      if (isUnderDev) {
        if (!newRoles.any((r) => normalizeRole(r) == targetRole)) {
          newRoles.add(targetRole);
        }
      } else {
        newRoles.removeWhere((r) => normalizeRole(r) == targetRole);
      }
    } else {
      if (isUnderDev) {
        newRoles = List<String>.from(target.roles);
      } else {
        newRoles.clear();
      }
    }

    // Optimistic update
    _controls[idx] = target.copyWith(
      isUnderDevelopment: newRoles.isNotEmpty,
      underDevelopmentRoles: newRoles,
      message: customMessage ?? target.message,
      updatedAt: DateTime.now(),
    );
    notifyListeners();

    try {
      final dio = DioClient.dio;
      final payload = <String, dynamic>{
        'is_under_development': isUnderDev,
        // ignore: use_null_aware_elements
        if (role != null) 'role': role,
        // ignore: use_null_aware_elements
        if (customMessage != null) 'message': customMessage,
      };

      final response = await dio.patch(
        '/page-controls/$pageKey',
        data: payload,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final isSuccess = data is Map && (data['success'] == true || data['success'] == 'true');
        if (isSuccess && data['data'] is Map) {
          final updatedMap = Map<String, dynamic>.from(data['data'] as Map);
          final serverModel = PageControlModel.fromJson(updatedMap);
          if (!_controls[idx].isEffectivelyEqualTo(serverModel)) {
            _controls[idx] = serverModel;
            notifyListeners();
          }
          await _saveToCache();
          return true;
        }
      }
      throw Exception('API returned non-success response');
    } catch (e) {
      debugPrint('[PageControlService] toggle error: $e');
      // Rollback on failure
      _controls[idx] = target.copyWith(
        isUnderDevelopment: previousUnderDev,
        underDevelopmentRoles: previousUnderDevRoles,
      );
      notifyListeners();
      return false;
    }
  }

  /// Returns the pages that belong to a specific role tab:
  /// [roleTab] can be: 'Admin', 'Telecaller', or 'Sales Person' ('Sales').
  List<PageControlModel> getControlsForRole(String roleTab) {
    final norm = roleTab.trim().toLowerCase();
    return _controls.where((c) {
      if (norm.contains('admin')) {
        return c.roles.any((r) => r.toLowerCase() == 'admin');
      }
      if (norm.contains('telecaller')) {
        return c.roles.any((r) => r.toLowerCase() == 'telecaller');
      }
      if (norm.contains('sales')) {
        return c.roles.any((r) => r.toLowerCase() == 'sales');
      }
      return false;
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Maps an application route to its corresponding page_key
  String? matchRouteToPageKey(String path, String? role) {
    final clean = path.split('?').first.trim().toLowerCase();

    // Telecaller specific routes take priority when caller is Telecaller
    final isTc = RoleGuard.isTelecaller(role);
    if (isTc) {
      if (clean.startsWith('/telecaller/callbacks')) return 'telecaller_callbacks';
      if (clean.startsWith('/telecaller/cnr')) return 'telecaller_cnr';
      if (clean.startsWith('/telecaller/leads') || clean.startsWith('/campaign/leads')) {
        return 'telecaller_calling_leads';
      }
    }

    // Campaign submodules
    if (clean.startsWith('/campaign/meta')) return 'campaign_meta';
    if (clean.startsWith('/campaign/housing')) return 'campaign_housing';
    if (clean.startsWith('/campaign/connections')) return 'campaign_connections';

    // Lead Allocation
    if (clean.startsWith('/admin/lead-allocation')) return 'lead_allocation';

    // Audit logs
    if (clean.startsWith('/settings/audit-logs')) return 'audit_logs';

    // Settings dedicated routes
    if (clean.startsWith('/settings/location-config')) return 'settings_locations';
    if (clean.startsWith('/settings/kpi-config')) return 'settings_kpi_config';
    if (clean.startsWith('/profile')) return 'settings_profile';

    // Core shared routes
    if (clean == '/dashboard') return 'dashboard';
    if (clean.startsWith('/properties')) return 'properties';
    if (clean.startsWith('/requirements')) return 'leads';
    if (clean.startsWith('/users')) return 'employees';
    if (clean.startsWith('/reports')) return 'reports';
    if (clean.startsWith('/library')) return 'library';
    if (clean.startsWith('/bin')) return 'recycle_bin';
    if (clean.startsWith('/support')) return 'support';

    return null;
  }

  /// Evaluates whether a given navigation route is marked Under Development for [role].
  /// Super Admin is NEVER blocked so they can administer the system.
  bool isRouteUnderDevelopment(String route, String? role) {
    if (RoleGuard.isSuperAdmin(role)) return false;

    final key = matchRouteToPageKey(route, role);
    if (key == null) return false;

    return isPageUnderDevelopment(key, role);
  }

  /// Evaluates whether a specific page_key is marked Under Development for [role].
  bool isPageUnderDevelopment(String pageKey, String? role) {
    if (RoleGuard.isSuperAdmin(role)) return false;

    final item = _controls.firstWhere(
      (c) => c.pageKey == pageKey,
      orElse: () => const PageControlModel(pageKey: '', title: '', route: '', roles: []),
    );

    if (item.pageKey.isEmpty) return false;
    return item.isUnderDevForRole(role);
  }

  /// Evaluates whether a settings section is marked Under Development for [role].
  bool isSettingsSectionUnderDevelopment(String sectionId, String? role) {
    if (RoleGuard.isSuperAdmin(role)) return false;

    String key;
    switch (sectionId) {
      case 'profile':
        key = 'settings_profile';
        break;
      case 'themes':
        key = 'settings_themes';
        break;
      case 'appearance':
        key = 'settings_appearance';
        break;
      case 'locations':
        key = 'settings_locations';
        break;
      case 'match_criteria':
        key = 'settings_match_criteria';
        break;
      case 'upload_limits':
        key = 'settings_upload_limits';
        break;
      case 'kpi_config':
        key = 'settings_kpi_config';
        break;
      case 'system':
        key = 'settings_system';
        break;
      case 'audit':
        key = 'audit_logs';
        break;
      default:
        return false;
    }

    return isPageUnderDevelopment(key, role);
  }

  /// Returns the matching PageControlModel for route or null.
  PageControlModel? getControlForRoute(String route, String? role) {
    final key = matchRouteToPageKey(route, role);
    if (key == null) return null;
    try {
      return _controls.firstWhere((c) => c.pageKey == key);
    } catch (_) {
      return null;
    }
  }

  /// Returns the matching PageControlModel for a settings section id.
  PageControlModel? getControlForSettingsSection(String sectionId) {
    String key = 'settings_$sectionId';
    if (sectionId == 'audit') key = 'audit_logs';
    try {
      return _controls.firstWhere((c) => c.pageKey == key);
    } catch (_) {
      return null;
    }
  }

  /// Resets controls to defaults and clears timestamps/in-flight states (e.g., on logout).
  void reset() {
    _controls = List.from(_defaultControls);
    _lastFetchedAt = null;
    _isLoading = false;
    _inFlightFetch = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.dispose();
  }
}

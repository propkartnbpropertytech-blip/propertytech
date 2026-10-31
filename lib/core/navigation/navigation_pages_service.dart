import 'package:flutter/foundation.dart';

import '../api/dio_client.dart';
import 'app_nav_registry.dart';

/// Page structure persisted in `app_navigation_pages`, kept in sync with
/// [AppNavigationRegistry] and read by the Live Nav Simulator.
class NavigationPagesService extends ChangeNotifier {
  NavigationPagesService._();
  static final NavigationPagesService instance = NavigationPagesService._();

  List<AppNavItem>? _pages;
  bool _loading = false;
  String? _error;
  DateTime? _loadedAt;

  /// Flat page rows from the database, or null until the first successful load.
  List<AppNavItem>? get pages => _pages;
  bool get isLoading => _loading;
  String? get error => _error;
  DateTime? get loadedAt => _loadedAt;
  bool get hasDatabasePages => _pages != null && _pages!.isNotEmpty;

  /// Super Admin: pushes the app's page registry to the database, then reads the stored structure.
  /// Other roles (or a failed sync) fall back to reading what is stored.
  Future<void> syncAndLoad({required bool canSync}) async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      List<dynamic>? rows;
      if (canSync) {
        try {
          final res = await DioClient.dio.put('/permissions/navigation/sync', data: {
            'pages': AppNavigationRegistry.flattenAll().map((p) => p.toSyncJson()).toList(),
          });
          rows = _rowsFrom(res.data);
        } catch (e) {
          _error = 'Sync failed: $e';
        }
      }
      if (rows == null) {
        final res = await DioClient.dio.get('/permissions/navigation');
        rows = _rowsFrom(res.data);
      }
      if (rows != null) {
        _pages = rows
            .whereType<Map>()
            .map((r) => AppNavItem.fromDbRow(Map<String, dynamic>.from(r)))
            .where((p) => p.key.isNotEmpty)
            .toList();
        _loadedAt = DateTime.now();
        if (!canSync) _error = null;
      }
    } catch (e) {
      _error = 'Could not load pages from the database: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Role tree from the database, or the in-app registry when the database has not loaded.
  List<AppNavItem> treeForRole(String role) {
    final stored = _pages;
    if (stored != null && stored.isNotEmpty) {
      return AppNavigationRegistry.buildTreeForRole(stored, role);
    }
    return AppNavigationRegistry.getNavItemsForRole(role);
  }

  static List<dynamic>? _rowsFrom(dynamic body) {
    if (body is Map && body['data'] is Map && (body['data'] as Map)['pages'] is List) {
      return (body['data'] as Map)['pages'] as List;
    }
    return null;
  }
}

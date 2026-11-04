import 'package:flutter/foundation.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/security/role_guard.dart';
import '../models/property_model.dart';

/// Cross-Admin property visibility state for the signed-in user:
/// Admin-level Rent/Resale sharing and the per-property "Share with Other Admins" flags.
/// Access is decided by the backend (Super Admin → Admin → Property Inventory →
/// "Manage Property Visibility Settings").
class PropertySharingController extends ChangeNotifier {
  PropertySharingController._();
  static final PropertySharingController instance = PropertySharingController._();

  static const _teamRoles = {'Admin', 'Sales', 'Telecaller'};

  bool canManage = false;
  bool canManageProperties = false;
  bool shareRent = false;
  bool shareResale = false;
  final Set<String> _hiddenPropertyIds = {};
  final Set<String> _savingPropertyIds = {};
  final Map<String, String> _sharedAdminNames = {};
  final Map<String, String> _sharedAdminCompanies = {};
  final Map<String, ({String name, String company})> _ownerAdminDirectory = {};
  bool savingAdminShare = false;

  /// Bumped when the set of properties shared with this user by other Admins changes after the first load.
  int sharedSetVersion = 0;

  String? _loadedForUserId;
  Future<void>? _inFlight;
  DateTime? _lastFetchAt;

  bool get _eligible => _teamRoles.contains(RoleGuard.currentUser?.role);
  bool get _isSuperAdmin => RoleGuard.currentUser?.role == 'Super Admin';

  Future<void> load({bool force = false}) {
    final userId = RoleGuard.currentUser?.id;
    if (!(_eligible || _isSuperAdmin) || userId == null) {
      _reset();
      return Future.value();
    }
    if (!force && _loadedForUserId == userId) return Future.value();
    return _inFlight ??= _fetch(userId).whenComplete(() => _inFlight = null);
  }

  Future<void> _fetch(String userId) async {
    _lastFetchAt = DateTime.now();
    try {
      final response = await DioClient.dio.get('/properties/sharing/me');
      final data = (response.data is Map ? response.data['data'] : null) as Map?;
      if (data == null || RoleGuard.currentUser?.id != userId) return;
      canManage = data['canManage'] == true;
      canManageProperties = data['canManageProperties'] == true;
      shareRent = data['shareRent'] == true;
      shareResale = data['shareResale'] == true;
      _hiddenPropertyIds
        ..clear()
        ..addAll(((data['hiddenPropertyIds'] as List?) ?? const []).map((e) => e.toString()));
      final names = data['sharedAdminNames'];
      final previousSharedIds = _sharedAdminNames.keys.toSet();
      final wasLoaded = _loadedForUserId == userId;
      _sharedAdminNames
        ..clear()
        ..addAll(names is Map
            ? names.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()))
            : const <String, String>{});
      if (wasLoaded && !setEquals(previousSharedIds, _sharedAdminNames.keys.toSet())) {
        sharedSetVersion++;
      }
      final companies = data['sharedAdminCompanies'];
      _sharedAdminCompanies
        ..clear()
        ..addAll(companies is Map
            ? companies.map((k, v) => MapEntry(k.toString(), (v ?? '').toString()))
            : const <String, String>{});
      final directory = data['ownerAdminDirectory'];
      _ownerAdminDirectory.clear();
      if (directory is Map) {
        directory.forEach((k, v) {
          if (v is Map) {
            _ownerAdminDirectory[k.toString()] =
                (name: (v['name'] ?? '').toString(), company: (v['company'] ?? '').toString());
          }
        });
      }
      _loadedForUserId = userId;
      notifyListeners();
    } catch (_) {}
  }

  void _reset() {
    if (_loadedForUserId == null && !canManage && !canManageProperties) return;
    canManage = false;
    canManageProperties = false;
    shareRent = false;
    shareResale = false;
    _hiddenPropertyIds.clear();
    _sharedAdminNames.clear();
    _sharedAdminCompanies.clear();
    _ownerAdminDirectory.clear();
    _loadedForUserId = null;
    notifyListeners();
  }

  /// Owner Admin name/company badge: other Admins' shared properties, and every Admin-owned property for Super Admin.
  bool showsOwnerAdminBadge(PropertyModel p) {
    if (_isSuperAdmin) return p.adminId != null && !p.id.startsWith('temp_');
    return isSharedFromOtherAdmin(p);
  }

  void _refreshIfMissing() {
    final last = _lastFetchAt;
    if (_inFlight == null && (last == null || DateTime.now().difference(last) > const Duration(seconds: 20))) {
      Future.microtask(() => load(force: true));
    }
  }

  /// True for another Admin's property that the signed-in team member sees through sharing.
  bool isSharedFromOtherAdmin(PropertyModel p) {
    if (!_eligible || p.id.startsWith('temp_')) return false;
    final user = RoleGuard.currentUser;
    if (user == null) return false;
    if (p.organizationId != null && user.organizationId != null) {
      return p.organizationId != user.organizationId;
    }
    return false;
  }

  /// Owner Admin's name for a shared property (never the Sales/Telecaller who added it).
  String? sharedAdminNameFor(PropertyModel p) {
    final name = _isSuperAdmin ? _ownerAdminDirectory[p.adminId]?.name : _sharedAdminNames[p.id];
    if (name == null && showsOwnerAdminBadge(p)) _refreshIfMissing();
    return (name == null || name.trim().isEmpty) ? null : name;
  }

  /// Owner Admin's company (organization) name for a shared property.
  String? sharedAdminCompanyFor(PropertyModel p) {
    final company = _isSuperAdmin ? _ownerAdminDirectory[p.adminId]?.company : _sharedAdminCompanies[p.id];
    return (company == null || company.trim().isEmpty) ? null : company;
  }

  /// Only properties of the viewer's own team can be toggled (shared ones from other Admins are read-only).
  bool canToggleProperty(PropertyModel p) {
    if (!canManageProperties || p.id.startsWith('temp_')) return false;
    final user = RoleGuard.currentUser;
    if (user == null) return false;
    if (p.organizationId != null && user.organizationId != null) {
      return p.organizationId == user.organizationId;
    }
    final teamAdminId = user.role == 'Admin' ? user.id : user.adminId;
    return teamAdminId != null && p.adminId == teamAdminId;
  }

  bool isPropertyShared(String propertyId) => !_hiddenPropertyIds.contains(propertyId);

  bool isSavingProperty(String propertyId) => _savingPropertyIds.contains(propertyId);

  Future<bool> setPropertyShared(String propertyId, bool value) async {
    final wasShared = isPropertyShared(propertyId);
    _applyPropertyFlag(propertyId, value);
    _savingPropertyIds.add(propertyId);
    notifyListeners();
    try {
      await DioClient.dio.patch('/properties/$propertyId/sharing', data: {'shareWithAdmins': value});
      return true;
    } catch (_) {
      _applyPropertyFlag(propertyId, wasShared);
      return false;
    } finally {
      _savingPropertyIds.remove(propertyId);
      notifyListeners();
    }
  }

  void _applyPropertyFlag(String propertyId, bool shared) {
    if (shared) {
      _hiddenPropertyIds.remove(propertyId);
    } else {
      _hiddenPropertyIds.add(propertyId);
    }
  }

  Future<bool> setAdminShare({bool? rent, bool? resale}) async {
    final previousRent = shareRent;
    final previousResale = shareResale;
    if (rent != null) shareRent = rent;
    if (resale != null) shareResale = resale;
    savingAdminShare = true;
    notifyListeners();
    try {
      await DioClient.dio.put('/properties/sharing/me', data: {
        'shareRent': ?rent,
        'shareResale': ?resale,
      });
      return true;
    } catch (_) {
      shareRent = previousRent;
      shareResale = previousResale;
      return false;
    } finally {
      savingAdminShare = false;
      notifyListeners();
    }
  }
}

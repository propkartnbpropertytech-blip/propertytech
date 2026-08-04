import '../../features/auth/models/user_model.dart';

/// Client-side RBAC helpers. Server must still enforce every mutation.
class RoleGuard {
  static UserModel? currentUser;
  static bool isSuperAdmin(String? role) =>
      (role ?? '').toLowerCase() == 'super admin';

  static bool isAdmin(String? role) {
    final r = (role ?? '').toLowerCase();
    return r == 'admin' || r == 'super admin';
  }

  static bool canManageEmployees(String? role) => isAdmin(role);

  /// Audit logs — Super Admin only (defense-in-depth).
  static bool canViewAuditLogs(String? role) => isSuperAdmin(role);

  /// Settings mutations that affect org lookups (cities/areas).
  static bool canManageLookups(String? role) => isSuperAdmin(role);

  /// Only Super Admin may assign/create/update/delete Admin accounts.
  static bool canAssignAdminRole(String? callerRole) => isSuperAdmin(callerRole);

  /// Safe internal redirect allowlist (blocks privilege jump via `?from=`).
  static const allowedPostLoginPaths = <String>{
    '/dashboard',
    '/properties',
    '/requirements',
    '/clients',
    '/owners',
    '/builders',
    '/profile',
    '/bin',
    '/settings',
    '/settings/audit-logs',
    '/users',
  };

  static String? sanitizeRedirectPath(String? raw, {String? role}) {
    if (raw == null || raw.isEmpty) return null;
    String path;
    try {
      path = Uri.decodeComponent(raw);
    } catch (_) {
      return null;
    }
    // Reject absolute / scheme-relative URLs
    if (path.contains('://') || path.startsWith('//')) return null;
    if (!path.startsWith('/')) return null;

    final pathOnly = path.split('?').first.split('#').first;
    final allowed = allowedPostLoginPaths.any(
      (p) => pathOnly == p || pathOnly.startsWith('$p/'),
    );
    if (!allowed) return null;

    if (pathOnly.startsWith('/users') && !canManageEmployees(role)) {
      return '/dashboard';
    }
    if (pathOnly.startsWith('/settings/audit-logs') && !canViewAuditLogs(role)) {
      return '/dashboard';
    }
    return path;
  }

  /// Returns an error message if [callerRole] cannot create/update a user
  /// with [targetRoleName]; null if allowed.
  static String? validateUserMutation({
    required String? callerRole,
    required String? targetRoleName,
    required bool isDelete,
  }) {
    if (!canManageEmployees(callerRole)) {
      return 'You do not have permission to manage employees.';
    }

    final target = (targetRoleName ?? '').toLowerCase();
    if (target == 'super admin') {
      return 'Super Admin accounts cannot be created or modified from the app.';
    }

    if (target == 'admin') {
      if (!canAssignAdminRole(callerRole)) {
        return 'Only Super Admin can create, update, or delete Admin users.';
      }
    }

    if (isDelete && target == 'admin' && !canAssignAdminRole(callerRole)) {
      return 'Only Super Admin can delete Admin users.';
    }

    if (!isSuperAdmin(callerRole) && target == 'admin') {
      return 'Admins may only manage Sales users.';
    }

    return null;
  }

  static String? roleNameForId(String? roleId, Iterable<({String id, String name})> roles) {
    if (roleId == null) return null;
    for (final r in roles) {
      if (r.id == roleId) return r.name;
    }
    return null;
  }
}

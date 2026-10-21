import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/core/security/permission_matrix_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RBAC Matrix & Privilege Escalation Security Tests', () {
    setUp(() async {
      await PermissionMatrixService.instance.resetToDefaults();
    });

    test('Super Admin always holds 100% active permissions', () {
      final matrix = PermissionMatrixService.instance;
      expect(matrix.hasPermission('Super Admin', 'page.dashboard'), isTrue);
      expect(matrix.hasPermission('Super Admin', 'page.properties'), isTrue);
      expect(matrix.hasPermission('Super Admin', 'page.audit_logs'), isTrue);
      expect(matrix.hasPermission('Super Admin', 'system.manage_lookups'), isTrue);
      expect(matrix.hasPermission('Super Admin', 'non_existent_arbitrary_key'), isTrue);
    });

    test('Non-admin roles cannot perform admin operations', () {
      expect(RoleGuard.canManageLookups('Telecaller'), isFalse);
      expect(RoleGuard.canManageEmployees('Sales'), isFalse);
      expect(RoleGuard.canManageEmployees('Telecaller'), isFalse);
      expect(RoleGuard.canAssignAdminRole('Sales'), isFalse);
      expect(RoleGuard.canAssignAdminRole('Telecaller'), isFalse);
    });

    test('Arbitrary or unrecognized roles fail closed (no permissions granted)', () {
      expect(RoleGuard.isAdmin('hacker'), isFalse);
      expect(RoleGuard.isSales('hacker'), isFalse);
      expect(RoleGuard.isTelecaller('hacker'), isFalse);
      expect(RoleGuard.isSuperAdmin('hacker'), isFalse);
      expect(RoleGuard.canViewAuditLogs('hacker'), isFalse);
    });

    test('Telecaller cannot access audit logs or admin lead allocation', () {
      expect(RoleGuard.canViewAuditLogs('Telecaller'), isFalse);
      expect(RoleGuard.canAssignAdminRole('Telecaller'), isFalse);
    });
  });
}

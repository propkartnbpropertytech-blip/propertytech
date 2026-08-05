import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/security/role_guard.dart';

void main() {
  group('Telecaller Role Guard Tests', () {
    test('Telecaller is recognized as having Admin privileges but cannot manage employees', () {
      expect(RoleGuard.isAdmin('Telecaller'), isTrue);
      expect(RoleGuard.canManageEmployees('Telecaller'), isFalse);
    });

    test('Telecaller cannot view audit logs or manage lookups', () {
      expect(RoleGuard.canViewAuditLogs('Telecaller'), isFalse);
      expect(RoleGuard.canManageLookups('Telecaller'), isFalse);
    });

    test('Telecaller cannot create or manage any employees', () {
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Telecaller',
          targetRoleName: 'Sales',
          isDelete: false,
        ),
        isNotNull,
      );

      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Telecaller',
          targetRoleName: 'Telecaller',
          isDelete: false,
        ),
        isNotNull,
      );
    });

    test('Admin can manage Sales and Telecallers, but not Admin/Super Admin', () {
      // Manage Sales
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Admin',
          targetRoleName: 'Sales',
          isDelete: false,
        ),
        isNull,
      );

      // Manage Telecaller
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Admin',
          targetRoleName: 'Telecaller',
          isDelete: false,
        ),
        isNull,
      );

      // Manage Admin
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Admin',
          targetRoleName: 'Admin',
          isDelete: false,
        ),
        isNotNull,
      );
    });

    test('Super Admin can manage Admin, but not Sales/Telecaller directly', () {
      // Manage Admin
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Super Admin',
          targetRoleName: 'Admin',
          isDelete: false,
        ),
        isNull,
      );

      // Manage Sales
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Super Admin',
          targetRoleName: 'Sales',
          isDelete: false,
        ),
        isNotNull,
      );

      // Manage Telecaller
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Super Admin',
          targetRoleName: 'Telecaller',
          isDelete: false,
        ),
        isNotNull,
      );
    });
  });
}

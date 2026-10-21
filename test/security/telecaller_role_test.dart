import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/security/role_guard.dart';

void main() {
  group('Telecaller Role Guard Tests', () {
    test('Telecaller is recognized as a dedicated role without Admin privileges and cannot manage employees', () {
      expect(RoleGuard.isTelecaller('Telecaller'), isTrue);
      expect(RoleGuard.isAdmin('Telecaller'), isFalse);
      expect(RoleGuard.canManageEmployees('Telecaller'), isFalse);
      expect(RoleGuard.canAccessCampaign('Telecaller'), isTrue);
    });

    test('Telecaller cannot view audit logs or manage lookups', () {
      expect(RoleGuard.canViewAuditLogs('Telecaller'), isFalse);
      expect(RoleGuard.canManageLookups('Telecaller'), isFalse);
    });

    test('Super Admin, Admin and Sales can manage city/area lookups', () {
      expect(RoleGuard.canManageLookups('Super Admin'), isTrue);
      expect(RoleGuard.canManageLookups('Admin'), isTrue);
      expect(RoleGuard.canManageLookups('Sales'), isTrue);
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

    test('Super Admin can manage Admin, Sales and Telecaller', () {
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Super Admin',
          targetRoleName: 'Admin',
          isDelete: false,
        ),
        isNull,
      );

      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Super Admin',
          targetRoleName: 'Sales',
          isDelete: false,
        ),
        isNull,
      );

      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Super Admin',
          targetRoleName: 'Telecaller',
          isDelete: false,
        ),
        isNull,
      );
    });
  });
}

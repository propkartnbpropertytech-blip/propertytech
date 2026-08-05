import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/security/role_guard.dart';

void main() {
  group('RoleGuard', () {
    test('Sales cannot manage employees', () {
      expect(RoleGuard.canManageEmployees('Sales'), isFalse);
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Sales',
          targetRoleName: 'Admin',
          isDelete: false,
        ),
        isNotNull,
      );
    });

    test('Admin cannot create or delete Admin', () {
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Admin',
          targetRoleName: 'Admin',
          isDelete: false,
        ),
        isNotNull,
      );
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Admin',
          targetRoleName: 'Admin',
          isDelete: true,
        ),
        isNotNull,
      );
    });

    test('Admin can manage Sales', () {
      expect(
        RoleGuard.validateUserMutation(
          callerRole: 'Admin',
          targetRoleName: 'Sales',
          isDelete: false,
        ),
        isNull,
      );
    });

    test('Super Admin can manage Admin but not Super Admin', () {
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
          targetRoleName: 'Super Admin',
          isDelete: false,
        ),
        isNotNull,
      );
    });

    test('JWT/role string tampering as Broker is denied', () {
      expect(RoleGuard.canManageEmployees('Broker'), isFalse);
      expect(RoleGuard.canAssignAdminRole('Broker'), isFalse);
    });

    test('Sales and Admin cannot view audit logs', () {
      expect(RoleGuard.canViewAuditLogs('Sales'), isFalse);
      expect(RoleGuard.canViewAuditLogs('Admin'), isFalse);
      expect(RoleGuard.canViewAuditLogs('Super Admin'), isTrue);
    });

    test('sanitizeRedirectPath blocks open redirects and privilege jumps', () {
      expect(RoleGuard.sanitizeRedirectPath('https://evil.com'), isNull);
      expect(RoleGuard.sanitizeRedirectPath('//evil.com'), isNull);
      expect(
        RoleGuard.sanitizeRedirectPath('/users', role: 'Sales'),
        '/dashboard',
      );
      expect(
        RoleGuard.sanitizeRedirectPath('/settings/audit-logs', role: 'Sales'),
        '/dashboard',
      );
      expect(
        RoleGuard.sanitizeRedirectPath('/dashboard', role: 'Sales'),
        '/dashboard',
      );
    });

    test('sanitizeRedirectPath preserves query parameters and path parameters', () {
      expect(
        RoleGuard.sanitizeRedirectPath('/properties?openId=123', role: 'Sales'),
        '/properties?openId=123',
      );
      expect(
        RoleGuard.sanitizeRedirectPath('/properties/456', role: 'Sales'),
        '/properties/456',
      );
      expect(
        RoleGuard.sanitizeRedirectPath('/dashboard?foo=bar#baz', role: 'Sales'),
        '/dashboard?foo=bar#baz',
      );
    });
  });
}

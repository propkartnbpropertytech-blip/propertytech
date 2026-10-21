import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/security/role_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Authorization & Route Guard Security Tests', () {
    test('Role classification correctly identifies roles', () {
      expect(RoleGuard.isSuperAdmin('Super Admin'), isTrue);
      expect(RoleGuard.isSuperAdmin('Admin'), isFalse);
      expect(RoleGuard.isAdmin('Admin'), isTrue);
      expect(RoleGuard.isAdmin('Super Admin'), isTrue);
      expect(RoleGuard.isAdmin('Sales'), isFalse);
      expect(RoleGuard.isAdmin('Telecaller'), isFalse);
      expect(RoleGuard.isSales('Sales'), isTrue);
      expect(RoleGuard.isTelecaller('Telecaller'), isTrue);
    });

    test('Audit logs access is strictly restricted to Super Admin', () {
      expect(RoleGuard.canViewAuditLogs('Super Admin'), isTrue);
      expect(RoleGuard.canViewAuditLogs('Admin'), isFalse);
      expect(RoleGuard.canViewAuditLogs('Sales'), isFalse);
      expect(RoleGuard.canViewAuditLogs('Telecaller'), isFalse);
      expect(RoleGuard.canViewAuditLogs(null), isFalse);
    });

    test('Admin role assignment is restricted to Super Admin', () {
      expect(RoleGuard.canAssignAdminRole('Super Admin'), isTrue);
      expect(RoleGuard.canAssignAdminRole('Admin'), isFalse);
      expect(RoleGuard.canAssignAdminRole('Sales'), isFalse);
      expect(RoleGuard.canAssignAdminRole('Telecaller'), isFalse);
    });

    test('sanitizeRedirectPath neutralizes open redirects and malicious protocols', () {
      expect(RoleGuard.sanitizeRedirectPath('https://malicious-site.com', role: 'Admin'), isNull);
      expect(RoleGuard.sanitizeRedirectPath('//evil.com/phishing', role: 'Admin'), isNull);
      expect(RoleGuard.sanitizeRedirectPath('javascript:alert(1)', role: 'Admin'), isNull);
      expect(RoleGuard.sanitizeRedirectPath('/properties', role: 'Admin'), equals('/properties'));
    });

    test('sanitizeRedirectPath blocks privilege escalation to audit logs for non-super-admins', () {
      expect(RoleGuard.sanitizeRedirectPath('/settings/audit-logs', role: 'Sales'), equals('/dashboard'));
      expect(RoleGuard.sanitizeRedirectPath('/settings/audit-logs', role: 'Admin'), equals('/dashboard'));
      expect(RoleGuard.sanitizeRedirectPath('/settings/audit-logs', role: 'Super Admin'), equals('/settings/audit-logs'));
    });
  });
}

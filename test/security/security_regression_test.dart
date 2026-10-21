import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/core/security/permission_matrix_service.dart';
import 'package:propkart/core/storage/secure_storage.dart';
import 'package:propkart/core/storage/session_cleanup.dart';
import 'package:propkart/core/utils/validators.dart';
import 'package:propkart/core/utils/team_user_visibility.dart';
import 'package:propkart/features/users/models/user_model.dart';
import 'security_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockSecurityStorage();

  group('Master Security Regression Test Suite', () {
    test('1. RoleGuard invariants: Super Admin immutable, non-admin contained', () {
      expect(RoleGuard.isSuperAdmin('Super Admin'), isTrue);
      expect(RoleGuard.isAdmin('Super Admin'), isTrue);
      expect(RoleGuard.isAdmin('Admin'), isTrue);
      expect(RoleGuard.isAdmin('Sales'), isFalse);
      expect(RoleGuard.isAdmin('Telecaller'), isFalse);
      expect(RoleGuard.canViewAuditLogs('Admin'), isFalse);
      expect(RoleGuard.canViewAuditLogs('Sales'), isFalse);
      expect(RoleGuard.canViewAuditLogs('Telecaller'), isFalse);
    });

    test('2. PermissionMatrixService invariants: Super Admin 100% active', () {
      final matrix = PermissionMatrixService.instance;
      expect(matrix.hasPermission('Super Admin', 'page.dashboard'), isTrue);
      expect(matrix.hasPermission('Super Admin', 'system.arbitrary_feature'), isTrue);
    });

    test('3. Token & Session isolation: complete wipe on clearLocalSession', () async {
      final storage = SecureStorage();
      await storage.saveToken('test_regression_token', persist: false);
      expect(await storage.getToken(), equals('test_regression_token'));

      await SessionCleanup.clearLocalSession(clearToken: true);
      expect(SecureStorage.inMemoryToken, isNull);
      expect(await storage.getToken(), isNull);
    });

    test('4. Input validation invariants: strict mobile and email rejection of malicious inputs', () {
      expect(CRMValidators.email('valid@example.com'), isNull);
      expect(CRMValidators.email('injection"OR"1"="1'), isNotNull);
      expect(CRMValidators.indianMobile('9876543210'), isNull);
      expect(CRMValidators.indianMobile('1234567890'), isNull); // 10 digits
      expect(CRMValidators.indianMobile('123456789'), isNotNull); // 9 digits
    });

    test('5. Team User Visibility invariants: Telecaller cannot see peer Telecallers', () {
      final List<UserModel> users = [
        UserModel(
          id: 'u1',
          fullName: 'Telecaller One',
          email: 'tc1@test.com',
          roleId: 'r_tc',
          roleName: 'Telecaller',
          isActive: true,
          createdAt: DateTime.now().toIso8601String(),
        ),
        UserModel(
          id: 'u2',
          fullName: 'Telecaller Two',
          email: 'tc2@test.com',
          roleId: 'r_tc',
          roleName: 'Telecaller',
          isActive: true,
          createdAt: DateTime.now().toIso8601String(),
        ),
      ];

      final visible = TeamUserVisibility.visibleTelecallerUsers(
        users: users,
        currentRole: 'Telecaller',
        currentUserId: 'u1',
      );
      expect(visible, isEmpty);
    });
  });
}

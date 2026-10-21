import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/utils/team_user_visibility.dart';
import 'package:propkart/features/users/models/user_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IDOR & Object Boundary Security Tests', () {
    final userAdmin = UserModel(
      id: 'admin_1',
      fullName: 'Admin User',
      email: 'admin@test.com',
      roleId: 'role_admin',
      roleName: 'Admin',
      isActive: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    final userSales1 = UserModel(
      id: 'sales_1',
      fullName: 'Sales User 1',
      email: 'sales1@test.com',
      roleId: 'role_sales',
      roleName: 'Sales Executive',
      isActive: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    final userTelecaller1 = UserModel(
      id: 'tc_1',
      fullName: 'Telecaller 1',
      email: 'tc1@test.com',
      roleId: 'role_tc',
      roleName: 'Telecaller',
      isActive: true,
      createdAt: DateTime.now().toIso8601String(),
    );

    test('Sales role cannot access employee filter lists (defense against user enumeration)', () {
      expect(TeamUserVisibility.canUseFilter('Sales'), isFalse);
      expect(TeamUserVisibility.canUseFilter('Broker'), isFalse);
      expect(TeamUserVisibility.canUseFilter('Admin'), isTrue);
      expect(TeamUserVisibility.canUseFilter('Super Admin'), isTrue);
    });

    test('Telecaller cannot enumerate other telecallers via visibility filter', () {
      final List<UserModel> list = [userAdmin, userSales1, userTelecaller1];
      final visible = TeamUserVisibility.visibleTelecallerUsers(
        users: list,
        currentRole: 'Telecaller',
        currentUserId: 'tc_1',
      );
      expect(visible, isEmpty);
    });

    test('Admin cannot see Super Admin in managed employee lists', () {
      final List<UserModel> list = [userAdmin, userSales1, userTelecaller1];
      final visible = TeamUserVisibility.visibleUsers(
        users: list,
        currentRole: 'Admin',
        currentUserId: 'admin_1',
      );
      // Admin should only see subordinate roles (Sales & Telecaller), never Admin peers or Super Admin
      final roleNames = visible.map((u) => u.roleName.toLowerCase()).toList();
      expect(roleNames.contains('admin'), isFalse);
      expect(roleNames.contains('sales executive'), isTrue);
      expect(roleNames.contains('telecaller'), isTrue);
    });
  });
}

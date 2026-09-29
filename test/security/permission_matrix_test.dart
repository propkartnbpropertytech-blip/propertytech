import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/security/permission_matrix_service.dart';
import 'package:propkart/core/security/role_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PermissionMatrixService.instance.resetToDefaults();
  });

  group('PermissionMatrixService & Super Admin Safeguards', () {
    test('Super Admin always has 100% active permissions', () {
      final service = PermissionMatrixService.instance;
      final total = PermissionMatrixService.allPermissions.length;

      expect(service.getActiveCount('Super Admin'), equals(total));
      expect(service.getActiveCount('superadmin'), equals(total));

      for (final p in PermissionMatrixService.allPermissions) {
        expect(service.hasPermission('Super Admin', p.key), isTrue);
      }
    });

    test('Super Admin cannot have permissions revoked', () async {
      final service = PermissionMatrixService.instance;

      // Attempt to revoke
      await service.setPermission('Super Admin', 'page.dashboard', false);
      expect(service.hasPermission('Super Admin', 'page.dashboard'), isTrue);

      await service.setCategoryPermissions('Super Admin', PermissionCategory.pages, false);
      expect(service.hasPermission('Super Admin', 'page.dashboard'), isTrue);
    });

    test('Admin standard defaults and dynamic toggles', () async {
      final service = PermissionMatrixService.instance;

      // Default Admin can view employees and reports
      expect(service.hasPermission('Admin', 'page.employees'), isTrue);
      expect(RoleGuard.canViewPage('Admin', '/users'), isTrue);

      // Disable employees for Admin
      await service.setPermission('Admin', 'page.employees', false);
      expect(service.hasPermission('Admin', 'page.employees'), isFalse);
      expect(service.canViewRoute('Admin', '/users'), isFalse);

      // Re-enable employees for Admin
      await service.setPermission('Admin', 'page.employees', true);
      expect(service.hasPermission('Admin', 'page.employees'), isTrue);
      expect(service.canViewRoute('Admin', '/users'), isTrue);
    });

    test('Sales standard defaults and dynamic elevation', () async {
      final service = PermissionMatrixService.instance;

      // By default Sales cannot access reports
      expect(service.hasPermission('Sales', 'page.reports'), isFalse);
      expect(service.canViewRoute('Sales', '/reports'), isFalse);

      // Dynamically grant reports access to Sales
      await service.setPermission('Sales', 'page.reports', true);
      expect(service.hasPermission('Sales', 'page.reports'), isTrue);
      expect(service.canViewRoute('Sales', '/reports'), isTrue);
    });

    test('Telecaller standard defaults and campaign access', () async {
      final service = PermissionMatrixService.instance;

      // Telecaller has campaign access by default
      expect(service.hasPermission('Telecaller', 'page.campaign'), isTrue);
      expect(service.canViewRoute('Telecaller', '/campaign'), isTrue);

      // Revoke campaign
      await service.setPermission('Telecaller', 'page.campaign', false);
      expect(service.hasPermission('Telecaller', 'page.campaign'), isFalse);
      expect(service.canViewRoute('Telecaller', '/campaign'), isFalse);
    });

    test('Category bulk toggle works for roles', () async {
      final service = PermissionMatrixService.instance;

      // Disable all Property operations for Sales
      await service.setCategoryPermissions('Sales', PermissionCategory.properties, false);
      final propPerms = PermissionMatrixService.allPermissions
          .where((p) => p.category == PermissionCategory.properties);

      for (final p in propPerms) {
        expect(service.hasPermission('Sales', p.key), isFalse);
      }

      // Re-enable all Property operations for Sales
      await service.setCategoryPermissions('Sales', PermissionCategory.properties, true);
      for (final p in propPerms) {
        expect(service.hasPermission('Sales', p.key), isTrue);
      }
    });

    test('Reset to defaults clears overrides', () async {
      final service = PermissionMatrixService.instance;

      // Mutate Sales & Admin
      await service.setPermission('Sales', 'page.reports', true);
      await service.setPermission('Admin', 'page.properties', false);

      expect(service.hasPermission('Sales', 'page.reports'), isTrue);
      expect(service.hasPermission('Admin', 'page.properties'), isFalse);

      // Reset
      await service.resetToDefaults();

      expect(service.hasPermission('Sales', 'page.reports'), isFalse);
      expect(service.hasPermission('Admin', 'page.properties'), isTrue);
    });

    test('Export JSON includes valid structure', () {
      final service = PermissionMatrixService.instance;
      final json = service.exportJson();

      expect(json, contains('version'));
      expect(json, contains('Super Admin'));
      expect(json, contains('Admin'));
      expect(json, contains('Telecaller'));
      expect(json, contains('Sales'));
      expect(json, contains('page.dashboard'));
    });
  });
}

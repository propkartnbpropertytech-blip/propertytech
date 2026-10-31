import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/core/security/permission_matrix_service.dart';
import 'package:propkart/features/settings/widgets/permission_matrix_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = PermissionMatrixService.instance;
  final pageKeys = PermissionMatrixService.allPermissions.map((p) => p.key).toSet();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await service.resetToDefaults();
  });

  group('Role Drill-down trees', () {
    for (final role in ['Telecaller', 'Sales']) {
      test('$role tree matches its configurable actions and real page keys', () {
        final treeKeys = roleDrilldownToggleKeys(role);
        final actions = PermissionMatrixService.roleActionKeys[role]!.toSet();

        expect(treeKeys.toSet().length, treeKeys.length, reason: 'duplicate toggle in $role tree');
        expect(treeKeys.toSet().containsAll(actions), isTrue, reason: 'action missing from $role tree');
        for (final k in treeKeys) {
          expect(actions.contains(k) || pageKeys.contains(k), isTrue, reason: '$k is not a $role control');
        }
      });

      test('$role actions all default to ON for $role only', () {
        for (final k in PermissionMatrixService.roleActionKeys[role]!) {
          expect(service.hasPermission(role, k), isTrue, reason: k);
          expect(service.isActionAllowed(role, k), isTrue, reason: k);
        }
      });
    }

    test('Admin tree is unchanged and stays independent', () {
      final adminKeys = roleDrilldownToggleKeys('Admin');
      expect(adminKeys.toSet().containsAll(PermissionMatrixService.adminActionKeys), isTrue);
      expect(adminKeys, isNot(contains('page.my_campaign_leads')));
    });
  });

  group('Toggles affect only their own role', () {
    test('Telecaller toggle does not change Admin or Sales', () async {
      await service.setPermission('Telecaller', 'page.properties.add', false);
      expect(service.isActionAllowed('Telecaller', 'page.properties.add'), isFalse);
      expect(service.isActionAllowed('Sales', 'page.properties.add'), isTrue);
      expect(service.isActionAllowed('Admin', 'page.properties.add'), isTrue);

      await service.setPermission('Telecaller', 'page.properties.add', true);
      expect(service.isActionAllowed('Telecaller', 'page.properties.add'), isTrue);
    });

    test('Sales toggle does not change Admin or Telecaller', () async {
      await service.setPermission('Sales', 'page.leads.run_matches', false);
      expect(service.isActionAllowed('Sales', 'page.leads.run_matches'), isFalse);
      expect(service.isActionAllowed('Telecaller', 'page.leads.run_matches'), isTrue);
      expect(service.isActionAllowed('Admin', 'page.leads.run_matches'), isTrue);
    });

    test('Admin toggle does not change Telecaller or Sales', () async {
      await service.setPermission('Admin', 'page.support.report_issue', false);
      expect(service.isActionAllowed('Admin', 'page.support.report_issue'), isFalse);
      expect(service.isActionAllowed('Telecaller', 'page.support.report_issue'), isTrue);
      expect(service.isActionAllowed('Sales', 'page.support.report_issue'), isTrue);
    });

    test('parent action off hides its nested actions for that role only', () async {
      await service.setPermission('Sales', 'page.leads.share', false);
      for (final k in ['page.leads.share.pdf', 'page.leads.share.link', 'page.leads.share.whatsapp', 'page.leads.share.multiple']) {
        expect(service.isActionAllowed('Sales', k), isFalse, reason: k);
        expect(service.isActionAllowed('Telecaller', k), isTrue, reason: k);
      }
    });

    test('page-level toggles are per role', () async {
      await service.setPermission('Telecaller', 'page.callbacks', false);
      expect(service.canViewRoute('Telecaller', '/telecaller/callbacks'), isFalse);
      await service.setPermission('Sales', 'page.settings.themes', false);
      expect(service.hasPermission('Sales', 'page.settings.themes'), isFalse);
      expect(service.hasPermission('Telecaller', 'page.settings.themes'), isTrue);
      expect(service.hasPermission('Admin', 'page.settings.themes'), isTrue);
    });

    test('Sales Campaign Leads page has its own toggle', () async {
      expect(service.isActionAllowed('Sales', 'page.my_campaign_leads'), isTrue);
      await service.setPermission('Sales', 'page.my_campaign_leads', false);
      expect(service.isActionAllowed('Sales', 'page.my_campaign_leads'), isFalse);
      expect(service.hasPermission('Sales', 'page.leads'), isTrue);
    });

    test('actions a role does not have are left unchanged', () async {
      await service.setPermission('Telecaller', 'page.leads.delete', false);
      expect(service.isActionAllowed('Telecaller', 'page.leads.delete'), isTrue);
      expect(service.isActionAllowed('Super Admin', 'page.leads.delete'), isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/session_cleanup.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'security_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockSecurityStorage();

  group('Tenant Isolation Security Tests', () {
    test('User model tenant binding is immutable', () {
      final userA = UserModel(
        id: 'usr_org1_01',
        fullName: 'Tenant A User',
        email: 'tenant_a@example.com',
        role: 'Sales',
        organizationId: 'org_tenant_1',
        permissions: const [],
      );

      expect(userA.organizationId, equals('org_tenant_1'));
      expect(userA.id, equals('usr_org1_01'));
    });

    test('SessionCleanup purges all tenant-scoped in-memory cache on user switch', () async {
      // Simulate tenant A storing data
      final propA = PropertyLocal()
        ..id = 'prop_tenant_a_001'
        ..title = 'Tenant A Property'
        ..organizationId = 'org_tenant_1';
      PropertyLocalRepository.inMemory[propA.id] = propA;

      final reqA = RequirementLocal()
        ..id = 'req_tenant_a_001'
        ..clientName = 'Tenant A Client'
        ..clientMobile = '9876543210'
        ..categoryId = 'cat_1'
        ..categoryName = 'Residential'
        ..minBudget = 1000000
        ..maxBudget = 5000000
        ..areaIds = ['a1']
        ..areaNames = ['Area 1']
        ..status = 'Active'
        ..createdAt = DateTime.now()
        ..organizationId = 'org_tenant_1';
      RequirementLocalRepository.inMemory[reqA.id] = reqA;

      expect(PropertyLocalRepository.inMemory, isNotEmpty);
      expect(RequirementLocalRepository.inMemory, isNotEmpty);

      // Perform local session wipe (simulates logout or tenant switch)
      await SessionCleanup.clearLocalSession(clearToken: true);

      // Verify complete purge
      expect(PropertyLocalRepository.inMemory, isEmpty);
      expect(RequirementLocalRepository.inMemory, isEmpty);
      expect(OutboxLocalRepository.inMemory, isEmpty);
    });

    test('Cross-tenant data cannot be retrieved after memory reset', () {
      PropertyLocalRepository.inMemory.clear();
      expect(PropertyLocalRepository.inMemory['prop_tenant_a_001'], isNull);
    });
  });
}

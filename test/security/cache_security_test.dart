import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/local_repositories.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/session_cleanup.dart';
import 'security_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockSecurityStorage();

  group('Cache Security & Data Clearance Tests', () {
    test('All in-memory repositories are cleared during SessionCleanup', () async {
      PropertyLocalRepository.inMemory['p1'] = PropertyLocal()..id = 'p1';
      RequirementLocalRepository.inMemory['r1'] = RequirementLocal()..id = 'r1';
      FollowupLocalRepository.inMemory['f1'] = FollowupLocal()..id = 'f1';
      BuilderLocalRepository.inMemory['b1'] = BuilderLocal()..id = 'b1';
      OwnerLocalRepository.inMemory['o1'] = OwnerLocal()..id = 'o1';
      LookupLocalRepository.inMemory['l1'] = LookupItemLocal()..id = 'l1';
      OutboxLocalRepository.inMemory['ob1'] = OutboxLocal()..id = 'ob1';
      ClientLocalRepository.inMemory['c1'] = ClientLocal()..id = 'c1';

      expect(PropertyLocalRepository.inMemory, isNotEmpty);
      expect(RequirementLocalRepository.inMemory, isNotEmpty);
      expect(FollowupLocalRepository.inMemory, isNotEmpty);
      expect(BuilderLocalRepository.inMemory, isNotEmpty);
      expect(OwnerLocalRepository.inMemory, isNotEmpty);
      expect(LookupLocalRepository.inMemory, isNotEmpty);
      expect(OutboxLocalRepository.inMemory, isNotEmpty);
      expect(ClientLocalRepository.inMemory, isNotEmpty);

      await SessionCleanup.clearLocalSession(clearToken: false);

      expect(PropertyLocalRepository.inMemory, isEmpty);
      expect(RequirementLocalRepository.inMemory, isEmpty);
      expect(FollowupLocalRepository.inMemory, isEmpty);
      expect(BuilderLocalRepository.inMemory, isEmpty);
      expect(OwnerLocalRepository.inMemory, isEmpty);
      expect(LookupLocalRepository.inMemory, isEmpty);
      expect(OutboxLocalRepository.inMemory, isEmpty);
      expect(ClientLocalRepository.inMemory, isEmpty);
    });
  });
}

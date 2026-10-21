import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/session_cleanup.dart';
import 'package:propkart/core/storage/secure_storage.dart';
import 'security_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockSecurityStorage();

  group('Session Security Lifecycle Tests', () {
    test('Default session expiration hours is 8', () async {
      final storage = SecureStorage();
      final hours = await storage.getSessionExpirationHours();
      expect(hours, equals(8));
    });

    test('Forced logout stream emits when session is invalidated', () async {
      int count = 0;
      final sub = SessionCleanup.onForcedLogout.listen((_) {
        count++;
      });

      SessionCleanup.notifyForcedLogout();
      SessionCleanup.notifyForcedLogout();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(count, equals(2));
      await sub.cancel();
    });

    test('Session cleanup clears tokens and in-memory caches', () async {
      final storage = SecureStorage();
      await storage.saveToken('jwt_session_token', persist: false);
      expect(await storage.getToken(), equals('jwt_session_token'));

      await SessionCleanup.clearLocalSession(clearToken: true);

      expect(SecureStorage.inMemoryToken, isNull);
      expect(await storage.getToken(), isNull);
    });
  });
}

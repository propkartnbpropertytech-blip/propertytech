import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/secure_storage.dart';
import 'package:propkart/core/storage/session_cleanup.dart';
import 'package:propkart/core/security/secure_log.dart';
import 'package:propkart/core/utils/validators.dart';
import 'security_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockSecurityStorage();

  group('Authentication Security Tests', () {
    test('Password complexity & validation enforces required length', () {
      expect(CRMValidators.minLength('12345', 6), isNotNull);
      expect(CRMValidators.minLength('123456', 6), isNull);
      expect(CRMValidators.required(''), isNotNull);
      expect(CRMValidators.required('   '), isNotNull);
      expect(CRMValidators.required('securePassword123'), isNull);
    });

    test('SecureLog redacts credentials, passwords, and tokens', () {
      const rawLog = 'User login attempt email=user@test.com password=SuperSecret!123 token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0In0.abcdef123456';
      final redacted = SecureLog.redact(rawLog);
      expect(redacted.contains('SuperSecret!123'), isFalse);
      expect(redacted.contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'), isFalse);
    });

    test('Login sets in-memory authentication token and logout purges it', () async {
      final storage = SecureStorage();
      await storage.saveToken('test_auth_token_sample', persist: false);
      expect(await storage.getToken(), equals('test_auth_token_sample'));

      await storage.deleteToken();
      expect(await storage.getToken(), isNull);
      expect(SecureStorage.inMemoryToken, isNull);
      expect(SecureStorage.inMemoryRefreshToken, isNull);
    });

    test('Session forced logout stream signals unauthenticated state', () async {
      bool forcedLogoutFired = false;
      final sub = SessionCleanup.onForcedLogout.listen((_) {
        forcedLogoutFired = true;
      });

      SessionCleanup.notifyForcedLogout();
      await Future.delayed(const Duration(milliseconds: 10));

      expect(forcedLogoutFired, isTrue);
      await sub.cancel();
    });
  });
}

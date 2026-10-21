import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/storage/secure_storage.dart';
import 'package:propkart/core/security/secure_log.dart';
import 'security_test_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockSecurityStorage();

  group('Token Security & Storage Tests', () {
    final storage = SecureStorage();

    setUp(() async {
      await storage.deleteToken();
    });

    tearDown(() async {
      await storage.deleteToken();
    });

    test('Access and refresh tokens can be safely stored and retrieved', () async {
      await storage.saveToken('test_jwt_access_token_123', persist: false);
      await storage.saveRefreshToken('test_refresh_token_456', persist: false);

      expect(await storage.getToken(), equals('test_jwt_access_token_123'));
      expect(await storage.getRefreshToken(), equals('test_refresh_token_456'));
    });

    test('deleteToken completely purges tokens from memory', () async {
      await storage.saveToken('token_to_purge', persist: false);
      await storage.saveRefreshToken('refresh_to_purge', persist: false);

      await storage.deleteToken();

      expect(SecureStorage.inMemoryToken, isNull);
      expect(SecureStorage.inMemoryRefreshToken, isNull);
      expect(await storage.getToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
    });

    test('SecureLog redacts authorization bearer tokens', () {
      final logMessage = 'Header Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.do_not_leak_this';
      final redacted = SecureLog.redact(logMessage);

      expect(redacted.contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'), isFalse);
      expect(redacted.contains('[REDACTED]'), isTrue);
    });
  });
}

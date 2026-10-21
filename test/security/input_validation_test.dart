import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/utils/validators.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Input Validation Security Tests', () {
    test('Email validator accepts valid emails and rejects malformed/injected strings', () {
      expect(CRMValidators.email('test@example.com'), isNull);
      expect(CRMValidators.email('user.name+tag@sub.domain.co'), isNull);

      expect(CRMValidators.email('plainaddress'), isNotNull);
      expect(CRMValidators.email('@missingusername.com'), isNotNull);
      expect(CRMValidators.email('user@.com'), isNotNull);
      expect(CRMValidators.email('user@com'), isNotNull);
      expect(CRMValidators.email('<script>alert(1)</script>@evil.com'), isNotNull);
      expect(CRMValidators.email('test@example.com\nBcc: evil@test.com'), isNotNull);
    });

    test('Indian mobile validator enforces 10-digit format', () {
      expect(CRMValidators.indianMobile('9876543210'), isNull);
      expect(CRMValidators.indianMobile('8123456789'), isNull);
      expect(CRMValidators.indianMobile('7000000000'), isNull);
      expect(CRMValidators.indianMobile('6300000000'), isNull);

      // Rejections
      expect(CRMValidators.indianMobile('987654321'), isNotNull);  // 9 digits
      expect(CRMValidators.indianMobile('98765432101'), isNotNull); // 11 digits
      expect(CRMValidators.indianMobile('98765abcde'), isNotNull); // alpha characters
      expect(CRMValidators.indianMobile('98765 43210'), isNotNull); // spaces
      expect(CRMValidators.indianMobile('phone; DROP TABLE users;'), isNotNull);
    });

    test('Numeric validator rejects non-digits and negative signs/symbols if restricted', () {
      expect(CRMValidators.numeric('1234567890'), isNull);
      expect(CRMValidators.numeric('12a34'), isNotNull);
      expect(CRMValidators.numeric('123; DROP TABLE users;'), isNotNull);
    });

    test('Length validators strictly bound inputs', () {
      expect(CRMValidators.minLength('ab', 3), isNotNull);
      expect(CRMValidators.minLength('abc', 3), isNull);
      expect(CRMValidators.maxLength('abcd', 3), isNotNull);
      expect(CRMValidators.maxLength('abc', 3), isNull);
    });
  });
}

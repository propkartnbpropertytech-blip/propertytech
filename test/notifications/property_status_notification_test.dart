import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/services/app_notifier_service.dart';

void main() {
  group('Property status push de-duplication', () {
    test('an id shown by a push is remembered so the panel poll skips it', () {
      expect(AppNotifierService.wasOsShown('status-1'), isFalse);
      AppNotifierService.markOsShown('status-1');
      expect(AppNotifierService.wasOsShown('status-1'), isTrue);
      expect(AppNotifierService.wasOsShown('status-2'), isFalse);
    });

    test('empty or missing ids are never treated as shown', () {
      AppNotifierService.markOsShown('');
      AppNotifierService.markOsShown(null);
      expect(AppNotifierService.wasOsShown(''), isFalse);
      expect(AppNotifierService.wasOsShown(null), isFalse);
    });
  });
}

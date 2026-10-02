import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/design_system/mobile/mobile_layout.dart';

import 'mobile_test_utils.dart';

void main() {
  group('MobileLayout breakpoints', () {
    test('mobile shell is strictly below 768', () {
      expect(MobileLayout.isMobileShell(767), isTrue);
      expect(MobileLayout.isMobileShell(767.9), isTrue);
      expect(MobileLayout.isMobileShell(768), isFalse);
    });

    test('width bands follow 360 / 480 / 768', () {
      expect(MobileLayout.widthClassFor(320), MobileWidthClass.compact);
      expect(MobileLayout.widthClassFor(359), MobileWidthClass.compact);
      expect(MobileLayout.widthClassFor(360), MobileWidthClass.phone);
      expect(MobileLayout.widthClassFor(479), MobileWidthClass.phone);
      expect(MobileLayout.widthClassFor(480), MobileWidthClass.phablet);
      expect(MobileLayout.widthClassFor(767), MobileWidthClass.phablet);
      expect(MobileLayout.widthClassFor(768), MobileWidthClass.shell);
    });

    test('horizontal padding is 12 below 360, otherwise 16', () {
      expect(MobileLayout.horizontalPaddingFor(320), 12);
      expect(MobileLayout.horizontalPaddingFor(360), 16);
      expect(MobileLayout.horizontalPaddingFor(767), 16);
    });
  });

  group('MobileShellSwitch renders exactly one shell', () {
    for (final width in kStep30Widths) {
      testMobile('width $width', (tester) async {
        await setSurface(tester, width);
        await tester.pumpWidget(
          MaterialApp(
            home: MobileShellSwitch(
              enabled: true,
              mobileBuilder: (_) => const Text('mobile-shell'),
              existingBuilder: (_) => const Text('existing-shell'),
            ),
          ),
        );
        final mobile = find.text('mobile-shell').evaluate().length;
        final existing = find.text('existing-shell').evaluate().length;
        expect(mobile + existing, 1, reason: 'never both, never neither');
        expect(mobile == 1, width < 768);
      });
    }

    testMobile('disabled flag always uses the existing shell', (tester) async {
      await setSurface(tester, 390);
      await tester.pumpWidget(
        MaterialApp(
          home: MobileShellSwitch(
            enabled: false,
            mobileBuilder: (_) => const Text('mobile-shell'),
            existingBuilder: (_) => const Text('existing-shell'),
          ),
        ),
      );
      expect(find.text('existing-shell'), findsOneWidget);
      expect(find.text('mobile-shell'), findsNothing);
    });
  });

  group('MobileContent', () {
    for (final width in kStep30Widths.where((w) => w < 768)) {
      testMobile('caps content at 560 and does not overflow at $width',
          (tester) async {
        await setSurface(tester, width);
        await tester.pumpWidget(
          wrap(
            const MobileContent(
              child: SizedBox(
                key: Key('content'),
                width: double.infinity,
                height: 40,
              ),
            ),
          ),
        );
        final size = tester.getSize(find.byKey(const Key('content')));
        expect(size.width, lessThanOrEqualTo(MobileLayout.contentMaxWidth));
        expect(tester.takeException(), isNull);
      });
    }
  });
}

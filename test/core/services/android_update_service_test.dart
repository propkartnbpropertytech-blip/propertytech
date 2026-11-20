import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/services/android_update_service.dart';
import 'package:propkart/modules/version/presentation/update_dialogs.dart';

void main() {
  group('AndroidUpdateService Invariants', () {
    test('1. Detects newer semantic versions correctly', () {
      // Patch bump
      expect(AndroidUpdateService.isNewerVersion('1.1.5', '1.1.4'), isTrue);
      // Minor bump
      expect(AndroidUpdateService.isNewerVersion('1.2.0', '1.1.4'), isTrue);
      // Major bump
      expect(AndroidUpdateService.isNewerVersion('2.0.0', '1.1.4'), isTrue);
      // Leading 'v' prefix
      expect(AndroidUpdateService.isNewerVersion('v1.1.5', '1.1.4'), isTrue);
      expect(AndroidUpdateService.isNewerVersion('1.1.5', 'v1.1.4'), isTrue);
    });

    test('2. Does not detect update when user has latest or newer version', () {
      // Exact same version installed
      expect(AndroidUpdateService.isNewerVersion('1.1.4', '1.1.4'), isFalse);
      // Older remote version
      expect(AndroidUpdateService.isNewerVersion('1.1.3', '1.1.4'), isFalse);
      expect(AndroidUpdateService.isNewerVersion('1.0.0', '1.1.4'), isFalse);
    });

    test('3. Compares build numbers when semver matches', () {
      // Build 7 > Build 6
      expect(AndroidUpdateService.isNewerVersion('1.1.4+7', '1.1.4+6'), isTrue);
      // Build 6 == Build 6
      expect(AndroidUpdateService.isNewerVersion('1.1.4+6', '1.1.4+6'), isFalse);
      // Build 5 < Build 6
      expect(AndroidUpdateService.isNewerVersion('1.1.4+5', '1.1.4+6'), isFalse);
    });

    test('4. Google Play Store target constants are verified', () {
      expect(
        AndroidUpdateService.playStoreUrl,
        equals('https://play.google.com/store/apps/details?id=com.nbpropertytech.propkart'),
      );
      expect(
        AndroidUpdateService.playStoreMarketUri,
        equals('market://details?id=com.nbpropertytech.propkart'),
      );
    });
  });

  group('UpdateDialog Widget Tests', () {
    testWidgets('5. Renders Cancel and Update Now options and handles dismiss', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => UpdateDialog(
                      isForceUpdate: false,
                      androidLink: AndroidUpdateService.playStoreUrl,
                      iosLink: 'comingsoon',
                      newVersion: '1.1.5',
                      onDismiss: () {
                        dismissed = true;
                        Navigator.of(context).pop();
                      },
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open the dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Verify header and buttons
      expect(find.text('New Update Available'), findsOneWidget);
      expect(find.text('v1.1.5 on Google Play'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Update Now'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
      expect(find.text('New Update Available'), findsNothing);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:propkart/main.dart';
import 'package:propkart/features/auth/repository/auth_repository.dart';
import 'package:propkart/core/services/app_notifier_service.dart';
import 'package:propkart/core/telemetry/audit_telemetry_service.dart';

class MockAuthRepository extends AuthRepository {
  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<String?> getSavedToken() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'PropKart',
      packageName: 'com.propkart.app',
      version: '1.1.5',
      buildNumber: '7',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') return null;
        if (methodCall.method == 'write') return null;
        if (methodCall.method == 'delete') return null;
        if (methodCall.method == 'deleteAll') return null;
        return null;
      },
    );
  });

  tearDown(() async {
    AppNotifierService.dismissToast();
    AuditTelemetryService.instance.dispose();
  });

  testWidgets('Login screen loads correctly test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    final authRepository = MockAuthRepository();
    await tester.pumpWidget(MyApp(authRepository: authRepository));
    
    // Wait for the BLoC status check and config initialization to settle
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Tap "Get Started" on splash screen to navigate to Login Screen
    print("ALL TEXT IN TEST WIDGET TREE:");
    for (final element in find.byType(Text).evaluate()) {
      final widget = element.widget as Text;
      print("Text Widget: '${widget.data}'");
    }

    await tester.tap(find.text('Get Started'));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Verify that our app title is shown.
    expect(find.text('Go ahead to your account'), findsOneWidget);

    // Verify that the form elements exist on the screen.
    expect(find.text('Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Remember me'), findsOneWidget);

    AppNotifierService.dismissToast();
    AuditTelemetryService.instance.dispose();
    await tester.pump(const Duration(milliseconds: 200));
  });
}

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void setupMockSecurityStorage() {
  SharedPreferences.setMockInitialValues({});

  final storageData = <String, String>{};
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'write') {
        final args = methodCall.arguments as Map;
        storageData[args['key'] as String] = args['value'] as String;
        return null;
      } else if (methodCall.method == 'read') {
        final args = methodCall.arguments as Map;
        return storageData[args['key'] as String];
      } else if (methodCall.method == 'delete') {
        final args = methodCall.arguments as Map;
        storageData.remove(args['key'] as String);
        return null;
      } else if (methodCall.method == 'deleteAll') {
        storageData.clear();
        return null;
      }
      return null;
    },
  );
}

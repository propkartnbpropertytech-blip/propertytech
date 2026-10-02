import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widths required by Step 3.0 verification.
const kStep30Widths = <double>[
  320, 360, 390, 412, 430, 480, 600, 700, 767, 768, 800, 1024, 1280,
];

/// iOS variant keeps `CRMTypography` on system fonts (no GoogleFonts fetch).
final kMobileVariant = TargetPlatformVariant.only(TargetPlatform.iOS);

void testMobile(String description, WidgetTesterCallback body) {
  testWidgets(description, body, variant: kMobileVariant);
}

Future<void> setSurface(WidgetTester tester, double width,
    {double height = 800}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(width, height);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

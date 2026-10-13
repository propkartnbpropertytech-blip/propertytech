import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:propkart/get_started_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('GetStartedScreen renders designer UI elements cleanly',
      (WidgetTester tester) async {
    // Set screen size
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: GetStartedScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Brand "PropKart" in Navigation
    expect(find.text('PropKart'), findsOneWidget);

    // 2. Verify Hero Headline
    expect(
      find.text('Discover Properties That Feel Like Home.'),
      findsOneWidget,
    );

    // 3. Verify Description
    expect(
      find.text(
        'Explore premium properties, discover your perfect match, and make your next move with confidence.',
      ),
      findsOneWidget,
    );

    // 4. Verify Log In Button
    expect(find.text('Log In'), findsOneWidget);
  });
}

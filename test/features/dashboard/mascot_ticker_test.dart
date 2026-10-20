import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/dashboard/widgets/floating_mascot_chatbot_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestMascot({bool disableAnimations = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: const Scaffold(
          body: Stack(
            children: [
              Positioned(
                bottom: 24,
                right: 24,
                child: FloatingMascotChatbotButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('FloatingMascotChatbotButton Ticker & Idling Tests', () {
    testWidgets('initial animation starts on mount and auto-settles to idle after delay', (tester) async {
      await tester.pumpWidget(buildTestMascot());

      final state = tester.state<FloatingMascotChatbotButtonState>(
        find.byType(FloatingMascotChatbotButton),
      );

      // Initially active on mobile/desktop platform
      expect(state.isBobbingAnimating, isTrue);
      expect(state.isPulseAnimating, isTrue);
      expect(state.isIdled, isFalse);

      // Advance by 5 seconds (settling timer duration)
      await tester.pump(const Duration(milliseconds: 5000));
      // Pump settling transition
      await tester.pump(const Duration(milliseconds: 500));

      expect(state.isIdled, isTrue);
      expect(state.isBobbingAnimating, isFalse);
      expect(state.isPulseAnimating, isFalse);
    });

    testWidgets('interaction awakening starts animation and auto-settles again', (tester) async {
      await tester.pumpWidget(buildTestMascot());

      final state = tester.state<FloatingMascotChatbotButtonState>(
        find.byType(FloatingMascotChatbotButton),
      );

      // Force settle to idle
      state.triggerSettleForTesting();
      await tester.pump(const Duration(milliseconds: 500));
      expect(state.isIdled, isTrue);

      // Trigger user interaction wake up
      state.triggerWakeUpForTesting();
      expect(state.isIdled, isFalse);
      expect(state.isBobbingAnimating, isTrue);
      expect(state.isPulseAnimating, isTrue);

      // Advance by 4 seconds (interaction idle delay)
      await tester.pump(const Duration(milliseconds: 4000));
      await tester.pump(const Duration(milliseconds: 500));

      expect(state.isIdled, isTrue);
      expect(state.isBobbingAnimating, isFalse);
      expect(state.isPulseAnimating, isFalse);
    });

    testWidgets('lifecycle backgrounding pauses mascot tickers immediately', (tester) async {
      await tester.pumpWidget(buildTestMascot());

      final state = tester.state<FloatingMascotChatbotButtonState>(
        find.byType(FloatingMascotChatbotButton),
      );

      expect(state.isBobbingAnimating, isTrue);

      // Simulate app backgrounding
      state.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(milliseconds: 500));

      expect(state.isIdled, isTrue);
      expect(state.isBobbingAnimating, isFalse);
    });

    testWidgets('reduced motion (disableAnimations) disables animation ticks', (tester) async {
      await tester.pumpWidget(buildTestMascot(disableAnimations: true));

      final state = tester.state<FloatingMascotChatbotButtonState>(
        find.byType(FloatingMascotChatbotButton),
      );

      await tester.pump(const Duration(milliseconds: 500));
      expect(state.isIdled, isTrue);
      expect(state.isBobbingAnimating, isFalse);
      expect(state.isPulseAnimating, isFalse);
    });

    testWidgets('widget isolates animation repaints within a RepaintBoundary', (tester) async {
      await tester.pumpWidget(buildTestMascot());

      // Verify RepaintBoundary is present around the animated mascot
      final repaintBoundaries = find.descendant(
        of: find.byType(FloatingMascotChatbotButton),
        matching: find.byType(RepaintBoundary),
      );

      expect(repaintBoundaries, findsOneWidget);
    });

    testWidgets('disposing widget stops timers and controllers cleanly with 0 leaks', (tester) async {
      await tester.pumpWidget(buildTestMascot());

      final state = tester.state<FloatingMascotChatbotButtonState>(
        find.byType(FloatingMascotChatbotButton),
      );

      expect(state.mounted, isTrue);

      // Unmount
      await tester.pumpWidget(const SizedBox.shrink());

      // Verify no exceptions or leaking ticker errors
      expect(tester.takeException(), isNull);
    });
  });
}

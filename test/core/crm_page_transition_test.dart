import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/design_system/tokens/app_motion.dart';
import 'package:propkart/core/design_system/widgets/crm_page_transition.dart';
import 'package:propkart/core/design_system/widgets/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CRM Page Transition (crmFadeSlidePage) Optimization Tests', () {
    testWidgets('builds CustomTransitionPage with correct keys and child', (tester) async {
      const testKey = ValueKey('test_route_key');
      const childWidget = Text('Destination Content');

      final page = crmFadeSlidePage<void>(
        key: testKey,
        name: 'test_route',
        child: childWidget,
      );

      expect(page.key, testKey);
      expect(page.name, 'test_route');
      expect(page.child, childWidget);
    });

    testWidgets('transition durations are optimized (150ms forward / 100ms reverse)', (tester) async {
      final page = crmFadeSlidePage<void>(
        key: const ValueKey('duration_key'),
        child: const SizedBox(),
      );

      expect(page.transitionDuration, CRMMotion.fast);
      expect(page.transitionDuration, const Duration(milliseconds: 150));
      expect(page.reverseTransitionDuration, CRMMotion.press);
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 100));
    });

    testWidgets('transitionsBuilder produces single FadeTransition and NO Scale or Slide layers', (tester) async {
      final page = crmFadeSlidePage<void>(
        key: const ValueKey('render_test'),
        child: const Text('Target Page', key: Key('target_page')),
      );

      final animController = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 150),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                animController,
                kAlwaysDismissedAnimation,
                page.child,
              ),
            ),
          ),
        ),
      );

      // 1. Must contain single FadeTransition
      expect(find.byType(FadeTransition), findsOneWidget);

      // 2. Must NOT contain ScaleTransition (triple composite eliminated)
      expect(find.byType(ScaleTransition), findsNothing);

      // 3. Must NOT contain SlideTransition (triple composite eliminated)
      expect(find.byType(SlideTransition), findsNothing);

      // 4. Target child must be present
      expect(find.byKey(const Key('target_page')), findsOneWidget);

      animController.dispose();
    });

    testWidgets('respects Accessibility / Reduced Motion (bypasses transition)', (tester) async {
      final page = crmFadeSlidePage<void>(
        key: const ValueKey('reduced_motion'),
        child: const Text('Accessible Content', key: Key('accessible_content')),
      );

      final animController = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 150),
      );

      // Wrap in MediaQuery with disableAnimations = true
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                return page.transitionsBuilder(
                  context,
                  animController,
                  kAlwaysDismissedAnimation,
                  page.child,
                );
              },
            ),
          ),
        ),
      );

      // When reduced motion is requested, transition must NOT wrap in FadeTransition
      expect(find.byType(FadeTransition), findsNothing);
      expect(find.byType(ScaleTransition), findsNothing);
      expect(find.byType(SlideTransition), findsNothing);

      // Child is returned directly
      expect(find.byKey(const Key('accessible_content')), findsOneWidget);

      animController.dispose();
    });

    testWidgets('animates opacity cleanly from 0.0 to 1.0 along easeOut curve', (tester) async {
      final page = crmFadeSlidePage<void>(
        key: const ValueKey('opacity_curve'),
        child: const Text('Fading Page'),
      );

      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 150),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                controller,
                kAlwaysDismissedAnimation,
                page.child,
              ),
            ),
          ),
        ),
      );

      // Frame 0: value 0.0 -> opacity 0.0
      FadeTransition fadeWidget = tester.widget(find.byType(FadeTransition));
      expect(fadeWidget.opacity.value, 0.0);

      // Mid-point at 75ms
      controller.value = 0.5;
      await tester.pump();
      fadeWidget = tester.widget(find.byType(FadeTransition));
      expect(fadeWidget.opacity.value, closeTo(CRMMotion.easeOut.transform(0.5), 0.01));

      // Settle at 150ms
      controller.value = 1.0;
      await tester.pump();
      fadeWidget = tester.widget(find.byType(FadeTransition));
      expect(fadeWidget.opacity.value, 1.0);

      controller.dispose();
    });

    testWidgets('destination page widget is passed directly and not rebuilt per tick', (tester) async {
      int buildCount = 0;
      final child = StatefulBuilder(
        builder: (context, setState) {
          buildCount++;
          return const Text('Stable Page');
        },
      );

      final page = crmFadeSlidePage<void>(
        key: const ValueKey('stable_child'),
        child: child,
      );

      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 150),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Builder(
              builder: (context) => page.transitionsBuilder(
                context,
                controller,
                kAlwaysDismissedAnimation,
                page.child,
              ),
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      // Advance animation multiple ticks
      controller.value = 0.25;
      await tester.pump();
      controller.value = 0.5;
      await tester.pump();
      controller.value = 0.75;
      await tester.pump();
      controller.value = 1.0;
      await tester.pump();

      // Child should NOT have rebuilt on animation controller value updates
      expect(buildCount, 1, reason: 'Destination page must remain stable across transition ticks');

      controller.dispose();
    });

    test('CRMAppShell does not mix in TickerProvider or retain dead _entryController', () {
      final shell = const CRMAppShell(child: SizedBox());
      final state = shell.createState();
      expect(state is TickerProvider, isFalse, reason: 'CRMAppShell must not implement TickerProvider since entryController was eliminated');
    });
  });
}

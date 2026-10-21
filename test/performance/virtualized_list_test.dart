import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Rendering Strategy Invariants (Step 7)', () {
    testWidgets('Bounded viewport rendering strategy does not instantiate all items for large datasets', (tester) async {
      final builtItemIndices = <int>{};

      Widget buildItem(int index) {
        builtItemIndices.add(index);
        return SizedBox(
          key: ValueKey('item_$index'),
          height: 120,
          child: Text('Card item #$index'),
        );
      }

      // Render a large dataset of 500 items inside a standard viewport using CustomScrollView/SliverList
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => buildItem(index),
                        childCount: 500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      // Verify invariant: out of 500 items, only a bounded subset within/near the viewport are instantiated
      expect(builtItemIndices.length, lessThan(20),
          reason: 'A virtualized rendering strategy must bound active rendered items (< 20 for initial frame of 500 items)');
      expect(builtItemIndices.contains(0), isTrue);
      expect(builtItemIndices.contains(499), isFalse,
          reason: 'Far off-screen items must not be instantiated on initial render');
    });

    testWidgets('Un-virtualized Column violates bounded rendering invariant by instantiating all items', (tester) async {
      final builtIndices = <int>{};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: List.generate(500, (index) {
                  builtIndices.add(index);
                  return SizedBox(
                    key: ValueKey('unbounded_$index'),
                    height: 120,
                    child: Text('Card $index'),
                  );
                }),
              ),
            ),
          ),
        ),
      );

      // All 500 items are forcibly instantiated in Column
      expect(builtIndices.length, equals(500));
      expect(find.byType(SizedBox), findsNWidgets(500));
    });

    testWidgets('Scrolling dynamically inflates new items while preserving bounded active count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => SizedBox(
                      key: ValueKey('scroll_item_$index'),
                      height: 100,
                      child: Text('Item $index'),
                    ),
                    childCount: 200,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('scroll_item_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('scroll_item_50')), findsNothing);

      // Scroll down by 5000 pixels
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -5000));
      await tester.pumpAndSettle();

      // Top item #0 has been culled from the viewport
      expect(find.byKey(const ValueKey('scroll_item_0')), findsNothing);
      // Downstream item is now visible
      expect(find.byKey(const ValueKey('scroll_item_50')), findsOneWidget);
    });
  });
}

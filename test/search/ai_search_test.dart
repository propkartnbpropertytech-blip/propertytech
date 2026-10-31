import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/search/ai_search_session.dart';
import 'package:propkart/features/search/widgets/ai_search_field.dart';
import 'package:propkart/features/search/widgets/ai_search_panel.dart';
import 'package:propkart/features/shell/widgets/top_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a later search wins and a failed search keeps the saved rows', () {
    fakeAsync((async) {
      final session = AiSearchSession(delay: const Duration(milliseconds: 700));
      final seen = <String>[];
      session.schedule('old query', (generation, text) {
        if (session.isCurrent(generation)) seen.add(text);
      });
      async.elapse(const Duration(milliseconds: 400));
      session.schedule('2 BHK rentals in Satellite', (generation, text) {
        if (session.isCurrent(generation)) seen.add(text);
      });
      async.elapse(const Duration(milliseconds: 699));
      expect(seen, isEmpty);
      async.elapse(const Duration(milliseconds: 1));
      expect(seen, ['2 BHK rentals in Satellite']);
      session.dispose();
    });

    final memory = AiSearchMemory();
    memory.remember({
      'properties': [
        {'id': 'p1', 'title': 'Satellite home'},
      ],
    });
    final cached = memory.fail();
    expect(memory.stale, isTrue);
    expect(cached?['properties'], hasLength(1));
    expect((cached?['properties'] as List).first['title'], 'Satellite home');
  });

  testWidgets('the compact AI Search button opens the panel', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = TextEditingController();
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: ModernTopBar(
              onToggleSidebar: () {},
              searchController: controller,
              onSearchOpened: () => opened = true,
            ),
          ),
        ),
      ),
    );
    expect(find.byTooltip('AI Search'), findsOneWidget);
    expect(find.text('AI Search'), findsNothing);
    await tester.tap(find.byTooltip('AI Search'));
    await tester.pump();
    expect(opened, isTrue);
    expect(find.text(AiSearchField.placeholder), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AiSearchPanel(query: ''),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('ai-search-close')), findsOneWidget);
    expect(find.text('2 BHK rentals in Satellite under ₹35,000'), findsOneWidget);
    expect(find.text('My leads with overdue follow-ups'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('a wide layout shows the AI Search label and distinct result states', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1100,
            child: ModernTopBar(
              onToggleSidebar: () {},
              searchController: TextEditingController(),
            ),
          ),
        ),
      ),
    );
    expect(find.text('AI Search'), findsOneWidget);
    expect(find.text(AiSearchField.placeholder), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AiSearchPanel(
            query: '2 BHK rentals in Satellite',
            chips: const [AiSearchChipData('bedrooms', '2 BHK'), AiSearchChipData('area', 'Satellite')],
            groups: [
              AiSearchGroupData(
                title: 'Properties',
                category: 'properties',
                total: 3,
                rows: [
                  AiSearchRowData(title: 'Sunrise', subtitle: 'Code: PK1', onTap: () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('2 BHK'), findsOneWidget);
    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('View more properties'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AiSearchPanel(query: 'missing', failed: true, offline: true))));
    expect(find.textContaining('offline'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AiSearchPanel(query: 'missing', failed: true))));
    expect(find.text('Search could not finish. Try again.'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AiSearchPanel(query: 'missing'))));
    expect(find.text('No matches for this search.'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AiSearchPanel(query: 'gota', loading: true))));
    expect(find.text('Searching…'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AiSearchPanel(query: 'gota', stale: true, groups: [
      AiSearchGroupData(title: 'Properties', category: 'properties', total: 1, rows: [
        AiSearchRowData(title: 'Saved home', subtitle: 'Code: PK2', onTap: _noop),
      ]),
    ]))));
    expect(find.textContaining('last saved results'), findsOneWidget);
    expect(find.text('Saved home'), findsOneWidget);
  });
}

void _noop() {}

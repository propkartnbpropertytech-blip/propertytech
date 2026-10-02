import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:propkart/core/design_system/mobile/mobile.dart';
import 'package:propkart/core/design_system/tokens/app_spacing.dart';
import 'package:propkart/features/shell/mobile/mobile_app_shell.dart';

import 'mobile_test_utils.dart';

bool _all(String _) => true;

const double _h = 800;
const double _safe = 34;

/// Shell clearance used by `CRMBreakpoints.mobileNavClearance` for [_safe].
const double _clearance = 76 + _safe;

const _widths = <double>[320, 360, 390, 412, 430, 480, 600, 767, 768];

void _systemInsets(WidgetTester tester, {double keyboard = 0}) {
  tester.view.padding = const FakeViewPadding(bottom: _safe);
  tester.view.viewPadding = const FakeViewPadding(bottom: _safe);
  if (keyboard > 0) {
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  }
  addTearDown(tester.view.resetPadding);
  addTearDown(tester.view.resetViewPadding);
  addTearDown(tester.view.resetViewInsets);
}

Widget _inShell(
  Widget child, {
  String role = 'Sales',
  String location = '/library',
}) {
  return MaterialApp(
    home: MobileAppShell(
      role: role,
      location: location,
      canView: _all,
      onNavigate: (_) {},
      onBack: (_) {},
      onSearch: () {},
      onNotifications: () {},
      onQuickActions: () {},
      onMessages: () {},
      child: child,
    ),
  );
}

Widget _outsideShell(Widget child) => MaterialApp(home: child);

const _probe = Key('probe');
const _fill = SizedBox.expand(key: _probe);

double _bottomOf(WidgetTester tester, Finder f) => tester.getRect(f).bottom;

MobileStickyActionBar _sticky({bool loading = false, bool enabled = true}) =>
    MobileStickyActionBar(
      secondary: const MobileAction(label: 'Back', onPressed: _noop),
      primary: MobileAction(
        label: 'Save',
        onPressed: _noop,
        loading: loading,
        enabled: enabled,
      ),
    );

void _noop() {}

void main() {
  group('K1 bottom clearance', () {
    testMobile('shell content MediaQuery has no bottom padding', (
      tester,
    ) async {
      await setSurface(tester, 390, height: _h);
      _systemInsets(tester);
      late MediaQueryData seen;
      late bool inShell;
      await tester.pumpWidget(
        _inShell(
          Builder(
            builder: (context) {
              seen = MediaQuery.of(context);
              inShell = MobileShellScope.isInShell(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(inShell, isTrue);
      expect(seen.padding.bottom, 0);
      expect(seen.viewPadding.bottom, 0);
    });

    testMobile('inside shell: MobileContent adds no second nav clearance', (
      tester,
    ) async {
      await setSurface(tester, 390, height: _h);
      _systemInsets(tester);
      await tester.pumpWidget(
        _inShell(
          const MobileContent(scrollable: false, centered: false, child: _fill),
        ),
      );
      expect(
        _bottomOf(tester, find.byKey(_probe)),
        _h - _clearance - CRMSpacing.m,
      );
    });

    testMobile('inside shell: a legacy SafeArea(bottom) adds nothing extra', (
      tester,
    ) async {
      await setSurface(tester, 390, height: _h);
      _systemInsets(tester);
      await tester.pumpWidget(
        _inShell(const SafeArea(top: false, child: _fill)),
      );
      expect(_bottomOf(tester, find.byKey(_probe)), _h - _clearance);
    });

    testMobile('outside shell: MobileContent applies the bottom safe area', (
      tester,
    ) async {
      await setSurface(tester, 390, height: _h);
      _systemInsets(tester);
      await tester.pumpWidget(
        _outsideShell(
          const Scaffold(
            body: MobileContent(
              scrollable: false,
              centered: false,
              child: _fill,
            ),
          ),
        ),
      );
      expect(_bottomOf(tester, find.byKey(_probe)), _h - _safe - CRMSpacing.m);
    });

    testMobile('outside shell: MobileList applies the bottom safe area', (
      tester,
    ) async {
      await setSurface(tester, 390, height: _h);
      _systemInsets(tester);
      await tester.pumpWidget(
        _outsideShell(
          Scaffold(
            body: MobileList<int>(
              items: const [1],
              keyOf: (i) => i,
              itemBuilder: (_, _) => const SizedBox(height: 40),
            ),
          ),
        ),
      );
      final list = tester.widget<ListView>(find.byType(ListView));
      expect((list.padding! as EdgeInsets).bottom, CRMSpacing.m + _safe);
    });

    testMobile('inside shell: MobileList adds no bottom safe area', (
      tester,
    ) async {
      await setSurface(tester, 390, height: _h);
      _systemInsets(tester);
      await tester.pumpWidget(
        _inShell(
          MobileList<int>(
            items: const [1],
            keyOf: (i) => i,
            itemBuilder: (_, _) => const SizedBox(height: 40),
          ),
        ),
      );
      final list = tester.widget<ListView>(find.byType(ListView));
      expect((list.padding! as EdgeInsets).bottom, CRMSpacing.m);
    });

    testMobile(
      'inside shell: sticky action sits above the nav, no extra inset',
      (tester) async {
        await setSurface(tester, 390, height: _h);
        _systemInsets(tester);
        await tester.pumpWidget(
          _inShell(
            MobileScreenScaffold(
              body: const Text('body'),
              bottomAction: _sticky(),
            ),
          ),
        );
        final save = find.widgetWithText(FilledButton, 'Save');
        expect(_bottomOf(tester, save), _h - _clearance - CRMSpacing.s);
      },
    );

    testMobile('outside shell: sticky action owns the safe area once', (
      tester,
    ) async {
      await setSurface(tester, 390, height: _h);
      _systemInsets(tester);
      await tester.pumpWidget(
        _outsideShell(
          MobileScreenScaffold(
            title: 'Edit',
            scrollable: false,
            body: const MobileContent(
              scrollable: false,
              centered: false,
              child: _fill,
            ),
            bottomAction: _sticky(),
          ),
        ),
      );
      final save = find.widgetWithText(FilledButton, 'Save');
      expect(_bottomOf(tester, save), _h - _safe - CRMSpacing.s);
      // Body does not add the safe area a second time above the bar.
      final barTop = tester.getRect(find.byType(MobileStickyActionBar)).top;
      expect(_bottomOf(tester, find.byKey(_probe)), barTop - CRMSpacing.m);
    });

    testMobile(
      'keyboard open in shell: nav hidden, sticky action above keyboard',
      (tester) async {
        await setSurface(tester, 390, height: _h);
        _systemInsets(tester, keyboard: 300);
        await tester.pumpWidget(
          _inShell(
            MobileScreenScaffold(
              body: const TextField(),
              bottomAction: _sticky(),
            ),
          ),
        );
        expect(find.byType(MobileBottomNav), findsNothing);
        final save = find.widgetWithText(FilledButton, 'Save');
        expect(_bottomOf(tester, save), _h - 300 - CRMSpacing.s);
      },
    );
  });

  group('Shell separation', () {
    testMobile('in shell the scaffold draws no top bar or nav of its own', (
      tester,
    ) async {
      await setSurface(tester, 390);
      await tester.pumpWidget(
        _inShell(
          const MobileScreenScaffold(title: 'Detail', body: Text('body')),
        ),
      );
      expect(find.byType(MobileTopBar), findsOneWidget);
      expect(find.byType(MobileBottomNav), findsOneWidget);
      expect(find.byType(MobileShellScope), findsOneWidget);
    });

    testMobile('outside the shell the scaffold draws its own top bar + Back', (
      tester,
    ) async {
      await setSurface(tester, 390);
      await tester.pumpWidget(
        _outsideShell(
          const MobileScreenScaffold(
            title: 'Sync diagnostics',
            body: Text('body'),
          ),
        ),
      );
      expect(find.byType(MobileTopBar), findsOneWidget);
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(find.byType(MobileBottomNav), findsNothing);
      expect(find.text('Sync diagnostics'), findsOneWidget);
    });

    testMobile('>=768 never builds the mobile shell', (tester) async {
      for (final w in [768.0, 1024.0, 1280.0]) {
        await setSurface(tester, w);
        await tester.pumpWidget(
          MaterialApp(
            home: MobileShellSwitch(
              enabled: true,
              mobileBuilder: (_) => const Text('mobile'),
              existingBuilder: (_) => const Text('existing'),
            ),
          ),
        );
        expect(find.text('existing'), findsOneWidget, reason: '$w');
        expect(find.text('mobile'), findsNothing, reason: '$w');
      }
    });
  });

  group('Title contract', () {
    test('controller: latest claim wins, stale release is ignored', () {
      final c = MobileTitleController();
      final a = Object();
      final b = Object();
      c.claim(a, 'A');
      c.claim(b, 'B');
      c.release(a);
      expect(c.title, 'B');
      c.release(b);
      expect(c.title, isNull);
      c.dispose();
    });

    testMobile('screen title overrides the shell title while mounted', (
      tester,
    ) async {
      await setSurface(tester, 390);
      await tester.pumpWidget(
        _inShell(
          const MobileScreenScaffold(
            title: 'Lead · Ravi',
            body: Text('detail'),
          ),
          location: '/requirements/abc',
        ),
      );
      await tester.pump();
      final topTitle = find.descendant(
        of: find.byType(MobileTopBar),
        matching: find.text('Lead · Ravi'),
      );
      expect(topTitle, findsOneWidget);

      await tester.pumpWidget(
        _inShell(const Text('list'), location: '/requirements/abc'),
      );
      await tester.pump();
      expect(topTitle, findsNothing);
      expect(
        find.descendant(
          of: find.byType(MobileTopBar),
          matching: find.text('Leads'),
        ),
        findsOneWidget,
      );
    });

    testMobile('without a screen title the shell uses resolve()', (
      tester,
    ) async {
      await setSurface(tester, 390);
      await tester.pumpWidget(
        _inShell(const MobileScreenScaffold(body: Text('x'))),
      );
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(MobileTopBar),
          matching: find.text('Library'),
        ),
        findsOneWidget,
      );
    });
  });

  group('Back contract', () {
    testMobile('pops a pushed route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MobileScreenScaffold(
                    title: 'Pushed',
                    body: Text('pushed body'),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('pushed body'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('pushed body'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testMobile('falls back through GoRouter when nothing can pop', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/detail',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const Scaffold(body: Text('home page')),
          ),
          GoRoute(
            path: '/detail',
            builder: (_, _) => const MobileScreenScaffold(
              title: 'Detail',
              body: Text('detail page'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('home page'), findsOneWidget);
    });
  });

  group('Loading / empty / error', () {
    testMobile('all four loading modes render with semantics', (tester) async {
      for (final mode in MobileLoadingMode.values) {
        await tester.pumpWidget(
          wrap(SingleChildScrollView(child: MobileLoadingState(mode: mode))),
        );
        expect(tester.takeException(), isNull, reason: '$mode');
      }
      await tester.pumpWidget(wrap(const MobileButtonLoader()));
      expect(find.byType(MobileButtonLoader), findsOneWidget);
    });

    testMobile('empty state uses caller copy and both actions', (tester) async {
      var primary = 0;
      var secondary = 0;
      await tester.pumpWidget(
        wrap(
          MobileEmptyState(
            icon: Icons.inbox_outlined,
            title: 'Caller title',
            description: 'Caller description',
            actionLabel: 'Primary',
            onAction: () => primary++,
            secondaryActionLabel: 'Secondary',
            onSecondaryAction: () => secondary++,
          ),
        ),
      );
      expect(find.text('Caller title'), findsOneWidget);
      await tester.tap(find.text('Primary'));
      await tester.tap(find.text('Secondary'));
      expect((primary, secondary), (1, 1));
    });

    testMobile('error state retries and shows only friendly copy', (
      tester,
    ) async {
      var retries = 0;
      MobileErrorState.logTechnical(
        StateError('Bad state: secret stack detail'),
        StackTrace.current,
      );
      await tester.pumpWidget(wrap(MobileErrorState(onRetry: () => retries++)));
      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.textContaining('Bad state'), findsNothing);
      expect(find.textContaining('Exception'), findsNothing);
      await tester.tap(find.text('Retry'));
      expect(retries, 1);
    });

    test('foundation never renders raw exceptions', () {
      final dir = Directory('lib/core/design_system/mobile');
      for (final f in dir.listSync().whereType<File>()) {
        final src = f.readAsStringSync();
        expect(src, isNot(contains('e.toString()')), reason: f.path);
        expect(src, isNot(contains(r"'$e'")), reason: f.path);
        expect(src, isNot(contains(r'${e}')), reason: f.path);
      }
    });
  });

  group('Offline (DR-021)', () {
    testMobile('every status has a label and is announced', (tester) async {
      final handle = tester.ensureSemantics();
      for (final s in MobileDataStatus.values) {
        await tester.pumpWidget(wrap(MobileSyncIndicator(status: s)));
        final label = MobileDataStatusCopy.label(s);
        expect(find.bySemanticsLabel(label), findsOneWidget, reason: '$s');
      }
      handle.dispose();
    });

    test('direct-server writes are never "Waiting to sync"', () {
      for (final inProgress in [true, false]) {
        for (final failed in [true, false]) {
          expect(
            MobileDataStatusRules.forWrite(
              MobileWriteChannel.directServer,
              inProgress: inProgress,
              failed: failed,
            ),
            isNot(MobileDataStatus.pendingWrite),
          );
        }
      }
      expect(
        MobileDataStatusRules.forWrite(
          MobileWriteChannel.directServer,
          inProgress: true,
        ),
        MobileDataStatus.directOperation,
      );
      expect(
        MobileDataStatusRules.forWrite(
          MobileWriteChannel.outbox,
          inProgress: true,
        ),
        MobileDataStatus.pendingWrite,
      );
      expect(
        MobileDataStatusRules.forWrite(MobileWriteChannel.outbox, failed: true),
        MobileDataStatus.failedWrite,
      );
      expect(MobileDataStatusRules.forWrite(MobileWriteChannel.outbox), isNull);
    });

    testMobile('offline banner never claims there is no data', (tester) async {
      await tester.pumpWidget(wrap(const MobileOfflineBanner(hasCache: true)));
      expect(find.textContaining('No data'), findsNothing);
      expect(find.textContaining('Offline'), findsOneWidget);
    });
  });

  group('List contract', () {
    testMobile('builds lazily with stable keys', (tester) async {
      await setSurface(tester, 390);
      var built = 0;
      final items = List<int>.generate(10000, (i) => i);
      await tester.pumpWidget(
        wrap(
          MobileList<int>(
            items: items,
            keyOf: (i) => 'row-$i',
            itemBuilder: (_, i) {
              built++;
              return SizedBox(height: 64, child: Text('Row $i'));
            },
          ),
        ),
      );
      expect(built, lessThan(60));
      expect(find.byKey(const ValueKey<Object>('row-0')), findsOneWidget);
      expect(find.byKey(const ValueKey<Object>('row-9999')), findsNothing);
    });

    testMobile('load-more fires near the end and shows the footer', (
      tester,
    ) async {
      await setSurface(tester, 390);
      var loadMore = 0;
      final items = List<int>.generate(30, (i) => i);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      Widget list({required bool loadingMore}) => wrap(
        MobileList<int>(
          items: items,
          keyOf: (i) => i,
          controller: controller,
          hasMore: true,
          isLoadingMore: loadingMore,
          onLoadMore: () => loadMore++,
          itemBuilder: (_, i) => SizedBox(height: 64, child: Text('Row $i')),
        ),
      );

      await tester.pumpWidget(list(loadingMore: true));
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      expect(find.byType(MobileLoadingState), findsOneWidget);
      // While a load is in flight the hook is not called again.
      expect(loadMore, 0);

      await tester.pumpWidget(list(loadingMore: false));
      controller.jumpTo(0);
      await tester.pump();
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      expect(find.byType(MobileLoadingState), findsNothing);
      expect(loadMore, greaterThan(0));
    });

    testMobile('pull-to-refresh is wired', (tester) async {
      await tester.pumpWidget(
        wrap(
          MobileList<int>(
            items: const [1, 2],
            keyOf: (i) => i,
            onRefresh: () async {},
            itemBuilder: (_, i) => Text('Row $i'),
          ),
        ),
      );
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testMobile('card is generic: selection and tap', (tester) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          MobileCard(
            title: 'Title',
            subtitle: 'Subtitle',
            metadata: const ['A', 'B'],
            selected: true,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('Title'));
      expect(taps, 1);
      expect(
        tester.getSemantics(find.byType(MobileCard)),
        isSemantics(isSelected: true),
      );
      handle.dispose();
    });
  });

  group('Search contract', () {
    Widget search(
      MobileSearchStatus status, {
      ValueChanged<String>? onQuery,
      bool body = true,
    }) => wrap(
      MobileSearch(
        hintText: 'Search',
        autofocus: false,
        status: status,
        showResultsBody: body,
        onQueryChanged: onQuery ?? (_) {},
        onFilterTap: () {},
        activeFilterCount: 2,
        idleState: const Text('idle'),
        results: const Text('results'),
        onRetry: () {},
      ),
    );

    testMobile('state transitions', (tester) async {
      await tester.pumpWidget(search(MobileSearchStatus.idle));
      expect(find.text('idle'), findsOneWidget);
      await tester.pumpWidget(search(MobileSearchStatus.typing));
      expect(find.text('results'), findsOneWidget);
      await tester.pumpWidget(search(MobileSearchStatus.loading));
      expect(find.byType(MobileLoadingState), findsOneWidget);
      await tester.pumpWidget(search(MobileSearchStatus.results));
      expect(find.text('results'), findsOneWidget);
      await tester.pumpWidget(search(MobileSearchStatus.empty));
      expect(find.text('No matches'), findsOneWidget);
      await tester.pumpWidget(search(MobileSearchStatus.error));
      expect(find.byType(MobileErrorState), findsOneWidget);
    });

    testMobile('clear emits an empty query; filter shows its count', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final queries = <String>[];
      await tester.pumpWidget(
        search(MobileSearchStatus.results, onQuery: queries.add),
      );
      await tester.enterText(find.byType(TextField), 'pune');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Clear search'));
      await tester.pump();
      expect(queries, ['pune', '']);
      expect(find.bySemanticsLabel('Filters, 2 new'), findsOneWidget);
      handle.dispose();
    });

    testMobile('header-only mode renders just the field', (tester) async {
      await tester.pumpWidget(search(MobileSearchStatus.results, body: false));
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('results'), findsNothing);
    });
  });

  group('Filter and sort contracts', () {
    const sections = [
      MobileFilterSection(
        id: 'a',
        title: 'Caller section A',
        options: [
          MobileOption(value: 'x', label: 'X'),
          MobileOption(value: 'y', label: 'Y'),
        ],
      ),
    ];

    Widget opener(
      Future<Object?> Function(BuildContext) open,
      void Function(Object?) done,
    ) => MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => done(await open(context)),
            child: const Text('open'),
          ),
        ),
      ),
    );

    testMobile('filter: select, reset, apply', (tester) async {
      Object? result = 'unset';
      await tester.pumpWidget(
        opener(
          (c) => MobileFilterSheet.show(
            c,
            sections: sections,
            initialSelection: const {
              'a': {'y'},
            },
          ),
          (r) => result = r,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Caller section A'), findsOneWidget);
      await tester.tap(find.text('Reset'));
      await tester.pump();
      await tester.tap(find.text('X'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(result, {
        'a': {'x'},
      });
    });

    testMobile('sort: selection applies, reset returns default, dismiss null', (
      tester,
    ) async {
      const options = [
        MobileOption(value: 'newest', label: 'Newest'),
        MobileOption(value: 'oldest', label: 'Oldest'),
      ];
      Object? result = 'unset';
      Widget app() => opener(
        (c) => MobileSortSheet.show(
          c,
          options: options,
          selected: 'newest',
          resetValue: 'newest',
        ),
        (r) => result = r,
      );

      await tester.pumpWidget(app());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oldest'));
      await tester.pumpAndSettle();
      expect(result, 'oldest');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(result, 'newest');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });

  group('Sticky actions', () {
    testMobile('48px, loading announced and inert, disabled inert', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        wrap(
          Align(
            alignment: Alignment.bottomCenter,
            child: _sticky(loading: true),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Save, in progress'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(
        tester.getSize(find.byType(FilledButton)).height,
        greaterThanOrEqualTo(48),
      );

      await tester.pumpWidget(
        wrap(
          Align(
            alignment: Alignment.bottomCenter,
            child: _sticky(enabled: false),
          ),
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Save')),
        isSemantics(isEnabled: false, isButton: true),
      );
      handle.dispose();
    });
  });

  group('Widths, text scale and accessibility', () {
    Widget screen() => MobileScreenScaffold(
      title: 'Screen',
      scrollable: false,
      header: MobileSearch(
        hintText: 'Search records',
        autofocus: false,
        showResultsBody: false,
        onQueryChanged: (_) {},
        onFilterTap: () {},
      ),
      banner: const MobileOfflineBanner(hasCache: true, lastUpdated: '10:30'),
      body: MobileList<int>(
        items: List<int>.generate(20, (i) => i),
        keyOf: (i) => i,
        itemBuilder: (_, i) => MobileCard(
          title: 'Card title $i that is fairly long for small phones',
          subtitle: 'Subtitle',
          metadata: const ['Meta one', 'Meta two'],
          onTap: () {},
        ),
      ),
      bottomAction: _sticky(),
    );

    for (final w in _widths) {
      for (final scale in [1.0, 1.3]) {
        testMobile('screen contract @ $w, text x$scale', (tester) async {
          await setSurface(tester, w, height: _h);
          _systemInsets(tester);
          final child = MediaQuery.withClampedTextScaling(
            minScaleFactor: scale,
            maxScaleFactor: scale,
            child: screen(),
          );
          await tester.pumpWidget(
            w < 768 ? _inShell(child) : _outsideShell(child),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
          expect(
            find.byType(MobileBottomNav),
            w < 768 ? findsOneWidget : findsNothing,
          );
          expect(
            find.byType(MobileTopBar),
            findsOneWidget,
            reason: 'exactly one top bar',
          );

          // Sticky actions never overlap the list or the bottom nav.
          final barRect = tester.getRect(find.byType(MobileStickyActionBar));
          final listRect = tester.getRect(find.byType(ListView));
          expect(listRect.bottom, lessThanOrEqualTo(barRect.top));
          if (w < 768) {
            final navTop = tester.getRect(find.byType(MobileBottomNav)).top;
            expect(barRect.bottom, lessThanOrEqualTo(navTop));
          }
        });
      }
    }

    testMobile('scaffold chrome meets 48px and label guidelines', (
      tester,
    ) async {
      await setSurface(tester, 360);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _outsideShell(
          MobileScreenScaffold(
            title: 'Detail',
            header: MobileSearch(
              hintText: 'Search',
              autofocus: false,
              showResultsBody: false,
              onQueryChanged: (_) {},
              onFilterTap: () {},
            ),
            body: const Text('body'),
            bottomAction: _sticky(),
          ),
        ),
      );
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      expect(
        tester.getSemantics(find.text('Detail')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });
  });
}

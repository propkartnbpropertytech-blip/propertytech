import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/design_system/mobile/mobile.dart';
import 'package:propkart/features/shell/mobile/mobile_app_shell.dart';
import 'package:propkart/features/shell/mobile/mobile_nav_config.dart';
import 'package:propkart/features/shell/mobile/more_screen.dart';

import 'mobile_test_utils.dart';

bool _all(String _) => true;

MobileAppShell _shell({
  String role = 'Admin',
  String location = '/dashboard',
  Widget child = const SizedBox.shrink(),
}) =>
    MobileAppShell(
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
    );

void main() {
  group('MobileBottomNav', () {
    final tabs = MobileNavConfig.tabsForRole('Telecaller', canView: _all);

    testMobile('exposes selected state and 48px cells', (tester) async {
      await setSurface(tester, 360);
      final handle = tester.ensureSemantics();
      int? tapped;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MobileBottomNav(
              items: tabs,
              selectedIndex: 2,
              onSelected: (i) => tapped = i,
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Callbacks')),
        isSemantics(isSelected: true, isButton: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('My Calling')),
        isSemantics(isSelected: false, isButton: true),
      );

      for (final label in ['Home', 'My Calling', 'Callbacks', 'CNR', 'More']) {
        final size = tester.getSize(find.bySemanticsLabel(label));
        expect(size.width, greaterThanOrEqualTo(48), reason: label);
        expect(size.height, greaterThanOrEqualTo(48), reason: label);
      }

      await tester.tap(find.text('CNR'));
      expect(tapped, 3);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testMobile('fits five tabs without overflow at 320', (tester) async {
      await setSurface(tester, 320);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MobileBottomNav(
              items: MobileNavConfig.tabsForRole('Admin', canView: _all),
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Reports'), findsOneWidget);
    });

    testMobile('center slot is opt-in only', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MobileBottomNav(
              items: tabs,
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testMobile('announces badge counts', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: MobileBottomNav(
              items: [
                tabs[0],
                tabs[2].copyWith(badgeCount: 4),
              ],
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Callbacks, 4 new'), findsOneWidget);
      handle.dispose();
    });
  });

  group('MobileTopBar and touch targets', () {
    testMobile('title is a header and actions are 48x48', (tester) async {
      await setSurface(tester, 320);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: MobileTopBar(
              title: 'A very long page title that must truncate cleanly',
              roleControl: const SizedBox(width: 72, height: 32),
              actions: [
                MobileIconAction(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  badgeCount: 3,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final size =
          tester.getSize(find.bySemanticsLabel('Notifications, 3 new'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(
            find.text('A very long page title that must truncate cleanly')),
        isSemantics(isHeader: true),
      );
      handle.dispose();
    });
  });

  group('MobileAppShell', () {
    for (final width in [320.0, 360.0, 390.0, 412.0, 430.0, 480.0, 600.0, 700.0, 767.0]) {
      testMobile('renders without overflow at $width', (tester) async {
        await setSurface(tester, width);
        await tester.pumpWidget(
          MaterialApp(
            home: _shell(child: const MobileContent(child: Text('body'))),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.byType(MobileBottomNav), findsOneWidget);
        expect(find.byType(MobileShellScope), findsOneWidget);
      });
    }

    testMobile('hides bottom nav while the keyboard is open', (tester) async {
      await setSurface(tester, 390);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 800),
              viewInsets: EdgeInsets.only(bottom: 300),
            ),
            child: _shell(role: 'Sales'),
          ),
        ),
      );
      expect(find.byType(MobileBottomNav), findsNothing);
    });
  });

  group('States', () {
    testMobile('loading modes render', (tester) async {
      for (final mode in MobileLoadingMode.values) {
        await tester.pumpWidget(
          wrap(SingleChildScrollView(child: MobileLoadingState(mode: mode))),
        );
        expect(tester.takeException(), isNull, reason: '$mode');
      }
    });

    testMobile('empty state shows both actions', (tester) async {
      var primary = 0;
      var secondary = 0;
      await tester.pumpWidget(wrap(MobileEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No leads',
        description: 'Nothing assigned yet.',
        actionLabel: 'Refresh',
        onAction: () => primary++,
        secondaryActionLabel: 'Clear filters',
        onSecondaryAction: () => secondary++,
      )));
      await tester.tap(find.text('Refresh'));
      await tester.tap(find.text('Clear filters'));
      expect(primary, 1);
      expect(secondary, 1);
    });

    testMobile('error state never renders raw exception text',
        (tester) async {
      var retried = 0;
      try {
        throw const FormatException('DioException [bad response]: 500');
      } catch (e, st) {
        MobileErrorState.logTechnical(e, st);
      }
      await tester.pumpWidget(wrap(MobileErrorState(onRetry: () => retried++)));

      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.text('Please try again.'), findsOneWidget);
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('DioException'), findsNothing);
      expect(find.textContaining('#0'), findsNothing);
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });

    testMobile('retry state calls back', (tester) async {
      var retried = 0;
      await tester.pumpWidget(wrap(MobileRetryState(
        message: "Couldn't load callbacks.",
        onRetry: () => retried++,
      )));
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
    });
  });

  group('Offline presentation', () {
    test('copy for every data status', () {
      expect(MobileDataStatusCopy.label(MobileDataStatus.cachedRead,
          lastUpdated: '10:42'), 'Offline · last updated 10:42');
      expect(MobileDataStatusCopy.label(MobileDataStatus.syncing), 'Syncing');
      expect(MobileDataStatusCopy.label(MobileDataStatus.pendingWrite),
          'Waiting to sync');
      expect(MobileDataStatusCopy.label(MobileDataStatus.directOperation),
          'Saving…');
      expect(MobileDataStatusCopy.label(MobileDataStatus.failedWrite),
          "Couldn't save. Try again.");
    });

    testMobile('banner distinguishes cached vs no cache', (tester) async {
      await tester.pumpWidget(wrap(const MobileOfflineBanner(
          hasCache: true, lastUpdated: '10:42')));
      expect(find.text('Offline · last updated 10:42'), findsOneWidget);

      await tester.pumpWidget(wrap(const MobileOfflineBanner(hasCache: false)));
      expect(find.text("You're offline"), findsOneWidget);
    });

    testMobile('failed write offers retry; pending shows badge',
        (tester) async {
      var retried = 0;
      await tester.pumpWidget(wrap(Column(children: [
        MobileSyncIndicator(
          status: MobileDataStatus.failedWrite,
          onRetry: () => retried++,
        ),
        const MobilePendingSyncBadge(),
      ])));
      await tester.tap(find.text('Retry'));
      expect(retried, 1);
      expect(find.text('Waiting to sync'), findsOneWidget);
    });
  });

  group('Lists and cards', () {
    testMobile('MobileList builds lazily with stable keys', (tester) async {
      await setSurface(tester, 390, height: 600);
      final items = List.generate(500, (i) => 'id-$i');
      await tester.pumpWidget(wrap(MobileList<String>(
        items: items,
        keyOf: (s) => s,
        itemBuilder: (_, s) => SizedBox(height: 80, child: Text(s)),
      )));
      expect(find.text('id-0'), findsOneWidget);
      expect(find.text('id-499'), findsNothing);
      expect(find.byKey(const ValueKey<Object>('id-0')), findsOneWidget);
    });

    testMobile('MobileList fires onLoadMore near the end', (tester) async {
      await setSurface(tester, 390, height: 600);
      var loads = 0;
      await tester.pumpWidget(wrap(MobileList<int>(
        items: List.generate(30, (i) => i),
        keyOf: (i) => i,
        hasMore: true,
        onLoadMore: () => loads++,
        itemBuilder: (_, i) => SizedBox(height: 80, child: Text('$i')),
      )));
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pump();
      expect(loads, greaterThan(0));
    });

    testMobile('MobileList empty and error states', (tester) async {
      await tester.pumpWidget(wrap(MobileList<int>(
        items: const [],
        keyOf: (i) => i,
        itemBuilder: (_, i) => Text('$i'),
        emptyState: const MobileEmptyState(
            icon: Icons.inbox_outlined, title: 'Nothing here'),
      )));
      expect(find.text('Nothing here'), findsOneWidget);

      await tester.pumpWidget(wrap(MobileList<int>(
        items: const [],
        keyOf: (i) => i,
        hasError: true,
        onRetry: () {},
        itemBuilder: (_, i) => Text('$i'),
      )));
      expect(find.text('Something went wrong.'), findsOneWidget);
    });

    testMobile('MobileCard announces its content', (tester) async {
      await setSurface(tester, 320);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(wrap(MobileCard(
        title: 'Rahul Sharma',
        subtitle: '2 BHK · Andheri',
        metadata: const ['Budget 80L', 'Site visit'],
        onTap: () {},
      )));
      expect(
        find.bySemanticsLabel(
            'Rahul Sharma, 2 BHK · Andheri, Budget 80L · Site visit'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      handle.dispose();
    });
  });

  group('Search, sheets and dialogs', () {
    testMobile('search clears and reports filter count', (tester) async {
      final queries = <String>[];
      await tester.pumpWidget(wrap(MobileSearch(
        hintText: 'Search leads',
        onQueryChanged: queries.add,
        onFilterTap: () {},
        activeFilterCount: 2,
        autofocus: false,
      )));
      await tester.enterText(find.byType(TextField), 'rahul');
      await tester.pump();
      expect(queries.last, 'rahul');
      await tester.tap(find.bySemanticsLabel('Clear search'));
      await tester.pump();
      expect(queries.last, '');
      expect(find.bySemanticsLabel('Filters, 2 new'), findsOneWidget);
    });

    testMobile('filter sheet returns selection on Apply', (tester) async {
      Map<String, Set<String>>? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await MobileFilterSheet.show(context, sections: const [
                  MobileFilterSection(id: 'type', title: 'Type', options: [
                    MobileOption(value: 'rent', label: 'Rent'),
                    MobileOption(value: 'sale', label: 'Sale'),
                  ]),
                ]);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rent'));
      await tester.pump();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(result, {'type': {'rent'}});
    });

    testMobile('sort sheet returns the chosen value', (tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await MobileSortSheet.show(context, options: const [
                  MobileOption(value: 'newest', label: 'Newest'),
                  MobileOption(value: 'oldest', label: 'Oldest'),
                ], selected: 'newest');
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oldest'));
      await tester.pumpAndSettle();
      expect(result, 'oldest');
    });

    testMobile('confirm dialog returns true / false', (tester) async {
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await MobileConfirmDialog.show(
                  context,
                  title: 'Delete lead Rahul?',
                  confirmLabel: 'Delete',
                  destructive: true,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(result, isTrue);
    });
  });

  group('Actions and forms', () {
    testMobile('sticky bar disables while loading', (tester) async {
      var saves = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MobileStickyActionBar(
            primary: MobileAction(
                label: 'Save', onPressed: () => saves++, loading: true),
            secondary: MobileAction(label: 'Cancel', onPressed: () {}),
          ),
        ),
      ));
      expect(find.byType(MobileButtonLoader), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(saves, 0);
    });

    testMobile('form scaffold renders steps and actions', (tester) async {
      await setSurface(tester, 320);
      var next = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MobileFormScaffold(
            stepHeader: const MobileFormStepHeader(
                currentStep: 2, totalSteps: 4, stepTitle: 'Location'),
            progress: const MobileFormProgress(currentStep: 2, totalSteps: 4),
            actions: MobileFormActions(
              onBack: () {},
              onNext: () => next++,
              draftStatus: 'Draft saved',
            ),
            children: const [
              MobileFormSection(title: 'Address', children: [TextField()]),
            ],
          ),
        ),
      ));
      expect(find.text('Step 2 of 4 · Location'), findsOneWidget);
      expect(find.text('Draft saved'), findsOneWidget);
      await tester.tap(find.text('Next'));
      expect(next, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('More view', () {
    testMobile('renders only the sections it is given', (tester) async {
      await setSurface(tester, 360, height: 1400);
      final opened = <String>[];
      await tester.pumpWidget(wrap(MobileMoreView(
        name: 'Asha',
        email: 'asha@example.com',
        role: 'Sales',
        sections: MobileNavConfig.moreForRole('Sales', canView: _all),
        onOpen: (e) => opened.add(e.route),
      )));
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Employees'), findsNothing);
      await tester.tap(find.text('Profile'));
      expect(opened, ['/profile']);
    });

    testMobile('telecaller shift slot is shown when provided',
        (tester) async {
      await setSurface(tester, 360, height: 1400);
      await tester.pumpWidget(wrap(MobileMoreView(
        name: 'Ravi',
        email: '',
        role: 'Telecaller',
        sections: MobileNavConfig.moreForRole('Telecaller', canView: _all),
        shiftControl: const Text('shift-toggle'),
        onOpen: (_) {},
      )));
      expect(find.text('Shift'), findsOneWidget);
      expect(find.text('shift-toggle'), findsOneWidget);
    });
  });

  testMobile('semantics tree has labels for all tappables', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(home: _shell()));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    expect(SemanticsBinding.instance.semanticsEnabled, isTrue);
    handle.dispose();
  });
}

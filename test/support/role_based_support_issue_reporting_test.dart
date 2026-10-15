import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/support/models/support_navigation_registry.dart';
import 'package:propkart/features/support/widgets/create_issue_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  UserModel createMockUser(String role) {
    return UserModel(
      id: 'test_user_id',
      email: 'test@propkart.com',
      fullName: 'Test $role',
      role: role,
      permissions: const [],
      token: 'fake_jwt_token',
    );
  }

  group('SupportNavigationRegistry Role-Based Discovery Tests', () {
    test('Admin role sees all authorized sidebar pages and subpages', () {
      RoleGuard.currentUser = createMockUser('Admin');
      final pages = SupportNavigationRegistry.getPagesForRole('Admin');

      final pageKeys = pages.map((p) => p.key).toList();
      final pageTitles = pages.map((p) => p.title).toList();

      // Check required Admin pages from prompt
      expect(pageTitles, contains('Dashboard'));
      expect(pageTitles, contains('Properties'));
      expect(pageTitles, contains('Leads'));
      expect(pageTitles, contains('Employees'));
      expect(pageTitles, contains('Reports'));
      expect(pageTitles, contains('Campaign'));
      expect(pageTitles, contains('Lead Allocation'));
      expect(pageTitles, contains('Library'));
      expect(pageTitles, contains('Settings'));
      expect(pageTitles, contains('Support'));
      expect(pageTitles, contains('Recycle Bin'));

      // Ensure telecaller-only queue pages are not in Admin top level
      expect(pageKeys, isNot(contains('telecaller_calling_leads')));
      expect(pageKeys, isNot(contains('telecaller_callbacks')));
      expect(pageKeys, isNot(contains('telecaller_cnr')));

      // Check Campaign nested subpages: Connection, Meta, Housing
      final campaignPage = pages.firstWhere((p) => p.key == 'campaign');
      expect(campaignPage.hasSubpages, isTrue);
      final campaignSubTitles = campaignPage.subpages.map((s) => s.title).toList();
      expect(campaignSubTitles, contains('Connection'));
      expect(campaignSubTitles, contains('Meta'));
      expect(campaignSubTitles, contains('Housing'));

      // Check Settings nested subpages
      final settingsPage = pages.firstWhere((p) => p.key == 'settings');
      expect(settingsPage.hasSubpages, isTrue);
      final settingsSubTitles = settingsPage.subpages.map((s) => s.title).toList();
      expect(settingsSubTitles, contains('Profile & Security'));
      expect(settingsSubTitles, contains('Themes'));
      expect(settingsSubTitles, contains('Appearance'));
      expect(settingsSubTitles, contains('Locations'));
      expect(settingsSubTitles, contains('Run Match Criteria'));
      expect(settingsSubTitles, contains('Upload Limits'));
      expect(settingsSubTitles, contains('KPI Configuration'));
      expect(settingsSubTitles, contains('System & About'));
    });

    test('Admin Dashboard includes individual selectable KPI cards', () {
      final pages = SupportNavigationRegistry.getPagesForRole('Admin');
      final dashboard = pages.firstWhere((p) => p.key == 'dashboard');
      final fnNames = dashboard.directFunctions.map((f) => f.name).toList();

      expect(fnNames, contains('Available Inventory KPI'));
      expect(fnNames, contains('Total Leads KPI'));
      expect(fnNames, contains('Telecallers Count KPI'));
      expect(fnNames, contains('New Leads Allocated KPI'));
      expect(fnNames, contains('Old Leads Allocated KPI'));
      expect(fnNames, contains('CNR (No Response) KPI'));
      expect(fnNames, contains('Not Interested KPI'));
      expect(fnNames, contains('Sales Users Count KPI'));
      expect(fnNames, contains('Assigned to Sales KPI'));
      expect(fnNames, contains('Site Visits Done KPI'));
      expect(fnNames, contains('Rejected After Visit KPI'));
      expect(fnNames, contains('Deal Won KPI'));
    });

    test('Telecaller role sees only Telecaller sidebar pages and subpages', () {
      RoleGuard.currentUser = createMockUser('Telecaller');
      final pages = SupportNavigationRegistry.getPagesForRole('Telecaller');

      final pageKeys = pages.map((p) => p.key).toList();
      final pageTitles = pages.map((p) => p.title).toList();

      expect(pageTitles, contains('Dashboard'));
      expect(pageTitles, contains('Properties'));
      expect(pageTitles, contains('My Calling Leads'));
      expect(pageTitles, contains('Callbacks'));
      expect(pageTitles, contains('CNR / Retry'));
      expect(pageTitles, contains('All Leads (Track)'));
      expect(pageTitles, contains('Library'));
      expect(pageTitles, contains('Settings'));
      expect(pageTitles, contains('Support'));
      expect(pageTitles, contains('Recycle Bin'));

      // Telecaller must NOT see Admin-only pages
      expect(pageKeys, isNot(contains('employees')));
      expect(pageKeys, isNot(contains('reports')));
      expect(pageKeys, isNot(contains('campaign')));
      expect(pageKeys, isNot(contains('lead_allocation')));

      // Telecaller Settings must not contain Admin-only subpages
      final settingsPage = pages.firstWhere((p) => p.key == 'settings');
      final settingsSubTitles = settingsPage.subpages.map((s) => s.title).toList();
      expect(settingsSubTitles, contains('Profile & Security'));
      expect(settingsSubTitles, contains('Themes'));
      expect(settingsSubTitles, isNot(contains('Run Match Criteria')));
      expect(settingsSubTitles, isNot(contains('Upload Limits')));
      expect(settingsSubTitles, isNot(contains('KPI Configuration')));
      expect(settingsSubTitles, isNot(contains('Page Control')));

      // Check Telecaller Dashboard specific KPIs
      final dashboard = pages.firstWhere((p) => p.key == 'dashboard');
      final fnNames = dashboard.directFunctions.map((f) => f.name).toList();
      expect(fnNames, contains('Open Leads KPI'));
      expect(fnNames, contains('New Leads Allocated KPI'));
      expect(fnNames, contains('Assigned to Sales KPI'));
      expect(fnNames, contains('Callback Leads KPI'));
      expect(fnNames, contains('CNR Leads KPI'));
      expect(fnNames, contains('Total Calling Leads KPI'));
    });

    test('Salesperson role sees only Salesperson sidebar pages and subpages', () {
      RoleGuard.currentUser = createMockUser('Sales');
      final pages = SupportNavigationRegistry.getPagesForRole('Sales');

      final pageKeys = pages.map((p) => p.key).toList();
      final pageTitles = pages.map((p) => p.title).toList();

      expect(pageTitles, contains('Dashboard'));
      expect(pageTitles, contains('Properties'));
      expect(pageTitles, contains('Leads'));
      expect(pageTitles, contains('Library'));
      expect(pageTitles, contains('Settings'));
      expect(pageTitles, contains('Support'));
      expect(pageTitles, contains('Recycle Bin'));

      // Salesperson must NOT see Telecaller calling desk or Admin management
      expect(pageKeys, isNot(contains('telecaller_calling_leads')));
      expect(pageKeys, isNot(contains('telecaller_callbacks')));
      expect(pageKeys, isNot(contains('telecaller_cnr')));
      expect(pageKeys, isNot(contains('employees')));
      expect(pageKeys, isNot(contains('reports')));
      expect(pageKeys, isNot(contains('campaign')));
      expect(pageKeys, isNot(contains('lead_allocation')));

      // Check Sales Dashboard specific KPIs
      final dashboard = pages.firstWhere((p) => p.key == 'dashboard');
      final fnNames = dashboard.directFunctions.map((f) => f.name).toList();
      expect(fnNames, contains('Available Inventory KPI'));
      expect(fnNames, contains('Site Visit Done KPI'));
      expect(fnNames, contains('Active Leads KPI'));
      expect(fnNames, contains('Deals Won KPI'));
      expect(fnNames, contains('Assigned Leads KPI'));
      expect(fnNames, contains('New Leads KPI'));
      expect(fnNames, contains('Follow-ups Due KPI'));
      expect(fnNames, contains('Active Follow-ups KPI'));
    });
  });

  group('SupportNavigationRegistry Problem Categorization Tests', () {
    test('KPI functions return tailored KPI problem options with Other', () {
      const kpiFn = SupportFunctionItem(
        key: 'kpi_test',
        name: 'Open Leads KPI',
        category: SupportFunctionCategory.kpi,
      );
      final options = SupportNavigationRegistry.getIssueOptionsForFunction(kpiFn);

      expect(options, contains('Incorrect KPI count'));
      expect(options, contains('KPI data not updating'));
      expect(options, contains('KPI not loading / showing 0'));
      expect(options, contains('Date filter not working'));
      expect(options, contains('Function not working'));
      expect(options, contains('Other'));
      expect(options.last, equals('Other'));
    });

    test('Filter functions return tailored Filter problem options with Other', () {
      const filterFn = SupportFunctionItem(
        key: 'filter_test',
        name: 'Search Bar & Location Filter',
        category: SupportFunctionCategory.filter,
      );
      final options = SupportNavigationRegistry.getIssueOptionsForFunction(filterFn);

      expect(options, contains('Search returned no results or incorrect results'));
      expect(options, contains('Filter selection not updating the list'));
      expect(options, contains('Date range filter not applying'));
      expect(options, contains('Filter reset button not working'));
      expect(options, contains('Other'));
    });

    test('Form functions return tailored Form problem options with Other', () {
      const formFn = SupportFunctionItem(
        key: 'form_test',
        name: 'Add New Property Form',
        category: SupportFunctionCategory.form,
      );
      final options = SupportNavigationRegistry.getIssueOptionsForFunction(formFn);

      expect(options, contains('Form validation error or unable to submit'));
      expect(options, contains('Data not saving after clicking submit'));
      expect(options, contains('Dropdown options missing or empty'));
      expect(options, contains('Other'));
    });
  });

  group('CreateIssueModal UI Flow & Step Navigation Tests', () {
    testWidgets('Step 1 renders role pages and expands subpages on click', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      RoleGuard.currentUser = createMockUser('Admin');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateIssueModal(
              catalog: const [],
              onSubmitted: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Step 1 header
      expect(find.text('Step 1: Select Page / Subpage'), findsOneWidget);

      // Verify Dashboard and Settings are listed
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Properties'), findsOneWidget);
      expect(find.text('Campaign'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Settings has subpages indicator
      expect(find.textContaining('Subpages'), findsWidgets);

      // Click on Campaign to expand its subpages
      await tester.ensureVisible(find.text('Campaign'));
      await tester.tap(find.text('Campaign'));
      await tester.pumpAndSettle();

      // Verify Campaign subpages appear: Connection, Meta, Housing
      expect(find.text('Connection'), findsOneWidget);
      expect(find.text('Meta'), findsOneWidget);
      expect(find.text('Housing'), findsOneWidget);

      // Click on Meta subpage
      await tester.tap(find.text('Meta'));
      await tester.pumpAndSettle();

      // Check selected target pill indicates Campaign -> Meta
      expect(find.textContaining('Campaign → Meta'), findsOneWidget);

      // Click Next Step to move to Step 2
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      // Verify Step 2 functions for Meta Campaign appear
      expect(find.textContaining('Step 2: Select Specific Function in "Campaign → Meta"'), findsOneWidget);
      expect(find.text('Meta Ads Webhook Ingestion Inbox Table'), findsOneWidget);
      expect(find.text('Single & Bulk Lead Assignment to Telecallers'), findsOneWidget);

      // Select a function
      await tester.tap(find.text('Meta Ads Webhook Ingestion Inbox Table'));
      await tester.pumpAndSettle();

      // Click Next Step to move to Step 3
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      // Verify Step 3 problem selection appears
      expect(find.textContaining('Step 3: What problem are you experiencing with "Meta Ads Webhook Ingestion Inbox Table"?'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Select "Other"
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      // Click Next Step to move to Step 4
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      // Verify Step 4 shows "Other — Please describe the issue"
      expect(find.text('Other — Please describe the issue'), findsOneWidget);
      expect(find.text('Detailed Description *'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Changing page in Step 1 resets previously selected function and problem', (tester) async {
      RoleGuard.currentUser = createMockUser('Admin');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreateIssueModal(
              catalog: const [],
              onSubmitted: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select Dashboard
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      // Advance to Step 2
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      // Select Available Inventory KPI
      expect(find.text('Available Inventory KPI'), findsOneWidget);
      await tester.tap(find.text('Available Inventory KPI'));
      await tester.pumpAndSettle();

      // Go to Step 3
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      // Select "Incorrect KPI count"
      expect(find.text('Incorrect KPI count'), findsOneWidget);
      await tester.tap(find.text('Incorrect KPI count'));
      await tester.pumpAndSettle();

      // Go back to Step 2 then Step 1
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();

      expect(find.text('Step 1: Select Page / Subpage'), findsOneWidget);

      // Change page to Properties
      await tester.tap(find.text('Properties'));
      await tester.pumpAndSettle();

      // Go to Step 2: Functions must now belong to Properties, not Dashboard!
      await tester.tap(find.text('Next Step'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Step 2: Select Specific Function in "Properties"'), findsOneWidget);
      expect(find.text('Add New Property Listing Form & Wizard'), findsOneWidget);
      expect(find.text('Share Property (PDF Generation, Custom Field Filter & Download)'), findsOneWidget);
      expect(find.text('Available Inventory KPI'), findsNothing);
    });
  });
}

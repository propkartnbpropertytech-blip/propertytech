import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/utils/team_user_visibility.dart';
import 'package:propkart/features/users/models/user_model.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/core/design_system/widgets/form/crm_multi_select_dropdown.dart';

void main() {
  group('Rejected Leads - Sales and Telecaller Filter Tests', () {
    final prexaTc = const UserModel(
      id: 'tc-prexa-01',
      roleId: 'role-tc',
      roleName: 'Telecaller',
      fullName: 'Prexa Vithalapara',
      email: 'prexa@propkart.com',
      isActive: true,
    );

    final zeelTc = const UserModel(
      id: 'tc-zeel-02',
      roleId: 'role-tc',
      roleName: 'Telecaller',
      fullName: 'Zeel Mudaliyar',
      email: 'zeel@propkart.com',
      isActive: true,
    );

    final rajanSales = const UserModel(
      id: 'sales-rajan-01',
      roleId: 'role-sales',
      roleName: 'Sales',
      fullName: 'Rajan Purani',
      email: 'rajan@propkart.com',
      isActive: true,
    );

    final rakeshSales = const UserModel(
      id: 'sales-rakesh-02',
      roleId: 'role-sales',
      roleName: 'Sales',
      fullName: 'Rakesh Jadav',
      email: 'rakesh@propkart.com',
      isActive: true,
    );

    final allUsers = [prexaTc, zeelTc, rajanSales, rakeshSales];

    test('TeamUserVisibility.visibleSalesUsers returns only Sales users', () {
      final salesUsers = TeamUserVisibility.visibleSalesUsers(
        users: allUsers,
        currentRole: 'Admin',
        currentUserId: 'admin-01',
      );

      expect(salesUsers.length, equals(2));
      expect(salesUsers.map((u) => u.fullName), containsAll(['Rajan Purani', 'Rakesh Jadav']));
      expect(salesUsers.map((u) => u.fullName), isNot(contains('Prexa Vithalapara')));
      expect(salesUsers.map((u) => u.fullName), isNot(contains('Zeel Mudaliyar')));
    });

    test('TeamUserVisibility.visibleTelecallerUsers returns only Telecaller users', () {
      final telecallerUsers = TeamUserVisibility.visibleTelecallerUsers(
        users: allUsers,
        currentRole: 'Admin',
        currentUserId: 'admin-01',
      );

      expect(telecallerUsers.length, equals(2));
      expect(telecallerUsers.map((u) => u.fullName), containsAll(['Prexa Vithalapara', 'Zeel Mudaliyar']));
      expect(telecallerUsers.map((u) => u.fullName), isNot(contains('Rajan Purani')));
      expect(telecallerUsers.map((u) => u.fullName), isNot(contains('Rakesh Jadav')));
    });

    test('Rejected lead matches Telecaller via assignedTelecallerId', () {
      final req = RequirementModel(
        id: 'req-01',
        clientName: 'Nirav Vaishnav',
        clientMobile: '9898000001',
        categoryId: 'cat-rent',
        categoryName: 'Apartment',
        propertyTypeId: 'apt-01',
        propertyTypeName: '2 BHK',
        minBudget: 20000,
        maxBudget: 35000,
        areaIds: ['area-01'],
        areaNames: ['Bodakdev'],
        status: 'Rejected (Others)',
        createdAt: DateTime.now(),
        assignedTelecallerId: 'tc-prexa-01',
        assignedTo: 'sales-rajan-01',
      );

      expect(TeamUserVisibility.requirementBelongsToUser(req, prexaTc), isTrue);
      expect(TeamUserVisibility.requirementBelongsToUser(req, zeelTc), isFalse);
      expect(TeamUserVisibility.requirementBelongsToUser(req, rajanSales), isTrue);
      expect(TeamUserVisibility.requirementBelongsToUser(req, rakeshSales), isFalse);
    });

    test('Rejected lead matches Telecaller via metaCustomFields (telecaller_id & rejected_by)', () {
      final reqWithMeta = RequirementModel(
        id: 'req-02',
        clientName: 'Sunil Patel',
        clientMobile: '9898000002',
        categoryId: 'cat-rent',
        categoryName: 'Apartment',
        propertyTypeId: 'apt-01',
        propertyTypeName: '3 BHK',
        minBudget: 35000,
        maxBudget: 50000,
        areaIds: ['area-01'],
        areaNames: ['Satellite'],
        status: 'Rejected (Budget Mismatch)',
        createdAt: DateTime.now(),
        metaCustomFields: {
          'telecaller_id': 'tc-zeel-02',
          'rejected_by': 'Zeel Mudaliyar',
        },
      );

      expect(TeamUserVisibility.requirementBelongsToUser(reqWithMeta, zeelTc), isTrue);
      expect(TeamUserVisibility.requirementBelongsToUser(reqWithMeta, prexaTc), isFalse);
    });

    test('Rejected lead matches Telecaller via creatorName / createdBy', () {
      final reqWithCreator = RequirementModel(
        id: 'req-03',
        clientName: 'Kunal Shah',
        clientMobile: '9898000003',
        categoryId: 'cat-rent',
        categoryName: 'Apartment',
        propertyTypeId: 'apt-01',
        propertyTypeName: '2 BHK',
        minBudget: 25000,
        maxBudget: 30000,
        areaIds: ['area-01'],
        areaNames: ['Vastrapur'],
        status: 'Rejected (Location Mismatch)',
        createdAt: DateTime.now(),
        createdBy: 'tc-prexa-01',
        creatorName: 'Prexa Vithalapara',
      );

      expect(TeamUserVisibility.requirementBelongsToUser(reqWithCreator, prexaTc), isTrue);
      expect(TeamUserVisibility.requirementBelongsToUser(reqWithCreator, zeelTc), isFalse);
    });

    test('Multi-Telecaller selection correctly matches leads from either selected telecaller', () {
      final reqPrexa = RequirementModel(
        id: 'req-p',
        clientName: 'Client 1',
        clientMobile: '9000000001',
        categoryId: 'cat-rent',
        categoryName: 'Apartment',
        propertyTypeId: 'apt-01',
        propertyTypeName: '2 BHK',
        minBudget: 20000,
        maxBudget: 30000,
        areaIds: [],
        areaNames: [],
        status: 'Rejected (Others)',
        createdAt: DateTime.now(),
        assignedTelecallerId: 'tc-prexa-01',
      );

      final reqZeel = RequirementModel(
        id: 'req-z',
        clientName: 'Client 2',
        clientMobile: '9000000002',
        categoryId: 'cat-rent',
        categoryName: 'Apartment',
        propertyTypeId: 'apt-01',
        propertyTypeName: '2 BHK',
        minBudget: 20000,
        maxBudget: 30000,
        areaIds: [],
        areaNames: [],
        status: 'Rejected (Not Interested)',
        createdAt: DateTime.now(),
        assignedTelecallerId: 'tc-zeel-02',
      );

      final reqOther = RequirementModel(
        id: 'req-o',
        clientName: 'Client 3',
        clientMobile: '9000000003',
        categoryId: 'cat-rent',
        categoryName: 'Apartment',
        propertyTypeId: 'apt-01',
        propertyTypeName: '2 BHK',
        minBudget: 20000,
        maxBudget: 30000,
        areaIds: [],
        areaNames: [],
        status: 'Rejected (Call Attempted)',
        createdAt: DateTime.now(),
        assignedTelecallerId: 'tc-other-99',
      );

      final allReqs = [reqPrexa, reqZeel, reqOther];

      // Filter simulation with single telecaller: Prexa
      final selectedTcPrexa = [prexaTc];
      final prexaFiltered = allReqs.where((r) => selectedTcPrexa.any((tc) => TeamUserVisibility.requirementBelongsToUser(r, tc))).toList();
      expect(prexaFiltered.length, equals(1));
      expect(prexaFiltered.first.id, equals('req-p'));

      // Filter simulation with single telecaller: Zeel
      final selectedTcZeel = [zeelTc];
      final zeelFiltered = allReqs.where((r) => selectedTcZeel.any((tc) => TeamUserVisibility.requirementBelongsToUser(r, tc))).toList();
      expect(zeelFiltered.length, equals(1));
      expect(zeelFiltered.first.id, equals('req-z'));

      // Filter simulation with MULTIPLE telecallers: Prexa AND Zeel
      final selectedTcBoth = [prexaTc, zeelTc];
      final bothFiltered = allReqs.where((r) => selectedTcBoth.any((tc) => TeamUserVisibility.requirementBelongsToUser(r, tc))).toList();
      expect(bothFiltered.length, equals(2));
      expect(bothFiltered.map((r) => r.id), containsAll(['req-p', 'req-z']));
      expect(bothFiltered.map((r) => r.id), isNot(contains('req-o')));
    });

    test('Combined Sales and Telecaller filtering correctly intersects both criteria', () {
      final reqPrexaRajan = RequirementModel(
        id: 'req-pr',
        clientName: 'Client PR',
        clientMobile: '9000000001',
        categoryId: 'cat-rent',
        categoryName: 'Apartment',
        propertyTypeId: 'apt-01',
        propertyTypeName: '2 BHK',
        minBudget: 20000,
        maxBudget: 30000,
        areaIds: [],
        areaNames: [],
        status: 'Rejected (Others)',
        createdAt: DateTime.now(),
        assignedTelecallerId: 'tc-prexa-01',
        assignedTo: 'sales-rajan-01',
      );

      final reqPrexaRakesh = RequirementModel(
        id: 'req-pk',
        clientName: 'Client PK',
        clientMobile: '9000000002',
        categoryId: 'cat-rent',
        categoryName: 'Apartment',
        propertyTypeId: 'apt-01',
        propertyTypeName: '2 BHK',
        minBudget: 20000,
        maxBudget: 30000,
        areaIds: [],
        areaNames: [],
        status: 'Rejected (Others)',
        createdAt: DateTime.now(),
        assignedTelecallerId: 'tc-prexa-01',
        assignedTo: 'sales-rakesh-02',
      );

      final allReqs = [reqPrexaRajan, reqPrexaRakesh];

      // Telecaller = Prexa, Sales = Rajan -> Only reqPrexaRajan
      final filtered = allReqs.where((r) {
        final matchesTc = TeamUserVisibility.requirementBelongsToUser(r, prexaTc);
        final matchesSales = TeamUserVisibility.requirementBelongsToUser(r, rajanSales);
        return matchesTc && matchesSales;
      }).toList();

      expect(filtered.length, equals(1));
      expect(filtered.first.id, equals('req-pr'));
    });

    testWidgets('CRMMultiSelectDropdown displays "All Telecallers" and allows multi-selection', (tester) async {
      final items = [
        LookupItem(id: 'tc-prexa-01', name: 'Prexa Vithalapara'),
        LookupItem(id: 'tc-zeel-02', name: 'Zeel Mudaliyar'),
      ];
      List<String> selected = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: SizedBox(
                    width: 200,
                    child: CRMMultiSelectDropdown(
                      label: 'Telecaller',
                      allLabel: 'All Telecallers',
                      selectedIds: selected,
                      items: items,
                      onChanged: (vals) {
                        setState(() {
                          selected = vals;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify initial label shows "All Telecallers"
      expect(find.text('All Telecallers'), findsOneWidget);

      // Tap dropdown to open overlay
      await tester.tap(find.text('All Telecallers'));
      await tester.pumpAndSettle();

      // Check both telecallers are listed
      expect(find.text('Prexa Vithalapara'), findsOneWidget);
      expect(find.text('Zeel Mudaliyar'), findsOneWidget);

      // Select Prexa
      await tester.tap(find.text('Prexa Vithalapara'));
      await tester.pumpAndSettle();
      expect(selected, contains('tc-prexa-01'));

      // Select Zeel as well (multi-selection)
      await tester.tap(find.text('Zeel Mudaliyar'));
      await tester.pumpAndSettle();
      expect(selected, containsAll(['tc-prexa-01', 'tc-zeel-02']));

      // Tap Done
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // Verify display text shows both names
      expect(find.text('Prexa Vithalapara, Zeel Mudaliyar'), findsOneWidget);
    });
  });
}

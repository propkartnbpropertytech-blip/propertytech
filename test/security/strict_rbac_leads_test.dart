import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/requirements/models/requirement_view_model.dart';
import 'package:propkart/core/utils/team_user_visibility.dart';

void main() {
  group('Strict RBAC Leads Isolation Tests (Frontend)', () {
    final now = DateTime.now();

    final adminUser = UserModel(
      id: 'admin_1',
      fullName: 'Admin Super',
      email: 'admin@propkart.com',
      role: 'Admin',
      permissions: const [],
      mobile: '9999999999',
      organizationId: 'org_1',
    );

    final salesUser1 = UserModel(
      id: 'sales_1',
      fullName: 'Sales One',
      email: 'sales1@propkart.com',
      role: 'Sales',
      permissions: const [],
      mobile: '8888888888',
      organizationId: 'org_1',
    );

    final salesUser2 = UserModel(
      id: 'sales_2',
      fullName: 'Sales Two',
      email: 'sales2@propkart.com',
      role: 'Sales',
      permissions: const [],
      mobile: '7777777777',
      organizationId: 'org_1',
    );

    final telecaller1 = UserModel(
      id: 'tc_1',
      fullName: 'Telecaller One',
      email: 'tc1@propkart.com',
      role: 'Telecaller',
      permissions: const [],
      mobile: '6666666666',
      organizationId: 'org_1',
    );

    final telecaller2 = UserModel(
      id: 'tc_2',
      fullName: 'Telecaller Two',
      email: 'tc2@propkart.com',
      role: 'Telecaller',
      permissions: const [],
      mobile: '5555555555',
      organizationId: 'org_1',
    );

    // Lead 1: Handed over by TC 1 -> Assigned to Sales 1
    final lead1 = RequirementModel(
      id: 'req_1',
      clientName: 'Client for Sales 1 from TC 1',
      clientMobile: '9000000001',
      categoryId: 'cat_res',
      categoryName: 'Residential',
      propertyTypeId: 'type_1',
      propertyTypeName: 'Apartment',
      status: 'Assigned to Sales',
      listingTypeName: 'Rent',
      minBudget: 10000,
      maxBudget: 20000,
      areaIds: const ['a1'],
      areaNames: const ['Bopal'],
      assignedTo: salesUser1.id,
      assigneeName: salesUser1.fullName,
      createdBy: telecaller1.id,
      creatorName: telecaller1.fullName,
      metaCustomFields: {
        'telecaller_id': telecaller1.id,
        '_transfer': {
          'assigned_to': salesUser1.id,
          'assigned_to_name': salesUser1.fullName,
          'telecaller_id': telecaller1.id,
        },
      },
      createdAt: now,
    );

    // Lead 2: Handed over by TC 2 -> Assigned to Sales 2
    final lead2 = RequirementModel(
      id: 'req_2',
      clientName: 'Client for Sales 2 from TC 2',
      clientMobile: '9000000002',
      categoryId: 'cat_res',
      categoryName: 'Residential',
      propertyTypeId: 'type_1',
      propertyTypeName: 'Apartment',
      status: 'Assigned to Sales',
      listingTypeName: 'Rent',
      minBudget: 10000,
      maxBudget: 20000,
      areaIds: const ['a1'],
      areaNames: const ['Bopal'],
      assignedTo: salesUser2.id,
      assigneeName: salesUser2.fullName,
      createdBy: telecaller2.id,
      creatorName: telecaller2.fullName,
      metaCustomFields: {
        'telecaller_id': telecaller2.id,
        '_transfer': {
          'assigned_to': salesUser2.id,
          'assigned_to_name': salesUser2.fullName,
          'telecaller_id': telecaller2.id,
        },
      },
      createdAt: now,
    );

    // Lead 3: Raw Unassigned Lead (not handed to sales yet)
    final lead3 = RequirementModel(
      id: 'req_3',
      clientName: 'Raw Unassigned Lead',
      clientMobile: '9000000003',
      categoryId: 'cat_res',
      categoryName: 'Residential',
      propertyTypeId: 'type_1',
      propertyTypeName: 'Apartment',
      status: 'Not Started',
      listingTypeName: 'Rent',
      minBudget: 10000,
      maxBudget: 20000,
      areaIds: const ['a1'],
      areaNames: const ['Bopal'],
      assignedTo: 'unassigned',
      createdBy: 'system_webhook',
      createdAt: now,
    );

    final allItems = [lead1, lead2, lead3]
        .map((r) => RequirementListItemViewModel.fromRequirement(r))
        .toList();

    test('1. Admin can see ALL leads across the company', () {
      final results = RequirementFilterEngine.filterAndSort(
        items: allItems,
        currentUser: adminUser,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
      );

      expect(results.length, equals(3));
      expect(results.map((v) => v.requirement.id), containsAll(['req_1', 'req_2', 'req_3']));
    });

    test('2. Sales User 1 can ONLY see leads assigned to them (zero access to Sales 2 or Unassigned)', () {
      final results = RequirementFilterEngine.filterAndSort(
        items: allItems,
        currentUser: salesUser1,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
        salesLeadGroupFilter: 'all',
      );

      expect(results.length, equals(1));
      expect(results.first.requirement.id, equals('req_1'));
    });

    test('3. Sales User 2 can ONLY see leads assigned to them', () {
      final results = RequirementFilterEngine.filterAndSort(
        items: allItems,
        currentUser: salesUser2,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
        salesLeadGroupFilter: 'all',
      );

      expect(results.length, equals(1));
      expect(results.first.requirement.id, equals('req_2'));
    });

    test('4. Telecaller 1 can ONLY see leads handed over to sales by TC 1 (never TC 2 or unassigned)', () {
      final results = RequirementFilterEngine.filterAndSort(
        items: allItems,
        currentUser: telecaller1,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
      );

      expect(results.length, equals(1));
      expect(results.first.requirement.id, equals('req_1'));
    });

    test('5. Telecaller 2 can ONLY see leads handed over to sales by TC 2', () {
      final results = RequirementFilterEngine.filterAndSort(
        items: allItems,
        currentUser: telecaller2,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
      );

      expect(results.length, equals(1));
      expect(results.first.requirement.id, equals('req_2'));
    });

    test('6. TeamUserVisibility: telecallerLeadSentToSalesperson enforces strict ownership and sales assignment', () {
      // TC 1 with lead 1 -> true
      expect(TeamUserVisibility.telecallerLeadSentToSalesperson(lead1, null, telecaller1), isTrue);
      // TC 2 with lead 1 -> false (not TC 2's lead)
      expect(TeamUserVisibility.telecallerLeadSentToSalesperson(lead1, null, telecaller2), isFalse);
      // TC 1 with lead 2 -> false (not TC 1's lead)
      expect(TeamUserVisibility.telecallerLeadSentToSalesperson(lead2, null, telecaller1), isFalse);
      // TC 1 with lead 3 -> false (unassigned lead, not handed to sales)
      expect(TeamUserVisibility.telecallerLeadSentToSalesperson(lead3, null, telecaller1), isFalse);
    });
  });
}

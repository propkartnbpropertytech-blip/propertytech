import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/dashboard/models/dashboard_summary.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/requirements/services/followup_sync_engine.dart';

void main() {
  group('FollowupSyncEngine - Sales User Follow-ups Visibility Tests', () {
    final now = DateTime.now();
    final todayStr = DateTime(now.year, now.month, now.day, 11, 0).toUtc().toIso8601String();
    final overdueStr = DateTime(now.year, now.month, now.day - 2, 10, 0).toUtc().toIso8601String();
    final futureStr = DateTime(now.year, now.month, now.day + 2, 15, 0).toUtc().toIso8601String();

    final salesUser = UserModel(
      id: 'sales_user_1',
      fullName: 'Somel Rathod',
      email: 'somel@propkart.in',
      role: 'Sales',
      organizationId: 'org_1',
      permissions: const [],
    );

    test('Follow-ups for Assigned leads appear under AllClients, Today, Due, and Future without being dropped', () {
      final reqsList = [
        RequirementModel(
          id: 'req_assigned_due',
          clientName: 'MN',
          clientMobile: '9898000939',
          categoryId: 'cat_1',
          categoryName: 'Residential',
          propertyTypeId: 'pt_1',
          propertyTypeName: 'Apartment',
          listingTypeId: 'lt_rent',
          listingTypeName: 'Rent',
          status: 'Assigned',
          minBudget: 20000,
          maxBudget: 30000,
          areaIds: const ['a1'],
          areaNames: const ['Gota'],
          assignedTo: 'sales_user_1',
          assigneeName: 'Somel Rathod',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        RequirementModel(
          id: 'req_assigned_today',
          clientName: 'Patel',
          clientMobile: '7801861441',
          categoryId: 'cat_1',
          categoryName: 'Residential',
          propertyTypeId: 'pt_1',
          propertyTypeName: 'Apartment',
          listingTypeId: 'lt_rent',
          listingTypeName: 'Rent',
          status: 'Assigned',
          minBudget: 20000,
          maxBudget: 30000,
          areaIds: const ['a1'],
          areaNames: const ['Gota'],
          assignedTo: 'sales_user_1',
          assigneeName: 'Somel Rathod',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
        RequirementModel(
          id: 'req_interested_future',
          clientName: 'Solanki Devang',
          clientMobile: '9988776655',
          categoryId: 'cat_1',
          categoryName: 'Residential',
          propertyTypeId: 'pt_1',
          propertyTypeName: 'Apartment',
          listingTypeId: 'lt_rent',
          listingTypeName: 'Rent',
          status: 'Interested',
          minBudget: 20000,
          maxBudget: 30000,
          areaIds: const ['a1'],
          areaNames: const ['Gota'],
          assignedTo: 'sales_user_1',
          assigneeName: 'Somel Rathod',
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];

      final serverFollowups = [
        DashboardFollowup(
          id: 'fu_1',
          requirementId: 'req_assigned_due',
          clientName: 'MN',
          mobile: '9898000939',
          followupDate: overdueStr,
          status: 'Pending',
          notes: 'Customer asked for callbacks in evening',
        ),
        DashboardFollowup(
          id: 'fu_2',
          requirementId: 'req_assigned_today',
          clientName: 'Patel',
          mobile: '7801861441',
          followupDate: todayStr,
          status: 'Pending',
          notes: 'Call at 11 AM',
        ),
        DashboardFollowup(
          id: 'fu_3',
          requirementId: 'req_interested_future',
          clientName: 'Solanki Devang',
          mobile: '9988776655',
          followupDate: futureStr,
          status: 'Pending',
          notes: 'Future site visit discussion',
        ),
      ];

      final result = FollowupSyncEngine.categorizeFollowups(
        serverFollowups: serverFollowups,
        reqsList: reqsList,
        isSiteVisitSection: false,
        targetListingType: 'Rent',
        currentUser: salesUser,
      );

      expect(result.allClients.length, equals(3), reason: 'All 3 clients must be listed');
      expect(result.due.length, equals(1), reason: 'Overdue pending followup must be in Due');
      expect(result.today.length, equals(1), reason: "Today's pending followup must be in Today");
      expect(result.future.length, equals(1), reason: 'Future pending followup must be in Future');
      expect(result.due.first.clientName, equals('MN'));
      expect(result.today.first.clientName, equals('Patel'));
      expect(result.future.first.clientName, equals('Solanki Devang'));
    });

    test('Rejected and Won leads are excluded from active followups', () {
      final reqsList = [
        RequirementModel(
          id: 'req_rejected',
          clientName: 'Rejected Client',
          clientMobile: '9000000001',
          categoryId: 'cat_1',
          categoryName: 'Residential',
          propertyTypeId: 'pt_1',
          propertyTypeName: 'Apartment',
          listingTypeId: 'lt_rent',
          listingTypeName: 'Rent',
          status: 'Rejected (Budget Mismatch)',
          minBudget: 20000,
          maxBudget: 30000,
          areaIds: const ['a1'],
          areaNames: const ['Gota'],
          assignedTo: 'sales_user_1',
          assigneeName: 'Somel Rathod',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
        RequirementModel(
          id: 'req_won',
          clientName: 'Won Client',
          clientMobile: '9000000002',
          categoryId: 'cat_1',
          categoryName: 'Residential',
          propertyTypeId: 'pt_1',
          propertyTypeName: 'Apartment',
          listingTypeId: 'lt_rent',
          listingTypeName: 'Rent',
          status: 'Won',
          minBudget: 20000,
          maxBudget: 30000,
          areaIds: const ['a1'],
          areaNames: const ['Gota'],
          assignedTo: 'sales_user_1',
          assigneeName: 'Somel Rathod',
          createdAt: now.subtract(const Duration(days: 5)),
        ),
      ];

      final serverFollowups = [
        DashboardFollowup(
          id: 'fu_rej',
          requirementId: 'req_rejected',
          clientName: 'Rejected Client',
          mobile: '9000000001',
          followupDate: overdueStr,
          status: 'Pending',
        ),
        DashboardFollowup(
          id: 'fu_won',
          requirementId: 'req_won',
          clientName: 'Won Client',
          mobile: '9000000002',
          followupDate: overdueStr,
          status: 'Pending',
        ),
      ];

      final result = FollowupSyncEngine.categorizeFollowups(
        serverFollowups: serverFollowups,
        reqsList: reqsList,
        isSiteVisitSection: false,
        targetListingType: 'Rent',
        currentUser: salesUser,
      );

      expect(result.allClients.length, equals(0), reason: 'Rejected and Won leads must not appear in active follow-ups');
    });

    test('Requirements with nextFollowupDate are synthesized if no serverFollowup exists', () {
      final reqsList = [
        RequirementModel(
          id: 'req_synth',
          clientName: 'Synthesized Client',
          clientMobile: '9111111111',
          categoryId: 'cat_1',
          categoryName: 'Residential',
          propertyTypeId: 'pt_1',
          propertyTypeName: 'Apartment',
          listingTypeId: 'lt_rent',
          listingTypeName: 'Rent',
          status: 'Assigned',
          nextFollowupDate: futureStr,
          remarks: 'Needs quotation tomorrow',
          minBudget: 20000,
          maxBudget: 30000,
          areaIds: const ['a1'],
          areaNames: const ['Gota'],
          assignedTo: 'sales_user_1',
          assigneeName: 'Somel Rathod',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];

      final result = FollowupSyncEngine.categorizeFollowups(
        serverFollowups: [],
        reqsList: reqsList,
        isSiteVisitSection: false,
        targetListingType: 'Rent',
        currentUser: salesUser,
      );

      expect(result.allClients.length, equals(1));
      expect(result.future.length, equals(1));
      expect(result.future.first.clientName, equals('Synthesized Client'));
    });
  });
}

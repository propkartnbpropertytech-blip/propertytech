import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/users/models/user_model.dart';
import 'package:propkart/features/users/utils/employee_activity.dart';

void main() {
  const sales = UserModel(
    id: 'sales-1',
    roleId: 'r1',
    roleName: 'Sales',
    fullName: 'Amit Shah',
    email: 'amit@example.com',
    mobile: '9876543210',
    isActive: true,
    createdByName: 'Admin One',
    adminId: 'admin-1',
  );

  RequirementModel lead({
    String status = 'Follow-up',
    String? assignedTo = 'sales-1',
    String? listingTypeName = 'Rent',
    DateTime? followup,
    List<dynamic>? visits,
  }) {
    return RequirementModel(
      id: 'l1',
      clientName: 'Riya',
      clientMobile: '9999999999',
      categoryId: 'c',
      categoryName: 'Residential',
      propertyTypeId: 't',
      propertyTypeName: 'Apartment',
      listingTypeName: listingTypeName,
      minBudget: 50,
      maxBudget: 70,
      areaIds: const [],
      areaNames: const [],
      status: status,
      createdAt: DateTime(2026, 1, 1),
      assignedTo: assignedTo,
      nextFollowupDate: followup?.toIso8601String(),
      rawSiteVisits: visits,
    );
  }

  test('links assigned leads and listing type to the employee', () {
    final req = lead(listingTypeName: 'Re-Sale');
    expect(EmployeeActivity.belongsToRequirement(req, sales), isTrue);
    expect(EmployeeActivity.isAssignedTo(req, sales), isTrue);
    expect(EmployeeActivity.requirementListingBucket(req), 'Re-Sale');
  });

  test('classifies won, upcoming follow-up and site visits', () {
    final req = lead(
      status: 'Won',
      followup: DateTime.now().add(const Duration(days: 2)),
      visits: const [
        {'id': 'v1'},
      ],
    );
    expect(EmployeeActivity.isWon(req), isTrue);
    expect(EmployeeActivity.isPendingFollowup(req), isTrue);
    expect(EmployeeActivity.hasSiteVisit(req), isTrue);
  });
}

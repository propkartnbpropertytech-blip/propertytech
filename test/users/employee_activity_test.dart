import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/properties/models/property_model.dart';
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

  test('sales KPIs count only properties they added, not admin-linked ones', () {
    expect(
      EmployeeActivity.isPropertyAddedBy(
        PropertyModel(
          id: 'p1',
          propertyCode: 'PK-1',
          title: 'Flat',
          categoryId: 'c',
          categoryName: 'Residential',
          propertyTypeId: 't',
          propertyTypeName: 'Apartment',
          listingTypeId: 'rent',
          listingTypeName: 'Rent',
          propertyStatusId: 's',
          propertyStatusName: 'Available',
          cityId: 'city',
          cityName: 'Ahmedabad',
          areaId: 'a',
          areaName: 'Thaltej',
          pincode: '380054',
          address: 'SG',
          price: 1,
          deposit: 0,
          maintenance: 0,
          bedrooms: 2,
          bathrooms: 2,
          balconies: 1,
          parking: 1,
          ownerName: 'O',
          ownerMobile: '1',
          isVerified: true,
          createdBy: 'sales-1',
          createdByName: 'Amit Shah',
          createdAt: DateTime(2026, 1, 1),
          images: const [],
          amenities: const [],
          videos: const [],
        ),
        sales,
      ),
      isTrue,
    );
    expect(
      EmployeeActivity.isPropertyAddedBy(
        PropertyModel(
          id: 'p2',
          propertyCode: 'PK-2',
          title: 'Admin Flat',
          categoryId: 'c',
          categoryName: 'Residential',
          propertyTypeId: 't',
          propertyTypeName: 'Apartment',
          listingTypeId: 'rent',
          listingTypeName: 'Rent',
          propertyStatusId: 's',
          propertyStatusName: 'Available',
          cityId: 'city',
          cityName: 'Ahmedabad',
          areaId: 'a',
          areaName: 'Thaltej',
          pincode: '380054',
          address: 'SG',
          price: 1,
          deposit: 0,
          maintenance: 0,
          bedrooms: 2,
          bathrooms: 2,
          balconies: 1,
          parking: 1,
          ownerName: 'O',
          ownerMobile: '1',
          isVerified: true,
          createdBy: 'admin-1',
          createdByName: 'Propkart Admin',
          createdAt: DateTime(2026, 1, 1),
          images: const [],
          amenities: const [],
          videos: const [],
          adminId: 'sales-1',
        ),
        sales,
      ),
      isFalse,
    );
  });

  test('assigned count drops after reassignment to another sales person', () {
    final stillAssigned = lead(assignedTo: 'sales-1');
    final reassigned = lead(
      assignedTo: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    ).copyWith(assigneeName: 'Amit Shah');
    expect(EmployeeActivity.isAssignedTo(stillAssigned, sales), isTrue);
    expect(EmployeeActivity.isAssignedTo(reassigned, sales), isFalse);
    expect(EmployeeActivity.isSalesOwnedLead(reassigned, sales), isFalse);
  });

  test('created leads stay counted even if currently unassigned', () {
    final created = lead(assignedTo: null).copyWith(
      createdBy: 'sales-1',
      creatorName: 'Amit Shah',
      assignedTo: '',
    );
    expect(EmployeeActivity.isCreatedBy(created, sales), isTrue);
    expect(EmployeeActivity.isAssignedTo(created, sales), isFalse);
    expect(EmployeeActivity.isSalesOwnedLead(created, sales), isTrue);
  });

  test('bin leads are not treated as rejected sales KPIs', () {
    expect(EmployeeActivity.isRejected(lead(status: 'Bin')), isFalse);
  });

  test('rejected and won KPIs use current sales-owned status', () {
    expect(EmployeeActivity.isRejected(lead(status: 'Rejected (Not Answering)')), isTrue);
    expect(EmployeeActivity.isRejected(lead(status: 'Follow-up')), isFalse);
    expect(EmployeeActivity.isWon(lead(status: 'Won')), isTrue);
  });
}

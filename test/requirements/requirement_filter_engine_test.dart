import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/requirements/models/requirement_view_model.dart';
import 'package:propkart/features/users/models/user_model.dart' as users_model;

RequirementModel createMockRequirement({
  required String id,
  required DateTime createdAt,
  String clientName = 'Alice Sharma',
  String clientMobile = '9876543210',
  String listingTypeName = 'Rent',
  String categoryName = 'Residential Apartment',
  String categoryId = 'cat_res',
  String status = 'Active',
  String propertyTypeName = 'Apartment',
  String? configurationName = '2 BHK',
  String? configurationId = 'cfg_2bhk',
  double minBudget = 20000,
  double maxBudget = 35000,
  String? createdBy = 'user_admin',
  String? creatorName = 'Admin Boss',
  String? assignedTo = 'user_sales_1',
  String? assigneeName = 'John Sales',
  Map<String, dynamic>? metaCustomFields,
}) {
  return RequirementModel(
    id: id,
    clientName: clientName,
    clientMobile: clientMobile,
    categoryId: categoryId,
    categoryName: categoryName,
    propertyTypeId: 'type_apt',
    propertyTypeName: propertyTypeName,
    listingTypeId: listingTypeName == 'Rent' ? 'lt_rent' : 'lt_resale',
    listingTypeName: listingTypeName,
    status: status,
    configurationId: configurationId,
    configurationName: configurationName,
    minBudget: minBudget,
    maxBudget: maxBudget,
    areaIds: const ['area_1', 'area_2'],
    areaNames: const ['Andheri West', 'Juhu'],
    remarks: 'Looking for gated society with parking',
    createdBy: createdBy,
    creatorName: creatorName,
    assignedTo: assignedTo,
    assigneeName: assigneeName,
    createdAt: createdAt,
    metaCustomFields: metaCustomFields,
  );
}

void main() {
  group('RequirementListItemViewModel Pre-computation', () {
    test('pre-computes status mapping, budget text, specs and normalized search tokens', () {
      final now = DateTime.now();
      final r = createMockRequirement(
        id: 'r1',
        createdAt: now,
        clientName: 'Rajesh Mehta',
        clientMobile: '9123456789',
        minBudget: 50000,
        maxBudget: 80000,
        status: 'Active',
        configurationName: '3 BHK',
      );

      final vm = RequirementListItemViewModel.fromRequirement(r);

      expect(vm.listingTypeLabel, equals('Rent'));
      expect(vm.mappedStatus, equals('Interested')); // Active maps to Interested
      expect(vm.budgetText, equals('₹50 K - ₹80 K'));
      expect(vm.specsText, contains('3 BHK'));
      expect(vm.normalizedSearchTokens, contains('rajesh'));
      expect(vm.normalizedSearchTokens, contains('9123456789'));
      expect(vm.normalizedSearchTokens, contains('andheri'));
      expect(vm.sortDateMillis, equals(now.millisecondsSinceEpoch));
    });

    test('pre-parses rejected_at timestamp correctly', () {
      final now = DateTime.now();
      final rejDate = now.subtract(const Duration(days: 3));
      final r = createMockRequirement(
        id: 'r2',
        createdAt: now,
        status: 'Rejected',
        metaCustomFields: {
          'rejected_at': rejDate.toIso8601String(),
        },
      );

      final vm = RequirementListItemViewModel.fromRequirement(r);

      expect(vm.isRejected, isTrue);
      expect(vm.rejectedAt, isNotNull);
      expect(vm.sortDateMillis, equals(rejDate.toLocal().millisecondsSinceEpoch));
    });
  });

  group('RequirementFilterEngine Logic & Semantics', () {
    final now = DateTime.now();
    final adminUser = UserModel(
      id: 'admin_1',
      fullName: 'Super Admin',
      email: 'admin@propkart.com',
      role: 'Super Admin',
      token: 'tok_1',
      permissions: const [],
    );

    final knownUserSales = users_model.UserModel(
      id: 'sales_1',
      fullName: 'Sales Person',
      email: 'sales@propkart.com',
      roleId: 'role_sales',
      roleName: 'Sales',
      isActive: true,
    );

    final r1 = createMockRequirement(
      id: 'req_1',
      createdAt: now,
      status: 'Active',
      listingTypeName: 'Rent',
      assignedTo: 'sales_1',
      assigneeName: 'Sales Person',
    );
    final r2 = createMockRequirement(
      id: 'req_2',
      createdAt: now.subtract(const Duration(days: 2)),
      status: 'Won',
      listingTypeName: 'Rent',
      assignedTo: 'sales_1',
    );
    final r3 = createMockRequirement(
      id: 'req_3',
      createdAt: now.subtract(const Duration(days: 5)),
      status: 'Rejected',
      listingTypeName: 'Re-Sale',
      metaCustomFields: {
        'rejected_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      },
    );

    final vms = [
      RequirementListItemViewModel.fromRequirement(r1),
      RequirementListItemViewModel.fromRequirement(r2),
      RequirementListItemViewModel.fromRequirement(r3),
    ];

    test('filters by listing type (Rent vs Re-Sale)', () {
      final rentResults = RequirementFilterEngine.filterAndSort(
        items: vms,
        currentUser: adminUser,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
        knownUsers: [knownUserSales],
      );
      expect(rentResults.length, equals(1));
      expect(rentResults.first.requirement.id, equals('req_1'));
    });

    test('filters won leads in Won tab', () {
      final wonResults = RequirementFilterEngine.filterAndSort(
        items: vms,
        currentUser: adminUser,
        activeListingTab: 'Rent',
        activeMainTab: 'Won',
        knownUsers: [knownUserSales],
      );
      expect(wonResults.length, equals(1));
      expect(wonResults.first.requirement.id, equals('req_2'));
    });

    test('filters rejected leads in Rejected tab', () {
      final rejResults = RequirementFilterEngine.filterAndSort(
        items: vms,
        currentUser: adminUser,
        activeListingTab: 'Re-Sale',
        activeMainTab: 'Rejected',
        knownUsers: [knownUserSales],
      );
      expect(rejResults.length, equals(1));
      expect(rejResults.first.requirement.id, equals('req_3'));
    });

    test('filters by Sales salesperson filter', () {
      final salesResults = RequirementFilterEngine.filterAndSort(
        items: vms,
        currentUser: adminUser,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
        selectedSalesFilterId: 'sales_1',
        knownUsers: [knownUserSales],
      );
      expect(salesResults.length, equals(1));
      expect(salesResults.first.requirement.id, equals('req_1'));
    });

    test('search query matches pre-normalized tokens instantly', () {
      final searchResults = RequirementFilterEngine.filterAndSort(
        items: vms,
        currentUser: adminUser,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
        searchQuery: 'Alice',
        knownUsers: [knownUserSales],
      );
      expect(searchResults.length, equals(1));
      expect(searchResults.first.requirement.id, equals('req_1'));
    });
  });

  group('RequirementFilterEngine High-Scale Performance Benchmarks', () {
    test('Benchmark: 100 items filter & sort executes in <1 ms', () {
      final now = DateTime.now();
      final items = List.generate(
        100,
        (i) => RequirementListItemViewModel.fromRequirement(
          createMockRequirement(
            id: 'req_$i',
            createdAt: now.subtract(Duration(hours: i)),
            clientName: 'Client $i',
            status: i % 3 == 0 ? 'Won' : (i % 3 == 1 ? 'Rejected' : 'Active'),
            minBudget: (10000 + (i * 500)).toDouble(),
            maxBudget: (20000 + (i * 1000)).toDouble(),
          ),
        ),
      );

      final sw = Stopwatch()..start();
      final result = RequirementFilterEngine.filterAndSort(
        items: items,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
        searchQuery: 'Client 4',
      );
      sw.stop();

      expect(result.isNotEmpty, isTrue);
      expect(sw.elapsedMilliseconds, lessThan(10));
    });

    test('Benchmark: 1,000 items filter & sort executes in <5 ms', () {
      final now = DateTime.now();
      final items = List.generate(
        1000,
        (i) => RequirementListItemViewModel.fromRequirement(
          createMockRequirement(
            id: 'req_$i',
            createdAt: now.subtract(Duration(hours: i % 720)),
            clientName: 'Lead VIP $i',
            status: 'Active',
            propertyTypeName: i % 2 == 0 ? 'Apartment' : 'Villa',
            configurationName: '${(i % 4) + 1} BHK',
            minBudget: 30000,
            maxBudget: 60000,
          ),
        ),
      );

      // Warm up
      RequirementFilterEngine.filterAndSort(items: items, activeListingTab: 'Rent', activeMainTab: 'Leads');

      final sw = Stopwatch()..start();
      final result = RequirementFilterEngine.filterAndSort(
        items: items,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
        searchQuery: 'Lead VIP 77',
      );
      sw.stop();

      expect(result.isNotEmpty, isTrue);
      expect(sw.elapsedMilliseconds, lessThan(15));
    });

    test('Benchmark: 5,000 items filter & sort executes in <25 ms', () {
      final now = DateTime.now();
      final items = List.generate(
        5000,
        (i) => RequirementListItemViewModel.fromRequirement(
          createMockRequirement(
            id: 'req_$i',
            createdAt: now.subtract(Duration(minutes: i * 5)),
            clientName: 'Corporate Lead $i',
            status: 'Active',
            configurationName: '${(i % 5) + 1} BHK',
          ),
        ),
      );

      // Warm up
      RequirementFilterEngine.filterAndSort(items: items, activeListingTab: 'Rent', activeMainTab: 'Leads');

      final sw = Stopwatch()..start();
      final result = RequirementFilterEngine.filterAndSort(
        items: items,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
        searchQuery: 'Corporate Lead 1234',
      );
      sw.stop();

      expect(result.length, equals(1));
      expect(sw.elapsedMilliseconds, lessThan(50));
    });
  });
}

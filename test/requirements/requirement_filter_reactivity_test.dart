import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/requirements/models/requirement_view_model.dart';
import 'package:propkart/features/requirements/services/followup_sync_engine.dart';
import 'package:propkart/features/dashboard/models/dashboard_summary.dart';

RequirementModel _createReq({
  required String id,
  required String clientName,
  required String clientMobile,
  required String status,
  String listingTypeName = 'Rent',
  String categoryId = 'cat_1',
  String categoryName = 'Residential',
  String propertyTypeId = 'pt_1',
  String propertyTypeName = 'Apartment',
  String? configurationId,
  String? configurationName,
  DateTime? createdAt,
}) {
  return RequirementModel(
    id: id,
    clientName: clientName,
    clientMobile: clientMobile,
    status: status,
    listingTypeName: listingTypeName,
    categoryId: categoryId,
    categoryName: categoryName,
    propertyTypeId: propertyTypeId,
    propertyTypeName: propertyTypeName,
    configurationId: configurationId,
    configurationName: configurationName,
    minBudget: 10000,
    maxBudget: 20000,
    areaIds: const ['a1'],
    areaNames: const ['Bopal'],
    createdAt: createdAt ?? DateTime.now(),
  );
}

void main() {
  group('Requirement Filter Reactivity & Tab Tests', () {
    final now = DateTime.now();

    final reqActiveRent = _createReq(
      id: 'req_1',
      clientName: 'Active Rent Client',
      clientMobile: '9876543210',
      status: 'Call Attempted',
      listingTypeName: 'Rent',
      configurationId: 'cfg_2bhk',
      configurationName: '2 BHK',
      createdAt: now,
    );

    final reqRejectedRent = _createReq(
      id: 'req_2',
      clientName: 'Rejected Rent Client',
      clientMobile: '9876543211',
      status: 'Rejected - Budget Issue',
      listingTypeName: 'Rent',
      configurationId: 'cfg_2bhk',
      configurationName: '2 BHK',
      createdAt: now,
    );

    final reqWonRent = _createReq(
      id: 'req_3',
      clientName: 'Won Client',
      clientMobile: '9876543212',
      status: 'Won',
      listingTypeName: 'Rent',
      configurationId: 'cfg_3bhk',
      configurationName: '3 BHK',
      createdAt: now,
    );

    final allItems = [reqActiveRent, reqRejectedRent, reqWonRent]
        .map((r) => RequirementListItemViewModel.fromRequirement(r))
        .toList();

    test('Switching from Leads to Rejected tab reacts immediately and excludes active leads', () {
      final leadsTab = RequirementFilterEngine.filterAndSort(
        items: allItems,
        activeMainTab: 'Leads',
        activeListingTab: 'Rent',
      );
      expect(leadsTab.map((v) => v.requirement.id), contains('req_1'));
      expect(leadsTab.map((v) => v.requirement.id), isNot(contains('req_2')));
      expect(leadsTab.map((v) => v.requirement.id), isNot(contains('req_3')));

      final rejectedTab = RequirementFilterEngine.filterAndSort(
        items: allItems,
        activeMainTab: 'Rejected',
        activeListingTab: 'Rent',
      );
      expect(rejectedTab.map((v) => v.requirement.id), contains('req_2'));
      expect(rejectedTab.map((v) => v.requirement.id), isNot(contains('req_1')));
      expect(rejectedTab.map((v) => v.requirement.id), isNot(contains('req_3')));
    });

    test('Switching to Won tab reacts immediately and shows only Won leads', () {
      final wonTab = RequirementFilterEngine.filterAndSort(
        items: allItems,
        activeMainTab: 'Won',
        activeListingTab: 'Rent',
      );
      expect(wonTab.map((v) => v.requirement.id), contains('req_3'));
      expect(wonTab.map((v) => v.requirement.id), isNot(contains('req_1')));
      expect(wonTab.map((v) => v.requirement.id), isNot(contains('req_2')));
    });

    test('Category and Status filter selections isolate specific matches', () {
      final statusMatch = RequirementFilterEngine.filterAndSort(
        items: allItems,
        activeMainTab: 'Leads',
        activeListingTab: 'Rent',
        selectedStatus: 'Call Attempted',
      );
      expect(statusMatch.length, 1);
      expect(statusMatch.first.requirement.id, 'req_1');

      final statusNoMatch = RequirementFilterEngine.filterAndSort(
        items: allItems,
        activeMainTab: 'Leads',
        activeListingTab: 'Rent',
        selectedStatus: 'Interested',
      );
      expect(statusNoMatch.isEmpty, true);
    });
  });

  group('FollowupSyncEngine Date & Listing Filters Tests', () {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    final fToday = DashboardFollowup(
      id: 'f_today',
      clientName: 'Today Client',
      mobile: '9999900001',
      followupDate: '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
      status: 'Pending',
      salespersonName: 'Ravi',
    );

    final fTomorrow = DashboardFollowup(
      id: 'f_tomorrow',
      clientName: 'Tomorrow Client',
      mobile: '9999900002',
      followupDate: '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}',
      status: 'Pending',
      salespersonName: 'Ravi',
    );

    final fNextWeek = DashboardFollowup(
      id: 'f_next_week',
      clientName: 'Next Week Client',
      mobile: '9999900003',
      followupDate: '${nextWeek.year}-${nextWeek.month.toString().padLeft(2, '0')}-${nextWeek.day.toString().padLeft(2, '0')}',
      status: 'Pending',
      salespersonName: 'Zeel',
    );

    final reqs = <RequirementModel>[
      _createReq(
        id: 'req_f1',
        clientName: 'Today Client',
        clientMobile: '9999900001',
        status: 'Active',
        listingTypeName: 'Rent',
        createdAt: today,
      ),
      _createReq(
        id: 'req_f2',
        clientName: 'Tomorrow Client',
        clientMobile: '9999900002',
        status: 'Active',
        listingTypeName: 'Rent',
        createdAt: today,
      ),
      _createReq(
        id: 'req_f3',
        clientName: 'Next Week Client',
        clientMobile: '9999900003',
        status: 'Active',
        listingTypeName: 'Rent',
        createdAt: today,
      ),
    ];

    test('Followup date filter applies to allClients when customDateFilter is set', () {
      final resAllDates = FollowupSyncEngine.categorizeFollowups(
        serverFollowups: [fToday, fTomorrow, fNextWeek],
        reqsList: reqs,
        isSiteVisitSection: false,
        targetListingType: 'Rent',
      );
      expect(resAllDates.allClients.length, 3);
      expect(resAllDates.future.length, 2);

      final resTomorrowOnly = FollowupSyncEngine.categorizeFollowups(
        serverFollowups: [fToday, fTomorrow, fNextWeek],
        reqsList: reqs,
        isSiteVisitSection: false,
        targetListingType: 'Rent',
        customDateFilter: tomorrow,
      );
      expect(resTomorrowOnly.allClients.length, 1);
      expect(resTomorrowOnly.allClients.first.id, 'f_tomorrow');
      expect(resTomorrowOnly.future.length, 1);
      expect(resTomorrowOnly.future.first.id, 'f_tomorrow');
    });

    test('Followup listing type check allows targetListingType="All" and matches Rent correctly', () {
      final resRent = FollowupSyncEngine.categorizeFollowups(
        serverFollowups: [fToday],
        reqsList: reqs,
        isSiteVisitSection: false,
        targetListingType: 'Rent',
      );
      expect(resRent.allClients.length, 1);

      final resResale = FollowupSyncEngine.categorizeFollowups(
        serverFollowups: [fToday],
        reqsList: reqs,
        isSiteVisitSection: false,
        targetListingType: 'Re-Sale',
      );
      expect(resResale.allClients.length, 0);

      final resAll = FollowupSyncEngine.categorizeFollowups(
        serverFollowups: [fToday],
        reqsList: reqs,
        isSiteVisitSection: false,
        targetListingType: 'All',
      );
      expect(resAll.allClients.length, 1);
    });
  });
}

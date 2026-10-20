import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/requirements/models/requirement_view_model.dart';
import 'package:propkart/features/users/models/user_model.dart' as users_model;
import 'package:propkart/core/utils/team_user_visibility.dart';
import 'package:propkart/core/storage/model_mappers.dart';
import 'package:propkart/core/storage/local_repositories.dart';

void main() {
  group('Telecaller Assigned to Sales Verification', () {
    const zeelId = '7835e447-46ea-4ba9-8048-bd1fb74c4e12';
    const zeelName = 'Zeel Mudaliyar';

    final zeelAuthUser = UserModel(
      id: zeelId,
      fullName: zeelName,
      email: 'zeel@propkart.com',
      role: 'Telecaller',
      token: 'tok_zeel',
      permissions: const [],
    );

    final viralUser = users_model.UserModel(
      id: '91aa6e3d-fd2d-4e74-a771-98399a8a5fed',
      fullName: 'Viral Jadeja',
      email: 'viral@propkart.com',
      roleId: 'role_sales',
      roleName: 'Sales Executive',
      isActive: true,
    );

    final rakeshUser = users_model.UserModel(
      id: 'c7fa7b7e-209d-49ec-a1c0-1f9e1574e305',
      fullName: 'Rakesh Jadav',
      email: 'rakesh@propkart.com',
      roleId: 'role_sales',
      roleName: 'Sales Executive',
      isActive: true,
    );

    final amanBackendJson = {
      'id': 'req_aman',
      'client_name': 'Aman',
      'client_mobile': '7046162205',
      'category_id': 'cat_res',
      'category_name': 'Residential Apartment',
      'status': 'Assigned',
      'listing_type_id': 'lt_rent',
      'listing_type_name': 'Rent',
      'property_type_name': 'Apartment',
      'min_budget': 15000.0,
      'max_budget': 25000.0,
      'area_ids': ['area_1'],
      'area_names': ['Vastrapur'],
      'assigned_to': viralUser.id,
      'assignee_name': viralUser.fullName,
      'telecaller_id': zeelId,
      'created_at': DateTime.now().toIso8601String(),
      'meta_custom_fields': {
        '_transfer': {
          'assigned_to': viralUser.id,
          'assigned_to_name': viralUser.fullName,
          'telecaller_id': zeelId,
          'interacted_by': zeelId,
        },
      },
    };

    final dkBackendJson = {
      'id': 'req_dk',
      'client_name': 'D K',
      'client_mobile': '9904351833',
      'category_id': 'cat_res',
      'category_name': 'Residential Apartment',
      'status': 'Assigned',
      'listing_type_id': 'lt_rent',
      'listing_type_name': 'Rent',
      'property_type_name': 'Apartment',
      'min_budget': 20000.0,
      'max_budget': 35000.0,
      'area_ids': ['area_2'],
      'area_names': ['Bopal'],
      'assigned_to': rakeshUser.id,
      'assignee_name': rakeshUser.fullName,
      'telecaller_id': zeelId,
      'created_at': DateTime.now().toIso8601String(),
      'meta_custom_fields': {
        '_transfer': {
          'assigned_to': rakeshUser.id,
          'assigned_to_name': rakeshUser.fullName,
          'telecaller_id': zeelId,
          'interacted_by': zeelId,
        },
      },
    };

    test('RequirementModel deserializes telecaller_id and _transfer properly', () {
      final reqAman = RequirementModel.fromJson(amanBackendJson);
      final reqDk = RequirementModel.fromJson(dkBackendJson);

      expect(reqAman.assignedTelecallerId, equals(zeelId));
      expect(reqAman.assigneeName, equals('Viral Jadeja'));
      expect(reqDk.assignedTelecallerId, equals(zeelId));
      expect(reqDk.assigneeName, equals('Rakesh Jadav'));
    });

    test('Local storage mappers preserve assignedTelecallerId through toLocal() and toModel()', () {
      final reqAman = RequirementModel.fromJson(amanBackendJson);
      final local = reqAman.toLocal();
      final restored = local.toModel();

      expect(restored.assignedTelecallerId, equals(zeelId));
    });

    test('RequirementListItemViewModel maps status "Assigned" to "Assigned to Sales"', () {
      final reqAman = RequirementModel.fromJson(amanBackendJson);
      final reqDk = RequirementModel.fromJson(dkBackendJson);

      final vmAman = RequirementListItemViewModel.fromRequirement(reqAman, currentUser: zeelAuthUser);
      final vmDk = RequirementListItemViewModel.fromRequirement(reqDk, currentUser: zeelAuthUser);

      expect(vmAman.mappedStatus, equals('Assigned to Sales'));
      expect(vmDk.mappedStatus, equals('Assigned to Sales'));
    });

    test('RequirementFilterEngine keeps Aman and D K for Zeel in Leads view', () {
      final reqAman = RequirementModel.fromJson(amanBackendJson);
      final reqDk = RequirementModel.fromJson(dkBackendJson);

      final vms = [
        RequirementListItemViewModel.fromRequirement(reqAman, currentUser: zeelAuthUser),
        RequirementListItemViewModel.fromRequirement(reqDk, currentUser: zeelAuthUser),
      ];

      final resultsAll = RequirementFilterEngine.filterAndSort(
        items: vms,
        currentUser: zeelAuthUser,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
        selectedStatus: 'All',
        knownUsers: [viralUser, rakeshUser],
      );

      expect(resultsAll.length, equals(2));
      expect(resultsAll.map((vm) => vm.requirement.clientName), containsAll(['Aman', 'D K']));
    });

    test('RequirementFilterEngine filters correctly by status Assigned / Assigned to Sales', () {
      final reqAman = RequirementModel.fromJson(amanBackendJson);
      final reqDk = RequirementModel.fromJson(dkBackendJson);

      final vms = [
        RequirementListItemViewModel.fromRequirement(reqAman, currentUser: zeelAuthUser),
        RequirementListItemViewModel.fromRequirement(reqDk, currentUser: zeelAuthUser),
      ];

      final resultsAssigned = RequirementFilterEngine.filterAndSort(
        items: vms,
        currentUser: zeelAuthUser,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
        selectedStatus: 'Assigned',
        knownUsers: [viralUser, rakeshUser],
      );
      expect(resultsAssigned.length, equals(2));

      final resultsAssignedToSales = RequirementFilterEngine.filterAndSort(
        items: vms,
        currentUser: zeelAuthUser,
        activeListingTab: 'Rent',
        activeMainTab: 'Leads',
        selectedStatus: 'Assigned to Sales',
        knownUsers: [viralUser, rakeshUser],
      );
      expect(resultsAssignedToSales.length, equals(2));
    });

    test('TeamUserVisibility matches assigned leads to Salesperson and Telecaller', () {
      final reqAman = RequirementModel.fromJson(amanBackendJson);
      final reqDk = RequirementModel.fromJson(dkBackendJson);

      expect(TeamUserVisibility.requirementBelongsToUser(reqAman, viralUser), isTrue);
      expect(TeamUserVisibility.requirementBelongsToUser(reqAman, zeelAuthUser), isTrue);

      expect(TeamUserVisibility.telecallerLeadSentToSalesperson(reqAman, viralUser, zeelAuthUser), isTrue);
      expect(TeamUserVisibility.telecallerLeadSentToSalesperson(reqDk, rakeshUser, zeelAuthUser), isTrue);
    });
  });
}

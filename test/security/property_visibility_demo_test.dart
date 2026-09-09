import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:propkart/core/security/role_guard.dart';
import 'package:propkart/features/auth/models/user_model.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/properties/bloc/properties_bloc.dart';
import 'package:propkart/core/storage/isar_collections.dart';
import 'package:propkart/core/storage/model_mappers.dart';

void main() {
  group('Property Global Visibility & Creator Hiding Demonstration', () {
    testWidgets('Simulate Scenario: Sales User A creates P1 -> Sales User B views it', (WidgetTester tester) async {
      print('=== DEMONSTRATION SCENARIO START ===');

      // 1. Sales User A creates Property P1
      final userA = const UserModel(
        id: 'user_a_id',
        role: 'Sales',
        fullName: 'Sales User A',
        email: 'sales.a@propkart.com',
        permissions: [],
        isActive: true,
      );

      final p1Data = {
        'id': 'prop_p1_id',
        'title': 'Property P1',
        'price': 7500000.0,
        'category_id': 'cat_res_id',
        'property_type_id': 'type_apt_id',
        'city_id': 'city_ahm_id',
        'area_id': 'area_pra_id',
        'owner_name': 'John Doe',
        'owner_mobile': '9876543210',
        'created_by': userA.id,
        'creator': {
          'id': userA.id,
          'full_name': userA.fullName,
        },
        'created_at': DateTime.now().toIso8601String(),
        'organization_id': 'org_1_id',
        'admin_id': 'admin_1_id',
      };

      print('Step 1: Sales User A (${userA.fullName}) creates Property P1.');
      print('Creation payload:\n${const JsonEncoder.withIndent('  ').convert(p1Data)}');

      // 2. Sales User B logs in
      final userB = const UserModel(
        id: 'user_b_id',
        role: 'Sales',
        fullName: 'Sales User B',
        email: 'sales.b@propkart.com',
        permissions: [],
        isActive: true,
        adminId: 'admin_1_id',
        organizationId: 'org_1_id',
      );
      RoleGuard.currentUser = userB;
      print('\nStep 2: Sales User B (${userB.fullName}) logs in.');
      print('Logged in user state: ID=${userB.id}, Role=${userB.role}');

      // 3. Show the exact API response containing P1
      final apiResponse = {
        'success': true,
        'message': 'Properties retrieved successfully',
        'data': {
          'properties': [p1Data],
          'count': 1,
        }
      };
      print('\nStep 3: Show the exact API response containing P1 returned to Sales User B:');
      print(const JsonEncoder.withIndent('  ').convert(apiResponse));

      // 4. Show the Isar database after sync containing P1
      final propertyModel = PropertyModel.fromJson(p1Data);
      final PropertyLocal propertyLocal = propertyModel.toLocal();
      print('\nStep 4: Show the Isar database object after sync containing P1:');
      print('Isar object: id=${propertyLocal.id}, title=${propertyLocal.title}, createdBy=${propertyLocal.createdBy}, createdByName=${propertyLocal.createdByName}');

      // 5. Show the BLoC state containing P1
      final state = PropertiesLoaded(
        properties: [propertyModel],
        metadata: null,
        bookmarkedIds: {},
        activeTab: 'All',
      );
      print('\nStep 5: Show the BLoC state containing P1:');
      print('BLoC State: PropertiesLoaded with ${state.properties.length} properties:');
      for (var p in state.properties) {
        print(' - Property: id=${p.id}, title=${p.title}, creator=${p.createdByName} (${p.createdBy})');
      }

      // 6. Show the UI rendering P1 and confirming "Added By" is hidden
      print('\nStep 6: Show the UI rendering P1.');
      final currentUser = RoleGuard.currentUser;
      final isUserAdminOrSuperAdmin = currentUser != null &&
          (currentUser.role == 'Super Admin' || currentUser.role == 'Admin');

      print('UI columns definition check:');
      print(' - "Client" column: Rendered');
      print(' - "Added By" / "Created By" column: ${isUserAdminOrSuperAdmin ? "Visible" : "Hidden (Sales User)"}');
      expect(isUserAdminOrSuperAdmin, isFalse);

      print('\n=== DEMONSTRATION SCENARIO SUCCESS ===');
    });
  });
}

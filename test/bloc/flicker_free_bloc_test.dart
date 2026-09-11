import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/requirements/bloc/requirements_bloc.dart';
import 'package:propkart/features/requirements/models/requirement_model.dart';
import 'package:propkart/features/properties/bloc/properties_bloc.dart';
import 'package:propkart/features/properties/models/property_model.dart';

void main() {
  group('Flicker-Free RequirementsBloc State Tests', () {
    final sampleReq = RequirementModel.fromJson({
      'id': 'req_123',
      'customer_name': 'Rahul Patel',
      'mobile': '9876543210',
      'category_id': 'cat-1',
      'property_type_id': 'prop-1',
      'budget_from': 5000000,
      'budget_to': 7500000,
      'area_ids': ['area-1'],
      'status': 'Active',
      'created_at': DateTime.now().toIso8601String(),
    });

    final sampleReq2 = RequirementModel.fromJson({
      'id': 'req_456',
      'customer_name': 'Anita Sharma',
      'mobile': '9123456780',
      'category_id': 'cat-1',
      'property_type_id': 'prop-2',
      'budget_from': 15000000,
      'budget_to': 20000000,
      'area_ids': ['area-2'],
      'status': 'Interested',
      'created_at': DateTime.now().toIso8601String(),
    });

    test('RequirementsLoaded holds newlyAdded and isSilentRefreshing', () {
      final state = RequirementsLoaded(
        requirements: [sampleReq],
        newlyAdded: sampleReq,
        isSilentRefreshing: false,
      );

      expect(state.requirements.length, equals(1));
      expect(state.newlyAdded?.id, equals('req_123'));
      expect(state.isSilentRefreshing, isFalse);
    });

    test('RequirementsLoaded.copyWith updates newlyAdded and isSilentRefreshing correctly', () {
      final state = RequirementsLoaded(
        requirements: [sampleReq],
      );

      final updated = state.copyWith(
        requirements: [sampleReq2, sampleReq],
        newlyAdded: sampleReq2,
        isSilentRefreshing: true,
      );

      expect(updated.requirements.length, equals(2));
      expect(updated.newlyAdded?.id, equals('req_456'));
      expect(updated.isSilentRefreshing, isTrue);
    });

    test('RequirementsSuccess passes newly created RequirementModel', () {
      final success = RequirementsSuccess(
        'Requirement created successfully',
        requirement: sampleReq,
      );

      expect(success.message, equals('Requirement created successfully'));
      expect(success.requirement?.id, equals('req_123'));
    });

    test('InitialLoad logic prevents table skeletons when requirements are already cached', () {
      final cachedRequirements = [sampleReq];

      final RequirementsState loadingState = RequirementsLoading();

      final rawLoadedList = loadingState is RequirementsLoaded
          ? loadingState.requirements
          : cachedRequirements;

      final isInitialLoad = (loadingState is RequirementsLoading || loadingState is RequirementsInitial) &&
          rawLoadedList.isEmpty;

      expect(isInitialLoad, isFalse);
      expect(rawLoadedList.length, equals(1));

      final emptyCache = <RequirementModel>[];
      final emptyRawLoadedList = loadingState is RequirementsLoaded
          ? loadingState.requirements
          : emptyCache;
      final emptyInitialLoad = (loadingState is RequirementsLoading || loadingState is RequirementsInitial) &&
          emptyRawLoadedList.isEmpty;

      expect(emptyInitialLoad, isTrue);
    });
  });

  group('Flicker-Free PropertiesBloc State Tests', () {
    final sampleProp = PropertyModel.fromJson({
      'id': 'prop_999',
      'property_code': 'PK-999',
      'title': 'Luxury 3BHK Apartment',
      'price': 8500000,
      'category_id': 'cat_1',
      'property_type_id': 'type_1',
      'city_id': 'city_1',
      'area_id': 'area_1',
      'owner_name': 'Sunil Mehta',
      'owner_mobile': '9988776655',
      'created_at': DateTime.now().toIso8601String(),
    });

    final sampleProp2 = PropertyModel.fromJson({
      'id': 'prop_1000',
      'property_code': 'PK-1000',
      'title': 'Commercial Office Space',
      'price': 15000000,
      'category_id': 'cat_2',
      'property_type_id': 'type_2',
      'city_id': 'city_1',
      'area_id': 'area_2',
      'owner_name': 'Kiran Shah',
      'owner_mobile': '9871234567',
      'created_at': DateTime.now().toIso8601String(),
    });

    test('PropertiesLoaded holds newlyAdded and isSilentRefreshing', () {
      final state = PropertiesLoaded(
        properties: [sampleProp],
        bookmarkedIds: {'prop_999'},
        activeTab: 'All',
        newlyAdded: sampleProp,
        isSilentRefreshing: false,
      );

      expect(state.properties.length, equals(1));
      expect(state.newlyAdded?.id, equals('prop_999'));
      expect(state.isSilentRefreshing, isFalse);
    });

    test('PropertiesLoaded.copyWith retains or overrides newlyAdded and isSilentRefreshing', () {
      final state = PropertiesLoaded(
        properties: [sampleProp],
        bookmarkedIds: {},
        activeTab: 'All',
      );

      final updated = state.copyWith(
        properties: [sampleProp2, sampleProp],
        newlyAdded: sampleProp2,
        isSilentRefreshing: true,
      );

      expect(updated.properties.length, equals(2));
      expect(updated.newlyAdded?.id, equals('prop_1000'));
      expect(updated.isSilentRefreshing, isTrue);
    });

    test('InitialLoad logic prevents table/card skeletons when properties are already cached', () {
      final cachedProperties = [sampleProp];

      final PropertiesState loadingState = PropertiesLoading();

      final rawLoadedList = loadingState is PropertiesLoaded
          ? loadingState.properties
          : cachedProperties;

      final isInitialLoad = (loadingState is PropertiesLoading || loadingState is PropertiesInitial) &&
          rawLoadedList.isEmpty;

      expect(isInitialLoad, isFalse);
      expect(rawLoadedList.length, equals(1));

      final emptyCache = <PropertyModel>[];
      final emptyRawLoadedList = loadingState is PropertiesLoaded
          ? loadingState.properties
          : emptyCache;
      final emptyInitialLoad = (loadingState is PropertiesLoading || loadingState is PropertiesInitial) &&
          emptyRawLoadedList.isEmpty;

      expect(emptyInitialLoad, isTrue);
    });
  });
}

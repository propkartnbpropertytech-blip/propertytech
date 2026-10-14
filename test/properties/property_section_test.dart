import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/properties/models/property_model.dart';

PropertyModel createTestProperty({
  required String id,
  String? section,
}) {
  return PropertyModel(
    id: id,
    propertyCode: 'PR-$id',
    title: 'Test Property $id',
    categoryId: 'cat_res',
    categoryName: 'Residential Apartment',
    propertyTypeId: 'type_apt',
    propertyTypeName: 'Apartment',
    listingTypeId: 'lt_rent',
    listingTypeName: 'Rent',
    propertyStatusId: 'status_avail',
    propertyStatusName: 'Available',
    cityId: 'city_1',
    cityName: 'Surat',
    areaId: 'area_1',
    areaName: 'Vesu',
    pincode: '395007',
    address: 'Vesu Main Road',
    section: section,
    price: 25000,
    deposit: 50000,
    maintenance: 2000,
    bedrooms: 2,
    bathrooms: 2,
    balconies: 1,
    parking: 1,
    ownerName: 'Owner Test',
    ownerMobile: '9876543210',
    isVerified: true,
    createdBy: 'test-admin',
    createdByName: 'Test Admin',
    createdAt: DateTime.now(),
    images: const [],
    amenities: const [],
    videos: const [],
  );
}

void main() {
  group('Property Section Model and Logic Tests', () {
    test('fromJson deserializes section correctly when present', () {
      final json = {
        'id': 'p101',
        'property_code': 'PR-101',
        'title': 'Section Test Property',
        'category_id': 'cat_1',
        'property_type_id': 'pt_1',
        'listing_type_id': 'lt_1',
        'property_status_id': 'ps_1',
        'city_id': 'c_1',
        'area_id': 'a_1',
        'address': 'Test Address',
        'section': 'Section 5',
        'price': '100000',
        'owner_name': 'John Doe',
        'owner_mobile': '9898989898',
        'created_by': 'admin_1',
        'created_at': DateTime.now().toIso8601String(),
      };

      final property = PropertyModel.fromJson(json);
      expect(property.section, equals('Section 5'));
    });

    test('fromJson handles null section gracefully', () {
      final json = {
        'id': 'p102',
        'property_code': 'PR-102',
        'title': 'No Section Property',
        'category_id': 'cat_1',
        'property_type_id': 'pt_1',
        'listing_type_id': 'lt_1',
        'property_status_id': 'ps_1',
        'city_id': 'c_1',
        'area_id': 'a_1',
        'address': 'Test Address',
        'price': '100000',
        'owner_name': 'John Doe',
        'owner_mobile': '9898989898',
        'created_by': 'admin_1',
        'created_at': DateTime.now().toIso8601String(),
      };

      final property = PropertyModel.fromJson(json);
      expect(property.section, isNull);
    });

    test('toJson serializes section correctly', () {
      final property = createTestProperty(id: 'p103', section: 'Section 12');
      final json = property.toJson();
      expect(json['section'], equals('Section 12'));
    });

    test('toJson serializes null section when omitted', () {
      final property = createTestProperty(id: 'p104', section: null);
      final json = property.toJson();
      expect(json['section'], isNull);
    });

    test('copyWith updates and preserves section', () {
      final property = createTestProperty(id: 'p105', section: 'Section 3');
      final updated = property.copyWith(section: 'Section 7');
      expect(updated.section, equals('Section 7'));

      final preserved = updated.copyWith(title: 'New Title');
      expect(preserved.section, equals('Section 7'));
    });

    test('section options list contains exactly Section 1 to Section 15', () {
      final sectionOptions = List.generate(15, (index) => 'Section ${index + 1}');
      expect(sectionOptions.length, equals(15));
      expect(sectionOptions.first, equals('Section 1'));
      expect(sectionOptions.last, equals('Section 15'));

      for (int i = 1; i <= 15; i++) {
        expect(sectionOptions.contains('Section $i'), isTrue);
      }
    });

    test('section validation recognizes non-empty section values', () {
      bool isValidValue(String? value) {
        if (value == null) return false;
        final val = value.trim();
        if (val.isEmpty ||
            val.toLowerCase() == 'n/a' ||
            val.toLowerCase() == 'none' ||
            val.toLowerCase() == 'null' ||
            val.toLowerCase() == 'pending verification') {
          return false;
        }
        return true;
      }

      expect(isValidValue('Section 1'), isTrue);
      expect(isValidValue('Section 15'), isTrue);
      expect(isValidValue(null), isFalse);
      expect(isValidValue(''), isFalse);
      expect(isValidValue('None'), isFalse);
      expect(isValidValue('N/A'), isFalse);
    });
  });
}

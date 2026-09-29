import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/properties/screens/properties_screen.dart';

PropertyModel createTestProperty({
  required String id,
  required String code,
  required DateTime createdAt,
  String listingTypeName = 'Rent',
  String categoryName = 'Residential Apartment',
  int bedrooms = 2,
  double price = 25000,
}) {
  return PropertyModel(
    id: id,
    propertyCode: code,
    title: 'Test Property $code',
    categoryId: 'cat_res',
    categoryName: categoryName,
    propertyTypeId: 'type_apt',
    propertyTypeName: 'Apartment',
    listingTypeId: 'lt_rent',
    listingTypeName: listingTypeName,
    propertyStatusId: 'status_avail',
    propertyStatusName: 'Available',
    cityId: 'city_1',
    cityName: 'Mumbai',
    areaId: 'area_1',
    areaName: 'Andheri',
    pincode: '400053',
    address: 'Andheri West',
    price: price,
    deposit: 50000,
    maintenance: 2000,
    bedrooms: bedrooms,
    bathrooms: 2,
    balconies: 1,
    parking: 1,
    ownerName: 'Owner Test',
    ownerMobile: '9876543210',
    isVerified: true,
    createdBy: 'user_1',
    createdByName: 'Admin',
    createdAt: createdAt,
    images: const [],
    amenities: const [],
    videos: const [],
  );
}

void main() {
  group('Property Date Filter Tests', () {
    final now = DateTime.now();
    final todayProp = createTestProperty(
      id: 'p1',
      code: 'PR-TODAY',
      createdAt: now,
    );
    final yesterdayProp = createTestProperty(
      id: 'p2',
      code: 'PR-YEST',
      createdAt: now.subtract(const Duration(days: 1)),
    );
    final fiveDaysAgoProp = createTestProperty(
      id: 'p3',
      code: 'PR-5DAYS',
      createdAt: now.subtract(const Duration(days: 5)),
    );
    final twoMonthsAgoProp = createTestProperty(
      id: 'p4',
      code: 'PR-2MONTHS',
      createdAt: now.subtract(const Duration(days: 60)),
    );

    final allProperties = [todayProp, yesterdayProp, fiveDaysAgoProp, twoMonthsAgoProp];

    test('PropertyDateFilterPreset enum defines all 6 presets', () {
      expect(PropertyDateFilterPreset.values.length, equals(6));
      expect(PropertyDateFilterPreset.values, contains(PropertyDateFilterPreset.today));
      expect(PropertyDateFilterPreset.values, contains(PropertyDateFilterPreset.yesterday));
      expect(PropertyDateFilterPreset.values, contains(PropertyDateFilterPreset.last7Days));
      expect(PropertyDateFilterPreset.values, contains(PropertyDateFilterPreset.thisMonth));
      expect(PropertyDateFilterPreset.values, contains(PropertyDateFilterPreset.customRange));
      expect(PropertyDateFilterPreset.values, contains(PropertyDateFilterPreset.allTime));
    });

    test('All Time preset matches all properties', () {
      final matchesAll = allProperties.where((p) => p.createdAt.isBefore(DateTime(2099))).length;
      expect(matchesAll, equals(4));
    });

    test('Today preset matches only today created properties', () {
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      final todayMatches = allProperties.where((p) {
        final d = p.createdAt.toLocal();
        return !d.isBefore(todayStart) && !d.isAfter(todayEnd);
      }).toList();

      expect(todayMatches.length, equals(1));
      expect(todayMatches.first.id, equals('p1'));
    });

    test('Yesterday preset matches only yesterday created properties', () {
      final todayStart = DateTime(now.year, now.month, now.day);
      final yestStart = todayStart.subtract(const Duration(days: 1));
      final yestEnd = DateTime(yestStart.year, yestStart.month, yestStart.day, 23, 59, 59, 999);
      final yestMatches = allProperties.where((p) {
        final d = p.createdAt.toLocal();
        return !d.isBefore(yestStart) && !d.isAfter(yestEnd);
      }).toList();

      expect(yestMatches.length, equals(1));
      expect(yestMatches.first.id, equals('p2'));
    });

    test('Last 7 Days preset matches properties created within 7 days', () {
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      final start = todayStart.subtract(const Duration(days: 6));
      final last7Matches = allProperties.where((p) {
        final d = p.createdAt.toLocal();
        return !d.isBefore(start) && !d.isAfter(todayEnd);
      }).toList();

      expect(last7Matches.length, equals(3));
      expect(last7Matches.map((p) => p.id), containsAll(['p1', 'p2', 'p3']));
    });

    test('Custom Range preset accurately filters date interval', () {
      final customStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 3));
      final customEnd = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
      final customMatches = allProperties.where((p) {
        final d = p.createdAt.toLocal();
        return !d.isBefore(customStart) && !d.isAfter(customEnd);
      }).toList();

      expect(customMatches.length, equals(2));
      expect(customMatches.map((p) => p.id), containsAll(['p1', 'p2']));
    });
  });
}

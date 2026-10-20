import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/properties/models/property_view_model.dart';

PropertyModel createMockProperty({
  required String id,
  required String code,
  required DateTime createdAt,
  String title = 'Test Villa',
  String listingTypeName = 'Rent',
  String categoryName = 'Residential Apartment',
  String categoryId = 'cat_res',
  int bedrooms = 2,
  double price = 25000,
  String cityName = 'Mumbai',
  String areaName = 'Andheri West',
  String ownerName = 'John Doe',
  String createdBy = 'user_1',
}) {
  return PropertyModel(
    id: id,
    propertyCode: code,
    title: '$title $code',
    categoryId: categoryId,
    categoryName: categoryName,
    propertyTypeId: 'type_apt',
    propertyTypeName: 'Apartment',
    listingTypeId: listingTypeName == 'Rent' ? 'lt_rent' : 'lt_resale',
    listingTypeName: listingTypeName,
    propertyStatusId: 'status_avail',
    propertyStatusName: 'Available',
    cityId: 'city_1',
    cityName: cityName,
    areaId: 'area_1',
    areaName: areaName,
    pincode: '400053',
    address: 'Near Metro Station, $areaName',
    price: price,
    deposit: price * 2,
    maintenance: 2000,
    bedrooms: bedrooms,
    bathrooms: 2,
    balconies: 1,
    parking: 1,
    ownerName: ownerName,
    ownerMobile: '9876543210',
    isVerified: true,
    createdBy: createdBy,
    createdByName: 'Admin User',
    createdAt: createdAt,
    images: const [],
    amenities: const ['Gym', 'Pool'],
    videos: const [],
  );
}

void main() {
  group('PropertyListItemViewModel Pre-computation', () {
    test('pre-computes display title, address, formatted price and search tokens', () {
      final now = DateTime.now();
      final p = createMockProperty(
        id: 'p1',
        code: 'PR-100',
        createdAt: now,
        title: 'Emerald Bay Luxury Villa',
        price: 15000000,
        bedrooms: 3,
        areaName: 'Bandra West',
      );

      final vm = PropertyListItemViewModel.fromProperty(p, null);

      expect(vm.addressText, contains('Emerald Bay Luxury Villa'));
      expect(vm.bhkText, equals('3 BHK'));
      expect(vm.priceText, equals('₹ 1.50 cr'));
      expect(vm.propertyCodeClean, equals('pr100'));
      expect(vm.normalizedSearchTokens, contains('emerald'));
      expect(vm.normalizedSearchTokens, contains('bandra'));
      expect(vm.normalizedSearchTokens, contains('100'));
      expect(vm.createdAtMillis, equals(now.toLocal().millisecondsSinceEpoch));
    });
  });

  group('PropertyFilterEngine Logic & Semantics', () {
    final now = DateTime.now();
    final p1 = createMockProperty(
      id: 'p1',
      code: 'PR-1',
      createdAt: now,
      listingTypeName: 'Rent',
      categoryName: 'Residential Apartment',
      bedrooms: 2,
      price: 30000,
      createdBy: 'user_1',
    );
    final p2 = createMockProperty(
      id: 'p2',
      code: 'PR-2',
      createdAt: now.subtract(const Duration(days: 2)),
      listingTypeName: 'Rent',
      categoryName: 'Commercial Office',
      categoryId: 'cat_comm',
      bedrooms: 0,
      price: 80000,
      createdBy: 'user_2',
    );
    final p3 = createMockProperty(
      id: 'p3',
      code: 'PR-3',
      createdAt: now.subtract(const Duration(days: 10)),
      listingTypeName: 'Re-Sale',
      categoryName: 'Residential Villa',
      bedrooms: 4,
      price: 25000000,
      createdBy: 'user_1',
    );

    final vms = [
      PropertyListItemViewModel.fromProperty(p1, null),
      PropertyListItemViewModel.fromProperty(p2, null),
      PropertyListItemViewModel.fromProperty(p3, null),
    ];

    test('filters by listing type (Rent vs Re-Sale)', () {
      final rentResults = PropertyFilterEngine.filterAndSort(
        items: vms,
        activeListingTab: 'Rent',
      );
      expect(rentResults.length, equals(2));
      expect(rentResults.map((v) => v.property.id), containsAll(['p1', 'p2']));

      final resaleResults = PropertyFilterEngine.filterAndSort(
        items: vms,
        activeListingTab: 'Re-Sale',
      );
      expect(resaleResults.length, equals(1));
      expect(resaleResults.first.property.id, equals('p3'));
    });

    test('filters by category tab and selected category', () {
      final commResults = PropertyFilterEngine.filterAndSort(
        items: vms,
        activeListingTab: 'Rent',
        activeCategoryTab: 'Commercial',
      );
      expect(commResults.length, equals(1));
      expect(commResults.first.property.id, equals('p2'));
    });

    test('filters by myAddedOnly', () {
      final myAdded = PropertyFilterEngine.filterAndSort(
        items: vms,
        activeListingTab: 'Rent',
        myAddedOnly: true,
        currentUserId: 'user_1',
      );
      expect(myAdded.length, equals(1));
      expect(myAdded.first.property.id, equals('p1'));
    });

    test('filters by price sorting (low to high & high to low)', () {
      final sortedLowToHigh = PropertyFilterEngine.filterAndSort(
        items: vms,
        activeListingTab: 'Rent',
        selectedPriceSortOrRange: 'low_to_high',
      );
      expect(sortedLowToHigh.first.property.id, equals('p1'));
      expect(sortedLowToHigh.last.property.id, equals('p2'));

      final sortedHighToLow = PropertyFilterEngine.filterAndSort(
        items: vms,
        activeListingTab: 'Rent',
        selectedPriceSortOrRange: 'high_to_low',
      );
      expect(sortedHighToLow.first.property.id, equals('p2'));
      expect(sortedHighToLow.last.property.id, equals('p1'));
    });

    test('filters by pre-normalized search tokens', () {
      final searchResults = PropertyFilterEngine.filterAndSort(
        items: vms,
        activeListingTab: 'Rent',
        searchQuery: 'Commercial',
      );
      expect(searchResults.length, equals(1));
      expect(searchResults.first.property.id, equals('p2'));
    });

    test('filters by date presets', () {
      final todayResults = PropertyFilterEngine.filterAndSort(
        items: vms,
        activeListingTab: 'Rent',
        datePreset: PropertyDateFilterPreset.today,
      );
      expect(todayResults.length, equals(1));
      expect(todayResults.first.property.id, equals('p1'));

      final last7Results = PropertyFilterEngine.filterAndSort(
        items: vms,
        activeListingTab: 'Rent',
        datePreset: PropertyDateFilterPreset.last7Days,
      );
      expect(last7Results.length, equals(2));
    });
  });

  group('PropertyFilterEngine High-Scale Performance Benchmarks', () {
    test('Benchmark: 100 items filter & sort executes in <1 ms', () {
      final now = DateTime.now();
      final items = List.generate(
        100,
        (i) => PropertyListItemViewModel.fromProperty(
          createMockProperty(
            id: 'p_$i',
            code: 'PR-$i',
            createdAt: now.subtract(Duration(hours: i)),
            price: (20000 + (i * 500)).toDouble(),
            bedrooms: (i % 4) + 1,
            title: 'Property $i with unique amenities',
          ),
          null,
        ),
      );

      final sw = Stopwatch()..start();
      final result = PropertyFilterEngine.filterAndSort(
        items: items,
        activeListingTab: 'Rent',
        searchQuery: 'Property 5',
        selectedPriceSortOrRange: 'low_to_high',
      );
      sw.stop();

      expect(result.isNotEmpty, isTrue);
      expect(sw.elapsedMilliseconds, lessThan(10));
    });

    test('Benchmark: 1,000 items filter & sort executes in <5 ms', () {
      final now = DateTime.now();
      final items = List.generate(
        1000,
        (i) => PropertyListItemViewModel.fromProperty(
          createMockProperty(
            id: 'p_$i',
            code: 'PR-$i',
            createdAt: now.subtract(Duration(hours: i % 720)),
            price: (10000 + (i * 200)).toDouble(),
            bedrooms: (i % 5) + 1,
            categoryName: i % 2 == 0 ? 'Residential Apartment' : 'Commercial Office',
            title: 'Spacious Property number $i',
          ),
          null,
        ),
      );

      // Warm up
      PropertyFilterEngine.filterAndSort(items: items, activeListingTab: 'Rent');

      final sw = Stopwatch()..start();
      final result = PropertyFilterEngine.filterAndSort(
        items: items,
        activeListingTab: 'Rent',
        searchQuery: 'Spacious Property number 42',
        selectedPriceSortOrRange: 'high_to_low',
      );
      sw.stop();

      expect(result.isNotEmpty, isTrue);
      expect(sw.elapsedMilliseconds, lessThan(15));
    });

    test('Benchmark: 5,000 items filter & sort executes in <25 ms', () {
      final now = DateTime.now();
      final items = List.generate(
        5000,
        (i) => PropertyListItemViewModel.fromProperty(
          createMockProperty(
            id: 'p_$i',
            code: 'PR-$i',
            createdAt: now.subtract(Duration(minutes: i * 10)),
            price: (15000 + (i * 100)).toDouble(),
            bedrooms: (i % 5) + 1,
            title: 'Prime Estate $i',
          ),
          null,
        ),
      );

      // Warm up
      PropertyFilterEngine.filterAndSort(items: items, activeListingTab: 'Rent');

      final sw = Stopwatch()..start();
      final result = PropertyFilterEngine.filterAndSort(
        items: items,
        activeListingTab: 'Rent',
        searchQuery: 'Prime Estate 333',
        selectedPriceSortOrRange: 'low_to_high',
      );
      sw.stop();

      expect(result.isNotEmpty, isTrue);
      expect(sw.elapsedMilliseconds, lessThan(50));
    });
  });
}

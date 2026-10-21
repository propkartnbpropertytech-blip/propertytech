import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/properties/models/property_view_model.dart';

PropertyModel _createTestProperty({
  required String id,
  required String code,
  required String listingTypeName,
  required String categoryName,
  required String propertyTypeName,
  required int bedrooms,
  required double price,
  required String areaName,
  required String areaId,
  required String createdBy,
  required String statusName,
  required List<String> images,
  String? furnishingName,
  DateTime? createdAt,
}) {
  final now = createdAt ?? DateTime.now();
  return PropertyModel(
    id: id,
    propertyCode: code,
    title: '$bedrooms BHK in $areaName',
    categoryId: 'cat_${categoryName.toLowerCase()}',
    categoryName: categoryName,
    propertyTypeId: 'type_1',
    propertyTypeName: propertyTypeName,
    listingTypeId: listingTypeName == 'Rent' ? 'lt_rent' : 'lt_resale',
    listingTypeName: listingTypeName,
    propertyStatusId: 'status_1',
    propertyStatusName: statusName,
    cityId: 'city_1',
    cityName: 'Mumbai',
    areaId: areaId,
    areaName: areaName,
    pincode: '400001',
    address: 'Near Station, $areaName',
    price: price,
    deposit: price * 2,
    maintenance: 1000,
    bedrooms: bedrooms,
    bathrooms: bedrooms,
    balconies: 1,
    parking: 1,
    furnishingTypeName: furnishingName,
    ownerName: 'Owner of $code',
    ownerMobile: '9999988888',
    isVerified: true,
    createdBy: createdBy,
    createdByName: 'Agent $createdBy',
    createdAt: now,
    images: images,
    amenities: const ['Lift', 'Security'],
    videos: const [],
  );
}

void main() {
  group('Property Filter Reactivity & Toggle Tests', () {
    final now = DateTime.now();

    final pRentResWithPhotos = _createTestProperty(
      id: 'p1',
      code: 'PR-001',
      listingTypeName: 'Rent',
      categoryName: 'Residential Apartment',
      propertyTypeName: 'Apartment',
      bedrooms: 2,
      price: 25000,
      areaName: 'Andheri West',
      areaId: 'area_andheri',
      createdBy: 'user_me',
      statusName: 'Available',
      furnishingName: 'Furnished',
      images: ['https://example.com/img1.jpg'],
      createdAt: now,
    );

    final pRentResNoPhotos = _createTestProperty(
      id: 'p2',
      code: 'PR-002',
      listingTypeName: 'Rent',
      categoryName: 'Residential Apartment',
      propertyTypeName: 'Apartment',
      bedrooms: 3,
      price: 45000,
      areaName: 'Bandra West',
      areaId: 'area_bandra',
      createdBy: 'user_other',
      statusName: 'Available',
      furnishingName: 'Unfurnished',
      images: [],
      createdAt: now.subtract(const Duration(days: 2)),
    );

    final pResaleRes = _createTestProperty(
      id: 'p3',
      code: 'PR-003',
      listingTypeName: 'Re-Sale',
      categoryName: 'Residential Villa',
      propertyTypeName: 'Villa',
      bedrooms: 4,
      price: 25000000,
      areaName: 'Andheri West',
      areaId: 'area_andheri',
      createdBy: 'user_me',
      statusName: 'Sold',
      furnishingName: 'Semi-Furnished',
      images: ['https://example.com/villa.jpg'],
      createdAt: now.subtract(const Duration(days: 10)),
    );

    final pCommercialRent = _createTestProperty(
      id: 'p4',
      code: 'PR-004',
      listingTypeName: 'Rent',
      categoryName: 'Commercial Office',
      propertyTypeName: 'Office Space',
      bedrooms: 0,
      price: 80000,
      areaName: 'BKC',
      areaId: 'area_bkc',
      createdBy: 'user_other',
      statusName: 'Available',
      furnishingName: 'Furnished',
      images: ['https://example.com/office.jpg'],
      createdAt: now,
    );

    final allProperties = [
      pRentResWithPhotos,
      pRentResNoPhotos,
      pResaleRes,
      pCommercialRent,
    ];

    final viewModels = allProperties
        .map((p) => PropertyListItemViewModel.fromProperty(p, null))
        .toList();

    test('1. Listing type toggle (Rent vs Re-Sale) reacts immediately', () {
      final rentList = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
      );
      expect(rentList.map((vm) => vm.property.id), containsAll(['p1', 'p2', 'p4']));
      expect(rentList.map((vm) => vm.property.id), isNot(contains('p3')));

      final resaleList = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Re-Sale',
      );
      expect(resaleList.map((vm) => vm.property.id), contains('p3'));
      expect(resaleList.map((vm) => vm.property.id), isNot(contains('p1')));
      expect(resaleList.map((vm) => vm.property.id), isNot(contains('p2')));
      expect(resaleList.map((vm) => vm.property.id), isNot(contains('p4')));
    });

    test('2. Category tab toggle (Residential vs Commercial) filters correctly', () {
      final resList = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        activeCategoryTab: 'Residential',
      );
      expect(resList.map((vm) => vm.property.id), containsAll(['p1', 'p2']));
      expect(resList.map((vm) => vm.property.id), isNot(contains('p4')));

      final commList = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        activeCategoryTab: 'Commercial',
      );
      expect(commList.map((vm) => vm.property.id), contains('p4'));
      expect(commList.map((vm) => vm.property.id), isNot(contains('p1')));
      expect(commList.map((vm) => vm.property.id), isNot(contains('p2')));
    });

    test('3. My Added toggle isolates properties created by current user', () {
      final myOnly = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        myAddedOnly: true,
        currentUserId: 'user_me',
      );
      expect(myOnly.map((vm) => vm.property.id), equals(['p1']));

      final allRent = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        myAddedOnly: false,
        currentUserId: 'user_me',
      );
      expect(allRent.length, equals(3));
    });

    test('4. Archive toggle isolates archived vs active properties', () {
      final archivedIds = {'p1'};

      final activeOnly = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        archiveTabOnly: false,
        archivedPropertyIds: archivedIds,
      );
      expect(activeOnly.map((vm) => vm.property.id), isNot(contains('p1')));
      expect(activeOnly.map((vm) => vm.property.id), containsAll(['p2', 'p4']));

      final archivedOnly = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        archiveTabOnly: true,
        archivedPropertyIds: archivedIds,
      );
      expect(archivedOnly.map((vm) => vm.property.id), equals(['p1']));
    });

    test('5. Photo presence toggle (with_images vs no_images)', () {
      final withPhotos = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        imageFilter: 'with_images',
      );
      expect(withPhotos.map((vm) => vm.property.id), containsAll(['p1', 'p4']));
      expect(withPhotos.map((vm) => vm.property.id), isNot(contains('p2')));

      final noPhotos = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        imageFilter: 'no_images',
        noImagesOnly: true,
      );
      expect(noPhotos.map((vm) => vm.property.id), equals(['p2']));
    });

    test('6. Area filter matches by selectedAreas', () {
      final bandraOnly = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        selectedAreas: {'area_bandra'},
      );
      expect(bandraOnly.map((vm) => vm.property.id), equals(['p2']));

      final andheriOnly = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        selectedAreas: {'Andheri West'},
      );
      expect(andheriOnly.map((vm) => vm.property.id), equals(['p1']));
    });

    test('7. BHK filter and Furnishing filter react accurately', () {
      final twoBhk = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        activeBhkFilter: '2 BHK',
      );
      expect(twoBhk.map((vm) => vm.property.id), equals(['p1']));

      final furnished = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        selectedFurnishingFilter: 'Furnished',
      );
      expect(furnished.map((vm) => vm.property.id), containsAll(['p1', 'p4']));
      expect(furnished.map((vm) => vm.property.id), isNot(contains('p2')));
    });

    test('8. Status filter matches available vs sold', () {
      final available = PropertyFilterEngine.filterAndSort(
        items: viewModels,
        activeListingTab: 'Rent',
        selectedStatusFilter: 'Available',
      );
      expect(available.map((vm) => vm.property.id), containsAll(['p1', 'p2', 'p4']));
    });

    test('9. Execution benchmark: 1,000 items filter in < 5 ms', () {
      final largeList = List.generate(1000, (i) {
        final isRent = i % 2 == 0;
        return PropertyListItemViewModel.fromProperty(
          _createTestProperty(
            id: 'p_$i',
            code: 'PR-$i',
            listingTypeName: isRent ? 'Rent' : 'Re-Sale',
            categoryName: i % 3 == 0 ? 'Residential Apartment' : 'Commercial Office',
            propertyTypeName: 'Apartment',
            bedrooms: ((i ~/ 2) % 4) + 1,
            price: 20000.0 + (i * 100),
            areaName: 'Area ${i % 10}',
            areaId: 'area_${i % 10}',
            createdBy: 'user_${i % 5}',
            statusName: 'Available',
            furnishingName: i % 2 == 0 ? 'Furnished' : 'Unfurnished',
            images: i % 3 == 0 ? ['https://example.com/$i.jpg'] : [],
            createdAt: now.subtract(Duration(hours: i)),
          ),
          null,
        );
      });

      final stopwatch = Stopwatch()..start();
      final filtered = PropertyFilterEngine.filterAndSort(
        items: largeList,
        activeListingTab: 'Rent',
        activeCategoryTab: 'Residential',
        activeBhkFilter: '2 BHK',
        imageFilter: 'with_images',
        selectedFurnishingFilter: 'Furnished',
      );
      stopwatch.stop();

      expect(filtered.isNotEmpty, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
    });
  });
}

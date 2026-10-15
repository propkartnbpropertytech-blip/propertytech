import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/properties/widgets/property_kpi_summary_bar.dart';
import 'package:propkart/features/dashboard/widgets/stat_card.dart';

PropertyModel buildTestProperty({
  required String id,
  required String code,
  required String listingTypeName,
  required String propertyStatusName,
  String categoryName = 'Residential',
}) {
  return PropertyModel(
    id: id,
    propertyCode: code,
    title: 'Test Property $code',
    categoryId: 'cat_1',
    categoryName: categoryName,
    propertyTypeId: 'type_1',
    propertyTypeName: 'Apartment',
    listingTypeId: listingTypeName == 'Rent' ? 'lt_rent' : 'lt_resale',
    listingTypeName: listingTypeName,
    propertyStatusId: propertyStatusName == 'Available' ? 'st_avail' : 'st_other',
    propertyStatusName: propertyStatusName,
    cityId: 'c1',
    cityName: 'Surat',
    areaId: 'a1',
    areaName: 'Vesu',
    pincode: '395007',
    address: 'Vesu Road',
    price: 25000,
    deposit: 50000,
    maintenance: 2000,
    bedrooms: 2,
    bathrooms: 2,
    balconies: 1,
    parking: 1,
    ownerName: 'Test Owner',
    ownerMobile: '9876543210',
    isVerified: true,
    createdBy: 'user_1',
    createdByName: 'Admin',
    createdAt: DateTime.now(),
    images: const [],
    amenities: const [],
    videos: const [],
  );
}

void main() {
  group('PropertyKpiSummaryBar KPI Counting Logic Tests', () {
    testWidgets('1. Correctly calculates Available Units, Rental Properties, and Re-Sale Properties',
        (tester) async {
      final properties = [
        // Available Rental across multiple categories
        buildTestProperty(id: '1', code: 'P1', listingTypeName: 'RENT', propertyStatusName: 'Available', categoryName: 'Residential'),
        buildTestProperty(id: '2', code: 'P2', listingTypeName: 'RENT', propertyStatusName: 'Available', categoryName: 'Commercial'),
        buildTestProperty(id: '3', code: 'P3', listingTypeName: 'RENT', propertyStatusName: 'Available', categoryName: 'Industrial'),
        
        // Non-Available Rental (e.g. Rented Out) -> Must NOT be counted in Rental Properties or Available Units
        buildTestProperty(id: '4', code: 'P4', listingTypeName: 'RENT', propertyStatusName: 'Rented Out', categoryName: 'Residential'),
        buildTestProperty(id: '5', code: 'P5', listingTypeName: 'RENT', propertyStatusName: 'Inactive', categoryName: 'Commercial'),

        // Available Re-Sale across multiple categories
        buildTestProperty(id: '6', code: 'P6', listingTypeName: 'RESALE', propertyStatusName: 'Available', categoryName: 'Residential'),
        buildTestProperty(id: '7', code: 'P7', listingTypeName: 'RESALE', propertyStatusName: 'Available', categoryName: 'Land & Plot'),

        // Non-Available Re-Sale (e.g. Sold Out) -> Must NOT be counted in Re-Sale Properties or Available Units
        buildTestProperty(id: '8', code: 'P8', listingTypeName: 'RESALE', propertyStatusName: 'Sold Out', categoryName: 'Residential'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PropertyKpiSummaryBar(
                properties: properties,
                activeListingTab: 'Rent',
                onListingTabChanged: (_) {},
                myAddedOnly: false,
                onToggleMyAdded: () {},
              ),
            ),
          ),
        ),
      );

      // Verify StatCards
      final statCards = tester.widgetList<StatCard>(find.byType(StatCard)).toList();
      expect(statCards.length, greaterThanOrEqualTo(3));

      // Card 1: Available Units -> 3 Available Rental + 2 Available Re-Sale = 5
      final availableUnitsCard = statCards.firstWhere((c) => c.title == 'Available Units');
      expect(availableUnitsCard.value, '5');

      // Card 2: Rental Properties -> Only Available Rental = 3 (excludes 2 Rented Out/Inactive)
      final rentalCard = statCards.firstWhere((c) => c.title == 'Rental Properties');
      expect(rentalCard.value, '3');

      // Card 3: Re-Sale Properties -> Only Available Re-Sale = 2 (excludes 1 Sold Out)
      final resaleCard = statCards.firstWhere((c) => c.title == 'Re-Sale Properties');
      expect(resaleCard.value, '2');
    });

    testWidgets('2. Verified ground truth numbers matching local database', (tester) async {
      // 133 Available Rental, 15 Rented Out Rental
      // 21 Available Re-Sale, 2 Sold Out Re-Sale
      // Total Available = 133 + 21 = 154
      // Total portfolio = 133 + 15 + 21 + 2 = 171
      final mockPortfolio = <PropertyModel>[];
      for (int i = 0; i < 133; i++) {
        mockPortfolio.add(buildTestProperty(id: 'r_avail_$i', code: 'RA$i', listingTypeName: 'RENT', propertyStatusName: 'Available'));
      }
      for (int i = 0; i < 15; i++) {
        mockPortfolio.add(buildTestProperty(id: 'r_out_$i', code: 'RO$i', listingTypeName: 'RENT', propertyStatusName: 'Rented Out'));
      }
      for (int i = 0; i < 21; i++) {
        mockPortfolio.add(buildTestProperty(id: 's_avail_$i', code: 'SA$i', listingTypeName: 'RESALE', propertyStatusName: 'Available'));
      }
      for (int i = 0; i < 2; i++) {
        mockPortfolio.add(buildTestProperty(id: 's_sold_$i', code: 'SS$i', listingTypeName: 'RESALE', propertyStatusName: 'Sold Out'));
      }

      expect(mockPortfolio.length, 171);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PropertyKpiSummaryBar(
                properties: mockPortfolio,
                activeListingTab: 'Rent',
                onListingTabChanged: (_) {},
                myAddedOnly: false,
                onToggleMyAdded: () {},
              ),
            ),
          ),
        ),
      );

      final statCards = tester.widgetList<StatCard>(find.byType(StatCard)).toList();

      final availableUnitsCard = statCards.firstWhere((c) => c.title == 'Available Units');
      expect(availableUnitsCard.value, '154');
      expect(availableUnitsCard.subtitle, '171 total in portfolio');

      final rentalCard = statCards.firstWhere((c) => c.title == 'Rental Properties');
      expect(rentalCard.value, '133');

      final resaleCard = statCards.firstWhere((c) => c.title == 'Re-Sale Properties');
      expect(resaleCard.value, '21');
    });
  });
}

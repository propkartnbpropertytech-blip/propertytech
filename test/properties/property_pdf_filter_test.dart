import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/properties/models/property_pdf_filter_config.dart';
import 'package:propkart/features/requirements/utils/property_share_pdf.dart';

PropertyModel createMockProperty({
  required String id,
  required String code,
  required String title,
  double price = 15000000,
  double deposit = 500000,
  int bedrooms = 3,
  int bathrooms = 3,
  int balconies = 2,
  double superBuiltupArea = 2200,
  double carpetArea = 1800,
  String address = 'Near Central Park',
  String areaName = 'Vastrapur',
  String cityName = 'Ahmedabad',
  List<String> amenities = const ['Swimming Pool', 'Gym', 'Clubhouse'],
}) {
  return PropertyModel(
    id: id,
    propertyCode: code,
    title: title,
    categoryId: 'cat_res',
    categoryName: 'Residential',
    propertyTypeId: 'type_apt',
    propertyTypeName: 'Apartment',
    listingTypeId: 'lt_sale',
    listingTypeName: 'Sale',
    propertyStatusId: 'status_avail',
    propertyStatusName: 'Available',
    cityId: 'city_1',
    cityName: cityName,
    areaId: 'area_1',
    areaName: areaName,
    pincode: '380015',
    address: address,
    price: price,
    deposit: deposit,
    maintenance: 3000,
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    balconies: balconies,
    parking: 1,
    superBuiltupArea: superBuiltupArea,
    carpetArea: carpetArea,
    ownerName: 'Test Owner',
    ownerMobile: '9876543210',
    isVerified: true,
    createdBy: 'admin_1',
    createdByName: 'Admin',
    createdAt: DateTime.now(),
    images: const [],
    amenities: amenities,
    videos: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PropertyPdfFilterConfig Tests', () {
    test('Default allEnabled enables all sections and fields', () {
      final config = PropertyPdfFilterConfig.allEnabled();
      for (final section in PropertyPdfFilterConfig.defaultSections) {
        expect(config.isSectionEnabled(section.id), isTrue);
        for (final field in section.fields) {
          expect(config.isFieldEnabled(field.id), isTrue);
        }
      }
    });

    test('Disabling a section automatically disables all its fields', () {
      final config = PropertyPdfFilterConfig(
        enabledSections: {'overview'},
        enabledFields: {'overview_title', 'basic_price', 'loc_city'},
        enabledAmenities: {},
      );

      // Section enabled
      expect(config.isSectionEnabled('overview'), isTrue);
      expect(config.isFieldEnabled('overview_title'), isTrue);

      // Section disabled -> field must return false even if in enabledFields set
      expect(config.isSectionEnabled('basic_details'), isFalse);
      expect(config.isFieldEnabled('basic_price'), isFalse);

      expect(config.isSectionEnabled('location'), isFalse);
      expect(config.isFieldEnabled('loc_city'), isFalse);
    });

    test('Disabling individual field keeps section enabled', () {
      final config = PropertyPdfFilterConfig(
        enabledSections: {'basic_details'},
        enabledFields: {'basic_property_code'}, // basic_price omitted
        enabledAmenities: {},
      );

      expect(config.isSectionEnabled('basic_details'), isTrue);
      expect(config.isFieldEnabled('basic_property_code'), isTrue);
      expect(config.isFieldEnabled('basic_price'), isFalse);
    });

    test('Amenities filter correctly requires amenities section', () {
      final config = PropertyPdfFilterConfig(
        enabledSections: {'amenities'},
        enabledFields: {'amenities_all'},
        enabledAmenities: {'Swimming Pool', 'Gym'},
      );

      expect(config.isAmenityEnabled('Swimming Pool'), isTrue);
      expect(config.isAmenityEnabled('Gym'), isTrue);
      expect(config.isAmenityEnabled('Clubhouse'), isFalse);

      final disabledAmenitiesConfig = PropertyPdfFilterConfig(
        enabledSections: {'overview'}, // amenities disabled
        enabledFields: {'amenities_all'},
        enabledAmenities: {'Swimming Pool'},
      );

      expect(disabledAmenitiesConfig.isAmenityEnabled('Swimming Pool'), isFalse);
    });
  });

  group('PropertySharePdf Generation Tests with Filter Config', () {
    final mockProperty = createMockProperty(
      id: 'prop-1',
      code: 'PK-1001',
      title: 'Luxury 3BHK Penthouse',
    );

    test('Option 1 builds PDF successfully with all enabled', () async {
      final config = PropertyPdfFilterConfig.allEnabled();
      final bytes = await PropertySharePdf.build(
        [mockProperty],
        templateStyle: PdfTemplateStyle.option1,
        filterConfig: config,
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Option 2 builds PDF successfully with partial filter', () async {
      final config = PropertyPdfFilterConfig(
        enabledSections: {'basic_details', 'location'},
        enabledFields: {'basic_price', 'loc_city', 'loc_area'},
        enabledAmenities: {},
      );

      final bytes = await PropertySharePdf.build(
        [mockProperty],
        templateStyle: PdfTemplateStyle.option2,
        filterConfig: config,
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
    });

    test('Multiple properties PDF builds successfully with filter applied', () async {
      final mockProperty2 = createMockProperty(
        id: 'prop-2',
        code: 'PK-1002',
        title: 'Modern 2BHK Flat',
      );

      final config = PropertyPdfFilterConfig(
        enabledSections: {'overview', 'specifications'},
        enabledFields: {'overview_title', 'specs_bedrooms'},
        enabledAmenities: {},
      );

      final bytes = await PropertySharePdf.build(
        [mockProperty, mockProperty2],
        templateStyle: PdfTemplateStyle.option1,
        filterConfig: config,
      );
      expect(bytes, isA<Uint8List>());
      expect(bytes.isNotEmpty, isTrue);
    });
  });
}

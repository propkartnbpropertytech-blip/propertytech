import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:propkart/core/design_system/widgets/crm_network_image.dart';
import 'package:propkart/features/properties/models/property_model.dart';
import 'package:propkart/features/properties/models/property_view_model.dart';

void main() {
  group('CrmImageDelivery URL Optimization', () {
    const rawCloudinaryImage =
        'https://res.cloudinary.com/propkart/image/upload/v1700000000/properties/unit_101.jpg';
    const rawCloudinaryNoVersion =
        'https://res.cloudinary.com/propkart/image/upload/properties/unit_101.png';
    const rawCloudinaryVideo =
        'https://res.cloudinary.com/propkart/video/upload/v1700000000/walkthrough.mp4';
    const externalImage = 'https://images.unsplash.com/photo-1560518883?auto=format';
    const dataUri = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

    test('isCloudinaryUrl correctly identifies Cloudinary hosts', () {
      expect(CrmImageDelivery.isCloudinaryUrl(rawCloudinaryImage), isTrue);
      expect(CrmImageDelivery.isCloudinaryUrl(rawCloudinaryNoVersion), isTrue);
      expect(CrmImageDelivery.isCloudinaryUrl(rawCloudinaryVideo), isTrue);
      expect(CrmImageDelivery.isCloudinaryUrl(externalImage), isFalse);
      expect(CrmImageDelivery.isCloudinaryUrl(dataUri), isFalse);
      expect(CrmImageDelivery.isCloudinaryUrl(''), isFalse);
      expect(CrmImageDelivery.isCloudinaryUrl('   '), isFalse);
    });

    test('transformUrl injects thumbnail transformation parameters', () {
      final transformed = CrmImageDelivery.transformUrl(
        rawCloudinaryImage,
        variant: CrmImageVariant.thumbnail,
      );
      expect(
        transformed,
        'https://res.cloudinary.com/propkart/image/upload/w_400,c_limit,q_auto,f_auto/v1700000000/properties/unit_101.jpg',
      );
    });

    test('transformUrl injects preview transformation parameters', () {
      final transformed = CrmImageDelivery.transformUrl(
        rawCloudinaryImage,
        variant: CrmImageVariant.preview,
      );
      expect(
        transformed,
        'https://res.cloudinary.com/propkart/image/upload/w_800,c_limit,q_auto,f_auto/v1700000000/properties/unit_101.jpg',
      );
    });

    test('transformUrl injects fullscreen transformation parameters', () {
      final transformed = CrmImageDelivery.transformUrl(
        rawCloudinaryImage,
        variant: CrmImageVariant.fullscreen,
      );
      expect(
        transformed,
        'https://res.cloudinary.com/propkart/image/upload/w_1920,c_limit,q_auto:good,f_auto/v1700000000/properties/unit_101.jpg',
      );
    });

    test('transformUrl preserves original URL when variant is original', () {
      final transformed = CrmImageDelivery.transformUrl(
        rawCloudinaryImage,
        variant: CrmImageVariant.original,
      );
      expect(transformed, rawCloudinaryImage);
    });

    test('transformUrl replaces existing transformations cleanly', () {
      const alreadyTransformed =
          'https://res.cloudinary.com/propkart/image/upload/w_200,h_200,c_fill/v1700000000/properties/unit_101.jpg';
      final transformed = CrmImageDelivery.transformUrl(
        alreadyTransformed,
        variant: CrmImageVariant.thumbnail,
      );
      expect(
        transformed,
        'https://res.cloudinary.com/propkart/image/upload/w_400,c_limit,q_auto,f_auto/v1700000000/properties/unit_101.jpg',
      );
    });

    test('transformUrl leaves non-Cloudinary URLs and data URIs untouched', () {
      expect(
        CrmImageDelivery.transformUrl(externalImage, variant: CrmImageVariant.thumbnail),
        externalImage,
      );
      expect(
        CrmImageDelivery.transformUrl(dataUri, variant: CrmImageVariant.thumbnail),
        dataUri,
      );
      expect(
        CrmImageDelivery.transformUrl('', variant: CrmImageVariant.thumbnail),
        '',
      );
    });

    test('transformVideoPoster converts video URL to transformed image poster', () {
      final poster = CrmImageDelivery.transformVideoPoster(
        rawCloudinaryVideo,
        variant: CrmImageVariant.preview,
      );
      expect(
        poster,
        'https://res.cloudinary.com/propkart/video/upload/w_800,c_limit,q_auto,f_jpg/v1700000000/walkthrough.jpg',
      );
    });
  });

  group('CrmImageDelivery Decode Dimension Computation', () {
    test('calculates DPR-aware pixel bounds capped at max DPR', () {
      final dims = CrmImageDelivery.getDecodeDimensions(
        logicalWidth: 100,
        logicalHeight: 80,
        devicePixelRatio: 3.5, // Above 2.5 cap
        variant: CrmImageVariant.thumbnail,
      );

      // 100 * 2.5 = 250, 80 * 2.5 = 200
      expect(dims.width, 250);
      expect(dims.height, 200);
    });

    test('clamps decode dimensions to variant maximum bounds', () {
      final dims = CrmImageDelivery.getDecodeDimensions(
        logicalWidth: 500,
        logicalHeight: 500,
        devicePixelRatio: 2.0,
        variant: CrmImageVariant.thumbnail, // Thumbnail max is 400
      );

      expect(dims.width, 400);
      expect(dims.height, 600);
    });

    test('returns null dimensions when no bounds are provided and variant is original', () {
      final dims = CrmImageDelivery.getDecodeDimensions(
        variant: CrmImageVariant.original,
      );

      expect(dims.width, isNull);
      expect(dims.height, isNull);
    });
  });

  group('PropertyListItemViewModel Image Optimization', () {
    test('precomputes optimizedThumbnailUrl for property with images', () {
      final prop = PropertyModel(
        id: 'prop-1',
        propertyCode: 'PK-1001',
        title: 'Luxury 3BHK Apartment',
        categoryId: 'cat-1',
        categoryName: 'Apartment',
        propertyTypeId: 'pt-1',
        propertyTypeName: 'Residential',
        listingTypeId: 'lt-1',
        listingTypeName: 'Sale',
        propertyStatusId: 'ps-1',
        propertyStatusName: 'Available',
        cityId: 'city-1',
        cityName: 'Mumbai',
        areaId: 'area-1',
        areaName: 'Bandra',
        pincode: '400050',
        address: 'Bandra West',
        price: 15000000,
        deposit: 0,
        maintenance: 0,
        bedrooms: 3,
        bathrooms: 3,
        balconies: 2,
        parking: 1,
        ownerName: 'John Doe',
        ownerMobile: '9876543210',
        createdBy: 'user-1',
        createdByName: 'Agent Smith',
        createdAt: DateTime.now(),
        images: [
          'https://res.cloudinary.com/propkart/image/upload/v1/properties/img1.jpg',
          'https://res.cloudinary.com/propkart/image/upload/v1/properties/img2.jpg',
        ],
        amenities: [],
        videos: [],
        isVerified: true,
      );

      final vm = PropertyListItemViewModel.fromProperty(prop, null);
      expect(
        vm.optimizedThumbnailUrl,
        'https://res.cloudinary.com/propkart/image/upload/w_400,c_limit,q_auto,f_auto/v1/properties/img1.jpg',
      );
    });

    test('optimizedThumbnailUrl is empty when property has no images', () {
      final prop = PropertyModel(
        id: 'prop-2',
        propertyCode: 'PK-1002',
        title: 'Empty Property',
        categoryId: 'cat-1',
        categoryName: 'Apartment',
        propertyTypeId: 'pt-1',
        propertyTypeName: 'Residential',
        listingTypeId: 'lt-1',
        listingTypeName: 'Sale',
        propertyStatusId: 'ps-1',
        propertyStatusName: 'Available',
        cityId: 'city-1',
        cityName: 'Mumbai',
        areaId: 'area-1',
        areaName: 'Bandra',
        pincode: '400050',
        address: 'Bandra West',
        price: 10000000,
        deposit: 0,
        maintenance: 0,
        bedrooms: 2,
        bathrooms: 2,
        balconies: 1,
        parking: 1,
        ownerName: 'Jane Doe',
        ownerMobile: '9876543211',
        createdBy: 'user-1',
        createdByName: 'Agent Smith',
        createdAt: DateTime.now(),
        images: [],
        amenities: [],
        videos: [],
        isVerified: true,
      );

      final vm = PropertyListItemViewModel.fromProperty(prop, null);
      expect(vm.optimizedThumbnailUrl, isEmpty);
    });
  });

  group('CrmNetworkImage Widget', () {
    testWidgets('renders placeholder when url is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CrmNetworkImage(
              url: '',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('renders custom error widget when provided and url is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrmNetworkImage(
              url: '',
              width: 100,
              height: 100,
              error: (context) => const Text('Custom Error Indicator'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Error Indicator'), findsOneWidget);
    });
  });
}

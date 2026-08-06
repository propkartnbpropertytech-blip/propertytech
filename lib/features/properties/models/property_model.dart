import 'package:intl/intl.dart';

class PropertyModel {
  final String id;
  final String propertyCode;
  final String title;
  final String? description;
  final String categoryId;
  final String categoryName;
  final String propertyTypeId;
  final String propertyTypeName;
  final String? configurationId;
  final String? configurationName;
  final String listingTypeId;
  final String listingTypeName;
  final String propertyStatusId;
  final String propertyStatusName;
  final String cityId;
  final String cityName;
  final String areaId;
  final String areaName;
  final String pincode;
  final String address;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final double? superBuiltupArea;
  final double? carpetArea;
  final double? plotArea;
  final double price;
  final double deposit;
  final double maintenance;
  final String? furnishingTypeId;
  final String? furnishingTypeName;
  final String? facingTypeId;
  final String? facingTypeName;
  final String? ownershipTypeId;
  final String? ownershipTypeName;
  final int bedrooms;
  final int bathrooms;
  final int balconies;
  final int parking;
  final int? floorNo;
  final int? totalFloor;
  final int? ageOfProperty;
  final DateTime? possessionDate;
  final String ownerName;
  final String ownerMobile;
  final String? brokerName;
  final String? remarks;
  final String? blockWing;
  final String? flatNo;
  final String? googlePlaceId;
  final String? brokerageTypeId;
  final String? brokerageTypeName;
  final String? adminId;
  final String? organizationId;
  final bool isVerified;
  final String createdBy;
  final String createdByName;
  final DateTime createdAt;
  final List<String> images;
  final List<String> amenities;
  final List<String> videos;
  final Map<String, dynamic>? additionalDetails;

  PropertyModel({
    required this.id,
    required this.propertyCode,
    required this.title,
    this.description,
    required this.categoryId,
    required this.categoryName,
    required this.propertyTypeId,
    required this.propertyTypeName,
    this.configurationId,
    this.configurationName,
    required this.listingTypeId,
    required this.listingTypeName,
    required this.propertyStatusId,
    required this.propertyStatusName,
    required this.cityId,
    required this.cityName,
    required this.areaId,
    required this.areaName,
    required this.pincode,
    required this.address,
    this.landmark,
    this.latitude,
    this.longitude,
    this.superBuiltupArea,
    this.carpetArea,
    this.plotArea,
    required this.price,
    required this.deposit,
    required this.maintenance,
    this.furnishingTypeId,
    this.furnishingTypeName,
    this.facingTypeId,
    this.facingTypeName,
    this.ownershipTypeId,
    this.ownershipTypeName,
    required this.bedrooms,
    required this.bathrooms,
    required this.balconies,
    required this.parking,
    this.floorNo,
    this.totalFloor,
    this.ageOfProperty,
    this.possessionDate,
    required this.ownerName,
    required this.ownerMobile,
    this.brokerName,
    this.remarks,
    this.blockWing,
    this.flatNo,
    required this.isVerified,
    required this.createdBy,
    required this.createdByName,
    required this.createdAt,
    required this.images,
    required this.amenities,
    required this.videos,
    this.googlePlaceId,
    this.brokerageTypeId,
    this.brokerageTypeName,
    this.adminId,
    this.organizationId,
    this.additionalDetails,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final propType = json['property_type'] as Map<String, dynamic>?;
    final config = json['configuration'] as Map<String, dynamic>?;
    final listing = json['listing_type'] as Map<String, dynamic>?;
    final status = json['property_status'] as Map<String, dynamic>?;
    final city = json['city'] as Map<String, dynamic>?;
    final area = json['area'] as Map<String, dynamic>?;
    final furnishing = json['furnishing_type'] as Map<String, dynamic>?;
    final facing = json['facing_type'] as Map<String, dynamic>?;
    final ownership = json['ownership_type'] as Map<String, dynamic>?;
    final brokerage = json['brokerage_type'] as Map<String, dynamic>?;
    final creator = json['creator'] as Map<String, dynamic>?;

    final List<String> imageList = [];
    final jsonPropertyImages = json['property_images'];
    final rawImages = (jsonPropertyImages is List && jsonPropertyImages.isNotEmpty)
        ? jsonPropertyImages
        : (json['images'] as List<dynamic>? ?? []);
    for (final img in rawImages) {
      if (img == null) continue;
      if (img is String) {
        if (img.isNotEmpty) imageList.add(img);
      } else if (img is Map) {
        final url = img['image_url'] as String? ?? 
                    img['url'] as String? ?? 
                    img['path'] as String? ?? 
                    '';
        if (url.isNotEmpty) imageList.add(url);
      } else {
        final str = img.toString();
        if (str.isNotEmpty) imageList.add(str);
      }
    }

    final rawAmenities = json['property_amenities'] as List<dynamic>? ?? [];
    final List<String> amenityList = rawAmenities
        .map((am) => ((am['amenity'] as Map<String, dynamic>?)?['name'] as String?) ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    final List<String> videoList = [];
    final jsonPropertyVideos = json['property_videos'];
    final rawVideos = (jsonPropertyVideos is List && jsonPropertyVideos.isNotEmpty)
        ? jsonPropertyVideos
        : (json['videos'] as List<dynamic>? ?? []);
    for (final vid in rawVideos) {
      if (vid == null) continue;
      if (vid is String) {
        if (vid.isNotEmpty) videoList.add(vid);
      } else if (vid is Map) {
        final url = vid['video_url'] as String? ?? 
                    vid['url'] as String? ?? 
                    vid['path'] as String? ?? 
                    '';
        if (url.isNotEmpty) videoList.add(url);
      } else {
        final str = vid.toString();
        if (str.isNotEmpty) videoList.add(str);
      }
    }

    return PropertyModel(
      id: json['id'] as String? ?? '',
      propertyCode: json['property_code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      categoryId: json['category_id'] as String? ?? '',
      categoryName: category != null ? category['name'] as String? ?? 'N/A' : 'N/A',
      propertyTypeId: json['property_type_id'] as String? ?? '',
      propertyTypeName: propType != null ? propType['name'] as String? ?? 'N/A' : 'N/A',
      configurationId: json['configuration_id'] as String?,
      configurationName: config != null ? config['name'] as String? : null,
      listingTypeId: json['listing_type_id'] as String? ?? '',
      listingTypeName: listing != null ? listing['name'] as String? ?? 'N/A' : 'N/A',
      propertyStatusId: json['property_status_id'] as String? ?? '',
      propertyStatusName: status != null ? status['name'] as String? ?? 'N/A' : 'N/A',
      cityId: json['city_id'] as String? ?? '',
      cityName: city != null ? city['city_name'] as String? ?? 'N/A' : 'N/A',
      areaId: json['area_id'] as String? ?? '',
      areaName: area != null ? area['area_name'] as String? ?? 'N/A' : 'N/A',
      pincode: area != null ? area['pincode'] as String? ?? 'N/A' : 'N/A',
      address: json['address'] as String? ?? '',
      landmark: json['landmark'] as String?,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      superBuiltupArea: json['super_builtup_area'] != null ? double.tryParse(json['super_builtup_area'].toString()) : null,
      carpetArea: json['carpet_area'] != null ? double.tryParse(json['carpet_area'].toString()) : null,
      plotArea: json['plot_area'] != null ? double.tryParse(json['plot_area'].toString()) : null,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      deposit: double.tryParse(json['deposit'].toString()) ?? 0.0,
      maintenance: double.tryParse(json['maintenance'].toString()) ?? 0.0,
      furnishingTypeId: json['furnishing_type_id'] as String?,
      furnishingTypeName: furnishing != null ? furnishing['name'] as String? : null,
      facingTypeId: json['facing_type_id'] as String?,
      facingTypeName: facing != null ? facing['name'] as String? : null,
      ownershipTypeId: json['ownership_type_id'] as String?,
      ownershipTypeName: ownership != null ? ownership['name'] as String? : null,
      googlePlaceId: json['google_place_id'] as String?,
      brokerageTypeId: json['brokerage_type_id'] as String?,
      brokerageTypeName: brokerage != null ? brokerage['name'] as String? : null,
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int? ?? 0,
      balconies: json['balconies'] as int? ?? 0,
      parking: json['parking'] as int? ?? 0,
      floorNo: json['floor_no'] as int?,
      totalFloor: json['total_floor'] as int?,
      ageOfProperty: json['age_of_property'] as int?,
      possessionDate: json['possession_date'] != null ? DateTime.tryParse(json['possession_date'] as String) : null,
      ownerName: json['owner_name'] as String? ?? '',
      ownerMobile: json['owner_mobile'] as String? ?? '',
      brokerName: json['broker_name'] as String?,
      remarks: json['remarks'] as String?,
      blockWing: json['block_wing'] as String?,
      flatNo: json['flat_no'] as String?,
      isVerified: json['is_verified'] as bool? ?? false,
      createdBy: json['created_by'] as String? ?? '',
      createdByName: creator != null ? creator['full_name'] as String? ?? 'N/A' : 'N/A',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      images: imageList,
      amenities: amenityList,
      videos: videoList,
      adminId: json['admin_id'] as String?,
      organizationId: json['organization_id'] as String?,
      additionalDetails: json['additional_details'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category_id': categoryId,
      'property_type_id': propertyTypeId,
      'configuration_id': configurationId,
      'listing_type_id': listingTypeId,
      'property_status_id': propertyStatusId,
      'city_id': cityId,
      'area_id': areaId,
      'address': address,
      'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'super_builtup_area': superBuiltupArea,
      'carpet_area': carpetArea,
      'plot_area': plotArea,
      'price': price,
      'deposit': deposit,
      'maintenance': maintenance,
      'furnishing_type_id': furnishingTypeId,
      'facing_type_id': facingTypeId,
      'ownership_type_id': ownershipTypeId,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'balconies': balconies,
      'parking': parking,
      'floor_no': floorNo,
      'total_floor': totalFloor,
      'age_of_property': ageOfProperty,
      'possession_date': possessionDate?.toIso8601String().substring(0, 10),
      'owner_name': ownerName,
      'owner_mobile': ownerMobile,
      'broker_name': brokerName,
      'remarks': remarks,
      'block_wing': blockWing,
      'flat_no': flatNo,
      'amenities': amenities,
      'images': images,
      'videos': videos,
      'additional_details': additionalDetails,
    };
  }

  String get statusDisplayName {
    if (propertyStatusName.toLowerCase().contains('to be available') || propertyStatusId == 'to_be_available') {
      if (possessionDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final avail = DateTime(possessionDate!.year, possessionDate!.month, possessionDate!.day);
        if (today.isAfter(avail) || today.isAtSameMomentAs(avail)) {
          return 'Available';
        } else {
          final df = DateFormat('dd-MM-yyyy');
          return 'To Be Available (${df.format(possessionDate!)})';
        }
      }
      return 'To Be Available';
    }
    return propertyStatusName;
  }

  bool get isStatusAvailable {
    return statusDisplayName.toLowerCase() == 'available';
  }

  String? get availableFromFormatted {
    final statusName = statusDisplayName.toLowerCase();
    
    // Checked statuses that represent availability
    final isAvailableStatus = statusName.contains('available') || 
                              propertyStatusId == 'available' || 
                              propertyStatusId == 'to_be_available';
                              
    if (!isAvailableStatus) {
      return null;
    }
    
    if (possessionDate != null) {
      return DateFormat('MMMM d, yyyy').format(possessionDate!);
    }
    
    return 'Immediate';
  }
}

class LookupItem {
  final String id;
  final String name;
  final String? categoryId;
  final String? state;
  final String? country;
  LookupItem({required this.id, required this.name, this.categoryId, this.state, this.country});
  factory LookupItem.fromJson(Map<String, dynamic> json) {
    return LookupItem(
      id: json['id'] as String,
      name: (json['name'] ?? json['city_name'] ?? json['area_name'] ?? '') as String,
      categoryId: json['category_id'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
    );
  }
}

class AreaLookup extends LookupItem {
  final String cityId;
  final String pincode;
  AreaLookup({required String id, required String name, required this.cityId, required this.pincode})
      : super(id: id, name: name);
  factory AreaLookup.fromJson(Map<String, dynamic> json) {
    return AreaLookup(
      id: json['id'] as String,
      name: json['area_name'] as String,
      cityId: json['city_id'] as String,
      pincode: json['pincode'] as String,
    );
  }
}

class PropertyMetadataModel {
  final List<LookupItem> cities;
  final List<AreaLookup> areas;
  final List<LookupItem> categories;
  final List<LookupItem> types;
  final List<LookupItem> configurations;
  final List<LookupItem> listingTypes;
  final List<LookupItem> statuses;
  final List<LookupItem> furnishings;
  final List<LookupItem> facings;
  final List<LookupItem> ownerships;
  final List<LookupItem> brokerages;
  final List<LookupItem> amenities;

  PropertyMetadataModel({
    required this.cities,
    required this.areas,
    required this.categories,
    required this.types,
    required this.configurations,
    required this.listingTypes,
    required this.statuses,
    required this.furnishings,
    required this.facings,
    required this.ownerships,
    required this.brokerages,
    required this.amenities,
  });

  factory PropertyMetadataModel.fromJson(Map<String, dynamic> json) {
    final meta = json['metadata'] as Map<String, dynamic>? ?? json;
    
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) parser) {
      if (raw == null) return [];
      return (raw as List<dynamic>).map((item) => parser(item as Map<String, dynamic>)).toList();
    }

    return PropertyMetadataModel(
      cities: parseList(meta['cities'], (j) => LookupItem(id: j['id'], name: j['city_name'])),
      areas: parseList(meta['areas'], AreaLookup.fromJson),
      categories: parseList(meta['categories'], LookupItem.fromJson),
      types: parseList(meta['types'], LookupItem.fromJson),
      configurations: parseList(meta['configurations'], LookupItem.fromJson),
      listingTypes: parseList(meta['listingTypes'], LookupItem.fromJson),
      statuses: parseList(meta['statuses'], LookupItem.fromJson),
      furnishings: parseList(meta['furnishings'], LookupItem.fromJson),
      facings: parseList(meta['facings'], LookupItem.fromJson),
      ownerships: parseList(meta['ownerships'], LookupItem.fromJson),
      brokerages: parseList(meta['brokerages'], LookupItem.fromJson),
      amenities: parseList(meta['amenities'], LookupItem.fromJson),
    );
  }
}

import 'package:isar/isar.dart';

part 'isar_collections.g.dart';

@collection
class LookupItemLocal {
  Id? isarId;

  @Index(unique: true, replace: true)
  late String id;

  late String name;
  late String category; // 'city', 'area', 'property_category', 'property_type', 'configuration', 'listing_type', 'property_status', 'furnishing_type', 'facing_type', 'ownership_type', 'brokerage_type', 'amenity'

  String? categoryId; // for property_types, configurations
  String? cityId; // for AreaLookup
  String? pincode; // for AreaLookup
}

@collection
class PropertyLocal {
  Id? isarId;

  @Index(unique: true, replace: true)
  late String id;

  late String propertyCode;
  late String title;
  String? description;
  late String categoryId;
  late String categoryName;
  late String propertyTypeId;
  late String propertyTypeName;
  String? configurationId;
  String? configurationName;
  late String listingTypeId;
  late String listingTypeName;
  late String propertyStatusId;
  late String propertyStatusName;
  late String cityId;
  late String cityName;
  late String areaId;
  late String areaName;
  late String pincode;
  late String address;
  String? landmark;
  double? latitude;
  double? longitude;
  double? superBuiltupArea;
  double? carpetArea;
  double? plotArea;
  late double price;
  late double deposit;
  late double maintenance;
  String? furnishingTypeId;
  String? furnishingTypeName;
  String? facingTypeId;
  String? facingTypeName;
  String? ownershipTypeId;
  String? ownershipTypeName;
  late int bedrooms;
  late int bathrooms;
  late int balconies;
  late int parking;
  int? floorNo;
  int? totalFloor;
  int? ageOfProperty;
  DateTime? possessionDate;
  late String ownerName;
  late String ownerMobile;
  String? brokerName;
  String? remarks;
  String? blockWing;
  String? flatNo;
  String? googlePlaceId;
  String? brokerageTypeId;
  String? brokerageTypeName;
  late bool isVerified;
  late String createdBy;
  late String createdByName;
  late DateTime createdAt;
  late List<String> images;
  late List<String> amenities;
  late List<String> videos;
  String? adminId;
  String? organizationId;
}

@collection
class RequirementLocal {
  Id? isarId;

  @Index(unique: true, replace: true)
  late String id;

  late String clientName;
  late String clientMobile;
  late String categoryId;
  late String categoryName;
  String? propertyTypeId;
  String? propertyTypeName;
  String? configurationId;
  String? configurationName;
  List<String>? configurationIds;
  List<String>? propertyTypeIds;
  late double minBudget;
  late double maxBudget;
  double? minArea;
  double? maxArea;
  late List<String> areaIds;
  late List<String> areaNames;
  String? remarks;
  late String status;
  late DateTime createdAt;
  double? budget;
  String? adminId;
  String? assignedTo;
  String? organizationId;
  String? listingTypeId;
  String? listingTypeName;
  String? creatorName;
  String? assigneeName;
  String? createdBy;
}

@collection
class FollowupLocal {
  Id? isarId;

  @Index(unique: true, replace: true)
  late String id;

  String? propertyId;
  String? propertyCode;
  String? propertyTitle;
  String? requirementId;
  String? requirementCustomerName;
  late String createdBy;
  late String clientName;
  late String mobile;
  late DateTime followupDate;
  String? notes;
  late String status;
  late DateTime createdAt;
}

@collection
class BuilderLocal {
  Id? isarId;

  @Index(unique: true, replace: true)
  late String id;

  late String companyName;
  late String contactPerson;
  late String mobile;
  late String email;
  late List<String> activeProjects;
  late String tier;
  String? remarks;
  late DateTime createdAt;
}

@collection
class OwnerLocal {
  Id? isarId;

  @Index(unique: true, replace: true)
  late String id;

  late String name;
  late String mobile;
  String? email;
  String? address;
  String? remarks;
  late DateTime createdAt;
}

@collection
class ClientLocal {
  Id? isarId;

  @Index(unique: true, replace: true)
  late String id;

  late String name;
  late String email;
  late String mobile;
  late String stage;
  late String source;
  String? assignedAgent;
  String? remarks;
  late DateTime createdAt;
}

@collection
class OutboxLocal {
  Id? isarId;

  @Index(unique: true, replace: true)
  late String id;

  late String endpoint;
  late String method;
  late String payloadJson;
  late DateTime createdAt;
  String? deviceId;
}

@embedded
class DashboardSummaryLocal {
  int? totalProperties;
  int? available;
  int? sold;
  int? rented;
  int? requirements;
  int? users;

  int? rentalAvailable;
  int? resaleAvailable;
  int? rentalRented;
  int? resaleSold;
  int? rentalRequirements;
  int? resaleRequirements;

  double? totalPropertiesTrend;
  double? availableTrend;
  double? soldTrend;
  double? rentedTrend;
  double? requirementsTrend;

  String? topBroker;
  String? topArea;
  String? topProperty;
  String? monthlyGrowth;
}

@collection
class DashboardLocal {
  Id? isarId;

  @Index(unique: true, replace: true)
  late String id; // e.g. 'singleton'

  late DashboardSummaryLocal summary;
  late String activityJson;
  late String recentPropertiesJson;
  late String checklistJson;
  late String followupsJson;
  String? siteVisitsJson;
  late DateTime updatedAt;
}

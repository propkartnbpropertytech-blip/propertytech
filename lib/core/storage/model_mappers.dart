import 'dart:convert';
import 'isar_collections.dart';
import '../../features/properties/models/property_model.dart';
import '../../features/requirements/models/requirement_model.dart';
import '../../features/dashboard/models/dashboard_summary.dart';
import '../../features/builders/models/builder_model.dart';
import '../../features/owners/models/owner_model.dart';
import '../../features/clients/models/client_model.dart';

extension PropertyLocalExtensions on PropertyLocal {
  PropertyModel toModel() {
    List<String> safeImages = const [];
    try {
      safeImages = images;
    } catch (_) {}

    List<String> safeAmenities = const [];
    try {
      safeAmenities = amenities;
    } catch (_) {}

    List<String> safeVideos = const [];
    try {
      safeVideos = videos;
    } catch (_) {}

    return PropertyModel(
      id: id,
      propertyCode: propertyCode,
      title: title,
      description: description,
      categoryId: categoryId,
      categoryName: categoryName,
      propertyTypeId: propertyTypeId,
      propertyTypeName: propertyTypeName,
      configurationId: configurationId,
      configurationName: configurationName,
      listingTypeId: listingTypeId,
      listingTypeName: listingTypeName,
      propertyStatusId: propertyStatusId,
      propertyStatusName: propertyStatusName,
      cityId: cityId,
      cityName: cityName,
      areaId: areaId,
      areaName: areaName,
      pincode: pincode,
      address: address,
      landmark: landmark,
      latitude: latitude,
      longitude: longitude,
      superBuiltupArea: superBuiltupArea,
      carpetArea: carpetArea,
      plotArea: plotArea,
      price: price,
      deposit: deposit,
      maintenance: maintenance,
      furnishingTypeId: furnishingTypeId,
      furnishingTypeName: furnishingTypeName,
      facingTypeId: facingTypeId,
      facingTypeName: facingTypeName,
      ownershipTypeId: ownershipTypeId,
      ownershipTypeName: ownershipTypeName,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      balconies: balconies,
      parking: parking,
      floorNo: floorNo,
      totalFloor: totalFloor,
      ageOfProperty: ageOfProperty,
      possessionDate: possessionDate,
      ownerName: ownerName,
      ownerMobile: ownerMobile,
      brokerName: brokerName,
      remarks: remarks,
      blockWing: blockWing,
      flatNo: flatNo,
      isVerified: isVerified,
      createdBy: createdBy,
      createdByName: createdByName,
      createdAt: createdAt,
      images: safeImages,
      amenities: safeAmenities,
      videos: safeVideos,
      googlePlaceId: googlePlaceId,
      brokerageTypeId: brokerageTypeId,
      adminId: adminId,
      organizationId: organizationId,
    );
  }
}

extension PropertyModelExtensions on PropertyModel {
  PropertyLocal toLocal() {
    return PropertyLocal()
      ..id = id
      ..propertyCode = propertyCode
      ..title = title
      ..description = description
      ..categoryId = categoryId
      ..categoryName = categoryName
      ..propertyTypeId = propertyTypeId
      ..propertyTypeName = propertyTypeName
      ..configurationId = configurationId
      ..configurationName = configurationName
      ..listingTypeId = listingTypeId
      ..listingTypeName = listingTypeName
      ..propertyStatusId = propertyStatusId
      ..propertyStatusName = propertyStatusName
      ..cityId = cityId
      ..cityName = cityName
      ..areaId = areaId
      ..areaName = areaName
      ..pincode = pincode
      ..address = address
      ..landmark = landmark
      ..latitude = latitude
      ..longitude = longitude
      ..superBuiltupArea = superBuiltupArea
      ..carpetArea = carpetArea
      ..plotArea = plotArea
      ..price = price
      ..deposit = deposit
      ..maintenance = maintenance
      ..furnishingTypeId = furnishingTypeId
      ..furnishingTypeName = furnishingTypeName
      ..facingTypeId = facingTypeId
      ..facingTypeName = facingTypeName
      ..ownershipTypeId = ownershipTypeId
      ..ownershipTypeName = ownershipTypeName
      ..bedrooms = bedrooms
      ..bathrooms = bathrooms
      ..balconies = balconies
      ..parking = parking
      ..floorNo = floorNo
      ..totalFloor = totalFloor
      ..ageOfProperty = ageOfProperty
      ..possessionDate = possessionDate
      ..ownerName = ownerName
      ..ownerMobile = ownerMobile
      ..brokerName = brokerName
      ..remarks = remarks
      ..blockWing = blockWing
      ..flatNo = flatNo
      ..isVerified = isVerified
      ..createdBy = createdBy
      ..createdByName = createdByName
      ..createdAt = createdAt
      ..images = images
      ..amenities = amenities
      ..videos = videos
      ..googlePlaceId = googlePlaceId
      ..brokerageTypeId = brokerageTypeId
      ..brokerageTypeName = brokerageTypeName
      ..adminId = adminId
      ..organizationId = organizationId;
  }
}

extension RequirementLocalExtensions on RequirementLocal {
  RequirementModel toModel() {
    List<String> safeAreaIds = const [];
    try {
      safeAreaIds = areaIds;
    } catch (_) {}

    List<String> safeAreaNames = const [];
    try {
      safeAreaNames = areaNames;
    } catch (_) {}

    String? decodedRemarks = remarks;
    String? parsedListingTypeId = listingTypeId;
    String? parsedListingTypeName = listingTypeName;

    if (parsedListingTypeId == null || parsedListingTypeId.isEmpty) {
      if (remarks != null && remarks!.startsWith('[lt:')) {
        final closeBracketIdx = remarks!.indexOf(']');
        if (closeBracketIdx != -1) {
          final content = remarks!.substring('[lt:'.length, closeBracketIdx);
          final parts = content.split(':');
          if (parts.isNotEmpty) {
            parsedListingTypeId = parts[0];
            if (parts.length > 1) {
              parsedListingTypeName = parts[1];
            }
          }
          decodedRemarks = remarks!.substring(closeBracketIdx + 1).trim();
          if (decodedRemarks!.isEmpty) decodedRemarks = null;
        }
      }
    }

    if (parsedListingTypeId == null || parsedListingTypeId.isEmpty) {
      parsedListingTypeId = 'Unknown';
      parsedListingTypeName = 'Unknown';
    }

    return RequirementModel(
      id: id,
      clientName: clientName,
      clientMobile: clientMobile,
      categoryId: categoryId,
      categoryName: categoryName,
      propertyTypeId: propertyTypeId ?? '',
      propertyTypeName: propertyTypeName ?? '',
      configurationId: configurationId,
      configurationName: configurationName,
      minBudget: minBudget,
      maxBudget: maxBudget,
      minArea: minArea,
      maxArea: maxArea,
      areaIds: safeAreaIds,
      areaNames: safeAreaNames,
      configurationIds: configurationIds ?? [],
      propertyTypeIds: propertyTypeIds ?? [],
      furnishingIds: furnishingIds ?? [],
      facingIds: facingIds ?? [],
      remarks: decodedRemarks,
      notes: notes,
      status: status,
      createdAt: createdAt,
      adminId: adminId,
      organizationId: organizationId,
      listingTypeId: parsedListingTypeId,
      listingTypeName: parsedListingTypeName,
      creatorName: creatorName,
      assigneeName: assigneeName,
      createdBy: createdBy,
      assignedTo: assignedTo,
    );
  }
}

extension RequirementModelExtensions on RequirementModel {
  RequirementLocal toLocal() {
    return RequirementLocal()
      ..id = id
      ..clientName = clientName
      ..clientMobile = clientMobile
      ..categoryId = categoryId
      ..categoryName = categoryName
      ..propertyTypeId = propertyTypeId
      ..propertyTypeName = propertyTypeName
      ..configurationId = configurationId
      ..configurationName = configurationName
      ..configurationIds = configurationIds
      ..propertyTypeIds = propertyTypeIds
      ..furnishingIds = furnishingIds
      ..facingIds = facingIds
      ..minBudget = minBudget
      ..maxBudget = maxBudget
      ..minArea = minArea ?? 0.0
      ..maxArea = maxArea ?? 0.0
      ..areaIds = areaIds
      ..areaNames = areaNames
      ..remarks = remarks
      ..notes = notes
      ..status = status
      ..createdAt = createdAt
      ..budget = (minBudget + maxBudget) / 2
      ..adminId = adminId
      ..assignedTo = assignedTo
      ..organizationId = organizationId
      ..listingTypeId = listingTypeId
      ..listingTypeName = listingTypeName
      ..creatorName = creatorName
      ..assigneeName = assigneeName
      ..createdBy = createdBy;
  }
}

extension FollowupLocalExtensions on FollowupLocal {
  DashboardFollowup toModel() {
    return DashboardFollowup(
      id: id,
      clientName: clientName,
      mobile: mobile,
      followupDate: followupDate.toIso8601String(),
      notes: notes,
      status: status,
      propertyCode: propertyCode,
      propertyTitle: propertyTitle,
      requirementCustomerName: requirementCustomerName,
    );
  }
}

extension DashboardFollowupExtensions on DashboardFollowup {
  FollowupLocal toLocal(String createdBy) {
    return FollowupLocal()
      ..id = id
      ..propertyId = null
      ..propertyCode = propertyCode
      ..propertyTitle = propertyTitle
      ..requirementId = null
      ..requirementCustomerName = requirementCustomerName
      ..createdBy = createdBy
      ..clientName = clientName
      ..mobile = mobile
      ..followupDate = DateTime.tryParse(followupDate) ?? DateTime.now()
      ..notes = notes
      ..status = status
      ..createdAt = DateTime.now();
  }
}

extension BuilderLocalExtensions on BuilderLocal {
  BuilderModel toModel() {
    return BuilderModel(
      id: id,
      companyName: companyName,
      contactPerson: contactPerson,
      mobile: mobile,
      email: email,
      activeProjects: activeProjects,
      tier: tier,
      remarks: remarks,
      createdAt: createdAt,
    );
  }
}

extension BuilderModelExtensions on BuilderModel {
  BuilderLocal toLocal() {
    return BuilderLocal()
      ..id = id
      ..companyName = companyName
      ..contactPerson = contactPerson
      ..mobile = mobile
      ..email = email
      ..activeProjects = activeProjects
      ..tier = tier
      ..remarks = remarks
      ..createdAt = createdAt;
  }
}

extension OwnerLocalExtensions on OwnerLocal {
  OwnerModel toModel() {
    return OwnerModel(
      id: id,
      name: name,
      mobile: mobile,
      email: email ?? '',
      address: address,
      remarks: remarks,
      createdAt: createdAt,
    );
  }
}

extension OwnerModelExtensions on OwnerModel {
  OwnerLocal toLocal() {
    return OwnerLocal()
      ..id = id
      ..name = name
      ..mobile = mobile
      ..email = email
      ..address = address
      ..remarks = remarks
      ..createdAt = createdAt;
  }
}

extension ClientLocalExtensions on ClientLocal {
  ClientModel toModel() {
    return ClientModel(
      id: id,
      name: name,
      email: email,
      mobile: mobile,
      stage: stage,
      source: source,
      assignedAgent: assignedAgent,
      remarks: remarks,
      createdAt: createdAt,
    );
  }
}

extension ClientModelExtensions on ClientModel {
  ClientLocal toLocal() {
    return ClientLocal()
      ..id = id
      ..name = name
      ..email = email
      ..mobile = mobile
      ..stage = stage
      ..source = source
      ..assignedAgent = assignedAgent
      ..remarks = remarks
      ..createdAt = createdAt;
  }
}

extension LookupLocalExtensions on LookupItemLocal {
  LookupItem toModel() {
    return LookupItem(
      id: id,
      name: name,
      categoryId: categoryId,
    );
  }

  AreaLookup toAreaModel() {
    return AreaLookup(
      id: id,
      name: name,
      cityId: cityId ?? '',
      pincode: pincode ?? '',
    );
  }
}

extension LookupItemExtensions on LookupItem {
  LookupItemLocal toLocal(String category) {
    return LookupItemLocal()
      ..id = id
      ..name = name
      ..category = category
      ..categoryId = categoryId;
  }
}

extension AreaLookupExtensions on AreaLookup {
  LookupItemLocal toAreaLocal() {
    return LookupItemLocal()
      ..id = id
      ..name = name
      ..category = 'area'
      ..cityId = cityId
      ..pincode = pincode;
  }
}

extension DashboardDataExtensions on DashboardData {
  DashboardLocal toLocal() {
    return DashboardLocal()
      ..id = 'singleton'
      ..summary = (DashboardSummaryLocal()
        ..totalProperties = summary.totalProperties
        ..available = summary.available
        ..sold = summary.sold
        ..rented = summary.rented
        ..requirements = summary.requirements
        ..users = summary.users
        ..rentalAvailable = summary.rentalAvailable
        ..resaleAvailable = summary.resaleAvailable
        ..rentalRented = summary.rentalRented
        ..resaleSold = summary.resaleSold
        ..rentalRequirements = summary.rentalRequirements
        ..resaleRequirements = summary.resaleRequirements
        ..totalPropertiesTrend = summary.totalPropertiesTrend
        ..availableTrend = summary.availableTrend
        ..soldTrend = summary.soldTrend
        ..rentedTrend = summary.rentedTrend
        ..requirementsTrend = summary.requirementsTrend
        ..topBroker = summary.topBroker
        ..topArea = summary.topArea
        ..topProperty = summary.topProperty
        ..monthlyGrowth = summary.monthlyGrowth)
      ..activityJson = jsonEncode(activity.map((a) => {
        'id': a.id,
        'module': a.module,
        'action': a.action,
        'description': a.description,
        'timestamp': a.timestamp,
        'user': a.user,
      }).toList())
      ..recentPropertiesJson = jsonEncode(recentProperties.map((p) => {
        'id': p.id,
        'code': p.code,
        'title': p.title,
        'area': p.area,
        'price': p.price,
        'status': p.status,
        'areaName': p.areaName,
        'listingType': p.listingType,
        'createdBy': p.createdBy,
        'createdAt': p.createdAt,
      }).toList())
      ..checklistJson = jsonEncode(checklist.map((c) => {
        'id': c.id,
        'title': c.title,
        'is_completed': c.isCompleted,
        'due_date': c.dueDate,
      }).toList())
      ..followupsJson = jsonEncode(followups.map((f) => {
        'id': f.id,
        'client_name': f.clientName,
        'mobile': f.mobile,
        'followup_date': f.followupDate,
        'notes': f.notes,
        'status': f.status,
        'property': f.propertyCode != null ? {'property_code': f.propertyCode, 'title': f.propertyTitle} : null,
        'requirement': f.requirementCustomerName != null ? {'customer_name': f.requirementCustomerName, 'id': f.requirementId} : null,
        'requirement_id': f.requirementId,
        'creator': f.creatorName != null ? {'full_name': f.creatorName} : null,
      }).toList())
      ..siteVisitsJson = jsonEncode(siteVisits.map((sv) => {
        'id': sv.id,
        'visit_date': sv.visitDate,
        'remarks': sv.remarks,
        'status': sv.status,
        'property': sv.propertyCode != null ? {'property_code': sv.propertyCode, 'title': sv.propertyTitle} : null,
        'requirement': sv.requirementCustomerName != null ? {'customer_name': sv.requirementCustomerName, 'id': sv.requirementId} : null,
        'requirement_id': sv.requirementId,
        'creator': sv.creatorName != null ? {'full_name': sv.creatorName} : null,
      }).toList())
      ..updatedAt = DateTime.now();
  }
}

extension DashboardLocalExtensions on DashboardLocal {
  DashboardData toModel() {
    final List<dynamic> actList = jsonDecode(activityJson);
    final List<dynamic> propList = jsonDecode(recentPropertiesJson);
    final List<dynamic> checkList = jsonDecode(checklistJson);
    final List<dynamic> follList = jsonDecode(followupsJson);
    final List<dynamic> svList = siteVisitsJson != null ? jsonDecode(siteVisitsJson!) : [];
 
    return DashboardData(
      summary: DashboardSummary(
        totalProperties: summary.totalProperties ?? 0,
        available: summary.available ?? 0,
        sold: summary.sold ?? 0,
        rented: summary.rented ?? 0,
        requirements: summary.requirements ?? 0,
        users: summary.users ?? 0,
        rentalAvailable: summary.rentalAvailable ?? 0,
        resaleAvailable: summary.resaleAvailable ?? 0,
        rentalRented: summary.rentalRented ?? 0,
        resaleSold: summary.resaleSold ?? 0,
        rentalRequirements: summary.rentalRequirements ?? 0,
        resaleRequirements: summary.resaleRequirements ?? 0,
        totalPropertiesTrend: summary.totalPropertiesTrend ?? 0.0,
        availableTrend: summary.availableTrend ?? 0.0,
        soldTrend: summary.soldTrend ?? 0.0,
        rentedTrend: summary.rentedTrend ?? 0.0,
        requirementsTrend: summary.requirementsTrend ?? 0.0,
        topBroker: summary.topBroker ?? 'N/A',
        topArea: summary.topArea ?? 'N/A',
        topProperty: summary.topProperty ?? 'N/A',
        monthlyGrowth: summary.monthlyGrowth ?? '0.0%',
      ),
      activity: actList.map((item) => RecentActivity.fromJson(item)).toList(),
      recentProperties: propList.map((item) => RecentProperty.fromJson(item)).toList(),
      checklist: checkList.map((item) => ChecklistItem.fromJson(item)).toList(),
      followups: follList.map((item) => DashboardFollowup.fromJson(item)).toList(),
      siteVisits: svList.map((item) => DashboardSiteVisit.fromJson(item)).toList(),
    );
  }
}

import '../../../core/storage/local_repositories.dart';

class RequirementModel {
  final String id;
  final String clientName;
  final String clientMobile;
  final String categoryId;
  final String categoryName;
  final String propertyTypeId;
  final String propertyTypeName;
  final String? configurationId;
  final String? configurationName;
  final String? listingTypeId;
  final String? listingTypeName;
  final double minBudget;
  final double maxBudget;
  final double? minArea;
  final double? maxArea;
  final List<String> areaIds;
  final List<String> areaNames;
  final List<String> configurationIds;
  final List<String> propertyTypeIds;
  final List<dynamic>? rawSiteVisits;
  final List<dynamic>? rawShareSessions;
  final String? remarks;
  final String status; // 'Active', 'Closed', 'Suspended'
  final DateTime createdAt;
  final String? adminId;
  final String? assignedTo;
  final String? organizationId;
  final String? assigneeName;
  final String? creatorName;
  final String? nextFollowupDate;
  final List<String> furnishingIds;
  final List<String> facingIds;
  final String? createdBy;
  final String? creatorMobile;
  final String? creatorEmail;

  RequirementModel({
    required this.id,
    required this.clientName,
    required this.clientMobile,
    required this.categoryId,
    required this.categoryName,
    required this.propertyTypeId,
    required this.propertyTypeName,
    this.configurationId,
    this.configurationName,
    this.listingTypeId,
    this.listingTypeName,
    required this.minBudget,
    required this.maxBudget,
    this.minArea,
    this.maxArea,
    required this.areaIds,
    required this.areaNames,
    this.configurationIds = const [],
    this.propertyTypeIds = const [],
    this.rawSiteVisits,
    this.rawShareSessions,
    this.remarks,
    required this.status,
    required this.createdAt,
    this.adminId,
    this.assignedTo,
    this.organizationId,
    this.assigneeName,
    this.creatorName,
    this.nextFollowupDate,
    this.furnishingIds = const [],
    this.facingIds = const [],
    this.createdBy,
    this.creatorMobile,
    this.creatorEmail,
  });

  factory RequirementModel.fromJson(Map<String, dynamic> json) {
    // Handle category name from joined category object
    String catName = '';
    if (json['categoryName'] != null) {
      catName = json['categoryName'];
    } else if (json['category'] != null && json['category'] is Map) {
      catName = json['category']['name'] ?? '';
    }

    // Handle multi-select arrays
    List<String> configIds = [];
    if (json['configurationIds'] != null) {
      configIds = List<String>.from(json['configurationIds']);
    } else if (json['configuration_ids'] != null) {
      configIds = List<String>.from(json['configuration_ids']);
    } else if (json['configuration_id'] != null) {
      configIds = [json['configuration_id'].toString()];
    }

    List<String> propTypeIds = [];
    if (json['propertyTypeIds'] != null) {
      propTypeIds = List<String>.from(json['propertyTypeIds']);
    } else if (json['property_type_ids'] != null) {
      propTypeIds = List<String>.from(json['property_type_ids']);
    } else if (json['property_type_id'] != null) {
      propTypeIds = [json['property_type_id'].toString()];
    }

    // Handle property type name from joined object
    String typeName = '';
    if (json['propertyTypeName'] != null) {
      typeName = json['propertyTypeName'];
    } else if (json['property_type'] != null && json['property_type'] is Map) {
      typeName = json['property_type']['name'] ?? '';
    }
    if (propTypeIds.isNotEmpty) {
      final names = propTypeIds
          .map((id) => LookupLocalRepository.getLookupNameSync(id))
          .whereType<String>()
          .where((n) => n.isNotEmpty && n != 'N/A')
          .toList();
      if (names.isNotEmpty && (names.length > 1 || typeName.isEmpty)) {
        typeName = names.join(', ');
      }
    }

    // Handle configuration name from joined object or multi-select configIds
    String? configName;
    if (json['configurationName'] != null) {
      configName = json['configurationName'];
    } else if (json['configuration'] != null && json['configuration'] is Map) {
      configName = json['configuration']['name'];
    }
    if (configIds.isNotEmpty) {
      final names = configIds
          .map((id) => LookupLocalRepository.getLookupNameSync(id))
          .whereType<String>()
          .where((n) => n.isNotEmpty && n != 'N/A')
          .toList();
      if (names.isNotEmpty && (names.length > 1 || configName == null || configName.isEmpty)) {
        configName = names.join(', ');
      }
    }

    // Handle listing type name from joined object
    String? listingName;
    if (json['listingTypeName'] != null) {
      listingName = json['listingTypeName'];
    } else if (json['listing_type'] != null && json['listing_type'] is Map) {
      listingName = json['listing_type']['name'];
    }

    // Handle target areas
    List<String> aIds = [];
    if (json['areaIds'] != null) {
      aIds = List<String>.from(json['areaIds']);
    } else if (json['area_ids'] != null) {
      aIds = List<String>.from(json['area_ids']);
    } else if (json['area_id'] != null) {
      aIds = [json['area_id'].toString()];
    }

    List<String> aNames = [];
    if (json['areaNames'] != null) {
      aNames = List<String>.from(json['areaNames']);
    } else if (json['area_names'] != null) {
      aNames = List<String>.from(json['area_names']);
    } else if (json['area'] != null && json['area'] is Map) {
      aNames = [json['area']['area_name']?.toString() ?? ''];
    }

    return RequirementModel(
      id: json['id'] ?? '',
      clientName: json['clientName'] ?? json['customer_name'] ?? '',
      clientMobile: json['clientMobile'] ?? json['mobile'] ?? '',
      categoryId: json['categoryId'] ?? json['category_id'] ?? '',
      categoryName: catName,
      propertyTypeId: json['propertyTypeId'] ?? json['property_type_id'] ?? '',
      propertyTypeName: typeName,
      configurationId: json['configurationId'] ?? json['configuration_id'],
      configurationName: configName,
      listingTypeId: json['listingTypeId'] ?? json['listing_type_id'],
      listingTypeName: listingName,
      minBudget: (json['minBudget'] ?? json['budget_from'] as num?)?.toDouble() ?? 0.0,
      maxBudget: (json['maxBudget'] ?? json['budget_to'] as num?)?.toDouble() ?? 0.0,
      minArea: (json['minArea'] ?? json['min_area'] as num?)?.toDouble(),
      maxArea: (json['maxArea'] ?? json['max_area'] as num?)?.toDouble(),
      areaIds: aIds,
      areaNames: aNames,
      configurationIds: configIds,
      propertyTypeIds: propTypeIds,
      rawSiteVisits: json['site_visits'] as List<dynamic>?,
      rawShareSessions: json['share_sessions'] as List<dynamic>?,
      remarks: json['remarks'],
      status: json['status'] ?? 'Active',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      adminId: (json['admin_id'] ?? json['adminId']) as String?,
      assignedTo: (json['assigned_to'] ?? json['assignedTo']) as String?,
      organizationId: json['organization_id'] as String?,
      assigneeName: () {
        if (json['assigneeName'] != null) return json['assigneeName'] as String;
        if (json['assignee_name'] != null) return json['assignee_name'] as String;
        if (json['assignee'] is Map) {
          return (json['assignee']['full_name'] ?? json['assignee']['fullName'] ?? json['assignee']['name']) as String?;
        }
        return null;
      }(),
      creatorName: () {
        if (json['creatorName'] != null) return json['creatorName'] as String;
        if (json['creator_name'] != null) return json['creator_name'] as String;
        if (json['creator'] is Map) {
          return (json['creator']['full_name'] ?? json['creator']['fullName'] ?? json['creator']['name']) as String?;
        }
        if (json['admin'] is Map) {
          return (json['admin']['full_name'] ?? json['admin']['fullName'] ?? json['admin']['name']) as String?;
        }
        return null;
      }(),
      nextFollowupDate: json['nextFollowupDate'] ?? json['next_followup_date'],
      furnishingIds: json['furnishingIds'] != null
          ? List<String>.from(json['furnishingIds'])
          : json['furnishing_type_ids'] != null
              ? List<String>.from(json['furnishing_type_ids'])
              : json['furnishing'] != null
                  ? [json['furnishing'].toString()]
                  : json['furnishing_type_id'] != null
                      ? [json['furnishing_type_id'].toString()]
                      : const [],
      facingIds: json['facingIds'] != null
          ? List<String>.from(json['facingIds'])
          : json['facing_type_ids'] != null
              ? List<String>.from(json['facing_type_ids'])
              : json['facing'] != null
                  ? [json['facing'].toString()]
                  : json['facing_type_id'] != null
                      ? [json['facing_type_id'].toString()]
                      : const [],
      createdBy: (json['created_by'] ?? json['createdBy']) as String?,
      creatorMobile: (json['creatorMobile'] ?? json['creator_mobile']) as String?,
      creatorEmail: (json['creatorEmail'] ?? json['creator_email']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientName': clientName,
      'clientMobile': clientMobile,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'propertyTypeId': propertyTypeId,
      'propertyTypeName': propertyTypeName,
      'configurationId': configurationId,
      'configurationName': configurationName,
      'listingTypeId': listingTypeId,
      'listingTypeName': listingTypeName,
      'minBudget': minBudget,
      'maxBudget': maxBudget,
      'minArea': minArea,
      'maxArea': maxArea,
      'areaIds': areaIds,
      'areaNames': areaNames,
      'configurationIds': configurationIds,
      'propertyTypeIds': propertyTypeIds,
      'remarks': remarks,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'adminId': adminId,
      'assignedTo': assignedTo,
      'organizationId': organizationId,
      'assigneeName': assigneeName,
      'creatorName': creatorName,
      'nextFollowupDate': nextFollowupDate,
      'furnishingIds': furnishingIds,
      'facingIds': facingIds,
      'createdBy': createdBy,
      'creatorMobile': creatorMobile,
      'creatorEmail': creatorEmail,
    };
  }

  Map<String, dynamic> toBackendJson() {
    return {
      'customer_name': clientName,
      'mobile': clientMobile,
      'category_id': categoryId,
      'property_type_id': propertyTypeId,
      'configuration_id': configurationId,
      'listing_type_id': listingTypeId,
      'budget': (minBudget + maxBudget) / 2,
      'budget_from': minBudget,
      'budget_to': maxBudget,
      'min_area': minArea,
      'max_area': maxArea,
      'area_id': areaIds.isNotEmpty ? areaIds.first : null,
      'area_ids': areaIds,
      'area_names': areaNames,
      'configuration_ids': configurationIds.isNotEmpty ? configurationIds : (configurationId != null ? [configurationId!] : null),
      'property_type_ids': propertyTypeIds.isNotEmpty ? propertyTypeIds : [propertyTypeId],
      'remarks': remarks,
      'status': status,
      'assigned_to': (assignedTo == null || assignedTo!.isEmpty) ? null : assignedTo,
      'furnishing_type_ids': furnishingIds,
      'facing_type_ids': facingIds,
      'furnishing_type_id': furnishingIds.isNotEmpty ? furnishingIds.first : null,
      'facing_type_id': facingIds.isNotEmpty ? facingIds.first : null,
    };
  }

  String calculateClientStage() {
    final combined = status.toLowerCase().replaceAll('-', '');
    if (combined == 'suspended' || combined == 'closed' || combined == 'dead' || combined == 'won') return 'Closed';
    if (combined == 'negotiation') return 'Negotiation';
    if (combined == 'booked' || combined == 'booking') return 'Booking';
    if (combined == 'agreement' || combined == 'documentation') return 'Documentation';
    if (combined == 'payment') return 'Payment';
    if (combined == 'possession') return 'Possession';
    if (combined.contains('sitevisit')) {
      if (combined == 'sitevisitdone') return 'Site Visit Completed';
      return 'Site Visit Scheduled';
    }
    if (combined.contains('followup') || combined.contains('interested')) return 'Client Interested';
    if (combined == 'notstarted') return 'Lead Created';

    if (rawSiteVisits != null && rawSiteVisits!.isNotEmpty) {
      final hasCompleted = rawSiteVisits!.any((v) => v['status'] == 'Completed');
      if (hasCompleted) return 'Site Visit Completed';
      final hasScheduled = rawSiteVisits!.any((v) => v['status'] == 'Scheduled' || v['status'] == 'Active');
      if (hasScheduled) return 'Site Visit Scheduled';
    }

    if (rawShareSessions != null && rawShareSessions!.isNotEmpty) {
      final hasViews = rawShareSessions!.any((s) => (s['view_count'] as num? ?? 0) > 0);
      if (hasViews) return 'Client Viewed';
      return 'Properties Shared';
    }

    if (status == 'Active' || status == 'Live') return 'Requirement Verified';
    
    return 'Requirement Added';
  }

  double get completenessScore {
    double score = 0.0;
    if (clientName.trim().isNotEmpty) score += 0.15;
    if (clientMobile.trim().isNotEmpty) score += 0.15;
    if (categoryId.trim().isNotEmpty) score += 0.15;
    if (propertyTypeId.trim().isNotEmpty) score += 0.10;
    if (configurationId != null && configurationId!.trim().isNotEmpty) score += 0.10;
    if (areaIds.isNotEmpty) score += 0.15;
    if (minBudget > 0 || maxBudget > 0) score += 0.20;
    return score;
  }

  String get requirementQuality {
    if (clientName.trim().isEmpty || clientMobile.trim().isEmpty) return "Poor";
    final bool missingSpecs = minBudget == 0.0 || maxBudget == 0.0 || areaIds.isEmpty || configurationId == null;
    if (completenessScore >= 0.85 && !missingSpecs) {
      return "High";
    } else if (completenessScore >= 0.60) {
      return "Medium";
    } else {
      return "Low";
    }
  }

  String get matchingReadiness {
    final hasCategory = categoryId.trim().isNotEmpty;
    final hasConfig = configurationId != null && configurationId!.trim().isNotEmpty;
    final hasBudget = minBudget > 0 || maxBudget > 0;
    final hasArea = areaIds.isNotEmpty;

    if (hasCategory && hasConfig && hasBudget && hasArea) {
      return 'Ready';
    } else if (hasCategory && hasBudget && hasArea) {
      return 'Needs Information';
    } else {
      return 'Cannot Match';
    }
  }

  String get requirementCode {
    final typeName = (listingTypeName ?? '').toLowerCase();
    String prefix = 'REQ';
    if (typeName.contains('rent')) {
      prefix = 'REQ-R';
    } else if (typeName.contains('sale')) {
      prefix = 'REQ-RS';
    }
    final int hashVal = id.hashCode.abs() % 1000000;
    final String suffix = hashVal.toString().padLeft(6, '0');
    return '$prefix-$suffix';
  }

  RequirementModel copyWith({
    String? id,
    String? clientName,
    String? clientMobile,
    String? categoryId,
    String? categoryName,
    String? propertyTypeId,
    String? propertyTypeName,
    String? configurationId,
    String? configurationName,
    String? listingTypeId,
    String? listingTypeName,
    double? minBudget,
    double? maxBudget,
    double? minArea,
    double? maxArea,
    List<String>? areaIds,
    List<String>? areaNames,
    List<String>? configurationIds,
    List<String>? propertyTypeIds,
    List<dynamic>? rawSiteVisits,
    List<dynamic>? rawShareSessions,
    String? remarks,
    String? status,
    DateTime? createdAt,
    String? adminId,
    String? assignedTo,
    String? organizationId,
    String? assigneeName,
    String? creatorName,
    String? nextFollowupDate,
    List<String>? furnishingIds,
    List<String>? facingIds,
    String? createdBy,
    String? creatorMobile,
    String? creatorEmail,
  }) {
    return RequirementModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientMobile: clientMobile ?? this.clientMobile,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      propertyTypeId: propertyTypeId ?? this.propertyTypeId,
      propertyTypeName: propertyTypeName ?? this.propertyTypeName,
      configurationId: configurationId ?? this.configurationId,
      configurationName: configurationName ?? this.configurationName,
      listingTypeId: listingTypeId ?? this.listingTypeId,
      listingTypeName: listingTypeName ?? this.listingTypeName,
      minBudget: minBudget ?? this.minBudget,
      maxBudget: maxBudget ?? this.maxBudget,
      minArea: minArea ?? this.minArea,
      maxArea: maxArea ?? this.maxArea,
      areaIds: areaIds ?? this.areaIds,
      areaNames: areaNames ?? this.areaNames,
      configurationIds: configurationIds ?? this.configurationIds,
      propertyTypeIds: propertyTypeIds ?? this.propertyTypeIds,
      rawSiteVisits: rawSiteVisits ?? this.rawSiteVisits,
      rawShareSessions: rawShareSessions ?? this.rawShareSessions,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      adminId: adminId ?? this.adminId,
      assignedTo: assignedTo ?? this.assignedTo,
      organizationId: organizationId ?? this.organizationId,
      assigneeName: assigneeName ?? this.assigneeName,
      creatorName: creatorName ?? this.creatorName,
      nextFollowupDate: nextFollowupDate ?? this.nextFollowupDate,
      furnishingIds: furnishingIds ?? this.furnishingIds,
      facingIds: facingIds ?? this.facingIds,
      createdBy: createdBy ?? this.createdBy,
      creatorMobile: creatorMobile ?? this.creatorMobile,
      creatorEmail: creatorEmail ?? this.creatorEmail,
    );
  }
}

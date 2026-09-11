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
  final String? notes;
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
  final String? leadSource;
  final String? referralName;
  final String? metaLeadId;
  final String? metaPageId;
  final String? metaFormId;
  final String? metaCampaignId;
  final String? metaCampaignName;
  final String? metaAdsetId;
  final String? metaAdsetName;
  final String? metaAdId;
  final String? metaAdName;
  final Map<String, dynamic>? metaCustomFields;
  final String? leadQuality;

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
    this.notes,
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
    this.leadSource,
    this.referralName,
    this.metaLeadId,
    this.metaPageId,
    this.metaFormId,
    this.metaCampaignId,
    this.metaCampaignName,
    this.metaAdsetId,
    this.metaAdsetName,
    this.metaAdId,
    this.metaAdName,
    this.metaCustomFields,
    this.leadQuality,
  });

  bool get isMetaLead => metaLeadId != null && metaLeadId!.isNotEmpty;
  String? get metaCampaignDisplayName => metaCampaignName ?? metaCampaignId;
  String? get metaAdDisplayName => metaAdName ?? metaAdId;

  String? get leadSourceDisplay {
    if (isMetaLead) {
      if (metaCampaignName != null && metaCampaignName!.isNotEmpty) {
        return 'Meta Ads ($metaCampaignName)';
      }
      return 'Meta Ads';
    }
    final src = (leadSource != null && leadSource!.trim().isNotEmpty)
        ? leadSource!.trim()
        : null;
    if (src == null) return null;
    if (src.toLowerCase() == 'referral' || src.toLowerCase() == 'referrel') {
      if (referralName != null && referralName!.trim().isNotEmpty) {
        return 'Referral (${referralName!.trim()})';
      }
      return 'Referral';
    }
    return src;
  }

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
      aNames = List<String>.from(json['areaNames']).where((s) => s.trim().isNotEmpty).toList();
    } else if (json['area_names'] != null) {
      aNames = List<String>.from(json['area_names']).where((s) => s.trim().isNotEmpty).toList();
    } else if (json['area'] != null && json['area'] is Map) {
      final aName = json['area']['area_name']?.toString().trim();
      if (aName != null && aName.isNotEmpty) {
        aNames = [aName];
      }
    }

    // Fallback: If areaNames is still empty, extract from meta_custom_fields
    if (aNames.isEmpty) {
      final meta = json['meta_custom_fields'] ?? json['metaCustomFields'];
      if (meta is Map) {
        for (final key in [
          'which_area_are_you_looking_for?',
          'where_is_your_property_located?',
          'preferred_area',
          'Preferred Area',
          'Preferred Location',
          'preferred_location',
          'location',
          'Location',
          'area',
          'Area'
        ]) {
          final val = meta[key]?.toString().trim();
          if (val != null && val.isNotEmpty) {
            final lower = val.toLowerCase();
            if (!lower.contains('any_suitable') && !lower.contains('any suitable') && lower != 'any' && lower != 'all' && lower != 'anywhere') {
              final formatted = val
                  .replaceAll('_', ' ')
                  .split(' ')
                  .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
                  .join(' ')
                  .trim();
              if (formatted.isNotEmpty) {
                aNames = [formatted];
                break;
              }
            }
          }
        }
      }
    }

    // Extract lead source and referral name
    String? parsedLeadSource = (json['leadSource'] ?? json['lead_source'] ?? json['source']) as String?;
    String? parsedReferralName = (json['referralName'] ?? json['referral_name'] ?? json['referred_by']) as String?;

    if (parsedLeadSource != null && parsedLeadSource.startsWith('Referral (')) {
      final match = RegExp(r'^Referral\s*\((.*?)\)$', caseSensitive: false).firstMatch(parsedLeadSource);
      if (match != null) {
        parsedReferralName = match.group(1);
        parsedLeadSource = 'Referral';
      }
    }

    String? parsedRemarks;
    if (json['internal_crm_remarks'] != null) {
      if (json['internal_crm_remarks'] is List && (json['internal_crm_remarks'] as List).isNotEmpty) {
        final remarksList = List.from(json['internal_crm_remarks']);
        remarksList.sort((a, b) {
          if (a is Map && b is Map) {
            final aTime = a['created_at']?.toString() ?? a['createdAt']?.toString() ?? '';
            final bTime = b['created_at']?.toString() ?? b['createdAt']?.toString() ?? '';
            if (aTime.isNotEmpty && bTime.isNotEmpty) {
              return aTime.compareTo(bTime);
            }
          }
          return 0;
        });
        final last = remarksList.last;
        if (last is Map && last['remark'] != null) {
          parsedRemarks = last['remark']?.toString();
        } else if (last is String) {
          parsedRemarks = last;
        }
      } else if (json['internal_crm_remarks'] is Map) {
        parsedRemarks = json['internal_crm_remarks']['remark']?.toString();
      } else if (json['internal_crm_remarks'] is String) {
        parsedRemarks = json['internal_crm_remarks'];
      }
    }

    if ((parsedRemarks == null || parsedRemarks.trim().isEmpty) && json['remarks'] != null && json['remarks'].toString().trim().isNotEmpty) {
      parsedRemarks = json['remarks'].toString().trim();
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
      remarks: parsedRemarks,
      notes: json['notes'] as String?,
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
      leadSource: parsedLeadSource,
      referralName: parsedReferralName,
      metaLeadId: (json['meta_lead_id'] ?? json['metaLeadId'])?.toString(),
      metaPageId: (json['meta_page_id'] ?? json['metaPageId'])?.toString(),
      metaFormId: (json['meta_form_id'] ?? json['metaFormId'])?.toString(),
      metaCampaignId: (json['meta_campaign_id'] ?? json['metaCampaignId'])?.toString(),
      metaCampaignName: (json['meta_campaign_name'] ?? json['metaCampaignName'])?.toString(),
      metaAdsetId: (json['meta_adset_id'] ?? json['metaAdsetId'])?.toString(),
      metaAdsetName: (json['meta_adset_name'] ?? json['metaAdsetName'])?.toString(),
      metaAdId: (json['meta_ad_id'] ?? json['metaAdId'])?.toString(),
      metaAdName: (json['meta_ad_name'] ?? json['metaAdName'])?.toString(),
      metaCustomFields: json['meta_custom_fields'] is Map
          ? Map<String, dynamic>.from(json['meta_custom_fields'] as Map)
          : json['metaCustomFields'] is Map
              ? Map<String, dynamic>.from(json['metaCustomFields'] as Map)
              : null,
      leadQuality: (json['lead_quality'] ?? json['leadQuality'])?.toString(),
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
      'notes': notes,
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
      'leadSource': leadSource,
      'referralName': referralName,
      'meta_lead_id': metaLeadId,
      'meta_page_id': metaPageId,
      'meta_form_id': metaFormId,
      'meta_campaign_id': metaCampaignId,
      'meta_campaign_name': metaCampaignName,
      'meta_adset_id': metaAdsetId,
      'meta_adset_name': metaAdsetName,
      'meta_ad_id': metaAdId,
      'meta_ad_name': metaAdName,
      'meta_custom_fields': metaCustomFields,
      'lead_quality': leadQuality,
    };
  }

  Map<String, dynamic> toBackendJson() {
    final String? formattedSource = leadSource != null && leadSource!.toLowerCase() == 'referral' && referralName != null && referralName!.isNotEmpty
        ? 'Referral ($referralName)'
        : leadSource;

    String? cleanUuid(String? val) {
      if (val == null) return null;
      final trimmed = val.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'unknown' || trimmed.toLowerCase() == 'n/a' || trimmed == 'None') return null;
      return trimmed;
    }

    final catId = cleanUuid(categoryId);
    final propTypeId = cleanUuid(propertyTypeId);
    final configId = cleanUuid(configurationId);
    final listTypeId = cleanUuid(listingTypeId);
    final assignTo = cleanUuid(assignedTo);

    final cleanPropTypeIds = propertyTypeIds.map((id) => cleanUuid(id)).whereType<String>().toList();
    final cleanConfigIds = configurationIds.map((id) => cleanUuid(id)).whereType<String>().toList();

    return {
      'customer_name': clientName,
      'mobile': clientMobile,
      'category_id': catId,
      'property_type_id': propTypeId,
      'configuration_id': configId,
      'listing_type_id': listTypeId,
      'budget': (minBudget + maxBudget) / 2,
      'budget_from': minBudget,
      'budget_to': maxBudget,
      'min_area': minArea,
      'max_area': maxArea,
      'area_id': areaIds.isNotEmpty ? cleanUuid(areaIds.first) : null,
      'area_ids': areaIds.map((id) => cleanUuid(id)).whereType<String>().toList(),
      'area_names': areaNames,
      'configuration_ids': cleanConfigIds.isNotEmpty ? cleanConfigIds : (configId != null ? [configId] : null),
      'property_type_ids': cleanPropTypeIds.isNotEmpty ? cleanPropTypeIds : (propTypeId != null ? [propTypeId] : null),
      'remarks': remarks,
      'internal_crm_remarks': remarks,
      'notes': notes,
      'status': status,
      'next_followup_date': nextFollowupDate,
      'assigned_to': assignTo,
      'furnishing_type_ids': furnishingIds,
      'facing_type_ids': facingIds,
      'furnishing_type_id': furnishingIds.isNotEmpty ? cleanUuid(furnishingIds.first) : null,
      'facing_type_id': facingIds.isNotEmpty ? cleanUuid(facingIds.first) : null,
      'lead_source': leadSource,
      'referral_name': referralName,
      'source': formattedSource,
      if (metaLeadId != null) 'meta_lead_id': metaLeadId,
      if (metaPageId != null) 'meta_page_id': metaPageId,
      if (metaFormId != null) 'meta_form_id': metaFormId,
      if (metaCampaignId != null) 'meta_campaign_id': metaCampaignId,
      if (metaCampaignName != null) 'meta_campaign_name': metaCampaignName,
      if (metaAdsetId != null) 'meta_adset_id': metaAdsetId,
      if (metaAdsetName != null) 'meta_adset_name': metaAdsetName,
      if (metaAdId != null) 'meta_ad_id': metaAdId,
      if (metaAdName != null) 'meta_ad_name': metaAdName,
      if (metaCustomFields != null) 'meta_custom_fields': metaCustomFields,
      if (leadQuality != null) 'lead_quality': leadQuality,
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
    String? notes,
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
    String? leadSource,
    String? referralName,
    String? metaLeadId,
    String? metaPageId,
    String? metaFormId,
    String? metaCampaignId,
    String? metaCampaignName,
    String? metaAdsetId,
    String? metaAdsetName,
    String? metaAdId,
    String? metaAdName,
    Map<String, dynamic>? metaCustomFields,
    String? leadQuality,
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
      notes: notes ?? this.notes,
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
      leadSource: leadSource ?? this.leadSource,
      referralName: referralName ?? this.referralName,
      metaLeadId: metaLeadId ?? this.metaLeadId,
      metaPageId: metaPageId ?? this.metaPageId,
      metaFormId: metaFormId ?? this.metaFormId,
      metaCampaignId: metaCampaignId ?? this.metaCampaignId,
      metaCampaignName: metaCampaignName ?? this.metaCampaignName,
      metaAdsetId: metaAdsetId ?? this.metaAdsetId,
      metaAdsetName: metaAdsetName ?? this.metaAdsetName,
      metaAdId: metaAdId ?? this.metaAdId,
      metaAdName: metaAdName ?? this.metaAdName,
      metaCustomFields: metaCustomFields ?? this.metaCustomFields,
      leadQuality: leadQuality ?? this.leadQuality,
    );
  }
}

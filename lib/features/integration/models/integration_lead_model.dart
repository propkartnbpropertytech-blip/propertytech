import 'dart:convert';

/// Represents an incoming lead payload from Meta Lead Ads, Google Sheets, or Webhook APIs.
class IntegrationLeadModel {
  final String id;
  final String source; // 'Meta Ads', 'Google Sheets', 'Webhook API'
  final DateTime receivedAt;
  final Map<String, dynamic> rawJson;
  final String? externalLeadId;
  final bool isDuplicate;
  final String? duplicateReason;
  final String qualityStatus; // 'Pending', 'Qualified', 'Disqualified', 'Converted', 'Junk'
  final String importStatus; // 'Pending', 'Ready', 'Imported', 'Ignored'
  final String? importedClientId;
  final String? metaFeedbackEventId;
  final DateTime? metaFeedbackSentAt;
  final int enquiryCount;
  final String leadType; // 'Property Listing', 'Requirement'
  final String campaignStatus; // 'New', 'Follow up', 'Interested', 'Not interested'
  final DateTime? followupScheduledAt;
  final String? followupRemarks;
  final String? followupStatus;
  final CrmMatchInfo? crmMatch;

  IntegrationLeadModel({
    required this.id,
    required this.source,
    required this.receivedAt,
    required this.rawJson,
    this.externalLeadId,
    this.isDuplicate = false,
    this.duplicateReason,
    this.qualityStatus = 'Pending',
    this.importStatus = 'Pending',
    this.importedClientId,
    this.metaFeedbackEventId,
    this.metaFeedbackSentAt,
    this.enquiryCount = 1,
    String? leadType,
    this.campaignStatus = 'New',
    this.followupScheduledAt,
    this.followupRemarks,
    this.followupStatus,
    this.crmMatch,
  }) : leadType = resolveLeadType(leadType, rawJson);

  /// Resolves lead type between 'Property Listing' and 'Requirement'
  static String resolveLeadType(String? explicitType, Map<String, dynamic> rawJson) {
    if (explicitType != null && explicitType.trim().isNotEmpty) {
      final t = explicitType.toLowerCase().trim();
      if (t.contains('property') || t.contains('listing') || t.contains('owner')) {
        return 'Property Listing';
      }
      if (t.contains('requirement') || t.contains('tenant') || t.contains('buyer')) {
        return 'Requirement';
      }
      return explicitType;
    }
    return classifyLeadTypeFromRaw(rawJson);
  }

  /// Classifies lead type from raw payload keys and values
  static String classifyLeadTypeFromRaw(Map<String, dynamic> rawJson) {
    final rawStr = jsonEncode(rawJson).toLowerCase();

    // 1. Explicit owner keywords
    if (rawStr.contains('rent out') ||
        rawStr.contains('rent_out') ||
        rawStr.contains('property located') ||
        rawStr.contains('where_is_your_property_located') ||
        rawStr.contains('expected monthly rent') ||
        rawStr.contains('expected_monthly_rent') ||
        rawStr.contains('rental property') ||
        rawStr.contains('complete_address_of_your_property') ||
        rawStr.contains('what_type_of_property_are_you_looking_to_rent_out') ||
        rawStr.contains('what_type_of_property_are_you_looking_to_sell')) {
      return 'Property Listing';
    }

    // 2. Explicit tenant keywords
    if (rawStr.contains('monthly_rental_budget') ||
        rawStr.contains('monthly rental budget') ||
        rawStr.contains('type_of_home') ||
        rawStr.contains('what_type_of_home') ||
        rawStr.contains('who_will_be_staying') ||
        rawStr.contains('which_area_are_you_looking') ||
        rawStr.contains('which_location_are_you_looking')) {
      return 'Requirement';
    }

    // 3. Fallback: check campaign or form name if present
    final campaign = (rawJson['campaign_name'] ?? rawJson['Campaign Name'] ?? '').toString().toLowerCase();
    final form = (rawJson['form_name'] ?? rawJson['Form Name'] ?? '').toString().toLowerCase();
    if (campaign.contains('listing') || campaign.contains('owner') || form.contains('listing') || form.contains('owner') || form.contains('rent out')) {
      return 'Property Listing';
    }

    return 'Requirement';
  }

  /// Extract cell value by dynamic key with intelligent alias resolution
  dynamic getValue(String key) {
    if (rawJson.containsKey(key)) {
      final val = rawJson[key];
      if (val != null && val.toString().trim().isNotEmpty) return val;
    }
    // Case-insensitive fallback
    for (final entry in rawJson.entries) {
      if (entry.key.toLowerCase().trim() == key.toLowerCase().trim()) {
        final val = entry.value;
        if (val != null && val.toString().trim().isNotEmpty) return val;
      }
    }

    final normKey = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    // 1. Client / Owner Name
    if (normKey == 'clientownername' ||
        normKey == 'fullname' ||
        normKey == 'name' ||
        normKey == 'clientname' ||
        normKey == 'customername' ||
        normKey == 'buyername' ||
        normKey == 'ownername' ||
        normKey == 'nameofclient') {
      const candidates = [
        'full_name',
        'name',
        'Name',
        'Client Name',
        'Customer Name',
        'Owner Name',
        'buyer_name',
        'Name of client',
      ];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 2. Phone / Mobile Number
    if (normKey == 'phonenumber' ||
        normKey == 'phone' ||
        normKey == 'mobile' ||
        normKey == 'mobilenumber' ||
        normKey == 'contact' ||
        normKey == 'contactnumber' ||
        normKey == 'number' ||
        normKey == 'ownermobile') {
      const candidates = [
        'phone_number',
        'phone',
        'Phone',
        'Phone Number',
        'mobile',
        'Mobile',
        'Number',
        'contact',
        'Contact',
        'contact_number',
      ];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 3. Property Type (Owner Listing: what type of property looking to rent out / sell)
    if (normKey == 'propertytype' || normKey == 'typeofproperty') {
      const candidates = [
        'what_type_of_property_are_you_looking_to_rent_out?',
        'what_type_of_property_are_you_looking_to_sell?',
        'property_type',
        'Property Type',
        'type',
        'Type',
        'configuration',
        'Configuration',
        'bhk',
        'BHK',
        '',
      ];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 4. Configuration (Tenant Requirement: what type of home looking for / BHK)
    if (normKey == 'configuration' ||
        normKey == 'bhk' ||
        normKey == 'typeofhome' ||
        normKey == 'hometype') {
      const candidates = [
        'what_type_of_home_are_you_looking_for?',
        'configuration',
        'Configuration',
        'bhk',
        'BHK',
        'type_of_home',
        'home_type',
        'type',
        'property_type',
      ];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 5. Expected Rent (Owner Listing: expected monthly rent)
    if (normKey == 'expectedrent' ||
        normKey == 'expectedmonthlyrent' ||
        normKey == 'rent' ||
        normKey == 'monthlyrent') {
      const candidates = [
        'what_is_your_expected_monthly_rent?',
        'expected_monthly_rent',
        'expected_rent',
        'Expected Rent',
        'monthly_rent',
        'rent',
        'Rent',
        'what_is_the_complete_address_of_your_property?',
      ];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 6. Monthly Budget (Tenant Requirement: rental budget)
    if (normKey == 'monthlybudget' ||
        normKey == 'monthlyrentalbudget' ||
        normKey == 'budget' ||
        normKey == 'rentalbudget' ||
        normKey == 'price') {
      const candidates = [
        'what_is_your_monthly_rental_budget?',
        'monthly_rental_budget',
        'Monthly Budget',
        'budget',
        'Budget',
        'price',
        'Price',
      ];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 7. Property Location (Owner Listing: where property is located / address)
    if (normKey == 'propertylocation' ||
        normKey == 'whereisyourpropertylocated' ||
        normKey == 'propertyaddress' ||
        normKey == 'completeaddress' ||
        normKey == 'whatisthecompleteaddressofyourproperty') {
      const candidates = [
        'where_is_your_property_located?',
        'what_is_the_complete_address_of_your_property?',
        'property_location',
        'Property Location',
        'location',
        'Location',
        'area',
        'Area',
        'locality',
        'address',
      ];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 8. Preferred Area (Tenant Requirement: which area / location looking for)
    if (normKey == 'preferredarea' ||
        normKey == 'whichareaareyoulookingfor' ||
        normKey == 'whichlocationareyoulookingfor' ||
        normKey == 'lookingarea' ||
        normKey == 'lookinglocation' ||
        normKey == 'area' ||
        normKey == 'location') {
      const candidates = [
        'which_area_are_you_looking_for?',
        'which_location_are_you_looking_for?',
        'preferred_area',
        'Preferred Area',
        'location',
        'Location',
        'area',
        'Area',
        'locality',
      ];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 9. City
    if (normKey == 'city' || normKey == 'targetcity') {
      const candidates = ['city', 'City', 'target_city'];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 10. Email
    if (normKey == 'email' || normKey == 'emailid' || normKey == 'emailaddress') {
      const candidates = ['email', 'Email', 'Email ID', 'email_id', 'email_address'];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 11. Campaign Name
    if (normKey == 'campaignname' || normKey == 'campaign') {
      const candidates = ['Campaign Name', 'campaign_name', 'campaign', 'utm_campaign'];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 12. Form Name
    if (normKey == 'formname' || normKey == 'form') {
      const candidates = ['form_name', 'Form Name', 'form'];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 13. Ad Name
    if (normKey == 'adname' || normKey == 'ad') {
      const candidates = ['Ad Name', 'ad_name', 'ad'];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 14. Who will be staying (Tenant Requirement)
    if (normKey == 'whowillbestaying' ||
        normKey == 'whowillstay' ||
        normKey == 'occupants' ||
        normKey == 'tenanttype' ||
        normKey == 'stayingwith') {
      const candidates = [
        'who_will_be_staying_in_the_property?',
        'occupants',
        'staying_with',
        'tenant_type',
        'who_will_stay',
      ];
      for (final c in candidates) {
        if (rawJson.containsKey(c) && rawJson[c] != null && rawJson[c].toString().trim().isNotEmpty) {
          return rawJson[c];
        }
      }
    }

    // 15. Lead Arrival Date / Timestamp
    if (normKey == 'receivedon' ||
        normKey == 'date' ||
        normKey == 'receiveddate' ||
        normKey == 'arrivaltime' ||
        normKey == 'createdat' ||
        normKey == 'leadtime') {
      return formattedReceivedAt;
    }

    // Fuzzy normalized search across all rawJson keys
    for (final entry in rawJson.entries) {
      final k = entry.key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (k.isNotEmpty && k == normKey) {
        return entry.value;
      }
    }

    return null;
  }

  /// Formatted local arrival date and time (e.g. "11 Sep 2026, 09:09 AM" or "Today, 09:09 AM")
  String get formattedReceivedAt {
    final local = receivedAt.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = local.hour == 0 ? 12 : (local.hour > 12 ? local.hour - 12 : local.hour);
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = local.minute.toString().padLeft(2, '0');
    final now = DateTime.now();

    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return 'Today, $hour:$minuteStr $period';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (local.year == yesterday.year && local.month == yesterday.month && local.day == yesterday.day) {
      return 'Yesterday, $hour:$minuteStr $period';
    }
    return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$minuteStr $period';
  }

  /// Relative elapsed time (e.g. "5m ago", "2h ago", "1d ago")
  String get relativeTimeAgo {
    final diff = DateTime.now().difference(receivedAt.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1d ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  /// Freshness level badge
  String get freshnessBadge {
    final diff = DateTime.now().difference(receivedAt.toLocal());
    if (diff.inHours < 24) return '⚡ Fresh Today';
    if (diff.inHours < 48) return '🔥 Recent';
    return '📅 Standard';
  }

  /// Concise 1-sentence executive summary for real estate agents
  String get leadSummary {
    final isProp = leadType == 'Property Listing';
    final name = getStringValue(isProp ? 'Client / Owner Name' : 'Client Name');
    final config = getStringValue(isProp ? 'Property Type' : 'Configuration');
    final budget = getStringValue(isProp ? 'Expected Rent' : 'Monthly Budget');
    final loc = getStringValue(isProp ? 'Property Location' : 'Preferred Area');
    final city = getStringValue('City');

    final locationStr = [loc, city].where((s) => s.isNotEmpty).join(', ');

    if (leadType == 'Property Listing') {
      final parts = <String>[];
      if (name.isNotEmpty) parts.add(name);
      parts.add('wants to rent out');
      if (config.isNotEmpty) parts.add(config);
      if (locationStr.isNotEmpty) parts.add('in $locationStr');
      if (budget.isNotEmpty) parts.add('• Expected Rent: $budget');
      parts.add('• Arrived: $formattedReceivedAt');
      return parts.join(' ');
    } else {
      final staying = getStringValue('Who Will Be Staying');
      final parts = <String>[];
      if (name.isNotEmpty) parts.add(name);
      parts.add('seeking');
      if (config.isNotEmpty) parts.add(config);
      if (locationStr.isNotEmpty) parts.add('in $locationStr');
      if (budget.isNotEmpty) parts.add('• Budget: $budget');
      if (staying.isNotEmpty) parts.add('• For: $staying');
      parts.add('• Arrived: $formattedReceivedAt');
      return parts.join(' ');
    }
  }

  /// Helper to get formatted, human-friendly string value
  String getStringValue(String key) {
    final val = getValue(key);
    if (val == null) return '';
    if (val is List) return val.join(', ');
    if (val is Map) return jsonEncode(val);
    String str = val.toString().trim();
    if (str.isEmpty) return '';

    // Smart formatting for common enum-like raw values
    final lower = str.toLowerCase();

    // 1. BHK formatting
    if (lower == '1_bhk' || lower == '1bhk') return '1 BHK';
    if (lower == '2_bhk' || lower == '2bhk') return '2 BHK';
    if (lower == '3_bhk' || lower == '3bhk') return '3 BHK';
    if (lower == '4_bhk' || lower == '4bhk') return '4 BHK';
    if (lower == '4_bhk_/_premium' || lower == '4_bhk_/_penthouse') return '4 BHK / Premium';

    // 2. Location formatting
    if (lower == 'other_area') return 'Other Area';
    if (lower == 'sg_highway_/_thaltej') return 'SG Highway / Thaltej';
    if (lower == 'bopal_/_south-west_ahmedabad') return 'Bopal / South-West Ahmedabad';
    if (lower == 'west_ahmedabad') return 'West Ahmedabad';
    if (lower == 'any_suitable_location') return 'Any Suitable Location';

    // 3. Occupants formatting
    if (lower == 'family') return 'Family';
    if (lower == 'working_professionals') return 'Working Professionals';
    if (lower == 'students') return 'Students';

    // Clean up underscores if it looks like an internal slug
    if (str.contains('_') && !str.contains(' ') && !str.contains('@')) {
      return str
          .split('_')
          .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
          .join(' ');
    }

    return str;
  }

  /// Create a copy with modified fields
  IntegrationLeadModel copyWith({
    String? id,
    String? source,
    DateTime? receivedAt,
    Map<String, dynamic>? rawJson,
    String? externalLeadId,
    bool? isDuplicate,
    String? duplicateReason,
    String? qualityStatus,
    String? importStatus,
    String? importedClientId,
    String? metaFeedbackEventId,
    DateTime? metaFeedbackSentAt,
    int? enquiryCount,
    String? leadType,
    String? campaignStatus,
    DateTime? followupScheduledAt,
    String? followupRemarks,
    String? followupStatus,
    CrmMatchInfo? crmMatch,
  }) {
    return IntegrationLeadModel(
      id: id ?? this.id,
      source: source ?? this.source,
      receivedAt: receivedAt ?? this.receivedAt,
      rawJson: rawJson ?? Map<String, dynamic>.from(this.rawJson),
      externalLeadId: externalLeadId ?? this.externalLeadId,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      duplicateReason: duplicateReason ?? this.duplicateReason,
      qualityStatus: qualityStatus ?? this.qualityStatus,
      importStatus: importStatus ?? this.importStatus,
      importedClientId: importedClientId ?? this.importedClientId,
      metaFeedbackEventId: metaFeedbackEventId ?? this.metaFeedbackEventId,
      metaFeedbackSentAt: metaFeedbackSentAt ?? this.metaFeedbackSentAt,
      enquiryCount: enquiryCount ?? this.enquiryCount,
      leadType: leadType ?? this.leadType,
      campaignStatus: campaignStatus ?? this.campaignStatus,
      followupScheduledAt: followupScheduledAt ?? this.followupScheduledAt,
      followupRemarks: followupRemarks ?? this.followupRemarks,
      followupStatus: followupStatus ?? this.followupStatus,
      crmMatch: crmMatch ?? this.crmMatch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'received_at': receivedAt.toIso8601String(),
      'raw_json': rawJson,
      'external_lead_id': externalLeadId,
      'is_duplicate': isDuplicate,
      'duplicate_reason': duplicateReason,
      'quality_status': qualityStatus,
      'import_status': importStatus,
      'imported_client_id': importedClientId,
      'meta_feedback_event_id': metaFeedbackEventId,
      'meta_feedback_sent_at': metaFeedbackSentAt?.toIso8601String(),
      'enquiry_count': enquiryCount,
      'lead_type': leadType,
      'campaign_status': campaignStatus,
      'followup_scheduled_at': followupScheduledAt?.toIso8601String(),
      'followup_remarks': followupRemarks,
      'followup_status': followupStatus,
      'crm_match': crmMatch?.toJson(),
    };
  }

  factory IntegrationLeadModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> raw = {};
    if (json['raw_json'] is Map<String, dynamic>) {
      raw = Map<String, dynamic>.from(json['raw_json']);
    } else if (json['raw_json'] is Map) {
      raw = Map<String, dynamic>.from(json['raw_json'] as Map);
    } else if (json['raw_json'] is String && (json['raw_json'] as String).isNotEmpty) {
      try {
        raw = Map<String, dynamic>.from(jsonDecode(json['raw_json'] as String));
      } catch (_) {}
    }

    final explicitType = json['lead_type']?.toString();
    final type = resolveLeadType(explicitType, raw);

    final latestFu = json['latest_followup'] is Map<String, dynamic>
        ? json['latest_followup'] as Map<String, dynamic>
        : null;

    return IntegrationLeadModel(
      id: json['id']?.toString() ?? '',
      source: json['source']?.toString() ?? 'Meta Ads',
      receivedAt: json['received_at'] != null
          ? DateTime.tryParse(json['received_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      rawJson: raw,
      externalLeadId: json['external_lead_id']?.toString(),
      isDuplicate: json['is_duplicate'] == true,
      duplicateReason: json['duplicate_reason']?.toString(),
      qualityStatus: json['quality_status']?.toString() ?? 'Pending',
      importStatus: json['import_status']?.toString() ?? 'Pending',
      importedClientId: json['imported_client_id']?.toString(),
      metaFeedbackEventId: json['meta_feedback_event_id']?.toString(),
      metaFeedbackSentAt: json['meta_feedback_sent_at'] != null
          ? DateTime.tryParse(json['meta_feedback_sent_at'].toString())
          : null,
      enquiryCount: int.tryParse(json['enquiry_count']?.toString() ?? '1') ?? 1,
      leadType: type,
      campaignStatus: json['campaign_status']?.toString() ?? 'New',
      followupScheduledAt: latestFu != null && latestFu['scheduled_at'] != null
          ? DateTime.tryParse(latestFu['scheduled_at'].toString())
          : (json['followup_scheduled_at'] != null
              ? DateTime.tryParse(json['followup_scheduled_at'].toString())
              : null),
      followupRemarks: latestFu?['remarks']?.toString() ?? json['followup_remarks']?.toString(),
      followupStatus: latestFu?['status']?.toString() ?? json['followup_status']?.toString(),
      crmMatch: json['crm_match'] is Map<String, dynamic>
          ? CrmMatchInfo.fromJson(Map<String, dynamic>.from(json['crm_match']))
          : null,
    );
  }
}

/// Real-time cross-table comparison result against requirements and properties tables
class CrmMatchInfo {
  final bool inCrm;
  final String? table; // 'requirements' or 'properties'
  final String? recordId;
  final String? code;
  final String? name;
  final String? status;
  final String? details;
  final DateTime? createdAt;

  const CrmMatchInfo({
    this.inCrm = false,
    this.table,
    this.recordId,
    this.code,
    this.name,
    this.status,
    this.details,
    this.createdAt,
  });

  factory CrmMatchInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CrmMatchInfo(inCrm: false);
    return CrmMatchInfo(
      inCrm: json['in_crm'] == true,
      table: json['table']?.toString(),
      recordId: json['record_id']?.toString(),
      code: json['code']?.toString(),
      name: json['name']?.toString(),
      status: json['status']?.toString(),
      details: json['details']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'in_crm': inCrm,
    'table': table,
    'record_id': recordId,
    'code': code,
    'name': name,
    'status': status,
    'details': details,
    'created_at': createdAt?.toIso8601String(),
  };
}

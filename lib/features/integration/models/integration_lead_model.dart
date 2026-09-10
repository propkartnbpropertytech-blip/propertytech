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
    this.leadType = 'Requirement',
    this.crmMatch,
  });

  /// Extract cell value by dynamic key
  dynamic getValue(String key) {
    if (rawJson.containsKey(key)) {
      return rawJson[key];
    }
    // Case-insensitive fallback
    for (final entry in rawJson.entries) {
      if (entry.key.toLowerCase().trim() == key.toLowerCase().trim()) {
        return entry.value;
      }
    }
    return null;
  }

  /// Helper to get formatted string value
  String getStringValue(String key) {
    final val = getValue(key);
    if (val == null) return '';
    if (val is List) return val.join(', ');
    if (val is Map) return jsonEncode(val);
    return val.toString();
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
      'crm_match': crmMatch?.toJson(),
    };
  }

  factory IntegrationLeadModel.fromJson(Map<String, dynamic> json) {
    String type = json['lead_type']?.toString() ?? '';
    if (type.isEmpty) {
      final raw = json['raw_json'];
      final rawStr = raw is Map ? jsonEncode(raw).toLowerCase() : (raw?.toString().toLowerCase() ?? '');
      if (rawStr.contains('rent out') ||
          rawStr.contains('property located') ||
          rawStr.contains('expected monthly rent') ||
          rawStr.contains('expected_monthly_rent') ||
          rawStr.contains('rental property')) {
        type = 'Property Listing';
      } else {
        type = 'Requirement';
      }
    }

    return IntegrationLeadModel(
      id: json['id']?.toString() ?? '',
      source: json['source']?.toString() ?? 'Meta Ads',
      receivedAt: json['received_at'] != null
          ? DateTime.tryParse(json['received_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      rawJson: json['raw_json'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['raw_json'])
          : (json['raw_json'] is String
              ? Map<String, dynamic>.from(jsonDecode(json['raw_json']))
              : {}),
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

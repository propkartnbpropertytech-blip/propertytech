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
    };
  }

  factory IntegrationLeadModel.fromJson(Map<String, dynamic> json) {
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
    );
  }
}

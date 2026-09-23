import '../../integration/models/integration_lead_model.dart';

class CampaignFollowupModel {
  final String id;
  final String leadId;
  final String leadType;
  final String clientName;
  final String mobile;
  final DateTime scheduledAt;
  final String remarks;
  final String status;
  final DateTime createdAt;
  final IntegrationLeadModel? lead;
  final String? telecallerName;

  CampaignFollowupModel({
    required this.id,
    required this.leadId,
    required this.leadType,
    required this.clientName,
    required this.mobile,
    required this.scheduledAt,
    required this.remarks,
    this.status = 'Pending',
    required this.createdAt,
    this.lead,
    this.telecallerName,
  });

  bool get isToday {
    final now = DateTime.now();
    return scheduledAt.year == now.year &&
        scheduledAt.month == now.month &&
        scheduledAt.day == now.day;
  }

  bool get isFuture {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return scheduledAt.isAfter(endOfToday);
  }

  bool get isPast {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    return scheduledAt.isBefore(startOfToday) && status == 'Pending';
  }

  factory CampaignFollowupModel.fromJson(Map<String, dynamic> json) {
    return CampaignFollowupModel(
      id: json['id']?.toString() ?? '',
      leadId: json['lead_id']?.toString() ?? '',
      leadType: json['lead_type']?.toString() ?? 'Requirement',
      clientName: json['client_name']?.toString() ?? 'Campaign Lead',
      mobile: json['mobile']?.toString() ?? '',
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.tryParse(json['scheduled_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      remarks: json['remarks']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lead: json['lead'] is Map<String, dynamic>
          ? IntegrationLeadModel.fromJson(Map<String, dynamic>.from(json['lead']))
          : null,
      telecallerName: json['telecaller_name']?.toString() ??
          (json['telecaller'] is Map ? json['telecaller']['full_name']?.toString() : null) ??
          (json['lead'] is Map
              ? (json['lead']['assigned_telecaller_name'] ??
                      json['lead']['raw_json']?['assigned_telecaller_name'] ??
                      json['lead']['raw_json']?['status_updated_by_name'])
                  ?.toString()
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lead_id': leadId,
      'lead_type': leadType,
      'client_name': clientName,
      'mobile': mobile,
      'scheduled_at': scheduledAt.toIso8601String(),
      'remarks': remarks,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'telecaller_name': telecallerName,
    };
  }
}

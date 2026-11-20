import '../../../core/api/dio_client.dart';

/// A follow-up on a campaign lead: Property Listing (`property_listing_lead_followups`)
/// or Requirement (`campaign_requirement_lead_followups`).
class ListingLeadFollowup {
  final String id;
  final String leadId;
  final String? leadType;
  final String? requirementId;
  final String salesUserId;
  final DateTime followupDate;
  final String status;
  final String? remarks;
  final String? outcomeRemarks;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final String? customerName;
  final String? phone;
  final String? salesUserName;
  final String? createdByName;
  final String? propertyType;
  final String? propertyLocation;
  final String? campaignName;
  final bool isToday;
  final bool isDue;
  final bool isFuture;

  const ListingLeadFollowup({
    required this.id,
    required this.leadId,
    this.leadType,
    this.requirementId,
    required this.salesUserId,
    required this.followupDate,
    required this.status,
    this.remarks,
    this.outcomeRemarks,
    this.completedAt,
    this.cancelledAt,
    this.createdAt,
    this.customerName,
    this.phone,
    this.salesUserName,
    this.createdByName,
    this.propertyType,
    this.propertyLocation,
    this.campaignName,
    this.isToday = false,
    this.isDue = false,
    this.isFuture = false,
  });

  bool get isPending => status == 'Pending';
  bool get isRequirementLead => leadType == 'Requirement';

  static DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();
  static String? _text(dynamic v) {
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  factory ListingLeadFollowup.fromJson(Map<String, dynamic> json) => ListingLeadFollowup(
        id: json['id'].toString(),
        leadId: json['lead_id'].toString(),
        leadType: _text(json['lead_type']),
        requirementId: _text(json['requirement_id']),
        salesUserId: json['sales_user_id']?.toString() ?? '',
        followupDate: _date(json['followup_date']) ?? DateTime.now(),
        status: json['status']?.toString() ?? 'Pending',
        remarks: _text(json['remarks']),
        outcomeRemarks: _text(json['outcome_remarks']),
        completedAt: _date(json['completed_at']),
        cancelledAt: _date(json['cancelled_at']),
        createdAt: _date(json['created_at']),
        customerName: _text(json['customer_name']),
        phone: _text(json['phone']),
        salesUserName: _text(json['sales_user_name']),
        createdByName: _text(json['created_by_name']),
        propertyType: _text(json['property_type']),
        propertyLocation: _text(json['property_location']),
        campaignName: _text(json['campaign_name']),
        isToday: json['is_today'] == true,
        isDue: json['is_due'] == true,
        isFuture: json['is_future'] == true,
      );
}

class ListingFollowupCounts {
  final int today;
  final int due;
  final int future;
  final int all;

  const ListingFollowupCounts({this.today = 0, this.due = 0, this.future = 0, this.all = 0});

  static int _int(dynamic v) => v is int ? v : int.tryParse('$v') ?? 0;

  factory ListingFollowupCounts.fromJson(Map<String, dynamic> json) => ListingFollowupCounts(
        today: _int(json['today']),
        due: _int(json['due']),
        future: _int(json['future']),
        all: _int(json['all']),
      );

  /// Count for a Follow-ups sub-tab key ('Today', 'Due', 'Future', 'AllClients').
  int forTab(String tab) => switch (tab) {
        'Due' => due,
        'Future' => future,
        'AllClients' => all,
        _ => today,
      };
}

class ListingFollowupsException implements Exception {
  final String message;
  const ListingFollowupsException(this.message);
  @override
  String toString() => message;
}

class ListingLeadFollowupsService {
  static const _path = '/listing-lead-followups';

  static int get _tzOffsetMinutes => DateTime.now().timeZoneOffset.inMinutes;

  static Future<T> _call<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Could not reach the server. Please try again.';
      throw ListingFollowupsException(message);
    }
  }

  static Map<String, dynamic> _data(Response res) {
    final body = res.data;
    if (body is Map && body['data'] is Map) return Map<String, dynamic>.from(body['data'] as Map);
    throw const ListingFollowupsException('Unexpected server response.');
  }

  static Future<({List<ListingLeadFollowup> items, ListingFollowupCounts counts})> fetch() {
    return _call(() async {
      final res = await DioClient.dio.get(_path, queryParameters: {'tzOffsetMinutes': _tzOffsetMinutes});
      final data = _data(res);
      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => ListingLeadFollowup.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      final counts = data['counts'] is Map
          ? ListingFollowupCounts.fromJson(Map<String, dynamic>.from(data['counts'] as Map))
          : const ListingFollowupCounts();
      return (items: items, counts: counts);
    });
  }

  /// [supersedePending] completes the lead's open follow-up first (Re-Follow-Up).
  static Future<void> create({
    required String leadId,
    required DateTime when,
    String? remarks,
    bool supersedePending = false,
  }) {
    return _call(() => DioClient.dio.post(_path, data: {
          'leadId': leadId,
          'followupDate': when.toUtc().toIso8601String(),
          'remarks': remarks,
          'supersedePending': supersedePending,
          'tzOffsetMinutes': _tzOffsetMinutes,
        }));
  }

  static Future<void> reschedule(String id, {required DateTime when, String? remarks}) {
    return _call(() => DioClient.dio.patch('$_path/$id', data: {
          'followupDate': when.toUtc().toIso8601String(),
          'remarks': remarks,
          'tzOffsetMinutes': _tzOffsetMinutes,
        }));
  }

  static Future<void> complete(String id, {String? outcomeRemarks, DateTime? nextWhen, String? nextRemarks}) {
    return _call(() => DioClient.dio.post('$_path/$id/complete', data: {
          'outcomeRemarks': outcomeRemarks,
          if (nextWhen != null) 'nextFollowupDate': nextWhen.toUtc().toIso8601String(),
          if (nextWhen != null) 'nextRemarks': nextRemarks,
          'tzOffsetMinutes': _tzOffsetMinutes,
        }));
  }

  static Future<void> cancel(String id, {String? reason}) {
    return _call(() => DioClient.dio.post('$_path/$id/cancel', data: {'reason': reason}));
  }
}

/// Campaign Requirement lead follow-ups, stored apart from the Leads page follow-ups.
class RequirementLeadFollowupsService {
  static const _path = '/campaign-requirement-followups';

  static int get _tzOffsetMinutes => DateTime.now().timeZoneOffset.inMinutes;

  static Future<({List<ListingLeadFollowup> items, ListingFollowupCounts counts})> fetch({String? requirementId}) {
    return ListingLeadFollowupsService._call(() async {
      final res = await DioClient.dio.get(_path, queryParameters: {
        'tzOffsetMinutes': _tzOffsetMinutes,
        if (requirementId != null && requirementId.isNotEmpty) 'requirementId': requirementId,
      });
      final data = ListingLeadFollowupsService._data(res);
      final items = (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => ListingLeadFollowup.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      final counts = data['counts'] is Map
          ? ListingFollowupCounts.fromJson(Map<String, dynamic>.from(data['counts'] as Map))
          : const ListingFollowupCounts();
      return (items: items, counts: counts);
    });
  }

  /// [supersedePending] completes the lead's open follow-up first (Re-Followup).
  static Future<void> create({
    required String requirementId,
    required DateTime when,
    String? remarks,
    bool supersedePending = false,
  }) {
    return ListingLeadFollowupsService._call(() => DioClient.dio.post(_path, data: {
          'requirementId': requirementId,
          'followupDate': when.toUtc().toIso8601String(),
          'remarks': remarks,
          'supersedePending': supersedePending,
          'tzOffsetMinutes': _tzOffsetMinutes,
        }));
  }

  static Future<void> reschedule(String id, {required DateTime when, String? remarks}) {
    return ListingLeadFollowupsService._call(() => DioClient.dio.patch('$_path/$id', data: {
          'followupDate': when.toUtc().toIso8601String(),
          'remarks': remarks,
          'tzOffsetMinutes': _tzOffsetMinutes,
        }));
  }

  static Future<void> complete(String id, {String? outcomeRemarks, DateTime? nextWhen, String? nextRemarks}) {
    return ListingLeadFollowupsService._call(() => DioClient.dio.post('$_path/$id/complete', data: {
          'outcomeRemarks': outcomeRemarks,
          if (nextWhen != null) 'nextFollowupDate': nextWhen.toUtc().toIso8601String(),
          if (nextWhen != null) 'nextRemarks': nextRemarks,
          'tzOffsetMinutes': _tzOffsetMinutes,
        }));
  }

  static Future<void> cancel(String id, {String? reason}) {
    return ListingLeadFollowupsService._call(() => DioClient.dio.post('$_path/$id/cancel', data: {'reason': reason}));
  }
}

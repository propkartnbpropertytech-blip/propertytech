class AuditLogModel {
  final String id;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userRole;
  final String? adminId;
  final String? organizationId;
  final String module;
  final String action;
  final String? recordType;
  final String? recordId;
  final String? eventName;
  final String? path;
  final dynamic oldData;
  final dynamic newData;
  final String? description;
  final Map<String, dynamic>? details;
  final int dwellMs;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceInfo;
  final String? sessionId;
  final DateTime createdAt;

  const AuditLogModel({
    required this.id,
    this.userId,
    this.userName,
    this.userEmail,
    this.userRole,
    this.adminId,
    this.organizationId,
    required this.module,
    required this.action,
    this.recordType,
    this.recordId,
    this.eventName,
    this.path,
    this.oldData,
    this.newData,
    this.description,
    this.details,
    this.dwellMs = 0,
    this.ipAddress,
    this.userAgent,
    this.deviceInfo,
    this.sessionId,
    required this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? parsedDetails;
    if (json['details'] is Map) {
      parsedDetails = Map<String, dynamic>.from(json['details'] as Map);
    }

    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString()).toLocal()
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return AuditLogModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      userName: json['user_name']?.toString(),
      userEmail: json['user_email']?.toString(),
      userRole: json['user_role']?.toString(),
      adminId: json['admin_id']?.toString(),
      organizationId: json['organization_id']?.toString(),
      module: json['module']?.toString() ?? 'General',
      action: json['action']?.toString() ?? 'UNKNOWN',
      recordType: json['record_type']?.toString(),
      recordId: json['record_id']?.toString(),
      eventName: json['event_name']?.toString(),
      path: json['path']?.toString(),
      oldData: json['old_data'],
      newData: json['new_data'],
      description: json['description']?.toString(),
      details: parsedDetails,
      dwellMs: int.tryParse(json['dwell_ms']?.toString() ?? '0') ?? 0,
      ipAddress: json['ip_address']?.toString(),
      userAgent: json['user_agent']?.toString(),
      deviceInfo: json['device_info']?.toString(),
      sessionId: json['session_id']?.toString(),
      createdAt: parsedDate,
    );
  }
}

class AuditTelemetryStats {
  final int total;
  final int pageViews;
  final int propertyTouches;
  final int propertyShares;
  final int searches;
  final int dwells;

  const AuditTelemetryStats({
    this.total = 0,
    this.pageViews = 0,
    this.propertyTouches = 0,
    this.propertyShares = 0,
    this.searches = 0,
    this.dwells = 0,
  });

  factory AuditTelemetryStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AuditTelemetryStats();
    return AuditTelemetryStats(
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      pageViews: int.tryParse(json['pageViews']?.toString() ?? '0') ?? 0,
      propertyTouches: int.tryParse(json['propertyTouches']?.toString() ?? '0') ?? 0,
      propertyShares: int.tryParse(json['propertyShares']?.toString() ?? '0') ?? 0,
      searches: int.tryParse(json['searches']?.toString() ?? '0') ?? 0,
      dwells: int.tryParse(json['dwells']?.toString() ?? '0') ?? 0,
    );
  }
}

class UserHierarchyItem {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? adminId;
  final String? adminName;

  const UserHierarchyItem({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.adminId,
    this.adminName,
  });

  factory UserHierarchyItem.fromJson(Map<String, dynamic> json) {
    return UserHierarchyItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Unknown',
      adminId: json['adminId']?.toString(),
      adminName: json['adminName']?.toString(),
    );
  }
}

class UsersHierarchyResponse {
  final List<UserHierarchyItem> admins;
  final List<UserHierarchyItem> telecallers;
  final List<UserHierarchyItem> salesUsers;
  final List<UserHierarchyItem> allUsers;

  const UsersHierarchyResponse({
    this.admins = const [],
    this.telecallers = const [],
    this.salesUsers = const [],
    this.allUsers = const [],
  });

  factory UsersHierarchyResponse.fromJson(Map<String, dynamic> json) {
    List<UserHierarchyItem> parseList(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((item) => UserHierarchyItem.fromJson(Map<String, dynamic>.from(item as Map))).toList();
    }

    return UsersHierarchyResponse(
      admins: parseList(json['admins']),
      telecallers: parseList(json['telecallers']),
      salesUsers: parseList(json['salesUsers']),
      allUsers: parseList(json['allUsers']),
    );
  }
}

class AuditLogsResponse {
  final List<AuditLogModel> logs;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final AuditTelemetryStats stats;

  const AuditLogsResponse({
    required this.logs,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.stats,
  });

  factory AuditLogsResponse.fromJson(Map<String, dynamic> json) {
    final rawLogs = json['logs'] as List? ?? [];
    return AuditLogsResponse(
      logs: rawLogs.map((l) => AuditLogModel.fromJson(Map<String, dynamic>.from(l as Map))).toList(),
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      page: int.tryParse(json['page']?.toString() ?? '1') ?? 1,
      limit: int.tryParse(json['limit']?.toString() ?? '50') ?? 50,
      totalPages: int.tryParse(json['totalPages']?.toString() ?? '1') ?? 1,
      stats: AuditTelemetryStats.fromJson(json['stats'] as Map<String, dynamic>?),
    );
  }
}

class CampaignConnectionModel {
  final String id;
  final String? organizationId;
  final String providerType; // 'HOUSING', 'META', 'GOOGLE_SHEETS', 'CUSTOM_WEBHOOK'
  final String displayName;
  final String status; // 'CONNECTED', 'DISCONNECTED', 'SYNCING', 'ERROR', 'NEVER_SYNCED'
  final bool isActive;
  final Map<String, dynamic> credentials;
  final Map<String, dynamic> config;
  final DateTime? lastSyncAt;
  final String? lastError;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CampaignConnectionModel({
    required this.id,
    this.organizationId,
    required this.providerType,
    required this.displayName,
    this.status = 'DISCONNECTED',
    this.isActive = true,
    this.credentials = const {},
    this.config = const {},
    this.lastSyncAt,
    this.lastError,
    this.createdAt,
    this.updatedAt,
  });

  bool get isConnected => status == 'CONNECTED';
  bool get isSyncing => status == 'SYNCING';
  bool get isError => status == 'ERROR';
  bool get isNeverSynced => status == 'NEVER_SYNCED';

  factory CampaignConnectionModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> creds = {};
    if (json['credentials_info'] is Map) {
      creds = Map<String, dynamic>.from(json['credentials_info'] as Map);
    } else if (json['credentials'] is Map) {
      creds = Map<String, dynamic>.from(json['credentials'] as Map);
    }

    return CampaignConnectionModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString(),
      providerType: (json['provider_type']?.toString() ?? 'CUSTOM_WEBHOOK').toUpperCase(),
      displayName: json['display_name']?.toString() ?? 'Campaign Integration',
      status: (json['status']?.toString() ?? 'DISCONNECTED').toUpperCase(),
      isActive: json['enabled'] == true || json['is_active'] == true,
      credentials: creds,
      config: json['config'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['config'])
          : (json['config'] is Map ? Map<String, dynamic>.from(json['config'] as Map) : {}),
      lastSyncAt: json['last_sync_at'] != null ? DateTime.tryParse(json['last_sync_at'].toString()) : null,
      lastError: json['last_error']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'provider_type': providerType,
      'display_name': displayName,
      'status': status,
      'enabled': isActive,
      'is_active': isActive,
      'credentials': credentials,
      'config': config,
      'last_sync_at': lastSyncAt?.toIso8601String(),
      'last_error': lastError,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  CampaignConnectionModel copyWith({
    String? id,
    String? organizationId,
    String? providerType,
    String? displayName,
    String? status,
    bool? isActive,
    Map<String, dynamic>? credentials,
    Map<String, dynamic>? config,
    DateTime? lastSyncAt,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampaignConnectionModel(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      providerType: providerType ?? this.providerType,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      credentials: credentials ?? this.credentials,
      config: config ?? this.config,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

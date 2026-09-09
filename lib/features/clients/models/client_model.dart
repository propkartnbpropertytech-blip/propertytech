class ClientModel {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String stage; // 'Lead', 'Contacted', 'Site Visit', 'Negotiation', 'Won', 'Lost'
  final String source; // 'Call', 'Referral', 'Website', 'Ads', 'WhatsApp'
  final String? assignedAgent;
  final String? remarks;
  final DateTime createdAt;

  ClientModel({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.stage,
    required this.source,
    this.assignedAgent,
    this.remarks,
    required this.createdAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      stage: json['stage'] ?? 'Lead',
      source: json['source'] ?? 'Call',
      assignedAgent: json['assignedAgent'],
      remarks: json['remarks'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'stage': stage,
      'source': source,
      'assignedAgent': assignedAgent,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? email,
    String? mobile,
    String? stage,
    String? source,
    String? assignedAgent,
    String? remarks,
    DateTime? createdAt,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      mobile: mobile ?? this.mobile,
      stage: stage ?? this.stage,
      source: source ?? this.source,
      assignedAgent: assignedAgent ?? this.assignedAgent,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

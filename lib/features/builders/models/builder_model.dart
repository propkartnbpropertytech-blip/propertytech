class BuilderModel {
  final String id;
  final String companyName;
  final String contactPerson;
  final String mobile;
  final String email;
  final List<String> activeProjects;
  final String tier; // 'Tier 1', 'Tier 2', 'Tier 3'
  final String? remarks;
  final DateTime createdAt;

  BuilderModel({
    required this.id,
    required this.companyName,
    required this.contactPerson,
    required this.mobile,
    required this.email,
    required this.activeProjects,
    required this.tier,
    this.remarks,
    required this.createdAt,
  });

  factory BuilderModel.fromJson(Map<String, dynamic> json) {
    return BuilderModel(
      id: json['id'] ?? '',
      companyName: json['companyName'] ?? '',
      contactPerson: json['contactPerson'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      activeProjects: List<String>.from(json['activeProjects'] ?? []),
      tier: json['tier'] ?? 'Tier 3',
      remarks: json['remarks'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyName': companyName,
      'contactPerson': contactPerson,
      'mobile': mobile,
      'email': email,
      'activeProjects': activeProjects,
      'tier': tier,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  BuilderModel copyWith({
    String? id,
    String? companyName,
    String? contactPerson,
    String? mobile,
    String? email,
    List<String>? activeProjects,
    String? tier,
    String? remarks,
    DateTime? createdAt,
  }) {
    return BuilderModel(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      contactPerson: contactPerson ?? this.contactPerson,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      activeProjects: activeProjects ?? this.activeProjects,
      tier: tier ?? this.tier,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class OwnerModel {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String? address;
  final String? remarks;
  final DateTime createdAt;

  OwnerModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    this.address,
    this.remarks,
    required this.createdAt,
  });

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    return OwnerModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      address: json['address'],
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
      'mobile': mobile,
      'email': email,
      'address': address,
      'remarks': remarks,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  OwnerModel copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? address,
    String? remarks,
    DateTime? createdAt,
  }) {
    return OwnerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      address: address ?? this.address,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

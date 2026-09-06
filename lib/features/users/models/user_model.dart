class RoleModel {
  final String id;
  final String name;
  final String? description;

  const RoleModel({
    required this.id,
    required this.name,
    this.description,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
    );
  }
}

class UserModel {
  final String id;
  final String roleId;
  final String roleName;
  final String fullName;
  final String email;
  final String? mobile;
  final bool isActive;
  final String? profilePhoto;
  final String? createdAt;
  final String? adminId;
  final String? organizationId;
  final String? createdByName;

  const UserModel({
    required this.id,
    required this.roleId,
    required this.roleName,
    required this.fullName,
    required this.email,
    this.mobile,
    required this.isActive,
    this.profilePhoto,
    this.createdAt,
    this.adminId,
    this.organizationId,
    this.createdByName,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String rName = 'Sales';
    if (json['roles'] is Map) {
      rName = json['roles']['name'] ?? 'Sales';
    } else if (json['roleName'] != null) {
      rName = json['roleName'];
    }

    String? cName;
    if (json['creator'] is Map) {
      cName = json['creator']['full_name'] ?? json['creator']['fullName'];
    }

    final adminId = json['admin_id'] as String?;
    if (rName == 'Admin' && adminId != null) {
      rName = 'Telecaller';
    }

    return UserModel(
      id: json['id'] ?? '',
      roleId: json['role_id'] ?? '',
      roleName: rName,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'],
      isActive: json['is_active'] ?? true,
      profilePhoto: json['profile_photo'],
      createdAt: json['created_at'],
      adminId: json['admin_id'] as String?,
      organizationId: json['organization_id'] as String?,
      createdByName: cName,
    );
  }
}

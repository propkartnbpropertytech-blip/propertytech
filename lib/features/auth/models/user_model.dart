import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? token;
  final String role;
  final List<String> permissions;
  final String fullName;
  final String? mobile;
  final bool isActive;
  final String? profilePhoto;
  final String? createdAt;
  final String? adminId;
  final String? organizationId;
  final String? adminName;
  final String? adminEmail;
  final String? adminRole;

  const UserModel({
    required this.id,
    required this.email,
    this.token,
    required this.role,
    required this.permissions,
    required this.fullName,
    this.mobile,
    this.isActive = true,
    this.profilePhoto,
    this.createdAt,
    this.adminId,
    this.organizationId,
    this.adminName,
    this.adminEmail,
    this.adminRole,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final dataMap = json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : json;
    final userMap = dataMap['user'] is Map<String, dynamic> ? dataMap['user'] as Map<String, dynamic> : dataMap;
    final token = json['token'] as String? ?? json['accessToken'] as String? ?? dataMap['token'] as String?;
    
    String role = 'Sales';
    if (userMap['roles'] is Map) {
      role = userMap['roles']['name']?.toString() ?? 'Sales';
    } else if (userMap['role'] != null) {
      role = userMap['role'].toString();
    } else if (userMap['roleName'] != null) {
      role = userMap['roleName'].toString();
    }

    final List<String> permissions = List<String>.from(userMap['permissions'] ?? []);
    final fullName = userMap['full_name']?.toString() ?? userMap['fullName']?.toString() ?? 'User';
    final mobile = userMap['mobile']?.toString() ?? userMap['phone']?.toString();
    final isActive = userMap['is_active'] as bool? ?? userMap['isActive'] as bool? ?? true;
    final profilePhoto = userMap['profile_photo']?.toString() ?? userMap['profilePhoto']?.toString();
    final createdAt = userMap['created_at']?.toString() ?? userMap['createdAt']?.toString();
    final adminId = userMap['admin_id']?.toString() ?? userMap['adminId']?.toString();
    final organizationId = userMap['organization_id']?.toString() ?? userMap['organizationId']?.toString();

    String? adminName;
    String? adminEmail;
    String? adminRole;

    final adminData = userMap['admin'] ?? userMap['creator'] ?? userMap['added_by'] ?? userMap['addedBy'];
    if (adminData is Map<String, dynamic>) {
      adminName = adminData['full_name']?.toString() ?? adminData['fullName']?.toString();
      adminEmail = adminData['email']?.toString();
      if (adminData['roles'] is Map) {
        adminRole = adminData['roles']['name']?.toString();
      } else {
        adminRole = adminData['role']?.toString() ?? adminData['roleName']?.toString();
      }
    } else if (userMap['admin_name'] != null || userMap['adminName'] != null) {
      adminName = userMap['admin_name']?.toString() ?? userMap['adminName']?.toString();
      adminEmail = userMap['admin_email']?.toString() ?? userMap['adminEmail']?.toString();
      adminRole = userMap['admin_role']?.toString() ?? userMap['adminRole']?.toString();
    }

    // If they have Admin role, but are managed by an Admin, they are a Telecaller
    if (role == 'Admin' && adminId != null) {
      role = 'Telecaller';
    }

    // Hierarchy guard: ensure we don't display invalid hierarchy relationships (e.g. Sales as Admin's creator)
    if (role == 'Admin' && (adminRole == 'Sales' || adminRole == 'Telecaller')) {
      adminName = null;
      adminEmail = null;
      adminRole = null;
    } else {
      final isEmployee = role == 'Sales' || role == 'Telecaller';
      final hasSalesOrTelecallerCreator = adminRole == 'Sales' || adminRole == 'Telecaller';
      if (isEmployee && hasSalesOrTelecallerCreator) {
        adminName = null;
        adminEmail = null;
        adminRole = null;
      }
    }

    return UserModel(
      id: userMap['id']?.toString() ?? userMap['uid']?.toString() ?? '',
      email: userMap['email']?.toString() ?? '',
      token: token,
      role: role,
      permissions: permissions,
      fullName: fullName,
      mobile: mobile,
      isActive: isActive,
      profilePhoto: profilePhoto,
      createdAt: createdAt,
      adminId: adminId,
      organizationId: organizationId,
      adminName: adminName,
      adminEmail: adminEmail,
      adminRole: adminRole,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (token != null) 'token': token,
      'role': role,
      'permissions': permissions,
      'fullName': fullName,
      if (mobile != null) 'mobile': mobile,
      'is_active': isActive,
      if (profilePhoto != null) 'profile_photo': profilePhoto,
      if (createdAt != null) 'created_at': createdAt,
      if (adminId != null) 'admin_id': adminId,
      if (organizationId != null) 'organization_id': organizationId,
      if (adminName != null) 'admin_name': adminName,
      if (adminEmail != null) 'admin_email': adminEmail,
      if (adminRole != null) 'admin_role': adminRole,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? token,
    String? role,
    List<String>? permissions,
    String? fullName,
    String? mobile,
    bool? isActive,
    String? profilePhoto,
    String? createdAt,
    String? adminId,
    String? organizationId,
    String? adminName,
    String? adminEmail,
    String? adminRole,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      token: token ?? this.token,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      fullName: fullName ?? this.fullName,
      mobile: mobile ?? this.mobile,
      isActive: isActive ?? this.isActive,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      createdAt: createdAt ?? this.createdAt,
      adminId: adminId ?? this.adminId,
      organizationId: organizationId ?? this.organizationId,
      adminName: adminName ?? this.adminName,
      adminEmail: adminEmail ?? this.adminEmail,
      adminRole: adminRole ?? this.adminRole,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        role,
        permissions,
        fullName,
        mobile,
        isActive,
        profilePhoto,
        createdAt,
        adminId,
        organizationId,
        adminName,
        adminEmail,
        adminRole,
      ];
}


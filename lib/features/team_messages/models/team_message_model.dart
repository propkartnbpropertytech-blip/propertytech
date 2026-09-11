class TeamChatUserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? adminId;
  final String? teamName;
  final String? adminName;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  TeamChatUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.adminId,
    this.teamName,
    this.adminName,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory TeamChatUserModel.fromJson(Map<String, dynamic> json) {
    String r = json['role']?.toString() ?? 'Sales';
    final adminId = json['admin_id']?.toString();

    // Telecaller resolution fallback if role was stored as Admin with an admin_id
    if (r.toLowerCase() == 'admin' && adminId != null && adminId.isNotEmpty) {
      r = 'Telecaller';
    }
    if (json['roles'] is Map && json['roles']['name'] != null) {
      final roleObjName = json['roles']['name'].toString();
      if (roleObjName.toLowerCase() == 'telecaller') {
        r = 'Telecaller';
      }
    }

    return TeamChatUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      role: r,
      adminId: adminId,
      teamName: json['team_name']?.toString(),
      adminName: json['admin_name']?.toString(),
      unreadCount: json['unread_count'] is int
          ? json['unread_count']
          : int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'admin_id': adminId,
      'team_name': teamName,
      'admin_name': adminName,
      'unread_count': unreadCount,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
    };
  }
}

class TeamMessageModel {
  final String id;
  final String organizationId;
  final String senderId;
  final String receiverId;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? senderName;
  final String? receiverName;

  TeamMessageModel({
    required this.id,
    required this.organizationId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.senderName,
    this.receiverName,
  });

  factory TeamMessageModel.fromJson(Map<String, dynamic> json) {
    return TeamMessageModel(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      receiverId: json['receiver_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['is_read'] == true || json['is_read']?.toString() == 'true',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      senderName: json['sender_name']?.toString(),
      receiverName: json['receiver_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'organization_id': organizationId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'sender_name': senderName,
      'receiver_name': receiverName,
    };
  }
}

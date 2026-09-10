class TeamChatUserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final int unreadCount;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  TeamChatUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.unreadCount = 0,
    this.lastMessage,
    this.lastMessageAt,
  });

  factory TeamChatUserModel.fromJson(Map<String, dynamic> json) {
    return TeamChatUserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'User',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      unreadCount: json['unread_count'] is int ? json['unread_count'] : int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: json['last_message_at'] != null ? DateTime.tryParse(json['last_message_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
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

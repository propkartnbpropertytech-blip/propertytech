class SupportCatalogFunction {
  final String key;
  final String name;

  const SupportCatalogFunction({
    required this.key,
    required this.name,
  });

  factory SupportCatalogFunction.fromJson(Map<String, dynamic> json) {
    return SupportCatalogFunction(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'name': name,
      };
}

class SupportCatalogPage {
  final String id;
  final String pageKey;
  final String pageName;
  final String category;
  final String description;
  final List<String> allowedRoles;
  final List<SupportCatalogFunction> functions;

  const SupportCatalogPage({
    required this.id,
    required this.pageKey,
    required this.pageName,
    required this.category,
    required this.description,
    required this.allowedRoles,
    required this.functions,
  });

  factory SupportCatalogPage.fromJson(Map<String, dynamic> json) {
    var fnList = <SupportCatalogFunction>[];
    if (json['functions'] is List) {
      fnList = (json['functions'] as List)
          .map((f) => SupportCatalogFunction.fromJson(f as Map<String, dynamic>))
          .toList();
    }
    var roles = <String>[];
    if (json['allowed_roles'] is List) {
      roles = (json['allowed_roles'] as List).map((r) => r.toString()).toList();
    }

    return SupportCatalogPage(
      id: json['id']?.toString() ?? '',
      pageKey: json['page_key']?.toString() ?? '',
      pageName: json['page_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      description: json['description']?.toString() ?? '',
      allowedRoles: roles,
      functions: fnList,
    );
  }
}

class SupportAttachment {
  final String id;
  final String fileName;
  final String filePath;
  final String? fileType;
  final int? fileSize;
  final DateTime uploadedAt;

  const SupportAttachment({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.fileType,
    this.fileSize,
    required this.uploadedAt,
  });

  factory SupportAttachment.fromJson(Map<String, dynamic> json) {
    return SupportAttachment(
      id: json['id']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? 'attachment',
      filePath: json['file_path']?.toString() ?? '',
      fileType: json['file_type']?.toString(),
      fileSize: json['file_size'] != null ? int.tryParse(json['file_size'].toString()) : null,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SupportComment {
  final String id;
  final String issueId;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String comment;
  final bool isInternalNote;
  final DateTime createdAt;

  const SupportComment({
    required this.id,
    required this.issueId,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.comment,
    required this.isInternalNote,
    required this.createdAt,
  });

  factory SupportComment.fromJson(Map<String, dynamic> json) {
    return SupportComment(
      id: json['id']?.toString() ?? '',
      issueId: json['issue_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      senderName: json['sender_name']?.toString() ?? 'User',
      senderRole: json['sender_role']?.toString() ?? 'User',
      comment: json['comment']?.toString() ?? '',
      isInternalNote: json['is_internal_note'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SupportTimelineEvent {
  final String id;
  final String issueId;
  final String eventType;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String description;
  final DateTime createdAt;

  const SupportTimelineEvent({
    required this.id,
    required this.issueId,
    required this.eventType,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.description,
    required this.createdAt,
  });

  factory SupportTimelineEvent.fromJson(Map<String, dynamic> json) {
    return SupportTimelineEvent(
      id: json['id']?.toString() ?? '',
      issueId: json['issue_id']?.toString() ?? '',
      eventType: json['event_type']?.toString() ?? 'EVENT',
      actorId: json['actor_id']?.toString() ?? '',
      actorName: json['actor_name']?.toString() ?? 'System',
      actorRole: json['actor_role']?.toString() ?? 'System',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class SupportIssue {
  final String id;
  final String ticketNumber;
  final String reporterId;
  final String reporterName;
  final String reporterRole;
  final String? reporterEmail;
  final String pageKey;
  final String pageName;
  final String functionKey;
  final String functionName;
  final String issueType;
  final String priority;
  final String status;
  final String description;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;
  final List<SupportAttachment> attachments;
  final List<SupportComment> comments;
  final List<SupportTimelineEvent> timeline;

  const SupportIssue({
    required this.id,
    required this.ticketNumber,
    required this.reporterId,
    required this.reporterName,
    required this.reporterRole,
    this.reporterEmail,
    required this.pageKey,
    required this.pageName,
    required this.functionKey,
    required this.functionName,
    required this.issueType,
    required this.priority,
    required this.status,
    required this.description,
    this.assignedTo,
    this.assignedToName,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    this.attachments = const [],
    this.comments = const [],
    this.timeline = const [],
  });

  factory SupportIssue.fromJson(Map<String, dynamic> json) {
    var attList = <SupportAttachment>[];
    if (json['attachments'] is List) {
      attList = (json['attachments'] as List)
          .map((a) => SupportAttachment.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    var commentList = <SupportComment>[];
    if (json['comments'] is List) {
      commentList = (json['comments'] as List)
          .map((c) => SupportComment.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    var timelineList = <SupportTimelineEvent>[];
    if (json['timeline'] is List) {
      timelineList = (json['timeline'] as List)
          .map((t) => SupportTimelineEvent.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return SupportIssue(
      id: json['id']?.toString() ?? '',
      ticketNumber: json['ticket_number']?.toString() ?? 'SUP-0000',
      reporterId: json['reporter_id']?.toString() ?? '',
      reporterName: json['reporter_name']?.toString() ?? 'User',
      reporterRole: json['reporter_role']?.toString() ?? 'User',
      reporterEmail: json['reporter_email']?.toString(),
      pageKey: json['page_key']?.toString() ?? '',
      pageName: json['page_name']?.toString() ?? '',
      functionKey: json['function_key']?.toString() ?? '',
      functionName: json['function_name']?.toString() ?? '',
      issueType: json['issue_type']?.toString() ?? 'Other',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Open',
      description: json['description']?.toString() ?? '',
      assignedTo: json['assigned_to']?.toString(),
      assignedToName: json['assigned_to_name']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'].toString())?.toLocal()
          : null,
      attachments: attList,
      comments: commentList,
      timeline: timelineList,
    );
  }
}

class SupportStats {
  final int total;
  final int open;
  final int inProgress;
  final int waitingForUser;
  final int resolved;
  final int closed;

  const SupportStats({
    required this.total,
    required this.open,
    required this.inProgress,
    required this.waitingForUser,
    required this.resolved,
    required this.closed,
  });

  factory SupportStats.fromJson(Map<String, dynamic> json) {
    return SupportStats(
      total: int.tryParse(json['total']?.toString() ?? '0') ?? 0,
      open: int.tryParse(json['open']?.toString() ?? '0') ?? 0,
      inProgress: int.tryParse(json['inProgress']?.toString() ?? '0') ?? 0,
      waitingForUser: int.tryParse(json['waitingForUser']?.toString() ?? '0') ?? 0,
      resolved: int.tryParse(json['resolved']?.toString() ?? '0') ?? 0,
      closed: int.tryParse(json['closed']?.toString() ?? '0') ?? 0,
    );
  }
}

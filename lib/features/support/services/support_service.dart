import 'package:flutter/foundation.dart';
import '../../../core/api/dio_client.dart';
import '../models/support_issue_model.dart';

class SupportService {
  static final SupportService _instance = SupportService._internal();
  static SupportService get instance => _instance;

  SupportService._internal();

  /// Fetch pages & functions catalog based on current user role
  Future<List<SupportCatalogPage>> fetchCatalog() async {
    try {
      final response = await DioClient.dio.get('/api/v1/support/catalog');
      if (response.data != null && response.data['success'] == true) {
        final rawList = response.data['data']['catalog'] as List? ?? [];
        return rawList
            .map((item) => SupportCatalogPage.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('[SupportService] fetchCatalog error: $e');
      }
      return [];
    }
  }

  /// Fetch paginated issues with filters
  Future<Map<String, dynamic>> fetchIssues({
    String? status,
    String? priority,
    String? role,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (priority != null && priority.isNotEmpty) queryParams['priority'] = priority;
      if (role != null && role.isNotEmpty) queryParams['role'] = role;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await DioClient.dio.get(
        '/api/v1/support/issues',
        queryParameters: queryParams,
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final rawList = data['issues'] as List? ?? [];
        final issues = rawList
            .map((item) => SupportIssue.fromJson(item as Map<String, dynamic>))
            .toList();
        final totalCount = data['totalCount'] as int? ?? 0;

        return {
          'issues': issues,
          'totalCount': totalCount,
          'page': page,
          'limit': limit,
        };
      }
      return {'issues': <SupportIssue>[], 'totalCount': 0};
    } catch (e) {
      if (kDebugMode) {
        print('[SupportService] fetchIssues error: $e');
      }
      return {'issues': <SupportIssue>[], 'totalCount': 0};
    }
  }

  /// Fetch support stats KPIs
  Future<SupportStats> fetchStats() async {
    try {
      final response = await DioClient.dio.get('/api/v1/support/stats');
      if (response.data != null && response.data['success'] == true) {
        final statsData = response.data['data']['stats'] as Map<String, dynamic>? ?? {};
        return SupportStats.fromJson(statsData);
      }
      return const SupportStats(total: 0, open: 0, inProgress: 0, waitingForUser: 0, resolved: 0, closed: 0);
    } catch (e) {
      if (kDebugMode) {
        print('[SupportService] fetchStats error: $e');
      }
      return const SupportStats(total: 0, open: 0, inProgress: 0, waitingForUser: 0, resolved: 0, closed: 0);
    }
  }

  /// Fetch single issue details by ID
  Future<SupportIssue?> fetchIssueById(String id) async {
    try {
      final response = await DioClient.dio.get('/api/v1/support/issues/$id');
      if (response.data != null && response.data['success'] == true) {
        final issueData = response.data['data']['issue'] as Map<String, dynamic>? ?? {};
        return SupportIssue.fromJson(issueData);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('[SupportService] fetchIssueById error: $e');
      }
      return null;
    }
  }

  /// Submit a new support issue
  Future<SupportIssue> createIssue({
    required String pageKey,
    required String pageName,
    required String functionKey,
    required String functionName,
    required String issueType,
    String priority = 'Medium',
    required String description,
    List<Map<String, dynamic>> attachments = const [],
  }) async {
    final response = await DioClient.dio.post(
      '/api/v1/support/issues',
      data: {
        'page_key': pageKey,
        'page_name': pageName,
        'function_key': functionKey,
        'function_name': functionName,
        'issue_type': issueType,
        'priority': priority,
        'description': description,
        'attachments': attachments,
      },
    );

    if (response.data != null && response.data['success'] == true) {
      final issueData = response.data['data']['issue'] as Map<String, dynamic>;
      return SupportIssue.fromJson(issueData);
    }
    throw Exception(response.data?['message'] ?? 'Failed to submit support ticket');
  }

  /// Update issue status, priority, or assignment (Super Admin)
  Future<SupportIssue> updateIssue(
    String id, {
    String? status,
    String? priority,
    String? assignedTo,
    String? assignedToName,
  }) async {
    final payload = <String, dynamic>{};
    if (status != null) payload['status'] = status;
    if (priority != null) payload['priority'] = priority;
    if (assignedTo != null) payload['assigned_to'] = assignedTo;
    if (assignedToName != null) payload['assigned_to_name'] = assignedToName;

    final response = await DioClient.dio.patch(
      '/api/v1/support/issues/$id',
      data: payload,
    );

    if (response.data != null && response.data['success'] == true) {
      final issueData = response.data['data']['issue'] as Map<String, dynamic>;
      return SupportIssue.fromJson(issueData);
    }
    throw Exception(response.data?['message'] ?? 'Failed to update support issue');
  }

  /// Add comment or Super Admin reply
  Future<SupportComment> addComment(
    String issueId,
    String comment, {
    bool isInternalNote = false,
  }) async {
    final response = await DioClient.dio.post(
      '/api/v1/support/issues/$issueId/comments',
      data: {
        'comment': comment,
        'is_internal_note': isInternalNote,
      },
    );

    if (response.data != null && response.data['success'] == true) {
      final commentData = response.data['data']['comment'] as Map<String, dynamic>;
      return SupportComment.fromJson(commentData);
    }
    throw Exception(response.data?['message'] ?? 'Failed to add comment');
  }
}

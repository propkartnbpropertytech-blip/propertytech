import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_constants.dart';
import '../../../core/api/api_exception.dart';

class RequirementsService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getRequirements({
    String? search,
    String? configurationId,
    String? propertyTypeId,
    String? status,
    String? listingTypeId,
    String? group,
    String? userId,
    String? salesUserId,
    String? createdBy,
    String? assignedTo,
    int? page,
    int? limit,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      if (search != null && search.isNotEmpty) {
        queryParameters['search'] = search;
      }
      if (configurationId != null && configurationId.isNotEmpty) {
        queryParameters['configurationId'] = configurationId;
      }
      if (propertyTypeId != null && propertyTypeId.isNotEmpty) {
        queryParameters['propertyTypeId'] = propertyTypeId;
      }
      if (status != null && status != 'All') {
        queryParameters['status'] = status;
      }
      if (listingTypeId != null && listingTypeId.isNotEmpty) {
        queryParameters['listingTypeId'] = listingTypeId;
      }
      if (group != null && group.isNotEmpty) {
        queryParameters['group'] = group;
      }
      if (userId != null && userId.isNotEmpty) {
        queryParameters['userId'] = userId;
      }
      if (salesUserId != null && salesUserId.isNotEmpty) {
        queryParameters['salesUserId'] = salesUserId;
      }
      if (createdBy != null && createdBy.isNotEmpty) {
        queryParameters['createdBy'] = createdBy;
      }
      if (assignedTo != null && assignedTo.isNotEmpty) {
        queryParameters['assignedTo'] = assignedTo;
      }
      if (page != null) {
        queryParameters['page'] = page;
      }
      if (limit != null) {
        queryParameters['limit'] = limit;
      }

      final response = await _apiClient.get(
        '/requirements',
        queryParameters: queryParameters,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getSalesSummary() async {
    try {
      final response = await _apiClient.get('/requirements/sales-summary');
      if (response.data is Map && response.data['data'] is List) {
        return (response.data['data'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createRequirementsBulk(List<Map<String, dynamic>> requirementsList) async {
    try {
      final response = await _apiClient.post('/requirements/bulk', {
        'requirements': requirementsList,
      });
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> createRequirement(Map<String, dynamic> requirementData) async {
    try {
      final response = await _apiClient.post('/requirements', requirementData);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> updateRequirement(String id, Map<String, dynamic> requirementData) async {
    try {
      final response = await _apiClient.put('/requirements/$id', requirementData);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> deleteRequirement(String id) async {
    try {
      final response = await _apiClient.delete('/requirements/$id');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> getBinRequirements() async {
    try {
      final response = await _apiClient.get(
        '/requirements',
        queryParameters: {'includeDeleted': 'true'},
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> restoreRequirement(String id) async {
    try {
      final response = await _apiClient.patch('/requirements/$id/restore', {});
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> permanentDeleteRequirement(String id) async {
    try {
      await _apiClient.delete('/requirements/$id/permanent');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> emptyBin() async {
    try {
      await _apiClient.delete('/requirements/bin/empty');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> getRequirementMatches(
    String requirementId, {
    int page = 1,
    int limit = 20,
    String? mode,
    int? minScore,
    bool includeNearby = false,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
        'include_nearby': includeNearby,
      };
      if (mode != null && mode.isNotEmpty) {
        queryParams['mode'] = mode;
      }
      if (minScore != null) {
        queryParams['min_score'] = minScore;
      }

      final response = await _apiClient.get(
        '/requirements/$requirementId/matches',
        queryParameters: queryParams,
      );
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      throw ApiException(message: "Invalid response format from server.");
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> exportRequirements(Map<String, dynamic> queryParameters) async {
    try {
      final response = await _apiClient.get(
        '/requirements/export',
        queryParameters: queryParameters,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> addRequirementNote(String id, String note) async {
    try {
      await _apiClient.post('/requirements/$id/notes', {'note': note});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> postSiteVisit(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/site-visits', data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> postFollowup(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/followups', data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> getSiteVisits(Map<String, dynamic> queryParameters) async {
    try {
      final res = await _apiClient.get('/site-visits', queryParameters: queryParameters);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> getFollowups(Map<String, dynamic> queryParameters) async {
    try {
      final res = await _apiClient.get('/followups', queryParameters: queryParameters);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> updateFollowup(String id, Map<String, dynamic> data) async {
    try {
      await _apiClient.put('/followups/$id', data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> patchFollowup(String id, Map<String, dynamic> data) async {
    try {
      await _apiClient.patch('/followups/$id', data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> deleteFollowup(String endpoint, Map<String, dynamic> data) async {
    try {
      await _apiClient.post(endpoint, data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> getShareSessions(String requirementId) async {
    try {
      final res = await _apiClient.get('/share-sessions/requirement/$requirementId');
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> revokeShareSession(String sessionId) async {
    try {
      await _apiClient.post('/share-sessions/$sessionId/revoke', {});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<dynamic> createShareSession(Map<String, dynamic> data) async {
    try {
      final res = await _apiClient.post('/share-sessions', data);
      return res.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> logShareAction(Map<String, dynamic> data) async {
    try {
      await _apiClient.post('/audit/share', data);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getSalesPropertyListingLeads({
    String? userId,
    bool orgWide = false,
  }) async {
    try {
      final query = <String, dynamic>{
        if (userId != null && userId.isNotEmpty) 'userId': userId,
        if (orgWide && (userId == null || userId.isEmpty)) 'scope': 'org',
      };
      final res = await _apiClient.get(
        ApiConstants.allocationSalesLeads,
        queryParameters: query,
      );
      return res.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> bulkUpdateSalesLeadStatus({
    required List<String> ids,
    required String status,
  }) async {
    try {
      final res = await _apiClient.patch(
        ApiConstants.allocationSalesLeadBulkStatus,
        {'ids': ids, 'status': status},
      );
      return res.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<Map<String, dynamic>> updateSalesLeadStatus({
    required String leadId,
    required String status,
  }) async {
    try {
      final res = await _apiClient.patch(
        ApiConstants.allocationSalesLeadStatus(leadId),
        {'status': status},
      );
      return res.data is Map<String, dynamic>
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  Future<void> downloadFile(String url, String savePath) async {
    try {
      await _apiClient.download(url, savePath);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }
}

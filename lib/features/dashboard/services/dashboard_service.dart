import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../models/kpi_models.dart';

class DashboardService {
  final ApiClient _apiClient = ApiClient();

  /// Shared across every [DashboardService] instance so parallel callers
  /// (bloc, shell, background refresh) hit the network once.
  static Future<Map<String, dynamic>>? _inFlight;

  Future<Map<String, dynamic>> getDashboardData() {
    return _inFlight ??= _fetch().whenComplete(() {
      _inFlight = null;
    });
  }

  Future<Map<String, dynamic>> _fetch() async {
    try {
      final response = await _apiClient.get('/dashboard');
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        if (map['success'] == true && map['data'] is Map<String, dynamic>) {
          return map['data'] as Map<String, dynamic>;
        }
        throw ApiException(
          message: map['message'] ?? 'Failed to fetch dashboard data.',
        );
      }
      throw ApiException(message: 'Invalid response format from server.');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    } catch (e) {
      throw ApiException(message: e.toString());
    }
  }

  /// Fetch PostgreSQL-authoritative overall KPI report from /api/v1/reports/overall
  Future<Map<String, dynamic>> getAuthoritativeReportMetrics({
    String? startDate,
    String? endDate,
    String? source,
  }) async {
    try {
      final response = await _apiClient.get(
        '/reports/overall',
        queryParameters: {
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (source != null) 'source': source,
        },
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getDashboardNotes() async {
    try {
      final response = await _apiClient.get('/dashboard/notes');
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final list = response.data['data'] as List? ?? [];
        return list.map((item) => item as Map<String, dynamic>).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createDashboardNote(String content) async {
    try {
      final response = await _apiClient.post('/dashboard/notes', {'content': content});
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateDashboardNote(String noteId, {String? content, bool? isCompleted}) async {
    try {
      final response = await _apiClient.patch('/dashboard/notes/$noteId', {
        if (content != null) 'content': content,
        if (isCompleted != null) 'is_completed': isCompleted,
      });
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return response.data['data'] as Map<String, dynamic>?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteDashboardNote(String noteId) async {
    try {
      final response = await _apiClient.delete('/dashboard/notes/$noteId');
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // Database-Authoritative Admin KPI Endpoints

  Future<DashboardKpisResponse> getDashboardKpis(KpiFilterParams params) async {
    try {
      final response = await _apiClient.get(
        '/dashboard/kpis',
        queryParameters: params.toQueryParams(),
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return DashboardKpisResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const DashboardKpisResponse();
    } catch (_) {
      return const DashboardKpisResponse();
    }
  }

  Future<InventoryBreakdownData> getInventoryBreakdown(KpiFilterParams params) async {
    try {
      final response = await _apiClient.get(
        '/dashboard/inventory-breakdown',
        queryParameters: params.toQueryParams(),
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return InventoryBreakdownData.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const InventoryBreakdownData();
    } catch (_) {
      return const InventoryBreakdownData();
    }
  }

  Future<InventoryPropertiesResponse> getInventoryProperties({
    required String status,
    required KpiFilterParams params,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final q = params.toQueryParams();
      q['status'] = status;
      q['page'] = page;
      q['limit'] = limit;
      final response = await _apiClient.get(
        '/dashboard/inventory-properties',
        queryParameters: q,
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return InventoryPropertiesResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const InventoryPropertiesResponse();
    } catch (e, stack) {
      debugPrint('[DashboardService] getInventoryProperties error: $e\n$stack');
      return const InventoryPropertiesResponse();
    }
  }

  Future<LeadsBreakdownData> getLeadsBreakdown(KpiFilterParams params) async {
    try {
      final response = await _apiClient.get(
        '/dashboard/leads-breakdown',
        queryParameters: params.toQueryParams(),
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return LeadsBreakdownData.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const LeadsBreakdownData();
    } catch (_) {
      return const LeadsBreakdownData();
    }
  }

  Future<LeadsListResponse> getLeadsList({
    String? source,
    required KpiFilterParams params,
    int page = 1,
    int limit = 25,
  }) async {
    try {
      final q = params.toQueryParams();
      if (source != null && source.isNotEmpty) q['source'] = source;
      q['page'] = page;
      q['limit'] = limit;
      final response = await _apiClient.get(
        '/dashboard/leads-list',
        queryParameters: q,
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return LeadsListResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const LeadsListResponse();
    } catch (_) {
      return const LeadsListResponse();
    }
  }

  Future<TelecallersSummaryResponse> getTelecallersSummary([KpiFilterParams? params]) async {
    try {
      final response = await _apiClient.get(
        '/dashboard/telecallers-summary',
        queryParameters: params?.toQueryParams(),
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return TelecallersSummaryResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const TelecallersSummaryResponse();
    } catch (_) {
      return const TelecallersSummaryResponse();
    }
  }

  Future<TelecallerDrilldownData?> getTelecallerDrilldown(
    String telecallerId, {
    String leadType = 'Both',
    KpiFilterParams? params,
  }) async {
    try {
      final q = params?.toQueryParams() ?? <String, dynamic>{};
      q['leadType'] = leadType;
      final response = await _apiClient.get(
        '/dashboard/telecaller-drilldown/$telecallerId',
        queryParameters: q,
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return TelecallerDrilldownData.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<LeadsListResponse> getTelecallerLeads(
    String telecallerId, {
    String category = 'all',
    String leadType = 'Both',
    String? search,
    int page = 1,
    int limit = 25,
    KpiFilterParams? params,
  }) async {
    try {
      final q = params?.toQueryParams() ?? <String, dynamic>{};
      q['category'] = category;
      q['leadType'] = leadType;
      q['page'] = page;
      q['limit'] = limit;
      if (search != null && search.trim().isNotEmpty) {
        q['search'] = search.trim();
      }
      final response = await _apiClient.get(
        '/dashboard/telecaller-leads/$telecallerId',
        queryParameters: q,
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return LeadsListResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const LeadsListResponse();
    } catch (e, stack) {
      debugPrint('[DashboardService] getTelecallerLeads error: $e\n$stack');
      return const LeadsListResponse();
    }
  }

  Future<SiteVisitsResponse> getSiteVisitsList({
    required KpiFilterParams params,
    String? search,
    int page = 1,
    int limit = 25,
  }) async {
    try {
      final q = params.toQueryParams();
      q['page'] = page;
      q['limit'] = limit;
      if (search != null && search.trim().isNotEmpty) {
        q['search'] = search.trim();
      }
      final response = await _apiClient.get(
        '/dashboard/site-visits-list',
        queryParameters: q,
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return SiteVisitsResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const SiteVisitsResponse();
    } catch (e, stack) {
      debugPrint('[DashboardService] getSiteVisitsList error: $e\n$stack');
      return const SiteVisitsResponse();
    }
  }

  Future<DealWonResponse> getDealWonList({
    required KpiFilterParams params,
    String? search,
    int page = 1,
    int limit = 25,
  }) async {
    try {
      final q = params.toQueryParams();
      q['page'] = page;
      q['limit'] = limit;
      if (search != null && search.trim().isNotEmpty) {
        q['search'] = search.trim();
      }
      final response = await _apiClient.get(
        '/dashboard/deal-won-list',
        queryParameters: q,
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return DealWonResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const DealWonResponse();
    } catch (e, stack) {
      debugPrint('[DashboardService] getDealWonList error: $e\n$stack');
      return const DealWonResponse();
    }
  }

  Future<SalesUserRequirementsResponse> getSalesUserRequirements(
    String salesUserId, {
    required String status,
    String? rejectionReason,
    String? search,
    int page = 1,
    int limit = 25,
    KpiFilterParams? params,
  }) async {
    try {
      final q = params?.toQueryParams() ?? <String, dynamic>{};
      q['status'] = status;
      q['page'] = page;
      q['limit'] = limit;
      if (rejectionReason != null && rejectionReason.trim().isNotEmpty) {
        q['rejectionReason'] = rejectionReason.trim();
      }
      if (search != null && search.trim().isNotEmpty) {
        q['search'] = search.trim();
      }
      final response = await _apiClient.get(
        '/dashboard/sales-user-requirements/$salesUserId',
        queryParameters: q,
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return SalesUserRequirementsResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const SalesUserRequirementsResponse();
    } catch (e, stack) {
      debugPrint('[DashboardService] getSalesUserRequirements error: $e\n$stack');
      return const SalesUserRequirementsResponse();
    }
  }

  Future<LeadsAllocatedResponse> getLeadsAllocatedBreakdown(KpiFilterParams params) async {
    try {
      final response = await _apiClient.get(
        '/dashboard/leads-allocated-breakdown',
        queryParameters: params.toQueryParams(),
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return LeadsAllocatedResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const LeadsAllocatedResponse();
    } catch (_) {
      return const LeadsAllocatedResponse();
    }
  }

  Future<AssignedToSalesResponse> getAssignedToSalesBreakdown(KpiFilterParams params) async {
    try {
      final response = await _apiClient.get(
        '/dashboard/assigned-to-sales-breakdown',
        queryParameters: params.toQueryParams(),
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return AssignedToSalesResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const AssignedToSalesResponse();
    } catch (_) {
      return const AssignedToSalesResponse();
    }
  }

  Future<SalesUsersSummaryResponse> getSalesUsersSummary([KpiFilterParams? params]) async {
    try {
      final response = await _apiClient.get(
        '/dashboard/sales-users-summary',
        queryParameters: params?.toQueryParams(),
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return SalesUsersSummaryResponse.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return const SalesUsersSummaryResponse();
    } catch (_) {
      return const SalesUsersSummaryResponse();
    }
  }

  Future<SalesUserDrilldownData?> getSalesUserDrilldown(
    String salesUserId, {
    KpiFilterParams? params,
  }) async {
    try {
      final response = await _apiClient.get(
        '/dashboard/sales-user-drilldown/$salesUserId',
        queryParameters: params?.toQueryParams() ?? {},
      );
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        return SalesUserDrilldownData.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<KpiConfigItem>> getKpiConfig() async {
    try {
      final response = await _apiClient.get('/dashboard/kpi-config');
      if (response.data is Map<String, dynamic> && response.data['success'] == true) {
        final list = (response.data['data'] as List?)
                ?.map((c) => KpiConfigItem.fromJson(Map<String, dynamic>.from(c)))
                .toList() ??
            [];
        return list;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> updateKpiConfig(List<Map<String, dynamic>> configs) async {
    try {
      final response = await _apiClient.put(
        '/dashboard/kpi-config',
        {'configs': configs},
      );
      return response.data is Map<String, dynamic> && response.data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
